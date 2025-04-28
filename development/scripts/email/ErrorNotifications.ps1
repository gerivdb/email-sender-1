# Script pour les notifications d'erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration des notifications
$NotificationConfig = @{
    # Seuils d'alerte
    Thresholds = @{
        Error = 5      # Nombre d'erreurs pour dÃ©clencher une alerte
        Warning = 10   # Nombre d'avertissements pour dÃ©clencher une alerte
        Critical = 1   # Nombre d'erreurs critiques pour dÃ©clencher une alerte
    }
    
    # Intervalle de vÃ©rification (en minutes)
    CheckInterval = 60
    
    # PÃ©riode de vÃ©rification (en heures)
    CheckPeriod = 24
    
    # Configuration des notifications par email
    Email = @{
        Enabled = $false
        SmtpServer = "smtp.example.com"
        Port = 587
        UseSsl = $true
        From = "alerts@example.com"
        To = @("admin@example.com")
        Credentials = $null  # PSCredential object
    }
    
    # Configuration des notifications Teams
    Teams = @{
        Enabled = $false
        WebhookUrl = ""
    }
    
    # Configuration des notifications Slack
    Slack = @{
        Enabled = $false
        WebhookUrl = ""
    }
    
    # Historique des notifications
    HistoryFile = Join-Path -Path $env:TEMP -ChildPath "ErrorNotifications\notification-history.json"
}

# Fonction pour initialiser le systÃ¨me de notifications
function Initialize-ErrorNotifications {
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Thresholds = @{},
        
        [Parameter(Mandatory = $false)]
        [int]$CheckInterval = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$CheckPeriod = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$HistoryFile = ""
    )
    
    # Mettre Ã  jour les seuils
    if ($Thresholds.Count -gt 0) {
        if ($Thresholds.ContainsKey("Error")) {
            $NotificationConfig.Thresholds.Error = $Thresholds.Error
        }
        
        if ($Thresholds.ContainsKey("Warning")) {
            $NotificationConfig.Thresholds.Warning = $Thresholds.Warning
        }
        
        if ($Thresholds.ContainsKey("Critical")) {
            $NotificationConfig.Thresholds.Critical = $Thresholds.Critical
        }
    }
    
    # Mettre Ã  jour l'intervalle de vÃ©rification
    if ($CheckInterval -gt 0) {
        $NotificationConfig.CheckInterval = $CheckInterval
    }
    
    # Mettre Ã  jour la pÃ©riode de vÃ©rification
    if ($CheckPeriod -gt 0) {
        $NotificationConfig.CheckPeriod = $CheckPeriod
    }
    
    # Mettre Ã  jour le fichier d'historique
    if (-not [string]::IsNullOrEmpty($HistoryFile)) {
        $NotificationConfig.HistoryFile = $HistoryFile
    }
    
    # CrÃ©er le dossier d'historique s'il n'existe pas
    $historyFolder = Split-Path -Path $NotificationConfig.HistoryFile -Parent
    if (-not (Test-Path -Path $historyFolder)) {
        New-Item -Path $historyFolder -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le fichier d'historique s'il n'existe pas
    if (-not (Test-Path -Path $NotificationConfig.HistoryFile)) {
        $initialHistory = @{
            Notifications = @()
            LastCheck = Get-Date -Format "o"
        }
        
        $initialHistory | ConvertTo-Json -Depth 5 | Set-Content -Path $NotificationConfig.HistoryFile
    }
    
    # Initialiser le collecteur de donnÃ©es
    Initialize-ErrorDataCollector
    
    return $NotificationConfig
}

# Fonction pour configurer les notifications par email
function Set-ErrorEmailNotifications {
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
    
    $NotificationConfig.Email.SmtpServer = $SmtpServer
    $NotificationConfig.Email.Port = $Port
    $NotificationConfig.Email.UseSsl = $UseSsl
    $NotificationConfig.Email.From = $From
    $NotificationConfig.Email.To = $To
    $NotificationConfig.Email.Credentials = $Credentials
    $NotificationConfig.Email.Enabled = $Enable
    
    return $NotificationConfig.Email
}

# Fonction pour configurer les notifications Teams
function Set-ErrorTeamsNotifications {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enable
    )
    
    $NotificationConfig.Teams.WebhookUrl = $WebhookUrl
    $NotificationConfig.Teams.Enabled = $Enable
    
    return $NotificationConfig.Teams
}

# Fonction pour configurer les notifications Slack
function Set-ErrorSlackNotifications {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enable
    )
    
    $NotificationConfig.Slack.WebhookUrl = $WebhookUrl
    $NotificationConfig.Slack.Enabled = $Enable
    
    return $NotificationConfig.Slack
}

# Fonction pour vÃ©rifier les erreurs et envoyer des notifications
function Test-ErrorNotifications {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Charger l'historique des notifications
    $historyPath = $NotificationConfig.HistoryFile
    $history = Get-Content -Path $historyPath -Raw | ConvertFrom-Json
    
    # VÃ©rifier si la derniÃ¨re vÃ©rification est assez ancienne
    $lastCheck = [DateTime]::Parse($history.LastCheck)
    $now = Get-Date
    $timeSinceLastCheck = $now - $lastCheck
    
    if (-not $Force -and $timeSinceLastCheck.TotalMinutes -lt $NotificationConfig.CheckInterval) {
        Write-Verbose "La derniÃ¨re vÃ©rification a Ã©tÃ© effectuÃ©e il y a moins de $($NotificationConfig.CheckInterval) minutes."
        return $null
    }
    
    # Obtenir les erreurs rÃ©centes
    $checkPeriodHours = $NotificationConfig.CheckPeriod
    $errors = Get-ErrorData -Days ($checkPeriodHours / 24)
    
    # Compter les erreurs par sÃ©vÃ©ritÃ©
    $errorCount = ($errors | Where-Object { $_.Severity -eq "Error" }).Count
    $warningCount = ($errors | Where-Object { $_.Severity -eq "Warning" }).Count
    $criticalCount = ($errors | Where-Object { $_.Severity -eq "Critical" }).Count
    
    # VÃ©rifier si les seuils sont dÃ©passÃ©s
    $shouldNotify = $Force -or
                   ($errorCount -ge $NotificationConfig.Thresholds.Error) -or
                   ($warningCount -ge $NotificationConfig.Thresholds.Warning) -or
                   ($criticalCount -ge $NotificationConfig.Thresholds.Critical)
    
    if (-not $shouldNotify) {
        Write-Verbose "Aucun seuil d'alerte n'est dÃ©passÃ©."
        
        # Mettre Ã  jour la date de derniÃ¨re vÃ©rification
        $history.LastCheck = Get-Date -Format "o"
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $historyPath
        
        return $null
    }
    
    # PrÃ©parer les donnÃ©es de notification
    $notification = @{
        Timestamp = Get-Date -Format "o"
        ErrorCount = $errorCount
        WarningCount = $warningCount
        CriticalCount = $criticalCount
        ThresholdsExceeded = @()
        RecentErrors = $errors | Sort-Object -Property Timestamp -Descending | Select-Object -First 10
    }
    
    # DÃ©terminer quels seuils sont dÃ©passÃ©s
    if ($errorCount -ge $NotificationConfig.Thresholds.Error) {
        $notification.ThresholdsExceeded += "Error"
    }
    
    if ($warningCount -ge $NotificationConfig.Thresholds.Warning) {
        $notification.ThresholdsExceeded += "Warning"
    }
    
    if ($criticalCount -ge $NotificationConfig.Thresholds.Critical) {
        $notification.ThresholdsExceeded += "Critical"
    }
    
    # Envoyer les notifications
    $notificationSent = $false
    
    # Email
    if ($NotificationConfig.Email.Enabled) {
        $emailSent = Send-ErrorEmailNotification -Notification $notification
        $notificationSent = $notificationSent -or $emailSent
    }
    
    # Teams
    if ($NotificationConfig.Teams.Enabled) {
        $teamsSent = Send-ErrorTeamsNotification -Notification $notification
        $notificationSent = $notificationSent -or $teamsSent
    }
    
    # Slack
    if ($NotificationConfig.Slack.Enabled) {
        $slackSent = Send-ErrorSlackNotification -Notification $notification
        $notificationSent = $notificationSent -or $slackSent
    }
    
    # Mettre Ã  jour l'historique des notifications
    if ($notificationSent) {
        $history.Notifications += $notification
        $history.LastCheck = Get-Date -Format "o"
        $history | ConvertTo-Json -Depth 5 | Set-Content -Path $historyPath
    }
    
    return $notification
}

# Fonction pour envoyer une notification par email
function Send-ErrorEmailNotification {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Notification
    )
    
    $config = $NotificationConfig.Email
    
    # CrÃ©er le corps de l'email
    $body = "<h1>Alerte d'erreurs</h1>"
    $body += "<p>Des seuils d'alerte ont Ã©tÃ© dÃ©passÃ©s:</p>"
    $body += "<ul>"
    
    foreach ($threshold in $Notification.ThresholdsExceeded) {
        $count = switch ($threshold) {
            "Error" { $Notification.ErrorCount }
            "Warning" { $Notification.WarningCount }
            "Critical" { $Notification.CriticalCount }
        }
        
        $body += "<li>$threshold: $count</li>"
    }
    
    $body += "</ul>"
    
    # Ajouter les erreurs rÃ©centes
    $body += "<h2>Erreurs rÃ©centes</h2>"
    $body += "<table border='1'>"
    $body += "<tr><th>Date</th><th>SÃ©vÃ©ritÃ©</th><th>CatÃ©gorie</th><th>Message</th></tr>"
    
    foreach ($error in $Notification.RecentErrors) {
        $timestamp = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        
        $body += "<tr>"
        $body += "<td>$timestamp</td>"
        $body += "<td>$($error.Severity)</td>"
        $body += "<td>$($error.Category)</td>"
        $body += "<td>$($error.Message)</td>"
        $body += "</tr>"
    }
    
    $body += "</table>"
    
    # ParamÃ¨tres de l'email
    $emailParams = @{
        SmtpServer = $config.SmtpServer
        Port = $config.Port
        UseSsl = $config.UseSsl
        From = $config.From
        To = $config.To
        Subject = "Alerte d'erreurs - $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
        Body = $body
        BodyAsHtml = $true
    }
    
    # Ajouter les credentials si spÃ©cifiÃ©s
    if ($null -ne $config.Credentials) {
        $emailParams.Credential = $config.Credentials
    }
    
    # Envoyer l'email
    try {
        Send-MailMessage @emailParams
        Write-Verbose "Notification envoyÃ©e par email Ã  $($config.To -join ', ')"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de la notification par email: $_"
        return $false
    }
}

# Fonction pour envoyer une notification Teams
function Send-ErrorTeamsNotification {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Notification
    )
    
    $webhookUrl = $NotificationConfig.Teams.WebhookUrl
    
    # CrÃ©er le message Teams
    $facts = @()
    
    foreach ($threshold in $Notification.ThresholdsExceeded) {
        $count = switch ($threshold) {
            "Error" { $Notification.ErrorCount }
            "Warning" { $Notification.WarningCount }
            "Critical" { $Notification.CriticalCount }
        }
        
        $facts += @{
            name = $threshold
            value = $count.ToString()
        }
    }
    
    $message = @{
        "@type" = "MessageCard"
        "@context" = "http://schema.org/extensions"
        "summary" = "Alerte d'erreurs"
        "themeColor" = "0078D7"
        "title" = "Alerte d'erreurs"
        "sections" = @(
            @{
                "activityTitle" = "Seuils d'alerte dÃ©passÃ©s"
                "facts" = $facts
            },
            @{
                "activityTitle" = "Erreurs rÃ©centes"
                "text" = ($Notification.RecentErrors | ForEach-Object {
                    $timestamp = [DateTime]::Parse($_.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                    "- **$($_.Severity)** ($timestamp): $($_.Message)"
                }) -join "`n"
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
        
        Write-Verbose "Notification envoyÃ©e Ã  Microsoft Teams"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de la notification Ã  Microsoft Teams: $_"
        return $false
    }
}

# Fonction pour envoyer une notification Slack
function Send-ErrorSlackNotification {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Notification
    )
    
    $webhookUrl = $NotificationConfig.Slack.WebhookUrl
    
    # CrÃ©er le message Slack
    $blocks = @(
        @{
            type = "header"
            text = @{
                type = "plain_text"
                text = "Alerte d'erreurs"
                emoji = $true
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "*Seuils d'alerte dÃ©passÃ©s:*"
            }
        }
    )
    
    # Ajouter les seuils dÃ©passÃ©s
    $thresholdsText = ""
    foreach ($threshold in $Notification.ThresholdsExceeded) {
        $count = switch ($threshold) {
            "Error" { $Notification.ErrorCount }
            "Warning" { $Notification.WarningCount }
            "Critical" { $Notification.CriticalCount }
        }
        
        $thresholdsText += "â€¢ $threshold: $count\n"
    }
    
    $blocks += @{
        type = "section"
        text = @{
            type = "mrkdwn"
            text = $thresholdsText
        }
    }
    
    # Ajouter les erreurs rÃ©centes
    $blocks += @{
        type = "section"
        text = @{
            type = "mrkdwn"
            text = "*Erreurs rÃ©centes:*"
        }
    }
    
    foreach ($error in ($Notification.RecentErrors | Select-Object -First 5)) {
        $timestamp = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        $severityEmoji = switch ($error.Severity) {
            "Error" { ":red_circle:" }
            "Warning" { ":warning:" }
            "Critical" { ":rotating_light:" }
            default { ":information_source:" }
        }
        
        $blocks += @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = "$severityEmoji *$($error.Severity)* ($timestamp)\n$($error.Message)"
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
        
        Write-Verbose "Notification envoyÃ©e Ã  Slack"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de la notification Ã  Slack: $_"
        return $false
    }
}

# Fonction pour dÃ©marrer un service de surveillance des erreurs
function Start-ErrorNotificationService {
    param (
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$RunOnce
    )
    
    # Utiliser l'intervalle par dÃ©faut si non spÃ©cifiÃ©
    if ($IntervalMinutes -le 0) {
        $IntervalMinutes = $NotificationConfig.CheckInterval
    }
    
    # Initialiser le service
    Initialize-ErrorNotifications
    
    if ($RunOnce) {
        # ExÃ©cuter une seule fois
        $notification = Test-ErrorNotifications -Force
        
        if ($null -ne $notification) {
            Write-Host "Notification envoyÃ©e."
        }
        else {
            Write-Host "Aucune notification envoyÃ©e."
        }
        
        return $notification
    }
    else {
        # ExÃ©cuter en boucle
        Write-Host "Service de notification dÃ©marrÃ©. Intervalle: $IntervalMinutes minutes."
        Write-Host "Appuyez sur Ctrl+C pour arrÃªter le service."
        
        try {
            while ($true) {
                $notification = Test-ErrorNotifications
                
                if ($null -ne $notification) {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Notification envoyÃ©e."
                }
                else {
                    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Aucune notification envoyÃ©e."
                }
                
                # Attendre l'intervalle
                Start-Sleep -Seconds ($IntervalMinutes * 60)
            }
        }
        finally {
            Write-Host "Service de notification arrÃªtÃ©."
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorNotifications, Set-ErrorEmailNotifications, Set-ErrorTeamsNotifications, Set-ErrorSlackNotifications
Export-ModuleMember -Function Test-ErrorNotifications, Send-ErrorEmailNotification, Send-ErrorTeamsNotification, Send-ErrorSlackNotification
Export-ModuleMember -Function Start-ErrorNotificationService
