#Requires -Version 5.1
<#
.SYNOPSIS
    Envoie des notifications sur l'Ã©tat de la roadmap.
.DESCRIPTION
    Ce script envoie des notifications par email ou via Teams/Slack
    sur l'Ã©tat de la roadmap, les tÃ¢ches en retard, et les prochaines Ã©chÃ©ances.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Email", "Teams", "Slack", "All")]
    [string]$NotificationType = "Email",
    
    [Parameter(Mandatory=$false)]
    [string]$EmailTo = "gerivonderbitsh+dev@gmail.com",
    
    [Parameter(Mandatory=$false)]
    [string]$TeamsWebhookUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhookUrl,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeFullReport,
    
    [Parameter(Mandatory=$false)]
    [switch]$OnlyIfOverdue
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$statusPath = Join-Path -Path $journalRoot -ChildPath "status.json"
$configPath = Join-Path -Path $journalRoot -ChildPath "config"

# CrÃ©er le dossier de configuration si nÃ©cessaire
if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
}

# Mettre Ã  jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# VÃ©rifier s'il y a des tÃ¢ches en retard
$hasOverdueTasks = $status.overdueTasks.Count -gt 0

# Si OnlyIfOverdue est spÃ©cifiÃ© et qu'il n'y a pas de tÃ¢ches en retard, quitter
if ($OnlyIfOverdue -and -not $hasOverdueTasks) {
    Write-Host "Aucune tÃ¢che en retard. Aucune notification envoyÃ©e." -ForegroundColor Green
    exit 0
}

# Fonction pour gÃ©nÃ©rer le contenu de la notification
function Get-NotificationContent {
    $content = @"
# Ã‰tat de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")

## RÃ©sumÃ©

- Progression globale: $($status.globalProgress)%
- Total des tÃ¢ches: $($index.statistics.totalEntries)
- TÃ¢ches non commencÃ©es: $($index.statistics.notStarted)
- TÃ¢ches en cours: $($index.statistics.inProgress)
- TÃ¢ches terminÃ©es: $($index.statistics.completed)
- TÃ¢ches bloquÃ©es: $($index.statistics.blocked)

"@
    
    # Ajouter les tÃ¢ches en retard
    if ($status.overdueTasks.Count -gt 0) {
        $content += @"
## TÃ¢ches en retard

"@
        
        foreach ($task in $status.overdueTasks) {
            $content += @"
- $($task.id): $($task.title) - En retard de $($task.daysOverdue) jours (Ã‰chÃ©ance: $($task.dueDate))

"@
        }
    }
    else {
        $content += @"
## TÃ¢ches en retard

Aucune tÃ¢che en retard.

"@
    }
    
    # Ajouter les prochaines Ã©chÃ©ances
    if ($status.upcomingDeadlines.Count -gt 0) {
        $content += @"
## Prochaines Ã©chÃ©ances

"@
        
        foreach ($task in $status.upcomingDeadlines) {
            $content += @"
- $($task.id): $($task.title) - Dans $($task.daysRemaining) jours (Ã‰chÃ©ance: $($task.dueDate))

"@
        }
    }
    else {
        $content += @"
## Prochaines Ã©chÃ©ances

Aucune Ã©chÃ©ance Ã  venir dans les 7 prochains jours.

"@
    }
    
    # Ajouter les tÃ¢ches bloquÃ©es
    if ($status.blockedTasks.Count -gt 0) {
        $content += @"
## TÃ¢ches bloquÃ©es

"@
        
        foreach ($task in $status.blockedTasks) {
            $content += @"
- $($task.id): $($task.title)

"@
        }
    }
    else {
        $content += @"
## TÃ¢ches bloquÃ©es

Aucune tÃ¢che bloquÃ©e.

"@
    }
    
    # Ajouter le rapport complet si demandÃ©
    if ($IncludeFullReport) {
        # GÃ©nÃ©rer un rapport complet
        $reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-RoadmapJournalReport.ps1"
        $reportPath = & $reportScriptPath -Format "Markdown" -OutputFolder $configPath
        
        if ($reportPath -and (Test-Path -Path $reportPath)) {
            $reportContent = Get-Content -Path $reportPath -Raw
            
            $content += @"

---

# Rapport complet

$reportContent

"@
        }
    }
    
    return $content
}

# Fonction pour envoyer une notification par email
function Send-EmailNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$To
    )
    
    try {
        # VÃ©rifier si le module Send-MailMessage est disponible
        if (-not (Get-Command -Name Send-MailMessage -ErrorAction SilentlyContinue)) {
            Write-Warning "La commande Send-MailMessage n'est pas disponible. L'email ne sera pas envoyÃ©."
            return $false
        }
        
        # Convertir le contenu Markdown en HTML
        $htmlContent = $Content -replace '# (.*)', '<h1>$1</h1>' `
                              -replace '## (.*)', '<h2>$1</h2>' `
                              -replace '### (.*)', '<h3>$1</h3>' `
                              -replace '- (.*)', '<li>$1</li>' `
                              -replace '\n\n', '<br/><br/>'
        
        $htmlContent = "<html><body>$htmlContent</body></html>"
        
        # CrÃ©er le sujet de l'email
        $subject = "Ã‰tat de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
        if ($hasOverdueTasks) {
            $subject = "[URGENT] $subject - TÃ¢ches en retard"
        }
        
        # Envoyer l'email
        Send-MailMessage -To $To `
                         -From "roadmap@email-sender-1.com" `
                         -Subject $subject `
                         -Body $htmlContent `
                         -BodyAsHtml `
                         -SmtpServer "smtp.gmail.com" `
                         -Port 587 `
                         -UseSsl `
                         -Credential (Get-Credential -Message "Entrez les identifiants pour l'envoi d'email")
        
        Write-Host "Notification envoyÃ©e par email Ã  $To" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'envoi de l'email: $_"
        return $false
    }
}

# Fonction pour envoyer une notification via Teams
function Send-TeamsNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$WebhookUrl
    )
    
    try {
        # Convertir le contenu Markdown pour Teams
        $teamsContent = $Content
        
        # CrÃ©er le message Teams
        $payload = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "summary" = "Ã‰tat de la Roadmap"
            "themeColor" = if ($hasOverdueTasks) { "FF0000" } else { "0078D7" }
            "title" = "Ã‰tat de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
            "sections" = @(
                @{
                    "text" = $teamsContent
                }
            )
        }
        
        # Envoyer la notification
        $jsonPayload = $payload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        
        Write-Host "Notification envoyÃ©e via Teams" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'envoi de la notification Teams: $_"
        return $false
    }
}

# Fonction pour envoyer une notification via Slack
function Send-SlackNotification {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [string]$WebhookUrl
    )
    
    try {
        # Convertir le contenu Markdown pour Slack
        $slackContent = $Content
        
        # CrÃ©er le message Slack
        $payload = @{
            "text" = "Ã‰tat de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
            "blocks" = @(
                @{
                    "type" = "section"
                    "text" = @{
                        "type" = "mrkdwn"
                        "text" = $slackContent
                    }
                }
            )
        }
        
        # Envoyer la notification
        $jsonPayload = $payload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        
        Write-Host "Notification envoyÃ©e via Slack" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'envoi de la notification Slack: $_"
        return $false
    }
}

# GÃ©nÃ©rer le contenu de la notification
$notificationContent = Get-NotificationContent

# Envoyer les notifications selon le type spÃ©cifiÃ©
switch ($NotificationType) {
    "Email" {
        Send-EmailNotification -Content $notificationContent -To $EmailTo
    }
    "Teams" {
        if (-not $TeamsWebhookUrl) {
            $webhookPath = Join-Path -Path $configPath -ChildPath "teams_webhook.txt"
            if (Test-Path -Path $webhookPath) {
                $TeamsWebhookUrl = Get-Content -Path $webhookPath -Raw
            }
            else {
                Write-Warning "URL du webhook Teams non spÃ©cifiÃ©e et non trouvÃ©e dans le fichier de configuration."
                break
            }
        }
        
        Send-TeamsNotification -Content $notificationContent -WebhookUrl $TeamsWebhookUrl
    }
    "Slack" {
        if (-not $SlackWebhookUrl) {
            $webhookPath = Join-Path -Path $configPath -ChildPath "slack_webhook.txt"
            if (Test-Path -Path $webhookPath) {
                $SlackWebhookUrl = Get-Content -Path $webhookPath -Raw
            }
            else {
                Write-Warning "URL du webhook Slack non spÃ©cifiÃ©e et non trouvÃ©e dans le fichier de configuration."
                break
            }
        }
        
        Send-SlackNotification -Content $notificationContent -WebhookUrl $SlackWebhookUrl
    }
    "All" {
        Send-EmailNotification -Content $notificationContent -To $EmailTo
        
        if (-not $TeamsWebhookUrl) {
            $webhookPath = Join-Path -Path $configPath -ChildPath "teams_webhook.txt"
            if (Test-Path -Path $webhookPath) {
                $TeamsWebhookUrl = Get-Content -Path $webhookPath -Raw
                Send-TeamsNotification -Content $notificationContent -WebhookUrl $TeamsWebhookUrl
            }
        }
        else {
            Send-TeamsNotification -Content $notificationContent -WebhookUrl $TeamsWebhookUrl
        }
        
        if (-not $SlackWebhookUrl) {
            $webhookPath = Join-Path -Path $configPath -ChildPath "slack_webhook.txt"
            if (Test-Path -Path $webhookPath) {
                $SlackWebhookUrl = Get-Content -Path $webhookPath -Raw
                Send-SlackNotification -Content $notificationContent -WebhookUrl $SlackWebhookUrl
            }
        }
        else {
            Send-SlackNotification -Content $notificationContent -WebhookUrl $SlackWebhookUrl
        }
    }
}

Write-Host "`nEnvoi des notifications terminÃ©." -ForegroundColor Green
