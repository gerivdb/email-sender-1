#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure l'efficacité de la parallélisation optimisée par rapport à l'exécution séquentielle.
.DESCRIPTION
    Ce script compare les performances entre l'exécution séquentielle et l'exécution
    parallèle optimisée pour mesurer le gain de performance.
.PARAMETER TestScript
    Chemin vers le script de test à exécuter.
.PARAMETER Parameters
    Paramètres à passer au script de test.
.PARAMETER Iterations
    Nombre d'itérations à exécuter. Par défaut: 5.
.PARAMETER ConcurrencyLevels
    Niveaux de concurrence à tester. Par défaut: 1, 2, 4, 8, 16.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats. Par défaut: "./parallelization-efficiency.json".
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats.
.EXAMPLE
    .\Measure-ParallelizationEfficiency.ps1 -TestScript ".\Simple-PRLoadTest.ps1" -Parameters @{Duration=5; OutputPath="test.json"} -Iterations 10
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestScript,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [int[]]$ConcurrencyLevels = @(1, 2, 4, 8, 16),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./parallelization-efficiency.json",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de parallélisation optimisée
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallélisation optimisée non trouvé: $modulePath"
}

Import-Module $modulePath -Force

# Fonction pour exécuter un test de manière séquentielle
function Invoke-SequentialTest {
    param (
        [string]$TestScript,
        [hashtable]$Parameters,
        [int]$Iterations
    )

    $results = @()
    $totalTime = 0

    for ($i = 1; $i -le $Iterations; $i++) {
        $iterationParams = $Parameters.Clone()

        # Générer un chemin de sortie unique si nécessaire
        if ($iterationParams.ContainsKey("OutputPath")) {
            $outputFile = [System.IO.Path]::GetFileNameWithoutExtension($iterationParams["OutputPath"])
            $outputExt = [System.IO.Path]::GetExtension($iterationParams["OutputPath"])
            $iterationParams["OutputPath"] = "$outputFile`_seq_$i$outputExt"
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $result = & $TestScript @iterationParams
            $success = $true
            $errorMsg = $null
        } catch {
            $result = $null
            $success = $false
            $errorMsg = $_.Exception.Message
        }

        $sw.Stop()
        $executionTime = $sw.Elapsed.TotalMilliseconds
        $totalTime += $executionTime

        $results += [PSCustomObject]@{
            Iteration     = $i
            ExecutionTime = $executionTime
            Success       = $success
            Error         = $errorMsg
            Result        = $result
        }
    }

    return [PSCustomObject]@{
        TotalTime   = $totalTime
        AverageTime = $totalTime / $Iterations
        Results     = $results
    }
}

# Fonction pour exécuter un test en parallèle
function Invoke-ParallelTest {
    param (
        [string]$TestScript,
        [hashtable]$Parameters,
        [int]$Iterations,
        [int]$Concurrency
    )

    # Initialiser le pool de parallélisation
    Initialize-ParallelPool -MaxThreads $Concurrency

    $scriptBlock = {
        param($Script, $Params, $Iteration)

        $iterationParams = $Params.Clone()

        # Générer un chemin de sortie unique si nécessaire
        if ($iterationParams.ContainsKey("OutputPath")) {
            $outputFile = [System.IO.Path]::GetFileNameWithoutExtension($iterationParams["OutputPath"])
            $outputExt = [System.IO.Path]::GetExtension($iterationParams["OutputPath"])
            $iterationParams["OutputPath"] = "$outputFile`_par_$Iteration$outputExt"
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $result = & $Script @iterationParams
            $success = $true
            $errorMsg = $null
        } catch {
            $result = $null
            $success = $false
            $errorMsg = $_.Exception.Message
        }

        $sw.Stop()
        $executionTime = $sw.Elapsed.TotalMilliseconds

        return [PSCustomObject]@{
            Iteration     = $Iteration
            ExecutionTime = $executionTime
            Success       = $success
            Error         = $errorMsg
            Result        = $result
        }
    }

    # Préparer les entrées pour les tâches parallèles
    $inputs = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        $inputs += [PSCustomObject]@{
            Script    = $TestScript
            Params    = $Parameters
            Iteration = $i
        }
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # Exécuter les tests en parallèle
    $results = Invoke-ParallelTasks -ScriptBlock $scriptBlock -InputObjects $inputs -ThrottleLimit $Concurrency -ShowProgress

    $sw.Stop()
    $totalTime = $sw.Elapsed.TotalMilliseconds

    # Nettoyer les ressources
    Clear-ParallelPool -Force

    return [PSCustomObject]@{
        TotalTime   = $totalTime
        AverageTime = $totalTime / $Iterations
        Results     = $results
        Concurrency = $Concurrency
    }
}

# Fonction pour générer un rapport HTML
function New-EfficiencyReport {
    param (
        [object]$Results,
        [string]$OutputPath
    )

    # Préparer les données pour les graphiques
    $concurrencyLevels = @("Sequential") + $Results.ParallelResults.Concurrency
    $totalTimes = @($Results.SequentialResults.TotalTime / 1000) + ($Results.ParallelResults.TotalTime | ForEach-Object { $_ / 1000 })
    $avgTimesData = @($Results.SequentialResults.AverageTime) + ($Results.ParallelResults.AverageTime)
    $speedups = @(1) + ($Results.ParallelResults | ForEach-Object { $Results.SequentialResults.TotalTime / $_.TotalTime })
    $efficiency = @(100) + ($Results.ParallelResults | ForEach-Object { ($Results.SequentialResults.TotalTime / $_.TotalTime) / $_.Concurrency * 100 })

    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'efficacité de parallélisation</title>
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
        <h1>Rapport d'efficacité de parallélisation</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="section">
        <h2>Résumé</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Script testé</div>
                <div class="metric-value">$(Split-Path -Path $TestScript -Leaf)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Itérations</div>
                <div class="metric-value">$Iterations</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Temps séquentiel</div>
                <div class="metric-value">$([Math]::Round($Results.SequentialResults.TotalTime / 1000, 2))<span class="metric-unit">s</span></div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Meilleur temps parallèle</div>
                <div class="metric-value">$([Math]::Round(($Results.ParallelResults | Sort-Object -Property TotalTime | Select-Object -First 1).TotalTime / 1000, 2))<span class="metric-unit">s</span></div>
            </div>
        </div>
    </div>

    <div class="section">
        <h2>Temps d'exécution total</h2>
        <div class="chart-container">
            <canvas id="totalTimeChart"></canvas>
        </div>
    </div>

    <div class="section">
        <h2>Accélération (Speedup)</h2>
        <div class="chart-container">
            <canvas id="speedupChart"></canvas>
        </div>
    </div>

    <div class="section">
        <h2>Efficacité de parallélisation</h2>
        <div class="chart-container">
            <canvas id="efficiencyChart"></canvas>
        </div>
    </div>

    <div class="section">
        <h2>Détails des résultats</h2>
        <table>
            <tr>
                <th>Mode</th>
                <th>Concurrence</th>
                <th>Temps total (s)</th>
                <th>Temps moyen (ms)</th>
                <th>Accélération</th>
                <th>Efficacité (%)</th>
            </tr>
            <tr>
                <td>Séquentiel</td>
                <td>1</td>
                <td>$([Math]::Round($Results.SequentialResults.TotalTime / 1000, 2))</td>
                <td>$([Math]::Round($Results.SequentialResults.AverageTime, 2))</td>
                <td>1.00</td>
                <td>100.00</td>
            </tr>
            $(
                foreach ($result in $Results.ParallelResults) {
                    $speedup = $Results.SequentialResults.TotalTime / $result.TotalTime
                    $eff = $speedup / $result.Concurrency * 100

                    "<tr>
                        <td>Parallèle</td>
                        <td>$($result.Concurrency)</td>
                        <td>$([Math]::Round($result.TotalTime / 1000, 2))</td>
                        <td>$([Math]::Round($result.AverageTime, 2))</td>
                        <td>$([Math]::Round($speedup, 2))</td>
                        <td>$([Math]::Round($eff, 2))</td>
                    </tr>"
                }
            )
        </table>
    </div>

    <div class="section">
        <h2>Analyse</h2>
        <p>
            L'efficacité de parallélisation mesure à quel point l'ajout de ressources supplémentaires (threads) améliore les performances.
            Une efficacité de 100% signifie que doubler le nombre de threads divise le temps d'exécution par deux.
        </p>
        <p>
            Observations clés :
        </p>
        <ul>
            $(
                $bestResult = $Results.ParallelResults | Sort-Object -Property TotalTime | Select-Object -First 1
                $bestSpeedup = $Results.SequentialResults.TotalTime / $bestResult.TotalTime
                $bestEff = $bestSpeedup / $bestResult.Concurrency * 100

                "<li>La meilleure performance a été obtenue avec <strong>$($bestResult.Concurrency) threads</strong>, offrant une accélération de <strong>$([Math]::Round($bestSpeedup, 2))x</strong>.</li>"

                if ($bestResult.Concurrency -eq ($ConcurrencyLevels | Measure-Object -Maximum).Maximum) {
                    "<li>L'accélération continue d'augmenter avec le nombre de threads, ce qui suggère que des niveaux de concurrence plus élevés pourraient offrir de meilleures performances.</li>"
                }
                elseif ($bestEff -lt 50) {
                    "<li>L'efficacité de parallélisation est relativement faible ($([Math]::Round($bestEff, 2))%), ce qui indique que le script a une partie séquentielle importante ou qu'il y a des contentions de ressources.</li>"
                }
                elseif ($bestEff -ge 80) {
                    "<li>L'efficacité de parallélisation est excellente ($([Math]::Round($bestEff, 2))%), ce qui indique que le script se parallélise très bien.</li>"
                }
                else {
                    "<li>L'efficacité de parallélisation est bonne ($([Math]::Round($bestEff, 2))%), mais il y a encore place à l'amélioration.</li>"
                }

                $amdahlsLaw = 1 / ((1 - (1 / $bestSpeedup)) + (1 / ($bestResult.Concurrency * $bestSpeedup)))
                "<li>Selon la loi d'Amdahl, environ $([Math]::Round((1 - (1 / $amdahlsLaw)) * 100, 2))% du script peut être parallélisé efficacement.</li>"
            )
        </ul>
    </div>

    <div class="footer">
        <p>Rapport généré par Measure-ParallelizationEfficiency.ps1</p>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique des temps d'exécution
            const totalTimeCtx = document.getElementById('totalTimeChart').getContext('2d');
            new Chart(totalTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($concurrencyLevels | ConvertTo-Json),
                    datasets: [{
                        label: 'Temps d\'exécution total (s)',
                        data: $($totalTimes | ConvertTo-Json),
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
                            text: 'Temps d\'exécution total par niveau de concurrence'
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

            // Graphique d'accélération
            const speedupCtx = document.getElementById('speedupChart').getContext('2d');
            new Chart(speedupCtx, {
                type: 'line',
                data: {
                    labels: $($concurrencyLevels | ConvertTo-Json),
                    datasets: [{
                        label: 'Accélération (Speedup)',
                        data: $($speedups | ConvertTo-Json),
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 2,
                        tension: 0.1
                    }, {
                        label: 'Accélération idéale',
                        data: [1, 2, 4, 8, 16].slice(0, $($concurrencyLevels | ConvertTo-Json).length),
                        backgroundColor: 'rgba(255, 99, 132, 0.2)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 2,
                        borderDash: [5, 5],
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Accélération par rapport à l\'exécution séquentielle'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Accélération (x fois)'
                            }
                        }
                    }
                }
            });

            // Graphique d'efficacité
            const efficiencyCtx = document.getElementById('efficiencyChart').getContext('2d');
            new Chart(efficiencyCtx, {
                type: 'line',
                data: {
                    labels: $($concurrencyLevels | ConvertTo-Json),
                    datasets: [{
                        label: 'Efficacité de parallélisation (%)',
                        data: $($efficiency | ConvertTo-Json),
                        backgroundColor: 'rgba(255, 159, 64, 0.5)',
                        borderColor: 'rgba(255, 159, 64, 1)',
                        borderWidth: 2,
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Efficacité de parallélisation par niveau de concurrence'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            title: {
                                display: true,
                                text: 'Efficacité (%)'
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
    # Vérifier que le script de test existe
    if (-not (Test-Path -Path $TestScript)) {
        throw "Script de test non trouvé: $TestScript"
    }

    # Vérifier que le répertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Cyan
    }

    # Afficher les informations de configuration
    Write-Host "Mesure de l'efficacité de parallélisation..." -ForegroundColor Cyan
    Write-Host "  Script de test: $TestScript"
    Write-Host "  Itérations: $Iterations"
    Write-Host "  Niveaux de concurrence: $($ConcurrencyLevels -join ', ')"

    # Exécuter le test de manière séquentielle
    Write-Host "`nExécution du test en mode séquentiel..." -ForegroundColor Yellow
    $sequentialResults = Invoke-SequentialTest -TestScript $TestScript -Parameters $Parameters -Iterations $Iterations

    Write-Host "  Temps total: $([Math]::Round($sequentialResults.TotalTime / 1000, 2)) secondes"
    Write-Host "  Temps moyen: $([Math]::Round($sequentialResults.AverageTime, 2)) ms"

    # Exécuter le test en parallèle avec différents niveaux de concurrence
    $parallelResults = @()

    foreach ($concurrency in $ConcurrencyLevels) {
        if ($concurrency -eq 1) {
            # Sauter le niveau de concurrence 1, car il est équivalent au mode séquentiel
            continue
        }

        Write-Host "`nExécution du test en mode parallèle avec $concurrency threads..." -ForegroundColor Yellow
        $result = Invoke-ParallelTest -TestScript $TestScript -Parameters $Parameters -Iterations $Iterations -Concurrency $concurrency

        $speedup = $sequentialResults.TotalTime / $result.TotalTime
        $efficiency = ($speedup / $concurrency) * 100

        Write-Host "  Temps total: $([Math]::Round($result.TotalTime / 1000, 2)) secondes"
        Write-Host "  Temps moyen: $([Math]::Round($result.AverageTime, 2)) ms"
        Write-Host "  Accélération: $([Math]::Round($speedup, 2))x"
        Write-Host "  Efficacité: $([Math]::Round($efficiency, 2))%"

        $parallelResults += $result
    }

    # Agréger les résultats
    $results = [PSCustomObject]@{
        TestScript        = $TestScript
        Parameters        = $Parameters
        Iterations        = $Iterations
        ConcurrencyLevels = $ConcurrencyLevels
        SequentialResults = $sequentialResults
        ParallelResults   = $parallelResults
    }

    # Enregistrer les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "`nRésultats enregistrés: $OutputPath" -ForegroundColor Green

    # Générer un rapport HTML si demandé
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-EfficiencyReport -Results $results -OutputPath $reportPath
    }

    # Afficher un résumé
    Write-Host "`nRésumé de l'efficacité de parallélisation:" -ForegroundColor Cyan

    $bestResult = $parallelResults | Sort-Object -Property TotalTime | Select-Object -First 1
    $bestSpeedup = $sequentialResults.TotalTime / $bestResult.TotalTime
    $bestEfficiency = ($bestSpeedup / $bestResult.Concurrency) * 100

    Write-Host "  Meilleure performance avec $($bestResult.Concurrency) threads"
    Write-Host "  Accélération maximale: $([Math]::Round($bestSpeedup, 2))x"
    Write-Host "  Efficacité maximale: $([Math]::Round($bestEfficiency, 2))%"

    return $results
}

# Exécuter le script
Main
