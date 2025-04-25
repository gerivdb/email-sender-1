<#
.SYNOPSIS
    Script de surveillance du port et de l'API n8n (Partie 1 : Fonctions de base et paramètres).

.DESCRIPTION
    Ce script contient les fonctions de base et les paramètres pour la surveillance du port et de l'API n8n.
    Il est conçu pour être utilisé avec les autres parties du script de surveillance.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Paramètres communs à toutes les parties du script
$script:CommonParams = @{
    Hostname = "localhost"
    Port = 5678
    Protocol = "http"
    ApiKey = ""
    Endpoints = @(
        "/",
        "/healthz",
        "/api/v1/executions"
    )
    Timeout = 10  # Timeout en secondes
    RetryCount = 3
    RetryDelay = 2  # Délai entre les tentatives en secondes
    LogFile = "n8n/logs/n8n-status.log"
    ReportFile = "n8n/logs/n8n-status-report.json"
    HtmlReportFile = "n8n/logs/n8n-status-report.html"
    NotificationEnabled = $true
    NotificationScript = "n8n/automation/notification/send-notification.ps1"
    NotificationLevel = "WARNING"  # INFO, WARNING, ERROR
    HistoryLength = 10  # Nombre d'historiques à conserver
    HistoryFolder = "n8n/logs/history"
    AutoRestart = $false
    RestartScript = "n8n/automation/deployment/restart-n8n.ps1"
    RestartThreshold = 3  # Nombre d'échecs consécutifs avant redémarrage
}

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier de log
    Add-Content -Path $script:CommonParams.LogFile -Value $logMessage
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour envoyer une notification
function Send-StatusNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "WARNING",
        
        [Parameter(Mandatory=$false)]
        [string]$NotificationScript = $script:CommonParams.NotificationScript
    )
    
    # Vérifier si les notifications sont activées
    if (-not $script:CommonParams.NotificationEnabled) {
        Write-Log "Notifications désactivées. Message non envoyé: $Subject" -Level "INFO"
        return
    }
    
    # Vérifier si le niveau de notification est suffisant
    $levelValue = switch ($Level) {
        "INFO" { 1 }
        "WARNING" { 2 }
        "ERROR" { 3 }
        default { 0 }
    }
    
    $notificationLevelValue = switch ($script:CommonParams.NotificationLevel) {
        "INFO" { 1 }
        "WARNING" { 2 }
        "ERROR" { 3 }
        default { 0 }
    }
    
    if ($levelValue -lt $notificationLevelValue) {
        Write-Log "Niveau de notification insuffisant ($Level < $($script:CommonParams.NotificationLevel)). Message non envoyé: $Subject" -Level "INFO"
        return
    }
    
    # Vérifier si le script de notification existe
    if (-not (Test-Path -Path $NotificationScript)) {
        Write-Log "Script de notification non trouvé: $NotificationScript" -Level "ERROR"
        return
    }
    
    # Exécuter le script de notification
    try {
        & $NotificationScript -Subject $Subject -Message $Message -Level $Level
        Write-Log "Notification envoyée: $Subject" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors de l'envoi de la notification: $_" -Level "ERROR"
    }
}

# Fonction pour récupérer l'API Key depuis les fichiers de configuration
function Get-ApiKeyFromConfig {
    # Essayer de récupérer l'API Key depuis le fichier de configuration
    $configFile = Join-Path -Path (Get-Location) -ChildPath "n8n/core/n8n-config.json"
    if (Test-Path -Path $configFile) {
        try {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
            if ($config.security -and $config.security.apiKey -and $config.security.apiKey.value) {
                return $config.security.apiKey.value
            }
        } catch {
            Write-Log "Erreur lors de la lecture du fichier de configuration: $_" -Level "ERROR"
        }
    }
    
    # Essayer de récupérer l'API Key depuis le fichier .env
    $envFile = Join-Path -Path (Get-Location) -ChildPath "n8n/.env"
    if (Test-Path -Path $envFile) {
        try {
            $envContent = Get-Content -Path $envFile
            foreach ($line in $envContent) {
                if ($line -match "^N8N_API_KEY=(.+)$") {
                    return $matches[1]
                }
            }
        } catch {
            Write-Log "Erreur lors de la lecture du fichier .env: $_" -Level "ERROR"
        }
    }
    
    return ""
}

# Fonction pour vérifier si un dossier existe et le créer si nécessaire
function Ensure-FolderExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )
    
    if (-not (Test-Path -Path $FolderPath)) {
        try {
            New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
            Write-Log "Dossier créé: $FolderPath" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de la création du dossier $FolderPath : $_" -Level "ERROR"
            return $false
        }
    }
    
    return $true
}

# Exporter les fonctions et variables pour les autres parties du script
Export-ModuleMember -Function Write-Log, Send-StatusNotification, Get-ApiKeyFromConfig, Ensure-FolderExists -Variable CommonParams
