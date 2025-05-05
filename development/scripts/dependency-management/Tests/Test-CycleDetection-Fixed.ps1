#Requires -Version 5.1

# Fonction amÃ©liorÃ©e pour dÃ©tecter les cycles dans un graphe
function Find-Cycles {
    param (
        [hashtable]$Graph
    )

    $visited = @{}
    $recStack = @{}
    $cycles = @()

    function DFS {
        param (
            [string]$Node,
            [string]$Path = ""
        )

        # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
        $visited[$Node] = $true
        $recStack[$Node] = $true
        
        # Mettre Ã  jour le chemin
        $currentPath = if ($Path -eq "") { $Node } else { "$Path -> $Node" }

        # Parcourir les voisins du nÅ“ud
        foreach ($neighbor in $Graph[$Node]) {
            # Si le voisin n'a pas Ã©tÃ© visitÃ©, l'explorer
            if (-not $visited.ContainsKey($neighbor)) {
                DFS -Node $neighbor -Path $currentPath
            }
            # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© dÃ©tectÃ©
            elseif ($recStack.ContainsKey($neighbor) -and $recStack[$neighbor]) {
                $cycles += "Cycle trouvÃ©: $currentPath -> $neighbor"
            }
        }

        # Retirer le nÅ“ud de la pile de rÃ©cursion
        $recStack[$Node] = $false
    }

    # Parcourir tous les nÅ“uds du graphe
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
$cycles = Find-Cycles -Graph $graph
$cycles

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
$complexCycles = Find-Cycles -Graph $complexGraph
$complexCycles

Write-Host "`nTest terminÃ©!"
