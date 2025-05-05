#Requires -Version 5.1

<#
.SYNOPSIS
    Script pour la dÃ©tection des cycles dans un graphe de dÃ©pendances.

.DESCRIPTION
    Ce script fournit des fonctions pour dÃ©tecter les cycles dans un graphe de dÃ©pendances.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
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

    # Fonction rÃ©cursive pour dÃ©tecter les cycles
    function DFS {
        param (
            [string]$Node
        )

        # Marquer le nÅ“ud comme visitÃ© et l'ajouter au chemin
        $visited[$Node] = $true
        $path[$Node] = $true

        # Parcourir les voisins du nÅ“ud
        if ($Graph.ContainsKey($Node)) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin n'a pas Ã©tÃ© visitÃ©, l'explorer
                if (-not $visited.ContainsKey($neighbor)) {
                    DFS -Node $neighbor
                }
                # Si le voisin est dans le chemin, un cycle a Ã©tÃ© dÃ©tectÃ©
                elseif ($path.ContainsKey($neighbor)) {
                    $cycles += "Cycle trouvÃ©: $Node -> $neighbor"
                }
            }
        }

        # Retirer le nÅ“ud du chemin
        $path.Remove($Node)
    }

    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            DFS -Node $node
        }
    }

    # Retourner les cycles trouvÃ©s
    return $cycles
}

# Exemple d'utilisation
$graph = @{
    'A' = @('B')
    'B' = @('C')
    'C' = @('A')
}

Write-Host "Graphe de dÃ©pendances:"
$graph | ConvertTo-Json

Write-Host "DÃ©tection des cycles:"
$cycles = Find-Cycles -Graph $graph
$cycles
