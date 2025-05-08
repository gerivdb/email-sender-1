# VisualAsymmetryReport.psm1
# Module pour la génération de rapports visuels d'asymétrie

<#
.SYNOPSIS
    Génère un rapport visuel d'asymétrie au format HTML.

.DESCRIPTION
    Cette fonction génère un rapport visuel complet d'asymétrie au format HTML,
    incluant des visualisations, des statistiques et des recommandations.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER OutputPath
    Le chemin du fichier de sortie HTML (optionnel).

.PARAMETER Title
    Le titre du rapport (par défaut "Rapport d'asymétrie").

.PARAMETER IncludeRecommendations
    Indique si le rapport doit inclure des recommandations (par défaut $true).

.PARAMETER IncludeRawData
    Indique si le rapport doit inclure les données brutes (par défaut $false).

.PARAMETER Theme
    Le thème visuel du rapport (par défaut "Default").
    Les thèmes disponibles sont : Default, Dark, Light, Colorblind.

.EXAMPLE
    Get-AsymmetryVisualReport -Data $data -OutputPath "report.html" -Title "Analyse d'asymétrie"
    Génère un rapport visuel d'asymétrie pour la distribution $data et l'enregistre dans le fichier "report.html".

.OUTPUTS
    System.String
#>
function Get-AsymmetryVisualReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'asymétrie",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRecommendations,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRawData,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dark", "Light", "Colorblind")]
        [string]$Theme = "Default"
    )

    # Vérifier que les modules nécessaires sont disponibles
    $tailSlopeModulePath = Join-Path -Path $PSScriptRoot -ChildPath "TailSlopeAsymmetry.psm1"
    $visualEvaluationModulePath = Join-Path -Path $PSScriptRoot -ChildPath "VisualAsymmetryEvaluation.psm1"
    $recommendationsModulePath = Join-Path -Path $PSScriptRoot -ChildPath "AsymmetryRecommendations.psm1"

    if (-not (Test-Path -Path $tailSlopeModulePath)) {
        throw "Le module TailSlopeAsymmetry.psm1 n'a pas été trouvé: $tailSlopeModulePath"
    }

    if (-not (Test-Path -Path $visualEvaluationModulePath)) {
        throw "Le module VisualAsymmetryEvaluation.psm1 n'a pas été trouvé: $visualEvaluationModulePath"
    }

    # Importer les modules nécessaires
    Import-Module $tailSlopeModulePath -Force
    Import-Module $visualEvaluationModulePath -Force

    # Importer le module de recommandations si disponible
    $hasRecommendations = $false
    if (Test-Path -Path $recommendationsModulePath) {
        Import-Module $recommendationsModulePath -Force
        $hasRecommendations = $true
    }

    # Analyser les données
    try {
        $asymmetryAnalysis = Get-CompositeAsymmetryScore -Data $Data -Methods @("Moments", "Quantiles", "Slope")
    } catch {
        Write-Warning "Erreur lors de l'analyse d'asymétrie statistique: $_"
        $asymmetryAnalysis = [PSCustomObject]@{
            CompositeScore     = 0
            AsymmetryDirection = "Unknown"
            AsymmetryIntensity = "Unknown"
            OptimalMethod      = "Unknown"
            Methods            = @("Moments", "Quantiles", "Slope")
            Results            = @{}
        }
    }

    try {
        $visualEvaluation = Get-VisualAsymmetryEvaluation -Data $Data
    } catch {
        Write-Warning "Erreur lors de l'évaluation visuelle de l'asymétrie: $_"
        $visualEvaluation = [PSCustomObject]@{
            CompositeScore       = 0
            AsymmetryDirection   = "Unknown"
            AsymmetryIntensity   = "Unknown"
            MostConsistentMethod = "Unknown"
            Methods              = @()
            Results              = @{}
        }
    }

    # Générer les recommandations si demandé
    $recommendations = @()
    if (($PSBoundParameters.ContainsKey('IncludeRecommendations') -and $IncludeRecommendations) -or (-not $PSBoundParameters.ContainsKey('IncludeRecommendations'))) {
        if ($hasRecommendations) {
            $recommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $asymmetryAnalysis -IncludeRuleDetails
        }
    }

    # Générer le CSS selon le thème choisi
    $css = Get-ReportThemeCSS -Theme $Theme

    # Calculer les statistiques descriptives
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $mean = ($Data | Measure-Object -Average).Average
    $median = Get-Median -Data $Data

    # Générer le HTML du rapport
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
$css
    </style>
</head>
<body class="theme-$($Theme.ToLower())">
    <header>
        <h1>$Title</h1>
        <p class="report-date">Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
    </header>

    <div class="summary-section">
        <h2>Résumé de l'analyse</h2>
        <div class="summary-grid">
            <div class="summary-card">
                <h3>Analyse statistique</h3>
                <p><strong>Direction d'asymétrie:</strong> <span class="$($asymmetryAnalysis.AsymmetryDirection.ToLower())">$($asymmetryAnalysis.AsymmetryDirection)</span></p>
                <p><strong>Intensité d'asymétrie:</strong> <span class="$($asymmetryAnalysis.AsymmetryIntensity.ToLower())">$($asymmetryAnalysis.AsymmetryIntensity)</span></p>
                <p><strong>Score composite:</strong> $([Math]::Round($asymmetryAnalysis.CompositeScore, 4))</p>
                <p><strong>Méthode optimale:</strong> $($asymmetryAnalysis.OptimalMethod)</p>
            </div>
            <div class="summary-card">
                <h3>Évaluation visuelle</h3>
                <p><strong>Direction d'asymétrie:</strong> <span class="$($visualEvaluation.AsymmetryDirection.ToLower())">$($visualEvaluation.AsymmetryDirection)</span></p>
                <p><strong>Intensité d'asymétrie:</strong> <span class="$($visualEvaluation.AsymmetryIntensity.ToLower())">$($visualEvaluation.AsymmetryIntensity)</span></p>
                <p><strong>Score composite:</strong> $([Math]::Round($visualEvaluation.CompositeScore, 4))</p>
                <p><strong>Méthode la plus cohérente:</strong> $($visualEvaluation.MostConsistentMethod)</p>
            </div>
            <div class="summary-card">
                <h3>Statistiques descriptives</h3>
                <p><strong>Taille de l'échantillon:</strong> $($Data.Count) points</p>
                <p><strong>Minimum:</strong> $([Math]::Round($min, 4))</p>
                <p><strong>Maximum:</strong> $([Math]::Round($max, 4))</p>
                <p><strong>Moyenne:</strong> $([Math]::Round($mean, 4))</p>
                <p><strong>Médiane:</strong> $([Math]::Round($median, 4))</p>
            </div>
        </div>
    </div>

    <div class="visualization-section">
        <h2>Visualisations</h2>
        <div class="visualization-grid">
            <div class="visualization-card">
                <h3>Histogramme</h3>
                <canvas id="histogramChart"></canvas>
            </div>
        </div>
    </div>
"@

    # Ajouter la section des méthodes d'analyse
    $html += @"
    <div class="methods-section">
        <h2>Méthodes d'analyse</h2>
        <div class="methods-grid">
            <div class="methods-card">
                <h3>Méthodes statistiques</h3>
                <table class="methods-table">
                    <thead>
                        <tr>
                            <th>Méthode</th>
                            <th>Score</th>
                            <th>Direction</th>
                            <th>Intensité</th>
                        </tr>
                    </thead>
                    <tbody>
"@

    foreach ($method in $asymmetryAnalysis.Methods) {
        if ($asymmetryAnalysis.Results.ContainsKey($method)) {
            $methodResult = $asymmetryAnalysis.Results[$method]
            $score = if ($null -ne $methodResult.Score) { [Math]::Round($methodResult.Score, 4) } else { 0 }
            $direction = if ($null -ne $methodResult.AsymmetryDirection) { $methodResult.AsymmetryDirection } else { "Unknown" }
            $intensity = if ($null -ne $methodResult.AsymmetryIntensity) { $methodResult.AsymmetryIntensity } else { "Unknown" }

            $html += @"
                        <tr>
                            <td>$method</td>
                            <td>$score</td>
                            <td class="$($direction.ToLower())">$direction</td>
                            <td class="$($intensity.ToLower())">$intensity</td>
                        </tr>
"@
        } else {
            $html += @"
                        <tr>
                            <td>$method</td>
                            <td>0</td>
                            <td>Unknown</td>
                            <td>Unknown</td>
                        </tr>
"@
        }
    }

    $html += @"
                    </tbody>
                </table>
            </div>
            <div class="methods-card">
                <h3>Méthodes visuelles</h3>
                <table class="methods-table">
                    <thead>
                        <tr>
                            <th>Méthode</th>
                            <th>Score</th>
                            <th>Direction</th>
                            <th>Intensité</th>
                        </tr>
                    </thead>
                    <tbody>
"@

    foreach ($method in $visualEvaluation.Methods) {
        if ($visualEvaluation.Results.ContainsKey($method)) {
            $methodResult = $visualEvaluation.Results[$method]
            $score = if ($null -ne $methodResult.Score) { [Math]::Round($methodResult.Score, 4) } else { 0 }
            $direction = if ($null -ne $methodResult.AsymmetryDirection) { $methodResult.AsymmetryDirection } else { "Unknown" }
            $intensity = if ($null -ne $methodResult.AsymmetryIntensity) { $methodResult.AsymmetryIntensity } else { "Unknown" }

            $html += @"
                        <tr>
                            <td>$method</td>
                            <td>$score</td>
                            <td class="$($direction.ToLower())">$direction</td>
                            <td class="$($intensity.ToLower())">$intensity</td>
                        </tr>
"@
        } else {
            $html += @"
                        <tr>
                            <td>$method</td>
                            <td>0</td>
                            <td>Unknown</td>
                            <td>Unknown</td>
                        </tr>
"@
        }
    }

    $html += @"
                    </tbody>
                </table>
            </div>
        </div>
    </div>
"@

    # Ajouter la section des recommandations si demandé
    if ((($PSBoundParameters.ContainsKey('IncludeRecommendations') -and $IncludeRecommendations) -or (-not $PSBoundParameters.ContainsKey('IncludeRecommendations'))) -and $hasRecommendations -and $recommendations.Count -gt 0) {
        $html += @"
    <div class="recommendations-section">
        <h2>Recommandations</h2>
        <div class="recommendations-list">
"@

        foreach ($recommendation in $recommendations) {
            $html += @"
            <div class="recommendation-card">
                <h3>$($recommendation.RuleName)</h3>
                <p class="recommendation-text">$($recommendation.Recommendation)</p>
                <div class="recommendation-meta">
                    <span class="recommendation-category">Catégorie: $($recommendation.Category)</span>
                    <span class="recommendation-priority">Priorité: $($recommendation.Priority)</span>
                </div>
            </div>
"@
        }

        $html += @"
        </div>
    </div>
"@
    }

    # Ajouter les données brutes si demandé
    if ($PSBoundParameters.ContainsKey('IncludeRawData') -and $IncludeRawData) {
        $html += @"
    <div class="raw-data-section">
        <h2>Données brutes</h2>
        <div class="raw-data-container">
            <pre class="raw-data-pre">$($Data -join ", ")</pre>
        </div>
    </div>
"@
    }

    # Ajouter le JavaScript pour les visualisations
    $html += @"
    <script>
        // Données pour l'histogramme
        const histogramData = {
            labels: [],
            datasets: [{
                label: 'Fréquence',
                data: [],
                backgroundColor: [],
                borderColor: [],
                borderWidth: 1
            }]
        };

        // Créer l'histogramme
        const histogram = new Chart(document.getElementById('histogramChart').getContext('2d'), {
            type: 'bar',
            data: histogramData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Fréquence'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Classes'
                        }
                    }
                }
            }
        });

        // Fonction pour mettre à jour l'histogramme
        function updateHistogram(data) {
            // Calculer l'histogramme
            const min = Math.min(...data);
            const max = Math.max(...data);
            const range = max - min;
            const binCount = 20;
            const binWidth = range / binCount;

            // Créer les classes
            const bins = [];
            for (let i = 0; i <= binCount; i++) {
                bins.push(min + i * binWidth);
            }

            // Compter les fréquences
            const frequencies = Array(binCount).fill(0);
            data.forEach(value => {
                const binIndex = Math.min(binCount - 1, Math.floor((value - min) / binWidth));
                frequencies[binIndex]++;
            });

            // Normaliser les fréquences
            const sum = frequencies.reduce((a, b) => a + b, 0);
            const normalizedFrequencies = frequencies.map(f => f / sum);

            // Créer les étiquettes des classes
            const binLabels = [];
            for (let i = 0; i < bins.length - 1; i++) {
                binLabels.push(`[${bins[i].toFixed(2)}, ${bins[i + 1].toFixed(2)})`);
            }

            // Calculer la médiane
            const sortedData = [...data].sort((a, b) => a - b);
            const median = sortedData.length % 2 === 0
                ? (sortedData[sortedData.length / 2 - 1] + sortedData[sortedData.length / 2]) / 2
                : sortedData[Math.floor(sortedData.length / 2)];

            // Trouver l'indice de la classe contenant la médiane
            let medianBinIndex = 0;
            for (let i = 0; i < bins.length - 1; i++) {
                if (median >= bins[i] && median < bins[i + 1]) {
                    medianBinIndex = i;
                    break;
                }
            }

            // Mettre à jour les données de l'histogramme
            histogramData.labels = binLabels;
            histogramData.datasets[0].data = normalizedFrequencies;

            // Définir les couleurs en fonction de la position par rapport à la médiane
            histogramData.datasets[0].backgroundColor = binLabels.map((_, i) =>
                i <= medianBinIndex ? 'rgba(54, 162, 235, 0.6)' : 'rgba(255, 99, 132, 0.6)'
            );
            histogramData.datasets[0].borderColor = binLabels.map((_, i) =>
                i <= medianBinIndex ? 'rgba(54, 162, 235, 1)' : 'rgba(255, 99, 132, 1)'
            );

            // Mettre à jour le graphique
            histogram.update();
        }

        // Mettre à jour l'histogramme avec les données
        const dataArray = [
            $($Data | ForEach-Object { "$([double]$_)" } | Join-String -Separator ", ")
        ];
        updateHistogram(dataArray);
    </script>
</body>
</html>
"@

    # Écrire le HTML dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport HTML écrit dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture du rapport HTML dans le fichier: $_"
        }
    }

    return $html
}

<#
.SYNOPSIS
    Génère le CSS pour un thème de rapport.

.DESCRIPTION
    Cette fonction génère le CSS pour un thème de rapport spécifique.

.PARAMETER Theme
    Le thème visuel du rapport.
    Les thèmes disponibles sont : Default, Dark, Light, Colorblind.

.EXAMPLE
    Get-ReportThemeCSS -Theme "Dark"
    Génère le CSS pour le thème Dark.

.OUTPUTS
    System.String
#>
function Get-ReportThemeCSS {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Default", "Dark", "Light", "Colorblind")]
        [string]$Theme
    )

    $baseCSS = @"
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }

        header {
            margin-bottom: 30px;
        }

        h1, h2, h3 {
            margin-top: 0;
        }

        .report-date {
            font-style: italic;
            color: #666;
        }

        .summary-section, .visualization-section, .methods-section, .recommendations-section, .raw-data-section {
            margin-bottom: 40px;
            padding: 20px;
            border-radius: 8px;
        }

        .summary-grid, .visualization-grid, .methods-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }

        .summary-card, .visualization-card, .methods-card, .recommendation-card {
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }

        .methods-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }

        .methods-table th, .methods-table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        .methods-table th {
            font-weight: bold;
        }

        .recommendations-list {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }

        .recommendation-text {
            margin-bottom: 10px;
        }

        .recommendation-meta {
            display: flex;
            justify-content: space-between;
            font-size: 0.9em;
            color: #666;
        }

        .raw-data-container {
            max-height: 300px;
            overflow-y: auto;
            padding: 10px;
            border-radius: 4px;
        }

        .raw-data-pre {
            white-space: pre-wrap;
            word-break: break-all;
            margin: 0;
        }

        .positive {
            color: #27ae60;
        }

        .negative {
            color: #e74c3c;
        }

        .symmetric {
            color: #3498db;
        }

        .negligible {
            font-weight: normal;
        }

        .veryweak, .weak {
            font-weight: normal;
        }

        .moderate {
            font-weight: bold;
        }

        .strong, .verystrong, .extreme {
            font-weight: bold;
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .summary-grid, .visualization-grid, .methods-grid, .recommendations-list {
                grid-template-columns: 1fr;
            }
        }

        @media print {
            body {
                padding: 0;
            }

            .summary-section, .visualization-section, .methods-section, .recommendations-section, .raw-data-section {
                break-inside: avoid;
                page-break-inside: avoid;
            }
        }
"@

    # Ajouter le CSS spécifique au thème
    switch ($Theme) {
        "Dark" {
            $themeCSS = @"
        .theme-dark {
            background-color: #1e1e1e;
            color: #f0f0f0;
        }

        .theme-dark h1, .theme-dark h2, .theme-dark h3 {
            color: #ffffff;
        }

        .theme-dark .report-date {
            color: #aaaaaa;
        }

        .theme-dark .summary-section, .theme-dark .visualization-section, .theme-dark .methods-section, .theme-dark .recommendations-section, .theme-dark .raw-data-section {
            background-color: #2d2d2d;
        }

        .theme-dark .summary-card, .theme-dark .visualization-card, .theme-dark .methods-card, .theme-dark .recommendation-card {
            background-color: #3d3d3d;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3);
        }

        .theme-dark .methods-table th, .theme-dark .methods-table td {
            border-bottom: 1px solid #555;
        }

        .theme-dark .recommendation-meta {
            color: #aaaaaa;
        }

        .theme-dark .raw-data-container {
            background-color: #2d2d2d;
            border: 1px solid #555;
        }

        .theme-dark .positive {
            color: #2ecc71;
        }

        .theme-dark .negative {
            color: #e74c3c;
        }

        .theme-dark .symmetric {
            color: #3498db;
        }
"@
        }
        "Light" {
            $themeCSS = @"
        .theme-light {
            background-color: #f8f9fa;
            color: #333333;
        }

        .theme-light h1, .theme-light h2, .theme-light h3 {
            color: #212529;
        }

        .theme-light .report-date {
            color: #6c757d;
        }

        .theme-light .summary-section, .theme-light .visualization-section, .theme-light .methods-section, .theme-light .recommendations-section, .theme-light .raw-data-section {
            background-color: #ffffff;
            border: 1px solid #dee2e6;
        }

        .theme-light .summary-card, .theme-light .visualization-card, .theme-light .methods-card, .theme-light .recommendation-card {
            background-color: #f8f9fa;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
        }

        .theme-light .methods-table th, .theme-light .methods-table td {
            border-bottom: 1px solid #dee2e6;
        }

        .theme-light .recommendation-meta {
            color: #6c757d;
        }

        .theme-light .raw-data-container {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
        }

        .theme-light .positive {
            color: #28a745;
        }

        .theme-light .negative {
            color: #dc3545;
        }

        .theme-light .symmetric {
            color: #007bff;
        }
"@
        }
        "Colorblind" {
            $themeCSS = @"
        .theme-colorblind {
            background-color: #ffffff;
            color: #333333;
        }

        .theme-colorblind h1, .theme-colorblind h2, .theme-colorblind h3 {
            color: #000000;
        }

        .theme-colorblind .report-date {
            color: #666666;
        }

        .theme-colorblind .summary-section, .theme-colorblind .visualization-section, .theme-colorblind .methods-section, .theme-colorblind .recommendations-section, .theme-colorblind .raw-data-section {
            background-color: #f5f5f5;
            border: 1px solid #dddddd;
        }

        .theme-colorblind .summary-card, .theme-colorblind .visualization-card, .theme-colorblind .methods-card, .theme-colorblind .recommendation-card {
            background-color: #ffffff;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            border: 1px solid #dddddd;
        }

        .theme-colorblind .methods-table th, .theme-colorblind .methods-table td {
            border-bottom: 1px solid #dddddd;
        }

        .theme-colorblind .recommendation-meta {
            color: #666666;
        }

        .theme-colorblind .raw-data-container {
            background-color: #f5f5f5;
            border: 1px solid #dddddd;
        }

        .theme-colorblind .positive {
            color: #0072B2;
        }

        .theme-colorblind .negative {
            color: #D55E00;
        }

        .theme-colorblind .symmetric {
            color: #009E73;
        }
"@
        }
        default {
            $themeCSS = @"
        .theme-default {
            background-color: #ffffff;
            color: #333333;
        }

        .theme-default h1, .theme-default h2, .theme-default h3 {
            color: #2c3e50;
        }

        .theme-default .report-date {
            color: #7f8c8d;
        }

        .theme-default .summary-section, .theme-default .visualization-section, .theme-default .methods-section, .theme-default .recommendations-section, .theme-default .raw-data-section {
            background-color: #f8f9fa;
            border: 1px solid #e9ecef;
        }

        .theme-default .summary-card, .theme-default .visualization-card, .theme-default .methods-card, .theme-default .recommendation-card {
            background-color: #ffffff;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }

        .theme-default .methods-table th, .theme-default .methods-table td {
            border-bottom: 1px solid #e9ecef;
        }

        .theme-default .recommendation-meta {
            color: #7f8c8d;
        }

        .theme-default .raw-data-container {
            background-color: #f8f9fa;
            border: 1px solid #e9ecef;
        }

        .theme-default .positive {
            color: #27ae60;
        }

        .theme-default .negative {
            color: #e74c3c;
        }

        .theme-default .symmetric {
            color: #3498db;
        }
"@
        }
    }

    return $baseCSS + $themeCSS
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-AsymmetryVisualReport, Get-ReportThemeCSS
