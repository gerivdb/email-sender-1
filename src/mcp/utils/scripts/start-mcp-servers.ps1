<#
.SYNOPSIS
    Démarre les serveurs MCP configurés.

.DESCRIPTION
    Ce script démarre les serveurs MCP configurés dans le fichier de configuration.
    Il crée les répertoires nécessaires et lance les serveurs en arrière-plan.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration MCP. Par défaut, il utilise 'projet/config/mcp-config.json'.

.PARAMETER LogPath
    Chemin vers le répertoire des logs. Par défaut, il utilise 'logs/mcp'.

.EXAMPLE
    .\start-mcp-servers.ps1
    .\start-mcp-servers.ps1 -ConfigPath "chemin/vers/config.json" -LogPath "chemin/vers/logs"
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = "projet/config/mcp-config.json",
    
    [Parameter()]
    [string]$LogPath = "logs/mcp"
)

# Obtenir le chemin absolu du répertoire courant
$currentDir = Get-Location
Write-Host "Répertoire courant : $currentDir"

# Vérifier si le fichier de configuration existe
$configFullPath = Join-Path -Path $currentDir -ChildPath $ConfigPath
if (-not (Test-Path -Path $configFullPath)) {
    Write-Error "Le fichier de configuration n'existe pas : $configFullPath"
    exit 1
}

# Créer le répertoire des logs s'il n'existe pas
$logFullPath = Join-Path -Path $currentDir -ChildPath $LogPath
if (-not (Test-Path -Path $logFullPath)) {
    New-Item -Path $logFullPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire des logs créé : $logFullPath"
}

# Lire le fichier de configuration
try {
    $config = Get-Content -Path $configFullPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors de la lecture du fichier de configuration : $_"
    exit 1
}

# Vérifier si les serveurs MCP sont activés
if (-not $config.enabled) {
    Write-Warning "Les serveurs MCP sont désactivés dans la configuration."
    exit 0
}

# Fonction pour démarrer un serveur MCP
function Start-MCPServer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerType,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ServerConfig,
        
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    if (-not $ServerConfig.enabled) {
        Write-Host "Le serveur MCP $ServerType est désactivé dans la configuration."
        return
    }
    
    $serverScriptPath = Join-Path -Path $currentDir -ChildPath "src/mcp/servers/$ServerType/server.js"
    if (-not (Test-Path -Path $serverScriptPath)) {
        Write-Warning "Le script du serveur $ServerType n'existe pas : $serverScriptPath"
        return
    }
    
    $logFilePath = Join-Path -Path $LogPath -ChildPath "$ServerType.log"
    
    # Démarrer le serveur en arrière-plan
    $processArgs = @{
        FilePath = "node"
        ArgumentList = $serverScriptPath, "--port", $ServerConfig.port, "--host", $ServerConfig.host, "--apiKey", $ServerConfig.apiKey, "--logLevel", $ServerConfig.logLevel
        RedirectStandardOutput = $logFilePath
        RedirectStandardError = "$logFilePath.error"
        NoNewWindow = $true
        PassThru = $true
    }
    
    try {
        $process = Start-Process @processArgs
        Write-Host "Serveur MCP $ServerType démarré sur $($ServerConfig.host):$($ServerConfig.port) (PID: $($process.Id))"
        
        # Attendre que le serveur soit prêt
        $maxWaitTime = 30 # secondes
        $startTime = Get-Date
        $serverReady = $false
        
        while (-not $serverReady -and ((Get-Date) - $startTime).TotalSeconds -lt $maxWaitTime) {
            if (Test-Path -Path $logFilePath) {
                $logContent = Get-Content -Path $logFilePath -Tail 10
                if ($logContent -match "Server running at") {
                    $serverReady = $true
                    Write-Host "Serveur MCP $ServerType prêt."
                }
            }
            
            Start-Sleep -Seconds 1
        }
        
        if (-not $serverReady) {
            Write-Warning "Le serveur MCP $ServerType n'est pas prêt après $maxWaitTime secondes."
        }
        
        return $process
    } catch {
        Write-Error "Erreur lors du démarrage du serveur MCP $ServerType : $_"
        return $null
    }
}

# Démarrer les serveurs MCP configurés
$processes = @{}

# Serveur filesystem
if ($config.servers.filesystem.enabled) {
    $processes["filesystem"] = Start-MCPServer -ServerType "filesystem" -ServerConfig $config.servers.filesystem -LogPath $logFullPath
}

# Serveur github
if ($config.servers.github.enabled) {
    $processes["github"] = Start-MCPServer -ServerType "github" -ServerConfig $config.servers.github -LogPath $logFullPath
}

# Serveur gcp
if ($config.servers.gcp.enabled) {
    $processes["gcp"] = Start-MCPServer -ServerType "gcp" -ServerConfig $config.servers.gcp -LogPath $logFullPath
}

# Afficher un résumé
Write-Host "`nRésumé des serveurs MCP :"
foreach ($serverType in $processes.Keys) {
    $process = $processes[$serverType]
    if ($null -ne $process) {
        Write-Host "- $serverType : En cours d'exécution (PID: $($process.Id))"
    } else {
        Write-Host "- $serverType : Non démarré"
    }
}

Write-Host "`nLes serveurs MCP sont démarrés. Utilisez 'Stop-AugmentMCPServers' pour les arrêter."
