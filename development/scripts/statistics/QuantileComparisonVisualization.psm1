# QuantileComparisonVisualization.psm1
# Module pour la visualisation des comparaisons de quantiles

<#
.SYNOPSIS
    Génère un graphique HTML interactif pour visualiser un graphique quantile-quantile (Q-Q plot).

.DESCRIPTION
    Cette fonction génère un graphique HTML interactif pour visualiser un graphique quantile-quantile (Q-Q plot)
    qui permet de comparer visuellement deux distributions.

.PARAMETER QQPlotData
    Les données du graphique Q-Q générées par la fonction Get-QuantileQuantilePlot.

.PARAMETER OutputPath
    Le chemin du fichier HTML de sortie.

.PARAMETER Title
    Le titre du graphique (par défaut, "Graphique Quantile-Quantile").

.PARAMETER Theme
    Le thème du graphique (par défaut, "Default").
    Les thèmes disponibles sont :
    - Default : Thème par défaut
    - Dark : Thème sombre
    - Light : Thème clair
    - Colorblind : Thème adapté aux daltoniens

.PARAMETER Width
    La largeur du graphique en pixels (par défaut, 800).

.PARAMETER Height
    La hauteur du graphique en pixels (par défaut, 600).

.PARAMETER ShowConfidenceBands
    Indique si les bandes de confiance doivent être affichées (par défaut, $true).

.PARAMETER ShowDiagonal
    Indique si la diagonale doit être affichée (par défaut, $true).

.PARAMETER ShowMetrics
    Indique si les métriques de comparaison doivent être affichées (par défaut, $true).

.EXAMPLE
    Get-QuantileQuantilePlotVisualization -QQPlotData $qqPlotData -OutputPath "qqplot.html" -Title "Comparaison des distributions"
    Génère un graphique HTML interactif pour visualiser un graphique Q-Q.

.OUTPUTS
    System.String
#>
function Get-QuantileQuantilePlotVisualization {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject]$QQPlotData,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Graphique Quantile-Quantile",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light", "Colorblind")]
        [string]$Theme = "Default",

        [Parameter(Mandatory = $false)]
        [int]$Width = 800,

        [Parameter(Mandatory = $false)]
        [int]$Height = 600,

        [Parameter(Mandatory = $false)]
        [bool]$ShowConfidenceBands = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ShowDiagonal = $true,

        [Parameter(Mandatory = $false)]
        [bool]$ShowMetrics = $true
    )

    # Vérifier que les données sont valides
    if ($null -eq $QQPlotData.ReferenceQuantiles -or $null -eq $QQPlotData.ComparisonQuantiles) {
        throw "Les données du graphique Q-Q ne sont pas valides."
    }

    # Définir les couleurs selon le thème
    $colors = @{
        Default = @{
            Background = "#ffffff"
            Text = "#333333"
            Grid = "#dddddd"
            Point = "#1f77b4"
            Diagonal = "#ff7f0e"
            ConfidenceBand = "rgba(31, 119, 180, 0.2)"
            ConfidenceBandBorder = "rgba(31, 119, 180, 0.5)"
        }
        Dark = @{
            Background = "#333333"
            Text = "#ffffff"
            Grid = "#555555"
            Point = "#1f77b4"
            Diagonal = "#ff7f0e"
            ConfidenceBand = "rgba(31, 119, 180, 0.2)"
            ConfidenceBandBorder = "rgba(31, 119, 180, 0.5)"
        }
        Light = @{
            Background = "#f5f5f5"
            Text = "#333333"
            Grid = "#dddddd"
            Point = "#1f77b4"
            Diagonal = "#ff7f0e"
            ConfidenceBand = "rgba(31, 119, 180, 0.2)"
            ConfidenceBandBorder = "rgba(31, 119, 180, 0.5)"
        }
        Colorblind = @{
            Background = "#ffffff"
            Text = "#333333"
            Grid = "#dddddd"
            Point = "#0072b2"
            Diagonal = "#e69f00"
            ConfidenceBand = "rgba(0, 114, 178, 0.2)"
            ConfidenceBandBorder = "rgba(0, 114, 178, 0.5)"
        }
    }

    # Sélectionner les couleurs selon le thème
    $themeColors = $colors[$Theme]

    # Préparer les données pour le graphique
    $referenceQuantiles = $QQPlotData.ReferenceQuantiles | ConvertTo-Json
    $comparisonQuantiles = $QQPlotData.ComparisonQuantiles | ConvertTo-Json
    
    $lowerBand = if ($null -ne $QQPlotData.LowerBand) { $QQPlotData.LowerBand | ConvertTo-Json } else { "null" }
    $upperBand = if ($null -ne $QQPlotData.UpperBand) { $QQPlotData.UpperBand | ConvertTo-Json } else { "null" }
    
    # Calculer les limites du graphique
    $allQuantiles = $QQPlotData.ReferenceQuantiles + $QQPlotData.ComparisonQuantiles
    if ($null -ne $QQPlotData.LowerBand) { $allQuantiles += $QQPlotData.LowerBand }
    if ($null -ne $QQPlotData.UpperBand) { $allQuantiles += $QQPlotData.UpperBand }
    
    $min = ($allQuantiles | Measure-Object -Minimum).Minimum
    $max = ($allQuantiles | Measure-Object -Maximum).Maximum
    
    $padding = ($max - $min) * 0.1
    $min = $min - $padding
    $max = $max + $padding

    # Préparer les métriques pour l'affichage
    $metricsHtml = ""
    if ($ShowMetrics) {
        $metricsHtml = @"
        <div class="metrics-container">
            <h3>Métriques de comparaison</h3>
            <table class="metrics-table">
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Déviation moyenne</td>
                    <td>$([Math]::Round($QQPlotData.MeanDeviation, 4))</td>
                </tr>
                <tr>
                    <td>Déviation maximale</td>
                    <td>$([Math]::Round($QQPlotData.MaxDeviation, 4))</td>
                </tr>
                <tr>
                    <td>Déviation minimale</td>
                    <td>$([Math]::Round($QQPlotData.MinDeviation, 4))</td>
                </tr>
                <tr>
                    <td>Somme des carrés des déviations</td>
                    <td>$([Math]::Round($QQPlotData.SumSquaredDeviation, 4))</td>
                </tr>
            </table>
        </div>
"@
    }

    # Générer le HTML
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
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: $($themeColors.Background);
            color: $($themeColors.Text);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .chart-container {
            width: ${Width}px;
            height: ${Height}px;
            margin: 0 auto;
        }
        
        .metrics-container {
            margin-top: 30px;
            padding: 20px;
            border: 1px solid $($themeColors.Grid);
            border-radius: 5px;
        }
        
        .metrics-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .metrics-table th, .metrics-table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid $($themeColors.Grid);
        }
        
        .metrics-table th {
            background-color: rgba(0, 0, 0, 0.1);
        }
        
        @media print {
            body {
                background-color: white;
                color: black;
            }
            
            .metrics-container {
                border: 1px solid #ccc;
            }
            
            .metrics-table th, .metrics-table td {
                border-bottom: 1px solid #ccc;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        
        <div class="chart-container">
            <canvas id="qqPlotChart"></canvas>
        </div>
        
        $metricsHtml
    </div>
    
    <script>
        // Données du graphique Q-Q
        const referenceQuantiles = $referenceQuantiles;
        const comparisonQuantiles = $comparisonQuantiles;
        const lowerBand = $lowerBand;
        const upperBand = $upperBand;
        
        // Créer le graphique
        const ctx = document.getElementById('qqPlotChart').getContext('2d');
        
        // Préparer les données pour le graphique
        const data = {
            datasets: [
                {
                    label: 'Points Q-Q',
                    data: referenceQuantiles.map((x, i) => ({ x, y: comparisonQuantiles[i] })),
                    backgroundColor: '$($themeColors.Point)',
                    borderColor: '$($themeColors.Point)',
                    pointRadius: 3,
                    pointHoverRadius: 5,
                    showLine: false
                }
            ]
        };
        
        // Ajouter la diagonale si demandé
        if ($($ShowDiagonal.ToString().ToLower())) {
            data.datasets.push({
                label: 'Diagonale',
                data: [
                    { x: $min, y: $min },
                    { x: $max, y: $max }
                ],
                backgroundColor: '$($themeColors.Diagonal)',
                borderColor: '$($themeColors.Diagonal)',
                pointRadius: 0,
                borderWidth: 2,
                borderDash: [5, 5],
                fill: false
            });
        }
        
        // Ajouter les bandes de confiance si demandé et disponibles
        if ($($ShowConfidenceBands.ToString().ToLower()) && lowerBand !== null && upperBand !== null) {
            // Bande de confiance inférieure
            data.datasets.push({
                label: 'Bande de confiance inférieure',
                data: referenceQuantiles.map((x, i) => ({ x, y: lowerBand[i] })),
                backgroundColor: 'transparent',
                borderColor: '$($themeColors.ConfidenceBandBorder)',
                pointRadius: 0,
                borderWidth: 1,
                borderDash: [3, 3],
                fill: false
            });
            
            // Bande de confiance supérieure
            data.datasets.push({
                label: 'Bande de confiance supérieure',
                data: referenceQuantiles.map((x, i) => ({ x, y: upperBand[i] })),
                backgroundColor: 'transparent',
                borderColor: '$($themeColors.ConfidenceBandBorder)',
                pointRadius: 0,
                borderWidth: 1,
                borderDash: [3, 3],
                fill: '+1'
            });
            
            // Zone entre les bandes de confiance
            data.datasets.push({
                label: 'Zone de confiance',
                data: referenceQuantiles.map((x, i) => ({ x, y: lowerBand[i] })),
                backgroundColor: '$($themeColors.ConfidenceBand)',
                borderColor: 'transparent',
                pointRadius: 0,
                fill: '+1'
            });
        }
        
        // Configuration du graphique
        const config = {
            type: 'scatter',
            data: data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: 'Quantiles de référence',
                            color: '$($themeColors.Text)'
                        },
                        min: $min,
                        max: $max,
                        grid: {
                            color: '$($themeColors.Grid)'
                        },
                        ticks: {
                            color: '$($themeColors.Text)'
                        }
                    },
                    y: {
                        title: {
                            display: true,
                            text: 'Quantiles de comparaison',
                            color: '$($themeColors.Text)'
                        },
                        min: $min,
                        max: $max,
                        grid: {
                            color: '$($themeColors.Grid)'
                        },
                        ticks: {
                            color: '$($themeColors.Text)'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: '$Title',
                        color: '$($themeColors.Text)',
                        font: {
                            size: 16
                        }
                    },
                    legend: {
                        display: true,
                        labels: {
                            color: '$($themeColors.Text)'
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const index = context.dataIndex;
                                const probability = (index / referenceQuantiles.length).toFixed(2);
                                return [
                                    `Probabilité: ${probability}`,
                                    `Référence: ${context.parsed.x.toFixed(4)}`,
                                    `Comparaison: ${context.parsed.y.toFixed(4)}`,
                                    `Déviation: ${(context.parsed.y - context.parsed.x).toFixed(4)}`
                                ];
                            }
                        }
                    }
                }
            }
        };
        
        // Créer le graphique
        const qqPlotChart = new Chart(ctx, config);
    </script>
</body>
</html>
"@

    # Enregistrer le HTML dans un fichier
    $html | Out-File -FilePath $OutputPath -Encoding UTF8

    return $OutputPath
}

<#
.SYNOPSIS
    Génère un graphique HTML interactif pour visualiser les métriques de comparaison entre distributions.

.DESCRIPTION
    Cette fonction génère un graphique HTML interactif pour visualiser les métriques de comparaison
    entre plusieurs distributions.

.PARAMETER ComparisonMetrics
    Un tableau d'objets contenant les métriques de comparaison générées par la fonction Get-QuantileComparisonMetrics.

.PARAMETER OutputPath
    Le chemin du fichier HTML de sortie.

.PARAMETER Title
    Le titre du graphique (par défaut, "Comparaison des métriques entre distributions").

.PARAMETER Theme
    Le thème du graphique (par défaut, "Default").
    Les thèmes disponibles sont :
    - Default : Thème par défaut
    - Dark : Thème sombre
    - Light : Thème clair
    - Colorblind : Thème adapté aux daltoniens

.PARAMETER Width
    La largeur du graphique en pixels (par défaut, 800).

.PARAMETER Height
    La hauteur du graphique en pixels (par défaut, 600).

.EXAMPLE
    Get-ComparisonMetricsVisualization -ComparisonMetrics $metricsArray -OutputPath "metrics.html" -Title "Comparaison des distributions"
    Génère un graphique HTML interactif pour visualiser les métriques de comparaison entre distributions.

.OUTPUTS
    System.String
#>
function Get-ComparisonMetricsVisualization {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject[]]$ComparisonMetrics,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Comparaison des métriques entre distributions",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light", "Colorblind")]
        [string]$Theme = "Default",

        [Parameter(Mandatory = $false)]
        [int]$Width = 800,

        [Parameter(Mandatory = $false)]
        [int]$Height = 600
    )

    # Vérifier que les données sont valides
    if ($ComparisonMetrics.Count -eq 0) {
        throw "Aucune métrique de comparaison n'a été fournie."
    }

    # Définir les couleurs selon le thème
    $colors = @{
        Default = @{
            Background = "#ffffff"
            Text = "#333333"
            Grid = "#dddddd"
            Bars = @("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")
        }
        Dark = @{
            Background = "#333333"
            Text = "#ffffff"
            Grid = "#555555"
            Bars = @("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")
        }
        Light = @{
            Background = "#f5f5f5"
            Text = "#333333"
            Grid = "#dddddd"
            Bars = @("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")
        }
        Colorblind = @{
            Background = "#ffffff"
            Text = "#333333"
            Grid = "#dddddd"
            Bars = @("#0072b2", "#e69f00", "#009e73", "#cc79a7", "#56b4e9", "#d55e00", "#f0e442", "#000000")
        }
    }

    # Sélectionner les couleurs selon le thème
    $themeColors = $colors[$Theme]

    # Préparer les données pour le graphique
    $labels = @()
    $datasets = @()
    $metricNames = @()

    # Collecter tous les noms de métriques
    foreach ($metrics in $ComparisonMetrics) {
        foreach ($key in $metrics.Metrics.Keys) {
            if ($metricNames -notcontains $key) {
                $metricNames += $key
            }
        }
    }

    # Préparer les données pour chaque métrique
    foreach ($metricName in $metricNames) {
        $data = @()
        $backgroundColor = $themeColors.Bars[$datasets.Count % $themeColors.Bars.Count]
        
        foreach ($metrics in $ComparisonMetrics) {
            if ($metrics.Metrics.ContainsKey($metricName)) {
                $data += $metrics.Metrics[$metricName]
            } else {
                $data += 0
            }
        }
        
        $datasets += @{
            label = $metricName
            data = $data
            backgroundColor = $backgroundColor
        }
    }

    # Préparer les labels pour chaque comparaison
    for ($i = 0; $i -lt $ComparisonMetrics.Count; $i++) {
        $labels += "Comparaison $($i + 1)"
    }

    # Convertir les données en JSON
    $labelsJson = $labels | ConvertTo-Json
    $datasetsJson = $datasets | ConvertTo-Json -Depth 3

    # Générer le HTML
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
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: $($themeColors.Background);
            color: $($themeColors.Text);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1 {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .chart-container {
            width: ${Width}px;
            height: ${Height}px;
            margin: 0 auto;
        }
        
        @media print {
            body {
                background-color: white;
                color: black;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        
        <div class="chart-container">
            <canvas id="metricsChart"></canvas>
        </div>
    </div>
    
    <script>
        // Données du graphique
        const labels = $labelsJson;
        const datasets = $datasetsJson;
        
        // Créer le graphique
        const ctx = document.getElementById('metricsChart').getContext('2d');
        
        // Configuration du graphique
        const config = {
            type: 'bar',
            data: {
                labels: labels,
                datasets: datasets
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: 'Comparaisons',
                            color: '$($themeColors.Text)'
                        },
                        grid: {
                            color: '$($themeColors.Grid)'
                        },
                        ticks: {
                            color: '$($themeColors.Text)'
                        }
                    },
                    y: {
                        title: {
                            display: true,
                            text: 'Valeurs des métriques',
                            color: '$($themeColors.Text)'
                        },
                        grid: {
                            color: '$($themeColors.Grid)'
                        },
                        ticks: {
                            color: '$($themeColors.Text)'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: '$Title',
                        color: '$($themeColors.Text)',
                        font: {
                            size: 16
                        }
                    },
                    legend: {
                        display: true,
                        labels: {
                            color: '$($themeColors.Text)'
                        }
                    }
                }
            }
        };
        
        // Créer le graphique
        const metricsChart = new Chart(ctx, config);
    </script>
</body>
</html>
"@

    # Enregistrer le HTML dans un fichier
    $html | Out-File -FilePath $OutputPath -Encoding UTF8

    return $OutputPath
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-QuantileQuantilePlotVisualization, Get-ComparisonMetricsVisualization
