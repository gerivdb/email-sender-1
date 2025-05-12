# Test-DurationNormalization.ps1
# Script pour tester la normalisation des durees
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-normalization.json"
)

# Importer le script de normalisation
$scriptPath = $PSScriptRoot
$normalizeDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Normalize-DurationValues.ps1"

if (-not (Test-Path -Path $normalizeDurationScriptPath)) {
    Write-Host "Le script de normalisation des durees n'existe pas: $normalizeDurationScriptPath" -ForegroundColor Red
    exit 1
}

# Creer un contenu de test avec differentes durees
$testContent = @"
# Test de la normalisation des durees

## Durees en jours/semaines/mois
- [ ] **1.1** Tache avec duree en jours (duree: 5 jours)
- [ ] **1.2** Tache avec duree en semaines (duree: 2 semaines)
- [ ] **1.3** Tache avec duree en mois (duree: 3 mois)
- [ ] **1.4** Tache avec duree en annees (duree: 1 annee)

## Durees en heures/minutes
- [ ] **2.1** Tache avec duree en heures (duree: 8 heures)
- [ ] **2.2** Tache avec duree en minutes (duree: 90 minutes)
- [ ] **2.3** Tache avec duree en heures et minutes (duree: 2 heures 30 minutes)

## Durees composees
- [ ] **3.1** Tache avec duree composee (duree: 1 jour 4 heures)
- [ ] **3.2** Tache avec duree composee complexe (duree: 2 semaines 3 jours 6 heures)
- [ ] **3.3** Tache avec duree composee avec minutes (duree: 4 heures 45 minutes)

## Durees reelles
- [ ] **4.1** Tache avec duree reelle en jours (duree reelle: 6 jours)
- [ ] **4.2** Tache avec duree reelle en semaines (duree reelle: 1.5 semaines)
- [ ] **4.3** Tache avec duree reelle en heures (duree reelle: 12 heures)

## Durees avec tags
- [ ] **5.1** Tache avec tag de duree (#duration:3d)
- [ ] **5.2** Tache avec tag de duree reelle (#duree-reelle:4j)
"@

# Executer le script de normalisation avec differentes unites standard
Write-Host "Test de normalisation en heures..." -ForegroundColor Cyan
$resultsHours = & $normalizeDurationScriptPath -Content $testContent -OutputFormat "JSON" -StandardUnit "Hours"

Write-Host "Test de normalisation en jours..." -ForegroundColor Cyan
$resultsDays = & $normalizeDurationScriptPath -Content $testContent -OutputFormat "JSON" -StandardUnit "Days"

Write-Host "Test de normalisation en semaines..." -ForegroundColor Cyan
$resultsWeeks = & $normalizeDurationScriptPath -Content $testContent -OutputFormat "JSON" -StandardUnit "Weeks"

Write-Host "Test de normalisation en mois..." -ForegroundColor Cyan
$resultsMonths = & $normalizeDurationScriptPath -Content $testContent -OutputFormat "JSON" -StandardUnit "Months"

# Verifier si les resultats sont valides
if ($null -eq $resultsHours -or $null -eq $resultsDays -or $null -eq $resultsWeeks -or $null -eq $resultsMonths) {
    Write-Host "Erreur lors de la normalisation des durees." -ForegroundColor Red
    exit 1
}

# Afficher les resultats
Write-Host "Resultats de la normalisation des durees:" -ForegroundColor Green
try {
    $resultsHoursObj = $resultsHours | ConvertFrom-Json
    $resultsDaysObj = $resultsDays | ConvertFrom-Json
    $resultsWeeksObj = $resultsWeeks | ConvertFrom-Json
    $resultsMonthsObj = $resultsMonths | ConvertFrom-Json

    # Afficher les statistiques
    Write-Host "Statistiques (normalisation en heures):" -ForegroundColor Yellow
    Write-Host "  Taches avec durees estimees normalisees: $($resultsHoursObj.Stats.TasksWithNormalizedEstimatedDurations)" -ForegroundColor Cyan
    Write-Host "  Taches avec durees reelles normalisees: $($resultsHoursObj.Stats.TasksWithNormalizedActualDurations)" -ForegroundColor Cyan

    # Verifier les conversions pour quelques exemples
    Write-Host "Verification des conversions:" -ForegroundColor Yellow

    # Exemple 1: Tache 1.1 (5 jours)
    if ($resultsHoursObj.NormalizedEstimatedDurations.'1.1') {
        $task1_1_hours = $resultsHoursObj.NormalizedEstimatedDurations.'1.1'[0].NormalizedValue
        $task1_1_days = $resultsDaysObj.NormalizedEstimatedDurations.'1.1'[0].NormalizedValue
        $task1_1_weeks = $resultsWeeksObj.NormalizedEstimatedDurations.'1.1'[0].NormalizedValue
        $task1_1_months = $resultsMonthsObj.NormalizedEstimatedDurations.'1.1'[0].NormalizedValue

        Write-Host "  Tache 1.1 (5 jours):" -ForegroundColor Cyan
        Write-Host "    En heures: $($task1_1_hours.ToString('F2')) heures" -ForegroundColor White
        Write-Host "    En jours: $($task1_1_days.ToString('F2')) jours" -ForegroundColor White
        Write-Host "    En semaines: $($task1_1_weeks.ToString('F2')) semaines" -ForegroundColor White
        Write-Host "    En mois: $($task1_1_months.ToString('F2')) mois" -ForegroundColor White

        # Verifier que les conversions sont correctes
        $expectedHours = 5 * 8  # 5 jours * 8 heures
        $expectedDays = 5
        $expectedWeeks = 5 / 5  # 5 jours / 5 jours par semaine
        $expectedMonths = 5 / 20  # 5 jours / 20 jours par mois

        $isCorrect = ($task1_1_hours -eq $expectedHours) -and
                     ($task1_1_days -eq $expectedDays) -and
                     ($task1_1_weeks -eq $expectedWeeks) -and
                     ($task1_1_months -eq $expectedMonths)

        if ($isCorrect) {
            Write-Host "    ✓ Conversions correctes" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Erreur dans les conversions" -ForegroundColor Red
            Write-Host "      Valeurs attendues: $expectedHours heures, $expectedDays jours, $expectedWeeks semaines, $expectedMonths mois" -ForegroundColor Red
        }
    }

    # Exemple 2: Tache 2.1 (8 heures)
    if ($resultsHoursObj.NormalizedEstimatedDurations.'2.1') {
        $task2_1_hours = $resultsHoursObj.NormalizedEstimatedDurations.'2.1'[0].NormalizedValue
        $task2_1_days = $resultsDaysObj.NormalizedEstimatedDurations.'2.1'[0].NormalizedValue
        $task2_1_weeks = $resultsWeeksObj.NormalizedEstimatedDurations.'2.1'[0].NormalizedValue
        $task2_1_months = $resultsMonthsObj.NormalizedEstimatedDurations.'2.1'[0].NormalizedValue

        Write-Host "  Tache 2.1 (8 heures):" -ForegroundColor Cyan
        Write-Host "    En heures: $($task2_1_hours.ToString('F2')) heures" -ForegroundColor White
        Write-Host "    En jours: $($task2_1_days.ToString('F2')) jours" -ForegroundColor White
        Write-Host "    En semaines: $($task2_1_weeks.ToString('F2')) semaines" -ForegroundColor White
        Write-Host "    En mois: $($task2_1_months.ToString('F2')) mois" -ForegroundColor White

        # Verifier que les conversions sont correctes
        $expectedHours = 8
        $expectedDays = 8 / 8  # 8 heures / 8 heures par jour
        $expectedWeeks = 8 / 40  # 8 heures / 40 heures par semaine
        $expectedMonths = 8 / 160  # 8 heures / 160 heures par mois

        $isCorrect = ($task2_1_hours -eq $expectedHours) -and
                     ($task2_1_days -eq $expectedDays) -and
                     ($task2_1_weeks -eq $expectedWeeks) -and
                     ($task2_1_months -eq $expectedMonths)

        if ($isCorrect) {
            Write-Host "    ✓ Conversions correctes" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Erreur dans les conversions" -ForegroundColor Red
            Write-Host "      Valeurs attendues: $expectedHours heures, $expectedDays jours, $expectedWeeks semaines, $expectedMonths mois" -ForegroundColor Red
        }
    }

    # Sauvegarder les resultats si un chemin de sortie est specifie
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $resultsHours | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "Resultats sauvegardes dans: $OutputPath" -ForegroundColor Green
    }

    # Retourner les resultats
    return @{
        Hours  = $resultsHoursObj
        Days   = $resultsDaysObj
        Weeks  = $resultsWeeksObj
        Months = $resultsMonthsObj
    }
} catch {
    Write-Host "Erreur lors de la conversion des resultats en JSON: $_" -ForegroundColor Red
    Write-Host "Resultats bruts: $resultsHours" -ForegroundColor Yellow
    exit 1
}
