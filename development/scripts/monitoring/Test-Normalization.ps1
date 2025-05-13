#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour la fonction de normalisation du module TrendAnalyzer.
.DESCRIPTION
    Ce script teste la fonction de normalisation des données du module TrendAnalyzer
    en utilisant des données de test simples.
.NOTES
    Nom: Test-Normalization.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TrendAnalyzer.psm1"
Import-Module $modulePath -Force

# Créer des données de test directement en mémoire
$testData = @{
    CollectorName = "TestNormCollector"
    StartTime = (Get-Date).AddHours(-1)
    EndTime = Get-Date
    SamplingInterval = 60
    MetricsData = @{
        CPU_Usage = @{
            Values = @(20, 40, 60, 80, 100)
            Timestamps = @(
                (Get-Date).AddMinutes(-50),
                (Get-Date).AddMinutes(-40),
                (Get-Date).AddMinutes(-30),
                (Get-Date).AddMinutes(-20),
                (Get-Date).AddMinutes(-10)
            )
            Unit = "%"
        }
        Memory_Usage = @{
            Values = @(4, 8, 12, 16, 20)
            Timestamps = @(
                (Get-Date).AddMinutes(-50),
                (Get-Date).AddMinutes(-40),
                (Get-Date).AddMinutes(-30),
                (Get-Date).AddMinutes(-20),
                (Get-Date).AddMinutes(-10)
            )
            Unit = "GB"
        }
    }
}

Write-Host "Test de normalisation des données de métriques" -ForegroundColor Cyan

# Tester la normalisation MinMax
Write-Host "`nTest de la méthode MinMax:" -ForegroundColor Yellow
$normalizedMinMax = ConvertTo-NormalizedMetrics -MetricsData $testData -Method "MinMax"

if ($null -eq $normalizedMinMax) {
    Write-Host "Échec: Aucun résultat de normalisation MinMax retourné." -ForegroundColor Red
    exit 1
}

# Tester la normalisation ZScore
Write-Host "`nTest de la méthode ZScore:" -ForegroundColor Yellow
$normalizedZScore = ConvertTo-NormalizedMetrics -MetricsData $testData -Method "ZScore"

if ($null -eq $normalizedZScore) {
    Write-Host "Échec: Aucun résultat de normalisation ZScore retourné." -ForegroundColor Red
    exit 1
}

# Tester la normalisation Robust
Write-Host "`nTest de la méthode Robust:" -ForegroundColor Yellow
$normalizedRobust = ConvertTo-NormalizedMetrics -MetricsData $testData -Method "Robust"

if ($null -eq $normalizedRobust) {
    Write-Host "Échec: Aucun résultat de normalisation Robust retourné." -ForegroundColor Red
    exit 1
}

# Vérifier que les valeurs normalisées sont dans les plages attendues
$minMaxValues = $normalizedMinMax.MetricsData.CPU_Usage.Values
$zScoreValues = $normalizedZScore.MetricsData.CPU_Usage.Values
$robustValues = $normalizedRobust.MetricsData.CPU_Usage.Values

# Pour MinMax, les valeurs doivent être entre 0 et 1
$minMaxInRange = ($minMaxValues | Where-Object { $_ -ge 0 -and $_ -le 1 }).Count -eq $minMaxValues.Count

# Pour ZScore, la moyenne doit être proche de 0
$zScoreMean = ($zScoreValues | Measure-Object -Average).Average
$zScoreMeanNearZero = [Math]::Abs($zScoreMean) -lt 0.001

Write-Host "`nRésultats de normalisation:" -ForegroundColor Cyan
Write-Host "  Méthode MinMax: Plage [$([Math]::Round(($minMaxValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($minMaxValues | Measure-Object -Maximum).Maximum, 3))]"
Write-Host "  Méthode ZScore: Plage [$([Math]::Round(($zScoreValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($zScoreValues | Measure-Object -Maximum).Maximum, 3))]"
Write-Host "  Méthode Robust: Plage [$([Math]::Round(($robustValues | Measure-Object -Minimum).Minimum, 3)) - $([Math]::Round(($robustValues | Measure-Object -Maximum).Maximum, 3))]"
Write-Host "  Moyenne ZScore: $([Math]::Round($zScoreMean, 6))"

# Vérifier que les statistiques originales sont correctement stockées
$cpuStats = $normalizedMinMax.OriginalStats.CPU_Usage

Write-Host "`nStatistiques originales CPU:" -ForegroundColor Cyan
Write-Host "  Min: $([Math]::Round($cpuStats.Min, 1))%"
Write-Host "  Max: $([Math]::Round($cpuStats.Max, 1))%"
Write-Host "  Moyenne: $([Math]::Round($cpuStats.Mean, 1))%"

# Résumé des tests
if ($minMaxInRange -and $zScoreMeanNearZero) {
    Write-Host "`nTous les tests de normalisation ont réussi!" -ForegroundColor Green
    exit 0
}
else {
    if (-not $minMaxInRange) {
        Write-Host "`nÉchec: Les valeurs normalisées MinMax ne sont pas dans la plage [0,1]." -ForegroundColor Red
    }
    if (-not $zScoreMeanNearZero) {
        Write-Host "`nÉchec: La moyenne des valeurs normalisées ZScore n'est pas proche de 0." -ForegroundColor Red
    }
    exit 1
}
