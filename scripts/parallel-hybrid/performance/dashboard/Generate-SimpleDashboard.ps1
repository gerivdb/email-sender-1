#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un tableau de bord HTML simplifié pour suivre l'évolution des performances.
.DESCRIPTION
    Ce script génère un tableau de bord HTML qui affiche l'évolution des performances
    des différentes fonctions au fil du temps.
.PARAMETER OutputPath
    Le chemin où le tableau de bord HTML sera généré.
.EXAMPLE
    .\Generate-SimpleDashboard.ps1 -OutputPath ".\Dashboard.html"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "PerformanceDashboard.html")
)

# Créer le répertoire parent s'il n'existe pas
$parentDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $parentDir -PathType Container)) {
    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
}

# Créer des données de démonstration
$demoData = @{
    "Tri" = @{
        "Dates" = @("2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11")
        "Temps" = @(120, 118, 115, 110, 105, 102, 98, 95, 92, 90, 85)
        "Moyenne" = 102.7
        "Min" = 85
        "Max" = 120
        "Tendance" = -29.2
    }
    "Filtrage" = @{
        "Dates" = @("2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11")
        "Temps" = @(85, 82, 80, 79, 77, 75, 74, 72, 70, 68, 65)
        "Moyenne" = 75.2
        "Min" = 65
        "Max" = 85
        "Tendance" = -23.5
    }
    "Agrégation" = @{
        "Dates" = @("2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11")
        "Temps" = @(150, 148, 145, 142, 140, 138, 135, 132, 130, 128, 125)
        "Moyenne" = 137.5
        "Min" = 125
        "Max" = 150
        "Tendance" = -16.7
    }
    "Traitement parallèle" = @{
        "Dates" = @("2025-04-01", "2025-04-02", "2025-04-03", "2025-04-04", "2025-04-05", "2025-04-06", "2025-04-07", "2025-04-08", "2025-04-09", "2025-04-10", "2025-04-11")
        "Temps" = @(200, 180, 160, 150, 140, 130, 120, 110, 100, 90, 80)
        "Moyenne" = 132.7
        "Min" = 80
        "Max" = 200
        "Tendance" = -60.0
    }
}

# Générer le HTML du tableau de bord
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
        <p>Nombre de fonctions suivies : $($demoData.Count)</p>
        <p>Période d'analyse : 01/04/2025 - 11/04/2025</p>
        <p>Amélioration moyenne des performances : 32.4%</p>
    </div>
    
    <div class="dashboard">
"@

foreach ($name in $demoData.Keys) {
    $data = $demoData[$name]
    
    $trendClass = "trend-neutral"
    $trendSymbol = "→"
    
    if ($data.Tendance -lt -5) {
        $trendClass = "trend-positive"
        $trendSymbol = "↓"
    }
    elseif ($data.Tendance -gt 5) {
        $trendClass = "trend-negative"
        $trendSymbol = "↑"
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
                    <td>$($data.Dates.Count)</td>
                </tr>
                <tr>
                    <td>Temps moyen</td>
                    <td>$([Math]::Round($data.Moyenne, 2)) ms</td>
                </tr>
                <tr>
                    <td>Temps min/max</td>
                    <td>$($data.Min) / $($data.Max) ms</td>
                </tr>
                <tr>
                    <td>Tendance</td>
                    <td class="$trendClass">$trendSymbol $([Math]::Round($data.Tendance, 2))%</td>
                </tr>
            </table>
        </div>
"@
}

$html += @"
    </div>
    
    <script>
"@

foreach ($name in $demoData.Keys) {
    $data = $demoData[$name]
    
    $datesJson = $data.Dates | ConvertTo-Json
    $tempsJson = $data.Temps | ConvertTo-Json
    
    $html += @"
        // Graphique pour $name
        const ctx_$($name -replace '\s+', '_') = document.getElementById('chart_$($name -replace '\s+', '_')').getContext('2d');
        new Chart(ctx_$($name -replace '\s+', '_'), {
            type: 'line',
            data: {
                labels: $datesJson,
                datasets: [{
                    label: '$name',
                    data: $tempsJson,
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    fill: false
                }]
            },
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

# Sauvegarder le tableau de bord
$html | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Tableau de bord généré : $OutputPath" -ForegroundColor Green

# Ouvrir le tableau de bord dans le navigateur par défaut
Start-Process $OutputPath
