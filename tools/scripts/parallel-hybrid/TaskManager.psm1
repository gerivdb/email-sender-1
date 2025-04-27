#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des tÃ¢ches parallÃ¨les pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce module fournit des fonctions pour gÃ©rer l'exÃ©cution parallÃ¨le des tÃ¢ches
    dans l'architecture hybride PowerShell-Python.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>

<#
.SYNOPSIS
    Initialise un gestionnaire de tÃ¢ches pour l'exÃ©cution parallÃ¨le.
.DESCRIPTION
    CrÃ©e et configure un gestionnaire de tÃ¢ches pour l'exÃ©cution parallÃ¨le des tÃ¢ches.
.PARAMETER MaxConcurrency
    Nombre maximum de tÃ¢ches concurrentes. Par dÃ©faut: nombre de processeurs.
.PARAMETER ThrottleLimit
    Limite de rÃ©gulation pour les runspaces. Par dÃ©faut: MaxConcurrency + 2.
.PARAMETER PriorityQueue
    Si spÃ©cifiÃ©, utilise une file d'attente avec prioritÃ© pour les tÃ¢ches.
.EXAMPLE
    $taskManager = Initialize-TaskManager -MaxConcurrency 4
.OUTPUTS
    Un objet reprÃ©sentant le gestionnaire de tÃ¢ches.
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

    # DÃ©terminer le nombre optimal de tÃ¢ches concurrentes
    if ($MaxConcurrency -le 0) {
        $MaxConcurrency = [Environment]::ProcessorCount
    }

    # DÃ©terminer la limite de rÃ©gulation
    if ($ThrottleLimit -le 0) {
        $ThrottleLimit = $MaxConcurrency + 2
    }

    # CrÃ©er le pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
    $runspacePool.Open()

    # CrÃ©er la file d'attente des tÃ¢ches
    $taskQueue = if ($PriorityQueue) {
        # File d'attente avec prioritÃ©
        New-Object System.Collections.Generic.List[PSObject]
    }
    else {
        # File d'attente standard
        New-Object System.Collections.Generic.Queue[PSObject]
    }

    # CrÃ©er et retourner le gestionnaire de tÃ¢ches
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
    Ajoute une tÃ¢che Ã  la file d'attente du gestionnaire de tÃ¢ches.
.DESCRIPTION
    Ajoute une tÃ¢che Ã  la file d'attente pour exÃ©cution parallÃ¨le.
.PARAMETER TaskManager
    Gestionnaire de tÃ¢ches initialisÃ© par Initialize-TaskManager.
.PARAMETER ScriptBlock
    Bloc de script Ã  exÃ©cuter.
.PARAMETER Parameters
    ParamÃ¨tres Ã  passer au bloc de script.
.PARAMETER Priority
    PrioritÃ© de la tÃ¢che (1-10, 10 Ã©tant la plus haute). Par dÃ©faut: 5.
.EXAMPLE
    $scriptBlock = { param($data) Process-Data $data }
    Add-TaskToQueue -TaskManager $taskManager -ScriptBlock $scriptBlock -Parameters @{ data = $myData }
.OUTPUTS
    Un objet reprÃ©sentant la tÃ¢che ajoutÃ©e.
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

    # CrÃ©er l'objet tÃ¢che
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

    # Ajouter la tÃ¢che Ã  la file d'attente
    if ($TaskManager.TaskQueue -is [System.Collections.Generic.List[PSObject]]) {
        # File d'attente avec prioritÃ©
        $TaskManager.TaskQueue.Add($task)
        $TaskManager.TaskQueue.Sort({ param($a, $b) $b.Priority - $a.Priority })
    }
    else {
        # File d'attente standard
        $TaskManager.TaskQueue.Enqueue($task)
    }

    # Mettre Ã  jour les statistiques
    $TaskManager.Statistics.TotalTasks++

    return $task
}

<#
.SYNOPSIS
    ExÃ©cute les tÃ¢ches en parallÃ¨le.
.DESCRIPTION
    ExÃ©cute les tÃ¢ches de la file d'attente en parallÃ¨le et attend leur complÃ©tion.
.PARAMETER TaskManager
    Gestionnaire de tÃ¢ches initialisÃ© par Initialize-TaskManager.
.PARAMETER WaitForCompletion
    Si spÃ©cifiÃ©, attend la complÃ©tion de toutes les tÃ¢ches. Par dÃ©faut: $true.
.PARAMETER TimeoutSeconds
    DÃ©lai d'attente en secondes. Par dÃ©faut: 0 (pas de dÃ©lai).
.EXAMPLE
    Start-ParallelTasks -TaskManager $taskManager
.OUTPUTS
    Les rÃ©sultats des tÃ¢ches exÃ©cutÃ©es.
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

    # DÃ©marrer le chronomÃ¨tre
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # ExÃ©cuter les tÃ¢ches en parallÃ¨le
    while ($TaskManager.TaskQueue.Count -gt 0 -or $TaskManager.ActiveTasks.Count -gt 0) {
        # VÃ©rifier le dÃ©lai d'attente
        if ($TimeoutSeconds -gt 0 -and $stopwatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
            Write-Warning "DÃ©lai d'attente dÃ©passÃ©. ArrÃªt des tÃ¢ches en cours..."
            break
        }

        # DÃ©marrer de nouvelles tÃ¢ches si possible
        while ($TaskManager.TaskQueue.Count -gt 0 -and $TaskManager.ActiveTasks.Count -lt $TaskManager.MaxConcurrency) {
            # RÃ©cupÃ©rer la prochaine tÃ¢che
            $task = if ($TaskManager.TaskQueue -is [System.Collections.Generic.List[PSObject]]) {
                # File d'attente avec prioritÃ©
                $nextTask = $TaskManager.TaskQueue[0]
                $TaskManager.TaskQueue.RemoveAt(0)
                $nextTask
            }
            else {
                # File d'attente standard
                $TaskManager.TaskQueue.Dequeue()
            }

            # CrÃ©er et configurer le PowerShell
            $ps = [powershell]::Create().AddScript($task.ScriptBlock)
            foreach ($param in $task.Parameters.GetEnumerator()) {
                $ps.AddParameter($param.Key, $param.Value) | Out-Null
            }
            $ps.RunspacePool = $TaskManager.RunspacePool

            # DÃ©marrer la tÃ¢che de maniÃ¨re asynchrone
            $task.PowerShell = $ps
            $task.AsyncResult = $ps.BeginInvoke()
            $task.Status = "Running"
            $task.StartTime = Get-Date

            # Ajouter la tÃ¢che aux tÃ¢ches actives
            $TaskManager.ActiveTasks.Add($task)
        }

        # VÃ©rifier les tÃ¢ches terminÃ©es
        for ($i = $TaskManager.ActiveTasks.Count - 1; $i -ge 0; $i--) {
            $task = $TaskManager.ActiveTasks[$i]

            if ($task.AsyncResult.IsCompleted) {
                # RÃ©cupÃ©rer le rÃ©sultat
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

                    # Supprimer la tÃ¢che des tÃ¢ches actives
                    $TaskManager.ActiveTasks.RemoveAt($i)
                }
            }
        }

        # Attendre un peu avant de vÃ©rifier Ã  nouveau
        if ($TaskManager.ActiveTasks.Count -gt 0) {
            Start-Sleep -Milliseconds 100
        }

        # Sortir de la boucle si on ne veut pas attendre la complÃ©tion
        if (-not $WaitForCompletion -and $TaskManager.TaskQueue.Count -eq 0) {
            break
        }
    }

    # ArrÃªter le chronomÃ¨tre
    $stopwatch.Stop()

    # Mettre Ã  jour les statistiques
    $TaskManager.Statistics.EndTime = Get-Date
    $TaskManager.Statistics.Duration = $TaskManager.Statistics.EndTime - $TaskManager.Statistics.StartTime

    # Retourner les rÃ©sultats
    return $TaskManager.CompletedTasks | ForEach-Object { $_.Result }
}

<#
.SYNOPSIS
    ExÃ©cute des tÃ¢ches parallÃ¨les en utilisant le gestionnaire de tÃ¢ches.
.DESCRIPTION
    Fonction de haut niveau qui combine l'initialisation du gestionnaire de tÃ¢ches,
    l'ajout des tÃ¢ches Ã  la file d'attente et leur exÃ©cution parallÃ¨le.
.PARAMETER TaskManager
    Gestionnaire de tÃ¢ches initialisÃ© par Initialize-TaskManager. Si non spÃ©cifiÃ©,
    un nouveau gestionnaire est crÃ©Ã©.
.PARAMETER Tasks
    Tableau de tÃ¢ches Ã  exÃ©cuter. Chaque tÃ¢che doit Ãªtre un hashtable avec les clÃ©s
    PythonScript, InputData, et Ã©ventuellement CachePath et AdditionalArguments.
.PARAMETER MaxConcurrency
    Nombre maximum de tÃ¢ches concurrentes. Par dÃ©faut: nombre de processeurs.
.PARAMETER TimeoutSeconds
    DÃ©lai d'attente en secondes. Par dÃ©faut: 0 (pas de dÃ©lai).
.EXAMPLE
    $tasks = @(
        @{ PythonScript = "script1.py"; InputData = $data1 },
        @{ PythonScript = "script2.py"; InputData = $data2 }
    )
    $results = Invoke-ParallelTasks -Tasks $tasks
.OUTPUTS
    Les rÃ©sultats des tÃ¢ches exÃ©cutÃ©es.
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

    # Initialiser le gestionnaire de tÃ¢ches si nÃ©cessaire
    if (-not $TaskManager) {
        $TaskManager = Initialize-TaskManager -MaxConcurrency $MaxConcurrency
    }

    # Ajouter les tÃ¢ches Ã  la file d'attente
    foreach ($task in $Tasks) {
        $scriptBlock = {
            param(
                [string]$PythonScript,
                [array]$InputData,
                [string]$CachePath,
                [hashtable]$AdditionalArguments
            )

            # PrÃ©parer les arguments pour le script Python
            $inputJson = ConvertTo-Json -InputObject $InputData -Depth 10 -Compress
            $inputFile = [System.IO.Path]::GetTempFileName()
            $outputFile = [System.IO.Path]::GetTempFileName()

            try {
                # Ã‰crire les donnÃ©es d'entrÃ©e dans un fichier temporaire
                $inputJson | Out-File -FilePath $inputFile -Encoding utf8

                # PrÃ©parer les arguments pour le script Python
                $pythonArgs = @(
                    $PythonScript,
                    "--input", $inputFile,
                    "--output", $outputFile
                )

                if ($CachePath) {
                    $pythonArgs += @("--cache", $CachePath)
                }

                # Ajouter les arguments supplÃ©mentaires
                foreach ($arg in $AdditionalArguments.GetEnumerator()) {
                    $pythonArgs += @("--$($arg.Key)", $arg.Value)
                }

                # ExÃ©cuter le script Python
                $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -NoNewWindow -PassThru -Wait

                # VÃ©rifier le code de sortie
                if ($process.ExitCode -ne 0) {
                    throw "Le script Python a Ã©chouÃ© avec le code de sortie $($process.ExitCode)"
                }

                # Lire les rÃ©sultats
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

    # ExÃ©cuter les tÃ¢ches en parallÃ¨le
    $results = Start-ParallelTasks -TaskManager $TaskManager -TimeoutSeconds $TimeoutSeconds

    return $results
}

<#
.SYNOPSIS
    Nettoie les ressources du gestionnaire de tÃ¢ches.
.DESCRIPTION
    LibÃ¨re les ressources utilisÃ©es par le gestionnaire de tÃ¢ches.
.PARAMETER TaskManager
    Gestionnaire de tÃ¢ches Ã  nettoyer.
.EXAMPLE
    Clear-TaskManager -TaskManager $taskManager
#>
function Clear-TaskManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TaskManager
    )

    # ArrÃªter les tÃ¢ches en cours
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
