#Requires -Version 5.1

# Fonction simple pour dÃ©tecter les cycles dans un graphe
function Find-SimpleCycle {
    param (
        [hashtable]$Graph
    )

    $visited = @{}
    $path = @{}
    $cycles = @()

    function DFS {
        param (
            [string]$Node
        )

        $visited[$Node] = $true
        $path[$Node] = $true

        foreach ($neighbor in $Graph[$Node]) {
            if (-not $visited.ContainsKey($neighbor)) {
                DFS -Node $neighbor
            }
            elseif ($path.ContainsKey($neighbor)) {
                $cycles += "Cycle trouvÃ©: $Node -> $neighbor"
            }
        }

        $path.Remove($Node)
    }

    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            DFS -Node $node
        }
    }

    return $cycles
}

# CrÃ©er un graphe de dÃ©pendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dÃ©pendances:"
$graph | ConvertTo-Json

Write-Host "`nDÃ©tection des cycles:"
$cycles = Find-SimpleCycle -Graph $graph
$cycles

# CrÃ©er un graphe de dÃ©pendances plus complexe avec plusieurs cycles
$complexGraph = @{
    'ModuleA' = @('ModuleB', 'ModuleC')
    'ModuleB' = @('ModuleD')
    'ModuleC' = @('ModuleE')
    'ModuleD' = @('ModuleF')
    'ModuleE' = @('ModuleB')  # Cycle: ModuleB -> ModuleD -> ModuleF -> ModuleB
    'ModuleF' = @('ModuleB')  # Cycle: ModuleC -> ModuleE -> ModuleB -> ModuleC
}

Write-Host "`nGraphe de dÃ©pendances complexe:"
$complexGraph | ConvertTo-Json

Write-Host "`nDÃ©tection des cycles dans le graphe complexe:"
$complexCycles = Find-SimpleCycle -Graph $complexGraph
$complexCycles

Write-Host "`nTest terminÃ©!"
