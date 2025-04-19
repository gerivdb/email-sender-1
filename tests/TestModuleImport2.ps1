# Script pour tester l'importation des modules

# Chemin des modules
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

# Importer les modules
Write-Host "Importation des modules..."
Import-Module $cycleDetectorPath -Force
Import-Module $cycleResolverPath -Force

# Tester la fonction Find-Cycle avec le nom complet du module
Write-Host "`nTest de la fonction Find-Cycle avec le nom complet du module:"
try {
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    $cycleResult = CycleDetector\Find-Cycle -Graph $graph
    Write-Host "Resultat: $($cycleResult | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'execution de CycleDetector\Find-Cycle: $_" -ForegroundColor Red
}

# Tester la fonction Resolve-DependencyCycle avec le nom complet du module
Write-Host "`nTest de la fonction Resolve-DependencyCycle avec le nom complet du module:"
try {
    if ($cycleResult) {
        $resolveResult = DependencyCycleResolver\Resolve-DependencyCycle -CycleResult $cycleResult
        Write-Host "Resultat: $($resolveResult | ConvertTo-Json)" -ForegroundColor Green
    } else {
        Write-Host "Impossible de tester Resolve-DependencyCycle car Find-Cycle a echoue." -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de l'execution de DependencyCycleResolver\Resolve-DependencyCycle: $_" -ForegroundColor Red
}
