#Requires -Version 5.1

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force -Verbose

Write-Host "Getting exported commands..."
Get-Command -Module ModuleDependencyTraversal

Write-Host "Testing Reset-ModuleDependencyGraph..."
Reset-ModuleDependencyGraph
Write-Host "Reset completed."

Write-Host "Creating test dependency graph..."
$Global:MDT_DependencyGraph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}
Write-Host "Graph created."

Write-Host "Testing Find-ModuleDependencyCycles..."
try {
    $cycles = Find-ModuleDependencyCycles
    Write-Host "Cycles found: $($cycles.CycleCount)"
    $cycles | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "Error in Find-ModuleDependencyCycles: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "Testing Resolve-ModuleDependencyCycles..."
try {
    $result = Resolve-ModuleDependencyCycles -ReportOnly
    Write-Host "Cycles resolved: $($result.ResolvedCycleCount)"
    $result | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "Error in Resolve-ModuleDependencyCycles: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "All tests completed!"
