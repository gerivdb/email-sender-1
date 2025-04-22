<#
.SYNOPSIS
    Script de test structurel pour n8n (Partie 1 : Fonctions de base et paramètres).

.DESCRIPTION
    Ce script contient les fonctions de base et les paramètres pour le test structurel de n8n.
    Il est conçu pour être utilisé avec les autres parties du script de test structurel.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

# Paramètres communs à toutes les parties du script
$script:CommonParams = @{
    N8nRootFolder = "n8n"
    WorkflowFolder = "n8n/data/.n8n/workflows"
    ConfigFolder = "n8n/config"
    LogFolder = "n8n/logs"
    LogFile = "n8n/logs/structure-test.log"
    ReportFile = "n8n/logs/structure-test-report.json"
    HtmlReportFile = "n8n/logs/structure-test-report.html"
    TestLevel = 2  # 1: Basic, 2: Standard, 3: Detailed
    FixIssues = $false
    NotificationEnabled = $true
    NotificationScript = "n8n/automation/notification/send-notification.ps1"
    NotificationLevel = "WARNING"  # INFO, WARNING, ERROR
}

# Structure attendue pour n8n
$script:ExpectedStructure = @{
    Folders = @(
        "n8n/automation",
        "n8n/automation/deployment",
        "n8n/automation/monitoring",
        "n8n/automation/diagnostics",
        "n8n/automation/notification",
        "n8n/config",
        "n8n/core",
        "n8n/core/workflows",
        "n8n/core/workflows/local",
        "n8n/data",
        "n8n/data/.n8n",
        "n8n/data/.n8n/workflows",
        "n8n/docs",
        "n8n/docs/architecture",
        "n8n/logs"
    )
    Files = @(
        "n8n/config/notification-config.json",
        "n8n/core/n8n-config.json",
        "n8n/.env"
    )
    Scripts = @(
        "n8n/automation/deployment/start-n8n.ps1",
        "n8n/automation/deployment/stop-n8n.ps1",
        "n8n/automation/monitoring/check-n8n-status.ps1",
        "n8n/automation/notification/send-notification.ps1"
    )
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
function Send-TestNotification {
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

# Fonction pour créer un dossier s'il n'existe pas
function Ensure-FolderExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory=$false)]
        [bool]$CreateIfMissing = $true
    )
    
    if (-not (Test-Path -Path $FolderPath)) {
        if ($CreateIfMissing) {
            try {
                New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier créé: $FolderPath" -Level "SUCCESS"
                return $true
            } catch {
                Write-Log "Erreur lors de la création du dossier $FolderPath : $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Dossier manquant: $FolderPath" -Level "WARNING"
            return $false
        }
    }
    
    return $true
}

# Fonction pour vérifier si un fichier existe
function Test-FileExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [bool]$CreateIfMissing = $false,
        
        [Parameter(Mandatory=$false)]
        [string]$DefaultContent = ""
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        if ($CreateIfMissing -and -not [string]::IsNullOrEmpty($DefaultContent)) {
            try {
                # Créer le dossier parent s'il n'existe pas
                $parentFolder = Split-Path -Path $FilePath -Parent
                Ensure-FolderExists -FolderPath $parentFolder -CreateIfMissing $true | Out-Null
                
                # Créer le fichier avec le contenu par défaut
                Set-Content -Path $FilePath -Value $DefaultContent -Encoding UTF8
                Write-Log "Fichier créé avec contenu par défaut: $FilePath" -Level "SUCCESS"
                return $true
            } catch {
                Write-Log "Erreur lors de la création du fichier $FilePath : $_" -Level "ERROR"
                return $false
            }
        } else {
            Write-Log "Fichier manquant: $FilePath" -Level "WARNING"
            return $false
        }
    }
    
    return $true
}

# Exporter les fonctions et variables pour les autres parties du script
Export-ModuleMember -Function Write-Log, Send-TestNotification, Ensure-FolderExists, Test-FileExists -Variable CommonParams, ExpectedStructure
