#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des tâches parallèles pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce module fournit des fonctions pour gérer l'exécution parallèle des tâches
    dans l'architecture hybride PowerShell-Python.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur
#>

<#
.SYNOPSIS
    Initialise un gestionnaire de tâches pour l'exécution parallèle.
.DESCRIPTION
    Crée et configure un gestionnaire de tâches pour l'exécution parallèle des tâches.
.PARAMETER MaxConcurrency
    Nombre maximum de tâches concurrentes. Par défaut: nombre de processeurs.
.PARAMETER ThrottleLimit
    Limite de régulation pour les runspaces. Par défaut: MaxConcurrency + 2.
.PARAMETER PriorityQueue
    Si spécifié, utilise une file d'attente avec priorité pour les tâches.
.EXAMPLE
    $taskManager = Initialize-TaskManager -MaxConcurrency 4
.OUTPUTS
    Un objet représentant le gestionnaire de tâches.
#>
function Initialize-TaskManager {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrency = 0,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 0,

        [Parameter(Mandatory = $false)]
        [switch]$PriorityQueue
    )

    # Déterminer le nombre optimal de tâches concurrentes
    if ($MaxConcurrency -le 0) {
        $MaxConcurrency = [Environment]::ProcessorCount
    }

    # Déterminer la limite de régulation
    if ($ThrottleLimit -le 0) {
        $ThrottleLimit = $MaxConcurrency + 2
    }

    # Créer le pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
    $runspacePool.Open()

    # Créer la file d'attente des tâches
    $taskQueue = if ($PriorityQueue) {
        # File d'attente avec priorité
        New-Object System.Collections.Generic.List[PSObject]
    }
    else {
        # File d'attente standard
        New-Object System.Collections.Generic.Queue[PSObject]
    }

    # Créer et retourner le gestionnaire de tâches
    return [PSCustomObject]@{
        MaxConcurrency = $MaxConcurrency
        ThrottleLimit = $ThrottleLimit
        RunspacePool = $runspacePool
        TaskQueue = $taskQueue
        ActiveTasks = New-Object System.Collections.Generic.List[PSObject]
        CompletedTasks = New-Object System.Collections.Generic.List[PSObject]
        FailedTasks = New-Object System.Collections.Generic.List[PSObject]
        Statistics = @{
            TotalTasks = 0
            CompletedTasks = 0
            FailedTasks = 0
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
        }
    }
}

<#
.SYNOPSIS
    Ajoute une tâche à la file d'attente du gestionnaire de tâches.
.DESCRIPTION
    Ajoute une tâche à la file d'attente pour exécution parallèle.
.PARAMETER TaskManager
    Gestionnaire de tâches initialisé par Initialize-TaskManager.
.PARAMETER ScriptBlock
    Bloc de script à exécuter.
.PARAMETER Parameters
    Paramètres à passer au bloc de script.
.PARAMETER Priority
    Priorité de la tâche (1-10, 10 étant la plus haute). Par défaut: 5.
.EXAMPLE
    $scriptBlock = { param($data) Process-Data $data }
    Add-TaskToQueue -TaskManager $taskManager -ScriptBlock $scriptBlock -Parameters @{ data = $myData }
.OUTPUTS
    Un objet représentant la tâche ajoutée.
#>
function Add-TaskToQueue {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TaskManager,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Priority = 5
    )

    # Créer l'objet tâche
    $task = [PSCustomObject]@{
        Id = [guid]::NewGuid().ToString()
        ScriptBlock = $ScriptBlock
        Parameters = $Parameters
        Priority = $Priority
        Status = "Queued"
        StartTime = $null
        EndTime = $null
        Duration = $null
        Result = $null
        Error = $null
        PowerShell = $null
        AsyncResult = $null
    }

    # Ajouter la tâche à la file d'attente
    if ($TaskManager.TaskQueue -is [System.Collections.Generic.List[PSObject]]) {
        # File d'attente avec priorité
        $TaskManager.TaskQueue.Add($task)
        $TaskManager.TaskQueue.Sort({ param($a, $b) $b.Priority - $a.Priority })
    }
    else {
        # File d'attente standard
        $TaskManager.TaskQueue.Enqueue($task)
    }

    # Mettre à jour les statistiques
    $TaskManager.Statistics.TotalTasks++

    return $task
}

<#
.SYNOPSIS
    Exécute les tâches en parallèle.
.DESCRIPTION
    Exécute les tâches de la file d'attente en parallèle et attend leur complétion.
.PARAMETER TaskManager
    Gestionnaire de tâches initialisé par Initialize-TaskManager.
.PARAMETER WaitForCompletion
    Si spécifié, attend la complétion de toutes les tâches. Par défaut: $true.
.PARAMETER TimeoutSeconds
    Délai d'attente en secondes. Par défaut: 0 (pas de délai).
.EXAMPLE
    Start-ParallelTasks -TaskManager $taskManager
.OUTPUTS
    Les résultats des tâches exécutées.
#>
function Start-ParallelTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TaskManager,

        [Parameter(Mandatory = $false)]
        [switch]$WaitForCompletion,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0
    )

    # Démarrer le chronomètre
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Exécuter les tâches en parallèle
    while ($TaskManager.TaskQueue.Count -gt 0 -or $TaskManager.ActiveTasks.Count -gt 0) {
        # Vérifier le délai d'attente
        if ($TimeoutSeconds -gt 0 -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
            Write-Warning "Délai d'attente dépassé. Arrêt des tâches en cours..."
            break
        }

        # Démarrer de nouvelles tâches si possible
        while ($TaskManager.TaskQueue.Count -gt 0 -and $TaskManager.ActiveTasks.Count -lt $TaskManager.MaxConcurrency) {
            # Récupérer la prochaine tâche
            $task = if ($TaskManager.TaskQueue -is [System.Collections.Generic.List[PSObject]]) {
                # File d'attente avec priorité
                $nextTask = $TaskManager.TaskQueue[0]
                $TaskManager.TaskQueue.RemoveAt(0)
                $nextTask
            }
            else {
                # File d'attente standard
                $TaskManager.TaskQueue.Dequeue()
            }

            # Créer et configurer le PowerShell
            $ps = [powershell]::Create().AddScript($task.ScriptBlock)
            foreach ($param in $task.Parameters.GetEnumerator()) {
                $ps.AddParameter($param.Key, $param.Value) | Out-Null
            }
            $ps.RunspacePool = $TaskManager.RunspacePool

            # Démarrer la tâche de manière asynchrone
            $task.PowerShell = $ps
            $task.AsyncResult = $ps.BeginInvoke()
            $task.Status = "Running"
            $task.StartTime = Get-Date

            # Ajouter la tâche aux tâches actives
            $TaskManager.ActiveTasks.Add($task)
        }

        # Vérifier les tâches terminées
        for ($i = $TaskManager.ActiveTasks.Count - 1; $i -ge 0; $i--) {
            $task = $TaskManager.ActiveTasks[$i]

            if ($task.AsyncResult.IsCompleted) {
                # Récupérer le résultat
                try {
                    $task.Result = $task.PowerShell.EndInvoke($task.AsyncResult)
                    $task.Status = "Completed"
                    $TaskManager.CompletedTasks.Add($task)
                    $TaskManager.Statistics.CompletedTasks++
                }
                catch {
                    $task.Error = $_
                    $task.Status = "Failed"
                    $TaskManager.FailedTasks.Add($task)
                    $TaskManager.Statistics.FailedTasks++
                }
                finally {
                    # Nettoyer les ressources
                    $task.PowerShell.Dispose()
                    $task.EndTime = Get-Date
                    $task.Duration = $task.EndTime - $task.StartTime

                    # Supprimer la tâche des tâches actives
                    $TaskManager.ActiveTasks.RemoveAt($i)
                }
            }
        }

        # Attendre un peu avant de vérifier à nouveau
        if ($TaskManager.ActiveTasks.Count -gt 0) {
            Start-Sleep -Milliseconds 100
        }

        # Sortir de la boucle si on ne veut pas attendre la complétion
        if (-not $WaitForCompletion -and $TaskManager.TaskQueue.Count -eq 0) {
            break
        }
    }

    # Arrêter le chronomètre
    $stopwatch.Stop()

    # Mettre à jour les statistiques
    $TaskManager.Statistics.EndTime = Get-Date
    $TaskManager.Statistics.Duration = $TaskManager.Statistics.EndTime - $TaskManager.Statistics.StartTime

    # Retourner les résultats
    return $TaskManager.CompletedTasks | ForEach-Object { $_.Result }
}

<#
.SYNOPSIS
    Exécute des tâches parallèles en utilisant le gestionnaire de tâches.
.DESCRIPTION
    Fonction de haut niveau qui combine l'initialisation du gestionnaire de tâches,
    l'ajout des tâches à la file d'attente et leur exécution parallèle.
.PARAMETER TaskManager
    Gestionnaire de tâches initialisé par Initialize-TaskManager. Si non spécifié,
    un nouveau gestionnaire est créé.
.PARAMETER Tasks
    Tableau de tâches à exécuter. Chaque tâche doit être un hashtable avec les clés
    PythonScript, InputData, et éventuellement CachePath et AdditionalArguments.
.PARAMETER MaxConcurrency
    Nombre maximum de tâches concurrentes. Par défaut: nombre de processeurs.
.PARAMETER TimeoutSeconds
    Délai d'attente en secondes. Par défaut: 0 (pas de délai).
.EXAMPLE
    $tasks = @(
        @{ PythonScript = "script1.py"; InputData = $data1 },
        @{ PythonScript = "script2.py"; InputData = $data2 }
    )
    $results = Invoke-ParallelTasks -Tasks $tasks
.OUTPUTS
    Les résultats des tâches exécutées.
#>
function Invoke-ParallelTasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$TaskManager,

        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrency = 0,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0
    )

    # Initialiser le gestionnaire de tâches si nécessaire
    if (-not $TaskManager) {
        $TaskManager = Initialize-TaskManager -MaxConcurrency $MaxConcurrency
    }

    # Ajouter les tâches à la file d'attente
    foreach ($task in $Tasks) {
        $scriptBlock = {
            param(
                [string]$PythonScript,
                [array]$InputData,
                [string]$CachePath,
                [hashtable]$AdditionalArguments
            )

            # Préparer les arguments pour le script Python
            $inputJson = ConvertTo-Json -InputObject $InputData -Depth 10 -Compress
            $inputFile = [System.IO.Path]::GetTempFileName()
            $outputFile = [System.IO.Path]::GetTempFileName()

            try {
                # Écrire les données d'entrée dans un fichier temporaire
                $inputJson | Out-File -FilePath $inputFile -Encoding utf8

                # Préparer les arguments pour le script Python
                $pythonArgs = @(
                    $PythonScript,
                    "--input", $inputFile,
                    "--output", $outputFile
                )

                if ($CachePath) {
                    $pythonArgs += @("--cache", $CachePath)
                }

                # Ajouter les arguments supplémentaires
                foreach ($arg in $AdditionalArguments.GetEnumerator()) {
                    $pythonArgs += @("--$($arg.Key)", $arg.Value)
                }

                # Exécuter le script Python
                $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait

                # Vérifier le code de sortie
                if ($process.ExitCode -ne 0) {
                    throw "Le script Python a échoué avec le code de sortie $($process.ExitCode)"
                }

                # Lire les résultats
                $outputJson = Get-Content -Path $outputFile -Raw
                $result = ConvertFrom-Json -InputObject $outputJson

                return $result
            }
            finally {
                # Nettoyer les fichiers temporaires
                if (Test-Path -Path $inputFile) {
                    Remove-Item -Path $inputFile -Force
                }
                if (Test-Path -Path $outputFile) {
                    Remove-Item -Path $outputFile -Force
                }
            }
        }

        Add-TaskToQueue -TaskManager $TaskManager -ScriptBlock $scriptBlock -Parameters $task
    }

    # Exécuter les tâches en parallèle
    $results = Start-ParallelTasks -TaskManager $TaskManager -TimeoutSeconds $TimeoutSeconds

    return $results
}

<#
.SYNOPSIS
    Nettoie les ressources du gestionnaire de tâches.
.DESCRIPTION
    Libère les ressources utilisées par le gestionnaire de tâches.
.PARAMETER TaskManager
    Gestionnaire de tâches à nettoyer.
.EXAMPLE
    Clear-TaskManager -TaskManager $taskManager
#>
function Clear-TaskManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TaskManager
    )

    # Arrêter les tâches en cours
    foreach ($task in $TaskManager.ActiveTasks) {
        if ($task.PowerShell -and -not $task.AsyncResult.IsCompleted) {
            $task.PowerShell.Stop()
            $task.PowerShell.Dispose()
        }
    }

    # Fermer le pool de runspaces
    if ($TaskManager.RunspacePool) {
        $TaskManager.RunspacePool.Close()
        $TaskManager.RunspacePool.Dispose()
    }

    # Vider les listes
    $TaskManager.ActiveTasks.Clear()
    $TaskManager.CompletedTasks.Clear()
    $TaskManager.FailedTasks.Clear()

    # Vider la file d'attente
    if ($TaskManager.TaskQueue -is [System.Collections.Generic.List[PSObject]]) {
        $TaskManager.TaskQueue.Clear()
    }
    else {
        while ($TaskManager.TaskQueue.Count -gt 0) {
            $TaskManager.TaskQueue.Dequeue() | Out-Null
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-TaskManager, Add-TaskToQueue, Start-ParallelTasks, Invoke-ParallelTasks, Clear-TaskManager
