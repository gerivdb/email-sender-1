# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les mÃ©triques de qualitÃ© des tests d'hypothÃ¨ses.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module HypothesisTestQualityMetrics,
    notamment les critÃ¨res de puissance statistique pour les tests d'hypothÃ¨ses.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# DÃ©finir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "HypothesisTestQualityMetrics.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les rÃ©sultats de maniÃ¨re formatÃ©e
function Format-PowerStatisticsCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== CritÃ¨res de puissance statistique pour les tests d'hypothÃ¨ses ===" -ForegroundColor Cyan
    Write-Host "Taille d'effet: $($Results.EffectSize) (CatÃ©gorie: $($Results.EffectSizeCategory))" -ForegroundColor White
    Write-Host "Taille d'Ã©chantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Alpha: $($Results.Alpha)" -ForegroundColor White
    Write-Host "Type de test: $($Results.TestType)" -ForegroundColor White
    Write-Host "Domaine d'application: $($Results.ApplicationDomain)" -ForegroundColor White
    Write-Host ""

    Write-Host "Puissance calculÃ©e: $([Math]::Round($Results.CalculatedPower, 4))" -ForegroundColor Yellow
    Write-Host "Puissance recommandÃ©e: $($Results.RecommendedPower)" -ForegroundColor Yellow
    Write-Host "Puissance suffisante: $($Results.IsPowerSufficient)" -ForegroundColor Yellow

    if (-not $Results.IsPowerSufficient) {
        Write-Host "Taille d'Ã©chantillon recommandÃ©e: $($Results.RecommendedSampleSize)" -ForegroundColor Yellow
    }

    Write-Host ""

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particuliÃ¨re." -ForegroundColor Green
    }

    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 1: Puissance statistique suffisante pour un effet moyen en recherche standard
Write-Host "Test 1: Puissance statistique suffisante pour un effet moyen en recherche standard" -ForegroundColor Magenta
$results1 = Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 128 -Alpha 0.05 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results1

# Test 2: Puissance statistique insuffisante pour un petit effet en recherche standard
Write-Host "`nTest 2: Puissance statistique insuffisante pour un petit effet en recherche standard" -ForegroundColor Magenta
$results2 = Get-PowerStatisticsCriteria -EffectSize 0.2 -SampleSize 64 -Alpha 0.05 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results2

# Test 3: Puissance statistique pour un grand effet en recherche clinique
Write-Host "`nTest 3: Puissance statistique pour un grand effet en recherche clinique" -ForegroundColor Magenta
$results3 = Get-PowerStatisticsCriteria -EffectSize 0.8 -SampleSize 50 -Alpha 0.05 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche clinique"
Format-PowerStatisticsCriteriaResults -Results $results3

# Test 4: Puissance statistique pour un test unilatÃ©ral
Write-Host "`nTest 4: Puissance statistique pour un test unilatÃ©ral" -ForegroundColor Magenta
$results4 = Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "unilatÃ©ral" -ApplicationDomain "Recherche standard"
Format-PowerStatisticsCriteriaResults -Results $results4

# Test 5: Puissance statistique pour un effet trÃ¨s grand en recherche exploratoire
Write-Host "`nTest 5: Puissance statistique pour un effet trÃ¨s grand en recherche exploratoire" -ForegroundColor Magenta
$results5 = Get-PowerStatisticsCriteria -EffectSize 1.2 -SampleSize 20 -Alpha 0.05 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche exploratoire"
Format-PowerStatisticsCriteriaResults -Results $results5

# Test 6: Puissance statistique pour un petit effet en recherche de haute prÃ©cision
Write-Host "`nTest 6: Puissance statistique pour un petit effet en recherche de haute prÃ©cision" -ForegroundColor Magenta
$results6 = Get-PowerStatisticsCriteria -EffectSize 0.2 -SampleSize 200 -Alpha 0.01 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche de haute prÃ©cision"
Format-PowerStatisticsCriteriaResults -Results $results6

# Test 7: Calcul direct de la puissance statistique
Write-Host "`nTest 7: Calcul direct de la puissance statistique" -ForegroundColor Magenta
$power = Get-StatisticalPower -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilatÃ©ral"
Write-Host "Puissance statistique calculÃ©e: $([Math]::Round($power, 4))" -ForegroundColor Yellow

# Test 8: Calcul de la taille d'Ã©chantillon requise
Write-Host "`nTest 8: Calcul de la taille d'Ã©chantillon requise" -ForegroundColor Magenta
$sampleSize = Get-RequiredSampleSize -EffectSize 0.3 -Power 0.8 -Alpha 0.05 -TestType "bilatÃ©ral"
Write-Host "Taille d'Ã©chantillon requise: $sampleSize" -ForegroundColor Yellow

# Fonction pour afficher les rÃ©sultats de contrÃ´le des erreurs
function Format-ErrorControlMetricsResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== MÃ©triques de contrÃ´le des erreurs de type I et II ===" -ForegroundColor Cyan
    Write-Host "Alpha: $($Results.Alpha) (AjustÃ©: $($Results.AdjustedAlpha))" -ForegroundColor White
    Write-Host "Beta: $($Results.Beta)" -ForegroundColor White
    Write-Host "Puissance: $($Results.Power)" -ForegroundColor White
    Write-Host "Taille d'Ã©chantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Taille d'effet: $($Results.EffectSize)" -ForegroundColor White
    Write-Host "Type de test: $($Results.TestType)" -ForegroundColor White
    Write-Host "Domaine d'application: $($Results.ApplicationDomain)" -ForegroundColor White

    if ($Results.MultipleTestingCorrection -ne "Aucune") {
        Write-Host "Correction pour tests multiples: $($Results.MultipleTestingCorrection) (Nombre de tests: $($Results.NumberOfTests))" -ForegroundColor White
    }

    Write-Host ""

    Write-Host "Taux de faux positifs: $([Math]::Round($Results.FalsePositiveRate, 4))" -ForegroundColor Yellow
    Write-Host "Taux de faux nÃ©gatifs: $([Math]::Round($Results.FalseNegativeRate, 4))" -ForegroundColor Yellow
    Write-Host "Taux de vrais positifs: $([Math]::Round($Results.TruePositiveRate, 4))" -ForegroundColor Yellow
    Write-Host "Taux de vrais nÃ©gatifs: $([Math]::Round($Results.TrueNegativeRate, 4))" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Alpha recommandÃ©: $($Results.RecommendedAlpha)" -ForegroundColor Yellow
    Write-Host "Beta recommandÃ©: $($Results.RecommendedBeta)" -ForegroundColor Yellow
    Write-Host "Alpha acceptable: $($Results.IsAlphaAcceptable)" -ForegroundColor Yellow
    Write-Host "Beta acceptable: $($Results.IsBetaAcceptable)" -ForegroundColor Yellow
    Write-Host "Ratio Alpha/Beta: $([Math]::Round($Results.AlphaToBetaRatio, 2))" -ForegroundColor Yellow
    Write-Host "Ã‰quilibre des erreurs: $($Results.ErrorBalanceCategory)" -ForegroundColor Yellow
    Write-Host ""

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particuliÃ¨re." -ForegroundColor Green
    }

    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 9: ContrÃ´le des erreurs pour un test standard
Write-Host "`nTest 9: ContrÃ´le des erreurs pour un test standard" -ForegroundColor Magenta
$results9 = Get-ErrorControlMetrics -Alpha 0.05 -Power 0.8 -SampleSize 64 -EffectSize 0.5 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
Format-ErrorControlMetricsResults -Results $results9

# Test 10: ContrÃ´le des erreurs avec correction pour tests multiples
Write-Host "`nTest 10: ContrÃ´le des erreurs avec correction pour tests multiples" -ForegroundColor Magenta
$results10 = Get-ErrorControlMetrics -Alpha 0.05 -Power 0.8 -SampleSize 64 -EffectSize 0.5 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard" -MultipleTestingCorrection "Bonferroni" -NumberOfTests 10
Format-ErrorControlMetricsResults -Results $results10

# Test 11: ContrÃ´le des erreurs pour la recherche clinique
Write-Host "`nTest 11: ContrÃ´le des erreurs pour la recherche clinique" -ForegroundColor Magenta
$results11 = Get-ErrorControlMetrics -Alpha 0.05 -Power 0.8 -SampleSize 100 -EffectSize 0.4 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche clinique"
Format-ErrorControlMetricsResults -Results $results11

# Test 12: ContrÃ´le des erreurs avec dÃ©sÃ©quilibre entre alpha et beta
Write-Host "`nTest 12: ContrÃ´le des erreurs avec dÃ©sÃ©quilibre entre alpha et beta" -ForegroundColor Magenta
$results12 = Get-ErrorControlMetrics -Alpha 0.01 -Power 0.5 -SampleSize 30 -EffectSize 0.3 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
Format-ErrorControlMetricsResults -Results $results12

# Fonction pour afficher les rÃ©sultats de robustesse des tests
function Format-TestRobustnessCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== CritÃ¨res de robustesse pour les tests paramÃ©triques et non-paramÃ©triques ===" -ForegroundColor Cyan
    Write-Host "Type de test: $($Results.TestType)" -ForegroundColor White
    Write-Host "Taille d'Ã©chantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Type de distribution: $($Results.DistributionType)" -ForegroundColor White
    Write-Host "HomogÃ©nÃ©itÃ© des variances: $($Results.VarianceHomogeneity)" -ForegroundColor White
    Write-Host "Pourcentage de valeurs aberrantes: $($Results.OutlierPercentage)%" -ForegroundColor White
    Write-Host "Pourcentage de donnÃ©es manquantes: $($Results.MissingDataPercentage)%" -ForegroundColor White
    Write-Host "Domaine d'application: $($Results.ApplicationDomain)" -ForegroundColor White
    Write-Host ""

    Write-Host "Score de robustesse pour tests paramÃ©triques: $([Math]::Round($Results.ParametricRobustnessScore, 2))" -ForegroundColor Yellow
    Write-Host "Score de robustesse pour tests non-paramÃ©triques: $([Math]::Round($Results.NonParametricRobustnessScore, 2))" -ForegroundColor Yellow
    Write-Host "Score de robustesse du test actuel: $([Math]::Round($Results.CurrentTestRobustnessScore, 2))" -ForegroundColor Yellow
    Write-Host "Niveau de robustesse: $($Results.RobustnessLevel)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Type de test recommandÃ©: $($Results.RecommendedTestType)" -ForegroundColor Yellow
    Write-Host "Test actuel appropriÃ©: $($Results.IsCurrentTestAppropriate)" -ForegroundColor Yellow
    Write-Host "Seuil de robustesse minimal: $($Results.MinRobustnessThreshold)" -ForegroundColor Yellow
    Write-Host "Robustesse acceptable: $($Results.IsRobustnessAcceptable)" -ForegroundColor Yellow
    Write-Host ""

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particuliÃ¨re." -ForegroundColor Green
    }

    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 13: Robustesse d'un test paramÃ©trique avec distribution normale
Write-Host "`nTest 13: Robustesse d'un test paramÃ©trique avec distribution normale" -ForegroundColor Magenta
$results13 = Get-TestRobustnessCriteria -TestType "ParamÃ©trique" -SampleSize 30 -DistributionType "Normale" -VarianceHomogeneity "Ã‰levÃ©e" -OutlierPercentage 2 -MissingDataPercentage 5 -ApplicationDomain "Recherche standard"
Format-TestRobustnessCriteriaResults -Results $results13

# Test 14: Robustesse d'un test paramÃ©trique avec distribution non normale
Write-Host "`nTest 14: Robustesse d'un test paramÃ©trique avec distribution non normale" -ForegroundColor Magenta
$results14 = Get-TestRobustnessCriteria -TestType "ParamÃ©trique" -SampleSize 30 -DistributionType "Queue lourde" -VarianceHomogeneity "Faible" -OutlierPercentage 8 -MissingDataPercentage 5 -ApplicationDomain "Recherche standard"
Format-TestRobustnessCriteriaResults -Results $results14

# Test 15: Robustesse d'un test non-paramÃ©trique avec petit Ã©chantillon
Write-Host "`nTest 15: Robustesse d'un test non-paramÃ©trique avec petit Ã©chantillon" -ForegroundColor Magenta
$results15 = Get-TestRobustnessCriteria -TestType "Non-paramÃ©trique" -SampleSize 8 -DistributionType "AsymÃ©trique" -VarianceHomogeneity "ModÃ©rÃ©e" -OutlierPercentage 5 -MissingDataPercentage 10 -ApplicationDomain "Recherche standard"
Format-TestRobustnessCriteriaResults -Results $results15

# Test 16: Robustesse d'un test paramÃ©trique pour la recherche clinique
Write-Host "`nTest 16: Robustesse d'un test paramÃ©trique pour la recherche clinique" -ForegroundColor Magenta
$results16 = Get-TestRobustnessCriteria -TestType "ParamÃ©trique" -SampleSize 50 -DistributionType "Normale" -VarianceHomogeneity "ModÃ©rÃ©e" -OutlierPercentage 3 -MissingDataPercentage 2 -ApplicationDomain "Recherche clinique"
Format-TestRobustnessCriteriaResults -Results $results16

# Fonction pour afficher les rÃ©sultats d'efficacitÃ© computationnelle
function Format-ComputationalEfficiencyMetricsResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== MÃ©triques d'efficacitÃ© computationnelle pour les tests d'hypothÃ¨ses ===" -ForegroundColor Cyan
    Write-Host "Type de test: $($Results.TestType)" -ForegroundColor White
    Write-Host "Nom du test: $($Results.TestName)" -ForegroundColor White
    Write-Host "Taille d'Ã©chantillon: $($Results.SampleSize)" -ForegroundColor White
    Write-Host "Nombre de variables: $($Results.NumberOfVariables)" -ForegroundColor White
    Write-Host "Nombre de groupes: $($Results.NumberOfGroups)" -ForegroundColor White
    Write-Host "Environnement de calcul: $($Results.ComputationalEnvironment)" -ForegroundColor White
    Write-Host ""

    Write-Host "ComplexitÃ© algorithmique (temps): $($Results.AlgorithmicComplexityTime)" -ForegroundColor Yellow
    Write-Host "ComplexitÃ© algorithmique (mÃ©moire): $($Results.AlgorithmicComplexityMemory)" -ForegroundColor Yellow
    Write-Host "Description de la complexitÃ©: $($Results.ComplexityDescription)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Temps d'exÃ©cution thÃ©orique: $([Math]::Round($Results.TheoreticalExecutionTime, 2)) ms" -ForegroundColor Yellow
    Write-Host "Utilisation de mÃ©moire thÃ©orique: $([Math]::Round($Results.TheoreticalMemoryUsage, 2)) KB" -ForegroundColor Yellow
    Write-Host "EfficacitÃ© du temps d'exÃ©cution: $($Results.ExecutionTimeEfficiency)" -ForegroundColor Yellow
    Write-Host "EfficacitÃ© de l'utilisation de mÃ©moire: $($Results.MemoryUsageEfficiency)" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Score d'efficacitÃ© du temps d'exÃ©cution: $($Results.ExecutionTimeScore)" -ForegroundColor Yellow
    Write-Host "Score d'efficacitÃ© de l'utilisation de mÃ©moire: $($Results.MemoryUsageScore)" -ForegroundColor Yellow
    Write-Host "Score global d'efficacitÃ©: $([Math]::Round($Results.OverallEfficiencyScore, 2))" -ForegroundColor Yellow
    Write-Host "Niveau global d'efficacitÃ©: $($Results.OverallEfficiencyLevel)" -ForegroundColor Yellow
    Write-Host ""

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "Recommandations:" -ForegroundColor Green
        foreach ($recommendation in $Results.Recommendations) {
            Write-Host "  - $recommendation" -ForegroundColor White
        }
    } else {
        Write-Host "Aucune recommandation particuliÃ¨re." -ForegroundColor Green
    }

    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 17: EfficacitÃ© computationnelle d'un test t
Write-Host "`nTest 17: EfficacitÃ© computationnelle d'un test t" -ForegroundColor Magenta
$results17 = Get-ComputationalEfficiencyMetrics -TestType "ParamÃ©trique" -TestName "t-test" -SampleSize 100 -NumberOfVariables 1 -NumberOfGroups 2 -ComputationalEnvironment "Standard"
Format-ComputationalEfficiencyMetricsResults -Results $results17

# Test 18: EfficacitÃ© computationnelle d'une ANOVA avec grand Ã©chantillon
Write-Host "`nTest 18: EfficacitÃ© computationnelle d'une ANOVA avec grand Ã©chantillon" -ForegroundColor Magenta
$results18 = Get-ComputationalEfficiencyMetrics -TestType "ParamÃ©trique" -TestName "ANOVA" -SampleSize 10000 -NumberOfVariables 1 -NumberOfGroups 5 -ComputationalEnvironment "Standard"
Format-ComputationalEfficiencyMetricsResults -Results $results18

# Test 19: EfficacitÃ© computationnelle d'une rÃ©gression linÃ©aire multiple
Write-Host "`nTest 19: EfficacitÃ© computationnelle d'une rÃ©gression linÃ©aire multiple" -ForegroundColor Magenta
$results19 = Get-ComputationalEfficiencyMetrics -TestType "ParamÃ©trique" -TestName "RÃ©gression linÃ©aire" -SampleSize 1000 -NumberOfVariables 20 -ComputationalEnvironment "Standard"
Format-ComputationalEfficiencyMetricsResults -Results $results19

# Test 20: EfficacitÃ© computationnelle d'un test bootstrap
Write-Host "`nTest 20: EfficacitÃ© computationnelle d'un test bootstrap" -ForegroundColor Magenta
$results20 = Get-ComputationalEfficiencyMetrics -TestType "Bootstrap" -TestName "Bootstrap t-test" -SampleSize 500 -NumberOfVariables 1 -ComputationalEnvironment "LimitÃ©"
Format-ComputationalEfficiencyMetricsResults -Results $results20

# RÃ©sumÃ© des tests
Write-Host "`n=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont Ã©tÃ© exÃ©cutÃ©s." -ForegroundColor Green
Write-Host "VÃ©rifiez les rÃ©sultats pour vous assurer que les critÃ¨res de puissance statistique, de contrÃ´le des erreurs, de robustesse et d'efficacitÃ© computationnelle sont correctement calculÃ©s." -ForegroundColor Green
