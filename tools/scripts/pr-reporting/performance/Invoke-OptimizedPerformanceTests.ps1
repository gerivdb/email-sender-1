#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de performance avec une parallÃ©lisation optimisÃ©e.
.DESCRIPTION
    Ce script utilise des techniques avancÃ©es de parallÃ©lisation pour exÃ©cuter
    des tests de performance tout en optimisant l'utilisation des ressources systÃ¨me.
.PARAMETER TestScripts
    Tableau de chemins vers les scripts de test Ã  exÃ©cuter.
.PARAMETER TestParameters
    ParamÃ¨tres Ã  passer aux scripts de test.
.PARAMETER Iterations
    Nombre d'itÃ©rations Ã  exÃ©cuter pour chaque test. Par dÃ©faut: 3.
.PARAMETER ThrottleLimit
    Nombre maximum de tests Ã  exÃ©cuter en parallÃ¨le. Par dÃ©faut: nombre de processeurs - 1.
.PARAMETER AdaptiveThrottling
    Si spÃ©cifiÃ©, ajuste dynamiquement le nombre de tests en parallÃ¨le en fonction de l'utilisation des ressources.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats agrÃ©gÃ©s. Par dÃ©faut: "./optimized-perf-results.json".
.PARAMETER GenerateReport
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.EXAMPLE
    .\Invoke-OptimizedPerformanceTests.ps1 -TestScripts @(".\Simple-PRLoadTest.ps1") -Iterations 5 -AdaptiveThrottling
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$TestScripts,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$TestParameters = @{},
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 3,
    
    [Parameter(Mandatory = $false)]
    [int]$ThrottleLimit = 0,
    
    [Parameter(Mandatory = $false)]
    [switch]$AdaptiveThrottling,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./optimized-perf-results.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de parallÃ©lisation optimisÃ©e
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallÃ©lisation optimisÃ©e non trouvÃ©: $modulePath"
}

Import-Module $modulePath -Force

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-OptimizedTestReport {
    param (
        [object]$Results,
        [string]$OutputPath
    )
    
    # PrÃ©parer les donnÃ©es pour les graphiques
    $testNames = @()
    $avgResponseTimes = @()
    $successRates = @()
    $executionTimes = @()
    
    # Regrouper les rÃ©sultats par script de test
    $groupedResults = $Results.TestResults | Group-Object -Property TestScript
    
    foreach ($group in $groupedResults) {
        $testName = Split-Path -Path $group.Name -Leaf
        $testNames += $testName
        
        # Calculer le temps de rÃ©ponse moyen
        $avgResponseTime = 0
        $successCount = 0
        $totalExecutionTime = 0
        
        foreach ($result in $group.Group) {
            if ($result.Success -and $result.Result -ne $null) {
                if ($result.Result.PSObject.Properties.Name -contains "AvgResponseMs") {
                    $avgResponseTime += $result.Result.AvgResponseMs
                }
                
                if ($result.Result.PSObject.Properties.Name -contains "TotalExecTime") {
                    $totalExecutionTime += $result.Result.TotalExecTime
                }
                
                $successCount++
            }
        }
        
        if ($successCount -gt 0) {
            $avgResponseTime = $avgResponseTime / $successCount
            $totalExecutionTime = $totalExecutionTime / $successCount
        }
        
        $avgResponseTimes += $avgResponseTime
        $successRates += ($successCount / $group.Group.Count) * 100
        $executionTimes += $totalExecutionTime
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests de performance optimisÃ©s</title>
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
        <h1>Rapport de tests de performance optimisÃ©s</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="section">
        <h2>RÃ©sumÃ©</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Tests exÃ©cutÃ©s</div>
                <div class="metric-value">$($Results.TotalTests)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Tests rÃ©ussis</div>
                <div class="metric-value">$($Results.SuccessCount)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Tests en erreur</div>
                <div class="metric-value">$($Results.ErrorCount)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Taux de rÃ©ussite</div>
                <div class="metric-value">$([Math]::Round(($Results.SuccessCount / $Results.TotalTests) * 100, 2))<span class="metric-unit">%</span></div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Temps de rÃ©ponse moyen par test</h2>
        <div class="chart-container">
            <canvas id="responseTimeChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Taux de rÃ©ussite par test</h2>
        <div class="chart-container">
            <canvas id="successRateChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Temps d'exÃ©cution par test</h2>
        <div class="chart-container">
            <canvas id="executionTimeChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>DÃ©tails des tests</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>ItÃ©rations</th>
                <th>RÃ©ussites</th>
                <th>Erreurs</th>
                <th>Temps de rÃ©ponse moyen (ms)</th>
                <th>Temps d'exÃ©cution moyen (s)</th>
            </tr>
            $(
                foreach ($group in $groupedResults) {
                    $testName = Split-Path -Path $group.Name -Leaf
                    $successCount = ($group.Group | Where-Object { $_.Success } | Measure-Object).Count
                    $errorCount = $group.Group.Count - $successCount
                    
                    $avgResponseTime = 0
                    $totalExecutionTime = 0
                    $validResults = 0
                    
                    foreach ($result in $group.Group) {
                        if ($result.Success -and $result.Result -ne $null) {
                            if ($result.Result.PSObject.Properties.Name -contains "AvgResponseMs") {
                                $avgResponseTime += $result.Result.AvgResponseMs
                            }
                            
                            if ($result.Result.PSObject.Properties.Name -contains "TotalExecTime") {
                                $totalExecutionTime += $result.Result.TotalExecTime
                            }
                            
                            $validResults++
                        }
                    }
                    
                    if ($validResults -gt 0) {
                        $avgResponseTime = $avgResponseTime / $validResults
                        $totalExecutionTime = $totalExecutionTime / $validResults
                    }
                    
                    "<tr>
                        <td>$testName</td>
                        <td>$($group.Group.Count)</td>
                        <td>$successCount</td>
                        <td>$errorCount</td>
                        <td>$([Math]::Round($avgResponseTime, 2))</td>
                        <td>$([Math]::Round($totalExecutionTime, 2))</td>
                    </tr>"
                }
            )
        </table>
    </div>
    
    <div class="footer">
        <p>Rapport gÃ©nÃ©rÃ© par Invoke-OptimizedPerformanceTests.ps1</p>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique des temps de rÃ©ponse
            const responseTimeCtx = document.getElementById('responseTimeChart').getContext('2d');
            new Chart(responseTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps de rÃ©ponse moyen (ms)',
                        data: $($avgResponseTimes | ConvertTo-Json),
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Temps de rÃ©ponse moyen par test'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Temps (ms)'
                            }
                        }
                    }
                }
            });
            
            // Graphique des taux de rÃ©ussite
            const successRateCtx = document.getElementById('successRateChart').getContext('2d');
            new Chart(successRateCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Taux de rÃ©ussite (%)',
                        data: $($successRates | ConvertTo-Json),
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Taux de rÃ©ussite par test'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            title: {
                                display: true,
                                text: 'Taux (%)'
                            }
                        }
                    }
                }
            });
            
            // Graphique des temps d'exÃ©cution
            const executionTimeCtx = document.getElementById('executionTimeChart').getContext('2d');
            new Chart(executionTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps d\'exÃ©cution moyen (s)',
                        data: $($executionTimes | ConvertTo-Json),
                        backgroundColor: 'rgba(255, 99, 132, 0.5)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Temps d\'exÃ©cution moyen par test'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Temps (s)'
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>
"@
    
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    # VÃ©rifier que les scripts de test existent
    foreach ($testScript in $TestScripts) {
        if (-not (Test-Path -Path $testScript)) {
            throw "Script de test non trouvÃ©: $testScript"
        }
    }
    
    # VÃ©rifier que le rÃ©pertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "RÃ©pertoire de sortie crÃ©Ã©: $outputDir" -ForegroundColor Cyan
    }
    
    # PrÃ©parer les paramÃ¨tres de test
    $testParams = $TestParameters.Clone()
    
    # Si le script est Simple-PRLoadTest.ps1, ajouter un paramÃ¨tre OutputPath par dÃ©faut
    foreach ($testScript in $TestScripts) {
        $scriptName = Split-Path -Path $testScript -Leaf
        if ($scriptName -eq "Simple-PRLoadTest.ps1" -and -not $testParams.ContainsKey("OutputPath")) {
            $testParams["OutputPath"] = [System.IO.Path]::GetTempFileName() + ".json"
        }
    }
    
    # Afficher les informations de configuration
    Write-Host "ExÃ©cution des tests de performance optimisÃ©s..." -ForegroundColor Cyan
    Write-Host "  Scripts de test: $($TestScripts -join ', ')"
    Write-Host "  ItÃ©rations: $Iterations"
    if ($ThrottleLimit -gt 0) {
        Write-Host "  Limite de parallÃ©lisation: $ThrottleLimit"
    }
    else {
        Write-Host "  Limite de parallÃ©lisation: Auto (basÃ©e sur le nombre de processeurs)"
    }
    Write-Host "  ParallÃ©lisation adaptative: $($AdaptiveThrottling.IsPresent)"
    
    # ExÃ©cuter les tests en parallÃ¨le
    $startTime = Get-Date
    $results = Invoke-ParallelPerformanceTests -TestScripts $TestScripts -TestParameters $testParams -Iterations $Iterations -ThrottleLimit $ThrottleLimit -AdaptiveThrottling:$AdaptiveThrottling -OutputPath $OutputPath
    $endTime = Get-Date
    
    # Ajouter des informations supplÃ©mentaires aux rÃ©sultats
    $results | Add-Member -MemberType NoteProperty -Name "StartTime" -Value $startTime -Force
    $results | Add-Member -MemberType NoteProperty -Name "EndTime" -Value $endTime -Force
    $results | Add-Member -MemberType NoteProperty -Name "TotalDuration" -Value ($endTime - $startTime).TotalSeconds -Force
    
    # Enregistrer les rÃ©sultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "RÃ©sultats enregistrÃ©s: $OutputPath" -ForegroundColor Green
    
    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-OptimizedTestReport -Results $results -OutputPath $reportPath
    }
    
    # Nettoyer les ressources
    Clear-ParallelPool -Force
    
    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
    Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalTests)"
    Write-Host "  Tests rÃ©ussis: $($results.SuccessCount)"
    Write-Host "  Tests en erreur: $($results.ErrorCount)"
    Write-Host "  DurÃ©e totale: $([Math]::Round($results.TotalDuration, 2)) secondes"
    
    return $results
}

# ExÃ©cuter le script
Main
