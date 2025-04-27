﻿#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport HTML dÃ©taillÃ© Ã  partir des rÃ©sultats de tests de performance.
.DESCRIPTION
    Ce script prend les fichiers JSON de rÃ©sultats de tests de performance et gÃ©nÃ¨re
    un rapport HTML dÃ©taillÃ© avec des graphiques et des analyses.
.PARAMETER ResultsPath
    Chemin vers le fichier JSON de rÃ©sultats de test de performance ou un tableau de chemins.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport HTML gÃ©nÃ©rÃ©.
.PARAMETER Title
    Titre du rapport. Par dÃ©faut: "Rapport de performance".
.PARAMETER CompareMode
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport de comparaison entre plusieurs fichiers de rÃ©sultats.
.EXAMPLE
    .\New-PerformanceReport.ps1 -ResultsPath "load_test_results.json" -OutputPath "performance_report.html"
.EXAMPLE
    .\New-PerformanceReport.ps1 -ResultsPath @("baseline_results.json", "current_results.json") -OutputPath "comparison_report.html" -CompareMode
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [object]$ResultsPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Title = "Rapport de performance",
    
    [Parameter(Mandatory = $false)]
    [switch]$CompareMode
)

# Fonction pour charger les rÃ©sultats de test
function Get-TestResults {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        throw "Le fichier de rÃ©sultats n'existe pas: $Path"
    }
    
    try {
        $results = Get-Content -Path $Path -Raw | ConvertFrom-Json
        return $results
    }
    catch {
        throw "Erreur lors du chargement des rÃ©sultats: $_"
    }
}

# Fonction pour gÃ©nÃ©rer un graphique en HTML/CSS/JS
function New-Chart {
    param (
        [string]$ChartId,
        [string]$ChartType,
        [string]$Title,
        [array]$Labels,
        [array]$Datasets,
        [hashtable]$Options = @{}
    )
    
    $datasetsJson = $Datasets | ConvertTo-Json -Depth 5
    $optionsJson = $Options | ConvertTo-Json -Depth 5
    $labelsJson = $Labels | ConvertTo-Json
    
    $chartHtml = @"
<div class="chart-container">
    <canvas id="$ChartId"></canvas>
</div>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('$ChartId').getContext('2d');
        new Chart(ctx, {
            type: '$ChartType',
            data: {
                labels: $labelsJson,
                datasets: $datasetsJson
            },
            options: $optionsJson
        });
    });
</script>
"@
    
    return $chartHtml
}

# Fonction pour gÃ©nÃ©rer un rapport de test unique
function New-SingleTestReport {
    param (
        [object]$Results,
        [string]$Title
    )
    
    # PrÃ©parer les donnÃ©es pour les graphiques
    $responseTimeData = @{
        label = "Temps de rÃ©ponse (ms)"
        data = @($Results.MinResponseMs, $Results.MedianResponseMs, $Results.AvgResponseMs, $Results.P90ResponseMs, $Results.P95ResponseMs, $Results.P99ResponseMs, $Results.MaxResponseMs)
        backgroundColor = "rgba(54, 162, 235, 0.5)"
        borderColor = "rgba(54, 162, 235, 1)"
        borderWidth = 1
    }
    
    $responseTimeLabels = @("Min", "MÃ©diane", "Moyenne", "P90", "P95", "P99", "Max")
    
    $responseTimeOptions = @{
        responsive = $true
        plugins = @{
            title = @{
                display = $true
                text = "Distribution des temps de rÃ©ponse"
            }
            legend = @{
                display = $false
            }
        }
        scales = @{
            y = @{
                beginAtZero = $true
                title = @{
                    display = $true
                    text = "Temps (ms)"
                }
            }
        }
    }
    
    # CrÃ©er le graphique de temps de rÃ©ponse
    $responseTimeChart = New-Chart -ChartId "responseTimeChart" -ChartType "bar" -Title "Distribution des temps de rÃ©ponse" -Labels $responseTimeLabels -Datasets @($responseTimeData) -Options $responseTimeOptions
    
    # Si des donnÃ©es de performance sont disponibles, crÃ©er un graphique de performance
    $performanceChart = ""
    if ($Results.Performance -and $Results.Performance.Count -gt 0) {
        $timestamps = @($Results.Performance | ForEach-Object { $_.Timestamp })
        $cpuData = @($Results.Performance | ForEach-Object { $_.CPU })
        $memoryData = @($Results.Performance | ForEach-Object { $_.WorkingSet / 1MB })
        
        $cpuDataset = @{
            label = "CPU (%)"
            data = $cpuData
            backgroundColor = "rgba(255, 99, 132, 0.2)"
            borderColor = "rgba(255, 99, 132, 1)"
            borderWidth = 1
            yAxisID = "y"
        }
        
        $memoryDataset = @{
            label = "MÃ©moire (MB)"
            data = $memoryData
            backgroundColor = "rgba(75, 192, 192, 0.2)"
            borderColor = "rgba(75, 192, 192, 1)"
            borderWidth = 1
            yAxisID = "y1"
        }
        
        $performanceOptions = @{
            responsive = $true
            plugins = @{
                title = @{
                    display = $true
                    text = "Utilisation des ressources pendant le test"
                }
            }
            scales = @{
                y = @{
                    type = "linear"
                    display = $true
                    position = "left"
                    title = @{
                        display = $true
                        text = "CPU (%)"
                    }
                }
                y1 = @{
                    type = "linear"
                    display = $true
                    position = "right"
                    title = @{
                        display = $true
                        text = "MÃ©moire (MB)"
                    }
                    grid = @{
                        drawOnChartArea = $false
                    }
                }
            }
        }
        
        $performanceChart = New-Chart -ChartId "performanceChart" -ChartType "line" -Title "Utilisation des ressources" -Labels $timestamps -Datasets @($cpuDataset, $memoryDataset) -Options $performanceOptions
    }
    
    # GÃ©nÃ©rer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .metric-title {
            font-size: 0.9em;
            color: #6c757d;
            margin-bottom: 5px;
        }
        .metric-value {
            font-size: 1.8em;
            font-weight: bold;
            color: #2c3e50;
        }
        .metric-unit {
            font-size: 0.8em;
            color: #6c757d;
        }
        .chart-container {
            margin-bottom: 30px;
            height: 400px;
        }
        .section {
            margin-bottom: 40px;
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
            background-color: #f5f5f5;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>$Title</h1>
        <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="section">
        <h2>RÃ©sumÃ© du test</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">DurÃ©e du test</div>
                <div class="metric-value">$([Math]::Round($Results.TotalExecTime, 2))<span class="metric-unit">s</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">RequÃªtes totales</div>
                <div class="metric-value">$($Results.TotalRequests)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">RequÃªtes par seconde</div>
                <div class="metric-value">$([Math]::Round($Results.RequestsPerSecond, 2))</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps de rÃ©ponse moyen</div>
                <div class="metric-value">$([Math]::Round($Results.AvgResponseMs, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps de rÃ©ponse mÃ©dian</div>
                <div class="metric-value">$([Math]::Round($Results.MedianResponseMs, 2))<span class="metric-unit">ms</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Ã‰cart type</div>
                <div class="metric-value">$([Math]::Round($Results.StandardDeviation, 2))<span class="metric-unit">ms</span></div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Temps de rÃ©ponse</h2>
        $responseTimeChart
    </div>
    
    <div class="section">
        <h2>DÃ©tails du test</h2>
        <table>
            <tr>
                <th>MÃ©trique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Date de dÃ©but</td>
                <td>$($Results.StartTime)</td>
            </tr>
            <tr>
                <td>DurÃ©e configurÃ©e</td>
                <td>$($Results.Duration) secondes</td>
            </tr>
            <tr>
                <td>Concurrence</td>
                <td>$($Results.Concurrency)</td>
            </tr>
            <tr>
                <td>RequÃªtes rÃ©ussies</td>
                <td>$($Results.SuccessCount)</td>
            </tr>
            <tr>
                <td>RequÃªtes en erreur</td>
                <td>$($Results.ErrorCount)</td>
            </tr>
            <tr>
                <td>Taux d'erreur</td>
                <td>$([Math]::Round(($Results.ErrorCount / $Results.TotalRequests) * 100, 2))%</td>
            </tr>
            <tr>
                <td>Temps de rÃ©ponse minimum</td>
                <td>$([Math]::Round($Results.MinResponseMs, 2)) ms</td>
            </tr>
            <tr>
                <td>Temps de rÃ©ponse maximum</td>
                <td>$([Math]::Round($Results.MaxResponseMs, 2)) ms</td>
            </tr>
            <tr>
                <td>P90</td>
                <td>$([Math]::Round($Results.P90ResponseMs, 2)) ms</td>
            </tr>
            <tr>
                <td>P95</td>
                <td>$([Math]::Round($Results.P95ResponseMs, 2)) ms</td>
            </tr>
            <tr>
                <td>P99</td>
                <td>$([Math]::Round($Results.P99ResponseMs, 2)) ms</td>
            </tr>
        </table>
    </div>
    
    <div class="section">
        <h2>Informations systÃ¨me</h2>
        <table>
            <tr>
                <th>MÃ©trique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Version PowerShell</td>
                <td>$($Results.System.PSVersion)</td>
            </tr>
            <tr>
                <td>SystÃ¨me d'exploitation</td>
                <td>$($Results.System.OS)</td>
            </tr>
            <tr>
                <td>Nombre de processeurs</td>
                <td>$($Results.System.ProcessorCount)</td>
            </tr>
            <tr>
                <td>MÃ©moire (GB)</td>
                <td>$($Results.System.Memory)</td>
            </tr>
        </table>
    </div>
    
    $(if ($performanceChart) {
        @"
    <div class="section">
        <h2>Utilisation des ressources</h2>
        $performanceChart
    </div>
"@
    })
    
    <div class="footer">
        <p>Rapport gÃ©nÃ©rÃ© par Simple-PRLoadTest.ps1</p>
    </div>
</body>
</html>
"@
    
    return $html
}

# Fonction pour gÃ©nÃ©rer un rapport de comparaison
function New-ComparisonReport {
    param (
        [array]$ResultsList,
        [array]$Labels,
        [string]$Title
    )
    
    # PrÃ©parer les donnÃ©es pour les graphiques de comparaison
    $rpsData = @()
    $responseTimeData = @()
    $p95Data = @()
    
    for ($i = 0; $i -lt $ResultsList.Count; $i++) {
        $color = "hsl($($i * 360 / $ResultsList.Count), 70%, 60%)"
        $lightColor = "hsla($($i * 360 / $ResultsList.Count), 70%, 60%, 0.2)"
        
        $rpsData += @{
            label = $Labels[$i]
            data = @($ResultsList[$i].RequestsPerSecond)
            backgroundColor = $lightColor
            borderColor = $color
            borderWidth = 1
        }
        
        $responseTimeData += @{
            label = $Labels[$i]
            data = @($ResultsList[$i].AvgResponseMs)
            backgroundColor = $lightColor
            borderColor = $color
            borderWidth = 1
        }
        
        $p95Data += @{
            label = $Labels[$i]
            data = @($ResultsList[$i].P95ResponseMs)
            backgroundColor = $lightColor
            borderColor = $color
            borderWidth = 1
        }
    }
    
    # CrÃ©er les graphiques de comparaison
    $rpsOptions = @{
        responsive = $true
        plugins = @{
            title = @{
                display = $true
                text = "Comparaison des requÃªtes par seconde"
            }
        }
        scales = @{
            y = @{
                beginAtZero = $true
                title = @{
                    display = $true
                    text = "RequÃªtes par seconde"
                }
            }
        }
    }
    
    $responseTimeOptions = @{
        responsive = $true
        plugins = @{
            title = @{
                display = $true
                text = "Comparaison des temps de rÃ©ponse moyens"
            }
        }
        scales = @{
            y = @{
                beginAtZero = $true
                title = @{
                    display = $true
                    text = "Temps (ms)"
                }
            }
        }
    }
    
    $p95Options = @{
        responsive = $true
        plugins = @{
            title = @{
                display = $true
                text = "Comparaison des temps de rÃ©ponse P95"
            }
        }
        scales = @{
            y = @{
                beginAtZero = $true
                title = @{
                    display = $true
                    text = "Temps (ms)"
                }
            }
        }
    }
    
    $rpsChart = New-Chart -ChartId "rpsComparisonChart" -ChartType "bar" -Title "Comparaison des requÃªtes par seconde" -Labels @("RequÃªtes par seconde") -Datasets $rpsData -Options $rpsOptions
    
    $responseTimeChart = New-Chart -ChartId "responseTimeComparisonChart" -ChartType "bar" -Title "Comparaison des temps de rÃ©ponse moyens" -Labels @("Temps de rÃ©ponse moyen") -Datasets $responseTimeData -Options $responseTimeOptions
    
    $p95Chart = New-Chart -ChartId "p95ComparisonChart" -ChartType "bar" -Title "Comparaison des temps de rÃ©ponse P95" -Labels @("P95") -Datasets $p95Data -Options $p95Options
    
    # PrÃ©parer le tableau de comparaison dÃ©taillÃ©
    $comparisonTable = "<table><tr><th>MÃ©trique</th>"
    
    foreach ($label in $Labels) {
        $comparisonTable += "<th>$label</th>"
    }
    
    $comparisonTable += "</tr>"
    
    $metrics = @(
        @{ Name = "DurÃ©e du test (s)"; Property = "TotalExecTime" },
        @{ Name = "RequÃªtes totales"; Property = "TotalRequests" },
        @{ Name = "RequÃªtes par seconde"; Property = "RequestsPerSecond" },
        @{ Name = "Temps de rÃ©ponse min (ms)"; Property = "MinResponseMs" },
        @{ Name = "Temps de rÃ©ponse mÃ©dian (ms)"; Property = "MedianResponseMs" },
        @{ Name = "Temps de rÃ©ponse moyen (ms)"; Property = "AvgResponseMs" },
        @{ Name = "Temps de rÃ©ponse max (ms)"; Property = "MaxResponseMs" },
        @{ Name = "P90 (ms)"; Property = "P90ResponseMs" },
        @{ Name = "P95 (ms)"; Property = "P95ResponseMs" },
        @{ Name = "P99 (ms)"; Property = "P99ResponseMs" },
        @{ Name = "Ã‰cart type (ms)"; Property = "StandardDeviation" }
    )
    
    foreach ($metric in $metrics) {
        $comparisonTable += "<tr><td>$($metric.Name)</td>"
        
        foreach ($result in $ResultsList) {
            $value = $result.$($metric.Property)
            if ($value -is [double]) {
                $value = [Math]::Round($value, 2)
            }
            $comparisonTable += "<td>$value</td>"
        }
        
        $comparisonTable += "</tr>"
    }
    
    $comparisonTable += "</table>"
    
    # GÃ©nÃ©rer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .chart-container {
            margin-bottom: 30px;
            height: 400px;
        }
        .section {
            margin-bottom: 40px;
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
            background-color: #f5f5f5;
        }
        .footer {
            text-align: center;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>$Title</h1>
        <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="section">
        <h2>Comparaison des performances</h2>
        <div class="chart-container">
            $rpsChart
        </div>
        <div class="chart-container">
            $responseTimeChart
        </div>
        <div class="chart-container">
            $p95Chart
        </div>
    </div>
    
    <div class="section">
        <h2>Comparaison dÃ©taillÃ©e</h2>
        $comparisonTable
    </div>
    
    <div class="section">
        <h2>Analyse</h2>
        <p>Ce rapport compare les performances entre diffÃ©rents tests. Voici quelques observations :</p>
        <ul>
            $(
                $baselineRps = $ResultsList[0].RequestsPerSecond
                $baselineResponseTime = $ResultsList[0].AvgResponseMs
                
                for ($i = 1; $i -lt $ResultsList.Count; $i++) {
                    $rpsChange = ($ResultsList[$i].RequestsPerSecond - $baselineRps) / $baselineRps * 100
                    $responseTimeChange = ($ResultsList[$i].AvgResponseMs - $baselineResponseTime) / $baselineResponseTime * 100
                    
                    $rpsChangeText = if ($rpsChange -ge 0) { "augmentation" } else { "diminution" }
                    $responseTimeChangeText = if ($responseTimeChange -ge 0) { "augmentation" } else { "diminution" }
                    
                    "<li>Comparaison entre $($Labels[0]) et $($Labels[$i]) : $([Math]::Abs([Math]::Round($rpsChange, 2)))% de $rpsChangeText des requÃªtes par seconde et $([Math]::Abs([Math]::Round($responseTimeChange, 2)))% de $responseTimeChangeText du temps de rÃ©ponse moyen.</li>"
                }
            )
        </ul>
    </div>
    
    <div class="footer">
        <p>Rapport gÃ©nÃ©rÃ© par New-PerformanceReport.ps1</p>
    </div>
</body>
</html>
"@
    
    return $html
}

# Fonction principale
function Main {
    # VÃ©rifier que le rÃ©pertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        if ($PSCmdlet.ShouldProcess($outputDir, "CrÃ©er le rÃ©pertoire")) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
    }
    
    if ($CompareMode) {
        # Mode comparaison
        if ($ResultsPath -isnot [array]) {
            $ResultsPath = @($ResultsPath)
        }
        
        if ($ResultsPath.Count -lt 2) {
            throw "Le mode comparaison nÃ©cessite au moins deux fichiers de rÃ©sultats."
        }
        
        $resultsList = @()
        $labels = @()
        
        for ($i = 0; $i -lt $ResultsPath.Count; $i++) {
            $path = $ResultsPath[$i]
            $results = Get-TestResults -Path $path
            $resultsList += $results
            
            # Utiliser le nom du fichier comme Ã©tiquette par dÃ©faut
            $label = [System.IO.Path]::GetFileNameWithoutExtension($path)
            $labels += $label
        }
        
        $html = New-ComparisonReport -ResultsList $resultsList -Labels $labels -Title $Title
    }
    else {
        # Mode rapport unique
        if ($ResultsPath -is [array]) {
            $ResultsPath = $ResultsPath[0]
        }
        
        $results = Get-TestResults -Path $ResultsPath
        $html = New-SingleTestReport -Results $results -Title $Title
    }
    
    # Enregistrer le rapport HTML
    if ($PSCmdlet.ShouldProcess($OutputPath, "Enregistrer le rapport HTML")) {
        $html | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
    }
}

# ExÃ©cuter le script
Main
