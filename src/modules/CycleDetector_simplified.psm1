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

# Retourne les statistiques d'utilisation du détecteur de cycles
function Get-CycleDetectionStatistics {
    [CmdletBinding()]
    param ()

    return $Global:CycleDetectorStats
}

# Vide le cache du détecteur de cycles
function Clear-CycleDetectionCache {
    [CmdletBinding()]
    param ()

    $Global:CycleDetectorCache.Clear()
    Write-Host "Cache du détecteur de cycles vidé."
}

# Importer le module de visualisation des cycles
$cycleVizPath = Join-Path -Path $PSScriptRoot -ChildPath "CycleViz.psm1"
if (Test-Path -Path $cycleVizPath) {
    Import-Module $cycleVizPath -Force
} else {
    Write-Warning "Le module de visualisation des cycles n'a pas ete trouve: $cycleVizPath"
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-CycleDetector, Find-Cycle, Find-GraphCycle, Get-CycleDetectionStatistics, Clear-CycleDetectionCache
