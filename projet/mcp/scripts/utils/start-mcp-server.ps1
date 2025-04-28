#Requires -Version 5.1
<#
.SYNOPSIS
    Script principal pour démarrer tous les serveurs MCP.
.DESCRIPTION
    Ce script démarre tous les serveurs MCP configurés ou un serveur spécifique.
.PARAMETER Server
    Nom du serveur à démarrer. Si non spécifié, tous les serveurs seront démarrés.
.PARAMETER ConfigPath
    Chemin du fichier de configuration MCP. Par défaut, "config/mcp-config.json".
.PARAMETER Force
    Force le démarrage sans demander de confirmation.
.EXAMPLE
    .\start-mcp-server.ps1
    Démarre tous les serveurs MCP configurés.
.EXAMPLE
    .\start-mcp-server.ps1 -Server filesystem
    Démarre uniquement le serveur MCP filesystem.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$Server,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/mcp-config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Start-McpServer {
    param (
        [string]$ServerName,
        [PSCustomObject]$ServerConfig
    )
    
    Write-Log "Démarrage du serveur MCP $ServerName..." -Level "INFO"
    
    try {
        if ($ServerConfig.url) {
            # Serveur basé sur URL (HTTP/WebSocket)
            Write-Log "Le serveur $ServerName est basé sur une URL: $($ServerConfig.url)" -Level "INFO"
            Write-Log "Aucune action nécessaire pour le démarrage." -Level "SUCCESS"
            return $true
        }
        elseif ($ServerConfig.command) {
            # Serveur basé sur commande
            $command = $ServerConfig.command
            $args = $ServerConfig.args -join " "
            $env = $ServerConfig.env
            
            # Préparer les variables d'environnement
            $envVars = ""
            if ($env) {
                foreach ($key in $env.PSObject.Properties.Name) {
                    $value = $env.$key
                    $envVars += "$key=$value "
                }
            }
            
            # Construire la commande complète
            $fullCommand = if ($envVars) { "$envVars $command $args" } else { "$command $args" }
            
            # Démarrer le processus
            Write-Log "Exécution de la commande: $fullCommand" -Level "INFO"
            
            $processInfo = @{
                FileName = $command
                Arguments = $args
                RedirectStandardOutput = $true
                RedirectStandardError = $true
                UseShellExecute = $false
                CreateNoWindow = $false
            }
            
            $process = Start-Process @processInfo -PassThru
            
            Write-Log "Serveur $ServerName démarré avec PID: $($process.Id)" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "Configuration invalide pour le serveur $ServerName: ni URL ni commande spécifiée" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors du démarrage du serveur $ServerName: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Démarrage des serveurs MCP..." -Level "TITLE"
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path $configPath)) {
        Write-Log "Fichier de configuration non trouvé: $configPath" -Level "ERROR"
        exit 1
    }
    
    # Charger la configuration
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $servers = $config.mcpServers
    
    # Vérifier si des serveurs sont configurés
    if (-not $servers -or $servers.PSObject.Properties.Count -eq 0) {
        Write-Log "Aucun serveur MCP configuré dans $configPath" -Level "WARNING"
        exit 0
    }
    
    # Démarrer les serveurs
    $startedServers = 0
    $failedServers = 0
    
    if ($Server) {
        # Démarrer un serveur spécifique
        if ($servers.PSObject.Properties.Name -contains $Server) {
            $serverConfig = $servers.$Server
            
            if ($PSCmdlet.ShouldProcess($Server, "Start MCP server")) {
                $result = Start-McpServer -ServerName $Server -ServerConfig $serverConfig
                if ($result) {
                    $startedServers++
                }
                else {
                    $failedServers++
                }
            }
        }
        else {
            Write-Log "Serveur MCP non trouvé: $Server" -Level "ERROR"
            Write-Log "Serveurs disponibles: $($servers.PSObject.Properties.Name -join ', ')" -Level "INFO"
            exit 1
        }
    }
    else {
        # Démarrer tous les serveurs
        foreach ($serverName in $servers.PSObject.Properties.Name) {
            $serverConfig = $servers.$serverName
            
            # Ignorer les serveurs désactivés
            if ($serverConfig.enabled -eq $false) {
                Write-Log "Serveur $serverName désactivé, ignoré." -Level "INFO"
                continue
            }
            
            if ($PSCmdlet.ShouldProcess($serverName, "Start MCP server")) {
                $result = Start-McpServer -ServerName $serverName -ServerConfig $serverConfig
                if ($result) {
                    $startedServers++
                }
                else {
                    $failedServers++
                }
            }
        }
    }
    
    Write-Log "Démarrage des serveurs MCP terminé. $startedServers serveurs démarrés, $failedServers échecs." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors du démarrage des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
