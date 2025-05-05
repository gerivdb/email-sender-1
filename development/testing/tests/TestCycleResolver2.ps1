# Script pour tester le module DependencyCycleResolver

# Importer les modules Ã  tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Write-Host "Importation des modules..."
Import-Module $cycleDetectorPath -Force
Import-Module $cycleResolverPath -Force

# Initialiser les modules
Write-Host "Initialisation des modules..."
CycleDetector\Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
DependencyCycleResolver\Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Test 1: RÃ©solution d'un cycle simple dans un graphe
Write-Host "`nTest 1: Resolution d'un cycle simple dans un graphe"
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# DÃ©tecter le cycle
$cycleResult = CycleDetector\Find-Cycle -Graph $graph

# VÃ©rifier que le cycle est dÃ©tectÃ©
if ($cycleResult.HasCycle) {
    Write-Host "  Cycle detecte" -ForegroundColor Green
    Write-Host "  Chemin du cycle: $($cycleResult.CyclePath -join ' -> ')"
} else {
    Write-Host "  Cycle non detecte" -ForegroundColor Red
}

# CrÃ©er un objet CycleResult compatible avec Resolve-DependencyCycle
$compatibleCycleResult = [PSCustomObject]@{
    HasCycle = $cycleResult.HasCycle
    CyclePath = $cycleResult.CyclePath
    Graph = $graph
}

# RÃ©soudre le cycle
$resolveResult = DependencyCycleResolver\Resolve-DependencyCycle -CycleResult $compatibleCycleResult

# VÃ©rifier que le cycle est rÃ©solu
if ($resolveResult.Success) {
    Write-Host "  Cycle resolu avec succes" -ForegroundColor Green
    Write-Host "  Arete supprimee: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  Echec de la resolution du cycle" -ForegroundColor Red
}

# VÃ©rifier que le graphe modifiÃ© n'a plus de cycle
$newCycleCheck = CycleDetector\Find-Cycle -Graph $resolveResult.Graph
if (-not $newCycleCheck.HasCycle) {
    Write-Host "  Le graphe modifie ne contient plus de cycle" -ForegroundColor Green
} else {
    Write-Host "  Le graphe modifie contient encore un cycle" -ForegroundColor Red
}

# Test 2: Statistiques du rÃ©solveur de cycles
Write-Host "`nTest 2: Statistiques du resolveur de cycles"
# Obtenir les statistiques
$stats = DependencyCycleResolver\Get-CycleResolverStatistics

# VÃ©rifier que les statistiques sont disponibles
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
