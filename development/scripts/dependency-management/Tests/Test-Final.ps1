#Requires -Version 5.1

# Importer le module SimpleCycleDetector
$moduleRoot = Split-Path -Parent $PSScriptRoot
$simpleCycleDetectorPath = Join-Path -Path $moduleRoot -ChildPath "SimpleCycleDetector.psm1"

Write-Host "Module path: $simpleCycleDetectorPath"

if (-not (Test-Path -Path $simpleCycleDetectorPath)) {
    throw "Le module SimpleCycleDetector.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $simpleCycleDetectorPath"
}

Write-Host "Importing module..."
Import-Module -Name $simpleCycleDetectorPath -Force -Verbose

Write-Host "Getting exported commands..."
Get-Command -Module SimpleCycleDetector

Write-Host "Testing cycle detection..."

# CrÃ©er un graphe de dÃ©pendances simple avec un cycle
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
