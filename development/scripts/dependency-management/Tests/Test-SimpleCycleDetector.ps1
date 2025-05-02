#Requires -Version 5.1

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "SimpleCycleDetector.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module SimpleCycleDetector.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force -Verbose

Write-Host "Getting exported commands..."
Get-Command -Module SimpleCycleDetector

Write-Host "Testing cycle detection..."

# Créer un graphe de dépendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

# Tester la fonction du module
try {
    $cycles = Find-GraphCycles -Graph $graph
    Write-Host "Cycle detection result: $($cycles.HasCycles)"
    Write-Host "Cycles found: $($cycles.CycleCount)"
    $cycles | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "Error in Find-GraphCycles: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "All tests completed!"
