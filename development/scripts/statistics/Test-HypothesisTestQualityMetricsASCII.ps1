# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les metriques de qualite des tests d'hypotheses.

.DESCRIPTION
    Ce script teste les fonctionnalites du module HypothesisTestQualityMetricsASCII,
    notamment les criteres de puissance statistique pour les tests d'hypotheses.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Definir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "HypothesisTestQualityMetricsASCII.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les resultats de maniere formatee
function Format-PowerStatisticsCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Criteres de puissance statistique pour les tests d'hypotheses ===" -ForegroundColor Cyan
    Write-Host "Taille d'effet: $($Results.EffectSize) (Categorie: $($Results.EffectSizeCategory))" -ForegroundColor White
    Write-Host "Taille d'echantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Alpha: $($Results.Alpha)" -ForegroundColor White
    Write-Host "Type de test: $($Results.TestType)" -ForegroundColor White
    Write-Host "Domaine d'application: $($Results.ApplicationDomain)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Puissance calculee: $([Math]::Round($Results.CalculatedPower, 4))" -ForegroundColor Yellow
    Write-Host "Puissance recommandee: $($Results.RecommendedPower)" -ForegroundColor Yellow
    Write-Host "Puissance suffisante: $($Results.IsPowerSufficient)" -ForegroundColor Yellow
    
    if (-not $Results.IsPowerSufficient) {
        Write-Host "Taille d'echantillon recommandee: $($Results.RecommendedSampleSize)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particuliere." -ForegroundColor Green
    }
    
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 1: Puissance statistique suffisante pour un effet moyen en recherche standard
Write-Host "Test 1: Puissance statistique suffisante pour un effet moyen en recherche standard" -ForegroundColor Magenta
$results1 = Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 128 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results1

# Test 2: Puissance statistique insuffisante pour un petit effet en recherche standard
Write-Host "`nTest 2: Puissance statistique insuffisante pour un petit effet en recherche standard" -ForegroundColor Magenta
$results2 = Get-PowerStatisticsCriteria -EffectSize 0.2 -SampleSize 64 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results2

# Test 3: Puissance statistique pour un grand effet en recherche clinique
Write-Host "`nTest 3: Puissance statistique pour un grand effet en recherche clinique" -ForegroundColor Magenta
$results3 = Get-PowerStatisticsCriteria -EffectSize 0.8 -SampleSize 50 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche clinique"
Format-PowerStatisticsCriteriaResults -Results $results3

# Test 4: Puissance statistique pour un test unilateral
Write-Host "`nTest 4: Puissance statistique pour un test unilateral" -ForegroundColor Magenta
$results4 = Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "unilateral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results4

# Test 5: Puissance statistique pour un effet tres grand en recherche exploratoire
Write-Host "`nTest 5: Puissance statistique pour un effet tres grand en recherche exploratoire" -ForegroundColor Magenta
$results5 = Get-PowerStatisticsCriteria -EffectSize 1.2 -SampleSize 20 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche exploratoire"
Format-PowerStatisticsCriteriaResults -Results $results5

# Test 6: Puissance statistique pour un petit effet en recherche de haute precision
Write-Host "`nTest 6: Puissance statistique pour un petit effet en recherche de haute precision" -ForegroundColor Magenta
$results6 = Get-PowerStatisticsCriteria -EffectSize 0.2 -SampleSize 200 -Alpha 0.01 -TestType "bilateral" -ApplicationDomain "Recherche de haute precision"
Format-PowerStatisticsCriteriaResults -Results $results6

# Test 7: Calcul direct de la puissance statistique
Write-Host "`nTest 7: Calcul direct de la puissance statistique" -ForegroundColor Magenta
$power = Get-StatisticalPower -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilateral"
Write-Host "Puissance statistique calculee: $([Math]::Round($power, 4))" -ForegroundColor Yellow

# Test 8: Calcul de la taille d'echantillon requise
Write-Host "`nTest 8: Calcul de la taille d'echantillon requise" -ForegroundColor Magenta
$sampleSize = Get-RequiredSampleSize -EffectSize 0.3 -Power 0.8 -Alpha 0.05 -TestType "bilateral"
Write-Host "Taille d'echantillon requise: $sampleSize" -ForegroundColor Yellow

# Resume des tests
Write-Host "`n=== Resume des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes." -ForegroundColor Green
Write-Host "Verifiez les resultats pour vous assurer que les criteres de puissance statistique sont correctement calcules." -ForegroundColor Green
