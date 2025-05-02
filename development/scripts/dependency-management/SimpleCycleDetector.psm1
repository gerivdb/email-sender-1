#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour la détection des cycles dans un graphe de dépendances.

.DESCRIPTION
    Ce module fournit des fonctions pour détecter les cycles dans un graphe de dépendances.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de création: 2023-06-15
#>

<#
.SYNOPSIS
    Détecte les cycles dans un graphe de dépendances.

.DESCRIPTION
    Cette fonction détecte les cycles dans un graphe de dépendances en utilisant
    l'algorithme de détection de cycles dans un graphe orienté.

.PARAMETER Graph
    Graphe de dépendances à analyser. Le graphe doit être une table de hachage où les clés
    sont les noms des nœuds et les valeurs sont des listes de noms de nœuds dépendants.

.PARAMETER IncludeAllCycles
    Indique si tous les cycles doivent être détectés. Par défaut, s'arrête au premier cycle trouvé.

.EXAMPLE
    $graph = @{
        'A' = @('B')
        'B' = @('C')
        'C' = @('A')
    }
    $cycles = Find-GraphCycles -Graph $graph
    Détecte les cycles dans le graphe spécifié.

.OUTPUTS
    [PSCustomObject] Résultat de la détection des cycles.
#>
function Find-GraphCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllCycles
    )

    # Vérifier si le graphe est vide
    if ($Graph.Count -eq 0) {
        Write-Warning "Le graphe est vide."
        return [PSCustomObject]@{
            HasCycles = $false
            Cycles = @()
            CycleCount = 0
        }
    }

    # Initialiser les variables
    $visited = @{}
    $recursionStack = @{}
    $cycles = [System.Collections.ArrayList]@()

    # Fonction récursive pour détecter les cycles
    function DetectCycle {
        param (
            [string]$Node,
            [hashtable]$Visited,
            [hashtable]$RecursionStack,
            [System.Collections.ArrayList]$Path,
            [System.Collections.ArrayList]$Cycles
        )

        # Marquer le nœud comme visité et l'ajouter à la pile de récursion
        $Visited[$Node] = $true
        $RecursionStack[$Node] = $true
        [void]$Path.Add($Node)

        # Parcourir les voisins du nœud
        if ($Graph.ContainsKey($Node)) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin n'a pas été visité, l'explorer
                if (-not $Visited.ContainsKey($neighbor)) {
                    DetectCycle -Node $neighbor -Visited $Visited -RecursionStack $RecursionStack -Path $Path -Cycles $Cycles
                }
                # Si le voisin est dans la pile de récursion, un cycle a été détecté
                elseif ($RecursionStack.ContainsKey($neighbor) -and $RecursionStack[$neighbor]) {
                    # Créer un cycle
                    $cycle = [System.Collections.ArrayList]@()
                    $startIndex = $Path.IndexOf($neighbor)
                    
                    # Si le voisin est dans le chemin actuel, extraire le cycle
                    if ($startIndex -ge 0) {
                        for ($i = $startIndex; $i -lt $Path.Count; $i++) {
                            [void]$cycle.Add($Path[$i])
                        }
                        [void]$cycle.Add($neighbor)
                    }
                    else {
                        # Sinon, créer un cycle simple
                        [void]$cycle.Add($Node)
                        [void]$cycle.Add($neighbor)
                    }

                    # Ajouter le cycle à la liste des cycles
                    [void]$Cycles.Add([PSCustomObject]@{
                        Nodes = $cycle.ToArray()
                        Length = $cycle.Count
                        Path = $cycle -join ' -> '
                    })

                    # Si on ne veut pas tous les cycles, on peut s'arrêter ici
                    if (-not $IncludeAllCycles) {
                        break
                    }
                }
            }
        }

        # Retirer le nœud de la pile de récursion et du chemin
        $RecursionStack[$Node] = $false
        [void]$Path.RemoveAt($Path.Count - 1)
    }

    # Parcourir tous les nœuds du graphe
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $path = [System.Collections.ArrayList]@()
            DetectCycle -Node $node -Visited $visited -RecursionStack $recursionStack -Path $path -Cycles $cycles
            
            # Si on a trouvé un cycle et qu'on ne veut pas tous les cycles, on peut s'arrêter ici
            if ($cycles.Count -gt 0 -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    # Retourner le résultat
    return [PSCustomObject]@{
        HasCycles = $cycles.Count -gt 0
        Cycles = $cycles
        CycleCount = $cycles.Count
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-GraphCycles
