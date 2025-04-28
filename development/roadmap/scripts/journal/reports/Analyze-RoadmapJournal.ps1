#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse le journal de la roadmap et gÃ©nÃ¨re des statistiques.
.DESCRIPTION
    Ce script analyse les entrÃ©es du journal de la roadmap pour gÃ©nÃ©rer
    des statistiques et des visualisations sur l'Ã©tat du projet.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCharts,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "Roadmap\journal\reports"
)

# Importer le module de gestion du journal
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\RoadmapJournalManager.psm1"
Import-Module $modulePath -Force

# Chemins des fichiers et dossiers
$journalRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Roadmap\journal"
$indexPath = Join-Path -Path $journalRoot -ChildPath "index.json"
$statusPath = Join-Path -Path $journalRoot -ChildPath "status.json"
$sectionsPath = Join-Path -Path $journalRoot -ChildPath "sections"
$archivesPath = Join-Path -Path $journalRoot -ChildPath "archives"

# CrÃ©er le dossier de rapports si nÃ©cessaire
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Mettre Ã  jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Fonction pour calculer les statistiques par section
function Get-SectionStatistics {
    $sectionStats = @{}

    # Parcourir toutes les entrÃ©es actives
    foreach ($entryId in $index.entries.PSObject.Properties.Name) {
        $entryPath = $index.entries.$entryId
        $entry = Get-Content -Path $entryPath -Raw | ConvertFrom-Json

        # Extraire la section principale (premier niveau de l'ID)
        $sectionId = ($entry.id -split '\.')[0]

        # Initialiser la section si elle n'existe pas
        if (-not $sectionStats.ContainsKey($sectionId)) {
            $sectionStats[$sectionId] = @{
                Total             = 0
                NotStarted        = 0
                InProgress        = 0
                Completed         = 0
                Blocked           = 0
                OverdueTasks      = 0
                UpcomingDeadlines = 0
                EstimatedHours    = 0
                CompletedHours    = 0
            }
        }

        # IncrÃ©menter les compteurs
        $sectionStats[$sectionId].Total++

        # IncrÃ©menter le compteur de statut
        switch ($entry.status) {
            "NotStarted" { $sectionStats[$sectionId].NotStarted++ }
            "InProgress" { $sectionStats[$sectionId].InProgress++ }
            "Completed" { $sectionStats[$sectionId].Completed++ }
            "Blocked" { $sectionStats[$sectionId].Blocked++ }
        }

        # VÃ©rifier si la tÃ¢che est en retard
        if ($entry.metadata.dueDate -and $entry.status -ne "Completed") {
            $dueDate = [DateTime]::Parse($entry.metadata.dueDate)
            if ($dueDate -lt (Get-Date)) {
                $sectionStats[$sectionId].OverdueTasks++
            } elseif ($dueDate -lt (Get-Date).AddDays(7)) {
                $sectionStats[$sectionId].UpcomingDeadlines++
            }
        }

        # Ajouter les heures estimÃ©es
        if ($entry.metadata.estimatedHours) {
            $sectionStats[$sectionId].EstimatedHours += $entry.metadata.estimatedHours

            # Ajouter les heures complÃ©tÃ©es si la tÃ¢che est terminÃ©e
            if ($entry.status -eq "Completed") {
                $sectionStats[$sectionId].CompletedHours += $entry.metadata.estimatedHours
            }
        }
    }

    # Parcourir les archives pour complÃ©ter les statistiques
    $archiveFolders = Get-ChildItem -Path $archivesPath -Directory

    foreach ($folder in $archiveFolders) {
        $archiveFiles = Get-ChildItem -Path $folder.FullName -Filter "*.json"

        foreach ($file in $archiveFiles) {
            $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

            # Extraire la section principale (premier niveau de l'ID)
            $sectionId = ($entry.id -split '\.')[0]

            # Initialiser la section si elle n'existe pas
            if (-not $sectionStats.ContainsKey($sectionId)) {
                $sectionStats[$sectionId] = @{
                    Total             = 0
                    NotStarted        = 0
                    InProgress        = 0
                    Completed         = 0
                    Blocked           = 0
                    OverdueTasks      = 0
                    UpcomingDeadlines = 0
                    EstimatedHours    = 0
                    CompletedHours    = 0
                }
            }

            # IncrÃ©menter les compteurs (uniquement pour les tÃ¢ches complÃ©tÃ©es)
            $sectionStats[$sectionId].Total++
            $sectionStats[$sectionId].Completed++

            # Ajouter les heures estimÃ©es et complÃ©tÃ©es
            if ($entry.metadata.estimatedHours) {
                $sectionStats[$sectionId].EstimatedHours += $entry.metadata.estimatedHours
                $sectionStats[$sectionId].CompletedHours += $entry.metadata.estimatedHours
            }
        }
    }

    return $sectionStats
}

# Fonction pour calculer les statistiques par mois
function Get-MonthlyStatistics {
    $monthlyStats = @{}

    # Parcourir les archives pour obtenir les statistiques mensuelles
    $archiveFolders = Get-ChildItem -Path $archivesPath -Directory

    foreach ($folder in $archiveFolders) {
        $month = $folder.Name
        $archiveFiles = Get-ChildItem -Path $folder.FullName -Filter "*.json"

        $monthlyStats[$month] = @{
            CompletedTasks = $archiveFiles.Count
            EstimatedHours = 0
        }

        foreach ($file in $archiveFiles) {
            $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

            # Ajouter les heures estimÃ©es
            if ($entry.metadata.estimatedHours) {
                $monthlyStats[$month].EstimatedHours += $entry.metadata.estimatedHours
            }
        }
    }

    return $monthlyStats
}

# Fonction pour calculer les prÃ©visions
function Get-ProjectForecasts {
    $sectionStats = Get-SectionStatistics
    $forecasts = @{}

    foreach ($sectionId in $sectionStats.Keys) {
        $section = $sectionStats[$sectionId]

        # Calculer le pourcentage de progression
        if ($section.Total -gt 0) {
            $progressPercentage = [math]::Round(($section.Completed / $section.Total) * 100)
        } else {
            $progressPercentage = 0
        }

        # Calculer la vitesse moyenne (heures complÃ©tÃ©es par jour)
        $completionDates = @()
        $archiveFolders = Get-ChildItem -Path $archivesPath -Directory

        foreach ($folder in $archiveFolders) {
            $archiveFiles = Get-ChildItem -Path $folder.FullName -Filter "*.json"

            foreach ($file in $archiveFiles) {
                $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

                # VÃ©rifier si l'entrÃ©e appartient Ã  cette section
                if (($entry.id -split '\.')[0] -eq $sectionId -and $entry.metadata.completionDate) {
                    $completionDates += [DateTime]::Parse($entry.metadata.completionDate)
                }
            }
        }

        # Calculer la vitesse moyenne si nous avons des dates d'achÃ¨vement
        if ($completionDates.Count -gt 0) {
            $completionDates = $completionDates | Sort-Object
            $firstDate = $completionDates[0]
            $lastDate = $completionDates[-1]

            $daysDifference = ($lastDate - $firstDate).Days
            if ($daysDifference -gt 0) {
                $tasksPerDay = $completionDates.Count / $daysDifference
                $hoursPerDay = $section.CompletedHours / $daysDifference
            } else {
                $tasksPerDay = $completionDates.Count
                $hoursPerDay = $section.CompletedHours
            }

            # Calculer la date d'achÃ¨vement prÃ©vue
            $remainingTasks = $section.Total - $section.Completed
            $remainingHours = $section.EstimatedHours - $section.CompletedHours

            if ($tasksPerDay -gt 0 -and $hoursPerDay -gt 0) {
                $daysToCompleteTasks = $remainingTasks / $tasksPerDay
                $daysToCompleteHours = $remainingHours / $hoursPerDay

                # Prendre la plus grande des deux estimations
                $daysToComplete = [math]::Max($daysToCompleteTasks, $daysToCompleteHours)
                $estimatedCompletionDate = (Get-Date).AddDays($daysToComplete)

                $forecasts[$sectionId] = @{
                    ProgressPercentage      = $progressPercentage
                    TasksPerDay             = $tasksPerDay
                    HoursPerDay             = $hoursPerDay
                    RemainingTasks          = $remainingTasks
                    RemainingHours          = $remainingHours
                    DaysToComplete          = $daysToComplete
                    EstimatedCompletionDate = $estimatedCompletionDate.ToString("yyyy-MM-dd")
                }
            }
        }
    }

    return $forecasts
}

# GÃ©nÃ©rer les statistiques
$sectionStats = Get-SectionStatistics
$monthlyStats = Get-MonthlyStatistics
$forecasts = Get-ProjectForecasts

# Afficher les statistiques globales
Write-Host "`n===== ANALYSE DU JOURNAL DE LA ROADMAP =====" -ForegroundColor Cyan
Write-Host "DerniÃ¨re mise Ã  jour: $($status.lastUpdated)" -ForegroundColor Gray

Write-Host "`n>> STATISTIQUES GLOBALES" -ForegroundColor Cyan
Write-Host "Progression globale: $($status.globalProgress)%"
Write-Host "Total des tÃ¢ches: $($index.statistics.totalEntries)"
Write-Host "TÃ¢ches non commencÃ©es: $($index.statistics.notStarted)" -ForegroundColor Gray
Write-Host "TÃ¢ches en cours: $($index.statistics.inProgress)" -ForegroundColor Yellow
Write-Host "TÃ¢ches terminÃ©es: $($index.statistics.completed)" -ForegroundColor Green
Write-Host "TÃ¢ches bloquÃ©es: $($index.statistics.blocked)" -ForegroundColor Red

# Afficher les statistiques par section
Write-Host "`n>> STATISTIQUES PAR SECTION" -ForegroundColor Cyan
foreach ($sectionId in $sectionStats.Keys | Sort-Object) {
    $section = $sectionStats[$sectionId]

    # Calculer le pourcentage de progression
    if ($section.Total -gt 0) {
        $progressPercentage = [math]::Round(($section.Completed / $section.Total) * 100)
    } else {
        $progressPercentage = 0
    }

    Write-Host "Section $sectionId : $progressPercentage% ($($section.Completed)/$($section.Total))"
    Write-Host "  Heures estimÃ©es: $($section.EstimatedHours) heures"
    Write-Host "  Heures complÃ©tÃ©es: $($section.CompletedHours) heures"

    if ($section.OverdueTasks -gt 0) {
        Write-Host "  TÃ¢ches en retard: $($section.OverdueTasks)" -ForegroundColor Red
    }

    if ($section.UpcomingDeadlines -gt 0) {
        Write-Host "  Ã‰chÃ©ances Ã  venir: $($section.UpcomingDeadlines)" -ForegroundColor Yellow
    }

    if ($forecasts.ContainsKey($sectionId)) {
        Write-Host "  Date d'achÃ¨vement prÃ©vue: $($forecasts[$sectionId].EstimatedCompletionDate)" -ForegroundColor Cyan
    }
}

# Afficher les statistiques mensuelles
Write-Host "`n>> STATISTIQUES MENSUELLES" -ForegroundColor Cyan
foreach ($month in $monthlyStats.Keys | Sort-Object) {
    $stats = $monthlyStats[$month]
    Write-Host "$month : $($stats.CompletedTasks) tÃ¢ches terminÃ©es ($($stats.EstimatedHours) heures)"
}

# GÃ©nÃ©rer un rapport JSON
$report = @{
    GeneratedAt  = (Get-Date).ToUniversalTime().ToString("o")
    GlobalStats  = @{
        Progress          = $status.globalProgress
        TotalTasks        = $index.statistics.totalEntries
        NotStarted        = $index.statistics.notStarted
        InProgress        = $index.statistics.inProgress
        Completed         = $index.statistics.completed
        Blocked           = $index.statistics.blocked
        OverdueTasks      = $status.overdueTasks.Count
        UpcomingDeadlines = $status.upcomingDeadlines.Count
    }
    SectionStats = $sectionStats
    MonthlyStats = $monthlyStats
    Forecasts    = $forecasts
}

# Enregistrer le rapport JSON
$reportPath = Join-Path -Path $OutputFolder -ChildPath "roadmap_analysis.json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding utf8 -Force

Write-Host "`nRapport d'analyse enregistrÃ©: $reportPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport Markdown
$markdownReport = @"
# Rapport d'analyse de la roadmap

*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Statistiques globales

- **Progression globale**: $($status.globalProgress)%
- **Total des tÃ¢ches**: $($index.statistics.totalEntries)
- **TÃ¢ches non commencÃ©es**: $($index.statistics.notStarted)
- **TÃ¢ches en cours**: $($index.statistics.inProgress)
- **TÃ¢ches terminÃ©es**: $($index.statistics.completed)
- **TÃ¢ches bloquÃ©es**: $($index.statistics.blocked)

## Statistiques par section

| Section | Progression | TÃ¢ches | Heures estimÃ©es | Heures complÃ©tÃ©es | Date d'achÃ¨vement prÃ©vue |
|---------|-------------|--------|-----------------|-------------------|--------------------------|
$(
    ($sectionStats.Keys | Sort-Object) | ForEach-Object {
        $section = $sectionStats[$_]
        $progressPercentage = if ($section.Total -gt 0) { [math]::Round(($section.Completed / $section.Total) * 100) } else { 0 }
        $estimatedDate = if ($forecasts.ContainsKey($_)) { $forecasts[$_].EstimatedCompletionDate } else { "N/A" }
        "| $_ | $progressPercentage% | $($section.Completed)/$($section.Total) | $($section.EstimatedHours) | $($section.CompletedHours) | $estimatedDate |"
    }
)

## TÃ¢ches en retard

$(
    if ($status.overdueTasks.Count -eq 0) {
        "Aucune tÃ¢che en retard."
    }
    else {
        "| ID | Titre | Date d'Ã©chÃ©ance | Jours de retard |`n|---|-------|----------------|----------------|`n" +
        ($status.overdueTasks | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysOverdue) |"
        })
    }
)

## Prochaines Ã©chÃ©ances

$(
    if ($status.upcomingDeadlines.Count -eq 0) {
        "Aucune Ã©chÃ©ance Ã  venir dans les 7 prochains jours."
    }
    else {
        "| ID | Titre | Date d'Ã©chÃ©ance | Jours restants |`n|---|-------|----------------|----------------|`n" +
        ($status.upcomingDeadlines | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysRemaining) |"
        })
    }
)

## Statistiques mensuelles

| Mois | TÃ¢ches terminÃ©es | Heures |
|------|------------------|--------|
$(
    ($monthlyStats.Keys | Sort-Object) | ForEach-Object {
        $stats = $monthlyStats[$_]
        "| $_ | $($stats.CompletedTasks) | $($stats.EstimatedHours) |"
    }
)

## PrÃ©visions

$(
    if ($forecasts.Count -eq 0) {
        "DonnÃ©es insuffisantes pour gÃ©nÃ©rer des prÃ©visions."
    }
    else {
        "| Section | TÃ¢ches restantes | Heures restantes | TÃ¢ches/jour | Heures/jour | Jours restants | Date d'achÃ¨vement |`n|---------|-----------------|-----------------|------------|-------------|---------------|-------------------|`n" +
        ($forecasts.Keys | Sort-Object) | ForEach-Object {
            $forecast = $forecasts[$_]
            "| $_ | $($forecast.RemainingTasks) | $($forecast.RemainingHours) | $([math]::Round($forecast.TasksPerDay, 2)) | $([math]::Round($forecast.HoursPerDay, 2)) | $([math]::Round($forecast.DaysToComplete)) | $($forecast.EstimatedCompletionDate) |"
        }
    }
)
"@

# Enregistrer le rapport Markdown
$markdownPath = Join-Path -Path $OutputFolder -ChildPath "roadmap_analysis.md"
$markdownReport | Out-File -FilePath $markdownPath -Encoding utf8 -Force

Write-Host "Rapport Markdown enregistrÃ©: $markdownPath" -ForegroundColor Green

# GÃ©nÃ©rer des graphiques si demandÃ©
if ($GenerateCharts) {
    # VÃ©rifier si le module PSGraph est installÃ©
    if (-not (Get-Module -ListAvailable -Name PSGraph)) {
        Write-Warning "Le module PSGraph n'est pas installÃ©. Les graphiques ne seront pas gÃ©nÃ©rÃ©s."
        Write-Warning "Pour installer PSGraph, exÃ©cutez: Install-Module -Name PSGraph -Scope CurrentUser"
    } else {
        Import-Module PSGraph

        # CrÃ©er un graphique de progression par section
        $progressGraph = Graph {
            Node @{shape = 'record' }

            foreach ($sectionId in $sectionStats.Keys | Sort-Object) {
                $section = $sectionStats[$sectionId]
                $progressPercentage = if ($section.Total -gt 0) { [math]::Round(($section.Completed / $section.Total) * 100) } else { 0 }

                Node "Section_$sectionId" @{
                    label     = "Section $sectionId | $progressPercentage%"
                    style     = 'filled'
                    fillcolor = if ($progressPercentage -ge 75) { 'green' } elseif ($progressPercentage -ge 50) { 'yellow' } elseif ($progressPercentage -ge 25) { 'orange' } else { 'red' }
                }
            }
        }

        # Enregistrer le graphique
        $graphPath = Join-Path -Path $OutputFolder -ChildPath "section_progress.png"
        $progressGraph | Export-PSGraph -OutputFormat png -DestinationPath $graphPath

        Write-Host "Graphique de progression enregistrÃ©: $graphPath" -ForegroundColor Green
    }
}

Write-Host "`nAnalyse terminÃ©e avec succÃ¨s." -ForegroundColor Green
