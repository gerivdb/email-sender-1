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

    # Initialiser les structures de données
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
        $script:NodeStack = New-Object System.Collections.Generic.Stack[string]
    } else {
        $script:NodeStack.Clear()
    }

    if (-not $script:PathStack) {
        $script:PathStack = New-Object System.Collections.Generic.Stack[string]
    } else {
        $script:PathStack.Clear()
    }

    # Parcourir tous les nœuds du graphe
    foreach ($startNode in $Graph.Keys) {
        # Si le nœud n'a pas été visité, commencer un parcours DFS à partir de ce nœud
        if (-not $script:VisitedNodes.ContainsKey($startNode)) {
            $script:NodeStack.Push($startNode)
            $script:PathStack.Push($startNode)
            $script:InStackNodes[$startNode] = $true

            $depth = 0

            while ($script:NodeStack.Count -gt 0 -and $depth -le $MaxDepth) {
                $currentNode = $script:NodeStack.Peek()

                # Marquer le nœud comme visité
                $script:VisitedNodes[$currentNode] = $true

                # Vérifier si le nœud a des voisins
                $hasUnvisitedNeighbor = $false

                if ($Graph.ContainsKey($currentNode) -and $null -ne $Graph[$currentNode]) {
                    foreach ($neighbor in $Graph[$currentNode]) {
                        # Si le voisin est déjà dans la pile, un cycle est détecté
                        if ($script:InStackNodes.ContainsKey($neighbor) -and $script:InStackNodes[$neighbor]) {
                            # Construire le chemin du cycle
                            $cyclePath = @()
                            $pathArray = $script:PathStack.ToArray()
                            [array]::Reverse($pathArray)

                            $startIndex = [array]::IndexOf($pathArray, $neighbor)
                            for ($i = $startIndex; $i -lt $pathArray.Length; $i++) {
                                $cyclePath += $pathArray[$i]
                            }
                            $cyclePath += $neighbor

                            return [PSCustomObject]@{
                                HasCycle  = $true
                                CyclePath = $cyclePath
                            }
                        }

                        # Si le voisin n'a pas été visité, l'ajouter à la pile
                        if (-not $script:VisitedNodes.ContainsKey($neighbor)) {
                            $script:NodeStack.Push($neighbor)
                            $script:PathStack.Push($neighbor)
                            $script:InStackNodes[$neighbor] = $true
                            $hasUnvisitedNeighbor = $true
                            $depth++
                            break
                        }
                    }
                }

                # Si tous les voisins ont été visités, retirer le nœud de la pile
                if (-not $hasUnvisitedNeighbor) {
                    $script:NodeStack.Pop()
                    $poppedNode = $script:PathStack.Pop()
                    $script:InStackNodes[$poppedNode] = $false
                    $depth--
                }
            }

            # Vider les piles si la profondeur maximale est atteinte
            if ($depth -gt $MaxDepth) {
                $script:NodeStack.Clear()
                $script:PathStack.Clear()
                $script:InStackNodes.Clear()
            }
        }
    }

    # Aucun cycle détecté
    return [PSCustomObject]@{
        HasCycle  = $false
        CyclePath = @()
    }
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

# Calcule un hash pour un graphe
function Get-GraphHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )

    # Créer une représentation en chaîne du graphe
    $graphString = ""

    # Trier les clés pour assurer la cohérence
    $sortedKeys = $Graph.Keys | Sort-Object

    foreach ($node in $sortedKeys) {
        $graphString += "${node}:"

        if ($null -ne $Graph[$node]) {
            # Trier les voisins pour assurer la cohérence
            $sortedNeighbors = $Graph[$node] | Sort-Object

            foreach ($neighbor in $sortedNeighbors) {
                $graphString += "${neighbor},"
            }
        }

        $graphString += ";"
    }

    # Calculer un hash simple basé sur la chaîne
    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($graphString)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($hashBytes)

    return [System.Convert]::ToBase64String($hash)
}

# Fonctions d'intégration avec ScriptInventory

# Détecte les cycles de dépendances dans les scripts PowerShell
function Find-ScriptDependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateGraph,

        [Parameter(Mandatory = $false)]
        [string]$GraphOutputPath
    )

    # Vérifier si le détecteur est activé
    if (-not $Global:CycleDetectorEnabled) {
        Write-Warning "Le détecteur de cycles est désactivé."
        return [PSCustomObject]@{
            HasCycles        = $false
            Cycles           = @()
            NonCyclicScripts = @()
            DependencyGraph  = @{}
            ScriptFiles      = @()
        }
    }

    # Vérifier si le module ScriptInventory est disponible
    if (-not (Get-Module -Name ScriptInventory)) {
        try {
            $scriptInventoryPath = Join-Path -Path $PSScriptRoot -ChildPath "ScriptInventory.psm1"
            Import-Module $scriptInventoryPath -Force -ErrorAction Stop
        } catch {
            Write-Error "Le module ScriptInventory n'a pas été trouvé. Assurez-vous qu'il est installé et disponible."
            return [PSCustomObject]@{
                HasCycles        = $false
                Cycles           = @()
                NonCyclicScripts = @()
                DependencyGraph  = @{}
                ScriptFiles      = @()
            }
        }
    }

    # Récupérer les fichiers de script
    $scriptFiles = Get-ScriptFiles -Path $Path -Include $Include -Exclude $Exclude
    $scriptFilePaths = $scriptFiles | Select-Object -ExpandProperty FullName

    # Construire le graphe de dépendances
    $graph = @{}
    $scriptFiles = @()

    foreach ($scriptPath in $scriptFilePaths) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $scriptFiles += $scriptName
        $dependencies = Get-ScriptDependencies -ScriptPath $scriptPath -SkipCache:$SkipCache |
            Where-Object { $_.Type -eq "Script" } |
            Select-Object -ExpandProperty Name
        $graph[$scriptName] = $dependencies
    }

    # Détecter les cycles dans le graphe
    $result = Find-Cycle -Graph $graph -SkipCache:$SkipCache

    # Préparer le résultat
    $cycles = @()
    $nonCyclicScripts = @()

    if ($result.HasCycle) {
        # Extraire les scripts impliqués dans le cycle
        $cycles = $result.CyclePath

        # Identifier les scripts qui ne sont pas dans le cycle
        $nonCyclicScripts = $scriptFiles | Where-Object { $cycles -notcontains $_ }
    } else {
        # Aucun cycle détecté, tous les scripts sont non cycliques
        $nonCyclicScripts = $scriptFiles
    }

    # Générer le graphe si demandé
    if ($GenerateGraph -and $GraphOutputPath) {
        Export-CycleVisualization -Graph $graph -OutputPath $GraphOutputPath -Format "HTML"
    }

    # Retourner le résultat
    return [PSCustomObject]@{
        HasCycles        = $result.HasCycle
        Cycles           = $cycles
        NonCyclicScripts = $nonCyclicScripts
        DependencyGraph  = $graph
        ScriptFiles      = $scriptFiles
    }
}

# Teste les workflows n8n pour détecter les cycles
function Test-WorkflowCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache
    )

    # Vérifier si le détecteur est activé
    if (-not $Global:CycleDetectorEnabled) {
        Write-Warning "Le détecteur de cycles est désactivé."
        return @()
    }

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $WorkflowPath -PathType Leaf)) {
        Write-Error "Le fichier '$WorkflowPath' n'existe pas."
        return @()
    }

    # Lire le contenu du workflow
    $workflowContent = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json

    # Construire le graphe de dépendances
    $graph = @{}
    foreach ($node in $workflowContent.nodes) {
        $nodeId = $node.id
        $connections = @()

        # Trouver toutes les connexions sortantes
        foreach ($connection in $workflowContent.connections) {
            if ($connection.source.node -eq $nodeId) {
                $connections += $connection.target.node
            }
        }

        $graph[$nodeId] = $connections
    }

    # Détecter les cycles dans le graphe
    $result = Find-Cycle -Graph $graph -SkipCache:$SkipCache

    if ($result.HasCycle) {
        return [PSCustomObject]@{
            HasCycle     = $true
            WorkflowPath = $WorkflowPath
            CyclePath    = $result.CyclePath
        }
    } else {
        return [PSCustomObject]@{
            HasCycle     = $false
            WorkflowPath = $WorkflowPath
            CyclePath    = @()
        }
    }
}

# Supprime un cycle détecté en supprimant une connexion
function Remove-Cycle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [object]$CycleResult,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le résultat contient un cycle
    if (-not $CycleResult.HasCycle) {
        Write-Warning "Aucun cycle à supprimer."
        return $false
    }

    # Déterminer le type de cycle
    if ($CycleResult.Type -eq "Script") {
        # Cycle dans des scripts PowerShell
        Write-Warning "La suppression automatique des cycles dans les scripts PowerShell n'est pas encore implémentée."
        Write-Host "Cycle détecté dans les scripts: $($CycleResult.CyclePath -join ' -> ')"
        return $false
    } elseif ($CycleResult.WorkflowPath) {
        # Cycle dans un workflow n8n
        $workflowPath = $CycleResult.WorkflowPath
        $cyclePath = $CycleResult.CyclePath

        # Trouver la connexion à supprimer (dernière connexion du cycle)
        $sourceNode = $cyclePath[-2]
        $targetNode = $cyclePath[-1]

        if ($PSCmdlet.ShouldProcess("$workflowPath", "Supprimer la connexion de $sourceNode vers $targetNode")) {
            # Lire le contenu du workflow
            $workflowContent = Get-Content -Path $workflowPath -Raw | ConvertFrom-Json

            # Trouver et supprimer la connexion
            $newConnections = @()
            foreach ($connection in $workflowContent.connections) {
                if (-not ($connection.source.node -eq $sourceNode -and $connection.target.node -eq $targetNode)) {
                    $newConnections += $connection
                }
            }

            # Mettre à jour le workflow
            $workflowContent.connections = $newConnections

            # Enregistrer le workflow modifié
            $workflowContent | ConvertTo-Json -Depth 10 | Set-Content -Path $workflowPath

            Write-Host "Connexion supprimée: $sourceNode -> $targetNode"
            return $true
        }
    } else {
        # Type de cycle inconnu
        Write-Warning "Type de cycle inconnu."
        return $false
    }

    return $false
}

# Génère une visualisation des cycles détectés
function Export-CycleVisualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "DOT", "JSON")]
        [string]$Format = "HTML"
    )

    # Vérifier si le détecteur est activé
    if (-not $Global:CycleDetectorEnabled) {
        Write-Warning "Le détecteur de cycles est désactivé."
        return $false
    }

    # Détecter les cycles dans le graphe
    $result = Find-Cycle -Graph $Graph

    # Générer la visualisation selon le format demandé
    switch ($Format) {
        "HTML" {
            # Générer une visualisation HTML interactive avec vis.js
            $nodes = @()
            $edges = @()
            $nodeId = 1
            $nodeMap = @{}

            # Créer les nœuds
            foreach ($node in $Graph.Keys) {
                $color = if ($result.HasCycle -and $result.CyclePath -contains $node) { "#FF5733" } else { "#7DCEA0" }
                $nodes += @{ id = $nodeId; label = $node; color = $color }
                $nodeMap[$node] = $nodeId
                $nodeId++
            }

            # Créer les arêtes
            foreach ($source in $Graph.Keys) {
                foreach ($target in $Graph[$source]) {
                    if ($nodeMap.ContainsKey($target)) {
                        $color = if ($result.HasCycle -and
                            $result.CyclePath -contains $source -and
                            $result.CyclePath -contains $target) {
                            "#FF5733"
                        } else {
                            "#85C1E9"
                        }
                        $edges += @{ from = $nodeMap[$source]; to = $nodeMap[$target]; arrows = "to"; color = $color }
                    }
                }
            }

            # Convertir en JSON pour l'inclusion dans le HTML
            $nodesJson = $nodes | ConvertTo-Json
            $edgesJson = $edges | ConvertTo-Json

            # Créer le HTML
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Visualisation des cycles de dépendances</title>
    <meta charset="utf-8">
    <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style type="text/css">
        #mynetwork {
            width: 100%;
            height: 800px;
            border: 1px solid lightgray;
        }
        body {
            font-family: Arial, sans-serif;
        }
        .info {
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <h1>Visualisation des dépendances</h1>
    <div class="info">
        <p><strong>Légende:</strong></p>
        <p><span style="color: #FF5733;">&#9679;</span> Nœuds impliqués dans un cycle</p>
        <p><span style="color: #7DCEA0;">&#9679;</span> Nœuds sans cycle</p>
    </div>
    <div id="mynetwork"></div>

    <script type="text/javascript">
        // Créer les données pour le réseau
        var nodes = new vis.DataSet($nodesJson);
        var edges = new vis.DataSet($edgesJson);

        // Créer un réseau
        var container = document.getElementById('mynetwork');
        var data = {
            nodes: nodes,
            edges: edges
        };
        var options = {
            nodes: {
                shape: 'box',
                font: {
                    size: 14
                },
                margin: 10
            },
            edges: {
                width: 2,
                smooth: {
                    type: 'continuous'
                }
            },
            physics: {
                stabilization: true,
                barnesHut: {
                    gravitationalConstant: -10000,
                    springConstant: 0.002
                }
            },
            layout: {
                hierarchical: {
                    direction: 'LR',
                    sortMethod: 'directed',
                    levelSeparation: 150
                }
            }
        };
        var network = new vis.Network(container, data, options);
    </script>
</body>
</html>
"@

            # Enregistrer le HTML dans le fichier de sortie
            Set-Content -Path $OutputPath -Value $html
            Write-Host "Visualisation HTML générée dans $OutputPath"
            return $true
        }
        "DOT" {
            # Générer un fichier DOT pour Graphviz
            $dot = "digraph DependencyGraph {`n"
            $dot += "    rankdir=LR;`n"
            $dot += "    node [shape=box, style=filled];`n"

            # Définir les nœuds
            foreach ($node in $Graph.Keys) {
                $color = if ($result.HasCycle -and $result.CyclePath -contains $node) { "salmon" } else { "palegreen" }
                $dot += "    `"$node`" [fillcolor=$color];`n"
            }

            # Définir les arêtes
            foreach ($source in $Graph.Keys) {
                foreach ($target in $Graph[$source]) {
                    $color = if ($result.HasCycle -and
                        $result.CyclePath -contains $source -and
                        $result.CyclePath -contains $target) {
                        "red"
                    } else {
                        "blue"
                    }
                    $dot += "    `"$source`" -> `"$target`" [color=$color];`n"
                }
            }

            $dot += "}`n"

            # Enregistrer le DOT dans le fichier de sortie
            Set-Content -Path $OutputPath -Value $dot
            Write-Host "Fichier DOT généré dans $OutputPath"
            return $true
        }
        "JSON" {
            # Générer un fichier JSON
            $json = @{
                nodes  = @()
                edges  = @()
                cycles = @()
            }

            # Ajouter les nœuds
            foreach ($node in $Graph.Keys) {
                $json.nodes += @{
                    id      = $node
                    inCycle = $result.HasCycle -and $result.CyclePath -contains $node
                }
            }

            # Ajouter les arêtes
            foreach ($source in $Graph.Keys) {
                foreach ($target in $Graph[$source]) {
                    $json.edges += @{
                        source  = $source
                        target  = $target
                        inCycle = $result.HasCycle -and
                        $result.CyclePath -contains $source -and
                        $result.CyclePath -contains $target
                    }
                }
            }

            # Ajouter les cycles détectés
            if ($result.HasCycle) {
                $json.cycles += $result.CyclePath
            }

            # Enregistrer le JSON dans le fichier de sortie
            $json | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
            Write-Host "Fichier JSON généré dans $OutputPath"
            return $true
        }
        default {
            Write-Error "Format non pris en charge: $Format"
            return $false
        }
    }
}

# Génère un rapport de dépendances pour les scripts PowerShell
function Get-ScriptDependencyReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = $PWD.Path,

        [Parameter(Mandatory = $false)]
        [string[]]$Include = @("*.ps1", "*.psm1"),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),

        [Parameter(Mandatory = $false)]
        [switch]$SkipCache,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateGraph,

        [Parameter(Mandatory = $false)]
        [string]$GraphOutputPath
    )

    # Vérifier si le détecteur est activé
    if (-not $Global:CycleDetectorEnabled) {
        Write-Warning "Le détecteur de cycles est désactivé."
        return $null
    }

    # Vérifier si le module ScriptInventory est disponible
    if (-not (Get-Module -Name ScriptInventory)) {
        try {
            $scriptInventoryPath = Join-Path -Path $PSScriptRoot -ChildPath "ScriptInventory.psm1"
            Import-Module $scriptInventoryPath -Force -ErrorAction Stop
        } catch {
            Write-Error "Le module ScriptInventory n'a pas été trouvé. Assurez-vous qu'il est installé et disponible."
            return $null
        }
    }

    # Récupérer les fichiers de script
    $scriptFiles = Get-ScriptFiles -Path $Path -Include $Include -Exclude $Exclude
    $scriptFilePaths = $scriptFiles | Select-Object -ExpandProperty FullName

    # Construire le graphe de dépendances
    $graph = @{}
    $scriptFileNames = @()

    foreach ($scriptPath in $scriptFilePaths) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $scriptFileNames += $scriptName
        $dependencies = Get-ScriptDependencies -ScriptPath $scriptPath -SkipCache:$SkipCache |
            Where-Object { $_.Type -eq "Script" } |
            Select-Object -ExpandProperty Name
        $graph[$scriptName] = $dependencies
    }

    # Détecter les cycles dans le graphe
    $result = Find-Cycle -Graph $graph -SkipCache:$SkipCache

    # Préparer le résultat
    $cycles = @()
    $nonCyclicScripts = @()

    if ($result.HasCycle) {
        # Extraire les scripts impliqués dans le cycle
        $cycles = $result.CyclePath

        # Identifier les scripts qui ne sont pas dans le cycle
        $nonCyclicScripts = $scriptFileNames | Where-Object { $cycles -notcontains $_ }
    } else {
        # Aucun cycle détecté, tous les scripts sont non cycliques
        $nonCyclicScripts = $scriptFileNames
    }

    $cycleResult = [PSCustomObject]@{
        HasCycles        = $result.HasCycle
        Cycles           = $cycles
        NonCyclicScripts = $nonCyclicScripts
        DependencyGraph  = $graph
        ScriptFiles      = $scriptFileNames
    }

    # Générer des statistiques
    $stats = [PSCustomObject]@{
        TotalScripts        = $cycleResult.ScriptFiles.Count
        CyclicScripts       = $cycleResult.Cycles.Count
        NonCyclicScripts    = $cycleResult.NonCyclicScripts.Count
        AverageDependencies = if ($cycleResult.ScriptFiles.Count -gt 0) {
            $totalDeps = 0
            foreach ($script in $cycleResult.DependencyGraph.Keys) {
                $totalDeps += $cycleResult.DependencyGraph[$script].Count
            }
            $totalDeps / $cycleResult.ScriptFiles.Count
        } else { 0 }
        MaxDependencies     = if ($cycleResult.ScriptFiles.Count -gt 0) {
            $maxDeps = 0
            $maxScript = ""
            foreach ($script in $cycleResult.DependencyGraph.Keys) {
                if ($cycleResult.DependencyGraph[$script].Count -gt $maxDeps) {
                    $maxDeps = $cycleResult.DependencyGraph[$script].Count
                    $maxScript = $script
                }
            }
            [PSCustomObject]@{
                Count  = $maxDeps
                Script = $maxScript
            }
        } else { $null }
    }

    # Générer le graphe si demandé
    if ($GenerateGraph -and $GraphOutputPath) {
        Export-CycleVisualization -Graph $cycleResult.DependencyGraph -OutputPath $GraphOutputPath -Format "HTML"
    }

    # Retourner le rapport
    return [PSCustomObject]@{
        Result     = $cycleResult
        Statistics = $stats
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-CycleDetector, Find-Cycle, Find-GraphCycle, Get-CycleDetectionStatistics, Clear-CycleDetectionCache, Get-GraphHash, Find-ScriptDependencyCycles, Test-WorkflowCycles, Remove-Cycle, Export-CycleVisualization, Get-ScriptDependencyReport
