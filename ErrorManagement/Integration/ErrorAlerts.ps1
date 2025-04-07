# Script pour les alertes automatiques d'erreurs récurrentes

# Configuration des alertes
$script:AlertConfig = @{
    # Seuils d'alerte
    Thresholds = @{
        Error = 5      # Nombre d'erreurs pour déclencher une alerte
        Warning = 10   # Nombre d'avertissements pour déclencher une alerte
        Frequency = 3  # Nombre d'occurrences d'une même erreur pour la considérer comme récurrente
    }
    
    # Configuration des notifications
    Notifications = @{
        Email = @{
            Enabled = $false
            SmtpServer = "smtp.example.com"
            Port = 587
            UseSsl = $true
            From = "alerts@example.com"
            To = @("admin@example.com")
            Credentials = $null  # PSCredential object
        }
        Teams = @{
            Enabled = $false
            WebhookUrl = ""
        }
        Slack = @{
            Enabled = $false
            WebhookUrl = ""
        }
    }
    
    # Historique des alertes
    HistoryFile = Join-Path -Path $env:TEMP -ChildPath "error-alerts-history.json"
    
    # Ignorer certaines erreurs
    IgnorePatterns = @(
        "PSAvoidUsingPlainTextForPassword",
        "PSAvoidUsingConvertToSecureStringWithPlainText"
    )
}

# Fonction pour initialiser la configuration des alertes
function Initialize-ErrorAlerts {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = ""
    )
    
    # Charger la configuration depuis un fichier si spécifié
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Mettre à jour les seuils
            if ($config.Thresholds) {
                $script:AlertConfig.Thresholds.Error = $config.Thresholds.Error
                $script:AlertConfig.Thresholds.Warning = $config.Thresholds.Warning
                $script:AlertConfig.Thresholds.Frequency = $config.Thresholds.Frequency
            }
            
            # Mettre à jour les notifications
            if ($config.Notifications) {
                if ($config.Notifications.Email) {
                    $script:AlertConfig.Notifications.Email.Enabled = $config.Notifications.Email.Enabled
                    $script:AlertConfig.Notifications.Email.SmtpServer = $config.Notifications.Email.SmtpServer
                    $script:AlertConfig.Notifications.Email.Port = $config.Notifications.Email.Port
                    $script:AlertConfig.Notifications.Email.UseSsl = $config.Notifications.Email.UseSsl
                    $script:AlertConfig.Notifications.Email.From = $config.Notifications.Email.From
                    $script:AlertConfig.Notifications.Email.To = $config.Notifications.Email.To
                }
                
                if ($config.Notifications.Teams) {
                    $script:AlertConfig.Notifications.Teams.Enabled = $config.Notifications.Teams.Enabled
                    $script:AlertConfig.Notifications.Teams.WebhookUrl = $config.Notifications.Teams.WebhookUrl
                }
                
                if ($config.Notifications.Slack) {
                    $script:AlertConfig.Notifications.Slack.Enabled = $config.Notifications.Slack.Enabled
                    $script:AlertConfig.Notifications.Slack.WebhookUrl = $config.Notifications.Slack.WebhookUrl
                }
            }
            
            # Mettre à jour le fichier d'historique
            if ($config.HistoryFile) {
                $script:AlertConfig.HistoryFile = $config.HistoryFile
            }
            
            # Mettre à jour les patterns à ignorer
            if ($config.IgnorePatterns) {
                $script:AlertConfig.IgnorePatterns = $config.IgnorePatterns
            }
            
            Write-Verbose "Configuration des alertes chargée depuis $ConfigPath"
        }
        catch {
            Write-Error "Erreur lors du chargement de la configuration des alertes: $_"
        }
    }
    
    # Initialiser l'historique des alertes
    if (-not (Test-Path -Path $script:AlertConfig.HistoryFile)) {
        $history = @{
            LastRun = Get-Date
            Alerts = @()
            ErrorCounts = @{}
        }
        
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $script:AlertConfig.HistoryFile
    }
    
    return $script:AlertConfig
}

# Fonction pour analyser les erreurs et déclencher des alertes
function Invoke-ErrorAnalysisAlert {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$AnalysisResults,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Charger l'historique des alertes
    $history = Get-Content -Path $script:AlertConfig.HistoryFile -Raw | ConvertFrom-Json
    
    # Convertir l'historique en objets PowerShell
    $errorCounts = @{}
    foreach ($key in $history.ErrorCounts.PSObject.Properties.Name) {
        $errorCounts[$key] = $history.ErrorCounts.$key
    }
    
    # Filtrer les résultats
    $filteredResults = $AnalysisResults | Where-Object {
        $_.Severity -in @("Error", "Warning") -and
        $_.RuleName -notin $script:AlertConfig.IgnorePatterns
    }
    
    # Compter les erreurs par type
    $currentErrors = @{}
    foreach ($result in $filteredResults) {
        $key = "$($result.RuleName):$($result.Severity)"
        
        if (-not $currentErrors.ContainsKey($key)) {
            $currentErrors[$key] = @{
                Count = 0
                Rule = $result.RuleName
                Severity = $result.Severity
                Messages = @()
            }
        }
        
        $currentErrors[$key].Count++
        $currentErrors[$key].Messages += "$($result.ScriptPath):$($result.Line) - $($result.Message)"
    }
    
    # Mettre à jour les compteurs d'erreurs
    foreach ($key in $currentErrors.Keys) {
        if (-not $errorCounts.ContainsKey($key)) {
            $errorCounts[$key] = @{
                Count = 0
                Occurrences = 0
                LastSeen = Get-Date
                Rule = $currentErrors[$key].Rule
                Severity = $currentErrors[$key].Severity
            }
        }
        
        $errorCounts[$key].Count = $currentErrors[$key].Count
        $errorCounts[$key].Occurrences++
        $errorCounts[$key].LastSeen = Get-Date
    }
    
    # Identifier les erreurs récurrentes
    $alerts = @()
    
    foreach ($key in $errorCounts.Keys) {
        $error = $errorCounts[$key]
        
        # Vérifier si l'erreur est récurrente
        if ($error.Occurrences -ge $script:AlertConfig.Thresholds.Frequency) {
            # Vérifier si le seuil d'alerte est atteint
            $threshold = if ($error.Severity -eq "Error") {
                $script:AlertConfig.Thresholds.Error
            }
            else {
                $script:AlertConfig.Thresholds.Warning
            }
            
            if ($error.Count -ge $threshold -or $Force) {
                $alerts += [PSCustomObject]@{
                    Rule = $error.Rule
                    Severity = $error.Severity
                    Count = $error.Count
                    Occurrences = $error.Occurrences
                    LastSeen = $error.LastSeen
                    Messages = if ($currentErrors.ContainsKey($key)) { $currentErrors[$key].Messages } else { @() }
                }
            }
        }
    }
    
    # Envoyer les alertes
    if ($alerts.Count -gt 0) {
        # Envoyer par email
        if ($script:AlertConfig.Notifications.Email.Enabled) {
            Send-ErrorAlertEmail -Alerts $alerts
        }
        
        # Envoyer à Teams
        if ($script:AlertConfig.Notifications.Teams.Enabled) {
            Send-ErrorAlertTeams -Alerts $alerts
        }
        
        # Envoyer à Slack
        if ($script:AlertConfig.Notifications.Slack.Enabled) {
            Send-ErrorAlertSlack -Alerts $alerts
        }
    }
    
    # Mettre à jour l'historique
    $history.LastRun = Get-Date
    $history.Alerts = $alerts
    $history.ErrorCounts = $errorCounts
    
    $history | ConvertTo-Json -Depth 5 | Set-Content -Path $script:AlertConfig.HistoryFile
    
    return $alerts
}

# Fonction pour envoyer une alerte par email
function Send-ErrorAlertEmail {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Alerts
    )
    
    $config = $script:AlertConfig.Notifications.Email
    
    # Créer le corps de l'email
    $body = "<h1>Alerte d'erreurs récurrentes</h1>"
    $body += "<p>Les erreurs suivantes ont été détectées de manière récurrente:</p>"
    $body += "<table border='1'>"
    $body += "<tr><th>Règle</th><th>Sévérité</th><th>Nombre</th><th>Occurrences</th><th>Dernière détection</th></tr>"
    
    foreach ($alert in $Alerts) {
        $severityColor = if ($alert.Severity -eq "Error") { "red" } else { "orange" }
        
        $body += "<tr>"
        $body += "<td>$($alert.Rule)</td>"
        $body += "<td style='color: $severityColor;'>$($alert.Severity)</td>"
        $body += "<td>$($alert.Count)</td>"
        $body += "<td>$($alert.Occurrences)</td>"
        $body += "<td>$($alert.LastSeen)</td>"
        $body += "</tr>"
    }
    
    $body += "</table>"
    
    # Ajouter les détails des erreurs
    $body += "<h2>Détails des erreurs</h2>"
    
    foreach ($alert in $Alerts) {
        $body += "<h3>$($alert.Rule) ($($alert.Severity))</h3>"
        $body += "<ul>"
        
        foreach ($message in $alert.Messages) {
            $body += "<li>$message</li>"
        }
        
        $body += "</ul>"
    }
    
    # Paramètres de l'email
    $emailParams = @{
        SmtpServer = $config.SmtpServer
        Port = $config.Port
        UseSsl = $config.UseSsl
        From = $config.From
        To = $config.To
        Subject = "Alerte d'erreurs récurrentes - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
        Body = $body
        BodyAsHtml = $true
    }
    
    # Ajouter les credentials si spécifiés
    if ($null -ne $config.Credentials) {
        $emailParams.Credential = $config.Credentials
    }
    
    # Envoyer l'email
    try {
        Send-MailMessage @emailParams
        Write-Verbose "Alerte envoyée par email à $($config.To -join ', ')"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de l'alerte par email: $_"
        return $false
    }
}

# Fonction pour envoyer une alerte à Microsoft Teams
function Send-ErrorAlertTeams {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Alerts
    )
    
    $webhookUrl = $script:AlertConfig.Notifications.Teams.WebhookUrl
    
    # Créer le message Teams
    $facts = @()
    
    foreach ($alert in $Alerts) {
        $facts += @{
            name = "$($alert.Rule) ($($alert.Severity))"
            value = "Nombre: $($alert.Count), Occurrences: $($alert.Occurrences)"
        }
    }
    
    $message = @{
        "@type" = "MessageCard"
        "@context" = "http://schema.org/extensions"
        "summary" = "Alerte d'erreurs récurrentes"
        "themeColor" = "0078D7"
        "title" = "Alerte d'erreurs récurrentes"
        "sections" = @(
            @{
                "activityTitle" = "Erreurs détectées"
                "activitySubtitle" = "Les erreurs suivantes ont été détectées de manière récurrente"
                "facts" = $facts
            }
        )
    }
    
    # Envoyer le message
    try {
        $body = $message | ConvertTo-Json -Depth 4
        
        $params = @{
            Uri = $webhookUrl
            Method = "POST"
            Body = $body
            ContentType = "application/json"
        }
        
        Invoke-RestMethod @params
        
        Write-Verbose "Alerte envoyée à Microsoft Teams"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de l'alerte à Microsoft Teams: $_"
        return $false
    }
}

# Fonction pour envoyer une alerte à Slack
function Send-ErrorAlertSlack {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Alerts
    )
    
    $webhookUrl = $script:AlertConfig.Notifications.Slack.WebhookUrl
    
    # Créer le message Slack
    $blocks = @(
        @{
            type = "header"
            text = @{
                type = "plain_text"
                text = "Alerte d'erreurs récurrentes"
                emoji = $true
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "Les erreurs suivantes ont été détectées de manière récurrente:"
            }
        }
    )
    
    foreach ($alert in $Alerts) {
        $severityEmoji = if ($alert.Severity -eq "Error") { ":red_circle:" } else { ":warning:" }
        
        $blocks += @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "*$($alert.Rule)* $severityEmoji`nNombre: $($alert.Count), Occurrences: $($alert.Occurrences)"
            }
        }
    }
    
    $message = @{
        blocks = $blocks
    }
    
    # Envoyer le message
    try {
        $body = $message | ConvertTo-Json -Depth 4
        
        $params = @{
            Uri = $webhookUrl
            Method = "POST"
            Body = $body
            ContentType = "application/json"
        }
        
        Invoke-RestMethod @params
        
        Write-Verbose "Alerte envoyée à Slack"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de l'alerte à Slack: $_"
        return $false
    }
}

# Fonction pour configurer les notifications par email
function Set-ErrorAlertEmailConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SmtpServer,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $true)]
        [string]$From,
        
        [Parameter(Mandatory = $true)]
        [string[]]$To,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseSsl,
        
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credentials,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enable
    )
    
    $script:AlertConfig.Notifications.Email.SmtpServer = $SmtpServer
    $script:AlertConfig.Notifications.Email.Port = $Port
    $script:AlertConfig.Notifications.Email.UseSsl = $UseSsl
    $script:AlertConfig.Notifications.Email.From = $From
    $script:AlertConfig.Notifications.Email.To = $To
    $script:AlertConfig.Notifications.Email.Credentials = $Credentials
    $script:AlertConfig.Notifications.Email.Enabled = $Enable
    
    return $script:AlertConfig.Notifications.Email
}

# Fonction pour configurer les notifications Teams
function Set-ErrorAlertTeamsConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enable
    )
    
    $script:AlertConfig.Notifications.Teams.WebhookUrl = $WebhookUrl
    $script:AlertConfig.Notifications.Teams.Enabled = $Enable
    
    return $script:AlertConfig.Notifications.Teams
}

# Fonction pour configurer les notifications Slack
function Set-ErrorAlertSlackConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enable
    )
    
    $script:AlertConfig.Notifications.Slack.WebhookUrl = $WebhookUrl
    $script:AlertConfig.Notifications.Slack.Enabled = $Enable
    
    return $script:AlertConfig.Notifications.Slack
}

# Fonction pour configurer les seuils d'alerte
function Set-ErrorAlertThresholds {
    param (
        [Parameter(Mandatory = $false)]
        [int]$ErrorThreshold = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$WarningThreshold = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$FrequencyThreshold = 3
    )
    
    $script:AlertConfig.Thresholds.Error = $ErrorThreshold
    $script:AlertConfig.Thresholds.Warning = $WarningThreshold
    $script:AlertConfig.Thresholds.Frequency = $FrequencyThreshold
    
    return $script:AlertConfig.Thresholds
}

# Fonction pour obtenir l'historique des alertes
function Get-ErrorAlertHistory {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 7
    )
    
    # Charger l'historique des alertes
    $history = Get-Content -Path $script:AlertConfig.HistoryFile -Raw | ConvertFrom-Json
    
    # Filtrer par date
    $cutoffDate = (Get-Date).AddDays(-$Days)
    
    $filteredAlerts = $history.Alerts | Where-Object {
        [datetime]$_.LastSeen -ge $cutoffDate
    }
    
    return $filteredAlerts
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorAlerts, Invoke-ErrorAnalysisAlert
Export-ModuleMember -Function Send-ErrorAlertEmail, Send-ErrorAlertTeams, Send-ErrorAlertSlack
Export-ModuleMember -Function Set-ErrorAlertEmailConfig, Set-ErrorAlertTeamsConfig, Set-ErrorAlertSlackConfig
Export-ModuleMember -Function Set-ErrorAlertThresholds, Get-ErrorAlertHistory
