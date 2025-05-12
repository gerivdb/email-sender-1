# Test-DurationExtraction.ps1
# Script pour tester l'extraction des attributs de durée des tâches
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-duration.json"
)

# Importer le script d'extraction des durées
$scriptPath = $PSScriptRoot
$extractDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-DurationAttributes.ps1"

if (-not (Test-Path -Path $extractDurationScriptPath)) {
    Write-Host "Le script d'extraction des durées n'existe pas: $extractDurationScriptPath" -ForegroundColor Red
    exit 1
}

# Créer un contenu de test avec différentes durées
$testContent = @"
# Test de l'extraction des durées

## Durées en jours/semaines/mois
- [ ] **1.1** Tâche avec durée en jours (durée: 5 jours)
- [ ] **1.2** Tâche avec durée en semaines (durée: 2 semaines)
- [ ] **1.3** Tâche avec durée en mois (durée: 3 mois)
- [ ] **1.4** Tâche avec durée en années (durée: 1 année)
- [ ] **1.5** Tâche avec durée abrégée (#durée:10j)
- [ ] **1.6** Tâche avec expression de durée (prend 7 jours de travail)
- [ ] **1.7** Tâche avec format alternatif (15 jours d'effort)

## Durées en heures/minutes
- [ ] **2.1** Tâche avec durée en heures (durée: 8 heures)
- [ ] **2.2** Tâche avec durée en minutes (durée: 45 minutes)
- [ ] **2.3** Tâche avec durée abrégée (#durée:4h)
- [ ] **2.4** Tâche avec expression de durée (prend 2 heures de travail)
- [ ] **2.5** Tâche avec format alternatif (30 minutes d'effort)

## Durées composées
- [ ] **3.1** Tâche avec durée composée jours/heures (durée: 2 jours 4 heures)
- [ ] **3.2** Tâche avec durée composée heures/minutes (durée: 3 heures 30 minutes)
- [ ] **3.3** Tâche avec expression de durée composée (prend 1 jour et 6 heures de travail)
- [ ] **3.4** Tâche avec format alternatif (5 heures et 15 minutes d'effort)

## Durées avec décimales
- [ ] **4.1** Tâche avec durée décimale en jours (durée: 2.5 jours)
- [ ] **4.2** Tâche avec durée décimale en heures (durée: 1.5 heures)

## Tâches sans durée
- [ ] **5.1** Tâche sans indication de durée
- [ ] **5.2** Tâche avec texte mentionnant le mot durée mais sans valeur
"@

# Exécuter le script d'extraction des durées
Write-Host "Exécution du script d'extraction des durées..." -ForegroundColor Cyan
$results = & $extractDurationScriptPath -Content $testContent -OutputFormat "JSON"

# Afficher les résultats
Write-Host "Résultats de l'extraction des durées:" -ForegroundColor Green
$resultsObj = $results | ConvertFrom-Json

# Afficher les statistiques
Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "- Nombre total de tâches: $($resultsObj.Stats.TotalTasks)" -ForegroundColor Yellow
Write-Host "- Tâches avec durées en jours/semaines/mois: $($resultsObj.Stats.TasksWithDayWeekMonthDurations)" -ForegroundColor Yellow
Write-Host "- Tâches avec durées en heures/minutes: $($resultsObj.Stats.TasksWithHourMinuteDurations)" -ForegroundColor Yellow
Write-Host "- Tâches avec durées composées: $($resultsObj.Stats.TasksWithCompositeDurations)" -ForegroundColor Yellow

# Vérifier les résultats attendus
$expectedDayWeekMonthTasks = @("1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7", "4.1")
$expectedHourMinuteTasks = @("2.1", "2.2", "2.3", "2.4", "2.5", "4.2")
$expectedCompositeTasks = @("3.1", "3.2", "3.3", "3.4")
$expectedNoTasks = @("5.1", "5.2")

# Vérifier les tâches avec durées en jours/semaines/mois
Write-Host "`nVérification des tâches avec durées en jours/semaines/mois:" -ForegroundColor Cyan
$dayWeekMonthTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationAttributes.DayWeekMonth.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingDayWeekMonthTasks = $expectedDayWeekMonthTasks | Where-Object { $_ -notin $dayWeekMonthTasks }
$unexpectedDayWeekMonthTasks = $dayWeekMonthTasks | Where-Object { $_ -notin $expectedDayWeekMonthTasks }

if ($missingDayWeekMonthTasks.Count -eq 0 -and $unexpectedDayWeekMonthTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec durées en jours/semaines/mois ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec durées en jours/semaines/mois:" -ForegroundColor Red
    if ($missingDayWeekMonthTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingDayWeekMonthTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedDayWeekMonthTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedDayWeekMonthTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches avec durées en heures/minutes
Write-Host "`nVérification des tâches avec durées en heures/minutes:" -ForegroundColor Cyan
$hourMinuteTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationAttributes.HourMinute.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingHourMinuteTasks = $expectedHourMinuteTasks | Where-Object { $_ -notin $hourMinuteTasks }
$unexpectedHourMinuteTasks = $hourMinuteTasks | Where-Object { $_ -notin $expectedHourMinuteTasks }

if ($missingHourMinuteTasks.Count -eq 0 -and $unexpectedHourMinuteTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec durées en heures/minutes ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec durées en heures/minutes:" -ForegroundColor Red
    if ($missingHourMinuteTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingHourMinuteTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedHourMinuteTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedHourMinuteTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches avec durées composées
Write-Host "`nVérification des tâches avec durées composées:" -ForegroundColor Cyan
$compositeTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationAttributes.Composite.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingCompositeTasks = $expectedCompositeTasks | Where-Object { $_ -notin $compositeTasks }
$unexpectedCompositeTasks = $compositeTasks | Where-Object { $_ -notin $expectedCompositeTasks }

if ($missingCompositeTasks.Count -eq 0 -and $unexpectedCompositeTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec durées composées ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec durées composées:" -ForegroundColor Red
    if ($missingCompositeTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingCompositeTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedCompositeTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedCompositeTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches sans durée
Write-Host "`nVérification des tâches sans durée:" -ForegroundColor Cyan
$allTasks = $resultsObj.Tasks.PSObject.Properties | Select-Object -ExpandProperty Name
$tasksWithDuration = $dayWeekMonthTasks + $hourMinuteTasks + $compositeTasks | Select-Object -Unique
$tasksWithoutDuration = $allTasks | Where-Object { $_ -notin $tasksWithDuration }
$missingNoTasks = $expectedNoTasks | Where-Object { $_ -notin $tasksWithoutDuration }
$unexpectedNoTasks = $tasksWithoutDuration | Where-Object { $_ -notin $expectedNoTasks }

if ($missingNoTasks.Count -eq 0 -and $unexpectedNoTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches sans durée ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches sans durée:" -ForegroundColor Red
    if ($missingNoTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingNoTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedNoTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedNoTasks -join ', ')" -ForegroundColor Red
    }
}

# Enregistrer les résultats
if (-not [string]::IsNullOrEmpty($OutputPath)) {
    $results | Set-Content -Path $OutputPath
    Write-Host "`nRésultats enregistrés dans $OutputPath" -ForegroundColor Green
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
