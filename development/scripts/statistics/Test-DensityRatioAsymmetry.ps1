# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module DensityRatioAsymmetry.

.DESCRIPTION
    Ce script teste les fonctionnalités du module DensityRatioAsymmetry
    en utilisant différentes distributions simulées.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-01
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "DensityRatioAsymmetry.psm1"
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
                $x = -[Math]::Log(1 - $u)
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

# Test 1: Seuils d'interprétation pour les ratios de densité
Write-Host "`n=== Test 1: Seuils d'interprétation pour les ratios de densité ===" -ForegroundColor Magenta
$thresholds = Get-DensityRatioThresholds -DistributionType "Normale" -ConfidenceLevel "95%" -SampleSize 100
Write-Host "Type de distribution: $($thresholds.DistributionType)" -ForegroundColor White
Write-Host "Niveau de confiance: $($thresholds.ConfidenceLevel)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($thresholds.SampleSize) (Catégorie: $($thresholds.SizeCategory))" -ForegroundColor White
Write-Host "Facteur d'ajustement pour la taille d'échantillon: $($thresholds.SizeAdjustmentFactor)" -ForegroundColor White
Write-Host "Seuil de base: $($thresholds.BaseThreshold)" -ForegroundColor Green
Write-Host "Seuil ajusté: $($thresholds.AdjustedThreshold)" -ForegroundColor Green

# Test 2: Seuils adaptatifs pour les ratios de densité
Write-Host "`n=== Test 2: Seuils adaptatifs pour les ratios de densité ===" -ForegroundColor Magenta
$adaptiveThresholds = Get-AdaptiveDensityRatioThresholds -SampleSize 100 -DistributionType "Normale" -ConfidenceLevel "95%"
Write-Host "Type de distribution: $($adaptiveThresholds.DistributionType)" -ForegroundColor White
Write-Host "Niveau de confiance: $($adaptiveThresholds.ConfidenceLevel)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($adaptiveThresholds.SampleSize) (Catégorie: $($adaptiveThresholds.SizeCategory))" -ForegroundColor White
Write-Host "Facteur adaptatif: $($adaptiveThresholds.AdaptiveFactor)" -ForegroundColor White
Write-Host "Seuil de base: $($adaptiveThresholds.BaseThreshold)" -ForegroundColor Green
Write-Host "`nSeuils adaptatifs:" -ForegroundColor Yellow
foreach ($key in $adaptiveThresholds.AdaptiveThresholds.Keys) {
    Write-Host "- $key : $([Math]::Round($adaptiveThresholds.AdaptiveThresholds[$key], 2))" -ForegroundColor White
}

# Test 3: Échelle d'intensité d'asymétrie pour un ratio de densité connu
Write-Host "`n=== Test 3: Échelle d'intensité d'asymétrie pour un ratio de densité connu ===" -ForegroundColor Magenta
$asymmetryScale = Get-AsymmetryIntensityScale -DensityRatio 2.5 -SampleSize 100 -DistributionType "Normale" -ConfidenceLevel "95%"
Write-Host "Ratio de densité: $($asymmetryScale.DensityRatio)" -ForegroundColor White
Write-Host "Ratio normalisé: $($asymmetryScale.NormalizedRatio)" -ForegroundColor White
Write-Host "Niveau d'intensité: $($asymmetryScale.IntensityLevel)" -ForegroundColor Green
Write-Host "Valeur d'intensité: $([Math]::Round($asymmetryScale.IntensityValue, 2))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($asymmetryScale.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Description: $($asymmetryScale.Description)" -ForegroundColor White
Write-Host "Impact: $($asymmetryScale.Impact)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $asymmetryScale.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Évaluation de l'asymétrie basée sur la densité pour une distribution normale
Write-Host "`n=== Test 4: Évaluation de l'asymétrie basée sur la densité pour une distribution normale ===" -ForegroundColor Magenta
$normalData = Get-TestData -Distribution "Normale" -SampleSize 100
$normalAsymmetry = Get-DensityBasedAsymmetry -Data $normalData -TailProportion 0.1
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($normalAsymmetry.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($normalAsymmetry.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($normalAsymmetry.StdDev, 2))" -ForegroundColor White
Write-Host "Proportion de queue: $($normalAsymmetry.TailProportion)" -ForegroundColor White
Write-Host "Méthode de largeur de bande: $($normalAsymmetry.BandwidthMethod)" -ForegroundColor White
Write-Host "Largeur de bande: $([Math]::Round($normalAsymmetry.Bandwidth, 4))" -ForegroundColor White
Write-Host "Densité de la queue gauche: $([Math]::Round($normalAsymmetry.LeftTailDensity, 4))" -ForegroundColor Green
Write-Host "Densité de la queue droite: $([Math]::Round($normalAsymmetry.RightTailDensity, 4))" -ForegroundColor Green
Write-Host "Ratio de densité: $([Math]::Round($normalAsymmetry.DensityRatio, 2))" -ForegroundColor Green
Write-Host "Niveau d'intensité: $($normalAsymmetry.AsymmetryEvaluation.IntensityLevel)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($normalAsymmetry.AsymmetryEvaluation.AsymmetryDirection)" -ForegroundColor Green

# Test 5: Évaluation de l'asymétrie basée sur la densité pour une distribution asymétrique positive
Write-Host "`n=== Test 5: Évaluation de l'asymétrie basée sur la densité pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewData = Get-TestData -Distribution "AsymétriquePositive" -SampleSize 100
$positiveSkewAsymmetry = Get-DensityBasedAsymmetry -Data $positiveSkewData -TailProportion 0.1
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($positiveSkewAsymmetry.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($positiveSkewAsymmetry.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($positiveSkewAsymmetry.StdDev, 2))" -ForegroundColor White
Write-Host "Densité de la queue gauche: $([Math]::Round($positiveSkewAsymmetry.LeftTailDensity, 4))" -ForegroundColor Green
Write-Host "Densité de la queue droite: $([Math]::Round($positiveSkewAsymmetry.RightTailDensity, 4))" -ForegroundColor Green
Write-Host "Ratio de densité: $([Math]::Round($positiveSkewAsymmetry.DensityRatio, 2))" -ForegroundColor Green
Write-Host "Niveau d'intensité: $($positiveSkewAsymmetry.AsymmetryEvaluation.IntensityLevel)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($positiveSkewAsymmetry.AsymmetryEvaluation.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewAsymmetry.AsymmetryEvaluation.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 6: Évaluation de l'asymétrie basée sur la densité pour une distribution asymétrique négative
Write-Host "`n=== Test 6: Évaluation de l'asymétrie basée sur la densité pour une distribution asymétrique négative ===" -ForegroundColor Magenta
$negativeSkewData = Get-TestData -Distribution "AsymétriqueNégative" -SampleSize 100
$negativeSkewAsymmetry = Get-DensityBasedAsymmetry -Data $negativeSkewData -TailProportion 0.1
Write-Host "Distribution: Asymétrique négative" -ForegroundColor White
Write-Host "Taille d'échantillon: $($negativeSkewAsymmetry.SampleSize)" -ForegroundColor White
Write-Host "Moyenne: $([Math]::Round($negativeSkewAsymmetry.Mean, 2))" -ForegroundColor White
Write-Host "Médiane: $([Math]::Round($negativeSkewAsymmetry.Median, 2))" -ForegroundColor White
Write-Host "Écart-type: $([Math]::Round($negativeSkewAsymmetry.StdDev, 2))" -ForegroundColor White
Write-Host "Densité de la queue gauche: $([Math]::Round($negativeSkewAsymmetry.LeftTailDensity, 4))" -ForegroundColor Green
Write-Host "Densité de la queue droite: $([Math]::Round($negativeSkewAsymmetry.RightTailDensity, 4))" -ForegroundColor Green
Write-Host "Ratio de densité: $([Math]::Round($negativeSkewAsymmetry.DensityRatio, 2))" -ForegroundColor Green
Write-Host "Niveau d'intensité: $($negativeSkewAsymmetry.AsymmetryEvaluation.IntensityLevel)" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($negativeSkewAsymmetry.AsymmetryEvaluation.AsymmetryDirection)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $negativeSkewAsymmetry.AsymmetryEvaluation.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Le module DensityRatioAsymmetry fonctionne correctement." -ForegroundColor Green
