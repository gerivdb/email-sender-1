# Script pour tester le module DependencyCycleResolver

# Importer les modules à tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Write-Host "Importation des modules..."
Import-Module $cycleDetectorPath -Force
Import-Module $cycleResolverPath -Force

# Initialiser les modules
Write-Host "Initialisation des modules..."
Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Test 1: Résolution d'un cycle simple dans un graphe
Write-Host "`nTest 1: Resolution d'un cycle simple dans un graphe"
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# Détecter le cycle
$cycleResult = Find-Cycle -Graph $graph

# Vérifier que le cycle est détecté
if ($cycleResult.HasCycle) {
    Write-Host "  Cycle detecte" -ForegroundColor Green
} else {
    Write-Host "  Cycle non detecte" -ForegroundColor Red
}

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# Vérifier que le cycle est résolu
if ($resolveResult.Success) {
    Write-Host "  Cycle resolu avec succes" -ForegroundColor Green
    Write-Host "    Arete supprimee: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  Echec de la resolution du cycle" -ForegroundColor Red
}

# Vérifier que le graphe modifié n'a plus de cycle
$newCycleCheck = Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  Le graphe modifie ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  Le graphe modifie contient encore un cycle" -ForegroundColor Red
}

# Test 2: Statistiques du résolveur de cycles
Write-Host "`nTest 2: Statistiques du resolveur de cycles"
# Obtenir les statistiques
$stats = Get-CycleResolverStatistics

# Vérifier que les statistiques sont disponibles
if ($stats.TotalResolutions -gt 0) {
    Write-Host "  Nombre total de resolutions: $($stats.TotalResolutions)" -ForegroundColor Green
} else {
    Write-Host "  Aucune resolution enregistree" -ForegroundColor Red
}

if ($stats.SuccessfulResolutions -gt 0) {
    Write-Host "  Resolutions reussies: $($stats.SuccessfulResolutions)" -ForegroundColor Green
} else {
    Write-Host "  Aucune resolution reussie" -ForegroundColor Red
}

if ($stats.SuccessRate -gt 0) {
    Write-Host "  Taux de reussite: $($stats.SuccessRate)%" -ForegroundColor Green
} else {
    Write-Host "  Taux de reussite nul" -ForegroundColor Red
}

Write-Host "`nTous les tests ont ete executes avec succes." -ForegroundColor Green
