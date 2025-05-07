#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module CorrelationQualityMetrics.

.DESCRIPTION
    Ce script teste les fonctionnalités du module CorrelationQualityMetrics,
    notamment les critères de précision pour l'estimation de la corrélation de Pearson.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "CorrelationQualityMetrics.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les résultats de manière formatée
function Format-PrecisionCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Critères de précision pour la corrélation de Pearson ===" -ForegroundColor Cyan
    Write-Host "Coefficient de corrélation: $($Results.CorrelationCoefficient)" -ForegroundColor White
    Write-Host "Taille de l'échantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Niveau de confiance: $($Results.ConfidenceLevel * 100)%" -ForegroundColor White
    Write-Host ""

    Write-Host "Intervalle de confiance:" -ForegroundColor Yellow
    Write-Host "  Borne inférieure: $([Math]::Round($Results.ConfidenceInterval.LowerBound, 4))" -ForegroundColor White
    Write-Host "  Borne supérieure: $([Math]::Round($Results.ConfidenceInterval.UpperBound, 4))" -ForegroundColor White
    Write-Host "  Largeur: $([Math]::Round($Results.ConfidenceInterval.Width, 4))" -ForegroundColor White
    Write-Host ""

    Write-Host "Erreur standard: $([Math]::Round($Results.StandardError, 4))" -ForegroundColor Yellow
    Write-Host "Niveau de précision: $($Results.PrecisionLevel)" -ForegroundColor Yellow
    Write-Host "Adéquation de la taille d'échantillon: $($Results.SampleSizeAdequacy)" -ForegroundColor Yellow
    Write-Host "Puissance statistique: $($Results.StatisticalPower)" -ForegroundColor Yellow
    Write-Host ""

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particulière." -ForegroundColor Green
    }

    Write-Host "Taille d'échantillon minimale recommandée: $($Results.MinimumSampleSizeRecommended)" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 1: Corrélation forte avec petit échantillon
Write-Host "Test 1: Corrélation forte avec petit échantillon" -ForegroundColor Magenta
$results1 = Get-PearsonCorrelationPrecisionCriteria -SampleSize 15 -CorrelationCoefficient 0.8 -ConfidenceLevel 0.95
Format-PrecisionCriteriaResults -Results $results1

# Test 2: Corrélation moyenne avec échantillon moyen
Write-Host "`nTest 2: Corrélation moyenne avec échantillon moyen" -ForegroundColor Magenta
$results2 = Get-PearsonCorrelationPrecisionCriteria -SampleSize 50 -CorrelationCoefficient 0.5 -ConfidenceLevel 0.95
Format-PrecisionCriteriaResults -Results $results2

# Test 3: Corrélation faible avec grand échantillon
Write-Host "`nTest 3: Corrélation faible avec grand échantillon" -ForegroundColor Magenta
$results3 = Get-PearsonCorrelationPrecisionCriteria -SampleSize 200 -CorrelationCoefficient 0.2 -ConfidenceLevel 0.95
Format-PrecisionCriteriaResults -Results $results3

# Test 4: Corrélation négative
Write-Host "`nTest 4: Corrélation négative" -ForegroundColor Magenta
$results4 = Get-PearsonCorrelationPrecisionCriteria -SampleSize 100 -CorrelationCoefficient -0.6 -ConfidenceLevel 0.95
Format-PrecisionCriteriaResults -Results $results4

# Test 5: Niveau de confiance différent
Write-Host "`nTest 5: Niveau de confiance différent (99%)" -ForegroundColor Magenta
$results5 = Get-PearsonCorrelationPrecisionCriteria -SampleSize 80 -CorrelationCoefficient 0.4 -ConfidenceLevel 0.99
Format-PrecisionCriteriaResults -Results $results5

# Test 6: Critères de précision pour Spearman
Write-Host "`nTest 6: Critères de précision pour Spearman" -ForegroundColor Magenta
$results6 = Get-SpearmanCorrelationPrecisionCriteria -SampleSize 60 -CorrelationCoefficient 0.6 -ConfidenceLevel 0.95
Format-PrecisionCriteriaResults -Results $results6

# Test 7: Seuils d'erreur acceptables pour la recherche
Write-Host "`nTest 7: Seuils d'erreur acceptables pour la recherche" -ForegroundColor Magenta
$thresholds1 = Get-CorrelationErrorThresholds -ApplicationContext "Recherche" -PrecisionLevel "Élevé" -CorrelationType "Pearson"
Write-Host "=== Seuils d'erreur pour la recherche (précision élevée, Pearson) ===" -ForegroundColor Cyan
Write-Host "Taille d'échantillon minimale: $($thresholds1.MinSampleSize)" -ForegroundColor White
Write-Host "Erreur standard maximale: $($thresholds1.MaxStandardError)" -ForegroundColor White
Write-Host "Largeur maximale de l'intervalle de confiance: $($thresholds1.MaxConfidenceIntervalWidth)" -ForegroundColor White
Write-Host "Niveau de confiance minimal: $($thresholds1.MinConfidenceLevel)" -ForegroundColor White
Write-Host "Recommandations:" -ForegroundColor Green
foreach ($recommendation in $thresholds1.Recommendations) {
    Write-Host "  - $recommendation" -ForegroundColor White
}

# Test 8: Seuils d'erreur acceptables pour les applications critiques
Write-Host "`nTest 8: Seuils d'erreur acceptables pour les applications critiques" -ForegroundColor Magenta
$thresholds2 = Get-CorrelationErrorThresholds -ApplicationContext "Critique" -PrecisionLevel "Très élevé" -CorrelationType "Tous"
Write-Host "=== Seuils d'erreur pour les applications critiques (précision très élevée, tous types) ===" -ForegroundColor Cyan
Write-Host "Taille d'échantillon minimale: $($thresholds2.MinSampleSize)" -ForegroundColor White
Write-Host "Erreur standard maximale: $($thresholds2.MaxStandardError)" -ForegroundColor White
Write-Host "Largeur maximale de l'intervalle de confiance: $($thresholds2.MaxConfidenceIntervalWidth)" -ForegroundColor White
Write-Host "Niveau de confiance minimal: $($thresholds2.MinConfidenceLevel)" -ForegroundColor White
Write-Host "Recommandations:" -ForegroundColor Green
foreach ($recommendation in $thresholds2.Recommendations) {
    Write-Host "  - $recommendation" -ForegroundColor White
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les critères de précision sont correctement calculés." -ForegroundColor Green
