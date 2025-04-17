#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche un tableau de bord de l'état de la roadmap.
.DESCRIPTION
    Ce script génère et affiche un tableau de bord avec des statistiques
    sur l'état de la roadmap, les tâches en retard, et les prochaines échéances.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [switch]$ExportToHtml,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "Roadmap\journal\dashboard.html"
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$statusPath = Join-Path -Path $journalRoot -ChildPath "status.json"

# Mettre à jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Fonction pour générer une barre de progression colorée
function Get-ProgressBar {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Percentage,
        
        [Parameter(Mandatory=$false)]
        [int]$Width = 50
    )
    
    $completed = [math]::Round(($Percentage / 100) * $Width)
    $remaining = $Width - $completed
    
    $color = switch ($true) {
        ($Percentage -lt 25) { "Red" }
        ($Percentage -lt 50) { "Yellow" }
        ($Percentage -lt 75) { "Cyan" }
        default { "Green" }
    }
    
    $progressBar = "[" + ("=" * $completed) + (" " * $remaining) + "] $Percentage%"
    
    return @{
        Text = $progressBar
        Color = $color
    }
}

# Afficher le titre
Write-Host "`n===== TABLEAU DE BORD DE LA ROADMAP =====" -ForegroundColor Cyan
Write-Host "Dernière mise à jour: $($status.lastUpdated)" -ForegroundColor Gray

# Afficher la progression globale
Write-Host "`n>> PROGRESSION GLOBALE" -ForegroundColor Cyan
$progressBar = Get-ProgressBar -Percentage $status.globalProgress
Write-Host $progressBar.Text -ForegroundColor $progressBar.Color

# Afficher les statistiques
Write-Host "`n>> STATISTIQUES" -ForegroundColor Cyan
Write-Host "Total des tâches: $($index.statistics.totalEntries)"
Write-Host "Tâches non commencées: $($index.statistics.notStarted)" -ForegroundColor Gray
Write-Host "Tâches en cours: $($index.statistics.inProgress)" -ForegroundColor Yellow
Write-Host "Tâches terminées: $($index.statistics.completed)" -ForegroundColor Green
Write-Host "Tâches bloquées: $($index.statistics.blocked)" -ForegroundColor Red

# Afficher les tâches en retard
Write-Host "`n>> TÂCHES EN RETARD" -ForegroundColor Cyan
if ($status.overdueTasks.Count -eq 0) {
    Write-Host "Aucune tâche en retard." -ForegroundColor Green
}
else {
    foreach ($task in $status.overdueTasks) {
        Write-Host "$($task.id): $($task.title)" -ForegroundColor Red
        Write-Host "  Date d'échéance: $($task.dueDate) (En retard de $($task.daysOverdue) jours)" -ForegroundColor Red
    }
}

# Afficher les prochaines échéances
Write-Host "`n>> PROCHAINES ÉCHÉANCES" -ForegroundColor Cyan
if ($status.upcomingDeadlines.Count -eq 0) {
    Write-Host "Aucune échéance à venir dans les 7 prochains jours." -ForegroundColor Gray
}
else {
    foreach ($task in $status.upcomingDeadlines) {
        Write-Host "$($task.id): $($task.title)" -ForegroundColor Yellow
        Write-Host "  Date d'échéance: $($task.dueDate) (Dans $($task.daysRemaining) jours)" -ForegroundColor Yellow
    }
}

# Afficher les tâches bloquées
Write-Host "`n>> TÂCHES BLOQUÉES" -ForegroundColor Cyan
if ($status.blockedTasks.Count -eq 0) {
    Write-Host "Aucune tâche bloquée." -ForegroundColor Green
}
else {
    foreach ($task in $status.blockedTasks) {
        Write-Host "$($task.id): $($task.title)" -ForegroundColor Red
    }
}

# Exporter en HTML si demandé
if ($ExportToHtml) {
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de bord de la Roadmap</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1, h2 {
            color: #2c3e50;
        }
        .dashboard-header {
            background-color: #34495e;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .dashboard-section {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .progress-container {
            width: 100%;
            background-color: #e0e0e0;
            border-radius: 5px;
            margin: 10px 0;
        }
        .progress-bar {
            height: 30px;
            border-radius: 5px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .stat-card {
            background-color: #f9f9f9;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .task-list {
            list-style-type: none;
            padding: 0;
        }
        .task-item {
            padding: 10px;
            border-left: 4px solid #3498db;
            background-color: #f9f9f9;
            margin-bottom: 10px;
            border-radius: 0 5px 5px 0;
        }
        .task-item.overdue {
            border-left-color: #e74c3c;
        }
        .task-item.upcoming {
            border-left-color: #f39c12;
        }
        .task-item.blocked {
            border-left-color: #e74c3c;
            background-color: #fadbd8;
        }
        .task-meta {
            font-size: 0.9em;
            color: #7f8c8d;
            margin-top: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="dashboard-header">
        <h1>Tableau de bord de la Roadmap</h1>
        <p>Dernière mise à jour: $($status.lastUpdated)</p>
    </div>
    
    <div class="dashboard-section">
        <h2>Progression globale</h2>
        <div class="progress-container">
            <div class="progress-bar" style="width: $($status.globalProgress)%; background-color: $(
                switch ($true) {
                    ($status.globalProgress -lt 25) { "#e74c3c" }
                    ($status.globalProgress -lt 50) { "#f39c12" }
                    ($status.globalProgress -lt 75) { "#3498db" }
                    default { "#2ecc71" }
                }
            );">
                $($status.globalProgress)%
            </div>
        </div>
    </div>
    
    <div class="dashboard-section">
        <h2>Statistiques</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total</h3>
                <div class="stat-value">$($index.statistics.totalEntries)</div>
                <p>Tâches</p>
            </div>
            <div class="stat-card">
                <h3>Non commencées</h3>
                <div class="stat-value" style="color: #7f8c8d;">$($index.statistics.notStarted)</div>
                <p>Tâches</p>
            </div>
            <div class="stat-card">
                <h3>En cours</h3>
                <div class="stat-value" style="color: #f39c12;">$($index.statistics.inProgress)</div>
                <p>Tâches</p>
            </div>
            <div class="stat-card">
                <h3>Terminées</h3>
                <div class="stat-value" style="color: #2ecc71;">$($index.statistics.completed)</div>
                <p>Tâches</p>
            </div>
            <div class="stat-card">
                <h3>Bloquées</h3>
                <div class="stat-value" style="color: #e74c3c;">$($index.statistics.blocked)</div>
                <p>Tâches</p>
            </div>
        </div>
    </div>
    
    <div class="dashboard-section">
        <h2>Tâches en retard</h2>
        $(
            if ($status.overdueTasks.Count -eq 0) {
                '<p style="color: #2ecc71;">Aucune tâche en retard.</p>'
            }
            else {
                '<ul class="task-list">'
                foreach ($task in $status.overdueTasks) {
                    @"
                    <li class="task-item overdue">
                        <strong>$($task.id): $($task.title)</strong>
                        <div class="task-meta">Date d'échéance: $($task.dueDate) (En retard de $($task.daysOverdue) jours)</div>
                    </li>
"@
                }
                '</ul>'
            }
        )
    </div>
    
    <div class="dashboard-section">
        <h2>Prochaines échéances</h2>
        $(
            if ($status.upcomingDeadlines.Count -eq 0) {
                '<p style="color: #7f8c8d;">Aucune échéance à venir dans les 7 prochains jours.</p>'
            }
            else {
                '<ul class="task-list">'
                foreach ($task in $status.upcomingDeadlines) {
                    @"
                    <li class="task-item upcoming">
                        <strong>$($task.id): $($task.title)</strong>
                        <div class="task-meta">Date d'échéance: $($task.dueDate) (Dans $($task.daysRemaining) jours)</div>
                    </li>
"@
                }
                '</ul>'
            }
        )
    </div>
    
    <div class="dashboard-section">
        <h2>Tâches bloquées</h2>
        $(
            if ($status.blockedTasks.Count -eq 0) {
                '<p style="color: #2ecc71;">Aucune tâche bloquée.</p>'
            }
            else {
                '<ul class="task-list">'
                foreach ($task in $status.blockedTasks) {
                    @"
                    <li class="task-item blocked">
                        <strong>$($task.id): $($task.title)</strong>
                    </li>
"@
                }
                '</ul>'
            }
        )
    </div>
    
    <div class="footer">
        <p>Généré par le système de journalisation de la roadmap EMAIL_SENDER_1</p>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "`nTableau de bord exporté en HTML: $OutputPath" -ForegroundColor Green
    
    # Ouvrir le fichier HTML dans le navigateur par défaut
    Start-Process $OutputPath
}
