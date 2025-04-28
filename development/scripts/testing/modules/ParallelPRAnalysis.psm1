#Requires -Version 5.1
<#
.SYNOPSIS
    Module de parallÃ©lisation pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalitÃ©s pour parallÃ©liser l'analyse des pull requests
    et amÃ©liorer les performances du systÃ¨me.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Variables globales
$script:DefaultMaxThreads = [System.Environment]::ProcessorCount
$script:DefaultThrottleLimit = 0 # 0 = utiliser MaxThreads

# Classe pour gÃ©rer la parallÃ©lisation de l'analyse des pull requests
class ParallelAnalysisManager {
    # PropriÃ©tÃ©s
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

        # CrÃ©er le pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        
        # Ajouter les modules nÃ©cessaires
        $modulesToImport = @(
            "PRAnalysisCache"
        )
        
        foreach ($moduleName in $modulesToImport) {
            $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "$moduleName.psm1"
            if (Test-Path -Path $modulePath) {
                $sessionState.ImportPSModule($modulePath)
            }
        }
        
        # CrÃ©er et ouvrir le pool de runspaces
        $this.RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $this.MaxThreads, $sessionState, $Host)
        $this.RunspacePool.ApartmentState = [System.Threading.ApartmentState]::MTA
        $this.RunspacePool.Open()
        
        $this.IsInitialized = $true
        Write-Verbose "Gestionnaire d'analyse parallÃ¨le initialisÃ© avec $($this.MaxThreads) threads maximum."
    }

    # Ajouter une tÃ¢che
    [void] AddJob([scriptblock]$scriptBlock, [object]$inputObject, [hashtable]$parameters) {
        if (-not $this.IsInitialized) {
            $this.Initialize()
        }

        # CrÃ©er une instance PowerShell
        $powershell = [System.Management.Automation.PowerShell]::Create()
        $powershell.RunspacePool = $this.RunspacePool
        
        # Ajouter le script et les paramÃ¨tres
        $powershell.AddScript($scriptBlock).AddArgument($inputObject).AddArgument($this.SharedState)
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        if ($null -ne $parameters) {
            foreach ($key in $parameters.Keys) {
                $powershell.AddArgument($parameters[$key])
            }
        }
        
        # DÃ©marrer la tÃ¢che de maniÃ¨re asynchrone
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
        
        Write-Verbose "TÃ¢che ajoutÃ©e. Total: $($this.SharedState.Progress.Total), En cours: $($this.SharedState.Progress.InProgress)"
    }

    # Attendre la fin de toutes les tÃ¢ches
    [array] WaitForAll([int]$timeoutSeconds = 0) {
        if ($this.Jobs.Count -eq 0) {
            Write-Warning "Aucune tÃ¢che Ã  attendre."
            return @()
        }

        $startTime = Get-Date
        $timeout = if ($timeoutSeconds -gt 0) { $startTime.AddSeconds($timeoutSeconds) } else { [datetime]::MaxValue }
        
        Write-Verbose "Attente de la fin de $($this.Jobs.Count) tÃ¢ches..."
        
        # Attendre que toutes les tÃ¢ches soient terminÃ©es ou que le timeout soit atteint
        while ($this.Jobs.Where({ -not $_.IsCompleted }).Count -gt 0 -and (Get-Date) -lt $timeout) {
            # VÃ©rifier les tÃ¢ches terminÃ©es
            foreach ($job in $this.Jobs.Where({ -not $_.IsCompleted })) {
                if ($job.AsyncResult.IsCompleted) {
                    try {
                        # RÃ©cupÃ©rer le rÃ©sultat
                        $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                        
                        # Mettre Ã  jour l'Ã©tat
                        $job.EndTime = Get-Date
                        $job.Duration = $job.EndTime - $job.StartTime
                        $job.IsCompleted = $true
                        
                        $this.SharedState.Progress.Completed++
                        $this.SharedState.Progress.InProgress--
                        
                        Write-Verbose "TÃ¢che terminÃ©e. ComplÃ©tÃ©es: $($this.SharedState.Progress.Completed), En cours: $($this.SharedState.Progress.InProgress)"
                    } catch {
                        # GÃ©rer les erreurs
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
                        
                        Write-Verbose "TÃ¢che Ã©chouÃ©e. Ã‰checs: $($this.SharedState.Progress.Failed), En cours: $($this.SharedState.Progress.InProgress)"
                    } finally {
                        # Nettoyer les ressources
                        $job.PowerShell.Dispose()
                    }
                }
            }
            
            # Attendre un peu pour Ã©viter de surcharger le CPU
            Start-Sleep -Milliseconds 100
            
            # Afficher la progression
            $progress = [int](($this.SharedState.Progress.Completed + $this.SharedState.Progress.Failed) / $this.SharedState.Progress.Total * 100)
            Write-Progress -Activity "Analyse parallÃ¨le" -Status "Progression: $progress%" -PercentComplete $progress
        }
        
        Write-Progress -Activity "Analyse parallÃ¨le" -Completed
        
        # VÃ©rifier si le timeout a Ã©tÃ© atteint
        if ((Get-Date) -ge $timeout -and $this.Jobs.Where({ -not $_.IsCompleted }).Count -gt 0) {
            Write-Warning "Timeout atteint. $($this.Jobs.Where({ -not $_.IsCompleted }).Count) tÃ¢ches n'ont pas Ã©tÃ© terminÃ©es."
        }
        
        # Retourner les rÃ©sultats
        return $this.SharedState.Results.ToArray()
    }

    # Nettoyer les ressources
    [void] Dispose() {
        # ArrÃªter toutes les tÃ¢ches en cours
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
        Write-Verbose "Gestionnaire d'analyse parallÃ¨le nettoyÃ©."
    }
}

# Fonction pour crÃ©er un nouveau gestionnaire d'analyse parallÃ¨le
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
        Write-Error "Erreur lors de la crÃ©ation du gestionnaire d'analyse parallÃ¨le: $_"
        return $null
    }
}

# Fonction pour exÃ©cuter une analyse parallÃ¨le
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
        # CrÃ©er le gestionnaire d'analyse parallÃ¨le
        $manager = New-ParallelAnalysisManager -MaxThreads $MaxThreads -ThrottleLimit $ThrottleLimit
        if ($null -eq $manager) {
            throw "Impossible de crÃ©er le gestionnaire d'analyse parallÃ¨le."
        }
        
        # Initialiser le gestionnaire
        $manager.Initialize()
        
        # Collecter les objets d'entrÃ©e
        $inputObjectList = [System.Collections.Generic.List[object]]::new()
    }

    process {
        # Ajouter les objets d'entrÃ©e Ã  la liste
        foreach ($inputObject in $InputObjects) {
            $inputObjectList.Add($inputObject)
        }
    }

    end {
        try {
            # Ajouter les tÃ¢ches
            foreach ($inputObject in $inputObjectList) {
                $manager.AddJob($ScriptBlock, $inputObject, $Parameters)
            }
            
            # Attendre la fin de toutes les tÃ¢ches
            $results = $manager.WaitForAll($TimeoutSeconds)
            
            # Afficher un rÃ©sumÃ©
            Write-Verbose "Analyse parallÃ¨le terminÃ©e."
            Write-Verbose "  Total: $($manager.SharedState.Progress.Total)"
            Write-Verbose "  RÃ©ussies: $($manager.SharedState.Progress.Completed)"
            Write-Verbose "  Ã‰chouÃ©es: $($manager.SharedState.Progress.Failed)"
            
            # Retourner les rÃ©sultats
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
        # DÃ©terminer le nombre de chunks
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
        
        Write-Verbose "Division de $itemCount Ã©lÃ©ments en $effectiveChunkCount chunks."
        
        # Calculer le poids de chaque Ã©lÃ©ment
        $weightedItems = $Items | ForEach-Object {
            [PSCustomObject]@{
                Item = $_
                Weight = & $WeightFunction $_
            }
        }
        
        # Trier les Ã©lÃ©ments par poids dÃ©croissant
        $sortedItems = $weightedItems | Sort-Object -Property Weight -Descending
        
        # CrÃ©er les chunks
        $chunks = [System.Collections.Generic.List[object][]]::new($effectiveChunkCount)
        $chunkWeights = [System.Collections.Generic.List[double]]::new($effectiveChunkCount)
        
        for ($i = 0; $i -lt $effectiveChunkCount; $i++) {
            $chunks.Add([System.Collections.Generic.List[object]]::new())
            $chunkWeights.Add(0)
        }
        
        # Distribuer les Ã©lÃ©ments dans les chunks
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
            
            # Ajouter l'Ã©lÃ©ment au chunk
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

# Fonction pour fusionner les rÃ©sultats
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
        # Si aucun regroupement n'est spÃ©cifiÃ©, fusionner tous les rÃ©sultats
        if ([string]::IsNullOrWhiteSpace($GroupBy)) {
            return & $MergeFunction $Results
        }
        
        # Regrouper les rÃ©sultats
        $groups = $Results | Group-Object -Property $GroupBy
        
        # Fusionner chaque groupe
        $mergedResults = foreach ($group in $groups) {
            & $MergeFunction $group.Group
        }
        
        return $mergedResults
    } catch {
        Write-Error "Erreur lors de la fusion des rÃ©sultats: $_"
        return $Results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ParallelAnalysisManager, Invoke-ParallelAnalysis, Split-AnalysisWorkload, Merge-ParallelResults
