# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les criteres de qualite par type d'analyse.

.DESCRIPTION
    Ce script teste les fonctionnalites du module AnalysisQualityCriteria,
    notamment les criteres de qualite pour l'analyse exploratoire des donnees.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Definir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "AnalysisQualityCriteria.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les resultats de maniere formatee
function Format-ExploratoryAnalysisQualityCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Criteres de qualite pour l'analyse exploratoire des donnees ===" -ForegroundColor Cyan
    Write-Host "Type d'analyse: $($Results.AnalysisType)" -ForegroundColor White
    Write-Host "Taille d'echantillon: $($Results.SampleSize) (Categorie: $($Results.SampleSizeCategory))" -ForegroundColor White
    Write-Host "Distribution des donnees: $($Results.DataDistribution)" -ForegroundColor White
    Write-Host "Pourcentage de valeurs aberrantes: $($Results.OutlierPercentage)% (Impact: $($Results.OutlierImpactCategory))" -ForegroundColor White
    Write-Host "Pourcentage de donnees manquantes: $($Results.MissingDataPercentage)% (Impact: $($Results.MissingDataImpactCategory))" -ForegroundColor White
    Write-Host ""

    Write-Host "Techniques utilisees:" -ForegroundColor Yellow
    if ($Results.TechniquesUsed.Count -gt 0) {
        foreach ($technique in $Results.TechniquesUsed) {
            Write-Host "  - $technique" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune technique specifiee" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Couverture des techniques recommandees: $($Results.TechniquesCoveragePercentage)% (Categorie: $($Results.TechniquesCoverageCategory))" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Scores de qualite:" -ForegroundColor Yellow
    Write-Host "  - Score de taille d'echantillon: $($Results.SampleSizeScore)" -ForegroundColor White
    Write-Host "  - Score de couverture des techniques: $($Results.TechniquesCoverageScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des valeurs aberrantes: $($Results.OutlierImpactScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des donnees manquantes: $($Results.MissingDataImpactScore)" -ForegroundColor White
    Write-Host "  - Score global de qualite: $($Results.OverallQualityScore) (Categorie: $($Results.OverallQualityCategory))" -ForegroundColor White
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

# Test 1: Analyse exploratoire avec taille d'echantillon insuffisante
Write-Host "Test 1: Analyse exploratoire avec taille d'echantillon insuffisante" -ForegroundColor Magenta
$results1 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 5 -DataDistribution "Normale" -OutlierPercentage 0 -MissingDataPercentage 0 -TechniquesUsed @("Statistiques descriptives", "Histogrammes")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results1

# Test 2: Analyse exploratoire avec taille d'echantillon minimale
Write-Host "`nTest 2: Analyse exploratoire avec taille d'echantillon minimale" -ForegroundColor Magenta
$results2 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 15 -DataDistribution "Normale" -OutlierPercentage 2 -MissingDataPercentage 3 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results2

# Test 3: Analyse exploratoire avec taille d'echantillon acceptable
Write-Host "`nTest 3: Analyse exploratoire avec taille d'echantillon acceptable" -ForegroundColor Magenta
$results3 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 50 -DataDistribution "Asymetrique" -OutlierPercentage 5 -MissingDataPercentage 7 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches", "Diagrammes de dispersion", "Matrices de correlation")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results3

# Test 4: Analyse exploratoire avec taille d'echantillon recommandee
Write-Host "`nTest 4: Analyse exploratoire avec taille d'echantillon recommandee" -ForegroundColor Magenta
$results4 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 150 -DataDistribution "Multimodale" -OutlierPercentage 8 -MissingDataPercentage 12 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches", "Diagrammes de dispersion", "Matrices de correlation", "Analyse en composantes principales (ACP)")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results4

# Test 5: Analyse exploratoire avec taille d'echantillon optimale
Write-Host "`nTest 5: Analyse exploratoire avec taille d'echantillon optimale" -ForegroundColor Magenta
$results5 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 500 -DataDistribution "Normale" -OutlierPercentage 3 -MissingDataPercentage 5 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches", "Diagrammes de dispersion", "Matrices de correlation", "Analyse en composantes principales (ACP)", "Analyse factorielle exploratoire")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results5

# Test 6: Analyse exploratoire avec distribution a queue lourde
Write-Host "`nTest 6: Analyse exploratoire avec distribution a queue lourde" -ForegroundColor Magenta
$results6 = Get-ExploratoryAnalysisQualityCriteria -SampleSize 200 -DataDistribution "Queue lourde" -OutlierPercentage 15 -MissingDataPercentage 8 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches", "Diagrammes de dispersion")
Format-ExploratoryAnalysisQualityCriteriaResults -Results $results6

# Fonction pour afficher les resultats de l'analyse confirmatoire
function Format-ConfirmatoryAnalysisQualityCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Criteres de qualite pour l'analyse confirmatoire ===" -ForegroundColor Cyan
    Write-Host "Type d'analyse: $($Results.AnalysisType)" -ForegroundColor White
    Write-Host "Taille d'echantillon: $($Results.SampleSize) (Categorie: $($Results.SampleSizeCategory))" -ForegroundColor White
    Write-Host "Puissance statistique: $([Math]::Round($Results.Power, 2)) (Categorie: $($Results.PowerCategory))" -ForegroundColor White
    Write-Host "Puissance recommandee: $($Results.RecommendedPower) (Suffisante: $($Results.IsPowerSufficient))" -ForegroundColor White
    Write-Host "Alpha: $($Results.Alpha) (Categorie: $($Results.AlphaCategory))" -ForegroundColor White
    Write-Host "Alpha recommande: $($Results.RecommendedAlpha) (Approprie: $($Results.IsAlphaAppropriate))" -ForegroundColor White
    Write-Host "Taille d'effet: $($Results.EffectSize) (Categorie: $($Results.EffectSizeCategory))" -ForegroundColor White
    Write-Host "Distribution des donnees: $($Results.DataDistribution) (Normalite adequate: $($Results.IsNormalityAdequate))" -ForegroundColor White
    Write-Host "Homogeneite des variances: $($Results.VarianceHomogeneity) (Adequate: $($Results.IsVarianceHomogeneityAdequate))" -ForegroundColor White
    Write-Host "Pourcentage de valeurs aberrantes: $($Results.OutlierPercentage)% (Impact: $($Results.OutlierImpactCategory))" -ForegroundColor White
    Write-Host "Pourcentage de donnees manquantes: $($Results.MissingDataPercentage)% (Impact: $($Results.MissingDataImpactCategory))" -ForegroundColor White
    Write-Host ""

    Write-Host "Techniques utilisees:" -ForegroundColor Yellow
    if ($Results.TechniquesUsed.Count -gt 0) {
        foreach ($technique in $Results.TechniquesUsed) {
            Write-Host "  - $technique" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune technique specifiee" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Couverture des techniques recommandees: $($Results.TechniquesCoveragePercentage)% (Categorie: $($Results.TechniquesCoverageCategory))" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Scores de qualite:" -ForegroundColor Yellow
    Write-Host "  - Score de taille d'echantillon: $($Results.SampleSizeScore)" -ForegroundColor White
    Write-Host "  - Score de puissance statistique: $($Results.PowerScore)" -ForegroundColor White
    Write-Host "  - Score de niveau de signification: $($Results.AlphaScore)" -ForegroundColor White
    Write-Host "  - Score de couverture des techniques: $($Results.TechniquesCoverageScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des valeurs aberrantes: $($Results.OutlierImpactScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des donnees manquantes: $($Results.MissingDataImpactScore)" -ForegroundColor White
    Write-Host "  - Score d'adequation des hypotheses: $($Results.HypothesesScore)" -ForegroundColor White
    Write-Host "  - Score global de qualite: $($Results.OverallQualityScore) (Categorie: $($Results.OverallQualityCategory))" -ForegroundColor White
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

# Test 7: Analyse confirmatoire avec taille d'echantillon insuffisante
Write-Host "`nTest 7: Analyse confirmatoire avec taille d'echantillon insuffisante" -ForegroundColor Magenta
$results7 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 20 -Power 0.7 -Alpha 0.05 -EffectSize 0.5 -DataDistribution "Normale" -VarianceHomogeneity "Elevee" -OutlierPercentage 0 -MissingDataPercentage 0 -TechniquesUsed @("Tests d'hypotheses")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results7

# Test 8: Analyse confirmatoire avec puissance insuffisante
Write-Host "`nTest 8: Analyse confirmatoire avec puissance insuffisante" -ForegroundColor Magenta
$results8 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 50 -Power 0.6 -Alpha 0.05 -EffectSize 0.3 -DataDistribution "Normale" -VarianceHomogeneity "Moderee" -OutlierPercentage 3 -MissingDataPercentage 5 -TechniquesUsed @("Tests d'hypotheses", "ANOVA")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results8

# Test 9: Analyse confirmatoire avec alpha inapproprie
Write-Host "`nTest 9: Analyse confirmatoire avec alpha inapproprie" -ForegroundColor Magenta
$results9 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 100 -Power 0.8 -Alpha 0.1 -EffectSize 0.5 -DataDistribution "Normale" -VarianceHomogeneity "Elevee" -OutlierPercentage 2 -MissingDataPercentage 3 -TechniquesUsed @("Tests d'hypotheses", "ANOVA", "Tests parametriques")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results9

# Test 10: Analyse confirmatoire avec distribution non normale
Write-Host "`nTest 10: Analyse confirmatoire avec distribution non normale" -ForegroundColor Magenta
$results10 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 150 -Power 0.85 -Alpha 0.05 -EffectSize 0.6 -DataDistribution "Asymetrique" -VarianceHomogeneity "Moderee" -OutlierPercentage 7 -MissingDataPercentage 8 -TechniquesUsed @("Tests d'hypotheses", "ANOVA", "Tests parametriques", "Tests non-parametriques")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results10

# Test 11: Analyse confirmatoire avec variance non homogene
Write-Host "`nTest 11: Analyse confirmatoire avec variance non homogene" -ForegroundColor Magenta
$results11 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 200 -Power 0.9 -Alpha 0.01 -EffectSize 0.7 -DataDistribution "Normale" -VarianceHomogeneity "Faible" -OutlierPercentage 4 -MissingDataPercentage 6 -TechniquesUsed @("Tests d'hypotheses", "ANOVA", "Tests parametriques", "Tests non-parametriques", "Analyse factorielle confirmatoire")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results11

# Test 12: Analyse confirmatoire optimale
Write-Host "`nTest 12: Analyse confirmatoire optimale" -ForegroundColor Magenta
$results12 = Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 500 -Power 0.95 -Alpha 0.01 -EffectSize 0.5 -DataDistribution "Normale" -VarianceHomogeneity "Elevee" -OutlierPercentage 1 -MissingDataPercentage 2 -TechniquesUsed @("Tests d'hypotheses", "Tests parametriques", "Tests non-parametriques", "ANOVA", "Analyse factorielle confirmatoire", "Modelisation par equations structurelles")
Format-ConfirmatoryAnalysisQualityCriteriaResults -Results $results12

# Fonction pour afficher les resultats de l'analyse predictive
function Format-PredictiveAnalysisQualityCriteriaResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )

    Write-Host "=== Criteres de qualite pour l'analyse predictive ===" -ForegroundColor Cyan
    Write-Host "Type d'analyse: $($Results.AnalysisType)" -ForegroundColor White
    Write-Host "Taille d'echantillon: $($Results.SampleSize) (Categorie: $($Results.SampleSizeCategory))" -ForegroundColor White
    Write-Host "Nombre de caracteristiques: $($Results.FeatureCount)" -ForegroundColor White
    Write-Host "Ratio observations/caracteristiques: $([Math]::Round($Results.ObservationToFeatureRatio, 2)) (Categorie: $($Results.ObservationToFeatureRatioCategory))" -ForegroundColor White
    Write-Host "Methode de validation: $($Results.ValidationMethod) (Categorie: $($Results.ValidationMethodCategory))" -ForegroundColor White

    if ($Results.ValidationMethod -eq "Validation croisee") {
        Write-Host "Nombre de plis: $($Results.NumberOfFolds) (Categorie: $($Results.ValidationConfigurationCategory))" -ForegroundColor White
    } elseif ($Results.ValidationMethod -eq "Train-test split") {
        Write-Host "Pourcentage de donnees de test: $($Results.TestSetPercentage)% (Categorie: $($Results.ValidationConfigurationCategory))" -ForegroundColor White
    }

    Write-Host "Pourcentage de valeurs aberrantes: $($Results.OutlierPercentage)% (Impact: $($Results.OutlierImpactCategory))" -ForegroundColor White
    Write-Host "Pourcentage de donnees manquantes: $($Results.MissingDataPercentage)% (Impact: $($Results.MissingDataImpactCategory))" -ForegroundColor White
    Write-Host ""

    Write-Host "Techniques utilisees:" -ForegroundColor Yellow
    if ($Results.TechniquesUsed.Count -gt 0) {
        foreach ($technique in $Results.TechniquesUsed) {
            Write-Host "  - $technique" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune technique specifiee" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Metriques d'evaluation utilisees:" -ForegroundColor Yellow
    if ($Results.EvaluationMetricsUsed.Count -gt 0) {
        foreach ($metric in $Results.EvaluationMetricsUsed) {
            Write-Host "  - $metric" -ForegroundColor White
        }
    } else {
        Write-Host "  Aucune metrique d'evaluation specifiee" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "Couverture des techniques recommandees: $($Results.TechniquesCoveragePercentage)% (Categorie: $($Results.TechniquesCoverageCategory))" -ForegroundColor Yellow
    Write-Host "Couverture des metriques d'evaluation: $($Results.EvaluationMetricsCoveragePercentage)% (Categorie: $($Results.EvaluationMetricsCoverageCategory))" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Scores de qualite:" -ForegroundColor Yellow
    Write-Host "  - Score de taille d'echantillon: $($Results.SampleSizeScore)" -ForegroundColor White
    Write-Host "  - Score de ratio observations/caracteristiques: $($Results.ObservationToFeatureRatioScore)" -ForegroundColor White
    Write-Host "  - Score de methode de validation: $($Results.ValidationMethodScore)" -ForegroundColor White
    Write-Host "  - Score de configuration de validation: $($Results.ValidationConfigurationScore)" -ForegroundColor White
    Write-Host "  - Score de couverture des techniques: $($Results.TechniquesCoverageScore)" -ForegroundColor White
    Write-Host "  - Score de couverture des metriques d'evaluation: $($Results.EvaluationMetricsCoverageScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des valeurs aberrantes: $($Results.OutlierImpactScore)" -ForegroundColor White
    Write-Host "  - Score d'impact des donnees manquantes: $($Results.MissingDataImpactScore)" -ForegroundColor White
    Write-Host "  - Score global de qualite: $($Results.OverallQualityScore) (Categorie: $($Results.OverallQualityCategory))" -ForegroundColor White
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

# Test 13: Analyse predictive avec taille d'echantillon insuffisante
Write-Host "`nTest 13: Analyse predictive avec taille d'echantillon insuffisante" -ForegroundColor Magenta
$results13 = Get-PredictiveAnalysisQualityCriteria -SampleSize 30 -ValidationMethod "Aucune" -FeatureCount 10 -OutlierPercentage 0 -MissingDataPercentage 0 -TechniquesUsed @("Regression lineaire")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results13

# Test 14: Analyse predictive avec ratio observations/caracteristiques insuffisant
Write-Host "`nTest 14: Analyse predictive avec ratio observations/caracteristiques insuffisant" -ForegroundColor Magenta
$results14 = Get-PredictiveAnalysisQualityCriteria -SampleSize 100 -ValidationMethod "Train-test split" -TestSetPercentage 15 -FeatureCount 30 -OutlierPercentage 2 -MissingDataPercentage 3 -TechniquesUsed @("Regression lineaire", "Regression logistique")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results14

# Test 15: Analyse predictive avec validation croisee insuffisante
Write-Host "`nTest 15: Analyse predictive avec validation croisee insuffisante" -ForegroundColor Magenta
$results15 = Get-PredictiveAnalysisQualityCriteria -SampleSize 200 -ValidationMethod "Validation croisee" -NumberOfFolds 2 -FeatureCount 15 -OutlierPercentage 5 -MissingDataPercentage 7 -TechniquesUsed @("Regression lineaire", "Arbres de decision", "Forets aleatoires") -EvaluationMetricsUsed @("R²", "RMSE")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results15

# Test 16: Analyse predictive avec couverture des techniques insuffisante
Write-Host "`nTest 16: Analyse predictive avec couverture des techniques insuffisante" -ForegroundColor Magenta
$results16 = Get-PredictiveAnalysisQualityCriteria -SampleSize 300 -ValidationMethod "Validation croisee" -NumberOfFolds 5 -FeatureCount 20 -OutlierPercentage 8 -MissingDataPercentage 10 -TechniquesUsed @("Regression lineaire") -EvaluationMetricsUsed @("R²", "RMSE", "MAE")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results16

# Test 17: Analyse predictive avec couverture des metriques d'evaluation insuffisante
Write-Host "`nTest 17: Analyse predictive avec couverture des metriques d'evaluation insuffisante" -ForegroundColor Magenta
$results17 = Get-PredictiveAnalysisQualityCriteria -SampleSize 400 -ValidationMethod "Validation croisee" -NumberOfFolds 5 -FeatureCount 15 -OutlierPercentage 3 -MissingDataPercentage 5 -TechniquesUsed @("Regression lineaire", "Regression logistique", "Arbres de decision", "Forets aleatoires") -EvaluationMetricsUsed @("R²")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results17

# Test 18: Analyse predictive optimale
Write-Host "`nTest 18: Analyse predictive optimale" -ForegroundColor Magenta
$results18 = Get-PredictiveAnalysisQualityCriteria -SampleSize 1000 -ValidationMethod "Validation croisee" -NumberOfFolds 10 -FeatureCount 20 -OutlierPercentage 1 -MissingDataPercentage 2 -TechniquesUsed @("Regression lineaire", "Regression logistique", "Arbres de decision", "Forets aleatoires", "Machines a vecteurs de support", "Reseaux de neurones") -EvaluationMetricsUsed @("R²", "RMSE", "MAE", "Precision", "Rappel", "F1-score", "AUC-ROC")
Format-PredictiveAnalysisQualityCriteriaResults -Results $results18

# Test 19: Tableau comparatif des criteres de qualite au format texte
Write-Host "`nTest 19: Tableau comparatif des criteres de qualite au format texte" -ForegroundColor Magenta
$comparisonText = Get-AnalysisQualityCriteriaComparison -Format "Text" -IncludeDetails $false
Write-Host $comparisonText -ForegroundColor White

# Test 20: Tableau comparatif des criteres de qualite au format HTML
Write-Host "`nTest 20: Tableau comparatif des criteres de qualite au format HTML" -ForegroundColor Magenta
$comparisonHtml = Get-AnalysisQualityCriteriaComparison -Format "HTML" -IncludeDetails $true

# Sauvegarder le tableau HTML dans un fichier
$htmlFilePath = Join-Path -Path $PSScriptRoot -ChildPath "AnalysisQualityCriteriaComparison.html"
Set-Content -Path $htmlFilePath -Value $comparisonHtml -Encoding UTF8
Write-Host "Le tableau comparatif au format HTML a ete sauvegarde dans le fichier: $htmlFilePath" -ForegroundColor Green

# Test 21: Tableau comparatif des criteres de qualite au format CSV
Write-Host "`nTest 21: Tableau comparatif des criteres de qualite au format CSV" -ForegroundColor Magenta
$comparisonCsv = Get-AnalysisQualityCriteriaComparison -Format "CSV" -IncludeDetails $true

# Sauvegarder le tableau CSV dans un fichier
$csvFilePath = Join-Path -Path $PSScriptRoot -ChildPath "AnalysisQualityCriteriaComparison.csv"
Set-Content -Path $csvFilePath -Value $comparisonCsv -Encoding UTF8
Write-Host "Le tableau comparatif au format CSV a ete sauvegarde dans le fichier: $csvFilePath" -ForegroundColor Green

# Test 22: Tableau comparatif des criteres de qualite au format JSON
Write-Host "`nTest 22: Tableau comparatif des criteres de qualite au format JSON" -ForegroundColor Magenta
$comparisonJson = Get-AnalysisQualityCriteriaComparison -Format "JSON" -IncludeDetails $true

# Sauvegarder le tableau JSON dans un fichier
$jsonFilePath = Join-Path -Path $PSScriptRoot -ChildPath "AnalysisQualityCriteriaComparison.json"
Set-Content -Path $jsonFilePath -Value $comparisonJson -Encoding UTF8
Write-Host "Le tableau comparatif au format JSON a ete sauvegarde dans le fichier: $jsonFilePath" -ForegroundColor Green

# Resume des tests
Write-Host "`n=== Resume des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont ete executes." -ForegroundColor Green
Write-Host "Verifiez les resultats pour vous assurer que les criteres de qualite pour l'analyse exploratoire, confirmatoire et predictive sont correctement evalues." -ForegroundColor Green
Write-Host "Les tableaux comparatifs ont ete generes dans differents formats et sauvegardes dans des fichiers." -ForegroundColor Green
