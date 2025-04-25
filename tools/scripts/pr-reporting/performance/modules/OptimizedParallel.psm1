#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'exécution parallèle optimisée des tests de performance.
.DESCRIPTION
    Fournit des fonctions avancées pour exécuter des tests en parallèle tout en
    optimisant l'utilisation des ressources système.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Variables globales pour le module
$script:MaxConcurrency = [Environment]::ProcessorCount
$script:ResourceThresholds = @{
    CPU = 85  # Pourcentage maximum d'utilisation CPU
    Memory = 80  # Pourcentage maximum d'utilisation mémoire
    DiskIO = 70  # Pourcentage maximum d'utilisation disque
}
$script:RunspacePool = $null
$script:ActiveJobs = @{}
$script:JobQueue = New-Object System.Collections.Generic.Queue[hashtable]
$script:ResourceMonitorJob = $null

# Fonction pour initialiser le pool de runspaces
function Initialize-ParallelPool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits
    )
    
    # Déterminer le nombre optimal de threads
    if ($MaxThreads -le 0) {
        $MaxThreads = [Math]::Max(1, [Environment]::ProcessorCount - 1)
    }
    
    # Mettre à jour les limites de ressources si spécifiées
    if ($ResourceLimits) {
        foreach ($key in $ResourceLimits.Keys) {
            if ($script:ResourceThresholds.ContainsKey($key)) {
                $script:ResourceThresholds[$key] = $ResourceLimits[$key]
            }
        }
    }
    
    # Créer le pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $script:RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
    $script:RunspacePool.Open()
    
    # Démarrer le moniteur de ressources
    Start-ResourceMonitor
    
    Write-Verbose "Pool de parallélisation initialisé avec $MaxThreads threads maximum"
    
    return @{
        MaxThreads = $MaxThreads
        ResourceThresholds = $script:ResourceThresholds.Clone()
    }
}

# Fonction pour démarrer le moniteur de ressources
function Start-ResourceMonitor {
    [CmdletBinding()]
    param()
    
    if ($script:ResourceMonitorJob -ne $null) {
        return
    }
    
    $monitorScript = {
        param($Interval = 2)
        
        while ($true) {
            # Obtenir les métriques de ressources
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
            $memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue
            $diskCounter = Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction SilentlyContinue
            
            $cpuUsage = if ($cpuCounter) { $cpuCounter.CounterSamples[0].CookedValue } else { 0 }
            $memoryUsage = if ($memoryCounter) { $memoryCounter.CounterSamples[0].CookedValue } else { 0 }
            $diskUsage = if ($diskCounter) { $diskCounter.CounterSamples[0].CookedValue } else { 0 }
            
            # Retourner les métriques
            [PSCustomObject]@{
                Timestamp = Get-Date
                CPU = $cpuUsage
                Memory = $memoryUsage
                Disk = $diskUsage
            }
            
            # Attendre l'intervalle spécifié
            Start-Sleep -Seconds $Interval
        }
    }
    
    $script:ResourceMonitorJob = Start-Job -ScriptBlock $monitorScript -ArgumentList 2
}

# Fonction pour obtenir les métriques de ressources actuelles
function Get-CurrentResourceMetrics {
    [CmdletBinding()]
    param()
    
    if ($script:ResourceMonitorJob -eq $null -or $script:ResourceMonitorJob.State -ne 'Running') {
        Start-ResourceMonitor
        Start-Sleep -Seconds 2  # Attendre que les premières métriques soient disponibles
    }
    
    $metrics = Receive-Job -Job $script:ResourceMonitorJob -Keep | Select-Object -Last 1
    
    if (-not $metrics) {
        # Fallback si le job ne retourne pas de métriques
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        $memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue
        $diskCounter = Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction SilentlyContinue
        
        $cpuUsage = if ($cpuCounter) { $cpuCounter.CounterSamples[0].CookedValue } else { 0 }
        $memoryUsage = if ($memoryCounter) { $memoryCounter.CounterSamples[0].CookedValue } else { 0 }
        $diskUsage = if ($diskCounter) { $diskCounter.CounterSamples[0].CookedValue } else { 0 }
        
        $metrics = [PSCustomObject]@{
            Timestamp = Get-Date
            CPU = $cpuUsage
            Memory = $memoryUsage
            Disk = $diskUsage
        }
    }
    
    return $metrics
}

# Fonction pour vérifier si les ressources sont disponibles pour exécuter plus de jobs
function Test-ResourceAvailability {
    [CmdletBinding()]
    param()
    
    $metrics = Get-CurrentResourceMetrics
    
    $cpuAvailable = $metrics.CPU -lt $script:ResourceThresholds.CPU
    $memoryAvailable = $metrics.Memory -lt $script:ResourceThresholds.Memory
    $diskAvailable = $metrics.Disk -lt $script:ResourceThresholds.DiskIO
    
    $result = $cpuAvailable -and $memoryAvailable -and $diskAvailable
    
    if (-not $result) {
        Write-Verbose "Ressources insuffisantes: CPU=$($metrics.CPU)%, Memory=$($metrics.Memory)%, Disk=$($metrics.Disk)%"
    }
    
    return $result
}

# Fonction pour exécuter une tâche en parallèle
function Invoke-ParallelTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Priority,
        
        [Parameter(Mandatory = $false)]
        [switch]$WaitForCompletion,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0
    )
    
    # Initialiser le pool si nécessaire
    if ($script:RunspacePool -eq $null) {
        Initialize-ParallelPool
    }
    
    # Créer un PowerShell pour exécuter le script
    $ps = [powershell]::Create()
    $ps.RunspacePool = $script:RunspacePool
    
    # Ajouter le script et les arguments
    [void]$ps.AddScript($ScriptBlock)
    foreach ($arg in $ArgumentList) {
        [void]$ps.AddArgument($arg)
    }
    
    # Créer un objet pour suivre le job
    $jobInfo = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        PowerShell = $ps
        StartTime = Get-Date
        Handle = $ps.BeginInvoke()
        Priority = [bool]$Priority
        Timeout = if ($TimeoutSeconds -gt 0) { (Get-Date).AddSeconds($TimeoutSeconds) } else { $null }
    }
    
    # Vérifier si les ressources sont disponibles
    if (Test-ResourceAvailability) {
        # Démarrer le job immédiatement
        $script:ActiveJobs[$jobInfo.Id] = $jobInfo
        Write-Verbose "Tâche $($jobInfo.Id) démarrée"
    }
    else {
        # Mettre le job dans la file d'attente
        if ($Priority) {
            # Insérer au début de la file d'attente pour les jobs prioritaires
            $tempQueue = New-Object System.Collections.Generic.Queue[hashtable]
            $tempQueue.Enqueue(@{ JobInfo = $jobInfo })
            foreach ($item in $script:JobQueue) {
                $tempQueue.Enqueue($item)
            }
            $script:JobQueue = $tempQueue
        }
        else {
            # Ajouter à la fin de la file d'attente
            $script:JobQueue.Enqueue(@{ JobInfo = $jobInfo })
        }
        Write-Verbose "Tâche $($jobInfo.Id) mise en file d'attente"
    }
    
    # Attendre la fin du job si demandé
    if ($WaitForCompletion) {
        $result = Wait-ParallelTask -JobId $jobInfo.Id -TimeoutSeconds $TimeoutSeconds
        return $result
    }
    
    return $jobInfo.Id
}

# Fonction pour attendre la fin d'une tâche parallèle
function Wait-ParallelTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$JobId,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0
    )
    
    $timeout = if ($TimeoutSeconds -gt 0) { (Get-Date).AddSeconds($TimeoutSeconds) } else { $null }
    
    # Attendre que le job soit terminé
    while ($script:ActiveJobs.ContainsKey($JobId) -or $script:JobQueue.Count -gt 0) {
        # Vérifier si le job est dans la file d'attente
        $queuedJob = $null
        foreach ($item in $script:JobQueue) {
            if ($item.JobInfo.Id -eq $JobId) {
                $queuedJob = $item
                break
            }
        }
        
        # Si le job est dans la file d'attente et que des ressources sont disponibles, le démarrer
        if ($queuedJob -ne $null -and (Test-ResourceAvailability)) {
            $script:JobQueue = New-Object System.Collections.Generic.Queue[hashtable]
            foreach ($item in $script:JobQueue) {
                if ($item.JobInfo.Id -ne $JobId) {
                    $script:JobQueue.Enqueue($item)
                }
            }
            $script:ActiveJobs[$JobId] = $queuedJob.JobInfo
            Write-Verbose "Tâche $JobId démarrée depuis la file d'attente"
        }
        
        # Si le job est actif et terminé, récupérer le résultat
        if ($script:ActiveJobs.ContainsKey($JobId) -and $script:ActiveJobs[$JobId].Handle.IsCompleted) {
            $jobInfo = $script:ActiveJobs[$JobId]
            $result = $jobInfo.PowerShell.EndInvoke($jobInfo.Handle)
            $jobInfo.PowerShell.Dispose()
            $script:ActiveJobs.Remove($JobId)
            
            # Traiter la file d'attente si des ressources sont disponibles
            Process-JobQueue
            
            return $result
        }
        
        # Vérifier le timeout
        if ($timeout -ne $null -and (Get-Date) -gt $timeout) {
            Write-Warning "Timeout atteint pour la tâche $JobId"
            
            # Si le job est actif, l'arrêter
            if ($script:ActiveJobs.ContainsKey($JobId)) {
                $jobInfo = $script:ActiveJobs[$JobId]
                $jobInfo.PowerShell.Stop()
                $jobInfo.PowerShell.Dispose()
                $script:ActiveJobs.Remove($JobId)
            }
            
            # Si le job est dans la file d'attente, le retirer
            $script:JobQueue = New-Object System.Collections.Generic.Queue[hashtable]
            foreach ($item in $script:JobQueue) {
                if ($item.JobInfo.Id -ne $JobId) {
                    $script:JobQueue.Enqueue($item)
                }
            }
            
            return $null
        }
        
        # Attendre un peu avant de vérifier à nouveau
        Start-Sleep -Milliseconds 100
        
        # Traiter la file d'attente si des ressources sont disponibles
        Process-JobQueue
    }
    
    return $null
}

# Fonction pour traiter la file d'attente des jobs
function Process-JobQueue {
    [CmdletBinding()]
    param()
    
    # Vérifier si des ressources sont disponibles
    if (-not (Test-ResourceAvailability)) {
        return
    }
    
    # Vérifier si la file d'attente est vide
    if ($script:JobQueue.Count -eq 0) {
        return
    }
    
    # Obtenir le prochain job de la file d'attente
    $nextJob = $script:JobQueue.Dequeue().JobInfo
    
    # Démarrer le job
    $script:ActiveJobs[$nextJob.Id] = $nextJob
    Write-Verbose "Tâche $($nextJob.Id) démarrée depuis la file d'attente"
}

# Fonction pour obtenir l'état des tâches parallèles
function Get-ParallelTaskStatus {
    [CmdletBinding()]
    param()
    
    $activeJobs = $script:ActiveJobs.Values | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.Id
            State = if ($_.Handle.IsCompleted) { "Completed" } else { "Running" }
            StartTime = $_.StartTime
            Duration = (Get-Date) - $_.StartTime
            Priority = $_.Priority
        }
    }
    
    $queuedJobs = $script:JobQueue | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.JobInfo.Id
            State = "Queued"
            StartTime = $null
            Duration = $null
            Priority = $_.JobInfo.Priority
        }
    }
    
    $metrics = Get-CurrentResourceMetrics
    
    return [PSCustomObject]@{
        ActiveJobs = $activeJobs
        QueuedJobs = $queuedJobs
        ResourceUsage = [PSCustomObject]@{
            CPU = $metrics.CPU
            Memory = $metrics.Memory
            Disk = $metrics.Disk
        }
        Thresholds = $script:ResourceThresholds.Clone()
        MaxConcurrency = $script:RunspacePool.GetMaxRunspaces()
        AvailableConcurrency = $script:RunspacePool.GetAvailableRunspaces()
    }
}

# Fonction pour nettoyer les ressources
function Clear-ParallelPool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Arrêter le moniteur de ressources
    if ($script:ResourceMonitorJob -ne $null) {
        Stop-Job -Job $script:ResourceMonitorJob -ErrorAction SilentlyContinue
        Remove-Job -Job $script:ResourceMonitorJob -Force -ErrorAction SilentlyContinue
        $script:ResourceMonitorJob = $null
    }
    
    # Arrêter tous les jobs actifs
    foreach ($jobId in @($script:ActiveJobs.Keys)) {
        $jobInfo = $script:ActiveJobs[$jobId]
        
        if ($Force -or $jobInfo.Handle.IsCompleted) {
            $jobInfo.PowerShell.Stop()
            $jobInfo.PowerShell.Dispose()
            $script:ActiveJobs.Remove($jobId)
        }
        elseif (-not $Force) {
            Write-Warning "La tâche $jobId est toujours en cours d'exécution. Utilisez -Force pour l'arrêter."
            return $false
        }
    }
    
    # Vider la file d'attente
    $script:JobQueue = New-Object System.Collections.Generic.Queue[hashtable]
    
    # Fermer le pool de runspaces
    if ($script:RunspacePool -ne $null) {
        $script:RunspacePool.Close()
        $script:RunspacePool.Dispose()
        $script:RunspacePool = $null
    }
    
    Write-Verbose "Pool de parallélisation nettoyé"
    return $true
}

# Fonction pour exécuter plusieurs tâches en parallèle avec contrôle de ressources
function Invoke-ParallelTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [object[]]$InputObjects,
        
        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits
    )
    
    # Initialiser le pool avec les limites spécifiées
    if ($ThrottleLimit -gt 0) {
        Initialize-ParallelPool -MaxThreads $ThrottleLimit -ResourceLimits $ResourceLimits
    }
    else {
        Initialize-ParallelPool -ResourceLimits $ResourceLimits
    }
    
    $totalJobs = $InputObjects.Count
    $completedJobs = 0
    $results = @()
    $jobIds = @()
    
    # Démarrer tous les jobs
    foreach ($inputObject in $InputObjects) {
        $jobId = Invoke-ParallelTask -ScriptBlock $ScriptBlock -ArgumentList $inputObject
        $jobIds += $jobId
    }
    
    # Attendre que tous les jobs soient terminés
    while ($jobIds.Count -gt 0) {
        $completedJobIds = @()
        
        foreach ($jobId in $jobIds) {
            if (-not $script:ActiveJobs.ContainsKey($jobId)) {
                continue
            }
            
            $jobInfo = $script:ActiveJobs[$jobId]
            
            if ($jobInfo.Handle.IsCompleted) {
                $result = $jobInfo.PowerShell.EndInvoke($jobInfo.Handle)
                $jobInfo.PowerShell.Dispose()
                $script:ActiveJobs.Remove($jobId)
                
                $results += $result
                $completedJobIds += $jobId
                $completedJobs++
                
                # Traiter la file d'attente
                Process-JobQueue
            }
            elseif ($jobInfo.Timeout -ne $null -and (Get-Date) -gt $jobInfo.Timeout) {
                Write-Warning "Timeout atteint pour la tâche $jobId"
                $jobInfo.PowerShell.Stop()
                $jobInfo.PowerShell.Dispose()
                $script:ActiveJobs.Remove($jobId)
                
                $completedJobIds += $jobId
                $completedJobs++
            }
        }
        
        # Mettre à jour la liste des jobs en cours
        $jobIds = $jobIds | Where-Object { $completedJobIds -notcontains $_ }
        
        # Afficher la progression si demandé
        if ($ShowProgress) {
            $percentComplete = [Math]::Min(100, [Math]::Round(($completedJobs / $totalJobs) * 100))
            $status = "Traitement de $completedJobs/$totalJobs tâches ($percentComplete%)"
            
            Write-Progress -Activity "Exécution des tâches parallèles" -Status $status -PercentComplete $percentComplete
        }
        
        # Attendre un peu avant de vérifier à nouveau
        if ($jobIds.Count -gt 0) {
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Terminer la barre de progression
    if ($ShowProgress) {
        Write-Progress -Activity "Exécution des tâches parallèles" -Completed
    }
    
    return $results
}

# Fonction pour exécuter des tests de performance en parallèle
function Invoke-ParallelPerformanceTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TestScripts,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$TestParameters = @{},
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$AdaptiveThrottling,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Créer le script à exécuter pour chaque test
    $scriptBlock = {
        param($TestScript, $Parameters, $Iteration)
        
        $testParams = $Parameters.Clone()
        
        # Ajouter l'itération aux paramètres si nécessaire
        if (-not $testParams.ContainsKey("Iteration")) {
            $testParams["Iteration"] = $Iteration
        }
        
        # Générer un chemin de sortie unique si nécessaire
        if ($testParams.ContainsKey("OutputPath")) {
            $outputFile = [System.IO.Path]::GetFileNameWithoutExtension($testParams["OutputPath"])
            $outputExt = [System.IO.Path]::GetExtension($testParams["OutputPath"])
            $testParams["OutputPath"] = "$outputFile`_$Iteration$outputExt"
        }
        
        try {
            # Exécuter le script de test
            $result = & $TestScript @testParams
            
            return [PSCustomObject]@{
                TestScript = $TestScript
                Iteration = $Iteration
                Success = $true
                Result = $result
                Error = $null
            }
        }
        catch {
            return [PSCustomObject]@{
                TestScript = $TestScript
                Iteration = $Iteration
                Success = $false
                Result = $null
                Error = $_.Exception.Message
            }
        }
    }
    
    # Préparer les entrées pour les tâches parallèles
    $inputs = @()
    foreach ($testScript in $TestScripts) {
        for ($i = 1; $i -le $Iterations; $i++) {
            $inputs += [PSCustomObject]@{
                TestScript = $testScript
                Parameters = $TestParameters
                Iteration = $i
            }
        }
    }
    
    # Configurer les limites de ressources pour l'exécution adaptative
    $resourceLimits = $null
    if ($AdaptiveThrottling) {
        $resourceLimits = @{
            CPU = 75  # Limite CPU plus basse pour l'exécution adaptative
            Memory = 70  # Limite mémoire plus basse pour l'exécution adaptative
        }
    }
    
    # Exécuter les tests en parallèle
    $results = Invoke-ParallelTasks -ScriptBlock $scriptBlock -InputObjects $inputs -ThrottleLimit $ThrottleLimit -ShowProgress -ResourceLimits $resourceLimits
    
    # Agréger les résultats
    $aggregatedResults = [PSCustomObject]@{
        StartTime = Get-Date
        EndTime = Get-Date
        TotalTests = $results.Count
        SuccessCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
        ErrorCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
        TestResults = $results
    }
    
    # Enregistrer les résultats si un chemin de sortie est spécifié
    if ($OutputPath) {
        $aggregatedResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    }
    
    return $aggregatedResults
}

# Exporter les fonctions du module
Export-ModuleMember -Function Initialize-ParallelPool, Invoke-ParallelTask, Wait-ParallelTask, Get-ParallelTaskStatus, Clear-ParallelPool, Invoke-ParallelTasks, Invoke-ParallelPerformanceTests
