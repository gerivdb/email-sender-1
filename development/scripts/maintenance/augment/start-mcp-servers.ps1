<#
.SYNOPSIS
    Script de dÃ©marrage pour tous les serveurs MCP.

.DESCRIPTION
    Ce script dÃ©marre tous les serveurs MCP nÃ©cessaires pour l'intÃ©gration avec Augment Code,
    notamment le serveur MCP pour les Memories et l'adaptateur MCP pour le gestionnaire de modes.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut : "development\config\unified-config.json".

.PARAMETER LogPath
    Chemin vers le rÃ©pertoire des logs. Par dÃ©faut : "logs\mcp".

.EXAMPLE
    .\start-mcp-servers.ps1
    # DÃ©marre tous les serveurs MCP avec les paramÃ¨tres par dÃ©faut

.EXAMPLE
    .\start-mcp-servers.ps1 -ConfigPath "config\custom-config.json" -LogPath "logs\custom"
    # DÃ©marre tous les serveurs MCP avec une configuration personnalisÃ©e et un rÃ©pertoire de logs personnalisÃ©

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = "development\config\unified-config.json",

    [Parameter()]
    [string]$LogPath = "logs\mcp"
)

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Charger la configuration unifiÃ©e
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    # CrÃ©er une configuration par dÃ©faut
    $config = [PSCustomObject]@{
        Augment = [PSCustomObject]@{
            MCP = [PSCustomObject]@{
                Enabled = $true
                Servers = @(
                    [PSCustomObject]@{
                        Name = "memories"
                        Port = 7891
                        ScriptPath = "development\scripts\maintenance\augment\mcp-memories-server.ps1"
                    },
                    [PSCustomObject]@{
                        Name = "mode-manager"
                        Port = 7892
                        ScriptPath = "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
                    }
                )
            }
        }
    }
}

# CrÃ©er le rÃ©pertoire des logs s'il n'existe pas
$logPath = Join-Path -Path $projectRoot -ChildPath $LogPath
if (-not (Test-Path -Path $logPath -PathType Container)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire des logs crÃ©Ã© : $logPath" -ForegroundColor Green
}

# Fonction pour dÃ©marrer un serveur MCP
function Start-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    # VÃ©rifier si le script existe
    $fullScriptPath = Join-Path -Path $projectRoot -ChildPath $ScriptPath
    if (-not (Test-Path -Path $fullScriptPath)) {
        Write-Warning "Script introuvable : $fullScriptPath"
        return $false
    }

    # VÃ©rifier si le port est disponible
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("127.0.0.1", $Port)
        $tcpClient.Close()
        Write-Warning "Le port $Port est dÃ©jÃ  utilisÃ©. Le serveur MCP $Name ne sera pas dÃ©marrÃ©."
        return $false
    } catch {
        # Le port est disponible
    }

    # CrÃ©er le fichier de log
    $logFile = Join-Path -Path $logPath -ChildPath "$Name.log"
    if (Test-Path -Path $logFile) {
        # Archiver le fichier de log existant
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $archiveLogFile = Join-Path -Path $logPath -ChildPath "$Name-$timestamp.log"
        Move-Item -Path $logFile -Destination $archiveLogFile -Force
    }

    # DÃ©marrer le serveur MCP
    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = "powershell"
        $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$fullScriptPath`" -Port $Port"
        $startInfo.WorkingDirectory = $projectRoot
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $process.Start() | Out-Null

        # CrÃ©er des tÃ¢ches pour lire la sortie standard et la sortie d'erreur
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = $process.StandardError.ReadToEndAsync()

        # Attendre que le processus dÃ©marre
        Start-Sleep -Seconds 2

        # VÃ©rifier si le processus est toujours en cours d'exÃ©cution
        if ($process.HasExited) {
            $output = $outputTask.Result
            $error = $errorTask.Result
            Write-Warning "Le serveur MCP $Name s'est arrÃªtÃ© prÃ©maturÃ©ment."
            Write-Warning "Sortie standard : $output"
            Write-Warning "Sortie d'erreur : $error"
            return $false
        }

        # Enregistrer le PID du processus
        $pid = $process.Id
        $pidFile = Join-Path -Path $logPath -ChildPath "$Name.pid"
        $pid | Out-File -FilePath $pidFile -Encoding UTF8

        Write-Host "Serveur MCP $Name dÃ©marrÃ© sur le port $Port (PID: $pid)." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors du dÃ©marrage du serveur MCP $Name : $_"
        return $false
    }
}

# Fonction pour arrÃªter un serveur MCP
function Stop-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    # VÃ©rifier si le fichier PID existe
    $pidFile = Join-Path -Path $logPath -ChildPath "$Name.pid"
    if (-not (Test-Path -Path $pidFile)) {
        Write-Warning "Fichier PID introuvable : $pidFile"
        return $false
    }

    # Lire le PID
    try {
        $pid = Get-Content -Path $pidFile -Encoding UTF8
        $pid = [int]$pid
    } catch {
        Write-Warning "Erreur lors de la lecture du PID : $_"
        return $false
    }

    # ArrÃªter le processus
    try {
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process) {
            $process.Kill()
            Write-Host "Serveur MCP $Name arrÃªtÃ© (PID: $pid)." -ForegroundColor Green
            Remove-Item -Path $pidFile -Force
            return $true
        } else {
            Write-Warning "Processus introuvable : $pid"
            Remove-Item -Path $pidFile -Force
            return $false
        }
    } catch {
        Write-Warning "Erreur lors de l'arrÃªt du serveur MCP $Name : $_"
        return $false
    }
}

# VÃ©rifier si les serveurs MCP sont activÃ©s
if (-not ($config.Augment -and $config.Augment.MCP -and $config.Augment.MCP.Enabled)) {
    Write-Warning "Les serveurs MCP sont dÃ©sactivÃ©s dans la configuration."
    exit 0
}

# DÃ©marrer les serveurs MCP
$servers = $config.Augment.MCP.Servers
if (-not $servers) {
    Write-Warning "Aucun serveur MCP dÃ©fini dans la configuration."
    exit 0
}

$startedServers = @()
foreach ($server in $servers) {
    $name = $server.Name
    $port = $server.Port
    $scriptPath = $server.ScriptPath

    Write-Host "DÃ©marrage du serveur MCP $name sur le port $port..." -ForegroundColor Cyan
    $success = Start-MCPServer -Name $name -Port $port -ScriptPath $scriptPath -LogPath $logPath
    if ($success) {
        $startedServers += $name
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des serveurs MCP :" -ForegroundColor Cyan
Write-Host "Serveurs dÃ©marrÃ©s : $($startedServers -join ", ")" -ForegroundColor Green
$failedServers = $servers | Where-Object { $_.Name -notin $startedServers } | Select-Object -ExpandProperty Name
if ($failedServers) {
    Write-Host "Serveurs non dÃ©marrÃ©s : $($failedServers -join ", ")" -ForegroundColor Red
}

# CrÃ©er un script d'arrÃªt
$stopScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\stop-mcp-servers.ps1"
$stopScriptContent = @"
<#
.SYNOPSIS
    Script d'arrÃªt pour tous les serveurs MCP.

.DESCRIPTION
    Ce script arrÃªte tous les serveurs MCP dÃ©marrÃ©s par le script start-mcp-servers.ps1.

.PARAMETER LogPath
    Chemin vers le rÃ©pertoire des logs. Par dÃ©faut : "logs\mcp".

.EXAMPLE
    .\stop-mcp-servers.ps1
    # ArrÃªte tous les serveurs MCP

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]`$LogPath = "logs\mcp"
)

# DÃ©terminer le chemin du projet
`$projectRoot = `$PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path `$projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty(`$projectRoot)) {
    `$projectRoot = Split-Path -Path `$projectRoot -Parent
}

if ([string]::IsNullOrEmpty(`$projectRoot) -or -not (Test-Path -Path (Join-Path -Path `$projectRoot -ChildPath ".git") -PathType Container)) {
    `$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path `$projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Chemin vers le rÃ©pertoire des logs
`$logPath = Join-Path -Path `$projectRoot -ChildPath `$LogPath
if (-not (Test-Path -Path `$logPath -PathType Container)) {
    Write-Warning "RÃ©pertoire des logs introuvable : `$logPath"
    exit 1
}

# Fonction pour arrÃªter un serveur MCP
function Stop-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Name,

        [Parameter(Mandatory = `$true)]
        [string]`$LogPath
    )

    # VÃ©rifier si le fichier PID existe
    `$pidFile = Join-Path -Path `$logPath -ChildPath "`$Name.pid"
    if (-not (Test-Path -Path `$pidFile)) {
        Write-Warning "Fichier PID introuvable : `$pidFile"
        return `$false
    }

    # Lire le PID
    try {
        `$pid = Get-Content -Path `$pidFile -Encoding UTF8
        `$pid = [int]`$pid
    } catch {
        Write-Warning "Erreur lors de la lecture du PID : `$_"
        return `$false
    }

    # ArrÃªter le processus
    try {
        `$process = Get-Process -Id `$pid -ErrorAction SilentlyContinue
        if (`$process) {
            `$process.Kill()
            Write-Host "Serveur MCP `$Name arrÃªtÃ© (PID: `$pid)." -ForegroundColor Green
            Remove-Item -Path `$pidFile -Force
            return `$true
        } else {
            Write-Warning "Processus introuvable : `$pid"
            Remove-Item -Path `$pidFile -Force
            return `$false
        }
    } catch {
        Write-Warning "Erreur lors de l'arrÃªt du serveur MCP `$Name : `$_"
        return `$false
    }
}

# RÃ©cupÃ©rer la liste des serveurs MCP
`$pidFiles = Get-ChildItem -Path `$logPath -Filter "*.pid" | Select-Object -ExpandProperty Name
`$servers = `$pidFiles | ForEach-Object { `$_ -replace "\.pid`$", "" }

if (-not `$servers) {
    Write-Warning "Aucun serveur MCP en cours d'exÃ©cution."
    exit 0
}

# ArrÃªter les serveurs MCP
`$stoppedServers = @()
foreach (`$server in `$servers) {
    Write-Host "ArrÃªt du serveur MCP `$server..." -ForegroundColor Cyan
    `$success = Stop-MCPServer -Name `$server -LogPath `$logPath
    if (`$success) {
        `$stoppedServers += `$server
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des serveurs MCP :" -ForegroundColor Cyan
Write-Host "Serveurs arrÃªtÃ©s : `$(`$stoppedServers -join ", ")" -ForegroundColor Green
`$failedServers = `$servers | Where-Object { `$_ -notin `$stoppedServers }
if (`$failedServers) {
    Write-Host "Serveurs non arrÃªtÃ©s : `$(`$failedServers -join ", ")" -ForegroundColor Red
}
"@

# Enregistrer le script d'arrÃªt
$stopScriptContent | Out-File -FilePath $stopScriptPath -Encoding UTF8
Write-Host "`nScript d'arrÃªt crÃ©Ã© : $stopScriptPath" -ForegroundColor Green
Write-Host "Pour arrÃªter les serveurs MCP, exÃ©cutez : .\stop-mcp-servers.ps1" -ForegroundColor Yellow
