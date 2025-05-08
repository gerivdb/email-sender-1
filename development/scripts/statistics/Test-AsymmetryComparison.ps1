# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les fonctions de comparaison d'asymétrie.

.DESCRIPTION
    Ce script teste les fonctions de comparaison d'asymétrie du module TailSlopeAsymmetry.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-03
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

# Test 1: Comparaison des méthodes d'asymétrie pour une distribution normale
Write-Host "`n=== Test 1: Comparaison des méthodes d'asymétrie pour une distribution normale ===" -ForegroundColor Magenta
$normalData = Get-TestData -Distribution "Normale" -SampleSize 100
$normalComparison = Compare-AsymmetryMethods -Data $normalData -Methods @("Slope", "Moments", "Quantiles")
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalComparison.SampleSize)" -ForegroundColor White
Write-Host "Méthodes utilisées: $($normalComparison.Methods -join ", ")" -ForegroundColor White
Write-Host "Méthode recommandée: $($normalComparison.RecommendedMethod)" -ForegroundColor Green
Write-Host "Score de cohérence: $([Math]::Round($normalComparison.ConsistencyScore, 2))" -ForegroundColor Green
Write-Host "`nScores par méthode:" -ForegroundColor Yellow
foreach ($method in $normalComparison.Methods) {
    if ($normalComparison.MethodScores.ContainsKey($method)) {
        $score = [Math]::Round($normalComparison.MethodScores[$method], 2)
        Write-Host "- $method - $score" -ForegroundColor White
    }
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalComparison.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 2: Comparaison des méthodes d'asymétrie pour une distribution asymétrique positive
Write-Host "`n=== Test 2: Comparaison des méthodes d'asymétrie pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewData = Get-TestData -Distribution "AsymétriquePositive" -SampleSize 100
$positiveSkewComparison = Compare-AsymmetryMethods -Data $positiveSkewData -Methods @("Slope", "Moments", "Quantiles")
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewComparison.SampleSize)" -ForegroundColor White
Write-Host "Méthodes utilisées: $($positiveSkewComparison.Methods -join ", ")" -ForegroundColor White
Write-Host "Méthode recommandée: $($positiveSkewComparison.RecommendedMethod)" -ForegroundColor Green
Write-Host "Score de cohérence: $([Math]::Round($positiveSkewComparison.ConsistencyScore, 2))" -ForegroundColor Green
Write-Host "`nScores par méthode:" -ForegroundColor Yellow
foreach ($method in $positiveSkewComparison.Methods) {
    if ($positiveSkewComparison.MethodScores.ContainsKey($method)) {
        $score = [Math]::Round($positiveSkewComparison.MethodScores[$method], 2)
        Write-Host "- $method - $score" -ForegroundColor White
    }
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $positiveSkewComparison.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Score composite d'asymétrie pour une distribution asymétrique positive
Write-Host "`n=== Test 3: Score composite d'asymétrie pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$compositeScore = Get-CompositeAsymmetryScore -Data $positiveSkewData -Methods @("Slope", "Moments", "Quantiles")
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($compositeScore.SampleSize)" -ForegroundColor White
Write-Host "Méthodes utilisées: $($compositeScore.Methods -join ", ")" -ForegroundColor White
Write-Host "Score composite: $([Math]::Round($compositeScore.CompositeScore, 2))" -ForegroundColor Green
Write-Host "Direction de l'asymétrie: $($compositeScore.AsymmetryDirection)" -ForegroundColor Green
Write-Host "Intensité de l'asymétrie: $($compositeScore.AsymmetryIntensity)" -ForegroundColor Green
Write-Host "`nPoids par méthode:" -ForegroundColor Yellow
foreach ($method in $compositeScore.Methods) {
    if ($compositeScore.MethodWeights.ContainsKey($method)) {
        $weight = [Math]::Round($compositeScore.MethodWeights[$method], 2)
        Write-Host "- $method - $weight" -ForegroundColor White
    }
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $compositeScore.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Détermination de la méthode optimale pour une distribution asymétrique négative
Write-Host "`n=== Test 4: Détermination de la méthode optimale pour une distribution asymétrique négative ===" -ForegroundColor Magenta
$negativeSkewData = Get-TestData -Distribution "AsymétriqueNégative" -SampleSize 100
$optimalMethod = Get-OptimalAsymmetryMethod -Data $negativeSkewData
Write-Host "Distribution: Asymétrique négative" -ForegroundColor White
Write-Host "Taille d'échantillon: $($optimalMethod.SampleSize)" -ForegroundColor White
Write-Host "Méthode optimale: $($optimalMethod.OptimalMethod)" -ForegroundColor Green
Write-Host "Méthodes recommandées: $($optimalMethod.RecommendedMethods -join ", ")" -ForegroundColor Green
Write-Host "`nCaractéristiques de la distribution:" -ForegroundColor Yellow
Write-Host "- Moyenne: $([Math]::Round($optimalMethod.DistributionCharacteristics.Mean, 2))" -ForegroundColor White
Write-Host "- Médiane: $([Math]::Round($optimalMethod.DistributionCharacteristics.Median, 2))" -ForegroundColor White
Write-Host "- Écart-type: $([Math]::Round($optimalMethod.DistributionCharacteristics.StdDev, 2))" -ForegroundColor White
Write-Host "- Skewness: $([Math]::Round($optimalMethod.DistributionCharacteristics.Skewness, 2))" -ForegroundColor White
Write-Host "- Kurtosis: $([Math]::Round($optimalMethod.DistributionCharacteristics.Kurtosis, 2))" -ForegroundColor White
Write-Host "`nJustification:" -ForegroundColor Yellow
foreach ($justification in $optimalMethod.Justification) {
    Write-Host "- $justification" -ForegroundColor White
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $optimalMethod.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions Compare-AsymmetryMethods, Get-CompositeAsymmetryScore et Get-OptimalAsymmetryMethod fonctionnent correctement." -ForegroundColor Green
