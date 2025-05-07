#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les métriques de robustesse des analyses de corrélation.

.DESCRIPTION
    Ce script teste les fonctionnalités du module CorrelationQualityMetrics liées à la robustesse,
    notamment les critères de résistance aux valeurs aberrantes, la stabilité face aux variations
    d'échantillonnage, et les seuils de robustesse pour différents types de distributions.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "CorrelationQualityMetrics.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les résultats de manière formatée
function Format-OutlierResistanceResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Critères de résistance aux valeurs aberrantes ===" -ForegroundColor Cyan
    Write-Host "Coefficient de corrélation original: $($Results.CorrelationCoefficient)" -ForegroundColor White
    Write-Host "Coefficient de corrélation tronqué: $($Results.TrimmedCorrelationCoefficient)" -ForegroundColor White
    Write-Host "Pourcentage de valeurs aberrantes: $($Results.OutlierPercentage)%" -ForegroundColor White
    Write-Host "Type de corrélation: $($Results.CorrelationType)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Différence absolue: $([Math]::Round($Results.AbsoluteDifference, 4))" -ForegroundColor Yellow
    Write-Host "Différence relative: $([Math]::Round($Results.RelativeDifference, 2))%" -ForegroundColor Yellow
    Write-Host "Indice de stabilité: $([Math]::Round($Results.StabilityIndex, 2))" -ForegroundColor Yellow
    Write-Host "Niveau de robustesse: $($Results.RobustnessLevel)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Seuil de différence acceptable: $([Math]::Round($Results.AcceptableDifferenceThreshold, 2))%" -ForegroundColor Green
    Write-Host "Différence acceptable: $($Results.IsDifferenceAcceptable)" -ForegroundColor Green
    Write-Host ""
    
    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particulière." -ForegroundColor Green
    }
    
    Write-Host "===================================================" -ForegroundColor Cyan
}

function Format-SamplingStabilityResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Métriques de stabilité face aux variations d'échantillonnage ===" -ForegroundColor Cyan
    Write-Host "Corrélation moyenne: $([Math]::Round($Results.MeanCorrelation, 4))" -ForegroundColor White
    Write-Host "Taille moyenne des échantillons: $([Math]::Round($Results.MeanSampleSize, 0))" -ForegroundColor White
    Write-Host "Nombre d'échantillons: $($Results.NumberOfSamples)" -ForegroundColor White
    Write-Host "Type de corrélation: $($Results.CorrelationType)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Écart-type des coefficients: $([Math]::Round($Results.StandardDeviation, 4))" -ForegroundColor Yellow
    Write-Host "Coefficient de variation: $([Math]::Round($Results.CoefficientOfVariation, 2))%" -ForegroundColor Yellow
    Write-Host "Erreur standard attendue: $([Math]::Round($Results.ExpectedStandardError, 4))" -ForegroundColor Yellow
    Write-Host "Ratio de stabilité: $([Math]::Round($Results.StabilityRatio, 2))" -ForegroundColor Yellow
    Write-Host "Niveau de stabilité: $($Results.StabilityLevel)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Intervalle de confiance pour la moyenne:" -ForegroundColor Green
    Write-Host "  Borne inférieure: $([Math]::Round($Results.ConfidenceInterval.LowerBound, 4))" -ForegroundColor White
    Write-Host "  Borne supérieure: $([Math]::Round($Results.ConfidenceInterval.UpperBound, 4))" -ForegroundColor White
    Write-Host "  Largeur: $([Math]::Round($Results.ConfidenceInterval.Width, 4))" -ForegroundColor White
    Write-Host ""
    
    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particulière." -ForegroundColor Green
    }
    
    Write-Host "===================================================" -ForegroundColor Cyan
}

function Format-RobustnessThresholdsResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Seuils de robustesse pour les analyses de corrélation ===" -ForegroundColor Cyan
    Write-Host "Type de distribution: $($Results.DistributionType)" -ForegroundColor White
    Write-Host "Niveau de précision: $($Results.PrecisionLevel)" -ForegroundColor White
    Write-Host "Type de corrélation: $($Results.CorrelationType)" -ForegroundColor White
    Write-Host "Type de corrélation recommandé: $($Results.RecommendedCorrelationType)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Impact maximal des valeurs aberrantes: $([Math]::Round($Results.MaxOutlierImpact * 100, 2))%" -ForegroundColor Yellow
    Write-Host "Variabilité maximale d'échantillonnage: $([Math]::Round($Results.MaxSamplingVariability * 100, 2))%" -ForegroundColor Yellow
    Write-Host "Indice de stabilité minimal: $([Math]::Round($Results.MinStabilityIndex, 2))" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particulière." -ForegroundColor Green
    }
    
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 1: Résistance aux valeurs aberrantes - Pearson avec faible impact
Write-Host "Test 1: Résistance aux valeurs aberrantes - Pearson avec faible impact" -ForegroundColor Magenta
$results1 = Test-CorrelationOutlierResistance -CorrelationCoefficient 0.75 -TrimmedCorrelationCoefficient 0.72 -OutlierPercentage 5 -CorrelationType "Pearson"
Format-OutlierResistanceResults -Results $results1

# Test 2: Résistance aux valeurs aberrantes - Pearson avec fort impact
Write-Host "`nTest 2: Résistance aux valeurs aberrantes - Pearson avec fort impact" -ForegroundColor Magenta
$results2 = Test-CorrelationOutlierResistance -CorrelationCoefficient 0.65 -TrimmedCorrelationCoefficient 0.45 -OutlierPercentage 5 -CorrelationType "Pearson"
Format-OutlierResistanceResults -Results $results2

# Test 3: Résistance aux valeurs aberrantes - Spearman avec faible impact
Write-Host "`nTest 3: Résistance aux valeurs aberrantes - Spearman avec faible impact" -ForegroundColor Magenta
$results3 = Test-CorrelationOutlierResistance -CorrelationCoefficient 0.70 -TrimmedCorrelationCoefficient 0.68 -OutlierPercentage 10 -CorrelationType "Spearman"
Format-OutlierResistanceResults -Results $results3

# Test 4: Stabilité face aux variations d'échantillonnage - Pearson avec bonne stabilité
Write-Host "`nTest 4: Stabilité face aux variations d'échantillonnage - Pearson avec bonne stabilité" -ForegroundColor Magenta
$results4 = Test-CorrelationSamplingStability -CorrelationCoefficients @(0.72, 0.68, 0.75, 0.71, 0.73) -SampleSizes @(50, 50, 50, 50, 50) -CorrelationType "Pearson" -ConfidenceLevel 0.95
Format-SamplingStabilityResults -Results $results4

# Test 5: Stabilité face aux variations d'échantillonnage - Pearson avec faible stabilité
Write-Host "`nTest 5: Stabilité face aux variations d'échantillonnage - Pearson avec faible stabilité" -ForegroundColor Magenta
$results5 = Test-CorrelationSamplingStability -CorrelationCoefficients @(0.65, 0.45, 0.75, 0.55, 0.70) -SampleSizes @(30, 30, 30, 30, 30) -CorrelationType "Pearson" -ConfidenceLevel 0.95
Format-SamplingStabilityResults -Results $results5

# Test 6: Stabilité face aux variations d'échantillonnage - Spearman
Write-Host "`nTest 6: Stabilité face aux variations d'échantillonnage - Spearman" -ForegroundColor Magenta
$results6 = Test-CorrelationSamplingStability -CorrelationCoefficients @(0.68, 0.65, 0.70, 0.67, 0.69) -SampleSizes @(40, 40, 40, 40, 40) -CorrelationType "Spearman" -ConfidenceLevel 0.95
Format-SamplingStabilityResults -Results $results6

# Test 7: Seuils de robustesse - Distribution normale avec précision élevée
Write-Host "`nTest 7: Seuils de robustesse - Distribution normale avec précision élevée" -ForegroundColor Magenta
$results7 = Get-CorrelationRobustnessThresholds -DistributionType "Normale" -PrecisionLevel "Élevé" -CorrelationType "Pearson"
Format-RobustnessThresholdsResults -Results $results7

# Test 8: Seuils de robustesse - Distribution à queue lourde avec précision moyenne
Write-Host "`nTest 8: Seuils de robustesse - Distribution à queue lourde avec précision moyenne" -ForegroundColor Magenta
$results8 = Get-CorrelationRobustnessThresholds -DistributionType "Queue lourde" -PrecisionLevel "Moyen" -CorrelationType "Spearman"
Format-RobustnessThresholdsResults -Results $results8

# Test 9: Seuils de robustesse - Distribution asymétrique avec précision très élevée
Write-Host "`nTest 9: Seuils de robustesse - Distribution asymétrique avec précision très élevée" -ForegroundColor Magenta
$results9 = Get-CorrelationRobustnessThresholds -DistributionType "Asymétrique" -PrecisionLevel "Très élevé" -CorrelationType "Tous"
Format-RobustnessThresholdsResults -Results $results9

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les métriques de robustesse sont correctement calculées." -ForegroundColor Green
