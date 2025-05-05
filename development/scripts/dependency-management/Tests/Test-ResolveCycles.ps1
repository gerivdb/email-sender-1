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

Write-Host "Testing cycle resolution..."

# CrÃ©er un graphe de dÃ©pendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dÃ©pendances simple:"
$graph | ConvertTo-Json

Write-Host "`nDÃ©tection des cycles dans le graphe simple:"
$cycles = Find-ModuleDependencyCycles -DependencyGraph $graph
Write-Host "Cycles trouvÃ©s: $($cycles.CycleCount)"
$cycles | ConvertTo-Json -Depth 10

Write-Host "`nRÃ©solution des cycles dans le graphe simple:"
$resolved = Resolve-ModuleDependencyCycles -DependencyGraph $graph
Write-Host "Cycles rÃ©solus: $($resolved.ResolvedCycleCount)"
$resolved | ConvertTo-Json -Depth 10

Write-Host "`nVÃ©rification que les cycles ont Ã©tÃ© rÃ©solus:"
$checkCycles = Find-ModuleDependencyCycles -DependencyGraph $resolved.ModifiedGraph
Write-Host "Cycles restants: $($checkCycles.CycleCount)"
$checkCycles | ConvertTo-Json -Depth 10

# CrÃ©er un graphe de dÃ©pendances plus complexe avec plusieurs cycles
$complexGraph = @{
    'ModuleA' = @('ModuleB', 'ModuleC')
    'ModuleB' = @('ModuleD')
    'ModuleC' = @('ModuleE')
    'ModuleD' = @('ModuleF')
    'ModuleE' = @('ModuleB')  # Cycle: ModuleE -> ModuleB -> ModuleD -> ModuleF -> ModuleB
    'ModuleF' = @('ModuleB')  # Cycle: ModuleF -> ModuleB -> ModuleD -> ModuleF
}

Write-Host "`nGraphe de dÃ©pendances complexe:"
$complexGraph | ConvertTo-Json

Write-Host "`nDÃ©tection des cycles dans le graphe complexe:"
$complexCycles = Find-ModuleDependencyCycles -DependencyGraph $complexGraph
Write-Host "Cycles trouvÃ©s: $($complexCycles.CycleCount)"
$complexCycles | ConvertTo-Json -Depth 10

Write-Host "`nRÃ©solution des cycles dans le graphe complexe:"
$complexResolved = Resolve-ModuleDependencyCycles -DependencyGraph $complexGraph
Write-Host "Cycles rÃ©solus: $($complexResolved.ResolvedCycleCount)"
$complexResolved | ConvertTo-Json -Depth 10

Write-Host "`nVÃ©rification que les cycles ont Ã©tÃ© rÃ©solus:"
$checkComplexCycles = Find-ModuleDependencyCycles -DependencyGraph $complexResolved.ModifiedGraph
Write-Host "Cycles restants: $($checkComplexCycles.CycleCount)"
$checkComplexCycles | ConvertTo-Json -Depth 10

Write-Host "`nTest terminÃ©!"
