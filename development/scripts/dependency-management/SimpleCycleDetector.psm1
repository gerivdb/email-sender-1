#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour la dÃ©tection des cycles dans un graphe de dÃ©pendances.

.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter les cycles dans un graphe de dÃ©pendances.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

<#
.SYNOPSIS
    DÃ©tecte les cycles dans un graphe de dÃ©pendances.

.DESCRIPTION
    Cette fonction dÃ©tecte les cycles dans un graphe de dÃ©pendances en utilisant
    l'algorithme de dÃ©tection de cycles dans un graphe orientÃ©.

.PARAMETER Graph
    Graphe de dÃ©pendances Ã  analyser. Le graphe doit Ãªtre une table de hachage oÃ¹ les clÃ©s
    sont les noms des nÅ“uds et les valeurs sont des listes de noms de nÅ“uds dÃ©pendants.

.PARAMETER IncludeAllCycles
    Indique si tous les cycles doivent Ãªtre dÃ©tectÃ©s. Par dÃ©faut, s'arrÃªte au premier cycle trouvÃ©.

.EXAMPLE
    $graph = @{
        'A' = @('B')
        'B' = @('C')
        'C' = @('A')
    }
    $cycles = Find-GraphCycles -Graph $graph
    DÃ©tecte les cycles dans le graphe spÃ©cifiÃ©.

.OUTPUTS
    [PSCustomObject] RÃ©sultat de la dÃ©tection des cycles.
#>
function Find-GraphCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllCycles
    )

    # VÃ©rifier si le graphe est vide
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

    # Fonction rÃ©cursive pour dÃ©tecter les cycles
    function DetectCycle {
        param (
            [string]$Node,
            [hashtable]$Visited,
            [hashtable]$RecursionStack,
            [System.Collections.ArrayList]$Path,
            [System.Collections.ArrayList]$Cycles
        )

        # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
        $Visited[$Node] = $true
        $RecursionStack[$Node] = $true
        [void]$Path.Add($Node)

        # Parcourir les voisins du nÅ“ud
        if ($Graph.ContainsKey($Node)) {
            foreach ($neighbor in $Graph[$Node]) {
                # Si le voisin n'a pas Ã©tÃ© visitÃ©, l'explorer
                if (-not $Visited.ContainsKey($neighbor)) {
                    DetectCycle -Node $neighbor -Visited $Visited -RecursionStack $RecursionStack -Path $Path -Cycles $Cycles
                }
                # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© dÃ©tectÃ©
                elseif ($RecursionStack.ContainsKey($neighbor) -and $RecursionStack[$neighbor]) {
                    # CrÃ©er un cycle
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
                        # Sinon, crÃ©er un cycle simple
                        [void]$cycle.Add($Node)
                        [void]$cycle.Add($neighbor)
                    }

                    # Ajouter le cycle Ã  la liste des cycles
                    [void]$Cycles.Add([PSCustomObject]@{
                        Nodes = $cycle.ToArray()
                        Length = $cycle.Count
                        Path = $cycle -join ' -> '
                    })

                    # Si on ne veut pas tous les cycles, on peut s'arrÃªter ici
                    if (-not $IncludeAllCycles) {
                        break
                    }
                }
            }
        }

        # Retirer le nÅ“ud de la pile de rÃ©cursion et du chemin
        $RecursionStack[$Node] = $false
        [void]$Path.RemoveAt($Path.Count - 1)
    }

    # Parcourir tous les nÅ“uds du graphe
    foreach ($node in $Graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $path = [System.Collections.ArrayList]@()
            DetectCycle -Node $node -Visited $visited -RecursionStack $recursionStack -Path $path -Cycles $cycles
            
            # Si on a trouvÃ© un cycle et qu'on ne veut pas tous les cycles, on peut s'arrÃªter ici
            if ($cycles.Count -gt 0 -and -not $IncludeAllCycles) {
                break
            }
        }
    }

    # Retourner le rÃ©sultat
    return [PSCustomObject]@{
        HasCycles = $cycles.Count -gt 0
        Cycles = $cycles
        CycleCount = $cycles.Count
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Find-GraphCycles
