# Test-DurationTags.ps1
# Script pour tester l'extraction des tags de durée des tâches
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-duration-tags.json"
)

# Importer le script d'extraction des tags de durée
$scriptPath = $PSScriptRoot
$extractDurationTagsScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-DurationTags.ps1"

if (-not (Test-Path -Path $extractDurationTagsScriptPath)) {
    Write-Host "Le script d'extraction des tags de durée n'existe pas: $extractDurationTagsScriptPath" -ForegroundColor Red
    exit 1
}

# Créer un contenu de test avec différents tags de durée
$testContent = @"
# Test de l'extraction des tags de durée

## Tags de durée en jours
- [ ] **1.1** Tâche avec tag de durée en jours #duration:5d
- [ ] **1.2** Tâche avec tag de durée en jours décimaux #duration:2.5d
- [ ] **1.3** Tâche avec tag de durée en jours et autre texte #duration:7d (estimation)
- [ ] **1.4** Tâche avec plusieurs tags de durée en jours #duration:3d #duration:4d

## Tags de durée en semaines
- [ ] **2.1** Tâche avec tag de durée en semaines #duration:2w
- [ ] **2.2** Tâche avec tag de durée en semaines décimales #duration:1.5w
- [ ] **2.3** Tâche avec tag de durée en semaines et autre texte #duration:3w (estimation)
- [ ] **2.4** Tâche avec plusieurs tags de durée en semaines #duration:1w #duration:2w

## Tags de durée en mois
- [ ] **3.1** Tâche avec tag de durée en mois #duration:1m
- [ ] **3.2** Tâche avec tag de durée en mois décimaux #duration:1.5m
- [ ] **3.3** Tâche avec tag de durée en mois et autre texte #duration:2m (estimation)
- [ ] **3.4** Tâche avec plusieurs tags de durée en mois #duration:1m #duration:3m

## Tags de durée mixtes
- [ ] **4.1** Tâche avec tags de durée mixtes #duration:5d #duration:2w
- [ ] **4.2** Tâche avec tags de durée mixtes #duration:1w #duration:1m
- [ ] **4.3** Tâche avec tags de durée mixtes #duration:10d #duration:1m

## Tâches sans tags de durée
- [ ] **5.1** Tâche sans tag de durée
- [ ] **5.2** Tâche avec texte mentionnant duration mais sans tag
"@

# Exécuter le script d'extraction des tags de durée
Write-Host "Exécution du script d'extraction des tags de durée..." -ForegroundColor Cyan
$results = & $extractDurationTagsScriptPath -Content $testContent -OutputFormat "JSON"

# Afficher les résultats
Write-Host "Résultats de l'extraction des tags de durée:" -ForegroundColor Green
$resultsObj = $results | ConvertFrom-Json

# Afficher les statistiques
Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "- Nombre total de tâches: $($resultsObj.Stats.TotalTasks)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en jours: $($resultsObj.Stats.TasksWithDurationDaysTags)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en semaines: $($resultsObj.Stats.TasksWithDurationWeeksTags)" -ForegroundColor Yellow
Write-Host "- Tâches avec tags de durée en mois: $($resultsObj.Stats.TasksWithDurationMonthsTags)" -ForegroundColor Yellow

# Vérifier les résultats attendus
$expectedDaysTasks = @("1.1", "1.2", "1.3", "1.4", "4.1", "4.3")
$expectedWeeksTasks = @("2.1", "2.2", "2.3", "2.4", "4.1", "4.2")
$expectedMonthsTasks = @("3.1", "3.2", "3.3", "3.4", "4.2", "4.3")
$expectedNoTasks = @("5.1", "5.2")

# Vérifier les tâches avec tags de durée en jours
Write-Host "`nVérification des tâches avec tags de durée en jours:" -ForegroundColor Cyan
$daysTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationTagAttributes.Days.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingDaysTasks = $expectedDaysTasks | Where-Object { $_ -notin $daysTasks }
$unexpectedDaysTasks = $daysTasks | Where-Object { $_ -notin $expectedDaysTasks }

if ($missingDaysTasks.Count -eq 0 -and $unexpectedDaysTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec tags de durée en jours ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec tags de durée en jours:" -ForegroundColor Red
    if ($missingDaysTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingDaysTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedDaysTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedDaysTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches avec tags de durée en semaines
Write-Host "`nVérification des tâches avec tags de durée en semaines:" -ForegroundColor Cyan
$weeksTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationTagAttributes.Weeks.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingWeeksTasks = $expectedWeeksTasks | Where-Object { $_ -notin $weeksTasks }
$unexpectedWeeksTasks = $weeksTasks | Where-Object { $_ -notin $expectedWeeksTasks }

if ($missingWeeksTasks.Count -eq 0 -and $unexpectedWeeksTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec tags de durée en semaines ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec tags de durée en semaines:" -ForegroundColor Red
    if ($missingWeeksTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingWeeksTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedWeeksTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedWeeksTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches avec tags de durée en mois
Write-Host "`nVérification des tâches avec tags de durée en mois:" -ForegroundColor Cyan
$monthsTasks = $resultsObj.Tasks.PSObject.Properties | Where-Object { $_.Value.DurationTagAttributes.Months.Count -gt 0 } | Select-Object -ExpandProperty Name
$missingMonthsTasks = $expectedMonthsTasks | Where-Object { $_ -notin $monthsTasks }
$unexpectedMonthsTasks = $monthsTasks | Where-Object { $_ -notin $expectedMonthsTasks }

if ($missingMonthsTasks.Count -eq 0 -and $unexpectedMonthsTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches avec tags de durée en mois ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches avec tags de durée en mois:" -ForegroundColor Red
    if ($missingMonthsTasks.Count -gt 0) {
        Write-Host "  - Tâches manquantes: $($missingMonthsTasks -join ', ')" -ForegroundColor Red
    }
    if ($unexpectedMonthsTasks.Count -gt 0) {
        Write-Host "  - Tâches inattendues: $($unexpectedMonthsTasks -join ', ')" -ForegroundColor Red
    }
}

# Vérifier les tâches sans tags de durée
Write-Host "`nVérification des tâches sans tags de durée:" -ForegroundColor Cyan
$allTasks = $resultsObj.Tasks.PSObject.Properties | Select-Object -ExpandProperty Name
$tasksWithDurationTags = $daysTasks + $weeksTasks + $monthsTasks | Select-Object -Unique
$tasksWithoutDurationTags = $allTasks | Where-Object { $_ -notin $tasksWithDurationTags }
$missingNoTasks = $expectedNoTasks | Where-Object { $_ -notin $tasksWithoutDurationTags }
$unexpectedNoTasks = $tasksWithoutDurationTags | Where-Object { $_ -notin $expectedNoTasks }

if ($missingNoTasks.Count -eq 0 -and $unexpectedNoTasks.Count -eq 0) {
    Write-Host "✓ Toutes les tâches sans tags de durée ont été correctement détectées." -ForegroundColor Green
} else {
    Write-Host "✗ Problèmes détectés dans les tâches sans tags de durée:" -ForegroundColor Red
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
