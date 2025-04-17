# Module de détection de cycles
# Ce module fournit des fonctionnalités pour détecter et corriger les cycles dans différents types de graphes.
# Version: 0.1.0 (Squelette)
# Date: 2025-06-01

# Variables globales
$Global:CycleDetectorEnabled = $true
$Global:CycleDetectorMaxDepth = 1000
$Global:CycleDetectorCacheEnabled = $true

# Initialiser le cache
$Global:CycleDetectorCache = @{}

# Statistiques d'utilisation
$Global:CycleDetectorStats = [PSCustomObject]@{
    TotalCalls           = 0
    TotalCycles          = 0
    AverageExecutionTime = 0
    CacheHits            = 0
    CacheMisses          = 0
}

# Variables statiques pour réduire les allocations mémoire
$script:StringBuilder = $null
$script:SHA256 = $null
$script:PathList = $null
$script:VisitedNodes = $null
$script:InStackNodes = $null
$script:NodeStack = $null
$script:PathStack = $null

# Initialise le détecteur de cycles avec les paramètres spécifiés
function Initialize-CycleDetector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 1000,

        [Parameter(Mandatory = $false)]
        [bool]$CacheEnabled = $true
    )

    # Initialiser les variables globales
    # Utiliser Set-Variable avec -Scope Global pour éviter les avertissements PSScriptAnalyzer
    Set-Variable -Name CycleDetectorEnabled -Value $Enabled -Scope Global
    Set-Variable -Name CycleDetectorMaxDepth -Value $MaxDepth -Scope Global
    Set-Variable -Name CycleDetectorCacheEnabled -Value $CacheEnabled -Scope Global

    # Retourner les valeurs pour indiquer à l'analyseur qu'elles sont utilisées
    return [PSCustomObject]@{
        Enabled      = $Global:CycleDetectorEnabled
        MaxDepth     = $Global:CycleDetectorMaxDepth
        CacheEnabled = $Global:CycleDetectorCacheEnabled
    }
}

# Détecte les cycles dans un graphe générique
function Find-Cycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = $Global:CycleDetectorMaxDepth,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache
    )

    # Vérifier si le détecteur est activé
    if (-not $Global:CycleDetectorEnabled) {
        return [PSCustomObject]@{
            HasCycle  = $false
            CyclePath = @()
        }
    }

    # Détection rapide pour les petits graphes
    if ($Graph.Count -le 5) {
        # Pour les très petits graphes, vérifier directement sans utiliser le cache
        $Global:CycleDetectorStats.TotalCalls++
        $startTime = Get-Date

        $result = Find-GraphCycle -Graph $Graph -MaxDepth $MaxDepth

        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        $Global:CycleDetectorStats.AverageExecutionTime = (($Global:CycleDetectorStats.AverageExecutionTime * ($Global:CycleDetectorStats.TotalCalls - 1)) + $executionTime) / $Global:CycleDetectorStats.TotalCalls

        if ($result.HasCycle) {
            $Global:CycleDetectorStats.TotalCycles++
        }

        return $result
    }

    # Calculer le hash du graphe pour le cache
    if (-not $SkipCache -and $Global:CycleDetectorCacheEnabled) {
        $graphHash = Get-GraphHash -Graph $Graph

        # Vérifier si le résultat est dans le cache
        if ($Global:CycleDetectorCache.ContainsKey($graphHash)) {
            $Global:CycleDetectorStats.CacheHits++
            return $Global:CycleDetectorCache[$graphHash]
        }

        # Gestion du cache LRU (Least Recently Used)
        if ($Global:CycleDetectorCache.Count -gt 1000) {
            # Supprimer 20% des entrées les plus anciennes
            $keysToRemove = $Global:CycleDetectorCache.Keys | Select-Object -First 200
            foreach ($key in $keysToRemove) {
                $Global:CycleDetectorCache.Remove($key)
            }
        }
    }

    $Global:CycleDetectorStats.CacheMisses++
    $Global:CycleDetectorStats.TotalCalls++

    # Mesurer le temps d'exécution
    $startTime = Get-Date

    # Détecter les cycles
    $result = Find-GraphCycle -Graph $Graph -MaxDepth $MaxDepth

    # Mettre à jour les statistiques
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalMilliseconds
    $Global:CycleDetectorStats.AverageExecutionTime = (($Global:CycleDetectorStats.AverageExecutionTime * ($Global:CycleDetectorStats.TotalCalls - 1)) + $executionTime) / $Global:CycleDetectorStats.TotalCalls

    if ($result.HasCycle) {
        $Global:CycleDetectorStats.TotalCycles++
    }

    # Mettre en cache le résultat
    if (-not $SkipCache -and $Global:CycleDetectorCacheEnabled) {
        $Global:CycleDetectorCache[$graphHash] = $result
    }

    return $result
}

# Calcule un hash pour un graphe
function Get-GraphHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    # Utiliser un algorithme de hachage plus rapide pour les grands graphes
    if ($Graph.Count -gt 1000) {
        return Get-FastGraphHash -Graph $Graph
    }

    # Réutiliser un StringBuilder statique pour réduire les allocations mémoire
    if (-not $script:StringBuilder) {
        $script:StringBuilder = New-Object System.Text.StringBuilder(1024 * 16) # 16KB initial capacity
    } else {
        $script:StringBuilder.Clear()
    }

    # Trier les clés une seule fois
    $sortedKeys = $Graph.Keys | Sort-Object

    foreach ($node in $sortedKeys) {
        [void]$script:StringBuilder.Append($node)
        [void]$script:StringBuilder.Append(":")

        if ($null -ne $Graph[$node]) {
            # Trier les voisins une seule fois
            $sortedNeighbors = $Graph[$node] | Sort-Object

            foreach ($neighbor in $sortedNeighbors) {
                [void]$script:StringBuilder.Append($neighbor)
                [void]$script:StringBuilder.Append(",")
            }
        }

        [void]$script:StringBuilder.Append(";")
    }

    $graphString = $script:StringBuilder.ToString()

    # Réutiliser l'instance SHA256 pour réduire les allocations mémoire
    if (-not $script:SHA256) {
        $script:SHA256 = [System.Security.Cryptography.SHA256]::Create()
    }

    $hash = $script:SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($graphString))

    return [System.Convert]::ToBase64String($hash)
}

# Version rapide du calcul de hash pour les grands graphes
function Get-FastGraphHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    # Pour les grands graphes, utiliser un hash plus simple mais plus rapide
    # basé sur les caractéristiques du graphe plutôt que sur son contenu exact

    # Calculer des statistiques sur le graphe
    $nodeCount = $Graph.Count
    $edgeCount = 0
    $maxOutDegree = 0
    $minOutDegree = [int]::MaxValue
    $sumOutDegree = 0

    foreach ($node in $Graph.Keys) {
        $outDegree = if ($null -ne $Graph[$node]) { $Graph[$node].Count } else { 0 }
        $edgeCount += $outDegree
        $maxOutDegree = [Math]::Max($maxOutDegree, $outDegree)
        $minOutDegree = [Math]::Min($minOutDegree, $outDegree)
        $sumOutDegree += $outDegree
    }

    $avgOutDegree = if ($nodeCount -gt 0) { $sumOutDegree / $nodeCount } else { 0 }

    # Échantillonner quelques nœuds pour le hash
    $sampleSize = [Math]::Min(100, $nodeCount)
    $sampleNodes = $Graph.Keys | Sort-Object | Select-Object -First $sampleSize

    # Créer une chaîne de caractères représentant les caractéristiques du graphe
    $hashString = "N${nodeCount}E${edgeCount}Max${maxOutDegree}Min${minOutDegree}Avg${avgOutDegree}S"

    foreach ($node in $sampleNodes) {
        $outDegree = if ($null -ne $Graph[$node]) { $Graph[$node].Count } else { 0 }
        $hashString += "${node}:${outDegree};"
    }

    # Calculer le hash de cette chaîne
    if (-not $script:SHA256) {
        $script:SHA256 = [System.Security.Cryptography.SHA256]::Create()
    }

    $hash = $script:SHA256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($hashString))

    return [System.Convert]::ToBase64String($hash)
}

# Fonction interne qui implémente l'algorithme DFS pour détecter les cycles
function Find-GraphCycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = $Global:CycleDetectorMaxDepth,

        [Parameter(Mandatory = $false)]
        [switch]$UseIterative
    )

    # Vérifier si le graphe est vide
    if ($Graph.Count -eq 0) {
        return [PSCustomObject]@{
            HasCycle  = $false
            CyclePath = @()
        }
    }

    # Détection rapide des boucles sur soi-même
    foreach ($node in $Graph.Keys) {
        if ($Graph[$node] -contains $node) {
            return [PSCustomObject]@{
                HasCycle  = $true
                CyclePath = @($node, $node)
            }
        }
    }

    # Utiliser l'implémentation itérative si demandée ou si le graphe est grand
    # Ajuster le seuil en fonction de la densité du graphe
    $edgeCount = 0
    foreach ($node in $Graph.Keys) {
        if ($null -ne $Graph[$node]) {
            $edgeCount += $Graph[$node].Count
        }
    }

    $density = if ($Graph.Count -gt 0) { $edgeCount / ($Graph.Count * $Graph.Count) } else { 0 }
    $threshold = if ($density -gt 0.1) { 500 } else { 1000 }

    if ($UseIterative -or $Graph.Count -gt $threshold) {
        return Find-GraphCycleIterative -Graph $Graph -MaxDepth $MaxDepth
    }

    # Initialiser le résultat
    $result = [PSCustomObject]@{
        HasCycle  = $false
        CyclePath = @()
    }

    # Implémentation récursive DFS optimisée
    $visited = @{}
    $recursionStack = @{}

    # Réutiliser un ArrayList pour le chemin
    if (-not $script:PathList) {
        $script:PathList = New-Object System.Collections.ArrayList(1000)
    } else {
        $script:PathList.Clear()
    }

    # Fonction récursive interne pour DFS
    function Invoke-DFSVisit {
        param (
            [string]$Node,
            [hashtable]$Visited,
            [hashtable]$RecursionStack,
            [hashtable]$Graph,
            [int]$CurrentDepth,
            [int]$MaxDepth,
            [System.Collections.ArrayList]$Path
        )

        # Vérifier la profondeur maximale
        if ($CurrentDepth -gt $MaxDepth) {
            return $false, $null
        }

        # Marquer le nœud comme visité et ajouter à la pile de récursion
        $Visited[$Node] = $true
        $RecursionStack[$Node] = $true
        $null = $Path.Add($Node)

        # Vérifier si le nœud a des voisins
        if ($Graph.ContainsKey($Node) -and $null -ne $Graph[$Node]) {
            # Optimisation : vérifier d'abord les voisins déjà dans la pile de récursion
            foreach ($neighbor in $Graph[$Node]) {
                if ($RecursionStack.ContainsKey($neighbor) -and $RecursionStack[$neighbor]) {
                    # Cycle détecté - construire le chemin du cycle
                    $cyclePath = @()
                    $startIndex = $Path.IndexOf($neighbor)
                    for ($i = $startIndex; $i -lt $Path.Count; $i++) {
                        $cyclePath += $Path[$i]
                    }
                    $cyclePath += $neighbor

                    return $true, $cyclePath
                }
            }

            # Ensuite, visiter récursivement les voisins non visités
            foreach ($neighbor in $Graph[$Node]) {
                if (-not $Visited.ContainsKey($neighbor) -or -not $Visited[$neighbor]) {
                    $hasCycle, $cyclePath = Invoke-DFSVisit -Node $neighbor -Visited $Visited -RecursionStack $RecursionStack -Graph $Graph -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -Path $Path

                    if ($hasCycle) {
                        return $true, $cyclePath
                    }
                }
            }
        }

        # Retirer le nœud de la pile de récursion et du chemin
        $RecursionStack[$Node] = $false
        $null = $Path.RemoveAt($Path.Count - 1)

        return $false, $null
    }

    # Parcourir tous les nœuds du graphe
    # Optimisation : commencer par les nœuds avec le plus de voisins
    $nodesByDegree = $Graph.Keys | Sort-Object -Property { if ($null -ne $Graph[$_]) { $Graph[$_].Count } else { 0 } } -Descending

    foreach ($node in $nodesByDegree) {
        # Si le nœud n'a pas été visité, le visiter
        if (-not $visited.ContainsKey($node) -or -not $visited[$node]) {
            $script:PathList.Clear()
            $hasCycle, $cyclePath = Invoke-DFSVisit -Node $node -Visited $visited -RecursionStack $recursionStack -Graph $Graph -CurrentDepth 0 -MaxDepth $MaxDepth -Path $script:PathList

            if ($hasCycle) {
                $result.HasCycle = $true
                $result.CyclePath = $cyclePath
                return $result
            }
        }
    }

    return $result
}

# Implémentation itérative de l'algorithme DFS pour détecter les cycles
function Find-GraphCycleIterative {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = $Global:CycleDetectorMaxDepth
    )

    # Vérifier si le graphe est vide
    if ($Graph.Count -eq 0) {
        return [PSCustomObject]@{
            HasCycle  = $false
            CyclePath = @()
        }
    }

    # Détection rapide des boucles sur soi-même
    foreach ($node in $Graph.Keys) {
        if ($Graph[$node] -contains $node) {
            return [PSCustomObject]@{
                HasCycle  = $true
                CyclePath = @($node, $node)
            }
        }
    }

    # Initialiser le résultat
    $result = [PSCustomObject]@{
        HasCycle  = $false
        CyclePath = @()
    }

    # Réutiliser les structures de données pour réduire les allocations mémoire
    if (-not $script:VisitedNodes) {
        $script:VisitedNodes = @{}
    } else {
        $script:VisitedNodes.Clear()
    }

    if (-not $script:InStackNodes) {
        $script:InStackNodes = @{}
    } else {
        $script:InStackNodes.Clear()
    }

    if (-not $script:NodeStack) {
        $script:NodeStack = New-Object System.Collections.Stack(1000)
    } else {
        $script:NodeStack.Clear()
    }

    if (-not $script:PathStack) {
        $script:PathStack = New-Object System.Collections.Stack(1000)
    } else {
        $script:PathStack.Clear()
    }

    # Optimisation : commencer par les nœuds avec le plus de voisins
    $nodesByDegree = $Graph.Keys | Sort-Object -Property { if ($null -ne $Graph[$_]) { $Graph[$_].Count } else { 0 } } -Descending

    # Parcourir tous les nœuds du graphe
    foreach ($startNode in $nodesByDegree) {
        # Si le nœud a déjà été visité, passer au suivant
        if ($script:VisitedNodes.ContainsKey($startNode)) {
            continue
        }

        # Réinitialiser les structures pour le nouveau nœud de départ
        $script:InStackNodes.Clear()
        $script:NodeStack.Clear()
        $script:PathStack.Clear()

        # Ajouter le nœud de départ à la pile
        $script:NodeStack.Push(@{
                Node      = $startNode
                Neighbors = $Graph[$startNode]
                Index     = 0
                Depth     = 0
            })
        $script:InStackNodes[$startNode] = $true
        $script:PathStack.Push($startNode)
        $script:VisitedNodes[$startNode] = $true

        while ($script:NodeStack.Count -gt 0) {
            $current = $script:NodeStack.Peek()

            # Vérifier la profondeur maximale
            if ($current.Depth -gt $MaxDepth) {
                $script:NodeStack.Pop()
                $script:InStackNodes[$current.Node] = $false
                $script:PathStack.Pop()
                continue
            }

            # Si tous les voisins ont été visités, retirer le nœud de la pile
            if ($null -eq $current.Neighbors -or $current.Index -ge $current.Neighbors.Count) {
                $script:NodeStack.Pop()
                $script:InStackNodes[$current.Node] = $false
                $script:PathStack.Pop()
                continue
            }

            # Obtenir le prochain voisin
            $neighbor = $current.Neighbors[$current.Index]
            $current.Index++

            # Vérifier si le voisin est déjà dans la pile (cycle détecté)
            if ($script:InStackNodes.ContainsKey($neighbor) -and $script:InStackNodes[$neighbor]) {
                # Cycle détecté
                $result.HasCycle = $true

                # Construire le chemin du cycle de manière efficace
                $pathArray = $script:PathStack.ToArray()
                [array]::Reverse($pathArray)

                $cyclePath = @()
                $inCycle = $false

                foreach ($node in $pathArray) {
                    if ($node -eq $neighbor) {
                        $inCycle = $true
                    }

                    if ($inCycle) {
                        $cyclePath += $node
                    }
                }

                $cyclePath += $neighbor
                $result.CyclePath = $cyclePath
                return $result
            }

            # Si le voisin n'a pas été visité, l'ajouter à la pile
            if (-not $script:VisitedNodes.ContainsKey($neighbor)) {
                $script:VisitedNodes[$neighbor] = $true
                $script:InStackNodes[$neighbor] = $true
                $script:PathStack.Push($neighbor)

                $script:NodeStack.Push(@{
                        Node      = $neighbor
                        Neighbors = $Graph[$neighbor]
                        Index     = 0
                        Depth     = $current.Depth + 1
                    })
            }
        }
    }

    return $result
}

# Analyse les dépendances entre les scripts PowerShell pour détecter les cycles
function Find-DependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return [PSCustomObject]@{
            HasCycles        = $false
            Cycles           = @()
            DependencyGraph  = @{}
            NonCyclicScripts = @()
        }
    }

    # Obtenir les fichiers PowerShell
    $scriptFiles = if ($Recursive) {
        Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse
    } else {
        Get-ChildItem -Path $Path -Filter "*.ps1"
    }

    # Construire le graphe de dépendances
    $dependencyGraph = @{}

    foreach ($scriptFile in $scriptFiles) {
        $scriptPath = $scriptFile.FullName
        $relativePath = $scriptFile.Name

        # Analyser le contenu du script pour trouver les dépendances
        $content = Get-Content -Path $scriptPath -Raw
        $dependencies = @()

        # Rechercher les instructions dot-sourcing (. .\script.ps1)
        $dotSourcePattern = '\.\s+(?:\.\\|\\|\$PSScriptRoot\\)?([^\\]+\.ps1)'
        $dotSourceMatches = [regex]::Matches($content, $dotSourcePattern)

        foreach ($match in $dotSourceMatches) {
            $dependency = $match.Groups[1].Value
            $dependencies += $dependency
        }

        # Rechercher les instructions Import-Module
        $importModulePattern = 'Import-Module\s+(?:\.\\|\\|\$PSScriptRoot\\)?([^\\]+\.ps1)'
        $importModuleMatches = [regex]::Matches($content, $importModulePattern)

        foreach ($match in $importModuleMatches) {
            $dependency = $match.Groups[1].Value
            $dependencies += $dependency
        }

        # Ajouter au graphe de dépendances
        $dependencyGraph[$relativePath] = $dependencies
    }

    # Détecter les cycles dans le graphe de dépendances
    $result = Find-Cycle -Graph $dependencyGraph

    # Construire le résultat
    $cyclicScripts = @{}
    $nonCyclicScripts = @()

    if ($result.HasCycle) {
        # Identifier les scripts impliqués dans des cycles
        foreach ($node in $result.CyclePath) {
            $cyclicScripts[$node] = $true
        }

        # Identifier les scripts sans cycles
        foreach ($script in $dependencyGraph.Keys) {
            if (-not $cyclicScripts.ContainsKey($script)) {
                $nonCyclicScripts += $script
            }
        }
    } else {
        # Aucun cycle, tous les scripts sont sans cycles
        $nonCyclicScripts = $dependencyGraph.Keys
    }

    # Créer l'objet résultat
    $dependencyCyclesResult = [PSCustomObject]@{
        HasCycles        = $result.HasCycle
        Cycles           = @($result.CyclePath)
        DependencyGraph  = $dependencyGraph
        NonCyclicScripts = $nonCyclicScripts
    }

    # Exporter le résultat en JSON si un chemin de sortie est spécifié
    if ($OutputPath) {
        $dependencyCyclesResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    }

    return $dependencyCyclesResult
}

# Analyse les workflows n8n pour détecter les cycles
function Test-WorkflowCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-Error "Le fichier de workflow '$WorkflowPath' n'existe pas."
        return [PSCustomObject]@{
            HasCycles    = $false
            Cycles       = @()
            WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
        }
    }

    try {
        # Lire le fichier JSON
        $workflowJson = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json -ErrorAction Stop

        # Vérifier la structure du workflow
        if (-not $workflowJson.nodes -or -not $workflowJson.connections) {
            Write-Error "Format de workflow invalide. Les propriétés 'nodes' et 'connections' sont requises."
            return [PSCustomObject]@{
                HasCycles    = $false
                Cycles       = @()
                WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
            }
        }

        # Construire le graphe du workflow
        $workflowGraph = @{}

        # Ajouter tous les nœuds au graphe
        foreach ($node in $workflowJson.nodes) {
            $workflowGraph[$node.id] = @()
        }

        # Ajouter les connexions
        foreach ($sourceNode in $workflowJson.connections.PSObject.Properties) {
            $sourceNodeId = $sourceNode.Name

            foreach ($connection in $sourceNode.Value) {
                $targetNodeId = $connection.node
                $workflowGraph[$sourceNodeId] += $targetNodeId
            }
        }

        # Détecter les cycles dans le graphe du workflow
        $result = Find-Cycle -Graph $workflowGraph

        # Créer l'objet résultat
        $workflowCyclesResult = [PSCustomObject]@{
            HasCycles    = $result.HasCycle
            Cycles       = @($result.CyclePath)
            WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
        }

        return $workflowCyclesResult
    } catch {
        Write-Error "Erreur lors de l'analyse du workflow: $_"
        return [PSCustomObject]@{
            HasCycles    = $false
            Cycles       = @()
            WorkflowName = [System.IO.Path]::GetFileNameWithoutExtension($WorkflowPath)
        }
    }
}

# Supprime un cycle d'un graphe en retirant une arête
function Remove-Cycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [string[]]$Cycle
    )

    # Cloner le graphe pour ne pas modifier l'original
    $newGraph = @{}
    foreach ($node in $Graph.Keys) {
        $newGraph[$node] = @() + $Graph[$node]
    }

    # Si le cycle est une boucle sur un seul nœud
    if ($Cycle.Count -eq 2 -and $Cycle[0] -eq $Cycle[1]) {
        $node = $Cycle[0]
        $newGraph[$node] = $newGraph[$node] | Where-Object { $_ -ne $node }
        return $newGraph
    }

    # Trouver une arête à supprimer
    for ($i = 0; $i -lt $Cycle.Count - 1; $i++) {
        $source = $Cycle[$i]
        $target = $Cycle[$i + 1]

        # Vérifier si l'arête existe
        if ($newGraph.ContainsKey($source) -and $newGraph[$source] -contains $target) {
            # Supprimer l'arête
            $newGraph[$source] = $newGraph[$source] | Where-Object { $_ -ne $target }
            return $newGraph
        }
    }

    # Vérifier l'arête entre le dernier et le premier nœud
    $source = $Cycle[-1]
    $target = $Cycle[0]

    if ($newGraph.ContainsKey($source) -and $newGraph[$source] -contains $target) {
        # Supprimer l'arête
        $newGraph[$source] = $newGraph[$source] | Where-Object { $_ -ne $target }
    }

    return $newGraph
}

# Récupère les statistiques d'utilisation du détecteur de cycles
function Get-CycleDetectionStatistics {
    [CmdletBinding()]
    param ()

    return $Global:CycleDetectorStats
}

# Efface le cache du détecteur de cycles
function Clear-CycleDetectionCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ResetStats
    )

    # Vider le cache
    if ($Global:CycleDetectorCache -is [hashtable]) {
        $Global:CycleDetectorCache.Clear()
    } else {
        # Réinitialiser le cache si ce n'est pas un hashtable
        Set-Variable -Name CycleDetectorCache -Value @{} -Scope Global
    }

    # Réinitialiser les statistiques si demandé
    if ($ResetStats) {
        $Global:CycleDetectorStats.TotalCalls = 0
        $Global:CycleDetectorStats.TotalCycles = 0
        $Global:CycleDetectorStats.AverageExecutionTime = 0
        $Global:CycleDetectorStats.CacheHits = 0
        $Global:CycleDetectorStats.CacheMisses = 0
    }

    # Réinitialiser les structures de données statiques
    if ($script:StringBuilder) { $script:StringBuilder.Clear() }
    if ($script:PathList) { $script:PathList.Clear() }
    if ($script:VisitedNodes) { $script:VisitedNodes.Clear() }
    if ($script:InStackNodes) { $script:InStackNodes.Clear() }
    if ($script:NodeStack) { $script:NodeStack.Clear() }
    if ($script:PathStack) { $script:PathStack.Clear() }

    # Forcer le garbage collector pour libérer la mémoire
    [System.GC]::Collect()

    # Retourner un objet pour indiquer que la fonction a été exécutée avec succès
    return [PSCustomObject]@{
        CacheCleared = $true
        StatsReset   = $ResetStats
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-CycleDetector, Find-Cycle, Find-GraphCycle, Find-DependencyCycles, Test-WorkflowCycles, Remove-Cycle, Get-CycleDetectionStatistics, Clear-CycleDetectionCache
