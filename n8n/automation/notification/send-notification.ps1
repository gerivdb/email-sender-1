<#
.SYNOPSIS
    Script d'envoi de notifications.

.DESCRIPTION
    Ce script envoie des notifications via différents canaux (email, Teams, etc.).

.PARAMETER Subject
    Sujet de la notification.

.PARAMETER Message
    Message de la notification.

.PARAMETER Level
    Niveau de la notification (INFO, WARNING, ERROR) (par défaut: INFO).

.PARAMETER Channel
    Canal de notification à utiliser (Email, Teams, Slack, All) (par défaut: All).

.PARAMETER ConfigFile
    Fichier de configuration pour les notifications (par défaut: n8n/config/notification-config.json).

.EXAMPLE
    .\send-notification.ps1 -Subject "Test" -Message "Ceci est un test" -Level "INFO"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Subject,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("INFO", "WARNING", "ERROR")]
    [string]$Level = "INFO",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Email", "Teams", "Slack", "All")]
    [string]$Channel = "All",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "n8n/config/notification-config.json"
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

# Fonction pour charger la configuration
function Get-NotificationConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigFile)) {
        Write-Log "Le fichier de configuration n'existe pas: $ConfigFile" -Level "ERROR"
        
        # Créer une configuration par défaut
        $defaultConfig = @{
            Email = @{
                Enabled = $false
                SmtpServer = "smtp.example.com"
                SmtpPort = 587
                UseSsl = $true
                Sender = "n8n@example.com"
                Recipients = @("admin@example.com")
                Username = ""
                Password = ""
            }
            Teams = @{
                Enabled = $false
                WebhookUrl = "https://outlook.office.com/webhook/..."
            }
            Slack = @{
                Enabled = $false
                WebhookUrl = "https://hooks.slack.com/services/..."
            }
        }
        
        # Créer le dossier de configuration s'il n'existe pas
        $configFolder = Split-Path -Path $ConfigFile -Parent
        if (-not (Test-Path -Path $configFolder)) {
            New-Item -Path $configFolder -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer la configuration par défaut
        $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Encoding utf8
        
        Write-Log "Configuration par défaut créée: $ConfigFile" -Level "WARNING"
        return $defaultConfig
    }
    
    # Charger la configuration
    try {
        $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
        return $config
    } catch {
        Write-Log "Erreur lors du chargement de la configuration: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour envoyer une notification par email
function Send-EmailNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    # Vérifier si les notifications par email sont activées
    if (-not $Config.Email.Enabled) {
        Write-Log "Les notifications par email sont désactivées." -Level "INFO"
        return $false
    }
    
    try {
        # Préparer les paramètres de l'email
        $emailParams = @{
            SmtpServer = $Config.Email.SmtpServer
            Port = $Config.Email.SmtpPort
            From = $Config.Email.Sender
            To = $Config.Email.Recipients
            Subject = "[$Level] $Subject"
            Body = $Message
            BodyAsHtml = $false
            UseSsl = $Config.Email.UseSsl
        }
        
        # Ajouter les informations d'authentification si nécessaire
        if (-not [string]::IsNullOrEmpty($Config.Email.Username) -and -not [string]::IsNullOrEmpty($Config.Email.Password)) {
            $securePassword = ConvertTo-SecureString $Config.Email.Password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($Config.Email.Username, $securePassword)
            $emailParams.Credential = $credentials
        }
        
        # Envoyer l'email
        Send-MailMessage @emailParams
        
        Write-Log "Notification par email envoyée: $Subject" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'envoi de la notification par email: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour envoyer une notification Teams
function Send-TeamsNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    # Vérifier si les notifications Teams sont activées
    if (-not $Config.Teams.Enabled) {
        Write-Log "Les notifications Teams sont désactivées." -Level "INFO"
        return $false
    }
    
    try {
        # Préparer la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "0076D7" }
            "WARNING" { "FFC107" }
            "ERROR" { "D9534F" }
            default { "0076D7" }
        }
        
        # Préparer le payload
        $payload = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "themeColor" = $color
            "summary" = $Subject
            "sections" = @(
                @{
                    "activityTitle" = "[$Level] $Subject"
                    "activitySubtitle" = "Notification n8n"
                    "activityImage" = "https://n8n.io/favicon.ico"
                    "facts" = @(
                        @{
                            "name" = "Niveau"
                            "value" = $Level
                        },
                        @{
                            "name" = "Date"
                            "value" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                        }
                    )
                    "text" = $Message
                }
            )
        }
        
        # Convertir le payload en JSON
        $payloadJson = $payload | ConvertTo-Json -Depth 10
        
        # Envoyer la notification
        Invoke-RestMethod -Uri $Config.Teams.WebhookUrl -Method Post -Body $payloadJson -ContentType "application/json"
        
        Write-Log "Notification Teams envoyée: $Subject" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'envoi de la notification Teams: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour envoyer une notification Slack
function Send-SlackNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    # Vérifier si les notifications Slack sont activées
    if (-not $Config.Slack.Enabled) {
        Write-Log "Les notifications Slack sont désactivées." -Level "INFO"
        return $false
    }
    
    try {
        # Préparer la couleur en fonction du niveau
        $color = switch ($Level) {
            "INFO" { "good" }
            "WARNING" { "warning" }
            "ERROR" { "danger" }
            default { "good" }
        }
        
        # Préparer le payload
        $payload = @{
            "attachments" = @(
                @{
                    "fallback" = "[$Level] $Subject"
                    "color" = $color
                    "pretext" = "Notification n8n"
                    "author_name" = "n8n"
                    "author_icon" = "https://n8n.io/favicon.ico"
                    "title" = "[$Level] $Subject"
                    "text" = $Message
                    "fields" = @(
                        @{
                            "title" = "Niveau"
                            "value" = $Level
                            "short" = $true
                        },
                        @{
                            "title" = "Date"
                            "value" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                            "short" = $true
                        }
                    )
                    "footer" = "n8n Notification System"
                    "ts" = [Math]::Floor([decimal](Get-Date -UFormat "%s"))
                }
            )
        }
        
        # Convertir le payload en JSON
        $payloadJson = $payload | ConvertTo-Json -Depth 10
        
        # Envoyer la notification
        Invoke-RestMethod -Uri $Config.Slack.WebhookUrl -Method Post -Body $payloadJson -ContentType "application/json"
        
        Write-Log "Notification Slack envoyée: $Subject" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'envoi de la notification Slack: $_" -Level "ERROR"
        return $false
    }
}

# Charger la configuration
$config = Get-NotificationConfig -ConfigFile $ConfigFile

if ($null -eq $config) {
    Write-Log "Impossible de charger la configuration. Les notifications ne seront pas envoyées." -Level "ERROR"
    exit 1
}

# Envoyer les notifications selon le canal spécifié
$success = $false

if ($Channel -eq "All" -or $Channel -eq "Email") {
    $emailSuccess = Send-EmailNotification -Subject $Subject -Message $Message -Level $Level -Config $config
    $success = $success -or $emailSuccess
}

if ($Channel -eq "All" -or $Channel -eq "Teams") {
    $teamsSuccess = Send-TeamsNotification -Subject $Subject -Message $Message -Level $Level -Config $config
    $success = $success -or $teamsSuccess
}

if ($Channel -eq "All" -or $Channel -eq "Slack") {
    $slackSuccess = Send-SlackNotification -Subject $Subject -Message $Message -Level $Level -Config $config
    $success = $success -or $slackSuccess
}

# Afficher le résultat
if ($success) {
    Write-Log "Notification envoyée avec succès: $Subject" -Level "SUCCESS"
    exit 0
} else {
    Write-Log "Échec de l'envoi de la notification: $Subject" -Level "ERROR"
    exit 1
}
