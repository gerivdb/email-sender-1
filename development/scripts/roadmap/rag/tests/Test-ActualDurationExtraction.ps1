# Test-ActualDurationExtraction.ps1
# Script pour tester l'extraction des attributs de durée réelle des tâches
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\test-results-actual-duration.json"
)

# Importer le script d'extraction des durées réelles
$scriptPath = $PSScriptRoot
$extractActualDurationScriptPath = Join-Path -Path $scriptPath -ChildPath "..\metadata\Extract-ActualDurationValues.ps1"

if (-not (Test-Path -Path $extractActualDurationScriptPath)) {
    Write-Host "Le script d'extraction des durées réelles n'existe pas: $extractActualDurationScriptPath" -ForegroundColor Red
    exit 1
}

# Créer un contenu de test avec différentes durées réelles
$testContent = @"
# Test de l'extraction des durées réelles

## Durées réelles explicites
- [ ] **1.1** Tâche avec durée réelle en jours (durée réelle: 5 jours)
- [ ] **1.2** Tâche avec durée réelle en semaines (durée réelle: 2 semaines)
- [ ] **1.3** Tâche avec durée réelle en mois (durée réelle: 3 mois)
- [ ] **1.4** Tâche avec durée réelle en heures (durée réelle: 8 heures)
- [ ] **1.5** Tâche avec durée réelle abrégée (#durée-réelle:10j)
- [ ] **1.6** Tâche avec expression de durée réelle (a pris 7 jours de travail)
- [ ] **1.7** Tâche avec format alternatif (15 jours effectifs)

## Durées réelles avec indicateurs
- [ ] **2.1** Tâche avec indicateur "effectif" (durée effective: 4 jours)
- [ ] **2.2** Tâche avec indicateur "réel" (temps réel: 3 jours)
- [ ] **2.3** Tâche avec indicateur "a pris" (a pris 5 jours)
- [ ] **2.4** Tâche avec indicateur "a duré" (a duré 2 semaines)
- [ ] **2.5** Tâche avec indicateur "terminé en" (terminé en 3 jours)
- [ ] **2.6** Tâche avec indicateur "réalisé en" (réalisé en 4 heures)

## Durées réelles avec décimales
- [ ] **3.1** Tâche avec durée réelle décimale en jours (durée réelle: 2.5 jours)
- [ ] **3.2** Tâche avec durée réelle décimale en heures (durée réelle: 1.5 heures)
- [ ] **3.3** Tâche avec durée réelle décimale avec virgule (durée réelle: 3,5 jours)

## Durées réelles calculées par différence de dates
- [ ] **4.1** Tâche avec dates de début et fin (commencé le 2025-01-01, terminé le 2025-01-05)
- [ ] **4.2** Tâche avec dates et heures (débuté le 2025-01-01 à 9h, fini le 2025-01-01 à 17h)
- [ ] **4.3** Tâche avec format de date français (début: 01/01/2025, fin: 05/01/2025)

## Comparaison avec durées estimées
- [ ] **5.1** Tâche avec durée estimée et réelle (estimé: 3 jours, réel: 4 jours)
- [ ] **5.2** Tâche avec écart positif (prévu: 2 jours, effectif: 3 jours, écart: +1 jour)
- [ ] **5.3** Tâche avec écart négatif (prévu: 5 jours, effectif: 4 jours, écart: -1 jour)

## Tâches sans durée réelle
- [ ] **6.1** Tâche sans indication de durée réelle
- [ ] **6.2** Tâche avec texte mentionnant le mot durée réelle mais sans valeur
"@

# Exécuter le script d'extraction des durées réelles
Write-Host "Exécution du script d'extraction des durées réelles..." -ForegroundColor Cyan
$results = & $extractActualDurationScriptPath -Content $testContent -OutputFormat "JSON"

# Vérifier si les résultats sont valides
if ($null -eq $results) {
    Write-Host "Aucun résultat retourné par le script d'extraction des durées réelles." -ForegroundColor Red
    exit 1
}

# Afficher les résultats
Write-Host "Résultats de l'extraction des durées réelles:" -ForegroundColor Green
try {
    $resultsObj = $results | ConvertFrom-Json
    
    # Afficher les statistiques
    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "  Total des tâches: $($resultsObj.Stats.TotalTasks)" -ForegroundColor Cyan
    Write-Host "  Tâches avec durées réelles explicites: $($resultsObj.Stats.TasksWithExplicitActualDurations)" -ForegroundColor Cyan
    Write-Host "  Tâches avec durées réelles calculées: $($resultsObj.Stats.TasksWithCalculatedActualDurations)" -ForegroundColor Cyan
    Write-Host "  Tâches avec comparaison estimé/réel: $($resultsObj.Stats.TasksWithEstimateActualComparison)" -ForegroundColor Cyan
    
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
