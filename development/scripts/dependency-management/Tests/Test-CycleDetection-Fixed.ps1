#Requires -Version 5.1

# Fonction améliorée pour détecter les cycles dans un graphe
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

        # Marquer le nœud comme visité et l'ajouter à la pile de récursion
        $visited[$Node] = $true
        $recStack[$Node] = $true
        
        # Mettre à jour le chemin
        $currentPath = if ($Path -eq "") { $Node } else { "$Path -> $Node" }

        # Parcourir les voisins du nœud
        foreach ($neighbor in $Graph[$Node]) {
            # Si le voisin n'a pas été visité, l'explorer
            if (-not $visited.ContainsKey($neighbor)) {
                DFS -Node $neighbor -Path $currentPath
            }
            # Si le voisin est dans la pile de récursion, un cycle a été détecté
            elseif ($recStack.ContainsKey($neighbor) -and $recStack[$neighbor]) {
                $cycles += "Cycle trouvé: $currentPath -> $neighbor"
            }
        }

        # Retirer le nœud de la pile de récursion
        $recStack[$Node] = $false
    }

    # Parcourir tous les nœuds du graphe
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            DFS -Node $node
        }
    }

    return $cycles
}

# Créer un graphe de dépendances simple avec un cycle
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dépendances:"
$graph | ConvertTo-Json

Write-Host "`nDétection des cycles:"
$cycles = Find-Cycles -Graph $graph
$cycles

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
$complexCycles = Find-Cycles -Graph $complexGraph
$complexCycles

Write-Host "`nTest terminé!"
