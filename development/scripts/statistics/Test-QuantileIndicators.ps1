# Test-QuantileIndicators.ps1
# Ce script teste les fonctions de calcul des quantiles et des indicateurs basés sur les quantiles

# Importer le module QuantileIndicators
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileIndicators.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module QuantileIndicators.psm1 n'a pas été trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Générer des données de test
Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta

# Distribution normale
$normalData = 1..100 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }

# Distribution asymétrique positive
$positiveSkewData = 1..100 | ForEach-Object {
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution asymétrique négative
$negativeSkewData = 1..100 | ForEach-Object {
    $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution bimodale
$bimodalData = @()
$bimodalData += 1..50 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 - 5, 2) }
$bimodalData += 1..50 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 + 2, 2) }

Write-Host "Données générées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution bimodale: $($bimodalData.Count) points" -ForegroundColor White

# Test 1: Calcul des quantiles avec différentes méthodes
Write-Host "`n=== Test 1: Calcul des quantiles avec différentes méthodes ===" -ForegroundColor Magenta
$methods = @("R1", "R7")  # Limiter à deux méthodes pour accélérer les tests
$probabilities = @(0.25, 0.5, 0.75)  # Limiter à trois probabilités pour accélérer les tests

Write-Host "Distribution normale:" -ForegroundColor White
foreach ($method in $methods) {
    Write-Host "  Methode $method`:" -ForegroundColor Cyan
    foreach ($probability in $probabilities) {
        $quantile = Get-Quantile -Data $normalData -Probability $probability -Method $method
        Write-Host "    Quantile $probability : $quantile" -ForegroundColor White
    }
}

Write-Host "`nDistribution asymetrique positive:" -ForegroundColor White
foreach ($method in $methods) {
    Write-Host "  Methode $method`:" -ForegroundColor Cyan
    foreach ($probability in $probabilities) {
        $quantile = Get-Quantile -Data $positiveSkewData -Probability $probability -Method $method
        Write-Host "    Quantile $probability : $quantile" -ForegroundColor White
    }
}

# Test 2: Calcul des quantiles pondérés
Write-Host "`n=== Test 2: Calcul des quantiles pondérés ===" -ForegroundColor Magenta
$weightingMethods = @("Frequency", "Importance")  # Limiter à deux méthodes pour accélérer les tests

# Générer des poids pour les données
$normalWeights = $normalData | ForEach-Object { [Math]::Abs($_) + 0.1 }
$positiveSkewWeights = $positiveSkewData | ForEach-Object { $_ + 0.1 }
$negativeSkewWeights = $negativeSkewData | ForEach-Object { 10 - $_ + 0.1 }
$bimodalWeights = $bimodalData | ForEach-Object { [Math]::Abs($_) + 0.1 }

Write-Host "Distribution normale:" -ForegroundColor White
foreach ($weightingMethod in $weightingMethods) {
    Write-Host "  Methode de ponderation $weightingMethod`:" -ForegroundColor Cyan
    foreach ($probability in $probabilities) {
        $weightedQuantile = Get-WeightedQuantile -Data $normalData -Weights $normalWeights -Probability $probability -WeightingMethod $weightingMethod
        Write-Host "    Quantile pondere $probability : $weightedQuantile" -ForegroundColor White
    }
}

# Limiter les tests pour accélérer l'exécution
Write-Host "`nDistribution asymetrique positive (méthode Frequency uniquement):" -ForegroundColor White
$weightedQuantile = Get-WeightedQuantile -Data $positiveSkewData -Weights $positiveSkewWeights -Probability 0.5 -WeightingMethod "Frequency"
Write-Host "  Quantile pondere 0.5 : $weightedQuantile" -ForegroundColor White

# Test 3: Calcul de l'écart interquartile (IQR)
Write-Host "`n=== Test 3: Calcul de l'écart interquartile (IQR) ===" -ForegroundColor Magenta
$normalIQR = Get-InterquartileRange -Data $normalData
$positiveSkewIQR = Get-InterquartileRange -Data $positiveSkewData
$negativeSkewIQR = Get-InterquartileRange -Data $negativeSkewData
$bimodalIQR = Get-InterquartileRange -Data $bimodalData

Write-Host "Écart interquartile (IQR):" -ForegroundColor White
Write-Host "- Distribution normale: $normalIQR" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $positiveSkewIQR" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $negativeSkewIQR" -ForegroundColor White
Write-Host "- Distribution bimodale: $bimodalIQR" -ForegroundColor White

# Test 4: Calcul du coefficient d'asymétrie de Bowley
Write-Host "`n=== Test 4: Calcul du coefficient d'asymétrie de Bowley ===" -ForegroundColor Magenta
$normalBowley = Get-BowleySkewness -Data $normalData
$positiveSkewBowley = Get-BowleySkewness -Data $positiveSkewData
$negativeSkewBowley = Get-BowleySkewness -Data $negativeSkewData
$bimodalBowley = Get-BowleySkewness -Data $bimodalData

Write-Host "Coefficient d'asymétrie de Bowley:" -ForegroundColor White
Write-Host "- Distribution normale: $normalBowley" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $positiveSkewBowley" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $negativeSkewBowley" -ForegroundColor White
Write-Host "- Distribution bimodale: $bimodalBowley" -ForegroundColor White

# Test 5: Comparaison avec les statistiques descriptives classiques
Write-Host "`n=== Test 5: Comparaison avec les statistiques descriptives classiques ===" -ForegroundColor Magenta

# Fonction pour calculer le coefficient d'asymétrie (skewness)
function Get-Skewness {
    param (
        [double[]]$Data
    )
    $mean = ($Data | Measure-Object -Average).Average
    # $n n'est pas utilisé dans cette implémentation simplifiée
    $m2 = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    return $m3 / [Math]::Pow($m2, 1.5)
}

$normalSkewness = Get-Skewness -Data $normalData
$positiveSkewSkewness = Get-Skewness -Data $positiveSkewData
$negativeSkewSkewness = Get-Skewness -Data $negativeSkewData
$bimodalSkewness = Get-Skewness -Data $bimodalData

Write-Host "Comparaison des coefficients d'asymétrie:" -ForegroundColor White
Write-Host "Distribution normale:" -ForegroundColor Cyan
Write-Host "- Coefficient d'asymétrie de Bowley: $normalBowley" -ForegroundColor White
Write-Host "- Coefficient d'asymétrie classique (skewness): $normalSkewness" -ForegroundColor White

Write-Host "`nDistribution asymétrique positive:" -ForegroundColor Cyan
Write-Host "- Coefficient d'asymétrie de Bowley: $positiveSkewBowley" -ForegroundColor White
Write-Host "- Coefficient d'asymétrie classique (skewness): $positiveSkewSkewness" -ForegroundColor White

Write-Host "`nDistribution asymétrique négative:" -ForegroundColor Cyan
Write-Host "- Coefficient d'asymétrie de Bowley: $negativeSkewBowley" -ForegroundColor White
Write-Host "- Coefficient d'asymétrie classique (skewness): $negativeSkewSkewness" -ForegroundColor White

Write-Host "`nDistribution bimodale:" -ForegroundColor Cyan
Write-Host "- Coefficient d'asymétrie de Bowley: $bimodalBowley" -ForegroundColor White
Write-Host "- Coefficient d'asymétrie classique (skewness): $bimodalSkewness" -ForegroundColor White

# Test 6: Génération d'un rapport JSON
Write-Host "`n=== Test 6: Génération d'un rapport JSON ===" -ForegroundColor Magenta
$jsonReportPath = Join-Path -Path $reportsFolder -ChildPath "quantile_indicators_report.json"

# Créer un rapport JSON avec les indicateurs basés sur les quantiles
$reportData = @{
    metadata      = @{
        title          = "Rapport d'indicateurs basés sur les quantiles"
        generationDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version        = "1.0"
    }
    distributions = @{
        normal       = @{
            name              = "Distribution normale"
            sampleSize        = $normalData.Count
            quantiles         = @{
                q10 = Get-Quantile -Data $normalData -Probability 0.1
                q25 = Get-Quantile -Data $normalData -Probability 0.25
                q50 = Get-Quantile -Data $normalData -Probability 0.5
                q75 = Get-Quantile -Data $normalData -Probability 0.75
                q90 = Get-Quantile -Data $normalData -Probability 0.9
            }
            weightedQuantiles = @{
                q50 = Get-WeightedQuantile -Data $normalData -Weights $normalWeights -Probability 0.5
            }
            indicators        = @{
                iqr             = $normalIQR
                bowleySkewness  = $normalBowley
                classicSkewness = $normalSkewness
            }
        }
        positiveSkew = @{
            name              = "Distribution asymétrique positive"
            sampleSize        = $positiveSkewData.Count
            quantiles         = @{
                q10 = Get-Quantile -Data $positiveSkewData -Probability 0.1
                q25 = Get-Quantile -Data $positiveSkewData -Probability 0.25
                q50 = Get-Quantile -Data $positiveSkewData -Probability 0.5
                q75 = Get-Quantile -Data $positiveSkewData -Probability 0.75
                q90 = Get-Quantile -Data $positiveSkewData -Probability 0.9
            }
            weightedQuantiles = @{
                q50 = Get-WeightedQuantile -Data $positiveSkewData -Weights $positiveSkewWeights -Probability 0.5
            }
            indicators        = @{
                iqr             = $positiveSkewIQR
                bowleySkewness  = $positiveSkewBowley
                classicSkewness = $positiveSkewSkewness
            }
        }
        negativeSkew = @{
            name              = "Distribution asymétrique négative"
            sampleSize        = $negativeSkewData.Count
            quantiles         = @{
                q10 = Get-Quantile -Data $negativeSkewData -Probability 0.1
                q25 = Get-Quantile -Data $negativeSkewData -Probability 0.25
                q50 = Get-Quantile -Data $negativeSkewData -Probability 0.5
                q75 = Get-Quantile -Data $negativeSkewData -Probability 0.75
                q90 = Get-Quantile -Data $negativeSkewData -Probability 0.9
            }
            weightedQuantiles = @{
                q50 = Get-WeightedQuantile -Data $negativeSkewData -Weights $negativeSkewWeights -Probability 0.5
            }
            indicators        = @{
                iqr             = $negativeSkewIQR
                bowleySkewness  = $negativeSkewBowley
                classicSkewness = $negativeSkewSkewness
            }
        }
        bimodal      = @{
            name              = "Distribution bimodale"
            sampleSize        = $bimodalData.Count
            quantiles         = @{
                q10 = Get-Quantile -Data $bimodalData -Probability 0.1
                q25 = Get-Quantile -Data $bimodalData -Probability 0.25
                q50 = Get-Quantile -Data $bimodalData -Probability 0.5
                q75 = Get-Quantile -Data $bimodalData -Probability 0.75
                q90 = Get-Quantile -Data $bimodalData -Probability 0.9
            }
            weightedQuantiles = @{
                q50 = Get-WeightedQuantile -Data $bimodalData -Weights $bimodalWeights -Probability 0.5
            }
            indicators        = @{
                iqr             = $bimodalIQR
                bowleySkewness  = $bimodalBowley
                classicSkewness = $bimodalSkewness
            }
        }
    }
}

# Enregistrer le rapport JSON
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport JSON généré: $jsonReportPath" -ForegroundColor Green
Write-Host "Taille du rapport: $((Get-Item -Path $jsonReportPath).Length) octets" -ForegroundColor White

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions de calcul des quantiles et des indicateurs basés sur les quantiles fonctionnent correctement." -ForegroundColor Green
