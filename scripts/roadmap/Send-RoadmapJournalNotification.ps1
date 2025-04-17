#Requires -Version 5.1
<#
.SYNOPSIS
    Envoie des notifications sur l'état de la roadmap.
.DESCRIPTION
    Ce script envoie des notifications par email ou via Teams/Slack
    sur l'état de la roadmap, les tâches en retard, et les prochaines échéances.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
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

# Créer le dossier de configuration si nécessaire
if (-not (Test-Path -Path $configPath)) {
    New-Item -Path $configPath -ItemType Directory -Force | Out-Null
}

# Mettre à jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Vérifier s'il y a des tâches en retard
$hasOverdueTasks = $status.overdueTasks.Count -gt 0

# Si OnlyIfOverdue est spécifié et qu'il n'y a pas de tâches en retard, quitter
if ($OnlyIfOverdue -and -not $hasOverdueTasks) {
    Write-Host "Aucune tâche en retard. Aucune notification envoyée." -ForegroundColor Green
    exit 0
}

# Fonction pour générer le contenu de la notification
function Get-NotificationContent {
    $content = @"
# État de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")

## Résumé

- Progression globale: $($status.globalProgress)%
- Total des tâches: $($index.statistics.totalEntries)
- Tâches non commencées: $($index.statistics.notStarted)
- Tâches en cours: $($index.statistics.inProgress)
- Tâches terminées: $($index.statistics.completed)
- Tâches bloquées: $($index.statistics.blocked)

"@
    
    # Ajouter les tâches en retard
    if ($status.overdueTasks.Count -gt 0) {
        $content += @"
## Tâches en retard

"@
        
        foreach ($task in $status.overdueTasks) {
            $content += @"
- $($task.id): $($task.title) - En retard de $($task.daysOverdue) jours (Échéance: $($task.dueDate))

"@
        }
    }
    else {
        $content += @"
## Tâches en retard

Aucune tâche en retard.

"@
    }
    
    # Ajouter les prochaines échéances
    if ($status.upcomingDeadlines.Count -gt 0) {
        $content += @"
## Prochaines échéances

"@
        
        foreach ($task in $status.upcomingDeadlines) {
            $content += @"
- $($task.id): $($task.title) - Dans $($task.daysRemaining) jours (Échéance: $($task.dueDate))

"@
        }
    }
    else {
        $content += @"
## Prochaines échéances

Aucune échéance à venir dans les 7 prochains jours.

"@
    }
    
    # Ajouter les tâches bloquées
    if ($status.blockedTasks.Count -gt 0) {
        $content += @"
## Tâches bloquées

"@
        
        foreach ($task in $status.blockedTasks) {
            $content += @"
- $($task.id): $($task.title)

"@
        }
    }
    else {
        $content += @"
## Tâches bloquées

Aucune tâche bloquée.

"@
    }
    
    # Ajouter le rapport complet si demandé
    if ($IncludeFullReport) {
        # Générer un rapport complet
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
        # Vérifier si le module Send-MailMessage est disponible
        if (-not (Get-Command -Name Send-MailMessage -ErrorAction SilentlyContinue)) {
            Write-Warning "La commande Send-MailMessage n'est pas disponible. L'email ne sera pas envoyé."
            return $false
        }
        
        # Convertir le contenu Markdown en HTML
        $htmlContent = $Content -replace '# (.*)', '<h1>$1</h1>' `
                              -replace '## (.*)', '<h2>$1</h2>' `
                              -replace '### (.*)', '<h3>$1</h3>' `
                              -replace '- (.*)', '<li>$1</li>' `
                              -replace '\n\n', '<br/><br/>'
        
        $htmlContent = "<html><body>$htmlContent</body></html>"
        
        # Créer le sujet de l'email
        $subject = "État de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
        if ($hasOverdueTasks) {
            $subject = "[URGENT] $subject - Tâches en retard"
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
        
        Write-Host "Notification envoyée par email à $To" -ForegroundColor Green
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
        
        # Créer le message Teams
        $payload = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "summary" = "État de la Roadmap"
            "themeColor" = if ($hasOverdueTasks) { "FF0000" } else { "0078D7" }
            "title" = "État de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
            "sections" = @(
                @{
                    "text" = $teamsContent
                }
            )
        }
        
        # Envoyer la notification
        $jsonPayload = $payload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        
        Write-Host "Notification envoyée via Teams" -ForegroundColor Green
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
        
        # Créer le message Slack
        $payload = @{
            "text" = "État de la Roadmap - $(Get-Date -Format "yyyy-MM-dd")"
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
        
        Write-Host "Notification envoyée via Slack" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'envoi de la notification Slack: $_"
        return $false
    }
}

# Générer le contenu de la notification
$notificationContent = Get-NotificationContent

# Envoyer les notifications selon le type spécifié
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
                Write-Warning "URL du webhook Teams non spécifiée et non trouvée dans le fichier de configuration."
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
                Write-Warning "URL du webhook Slack non spécifiée et non trouvée dans le fichier de configuration."
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

Write-Host "`nEnvoi des notifications terminé." -ForegroundColor Green
