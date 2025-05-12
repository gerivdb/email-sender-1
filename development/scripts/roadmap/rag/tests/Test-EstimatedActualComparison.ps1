# Test-EstimatedActualComparison.ps1
# Script pour tester la comparaison des durées estimées et réelles
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-comparison.json"
)

# Importer le script de comparaison
$scriptPath = $PSScriptRoot
$compareScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Compare-EstimatedActualDurations.ps1"

if (-not (Test-Path -Path $compareScriptPath)) {
    Write-Host "Le script de comparaison n'existe pas: $compareScriptPath" -ForegroundColor Red
    exit 1
}

# Créer un contenu de test avec différentes durées estimées et réelles
$testContent = @"
# Test de la comparaison des durées estimées et réelles

## Durées estimées et réelles explicites
- [ ] **1.1** Tâche avec durée estimée et réelle (estimé: 3 jours, réel: 4 jours)
- [ ] **1.2** Tâche avec écart positif (prévu: 2 jours, effectif: 3 jours, écart: +1 jour)
- [ ] **1.3** Tâche avec écart négatif (prévu: 5 jours, effectif: 4 jours, écart: -1 jour)
- [ ] **1.4** Tâche avec unités différentes (estimé: 1 semaine, réel: 6 jours)
- [ ] **1.5** Tâche avec durée estimée uniquement (durée: 3 jours)
- [ ] **1.6** Tâche avec durée réelle uniquement (durée réelle: 4 jours)

## Durées avec tags
- [ ] **2.1** Tâche avec tag de durée estimée (#duration:5d)
- [ ] **2.2** Tâche avec tag de durée réelle (#durée-réelle:4j)
- [ ] **2.3** Tâche avec les deux types de tags (#duration:3d #durée-réelle:4j)

## Durées calculées
- [ ] **3.1** Tâche avec dates (commencé le 2025-01-01, terminé le 2025-01-05, durée: 4 jours)
- [ ] **3.2** Tâche avec heures (débuté le 2025-01-01 à 9h, fini le 2025-01-01 à 17h, durée: 8 heures)
"@

# Exécuter le script de comparaison
Write-Host "Exécution du script de comparaison des durées..." -ForegroundColor Cyan
$results = & $compareScriptPath -Content $testContent -OutputFormat "JSON"

# Vérifier si les résultats sont valides
if ($null -eq $results) {
    Write-Host "Aucun résultat retourné par le script de comparaison." -ForegroundColor Red
    exit 1
}

# Afficher les résultats
Write-Host "Résultats de la comparaison des durées:" -ForegroundColor Green
try {
    $resultsObj = $results | ConvertFrom-Json
    
    # Afficher les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  Total des tâches: $($resultsObj.Stats.TotalTasks)" -ForegroundColor Cyan
    Write-Host "  Tâches avec durées estimées: $($resultsObj.Stats.TasksWithEstimatedDurations)" -ForegroundColor Cyan
    Write-Host "  Tâches avec durées réelles: $($resultsObj.Stats.TasksWithActualDurations)" -ForegroundColor Cyan
    Write-Host "  Tâches avec comparaisons explicites: $($resultsObj.Stats.TasksWithExplicitComparisons)" -ForegroundColor Cyan
    Write-Host "  Tâches avec comparaisons calculées: $($resultsObj.Stats.TasksWithCalculatedComparisons)" -ForegroundColor Cyan
    
    # Sauvegarder les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $results | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "Résultats sauvegardés dans: $OutputPath" -ForegroundColor Green
    }
    
    # Retourner les résultats
    return $resultsObj
}
catch {
    Write-Host "Erreur lors de la conversion des résultats en JSON: $_" -ForegroundColor Red
    Write-Host "Résultats bruts: $results" -ForegroundColor Yellow
    exit 1
}
