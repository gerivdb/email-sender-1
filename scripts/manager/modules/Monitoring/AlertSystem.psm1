# Module de système d'alertes pour le Script Manager
# Ce module gère les alertes pour les problèmes détectés dans les scripts
# Author: Script Manager
# Version: 1.0
# Tags: monitoring, alerts, scripts

function Initialize-AlertSystem {
    <#
    .SYNOPSIS
        Initialise le système d'alertes
    .DESCRIPTION
        Configure le système d'alertes pour les scripts
    .PARAMETER Inventory
        Objet d'inventaire des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer les alertes
    .EXAMPLE
        Initialize-AlertSystem -Inventory $inventory -OutputPath "monitoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Inventory,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier des alertes
    $AlertsPath = Join-Path -Path $OutputPath -ChildPath "alerts"
    if (-not (Test-Path -Path $AlertsPath)) {
        New-Item -ItemType Directory -Path $AlertsPath -Force | Out-Null
    }
    
    Write-Host "Initialisation du système d'alertes..." -ForegroundColor Cyan
    
    # Créer le fichier de configuration des alertes
    $AlertConfigPath = Join-Path -Path $AlertsPath -ChildPath "alert_config.json"
    $AlertConfig = @{
        Enabled = $true
        NotificationMethods = @{
            Console = $true
            Email = $false
            Teams = $false
            Slack = $false
        }
        EmailConfig = @{
            SmtpServer = ""
            SmtpPort = 587
            UseSsl = $true
            FromAddress = ""
            ToAddress = @()
            Credentials = @{
                Username = ""
                Password = ""  # Note: Stocker les mots de passe en clair n'est pas recommandé
            }
        }
        TeamsConfig = @{
            WebhookUrl = ""
        }
        SlackConfig = @{
            WebhookUrl = ""
        }
        AlertLevels = @{
            Info = $true
            Warning = $true
            Error = $true
            Critical = $true
        }
        AlertRules = @(
            @{
                Name = "Erreur de syntaxe"
                Description = "Détecte les erreurs de syntaxe dans les scripts"
                Enabled = $true
                Level = "Critical"
                Condition = "SyntaxError"
            },
            @{
                Name = "Chemin absolu"
                Description = "Détecte l'utilisation de chemins absolus dans les scripts"
                Enabled = $true
                Level = "Warning"
                Condition = "AbsolutePath"
            },
            @{
                Name = "Comparaison $null incorrecte"
                Description = "Détecte les comparaisons avec $null du mauvais côté"
                Enabled = $true
                Level = "Warning"
                Condition = "NullComparison"
            },
            @{
                Name = "Script modifié"
                Description = "Détecte les modifications de scripts"
                Enabled = $true
                Level = "Info"
                Condition = "ScriptModified"
            },
            @{
                Name = "Script supprimé"
                Description = "Détecte les suppressions de scripts"
                Enabled = $true
                Level = "Error"
                Condition = "ScriptDeleted"
            }
        )
    }
    
    # Enregistrer la configuration des alertes
    $AlertConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $AlertConfigPath
    
    Write-Host "  Configuration des alertes créée: $AlertConfigPath" -ForegroundColor Green
    
    # Créer le fichier d'historique des alertes
    $AlertHistoryPath = Join-Path -Path $AlertsPath -ChildPath "alert_history.json"
    $AlertHistory = @{
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Alerts = @()
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $AlertHistoryPath -Value $AlertHistory
    
    Write-Host "  Historique des alertes initialisé: $AlertHistoryPath" -ForegroundColor Green
    
    # Créer le script de gestion des alertes
    $AlertScriptPath = Join-Path -Path $AlertsPath -ChildPath "Send-Alert.ps1"
    $AlertScriptContent = @"
<#
.SYNOPSIS
    Envoie une alerte pour un problème détecté
.DESCRIPTION
    Envoie une alerte via les méthodes configurées (console, email, Teams, Slack)
.PARAMETER AlertName
    Nom de l'alerte
.PARAMETER Level
    Niveau de l'alerte (Info, Warning, Error, Critical)
.PARAMETER Message
    Message de l'alerte
.PARAMETER ScriptPath
    Chemin du script concerné
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration des alertes
.PARAMETER HistoryPath
    Chemin vers le fichier d'historique des alertes
.EXAMPLE
    .\Send-Alert.ps1 -AlertName "Erreur de syntaxe" -Level "Critical" -Message "Erreur de syntaxe dans le script" -ScriptPath "scripts\myscript.ps1" -ConfigPath "monitoring\alerts\alert_config.json" -HistoryPath "monitoring\alerts\alert_history.json"
#>

param (
    [Parameter(Mandatory=`$true)]
    [string]`$AlertName,
    
    [Parameter(Mandatory=`$true)]
    [ValidateSet("Info", "Warning", "Error", "Critical")]
    [string]`$Level,
    
    [Parameter(Mandatory=`$true)]
    [string]`$Message,
    
    [Parameter(Mandatory=`$true)]
    [string]`$ScriptPath,
    
    [Parameter(Mandatory=`$true)]
    [string]`$ConfigPath,
    
    [Parameter(Mandatory=`$true)]
    [string]`$HistoryPath
)

# Vérifier si les fichiers existent
if (-not (Test-Path -Path `$ConfigPath)) {
    Write-Error "Fichier de configuration non trouvé: `$ConfigPath"
    exit 1
}

if (-not (Test-Path -Path `$HistoryPath)) {
    Write-Error "Fichier d'historique non trouvé: `$HistoryPath"
    exit 1
}

# Charger la configuration et l'historique
try {
    `$Config = Get-Content -Path `$ConfigPath -Raw | ConvertFrom-Json
    `$History = Get-Content -Path `$HistoryPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des fichiers: `$_"
    exit 1
}

# Vérifier si les alertes sont activées
if (-not `$Config.Enabled) {
    Write-Warning "Le système d'alertes est désactivé"
    exit 0
}

# Vérifier si le niveau d'alerte est activé
if (-not `$Config.AlertLevels.(`$Level)) {
    Write-Warning "Les alertes de niveau `$Level sont désactivées"
    exit 0
}

# Créer l'objet d'alerte
`$Alert = [PSCustomObject]@{
    Name = `$AlertName
    Level = `$Level
    Message = `$Message
    ScriptPath = `$ScriptPath
    ScriptName = Split-Path -Leaf `$ScriptPath
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Acknowledged = `$false
}

# Ajouter l'alerte à l'historique
`$History.Alerts += `$Alert
`$History.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Enregistrer l'historique mis à jour
`$History | ConvertTo-Json -Depth 10 | Set-Content -Path `$HistoryPath

# Envoyer l'alerte via les méthodes configurées
if (`$Config.NotificationMethods.Console) {
    # Afficher l'alerte dans la console
    `$Color = switch (`$Level) {
        "Info" { "Cyan" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Critical" { "DarkRed" }
    }
    
    Write-Host "ALERTE [`$Level] - `$AlertName" -ForegroundColor `$Color
    Write-Host "Script: `$ScriptPath" -ForegroundColor `$Color
    Write-Host "Message: `$Message" -ForegroundColor `$Color
    Write-Host "Timestamp: `$(`$Alert.Timestamp)" -ForegroundColor `$Color
    Write-Host ""
}

if (`$Config.NotificationMethods.Email) {
    # Envoyer l'alerte par email
    try {
        `$EmailConfig = `$Config.EmailConfig
        
        if (-not [string]::IsNullOrEmpty(`$EmailConfig.SmtpServer) -and -not [string]::IsNullOrEmpty(`$EmailConfig.FromAddress) -and `$EmailConfig.ToAddress.Count -gt 0) {
            `$Subject = "ALERTE [`$Level] - `$AlertName"
            `$Body = @"
Une alerte a été détectée par le Script Manager:

Nom: `$AlertName
Niveau: `$Level
Script: `$ScriptPath
Message: `$Message
Timestamp: `$(`$Alert.Timestamp)

Cette alerte a été générée automatiquement par le système d'alertes du Script Manager.
"@
            
            `$EmailParams = @{
                SmtpServer = `$EmailConfig.SmtpServer
                Port = `$EmailConfig.SmtpPort
                UseSsl = `$EmailConfig.UseSsl
                From = `$EmailConfig.FromAddress
                To = `$EmailConfig.ToAddress
                Subject = `$Subject
                Body = `$Body
            }
            
            # Ajouter les informations d'identification si nécessaire
            if (-not [string]::IsNullOrEmpty(`$EmailConfig.Credentials.Username) -and -not [string]::IsNullOrEmpty(`$EmailConfig.Credentials.Password)) {
                `$SecurePassword = ConvertTo-SecureString `$EmailConfig.Credentials.Password -AsPlainText -Force
                `$Credentials = New-Object System.Management.Automation.PSCredential(`$EmailConfig.Credentials.Username, `$SecurePassword)
                `$EmailParams.Credential = `$Credentials
            }
            
            Send-MailMessage @EmailParams
            Write-Host "Alerte envoyée par email" -ForegroundColor Green
        } else {
            Write-Warning "Configuration email incomplète"
        }
    } catch {
        Write-Warning "Erreur lors de l'envoi de l'email: `$_"
    }
}

if (`$Config.NotificationMethods.Teams) {
    # Envoyer l'alerte via Teams
    try {
        `$TeamsConfig = `$Config.TeamsConfig
        
        if (-not [string]::IsNullOrEmpty(`$TeamsConfig.WebhookUrl)) {
            `$Color = switch (`$Level) {
                "Info" { "0076D7" }
                "Warning" { "FFC107" }
                "Error" { "FF5722" }
                "Critical" { "B71C1C" }
            }
            
            `$TeamsMessage = @{
                "@type" = "MessageCard"
                "@context" = "http://schema.org/extensions"
                "themeColor" = `$Color
                "summary" = "Alerte Script Manager: `$AlertName"
                "sections" = @(
                    @{
                        "activityTitle" = "ALERTE [`$Level] - `$AlertName"
                        "activitySubtitle" = "Générée le `$(`$Alert.Timestamp)"
                        "facts" = @(
                            @{
                                "name" = "Script:"
                                "value" = `$ScriptPath
                            },
                            @{
                                "name" = "Message:"
                                "value" = `$Message
                            },
                            @{
                                "name" = "Niveau:"
                                "value" = `$Level
                            }
                        )
                    }
                )
            }
            
            `$TeamsMessageJson = `$TeamsMessage | ConvertTo-Json -Depth 10
            
            Invoke-RestMethod -Uri `$TeamsConfig.WebhookUrl -Method Post -Body `$TeamsMessageJson -ContentType "application/json"
            Write-Host "Alerte envoyée via Teams" -ForegroundColor Green
        } else {
            Write-Warning "URL de webhook Teams manquante"
        }
    } catch {
        Write-Warning "Erreur lors de l'envoi de l'alerte via Teams: `$_"
    }
}

if (`$Config.NotificationMethods.Slack) {
    # Envoyer l'alerte via Slack
    try {
        `$SlackConfig = `$Config.SlackConfig
        
        if (-not [string]::IsNullOrEmpty(`$SlackConfig.WebhookUrl)) {
            `$Color = switch (`$Level) {
                "Info" { "good" }
                "Warning" { "warning" }
                "Error" { "danger" }
                "Critical" { "danger" }
            }
            
            `$SlackMessage = @{
                "attachments" = @(
                    @{
                        "fallback" = "ALERTE [`$Level] - `$AlertName"
                        "color" = `$Color
                        "pretext" = "Une alerte a été détectée par le Script Manager"
                        "title" = "ALERTE [`$Level] - `$AlertName"
                        "text" = `$Message
                        "fields" = @(
                            @{
                                "title" = "Script"
                                "value" = `$ScriptPath
                                "short" = `$false
                            },
                            @{
                                "title" = "Niveau"
                                "value" = `$Level
                                "short" = `$true
                            },
                            @{
                                "title" = "Timestamp"
                                "value" = `$Alert.Timestamp
                                "short" = `$true
                            }
                        )
                    }
                )
            }
            
            `$SlackMessageJson = `$SlackMessage | ConvertTo-Json -Depth 10
            
            Invoke-RestMethod -Uri `$SlackConfig.WebhookUrl -Method Post -Body `$SlackMessageJson -ContentType "application/json"
            Write-Host "Alerte envoyée via Slack" -ForegroundColor Green
        } else {
            Write-Warning "URL de webhook Slack manquante"
        }
    } catch {
        Write-Warning "Erreur lors de l'envoi de l'alerte via Slack: `$_"
    }
}
"@
    
    Set-Content -Path $AlertScriptPath -Value $AlertScriptContent
    
    Write-Host "  Script d'envoi d'alertes créé: $AlertScriptPath" -ForegroundColor Green
    
    return [PSCustomObject]@{
        AlertsPath = $AlertsPath
        AlertConfigPath = $AlertConfigPath
        AlertHistoryPath = $AlertHistoryPath
        AlertScriptPath = $AlertScriptPath
    }
}

function Send-ScriptAlert {
    <#
    .SYNOPSIS
        Envoie une alerte pour un problème détecté dans un script
    .DESCRIPTION
        Utilise le script d'envoi d'alertes pour notifier d'un problème
    .PARAMETER AlertName
        Nom de l'alerte
    .PARAMETER Level
        Niveau de l'alerte (Info, Warning, Error, Critical)
    .PARAMETER Message
        Message de l'alerte
    .PARAMETER ScriptPath
        Chemin du script concerné
    .PARAMETER AlertConfig
        Objet de configuration des alertes
    .EXAMPLE
        Send-ScriptAlert -AlertName "Erreur de syntaxe" -Level "Critical" -Message "Erreur de syntaxe dans le script" -ScriptPath "scripts\myscript.ps1" -AlertConfig $alertConfig
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$AlertName,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Info", "Warning", "Error", "Critical")]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AlertConfig
    )
    
    # Vérifier si le script d'envoi d'alertes existe
    if (-not (Test-Path -Path $AlertConfig.AlertScriptPath)) {
        Write-Error "Script d'envoi d'alertes non trouvé: $($AlertConfig.AlertScriptPath)"
        return $false
    }
    
    # Exécuter le script d'envoi d'alertes
    try {
        & $AlertConfig.AlertScriptPath -AlertName $AlertName -Level $Level -Message $Message -ScriptPath $ScriptPath -ConfigPath $AlertConfig.AlertConfigPath -HistoryPath $AlertConfig.AlertHistoryPath
        return $true
    } catch {
        Write-Error "Erreur lors de l'envoi de l'alerte: $_"
        return $false
    }
}

function Get-AlertHistory {
    <#
    .SYNOPSIS
        Récupère l'historique des alertes
    .DESCRIPTION
        Charge et retourne l'historique des alertes
    .PARAMETER HistoryPath
        Chemin vers le fichier d'historique des alertes
    .PARAMETER MaxAlerts
        Nombre maximum d'alertes à retourner
    .EXAMPLE
        Get-AlertHistory -HistoryPath "monitoring\alerts\alert_history.json" -MaxAlerts 10
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryPath,
        
        [Parameter()]
        [int]$MaxAlerts = 0
    )
    
    # Vérifier si le fichier d'historique existe
    if (-not (Test-Path -Path $HistoryPath)) {
        Write-Error "Fichier d'historique non trouvé: $HistoryPath"
        return $null
    }
    
    # Charger l'historique
    try {
        $History = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'historique: $_"
        return $null
    }
    
    # Retourner les alertes
    if ($MaxAlerts -gt 0) {
        return $History.Alerts | Select-Object -Last $MaxAlerts
    } else {
        return $History.Alerts
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-AlertSystem, Send-ScriptAlert, Get-AlertHistory
