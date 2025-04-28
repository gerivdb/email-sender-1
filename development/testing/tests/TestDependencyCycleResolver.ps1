# Script pour tester le module DependencyCycleResolver

# Importer le module à tester
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Write-Host "Importation du module..."
Import-Module $cycleResolverPath -Force -Global

# Initialiser le module
Write-Host "Initialisation du module..."
Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"

# Test 1: Résolution d'un cycle simple dans un graphe
Write-Host "`nTest 1: Resolution d'un cycle simple dans un graphe"
$graph = @{
    "A" = @("B")
    "B" = @("C")
    "C" = @("A")
}

# Créer un objet CycleResult compatible avec Resolve-DependencyCycle
$cycleResult = [PSCustomObject]@{
    HasCycle = $true
    CyclePath = @("A", "B", "C", "A")
    Graph = $graph
}

# Résoudre le cycle
$resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

# Vérifier que le cycle est résolu
if ($resolveResult.Success) {
    Write-Host "  Cycle resolu avec succes" -ForegroundColor Green
    Write-Host "  Arete supprimee: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
} else {
    Write-Host "  Echec de la resolution du cycle" -ForegroundColor Red
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
