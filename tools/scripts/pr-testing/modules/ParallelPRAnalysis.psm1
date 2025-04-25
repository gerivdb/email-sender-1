#Requires -Version 5.1
<#
.SYNOPSIS
    Module de parallélisation pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalités pour paralléliser l'analyse des pull requests
    et améliorer les performances du système.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Variables globales
$script:DefaultMaxThreads = [System.Environment]::ProcessorCount
$script:DefaultThrottleLimit = 0 # 0 = utiliser MaxThreads

# Classe pour gérer la parallélisation de l'analyse des pull requests
class ParallelAnalysisManager {
    # Propriétés
    [int]$MaxThreads
    [int]$ThrottleLimit
    [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool
    [System.Collections.Generic.List[object]]$Jobs
    [hashtable]$SharedState
    [bool]$IsInitialized

    # Constructeur
    ParallelAnalysisManager([int]$maxThreads, [int]$throttleLimit) {
        $this.MaxThreads = if ($maxThreads -gt 0) { $maxThreads } else { $script:DefaultMaxThreads }
        $this.ThrottleLimit = if ($throttleLimit -gt 0) { $throttleLimit } else { $this.MaxThreads }
        $this.Jobs = [System.Collections.Generic.List[object]]::new()
        $this.SharedState = [hashtable]::Synchronized(@{
            Results = [System.Collections.Generic.List[object]]::new()
            Errors = [System.Collections.Generic.List[object]]::new()
            Progress = @{
                Total = 0
                Completed = 0
                Failed = 0
                InProgress = 0
            }
            CancellationRequested = $false
        })
        $this.IsInitialized = $false
    }

    # Initialiser le gestionnaire
    [void] Initialize() {
        if ($this.IsInitialized) {
            return
        }

        # Créer le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # Ajouter les modules nécessaires
        $modulesToImport = @(
            "PRAnalysisCache"
        )
        
        foreach ($moduleName in $modulesToImport) {
            $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "$moduleName.psm1"
            if (Test-Path -Path $modulePath) {
                $sessionState.ImportPSModule($modulePath)
            }
        }
        
        # Créer et ouvrir le pool de runspaces
        $this.RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $this.MaxThreads, $sessionState, $Host)
        $this.RunspacePool.ApartmentState = [System.Threading.ApartmentState]::MTA
        $this.RunspacePool.Open()
        
        $this.IsInitialized = $true
        Write-Verbose "Gestionnaire d'analyse parallèle initialisé avec $($this.MaxThreads) threads maximum."
    }

    # Ajouter une tâche
    [void] AddJob([scriptblock]$scriptBlock, [object]$inputObject, [hashtable]$parameters) {
        if (-not $this.IsInitialized) {
            $this.Initialize()
        }

        # Créer une instance PowerShell
        $powershell = [System.Management.Automation.PowerShell]::Create()
        $powershell.RunspacePool = $this.RunspacePool
        
        # Ajouter le script et les paramètres
        $powershell.AddScript($scriptBlock).AddArgument($inputObject).AddArgument($this.SharedState)
        
        # Ajouter les paramètres supplémentaires
        if ($null -ne $parameters) {
            foreach ($key in $parameters.Keys) {
                $powershell.AddArgument($parameters[$key])
            }
        }
        
        # Démarrer la tâche de manière asynchrone
        $job = [PSCustomObject]@{
            PowerShell = $powershell
            AsyncResult = $powershell.BeginInvoke()
            InputObject = $inputObject
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
            IsCompleted = $false
        }
        
        $this.Jobs.Add($job)
        $this.SharedState.Progress.Total++
        $this.SharedState.Progress.InProgress++
        
        Write-Verbose "Tâche ajoutée. Total: $($this.SharedState.Progress.Total), En cours: $($this.SharedState.Progress.InProgress)"
    }

    # Attendre la fin de toutes les tâches
    [array] WaitForAll([int]$timeoutSeconds = 0) {
        if ($this.Jobs.Count -eq 0) {
            Write-Warning "Aucune tâche à attendre."
            return @()
        }

        $startTime = Get-Date
        $timeout = if ($timeoutSeconds -gt 0) { $startTime.AddSeconds($timeoutSeconds) } else { [datetime]::MaxValue }
        
        Write-Verbose "Attente de la fin de $($this.Jobs.Count) tâches..."
        
        # Attendre que toutes les tâches soient terminées ou que le timeout soit atteint
        while ($this.Jobs.Where({ -not $_.IsCompleted }).Count -gt 0 -and (Get-Date) -lt $timeout) {
            # Vérifier les tâches terminées
            foreach ($job in $this.Jobs.Where({ -not $_.IsCompleted })) {
                if ($job.AsyncResult.IsCompleted) {
                    try {
                        # Récupérer le résultat
                        $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                        
                        # Mettre à jour l'état
                        $job.EndTime = Get-Date
                        $job.Duration = $job.EndTime - $job.StartTime
                        $job.IsCompleted = $true
                        
                        $this.SharedState.Progress.Completed++
                        $this.SharedState.Progress.InProgress--
                        
                        Write-Verbose "Tâche terminée. Complétées: $($this.SharedState.Progress.Completed), En cours: $($this.SharedState.Progress.InProgress)"
                    } catch {
                        # Gérer les erreurs
                        $job.EndTime = Get-Date
                        $job.Duration = $job.EndTime - $job.StartTime
                        $job.IsCompleted = $true
                        
                        $this.SharedState.Progress.Failed++
                        $this.SharedState.Progress.InProgress--
                        
                        $errorInfo = [PSCustomObject]@{
                            InputObject = $job.InputObject
                            Error = $_
                            Time = Get-Date
                        }
                        
                        $this.SharedState.Errors.Add($errorInfo)
                        
                        Write-Verbose "Tâche échouée. Échecs: $($this.SharedState.Progress.Failed), En cours: $($this.SharedState.Progress.InProgress)"
                    } finally {
                        # Nettoyer les ressources
                        $job.PowerShell.Dispose()
                    }
                }
            }
            
            # Attendre un peu pour éviter de surcharger le CPU
            Start-Sleep -Milliseconds 100
            
            # Afficher la progression
            $progress = [int](($this.SharedState.Progress.Completed + $this.SharedState.Progress.Failed) / $this.SharedState.Progress.Total * 100)
            Write-Progress -Activity "Analyse parallèle" -Status "Progression: $progress%" -PercentComplete $progress
        }
        
        Write-Progress -Activity "Analyse parallèle" -Completed
        
        # Vérifier si le timeout a été atteint
        if ((Get-Date) -ge $timeout -and $this.Jobs.Where({ -not $_.IsCompleted }).Count -gt 0) {
            Write-Warning "Timeout atteint. $($this.Jobs.Where({ -not $_.IsCompleted }).Count) tâches n'ont pas été terminées."
        }
        
        # Retourner les résultats
        return $this.SharedState.Results.ToArray()
    }

    # Nettoyer les ressources
    [void] Dispose() {
        # Arrêter toutes les tâches en cours
        foreach ($job in $this.Jobs.Where({ -not $_.IsCompleted })) {
            try {
                $job.PowerShell.Stop()
                $job.PowerShell.Dispose()
            } catch {
                # Ignorer les erreurs lors de la fermeture
            }
        }
        
        # Fermer le pool de runspaces
        if ($null -ne $this.RunspacePool) {
            try {
                $this.RunspacePool.Close()
                $this.RunspacePool.Dispose()
            } catch {
                # Ignorer les erreurs lors de la fermeture
            }
        }
        
        $this.IsInitialized = $false
        Write-Verbose "Gestionnaire d'analyse parallèle nettoyé."
    }
}

# Fonction pour créer un nouveau gestionnaire d'analyse parallèle
function New-ParallelAnalysisManager {
    [CmdletBinding()]
    [OutputType([ParallelAnalysisManager])]
    param(
        [Parameter()]
        [int]$MaxThreads = 0,

        [Parameter()]
        [int]$ThrottleLimit = 0
    )

    try {
        $manager = [ParallelAnalysisManager]::new($MaxThreads, $ThrottleLimit)
        return $manager
    } catch {
        Write-Error "Erreur lors de la création du gestionnaire d'analyse parallèle: $_"
        return $null
    }
}

# Fonction pour exécuter une analyse parallèle
function Invoke-ParallelAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$InputObjects,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [int]$MaxThreads = 0,

        [Parameter()]
        [int]$ThrottleLimit = 0,

        [Parameter()]
        [hashtable]$Parameters = @{},

        [Parameter()]
        [int]$TimeoutSeconds = 0
    )

    begin {
        # Créer le gestionnaire d'analyse parallèle
        $manager = New-ParallelAnalysisManager -MaxThreads $MaxThreads -ThrottleLimit $ThrottleLimit
        if ($null -eq $manager) {
            throw "Impossible de créer le gestionnaire d'analyse parallèle."
        }
        
        # Initialiser le gestionnaire
        $manager.Initialize()
        
        # Collecter les objets d'entrée
        $inputObjectList = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # Ajouter les objets d'entrée à la liste
        foreach ($inputObject in $InputObjects) {
            $inputObjectList.Add($inputObject)
        }
    }

    end {
        try {
            # Ajouter les tâches
            foreach ($inputObject in $inputObjectList) {
                $manager.AddJob($ScriptBlock, $inputObject, $Parameters)
            }
            
            # Attendre la fin de toutes les tâches
            $results = $manager.WaitForAll($TimeoutSeconds)
            
            # Afficher un résumé
            Write-Verbose "Analyse parallèle terminée."
            Write-Verbose "  Total: $($manager.SharedState.Progress.Total)"
            Write-Verbose "  Réussies: $($manager.SharedState.Progress.Completed)"
            Write-Verbose "  Échouées: $($manager.SharedState.Progress.Failed)"
            
            # Retourner les résultats
            return $results
        } finally {
            # Nettoyer les ressources
            $manager.Dispose()
        }
    }
}

# Fonction pour diviser une charge de travail
function Split-AnalysisWorkload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items,

        [Parameter()]
        [int]$ChunkCount = 0,

        [Parameter()]
        [int]$ChunkSize = 0,

        [Parameter()]
        [scriptblock]$WeightFunction = { param($item) 1 }
    )

    try {
        # Déterminer le nombre de chunks
        $itemCount = $Items.Count
        $effectiveChunkCount = $ChunkCount
        
        if ($effectiveChunkCount -le 0) {
            if ($ChunkSize -gt 0) {
                $effectiveChunkCount = [Math]::Ceiling($itemCount / $ChunkSize)
            } else {
                $effectiveChunkCount = [System.Environment]::ProcessorCount
            }
        }
        
        # Limiter le nombre de chunks
        $effectiveChunkCount = [Math]::Min($effectiveChunkCount, $itemCount)
        $effectiveChunkCount = [Math]::Max($effectiveChunkCount, 1)
        
        Write-Verbose "Division de $itemCount éléments en $effectiveChunkCount chunks."
        
        # Calculer le poids de chaque élément
        $weightedItems = $Items | ForEach-Object {
            [PSCustomObject]@{
                Item = $_
                Weight = & $WeightFunction $_
            }
        }
        
        # Trier les éléments par poids décroissant
        $sortedItems = $weightedItems | Sort-Object -Property Weight -Descending
        
        # Créer les chunks
        $chunks = [System.Collections.Generic.List[object][]]::new($effectiveChunkCount)
        $chunkWeights = [System.Collections.Generic.List[double]]::new($effectiveChunkCount)
        
        for ($i = 0; $i -lt $effectiveChunkCount; $i++) {
            $chunks.Add([System.Collections.Generic.List[object]]::new())
            $chunkWeights.Add(0)
        }
        
        # Distribuer les éléments dans les chunks
        foreach ($item in $sortedItems) {
            # Trouver le chunk avec le poids le plus faible
            $minWeightIndex = 0
            $minWeight = $chunkWeights[0]
            
            for ($i = 1; $i -lt $effectiveChunkCount; $i++) {
                if ($chunkWeights[$i] -lt $minWeight) {
                    $minWeightIndex = $i
                    $minWeight = $chunkWeights[$i]
                }
            }
            
            # Ajouter l'élément au chunk
            $chunks[$minWeightIndex].Add($item.Item)
            $chunkWeights[$minWeightIndex] += $item.Weight
        }
        
        # Retourner les chunks
        return $chunks.ToArray()
    } catch {
        Write-Error "Erreur lors de la division de la charge de travail: $_"
        return @($Items)
    }
}

# Fonction pour fusionner les résultats
function Merge-ParallelResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Results,

        [Parameter()]
        [string]$GroupBy = "",

        [Parameter()]
        [scriptblock]$MergeFunction = { param($results) $results }
    )

    try {
        # Si aucun regroupement n'est spécifié, fusionner tous les résultats
        if ([string]::IsNullOrWhiteSpace($GroupBy)) {
            return & $MergeFunction $Results
        }
        
        # Regrouper les résultats
        $groups = $Results | Group-Object -Property $GroupBy
        
        # Fusionner chaque groupe
        $mergedResults = foreach ($group in $groups) {
            & $MergeFunction $group.Group
        }
        
        return $mergedResults
    } catch {
        Write-Error "Erreur lors de la fusion des résultats: $_"
        return $Results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ParallelAnalysisManager, Invoke-ParallelAnalysis, Split-AnalysisWorkload, Merge-ParallelResults
