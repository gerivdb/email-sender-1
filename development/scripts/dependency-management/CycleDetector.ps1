#Requires -Version 5.1

<#
.SYNOPSIS
    Script pour la détection des cycles dans un graphe de dépendances.

.DESCRIPTION
    Ce script fournit des fonctions pour détecter les cycles dans un graphe de dépendances.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

function Find-Cycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    # Initialiser les variables
    $visited = @{}
    $path = @{}
    $cycles = @()

    # Fonction récursive pour détecter les cycles
    function DFS {
        param (
            [string]$Node
        )

        # Marquer le nœud comme visité et l'ajouter au chemin
        $visited[$Node] = $true
        $path[$Node] = $true

        # Parcourir les voisins du nœud
        if ($Graph.ContainsKey($Node)) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin n'a pas été visité, l'explorer
                if (-not $visited.ContainsKey($neighbor)) {
                    DFS -Node $neighbor
                }
                # Si le voisin est dans le chemin, un cycle a été détecté
                elseif ($path.ContainsKey($neighbor)) {
                    $cycles += "Cycle trouvé: $Node -> $neighbor"
                }
            }
        }

        # Retirer le nœud du chemin
        $path.Remove($Node)
    }

    # Parcourir tous les nœuds du graphe
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            DFS -Node $node
        }
    }

    # Retourner les cycles trouvés
    return $cycles
}

# Exemple d'utilisation
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dépendances:"
$graph | ConvertTo-Json

Write-Host "Détection des cycles:"
$cycles = Find-Cycles -Graph $graph
$cycles
