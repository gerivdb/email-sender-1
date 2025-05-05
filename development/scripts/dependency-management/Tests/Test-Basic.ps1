#Requires -Version 5.1

# Importer le module Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force

Write-Host "Testing module functions..."

# CrÃ©er un graphe de dÃ©pendances simple
$graph = @{
    'ModuleA' = @('ModuleB', 'ModuleC')
    'ModuleB' = @('ModuleD')
    'ModuleC' = @('ModuleE')
    'ModuleD' = @()
    'ModuleE' = @('ModuleB')  # CrÃ©e un cycle avec ModuleB
}

# DÃ©finir les variables globales
$Global:MDT_DependencyGraph = $graph
$Global:MDT_VisitedModules = @{}
$Global:MDT_MaxRecursionDepth = 10
$Global:MDT_CurrentRecursionDepth = 0

# Tester Get-ModuleDependencyGraph
Write-Host "`nTesting Get-ModuleDependencyGraph..."
$result = Get-ModuleDependencyGraph
Write-Host "Graph contains $($result.Count) modules"
foreach ($module in $result.Keys) {
    Write-Host "  - $module depends on: $($result[$module] -join ', ')"
}

# Tester Get-ModuleVisitStatistics
Write-Host "`nTesting Get-ModuleVisitStatistics..."
$Global:MDT_VisitedModules = @{
    'ModuleA' = @{ Depth = 0; Visited = $true; VisitedAt = Get-Date }
    'ModuleB' = @{ Depth = 1; Visited = $true; VisitedAt = Get-Date }
    'ModuleC' = @{ Depth = 1; Visited = $true; VisitedAt = Get-Date }
    'ModuleD' = @{ Depth = 2; Visited = $true; VisitedAt = Get-Date }
    'ModuleE' = @{ Depth = 2; Visited = $true; VisitedAt = Get-Date }
}
$stats = Get-ModuleVisitStatistics
Write-Host "Visited modules: $($stats.VisitedModulesCount)"
Write-Host "Max depth: $($stats.MaxDepth)"
Write-Host "Min depth: $($stats.MinDepth)"
Write-Host "Average depth: $($stats.AverageDepth)"

# Tester Reset-ModuleDependencyGraph
Write-Host "`nTesting Reset-ModuleDependencyGraph..."
Reset-ModuleDependencyGraph
Write-Host "Graph after reset: $($Global:MDT_DependencyGraph.Count) modules"
Write-Host "Visited modules after reset: $($Global:MDT_VisitedModules.Count) modules"

Write-Host "`nAll tests completed!"
