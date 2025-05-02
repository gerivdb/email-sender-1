#Requires -Version 5.1

# Importer le module à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spécifié: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force

Write-Host "Testing cycle detection..."

# Créer un graphe de dépendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dépendances simple:"
$graph | ConvertTo-Json

Write-Host "`nDétection des cycles dans le graphe simple:"
$cycles = Find-ModuleDependencyCycles -DependencyGraph $graph
Write-Host "Cycles trouvés: $($cycles.CycleCount)"
$cycles | ConvertTo-Json -Depth 10

# Créer un graphe de dépendances plus complexe avec plusieurs cycles
$complexGraph = @{
    'ModuleA' = @('ModuleB', 'ModuleC')
    'ModuleB' = @('ModuleD')
    'ModuleC' = @('ModuleE')
    'ModuleD' = @('ModuleF')
    'ModuleE' = @('ModuleB')  # Cycle: ModuleE -> ModuleB -> ModuleD -> ModuleF -> ModuleB
    'ModuleF' = @('ModuleB')  # Cycle: ModuleF -> ModuleB -> ModuleD -> ModuleF
}

Write-Host "`nGraphe de dépendances complexe:"
$complexGraph | ConvertTo-Json

Write-Host "`nDétection des cycles dans le graphe complexe:"
$complexCycles = Find-ModuleDependencyCycles -DependencyGraph $complexGraph
Write-Host "Cycles trouvés: $($complexCycles.CycleCount)"
$complexCycles | ConvertTo-Json -Depth 10

Write-Host "`nTest terminé!"
