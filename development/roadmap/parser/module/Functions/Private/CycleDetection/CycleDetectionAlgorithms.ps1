<#
.SYNOPSIS
    Algorithmes de dÃ©tection de cycles de dÃ©pendances.

.DESCRIPTION
    Ce script contient des algorithmes pour dÃ©tecter les cycles de dÃ©pendances
    dans un graphe de dÃ©pendances.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour dÃ©tecter les cycles avec l'algorithme DFS (Depth-First Search)
function Find-CyclesDFS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les structures de donnÃ©es
        $visited = @{}
        $recursionStack = @{}
        $cycles = @()
        
        # Fonction rÃ©cursive pour la recherche en profondeur
        function DFS-Visit {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Node,
                
                [Parameter(Mandatory = $true)]
                [System.Collections.ArrayList]$Path
            )
            
            # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
            $visited[$Node] = $true
            $recursionStack[$Node] = $true
            
            # Ajouter le nÅ“ud au chemin actuel
            [void]$Path.Add($Node)
            
            # Parcourir les voisins
            if ($Graph.ContainsKey($Node)) {
                foreach ($neighbor in $Graph[$Node]) {
                    # Si le voisin n'a pas Ã©tÃ© visitÃ©, le visiter
                    if (-not $visited.ContainsKey($neighbor) -or -not $visited[$neighbor]) {
                        DFS-Visit -Node $neighbor -Path $Path
                    }
                    # Si le voisin est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© trouvÃ©
                    elseif ($recursionStack.ContainsKey($neighbor) -and $recursionStack[$neighbor]) {
                        # Trouver l'index du voisin dans le chemin
                        $cycleStartIndex = $Path.IndexOf($neighbor)
                        
                        if ($cycleStartIndex -ge 0) {
                            # Extraire le cycle
                            $cycleFiles = $Path.GetRange($cycleStartIndex, $Path.Count - $cycleStartIndex)
                            
                            # Ajouter le cycle Ã  la liste des cycles
                            $cycles += [PSCustomObject]@{
                                Files = $cycleFiles
                                Length = $cycleFiles.Count
                                Severity = [Math]::Min(10, $cycleFiles.Count * 2)
                                Description = "Cycle dÃ©tectÃ© par l'algorithme DFS"
                            }
                        }
                    }
                }
            }
            
            # Retirer le nÅ“ud de la pile de rÃ©cursion et du chemin
            $recursionStack[$Node] = $false
            [void]$Path.RemoveAt($Path.Count - 1)
        }
        
        # Parcourir tous les nÅ“uds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
                DFS-Visit -Node $node -Path (New-Object System.Collections.ArrayList)
            }
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection des cycles avec l'algorithme DFS : $_"
        return @()
    }
}

# Fonction pour dÃ©tecter les cycles avec l'algorithme de Tarjan
function Find-CyclesTarjan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les structures de donnÃ©es
        $index = 0
        $indices = @{}
        $lowLinks = @{}
        $onStack = @{}
        $stack = New-Object System.Collections.ArrayList
        $cycles = @()
        
        # Fonction rÃ©cursive pour l'algorithme de Tarjan
        function Tarjan-Visit {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Node
            )
            
            # Initialiser le nÅ“ud
            $indices[$Node] = $index
            $lowLinks[$Node] = $index
            $index++
            [void]$stack.Add($Node)
            $onStack[$Node] = $true
            
            # Parcourir les voisins
            if ($Graph.ContainsKey($Node)) {
                foreach ($neighbor in $Graph[$Node]) {
                    # Si le voisin n'a pas Ã©tÃ© visitÃ©, le visiter
                    if (-not $indices.ContainsKey($neighbor)) {
                        Tarjan-Visit -Node $neighbor
                        $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $lowLinks[$neighbor])
                    }
                    # Si le voisin est sur la pile, mettre Ã  jour le lowLink
                    elseif ($onStack.ContainsKey($neighbor) -and $onStack[$neighbor]) {
                        $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $indices[$neighbor])
                    }
                }
            }
            
            # Si le nÅ“ud est la racine d'une composante fortement connexe
            if ($lowLinks[$Node] -eq $indices[$Node]) {
                $scc = New-Object System.Collections.ArrayList
                $w = ""
                
                do {
                    $w = $stack[$stack.Count - 1]
                    [void]$stack.RemoveAt($stack.Count - 1)
                    $onStack[$w] = $false
                    [void]$scc.Add($w)
                } while ($w -ne $Node)
                
                # Si la composante fortement connexe contient plus d'un nÅ“ud, c'est un cycle
                if ($scc.Count -gt 1) {
                    $cycles += [PSCustomObject]@{
                        Files = $scc
                        Length = $scc.Count
                        Severity = [Math]::Min(10, $scc.Count * 2)
                        Description = "Cycle dÃ©tectÃ© par l'algorithme de Tarjan"
                    }
                }
            }
        }
        
        # Parcourir tous les nÅ“uds du graphe
        foreach ($node in $Graph.Keys) {
            if (-not $indices.ContainsKey($node)) {
                Tarjan-Visit -Node $node
            }
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection des cycles avec l'algorithme de Tarjan : $_"
        return @()
    }
}

# Fonction pour dÃ©tecter les cycles avec l'algorithme de Johnson
function Find-CyclesJohnson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Initialiser les structures de donnÃ©es
        $cycles = @()
        $blocked = @{}
        $blockedMap = @{}
        $stack = New-Object System.Collections.ArrayList
        
        # Fonction pour trouver les cycles Ã  partir d'un nÅ“ud
        function Find-CyclesFromNode {
            param(
                [Parameter(Mandatory = $true)]
                [string]$StartNode,
                
                [Parameter(Mandatory = $true)]
                [hashtable]$SubGraph
            )
            
            # RÃ©initialiser les structures de donnÃ©es
            $blocked = @{}
            $blockedMap = @{}
            
            # Fonction rÃ©cursive pour la recherche de circuits
            function Circuit {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Node,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$StartNode
                )
                
                $foundCircuit = $false
                
                # Ajouter le nÅ“ud Ã  la pile
                [void]$stack.Add($Node)
                $blocked[$Node] = $true
                
                # Parcourir les voisins
                if ($SubGraph.ContainsKey($Node)) {
                    foreach ($neighbor in $SubGraph[$Node]) {
                        # Si le voisin est le nÅ“ud de dÃ©part, un cycle a Ã©tÃ© trouvÃ©
                        if ($neighbor -eq $StartNode) {
                            # Ajouter le cycle Ã  la liste des cycles
                            $cycleFiles = $stack.ToArray()
                            $cycleFiles += $StartNode
                            
                            $cycles += [PSCustomObject]@{
                                Files = $cycleFiles
                                Length = $cycleFiles.Count
                                Severity = [Math]::Min(10, $cycleFiles.Count * 2)
                                Description = "Cycle dÃ©tectÃ© par l'algorithme de Johnson"
                            }
                            
                            $foundCircuit = $true
                        }
                        # Sinon, si le voisin n'est pas bloquÃ©, continuer la recherche
                        elseif (-not $blocked.ContainsKey($neighbor) -or -not $blocked[$neighbor]) {
                            if (Circuit -Node $neighbor -StartNode $StartNode) {
                                $foundCircuit = $true
                            }
                        }
                    }
                }
                
                # Si un circuit a Ã©tÃ© trouvÃ©, dÃ©bloquer le nÅ“ud
                if ($foundCircuit) {
                    Unblock -Node $Node
                }
                # Sinon, mettre Ã  jour la carte de blocage
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
                
                # Retirer le nÅ“ud de la pile
                [void]$stack.RemoveAt($stack.Count - 1)
                
                return $foundCircuit
            }
            
            # Fonction pour dÃ©bloquer un nÅ“ud
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
        
        # Parcourir tous les nÅ“uds du graphe
        foreach ($node in $Graph.Keys) {
            Find-CyclesFromNode -StartNode $node -SubGraph $Graph
        }
        
        return $cycles
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection des cycles avec l'algorithme de Johnson : $_"
        return @()
    }
}

# Fonction principale pour dÃ©tecter les cycles de dÃ©pendances
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
        # DÃ©tecter les cycles avec l'algorithme spÃ©cifiÃ©
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

        # Filtrer les cycles selon la sÃ©vÃ©ritÃ© minimale
        $filteredCycles = $allCycles | Where-Object { $_.Severity -ge $MinimumCycleSeverity }

        return @{
            AllCycles = $allCycles
            FilteredCycles = $filteredCycles
        }
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection des cycles de dÃ©pendances : $_"
        return @{
            AllCycles = @()
            FilteredCycles = @()
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Find-DependencyCycles
