#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des tests de performance avec une parallélisation optimisée.
.DESCRIPTION
    Ce script utilise des techniques avancées de parallélisation pour exécuter
    des tests de performance tout en optimisant l'utilisation des ressources système.
.PARAMETER TestScripts
    Tableau de chemins vers les scripts de test à exécuter.
.PARAMETER TestParameters
    Paramètres à passer aux scripts de test.
.PARAMETER Iterations
    Nombre d'itérations à exécuter pour chaque test. Par défaut: 3.
.PARAMETER ThrottleLimit
    Nombre maximum de tests à exécuter en parallèle. Par défaut: nombre de processeurs - 1.
.PARAMETER AdaptiveThrottling
    Si spécifié, ajuste dynamiquement le nombre de tests en parallèle en fonction de l'utilisation des ressources.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats agrégés. Par défaut: "./optimized-perf-results.json".
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats.
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

# Importer le module de parallélisation optimisée
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallélisation optimisée non trouvé: $modulePath"
}

Import-Module $modulePath -Force

# Fonction pour générer un rapport HTML
function New-OptimizedTestReport {
    param (
        [object]$Results,
        [string]$OutputPath
    )
    
    # Préparer les données pour les graphiques
    $testNames = @()
    $avgResponseTimes = @()
    $successRates = @()
    $executionTimes = @()
    
    # Regrouper les résultats par script de test
    $groupedResults = $Results.TestResults | Group-Object -Property TestScript
    
    foreach ($group in $groupedResults) {
        $testName = Split-Path -Path $group.Name -Leaf
        $testNames += $testName
        
        # Calculer le temps de réponse moyen
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
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests de performance optimisés</title>
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
        <h1>Rapport de tests de performance optimisés</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="section">
        <h2>Résumé</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Tests exécutés</div>
                <div class="metric-value">$($Results.TotalTests)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Tests réussis</div>
                <div class="metric-value">$($Results.SuccessCount)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Tests en erreur</div>
                <div class="metric-value">$($Results.ErrorCount)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Taux de réussite</div>
                <div class="metric-value">$([Math]::Round(($Results.SuccessCount / $Results.TotalTests) * 100, 2))<span class="metric-unit">%</span></div>
            </div>
        </div>
    </div>
    
    <div class="section">
        <h2>Temps de réponse moyen par test</h2>
        <div class="chart-container">
            <canvas id="responseTimeChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Taux de réussite par test</h2>
        <div class="chart-container">
            <canvas id="successRateChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Temps d'exécution par test</h2>
        <div class="chart-container">
            <canvas id="executionTimeChart"></canvas>
        </div>
    </div>
    
    <div class="section">
        <h2>Détails des tests</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Itérations</th>
                <th>Réussites</th>
                <th>Erreurs</th>
                <th>Temps de réponse moyen (ms)</th>
                <th>Temps d'exécution moyen (s)</th>
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
        <p>Rapport généré par Invoke-OptimizedPerformanceTests.ps1</p>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique des temps de réponse
            const responseTimeCtx = document.getElementById('responseTimeChart').getContext('2d');
            new Chart(responseTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps de réponse moyen (ms)',
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
                            text: 'Temps de réponse moyen par test'
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
            
            // Graphique des taux de réussite
            const successRateCtx = document.getElementById('successRateChart').getContext('2d');
            new Chart(successRateCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Taux de réussite (%)',
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
                            text: 'Taux de réussite par test'
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
            
            // Graphique des temps d'exécution
            const executionTimeCtx = document.getElementById('executionTimeChart').getContext('2d');
            new Chart(executionTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($testNames | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps d\'exécution moyen (s)',
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
                            text: 'Temps d\'exécution moyen par test'
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
    Write-Host "Rapport HTML généré: $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    # Vérifier que les scripts de test existent
    foreach ($testScript in $TestScripts) {
        if (-not (Test-Path -Path $testScript)) {
            throw "Script de test non trouvé: $testScript"
        }
    }
    
    # Vérifier que le répertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Cyan
    }
    
    # Préparer les paramètres de test
    $testParams = $TestParameters.Clone()
    
    # Si le script est Simple-PRLoadTest.ps1, ajouter un paramètre OutputPath par défaut
    foreach ($testScript in $TestScripts) {
        $scriptName = Split-Path -Path $testScript -Leaf
        if ($scriptName -eq "Simple-PRLoadTest.ps1" -and -not $testParams.ContainsKey("OutputPath")) {
            $testParams["OutputPath"] = [System.IO.Path]::GetTempFileName() + ".json"
        }
    }
    
    # Afficher les informations de configuration
    Write-Host "Exécution des tests de performance optimisés..." -ForegroundColor Cyan
    Write-Host "  Scripts de test: $($TestScripts -join ', ')"
    Write-Host "  Itérations: $Iterations"
    if ($ThrottleLimit -gt 0) {
        Write-Host "  Limite de parallélisation: $ThrottleLimit"
    }
    else {
        Write-Host "  Limite de parallélisation: Auto (basée sur le nombre de processeurs)"
    }
    Write-Host "  Parallélisation adaptative: $($AdaptiveThrottling.IsPresent)"
    
    # Exécuter les tests en parallèle
    $startTime = Get-Date
    $results = Invoke-ParallelPerformanceTests -TestScripts $TestScripts -TestParameters $testParams -Iterations $Iterations -ThrottleLimit $ThrottleLimit -AdaptiveThrottling:$AdaptiveThrottling -OutputPath $OutputPath
    $endTime = Get-Date
    
    # Ajouter des informations supplémentaires aux résultats
    $results | Add-Member -MemberType NoteProperty -Name "StartTime" -Value $startTime -Force
    $results | Add-Member -MemberType NoteProperty -Name "EndTime" -Value $endTime -Force
    $results | Add-Member -MemberType NoteProperty -Name "TotalDuration" -Value ($endTime - $startTime).TotalSeconds -Force
    
    # Enregistrer les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Résultats enregistrés: $OutputPath" -ForegroundColor Green
    
    # Générer un rapport HTML si demandé
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-OptimizedTestReport -Results $results -OutputPath $reportPath
    }
    
    # Nettoyer les ressources
    Clear-ParallelPool -Force
    
    # Afficher un résumé
    Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests exécutés: $($results.TotalTests)"
    Write-Host "  Tests réussis: $($results.SuccessCount)"
    Write-Host "  Tests en erreur: $($results.ErrorCount)"
    Write-Host "  Durée totale: $([Math]::Round($results.TotalDuration, 2)) secondes"
    
    return $results
}

# Exécuter le script
Main
