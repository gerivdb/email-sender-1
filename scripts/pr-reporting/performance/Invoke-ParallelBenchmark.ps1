#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des benchmarks de performance en parallèle avec optimisation des ressources.
.DESCRIPTION
    Ce script combine les fonctionnalités de Invoke-PRPerformanceBenchmark et
    la parallélisation optimisée pour exécuter des benchmarks de performance
    plus efficacement.
.PARAMETER Functions
    Tableau de noms de fonctions à tester.
.PARAMETER ModulePaths
    Tableau de chemins vers les modules contenant les fonctions à tester.
.PARAMETER DataSizes
    Tailles de données à utiliser pour les tests. Par défaut: "Small", "Medium", "Large".
.PARAMETER Iterations
    Nombre d'itérations à exécuter pour chaque test. Par défaut: 5.
.PARAMETER AdaptiveParallelization
    Si spécifié, ajuste dynamiquement le nombre de tests en parallèle en fonction de l'utilisation des ressources.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats agrégés. Par défaut: "./benchmark-results.json".
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats.
.EXAMPLE
    .\Invoke-ParallelBenchmark.ps1 -Functions @("Get-Data", "Process-Data") -ModulePaths @(".\DataModule.psm1") -Iterations 10
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$Functions,

    [Parameter(Mandatory = $true)]
    [string[]]$ModulePaths,

    [Parameter(Mandatory = $false)]
    [string[]]$DataSizes = @("Small", "Medium", "Large"),

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false)]
    [switch]$AdaptiveParallelization,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./benchmark-results.json",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de parallélisation optimisée
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\OptimizedParallel.psm1"
if (-not (Test-Path -Path $modulePath)) {
    throw "Module de parallélisation optimisée non trouvé: $modulePath"
}

Import-Module $modulePath -Force

# Fonction pour générer des données de test
function New-TestData {
    param (
        [string]$Size
    )

    $data = @{}

    switch ($Size) {
        "Small" {
            $data.Items = 100
            $data.Complexity = "Low"
            $data.Array = 1..100
            $data.Hashtable = @{}
            for ($i = 1; $i -le 100; $i++) {
                $data.Hashtable["Key$i"] = "Value$i"
            }
        }
        "Medium" {
            $data.Items = 1000
            $data.Complexity = "Medium"
            $data.Array = 1..1000
            $data.Hashtable = @{}
            for ($i = 1; $i -le 1000; $i++) {
                $data.Hashtable["Key$i"] = "Value$i"
            }
        }
        "Large" {
            $data.Items = 10000
            $data.Complexity = "High"
            $data.Array = 1..10000
            $data.Hashtable = @{}
            for ($i = 1; $i -le 10000; $i++) {
                $data.Hashtable["Key$i"] = "Value$i"
            }
        }
        default {
            $data.Items = 100
            $data.Complexity = "Low"
            $data.Array = 1..100
            $data.Hashtable = @{}
            for ($i = 1; $i -le 100; $i++) {
                $data.Hashtable["Key$i"] = "Value$i"
            }
        }
    }

    return $data
}

# Fonction pour exécuter un benchmark sur une fonction
function Invoke-FunctionBenchmark {
    param (
        [string]$FunctionName,
        [string]$ModulePath,
        [object]$TestData,
        [int]$Iterations
    )

    try {
        # Importer le module
        Import-Module $ModulePath -Force

        # Vérifier que la fonction existe
        if (-not (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue)) {
            return [PSCustomObject]@{
                FunctionName = $FunctionName
                ModulePath   = $ModulePath
                Success      = $false
                Error        = "Fonction non trouvée: $FunctionName"
            }
        }

        # Exécuter le benchmark
        $results = @()
        $totalTime = 0
        $minTime = [double]::MaxValue
        $maxTime = 0

        for ($i = 1; $i -le $Iterations; $i++) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            # Exécuter la fonction
            $result = & $FunctionName -InputData $TestData

            $sw.Stop()
            $executionTime = $sw.Elapsed.TotalMilliseconds

            $results += [PSCustomObject]@{
                Iteration     = $i
                ExecutionTime = $executionTime
                Result        = $result
            }

            $totalTime += $executionTime
            if ($executionTime -lt $minTime) { $minTime = $executionTime }
            if ($executionTime -gt $maxTime) { $maxTime = $executionTime }
        }

        # Calculer les statistiques
        $avgTime = $totalTime / $Iterations
        $variance = 0
        foreach ($result in $results) {
            $variance += [Math]::Pow($result.ExecutionTime - $avgTime, 2)
        }
        $variance = $variance / $Iterations
        $stdDev = [Math]::Sqrt($variance)

        # Retourner les résultats
        return [PSCustomObject]@{
            FunctionName = $FunctionName
            ModulePath   = $ModulePath
            DataSize     = $TestData.Items
            Complexity   = $TestData.Complexity
            Iterations   = $Iterations
            AverageTime  = $avgTime
            MinTime      = $minTime
            MaxTime      = $maxTime
            StdDev       = $stdDev
            Results      = $results
            Success      = $true
            Error        = $null
        }
    } catch {
        return [PSCustomObject]@{
            FunctionName = $FunctionName
            ModulePath   = $ModulePath
            Success      = $false
            Error        = $_.Exception.Message
        }
    }
}

# Fonction pour générer un rapport HTML
function New-BenchmarkReport {
    param (
        [object]$Results,
        [string]$OutputPath
    )

    # Préparer les données pour les graphiques
    $functionNames = @()
    $avgTimes = @{}
    $stdDevs = @{}

    foreach ($dataSize in $DataSizes) {
        $avgTimes[$dataSize] = @()
        $stdDevs[$dataSize] = @()
    }

    foreach ($function in $Functions) {
        $functionNames += $function

        foreach ($dataSize in $DataSizes) {
            $complexity = "Low"
            if ($dataSize -eq "Medium") { $complexity = "Medium" }
            if ($dataSize -eq "Large") { $complexity = "High" }
            $functionResults = $Results.BenchmarkResults | Where-Object { $_.FunctionName -eq $function -and $_.Complexity -eq $complexity }

            if ($functionResults) {
                $avgTimes[$dataSize] += $functionResults.AverageTime
                $stdDevs[$dataSize] += $functionResults.StdDev
            } else {
                $avgTimes[$dataSize] += 0
                $stdDevs[$dataSize] += 0
            }
        }
    }

    # Générer les datasets pour les graphiques
    $datasets = @()
    $colors = @(
        @{ backgroundColor = "rgba(54, 162, 235, 0.5)"; borderColor = "rgba(54, 162, 235, 1)" },
        @{ backgroundColor = "rgba(255, 99, 132, 0.5)"; borderColor = "rgba(255, 99, 132, 1)" },
        @{ backgroundColor = "rgba(75, 192, 192, 0.5)"; borderColor = "rgba(75, 192, 192, 1)" }
    )

    for ($i = 0; $i -lt $DataSizes.Count; $i++) {
        $dataSize = $DataSizes[$i]
        $color = $colors[$i % $colors.Count]

        $datasets += @{
            label           = "Taille $dataSize"
            data            = $avgTimes[$dataSize]
            backgroundColor = $color.backgroundColor
            borderColor     = $color.borderColor
            borderWidth     = 1
        }
    }

    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de benchmark de performance</title>
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
        <h1>Rapport de benchmark de performance</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="section">
        <h2>Résumé</h2>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-title">Fonctions testées</div>
                <div class="metric-value">$($Functions.Count)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Tailles de données</div>
                <div class="metric-value">$($DataSizes.Count)</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Itérations par test</div>
                <div class="metric-value">$Iterations</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Durée totale</div>
                <div class="metric-value">$([Math]::Round($Results.TotalDuration, 2))<span class="metric-unit">s</span></div>
            </div>
        </div>
    </div>

    <div class="section">
        <h2>Temps d'exécution moyen par fonction</h2>
        <div class="chart-container">
            <canvas id="executionTimeChart"></canvas>
        </div>
    </div>

    <div class="section">
        <h2>Détails des benchmarks</h2>
        <table>
            <tr>
                <th>Fonction</th>
                <th>Taille de données</th>
                <th>Itérations</th>
                <th>Temps moyen (ms)</th>
                <th>Temps min (ms)</th>
                <th>Temps max (ms)</th>
                <th>Écart type</th>
            </tr>
            $(
                foreach ($result in $Results.BenchmarkResults) {
                    "<tr>
                        <td>$($result.FunctionName)</td>
                        <td>$($result.Complexity)</td>
                        <td>$($result.Iterations)</td>
                        <td>$([Math]::Round($result.AverageTime, 2))</td>
                        <td>$([Math]::Round($result.MinTime, 2))</td>
                        <td>$([Math]::Round($result.MaxTime, 2))</td>
                        <td>$([Math]::Round($result.StdDev, 2))</td>
                    </tr>"
                }
            )
        </table>
    </div>

    <div class="footer">
        <p>Rapport généré par Invoke-ParallelBenchmark.ps1</p>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Graphique des temps d'exécution
            const executionTimeCtx = document.getElementById('executionTimeChart').getContext('2d');
            new Chart(executionTimeCtx, {
                type: 'bar',
                data: {
                    labels: $($functionNames | ConvertTo-Json),
                    datasets: $($datasets | ConvertTo-Json -Depth 3)
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Temps d\'exécution moyen par fonction et taille de données'
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
    # Vérifier que les modules existent
    foreach ($modulePath in $ModulePaths) {
        if (-not (Test-Path -Path $modulePath)) {
            throw "Module non trouvé: $modulePath"
        }
    }

    # Vérifier que le répertoire de sortie existe
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé: $outputDir" -ForegroundColor Cyan
    }

    # Afficher les informations de configuration
    Write-Host "Exécution des benchmarks de performance en parallèle..." -ForegroundColor Cyan
    Write-Host "  Fonctions: $($Functions -join ', ')"
    Write-Host "  Modules: $($ModulePaths -join ', ')"
    Write-Host "  Tailles de données: $($DataSizes -join ', ')"
    Write-Host "  Itérations: $Iterations"
    Write-Host "  Parallélisation adaptative: $($AdaptiveParallelization.IsPresent)"

    # Préparer les tâches de benchmark
    $benchmarkTasks = @()

    foreach ($function in $Functions) {
        foreach ($modulePath in $ModulePaths) {
            foreach ($dataSize in $DataSizes) {
                $testData = New-TestData -Size $dataSize

                $benchmarkTasks += [PSCustomObject]@{
                    FunctionName = $function
                    ModulePath   = $modulePath
                    TestData     = $testData
                    Iterations   = $Iterations
                }
            }
        }
    }

    # Initialiser le pool de parallélisation
    $resourceLimits = $null
    if ($AdaptiveParallelization) {
        $resourceLimits = @{
            CPU    = 75
            Memory = 70
        }
    }

    Initialize-ParallelPool -ResourceLimits $resourceLimits

    # Exécuter les benchmarks en parallèle
    $startTime = Get-Date

    $scriptBlock = {
        param($Task)

        Invoke-FunctionBenchmark -FunctionName $Task.FunctionName -ModulePath $Task.ModulePath -TestData $Task.TestData -Iterations $Task.Iterations
    }

    $benchmarkResults = Invoke-ParallelTasks -ScriptBlock $scriptBlock -InputObjects $benchmarkTasks -ShowProgress

    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalSeconds

    # Agréger les résultats
    $results = [PSCustomObject]@{
        StartTime        = $startTime
        EndTime          = $endTime
        TotalDuration    = $totalDuration
        Functions        = $Functions
        ModulePaths      = $ModulePaths
        DataSizes        = $DataSizes
        Iterations       = $Iterations
        BenchmarkResults = $benchmarkResults
    }

    # Enregistrer les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Résultats enregistrés: $OutputPath" -ForegroundColor Green

    # Générer un rapport HTML si demandé
    if ($GenerateReport) {
        $reportPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-BenchmarkReport -Results $results -OutputPath $reportPath
    }

    # Nettoyer les ressources
    Clear-ParallelPool -Force

    # Afficher un résumé
    Write-Host "`nRésumé des benchmarks:" -ForegroundColor Cyan
    Write-Host "  Benchmarks exécutés: $($benchmarkResults.Count)"
    Write-Host "  Durée totale: $([Math]::Round($totalDuration, 2)) secondes"

    # Afficher les temps moyens par fonction et taille de données
    Write-Host "`nTemps d'exécution moyens (ms):" -ForegroundColor Yellow

    $table = @{}
    foreach ($function in $Functions) {
        $table[$function] = @{}
        foreach ($dataSize in $DataSizes) {
            $complexity = switch ($dataSize) {
                "Small" { "Low" }
                "Medium" { "Medium" }
                "Large" { "High" }
            }

            $result = $benchmarkResults | Where-Object { $_.FunctionName -eq $function -and $_.Complexity -eq $complexity }
            if ($result) {
                $table[$function][$dataSize] = [Math]::Round($result.AverageTime, 2)
            } else {
                $table[$function][$dataSize] = "N/A"
            }
        }
    }

    # Afficher le tableau
    $header = "Fonction".PadRight(20)
    foreach ($dataSize in $DataSizes) {
        $header += $dataSize.PadRight(15)
    }
    Write-Host $header

    foreach ($function in $Functions) {
        $row = $function.PadRight(20)
        foreach ($dataSize in $DataSizes) {
            $row += $table[$function][$dataSize].ToString().PadRight(15)
        }
        Write-Host $row
    }

    return $results
}

# Exécuter le script
Main
