#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse le journal de la roadmap et génère des statistiques.
.DESCRIPTION
    Ce script analyse les entrées du journal de la roadmap pour générer
    des statistiques et des visualisations sur l'état du projet.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-16
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

# Créer le dossier de rapports si nécessaire
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Mettre à jour le statut global
$status = Get-RoadmapJournalStatus

# Charger l'index
$index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json

# Fonction pour calculer les statistiques par section
function Get-SectionStatistics {
    $sectionStats = @{}

    # Parcourir toutes les entrées actives
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

        # Incrémenter les compteurs
        $sectionStats[$sectionId].Total++

        # Incrémenter le compteur de statut
        switch ($entry.status) {
            "NotStarted" { $sectionStats[$sectionId].NotStarted++ }
            "InProgress" { $sectionStats[$sectionId].InProgress++ }
            "Completed" { $sectionStats[$sectionId].Completed++ }
            "Blocked" { $sectionStats[$sectionId].Blocked++ }
        }

        # Vérifier si la tâche est en retard
        if ($entry.metadata.dueDate -and $entry.status -ne "Completed") {
            $dueDate = [DateTime]::Parse($entry.metadata.dueDate)
            if ($dueDate -lt (Get-Date)) {
                $sectionStats[$sectionId].OverdueTasks++
            } elseif ($dueDate -lt (Get-Date).AddDays(7)) {
                $sectionStats[$sectionId].UpcomingDeadlines++
            }
        }

        # Ajouter les heures estimées
        if ($entry.metadata.estimatedHours) {
            $sectionStats[$sectionId].EstimatedHours += $entry.metadata.estimatedHours

            # Ajouter les heures complétées si la tâche est terminée
            if ($entry.status -eq "Completed") {
                $sectionStats[$sectionId].CompletedHours += $entry.metadata.estimatedHours
            }
        }
    }

    # Parcourir les archives pour compléter les statistiques
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

            # Incrémenter les compteurs (uniquement pour les tâches complétées)
            $sectionStats[$sectionId].Total++
            $sectionStats[$sectionId].Completed++

            # Ajouter les heures estimées et complétées
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

            # Ajouter les heures estimées
            if ($entry.metadata.estimatedHours) {
                $monthlyStats[$month].EstimatedHours += $entry.metadata.estimatedHours
            }
        }
    }

    return $monthlyStats
}

# Fonction pour calculer les prévisions
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

        # Calculer la vitesse moyenne (heures complétées par jour)
        $completionDates = @()
        $archiveFolders = Get-ChildItem -Path $archivesPath -Directory

        foreach ($folder in $archiveFolders) {
            $archiveFiles = Get-ChildItem -Path $folder.FullName -Filter "*.json"

            foreach ($file in $archiveFiles) {
                $entry = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

                # Vérifier si l'entrée appartient à cette section
                if (($entry.id -split '\.')[0] -eq $sectionId -and $entry.metadata.completionDate) {
                    $completionDates += [DateTime]::Parse($entry.metadata.completionDate)
                }
            }
        }

        # Calculer la vitesse moyenne si nous avons des dates d'achèvement
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

            # Calculer la date d'achèvement prévue
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

# Générer les statistiques
$sectionStats = Get-SectionStatistics
$monthlyStats = Get-MonthlyStatistics
$forecasts = Get-ProjectForecasts

# Afficher les statistiques globales
Write-Host "`n===== ANALYSE DU JOURNAL DE LA ROADMAP =====" -ForegroundColor Cyan
Write-Host "Dernière mise à jour: $($status.lastUpdated)" -ForegroundColor Gray

Write-Host "`n>> STATISTIQUES GLOBALES" -ForegroundColor Cyan
Write-Host "Progression globale: $($status.globalProgress)%"
Write-Host "Total des tâches: $($index.statistics.totalEntries)"
Write-Host "Tâches non commencées: $($index.statistics.notStarted)" -ForegroundColor Gray
Write-Host "Tâches en cours: $($index.statistics.inProgress)" -ForegroundColor Yellow
Write-Host "Tâches terminées: $($index.statistics.completed)" -ForegroundColor Green
Write-Host "Tâches bloquées: $($index.statistics.blocked)" -ForegroundColor Red

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
    Write-Host "  Heures estimées: $($section.EstimatedHours) heures"
    Write-Host "  Heures complétées: $($section.CompletedHours) heures"

    if ($section.OverdueTasks -gt 0) {
        Write-Host "  Tâches en retard: $($section.OverdueTasks)" -ForegroundColor Red
    }

    if ($section.UpcomingDeadlines -gt 0) {
        Write-Host "  Échéances à venir: $($section.UpcomingDeadlines)" -ForegroundColor Yellow
    }

    if ($forecasts.ContainsKey($sectionId)) {
        Write-Host "  Date d'achèvement prévue: $($forecasts[$sectionId].EstimatedCompletionDate)" -ForegroundColor Cyan
    }
}

# Afficher les statistiques mensuelles
Write-Host "`n>> STATISTIQUES MENSUELLES" -ForegroundColor Cyan
foreach ($month in $monthlyStats.Keys | Sort-Object) {
    $stats = $monthlyStats[$month]
    Write-Host "$month : $($stats.CompletedTasks) tâches terminées ($($stats.EstimatedHours) heures)"
}

# Générer un rapport JSON
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

Write-Host "`nRapport d'analyse enregistré: $reportPath" -ForegroundColor Green

# Générer un rapport Markdown
$markdownReport = @"
# Rapport d'analyse de la roadmap

*Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## Statistiques globales

- **Progression globale**: $($status.globalProgress)%
- **Total des tâches**: $($index.statistics.totalEntries)
- **Tâches non commencées**: $($index.statistics.notStarted)
- **Tâches en cours**: $($index.statistics.inProgress)
- **Tâches terminées**: $($index.statistics.completed)
- **Tâches bloquées**: $($index.statistics.blocked)

## Statistiques par section

| Section | Progression | Tâches | Heures estimées | Heures complétées | Date d'achèvement prévue |
|---------|-------------|--------|-----------------|-------------------|--------------------------|
$(
    ($sectionStats.Keys | Sort-Object) | ForEach-Object {
        $section = $sectionStats[$_]
        $progressPercentage = if ($section.Total -gt 0) { [math]::Round(($section.Completed / $section.Total) * 100) } else { 0 }
        $estimatedDate = if ($forecasts.ContainsKey($_)) { $forecasts[$_].EstimatedCompletionDate } else { "N/A" }
        "| $_ | $progressPercentage% | $($section.Completed)/$($section.Total) | $($section.EstimatedHours) | $($section.CompletedHours) | $estimatedDate |"
    }
)

## Tâches en retard

$(
    if ($status.overdueTasks.Count -eq 0) {
        "Aucune tâche en retard."
    }
    else {
        "| ID | Titre | Date d'échéance | Jours de retard |`n|---|-------|----------------|----------------|`n" +
        ($status.overdueTasks | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysOverdue) |"
        })
    }
)

## Prochaines échéances

$(
    if ($status.upcomingDeadlines.Count -eq 0) {
        "Aucune échéance à venir dans les 7 prochains jours."
    }
    else {
        "| ID | Titre | Date d'échéance | Jours restants |`n|---|-------|----------------|----------------|`n" +
        ($status.upcomingDeadlines | ForEach-Object {
            "| $($_.id) | $($_.title) | $($_.dueDate) | $($_.daysRemaining) |"
        })
    }
)

## Statistiques mensuelles

| Mois | Tâches terminées | Heures |
|------|------------------|--------|
$(
    ($monthlyStats.Keys | Sort-Object) | ForEach-Object {
        $stats = $monthlyStats[$_]
        "| $_ | $($stats.CompletedTasks) | $($stats.EstimatedHours) |"
    }
)

## Prévisions

$(
    if ($forecasts.Count -eq 0) {
        "Données insuffisantes pour générer des prévisions."
    }
    else {
        "| Section | Tâches restantes | Heures restantes | Tâches/jour | Heures/jour | Jours restants | Date d'achèvement |`n|---------|-----------------|-----------------|------------|-------------|---------------|-------------------|`n" +
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

Write-Host "Rapport Markdown enregistré: $markdownPath" -ForegroundColor Green

# Générer des graphiques si demandé
if ($GenerateCharts) {
    # Vérifier si le module PSGraph est installé
    if (-not (Get-Module -ListAvailable -Name PSGraph)) {
        Write-Warning "Le module PSGraph n'est pas installé. Les graphiques ne seront pas générés."
        Write-Warning "Pour installer PSGraph, exécutez: Install-Module -Name PSGraph -Scope CurrentUser"
    } else {
        Import-Module PSGraph

        # Créer un graphique de progression par section
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

        Write-Host "Graphique de progression enregistré: $graphPath" -ForegroundColor Green
    }
}

Write-Host "`nAnalyse terminée avec succès." -ForegroundColor Green
