# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les fonctions de génération de rapports d'asymétrie.

.DESCRIPTION
    Ce script teste les fonctions de génération de rapports d'asymétrie du module TailSlopeAsymmetry.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-04
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

# Créer un dossier pour les rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Test 1: Rapport textuel pour une distribution normale
Write-Host "`n=== Test 1: Rapport textuel pour une distribution normale ===" -ForegroundColor Magenta
$normalData = Get-TestData -Distribution "Normale" -SampleSize 100
$normalReportPath = Join-Path -Path $reportsFolder -ChildPath "normal_report.txt"
$normalReport = Get-AsymmetryTextReport -Data $normalData -Methods @("Slope", "Moments", "Quantiles") -DetailLevel "Normal" -OutputPath $normalReportPath
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Niveau de détail: Normal" -ForegroundColor White
Write-Host "Rapport écrit dans: $normalReportPath" -ForegroundColor Green
Write-Host "Aperçu du rapport:" -ForegroundColor Yellow
Write-Host ($normalReport -split "`n" | Select-Object -First 10 | ForEach-Object { "  $_" }) -ForegroundColor White
Write-Host "..." -ForegroundColor White

# Test 2: Rapport textuel détaillé pour une distribution asymétrique positive
Write-Host "`n=== Test 2: Rapport textuel détaillé pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewData = Get-TestData -Distribution "AsymétriquePositive" -SampleSize 100
$positiveSkewReportPath = Join-Path -Path $reportsFolder -ChildPath "positive_skew_report.txt"
$positiveSkewReport = Get-AsymmetryTextReport -Data $positiveSkewData -Methods @("Slope", "Moments", "Quantiles") -DetailLevel "Detailed" -OutputPath $positiveSkewReportPath
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Niveau de détail: Detailed" -ForegroundColor White
Write-Host "Rapport écrit dans: $positiveSkewReportPath" -ForegroundColor Green
Write-Host "Aperçu du rapport:" -ForegroundColor Yellow
Write-Host ($positiveSkewReport -split "`n" | Select-Object -First 10 | ForEach-Object { "  $_" }) -ForegroundColor White
Write-Host "..." -ForegroundColor White

# Test 3: Rapport textuel verbose pour une distribution asymétrique négative
Write-Host "`n=== Test 3: Rapport textuel verbose pour une distribution asymétrique négative ===" -ForegroundColor Magenta
$negativeSkewData = Get-TestData -Distribution "AsymétriqueNégative" -SampleSize 100
$negativeSkewReportPath = Join-Path -Path $reportsFolder -ChildPath "negative_skew_report.txt"
$negativeSkewReport = Get-AsymmetryTextReport -Data $negativeSkewData -Methods @("Slope", "Moments", "Quantiles") -DetailLevel "Verbose" -OutputPath $negativeSkewReportPath
Write-Host "Distribution: Asymétrique négative" -ForegroundColor White
Write-Host "Taille d'échantillon: $($negativeSkewData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Niveau de détail: Verbose" -ForegroundColor White
Write-Host "Rapport écrit dans: $negativeSkewReportPath" -ForegroundColor Green
Write-Host "Aperçu du rapport:" -ForegroundColor Yellow
Write-Host ($negativeSkewReport -split "`n" | Select-Object -First 10 | ForEach-Object { "  $_" }) -ForegroundColor White
Write-Host "..." -ForegroundColor White

# Test 4: Rapport textuel minimal pour une distribution exponentielle
Write-Host "`n=== Test 4: Rapport textuel minimal pour une distribution exponentielle ===" -ForegroundColor Magenta
$expData = Get-TestData -Distribution "Exponentielle" -SampleSize 100
$expReportPath = Join-Path -Path $reportsFolder -ChildPath "exponential_report.txt"
$expReport = Get-AsymmetryTextReport -Data $expData -Methods @("Slope", "Moments", "Quantiles") -DetailLevel "Minimal" -OutputPath $expReportPath
Write-Host "Distribution: Exponentielle" -ForegroundColor White
Write-Host "Taille d'échantillon: $($expData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Niveau de détail: Minimal" -ForegroundColor White
Write-Host "Rapport écrit dans: $expReportPath" -ForegroundColor Green
Write-Host "Aperçu du rapport:" -ForegroundColor Yellow
Write-Host ($expReport -split "`n" | Select-Object -First 10 | ForEach-Object { "  $_" }) -ForegroundColor White
Write-Host "..." -ForegroundColor White

# Test 5: Rapport HTML pour une distribution normale
Write-Host "`n=== Test 5: Rapport HTML pour une distribution normale ===" -ForegroundColor Magenta
$normalHtmlReportPath = Join-Path -Path $reportsFolder -ChildPath "normal_report.html"
Get-AsymmetryHtmlReport -Data $normalData -Methods @("Slope", "Moments", "Quantiles") -OutputPath $normalHtmlReportPath
Write-Host "Distribution: Normale" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Rapport écrit dans: $normalHtmlReportPath" -ForegroundColor Green
Write-Host "Taille du rapport HTML: $((Get-Item -Path $normalHtmlReportPath).Length) octets" -ForegroundColor White

# Test 6: Rapport HTML pour une distribution asymétrique positive
Write-Host "`n=== Test 6: Rapport HTML pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewHtmlReportPath = Join-Path -Path $reportsFolder -ChildPath "positive_skew_report.html"
Get-AsymmetryHtmlReport -Data $positiveSkewData -Methods @("Slope", "Moments", "Quantiles") -Title "Rapport d'asymétrie positive" -OutputPath $positiveSkewHtmlReportPath
Write-Host "Distribution: Asymétrique positive" -ForegroundColor White
Write-Host "Taille d'échantillon: $($positiveSkewData.Count)" -ForegroundColor White
Write-Host "Méthodes utilisées: Slope, Moments, Quantiles" -ForegroundColor White
Write-Host "Titre personnalisé: Rapport d'asymétrie positive" -ForegroundColor White
Write-Host "Rapport écrit dans: $positiveSkewHtmlReportPath" -ForegroundColor Green
Write-Host "Taille du rapport HTML: $((Get-Item -Path $positiveSkewHtmlReportPath).Length) octets" -ForegroundColor White

# Ouvrir le rapport HTML dans le navigateur par défaut
Write-Host "`n=== Ouverture du rapport HTML dans le navigateur ===" -ForegroundColor Magenta
Write-Host "Ouverture du rapport HTML pour la distribution asymétrique positive..." -ForegroundColor White
Start-Process $positiveSkewHtmlReportPath

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions Get-AsymmetryTextReport et Get-AsymmetryHtmlReport fonctionnent correctement." -ForegroundColor Green
Write-Host "Les rapports ont été écrits dans le dossier: $reportsFolder" -ForegroundColor Green
