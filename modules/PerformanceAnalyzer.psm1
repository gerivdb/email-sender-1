# Module d'analyse des performances
# Ce module analyse les métriques de performance du système
# Author: EMAIL_SENDER_1 Team
# Version: 1.0.0

#Requires -Version 5.1

# Variables globales du module
$script:PerformanceAnalyzerConfig = @{
    Enabled    = $true
    ConfigPath = "$env:TEMP\PerformanceAnalyzer\config.json"
    LogPath    = "$env:TEMP\PerformanceAnalyzer\logs.log"
    LogLevel   = "INFO"
}

function Initialize-PerformanceAnalyzer {
    <#
    .SYNOPSIS
        Initialise le module d'analyse des performances.
    .DESCRIPTION
        Configure et initialise le module d'analyse des performances avec les paramètres spécifiés.
    .PARAMETER Enabled
        Active ou désactive l'analyseur de performances.
    .PARAMETER ConfigPath
        Chemin du fichier de configuration.
    .PARAMETER LogPath
        Chemin du fichier de log.
    .PARAMETER LogLevel
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .EXAMPLE
        Initialize-PerformanceAnalyzer -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:TEMP\PerformanceAnalyzer\config.json",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\PerformanceAnalyzer\logs.log",

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$LogLevel = "INFO"
    )

    # Mettre à jour la configuration
    $script:PerformanceAnalyzerConfig.Enabled = $Enabled
    $script:PerformanceAnalyzerConfig.ConfigPath = $ConfigPath
    $script:PerformanceAnalyzerConfig.LogPath = $LogPath
    $script:PerformanceAnalyzerConfig.LogLevel = $LogLevel

    # Créer les répertoires nécessaires
    $configDir = Split-Path -Path $ConfigPath -Parent
    $logDir = Split-Path -Path $LogPath -Parent

    if (-not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Journaliser l'initialisation
    Write-Log -Message "PerformanceAnalyzer initialisé avec succès." -Level "INFO"
    Write-Log -Message "Configuration: $($script:PerformanceAnalyzerConfig | ConvertTo-Json -Compress)" -Level "DEBUG"

    return $script:PerformanceAnalyzerConfig
}

function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message dans le fichier de log.
    .DESCRIPTION
        Écrit un message dans le fichier de log avec le niveau spécifié.
    .PARAMETER Message
        Message à journaliser.
    .PARAMETER Level
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .EXAMPLE
        Write-Log -Message "Opération réussie" -Level "INFO"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    # Vérifier si le niveau de log est suffisant
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$Level] -lt $logLevels[$script:PerformanceAnalyzerConfig.LogLevel]) {
        return
    }

    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Écrire dans le fichier de log
    try {
        Add-Content -Path $script:PerformanceAnalyzerConfig.LogPath -Value $logMessage -ErrorAction Stop
    } catch {
        Write-Warning "Impossible d'écrire dans le fichier de log: $_"
    }

    # Afficher dans la console si le niveau est WARNING ou ERROR
    if ($Level -eq "WARNING" -or $Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor $(if ($Level -eq "WARNING") { "Yellow" } else { "Red" })
    }
}

function Start-PerformanceAnalysis {
    <#
    .SYNOPSIS
        Démarre l'analyse des performances.
    .DESCRIPTION
        Collecte et analyse les métriques de performance du système.
    .PARAMETER Duration
        Durée de l'analyse en secondes.
    .PARAMETER CollectionInterval
        Intervalle de collecte des métriques en secondes.
    .PARAMETER OutputPath
        Chemin de sortie pour les résultats de l'analyse.
    .EXAMPLE
        Start-PerformanceAnalysis -Duration 60 -CollectionInterval 5 -OutputPath "C:\Results"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Duration = 60,

        [Parameter(Mandatory = $false)]
        [int]$CollectionInterval = 5,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP\PerformanceAnalyzer\results"
    )

    # Vérifier si l'analyseur est activé
    if (-not $script:PerformanceAnalyzerConfig.Enabled) {
        Write-Warning "L'analyseur de performances est désactivé. Utilisez Initialize-PerformanceAnalyzer -Enabled `$true pour l'activer."
        return
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    Write-Log -Message "Démarrage de l'analyse des performances..." -Level "INFO"
    Write-Log -Message "Durée: $Duration secondes, Intervalle: $CollectionInterval secondes" -Level "DEBUG"

    # Collecter les métriques
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $metrics = @()

    while ((Get-Date) -lt $endTime) {
        $currentMetrics = @{
            Timestamp = Get-Date
            CPU       = Get-CPUMetrics
            Memory    = Get-MemoryMetrics
            Disk      = Get-DiskMetrics
            Network   = Get-NetworkMetrics
        }

        $metrics += $currentMetrics
        Write-Log -Message "Métriques collectées à $($currentMetrics.Timestamp)" -Level "DEBUG"

        # Attendre l'intervalle de collecte
        Start-Sleep -Seconds $CollectionInterval
    }

    Write-Log -Message "Collecte des métriques terminée. $($metrics.Count) échantillons collectés." -Level "INFO"

    # Analyser les métriques
    $analysisResult = Measure-Metrics -Metrics $metrics

    # Sauvegarder les résultats
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $resultsFile = Join-Path -Path $OutputPath -ChildPath "performance_analysis_$timestamp.json"

    $results = @{
        StartTime          = $startTime
        EndTime            = Get-Date
        Duration           = $Duration
        CollectionInterval = $CollectionInterval
        SampleCount        = $metrics.Count
        Metrics            = $metrics
        Analysis           = $analysisResult
    }

    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding utf8

    Write-Log -Message "Analyse des performances terminée. Résultats sauvegardés dans $resultsFile" -Level "INFO"

    return $results
}

function Measure-CPUMetrics {
    <#
    .SYNOPSIS
        Analyse les métriques CPU.
    .DESCRIPTION
        Analyse les métriques CPU pour identifier les tendances, les anomalies et les problèmes de performance.
    .PARAMETER CPUMetrics
        Métriques CPU à analyser.
    .EXAMPLE
        Measure-CPUMetrics -CPUMetrics $metrics.CPU
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$CPUMetrics
    )

    Write-Log -Message "Analyse des métriques CPU..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $CPUMetrics | ForEach-Object { $_.Usage } | Measure-Object -Average -Maximum -Minimum
    $userTimeStats = $CPUMetrics | ForEach-Object { $_.UserTime } | Measure-Object -Average -Maximum -Minimum
    $systemTimeStats = $CPUMetrics | ForEach-Object { $_.SystemTime } | Measure-Object -Average -Maximum -Minimum
    $interruptTimeStats = $CPUMetrics | ForEach-Object { $_.InterruptTime } | Measure-Object -Average -Maximum -Minimum
    $queueLengthStats = $CPUMetrics | ForEach-Object { $_.QueueLength } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($CPUMetrics | ForEach-Object { $_.Usage })
    $queueLengthTrend = Get-MetricTrend -Values ($CPUMetrics | ForEach-Object { $_.QueueLength })

    # Identifier les processus les plus consommateurs
    $topProcesses = @{}
    foreach ($metric in $CPUMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count    = 0
                    TotalCPU = 0
                    MaxCPU   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalCPU += $process.CPU
            if ($process.CPU -gt $topProcesses[$process.Name].MaxCPU) {
                $topProcesses[$process.Name].MaxCPU = $process.CPU
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.Key
            AverageCPU = [math]::Round($_.Value.TotalCPU / $_.Value.Count, 2)
            MaxCPU     = [math]::Round($_.Value.MaxCPU, 2)
            Frequency  = [math]::Round(($_.Value.Count / $CPUMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageCPU -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highCpuThreshold = 80
    $highQueueLengthThreshold = 5
    $highInterruptTimeThreshold = 10

    # Détecter les pics d'utilisation CPU
    $cpuSpikes = $CPUMetrics | Where-Object { $_.Usage -gt $highCpuThreshold }
    if ($cpuSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation CPU détectés: $($cpuSpikes.Count) occurrences au-dessus de $highCpuThreshold%"
    }

    # Détecter les files d'attente longues
    $longQueues = $CPUMetrics | Where-Object { $_.QueueLength -gt $highQueueLengthThreshold }
    if ($longQueues.Count -gt 0) {
        $anomalies += "Files d'attente CPU longues détectées: $($longQueues.Count) occurrences au-dessus de $highQueueLengthThreshold"
    }

    # Détecter les temps d'interruption élevés
    $highInterrupts = $CPUMetrics | Where-Object { $_.InterruptTime -gt $highInterruptTimeThreshold }
    if ($highInterrupts.Count -gt 0) {
        $anomalies += "Temps d'interruption élevés détectés: $($highInterrupts.Count) occurrences au-dessus de $highInterruptTimeThreshold%"
    }

    # Analyser l'équilibre entre temps utilisateur et système
    $userSystemRatio = [math]::Round($userTimeStats.Average / ($systemTimeStats.Average + 0.001), 2)
    if ($userSystemRatio < 1) {
        $anomalies += "Ratio temps utilisateur/système faible ($userSystemRatio): possible problème de pilote ou de système"
    }

    # Analyser les processus problématiques
    $problematicProcesses = $topProcessesList | Where-Object { $_.MaxCPU -gt $highCpuThreshold -and $_.Frequency -gt 50 }
    foreach ($process in $problematicProcesses) {
        $anomalies += "Processus problématique détecté: $($process.Name) (CPU max: $($process.MaxCPU)%, fréquence: $($process.Frequency)%)"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage                = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highCpuThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highCpuThreshold
        }
        UserTime             = @{
            Average = [math]::Round($userTimeStats.Average, 2)
            Maximum = [math]::Round($userTimeStats.Maximum, 2)
            Minimum = [math]::Round($userTimeStats.Minimum, 2)
        }
        SystemTime           = @{
            Average = [math]::Round($systemTimeStats.Average, 2)
            Maximum = [math]::Round($systemTimeStats.Maximum, 2)
            Minimum = [math]::Round($systemTimeStats.Minimum, 2)
        }
        InterruptTime        = @{
            Average          = [math]::Round($interruptTimeStats.Average, 2)
            Maximum          = [math]::Round($interruptTimeStats.Maximum, 2)
            Minimum          = [math]::Round($interruptTimeStats.Minimum, 2)
            Threshold        = $highInterruptTimeThreshold
            ExceedsThreshold = $interruptTimeStats.Maximum -gt $highInterruptTimeThreshold
        }
        QueueLength          = @{
            Average          = [math]::Round($queueLengthStats.Average, 2)
            Maximum          = [math]::Round($queueLengthStats.Maximum, 2)
            Minimum          = [math]::Round($queueLengthStats.Minimum, 2)
            Trend            = $queueLengthTrend
            Threshold        = $highQueueLengthThreshold
            ExceedsThreshold = $queueLengthStats.Maximum -gt $highQueueLengthThreshold
        }
        UserSystemRatio      = $userSystemRatio
        TopProcesses         = $topProcessesList
        ProblematicProcesses = $problematicProcesses
        Anomalies            = $anomalies
    }

    # Générer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation CPU en identifiant et en ajustant les processus consommateurs"
    }

    if ($analysis.QueueLength.ExceedsThreshold) {
        $recommendations += "Réduire la charge de travail ou augmenter les ressources CPU pour diminuer les files d'attente"
    }

    if ($analysis.InterruptTime.ExceedsThreshold) {
        $recommendations += "Vérifier les pilotes et périphériques qui génèrent un nombre élevé d'interruptions"
    }

    if ($userSystemRatio < 1) {
        $recommendations += "Investiguer les processus système et les pilotes qui consomment trop de temps CPU"
    }

    if ($problematicProcesses.Count -gt 0) {
        $recommendations += "Optimiser ou remplacer les processus problématiques: $($problematicProcesses.Name -join ', ')"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des métriques CPU terminée. $($anomalies.Count) anomalies identifiées." -Level "INFO"

    return $analysis
}

function Get-MetricTrend {
    <#
    .SYNOPSIS
        Calcule la tendance d'une série de valeurs.
    .DESCRIPTION
        Calcule la tendance (croissante, décroissante ou stable) d'une série de valeurs.
    .PARAMETER Values
        Série de valeurs à analyser.
    .EXAMPLE
        Get-MetricTrend -Values $cpuValues
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Values
    )

    if ($Values.Count -lt 2) {
        return "Stable"
    }

    # Calculer la pente de la tendance linéaire
    $n = $Values.Count
    $sumX = 0
    $sumY = 0
    $sumXY = 0
    $sumXX = 0

    for ($i = 0; $i -lt $n; $i++) {
        $sumX += $i
        $sumY += $Values[$i]
        $sumXY += $i * $Values[$i]
        $sumXX += $i * $i
    }

    $slope = 0
    $denominator = $n * $sumXX - $sumX * $sumX

    if ($denominator -ne 0) {
        $slope = ($n * $sumXY - $sumX * $sumY) / $denominator
    }

    # Déterminer la tendance
    $threshold = 0.1

    if ($slope -gt $threshold) {
        return "Croissante"
    } elseif ($slope -lt - $threshold) {
        return "Décroissante"
    } else {
        return "Stable"
    }
}

function Measure-MemoryMetrics {
    <#
    .SYNOPSIS
        Analyse les métriques mémoire.
    .DESCRIPTION
        Analyse les métriques mémoire pour identifier les tendances, les anomalies et les problèmes de performance.
    .PARAMETER MemoryMetrics
        Métriques mémoire à analyser.
    .EXAMPLE
        Measure-MemoryMetrics -MemoryMetrics $metrics.Memory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$MemoryMetrics
    )

    Write-Log -Message "Analyse des métriques mémoire..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $MemoryMetrics | ForEach-Object { $_.Usage } | Measure-Object -Average -Maximum -Minimum
    $availableMBStats = $MemoryMetrics | ForEach-Object { $_.Available.MB } | Measure-Object -Average -Maximum -Minimum
    $pageFaultsStats = $MemoryMetrics | ForEach-Object { $_.Performance.PageFaultsPersec } | Measure-Object -Average -Maximum -Minimum
    $pagesInputStats = $MemoryMetrics | ForEach-Object { $_.Performance.PagesInputPersec } | Measure-Object -Average -Maximum -Minimum
    $commitPercentStats = $MemoryMetrics | ForEach-Object { $_.Performance.CommitPercent } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Usage })
    $availableTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Available.MB })
    $pageFaultsTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Performance.PageFaultsPersec })

    # Identifier les processus les plus consommateurs
    $topProcesses = @{}
    foreach ($metric in $MemoryMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count       = 0
                    TotalMemory = 0
                    MaxMemory   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalMemory += $process.WorkingSet
            if ($process.WorkingSet -gt $topProcesses[$process.Name].MaxMemory) {
                $topProcesses[$process.Name].MaxMemory = $process.WorkingSet
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name            = $_.Key
            AverageMemoryMB = [math]::Round($_.Value.TotalMemory / $_.Value.Count, 2)
            MaxMemoryMB     = [math]::Round($_.Value.MaxMemory, 2)
            Frequency       = [math]::Round(($_.Value.Count / $MemoryMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageMemoryMB -Descending | Select-Object -First 5

    # Analyser les fuites mémoire potentielles
    $leakSuspects = @()
    foreach ($metric in $MemoryMetrics) {
        if ($metric.LeakDetection.LeakDetected) {
            foreach ($suspect in $metric.LeakDetection.LeakSuspects) {
                if (-not ($leakSuspects | Where-Object { $_.Name -eq $suspect.Name })) {
                    $leakSuspects += $suspect
                }
            }
        }
    }

    # Analyser les anomalies
    $anomalies = @()
    $highMemoryThreshold = 85
    $highPageFaultsThreshold = 1000
    $highCommitPercentThreshold = 90
    $lowAvailableMemoryThreshold = 500  # MB

    # Détecter les pics d'utilisation mémoire
    $memorySpikes = $MemoryMetrics | Where-Object { $_.Usage -gt $highMemoryThreshold }
    if ($memorySpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation mémoire détectés: $($memorySpikes.Count) occurrences au-dessus de $highMemoryThreshold%"
    }

    # Détecter les pics de défauts de page
    $pageFaultsSpikes = $MemoryMetrics | Where-Object { $_.Performance.PageFaultsPersec -gt $highPageFaultsThreshold }
    if ($pageFaultsSpikes.Count -gt 0) {
        $anomalies += "Pics de défauts de page détectés: $($pageFaultsSpikes.Count) occurrences au-dessus de $highPageFaultsThreshold/sec"
    }

    # Détecter les niveaux de mémoire disponible faibles
    $lowMemoryEvents = $MemoryMetrics | Where-Object { $_.Available.MB -lt $lowAvailableMemoryThreshold }
    if ($lowMemoryEvents.Count -gt 0) {
        $anomalies += "Niveaux de mémoire disponible faibles détectés: $($lowMemoryEvents.Count) occurrences en dessous de $lowAvailableMemoryThreshold MB"
    }

    # Détecter les taux d'engagement élevés
    $highCommitEvents = $MemoryMetrics | Where-Object { $_.Performance.CommitPercent -gt $highCommitPercentThreshold }
    if ($highCommitEvents.Count -gt 0) {
        $anomalies += "Taux d'engagement mémoire élevés détectés: $($highCommitEvents.Count) occurrences au-dessus de $highCommitPercentThreshold%"
    }

    # Analyser les fuites mémoire
    if ($leakSuspects.Count -gt 0) {
        $anomalies += "Fuites mémoire potentielles détectées dans les processus: $($leakSuspects.Name -join ', ')"
    }

    # Analyser les processus problématiques
    $problematicProcesses = $topProcessesList | Where-Object { $_.MaxMemoryMB -gt 1000 -and $_.Frequency -gt 50 }
    foreach ($process in $problematicProcesses) {
        $anomalies += "Processus à haute consommation mémoire détecté: $($process.Name) (Mémoire max: $($process.MaxMemoryMB) MB, fréquence: $($process.Frequency)%)"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage                = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highMemoryThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highMemoryThreshold
        }
        Available            = @{
            AverageMB      = [math]::Round($availableMBStats.Average, 2)
            MaximumMB      = [math]::Round($availableMBStats.Maximum, 2)
            MinimumMB      = [math]::Round($availableMBStats.Minimum, 2)
            Trend          = $availableTrend
            Threshold      = $lowAvailableMemoryThreshold
            BelowThreshold = $availableMBStats.Minimum -lt $lowAvailableMemoryThreshold
        }
        PageFaults           = @{
            Average          = [math]::Round($pageFaultsStats.Average, 2)
            Maximum          = [math]::Round($pageFaultsStats.Maximum, 2)
            Minimum          = [math]::Round($pageFaultsStats.Minimum, 2)
            Trend            = $pageFaultsTrend
            Threshold        = $highPageFaultsThreshold
            ExceedsThreshold = $pageFaultsStats.Maximum -gt $highPageFaultsThreshold
        }
        PagesInput           = @{
            Average = [math]::Round($pagesInputStats.Average, 2)
            Maximum = [math]::Round($pagesInputStats.Maximum, 2)
            Minimum = [math]::Round($pagesInputStats.Minimum, 2)
        }
        CommitPercent        = @{
            Average          = [math]::Round($commitPercentStats.Average, 2)
            Maximum          = [math]::Round($commitPercentStats.Maximum, 2)
            Minimum          = [math]::Round($commitPercentStats.Minimum, 2)
            Threshold        = $highCommitPercentThreshold
            ExceedsThreshold = $commitPercentStats.Maximum -gt $highCommitPercentThreshold
        }
        TopProcesses         = $topProcessesList
        LeakSuspects         = $leakSuspects
        ProblematicProcesses = $problematicProcesses
        Anomalies            = $anomalies
    }

    # Générer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "Réduire la consommation mémoire en optimisant ou en fermant les applications gourmandes"
    }

    if ($analysis.Available.BelowThreshold) {
        $recommendations += "Augmenter la mémoire physique ou réduire le nombre d'applications simultanées"
    }

    if ($analysis.PageFaults.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation de la mémoire pour réduire les défauts de page"
    }

    if ($analysis.CommitPercent.ExceedsThreshold) {
        $recommendations += "Augmenter la taille du fichier d'échange ou réduire la charge mémoire"
    }

    if ($leakSuspects.Count -gt 0) {
        $recommendations += "Investiguer et corriger les fuites mémoire dans les processus: $($leakSuspects.Name -join ', ')"
    }

    if ($problematicProcesses.Count -gt 0) {
        $recommendations += "Optimiser ou remplacer les processus à haute consommation mémoire: $($problematicProcesses.Name -join ', ')"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des métriques mémoire terminée. $($anomalies.Count) anomalies identifiées." -Level "INFO"

    return $analysis
}

function Measure-DiskMetrics {
    <#
    .SYNOPSIS
        Analyse les métriques disque.
    .DESCRIPTION
        Analyse les métriques disque pour identifier les tendances, les anomalies et les problèmes de performance.
    .PARAMETER DiskMetrics
        Métriques disque à analyser.
    .EXAMPLE
        Measure-DiskMetrics -DiskMetrics $metrics.Disk
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$DiskMetrics
    )

    Write-Log -Message "Analyse des métriques disque..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $DiskMetrics | ForEach-Object { $_.Usage.Average } | Measure-Object -Average -Maximum -Minimum
    $iopsStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.TotalIOPS } | Measure-Object -Average -Maximum -Minimum
    $responseTimeStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.ResponseTimeMS } | Measure-Object -Average -Maximum -Minimum
    $queueLengthStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.QueueLength } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Usage.Average })
    $iopsTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Performance.Total.TotalIOPS })
    $responseTimeTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Performance.Total.ResponseTimeMS })

    # Analyser les performances par disque logique
    $drivePerformance = @{}
    foreach ($metric in $DiskMetrics) {
        foreach ($drive in $metric.Performance.LogicalDisks) {
            if (-not $drivePerformance.ContainsKey($drive.Drive)) {
                $drivePerformance[$drive.Drive] = @{
                    Count             = 0
                    TotalUsage        = 0
                    TotalReadMB       = 0
                    TotalWriteMB      = 0
                    TotalResponseTime = 0
                    MaxUsage          = 0
                    MaxResponseTime   = 0
                }
            }

            $driveUsage = ($metric.Usage.ByDrive | Where-Object { $_.Drive -eq $drive.Drive }).Usage
            $drivePerformance[$drive.Drive].Count++
            $drivePerformance[$drive.Drive].TotalUsage += $driveUsage
            $drivePerformance[$drive.Drive].TotalReadMB += $drive.DiskReadBytesPersec
            $drivePerformance[$drive.Drive].TotalWriteMB += $drive.DiskWriteBytesPersec
            $drivePerformance[$drive.Drive].TotalResponseTime += $drive.AvgDiskSecPerTransfer

            if ($driveUsage -gt $drivePerformance[$drive.Drive].MaxUsage) {
                $drivePerformance[$drive.Drive].MaxUsage = $driveUsage
            }

            if ($drive.AvgDiskSecPerTransfer -gt $drivePerformance[$drive.Drive].MaxResponseTime) {
                $drivePerformance[$drive.Drive].MaxResponseTime = $drive.AvgDiskSecPerTransfer
            }
        }
    }

    # Calculer les moyennes par disque et trier
    $drivePerformanceList = $drivePerformance.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Drive                 = $_.Key
            AverageUsage          = [math]::Round($_.Value.TotalUsage / $_.Value.Count, 2)
            MaxUsage              = [math]::Round($_.Value.MaxUsage, 2)
            AverageReadMBPerSec   = [math]::Round($_.Value.TotalReadMB / $_.Value.Count, 2)
            AverageWriteMBPerSec  = [math]::Round($_.Value.TotalWriteMB / $_.Value.Count, 2)
            AverageResponseTimeMS = [math]::Round($_.Value.TotalResponseTime / $_.Value.Count, 2)
            MaxResponseTimeMS     = [math]::Round($_.Value.MaxResponseTime, 2)
        }
    } | Sort-Object -Property AverageUsage -Descending

    # Analyser les processus les plus actifs
    $topProcesses = @{}
    foreach ($metric in $DiskMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count     = 0
                    TotalIOPS = 0
                    MaxIOPS   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalIOPS += $process.IOPS
            if ($process.IOPS -gt $topProcesses[$process.Name].MaxIOPS) {
                $topProcesses[$process.Name].MaxIOPS = $process.IOPS
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name        = $_.Key
            AverageIOPS = [math]::Round($_.Value.TotalIOPS / $_.Value.Count, 2)
            MaxIOPS     = [math]::Round($_.Value.MaxIOPS, 2)
            Frequency   = [math]::Round(($_.Value.Count / $DiskMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageIOPS -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highDiskUsageThreshold = 90
    $highIOPSThreshold = 1000
    $highResponseTimeThreshold = 20  # ms
    $highQueueLengthThreshold = 2

    # Détecter les pics d'utilisation disque
    $diskSpikes = $DiskMetrics | Where-Object { $_.Usage.Average -gt $highDiskUsageThreshold }
    if ($diskSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation disque détectés: $($diskSpikes.Count) occurrences au-dessus de $highDiskUsageThreshold%"
    }

    # Détecter les pics d'IOPS
    $iopsSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.TotalIOPS -gt $highIOPSThreshold }
    if ($iopsSpikes.Count -gt 0) {
        $anomalies += "Pics d'IOPS détectés: $($iopsSpikes.Count) occurrences au-dessus de $highIOPSThreshold IOPS"
    }

    # Détecter les temps de réponse élevés
    $responseTimeSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.ResponseTimeMS -gt $highResponseTimeThreshold }
    if ($responseTimeSpikes.Count -gt 0) {
        $anomalies += "Temps de réponse disque élevés détectés: $($responseTimeSpikes.Count) occurrences au-dessus de $highResponseTimeThreshold ms"
    }

    # Détecter les files d'attente longues
    $queueLengthSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.QueueLength -gt $highQueueLengthThreshold }
    if ($queueLengthSpikes.Count -gt 0) {
        $anomalies += "Files d'attente disque longues détectées: $($queueLengthSpikes.Count) occurrences au-dessus de $highQueueLengthThreshold"
    }

    # Analyser la fragmentation
    $highFragmentationThreshold = 15  # %
    $fragmentationIssues = $DiskMetrics | Where-Object {
        $_.Fragmentation | Where-Object { $_.FragmentationPercent -gt $highFragmentationThreshold }
    }
    if ($fragmentationIssues.Count -gt 0) {
        $anomalies += "Fragmentation élevée détectée sur certains volumes"
    }

    # Analyser les disques problématiques
    $problematicDrives = $drivePerformanceList | Where-Object {
        $_.MaxUsage -gt $highDiskUsageThreshold -or
        $_.MaxResponseTimeMS -gt $highResponseTimeThreshold
    }
    foreach ($drive in $problematicDrives) {
        $anomalies += "Disque problématique détecté: $($drive.Drive) (Usage max: $($drive.MaxUsage)%, Temps de réponse max: $($drive.MaxResponseTimeMS) ms)"
    }

    # Analyser la santé des disques physiques
    $diskHealthIssues = @()
    foreach ($metric in $DiskMetrics) {
        foreach ($disk in $metric.PhysicalDisks) {
            if ($disk.Health.Status -ne "OK" -and $disk.Health.Status -ne "Healthy") {
                $diskHealthIssues += "$($disk.Model) ($($disk.Index)): $($disk.Health.Status)"
            }
        }
    }

    if ($diskHealthIssues.Count -gt 0) {
        $anomalies += "Problèmes de santé détectés sur les disques physiques: $($diskHealthIssues -join ', ')"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage             = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highDiskUsageThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highDiskUsageThreshold
        }
        IOPS              = @{
            Average          = [math]::Round($iopsStats.Average, 2)
            Maximum          = [math]::Round($iopsStats.Maximum, 2)
            Minimum          = [math]::Round($iopsStats.Minimum, 2)
            Trend            = $iopsTrend
            Threshold        = $highIOPSThreshold
            ExceedsThreshold = $iopsStats.Maximum -gt $highIOPSThreshold
        }
        ResponseTime      = @{
            AverageMS        = [math]::Round($responseTimeStats.Average, 2)
            MaximumMS        = [math]::Round($responseTimeStats.Maximum, 2)
            MinimumMS        = [math]::Round($responseTimeStats.Minimum, 2)
            Trend            = $responseTimeTrend
            Threshold        = $highResponseTimeThreshold
            ExceedsThreshold = $responseTimeStats.Maximum -gt $highResponseTimeThreshold
        }
        QueueLength       = @{
            Average          = [math]::Round($queueLengthStats.Average, 2)
            Maximum          = [math]::Round($queueLengthStats.Maximum, 2)
            Minimum          = [math]::Round($queueLengthStats.Minimum, 2)
            Threshold        = $highQueueLengthThreshold
            ExceedsThreshold = $queueLengthStats.Maximum -gt $highQueueLengthThreshold
        }
        DrivePerformance  = $drivePerformanceList
        ProblematicDrives = $problematicDrives
        TopProcesses      = $topProcessesList
        DiskHealthIssues  = $diskHealthIssues
        Anomalies         = $anomalies
    }

    # Générer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "Libérer de l'espace disque ou ajouter de la capacité de stockage"
    }

    if ($analysis.IOPS.ExceedsThreshold) {
        $recommendations += "Réduire les opérations d'E/S intensives ou utiliser des disques plus performants"
    }

    if ($analysis.ResponseTime.ExceedsThreshold) {
        $recommendations += "Améliorer les performances disque en utilisant des SSD ou en optimisant les opérations d'E/S"
    }

    if ($analysis.QueueLength.ExceedsThreshold) {
        $recommendations += "Réduire la charge disque ou améliorer les performances du sous-système de stockage"
    }

    if ($fragmentationIssues.Count -gt 0) {
        $recommendations += "Défragmenter les volumes avec une fragmentation élevée"
    }

    if ($problematicDrives.Count -gt 0) {
        $recommendations += "Optimiser l'utilisation des disques problématiques: $($problematicDrives.Drive -join ', ')"
    }

    if ($diskHealthIssues.Count -gt 0) {
        $recommendations += "Vérifier et remplacer les disques physiques défectueux"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des métriques disque terminée. $($anomalies.Count) anomalies identifiées." -Level "INFO"

    return $analysis
}

function Measure-NetworkMetrics {
    <#
    .SYNOPSIS
        Analyse les métriques réseau.
    .DESCRIPTION
        Analyse les métriques réseau pour identifier les tendances, les anomalies et les problèmes de performance.
    .PARAMETER NetworkMetrics
        Métriques réseau à analyser.
    .EXAMPLE
        Measure-NetworkMetrics -NetworkMetrics $metrics.Network
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$NetworkMetrics
    )

    Write-Log -Message "Analyse des métriques réseau..." -Level "INFO"

    # Calculer les statistiques de base
    $bandwidthUsageStats = $NetworkMetrics | ForEach-Object { $_.BandwidthUsage } | Measure-Object -Average -Maximum -Minimum
    $throughputInStats = $NetworkMetrics | ForEach-Object { $_.Throughput.InMbps } | Measure-Object -Average -Maximum -Minimum
    $throughputOutStats = $NetworkMetrics | ForEach-Object { $_.Throughput.OutMbps } | Measure-Object -Average -Maximum -Minimum
    $latencyStats = $NetworkMetrics | ForEach-Object { $_.Latency } | Measure-Object -Average -Maximum -Minimum
    $errorRateStats = $NetworkMetrics | ForEach-Object { $_.Performance.ErrorRate } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $bandwidthTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.BandwidthUsage })
    $latencyTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.Latency })
    $errorRateTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.Performance.ErrorRate })

    # Analyser les connexions TCP
    $tcpConnectionStats = @{}
    foreach ($metric in $NetworkMetrics) {
        foreach ($state in $metric.Connections.TCP.ByState) {
            if (-not $tcpConnectionStats.ContainsKey($state.State)) {
                $tcpConnectionStats[$state.State] = @{
                    Count = 0
                    Total = 0
                    Max   = 0
                }
            }

            $tcpConnectionStats[$state.State].Count++
            $tcpConnectionStats[$state.State].Total += $state.Count
            if ($state.Count -gt $tcpConnectionStats[$state.State].Max) {
                $tcpConnectionStats[$state.State].Max = $state.Count
            }
        }
    }

    # Calculer la moyenne pour chaque état de connexion et trier
    $tcpConnectionList = $tcpConnectionStats.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            State   = $_.Key
            Average = [math]::Round($_.Value.Total / $_.Value.Count, 2)
            Maximum = $_.Value.Max
        }
    } | Sort-Object -Property Average -Descending

    # Analyser les processus avec le plus de connexions
    $topProcesses = @{}
    foreach ($metric in $NetworkMetrics) {
        foreach ($process in $metric.Connections.TCP.ByProcess) {
            if (-not $topProcesses.ContainsKey($process.Process)) {
                $topProcesses[$process.Process] = @{
                    Count            = 0
                    TotalConnections = 0
                    MaxConnections   = 0
                }
            }

            $topProcesses[$process.Process].Count++
            $topProcesses[$process.Process].TotalConnections += $process.Count
            if ($process.Count -gt $topProcesses[$process.Process].MaxConnections) {
                $topProcesses[$process.Process].MaxConnections = $process.Count
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name               = $_.Key
            AverageConnections = [math]::Round($_.Value.TotalConnections / $_.Value.Count, 2)
            MaxConnections     = $_.Value.MaxConnections
            Frequency          = [math]::Round(($_.Value.Count / $NetworkMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageConnections -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highBandwidthThreshold = 80
    $highLatencyThreshold = 100  # ms
    $highErrorRateThreshold = 0.1  # %
    $highTCPConnectionsThreshold = 1000
    $highTCPResetRateThreshold = 5  # %

    # Détecter les pics d'utilisation de la bande passante
    $bandwidthSpikes = $NetworkMetrics | Where-Object { $_.BandwidthUsage -gt $highBandwidthThreshold }
    if ($bandwidthSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation de la bande passante détectés: $($bandwidthSpikes.Count) occurrences au-dessus de $highBandwidthThreshold%"
    }

    # Détecter les pics de latence
    $latencySpikes = $NetworkMetrics | Where-Object { $_.Latency -gt $highLatencyThreshold }
    if ($latencySpikes.Count -gt 0) {
        $anomalies += "Pics de latence réseau détectés: $($latencySpikes.Count) occurrences au-dessus de $highLatencyThreshold ms"
    }

    # Détecter les taux d'erreurs élevés
    $errorRateSpikes = $NetworkMetrics | Where-Object { $_.Performance.ErrorRate -gt $highErrorRateThreshold }
    if ($errorRateSpikes.Count -gt 0) {
        $anomalies += "Taux d'erreurs réseau élevés détectés: $($errorRateSpikes.Count) occurrences au-dessus de $highErrorRateThreshold%"
    }

    # Détecter les nombres élevés de connexions TCP
    $highConnectionsEvents = $NetworkMetrics | Where-Object { $_.Connections.TCP.Total -gt $highTCPConnectionsThreshold }
    if ($highConnectionsEvents.Count -gt 0) {
        $anomalies += "Nombre élevé de connexions TCP détecté: $($highConnectionsEvents.Count) occurrences au-dessus de $highTCPConnectionsThreshold connexions"
    }

    # Détecter les taux élevés de réinitialisation TCP
    $tcpResetRateEvents = $NetworkMetrics | ForEach-Object {
        if ($_.Connections.TCPStats.ConnectionsEstablished -gt 0) {
            $resetRate = ($_.Connections.TCPStats.ConnectionsReset / $_.Connections.TCPStats.ConnectionsEstablished) * 100
            if ($resetRate -gt $highTCPResetRateThreshold) {
                return $_
            }
        }
        return $null
    } | Where-Object { $_ -ne $null }

    if ($tcpResetRateEvents.Count -gt 0) {
        $anomalies += "Taux élevés de réinitialisation TCP détectés: $($tcpResetRateEvents.Count) occurrences au-dessus de $highTCPResetRateThreshold%"
    }

    # Analyser les anomalies réseau détectées par le collecteur
    $collectorAnomalies = @()
    foreach ($metric in $NetworkMetrics) {
        foreach ($anomaly in $metric.Anomalies) {
            if (-not $collectorAnomalies.Contains($anomaly)) {
                $collectorAnomalies += $anomaly
            }
        }
    }

    if ($collectorAnomalies.Count -gt 0) {
        $anomalies += $collectorAnomalies
    }

    # Construire l'objet d'analyse
    $analysis = @{
        BandwidthUsage = @{
            Average          = [math]::Round($bandwidthUsageStats.Average, 2)
            Maximum          = [math]::Round($bandwidthUsageStats.Maximum, 2)
            Minimum          = [math]::Round($bandwidthUsageStats.Minimum, 2)
            Trend            = $bandwidthTrend
            Threshold        = $highBandwidthThreshold
            ExceedsThreshold = $bandwidthUsageStats.Maximum -gt $highBandwidthThreshold
        }
        Throughput     = @{
            In    = @{
                AverageMbps = [math]::Round($throughputInStats.Average, 2)
                MaximumMbps = [math]::Round($throughputInStats.Maximum, 2)
                MinimumMbps = [math]::Round($throughputInStats.Minimum, 2)
            }
            Out   = @{
                AverageMbps = [math]::Round($throughputOutStats.Average, 2)
                MaximumMbps = [math]::Round($throughputOutStats.Maximum, 2)
                MinimumMbps = [math]::Round($throughputOutStats.Minimum, 2)
            }
            Total = @{
                AverageMbps = [math]::Round($throughputInStats.Average + $throughputOutStats.Average, 2)
                MaximumMbps = [math]::Round($throughputInStats.Maximum + $throughputOutStats.Maximum, 2)
            }
        }
        Latency        = @{
            AverageMS        = [math]::Round($latencyStats.Average, 2)
            MaximumMS        = [math]::Round($latencyStats.Maximum, 2)
            MinimumMS        = [math]::Round($latencyStats.Minimum, 2)
            Trend            = $latencyTrend
            Threshold        = $highLatencyThreshold
            ExceedsThreshold = $latencyStats.Maximum -gt $highLatencyThreshold
        }
        ErrorRate      = @{
            Average          = [math]::Round($errorRateStats.Average, 4)
            Maximum          = [math]::Round($errorRateStats.Maximum, 4)
            Minimum          = [math]::Round($errorRateStats.Minimum, 4)
            Trend            = $errorRateTrend
            Threshold        = $highErrorRateThreshold
            ExceedsThreshold = $errorRateStats.Maximum -gt $highErrorRateThreshold
        }
        TCPConnections = @{
            ByState = $tcpConnectionList
            Total   = @{
                Average          = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Average).Average, 2)
                Maximum          = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Maximum).Maximum, 2)
                Threshold        = $highTCPConnectionsThreshold
                ExceedsThreshold = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Maximum).Maximum, 2) -gt $highTCPConnectionsThreshold
            }
        }
        TopProcesses   = $topProcessesList
        Anomalies      = $anomalies
    }

    # Générer des recommandations
    $recommendations = @()

    if ($analysis.BandwidthUsage.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation de la bande passante ou augmenter la capacité réseau"
    }

    if ($analysis.Latency.ExceedsThreshold) {
        $recommendations += "Investiguer les causes de latence réseau élevée (routage, congestion, matériel)"
    }

    if ($analysis.ErrorRate.ExceedsThreshold) {
        $recommendations += "Vérifier les équipements réseau et les câbles pour réduire les erreurs de transmission"
    }

    if ($analysis.TCPConnections.Total.ExceedsThreshold) {
        $recommendations += "Optimiser la gestion des connexions TCP dans les applications avec un nombre élevé de connexions"
    }

    if ($tcpResetRateEvents.Count -gt 0) {
        $recommendations += "Investiguer les causes des réinitialisations TCP fréquentes (pare-feu, timeout, problèmes d'application)"
    }

    if ($collectorAnomalies.Count -gt 0) {
        $recommendations += "Résoudre les anomalies réseau détectées par le collecteur"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des métriques réseau terminée. $($anomalies.Count) anomalies identifiées." -Level "INFO"

    return $analysis
}

function Measure-Metrics {
    <#
    .SYNOPSIS
        Analyse les métriques de performance.
    .DESCRIPTION
        Analyse les métriques de performance pour identifier les tendances et les problèmes.
    .PARAMETER Metrics
        Métriques à analyser.
    .EXAMPLE
        Measure-Metrics -Metrics $metrics
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics
    )

    Write-Log -Message "Analyse des métriques..." -Level "INFO"

    # Analyser les métriques CPU avec la fonction spécialisée
    $cpuAnalysis = Measure-CPUMetrics -CPUMetrics ($Metrics | ForEach-Object { $_.CPU })

    # Analyser les métriques mémoire avec la fonction spécialisée
    $memoryAnalysis = Measure-MemoryMetrics -MemoryMetrics ($Metrics | ForEach-Object { $_.Memory })

    # Analyser les métriques disque avec la fonction spécialisée
    $diskAnalysis = Measure-DiskMetrics -DiskMetrics ($Metrics | ForEach-Object { $_.Disk })

    # Analyser les métriques réseau avec la fonction spécialisée
    $networkAnalysis = Measure-NetworkMetrics -NetworkMetrics ($Metrics | ForEach-Object { $_.Network })

    $analysis = @{
        CPU     = $cpuAnalysis
        Memory  = $memoryAnalysis
        Disk    = $diskAnalysis
        Network = $networkAnalysis
    }

    # Identifier les problèmes potentiels
    $issues = @()

    # Ajouter les anomalies de tous les analyseurs
    $issues += $cpuAnalysis.Anomalies
    $issues += $memoryAnalysis.Anomalies
    $issues += $diskAnalysis.Anomalies
    $issues += $networkAnalysis.Anomalies

    $analysis.Issues = $issues

    # Combiner les recommandations
    $recommendations = @()
    $recommendations += $cpuAnalysis.Recommendations
    $recommendations += $memoryAnalysis.Recommendations
    $recommendations += $diskAnalysis.Recommendations
    $recommendations += $networkAnalysis.Recommendations
    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des métriques terminée. $($issues.Count) problèmes identifiés." -Level "INFO"

    return $analysis
}

function Get-PerformanceReport {
    <#
    .SYNOPSIS
        Génère un rapport de performance.
    .DESCRIPTION
        Génère un rapport de performance basé sur les métriques collectées.
    .PARAMETER ReportType
        Type de rapport (Summary, Detailed).
    .PARAMETER TimeRange
        Plage de temps pour le rapport (Last1Hour, Last24Hours, Last7Days).
    .PARAMETER Format
        Format du rapport (Text, HTML, JSON).
    .EXAMPLE
        Get-PerformanceReport -ReportType "Detailed" -TimeRange "Last24Hours" -Format "HTML"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Summary", "Detailed")]
        [string]$ReportType = "Summary",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Last1Hour", "Last24Hours", "Last7Days")]
        [string]$TimeRange = "Last1Hour",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    Write-Log -Message "Génération d'un rapport de performance ($ReportType, $TimeRange, $Format)..." -Level "INFO"

    # Simuler un rapport pour l'instant
    $report = @{
        ReportType  = $ReportType
        TimeRange   = $TimeRange
        GeneratedAt = Get-Date
        CPU         = @{
            Usage        = 45.5
            TopProcesses = @(
                @{Name = "Process1"; CPU = 15.2 },
                @{Name = "Process2"; CPU = 10.5 },
                @{Name = "Process3"; CPU = 8.3 }
            )
        }
        Memory      = @{
            Usage        = 65.3
            Available    = 4096
            TopProcesses = @(
                @{Name = "Process1"; Memory = 1024 },
                @{Name = "Process2"; Memory = 512 },
                @{Name = "Process3"; Memory = 256 }
            )
        }
        Disk        = @{
            Usage        = 75.2
            IOOperations = 250
            ResponseTime = 8.5
        }
        Network     = @{
            BandwidthUsage = 35.8
            Throughput     = @{In = 25.6; Out = 10.2 }
            Latency        = 45.3
        }
    }

    # Formater le rapport
    switch ($Format) {
        "HTML" {
            # Simuler un rapport HTML
            $html = "<html><head><title>Rapport de performance</title></head><body>"
            $html += "<h1>Rapport de performance</h1>"
            $html += "<p>Type: $ReportType</p>"
            $html += "<p>Plage de temps: $TimeRange</p>"
            $html += "<p>Généré le: $($report.GeneratedAt)</p>"
            $html += "</body></html>"

            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
            $html | Out-File -FilePath $tempFile -Encoding utf8

            Write-Log -Message "Rapport HTML généré: $tempFile" -Level "INFO"
            return $tempFile
        }
        "JSON" {
            $json = $report | ConvertTo-Json -Depth 10

            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
            $json | Out-File -FilePath $tempFile -Encoding utf8

            Write-Log -Message "Rapport JSON généré: $tempFile" -Level "INFO"
            return $tempFile
        }
        default {
            Write-Log -Message "Rapport texte généré" -Level "INFO"
            return $report
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-PerformanceAnalyzer, Start-PerformanceAnalysis, Get-PerformanceReport, Measure-CPUMetrics, Measure-MemoryMetrics, Measure-DiskMetrics, Measure-NetworkMetrics, Measure-Metrics, Get-MetricTrend
