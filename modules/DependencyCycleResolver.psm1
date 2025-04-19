#Requires -Version 5.1
<#
.SYNOPSIS
    Module de résolution automatique des cycles de dépendances.
.DESCRIPTION
    Ce module fournit des fonctionnalités pour résoudre automatiquement les cycles de dépendances
    détectés dans les scripts PowerShell et les workflows n8n.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Variables globales
$script:CycleResolverEnabled = $true
$script:CycleResolverMaxIterations = 10
$script:CycleResolverStrategy = "MinimumImpact" # Stratégies: MinimumImpact, WeightBased, Random
$script:CycleResolverStats = @{
    TotalResolutions = 0
    SuccessfulResolutions = 0
    FailedResolutions = 0
    AverageIterations = 0
    LastResolutionTime = $null
}

# Initialise le résolveur de cycles avec les paramètres spécifiés
function Initialize-DependencyCycleResolver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinimumImpact", "WeightBased", "Random")]
        [string]$Strategy = "MinimumImpact"
    )

    $script:CycleResolverEnabled = $Enabled
    $script:CycleResolverMaxIterations = $MaxIterations
    $script:CycleResolverStrategy = $Strategy

    # Vérifier si le module CycleDetector est disponible
    if (-not (Get-Module -Name CycleDetector -ListAvailable)) {
        try {
            $cycleDetectorPath = Join-Path -Path $PSScriptRoot -ChildPath "CycleDetector.psm1"
            Import-Module $cycleDetectorPath -Force -ErrorAction Stop
        } catch {
            Write-Error "Le module CycleDetector n'a pas été trouvé. Assurez-vous qu'il est installé et disponible."
            return $false
        }
    }

    return $true
}

# Résout automatiquement les cycles de dépendances dans un graphe
function Resolve-DependencyCycle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$CycleResult,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinimumImpact", "WeightBased", "Random")]
        [string]$Strategy = $script:CycleResolverStrategy,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = $script:CycleResolverMaxIterations,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le résolveur est activé
    if (-not $script:CycleResolverEnabled) {
        Write-Warning "Le résolveur de cycles est désactivé."
        return $false
    }

    # Vérifier si le résultat contient un cycle
    if (-not $CycleResult.HasCycle -and -not $CycleResult.HasCycles) {
        Write-Warning "Aucun cycle à résoudre."
        return $false
    }

    # Mesurer le temps d'exécution
    $startTime = Get-Date

    # Initialiser les statistiques
    $script:CycleResolverStats.TotalResolutions++
    $iterations = 0
    $success = $false

    # Obtenir le graphe et le cycle
    $graph = if ($CycleResult.DependencyGraph) { 
        $CycleResult.DependencyGraph.Clone() 
    } elseif ($CycleResult.Graph) { 
        $CycleResult.Graph.Clone() 
    } else {
        Write-Error "Le résultat ne contient pas de graphe de dépendances."
        $script:CycleResolverStats.FailedResolutions++
        return $false
    }

    $cycle = if ($CycleResult.Cycles) { 
        $CycleResult.Cycles 
    } elseif ($CycleResult.CyclePath) { 
        $CycleResult.CyclePath 
    } else {
        Write-Error "Le résultat ne contient pas de cycle."
        $script:CycleResolverStats.FailedResolutions++
        return $false
    }

    # Boucle de résolution
    while ($iterations -lt $MaxIterations) {
        $iterations++

        # Sélectionner l'arête à supprimer selon la stratégie
        $edgeToRemove = Select-EdgeToRemove -Graph $graph -Cycle $cycle -Strategy $Strategy

        if (-not $edgeToRemove) {
            Write-Warning "Impossible de sélectionner une arête à supprimer."
            break
        }

        $source = $edgeToRemove.Source
        $target = $edgeToRemove.Target

        # Supprimer l'arête
        if ($PSCmdlet.ShouldProcess("$source -> $target", "Supprimer l'arête")) {
            $graph[$source] = $graph[$source] | Where-Object { $_ -ne $target }

            # Vérifier si le cycle a été résolu
            $newCycleCheck = Find-Cycle -Graph $graph
            if (-not $newCycleCheck.HasCycle) {
                $success = $true
                break
            }

            # Mettre à jour le cycle pour la prochaine itération
            $cycle = $newCycleCheck.CyclePath
        }
    }

    # Mettre à jour les statistiques
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalMilliseconds
    $script:CycleResolverStats.LastResolutionTime = $executionTime

    if ($success) {
        $script:CycleResolverStats.SuccessfulResolutions++
        $script:CycleResolverStats.AverageIterations = (($script:CycleResolverStats.AverageIterations * ($script:CycleResolverStats.SuccessfulResolutions - 1)) + $iterations) / $script:CycleResolverStats.SuccessfulResolutions

        # Retourner le graphe modifié
        return [PSCustomObject]@{
            Success = $true
            Graph = $graph
            RemovedEdges = @(@{Source = $source; Target = $target})
            Iterations = $iterations
            ExecutionTime = $executionTime
        }
    } else {
        $script:CycleResolverStats.FailedResolutions++
        Write-Warning "Impossible de résoudre le cycle après $iterations itérations."
        return [PSCustomObject]@{
            Success = $false
            Graph = $graph
            RemovedEdges = @()
            Iterations = $iterations
            ExecutionTime = $executionTime
        }
    }
}

# Résout automatiquement les cycles de dépendances dans un script PowerShell
function Resolve-ScriptDependencyCycle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinimumImpact", "WeightBased", "Random")]
        [string]$Strategy = $script:CycleResolverStrategy,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = $script:CycleResolverMaxIterations,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath
    )

    # Vérifier si le résolveur est activé
    if (-not $script:CycleResolverEnabled) {
        Write-Warning "Le résolveur de cycles est désactivé."
        return $false
    }

    # Détecter les cycles de dépendances
    $cycleResult = Find-ScriptDependencyCycles -Path $Path -Recursive:$Recursive

    if (-not $cycleResult.HasCycles) {
        Write-Host "Aucun cycle de dépendances détecté."
        return [PSCustomObject]@{
            Success = $true
            Path = $Path
            CyclesDetected = 0
            CyclesResolved = 0
            RemovedEdges = @()
        }
    }

    Write-Host "Cycles de dépendances détectés: $($cycleResult.Cycles.Count)"

    # Résoudre les cycles
    $resolvedCycles = 0
    $removedEdges = @()

    $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult -Strategy $Strategy -MaxIterations $MaxIterations -Force:$Force

    if ($resolveResult.Success) {
        $resolvedCycles++
        $removedEdges += $resolveResult.RemovedEdges

        Write-Host "Cycle résolu en supprimant l'arête: $($resolveResult.RemovedEdges[0].Source) -> $($resolveResult.RemovedEdges[0].Target)"
    } else {
        Write-Warning "Impossible de résoudre le cycle."
    }

    # Générer un rapport si demandé
    if ($GenerateReport) {
        $report = [PSCustomObject]@{
            Path = $Path
            CyclesDetected = $cycleResult.Cycles.Count
            CyclesResolved = $resolvedCycles
            RemovedEdges = $removedEdges
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        if ($ReportPath) {
            $reportDir = Split-Path -Path $ReportPath -Parent
            if (-not (Test-Path -Path $reportDir)) {
                New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
            }

            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding utf8
            Write-Host "Rapport généré: $ReportPath"
        }
    }

    return [PSCustomObject]@{
        Success = ($resolvedCycles -gt 0)
        Path = $Path
        CyclesDetected = $cycleResult.Cycles.Count
        CyclesResolved = $resolvedCycles
        RemovedEdges = $removedEdges
    }
}

# Résout automatiquement les cycles dans un workflow n8n
function Resolve-WorkflowCycle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinimumImpact", "WeightBased", "Random")]
        [string]$Strategy = $script:CycleResolverStrategy,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = $script:CycleResolverMaxIterations,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath
    )

    # Vérifier si le résolveur est activé
    if (-not $script:CycleResolverEnabled) {
        Write-Warning "Le résolveur de cycles est désactivé."
        return $false
    }

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $WorkflowPath -PathType Leaf)) {
        Write-Error "Le fichier '$WorkflowPath' n'existe pas."
        return $false
    }

    # Détecter les cycles dans le workflow
    $cycleResult = Test-WorkflowCycles -WorkflowPath $WorkflowPath

    if (-not $cycleResult.HasCycle) {
        Write-Host "Aucun cycle détecté dans le workflow."
        return [PSCustomObject]@{
            Success = $true
            WorkflowPath = $WorkflowPath
            CyclesDetected = 0
            CyclesResolved = 0
            RemovedEdges = @()
        }
    }

    Write-Host "Cycle détecté dans le workflow: $($cycleResult.CyclePath -join ' -> ')"

    # Résoudre le cycle
    if ($PSCmdlet.ShouldProcess($WorkflowPath, "Résoudre le cycle")) {
        # Lire le contenu du workflow
        $workflowContent = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json

        # Identifier les connexions qui forment le cycle
        $cyclePath = $cycleResult.CyclePath
        $connections = @()

        for ($i = 0; $i -lt $cyclePath.Count - 1; $i++) {
            $sourceNode = $cyclePath[$i]
            $targetNode = $cyclePath[$i + 1]

            # Trouver la connexion correspondante
            foreach ($connection in $workflowContent.connections) {
                if ($connection.source.node -eq $sourceNode -and $connection.target.node -eq $targetNode) {
                    $connections += $connection
                    break
                }
            }
        }

        # Sélectionner la connexion à supprimer selon la stratégie
        $connectionToRemove = $null

        switch ($Strategy) {
            "MinimumImpact" {
                # Sélectionner la connexion avec le moins d'impact (par exemple, la moins utilisée)
                $connectionToRemove = $connections | Sort-Object -Property { $_.source.node.Length + $_.target.node.Length } | Select-Object -First 1
            }
            "WeightBased" {
                # Sélectionner la connexion avec le poids le plus faible (si disponible)
                $connectionToRemove = $connections | Sort-Object -Property { if ($_.weight) { $_.weight } else { 1 } } | Select-Object -First 1
            }
            "Random" {
                # Sélectionner une connexion aléatoire
                $connectionToRemove = $connections | Get-Random
            }
        }

        if ($connectionToRemove) {
            # Supprimer la connexion
            $sourceNode = $connectionToRemove.source.node
            $targetNode = $connectionToRemove.target.node

            $newConnections = @()
            foreach ($connection in $workflowContent.connections) {
                if (-not ($connection.source.node -eq $sourceNode -and $connection.target.node -eq $targetNode)) {
                    $newConnections += $connection
                }
            }

            # Mettre à jour le workflow
            $workflowContent.connections = $newConnections

            # Enregistrer le workflow modifié
            $workflowContent | ConvertTo-Json -Depth 10 | Set-Content -Path $WorkflowPath

            Write-Host "Connexion supprimée: $sourceNode -> $targetNode"

            # Générer un rapport si demandé
            if ($GenerateReport) {
                $report = [PSCustomObject]@{
                    WorkflowPath = $WorkflowPath
                    CyclesDetected = 1
                    CyclesResolved = 1
                    RemovedEdges = @(@{Source = $sourceNode; Target = $targetNode})
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }

                if ($ReportPath) {
                    $reportDir = Split-Path -Path $ReportPath -Parent
                    if (-not (Test-Path -Path $reportDir)) {
                        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
                    }

                    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding utf8
                    Write-Host "Rapport généré: $ReportPath"
                }
            }

            return [PSCustomObject]@{
                Success = $true
                WorkflowPath = $WorkflowPath
                CyclesDetected = 1
                CyclesResolved = 1
                RemovedEdges = @(@{Source = $sourceNode; Target = $targetNode})
            }
        } else {
            Write-Warning "Impossible de sélectionner une connexion à supprimer."
            return [PSCustomObject]@{
                Success = $false
                WorkflowPath = $WorkflowPath
                CyclesDetected = 1
                CyclesResolved = 0
                RemovedEdges = @()
            }
        }
    }

    return $false
}

# Obtient les statistiques du résolveur de cycles
function Get-CycleResolverStatistics {
    [CmdletBinding()]
    param ()

    return [PSCustomObject]@{
        Enabled = $script:CycleResolverEnabled
        MaxIterations = $script:CycleResolverMaxIterations
        Strategy = $script:CycleResolverStrategy
        TotalResolutions = $script:CycleResolverStats.TotalResolutions
        SuccessfulResolutions = $script:CycleResolverStats.SuccessfulResolutions
        FailedResolutions = $script:CycleResolverStats.FailedResolutions
        SuccessRate = if ($script:CycleResolverStats.TotalResolutions -gt 0) {
            [math]::Round(($script:CycleResolverStats.SuccessfulResolutions / $script:CycleResolverStats.TotalResolutions) * 100, 2)
        } else { 0 }
        AverageIterations = $script:CycleResolverStats.AverageIterations
        LastResolutionTime = $script:CycleResolverStats.LastResolutionTime
    }
}

# Fonction interne pour sélectionner l'arête à supprimer selon la stratégie
function Select-EdgeToRemove {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [array]$Cycle,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinimumImpact", "WeightBased", "Random")]
        [string]$Strategy = "MinimumImpact"
    )

    # Créer la liste des arêtes du cycle
    $edges = @()
    for ($i = 0; $i -lt $Cycle.Count - 1; $i++) {
        $source = $Cycle[$i]
        $target = $Cycle[$i + 1]
        
        # Vérifier que l'arête existe
        if ($Graph.ContainsKey($source) -and $Graph[$source] -contains $target) {
            $edges += [PSCustomObject]@{
                Source = $source
                Target = $target
                Weight = 1 # Poids par défaut
            }
        }
    }

    # Ajouter l'arête qui ferme le cycle
    $lastSource = $Cycle[-1]
    $lastTarget = $Cycle[0]
    if ($Graph.ContainsKey($lastSource) -and $Graph[$lastSource] -contains $lastTarget) {
        $edges += [PSCustomObject]@{
            Source = $lastSource
            Target = $lastTarget
            Weight = 1 # Poids par défaut
        }
    }

    # Sélectionner l'arête selon la stratégie
    switch ($Strategy) {
        "MinimumImpact" {
            # Calculer l'impact de la suppression de chaque arête
            foreach ($edge in $edges) {
                # L'impact est le nombre de chemins qui passent par cette arête
                $impact = 0
                foreach ($node in $Graph.Keys) {
                    if ($node -eq $edge.Source) { continue }
                    
                    # Vérifier si le nœud peut atteindre la source de l'arête
                    $canReachSource = Test-PathExists -Graph $Graph -Source $node -Target $edge.Source
                    
                    if ($canReachSource) {
                        foreach ($otherNode in $Graph.Keys) {
                            if ($otherNode -eq $edge.Target) { continue }
                            
                            # Vérifier si la cible de l'arête peut atteindre l'autre nœud
                            $targetCanReachOther = Test-PathExists -Graph $Graph -Source $edge.Target -Target $otherNode
                            
                            if ($targetCanReachOther) {
                                $impact++
                            }
                        }
                    }
                }
                
                $edge | Add-Member -NotePropertyName Impact -NotePropertyValue $impact
            }
            
            # Sélectionner l'arête avec le moins d'impact
            return $edges | Sort-Object -Property Impact | Select-Object -First 1
        }
        "WeightBased" {
            # Sélectionner l'arête avec le poids le plus faible
            return $edges | Sort-Object -Property Weight | Select-Object -First 1
        }
        "Random" {
            # Sélectionner une arête aléatoire
            return $edges | Get-Random
        }
    }
}

# Fonction interne pour vérifier s'il existe un chemin entre deux nœuds
function Test-PathExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,

        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    # Utiliser un algorithme BFS pour trouver un chemin
    $queue = New-Object System.Collections.Queue
    $visited = @{}

    $queue.Enqueue($Source)
    $visited[$Source] = $true

    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()

        if ($current -eq $Target) {
            return $true
        }

        if ($Graph.ContainsKey($current) -and $Graph[$current]) {
            foreach ($neighbor in $Graph[$current]) {
                if (-not $visited.ContainsKey($neighbor) -or -not $visited[$neighbor]) {
                    $queue.Enqueue($neighbor)
                    $visited[$neighbor] = $true
                }
            }
        }
    }

    return $false
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-DependencyCycleResolver, Resolve-DependencyCycle, Resolve-ScriptDependencyCycle, Resolve-WorkflowCycle, Get-CycleResolverStatistics
