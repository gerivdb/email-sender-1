# Send-CleanupNotification.ps1
# Script pour envoyer des notifications concernant le nettoyage des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Start", "Complete", "Error", "Warning", "Summary")]
    [string]$NotificationType,
    
    [Parameter(Mandatory = $false)]
    [string]$Subject = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Message = "",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Details = @{},
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Email", "Teams", "Slack", "Console", "Log", "All")]
    [string[]]$Channels = @("Console", "Log"),
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir le chemin du fichier de configuration des notifications
function Get-NotificationConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $notificationsPath = Join-Path -Path $configPath -ChildPath "notifications"
    
    if (-not (Test-Path -Path $notificationsPath)) {
        New-Item -Path $notificationsPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $notificationsPath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration des notifications
function Get-NotificationConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-NotificationConfigPath -ConfigName $ConfigName
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading notification configuration: $_" -Level "Error"
            return $null
        }
    } else {
        # Créer une configuration par défaut
        $defaultConfig = @{
            name = $ConfigName
            created_at = (Get-Date).ToString("o")
            last_modified = (Get-Date).ToString("o")
            channels = @{
                email = @{
                    enabled = $false
                    smtp_server = "smtp.example.com"
                    smtp_port = 587
                    use_ssl = $true
                    username = ""
                    password = ""
                    from_address = "noreply@example.com"
                    to_addresses = @("admin@example.com")
                    cc_addresses = @()
                    bcc_addresses = @()
                }
                teams = @{
                    enabled = $false
                    webhook_url = ""
                }
                slack = @{
                    enabled = $false
                    webhook_url = ""
                    channel = "#notifications"
                }
                console = @{
                    enabled = $true
                }
                log = @{
                    enabled = $true
                    log_path = ""
                }
            }
            notification_types = @{
                start = @{
                    enabled = $true
                    subject = "Cleanup process started"
                    message = "The restore point cleanup process has started."
                    channels = @("Console", "Log")
                }
                complete = @{
                    enabled = $true
                    subject = "Cleanup process completed"
                    message = "The restore point cleanup process has completed successfully."
                    channels = @("Console", "Log")
                }
                error = @{
                    enabled = $true
                    subject = "Cleanup process error"
                    message = "An error occurred during the restore point cleanup process."
                    channels = @("Console", "Log", "Email")
                }
                warning = @{
                    enabled = $true
                    subject = "Cleanup process warning"
                    message = "A warning occurred during the restore point cleanup process."
                    channels = @("Console", "Log")
                }
                summary = @{
                    enabled = $true
                    subject = "Cleanup process summary"
                    message = "Summary of the restore point cleanup process."
                    channels = @("Console", "Log", "Email")
                }
            }
        }
        
        # Sauvegarder la configuration par défaut
        try {
            $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-Log "Created default notification configuration: $configPath" -Level "Info"
        } catch {
            Write-Log "Error creating default notification configuration: $_" -Level "Error"
        }
        
        return $defaultConfig
    }
}

# Fonction pour envoyer une notification par email
function Send-EmailNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        
        [Parameter(Mandatory = $true)]
        [string]$Body,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    if (-not $Config.channels.email.enabled) {
        Write-Log "Email notifications are disabled" -Level "Debug"
        return $false
    }
    
    try {
        $smtpServer = $Config.channels.email.smtp_server
        $smtpPort = $Config.channels.email.smtp_port
        $useSSL = $Config.channels.email.use_ssl
        $username = $Config.channels.email.username
        $password = $Config.channels.email.password
        $fromAddress = $Config.channels.email.from_address
        $toAddresses = $Config.channels.email.to_addresses
        $ccAddresses = $Config.channels.email.cc_addresses
        $bccAddresses = $Config.channels.email.bcc_addresses
        
        # Créer les paramètres pour Send-MailMessage
        $mailParams = @{
            SmtpServer = $smtpServer
            Port = $smtpPort
            UseSsl = $useSSL
            From = $fromAddress
            To = $toAddresses
            Subject = $Subject
            Body = $Body
            BodyAsHtml = $true
        }
        
        if (-not [string]::IsNullOrEmpty($username) -and -not [string]::IsNullOrEmpty($password)) {
            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($username, $securePassword)
            $mailParams.Credential = $credentials
        }
        
        if ($ccAddresses.Count -gt 0) {
            $mailParams.Cc = $ccAddresses
        }
        
        if ($bccAddresses.Count -gt 0) {
            $mailParams.Bcc = $bccAddresses
        }
        
        # Envoyer l'email
        Send-MailMessage @mailParams
        
        Write-Log "Email notification sent to $($toAddresses -join ', ')" -Level "Info"
        return $true
    } catch {
        Write-Log "Error sending email notification: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour envoyer une notification Microsoft Teams
function Send-TeamsNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{},
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    if (-not $Config.channels.teams.enabled) {
        Write-Log "Teams notifications are disabled" -Level "Debug"
        return $false
    }
    
    try {
        $webhookUrl = $Config.channels.teams.webhook_url
        
        if ([string]::IsNullOrEmpty($webhookUrl)) {
            Write-Log "Teams webhook URL is not configured" -Level "Warning"
            return $false
        }
        
        # Créer le corps de la requête
        $facts = @()
        
        foreach ($key in $Details.Keys) {
            $facts += @{
                name = $key
                value = $Details[$key]
            }
        }
        
        $body = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            themeColor = "0076D7"
            summary = $Title
            sections = @(
                @{
                    activityTitle = $Title
                    activitySubtitle = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    activityImage = "https://raw.githubusercontent.com/microsoft/vscode-codicons/main/src/icons/database.svg"
                    text = $Message
                    facts = $facts
                }
            )
        }
        
        # Convertir le corps en JSON
        $bodyJson = $body | ConvertTo-Json -Depth 10
        
        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $bodyJson -ContentType "application/json"
        
        Write-Log "Teams notification sent" -Level "Info"
        return $true
    } catch {
        Write-Log "Error sending Teams notification: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour envoyer une notification Slack
function Send-SlackNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{},
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    if (-not $Config.channels.slack.enabled) {
        Write-Log "Slack notifications are disabled" -Level "Debug"
        return $false
    }
    
    try {
        $webhookUrl = $Config.channels.slack.webhook_url
        $channel = $Config.channels.slack.channel
        
        if ([string]::IsNullOrEmpty($webhookUrl)) {
            Write-Log "Slack webhook URL is not configured" -Level "Warning"
            return $false
        }
        
        # Créer les champs
        $fields = @()
        
        foreach ($key in $Details.Keys) {
            $fields += @{
                title = $key
                value = $Details[$key]
                short = $true
            }
        }
        
        # Créer le corps de la requête
        $body = @{
            channel = $channel
            username = "Restore Point Cleanup"
            icon_emoji = ":gear:"
            attachments = @(
                @{
                    fallback = $Title
                    color = "#36a64f"
                    pretext = $Title
                    author_name = "Restore Point Cleanup"
                    title = $Title
                    text = $Message
                    fields = $fields
                    footer = "Restore Point Cleanup"
                    footer_icon = "https://platform.slack-edge.com/img/default_application_icon.png"
                    ts = [Math]::Floor([decimal](Get-Date -UFormat "%s"))
                }
            )
        }
        
        # Convertir le corps en JSON
        $bodyJson = $body | ConvertTo-Json -Depth 10
        
        # Envoyer la requête
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $bodyJson -ContentType "application/json"
        
        Write-Log "Slack notification sent to $channel" -Level "Info"
        return $true
    } catch {
        Write-Log "Error sending Slack notification: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour envoyer une notification à la console
function Send-ConsoleNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{},
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    if (-not $Config.channels.console.enabled) {
        return $false
    }
    
    # Déterminer la couleur en fonction du type de notification
    $color = switch ($Title) {
        { $_ -like "*Error*" } { "Red" }
        { $_ -like "*Warning*" } { "Yellow" }
        { $_ -like "*Complete*" } { "Green" }
        default { "Cyan" }
    }
    
    # Afficher le titre et le message
    Write-Host "`n$Title" -ForegroundColor $color
    Write-Host "=" * $Title.Length -ForegroundColor $color
    Write-Host "$Message`n" -ForegroundColor White
    
    # Afficher les détails
    if ($Details.Count -gt 0) {
        foreach ($key in $Details.Keys) {
            Write-Host "$key : " -ForegroundColor Gray -NoNewline
            Write-Host "$($Details[$key])" -ForegroundColor White
        }
        Write-Host ""
    }
    
    return $true
}

# Fonction pour envoyer une notification au journal
function Send-LogNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{},
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    if (-not $Config.channels.log.enabled) {
        return $false
    }
    
    # Déterminer le niveau de journalisation
    $level = switch ($Title) {
        { $_ -like "*Error*" } { "Error" }
        { $_ -like "*Warning*" } { "Warning" }
        default { "Info" }
    }
    
    # Journaliser le titre et le message
    Write-Log "$Title - $Message" -Level $level
    
    # Journaliser les détails
    if ($Details.Count -gt 0) {
        foreach ($key in $Details.Keys) {
            Write-Log "  $key: $($Details[$key])" -Level $level
        }
    }
    
    return $true
}

# Fonction principale pour envoyer une notification
function Send-CleanupNotification {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Start", "Complete", "Error", "Warning", "Summary")]
        [string]$NotificationType,
        
        [Parameter(Mandatory = $false)]
        [string]$Subject = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Message = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "Teams", "Slack", "Console", "Log", "All")]
        [string[]]$Channels = @("Console", "Log"),
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    # Charger la configuration
    $config = Get-NotificationConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        Write-Log "Failed to load notification configuration" -Level "Error"
        return $false
    }
    
    # Vérifier si le type de notification est activé
    $notificationType = $NotificationType.ToLower()
    
    if (-not $config.notification_types.PSObject.Properties.Name.Contains($notificationType) -or 
        -not $config.notification_types.$notificationType.enabled) {
        Write-Log "$NotificationType notifications are disabled" -Level "Debug"
        return $false
    }
    
    # Obtenir les paramètres de notification
    $notificationConfig = $config.notification_types.$notificationType
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ([string]::IsNullOrEmpty($Subject)) {
        $Subject = $notificationConfig.subject
    }
    
    if ([string]::IsNullOrEmpty($Message)) {
        $Message = $notificationConfig.message
    }
    
    if ($Channels.Contains("All")) {
        $Channels = @("Email", "Teams", "Slack", "Console", "Log")
    }
    
    # Fusionner avec les canaux configurés
    if ($Channels.Count -eq 0 -and $notificationConfig.PSObject.Properties.Name.Contains("channels")) {
        $Channels = $notificationConfig.channels
    }
    
    # Envoyer les notifications
    $results = @{}
    
    if ($Channels.Contains("Email")) {
        $emailBody = "<h2>$Subject</h2><p>$Message</p>"
        
        if ($Details.Count -gt 0) {
            $emailBody += "<h3>Details</h3><ul>"
            
            foreach ($key in $Details.Keys) {
                $emailBody += "<li><strong>$key:</strong> $($Details[$key])</li>"
            }
            
            $emailBody += "</ul>"
        }
        
        $results.Email = Send-EmailNotification -Subject $Subject -Body $emailBody -Config $config
    }
    
    if ($Channels.Contains("Teams")) {
        $results.Teams = Send-TeamsNotification -Title $Subject -Message $Message -Details $Details -Config $config
    }
    
    if ($Channels.Contains("Slack")) {
        $results.Slack = Send-SlackNotification -Title $Subject -Message $Message -Details $Details -Config $config
    }
    
    if ($Channels.Contains("Console")) {
        $results.Console = Send-ConsoleNotification -Title $Subject -Message $Message -Details $Details -Config $config
    }
    
    if ($Channels.Contains("Log")) {
        $results.Log = Send-LogNotification -Title $Subject -Message $Message -Details $Details -Config $config
    }
    
    # Vérifier si toutes les notifications ont été envoyées avec succès
    $success = $true
    
    foreach ($channel in $Channels) {
        if ($results.ContainsKey($channel) -and -not $results[$channel]) {
            $success = $false
        }
    }
    
    return $success
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Send-CleanupNotification -NotificationType $NotificationType -Subject $Subject -Message $Message -Details $Details -Channels $Channels -ConfigName $ConfigName
}
