#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour la détection des corrélations non linéaires.

.DESCRIPTION
    Ce script teste les fonctionnalités du module CorrelationQualityMetrics liées à la détection
    des corrélations non linéaires, notamment les relations quadratiques, exponentielles,
    et les seuils de sensibilité pour les corrélations complexes.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "CorrelationQualityMetrics.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les résultats de manière formatée
function Format-QuadraticRelationshipResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Critères de détection des relations quadratiques ===" -ForegroundColor Cyan
    Write-Host "Coefficient de corrélation linéaire: $($Results.LinearCorrelation)" -ForegroundColor White
    Write-Host "Coefficient de corrélation quadratique: $($Results.QuadraticCorrelation)" -ForegroundColor White
    Write-Host "Taille de l'échantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Niveau de confiance: $($Results.ConfidenceLevel * 100)%" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Différence de corrélation: $([Math]::Round($Results.CorrelationDifference, 4))" -ForegroundColor Yellow
    Write-Host "Indice de non-linéarité: $([Math]::Round($Results.NonLinearityIndex, 2))" -ForegroundColor Yellow
    Write-Host "Statistique Z: $([Math]::Round($Results.ZStatistic, 4))" -ForegroundColor Yellow
    Write-Host "P-value: $([Math]::Round($Results.PValue, 4))" -ForegroundColor Yellow
    Write-Host "Statistiquement significatif: $($Results.IsSignificant)" -ForegroundColor Yellow
    Write-Host "Niveau de confiance dans la détection: $($Results.DetectionConfidenceLevel)" -ForegroundColor Yellow
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

function Format-ExponentialRelationshipResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Critères de détection des relations exponentielles ===" -ForegroundColor Cyan
    Write-Host "Coefficient de corrélation linéaire: $($Results.LinearCorrelation)" -ForegroundColor White
    Write-Host "Coefficient de corrélation après transformation logarithmique: $($Results.LogTransformedCorrelation)" -ForegroundColor White
    Write-Host "Taille de l'échantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Niveau de confiance: $($Results.ConfidenceLevel * 100)%" -ForegroundColor White
    Write-Host "Type de relation: $($Results.RelationshipType)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Différence de corrélation: $([Math]::Round($Results.CorrelationDifference, 4))" -ForegroundColor Yellow
    Write-Host "Indice de non-linéarité: $([Math]::Round($Results.NonLinearityIndex, 2))" -ForegroundColor Yellow
    Write-Host "Statistique Z: $([Math]::Round($Results.ZStatistic, 4))" -ForegroundColor Yellow
    Write-Host "P-value: $([Math]::Round($Results.PValue, 4))" -ForegroundColor Yellow
    Write-Host "Statistiquement significatif: $($Results.IsSignificant)" -ForegroundColor Yellow
    Write-Host "Niveau de confiance dans la détection: $($Results.DetectionConfidenceLevel)" -ForegroundColor Yellow
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

function Format-NonLinearThresholdsResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Seuils de sensibilité pour la détection des corrélations complexes ===" -ForegroundColor Cyan
    Write-Host "Type de relation: $($Results.RelationshipType)" -ForegroundColor White
    Write-Host "Niveau de précision: $($Results.PrecisionLevel)" -ForegroundColor White
    Write-Host "Catégorie de taille d'échantillon: $($Results.SampleSizeCategory)" -ForegroundColor White
    Write-Host "Transformation recommandée: $($Results.TransformationRecommended)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Indice minimal de non-linéarité: $([Math]::Round($Results.MinNonLinearityIndex, 2))" -ForegroundColor Yellow
    Write-Host "Différence minimale de corrélation: $([Math]::Round($Results.MinCorrelationDifference, 4))" -ForegroundColor Yellow
    Write-Host "P-value maximale: $([Math]::Round($Results.MaxPValue, 4))" -ForegroundColor Yellow
    Write-Host "Niveau de confiance minimal dans la détection: $($Results.MinDetectionConfidenceLevel)" -ForegroundColor Yellow
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

# Test 1: Détection d'une relation quadratique forte
Write-Host "Test 1: Détection d'une relation quadratique forte" -ForegroundColor Magenta
$results1 = Test-QuadraticRelationship -LinearCorrelation 0.3 -QuadraticCorrelation 0.8 -SampleSize 50 -ConfidenceLevel 0.95
Format-QuadraticRelationshipResults -Results $results1

# Test 2: Détection d'une relation quadratique faible
Write-Host "`nTest 2: Détection d'une relation quadratique faible" -ForegroundColor Magenta
$results2 = Test-QuadraticRelationship -LinearCorrelation 0.5 -QuadraticCorrelation 0.6 -SampleSize 30 -ConfidenceLevel 0.95
Format-QuadraticRelationshipResults -Results $results2

# Test 3: Détection d'une relation quadratique avec petit échantillon
Write-Host "`nTest 3: Détection d'une relation quadratique avec petit échantillon" -ForegroundColor Magenta
$results3 = Test-QuadraticRelationship -LinearCorrelation 0.2 -QuadraticCorrelation 0.7 -SampleSize 15 -ConfidenceLevel 0.95
Format-QuadraticRelationshipResults -Results $results3

# Test 4: Détection d'une relation exponentielle (croissance)
Write-Host "`nTest 4: Détection d'une relation exponentielle (croissance)" -ForegroundColor Magenta
$results4 = Test-ExponentialRelationship -LinearCorrelation 0.4 -LogTransformedCorrelation 0.85 -SampleSize 60 -ConfidenceLevel 0.95
Format-ExponentialRelationshipResults -Results $results4

# Test 5: Détection d'une relation exponentielle (décroissance)
Write-Host "`nTest 5: Détection d'une relation exponentielle (décroissance)" -ForegroundColor Magenta
$results5 = Test-ExponentialRelationship -LinearCorrelation -0.3 -LogTransformedCorrelation -0.75 -SampleSize 40 -ConfidenceLevel 0.95
Format-ExponentialRelationshipResults -Results $results5

# Test 6: Détection d'une relation exponentielle faible
Write-Host "`nTest 6: Détection d'une relation exponentielle faible" -ForegroundColor Magenta
$results6 = Test-ExponentialRelationship -LinearCorrelation 0.6 -LogTransformedCorrelation 0.7 -SampleSize 50 -ConfidenceLevel 0.95
Format-ExponentialRelationshipResults -Results $results6

# Test 7: Seuils pour relation quadratique avec précision élevée
Write-Host "`nTest 7: Seuils pour relation quadratique avec précision élevée" -ForegroundColor Magenta
$results7 = Get-NonLinearCorrelationThresholds -RelationshipType "Quadratique" -PrecisionLevel "Élevé" -SampleSizeCategory "Moyen"
Format-NonLinearThresholdsResults -Results $results7

# Test 8: Seuils pour relation exponentielle avec petit échantillon
Write-Host "`nTest 8: Seuils pour relation exponentielle avec petit échantillon" -ForegroundColor Magenta
$results8 = Get-NonLinearCorrelationThresholds -RelationshipType "Exponentielle" -PrecisionLevel "Moyen" -SampleSizeCategory "Petit"
Format-NonLinearThresholdsResults -Results $results8

# Test 9: Seuils pour relation complexe avec précision très élevée
Write-Host "`nTest 9: Seuils pour relation complexe avec précision très élevée" -ForegroundColor Magenta
$results9 = Get-NonLinearCorrelationThresholds -RelationshipType "Complexe" -PrecisionLevel "Très élevé" -SampleSizeCategory "Grand"
Format-NonLinearThresholdsResults -Results $results9

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les critères de détection des corrélations non linéaires sont correctement calculés." -ForegroundColor Green
