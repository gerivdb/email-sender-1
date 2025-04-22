<#
.SYNOPSIS
    Script de redémarrage de n8n.

.DESCRIPTION
    Ce script arrête et redémarre le service n8n.

.PARAMETER LogFile
    Fichier de log pour le redémarrage (par défaut: n8n/logs/restart-n8n.log).

.PARAMETER StartScript
    Script à utiliser pour démarrer n8n (par défaut: n8n/automation/deployment/start-n8n.ps1).

.PARAMETER StopScript
    Script à utiliser pour arrêter n8n (par défaut: n8n/automation/deployment/stop-n8n.ps1).

.PARAMETER WaitBeforeStart
    Temps d'attente en secondes entre l'arrêt et le démarrage (par défaut: 5).

.PARAMETER NotificationEnabled
    Indique si les notifications doivent être envoyées (par défaut: $true).

.PARAMETER NotificationScript
    Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1).

.EXAMPLE
    .\restart-n8n.ps1

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/restart-n8n.log",
    
    [Parameter(Mandatory=$false)]
    [string]$StartScript = "n8n/automation/deployment/start-n8n.ps1",
    
    [Parameter(Mandatory=$false)]
    [string]$StopScript = "n8n/automation/deployment/stop-n8n.ps1",
    
    [Parameter(Mandatory=$false)]
    [int]$WaitBeforeStart = 5,
    
    [Parameter(Mandatory=$false)]
    [bool]$NotificationEnabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationScript = "n8n/automation/notification/send-notification.ps1"
)

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
    Add-Content -Path $LogFile -Value $logMessage
    
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
function Send-RestartNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "WARNING",
        
        [Parameter(Mandatory=$false)]
        [string]$NotificationScript = $NotificationScript
    )
    
    # Vérifier si les notifications sont activées
    if (-not $NotificationEnabled) {
        Write-Log "Notifications désactivées. Message non envoyé: $Subject" -Level "INFO"
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

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Afficher les informations de démarrage
Write-Log "=== Redémarrage de n8n ===" -Level "INFO"
Write-Log "Script de démarrage: $StartScript" -Level "INFO"
Write-Log "Script d'arrêt: $StopScript" -Level "INFO"
Write-Log "Temps d'attente: $WaitBeforeStart secondes" -Level "INFO"

# Vérifier si les scripts existent
if (-not (Test-Path -Path $StopScript)) {
    Write-Log "Script d'arrêt non trouvé: $StopScript" -Level "ERROR"
    exit 1
}

if (-not (Test-Path -Path $StartScript)) {
    Write-Log "Script de démarrage non trouvé: $StartScript" -Level "ERROR"
    exit 1
}

# Arrêter n8n
Write-Log "Arrêt de n8n..." -Level "INFO"
try {
    & $StopScript
    Write-Log "n8n arrêté avec succès" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de l'arrêt de n8n: $_" -Level "ERROR"
    
    # Envoyer une notification
    if ($NotificationEnabled) {
        Send-RestartNotification -Subject "Échec de l'arrêt de n8n" -Message "Erreur lors de l'arrêt de n8n: $_" -Level "ERROR"
    }
    
    exit 1
}

# Attendre avant de démarrer
Write-Log "Attente de $WaitBeforeStart secondes avant le démarrage..." -Level "INFO"
Start-Sleep -Seconds $WaitBeforeStart

# Démarrer n8n
Write-Log "Démarrage de n8n..." -Level "INFO"
try {
    & $StartScript
    Write-Log "n8n démarré avec succès" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors du démarrage de n8n: $_" -Level "ERROR"
    
    # Envoyer une notification
    if ($NotificationEnabled) {
        Send-RestartNotification -Subject "Échec du démarrage de n8n" -Message "Erreur lors du démarrage de n8n: $_" -Level "ERROR"
    }
    
    exit 1
}

# Envoyer une notification
if ($NotificationEnabled) {
    Send-RestartNotification -Subject "n8n redémarré avec succès" -Message "n8n a été redémarré avec succès." -Level "INFO"
}

Write-Log "=== Redémarrage de n8n terminé ===" -Level "SUCCESS"
exit 0
