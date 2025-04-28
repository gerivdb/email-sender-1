#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©montre l'utilisation de l'optimisation dynamique de la parallÃ©lisation.
.DESCRIPTION
    Ce script montre comment utiliser les modules Dynamic-ThreadManager et TaskPriorityQueue
    pour optimiser dynamiquement la parallÃ©lisation des tÃ¢ches.
.EXAMPLE
    .\Demo-DynamicParallelization.ps1
    ExÃ©cute la dÃ©monstration avec les paramÃ¨tres par dÃ©faut.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Importer les modules nÃ©cessaires
$moduleRoot = Split-Path -Parent $PSScriptRoot
$threadManagerPath = Join-Path -Path $moduleRoot -ChildPath "Dynamic-ThreadManager.psm1"
$queueManagerPath = Join-Path -Path $moduleRoot -ChildPath "TaskPriorityQueue.psm1"

Import-Module $threadManagerPath -Force
Import-Module $queueManagerPath -Force

# Fonction pour simuler une tÃ¢che de traitement
function Invoke-ProcessingTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [int]$Duration = 1000,

        [Parameter(Mandatory = $false)]
        [int]$CpuIntensity = 50
    )

    Write-Host "DÃ©marrage de la tÃ¢che: $TaskName" -ForegroundColor Cyan

    # Simuler une charge CPU
    $startTime = Get-Date
    $endTime = $startTime.AddMilliseconds($Duration)

    while ((Get-Date) -lt $endTime) {
        # Simuler une charge CPU variable
        if ($CpuIntensity -gt 0) {
            # Simuler une charge CPU en effectuant des calculs
            $data = 1..$CpuIntensity
            # Utiliser Out-Null pour Ã©viter l'avertissement de variable non utilisÃ©e
            $data | ForEach-Object { [math]::Pow($_, 2) } | Out-Null
        }

        # Pause courte pour Ã©viter de saturer le CPU
        Start-Sleep -Milliseconds 10
    }

    Write-Host "Fin de la tÃ¢che: $TaskName (DurÃ©e: $((Get-Date) - $startTime))" -ForegroundColor Green

    return @{
        TaskName     = $TaskName
        Duration     = ((Get-Date) - $startTime).TotalMilliseconds
        CpuIntensity = $CpuIntensity
    }
}

# Fonction pour exÃ©cuter des tÃ¢ches avec optimisation dynamique
function Invoke-OptimizedParallelTasks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [int]$InitialThreads = 4,

        [Parameter(Mandatory = $false)]
        [int]$AdjustmentIntervalSeconds = 2
    )

    Write-Host "DÃ©marrage de l'exÃ©cution optimisÃ©e de $($Tasks.Count) tÃ¢ches..." -ForegroundColor Yellow

    # CrÃ©er une file d'attente prioritaire
    $queue = New-TaskPriorityQueue

    # Ajouter les tÃ¢ches Ã  la file d'attente
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

    # DÃ©marrer le monitoring des threads
    $monitoringCallback = {
        param($optimalThreads)

        # Mettre Ã  jour le nombre de threads
        $script:currentThreads = Update-ThreadCount -CurrentThreadCount $script:currentThreads -OptimalThreadCount $optimalThreads

        Write-Host "Ajustement du nombre de threads: $script:currentThreads (Optimal: $optimalThreads)" -ForegroundColor Magenta
    }

    $monitoring = Start-ThreadMonitoring -IntervalSeconds $AdjustmentIntervalSeconds -AdjustmentCallback $monitoringCallback

    try {
        # Boucle principale
        while ($queue.Count() -gt 0 -or $runningTasks.Count -gt 0) {
            # Promouvoir les tÃ¢ches en attente
            Invoke-TaskPromotion -Queue $queue

            # DÃ©marrer de nouvelles tÃ¢ches si des threads sont disponibles
            while ($runningTasks.Count -lt $currentThreads -and $queue.Count() -gt 0) {
                $task = Get-NextTask -Queue $queue

                if ($task) {
                    # DÃ©marrer la tÃ¢che en arriÃ¨re-plan
                    $job = Start-Job -ScriptBlock $task.ScriptBlock -ArgumentList $task.Parameters

                    # Enregistrer la tÃ¢che en cours d'exÃ©cution
                    $runningTasks[$job.Id] = @{
                        Job       = $job
                        Task      = $task
                        StartTime = Get-Date
                    }

                    Write-Host "TÃ¢che dÃ©marrÃ©e: $($task.Name) (ID: $($job.Id), PrioritÃ©: $($task.Priority))" -ForegroundColor Yellow
                }
            }

            # VÃ©rifier les tÃ¢ches terminÃ©es
            $completedJobIds = @($runningTasks.Keys | Where-Object { $runningTasks[$_].Job.State -ne 'Running' })

            foreach ($jobId in $completedJobIds) {
                $jobInfo = $runningTasks[$jobId]
                $job = $jobInfo.Job
                $task = $jobInfo.Task

                # RÃ©cupÃ©rer les rÃ©sultats
                $result = Receive-Job -Job $job
                $job | Remove-Job -Force

                # Enregistrer la tÃ¢che terminÃ©e
                $completedTasks += @{
                    TaskName = $task.Name
                    Priority = $task.Priority
                    Duration = ((Get-Date) - $jobInfo.StartTime).TotalMilliseconds
                    Result   = $result
                }

                Write-Host "TÃ¢che terminÃ©e: $($task.Name) (ID: $jobId, PrioritÃ©: $($task.Priority))" -ForegroundColor Green

                # Supprimer la tÃ¢che de la liste des tÃ¢ches en cours
                $runningTasks.Remove($jobId)
            }

            # Pause courte pour Ã©viter de saturer le CPU
            Start-Sleep -Milliseconds 100
        }
    } finally {
        # ArrÃªter le monitoring
        Stop-ThreadMonitoring -MonitoringId $monitoring.MonitoringId

        # Nettoyer les jobs restants
        $runningTasks.Values | ForEach-Object { $_.Job | Remove-Job -Force -ErrorAction SilentlyContinue }
    }

    # Afficher un rÃ©sumÃ©
    $totalDuration = ((Get-Date) - $startTime).TotalSeconds

    Write-Host "`nRÃ©sumÃ© de l'exÃ©cution:" -ForegroundColor Yellow
    Write-Host "  TÃ¢ches exÃ©cutÃ©es: $($completedTasks.Count)" -ForegroundColor White
    Write-Host "  DurÃ©e totale: $totalDuration secondes" -ForegroundColor White
    Write-Host "  TÃ¢ches par seconde: $([math]::Round($completedTasks.Count / $totalDuration, 2))" -ForegroundColor White

    return $completedTasks
}

# CrÃ©er des tÃ¢ches de test
$tasks = @(
    @{ Name = "TÃ¢che lÃ©gÃ¨re 1"; Duration = 500; CpuIntensity = 10; Priority = 5 },
    @{ Name = "TÃ¢che lÃ©gÃ¨re 2"; Duration = 700; CpuIntensity = 20; Priority = 5 },
    @{ Name = "TÃ¢che lÃ©gÃ¨re 3"; Duration = 600; CpuIntensity = 15; Priority = 5 },
    @{ Name = "TÃ¢che moyenne 1"; Duration = 1500; CpuIntensity = 40; Priority = 7 },
    @{ Name = "TÃ¢che moyenne 2"; Duration = 1200; CpuIntensity = 50; Priority = 7 },
    @{ Name = "TÃ¢che lourde 1"; Duration = 3000; CpuIntensity = 80; Priority = 9 },
    @{ Name = "TÃ¢che lourde 2"; Duration = 2500; CpuIntensity = 70; Priority = 9 },
    @{ Name = "TÃ¢che bloquante"; Duration = 4000; CpuIntensity = 90; Priority = 10 }
)

# ExÃ©cuter les tÃ¢ches avec optimisation dynamique
$results = Invoke-OptimizedParallelTasks -Tasks $tasks -InitialThreads 4 -AdjustmentIntervalSeconds 1

# Afficher les rÃ©sultats dÃ©taillÃ©s
Write-Host "`nRÃ©sultats dÃ©taillÃ©s:" -ForegroundColor Yellow
$results | Sort-Object -Property Duration -Descending | Format-Table -Property TaskName, Priority, Duration -AutoSize
