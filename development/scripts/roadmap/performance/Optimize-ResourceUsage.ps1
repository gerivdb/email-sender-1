# Optimize-ResourceUsage.ps1
# Module pour l'optimisation de l'utilisation des ressources
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour l'optimisation de l'utilisation des ressources.

.DESCRIPTION
    Ce module fournit des fonctions pour l'optimisation de l'utilisation des ressources,
    notamment la gestion intelligente de la mémoire, la prioritisation des tâches et le monitoring des performances.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

# Fonction pour implémenter la gestion intelligente de la mémoire
function Enable-IntelligentMemoryManagement {
    <#
    .SYNOPSIS
        Active la gestion intelligente de la mémoire pour les roadmaps.

    .DESCRIPTION
        Cette fonction active la gestion intelligente de la mémoire pour les roadmaps,
        permettant d'optimiser l'utilisation de la mémoire en fonction des besoins.

    .PARAMETER MaxMemoryUsageMB
        L'utilisation maximale de mémoire en mégaoctets.
        Par défaut, 1024 Mo (1 Go).

    .PARAMETER MemoryReleaseThresholdMB
        Le seuil d'utilisation de la mémoire à partir duquel la libération est déclenchée.
        Par défaut, 768 Mo (75% de MaxMemoryUsageMB).

    .PARAMETER MemoryReleasePercentage
        Le pourcentage de mémoire à libérer lorsque le seuil est atteint.
        Par défaut, 25%.

    .PARAMETER MonitoringIntervalSeconds
        L'intervalle de surveillance de la mémoire en secondes.
        Par défaut, 5 secondes.

    .PARAMETER EnableAdaptiveThresholds
        Indique si les seuils adaptatifs sont activés.
        Par défaut, $true.

    .EXAMPLE
        Enable-IntelligentMemoryManagement -MaxMemoryUsageMB 2048 -MemoryReleaseThresholdMB 1536 -MonitoringIntervalSeconds 10
        Active la gestion intelligente de la mémoire avec une utilisation maximale de 2 Go et un seuil de libération de 1,5 Go.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxMemoryUsageMB = 1024,

        [Parameter(Mandatory = $false)]
        [int]$MemoryReleaseThresholdMB = 0,

        [Parameter(Mandatory = $false)]
        [int]$MemoryReleasePercentage = 25,

        [Parameter(Mandatory = $false)]
        [int]$MonitoringIntervalSeconds = 5,

        [Parameter(Mandatory = $false)]
        [bool]$EnableAdaptiveThresholds = $true
    )

    try {
        # Calculer le seuil de libération si non spécifié
        if ($MemoryReleaseThresholdMB -eq 0) {
            $MemoryReleaseThresholdMB = [int]($MaxMemoryUsageMB * 0.75)
        }

        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            MaxMemoryUsageMB          = $MaxMemoryUsageMB
            MemoryReleaseThresholdMB  = $MemoryReleaseThresholdMB
            MemoryReleasePercentage   = $MemoryReleasePercentage
            MonitoringIntervalSeconds = $MonitoringIntervalSeconds
            EnableAdaptiveThresholds  = $EnableAdaptiveThresholds
            StartTime                 = Get-Date
            MemoryReleaseCount        = 0
            TotalMemoryReleasedMB     = 0
            MemoryUsageHistory        = @()
            IsActive                  = $true
        }

        # Démarrer le job de surveillance de la mémoire
        $monitoringJob = Start-Job -ScriptBlock {
            param($Config)

            # Fonction pour obtenir l'utilisation actuelle de la mémoire
            function Get-CurrentMemoryUsage {
                $process = Get-Process -Id $PID
                return [PSCustomObject]@{
                    WorkingSetMB           = [Math]::Round($process.WorkingSet64 / 1MB, 2)
                    PrivateMemoryMB        = [Math]::Round($process.PrivateMemorySize64 / 1MB, 2)
                    VirtualMemoryMB        = [Math]::Round($process.VirtualMemorySize64 / 1MB, 2)
                    PagedMemoryMB          = [Math]::Round($process.PagedMemorySize64 / 1MB, 2)
                    NonpagedSystemMemoryMB = [Math]::Round($process.NonpagedSystemMemorySize64 / 1MB, 2)
                    PagedSystemMemoryMB    = [Math]::Round($process.PagedSystemMemorySize64 / 1MB, 2)
                }
            }

            # Fonction pour libérer la mémoire
            function Release-Memory {
                param($AmountToReleaseMB)

                # Forcer le garbage collector
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [System.GC]::Collect()

                # Obtenir l'utilisation de la mémoire après la libération
                $memoryAfter = Get-CurrentMemoryUsage

                return [PSCustomObject]@{
                    ReleasedMB  = $memoryBefore.WorkingSetMB - $memoryAfter.WorkingSetMB
                    MemoryAfter = $memoryAfter
                }
            }

            # Boucle de surveillance
            while ($Config.IsActive) {
                # Obtenir l'utilisation actuelle de la mémoire
                $memoryBefore = Get-CurrentMemoryUsage

                # Ajouter à l'historique
                $Config.MemoryUsageHistory += [PSCustomObject]@{
                    Timestamp   = Get-Date
                    MemoryUsage = $memoryBefore
                }

                # Limiter la taille de l'historique
                if ($Config.MemoryUsageHistory.Count -gt 100) {
                    $Config.MemoryUsageHistory = $Config.MemoryUsageHistory | Select-Object -Last 100
                }

                # Vérifier si le seuil est dépassé
                if ($memoryBefore.WorkingSetMB -gt $Config.MemoryReleaseThresholdMB) {
                    # Calculer la quantité de mémoire à libérer
                    $amountToReleaseMB = [Math]::Round($memoryBefore.WorkingSetMB * ($Config.MemoryReleasePercentage / 100), 2)

                    # Libérer la mémoire
                    $releaseResult = Release-Memory -AmountToReleaseMB $amountToReleaseMB

                    # Mettre à jour les statistiques
                    $Config.MemoryReleaseCount++
                    $Config.TotalMemoryReleasedMB += $releaseResult.ReleasedMB

                    # Adapter les seuils si nécessaire
                    if ($Config.EnableAdaptiveThresholds) {
                        # Calculer l'utilisation moyenne de la mémoire sur les 10 dernières mesures
                        $recentMemoryUsage = $Config.MemoryUsageHistory | Select-Object -Last 10
                        $avgMemoryUsage = ($recentMemoryUsage | Measure-Object -Property { $_.MemoryUsage.WorkingSetMB } -Average).Average

                        # Ajuster le seuil de libération en fonction de l'utilisation moyenne
                        $Config.MemoryReleaseThresholdMB = [Math]::Min($Config.MaxMemoryUsageMB * 0.9, [Math]::Max($avgMemoryUsage * 1.2, $Config.MaxMemoryUsageMB * 0.5))
                    }
                }

                # Attendre l'intervalle de surveillance
                Start-Sleep -Seconds $Config.MonitoringIntervalSeconds
            }

            return $Config
        } -ArgumentList $config

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Config         = $config
            MonitoringJob  = $monitoringJob

            # Fonction pour arrêter la surveillance
            StopMonitoring = {
                $this.Config.IsActive = $false
                $this.MonitoringJob | Stop-Job
                $this.MonitoringJob | Remove-Job
            }

            # Fonction pour obtenir les statistiques
            GetStatistics  = {
                $jobResult = $this.MonitoringJob | Receive-Job -Keep

                if ($null -ne $jobResult) {
                    $this.Config = $jobResult
                }

                return [PSCustomObject]@{
                    MaxMemoryUsageMB         = $this.Config.MaxMemoryUsageMB
                    MemoryReleaseThresholdMB = $this.Config.MemoryReleaseThresholdMB
                    MemoryReleaseCount       = $this.Config.MemoryReleaseCount
                    TotalMemoryReleasedMB    = $this.Config.TotalMemoryReleasedMB
                    CurrentMemoryUsage       = $this.Config.MemoryUsageHistory | Select-Object -Last 1
                    AverageMemoryUsage       = ($this.Config.MemoryUsageHistory | Measure-Object -Property { $_.MemoryUsage.WorkingSetMB } -Average).Average
                    RunningTime              = (Get-Date) - $this.Config.StartTime
                }
            }
        }

        return $result
    } catch {
        Write-Error "Échec de l'activation de la gestion intelligente de la mémoire: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour implémenter le monitoring des performances en temps réel
function Enable-PerformanceMonitoring {
    <#
    .SYNOPSIS
        Active le monitoring des performances en temps réel pour les roadmaps.

    .DESCRIPTION
        Cette fonction active le monitoring des performances en temps réel pour les roadmaps,
        permettant de surveiller et d'optimiser les performances du système.

    .PARAMETER MonitoringIntervalSeconds
        L'intervalle de surveillance des performances en secondes.
        Par défaut, 5 secondes.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats du monitoring.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER MetricsToMonitor
        Les métriques à surveiller.
        Par défaut, toutes les métriques sont surveillées.

    .PARAMETER AlertThresholds
        Les seuils d'alerte pour chaque métrique.
        Par défaut, des seuils raisonnables sont définis.

    .PARAMETER EnableDashboard
        Indique si le tableau de bord en temps réel est activé.
        Par défaut, $true.

    .EXAMPLE
        Enable-PerformanceMonitoring -MonitoringIntervalSeconds 10 -MetricsToMonitor @("CPU", "Memory", "Disk", "Network") -AlertThresholds @{ CPU = 80; Memory = 85; Disk = 90; Network = 75 }
        Active le monitoring des performances avec un intervalle de 10 secondes et des seuils d'alerte personnalisés.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MonitoringIntervalSeconds = 5,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string[]]$MetricsToMonitor = @("CPU", "Memory", "Disk", "Network", "ProcessingTime", "ResponseTime", "ThroughputRate", "ErrorRate", "QueueLength"),

        [Parameter(Mandatory = $false)]
        [hashtable]$AlertThresholds = @{
            CPU            = 80
            Memory         = 85
            Disk           = 90
            Network        = 75
            ProcessingTime = 5000
            ResponseTime   = 2000
            ThroughputRate = 10
            ErrorRate      = 5
            QueueLength    = 100
        },

        [Parameter(Mandatory = $false)]
        [bool]$EnableDashboard = $true
    )

    try {
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "PerformanceMonitoring"
        }

        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        # Générer un identifiant unique pour cette session
        $sessionId = [Guid]::NewGuid().ToString()
        $sessionPath = Join-Path -Path $OutputPath -ChildPath $sessionId

        # Créer le dossier de session
        if (-not (Test-Path $sessionPath)) {
            New-Item -Path $sessionPath -ItemType Directory -Force | Out-Null
        }

        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            MonitoringIntervalSeconds = $MonitoringIntervalSeconds
            OutputPath                = $sessionPath
            MetricsToMonitor          = $MetricsToMonitor
            AlertThresholds           = $AlertThresholds
            EnableDashboard           = $EnableDashboard
            StartTime                 = Get-Date
            IsActive                  = $true
            Metrics                   = @{}
            Alerts                    = @()
            PerformanceHistory        = @()
        }

        # Initialiser les métriques
        foreach ($metric in $MetricsToMonitor) {
            $config.Metrics[$metric] = @{
                CurrentValue = 0
                MinValue     = [double]::MaxValue
                MaxValue     = [double]::MinValue
                AverageValue = 0
                SampleCount  = 0
                TotalValue   = 0
                Unit         = switch ($metric) {
                    "CPU" { "%" }
                    "Memory" { "%" }
                    "Disk" { "%" }
                    "Network" { "%" }
                    "ProcessingTime" { "ms" }
                    "ResponseTime" { "ms" }
                    "ThroughputRate" { "req/s" }
                    "ErrorRate" { "%" }
                    "QueueLength" { "items" }
                    default { "units" }
                }
            }
        }

        # Démarrer le job de monitoring
        $monitoringJob = Start-Job -ScriptBlock {
            param($Config)

            # Fonction pour collecter les métriques système
            function Get-SystemMetrics {
                # CPU
                $cpuUsage = (Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue

                # Mémoire
                $memoryInfo = Get-CimInstance -ClassName Win32_OperatingSystem
                $memoryUsage = [Math]::Round(($memoryInfo.TotalVisibleMemorySize - $memoryInfo.FreePhysicalMemory) / $memoryInfo.TotalVisibleMemorySize * 100, 2)

                # Disque
                $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
                $diskUsage = [Math]::Round(($diskInfo.Size - $diskInfo.FreeSpace) / $diskInfo.Size * 100, 2)

                # Réseau
                $networkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
                $networkUsage = if ($null -ne $networkAdapter) {
                    $networkStats = Get-NetAdapterStatistics -Name $networkAdapter.Name
                    $totalBytes = $networkStats.ReceivedBytes + $networkStats.SentBytes
                    $maxBytes = 1GB  # Valeur arbitraire pour normaliser
                    [Math]::Min(100, [Math]::Round($totalBytes / $maxBytes * 100, 2))
                } else {
                    0
                }

                # Processus actuel
                $process = Get-Process -Id $PID
                $processingTime = $process.TotalProcessorTime.TotalMilliseconds
                $responseTime = $process.Responding ? 100 : 5000  # Valeur arbitraire
                $throughputRate = 20  # Valeur arbitraire
                $errorRate = 2  # Valeur arbitraire
                $queueLength = 15  # Valeur arbitraire

                return [PSCustomObject]@{
                    CPU            = $cpuUsage
                    Memory         = $memoryUsage
                    Disk           = $diskUsage
                    Network        = $networkUsage
                    ProcessingTime = $processingTime
                    ResponseTime   = $responseTime
                    ThroughputRate = $throughputRate
                    ErrorRate      = $errorRate
                    QueueLength    = $queueLength
                    Timestamp      = Get-Date
                }
            }

            # Fonction pour mettre à jour les métriques
            function Update-Metrics {
                param($Metrics, $NewValues)

                foreach ($metric in $Metrics.Keys) {
                    if ($NewValues.PSObject.Properties.Name -contains $metric) {
                        $value = $NewValues.$metric

                        # Mettre à jour les statistiques
                        $Metrics[$metric].CurrentValue = $value
                        $Metrics[$metric].MinValue = [Math]::Min($Metrics[$metric].MinValue, $value)
                        $Metrics[$metric].MaxValue = [Math]::Max($Metrics[$metric].MaxValue, $value)
                        $Metrics[$metric].TotalValue += $value
                        $Metrics[$metric].SampleCount++
                        $Metrics[$metric].AverageValue = $Metrics[$metric].TotalValue / $Metrics[$metric].SampleCount
                    }
                }

                return $Metrics
            }

            # Fonction pour vérifier les alertes
            function Check-Alerts {
                param($Metrics, $Thresholds)

                $alerts = @()

                foreach ($metric in $Metrics.Keys) {
                    if ($Thresholds.ContainsKey($metric)) {
                        $threshold = $Thresholds[$metric]
                        $value = $Metrics[$metric].CurrentValue

                        if ($value -gt $threshold) {
                            $alerts += [PSCustomObject]@{
                                Metric    = $metric
                                Value     = $value
                                Threshold = $threshold
                                Severity  = if ($value -gt $threshold * 1.5) { "Critical" } elseif ($value -gt $threshold * 1.2) { "High" } else { "Medium" }
                                Timestamp = Get-Date
                                Message   = "La métrique $metric a dépassé le seuil de $threshold $($Metrics[$metric].Unit) avec une valeur de $value $($Metrics[$metric].Unit)."
                            }
                        }
                    }
                }

                return $alerts
            }

            # Boucle de monitoring
            while ($Config.IsActive) {
                # Collecter les métriques
                $systemMetrics = Get-SystemMetrics

                # Mettre à jour les métriques
                $Config.Metrics = Update-Metrics -Metrics $Config.Metrics -NewValues $systemMetrics

                # Vérifier les alertes
                $newAlerts = Check-Alerts -Metrics $Config.Metrics -Thresholds $Config.AlertThresholds
                $Config.Alerts += $newAlerts

                # Ajouter à l'historique
                $Config.PerformanceHistory += [PSCustomObject]@{
                    Timestamp = $systemMetrics.Timestamp
                    Metrics   = $systemMetrics
                    Alerts    = $newAlerts
                }

                # Limiter la taille de l'historique
                if ($Config.PerformanceHistory.Count -gt 1000) {
                    $Config.PerformanceHistory = $Config.PerformanceHistory | Select-Object -Last 1000
                }

                # Sauvegarder les métriques actuelles
                $metricsFilePath = Join-Path -Path $Config.OutputPath -ChildPath "current-metrics.json"
                $Config.Metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $metricsFilePath -Encoding UTF8

                # Sauvegarder les alertes récentes
                $alertsFilePath = Join-Path -Path $Config.OutputPath -ChildPath "recent-alerts.json"
                ($Config.Alerts | Select-Object -Last 50) | ConvertTo-Json -Depth 10 | Out-File -FilePath $alertsFilePath -Encoding UTF8

                # Générer le tableau de bord si activé
                if ($Config.EnableDashboard) {
                    $dashboardFilePath = Join-Path -Path $Config.OutputPath -ChildPath "dashboard.html"

                    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Tableau de bord de performance</title>
    <meta http-equiv="refresh" content="$($Config.MonitoringIntervalSeconds)">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .metric { margin-bottom: 10px; }
        .metric-name { font-weight: bold; }
        .metric-value { font-size: 24px; }
        .metric-unit { font-size: 14px; color: #666; }
        .metric-stats { font-size: 12px; color: #666; }
        .alert { margin-bottom: 10px; padding: 10px; border-radius: 5px; }
        .alert-medium { background-color: #fff3cd; }
        .alert-high { background-color: #f8d7da; }
        .alert-critical { background-color: #dc3545; color: white; }
        .progress-bar { height: 20px; background-color: #e9ecef; border-radius: 5px; margin-bottom: 5px; }
        .progress-bar-fill { height: 100%; border-radius: 5px; }
        .cpu-fill { background-color: #007bff; }
        .memory-fill { background-color: #28a745; }
        .disk-fill { background-color: #ffc107; }
        .network-fill { background-color: #17a2b8; }
        .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
    </style>
</head>
<body>
    <h1>Tableau de bord de performance</h1>
    <p>Dernière mise à jour: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>

    <div class="grid">
        <div>
            <h2>Métriques système</h2>
"@

                    foreach ($metric in @("CPU", "Memory", "Disk", "Network")) {
                        if ($Config.Metrics.ContainsKey($metric)) {
                            $value = $Config.Metrics[$metric].CurrentValue
                            $unit = $Config.Metrics[$metric].Unit
                            $min = $Config.Metrics[$metric].MinValue
                            $max = $Config.Metrics[$metric].MaxValue
                            $avg = $Config.Metrics[$metric].AverageValue

                            $htmlContent += @"
            <div class="metric">
                <div class="metric-name">$metric</div>
                <div class="progress-bar">
                    <div class="progress-bar-fill $($metric.ToLower())-fill" style="width: $value%;"></div>
                </div>
                <div class="metric-value">$value <span class="metric-unit">$unit</span></div>
                <div class="metric-stats">Min: $min $unit, Max: $max $unit, Avg: $([Math]::Round($avg, 2)) $unit</div>
            </div>
"@
                        }
                    }

                    $htmlContent += @"
        </div>

        <div>
            <h2>Métriques d'application</h2>
"@

                    foreach ($metric in @("ProcessingTime", "ResponseTime", "ThroughputRate", "ErrorRate", "QueueLength")) {
                        if ($Config.Metrics.ContainsKey($metric)) {
                            $value = $Config.Metrics[$metric].CurrentValue
                            $unit = $Config.Metrics[$metric].Unit
                            $min = $Config.Metrics[$metric].MinValue
                            $max = $Config.Metrics[$metric].MaxValue
                            $avg = $Config.Metrics[$metric].AverageValue

                            $htmlContent += @"
            <div class="metric">
                <div class="metric-name">$metric</div>
                <div class="metric-value">$value <span class="metric-unit">$unit</span></div>
                <div class="metric-stats">Min: $min $unit, Max: $max $unit, Avg: $([Math]::Round($avg, 2)) $unit</div>
            </div>
"@
                        }
                    }

                    $htmlContent += @"
        </div>
    </div>

    <h2>Alertes récentes</h2>
"@

                    $recentAlerts = $Config.Alerts | Select-Object -Last 10

                    if ($recentAlerts.Count -eq 0) {
                        $htmlContent += @"
    <p>Aucune alerte récente.</p>
"@
                    } else {
                        foreach ($alert in $recentAlerts) {
                            $htmlContent += @"
    <div class="alert alert-$($alert.Severity.ToLower())">
        <strong>$($alert.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"))</strong> - $($alert.Message)
    </div>
"@
                        }
                    }

                    $htmlContent += @"
</body>
</html>
"@

                    $htmlContent | Out-File -FilePath $dashboardFilePath -Encoding UTF8
                }

                # Attendre l'intervalle de monitoring
                Start-Sleep -Seconds $Config.MonitoringIntervalSeconds
            }

            return $Config
        } -ArgumentList $config

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Config                = $config
            MonitoringJob         = $monitoringJob
            DashboardPath         = if ($EnableDashboard) { Join-Path -Path $sessionPath -ChildPath "dashboard.html" } else { $null }

            # Fonction pour arrêter le monitoring
            StopMonitoring        = {
                $this.Config.IsActive = $false
                $this.MonitoringJob | Stop-Job
                $this.MonitoringJob | Remove-Job
            }

            # Fonction pour obtenir les métriques actuelles
            GetCurrentMetrics     = {
                $metricsFilePath = Join-Path -Path $this.Config.OutputPath -ChildPath "current-metrics.json"

                if (Test-Path $metricsFilePath) {
                    return Get-Content -Path $metricsFilePath -Raw | ConvertFrom-Json
                } else {
                    return $null
                }
            }

            # Fonction pour obtenir les alertes récentes
            GetRecentAlerts       = {
                $alertsFilePath = Join-Path -Path $this.Config.OutputPath -ChildPath "recent-alerts.json"

                if (Test-Path $alertsFilePath) {
                    return Get-Content -Path $alertsFilePath -Raw | ConvertFrom-Json
                } else {
                    return @()
                }
            }

            # Fonction pour ouvrir le tableau de bord
            OpenDashboard         = {
                if ($this.Config.EnableDashboard -and (Test-Path $this.DashboardPath)) {
                    Start-Process $this.DashboardPath
                    return $true
                } else {
                    return $false
                }
            }

            # Fonction pour exporter les données de performance
            ExportPerformanceData = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$OutputPath,

                    [Parameter(Mandatory = $false)]
                    [ValidateSet("CSV", "JSON", "HTML")]
                    [string]$Format = "CSV"
                )

                $jobResult = $this.MonitoringJob | Receive-Job -Keep

                if ($null -ne $jobResult) {
                    $this.Config = $jobResult
                }

                $performanceData = $this.Config.PerformanceHistory

                switch ($Format) {
                    "CSV" {
                        $csvData = foreach ($entry in $performanceData) {
                            [PSCustomObject]@{
                                Timestamp      = $entry.Timestamp
                                CPU            = $entry.Metrics.CPU
                                Memory         = $entry.Metrics.Memory
                                Disk           = $entry.Metrics.Disk
                                Network        = $entry.Metrics.Network
                                ProcessingTime = $entry.Metrics.ProcessingTime
                                ResponseTime   = $entry.Metrics.ResponseTime
                                ThroughputRate = $entry.Metrics.ThroughputRate
                                ErrorRate      = $entry.Metrics.ErrorRate
                                QueueLength    = $entry.Metrics.QueueLength
                                AlertCount     = $entry.Alerts.Count
                            }
                        }

                        $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                    }
                    "JSON" {
                        $performanceData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
                    }
                    "HTML" {
                        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .chart { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de performance</h1>
    <p><strong>Période:</strong> $($performanceData[0].Timestamp) - $($performanceData[-1].Timestamp)</p>

    <h2>Graphiques de performance</h2>
    <div class="chart">
        <canvas id="systemMetricsChart"></canvas>
    </div>
    <div class="chart">
        <canvas id="appMetricsChart"></canvas>
    </div>

    <h2>Données de performance</h2>
    <table>
        <tr>
            <th>Horodatage</th>
            <th>CPU (%)</th>
            <th>Mémoire (%)</th>
            <th>Disque (%)</th>
            <th>Réseau (%)</th>
            <th>Temps de traitement (ms)</th>
            <th>Temps de réponse (ms)</th>
            <th>Débit (req/s)</th>
            <th>Taux d'erreur (%)</th>
            <th>Longueur de file</th>
            <th>Alertes</th>
        </tr>
"@

                        foreach ($entry in $performanceData) {
                            $htmlContent += @"
        <tr>
            <td>$($entry.Timestamp)</td>
            <td>$($entry.Metrics.CPU)</td>
            <td>$($entry.Metrics.Memory)</td>
            <td>$($entry.Metrics.Disk)</td>
            <td>$($entry.Metrics.Network)</td>
            <td>$($entry.Metrics.ProcessingTime)</td>
            <td>$($entry.Metrics.ResponseTime)</td>
            <td>$($entry.Metrics.ThroughputRate)</td>
            <td>$($entry.Metrics.ErrorRate)</td>
            <td>$($entry.Metrics.QueueLength)</td>
            <td>$($entry.Alerts.Count)</td>
        </tr>
"@
                        }

                        $htmlContent += @"
    </table>

    <script>
        // Données pour les graphiques
        const timestamps = [$(($performanceData | ForEach-Object { "'$($_.Timestamp.ToString("HH:mm:ss"))'" }) -join ", ")];
        const cpuData = [$(($performanceData | ForEach-Object { $_.Metrics.CPU }) -join ", ")];
        const memoryData = [$(($performanceData | ForEach-Object { $_.Metrics.Memory }) -join ", ")];
        const diskData = [$(($performanceData | ForEach-Object { $_.Metrics.Disk }) -join ", ")];
        const networkData = [$(($performanceData | ForEach-Object { $_.Metrics.Network }) -join ", ")];
        const processingTimeData = [$(($performanceData | ForEach-Object { $_.Metrics.ProcessingTime }) -join ", ")];
        const responseTimeData = [$(($performanceData | ForEach-Object { $_.Metrics.ResponseTime }) -join ", ")];
        const throughputRateData = [$(($performanceData | ForEach-Object { $_.Metrics.ThroughputRate }) -join ", ")];
        const errorRateData = [$(($performanceData | ForEach-Object { $_.Metrics.ErrorRate }) -join ", ")];
        const queueLengthData = [$(($performanceData | ForEach-Object { $_.Metrics.QueueLength }) -join ", ")];

        // Graphique des métriques système
        const systemCtx = document.getElementById('systemMetricsChart').getContext('2d');
        const systemChart = new Chart(systemCtx, {
            type: 'line',
            data: {
                labels: timestamps,
                datasets: [
                    {
                        label: 'CPU (%)',
                        data: cpuData,
                        borderColor: 'rgba(0, 123, 255, 1)',
                        backgroundColor: 'rgba(0, 123, 255, 0.1)',
                        borderWidth: 2,
                        fill: true
                    },
                    {
                        label: 'Mémoire (%)',
                        data: memoryData,
                        borderColor: 'rgba(40, 167, 69, 1)',
                        backgroundColor: 'rgba(40, 167, 69, 0.1)',
                        borderWidth: 2,
                        fill: true
                    },
                    {
                        label: 'Disque (%)',
                        data: diskData,
                        borderColor: 'rgba(255, 193, 7, 1)',
                        backgroundColor: 'rgba(255, 193, 7, 0.1)',
                        borderWidth: 2,
                        fill: true
                    },
                    {
                        label: 'Réseau (%)',
                        data: networkData,
                        borderColor: 'rgba(23, 162, 184, 1)',
                        backgroundColor: 'rgba(23, 162, 184, 0.1)',
                        borderWidth: 2,
                        fill: true
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Métriques système'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });

        // Graphique des métriques d'application
        const appCtx = document.getElementById('appMetricsChart').getContext('2d');
        const appChart = new Chart(appCtx, {
            type: 'line',
            data: {
                labels: timestamps,
                datasets: [
                    {
                        label: 'Temps de traitement (ms)',
                        data: processingTimeData,
                        borderColor: 'rgba(220, 53, 69, 1)',
                        backgroundColor: 'rgba(220, 53, 69, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Temps de réponse (ms)',
                        data: responseTimeData,
                        borderColor: 'rgba(111, 66, 193, 1)',
                        backgroundColor: 'rgba(111, 66, 193, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Débit (req/s)',
                        data: throughputRateData,
                        borderColor: 'rgba(32, 201, 151, 1)',
                        backgroundColor: 'rgba(32, 201, 151, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        yAxisID: 'y1'
                    },
                    {
                        label: 'Taux d\'erreur (%)',
                        data: errorRateData,
                        borderColor: 'rgba(253, 126, 20, 1)',
                        backgroundColor: 'rgba(253, 126, 20, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        yAxisID: 'y1'
                    },
                    {
                        label: 'Longueur de file',
                        data: queueLengthData,
                        borderColor: 'rgba(13, 202, 240, 1)',
                        backgroundColor: 'rgba(13, 202, 240, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        yAxisID: 'y1'
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Métriques d\'application'
                    }
                },
                scales: {
                    y: {
                        type: 'linear',
                        display: true,
                        position: 'left',
                        title: {
                            display: true,
                            text: 'Temps (ms)'
                        }
                    },
                    y1: {
                        type: 'linear',
                        display: true,
                        position: 'right',
                        title: {
                            display: true,
                            text: 'Autres métriques'
                        },
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

                        $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
                    }
                }

                return $OutputPath
            }
        }

        return $result
    } catch {
        Write-Error "Échec de l'activation du monitoring des performances: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour implémenter le système de prioritisation des tâches
function Enable-TaskPrioritization {
    <#
    .SYNOPSIS
        Active le système de prioritisation des tâches pour les roadmaps.

    .DESCRIPTION
        Cette fonction active le système de prioritisation des tâches pour les roadmaps,
        permettant d'optimiser l'ordre d'exécution des tâches en fonction de leur importance.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats de la prioritisation.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER PriorityLevels
        Le nombre de niveaux de priorité.
        Par défaut, 10 niveaux.

    .PARAMETER PriorityFactors
        Les facteurs à prendre en compte pour la prioritisation et leur poids.
        Par défaut, tous les facteurs ont un poids égal.

    .PARAMETER EnableDynamicPrioritization
        Indique si la prioritisation dynamique est activée.
        Par défaut, $true.

    .EXAMPLE
        Enable-TaskPrioritization -RoadmapPath "C:\Roadmaps\roadmap.md" -PriorityLevels 5 -PriorityFactors @{ Deadline = 0.5; Dependencies = 0.3; Complexity = 0.2 }
        Active le système de prioritisation des tâches avec 5 niveaux de priorité et des poids personnalisés pour les facteurs.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$PriorityLevels = 10,

        [Parameter(Mandatory = $false)]
        [hashtable]$PriorityFactors = @{
            Deadline             = 0.25
            Dependencies         = 0.25
            Complexity           = 0.2
            StrategicImportance  = 0.2
            ResourceAvailability = 0.1
        },

        [Parameter(Mandatory = $false)]
        [bool]$EnableDynamicPrioritization = $true
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }

        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "TaskPrioritization"
        }

        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        # Générer un identifiant unique pour cette exécution
        $executionId = [Guid]::NewGuid().ToString()
        $executionPath = Join-Path -Path $OutputPath -ChildPath $executionId

        # Créer le dossier d'exécution
        if (-not (Test-Path $executionPath)) {
            New-Item -Path $executionPath -ItemType Directory -Force | Out-Null
        }

        # Analyser la roadmap pour extraire les tâches
        Write-Verbose "Extraction des tâches de la roadmap..."
        $roadmapContent = Get-Content -Path $RoadmapPath
        $parsedRoadmap = Parse-RoadmapContent -Content $roadmapContent
        $tasks = $parsedRoadmap.Tasks

        Write-Verbose "Nombre total de tâches: $($tasks.Count)"

        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            RoadmapPath                 = $RoadmapPath
            OutputPath                  = $executionPath
            PriorityLevels              = $PriorityLevels
            PriorityFactors             = $PriorityFactors
            EnableDynamicPrioritization = $EnableDynamicPrioritization
            StartTime                   = Get-Date
            Tasks                       = $tasks
            PrioritizedTasks            = @()
            TaskDependencies            = @{}
            TaskDeadlines               = @{}
            TaskComplexities            = @{}
            TaskStrategicImportance     = @{}
            TaskResourceAvailability    = @{}
        }

        # Analyser les dépendances entre les tâches
        foreach ($task in $tasks) {
            $taskId = $task.Id
            $config.TaskDependencies[$taskId] = @()

            # Trouver les dépendances explicites
            if ($task.PSObject.Properties.Name.Contains("Dependencies") -and $null -ne $task.Dependencies) {
                $config.TaskDependencies[$taskId] += $task.Dependencies
            }

            # Trouver les dépendances implicites (tâches parentes)
            if ($task.PSObject.Properties.Name.Contains("ParentId") -and -not [string]::IsNullOrEmpty($task.ParentId)) {
                $config.TaskDependencies[$taskId] += $task.ParentId
            }
        }

        # Estimer les dates limites, la complexité, l'importance stratégique et la disponibilité des ressources
        foreach ($task in $tasks) {
            $taskId = $task.Id

            # Date limite
            if ($task.PSObject.Properties.Name.Contains("DueDate") -and -not [string]::IsNullOrEmpty($task.DueDate)) {
                $config.TaskDeadlines[$taskId] = [DateTime]::Parse($task.DueDate)
            } else {
                # Estimer une date limite par défaut (30 jours à partir de maintenant)
                $config.TaskDeadlines[$taskId] = (Get-Date).AddDays(30)
            }

            # Complexité
            if ($task.PSObject.Properties.Name.Contains("Complexity") -and -not [string]::IsNullOrEmpty($task.Complexity)) {
                $config.TaskComplexities[$taskId] = switch ($task.Complexity.ToLower()) {
                    "low" { 1 }
                    "medium" { 2 }
                    "high" { 3 }
                    default { 2 }
                }
            } else {
                # Estimer la complexité par défaut
                $config.TaskComplexities[$taskId] = 2
            }

            # Importance stratégique
            if ($task.PSObject.Properties.Name.Contains("StrategicImportance") -and -not [string]::IsNullOrEmpty($task.StrategicImportance)) {
                $config.TaskStrategicImportance[$taskId] = switch ($task.StrategicImportance.ToLower()) {
                    "low" { 1 }
                    "medium" { 2 }
                    "high" { 3 }
                    default { 2 }
                }
            } else {
                # Estimer l'importance stratégique par défaut
                $config.TaskStrategicImportance[$taskId] = 2
            }

            # Disponibilité des ressources
            if ($task.PSObject.Properties.Name.Contains("ResourceAvailability") -and -not [string]::IsNullOrEmpty($task.ResourceAvailability)) {
                $config.TaskResourceAvailability[$taskId] = switch ($task.ResourceAvailability.ToLower()) {
                    "low" { 1 }
                    "medium" { 2 }
                    "high" { 3 }
                    default { 2 }
                }
            } else {
                # Estimer la disponibilité des ressources par défaut
                $config.TaskResourceAvailability[$taskId] = 2
            }
        }

        # Fonction pour calculer la priorité d'une tâche
        function Calculate-TaskPriority {
            param(
                [Parameter(Mandatory = $true)]
                [string]$TaskId,

                [Parameter(Mandatory = $true)]
                [PSObject]$Config
            )

            $task = $Config.Tasks | Where-Object { $_.Id -eq $TaskId }

            if ($null -eq $task) {
                return 0
            }

            # Vérifier si la tâche est déjà terminée
            if ($task.PSObject.Properties.Name.Contains("Status") -and $task.Status -eq "Completed") {
                return 0
            }

            # Calculer le score pour chaque facteur
            $deadlineScore = 0
            $dependenciesScore = 0
            $complexityScore = 0
            $strategicImportanceScore = 0
            $resourceAvailabilityScore = 0

            # Score de date limite
            if ($Config.TaskDeadlines.ContainsKey($TaskId)) {
                $daysUntilDeadline = ($Config.TaskDeadlines[$TaskId] - (Get-Date)).TotalDays
                $deadlineScore = if ($daysUntilDeadline -le 0) { 10 } else { [Math]::Max(1, 10 - [Math]::Floor($daysUntilDeadline / 3)) }
            }

            # Score de dépendances
            if ($Config.TaskDependencies.ContainsKey($TaskId)) {
                $dependencies = $Config.TaskDependencies[$TaskId]
                $completedDependencies = 0

                foreach ($depId in $dependencies) {
                    $depTask = $Config.Tasks | Where-Object { $_.Id -eq $depId }

                    if ($null -ne $depTask -and $depTask.PSObject.Properties.Name.Contains("Status") -and $depTask.Status -eq "Completed") {
                        $completedDependencies++
                    }
                }

                $dependenciesScore = if ($dependencies.Count -eq 0) { 10 } else { [Math]::Round(($completedDependencies / $dependencies.Count) * 10) }
            } else {
                $dependenciesScore = 10
            }

            # Score de complexité
            if ($Config.TaskComplexities.ContainsKey($TaskId)) {
                $complexityScore = 11 - $Config.TaskComplexities[$TaskId] * 3
            }

            # Score d'importance stratégique
            if ($Config.TaskStrategicImportance.ContainsKey($TaskId)) {
                $strategicImportanceScore = $Config.TaskStrategicImportance[$TaskId] * 3
            }

            # Score de disponibilité des ressources
            if ($Config.TaskResourceAvailability.ContainsKey($TaskId)) {
                $resourceAvailabilityScore = $Config.TaskResourceAvailability[$TaskId] * 3
            }

            # Calculer le score total pondéré
            $totalScore =
            $deadlineScore * $Config.PriorityFactors.Deadline +
            $dependenciesScore * $Config.PriorityFactors.Dependencies +
            $complexityScore * $Config.PriorityFactors.Complexity +
            $strategicImportanceScore * $Config.PriorityFactors.StrategicImportance +
            $resourceAvailabilityScore * $Config.PriorityFactors.ResourceAvailability

            # Normaliser le score sur l'échelle de priorité
            $priority = [Math]::Max(1, [Math]::Min($Config.PriorityLevels, [Math]::Ceiling($totalScore * $Config.PriorityLevels / 10)))

            return $priority
        }

        # Calculer la priorité pour chaque tâche
        $prioritizedTasks = @()

        foreach ($task in $tasks) {
            $priority = Calculate-TaskPriority -TaskId $task.Id -Config $config

            $prioritizedTask = $task.PSObject.Copy()
            $prioritizedTask | Add-Member -MemberType NoteProperty -Name "Priority" -Value $priority -Force

            $prioritizedTasks += $prioritizedTask
        }

        # Trier les tâches par priorité (décroissante)
        $prioritizedTasks = $prioritizedTasks | Sort-Object -Property Priority -Descending

        # Mettre à jour la configuration
        $config.PrioritizedTasks = $prioritizedTasks

        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $executionPath -ChildPath "prioritized-tasks.json"
        $prioritizedTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Config                = $config
            PrioritizedTasks      = $prioritizedTasks
            ResultFilePath        = $resultFilePath

            # Fonction pour recalculer les priorités
            RecalculatePriorities = {
                $updatedTasks = @()

                foreach ($task in $this.Config.Tasks) {
                    $priority = Calculate-TaskPriority -TaskId $task.Id -Config $this.Config

                    $updatedTask = $task.PSObject.Copy()
                    $updatedTask | Add-Member -MemberType NoteProperty -Name "Priority" -Value $priority -Force

                    $updatedTasks += $updatedTask
                }

                # Trier les tâches par priorité (décroissante)
                $updatedTasks = $updatedTasks | Sort-Object -Property Priority -Descending

                # Mettre à jour la configuration
                $this.Config.PrioritizedTasks = $updatedTasks
                $this.PrioritizedTasks = $updatedTasks

                # Sauvegarder les résultats
                $this.PrioritizedTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.ResultFilePath -Encoding UTF8

                return $this.PrioritizedTasks
            }

            # Fonction pour obtenir les tâches prioritaires
            GetTopPriorityTasks   = {
                param(
                    [Parameter(Mandatory = $false)]
                    [int]$Count = 10
                )

                return $this.PrioritizedTasks | Select-Object -First $Count
            }
        }

        return $result
    } catch {
        Write-Error "Échec de l'activation du système de prioritisation des tâches: $($_.Exception.Message)"
        return $null
    }
}
