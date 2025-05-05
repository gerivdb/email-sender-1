#Requires -Version 5.1

# Importer le module Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyTraversal.psm1"

Write-Host "Module path: $modulePath"

if (-not (Test-Path -Path $modulePath)) {
    throw "Le module ModuleDependencyTraversal.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $modulePath"
}

Write-Host "Importing module..."
Import-Module -Name $modulePath -Force -Verbose

Write-Host "Testing simple cycle detection..."

# CrÃ©er un graphe de dÃ©pendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

# Fonction simple pour dÃ©tecter les cycles
function Find-SimpleCycle {
    param (
        [hashtable]$Graph
    )

    $visited = @{}
    $path = @{}
    $cycles = @()

    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $result = Find-SimpleCycleUtil -Graph $Graph -Node $node -Visited $visited -Path $path -Cycles $cycles
            if ($result) {
                return $true, $cycles
            }
        }
    }

    return $false, $cycles
}

function Find-SimpleCycleUtil {
    param (
        [hashtable]$Graph,
        [string]$Node,
        [hashtable]$Visited,
        [hashtable]$Path,
        [ref]$Cycles
    )

    $Visited[$Node] = $true
    $Path[$Node] = $true

    foreach ($neighbor in $Graph[$Node]) {
        if (-not $Visited.ContainsKey($neighbor)) {
            $result = Find-SimpleCycleUtil -Graph $Graph -Node $neighbor -Visited $Visited -Path $Path -Cycles $Cycles
            if ($result) {
                return $true
            }
        }
        elseif ($Path.ContainsKey($neighbor)) {
            $Cycles.Value += @("Cycle found: $Node -> $neighbor")
            return $true
        }
    }

    $Path.Remove($Node)
    return $false
}

# Tester la fonction simple
$hasCycle, $simpleCycles = Find-SimpleCycle -Graph $graph
Write-Host "Simple cycle detection result: $hasCycle"
Write-Host "Cycles found: $($simpleCycles -join ', ')"

# Tester la fonction du module
try {
    $Global:MDT_DependencyGraph = $graph
    $cycles = Find-ModuleDependencyCycles
    Write-Host "Module cycle detection result: $($cycles.HasCycles)"
    Write-Host "Cycles found: $($cycles.CycleCount)"
    $cycles | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "Error in Find-ModuleDependencyCycles: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host "All tests completed!"
