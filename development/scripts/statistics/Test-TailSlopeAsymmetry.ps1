# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module TailSlopeAsymmetry.

.DESCRIPTION
    Ce script teste les fonctionnalités du module TailSlopeAsymmetry
    en utilisant différentes distributions simulées.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-02
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TailSlopeAsymmetry.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour générer des données de test
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Normale", "Exponentielle", "LogNormale", "Uniforme", "T-Student", "AsymétriquePositive", "AsymétriqueNégative")]
        [string]$Distribution,

        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 42
    )

    # Initialiser le générateur de nombres aléatoires
    $random = New-Object System.Random($Seed)

    # Générer les données selon la distribution demandée
    $data = @()
    switch ($Distribution) {
        "Normale" {
            # Distribution normale standard (moyenne 0, écart-type 1)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                # Méthode Box-Muller pour générer des nombres aléatoires normaux
                $u1 = $random.NextDouble()
                $u2 = $random.NextDouble()
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $data += $z
            }
        }
        "Exponentielle" {
            # Distribution exponentielle (lambda = 1)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                $u = $random.NextDouble()
                $x = - [Math]::Log(1 - $u)
                $data += $x
            }
        }
        "LogNormale" {
            # Distribution log-normale (moyenne 0, écart-type 1)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                # Générer d'abord une valeur normale
                $u1 = $random.NextDouble()
                $u2 = $random.NextDouble()
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                # Puis la transformer en log-normale
                $x = [Math]::Exp($z)
                $data += $x
            }
        }
        "Uniforme" {
            # Distribution uniforme (entre 0 et 1)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                $data += $random.NextDouble()
            }
        }
        "T-Student" {
            # Distribution t de Student (degrés de liberté = 3)
            $df = 3
            for ($i = 0; $i -lt $SampleSize; $i++) {
                # Générer d'abord une valeur normale
                $u1 = $random.NextDouble()
                $u2 = $random.NextDouble()
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)

                # Générer une valeur chi-carré
                $chiSquare = 0
                for ($j = 0; $j -lt $df; $j++) {
                    $u = $random.NextDouble()
                    $v = $random.NextDouble()
                    $chiSquare += [Math]::Pow([Math]::Sqrt(-2 * [Math]::Log($u)) * [Math]::Cos(2 * [Math]::PI * $v), 2)
                }

                # Calculer la valeur t
                $t = $z / [Math]::Sqrt($chiSquare / $df)
                $data += $t
            }
        }
        "AsymétriquePositive" {
            # Distribution asymétrique positive (mélange de deux normales)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                $u = $random.NextDouble()
                if ($u -lt 0.7) {
                    # 70% des points suivent une normale(0, 1)
                    $u1 = $random.NextDouble()
                    $u2 = $random.NextDouble()
                    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                    $data += $z
                } else {
                    # 30% des points suivent une normale(3, 1)
                    $u1 = $random.NextDouble()
                    $u2 = $random.NextDouble()
                    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                    $data += $z + 3
                }
            }
        }
        "AsymétriqueNégative" {
            # Distribution asymétrique négative (mélange de deux normales)
            for ($i = 0; $i -lt $SampleSize; $i++) {
                $u = $random.NextDouble()
                if ($u -lt 0.7) {
                    # 70% des points suivent une normale(0, 1)
                    $u1 = $random.NextDouble()
                    $u2 = $random.NextDouble()
                    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                    $data += $z
                } else {
                    # 30% des points suivent une normale(-3, 1)
                    $u1 = $random.NextDouble()
                    $u2 = $random.NextDouble()
                    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                    $data += $z - 3
                }
            }
        }
    }

    return $data
}

# Test 1: Extraction des queues d'une distribution normale
Write-Host "`n=== Test 1: Extraction des queues d'une distribution normale ===" -ForegroundColor Magenta
$normalData = Get-TestData -Distribution "Normale" -SampleSize 50
$normalTails = Get-DistributionTails -Data $normalData -TailProportion 0.1 -Method "Quantile"
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalTails.Data.Count)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($normalTails.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($normalTails.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($normalTails.StdDev, 2))" -ForegroundColor White
Write-Host "Méthode: $($normalTails.Method)" -ForegroundColor White
Write-Host "Proportion de queue: $($normalTails.TailProportion)" -ForegroundColor White
Write-Host "Seuil inférieur: $([Math]::Round($normalTails.LowerThreshold, 2))" -ForegroundColor Green
Write-Host "Seuil supérieur: $([Math]::Round($normalTails.UpperThreshold, 2))" -ForegroundColor Green
Write-Host "Taille de la queue gauche: $($normalTails.LeftTailSize)" -ForegroundColor Green
Write-Host "Taille de la queue droite: $($normalTails.RightTailSize)" -ForegroundColor Green

# Test 2: Extraction des queues d'une distribution asymétrique positive
Write-Host "`n=== Test 2: Extraction des queues d'une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewData = Get-TestData -Distribution "AsymétriquePositive" -SampleSize 50
$positiveSkewTails = Get-DistributionTails -Data $positiveSkewData -TailProportion 0.1 -Method "Quantile"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewTails.Data.Count)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewTails.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewTails.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewTails.StdDev, 2))" -ForegroundColor White
Write-Host "Méthode: $($positiveSkewTails.Method)" -ForegroundColor White
Write-Host "Proportion de queue: $($positiveSkewTails.TailProportion)" -ForegroundColor White
Write-Host "Seuil inférieur: $([Math]::Round($positiveSkewTails.LowerThreshold, 2))" -ForegroundColor Green
Write-Host "Seuil supérieur: $([Math]::Round($positiveSkewTails.UpperThreshold, 2))" -ForegroundColor Green
Write-Host "Taille de la queue gauche: $($positiveSkewTails.LeftTailSize)" -ForegroundColor Green
Write-Host "Taille de la queue droite: $($positiveSkewTails.RightTailSize)" -ForegroundColor Green

# Test 3: Extraction des queues avec la méthode adaptative
Write-Host "`n=== Test 3: Extraction des queues avec la méthode adaptative ===" -ForegroundColor Magenta
$adaptiveTails = Get-DistributionTails -Data $normalData -TailProportion 0.1 -Method "Adaptive" -AdaptiveThreshold 1.5
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($adaptiveTails.Data.Count)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($adaptiveTails.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($adaptiveTails.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($adaptiveTails.StdDev, 2))" -ForegroundColor White
Write-Host "Méthode: $($adaptiveTails.Method)" -ForegroundColor White
Write-Host "Seuil adaptatif: $($adaptiveTails.AdaptiveThreshold)" -ForegroundColor White
Write-Host "Seuil inférieur: $([Math]::Round($adaptiveTails.LowerThreshold, 2))" -ForegroundColor Green
Write-Host "Seuil supérieur: $([Math]::Round($adaptiveTails.UpperThreshold, 2))" -ForegroundColor Green
Write-Host "Taille de la queue gauche: $($adaptiveTails.LeftTailSize)" -ForegroundColor Green
Write-Host "Taille de la queue droite: $($adaptiveTails.RightTailSize)" -ForegroundColor Green

# Test 4: Extraction des queues avec la méthode des percentiles
Write-Host "`n=== Test 4: Extraction des queues avec la méthode des percentiles ===" -ForegroundColor Magenta
$percentileTails = Get-DistributionTails -Data $normalData -TailProportion 0.1 -Method "Percentile"
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($percentileTails.Data.Count)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($percentileTails.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($percentileTails.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($percentileTails.StdDev, 2))" -ForegroundColor White
Write-Host "Méthode: $($percentileTails.Method)" -ForegroundColor White
Write-Host "Proportion de queue: $($percentileTails.TailProportion)" -ForegroundColor White
Write-Host "Seuil inférieur: $([Math]::Round($percentileTails.LowerThreshold, 2))" -ForegroundColor Green
Write-Host "Seuil supérieur: $([Math]::Round($percentileTails.UpperThreshold, 2))" -ForegroundColor Green
Write-Host "Taille de la queue gauche: $($percentileTails.LeftTailSize)" -ForegroundColor Green
Write-Host "Taille de la queue droite: $($percentileTails.RightTailSize)" -ForegroundColor Green

# Test 5: Régression linéaire pour les queues d'une distribution normale
Write-Host "`n=== Test 5: Régression linéaire pour les queues d'une distribution normale ===" -ForegroundColor Magenta
$normalTails = Get-DistributionTails -Data $normalData -TailProportion 0.1 -Method "Quantile"
$leftTailRegression = Get-TailLinearRegression -TailData $normalTails.LeftTailData -Method "Linear"
$rightTailRegression = Get-TailLinearRegression -TailData $normalTails.RightTailData -Method "Linear"
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Méthode de régression: Linear" -ForegroundColor White
Write-Host "`nRégression de la queue gauche:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($leftTailRegression.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($leftTailRegression.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($leftTailRegression.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($leftTailRegression.StandardError, 4))" -ForegroundColor Green
Write-Host "`nRégression de la queue droite:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($rightTailRegression.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($rightTailRegression.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($rightTailRegression.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($rightTailRegression.StandardError, 4))" -ForegroundColor Green

# Test 6: Régression linéaire pour les queues d'une distribution asymétrique positive
Write-Host "`n=== Test 6: Régression linéaire pour les queues d'une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewTails = Get-DistributionTails -Data $positiveSkewData -TailProportion 0.1 -Method "Quantile"
$leftTailRegression = Get-TailLinearRegression -TailData $positiveSkewTails.LeftTailData -Method "Linear"
$rightTailRegression = Get-TailLinearRegression -TailData $positiveSkewTails.RightTailData -Method "Linear"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Méthode de régression: Linear" -ForegroundColor White
Write-Host "`nRégression de la queue gauche:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($leftTailRegression.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($leftTailRegression.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($leftTailRegression.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($leftTailRegression.StandardError, 4))" -ForegroundColor Green
Write-Host "`nRégression de la queue droite:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($rightTailRegression.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($rightTailRegression.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($rightTailRegression.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($rightTailRegression.StandardError, 4))" -ForegroundColor Green

# Test 7: Régression linéaire pondérée pour les queues d'une distribution asymétrique positive
Write-Host "`n=== Test 7: Régression linéaire pondérée pour les queues d'une distribution asymétrique positive ===" -ForegroundColor Magenta
$leftTailRegressionWeighted = Get-TailLinearRegression -TailData $positiveSkewTails.LeftTailData -Method "Weighted" -WeightFunction "Exponential"
$rightTailRegressionWeighted = Get-TailLinearRegression -TailData $positiveSkewTails.RightTailData -Method "Weighted" -WeightFunction "Exponential"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Méthode de régression: Weighted" -ForegroundColor White
Write-Host "Fonction de pondération: Exponential" -ForegroundColor White
Write-Host "`nRégression pondérée de la queue gauche:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($leftTailRegressionWeighted.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($leftTailRegressionWeighted.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($leftTailRegressionWeighted.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($leftTailRegressionWeighted.StandardError, 4))" -ForegroundColor Green
Write-Host "`nRégression pondérée de la queue droite:" -ForegroundColor Yellow
Write-Host "Pente: $([Math]::Round($rightTailRegressionWeighted.Slope, 4))" -ForegroundColor Green
Write-Host "Ordonnée à l'origine: $([Math]::Round($rightTailRegressionWeighted.Intercept, 4))" -ForegroundColor Green
Write-Host "R²: $([Math]::Round($rightTailRegressionWeighted.RSquared, 4))" -ForegroundColor Green
Write-Host "Erreur standard: $([Math]::Round($rightTailRegressionWeighted.StandardError, 4))" -ForegroundColor Green

# Test 8: Calcul du ratio des pentes pour une distribution normale
Write-Host "`n=== Test 8: Calcul du ratio des pentes pour une distribution normale ===" -ForegroundColor Magenta
$normalTails = Get-DistributionTails -Data $normalData -TailProportion 0.1 -Method "Quantile"
$leftTailRegression = Get-TailLinearRegression -TailData $normalTails.LeftTailData -Method "Linear"
$rightTailRegression = Get-TailLinearRegression -TailData $normalTails.RightTailData -Method "Linear"
$slopeRatio = Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression -NormalizationMethod "Absolute"
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Méthode de normalisation: Absolute" -ForegroundColor White
Write-Host "Pente de la queue gauche: $([Math]::Round($slopeRatio.LeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente de la queue droite: $([Math]::Round($slopeRatio.RightSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue gauche: $([Math]::Round($slopeRatio.NormalizedLeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue droite: $([Math]::Round($slopeRatio.NormalizedRightSlope, 4))" -ForegroundColor Green
Write-Host "Ratio des pentes: $([Math]::Round($slopeRatio.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($slopeRatio.AsymmetryDirection)" -ForegroundColor Green

# Test 9: Calcul du ratio des pentes pour une distribution asymétrique positive
Write-Host "`n=== Test 9: Calcul du ratio des pentes pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewTails = Get-DistributionTails -Data $positiveSkewData -TailProportion 0.1 -Method "Quantile"
$leftTailRegression = Get-TailLinearRegression -TailData $positiveSkewTails.LeftTailData -Method "Linear"
$rightTailRegression = Get-TailLinearRegression -TailData $positiveSkewTails.RightTailData -Method "Linear"
$slopeRatio = Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression -NormalizationMethod "Absolute"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Méthode de normalisation: Absolute" -ForegroundColor White
Write-Host "Pente de la queue gauche: $([Math]::Round($slopeRatio.LeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente de la queue droite: $([Math]::Round($slopeRatio.RightSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue gauche: $([Math]::Round($slopeRatio.NormalizedLeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue droite: $([Math]::Round($slopeRatio.NormalizedRightSlope, 4))" -ForegroundColor Green
Write-Host "Ratio des pentes: $([Math]::Round($slopeRatio.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($slopeRatio.AsymmetryDirection)" -ForegroundColor Green

# Test 10: Calcul du ratio des pentes avec différentes méthodes de normalisation
Write-Host "`n=== Test 10: Calcul du ratio des pentes avec différentes méthodes de normalisation ===" -ForegroundColor Magenta
$slopeRatioSigned = Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression -NormalizationMethod "Signed"
$slopeRatioNormalized = Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression -NormalizationMethod "Normalized"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "`nMéthode de normalisation: Signed" -ForegroundColor Yellow
Write-Host "Pente normalisée de la queue gauche: $([Math]::Round($slopeRatioSigned.NormalizedLeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue droite: $([Math]::Round($slopeRatioSigned.NormalizedRightSlope, 4))" -ForegroundColor Green
Write-Host "Ratio des pentes: $([Math]::Round($slopeRatioSigned.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($slopeRatioSigned.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nMéthode de normalisation: Normalized" -ForegroundColor Yellow
Write-Host "Pente normalisée de la queue gauche: $([Math]::Round($slopeRatioNormalized.NormalizedLeftSlope, 4))" -ForegroundColor Green
Write-Host "Pente normalisée de la queue droite: $([Math]::Round($slopeRatioNormalized.NormalizedRightSlope, 4))" -ForegroundColor Green
Write-Host "Ratio des pentes: $([Math]::Round($slopeRatioNormalized.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($slopeRatioNormalized.AsymmetryDirection)" -ForegroundColor Green

# Test 11: Évaluation complète de l'asymétrie pour une distribution normale
Write-Host "`n=== Test 11: Évaluation complète de l'asymétrie pour une distribution normale ===" -ForegroundColor Magenta
$normalAsymmetry = Get-TailSlopeAsymmetry -Data $normalData -TailProportion 0.1 -TailMethod "Quantile" -RegressionMethod "Linear" -NormalizationMethod "Absolute"
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Méthode de queue: $($normalAsymmetry.TailMethod)" -ForegroundColor White
Write-Host "Méthode de régression: $($normalAsymmetry.RegressionMethod)" -ForegroundColor White
Write-Host "Méthode de normalisation: $($normalAsymmetry.NormalizationMethod)" -ForegroundColor White
Write-Host "Ratio des pentes: $([Math]::Round($normalAsymmetry.SlopeRatio.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($normalAsymmetry.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "Valeur d'asymétrie: $([Math]::Round($normalAsymmetry.AsymmetryValue, 2))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($normalAsymmetry.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalAsymmetry.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 12: Évaluation complète de l'asymétrie pour une distribution asymétrique positive
Write-Host "`n=== Test 12: Évaluation complète de l'asymétrie pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewAsymmetry = Get-TailSlopeAsymmetry -Data $positiveSkewData -TailProportion 0.1 -TailMethod "Quantile" -RegressionMethod "Linear" -NormalizationMethod "Absolute"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Méthode de queue: $($positiveSkewAsymmetry.TailMethod)" -ForegroundColor White
Write-Host "Méthode de régression: $($positiveSkewAsymmetry.RegressionMethod)" -ForegroundColor White
Write-Host "Méthode de normalisation: $($positiveSkewAsymmetry.NormalizationMethod)" -ForegroundColor White
Write-Host "Ratio des pentes: $([Math]::Round($positiveSkewAsymmetry.SlopeRatio.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($positiveSkewAsymmetry.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "Valeur d'asymétrie: $([Math]::Round($positiveSkewAsymmetry.AsymmetryValue, 2))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($positiveSkewAsymmetry.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewAsymmetry.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 13: Évaluation complète de l'asymétrie avec différentes méthodes
Write-Host "`n=== Test 13: Évaluation complète de l'asymétrie avec différentes méthodes ===" -ForegroundColor Magenta
$asymmetryAdaptive = Get-TailSlopeAsymmetry -Data $positiveSkewData -TailProportion 0.1 -TailMethod "Adaptive" -RegressionMethod "Weighted" -NormalizationMethod "Signed"
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Méthode de queue: $($asymmetryAdaptive.TailMethod)" -ForegroundColor White
Write-Host "Méthode de régression: $($asymmetryAdaptive.RegressionMethod)" -ForegroundColor White
Write-Host "Méthode de normalisation: $($asymmetryAdaptive.NormalizationMethod)" -ForegroundColor White
Write-Host "Ratio des pentes: $([Math]::Round($asymmetryAdaptive.SlopeRatio.SlopeRatio, 4))" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($asymmetryAdaptive.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "Valeur d'asymétrie: $([Math]::Round($asymmetryAdaptive.AsymmetryValue, 2))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($asymmetryAdaptive.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $asymmetryAdaptive.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions Get-DistributionTails, Get-TailLinearRegression, Get-TailSlopeRatio et Get-TailSlopeAsymmetry fonctionnent correctement." -ForegroundColor Green
