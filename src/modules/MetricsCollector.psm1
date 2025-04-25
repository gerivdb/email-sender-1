# Module de collecte de métriques de performance
# Ce module collecte les métriques de performance du système et des applications
# Author: EMAIL_SENDER_1 Team
# Version: 1.0.0
# Tags: performance, metrics, monitoring

#Requires -Version 5.1

# Variables globales du module
$script:MetricsCollectorConfig = @{
    Enabled            = $true
    CollectionInterval = 5  # secondes
    StoragePath        = "$env:TEMP\MetricsCollector"
    MaxStorageSize     = 100    # Mo
    CollectCPU         = $true
    CollectMemory      = $true
    CollectDisk        = $true
    CollectNetwork     = $true
    CollectApplication = $true
    TopProcessCount    = 5
}

$script:CollectionJob = $null
$script:MetricsCache = @{}

function Initialize-MetricsCollector {
    <#
    .SYNOPSIS
        Initialise le collecteur de métriques de performance.
    .DESCRIPTION
        Configure et initialise le collecteur de métriques de performance avec les paramètres spécifiés.
    .PARAMETER Enabled
        Active ou désactive la collecte de métriques.
    .PARAMETER CollectionInterval
        Intervalle de collecte des métriques en secondes.
    .PARAMETER StoragePath
        Chemin de stockage des métriques collectées.
    .PARAMETER MaxStorageSize
        Taille maximale de stockage en Mo.
    .PARAMETER CollectCPU
        Active ou désactive la collecte des métriques CPU.
    .PARAMETER CollectMemory
        Active ou désactive la collecte des métriques mémoire.
    .PARAMETER CollectDisk
        Active ou désactive la collecte des métriques disque.
    .PARAMETER CollectNetwork
        Active ou désactive la collecte des métriques réseau.
    .PARAMETER CollectApplication
        Active ou désactive la collecte des métriques applicatives.
    .PARAMETER TopProcessCount
        Nombre de processus à inclure dans les métriques "Top Processes".
    .EXAMPLE
        Initialize-MetricsCollector -CollectionInterval 10 -StoragePath "C:\Metrics"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3600)]
        [int]$CollectionInterval = 5,

        [Parameter(Mandatory = $false)]
        [string]$StoragePath = "$env:TEMP\MetricsCollector",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10000)]
        [int]$MaxStorageSize = 100,

        [Parameter(Mandatory = $false)]
        [bool]$CollectCPU = $true,

        [Parameter(Mandatory = $false)]
        [bool]$CollectMemory = $true,

        [Parameter(Mandatory = $false)]
        [bool]$CollectDisk = $true,

        [Parameter(Mandatory = $false)]
        [bool]$CollectNetwork = $true,

        [Parameter(Mandatory = $false)]
        [bool]$CollectApplication = $true,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$TopProcessCount = 5
    )

    # Mettre à jour la configuration
    $script:MetricsCollectorConfig.Enabled = $Enabled
    $script:MetricsCollectorConfig.CollectionInterval = $CollectionInterval
    $script:MetricsCollectorConfig.StoragePath = $StoragePath
    $script:MetricsCollectorConfig.MaxStorageSize = $MaxStorageSize
    $script:MetricsCollectorConfig.CollectCPU = $CollectCPU
    $script:MetricsCollectorConfig.CollectMemory = $CollectMemory
    $script:MetricsCollectorConfig.CollectDisk = $CollectDisk
    $script:MetricsCollectorConfig.CollectNetwork = $CollectNetwork
    $script:MetricsCollectorConfig.CollectApplication = $CollectApplication
    $script:MetricsCollectorConfig.TopProcessCount = $TopProcessCount

    # Créer le répertoire de stockage s'il n'existe pas
    if (-not (Test-Path -Path $StoragePath)) {
        New-Item -Path $StoragePath -ItemType Directory -Force | Out-Null
    }

    Write-Verbose "MetricsCollector initialisé avec succès."
    Write-Verbose "Intervalle de collecte: $CollectionInterval secondes"
    Write-Verbose "Chemin de stockage: $StoragePath"

    return $script:MetricsCollectorConfig
}

function Start-MetricsCollection {
    <#
    .SYNOPSIS
        Démarre la collecte de métriques de performance.
    .DESCRIPTION
        Démarre un job en arrière-plan qui collecte périodiquement les métriques de performance.
    .PARAMETER NoBackground
        Si spécifié, exécute la collecte en premier plan (utile pour le débogage).
    .EXAMPLE
        Start-MetricsCollection
    .EXAMPLE
        Start-MetricsCollection -NoBackground
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$NoBackground
    )

    # Vérifier si le collecteur est activé
    if (-not $script:MetricsCollectorConfig.Enabled) {
        Write-Warning "Le collecteur de métriques est désactivé. Utilisez Initialize-MetricsCollector -Enabled `$true pour l'activer."
        return
    }

    # Arrêter la collecte existante si elle est en cours
    if ($null -ne $script:CollectionJob) {
        Stop-MetricsCollection
    }

    # Définir le script de collecte
    $collectionScript = {
        param($config)

        # Fonction pour collecter toutes les métriques
        function Get-AllMetrics {
            # Renommé pour utiliser un verbe approuvé
            $metrics = @{
                Timestamp = Get-Date
            }

            if ($config.CollectCPU) {
                $metrics.CPU = Get-CPUMetrics
            }

            if ($config.CollectMemory) {
                $metrics.Memory = Get-MemoryMetrics
            }

            if ($config.CollectDisk) {
                $metrics.Disk = Get-DiskMetrics
            }

            if ($config.CollectNetwork) {
                $metrics.Network = Get-NetworkMetrics
            }

            if ($config.CollectApplication) {
                $metrics.Application = Get-ApplicationMetrics
            }

            return $metrics
        }

        # Fonction pour sauvegarder les métriques
        function Save-Metrics {
            param($metrics, $path)

            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $filePath = Join-Path -Path $path -ChildPath "metrics_$timestamp.json"

            $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8

            # Nettoyer les anciens fichiers si nécessaire
            $allFiles = Get-ChildItem -Path $path -Filter "metrics_*.json" | Sort-Object LastWriteTime
            $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum / 1MB

            if ($totalSize -gt $config.MaxStorageSize) {
                $sizeToDelete = $totalSize - $config.MaxStorageSize
                $filesToDelete = @()
                $currentSize = 0

                foreach ($file in $allFiles) {
                    $fileSize = $file.Length / 1MB
                    $filesToDelete += $file
                    $currentSize += $fileSize

                    if ($currentSize -ge $sizeToDelete) {
                        break
                    }
                }

                foreach ($file in $filesToDelete) {
                    Remove-Item -Path $file.FullName -Force
                }
            }
        }

        # Boucle principale de collecte
        while ($true) {
            try {
                $metrics = Get-AllMetrics
                Save-Metrics -metrics $metrics -path $config.StoragePath
            } catch {
                Write-Error "Erreur lors de la collecte des métriques: $_"
            }

            # Attendre l'intervalle de collecte
            Start-Sleep -Seconds $config.CollectionInterval
        }
    }

    # Démarrer la collecte
    if ($NoBackground) {
        # Exécuter en premier plan pour le débogage
        & $collectionScript $script:MetricsCollectorConfig
    } else {
        # Démarrer un job en arrière-plan
        $script:CollectionJob = Start-Job -ScriptBlock $collectionScript -ArgumentList $script:MetricsCollectorConfig
        Write-Verbose "Collecte de métriques démarrée en arrière-plan (Job ID: $($script:CollectionJob.Id))"
    }
}

function Stop-MetricsCollection {
    <#
    .SYNOPSIS
        Arrête la collecte de métriques de performance.
    .DESCRIPTION
        Arrête le job de collecte de métriques en arrière-plan.
    .EXAMPLE
        Stop-MetricsCollection
    #>
    [CmdletBinding()]
    param ()

    if ($null -ne $script:CollectionJob) {
        Stop-Job -Job $script:CollectionJob
        Remove-Job -Job $script:CollectionJob
        $script:CollectionJob = $null
        Write-Verbose "Collecte de métriques arrêtée."
    } else {
        Write-Verbose "Aucune collecte de métriques en cours."
    }
}

function Get-CPUMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques CPU.
    .DESCRIPTION
        Collecte les metriques d'utilisation du CPU, par coeur, la longueur de la file d'attente et les processus les plus consommateurs.
        Inclut également des métriques avancées comme le temps CPU système vs utilisateur, les interruptions et la détection des processus problématiques.
    .EXAMPLE
        Get-CPUMetrics
    #>
    [CmdletBinding()]
    param ()

    # Obtenir les informations détaillées du processeur
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed

    # Obtenir l'utilisation globale du CPU
    $cpuPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" |
        Select-Object PercentProcessorTime, PercentUserTime, PercentPrivilegedTime, PercentInterruptTime, PercentDPCTime, InterruptsPersec

    $cpuTotal = $cpuPerf.PercentProcessorTime

    # Obtenir l'utilisation par cœur avec détails
    $cpuCoresDetailed = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name!='_Total'" |
        ForEach-Object {
            @{
                CoreID         = $_.Name
                Usage          = $_.PercentProcessorTime
                UserTime       = $_.PercentUserTime
                PrivilegedTime = $_.PercentPrivilegedTime
                InterruptTime  = $_.PercentInterruptTime
            }
        }

    # Obtenir la longueur de la file d'attente du processeur
    $systemPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System
    $queueLength = $systemPerf.ProcessorQueueLength
    $contextSwitchesPersec = $systemPerf.ContextSwitchesPersec
    $systemCallsPersec = $systemPerf.SystemCallsPersec

    # Obtenir les processus les plus consommateurs de CPU
    $allProcesses = Get-Process
    $topProcesses = $allProcesses |
        Sort-Object -Property CPU -Descending |
        Select-Object -First $script:MetricsCollectorConfig.TopProcessCount |
        ForEach-Object {
            @{
                Name       = $_.Name
                ID         = $_.Id
                CPU        = $_.CPU
                WorkingSet = [math]::Round($_.WorkingSet64 / 1MB, 2)  # Convertir en MB
                Threads    = $_.Threads.Count
                Handles    = $_.HandleCount
                StartTime  = if ($_.StartTime) { $_.StartTime } else { Get-Date }
                RunTime    = if ($_.StartTime) { (Get-Date) - $_.StartTime } else { [TimeSpan]::Zero }
            }
        }

    # Détecter les processus problématiques (haute utilisation CPU soutenue)
    $cpuThreshold = 80  # Seuil d'utilisation CPU considéré comme élevé (en %)
    $highCpuProcesses = @()

    # Vérifier si nous avons des données de cache pour comparer
    if ($script:MetricsCache.ContainsKey("CPUProcesses")) {
        $previousProcesses = $script:MetricsCache.CPUProcesses

        foreach ($process in $topProcesses) {
            $previousProcess = $previousProcesses | Where-Object { $_.ID -eq $process.ID } | Select-Object -First 1

            if ($previousProcess -and $process.CPU -gt $cpuThreshold -and $previousProcess.CPU -gt $cpuThreshold) {
                $highCpuProcesses += @{
                    Name     = $process.Name
                    ID       = $process.ID
                    CPU      = $process.CPU
                    Duration = "Soutenue"  # Utilisation élevée sur plusieurs mesures
                }
            } elseif ($process.CPU -gt $cpuThreshold) {
                $highCpuProcesses += @{
                    Name     = $process.Name
                    ID       = $process.ID
                    CPU      = $process.CPU
                    Duration = "Ponctuelle"  # Utilisation élevée sur cette mesure uniquement
                }
            }
        }
    }

    # Mettre à jour le cache des processus
    $script:MetricsCache.CPUProcesses = $topProcesses

    # Obtenir la température du CPU si disponible
    $temperature = $null
    try {
        $temperature = Get-CimInstance -Namespace "root/wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty CurrentTemperature |
            ForEach-Object { ($_ - 2732) / 10 }  # Convertir de dixièmes de Kelvin en Celsius
    } catch {
        # La température n'est pas disponible sur tous les systèmes
        $temperature = 0
    }

    # Calculer le ratio d'utilisation système vs utilisateur
    $userTimeRatio = 0
    $systemTimeRatio = 0

    if ($cpuTotal -gt 0) {
        $userTimeRatio = [math]::Round(($cpuPerf.PercentUserTime / $cpuTotal) * 100, 1)
        $systemTimeRatio = [math]::Round(($cpuPerf.PercentPrivilegedTime / $cpuTotal) * 100, 1)
    }

    # Détecter les anomalies CPU
    $cpuAnomalies = @()

    # Anomalie 1: Trop d'interruptions
    if ($cpuPerf.PercentInterruptTime -gt 10) {
        # Plus de 10% du temps CPU passé en interruptions
        $cpuAnomalies += "Taux d'interruptions élevé ($($cpuPerf.PercentInterruptTime)%)"
    }

    # Anomalie 2: File d'attente trop longue
    if ($queueLength -gt 10) {
        # Plus de 10 processus en attente
        $cpuAnomalies += "File d'attente CPU longue ($queueLength processus)"
    }

    # Anomalie 3: Déséquilibre entre cœurs
    $coreUsages = $cpuCoresDetailed | ForEach-Object { $_.Usage }
    $maxCoreUsage = ($coreUsages | Measure-Object -Maximum).Maximum
    $minCoreUsage = ($coreUsages | Measure-Object -Minimum).Minimum

    if (($maxCoreUsage - $minCoreUsage) -gt 50 -and $cpuTotal -gt 30) {
        # Différence de plus de 50% entre les cœurs
        $cpuAnomalies += "Desequilibre entre coeurs (difference de $($maxCoreUsage - $minCoreUsage)%)"
    }

    return @{
        Info                  = @{
            Name              = $cpuInfo.Name
            Cores             = $cpuInfo.NumberOfCores
            LogicalProcessors = $cpuInfo.NumberOfLogicalProcessors
            MaxClockSpeed     = $cpuInfo.MaxClockSpeed
            CurrentClockSpeed = $cpuInfo.CurrentClockSpeed
        }
        Usage                 = $cpuTotal
        UserTime              = $cpuPerf.PercentUserTime
        SystemTime            = $cpuPerf.PercentPrivilegedTime
        InterruptTime         = $cpuPerf.PercentInterruptTime
        DPCTime               = $cpuPerf.PercentDPCTime
        InterruptsPersec      = $cpuPerf.InterruptsPersec
        ContextSwitchesPersec = $contextSwitchesPersec
        SystemCallsPersec     = $systemCallsPersec
        UsagePerCore          = $cpuCoresDetailed
        QueueLength           = $queueLength
        TopProcesses          = $topProcesses
        HighCpuProcesses      = $highCpuProcesses
        Temperature           = $temperature
        UserTimeRatio         = $userTimeRatio
        SystemTimeRatio       = $systemTimeRatio
        Anomalies             = $cpuAnomalies
    }
}

function Get-MemoryMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques mémoire.
    .DESCRIPTION
        Collecte les métriques détaillées d'utilisation de la mémoire physique et virtuelle, du fichier d'échange,
        des défauts de page, des allocations et des processus les plus consommateurs. Inclut également
        une détection avancée des fuites mémoire et des anomalies.
    .EXAMPLE
        Get-MemoryMetrics
    #>
    [CmdletBinding()]
    param ()

    # Obtenir les informations de mémoire du système
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $memoryInfo = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory
    # $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem  # Non utilisé pour l'instant

    # Obtenir les informations sur le fichier d'échange
    $pageFileInfo = Get-CimInstance -ClassName Win32_PageFileUsage
    # $pageFileStats = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_PagingFile -Filter "Name='_Total'" -ErrorAction SilentlyContinue  # Non utilisé pour l'instant

    # Calculer les métriques de mémoire physique
    $totalPhysicalMemory = $osInfo.TotalVisibleMemorySize / 1KB  # Convertir en MB
    $freePhysicalMemory = $osInfo.FreePhysicalMemory / 1KB       # Convertir en MB
    $usedPhysicalMemory = $totalPhysicalMemory - $freePhysicalMemory
    $physicalMemoryUsagePercent = [math]::Round(($usedPhysicalMemory / $totalPhysicalMemory) * 100, 1)

    # Calculer les métriques de mémoire virtuelle
    $totalVirtualMemory = ($osInfo.TotalVirtualMemorySize) / 1KB  # Convertir en MB
    $freeVirtualMemory = ($osInfo.FreeVirtualMemory) / 1KB        # Convertir en MB
    $usedVirtualMemory = $totalVirtualMemory - $freeVirtualMemory
    $virtualMemoryUsagePercent = [math]::Round(($usedVirtualMemory / $totalVirtualMemory) * 100, 1)

    # Calculer les métriques du fichier d'échange
    $pageFileUsage = @()
    $totalPageFileSize = 0
    $totalPageFileUsed = 0

    foreach ($pageFile in $pageFileInfo) {
        $currentUsage = [math]::Round(($pageFile.CurrentUsage / $pageFile.AllocatedBaseSize) * 100, 1)
        $pageFileUsage += @{
            Name         = $pageFile.Name
            Path         = $pageFile.Caption
            TotalSizeMB  = $pageFile.AllocatedBaseSize
            UsedMB       = $pageFile.CurrentUsage
            UsagePercent = $currentUsage
        }

        $totalPageFileSize += $pageFile.AllocatedBaseSize
        $totalPageFileUsed += $pageFile.CurrentUsage
    }

    $totalPageFileUsagePercent = 0
    if ($totalPageFileSize -gt 0) {
        $totalPageFileUsagePercent = [math]::Round(($totalPageFileUsed / $totalPageFileSize) * 100, 1)
    }

    # Obtenir les métriques de performance mémoire
    $pageFaultsPersec = $memoryInfo.PageFaultsPersec
    $pageReadsPersec = $memoryInfo.PageReadsPersec
    $pageWritesPersec = $memoryInfo.PageWritesPersec
    $pagesInputPersec = $memoryInfo.PagesInputPersec
    $pagesOutputPersec = $memoryInfo.PagesOutputPersec
    $poolNonpagedBytes = $memoryInfo.PoolNonpagedBytes / 1MB  # Convertir en MB
    $poolPagedBytes = $memoryInfo.PoolPagedBytes / 1MB        # Convertir en MB
    $cacheBytes = $memoryInfo.CacheBytes / 1MB                # Convertir en MB
    $commitLimit = $memoryInfo.CommitLimit / 1MB              # Convertir en MB
    $committedBytes = $memoryInfo.CommittedBytes / 1MB        # Convertir en MB
    $commitPercent = 0

    if ($commitLimit -gt 0) {
        $commitPercent = [math]::Round(($committedBytes / $commitLimit) * 100, 1)
    }

    # Obtenir les processus les plus consommateurs de mémoire
    $allProcesses = Get-Process
    $topProcesses = $allProcesses |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First $script:MetricsCollectorConfig.TopProcessCount |
        ForEach-Object {
            $privateBytes = 0
            try {
                $privateBytes = $_.PrivateMemorySize64 / 1MB  # Convertir en MB
            } catch {
                # Ignorer les erreurs
            }

            @{
                Name                   = $_.Name
                ID                     = $_.Id
                WorkingSetMB           = [math]::Round($_.WorkingSet64 / 1MB, 2)  # Convertir en MB
                PrivateBytesMB         = [math]::Round($privateBytes, 2)
                VirtualMemoryMB        = [math]::Round($_.VirtualMemorySize64 / 1MB, 2)  # Convertir en MB
                PagedMemoryMB          = [math]::Round($_.PagedMemorySize64 / 1MB, 2)  # Convertir en MB
                PagedSystemMemoryMB    = [math]::Round($_.PagedSystemMemorySize64 / 1MB, 2)  # Convertir en MB
                NonPagedSystemMemoryMB = [math]::Round($_.NonpagedSystemMemorySize64 / 1MB, 2)  # Convertir en MB
                Threads                = $_.Threads.Count
                Handles                = $_.HandleCount
                StartTime              = if ($_.StartTime) { $_.StartTime } else { Get-Date }
                CPU                    = $_.CPU
            }
        }

    # Détecter les fuites mémoire potentielles (analyse avancée)
    $leakDetected = $false
    $leakSuspects = @()
    $memoryGrowth = 0

    if ($script:MetricsCache.ContainsKey("Memory")) {
        $previousMemory = $script:MetricsCache.Memory
        $memoryGrowth = $physicalMemoryUsagePercent - $previousMemory.Usage
        $timeElapsed = (Get-Date) - $previousMemory.Timestamp

        # Détection basée sur la croissance de la mémoire physique
        if ($memoryGrowth -gt 5 -and $previousMemory.Growth -gt 5) {
            $leakDetected = $true

            # Identifier les processus suspects (ceux dont la mémoire augmente constamment)
            if ($script:MetricsCache.ContainsKey("MemoryProcesses")) {
                $previousProcesses = $script:MetricsCache.MemoryProcesses

                foreach ($process in $topProcesses) {
                    $previousProcess = $previousProcesses | Where-Object { $_.ID -eq $process.ID } | Select-Object -First 1

                    if ($previousProcess) {
                        $processGrowth = $process.WorkingSetMB - $previousProcess.WorkingSetMB
                        $growthRate = 0

                        if ($timeElapsed.TotalMinutes -gt 0) {
                            $growthRate = $processGrowth / $timeElapsed.TotalMinutes  # MB par minute
                        }

                        if ($processGrowth -gt 10 -and $growthRate -gt 2) {
                            # Plus de 10 MB et 2 MB/min
                            $leakSuspects += @{
                                Name               = $process.Name
                                ID                 = $process.ID
                                CurrentMemoryMB    = $process.WorkingSetMB
                                GrowthMB           = [math]::Round($processGrowth, 2)
                                GrowthRateMBPerMin = [math]::Round($growthRate, 2)
                            }
                        }
                    }
                }
            }
        }

        # Mettre à jour le cache
        $script:MetricsCache.Memory = @{
            Usage     = $physicalMemoryUsagePercent
            Growth    = $memoryGrowth
            Timestamp = Get-Date
        }
    } else {
        # Initialiser le cache
        $script:MetricsCache.Memory = @{
            Usage     = $physicalMemoryUsagePercent
            Growth    = 0
            Timestamp = Get-Date
        }
    }

    # Mettre à jour le cache des processus
    $script:MetricsCache.MemoryProcesses = $topProcesses

    # Détecter les anomalies mémoire
    $memoryAnomalies = @()

    # Anomalie 1: Utilisation élevée de la mémoire physique
    if ($physicalMemoryUsagePercent -gt 90) {
        $memoryAnomalies += "Utilisation elevee de la memoire physique ($physicalMemoryUsagePercent%)"
    }

    # Anomalie 2: Utilisation élevée du fichier d'échange
    if ($totalPageFileUsagePercent -gt 80) {
        $memoryAnomalies += "Utilisation elevee du fichier d'echange ($totalPageFileUsagePercent%)"
    }

    # Anomalie 3: Taux élevé de défauts de page
    if ($pageFaultsPersec -gt 1000) {
        $memoryAnomalies += "Taux eleve de defauts de page ($pageFaultsPersec par seconde)"
    }

    # Anomalie 4: Taux élevé d'E/S de pagination
    if (($pagesInputPersec + $pagesOutputPersec) -gt 50) {
        $memoryAnomalies += "Taux eleve d'E/S de pagination ($(($pagesInputPersec + $pagesOutputPersec)) pages par seconde)"
    }

    # Anomalie 5: Engagement mémoire élevé
    if ($commitPercent -gt 90) {
        $memoryAnomalies += "Engagement memoire eleve ($commitPercent%)"
    }

    # Anomalie 6: Fuite mémoire détectée
    if ($leakDetected) {
        $memoryAnomalies += "Fuite memoire potentielle detectee (croissance de $memoryGrowth% depuis la derniere mesure)"
    }

    return @{
        Physical      = @{
            TotalMB      = [math]::Round($totalPhysicalMemory, 2)
            AvailableMB  = [math]::Round($freePhysicalMemory, 2)
            UsedMB       = [math]::Round($usedPhysicalMemory, 2)
            UsagePercent = $physicalMemoryUsagePercent
        }
        Virtual       = @{
            TotalMB      = [math]::Round($totalVirtualMemory, 2)
            AvailableMB  = [math]::Round($freeVirtualMemory, 2)
            UsedMB       = [math]::Round($usedVirtualMemory, 2)
            UsagePercent = $virtualMemoryUsagePercent
        }
        PageFile      = @{
            Details      = $pageFileUsage
            TotalMB      = $totalPageFileSize
            UsedMB       = $totalPageFileUsed
            UsagePercent = $totalPageFileUsagePercent
        }
        Performance   = @{
            PageFaultsPersec  = $pageFaultsPersec
            PageReadsPersec   = $pageReadsPersec
            PageWritesPersec  = $pageWritesPersec
            PagesInputPersec  = $pagesInputPersec
            PagesOutputPersec = $pagesOutputPersec
            PoolNonpagedMB    = [math]::Round($poolNonpagedBytes, 2)
            PoolPagedMB       = [math]::Round($poolPagedBytes, 2)
            CacheMB           = [math]::Round($cacheBytes, 2)
            CommitLimitMB     = [math]::Round($commitLimit, 2)
            CommittedBytesMB  = [math]::Round($committedBytes, 2)
            CommitPercent     = $commitPercent
        }
        TopProcesses  = $topProcesses
        LeakDetection = @{
            LeakDetected = $leakDetected
            LeakSuspects = $leakSuspects
            MemoryGrowth = $memoryGrowth
        }
        Anomalies     = $memoryAnomalies
    }
}

function Get-DiskMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques disque.
    .DESCRIPTION
        Collecte les métriques détaillées d'utilisation du disque, les opérations d'E/S, la longueur de la file d'attente,
        les processus les plus actifs, la fragmentation, la santé du disque et les alertes d'espace disque faible.
    .EXAMPLE
        Get-DiskMetrics
    #>
    [CmdletBinding()]
    param ()

    # Obtenir les informations sur les disques physiques
    $physicalDisks = Get-CimInstance -ClassName Win32_DiskDrive |
        Select-Object DeviceID, Model, Size, MediaType, SerialNumber, Status, StatusInfo

    # Obtenir les performances des disques physiques
    $physicalDiskPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk |
        Where-Object { $_.Name -ne "_Total" } |
        Select-Object Name, PercentDiskTime, AvgDiskQueueLength, AvgDiskSecPerRead, AvgDiskSecPerWrite

    # Obtenir l'utilisation de l'espace disque
    $logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        ForEach-Object {
            $usedSpace = $_.Size - $_.FreeSpace
            $usagePercent = [math]::Round(($usedSpace / $_.Size) * 100, 1)
            $lowSpaceThreshold = 10  # Alerte si moins de 10% d'espace libre
            $criticalSpaceThreshold = 5  # Alerte critique si moins de 5% d'espace libre

            $spaceStatus = "Normal"
            if ((100 - $usagePercent) -lt $criticalSpaceThreshold) {
                $spaceStatus = "Critique"
            } elseif ((100 - $usagePercent) -lt $lowSpaceThreshold) {
                $spaceStatus = "Faible"
            }

            @{
                Drive       = $_.DeviceID
                VolumeName  = $_.VolumeName
                FileSystem  = $_.FileSystem
                Size        = [math]::Round($_.Size / 1GB, 2)  # Convertir en GB
                FreeSpace   = [math]::Round($_.FreeSpace / 1GB, 2)  # Convertir en GB
                UsedSpace   = [math]::Round($usedSpace / 1GB, 2)  # Convertir en GB
                Usage       = $usagePercent
                SpaceStatus = $spaceStatus
            }
        }

    # Calculer l'utilisation moyenne
    $avgUsage = 0
    if ($logicalDisks.Count -gt 0) {
        $usageValues = $logicalDisks | ForEach-Object { $_.Usage }
        $avgUsage = [math]::Round(($usageValues | Measure-Object -Average).Average, 1)
    }

    # Obtenir les performances des disques logiques
    $logicalDiskPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_LogicalDisk |
        Where-Object { $_.Name -ne "_Total" } |
        ForEach-Object {
            @{
                Drive                  = $_.Name
                DiskReadBytesPersec    = [math]::Round($_.DiskReadBytesPersec / 1MB, 2)  # Convertir en MB/s
                DiskWriteBytesPersec   = [math]::Round($_.DiskWriteBytesPersec / 1MB, 2)  # Convertir en MB/s
                DiskReadsPersec        = $_.DiskReadsPersec
                DiskWritesPersec       = $_.DiskWritesPersec
                SplitIOPerSec          = $_.SplitIOPerSec
                CurrentDiskQueueLength = $_.CurrentDiskQueueLength
                AvgDiskSecPerTransfer  = [math]::Round($_.AvgDiskSecPerTransfer * 1000, 1)  # Convertir en ms
            }
        }

    # Obtenir les performances globales du disque
    $totalDiskPerf = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_LogicalDisk -Filter "Name='_Total'" |
        Select-Object DiskReadBytesPersec, DiskWriteBytesPersec, CurrentDiskQueueLength, AvgDiskSecPerTransfer,
        DiskReadsPersec, DiskWritesPersec, SplitIOPerSec

    # Calculer les IOPS (opérations d'E/S par seconde)
    $iops = $totalDiskPerf.DiskReadsPersec + $totalDiskPerf.DiskWritesPersec

    # Obtenir le temps de réponse moyen en millisecondes
    $responseTime = [math]::Round($totalDiskPerf.AvgDiskSecPerTransfer * 1000, 1)

    # Obtenir les processus avec le plus d'activité disque
    $topProcesses = Get-Process |
        Sort-Object -Property IO -Descending |
        Select-Object -First $script:MetricsCollectorConfig.TopProcessCount |
        ForEach-Object {
            @{
                Name    = $_.Name
                ID      = $_.Id
                IO      = [math]::Round($_.IO / 1KB, 2)  # Convertir en KB
                IORate  = if ($_.StartTime) {
                    $uptime = (Get-Date) - $_.StartTime
                    if ($uptime.TotalSeconds -gt 0) {
                        [math]::Round(($_.IO / 1KB) / $uptime.TotalSeconds, 2)  # KB/s
                    } else { 0 }
                } else { 0 }
                Threads = $_.Threads.Count
                Handles = $_.HandleCount
            }
        }

    # Obtenir des informations sur la fragmentation (nécessite des privilèges élevés)
    $fragmentation = @{}
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.FileSystemType -eq 'NTFS' }
        foreach ($volume in $volumes) {
            $defragAnalysis = $null
            try {
                # Cette commande nécessite des privilèges élevés
                $defragAnalysis = Optimize-Volume -DriveLetter $volume.DriveLetter -Analyze -Verbose:$false -ErrorAction SilentlyContinue
            } catch {
                # Ignorer les erreurs
            }

            if ($defragAnalysis) {
                $fragmentation[$volume.DriveLetter] = @{
                    FragmentationPercent = $defragAnalysis.DefragAnalysis.FragmentationPercent
                    RecommendedAction    = $defragAnalysis.DefragAnalysis.RecommendedAction
                }
            } else {
                # Fallback: utiliser une estimation basée sur l'utilisation du disque
                $diskUsage = $logicalDisks | Where-Object { $_.Drive -eq "$($volume.DriveLetter):" } | Select-Object -First 1
                if ($diskUsage) {
                    $estimatedFragmentation = [math]::Min(90, [math]::Round($diskUsage.Usage * 0.8, 0))  # Estimation simpliste
                    $fragmentation[$volume.DriveLetter] = @{
                        FragmentationPercent = $estimatedFragmentation
                        RecommendedAction    = if ($estimatedFragmentation -gt 30) { "Defragment" } else { "None" }
                        IsEstimated          = $true
                    }
                }
            }
        }
    } catch {
        Write-Verbose "Impossible d'obtenir les informations de fragmentation: $_"
    }

    # Vérifier la santé des disques (SMART)
    $diskHealth = @{}
    try {
        # Utiliser PowerShell pour obtenir les informations SMART (nécessite des privilèges élevés)
        $smartData = Get-CimInstance -Namespace "root\wmi" -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue

        if ($smartData) {
            foreach ($disk in $smartData) {
                $diskIndex = $disk.InstanceName.Split('#')[1].Split('&')[0]
                $predictFailure = $disk.PredictFailure
                $reason = $disk.Reason

                $diskHealth[$diskIndex] = @{
                    PredictFailure = $predictFailure
                    Reason         = $reason
                    Status         = if ($predictFailure) { "Warning" } else { "Healthy" }
                }
            }
        } else {
            # Fallback: utiliser l'attribut Status des disques physiques
            foreach ($disk in $physicalDisks) {
                $diskIndex = $disk.DeviceID.Split('\\')[-1]
                $diskHealth[$diskIndex] = @{
                    Status         = switch ($disk.Status) {
                        "OK" { "Healthy" }
                        "Degraded" { "Warning" }
                        "Error" { "Critical" }
                        default { "Unknown" }
                    }
                    PredictFailure = $disk.Status -ne "OK"
                    Reason         = $disk.StatusInfo
                }
            }
        }
    } catch {
        Write-Verbose "Impossible d'obtenir les informations de santé des disques: $_"
    }

    # Détecter les anomalies disque
    $diskAnomalies = @()

    # Anomalie 1: Espace disque faible
    $lowSpaceDisks = $logicalDisks | Where-Object { $_.SpaceStatus -ne "Normal" }
    foreach ($disk in $lowSpaceDisks) {
        $diskAnomalies += "Espace disque $($disk.SpaceStatus.ToLower()) sur $($disk.Drive) ($([math]::Round(100 - $disk.Usage, 1))% libre)"
    }

    # Anomalie 2: File d'attente disque longue
    if ($totalDiskPerf.CurrentDiskQueueLength -gt 2) {
        $diskAnomalies += "File d'attente disque longue ($($totalDiskPerf.CurrentDiskQueueLength) requetes)"
    }

    # Anomalie 3: Temps de réponse disque élevé
    if ($responseTime -gt 25) {
        # Plus de 25ms est considéré comme lent
        $diskAnomalies += "Temps de reponse disque eleve ($responseTime ms)"
    }

    # Anomalie 4: Fragmentation élevée
    foreach ($drive in $fragmentation.Keys) {
        if ($fragmentation[$drive].FragmentationPercent -gt 30) {
            $diskAnomalies += "Fragmentation elevee sur le lecteur $drive ($($fragmentation[$drive].FragmentationPercent)%)"
        }
    }

    # Anomalie 5: Problème de santé disque
    foreach ($disk in $diskHealth.Keys) {
        if ($diskHealth[$disk].Status -ne "Healthy") {
            $diskAnomalies += "Probleme de sante detecte sur le disque $disk ($($diskHealth[$disk].Status))"
        }
    }

    return @{
        LogicalDisks  = $logicalDisks
        PhysicalDisks = $physicalDisks | ForEach-Object {
            $diskIndex = $_.DeviceID.Split('\\')[-1]
            @{
                Index        = $diskIndex
                Model        = $_.Model
                SizeGB       = [math]::Round($_.Size / 1GB, 2)
                MediaType    = $_.MediaType
                SerialNumber = $_.SerialNumber
                Status       = $_.Status
                Health       = if ($diskHealth.ContainsKey($diskIndex)) { $diskHealth[$diskIndex] } else { @{ Status = "Unknown" } }
            }
        }
        Performance   = @{
            LogicalDisks  = $logicalDiskPerf
            PhysicalDisks = $physicalDiskPerf | ForEach-Object {
                @{
                    Name            = $_.Name
                    PercentDiskTime = $_.PercentDiskTime
                    QueueLength     = $_.AvgDiskQueueLength
                    ReadLatencyMS   = [math]::Round($_.AvgDiskSecPerRead * 1000, 1)
                    WriteLatencyMS  = [math]::Round($_.AvgDiskSecPerWrite * 1000, 1)
                }
            }
            Total         = @{
                ReadMBPerSec   = [math]::Round($totalDiskPerf.DiskReadBytesPersec / 1MB, 2)
                WriteMBPerSec  = [math]::Round($totalDiskPerf.DiskWriteBytesPersec / 1MB, 2)
                ReadIOPS       = $totalDiskPerf.DiskReadsPersec
                WriteIOPS      = $totalDiskPerf.DiskWritesPersec
                TotalIOPS      = $iops
                QueueLength    = $totalDiskPerf.CurrentDiskQueueLength
                ResponseTimeMS = $responseTime
                SplitIOPerSec  = $totalDiskPerf.SplitIOPerSec
            }
        }
        Usage         = @{
            Average = $avgUsage
            ByDrive = $logicalDisks | ForEach-Object { @{ Drive = $_.Drive; Usage = $_.Usage } }
        }
        Fragmentation = $fragmentation
        TopProcesses  = $topProcesses
        Anomalies     = $diskAnomalies
    }
}

function Get-NetworkMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques réseau.
    .DESCRIPTION
        Collecte les métriques détaillées d'utilisation de la bande passante, le débit, la latence, les connexions actives,
        les erreurs, la qualité de la connexion et la détection des problèmes réseau.
    .EXAMPLE
        Get-NetworkMetrics
    #>
    [CmdletBinding()]
    param ()

    # Obtenir les informations sur les adaptateurs réseau
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter |
        Where-Object { $_.NetConnectionStatus -eq 2 } | # 2 = Connecté
        Select-Object DeviceID, Name, AdapterType, MACAddress, Speed, NetConnectionStatus

    # Obtenir les configurations IP des adaptateurs
    $networkConfigs = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled -eq $true } |
        Select-Object Index, Description, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder, DHCPEnabled, DHCPServer

    # Obtenir les performances réseau
    $networkInterfaces = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface |
        ForEach-Object {
            $bandwidthUsage = 0
            if ($_.CurrentBandwidth -gt 0) {
                $bandwidthUsage = [math]::Round(($_.BytesTotalPersec / ($_.CurrentBandwidth / 8)) * 100, 1)
            }

            @{
                Name                   = $_.Name
                BytesReceivedPerSec    = [math]::Round($_.BytesReceivedPersec / 1MB, 2)  # Convertir en MB/s
                BytesSentPerSec        = [math]::Round($_.BytesSentPersec / 1MB, 2)  # Convertir en MB/s
                BytesTotalPerSec       = [math]::Round($_.BytesTotalPersec / 1MB, 2)  # Convertir en MB/s
                PacketsReceivedPerSec  = $_.PacketsReceivedPersec
                PacketsSentPerSec      = $_.PacketsSentPersec
                Bandwidth              = [math]::Round($_.CurrentBandwidth / 1MB, 2)  # Convertir en Mbps
                BandwidthUsage         = $bandwidthUsage
                ErrorsReceivedPerSec   = $_.PacketsReceivedErrorsPersec
                ErrorsSentPerSec       = $_.PacketsOutboundErrorsPersec
                TotalErrorsPerSec      = $_.PacketsReceivedErrorsPersec + $_.PacketsOutboundErrorsPersec
                DiscardedPacketsPerSec = $_.PacketsReceivedDiscardedPersec + $_.PacketsOutboundDiscardedPersec
                OutputQueueLength      = $_.OutputQueueLength
            }
        }

    # Obtenir les statistiques TCP/IP
    $tcpStats = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_TCPv4 |
        Select-Object ConnectionFailures, ConnectionsActive, ConnectionsEstablished, ConnectionsPassive,
        ConnectionsReset, SegmentsReceivedPersec, SegmentsRetransmittedPersec, SegmentsSentPersec

    $udpStats = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_UDPv4 |
        Select-Object DatagramsPersec, DatagramsReceivedErrors, DatagramsReceivedPersec, DatagramsSentPersec

    # Calculer l'utilisation moyenne de la bande passante
    $avgBandwidthUsage = 0
    if ($networkInterfaces.Count -gt 0) {
        $bandwidthUsageValues = $networkInterfaces | ForEach-Object { $_.BandwidthUsage }
        $avgBandwidthUsage = [math]::Round(($bandwidthUsageValues | Measure-Object -Average).Average, 1)
    }

    # Calculer le débit moyen
    $avgThroughputIn = 0
    $avgThroughputOut = 0
    if ($networkInterfaces.Count -gt 0) {
        $bytesReceivedValues = $networkInterfaces | ForEach-Object { $_.BytesReceivedPerSec }
        $bytesSentValues = $networkInterfaces | ForEach-Object { $_.BytesSentPerSec }
        $avgThroughputIn = [math]::Round(($bytesReceivedValues | Measure-Object -Average).Average, 2)
        $avgThroughputOut = [math]::Round(($bytesSentValues | Measure-Object -Average).Average, 2)
    }

    # Mesurer la latence vers plusieurs destinations
    $pingTargets = @(
        @{ Name = "Google DNS"; Address = "8.8.8.8" },
        @{ Name = "Cloudflare DNS"; Address = "1.1.1.1" },
        @{ Name = "Local Gateway"; Address = ($networkConfigs | Select-Object -First 1).DefaultIPGateway }
    )

    $pingResults = @{}
    foreach ($target in $pingTargets) {
        if ($null -ne $target.Address) {
            try {
                $pingResult = Test-Connection -ComputerName $target.Address -Count 3 -ErrorAction SilentlyContinue
                if ($pingResult) {
                    $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
                    $minLatency = ($pingResult | Measure-Object -Property ResponseTime -Minimum).Minimum
                    $maxLatency = ($pingResult | Measure-Object -Property ResponseTime -Maximum).Maximum
                    $packetLoss = 100 - (($pingResult.Count / 3) * 100)

                    $pingResults[$target.Name] = @{
                        Address    = $target.Address
                        AvgLatency = [math]::Round($avgLatency, 1)
                        MinLatency = $minLatency
                        MaxLatency = $maxLatency
                        PacketLoss = $packetLoss
                        Jitter     = [math]::Round($maxLatency - $minLatency, 1)
                        Status     = if ($packetLoss -lt 100) { "Accessible" } else { "Inaccessible" }
                    }
                } else {
                    $pingResults[$target.Name] = @{
                        Address    = $target.Address
                        Status     = "Inaccessible"
                        PacketLoss = 100
                    }
                }
            } catch {
                $pingResults[$target.Name] = @{
                    Address = $target.Address
                    Status  = "Erreur"
                    Error   = $_.Exception.Message
                }
            }
        }
    }

    # Évaluer la qualité de la connexion Internet
    $internetQuality = "Inconnue"
    $internetQualityScore = 0
    $internetQualityDetails = @{}

    if ($pingResults.ContainsKey("Google DNS") -and $pingResults["Google DNS"].Status -eq "Accessible") {
        $latency = $pingResults["Google DNS"].AvgLatency
        $packetLoss = $pingResults["Google DNS"].PacketLoss
        $jitter = $pingResults["Google DNS"].Jitter

        # Calcul du score (0-100)
        $latencyScore = if ($latency -lt 10) { 40 } elseif ($latency -lt 50) { 30 } elseif ($latency -lt 100) { 20 } elseif ($latency -lt 200) { 10 } else { 0 }
        $packetLossScore = if ($packetLoss -eq 0) { 40 } elseif ($packetLoss -lt 5) { 30 } elseif ($packetLoss -lt 10) { 20 } elseif ($packetLoss -lt 20) { 10 } else { 0 }
        $jitterScore = if ($jitter -lt 5) { 20 } elseif ($jitter -lt 20) { 15 } elseif ($jitter -lt 50) { 10 } elseif ($jitter -lt 100) { 5 } else { 0 }

        $internetQualityScore = $latencyScore + $packetLossScore + $jitterScore

        $internetQuality = if ($internetQualityScore -ge 90) { "Excellente" }
        elseif ($internetQualityScore -ge 70) { "Bonne" }
        elseif ($internetQualityScore -ge 50) { "Moyenne" }
        elseif ($internetQualityScore -ge 30) { "Médiocre" }
        else { "Mauvaise" }

        $internetQualityDetails = @{
            Score           = $internetQualityScore
            LatencyScore    = $latencyScore
            PacketLossScore = $packetLossScore
            JitterScore     = $jitterScore
            Latency         = $latency
            PacketLoss      = $packetLoss
            Jitter          = $jitter
        }
    }

    # Obtenir les connexions TCP actives
    $tcpConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue |
        Group-Object -Property State |
        ForEach-Object {
            @{
                State = $_.Name
                Count = $_.Count
            }
        }

    # Obtenir les connexions par processus
    $connectionsByProcess = @{}
    try {
        $netstat = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
            Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess

        foreach ($conn in $netstat) {
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                $processName = if ($process) { $process.Name } else { "Unknown" }

                if (-not $connectionsByProcess.ContainsKey($processName)) {
                    $connectionsByProcess[$processName] = 0
                }

                $connectionsByProcess[$processName]++
            } catch {
                # Ignorer les erreurs
            }
        }
    } catch {
        # Ignorer les erreurs
    }

    # Calculer le taux d'erreurs
    $totalErrors = 0
    $totalPackets = 0

    if ($networkInterfaces.Count -gt 0) {
        $totalErrorsValues = $networkInterfaces | ForEach-Object { $_.TotalErrorsPerSec }
        $totalErrors = ($totalErrorsValues | Measure-Object -Sum).Sum

        $packetsReceivedValues = $networkInterfaces | ForEach-Object { $_.PacketsReceivedPerSec }
        $packetsSentValues = $networkInterfaces | ForEach-Object { $_.PacketsSentPerSec }
        $totalPacketsReceived = ($packetsReceivedValues | Measure-Object -Sum).Sum
        $totalPacketsSent = ($packetsSentValues | Measure-Object -Sum).Sum
        $totalPackets = $totalPacketsReceived + $totalPacketsSent
    }

    $errorRate = 0
    if ($totalPackets -gt 0) {
        $errorRate = [math]::Round(($totalErrors / $totalPackets) * 100, 3)
    }

    # Détecter les anomalies réseau
    $networkAnomalies = @()

    # Anomalie 1: Taux d'erreurs élevé
    if ($errorRate -gt 1) {
        # Plus de 1% d'erreurs est considéré comme élevé
        $networkAnomalies += "Taux d'erreurs reseau eleve ($errorRate%)"
    }

    # Anomalie 2: Latence élevée
    if ($pingResults.ContainsKey("Google DNS") -and $pingResults["Google DNS"].Status -eq "Accessible" -and $pingResults["Google DNS"].AvgLatency -gt 100) {
        $networkAnomalies += "Latence Internet elevee ($($pingResults["Google DNS"].AvgLatency) ms)"
    }

    # Anomalie 3: Perte de paquets
    if ($pingResults.ContainsKey("Google DNS") -and $pingResults["Google DNS"].Status -eq "Accessible" -and $pingResults["Google DNS"].PacketLoss -gt 0) {
        $networkAnomalies += "Perte de paquets detectee ($($pingResults["Google DNS"].PacketLoss)%)"
    }

    # Anomalie 4: Jitter élevé
    if ($pingResults.ContainsKey("Google DNS") -and $pingResults["Google DNS"].Status -eq "Accessible" -and $pingResults["Google DNS"].Jitter -gt 50) {
        $networkAnomalies += "Jitter eleve ($($pingResults["Google DNS"].Jitter) ms)"
    }

    # Anomalie 5: Saturation de la bande passante
    if ($avgBandwidthUsage -gt 80) {
        # Plus de 80% d'utilisation est considéré comme une saturation
        $networkAnomalies += "Saturation de la bande passante ($avgBandwidthUsage%)"
    }

    # Anomalie 6: Nombre élevé de connexions
    $establishedConnections = ($tcpConnections | Where-Object { $_.State -eq "Established" } | Select-Object -First 1).Count
    if ($establishedConnections -gt 1000) {
        # Plus de 1000 connexions est considéré comme élevé
        $networkAnomalies += "Nombre eleve de connexions TCP ($establishedConnections)"
    }

    # Anomalie 7: Problème de connectivité Internet
    if ($pingResults.ContainsKey("Google DNS") -and $pingResults["Google DNS"].Status -ne "Accessible" -and
        $pingResults.ContainsKey("Cloudflare DNS") -and $pingResults["Cloudflare DNS"].Status -ne "Accessible") {
        $networkAnomalies += "Probleme de connectivite Internet detecte"
    }

    # Anomalie 8: Problème de connectivité locale
    if ($pingResults.ContainsKey("Local Gateway") -and $pingResults["Local Gateway"].Status -ne "Accessible") {
        $networkAnomalies += "Probleme de connectivite locale detecte (passerelle inaccessible)"
    }

    return @{
        Adapters     = $networkAdapters | ForEach-Object {
            $adapterConfig = $networkConfigs | Where-Object { $_.Index -eq $_.DeviceID } | Select-Object -First 1
            @{
                ID          = $_.DeviceID
                Name        = $_.Name
                Type        = $_.AdapterType
                MAC         = $_.MACAddress
                SpeedMbps   = [math]::Round($_.Speed / 1000000, 0)  # Convertir en Mbps
                Status      = switch ($_.NetConnectionStatus) {
                    0 { "Déconnecté" }
                    1 { "En cours de connexion" }
                    2 { "Connecté" }
                    3 { "En cours de déconnexion" }
                    4 { "Matériel non présent" }
                    5 { "Matériel désactivé" }
                    6 { "Matériel défaillant" }
                    7 { "Média déconnecté" }
                    8 { "Authentification" }
                    9 { "Authentification et média" }
                    10 { "Configuration automatique" }
                    11 { "Média connecté" }
                    12 { "Média en pause" }
                    default { "Inconnu" }
                }
                IPAddresses = $adapterConfig.IPAddress
                Subnet      = $adapterConfig.IPSubnet
                Gateway     = $adapterConfig.DefaultIPGateway
                DNSServers  = $adapterConfig.DNSServerSearchOrder
                DHCPEnabled = $adapterConfig.DHCPEnabled
                DHCPServer  = $adapterConfig.DHCPServer
            }
        }
        Interfaces   = $networkInterfaces
        Usage        = @{
            BandwidthUsage = $avgBandwidthUsage
            Throughput     = @{
                In    = $avgThroughputIn
                Out   = $avgThroughputOut
                Total = $avgThroughputIn + $avgThroughputOut
            }
        }
        Connectivity = @{
            PingResults     = $pingResults
            InternetQuality = @{
                Rating  = $internetQuality
                Score   = $internetQualityScore
                Details = $internetQualityDetails
            }
        }
        Connections  = @{
            TCP      = @{
                ByState   = $tcpConnections
                ByProcess = $connectionsByProcess.GetEnumerator() | ForEach-Object {
                    @{
                        Process = $_.Key
                        Count   = $_.Value
                    }
                } | Sort-Object -Property Count -Descending
                Total     = ($tcpConnections | Measure-Object -Property Count -Sum).Sum
            }
            TCPStats = $tcpStats
            UDPStats = $udpStats
        }
        Performance  = @{
            ErrorRate        = $errorRate
            TotalErrors      = $totalErrors
            TotalPackets     = $totalPackets
            DiscardedPackets = if ($networkInterfaces.Count -gt 0) {
                $discardedPacketsValues = $networkInterfaces | ForEach-Object { $_.DiscardedPacketsPerSec }
                ($discardedPacketsValues | Measure-Object -Sum).Sum
            } else { 0 }
        }
        Anomalies    = $networkAnomalies
    }
}

function Get-ApplicationMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques applicatives.
    .DESCRIPTION
        Collecte les métriques d'exécution des scripts, des fonctions, des API, le taux d'erreurs et les opérations concurrentes.
    .EXAMPLE
        Get-ApplicationMetrics
    #>
    [CmdletBinding()]
    param ()

    # Cette fonction est un placeholder pour l'instant
    # Dans une implémentation réelle, elle collecterait des métriques spécifiques à l'application

    return @{
        ScriptExecutionTime   = @{}
        FunctionExecutionTime = @{}
        APIResponseTime       = @{}
        ErrorRate             = 0
        ConcurrentOperations  = 0
    }
}

function Get-CollectedMetrics {
    <#
    .SYNOPSIS
        Récupère les métriques collectées.
    .DESCRIPTION
        Récupère les métriques collectées à partir du stockage.
    .PARAMETER TimeRange
        Plage de temps pour laquelle récupérer les métriques.
    .PARAMETER MetricType
        Type de métrique à récupérer (CPU, Memory, Disk, Network, Application).
    .PARAMETER OutputFormat
        Format de sortie des métriques (Object, CSV, JSON).
    .EXAMPLE
        Get-CollectedMetrics -TimeRange "Last1Hour" -MetricType "CPU" -OutputFormat "JSON"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Last1Hour", "Last24Hours", "Last7Days", "All")]
        [string]$TimeRange = "Last1Hour",

        [Parameter(Mandatory = $false)]
        [ValidateSet("CPU", "Memory", "Disk", "Network", "Application", "All")]
        [string]$MetricType = "All",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "CSV", "JSON")]
        [string]$OutputFormat = "Object"
    )

    # Vérifier si le répertoire de stockage existe
    if (-not (Test-Path -Path $script:MetricsCollectorConfig.StoragePath)) {
        Write-Warning "Le répertoire de stockage n'existe pas: $($script:MetricsCollectorConfig.StoragePath)"
        return $null
    }

    # Déterminer la date de début en fonction de la plage de temps
    $startDate = switch ($TimeRange) {
        "Last1Hour" { (Get-Date).AddHours(-1) }
        "Last24Hours" { (Get-Date).AddHours(-24) }
        "Last7Days" { (Get-Date).AddDays(-7) }
        "All" { [DateTime]::MinValue }
    }

    # Récupérer les fichiers de métriques
    $metricFiles = Get-ChildItem -Path $script:MetricsCollectorConfig.StoragePath -Filter "metrics_*.json" |
        Where-Object { $_.LastWriteTime -ge $startDate } |
        Sort-Object LastWriteTime

    if ($metricFiles.Count -eq 0) {
        Write-Warning "Aucune métrique trouvée pour la plage de temps spécifiée."
        return $null
    }

    # Charger et filtrer les métriques
    $metrics = @()
    foreach ($file in $metricFiles) {
        $metricData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

        # Filtrer par type de métrique
        if ($MetricType -ne "All") {
            $filteredData = [PSCustomObject]@{
                Timestamp = $metricData.Timestamp
            }

            if ($metricData.PSObject.Properties.Name -contains $MetricType) {
                Add-Member -InputObject $filteredData -MemberType NoteProperty -Name $MetricType -Value $metricData.$MetricType
            }

            $metrics += $filteredData
        } else {
            $metrics += $metricData
        }
    }

    # Formater la sortie
    switch ($OutputFormat) {
        "CSV" {
            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.csv'
            $metrics | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $tempFile -Encoding utf8
            return $tempFile
        }
        "JSON" {
            return $metrics | ConvertTo-Json -Depth 10
        }
        default {
            return $metrics
        }
    }
}

function Get-SystemMetrics {
    <#
    .SYNOPSIS
        Collecte toutes les metriques systeme.
    .DESCRIPTION
        Collecte les metriques CPU, memoire, disque et reseau, ainsi que les informations generales sur le systeme.
    .EXAMPLE
        Get-SystemMetrics
    #>
    [CmdletBinding()]
    param ()

    # Obtenir les informations systeme
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $bios = Get-CimInstance -ClassName Win32_BIOS

    # Collecter toutes les metriques
    $cpuMetrics = Get-CPUMetrics
    $memoryMetrics = Get-MemoryMetrics
    $diskMetrics = Get-DiskMetrics
    $networkMetrics = Get-NetworkMetrics

    # Construire l'objet de metriques systeme
    return @{
        Timestamp = Get-Date
        System    = @{
            ComputerName    = $computerSystem.Name
            Manufacturer    = $computerSystem.Manufacturer
            Model           = $computerSystem.Model
            OperatingSystem = $operatingSystem.Caption
            OSVersion       = $operatingSystem.Version
            OSBuild         = $operatingSystem.BuildNumber
            OSArchitecture  = $operatingSystem.OSArchitecture
            ProcessorName   = $processor.Name
            BIOSVersion     = $bios.SMBIOSBIOSVersion
            LastBootUpTime  = $operatingSystem.LastBootUpTime
            Uptime          = (Get-Date) - $operatingSystem.LastBootUpTime
        }
        CPU       = $cpuMetrics
        Memory    = $memoryMetrics
        Disk      = $diskMetrics
        Network   = $networkMetrics
        Anomalies = @{
            CPU     = $cpuMetrics.Anomalies
            Memory  = $memoryMetrics.Anomalies
            Disk    = $diskMetrics.Anomalies
            Network = $networkMetrics.Anomalies
            Total   = ($cpuMetrics.Anomalies.Count + $memoryMetrics.Anomalies.Count + $diskMetrics.Anomalies.Count + $networkMetrics.Anomalies.Count)
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-MetricsCollector, Start-MetricsCollection, Stop-MetricsCollection, Get-CPUMetrics, Get-MemoryMetrics, Get-DiskMetrics, Get-NetworkMetrics, Get-ApplicationMetrics, Get-CollectedMetrics, Get-SystemMetrics
