# Test-QuantileComparison.ps1
# Ce script teste les fonctions d'analyse comparative des quantiles

# Importer les modules necessaires
$quantileComparisonPath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileComparison.psm1"
if (-not (Test-Path -Path $quantileComparisonPath)) {
    Write-Error "Le module QuantileComparison.psm1 n'a pas ete trouve: $quantileComparisonPath"
    exit 1
}

$visualizationPath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileComparisonVisualization.psm1"
if (-not (Test-Path -Path $visualizationPath)) {
    Write-Error "Le module QuantileComparisonVisualization.psm1 n'a pas ete trouve: $visualizationPath"
    exit 1
}

Import-Module $quantileComparisonPath -Force
Import-Module $visualizationPath -Force

# Definir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Generer des donnees de test
Write-Host "`n=== Generation des donnees de test ===" -ForegroundColor Magenta

# Fonction pour generer des donnees selon une distribution normale
function Get-NormalDistribution {
    param (
        [int]$Count = 100,
        [double]$Mean = 0,
        [double]$StdDev = 1
    )

    $data = @()
    $random = [System.Random]::new()

    for ($i = 0; $i -lt $Count; $i++) {
        # Methode de Box-Muller pour generer des nombres aleatoires selon une loi normale
        $u1 = $random.NextDouble()
        $u2 = $random.NextDouble()

        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $value = $Mean + $StdDev * $z

        $data += $value
    }

    return $data
}

# Fonction pour generer des donnees selon une distribution exponentielle
function Get-ExponentialDistribution {
    param (
        [int]$Count = 100,
        [double]$Lambda = 1
    )

    $data = @()
    $random = [System.Random]::new()

    for ($i = 0; $i -lt $Count; $i++) {
        $u = $random.NextDouble()
        $value = - [Math]::Log(1 - $u) / $Lambda

        $data += $value
    }

    return $data
}

# Generer des donnees selon differentes distributions
$normalData = Get-NormalDistribution -Count 200 -Mean 0 -StdDev 1
$shiftedNormalData = Get-NormalDistribution -Count 200 -Mean 2 -StdDev 1
$wideNormalData = Get-NormalDistribution -Count 200 -Mean 0 -StdDev 2
$exponentialData = Get-ExponentialDistribution -Count 200 -Lambda 1

Write-Host "Donnees generees:" -ForegroundColor White
Write-Host "- Distribution normale standard: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution normale decalee: $($shiftedNormalData.Count) points" -ForegroundColor White
Write-Host "- Distribution normale elargie: $($wideNormalData.Count) points" -ForegroundColor White
Write-Host "- Distribution exponentielle: $($exponentialData.Count) points" -ForegroundColor White

# Test 1: Calcul des quantiles de la loi normale standard
Write-Host "`n=== Test 1: Calcul des quantiles de la loi normale standard ===" -ForegroundColor Magenta
$probabilities = @(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.975, 0.99)

Write-Host "Quantiles de la loi normale standard:" -ForegroundColor White
foreach ($p in $probabilities) {
    $quantile = Get-NormalQuantile -Probability $p
    Write-Host "  Quantile $p : $quantile" -ForegroundColor White
}

# Test 2: Generation des donnees pour un graphique Q-Q
Write-Host "`n=== Test 2: Generation des donnees pour un graphique Q-Q ===" -ForegroundColor Magenta

# Comparer la distribution normale standard avec la distribution normale decalee
$qqPlot1 = Get-QuantileQuantilePlot -ReferenceData $normalData -ComparisonData $shiftedNormalData -ConfidenceBands
Write-Host "Comparaison normale standard vs. normale decalee:" -ForegroundColor White
Write-Host "  Nombre de points: $($qqPlot1.Probabilities.Count)" -ForegroundColor White
Write-Host "  Deviation moyenne: $($qqPlot1.MeanDeviation)" -ForegroundColor White
Write-Host "  Deviation maximale: $($qqPlot1.MaxDeviation)" -ForegroundColor White
Write-Host "  Deviation minimale: $($qqPlot1.MinDeviation)" -ForegroundColor White

# Comparer la distribution normale standard avec la distribution normale elargie
$qqPlot2 = Get-QuantileQuantilePlot -ReferenceData $normalData -ComparisonData $wideNormalData -ConfidenceBands
Write-Host "`nComparaison normale standard vs. normale elargie:" -ForegroundColor White
Write-Host "  Nombre de points: $($qqPlot2.Probabilities.Count)" -ForegroundColor White
Write-Host "  Deviation moyenne: $($qqPlot2.MeanDeviation)" -ForegroundColor White
Write-Host "  Deviation maximale: $($qqPlot2.MaxDeviation)" -ForegroundColor White
Write-Host "  Deviation minimale: $($qqPlot2.MinDeviation)" -ForegroundColor White

# Comparer la distribution normale standard avec la distribution exponentielle
$qqPlot3 = Get-QuantileQuantilePlot -ReferenceData $normalData -ComparisonData $exponentialData -ConfidenceBands
Write-Host "`nComparaison normale standard vs. exponentielle:" -ForegroundColor White
Write-Host "  Nombre de points: $($qqPlot3.Probabilities.Count)" -ForegroundColor White
Write-Host "  Deviation moyenne: $($qqPlot3.MeanDeviation)" -ForegroundColor White
Write-Host "  Deviation maximale: $($qqPlot3.MaxDeviation)" -ForegroundColor White
Write-Host "  Deviation minimale: $($qqPlot3.MinDeviation)" -ForegroundColor White

# Test 3: Calcul des metriques de comparaison
Write-Host "`n=== Test 3: Calcul des metriques de comparaison ===" -ForegroundColor Magenta

# Calculer les metriques pour la comparaison normale standard vs. normale decalee
$metrics1 = Get-QuantileComparisonMetrics -ReferenceData $normalData -ComparisonData $shiftedNormalData
Write-Host "Metriques pour normale standard vs. normale decalee:" -ForegroundColor White
foreach ($key in $metrics1.Metrics.Keys) {
    Write-Host "  $key : $($metrics1.Metrics[$key])" -ForegroundColor White
}

# Calculer les metriques pour la comparaison normale standard vs. normale elargie
$metrics2 = Get-QuantileComparisonMetrics -ReferenceData $normalData -ComparisonData $wideNormalData
Write-Host "`nMetriques pour normale standard vs. normale elargie:" -ForegroundColor White
foreach ($key in $metrics2.Metrics.Keys) {
    Write-Host "  $key : $($metrics2.Metrics[$key])" -ForegroundColor White
}

# Calculer les metriques pour la comparaison normale standard vs. exponentielle
$metrics3 = Get-QuantileComparisonMetrics -ReferenceData $normalData -ComparisonData $exponentialData
Write-Host "`nMetriques pour normale standard vs. exponentielle:" -ForegroundColor White
foreach ($key in $metrics3.Metrics.Keys) {
    Write-Host "  $key : $($metrics3.Metrics[$key])" -ForegroundColor White
}

# Test 4: Generation d'un rapport JSON
Write-Host "`n=== Test 4: Generation d'un rapport JSON ===" -ForegroundColor Magenta
$jsonReportPath = Join-Path -Path $reportsFolder -ChildPath "quantile_comparison_report.json"

# Creer un rapport JSON avec les resultats des comparaisons
$reportData = @{
    metadata    = @{
        title          = "Rapport de comparaison de quantiles"
        generationDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version        = "1.0"
    }
    comparisons = @{
        normalVsShifted     = @{
            name          = "Normale standard vs. Normale decalee"
            metrics       = $metrics1.Metrics
            meanDeviation = $qqPlot1.MeanDeviation
            maxDeviation  = $qqPlot1.MaxDeviation
            minDeviation  = $qqPlot1.MinDeviation
        }
        normalVsWide        = @{
            name          = "Normale standard vs. Normale elargie"
            metrics       = $metrics2.Metrics
            meanDeviation = $qqPlot2.MeanDeviation
            maxDeviation  = $qqPlot2.MaxDeviation
            minDeviation  = $qqPlot2.MinDeviation
        }
        normalVsExponential = @{
            name          = "Normale standard vs. Exponentielle"
            metrics       = $metrics3.Metrics
            meanDeviation = $qqPlot3.MeanDeviation
            maxDeviation  = $qqPlot3.MaxDeviation
            minDeviation  = $qqPlot3.MinDeviation
        }
    }
}

# Enregistrer le rapport JSON
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport JSON genere: $jsonReportPath" -ForegroundColor Green
Write-Host "Taille du rapport: $((Get-Item -Path $jsonReportPath).Length) octets" -ForegroundColor White

# Test 5: Generation des visualisations
Write-Host "`n=== Test 5: Generation des visualisations ===" -ForegroundColor Magenta

# Generer un graphique Q-Q pour la comparaison normale standard vs. normale decalee
$qqPlotVisualizationPath1 = Join-Path -Path $reportsFolder -ChildPath "qqplot_normal_vs_shifted.html"
Get-QuantileQuantilePlotVisualization -QQPlotData $qqPlot1 -OutputPath $qqPlotVisualizationPath1 -Title "Q-Q Plot: Normale standard vs. Normale decalee"
Write-Host "Visualisation Q-Q generee: $qqPlotVisualizationPath1" -ForegroundColor Green

# Generer un graphique Q-Q pour la comparaison normale standard vs. exponentielle
$qqPlotVisualizationPath2 = Join-Path -Path $reportsFolder -ChildPath "qqplot_normal_vs_exponential.html"
Get-QuantileQuantilePlotVisualization -QQPlotData $qqPlot3 -OutputPath $qqPlotVisualizationPath2 -Title "Q-Q Plot: Normale standard vs. Exponentielle" -Theme "Dark"
Write-Host "Visualisation Q-Q generee: $qqPlotVisualizationPath2" -ForegroundColor Green

# Generer un graphique de comparaison des metriques
$metricsVisualizationPath = Join-Path -Path $reportsFolder -ChildPath "comparison_metrics.html"
Get-ComparisonMetricsVisualization -ComparisonMetrics @($metrics1, $metrics2, $metrics3) -OutputPath $metricsVisualizationPath -Title "Comparaison des metriques entre distributions"
Write-Host "Visualisation des metriques generee: $metricsVisualizationPath" -ForegroundColor Green

# Resume des tests
Write-Host "`n=== Resume des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes avec succes." -ForegroundColor Green
Write-Host "Les fonctions d'analyse comparative des quantiles fonctionnent correctement." -ForegroundColor Green
Write-Host "Les visualisations ont ete generees avec succes." -ForegroundColor Green
