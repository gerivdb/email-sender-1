<#
.SYNOPSIS
    Algorithmes pour la détection de cycles dans un graphe.

.DESCRIPTION
    Ce script contient des implémentations des algorithmes DFS, Tarjan et Johnson
    pour la détection de cycles dans un graphe de dépendances.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Fonction pour détecter les cycles avec l'algorithme DFS (Depth-First Search)
function Find-CyclesDFS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les variables
        $cycles = @()
        $visited = @{}
        $recursionStack = @{}
        
        # Fonction récursive pour la recherche en profondeur
        function DFS-Visit {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Node,
                
                [Parameter(Mandatory = $true)]
                [System.Collections.ArrayList]$Path
            )
            
            # Marquer le nœud comme visité et l'ajouter à la pile de récursion
            $visited[$Node] = $true
            $recursionStack[$Node] = $true
            
            # Ajouter le nœud au chemin courant
            [void]$Path.Add($Node)
            
            # Parcourir les voisins du nœud
            foreach ($neighbor in $Graph[$Node]) {
                # Vérifier si le voisin existe dans le graphe
                if (-not $Graph.ContainsKey($neighbor)) {
                    continue
                }
                
                # Si le voisin n'a pas été visité, le visiter
                if (-not $visited.ContainsKey($neighbor)) {
                    $cycleFound = DFS-Visit -Node $neighbor -Path $Path
                    if ($cycleFound) {
                        return $true
                    }
                }
                # Si le voisin est dans la pile de récursion, un cycle a été trouvé
                elseif ($recursionStack.ContainsKey($neighbor)) {
                    # Trouver l'index du voisin dans le chemin
                    $startIndex = $Path.IndexOf($neighbor)
                    
                    # Extraire le cycle
                    $cycle = $Path.GetRange($startIndex, $Path.Count - $startIndex)
                    $cycle.Add($neighbor) # Fermer le cycle
                    
                    # Ajouter le cycle à la liste des cycles
                    $cycles += @{
                        Files = $cycle.ToArray()
                        Length = $cycle.Count
                        Severity = [Math]::Min(5, [Math]::Ceiling($cycle.Count / 2))
                        Description = "Cycle de dépendance détecté entre $($cycle.Count) fichiers"
                    }
                    
                    return $true
                }
            }
            
            # Retirer le nœud de la pile de récursion et du chemin
            $recursionStack.Remove($Node)
            [void]$Path.RemoveAt($Path.Count - 1)
            
            return $false
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $visited.ContainsKey($node)) {
                $path = New-Object System.Collections.ArrayList
                [void]DFS-Visit -Node $node -Path $path
            }
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme DFS : $_"
        return @()
    }
}

# Fonction pour détecter les composantes fortement connexes avec l'algorithme de Tarjan
function Find-CyclesTarjan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les variables
        $index = 0
        $stack = New-Object System.Collections.Stack
        $indices = @{}
        $lowlinks = @{}
        $onStack = @{}
        $components = @()
        
        # Fonction récursive pour la recherche en profondeur
        function StrongConnect {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Node
            )
            
            # Définir l'index et le lowlink du nœud
            $indices[$Node] = $index
            $lowlinks[$Node] = $index
            $index++
            
            # Ajouter le nœud à la pile
            $stack.Push($Node)
            $onStack[$Node] = $true
            
            # Parcourir les voisins du nœud
            foreach ($neighbor in $Graph[$Node]) {
                # Vérifier si le voisin existe dans le graphe
                if (-not $Graph.ContainsKey($neighbor)) {
                    continue
                }
                
                # Si le voisin n'a pas été visité, le visiter
                if (-not $indices.ContainsKey($neighbor)) {
                    StrongConnect -Node $neighbor
                    $lowlinks[$Node] = [Math]::Min($lowlinks[$Node], $lowlinks[$neighbor])
                }
                # Si le voisin est sur la pile, mettre à jour le lowlink
                elseif ($onStack.ContainsKey($neighbor)) {
                    $lowlinks[$Node] = [Math]::Min($lowlinks[$Node], $indices[$neighbor])
                }
            }
            
            # Vérifier si le nœud est la racine d'une composante fortement connexe
            if ($lowlinks[$Node] -eq $indices[$Node]) {
                $component = New-Object System.Collections.ArrayList
                
                do {
                    $w = $stack.Pop()
                    $onStack.Remove($w)
                    [void]$component.Add($w)
                } while ($w -ne $Node)
                
                # Ajouter la composante si elle contient plus d'un nœud (cycle)
                if ($component.Count -gt 1) {
                    # Fermer le cycle
                    [void]$component.Add($component[0])
                    
                    $components += @{
                        Files = $component.ToArray()
                        Length = $component.Count
                        Severity = [Math]::Min(5, [Math]::Ceiling($component.Count / 2))
                        Description = "Cycle de dépendance détecté entre $($component.Count) fichiers"
                    }
                }
            }
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $indices.ContainsKey($node)) {
                StrongConnect -Node $node
            }
        }
        
        return $components
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme de Tarjan : $_"
        return @()
    }
}

# Fonction pour énumérer tous les cycles élémentaires avec l'algorithme de Johnson
function Find-CyclesJohnson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les variables
        $cycles = @()
        $blocked = @{}
        $B = @{}
        $stack = New-Object System.Collections.ArrayList
        
        # Convertir le graphe en liste d'adjacence
        $adjList = @{}
        foreach ($node in $Graph.Keys) {
            $adjList[$node] = $Graph[$node]
        }
        
        # Fonction pour trouver les cycles à partir d'un nœud
        function FindCyclesFrom {
            param(
                [Parameter(Mandatory = $true)]
                [string]$StartNode
            )
            
            # Réinitialiser les variables
            $blocked = @{}
            foreach ($node in $adjList.Keys) {
                $blocked[$node] = $false
                $B[$node] = @()
            }
            
            # Fonction récursive pour la recherche de cycles
            function Circuit {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$CurrentNode,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$StartNode
                )
                
                $foundCycle = $false
                
                # Ajouter le nœud courant à la pile
                [void]$stack.Add($CurrentNode)
                $blocked[$CurrentNode] = $true
                
                # Parcourir les voisins du nœud
                foreach ($neighbor in $adjList[$CurrentNode]) {
                    # Vérifier si le voisin est le nœud de départ (cycle trouvé)
                    if ($neighbor -eq $StartNode) {
                        # Créer un nouveau cycle
                        $cycle = $stack.ToArray()
                        $cycle += $StartNode # Fermer le cycle
                        
                        # Ajouter le cycle à la liste des cycles
                        $cycles += @{
                            Files = $cycle
                            Length = $cycle.Length
                            Severity = [Math]::Min(5, [Math]::Ceiling($cycle.Length / 2))
                            Description = "Cycle de dépendance détecté entre $($cycle.Length) fichiers"
                        }
                        
                        $foundCycle = $true
                    }
                    # Sinon, continuer la recherche si le voisin n'est pas bloqué
                    elseif (-not $blocked[$neighbor]) {
                        if (Circuit -CurrentNode $neighbor -StartNode $StartNode) {
                            $foundCycle = $true
                        }
                    }
                }
                
                # Si un cycle a été trouvé, débloquer le nœud courant
                if ($foundCycle) {
                    Unblock -Node $CurrentNode
                }
                # Sinon, ajouter le nœud courant aux listes de blocage de ses voisins
                else {
                    foreach ($neighbor in $adjList[$CurrentNode]) {
                        if (-not $B[$neighbor].Contains($CurrentNode)) {
                            $B[$neighbor] += $CurrentNode
                        }
                    }
                }
                
                # Retirer le nœud courant de la pile
                [void]$stack.RemoveAt($stack.Count - 1)
                
                return $foundCycle
            }
            
            # Fonction pour débloquer un nœud
            function Unblock {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Node
                )
                
                $blocked[$Node] = $false
                
                # Débloquer les nœuds qui dépendent du nœud courant
                $i = 0
                while ($i -lt $B[$Node].Count) {
                    $w = $B[$Node][$i]
                    $i++
                    
                    if ($blocked[$w]) {
                        Unblock -Node $w
                    }
                }
                
                # Vider la liste de blocage du nœud
                $B[$Node] = @()
            }
            
            # Lancer la recherche de cycles
            [void]$Circuit -CurrentNode $StartNode -StartNode $StartNode
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $adjList.Keys) {
            FindCyclesFrom -StartNode $node
            
            # Supprimer le nœud du graphe pour éviter de trouver les mêmes cycles
            $adjList.Remove($node)
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme de Johnson : $_"
        return @()
    }
}

# Fonction principale pour détecter les cycles dans un graphe
function Find-DependencyCycles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DFS", "TARJAN", "JOHNSON")]
        [string]$Algorithm = "TARJAN",
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumCycleSeverity = 1
    )
    
    try {
        # Détecter les cycles avec l'algorithme spécifié
        $allCycles = switch ($Algorithm) {
            "DFS" {
                Find-CyclesDFS -Graph $Graph
            }
            "TARJAN" {
                Find-CyclesTarjan -Graph $Graph
            }
            "JOHNSON" {
                Find-CyclesJohnson -Graph $Graph
            }
            default {
                Find-CyclesTarjan -Graph $Graph
            }
        }
        
        # Filtrer les cycles selon la sévérité minimale
        $filteredCycles = $allCycles | Where-Object { $_.Severity -ge $MinimumCycleSeverity }
        
        return @{
            AllCycles = $allCycles
            FilteredCycles = $filteredCycles
        }
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles de dépendances : $_"
        return @{
            AllCycles = @()
            FilteredCycles = @()
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Find-DependencyCycles
