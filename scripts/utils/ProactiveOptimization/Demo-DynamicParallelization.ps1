#Requires -Version 5.1
<#
.SYNOPSIS
    Démontre l'utilisation de l'optimisation dynamique de la parallélisation.
.DESCRIPTION
    Ce script montre comment utiliser les modules Dynamic-ThreadManager et TaskPriorityQueue
    pour optimiser dynamiquement la parallélisation des tâches.
.EXAMPLE
    .\Demo-DynamicParallelization.ps1
    Exécute la démonstration avec les paramètres par défaut.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Importer les modules nécessaires
$moduleRoot = Split-Path -Parent $PSScriptRoot
$threadManagerPath = Join-Path -Path $moduleRoot -ChildPath "Dynamic-ThreadManager.psm1"
$queueManagerPath = Join-Path -Path $moduleRoot -ChildPath "TaskPriorityQueue.psm1"

Import-Module $threadManagerPath -Force
Import-Module $queueManagerPath -Force

# Fonction pour simuler une tâche de traitement
function Invoke-ProcessingTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [int]$Duration = 1000,

        [Parameter(Mandatory = $false)]
        [int]$CpuIntensity = 50
    )

    Write-Host "Démarrage de la tâche: $TaskName" -ForegroundColor Cyan

    # Simuler une charge CPU
    $startTime = Get-Date
    $endTime = $startTime.AddMilliseconds($Duration)

    while ((Get-Date) -lt $endTime) {
        # Simuler une charge CPU variable
        if ($CpuIntensity -gt 0) {
            # Simuler une charge CPU en effectuant des calculs
            $data = 1..$CpuIntensity
            # Utiliser Out-Null pour éviter l'avertissement de variable non utilisée
            $data | ForEach-Object { [math]::Pow($_, 2) } | Out-Null
        }

        # Pause courte pour éviter de saturer le CPU
        Start-Sleep -Milliseconds 10
    }

    Write-Host "Fin de la tâche: $TaskName (Durée: $((Get-Date) - $startTime))" -ForegroundColor Green

    return @{
        TaskName     = $TaskName
        Duration     = ((Get-Date) - $startTime).TotalMilliseconds
        CpuIntensity = $CpuIntensity
    }
}

# Fonction pour exécuter des tâches avec optimisation dynamique
function Invoke-OptimizedParallelTasks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [int]$InitialThreads = 4,

        [Parameter(Mandatory = $false)]
        [int]$AdjustmentIntervalSeconds = 2
    )

    Write-Host "Démarrage de l'exécution optimisée de $($Tasks.Count) tâches..." -ForegroundColor Yellow

    # Créer une file d'attente prioritaire
    $queue = New-TaskPriorityQueue

    # Ajouter les tâches à la file d'attente
    foreach ($task in $Tasks) {
        $priorityTask = New-PriorityTask -Name $task.Name -ScriptBlock {
            param($taskParams)
            Invoke-ProcessingTask -TaskName $taskParams.Name -Duration $taskParams.Duration -CpuIntensity $taskParams.CpuIntensity
        } -Parameters @{ Name = $task.Name; Duration = $task.Duration; CpuIntensity = $task.CpuIntensity } -Priority $task.Priority

        Add-TaskToQueue -Queue $queue -Task $priorityTask
    }

    # Initialiser les variables
    $currentThreads = $InitialThreads
    $runningTasks = @{}
    $completedTasks = @()
    $startTime = Get-Date

    # Démarrer le monitoring des threads
    $monitoringCallback = {
        param($optimalThreads)

        # Mettre à jour le nombre de threads
        $script:currentThreads = Update-ThreadCount -CurrentThreadCount $script:currentThreads -OptimalThreadCount $optimalThreads

        Write-Host "Ajustement du nombre de threads: $script:currentThreads (Optimal: $optimalThreads)" -ForegroundColor Magenta
    }

    $monitoring = Start-ThreadMonitoring -IntervalSeconds $AdjustmentIntervalSeconds -AdjustmentCallback $monitoringCallback

    try {
        # Boucle principale
        while ($queue.Count() -gt 0 -or $runningTasks.Count -gt 0) {
            # Promouvoir les tâches en attente
            Invoke-TaskPromotion -Queue $queue

            # Démarrer de nouvelles tâches si des threads sont disponibles
            while ($runningTasks.Count -lt $currentThreads -and $queue.Count() -gt 0) {
                $task = Get-NextTask -Queue $queue

                if ($task) {
                    # Démarrer la tâche en arrière-plan
                    $job = Start-Job -ScriptBlock $task.ScriptBlock -ArgumentList $task.Parameters

                    # Enregistrer la tâche en cours d'exécution
                    $runningTasks[$job.Id] = @{
                        Job       = $job
                        Task      = $task
                        StartTime = Get-Date
                    }

                    Write-Host "Tâche démarrée: $($task.Name) (ID: $($job.Id), Priorité: $($task.Priority))" -ForegroundColor Yellow
                }
            }

            # Vérifier les tâches terminées
            $completedJobIds = @($runningTasks.Keys | Where-Object { $runningTasks[$_].Job.State -ne 'Running' })

            foreach ($jobId in $completedJobIds) {
                $jobInfo = $runningTasks[$jobId]
                $job = $jobInfo.Job
                $task = $jobInfo.Task

                # Récupérer les résultats
                $result = Receive-Job -Job $job
                $job | Remove-Job -Force

                # Enregistrer la tâche terminée
                $completedTasks += @{
                    TaskName = $task.Name
                    Priority = $task.Priority
                    Duration = ((Get-Date) - $jobInfo.StartTime).TotalMilliseconds
                    Result   = $result
                }

                Write-Host "Tâche terminée: $($task.Name) (ID: $jobId, Priorité: $($task.Priority))" -ForegroundColor Green

                # Supprimer la tâche de la liste des tâches en cours
                $runningTasks.Remove($jobId)
            }

            # Pause courte pour éviter de saturer le CPU
            Start-Sleep -Milliseconds 100
        }
    } finally {
        # Arrêter le monitoring
        Stop-ThreadMonitoring -MonitoringId $monitoring.MonitoringId

        # Nettoyer les jobs restants
        $runningTasks.Values | ForEach-Object { $_.Job | Remove-Job -Force -ErrorAction SilentlyContinue }
    }

    # Afficher un résumé
    $totalDuration = ((Get-Date) - $startTime).TotalSeconds

    Write-Host "`nRésumé de l'exécution:" -ForegroundColor Yellow
    Write-Host "  Tâches exécutées: $($completedTasks.Count)" -ForegroundColor White
    Write-Host "  Durée totale: $totalDuration secondes" -ForegroundColor White
    Write-Host "  Tâches par seconde: $([math]::Round($completedTasks.Count / $totalDuration, 2))" -ForegroundColor White

    return $completedTasks
}

# Créer des tâches de test
$tasks = @(
    @{ Name = "Tâche légère 1"; Duration = 500; CpuIntensity = 10; Priority = 5 },
    @{ Name = "Tâche légère 2"; Duration = 700; CpuIntensity = 20; Priority = 5 },
    @{ Name = "Tâche légère 3"; Duration = 600; CpuIntensity = 15; Priority = 5 },
    @{ Name = "Tâche moyenne 1"; Duration = 1500; CpuIntensity = 40; Priority = 7 },
    @{ Name = "Tâche moyenne 2"; Duration = 1200; CpuIntensity = 50; Priority = 7 },
    @{ Name = "Tâche lourde 1"; Duration = 3000; CpuIntensity = 80; Priority = 9 },
    @{ Name = "Tâche lourde 2"; Duration = 2500; CpuIntensity = 70; Priority = 9 },
    @{ Name = "Tâche bloquante"; Duration = 4000; CpuIntensity = 90; Priority = 10 }
)

# Exécuter les tâches avec optimisation dynamique
$results = Invoke-OptimizedParallelTasks -Tasks $tasks -InitialThreads 4 -AdjustmentIntervalSeconds 1

# Afficher les résultats détaillés
Write-Host "`nRésultats détaillés:" -ForegroundColor Yellow
$results | Sort-Object -Property Duration -Descending | Format-Table -Property TaskName, Priority, Duration -AutoSize
