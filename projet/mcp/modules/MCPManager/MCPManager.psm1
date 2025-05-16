#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des serveurs MCP (Model Context Protocol).
.DESCRIPTION
    Ce module fournit des fonctions pour détecter, configurer et gérer les serveurs MCP
    (Model Context Protocol) pour une intégration transparente avec les outils d'IA.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>

# Variables globales
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:ConfigPath = Join-Path -Path $script:ProjectRoot -ChildPath "config\mcp-config.json"
# Vérifier si le chemin existe, sinon utiliser un chemin alternatif
if (-not (Test-Path $script:ConfigPath)) {
    $script:ConfigPath = Join-Path -Path $script:ProjectRoot -ChildPath "..\config\mcp-config.json"
}
$script:DetectedServersPath = Join-Path -Path $script:ProjectRoot -ChildPath "monitoring\detected-servers.json"
$script:LogPath = Join-Path -Path $script:ProjectRoot -ChildPath "monitoring\logs\mcp-manager.log"

# Créer les répertoires nécessaires s'ils n'existent pas
$configDir = Split-Path -Parent $script:ConfigPath
if (-not (Test-Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
}

$logDir = Split-Path -Parent $script:LogPath
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$monitoringDir = Split-Path -Parent $script:DetectedServersPath
if (-not (Test-Path $monitoringDir)) {
    New-Item -Path $monitoringDir -ItemType Directory -Force | Out-Null
}

# Fonctions d'aide
function Write-MCPLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Afficher le message dans la console
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
        default { "White" }
    }

    Write-Host $logMessage -ForegroundColor $color

    # Écrire dans le fichier de log
    try {
        $logDir = Split-Path -Parent $script:LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
    }
}

function Get-MCPConfig {
    [CmdletBinding()]
    param ()

    try {
        if (Test-Path $script:ConfigPath) {
            $config = Get-Content -Path $script:ConfigPath -Raw | ConvertFrom-Json
            return $config
        } else {
            Write-MCPLog "Fichier de configuration non trouvé: $script:ConfigPath" -Level "ERROR"
            return $null
        }
    } catch {
        Write-MCPLog "Erreur lors de la lecture de la configuration: $_" -Level "ERROR"
        return $null
    }
}

function Save-MCPConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    try {
        $configDir = Split-Path -Parent $script:ConfigPath
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }

        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigPath
        Write-MCPLog "Configuration enregistrée: $script:ConfigPath" -Level "SUCCESS"
        return $true
    } catch {
        Write-MCPLog "Erreur lors de l'enregistrement de la configuration: $_" -Level "ERROR"
        return $false
    }
}

function Get-MCPProcesses {
    [CmdletBinding()]
    param ()

    $mcpProcesses = @()

    # Rechercher les processus MCP
    $processes = Get-Process | Where-Object {
        $_.ProcessName -like "*mcp*" -or
        $_.ProcessName -like "*node*" -or
        $_.ProcessName -like "*python*" -or
        $_.ProcessName -like "*gateway*"
    }

    foreach ($process in $processes) {
        # Vérifier si le processus est un serveur MCP
        $commandLine = $null
        try {
            $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        } catch {
            # Ignorer les erreurs
        }

        if ($commandLine -and ($commandLine -like "*mcp*" -or $commandLine -like "*modelcontextprotocol*")) {
            $mcpProcesses += @{
                Process     = $process
                CommandLine = $commandLine
                ServerName  = if ($commandLine -like "*filesystem*") { "filesystem" }
                elseif ($commandLine -like "*github*") { "github" }
                elseif ($commandLine -like "*gcp*") { "gcp" }
                elseif ($commandLine -like "*notion*") { "notion" }
                elseif ($commandLine -like "*gateway*") { "gateway" }
                else { "unknown" }
            }
        }
    }

    return $mcpProcesses
}

# Fonctions publiques
function Get-MCPServers {
    <#
    .SYNOPSIS
        Récupère la liste des serveurs MCP configurés.
    .DESCRIPTION
        Cette fonction récupère la liste des serveurs MCP configurés dans le fichier de configuration.
    .EXAMPLE
        Get-MCPServers
        Récupère la liste des serveurs MCP configurés.
    #>
    [CmdletBinding()]
    param ()

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return @()
    }

    $servers = @()

    foreach ($serverName in $config.mcpServers.PSObject.Properties.Name) {
        $serverConfig = $config.mcpServers.$serverName

        $servers += [PSCustomObject]@{
            Name       = $serverName
            Enabled    = $serverConfig.enabled
            Type       = if ($serverConfig.url) { "URL" } else { "Command" }
            URL        = $serverConfig.url
            Command    = $serverConfig.command
            Args       = $serverConfig.args
            ConfigPath = $serverConfig.configPath
        }
    }

    return $servers
}

function Get-MCPServerStatus {
    <#
    .SYNOPSIS
        Récupère l'état d'un serveur MCP.
    .DESCRIPTION
        Cette fonction récupère l'état d'un serveur MCP spécifique ou de tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP. Si non spécifié, l'état de tous les serveurs sera récupéré.
    .EXAMPLE
        Get-MCPServerStatus -ServerName filesystem
        Récupère l'état du serveur MCP filesystem.
    .EXAMPLE
        Get-MCPServerStatus
        Récupère l'état de tous les serveurs MCP.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName
    )

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return @()
    }

    $mcpProcesses = Get-MCPProcesses
    $results = @()

    foreach ($name in $config.mcpServers.PSObject.Properties.Name) {
        # Filtrer par serveur si spécifié
        if ($ServerName -and $name -ne $ServerName) {
            continue
        }

        $serverConfig = $config.mcpServers.$name

        # Ignorer les serveurs désactivés
        if ($serverConfig.enabled -eq $false) {
            continue
        }

        $status = [PSCustomObject]@{
            Name      = $name
            Status    = "Stopped"
            Process   = $null
            PID       = $null
            Memory    = $null
            CPU       = $null
            StartTime = $null
            Uptime    = $null
        }

        # Vérifier si le serveur est en cours d'exécution
        $serverProcess = $mcpProcesses | Where-Object { $_.ServerName -eq $name }

        if ($serverProcess) {
            $process = $serverProcess.Process

            $status.Status = "Running"
            $status.Process = $process
            $status.PID = $process.Id
            $status.Memory = $process.WorkingSet64
            $status.CPU = $process.CPU
            $status.StartTime = $process.StartTime
            $status.Uptime = (Get-Date) - $process.StartTime
        }

        $results += $status
    }

    return $results
}

function Start-MCPServer {
    <#
    .SYNOPSIS
        Démarre un serveur MCP.
    .DESCRIPTION
        Cette fonction démarre un serveur MCP spécifique ou tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP à démarrer. Si non spécifié, tous les serveurs seront démarrés.
    .PARAMETER Force
        Force le démarrage sans demander de confirmation.
    .EXAMPLE
        Start-MCPServer -ServerName filesystem
        Démarre le serveur MCP filesystem.
    .EXAMPLE
        Start-MCPServer
        Démarre tous les serveurs MCP.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return $false
    }

    $startedServers = 0
    $failedServers = 0

    foreach ($name in $config.mcpServers.PSObject.Properties.Name) {
        # Filtrer par serveur si spécifié
        if ($ServerName -and $name -ne $ServerName) {
            continue
        }

        $serverConfig = $config.mcpServers.$name

        # Ignorer les serveurs désactivés
        if ($serverConfig.enabled -eq $false) {
            Write-MCPLog "Serveur $name désactivé, ignoré." -Level "INFO"
            continue
        }

        # Vérifier si le serveur est déjà en cours d'exécution
        $serverStatus = Get-MCPServerStatus -ServerName $name

        if ($serverStatus.Status -eq "Running") {
            Write-MCPLog "Serveur $name déjà en cours d'exécution (PID: $($serverStatus.PID))." -Level "INFO"
            continue
        }

        # Démarrer le serveur
        if ($PSCmdlet.ShouldProcess($name, "Start MCP server")) {
            try {
                if ($serverConfig.url) {
                    # Serveur basé sur URL (HTTP/WebSocket)
                    Write-MCPLog "Le serveur $name est basé sur une URL: $($serverConfig.url)" -Level "INFO"
                    Write-MCPLog "Aucune action nécessaire pour le démarrage." -Level "SUCCESS"
                    $startedServers++
                } elseif ($serverConfig.command) {
                    # Serveur basé sur commande
                    $command = $serverConfig.command
                    $argString = $serverConfig.args -join " "
                    $envConfig = $serverConfig.env

                    # Préparer les variables d'environnement
                    $envVars = @{}
                    if ($envConfig) {
                        foreach ($key in $envConfig.PSObject.Properties.Name) {
                            $value = $envConfig.$key
                            $envVars[$key] = $value
                        }
                    }

                    # Démarrer le processus
                    Write-MCPLog "Démarrage du serveur $name..." -Level "INFO"

                    $processInfo = @{
                        FilePath               = $command
                        ArgumentList           = $argString
                        RedirectStandardOutput = $true
                        RedirectStandardError  = $true
                        UseShellExecute        = $false
                        CreateNoWindow         = $false
                    }

                    $process = Start-Process @processInfo -PassThru

                    Write-MCPLog "Serveur $name démarré avec PID: $($process.Id)" -Level "SUCCESS"
                    $startedServers++
                } else {
                    Write-MCPLog "Configuration invalide pour le serveur ${name} - ni URL ni commande spécifiée" -Level "ERROR"
                    $failedServers++
                }
            } catch {
                Write-MCPLog "Erreur lors du démarrage du serveur ${name} - $_" -Level "ERROR"
                $failedServers++
            }
        }
    }

    Write-MCPLog "Démarrage des serveurs MCP terminé. ${startedServers} serveurs démarrés, ${failedServers} échecs." -Level "INFO"

    return $startedServers -gt 0 -and $failedServers -eq 0
}

function Stop-MCPServer {
    <#
    .SYNOPSIS
        Arrête un serveur MCP.
    .DESCRIPTION
        Cette fonction arrête un serveur MCP spécifique ou tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP à arrêter. Si non spécifié, tous les serveurs seront arrêtés.
    .PARAMETER Force
        Force l'arrêt sans demander de confirmation.
    .EXAMPLE
        Stop-MCPServer -ServerName filesystem
        Arrête le serveur MCP filesystem.
    .EXAMPLE
        Stop-MCPServer
        Arrête tous les serveurs MCP.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $serverStatus = Get-MCPServerStatus -ServerName $ServerName

    if ($serverStatus.Count -eq 0) {
        if ($ServerName) {
            Write-MCPLog "Serveur MCP $ServerName non trouvé ou non en cours d'exécution." -Level "WARNING"
        } else {
            Write-MCPLog "Aucun serveur MCP en cours d'exécution." -Level "WARNING"
        }
        return $true
    }

    $stoppedServers = 0
    $failedServers = 0

    foreach ($server in $serverStatus) {
        if ($server.Status -ne "Running") {
            Write-MCPLog "Serveur $($server.Name) non en cours d'exécution." -Level "INFO"
            continue
        }

        if ($PSCmdlet.ShouldProcess($server.Name, "Stop MCP server")) {
            try {
                $server.Process | Stop-Process -Force
                Write-MCPLog "Serveur $($server.Name) arrêté avec succès." -Level "SUCCESS"
                $stoppedServers++
            } catch {
                Write-MCPLog "Erreur lors de l'arrêt du serveur $($server.Name) - $_" -Level "ERROR"
                $failedServers++
            }
        }
    }

    Write-MCPLog "Arrêt des serveurs MCP terminé. ${stoppedServers} serveurs arrêtés, ${failedServers} échecs." -Level "INFO"

    return $stoppedServers -gt 0 -and $failedServers -eq 0
}

function Restart-MCPServer {
    <#
    .SYNOPSIS
        Redémarre un serveur MCP.
    .DESCRIPTION
        Cette fonction redémarre un serveur MCP spécifique ou tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP à redémarrer. Si non spécifié, tous les serveurs seront redémarrés.
    .PARAMETER Force
        Force le redémarrage sans demander de confirmation.
    .EXAMPLE
        Restart-MCPServer -ServerName filesystem
        Redémarre le serveur MCP filesystem.
    .EXAMPLE
        Restart-MCPServer
        Redémarre tous les serveurs MCP.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($ServerName, "Restart MCP server")) {
        $stopResult = Stop-MCPServer -ServerName $ServerName -Force:$Force

        if (-not $stopResult) {
            Write-MCPLog "Erreur lors de l'arrêt du serveur ${ServerName}." -Level "ERROR"
            return $false
        }

        # Attendre que les processus soient complètement arrêtés
        Start-Sleep -Seconds 2

        $startResult = Start-MCPServer -ServerName $ServerName -Force:$Force

        if (-not $startResult) {
            Write-MCPLog "Erreur lors du démarrage du serveur ${ServerName}." -Level "ERROR"
            return $false
        }

        return $true
    }

    return $false
}

function Enable-MCPServer {
    <#
    .SYNOPSIS
        Active un serveur MCP.
    .DESCRIPTION
        Cette fonction active un serveur MCP spécifique ou tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP à activer. Si non spécifié, tous les serveurs seront activés.
    .EXAMPLE
        Enable-MCPServer -ServerName filesystem
        Active le serveur MCP filesystem.
    .EXAMPLE
        Enable-MCPServer
        Active tous les serveurs MCP.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName
    )

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return $false
    }

    $enabledServers = 0

    foreach ($name in $config.mcpServers.PSObject.Properties.Name) {
        # Filtrer par serveur si spécifié
        if ($ServerName -and $name -ne $ServerName) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($name, "Enable MCP server")) {
            # Activer le serveur
            $config.mcpServers.$name.enabled = $true
            $enabledServers++
        }
    }

    if ($enabledServers -gt 0) {
        $saveResult = Save-MCPConfig -Config $config

        if ($saveResult) {
            Write-MCPLog "$enabledServers serveurs MCP activés." -Level "SUCCESS"
            return $true
        } else {
            Write-MCPLog "Erreur lors de l'enregistrement de la configuration." -Level "ERROR"
            return $false
        }
    } else {
        Write-MCPLog "Aucun serveur MCP activé." -Level "WARNING"
        return $true
    }
}

function Disable-MCPServer {
    <#
    .SYNOPSIS
        Désactive un serveur MCP.
    .DESCRIPTION
        Cette fonction désactive un serveur MCP spécifique ou tous les serveurs.
    .PARAMETER ServerName
        Nom du serveur MCP à désactiver. Si non spécifié, tous les serveurs seront désactivés.
    .EXAMPLE
        Disable-MCPServer -ServerName filesystem
        Désactive le serveur MCP filesystem.
    .EXAMPLE
        Disable-MCPServer
        Désactive tous les serveurs MCP.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ServerName
    )

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return $false
    }

    $disabledServers = 0

    foreach ($name in $config.mcpServers.PSObject.Properties.Name) {
        # Filtrer par serveur si spécifié
        if ($ServerName -and $name -ne $ServerName) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($name, "Disable MCP server")) {
            # Désactiver le serveur
            $config.mcpServers.$name.enabled = $false
            $disabledServers++
        }
    }

    if ($disabledServers -gt 0) {
        $saveResult = Save-MCPConfig -Config $config

        if ($saveResult) {
            Write-MCPLog "$disabledServers serveurs MCP désactivés." -Level "SUCCESS"
            return $true
        } else {
            Write-MCPLog "Erreur lors de l'enregistrement de la configuration." -Level "ERROR"
            return $false
        }
    } else {
        Write-MCPLog "Aucun serveur MCP désactivé." -Level "WARNING"
        return $true
    }
}

function Invoke-MCPCommand {
    <#
    .SYNOPSIS
        Exécute une commande MCP.
    .DESCRIPTION
        Cette fonction exécute une commande sur un serveur MCP spécifique.
    .PARAMETER ServerName
        Nom du serveur MCP sur lequel exécuter la commande.
    .PARAMETER Command
        Commande à exécuter.
    .PARAMETER Arguments
        Arguments de la commande.
    .EXAMPLE
        Invoke-MCPCommand -ServerName filesystem -Command "listFiles" -Arguments @{path = "."}
        Liste les fichiers dans le répertoire courant.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerName,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Arguments = @{}
    )

    $config = Get-MCPConfig

    if ($null -eq $config) {
        return $null
    }

    # Vérifier si le serveur existe
    if (-not $config.mcpServers.PSObject.Properties.Name.Contains($ServerName)) {
        Write-MCPLog "Serveur MCP $ServerName non trouvé." -Level "ERROR"
        return $null
    }

    $serverConfig = $config.mcpServers.$ServerName

    # Vérifier si le serveur est activé
    if ($serverConfig.enabled -eq $false) {
        Write-MCPLog "Serveur MCP $ServerName désactivé." -Level "ERROR"
        return $null
    }

    # Vérifier si le serveur est en cours d'exécution
    $serverStatus = Get-MCPServerStatus -ServerName $ServerName

    if ($serverStatus.Status -ne "Running") {
        Write-MCPLog "Serveur MCP $ServerName non en cours d'exécution." -Level "ERROR"
        return $null
    }

    # Exécuter la commande
    try {
        # Ici, vous devriez implémenter la logique pour exécuter la commande sur le serveur MCP
        # Cela dépend du type de serveur et de la façon dont il expose ses commandes

        # Pour l'instant, nous simulons l'exécution
        Write-MCPLog "Exécution de la commande $Command sur le serveur $ServerName..." -Level "INFO"

        # Simuler un résultat
        $result = @{
            success   = $true
            result    = "Résultat de la commande $Command sur le serveur $ServerName"
            arguments = $Arguments
        }

        return $result
    } catch {
        Write-MCPLog "Erreur lors de l'exécution de la commande ${Command} sur le serveur ${ServerName} - $_" -Level "ERROR"
        return $null
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-MCPServers, Get-MCPServerStatus, Start-MCPServer, Stop-MCPServer, Restart-MCPServer, Enable-MCPServer, Disable-MCPServer, Invoke-MCPCommand
