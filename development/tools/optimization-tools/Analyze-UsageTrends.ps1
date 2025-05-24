<#
.SYNOPSIS
    Analyse les tendances d'utilisation des scripts.
.DESCRIPTION
    Ce script analyse les donnÃ©es d'utilisation pour identifier les tendances
    et les patterns d'utilisation des scripts au fil du temps.
.EXAMPLE
    .\Analyze-UsageTrends.ps1 -PeriodDays 30
.NOTES
    Version: 1.0
    Date: 15/05/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = "",

    [Parameter(Mandatory = $false)]
    [int]$PeriodDays = 30,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports\trends"
)

# Importer le module UsageMonitor existant
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\UsageMonitor\UsageMonitor.psm1"
if (Test-Path -Path $usageMonitorPath) {
    Import-Module $usageMonitorPath -Force
} else {
    Write-Error "Module UsageMonitor non trouvÃ©: $usageMonitorPath"
    exit 1
}

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "TITLE"   = "Cyan"
    }

    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"

    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour analyser les tendances d'utilisation
function Test-ScriptUsageTrends {
    [CmdletBinding()]
    param (
        [int]$PeriodDays = 30
    )

    Write-Log "Analyse des tendances d'utilisation sur les $PeriodDays derniers jours..." -Level "TITLE"

    # Obtenir toutes les mÃ©triques d'utilisation
    $allMetrics = @{}
    $startDate = (Get-Date).AddDays(-$PeriodDays)

    # RÃ©cupÃ©rer les mÃ©triques pour chaque script
    $scriptPaths = Get-AllScriptPaths

    foreach ($scriptPath in $scriptPaths) {
        $metrics = Get-MetricsForScript -ScriptPath $scriptPath

        # Filtrer les mÃ©triques par pÃ©riode
        $filteredMetrics = $metrics | Where-Object { $_.StartTime -ge $startDate }

        if ($filteredMetrics.Count -gt 0) {
            $allMetrics[$scriptPath] = $filteredMetrics
        }
    }

    # Analyser les tendances
    $trends = @{
        DailyUsage          = @{}
        HourlyUsage         = @{}
        PerformanceTrends   = @{}
        FailureRateTrends   = @{}
        ResourceUsageTrends = @{}
    }

    # Analyser l'utilisation quotidienne
    $dailyUsage = @{}
    $currentDate = $startDate
    $endDate = Get-Date

    while ($currentDate -le $endDate) {
        $dateKey = $currentDate.ToString("yyyy-MM-dd")
        $dailyUsage[$dateKey] = @{}
        $currentDate = $currentDate.AddDays(1)
    }

    foreach ($scriptPath in $allMetrics.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf

        foreach ($metric in $allMetrics[$scriptPath]) {
            $dateKey = $metric.StartTime.ToString("yyyy-MM-dd")

            if (-not $dailyUsage[$dateKey].ContainsKey($scriptName)) {
                $dailyUsage[$dateKey][$scriptName] = 0
            }

            $dailyUsage[$dateKey][$scriptName]++
        }
    }

    $trends.DailyUsage = $dailyUsage

    # Analyser l'utilisation horaire
    $hourlyUsage = @{}

    for ($hour = 0; $hour -lt 24; $hour++) {
        $hourlyUsage[$hour] = @{}
    }

    foreach ($scriptPath in $allMetrics.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf

        foreach ($metric in $allMetrics[$scriptPath]) {
            $hour = $metric.StartTime.Hour

            if (-not $hourlyUsage[$hour].ContainsKey($scriptName)) {
                $hourlyUsage[$hour][$scriptName] = 0
            }

            $hourlyUsage[$hour][$scriptName]++
        }
    }

    $trends.HourlyUsage = $hourlyUsage

    # Analyser les tendances de performance
    $performanceTrends = @{}

    foreach ($scriptPath in $allMetrics.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $performanceTrends[$scriptName] = @{}

        # Regrouper par semaine
        $weeklyMetrics = $allMetrics[$scriptPath] | Group-Object -Property { Get-Date -Date $_.StartTime -UFormat %V }

        foreach ($weekGroup in $weeklyMetrics) {
            $weekNumber = $weekGroup.Name
            $successfulExecutions = $weekGroup.Group | Where-Object { $_.Success }

            if ($successfulExecutions.Count -gt 0) {
                $avgDuration = ($successfulExecutions | Measure-Object -Property { $_.Duration.TotalMilliseconds } -Average).Average
                $performanceTrends[$scriptName][$weekNumber] = [math]::Round($avgDuration, 2)
            }
        }
    }

    $trends.PerformanceTrends = $performanceTrends

    # Analyser les tendances de taux d'Ã©chec
    $failureRateTrends = @{}

    foreach ($scriptPath in $allMetrics.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $failureRateTrends[$scriptName] = @{}

        # Regrouper par semaine
        $weeklyMetrics = $allMetrics[$scriptPath] | Group-Object -Property { Get-Date -Date $_.StartTime -UFormat %V }

        foreach ($weekGroup in $weeklyMetrics) {
            $weekNumber = $weekGroup.Name
            $totalExecutions = $weekGroup.Group.Count
            $failedExecutions = ($weekGroup.Group | Where-Object { -not $_.Success }).Count

            if ($totalExecutions -gt 0) {
                $failureRate = ($failedExecutions / $totalExecutions) * 100
                $failureRateTrends[$scriptName][$weekNumber] = [math]::Round($failureRate, 2)
            }
        }
    }

    $trends.FailureRateTrends = $failureRateTrends

    # Analyser les tendances d'utilisation des ressources
    $resourceUsageTrends = @{}

    foreach ($scriptPath in $allMetrics.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $resourceUsageTrends[$scriptName] = @{
            CPU    = @{}
            Memory = @{}
        }

        # Regrouper par semaine
        $weeklyMetrics = $allMetrics[$scriptPath] | Group-Object -Property { Get-Date -Date $_.StartTime -UFormat %V }

        foreach ($weekGroup in $weeklyMetrics) {
            $weekNumber = $weekGroup.Name
            $metricsWithResourceUsage = $weekGroup.Group | Where-Object {
                $_.ResourceUsage -and
                $_.ResourceUsage.CpuUsageStart -and
                $_.ResourceUsage.CpuUsageEnd -and
                $_.ResourceUsage.MemoryUsageStart -and
                $_.ResourceUsage.MemoryUsageEnd
            }

            if ($metricsWithResourceUsage.Count -gt 0) {
                $avgCpuUsage = ($metricsWithResourceUsage | Measure-Object -Property { $_.ResourceUsage.CpuUsageEnd - $_.ResourceUsage.CpuUsageStart } -Average).Average
                $avgMemoryUsage = ($metricsWithResourceUsage | Measure-Object -Property { ($_.ResourceUsage.MemoryUsageEnd - $_.ResourceUsage.MemoryUsageStart) / 1MB } -Average).Average

                $resourceUsageTrends[$scriptName].CPU[$weekNumber] = [math]::Round($avgCpuUsage, 2)
                $resourceUsageTrends[$scriptName].Memory[$weekNumber] = [math]::Round($avgMemoryUsage, 2)
            }
        }
    }

    $trends.ResourceUsageTrends = $resourceUsageTrends

    # Afficher les rÃ©sultats
    Write-Log "Tendances d'utilisation quotidienne:" -Level "INFO"
    $topDays = $dailyUsage.GetEnumerator() | Sort-Object -Property { ($_.Value.Values | Measure-Object -Sum).Sum } -Descending | Select-Object -First 5

    foreach ($day in $topDays) {
        $totalUsage = ($day.Value.Values | Measure-Object -Sum).Sum
        Write-Log "  - $($day.Key): $totalUsage exÃ©cutions" -Level "INFO"
    }

    Write-Log "Tendances d'utilisation horaire:" -Level "INFO"
    $topHours = $hourlyUsage.GetEnumerator() | Sort-Object -Property { ($_.Value.Values | Measure-Object -Sum).Sum } -Descending | Select-Object -First 5

    foreach ($hour in $topHours) {
        $totalUsage = ($hour.Value.Values | Measure-Object -Sum).Sum
        Write-Log "  - $($hour.Key):00: $totalUsage exÃ©cutions" -Level "INFO"
    }

    Write-Log "Scripts avec amÃ©lioration de performance:" -Level "INFO"
    $improvingScripts = @()

    foreach ($scriptName in $performanceTrends.Keys) {
        $weeks = $performanceTrends[$scriptName].Keys | Sort-Object

        if ($weeks.Count -ge 2) {
            $firstWeek = $weeks[0]
            $lastWeek = $weeks[-1]

            $firstWeekPerf = $performanceTrends[$scriptName][$firstWeek]
            $lastWeekPerf = $performanceTrends[$scriptName][$lastWeek]

            if ($firstWeekPerf -gt $lastWeekPerf) {
                $improvement = (($firstWeekPerf - $lastWeekPerf) / $firstWeekPerf) * 100
                $improvingScripts += [PSCustomObject]@{
                    ScriptName    = $scriptName
                    Improvement   = [math]::Round($improvement, 2)
                    FirstWeekPerf = $firstWeekPerf
                    LastWeekPerf  = $lastWeekPerf
                }
            }
        }
    }

    $improvingScripts = $improvingScripts | Sort-Object -Property Improvement -Descending | Select-Object -First 5

    foreach ($script in $improvingScripts) {
        Write-Log "  - $($script.ScriptName): AmÃ©lioration de $($script.Improvement)% ($($script.FirstWeekPerf) ms -> $($script.LastWeekPerf) ms)" -Level "SUCCESS"
    }

    Write-Log "Scripts avec dÃ©gradation de performance:" -Level "INFO"
    $degradingScripts = @()

    foreach ($scriptName in $performanceTrends.Keys) {
        $weeks = $performanceTrends[$scriptName].Keys | Sort-Object

        if ($weeks.Count -ge 2) {
            $firstWeek = $weeks[0]
            $lastWeek = $weeks[-1]

            $firstWeekPerf = $performanceTrends[$scriptName][$firstWeek]
            $lastWeekPerf = $performanceTrends[$scriptName][$lastWeek]

            if ($firstWeekPerf -lt $lastWeekPerf) {
                $degradation = (($lastWeekPerf - $firstWeekPerf) / $firstWeekPerf) * 100
                $degradingScripts += [PSCustomObject]@{
                    ScriptName    = $scriptName
                    Degradation   = [math]::Round($degradation, 2)
                    FirstWeekPerf = $firstWeekPerf
                    LastWeekPerf  = $lastWeekPerf
                }
            }
        }
    }

    $degradingScripts = $degradingScripts | Sort-Object -Property Degradation -Descending | Select-Object -First 5

    foreach ($script in $degradingScripts) {
        Write-Log "  - $($script.ScriptName): DÃ©gradation de $($script.Degradation)% ($($script.FirstWeekPerf) ms -> $($script.LastWeekPerf) ms)" -Level "WARNING"
    }

    return $trends
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-TrendReport {
    param (
        [hashtable]$Trends,
        [string]$OutputPath
    )

    Write-Log "GÃ©nÃ©ration du rapport de tendances d'utilisation..." -Level "TITLE"

    # CrÃ©er le dossier de sortie s'il n'existe pas
    $reportDir = Join-Path -Path $PSScriptRoot -ChildPath $OutputPath
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $reportFile = Join-Path -Path $reportDir -ChildPath "usage_trends_$(Get-Date -Format 'yyyy-MM-dd').html"

    # GÃ©nÃ©rer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des tendances d'utilisation des scripts</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .improvement {
            color: #2ecc71;
        }
        .degradation {
            color: #e74c3c;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport des tendances d'utilisation des scripts</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm")</p>

        <h2>Utilisation quotidienne</h2>
        <div class="chart-container">
            <canvas id="dailyUsageChart"></canvas>
        </div>

        <h2>Utilisation horaire</h2>
        <div class="chart-container">
            <canvas id="hourlyUsageChart"></canvas>
        </div>

        <h2>Tendances de performance</h2>
        <div class="chart-container">
            <canvas id="performanceChart"></canvas>
        </div>

        <h2>Tendances de taux d'Ã©chec</h2>
        <div class="chart-container">
            <canvas id="failureRateChart"></canvas>
        </div>

        <h2>Tendances d'utilisation des ressources</h2>
        <div class="chart-container">
            <canvas id="resourceUsageChart"></canvas>
        </div>

        <script>
            // DonnÃ©es pour les graphiques
            const dailyUsageData = {
                labels: [$(($Trends.DailyUsage.Keys | Sort-Object | ForEach-Object { "'$_'" }) -join ', ')],
                datasets: [
"@

    # Ajouter les datasets pour l'utilisation quotidienne
    $topScripts = @()
    foreach ($day in $Trends.DailyUsage.Values) {
        foreach ($script in $day.Keys) {
            if ($topScripts -notcontains $script) {
                $topScripts += $script
            }
        }
    }

    $topScripts = $topScripts | Select-Object -First 5
    $colorIndex = 0
    $colors = @(
        "rgba(54, 162, 235, 0.5)",
        "rgba(255, 99, 132, 0.5)",
        "rgba(255, 206, 86, 0.5)",
        "rgba(75, 192, 192, 0.5)",
        "rgba(153, 102, 255, 0.5)"
    )

    foreach ($script in $topScripts) {
        $data = @()
        foreach ($day in $Trends.DailyUsage.Keys | Sort-Object) {
            if ($Trends.DailyUsage[$day].ContainsKey($script)) {
                $data += $Trends.DailyUsage[$day][$script]
            } else {
                $data += 0
            }
        }

        $color = $colors[$colorIndex % $colors.Count]
        $borderColor = $color -replace "0.5", "1"

        $htmlContent += @"
                    {
                        label: '$script',
                        data: [$(($data) -join ', ')],
                        backgroundColor: '$color',
                        borderColor: '$borderColor',
                        borderWidth: 1
                    },
"@

        $colorIndex++
    }

    # Supprimer la virgule finale
    $htmlContent = $htmlContent.TrimEnd(",`r`n")

    $htmlContent += @"
                ]
            };

            const hourlyUsageData = {
                labels: [$(0..23 | ForEach-Object { "'$_:00'" } | Join-String -Separator ', ')],
                datasets: [
"@

    # Ajouter les datasets pour l'utilisation horaire
    $topScripts = @()
    foreach ($hour in $Trends.HourlyUsage.Values) {
        foreach ($script in $hour.Keys) {
            if ($topScripts -notcontains $script) {
                $topScripts += $script
            }
        }
    }

    $topScripts = $topScripts | Select-Object -First 5
    $colorIndex = 0

    foreach ($script in $topScripts) {
        $data = @()
        foreach ($hour in 0..23) {
            if ($Trends.HourlyUsage[$hour].ContainsKey($script)) {
                $data += $Trends.HourlyUsage[$hour][$script]
            } else {
                $data += 0
            }
        }

        $color = $colors[$colorIndex % $colors.Count]
        $borderColor = $color -replace "0.5", "1"

        $htmlContent += @"
                    {
                        label: '$script',
                        data: [$(($data) -join ', ')],
                        backgroundColor: '$color',
                        borderColor: '$borderColor',
                        borderWidth: 1
                    },
"@

        $colorIndex++
    }

    # Supprimer la virgule finale
    $htmlContent = $htmlContent.TrimEnd(",`r`n")

    $htmlContent += @"
                ]
            };

            const performanceData = {
                labels: ['Semaine 1', 'Semaine 2', 'Semaine 3', 'Semaine 4'],
                datasets: [
"@

    # Ajouter les datasets pour les tendances de performance
    $topScripts = $Trends.PerformanceTrends.Keys | Select-Object -First 5
    $colorIndex = 0

    foreach ($script in $topScripts) {
        $data = @()
        $weeks = $Trends.PerformanceTrends[$script].Keys | Sort-Object

        for ($i = 0; $i -lt 4; $i++) {
            if ($i -lt $weeks.Count) {
                $week = $weeks[$i]
                $data += $Trends.PerformanceTrends[$script][$week]
            } else {
                $data += "null"
            }
        }

        $color = $colors[$colorIndex % $colors.Count]
        $borderColor = $color -replace "0.5", "1"

        $htmlContent += @"
                    {
                        label: '$script',
                        data: [$(($data) -join ', ')],
                        backgroundColor: '$color',
                        borderColor: '$borderColor',
                        borderWidth: 1
                    },
"@

        $colorIndex++
    }

    # Supprimer la virgule finale
    $htmlContent = $htmlContent.TrimEnd(",`r`n")

    $htmlContent += @"
                ]
            };

            const failureRateData = {
                labels: ['Semaine 1', 'Semaine 2', 'Semaine 3', 'Semaine 4'],
                datasets: [
"@

    # Ajouter les datasets pour les tendances de taux d'Ã©chec
    $topScripts = $Trends.FailureRateTrends.Keys | Select-Object -First 5
    $colorIndex = 0

    foreach ($script in $topScripts) {
        $data = @()
        $weeks = $Trends.FailureRateTrends[$script].Keys | Sort-Object

        for ($i = 0; $i -lt 4; $i++) {
            if ($i -lt $weeks.Count) {
                $week = $weeks[$i]
                $data += $Trends.FailureRateTrends[$script][$week]
            } else {
                $data += "null"
            }
        }

        $color = $colors[$colorIndex % $colors.Count]
        $borderColor = $color -replace "0.5", "1"

        $htmlContent += @"
                    {
                        label: '$script',
                        data: [$(($data) -join ', ')],
                        backgroundColor: '$color',
                        borderColor: '$borderColor',
                        borderWidth: 1
                    },
"@

        $colorIndex++
    }

    # Supprimer la virgule finale
    $htmlContent = $htmlContent.TrimEnd(",`r`n")

    $htmlContent += @"
                ]
            };

            const resourceUsageData = {
                labels: ['Semaine 1', 'Semaine 2', 'Semaine 3', 'Semaine 4'],
                datasets: [
"@

    # Ajouter les datasets pour les tendances d'utilisation des ressources
    $topScripts = $Trends.ResourceUsageTrends.Keys | Select-Object -First 3
    $colorIndex = 0

    foreach ($script in $topScripts) {
        $cpuData = @()
        $memoryData = @()
        $cpuWeeks = $Trends.ResourceUsageTrends[$script].CPU.Keys | Sort-Object
        $memoryWeeks = $Trends.ResourceUsageTrends[$script].Memory.Keys | Sort-Object

        for ($i = 0; $i -lt 4; $i++) {
            if ($i -lt $cpuWeeks.Count) {
                $week = $cpuWeeks[$i]
                $cpuData += $Trends.ResourceUsageTrends[$script].CPU[$week]
            } else {
                $cpuData += "null"
            }

            if ($i -lt $memoryWeeks.Count) {
                $week = $memoryWeeks[$i]
                $memoryData += $Trends.ResourceUsageTrends[$script].Memory[$week]
            } else {
                $memoryData += "null"
            }
        }

        $cpuColor = $colors[$colorIndex % $colors.Count]
        $cpuBorderColor = $cpuColor -replace "0.5", "1"

        $memoryColor = $colors[($colorIndex + 1) % $colors.Count]
        $memoryBorderColor = $memoryColor -replace "0.5", "1"

        $htmlContent += @"
                    {
                        label: '$script (CPU)',
                        data: [$(($cpuData) -join ', ')],
                        backgroundColor: '$cpuColor',
                        borderColor: '$cpuBorderColor',
                        borderWidth: 1
                    },
                    {
                        label: '$script (MÃ©moire)',
                        data: [$(($memoryData) -join ', ')],
                        backgroundColor: '$memoryColor',
                        borderColor: '$memoryBorderColor',
                        borderWidth: 1
                    },
"@

        $colorIndex += 2
    }

    # Supprimer la virgule finale
    $htmlContent = $htmlContent.TrimEnd(",`r`n")

    $htmlContent += @"
                ]
            };

            // CrÃ©er les graphiques
            window.onload = function() {
                const dailyUsageCtx = document.getElementById('dailyUsageChart').getContext('2d');
                new Chart(dailyUsageCtx, {
                    type: 'line',
                    data: dailyUsageData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });

                const hourlyUsageCtx = document.getElementById('hourlyUsageChart').getContext('2d');
                new Chart(hourlyUsageCtx, {
                    type: 'bar',
                    data: hourlyUsageData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });

                const performanceCtx = document.getElementById('performanceChart').getContext('2d');
                new Chart(performanceCtx, {
                    type: 'line',
                    data: performanceData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });

                const failureRateCtx = document.getElementById('failureRateChart').getContext('2d');
                new Chart(failureRateCtx, {
                    type: 'line',
                    data: failureRateData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: 100
                            }
                        }
                    }
                });

                const resourceUsageCtx = document.getElementById('resourceUsageChart').getContext('2d');
                new Chart(resourceUsageCtx, {
                    type: 'line',
                    data: resourceUsageData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });
            };
        </script>

        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© par le systÃ¨me d'analyse des tendances d'utilisation</p>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $reportFile -Encoding utf8 -Force

    Write-Log "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $reportFile" -Level "SUCCESS"

    return $reportFile
}

# Point d'entrÃ©e principal
try {
    # Initialiser le moniteur d'utilisation
    if ([string]::IsNullOrEmpty($DatabasePath)) {
        $DatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "usage_data.xml"
    }

    Initialize-UsageMonitor -DatabasePath $DatabasePath
    Write-Log "Moniteur d'utilisation initialisÃ© avec la base de donnÃ©es: $DatabasePath" -Level "SUCCESS"

    # Analyser les tendances d'utilisation
    $trends = Test-ScriptUsageTrends -PeriodDays $PeriodDays

    # GÃ©nÃ©rer un rapport si demandÃ©
    if ($GenerateReport) {
        $reportFile = New-TrendReport -Trends $trends -OutputPath $ReportPath

        # Ouvrir le rapport dans le navigateur par dÃ©faut
        if (Test-Path -Path $reportFile) {
            Start-Process $reportFile
        }
    }
} catch {
    Write-Log "Erreur lors de l'exÃ©cution du script: $_" -Level "ERROR"
    exit 1
}

