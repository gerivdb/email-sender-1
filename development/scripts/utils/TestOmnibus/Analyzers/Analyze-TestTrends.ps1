<#
.SYNOPSIS
    Analyse les tendances des rÃ©sultats des tests au fil du temps.
.DESCRIPTION
    Ce script analyse les rÃ©sultats des tests au fil du temps pour identifier
    les tendances, comme les tests qui Ã©chouent de plus en plus souvent,
    les tests qui deviennent plus lents, etc.
.PARAMETER HistoryPath
    Chemin vers le rÃ©pertoire contenant l'historique des rÃ©sultats des tests.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
.PARAMETER DaysToAnalyze
    Nombre de jours Ã  analyser.
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats de l'analyse.
.EXAMPLE
    .\Analyze-TestTrends.ps1 -HistoryPath "D:\TestHistory" -OutputPath "D:\TestResults\Trends" -DaysToAnalyze 30 -GenerateReport
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$HistoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Trends"),
    
    [Parameter(Mandatory = $false)]
    [int]$DaysToAnalyze = 30,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# VÃ©rifier que le chemin de l'historique existe
if (-not (Test-Path -Path $HistoryPath)) {
    Write-Error "Le chemin de l'historique n'existe pas: $HistoryPath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour charger l'historique des rÃ©sultats des tests
function Get-TestHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath,
        
        [Parameter(Mandatory = $true)]
        [int]$DaysToAnalyze
    )
    
    try {
        # Calculer la date de dÃ©but
        $startDate = (Get-Date).AddDays(-$DaysToAnalyze)
        
        # Rechercher tous les fichiers de rÃ©sultats
        $resultFiles = Get-ChildItem -Path $HistoryPath -Filter "results_*.xml" -Recurse | 
                       Where-Object { $_.LastWriteTime -ge $startDate } |
                       Sort-Object LastWriteTime
        
        if ($resultFiles.Count -eq 0) {
            Write-Warning "Aucun fichier de rÃ©sultats trouvÃ© pour la pÃ©riode spÃ©cifiÃ©e."
            return @()
        }
        
        # Charger les rÃ©sultats
        $history = @()
        
        foreach ($file in $resultFiles) {
            try {
                $results = Import-Clixml -Path $file.FullName
                
                # Ajouter la date d'exÃ©cution
                $executionDate = $file.LastWriteTime
                
                # CrÃ©er un objet d'historique
                $historyEntry = [PSCustomObject]@{
                    Date = $executionDate
                    Results = $results
                    TotalCount = $results.Count
                    PassedCount = ($results | Where-Object { $_.Success }).Count
                    FailedCount = ($results | Where-Object { -not $_.Success }).Count
                    TotalDuration = ($results | Measure-Object -Property Duration -Sum).Sum
                    AverageDuration = ($results | Measure-Object -Property Duration -Average).Average
                    FilePath = $file.FullName
                }
                
                $history += $historyEntry
            }
            catch {
                Write-Warning "Erreur lors du chargement du fichier $($file.FullName): $_"
            }
        }
        
        return $history
    }
    catch {
        Write-Error "Erreur lors du chargement de l'historique des rÃ©sultats: $_"
        return @()
    }
}

# Fonction pour analyser les tendances des tests
function Get-TestTrends {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$History
    )
    
    try {
        # VÃ©rifier qu'il y a suffisamment de donnÃ©es
        if ($History.Count -lt 2) {
            Write-Warning "Pas assez de donnÃ©es pour analyser les tendances (minimum 2 exÃ©cutions)."
            return $null
        }
        
        # CrÃ©er un dictionnaire pour stocker les tendances par test
        $testTrends = @{}
        
        # Identifier tous les tests uniques
        $allTests = @()
        foreach ($entry in $History) {
            foreach ($result in $entry.Results) {
                if ($allTests -notcontains $result.Name) {
                    $allTests += $result.Name
                }
            }
        }
        
        # Analyser les tendances pour chaque test
        foreach ($testName in $allTests) {
            # Extraire l'historique de ce test
            $testHistory = @()
            
            foreach ($entry in $History) {
                $testResult = $entry.Results | Where-Object { $_.Name -eq $testName } | Select-Object -First 1
                
                if ($testResult) {
                    $testHistory += [PSCustomObject]@{
                        Date = $entry.Date
                        Success = $testResult.Success
                        Duration = $testResult.Duration
                        ErrorMessage = $testResult.ErrorMessage
                    }
                }
            }
            
            # Calculer les tendances
            $successRate = ($testHistory | Where-Object { $_.Success } | Measure-Object).Count / $testHistory.Count
            $failureRate = 1 - $successRate
            
            # Calculer la tendance de durÃ©e
            $durationTrend = 0
            if ($testHistory.Count -gt 1) {
                $firstDuration = $testHistory[0].Duration
                $lastDuration = $testHistory[-1].Duration
                
                if ($firstDuration -gt 0) {
                    $durationTrend = ($lastDuration - $firstDuration) / $firstDuration
                }
            }
            
            # Calculer la tendance de stabilitÃ©
            $stabilityTrend = 0
            if ($testHistory.Count -gt 1) {
                $changes = 0
                for ($i = 1; $i -lt $testHistory.Count; $i++) {
                    if ($testHistory[$i].Success -ne $testHistory[$i-1].Success) {
                        $changes++
                    }
                }
                
                $stabilityTrend = $changes / ($testHistory.Count - 1)
            }
            
            # DÃ©terminer si le test est flaky
            $isFlaky = $stabilityTrend -gt 0.3  # Plus de 30% de changements
            
            # Ajouter les tendances au dictionnaire
            $testTrends[$testName] = [PSCustomObject]@{
                Name = $testName
                SuccessRate = $successRate
                FailureRate = $failureRate
                DurationTrend = $durationTrend
                StabilityTrend = $stabilityTrend
                IsFlaky = $isFlaky
                History = $testHistory
                LastResult = $testHistory[-1]
                FirstResult = $testHistory[0]
            }
        }
        
        return $testTrends
    }
    catch {
        Write-Error "Erreur lors de l'analyse des tendances: $_"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML des tendances
function New-TrendReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestTrends,
        
        [Parameter(Mandatory = $true)]
        [array]$History,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        # CrÃ©er le chemin du rapport
        $reportPath = Join-Path -Path $OutputPath -ChildPath "trend_report.html"
        
        # GÃ©nÃ©rer le contenu HTML
        $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tendances des tests</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
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
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .success {
            color: #2ecc71;
        }
        .failure {
            color: #e74c3c;
        }
        .warning {
            color: #f39c12;
        }
        .neutral {
            color: #3498db;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        .trend-summary {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .trend-item {
            flex: 1;
            text-align: center;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin: 0 5px;
        }
        .trend-item h3 {
            margin-top: 0;
        }
        .trend-value {
            font-size: 2em;
            font-weight: bold;
        }
        .trend-positive {
            color: #2ecc71;
        }
        .trend-negative {
            color: #e74c3c;
        }
        .trend-neutral {
            color: #3498db;
        }
        .flaky-test {
            background-color: #fff3cd;
        }
        .progress {
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            overflow: hidden;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 100%;
            color: white;
            text-align: center;
            line-height: 20px;
        }
        .progress-bar-success {
            background-color: #2ecc71;
        }
        .progress-bar-warning {
            background-color: #f39c12;
        }
        .progress-bar-danger {
            background-color: #e74c3c;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport de tendances des tests</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
        <p>PÃ©riode analysÃ©e: $($History[0].Date.ToString("dd/MM/yyyy")) - $($History[-1].Date.ToString("dd/MM/yyyy"))</p>
        
        <div class="trend-summary">
            <div class="trend-item">
                <h3>Taux de rÃ©ussite global</h3>
                <div class="trend-value $((if (($History[-1].PassedCount / $History[-1].TotalCount) -ge 0.9) { "trend-positive" } elseif (($History[-1].PassedCount / $History[-1].TotalCount) -ge 0.7) { "trend-neutral" } else { "trend-negative" }))">
                    $([math]::Round(($History[-1].PassedCount / $History[-1].TotalCount) * 100, 2))%
                </div>
                <p>$($History[-1].PassedCount) / $($History[-1].TotalCount) tests</p>
            </div>
            <div class="trend-item">
                <h3>Tests instables (flaky)</h3>
                <div class="trend-value $((if (($TestTrends.Values | Where-Object { $_.IsFlaky } | Measure-Object).Count -eq 0) { "trend-positive" } elseif (($TestTrends.Values | Where-Object { $_.IsFlaky } | Measure-Object).Count -le 2) { "trend-neutral" } else { "trend-negative" }))">
                    $(($TestTrends.Values | Where-Object { $_.IsFlaky } | Measure-Object).Count)
                </div>
                <p>sur $($TestTrends.Count) tests</p>
            </div>
            <div class="trend-item">
                <h3>DurÃ©e moyenne</h3>
                <div class="trend-value $((if ($History[-1].AverageDuration -lt $History[0].AverageDuration) { "trend-positive" } elseif ($History[-1].AverageDuration -le ($History[0].AverageDuration * 1.1)) { "trend-neutral" } else { "trend-negative" }))">
                    $([math]::Round($History[-1].AverageDuration, 2)) ms
                </div>
                <p>$([math]::Round(($History[-1].AverageDuration - $History[0].AverageDuration) / $History[0].AverageDuration * 100, 2))% depuis le dÃ©but</p>
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="successRateChart"></canvas>
        </div>
        
        <div class="chart-container">
            <canvas id="durationChart"></canvas>
        </div>
        
        <h2>Tests instables (flaky)</h2>
"@

        # Ajouter la section des tests flaky
        $flakyTests = $TestTrends.Values | Where-Object { $_.IsFlaky } | Sort-Object -Property StabilityTrend -Descending
        
        if ($flakyTests.Count -gt 0) {
            $htmlReport += @"
        <table>
            <tr>
                <th>Test</th>
                <th>Taux de rÃ©ussite</th>
                <th>Tendance de stabilitÃ©</th>
                <th>Tendance de durÃ©e</th>
                <th>Dernier rÃ©sultat</th>
            </tr>
"@
            
            foreach ($test in $flakyTests) {
                $successRatePercent = [math]::Round($test.SuccessRate * 100, 2)
                $stabilityTrendPercent = [math]::Round($test.StabilityTrend * 100, 2)
                $durationTrendPercent = [math]::Round($test.DurationTrend * 100, 2)
                $lastResultClass = if ($test.LastResult.Success) { "success" } else { "failure" }
                $lastResultText = if ($test.LastResult.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
                
                $htmlReport += @"
            <tr class="flaky-test">
                <td>$($test.Name)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($successRatePercent -ge 80) { "progress-bar-success" } elseif ($successRatePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $successRatePercent%">
                            $successRatePercent%
                        </div>
                    </div>
                </td>
                <td>$stabilityTrendPercent% de changements</td>
                <td>$durationTrendPercent%</td>
                <td class="$lastResultClass">$lastResultText</td>
            </tr>
"@
            }
            
            $htmlReport += @"
        </table>
"@
        }
        else {
            $htmlReport += @"
        <p>Aucun test instable dÃ©tectÃ©.</p>
"@
        }
        
        # Ajouter la section des tendances par test
        $htmlReport += @"
        <h2>Tendances par test</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Taux de rÃ©ussite</th>
                <th>Tendance de durÃ©e</th>
                <th>StabilitÃ©</th>
                <th>Dernier rÃ©sultat</th>
            </tr>
"@
        
        foreach ($test in ($TestTrends.Values | Sort-Object -Property SuccessRate -Descending)) {
            $successRatePercent = [math]::Round($test.SuccessRate * 100, 2)
            $durationTrendPercent = [math]::Round($test.DurationTrend * 100, 2)
            $stabilityClass = if ($test.IsFlaky) { "warning" } else { "success" }
            $stabilityText = if ($test.IsFlaky) { "Instable" } else { "Stable" }
            $lastResultClass = if ($test.LastResult.Success) { "success" } else { "failure" }
            $lastResultText = if ($test.LastResult.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
            
            $htmlReport += @"
            <tr>
                <td>$($test.Name)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($successRatePercent -ge 80) { "progress-bar-success" } elseif ($successRatePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $successRatePercent%">
                            $successRatePercent%
                        </div>
                    </div>
                </td>
                <td class="$((if ($durationTrendPercent -lt 0) { "success" } elseif ($durationTrendPercent -lt 10) { "neutral" } else { "failure" }))">$durationTrendPercent%</td>
                <td class="$stabilityClass">$stabilityText</td>
                <td class="$lastResultClass">$lastResultText</td>
            </tr>
"@
        }
        
        $htmlReport += @"
        </table>
        
        <h2>Historique des exÃ©cutions</h2>
        <table>
            <tr>
                <th>Date</th>
                <th>Tests rÃ©ussis</th>
                <th>Tests Ã©chouÃ©s</th>
                <th>DurÃ©e totale</th>
                <th>DurÃ©e moyenne</th>
            </tr>
"@
        
        foreach ($entry in $History) {
            $htmlReport += @"
            <tr>
                <td>$($entry.Date.ToString("dd/MM/yyyy HH:mm:ss"))</td>
                <td class="success">$($entry.PassedCount)</td>
                <td class="$((if ($entry.FailedCount -eq 0) { "success" } else { "failure" }))">$($entry.FailedCount)</td>
                <td>$([math]::Round($entry.TotalDuration, 2)) ms</td>
                <td>$([math]::Round($entry.AverageDuration, 2)) ms</td>
            </tr>
"@
        }
        
        $htmlReport += @"
        </table>
        
        <script>
            // CrÃ©er un graphique du taux de rÃ©ussite
            const successRateCtx = document.getElementById('successRateChart').getContext('2d');
            const successRateChart = new Chart(successRateCtx, {
                type: 'line',
                data: {
                    labels: [$(($History | ForEach-Object { "'" + $_.Date.ToString("dd/MM/yyyy") + "'" }) -join ", ")],
                    datasets: [{
                        label: 'Taux de rÃ©ussite (%)',
                        data: [$(($History | ForEach-Object { [math]::Round(($_.PassedCount / $_.TotalCount) * 100, 2) }) -join ", ")],
                        backgroundColor: 'rgba(46, 204, 113, 0.2)',
                        borderColor: 'rgba(46, 204, 113, 1)',
                        borderWidth: 1,
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100
                        }
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: 'Ã‰volution du taux de rÃ©ussite'
                        }
                    }
                }
            });
            
            // CrÃ©er un graphique de la durÃ©e moyenne
            const durationCtx = document.getElementById('durationChart').getContext('2d');
            const durationChart = new Chart(durationCtx, {
                type: 'line',
                data: {
                    labels: [$(($History | ForEach-Object { "'" + $_.Date.ToString("dd/MM/yyyy") + "'" }) -join ", ")],
                    datasets: [{
                        label: 'DurÃ©e moyenne (ms)',
                        data: [$(($History | ForEach-Object { [math]::Round($_.AverageDuration, 2) }) -join ", ")],
                        backgroundColor: 'rgba(52, 152, 219, 0.2)',
                        borderColor: 'rgba(52, 152, 219, 1)',
                        borderWidth: 1,
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        title: {
                            display: true,
                            text: 'Ã‰volution de la durÃ©e moyenne des tests'
                        }
                    }
                }
            });
        </script>
        
        <div class="footer">
            <p>GÃ©nÃ©rÃ© par TestOmnibus Trend Analyzer</p>
        </div>
    </div>
</body>
</html>
"@
        
        # Enregistrer le rapport HTML
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($reportPath, $htmlReport, $utf8WithBom)
        
        return $reportPath
    }
    catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de tendances: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # Charger l'historique des rÃ©sultats des tests
    Write-Host "Chargement de l'historique des rÃ©sultats des tests..." -ForegroundColor Cyan
    $history = Get-TestHistory -HistoryPath $HistoryPath -DaysToAnalyze $DaysToAnalyze
    
    if ($history.Count -eq 0) {
        Write-Warning "Aucun historique de rÃ©sultats trouvÃ©."
        return 1
    }
    
    Write-Host "Historique chargÃ©: $($history.Count) exÃ©cutions" -ForegroundColor Green
    
    # Analyser les tendances
    Write-Host "Analyse des tendances..." -ForegroundColor Cyan
    $testTrends = Get-TestTrends -History $history
    
    if (-not $testTrends) {
        Write-Warning "Impossible d'analyser les tendances."
        return 1
    }
    
    Write-Host "Tendances analysÃ©es pour $($testTrends.Count) tests" -ForegroundColor Green
    
    # Identifier les tests flaky
    $flakyTests = $testTrends.Values | Where-Object { $_.IsFlaky }
    Write-Host "Tests instables (flaky) dÃ©tectÃ©s: $($flakyTests.Count)" -ForegroundColor Yellow
    
    foreach ($test in $flakyTests) {
        Write-Host "  - $($test.Name) (stabilitÃ©: $([math]::Round($test.StabilityTrend * 100, 2))%)" -ForegroundColor Yellow
    }
    
    # GÃ©nÃ©rer un rapport si demandÃ©
    if ($GenerateReport) {
        Write-Host "GÃ©nÃ©ration du rapport de tendances..." -ForegroundColor Cyan
        $reportPath = New-TrendReport -TestTrends $testTrends -History $history -OutputPath $OutputPath
        
        if ($reportPath) {
            Write-Host "Rapport de tendances gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
        }
    }
    
    # Retourner les rÃ©sultats
    return [PSCustomObject]@{
        History = $history
        Trends = $testTrends
        FlakyTests = $flakyTests
        ReportPath = if ($GenerateReport) { $reportPath } else { $null }
    }
}
catch {
    Write-Error "Erreur lors de l'analyse des tendances: $_"
    return 1
}
