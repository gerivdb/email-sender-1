<#
.SYNOPSIS
    Algorithmes de détection de cycles de dépendances.

.DESCRIPTION
    Ce script contient des algorithmes pour détecter les cycles de dépendances
    dans un graphe de dépendances.

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
        # Initialiser les structures de données
        $visited = @{}
        $recursionStack = @{}
        $cycles = @()
        
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
            
            # Ajouter le nœud au chemin actuel
            [void]$Path.Add($Node)
            
            # Parcourir les voisins
            if ($Graph.ContainsKey($Node)) {
                foreach ($neighbor in $Graph[$Node]) {
                    # Si le voisin n'a pas été visité, le visiter
                    if (-not $visited.ContainsKey($neighbor) -or -not $visited[$neighbor]) {
                        DFS-Visit -Node $neighbor -Path $Path
                    }
                    # Si le voisin est dans la pile de récursion, un cycle a été trouvé
                    elseif ($recursionStack.ContainsKey($neighbor) -and $recursionStack[$neighbor]) {
                        # Trouver l'index du voisin dans le chemin
                        $cycleStartIndex = $Path.IndexOf($neighbor)
                        
                        if ($cycleStartIndex -ge 0) {
                            # Extraire le cycle
                            $cycleFiles = $Path.GetRange($cycleStartIndex, $Path.Count - $cycleStartIndex)
                            
                            # Ajouter le cycle à la liste des cycles
                            $cycles += [PSCustomObject]@{
                                Files = $cycleFiles
                                Length = $cycleFiles.Count
                                Severity = [Math]::Min(10, $cycleFiles.Count * 2)
                                Description = "Cycle détecté par l'algorithme DFS"
                            }
                        }
                    }
                }
            }
            
            # Retirer le nœud de la pile de récursion et du chemin
            $recursionStack[$Node] = $false
            [void]$Path.RemoveAt($Path.Count - 1)
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
                DFS-Visit -Node $node -Path (New-Object System.Collections.ArrayList)
            }
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme DFS : $_"
        return @()
    }
}

# Fonction pour détecter les cycles avec l'algorithme de Tarjan
function Find-CyclesTarjan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les structures de données
        $index = 0
        $indices = @{}
        $lowLinks = @{}
        $onStack = @{}
        $stack = New-Object System.Collections.ArrayList
        $cycles = @()
        
        # Fonction récursive pour l'algorithme de Tarjan
        function Tarjan-Visit {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Node
            )
            
            # Initialiser le nœud
            $indices[$Node] = $index
            $lowLinks[$Node] = $index
            $index++
            [void]$stack.Add($Node)
            $onStack[$Node] = $true
            
            # Parcourir les voisins
            if ($Graph.ContainsKey($Node)) {
                foreach ($neighbor in $Graph[$Node]) {
                    # Si le voisin n'a pas été visité, le visiter
                    if (-not $indices.ContainsKey($neighbor)) {
                        Tarjan-Visit -Node $neighbor
                        $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $lowLinks[$neighbor])
                    }
                    # Si le voisin est sur la pile, mettre à jour le lowLink
                    elseif ($onStack.ContainsKey($neighbor) -and $onStack[$neighbor]) {
                        $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $indices[$neighbor])
                    }
                }
            }
            
            # Si le nœud est la racine d'une composante fortement connexe
            if ($lowLinks[$Node] -eq $indices[$Node]) {
                $scc = New-Object System.Collections.ArrayList
                $w = ""
                
                do {
                    $w = $stack[$stack.Count - 1]
                    [void]$stack.RemoveAt($stack.Count - 1)
                    $onStack[$w] = $false
                    [void]$scc.Add($w)
                } while ($w -ne $Node)
                
                # Si la composante fortement connexe contient plus d'un nœud, c'est un cycle
                if ($scc.Count -gt 1) {
                    $cycles += [PSCustomObject]@{
                        Files = $scc
                        Length = $scc.Count
                        Severity = [Math]::Min(10, $scc.Count * 2)
                        Description = "Cycle détecté par l'algorithme de Tarjan"
                    }
                }
            }
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $indices.ContainsKey($node)) {
                Tarjan-Visit -Node $node
            }
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme de Tarjan : $_"
        return @()
    }
}

# Fonction pour détecter les cycles avec l'algorithme de Johnson
function Find-CyclesJohnson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les structures de données
        $cycles = @()
        $blocked = @{}
        $blockedMap = @{}
        $stack = New-Object System.Collections.ArrayList
        
        # Fonction pour trouver les cycles à partir d'un nœud
        function Find-CyclesFromNode {
            param(
                [Parameter(Mandatory = $true)]
                [string]$StartNode,
                
                [Parameter(Mandatory = $true)]
                [hashtable]$SubGraph
            )
            
            # Réinitialiser les structures de données
            $blocked = @{}
            $blockedMap = @{}
            
            # Fonction récursive pour la recherche de circuits
            function Circuit {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Node,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$StartNode
                )
                
                $foundCircuit = $false
                
                # Ajouter le nœud à la pile
                [void]$stack.Add($Node)
                $blocked[$Node] = $true
                
                # Parcourir les voisins
                if ($SubGraph.ContainsKey($Node)) {
                    foreach ($neighbor in $SubGraph[$Node]) {
                        # Si le voisin est le nœud de départ, un cycle a été trouvé
                        if ($neighbor -eq $StartNode) {
                            # Ajouter le cycle à la liste des cycles
                            $cycleFiles = $stack.ToArray()
                            $cycleFiles += $StartNode
                            
                            $cycles += [PSCustomObject]@{
                                Files = $cycleFiles
                                Length = $cycleFiles.Count
                                Severity = [Math]::Min(10, $cycleFiles.Count * 2)
                                Description = "Cycle détecté par l'algorithme de Johnson"
                            }
                            
                            $foundCircuit = $true
                        }
                        # Sinon, si le voisin n'est pas bloqué, continuer la recherche
                        elseif (-not $blocked.ContainsKey($neighbor) -or -not $blocked[$neighbor]) {
                            if (Circuit -Node $neighbor -StartNode $StartNode) {
                                $foundCircuit = $true
                            }
                        }
                    }
                }
                
                # Si un circuit a été trouvé, débloquer le nœud
                if ($foundCircuit) {
                    Unblock -Node $Node
                }
                # Sinon, mettre à jour la carte de blocage
                else {
                    if ($SubGraph.ContainsKey($Node)) {
                        foreach ($neighbor in $SubGraph[$Node]) {
                            if (-not $blockedMap.ContainsKey($neighbor)) {
                                $blockedMap[$neighbor] = @()
                            }
                            
                            if (-not $blockedMap[$neighbor].Contains($Node)) {
                                $blockedMap[$neighbor] += $Node
                            }
                        }
                    }
                }
                
                # Retirer le nœud de la pile
                [void]$stack.RemoveAt($stack.Count - 1)
                
                return $foundCircuit
            }
            
            # Fonction pour débloquer un nœud
            function Unblock {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Node
                )
                
                $blocked[$Node] = $false
                
                if ($blockedMap.ContainsKey($Node)) {
                    foreach ($blockedNode in $blockedMap[$Node]) {
                        if ($blocked.ContainsKey($blockedNode) -and $blocked[$blockedNode]) {
                            Unblock -Node $blockedNode
                        }
                    }
                    
                    $blockedMap[$Node] = @()
                }
            }
            
            # Lancer la recherche de circuits
            Circuit -Node $StartNode -StartNode $StartNode
        }
        
        # Parcourir tous les nœuds du graphe
        foreach ($node in $Graph.Keys) {
            Find-CyclesFromNode -StartNode $node -SubGraph $Graph
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la détection des cycles avec l'algorithme de Johnson : $_"
        return @()
    }
}

# Fonction principale pour détecter les cycles de dépendances
function Find-DependencyCycles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DFS", "TARJAN", "JOHNSON")]
        [string]$Algorithm = "TARJAN",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
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
