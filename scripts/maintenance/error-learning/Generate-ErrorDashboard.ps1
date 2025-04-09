<#
.SYNOPSIS
    Script pour générer un tableau de bord de qualité du code.
.DESCRIPTION
    Ce script génère un tableau de bord HTML de qualité du code basé sur les erreurs collectées.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenInBrowser
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Définir le chemin de sortie par défaut
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "dashboard\error-dashboard.html"
}

# Créer le dossier de sortie s'il n'existe pas
$dashboardDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $dashboardDir)) {
    New-Item -Path $dashboardDir -ItemType Directory -Force | Out-Null
}

# Analyser les erreurs
$analysisResult = Analyze-PowerShellErrors -IncludeStatistics -MaxResults 100
$totalErrors = $analysisResult.Statistics.TotalErrors
$categories = $analysisResult.Statistics.CategorizedErrors
$lastUpdate = $analysisResult.Statistics.LastUpdate
$recentErrors = $analysisResult.Errors

# Préparer les données pour les graphiques
$categoryData = @()
foreach ($category in $categories.Keys) {
    $count = $categories[$category]
    $percentage = [math]::Round(($count / $totalErrors) * 100, 2)
    $categoryData += @{
        Category = $category
        Count = $count
        Percentage = $percentage
    }
}

# Trier les catégories par nombre d'erreurs (décroissant)
$categoryData = $categoryData | Sort-Object -Property Count -Descending

# Préparer les données pour le tableau des erreurs récentes
$errorTableRows = ""
foreach ($error in $recentErrors) {
    $errorTableRows += @"
    <tr>
        <td>$($error.Timestamp)</td>
        <td>$($error.Source)</td>
        <td>$($error.Category)</td>
        <td>$($error.ErrorMessage)</td>
    </tr>
"@
}

# Générer le contenu HTML
$htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de bord des erreurs PowerShell</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .card {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        .card-title {
            margin-top: 0;
            color: #2c3e50;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
        }
        .stats {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
        }
        .stat-card {
            flex: 1;
            min-width: 200px;
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            padding: 15px;
            margin: 10px;
            text-align: center;
        }
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #3498db;
        }
        .stat-label {
            color: #7f8c8d;
            font-size: 14px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .chart-container {
            height: 300px;
            margin-bottom: 20px;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #7f8c8d;
            font-size: 12px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Tableau de bord des erreurs PowerShell</h1>
            <p>Dernière mise à jour : $lastUpdate</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">$totalErrors</div>
                <div class="stat-label">Erreurs totales</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$($categoryData.Count)</div>
                <div class="stat-label">Catégories</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$($recentErrors.Count)</div>
                <div class="stat-label">Erreurs récentes</div>
            </div>
        </div>
        
        <div class="card">
            <h2 class="card-title">Répartition des erreurs par catégorie</h2>
            <div class="chart-container">
                <canvas id="categoryChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2 class="card-title">Erreurs récentes</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Source</th>
                        <th>Catégorie</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
                    $errorTableRows
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p>Généré par le système d'apprentissage des erreurs PowerShell</p>
        </div>
    </div>
    
    <script>
        // Graphique des catégories
        const categoryCtx = document.getElementById('categoryChart').getContext('2d');
        const categoryChart = new Chart(categoryCtx, {
            type: 'bar',
            data: {
                labels: [$(($categoryData | ForEach-Object { "'$($_.Category)'" }) -join ", ")],
                datasets: [{
                    label: 'Nombre d\'erreurs',
                    data: [$(($categoryData | ForEach-Object { $_.Count }) -join ", ")],
                    backgroundColor: 'rgba(52, 152, 219, 0.7)',
                    borderColor: 'rgba(52, 152, 219, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

# Enregistrer le fichier HTML
$htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Tableau de bord généré : $OutputPath"

# Ouvrir dans le navigateur si demandé
if ($OpenInBrowser) {
    Start-Process $OutputPath
}
