#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un tableau de bord HTML pour suivre l'évolution des performances.
.DESCRIPTION
    Ce script génère un tableau de bord HTML qui affiche l'évolution des performances
    des différentes fonctions au fil du temps. Il utilise les données d'historique
    des performances pour générer des graphiques et des tableaux.
.PARAMETER HistoryDir
    Le répertoire contenant les fichiers d'historique des performances.
.PARAMETER OutputPath
    Le chemin où le tableau de bord HTML sera généré.
.EXAMPLE
    .\Generate-PerformanceDashboard.ps1 -HistoryDir ".\PerformanceHistory" -OutputPath ".\Dashboard.html"
    Génère un tableau de bord HTML à partir des fichiers d'historique dans le répertoire ".\PerformanceHistory".
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$HistoryDir = (Join-Path -Path $PSScriptRoot -ChildPath "..\tests\TestResults\PerformanceHistory"),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "PerformanceDashboard.html")
)

# Créer le répertoire parent s'il n'existe pas
$parentDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $parentDir -PathType Container)) {
    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
}

# Vérifier si le répertoire d'historique existe
if (-not (Test-Path -Path $HistoryDir -PathType Container)) {
    Write-Error "Le répertoire d'historique '$HistoryDir' n'existe pas."
    exit 1
}

# Fonction pour charger l'historique des performances
function Get-PerformanceHistory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath
    )

    if (Test-Path -Path $HistoryPath -PathType Leaf) {
        $history = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
        return $history
    }

    return @()
}

# Fonction pour analyser l'historique des performances
function Measure-PerformanceHistory {
    param (
        [Parameter(Mandatory = $true)]
        [array]$History
    )

    if ($History.Count -eq 0) {
        return $null
    }

    # Calculer les statistiques
    $avgTime = ($History | Measure-Object -Property ExecutionTimeMs -Average).Average
    $minTime = ($History | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
    $maxTime = ($History | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
    $stdDev = 0

    if ($History.Count -gt 1) {
        $stdDev = [Math]::Sqrt(($History | ForEach-Object { [Math]::Pow($_.ExecutionTimeMs - $avgTime, 2) } | Measure-Object -Average).Average)
    }

    # Calculer la tendance
    $trend = 0
    if ($History.Count -gt 1) {
        $firstHalf = $History | Select-Object -First ([Math]::Floor($History.Count / 2))
        $secondHalf = $History | Select-Object -Last ([Math]::Ceiling($History.Count / 2))

        $firstHalfAvg = ($firstHalf | Measure-Object -Property ExecutionTimeMs -Average).Average
        $secondHalfAvg = ($secondHalf | Measure-Object -Property ExecutionTimeMs -Average).Average

        if ($firstHalfAvg -ne 0) {
            $trend = ($secondHalfAvg - $firstHalfAvg) / $firstHalfAvg * 100
        }
    }

    return [PSCustomObject]@{
        Count = $History.Count
        AverageTimeMs = $avgTime
        MinTimeMs = $minTime
        MaxTimeMs = $maxTime
        StdDevMs = $stdDev
        TrendPercent = $trend
    }
}

# Fonction pour générer des données de graphique pour Chart.js
function New-ChartData {
    param (
        [Parameter(Mandatory = $true)]
        [array]$History,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($History.Count -eq 0) {
        return $null
    }

    # Trier l'historique par horodatage
    $sortedHistory = $History | Sort-Object -Property Timestamp

    # Extraire les données pour le graphique
    $labels = $sortedHistory | ForEach-Object { $_.Timestamp }
    $data = $sortedHistory | ForEach-Object { $_.ExecutionTimeMs }

    # Générer les données pour Chart.js
    $chartData = @{
        labels = $labels
        datasets = @(
            @{
                label = $Name
                data = $data
                backgroundColor = "rgba(54, 162, 235, 0.2)"
                borderColor = "rgba(54, 162, 235, 1)"
                borderWidth = 1
                fill = $false
            }
        )
    }

    return $chartData | ConvertTo-Json -Depth 10
}

# Fonction pour générer le HTML du tableau de bord
function New-DashboardHtml {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceData
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de bord des performances</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(600px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background-color: #f5f5f5;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .trend-positive {
            color: green;
        }
        .trend-negative {
            color: red;
        }
        .trend-neutral {
            color: gray;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Tableau de bord des performances</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>

    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de fonctions suivies : $($PerformanceData.Count)</p>
    </div>

    <div class="dashboard">
"@

    foreach ($name in $PerformanceData.Keys) {
        $data = $PerformanceData[$name]
        $analysis = $data.Analysis
        $chartData = $data.ChartData

        $trendClass = 'trend-neutral'
        $trendSymbol = '→'

        if ($analysis.TrendPercent -lt -5) {
            $trendClass = 'trend-positive'
            $trendSymbol = '↓'
        }
        elseif ($analysis.TrendPercent -gt 5) {
            $trendClass = 'trend-negative'
            $trendSymbol = '↑'
        }

        $html += @"
        <div class="card">
            <h2>$name</h2>
            <div class="chart-container">
                <canvas id="chart_$($name -replace '\s+', '_')"></canvas>
            </div>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nombre de mesures</td>
                    <td>$($analysis.Count)</td>
                </tr>
                <tr>
                    <td>Temps moyen</td>
                    <td>$([Math]::Round($analysis.AverageTimeMs, 2)) ms</td>
                </tr>
                <tr>
                    <td>Temps min/max</td>
                    <td>$([Math]::Round($analysis.MinTimeMs, 2)) / $([Math]::Round($analysis.MaxTimeMs, 2)) ms</td>
                </tr>
                <tr>
                    <td>Écart-type</td>
                    <td>$([Math]::Round($analysis.StdDevMs, 2)) ms</td>
                </tr>
                <tr>
                    <td>Tendance</td>
                    <td class="$trendClass">$trendSymbol $([Math]::Round($analysis.TrendPercent, 2))%</td>
                </tr>
            </table>
        </div>
"@
    }

    $html += @"
    </div>

    <script>
"@

    foreach ($name in $PerformanceData.Keys) {
        $chartData = $PerformanceData[$name].ChartData

        $html += @"
        // Graphique pour $name
        const ctx_$($name -replace '\s+', '_') = document.getElementById('chart_$($name -replace '\s+', '_')').getContext('2d');
        new Chart(ctx_$($name -replace '\s+', '_'), {
            type: 'line',
            data: $chartData,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: false,
                        title: {
                            display: true,
                            text: 'Temps d\'exécution (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    }
                }
            }
        });
"@
    }

    $html += @"
    </script>
</body>
</html>
"@

    return $html
}

# Charger les fichiers d'historique
$historyFiles = Get-ChildItem -Path $HistoryDir -Filter "*_history.json" -File

if ($historyFiles.Count -eq 0) {
    Write-Warning "Aucun fichier d'historique trouvé dans le répertoire '$HistoryDir'."

    # Créer des données de démonstration si aucun fichier d'historique n'est trouvé
    Write-Host "Création de données de démonstration..." -ForegroundColor Yellow

    $demoHistoryDir = Join-Path -Path $HistoryDir -ChildPath "Demo"
    New-Item -Path $demoHistoryDir -ItemType Directory -Force | Out-Null

    $functions = @("Tri", "Filtrage", "Agrégation")

    foreach ($function in $functions) {
        $historyPath = Join-Path -Path $demoHistoryDir -ChildPath "$($function.ToLower())_history.json"
        $history = @()

        # Générer des données de démonstration pour les 30 derniers jours
        for ($i = 30; $i -ge 0; $i--) {
            $date = (Get-Date).AddDays(-$i)
            $timestamp = $date.ToString("yyyy-MM-dd HH:mm:ss")

            # Simuler une tendance (amélioration progressive des performances)
            $baseTime = 100 - ($i * 0.5)

            # Ajouter une variation aléatoire
            $variation = Get-Random -Minimum -10 -Maximum 10
            $executionTime = $baseTime + $variation

            $history += [PSCustomObject]@{
                Name = $function
                ExecutionTimeMs = $executionTime
                Timestamp = $timestamp
            }
        }

        # Sauvegarder l'historique
        $history | ConvertTo-Json | Out-File -FilePath $historyPath -Encoding utf8
    }

    # Mettre à jour la liste des fichiers d'historique
    $historyFiles = Get-ChildItem -Path $HistoryDir -Filter "*_history.json" -File -Recurse
}

# Préparer les données pour le tableau de bord
$performanceData = @{}

foreach ($file in $historyFiles) {
    $history = Get-PerformanceHistory -HistoryPath $file.FullName

    if ($history.Count -gt 0) {
        $name = $history[0].Name

        if ([string]::IsNullOrEmpty($name)) {
            $name = $file.BaseName -replace '_history$', ''
            $name = (Get-Culture).TextInfo.ToTitleCase($name)
        }

        $analysis = Measure-PerformanceHistory -History $history
        $chartData = New-ChartData -History $history -Name $name

        $performanceData[$name] = @{
            History = $history
            Analysis = $analysis
            ChartData = $chartData
        }
    }
}

# Générer le HTML du tableau de bord
$dashboardHtml = New-DashboardHtml -PerformanceData $performanceData

# Sauvegarder le tableau de bord
$dashboardHtml | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Tableau de bord généré : $OutputPath" -ForegroundColor Green

# Ouvrir le tableau de bord dans le navigateur par défaut
Start-Process $OutputPath
