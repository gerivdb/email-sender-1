# Script pour tester l'importation des modules

# Chemin des modules
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$cycleDetectorPath = Join-Path -Path $modulesPath -ChildPath "CycleDetector.psm1"
$cycleResolverPath = Join-Path -Path $modulesPath -ChildPath "DependencyCycleResolver.psm1"

Write-Host "Chemin du module CycleDetector: $cycleDetectorPath"
Write-Host "Chemin du module DependencyCycleResolver: $cycleResolverPath"

# Vérifier si les fichiers existent
if (Test-Path -Path $cycleDetectorPath) {
    Write-Host "Le fichier CycleDetector.psm1 existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier CycleDetector.psm1 n'existe pas." -ForegroundColor Red
}

if (Test-Path -Path $cycleResolverPath) {
    Write-Host "Le fichier DependencyCycleResolver.psm1 existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier DependencyCycleResolver.psm1 n'existe pas." -ForegroundColor Red
}

# Importer les modules
Write-Host "`nImportation des modules..."
try {
    Import-Module $cycleDetectorPath -Force -Verbose
    Write-Host "Module CycleDetector importé avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module CycleDetector: $_" -ForegroundColor Red
}

try {
    Import-Module $cycleResolverPath -Force -Verbose
    Write-Host "Module DependencyCycleResolver importé avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module DependencyCycleResolver: $_" -ForegroundColor Red
}

# Lister les fonctions exportées
Write-Host "`nFonctions exportées par le module CycleDetector:"
Get-Command -Module CycleDetector | Format-Table -Property Name, CommandType

Write-Host "`nFonctions exportées par le module DependencyCycleResolver:"
Get-Command -Module DependencyCycleResolver | Format-Table -Property Name, CommandType

# Tester une fonction du module CycleDetector
Write-Host "`nTest de la fonction Initialize-CycleDetector:"
try {
    $result = Initialize-CycleDetector -Enabled $true -MaxDepth 100 -CacheEnabled $true
    Write-Host "Résultat: $result" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exécution de Initialize-CycleDetector: $_" -ForegroundColor Red
}

# Tester une fonction du module DependencyCycleResolver
Write-Host "`nTest de la fonction Initialize-DependencyCycleResolver:"
try {
    $result = Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    Write-Host "Résultat: $result" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exécution de Initialize-DependencyCycleResolver: $_" -ForegroundColor Red
}

# Tester la fonction Find-Cycle
Write-Host "`nTest de la fonction Find-Cycle:"
try {
    $graph = @{
        "A" = @("B")
        "B" = @("C")
        "C" = @("A")
    }
    $cycleResult = Find-Cycle -Graph $graph
    Write-Host "Résultat: $($cycleResult | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exécution de Find-Cycle: $_" -ForegroundColor Red
}
