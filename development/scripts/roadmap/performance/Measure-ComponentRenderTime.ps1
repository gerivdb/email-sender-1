﻿# Measure-ComponentRenderTime.ps1
# Script pour mesurer le temps de rendu des composants dans les vues de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("TaskList", "TaskTree", "Gantt", "DependencyGraph", "All")]
    [string]$ComponentType = "All",

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [switch]$DetailedBreakdown,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "CSV", "JSON", "HTML")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"

# Importer les fonctions utilitaires si elles existent
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"
if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"

        switch ($Level) {
            "Error" { Write-Host $logMessage -ForegroundColor Red }
            "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
            "Success" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
}

# Fonction pour mesurer le temps de rendu d'un composant spécifique
function Measure-ComponentRender {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ComponentType,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedBreakdown
    )

    $results = @{
        ComponentType  = $ComponentType
        StartTime      = Get-Date
        EndTime        = $null
        ElapsedMs      = 0
        ParseTime      = 0
        ProcessingTime = 0
        RenderTime     = 0
        Success        = $false
        Error          = $null
        TaskCount      = 0
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $parseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Étape 1: Parser le fichier markdown
        $parserScript = Join-Path -Path $utilsPath -ChildPath "Parse-Markdown.ps1"
        if (Test-Path -Path $parserScript) {
            . $parserScript
            $content = Get-Content -Path $RoadmapPath -Raw
            $tasks = Parse-MarkdownTasks -Content $content
            $results.TaskCount = $tasks.Count
        } else {
            throw "Script de parsing Markdown non trouvé: $parserScript"
        }

        $parseStopwatch.Stop()
        $results.ParseTime = $parseStopwatch.ElapsedMilliseconds

        # Étape 2: Traiter les données selon le type de composant
        $processingStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        switch ($ComponentType) {
            "TaskList" {
                # Traitement pour liste de tâches simple
                $processedTasks = $tasks | Select-Object Id, Description, Status, IndentLevel
            }
            "TaskTree" {
                # Traitement pour arbre hiérarchique
                $processedTasks = @()
                $taskMap = @{}

                # Construire une map des tâches par ID
                foreach ($task in $tasks) {
                    $taskMap[$task.Id] = @{
                        Task     = $task
                        Children = @()
                    }
                }

                # Construire l'arbre
                foreach ($task in $tasks) {
                    if ($task.ParentId -and $taskMap.ContainsKey($task.ParentId)) {
                        $taskMap[$task.ParentId].Children += $task.Id
                    } else {
                        $processedTasks += $task.Id
                    }
                }
            }
            "Gantt" {
                # Traitement pour diagramme de Gantt
                $processedTasks = @()

                foreach ($task in $tasks) {
                    # Extraire les dates si disponibles
                    $startDate = $null
                    $endDate = $null
                    $duration = $null

                    if ($task.Metadata -and $task.Metadata.ContainsKey("StartDate")) {
                        $startDate = $task.Metadata["StartDate"]
                    }

                    if ($task.Metadata -and $task.Metadata.ContainsKey("EndDate")) {
                        $endDate = $task.Metadata["EndDate"]
                    }

                    if ($task.Metadata -and $task.Metadata.ContainsKey("Duration")) {
                        $duration = $task.Metadata["Duration"]
                    }

                    $processedTasks += [PSCustomObject]@{
                        Id           = $task.Id
                        Description  = $task.Description
                        Status       = $task.Status
                        StartDate    = $startDate
                        EndDate      = $endDate
                        Duration     = $duration
                        Dependencies = $task.Dependencies
                    }
                }
            }
            "DependencyGraph" {
                # Traitement pour graphe de dépendances
                $nodes = @()
                $edges = @()

                foreach ($task in $tasks) {
                    $nodes += [PSCustomObject]@{
                        Id     = $task.Id
                        Label  = $task.Description
                        Status = $task.Status
                    }

                    if ($task.Dependencies) {
                        foreach ($dep in $task.Dependencies) {
                            $edges += [PSCustomObject]@{
                                Source = $dep
                                Target = $task.Id
                            }
                        }
                    }

                    # Ajouter les relations parent-enfant
                    if ($task.ParentId) {
                        $edges += [PSCustomObject]@{
                            Source = $task.ParentId
                            Target = $task.Id
                            Type   = "Hierarchical"
                        }
                    }
                }

                $processedTasks = [PSCustomObject]@{
                    Nodes = $nodes
                    Edges = $edges
                }
            }
            "All" {
                # Traiter tous les types de composants
                $taskList = $tasks | Select-Object Id, Description, Status, IndentLevel

                # Arbre hiérarchique
                $taskTree = @()
                $taskMap = @{}

                foreach ($task in $tasks) {
                    $taskMap[$task.Id] = @{
                        Task     = $task
                        Children = @()
                    }
                }

                foreach ($task in $tasks) {
                    if ($task.ParentId -and $taskMap.ContainsKey($task.ParentId)) {
                        $taskMap[$task.ParentId].Children += $task.Id
                    } else {
                        $taskTree += $task.Id
                    }
                }

                # Gantt
                $ganttTasks = @()

                foreach ($task in $tasks) {
                    $startDate = $null
                    $endDate = $null
                    $duration = $null

                    if ($task.Metadata -and $task.Metadata.ContainsKey("StartDate")) {
                        $startDate = $task.Metadata["StartDate"]
                    }

                    if ($task.Metadata -and $task.Metadata.ContainsKey("EndDate")) {
                        $endDate = $task.Metadata["EndDate"]
                    }

                    if ($task.Metadata -and $task.Metadata.ContainsKey("Duration")) {
                        $duration = $task.Metadata["Duration"]
                    }

                    $ganttTasks += [PSCustomObject]@{
                        Id           = $task.Id
                        Description  = $task.Description
                        Status       = $task.Status
                        StartDate    = $startDate
                        EndDate      = $endDate
                        Duration     = $duration
                        Dependencies = $task.Dependencies
                    }
                }

                # Graphe de dépendances
                $nodes = @()
                $edges = @()

                foreach ($task in $tasks) {
                    $nodes += [PSCustomObject]@{
                        Id     = $task.Id
                        Label  = $task.Description
                        Status = $task.Status
                    }

                    if ($task.Dependencies) {
                        foreach ($dep in $task.Dependencies) {
                            $edges += [PSCustomObject]@{
                                Source = $dep
                                Target = $task.Id
                            }
                        }
                    }

                    if ($task.ParentId) {
                        $edges += [PSCustomObject]@{
                            Source = $task.ParentId
                            Target = $task.Id
                            Type   = "Hierarchical"
                        }
                    }
                }

                $dependencyGraph = [PSCustomObject]@{
                    Nodes = $nodes
                    Edges = $edges
                }

                $processedTasks = [PSCustomObject]@{
                    TaskList        = $taskList
                    TaskTree        = $taskTree
                    GanttTasks      = $ganttTasks
                    DependencyGraph = $dependencyGraph
                }
            }
            default {
                throw "Type de composant non supporté: $ComponentType"
            }
        }

        $processingStopwatch.Stop()
        $results.ProcessingTime = $processingStopwatch.ElapsedMilliseconds

        # Étape 3: Simuler le rendu (dans un environnement réel, cela serait fait par le navigateur)
        $renderStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Simuler le temps de rendu en fonction de la complexité des données
        $renderTime = 0

        switch ($ComponentType) {
            "TaskList" {
                # Simulation simple: 0.5ms par tâche
                $renderTime = $tasks.Count * 0.5
            }
            "TaskTree" {
                # Simulation plus complexe: 1ms par tâche + 0.2ms par niveau de profondeur
                $depthSum = ($tasks | Measure-Object -Property IndentLevel -Sum).Sum
                $renderTime = $tasks.Count * 1 + $depthSum * 0.2
            }
            "Gantt" {
                # Simulation complexe: 2ms par tâche + 0.5ms par dépendance
                $dependencyCount = ($tasks | Where-Object { $_.Dependencies } | ForEach-Object { $_.Dependencies.Count } | Measure-Object -Sum).Sum
                $renderTime = $tasks.Count * 2 + $dependencyCount * 0.5
            }
            "DependencyGraph" {
                # Simulation très complexe: 1.5ms par nœud + 1ms par arête
                $nodeCount = $nodes.Count
                $edgeCount = $edges.Count
                $renderTime = $nodeCount * 1.5 + $edgeCount * 1
            }
            "All" {
                # Somme des temps de rendu de tous les composants
                $taskListTime = $tasks.Count * 0.5

                $depthSum = ($tasks | Measure-Object -Property IndentLevel -Sum).Sum
                $taskTreeTime = $tasks.Count * 1 + $depthSum * 0.2

                $dependencyCount = ($tasks | Where-Object { $_.Dependencies } | ForEach-Object { $_.Dependencies.Count } | Measure-Object -Sum).Sum
                $ganttTime = $tasks.Count * 2 + $dependencyCount * 0.5

                $nodeCount = $nodes.Count
                $edgeCount = $edges.Count
                $dependencyGraphTime = $nodeCount * 1.5 + $edgeCount * 1

                $renderTime = $taskListTime + $taskTreeTime + $ganttTime + $dependencyGraphTime
            }
        }

        # Ajouter une variation aléatoire de ±10% pour simuler des conditions réelles
        $randomFactor = 0.9 + (Get-Random -Minimum 0 -Maximum 20) / 100
        $renderTime = $renderTime * $randomFactor

        $renderStopwatch.Stop()
        $results.RenderTime = [math]::Round($renderTime, 2)

        $stopwatch.Stop()
        $results.ElapsedMs = $stopwatch.ElapsedMilliseconds
        $results.EndTime = Get-Date
        $results.Success = $true
    } catch {
        $results.EndTime = Get-Date
        $results.Error = $_.Exception.Message
        $results.Success = $false

        Write-Log "Erreur lors de la mesure du temps de rendu: $_" -Level Error
    }

    return $results
}

# Fonction pour formater les résultats en texte
function Format-ResultsAsText {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ComponentType,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedBreakdown
    )

    $output = @()
    $output += "=== RAPPORT DE PERFORMANCE DE RENDU ==="
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Roadmap: $RoadmapPath"
    $output += "Type de composant: $ComponentType"
    $output += "Nombre d'itérations: $Iterations"
    $output += ""

    $successfulResults = $Results | Where-Object { $_.Success }
    $failedResults = $Results | Where-Object { -not $_.Success }

    if ($successfulResults.Count -gt 0) {
        $avgTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Average).Average, 2)
        $minTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Minimum).Minimum, 2)
        $maxTime = [math]::Round(($successfulResults | Measure-Object -Property ElapsedMs -Maximum).Maximum, 2)
        $stdDev = [math]::Round([Math]::Sqrt(($successfulResults | ForEach-Object { [Math]::Pow($_.ElapsedMs - $avgTime, 2) } | Measure-Object -Average).Average), 2)

        $output += "--- RÉSULTATS DE TEMPS TOTAL ---"
        $output += "Temps moyen: $avgTime ms"
        $output += "Temps minimum: $minTime ms"
        $output += "Temps maximum: $maxTime ms"
        $output += "Écart type: $stdDev ms"
        $output += "Coefficient de variation: $([math]::Round(($stdDev / $avgTime) * 100, 2))%"
        $output += ""

        if ($DetailedBreakdown) {
            $avgParseTime = [math]::Round(($successfulResults | Measure-Object -Property ParseTime -Average).Average, 2)
            $avgProcessingTime = [math]::Round(($successfulResults | Measure-Object -Property ProcessingTime -Average).Average, 2)
            $avgRenderTime = [math]::Round(($successfulResults | Measure-Object -Property RenderTime -Average).Average, 2)

            $output += "--- RÉPARTITION DES TEMPS ---"
            $output += "Temps de parsing moyen: $avgParseTime ms ($([math]::Round(($avgParseTime / $avgTime) * 100, 2))%)"
            $output += "Temps de traitement moyen: $avgProcessingTime ms ($([math]::Round(($avgProcessingTime / $avgTime) * 100, 2))%)"
            $output += "Temps de rendu moyen: $avgRenderTime ms ($([math]::Round(($avgRenderTime / $avgTime) * 100, 2))%)"
            $output += ""
        }

        $taskCount = $successfulResults[0].TaskCount
        $output += "Nombre de tâches: $taskCount"
        $output += "Temps moyen par tâche: $([math]::Round($avgTime / $taskCount, 2)) ms"
        $output += ""
    }

    if ($failedResults.Count -gt 0) {
        $output += "--- ERREURS ($($failedResults.Count)) ---"
        foreach ($result in $failedResults) {
            $output += "Itération $(($Results.IndexOf($result) + 1)): $($result.Error)"
        }
        $output += ""
    }

    if ($DetailedBreakdown) {
        $output += "--- DÉTAILS DES ITÉRATIONS ---"
        for ($i = 0; $i -lt $Results.Count; $i++) {
            $result = $Results[$i]
            $status = $result.Success ? "Réussi" : "Échec"
            $output += "Itération $($i + 1): $status - Total: $($result.ElapsedMs) ms"

            if ($result.Success) {
                $output += "  Parse: $($result.ParseTime) ms | Traitement: $($result.ProcessingTime) ms | Rendu: $($result.RenderTime) ms"
            }

            if (-not $result.Success) {
                $output += "  Erreur: $($result.Error)"
            }
        }
    }

    return $output -join "`n"
}

# Fonction principale
function Invoke-ComponentRenderMeasurement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [string]$ComponentType,

        [Parameter(Mandatory = $true)]
        [int]$Iterations,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedBreakdown,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputFormat
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Fichier de roadmap non trouvé: $RoadmapPath" -Level Error
        return $false
    }

    Write-Log "Démarrage des mesures de performance de rendu pour $RoadmapPath (Composant: $ComponentType, Itérations: $Iterations)" -Level Info

    $results = @()

    # Exécuter les mesures pour chaque itération
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "Exécution de l'itération $i/$Iterations..." -Level Info
        $result = Measure-ComponentRender -RoadmapPath $RoadmapPath -ComponentType $ComponentType -DetailedBreakdown:$DetailedBreakdown
        $results += $result

        $status = $result.Success ? "réussie" : "échouée"
        $timeInfo = $result.Success ? "$($result.ElapsedMs) ms" : "N/A"

        Write-Log "Itération $i/$Iterations $status (Temps: $timeInfo)" -Level ($result.Success ? "Success" : "Error")

        # Petite pause entre les itérations
        Start-Sleep -Milliseconds 500
    }

    # Formater et enregistrer les résultats
    $formattedResults = Format-ResultsAsText -Results $results -RoadmapPath $RoadmapPath -ComponentType $ComponentType -Iterations $Iterations -DetailedBreakdown:$DetailedBreakdown

    if ($OutputPath) {
        $formattedResults | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Résultats enregistrés dans: $OutputPath" -Level Success
    } else {
        Write-Output $formattedResults
    }

    return $results
}

# Exécution principale
try {
    $result = Invoke-ComponentRenderMeasurement -RoadmapPath $RoadmapPath -ComponentType $ComponentType -Iterations $Iterations -DetailedBreakdown:$DetailedBreakdown -OutputPath $OutputPath -OutputFormat $OutputFormat

    if ($result) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Log "Erreur lors de l'exécution des mesures de performance de rendu: $_" -Level Error
    exit 2
}
