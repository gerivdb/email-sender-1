# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour definir les criteres de qualite par type d'application d'analyse statistique.

.DESCRIPTION
    Ce module fournit des fonctions pour definir et evaluer les criteres de qualite
    pour differents types d'analyses statistiques, notamment l'analyse exploratoire,
    l'analyse confirmatoire et l'analyse predictive.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

#region Variables globales et constantes

# Seuils de taille d'echantillon par type d'analyse
$script:SampleSizeThresholds = @{
    "Analyse exploratoire"  = @{
        "Minimal"    = 10
        "Acceptable" = 30
        "Recommande" = 100
        "Optimal"    = 300
    }
    "Analyse confirmatoire" = @{
        "Minimal"    = 30
        "Acceptable" = 100
        "Recommande" = 300
        "Optimal"    = 1000
    }
    "Analyse predictive"    = @{
        "Minimal"    = 50
        "Acceptable" = 200
        "Recommande" = 500
        "Optimal"    = 2000
    }
}

# Seuils de puissance statistique par type d'analyse
$script:PowerThresholds = @{
    "Analyse exploratoire"  = 0.70
    "Analyse confirmatoire" = 0.80
    "Analyse predictive"    = 0.90
}

# Seuils de niveau de signification (alpha) par type d'analyse
$script:AlphaThresholds = @{
    "Analyse exploratoire"  = 0.10
    "Analyse confirmatoire" = 0.05
    "Analyse predictive"    = 0.01
}

# Exigences de normalite des donnees par type d'analyse
$script:NormalityRequirements = @{
    "Analyse exploratoire"  = "Faible"
    "Analyse confirmatoire" = "Moderee"
    "Analyse predictive"    = "Elevee"
}

# Exigences d'homogeneite des variances par type d'analyse
$script:VarianceHomogeneityRequirements = @{
    "Analyse exploratoire"  = "Faible"
    "Analyse confirmatoire" = "Moderee"
    "Analyse predictive"    = "Elevee"
}

# Exigences de traitement des valeurs aberrantes par type d'analyse
$script:OutlierRequirements = @{
    "Analyse exploratoire"  = "Identification"
    "Analyse confirmatoire" = "Traitement"
    "Analyse predictive"    = "Elimination ou modelisation"
}

# Exigences de traitement des donnees manquantes par type d'analyse
$script:MissingDataRequirements = @{
    "Analyse exploratoire"  = "Identification"
    "Analyse confirmatoire" = "Imputation simple"
    "Analyse predictive"    = "Imputation multiple ou modelisation"
}

# Techniques recommandees par type d'analyse
$script:RecommendedTechniques = @{
    "Analyse exploratoire"  = @(
        "Statistiques descriptives",
        "Histogrammes",
        "Diagrammes de dispersion",
        "Boites a moustaches",
        "Matrices de correlation",
        "Analyse en composantes principales (ACP)",
        "Analyse factorielle exploratoire"
    )
    "Analyse confirmatoire" = @(
        "Tests d'hypotheses",
        "Tests parametriques",
        "Tests non-parametriques",
        "Analyse de variance (ANOVA)",
        "Analyse factorielle confirmatoire",
        "Modelisation par equations structurelles"
    )
    "Analyse predictive"    = @(
        "Regression lineaire",
        "Regression logistique",
        "Arbres de decision",
        "Forets aleatoires",
        "Machines a vecteurs de support",
        "Reseaux de neurones",
        "Validation croisee"
    )
}

# Metriques d'evaluation par type d'analyse
$script:EvaluationMetrics = @{
    "Analyse exploratoire"  = @(
        "Completude de l'exploration",
        "Identification des patterns",
        "Detection des anomalies",
        "Qualite des visualisations"
    )
    "Analyse confirmatoire" = @(
        "Puissance statistique",
        "Controle des erreurs de type I et II",
        "Taille d'effet",
        "Ajustement du modele"
    )
    "Analyse predictive"    = @(
        "Precision",
        "Rappel",
        "F1-score",
        "AUC-ROC",
        "Erreur quadratique moyenne",
        "R²",
        "Capacite de generalisation"
    )
}

#endregion

#region Fonctions principales

<#
.SYNOPSIS
    Definit les criteres de qualite pour l'analyse exploratoire des donnees.

.DESCRIPTION
    Cette fonction definit et evalue les criteres de qualite specifiques a l'analyse
    exploratoire des donnees, notamment en termes de taille d'echantillon, techniques
    recommandees, et metriques d'evaluation.

.PARAMETER SampleSize
    La taille de l'echantillon utilise ou prevu.

.PARAMETER DataDistribution
    Le type de distribution des donnees (par defaut "Inconnue").

.PARAMETER OutlierPercentage
    Le pourcentage de valeurs aberrantes dans les donnees (par defaut 0).

.PARAMETER MissingDataPercentage
    Le pourcentage de donnees manquantes (par defaut 0).

.PARAMETER TechniquesUsed
    Les techniques d'analyse utilisees ou prevues.

.EXAMPLE
    Get-ExploratoryAnalysisQualityCriteria -SampleSize 50 -DataDistribution "Normale" -OutlierPercentage 2 -MissingDataPercentage 5 -TechniquesUsed @("Statistiques descriptives", "Histogrammes", "Boites a moustaches")
    Evalue les criteres de qualite pour une analyse exploratoire avec un echantillon de 50 sujets.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ExploratoryAnalysisQualityCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymetrique", "Multimodale", "Queue lourde", "Mixte", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$OutlierPercentage = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$MissingDataPercentage = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$TechniquesUsed = @()
    )

    # Evaluer la taille d'echantillon
    $sampleSizeCategory = if ($SampleSize -lt $script:SampleSizeThresholds["Analyse exploratoire"]["Minimal"]) {
        "Insuffisant"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse exploratoire"]["Acceptable"]) {
        "Minimal"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse exploratoire"]["Recommande"]) {
        "Acceptable"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse exploratoire"]["Optimal"]) {
        "Recommande"
    } else {
        "Optimal"
    }

    $isSampleSizeSufficient = $sampleSizeCategory -ne "Insuffisant"

    # Evaluer la couverture des techniques recommandees
    $recommendedTechniques = $script:RecommendedTechniques["Analyse exploratoire"]
    $usedRecommendedTechniques = $TechniquesUsed | Where-Object { $recommendedTechniques -contains $_ }
    $techniquesCoveragePercentage = if ($recommendedTechniques.Count -gt 0) {
        [Math]::Round(($usedRecommendedTechniques.Count / $recommendedTechniques.Count) * 100, 2)
    } else {
        0
    }

    $techniquesCoverageCategory = if ($techniquesCoveragePercentage -lt 25) {
        "Insuffisant"
    } elseif ($techniquesCoveragePercentage -lt 50) {
        "Minimal"
    } elseif ($techniquesCoveragePercentage -lt 75) {
        "Acceptable"
    } else {
        "Complet"
    }

    # Evaluer l'impact des valeurs aberrantes
    $outlierImpactCategory = if ($OutlierPercentage -gt 15) {
        "Severe"
    } elseif ($OutlierPercentage -gt 10) {
        "Eleve"
    } elseif ($OutlierPercentage -gt 5) {
        "Modere"
    } elseif ($OutlierPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Evaluer l'impact des donnees manquantes
    $missingDataImpactCategory = if ($MissingDataPercentage -gt 20) {
        "Severe"
    } elseif ($MissingDataPercentage -gt 10) {
        "Eleve"
    } elseif ($MissingDataPercentage -gt 5) {
        "Modere"
    } elseif ($MissingDataPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Calculer un score global de qualite (0-100)
    $sampleSizeScore = switch ($sampleSizeCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 25 }
        "Acceptable" { 50 }
        "Recommande" { 75 }
        "Optimal" { 100 }
        default { 0 }
    }

    $techniquesCoverageScore = switch ($techniquesCoverageCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 33 }
        "Acceptable" { 67 }
        "Complet" { 100 }
        default { 0 }
    }

    $outlierImpactScore = switch ($outlierImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    $missingDataImpactScore = switch ($missingDataImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    # Ponderation des scores
    $overallQualityScore = [Math]::Round(
        ($sampleSizeScore * 0.4) +
        ($techniquesCoverageScore * 0.3) +
        ($outlierImpactScore * 0.15) +
        ($missingDataImpactScore * 0.15),
        2
    )

    # Determiner le niveau global de qualite
    $overallQualityCategory = if ($overallQualityScore -ge 90) {
        "Excellent"
    } elseif ($overallQualityScore -ge 75) {
        "Bon"
    } elseif ($overallQualityScore -ge 60) {
        "Acceptable"
    } elseif ($overallQualityScore -ge 40) {
        "Limite"
    } else {
        "Insuffisant"
    }

    # Generer des recommandations
    $recommendations = @()

    if ($sampleSizeCategory -eq "Insuffisant") {
        $recommendations += "La taille d'echantillon est insuffisante pour une analyse exploratoire fiable."
        $recommendations += "Augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse exploratoire"]["Minimal"]) observations."
    } elseif ($sampleSizeCategory -in @("Minimal", "Acceptable")) {
        $recommendations += "Envisager d'augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse exploratoire"]["Recommande"]) observations pour des resultats plus fiables."
    }

    if ($techniquesCoverageCategory -in @("Insuffisant", "Minimal")) {
        $missingTechniques = $recommendedTechniques | Where-Object { $TechniquesUsed -notcontains $_ }
        $recommendations += "La couverture des techniques recommandees est insuffisante."
        $recommendations += "Envisager d'inclure les techniques suivantes: $($missingTechniques -join ', ')."
    }

    if ($outlierImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de valeurs aberrantes ($OutlierPercentage%) peut affecter la fiabilite des resultats."
        $recommendations += "Identifier et analyser les valeurs aberrantes avant de tirer des conclusions."
    }

    if ($missingDataImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de donnees manquantes ($MissingDataPercentage%) peut biaiser les resultats."
        $recommendations += "Analyser le pattern des donnees manquantes et envisager des techniques d'imputation appropriees."
    }

    if ($DataDistribution -ne "Normale" -and $DataDistribution -ne "Inconnue") {
        $recommendations += "La distribution des donnees ($DataDistribution) peut necessiter des techniques d'analyse specifiques."

        if ($DataDistribution -eq "Asymetrique") {
            $recommendations += "Envisager des transformations (log, racine carree) ou des methodes non-parametriques."
        } elseif ($DataDistribution -eq "Multimodale") {
            $recommendations += "Envisager une analyse par clusters ou une decomposition en sous-populations."
        } elseif ($DataDistribution -eq "Queue lourde") {
            $recommendations += "Utiliser des statistiques robustes aux valeurs extremes."
        }
    }

    # Retourner les resultats
    return @{
        AnalysisType                 = "Analyse exploratoire"
        SampleSize                   = $SampleSize
        SampleSizeCategory           = $sampleSizeCategory
        IsSampleSizeSufficient       = $isSampleSizeSufficient
        DataDistribution             = $DataDistribution
        OutlierPercentage            = $OutlierPercentage
        OutlierImpactCategory        = $outlierImpactCategory
        MissingDataPercentage        = $MissingDataPercentage
        MissingDataImpactCategory    = $missingDataImpactCategory
        TechniquesUsed               = $TechniquesUsed
        RecommendedTechniques        = $recommendedTechniques
        TechniquesCoveragePercentage = $techniquesCoveragePercentage
        TechniquesCoverageCategory   = $techniquesCoverageCategory
        SampleSizeScore              = $sampleSizeScore
        TechniquesCoverageScore      = $techniquesCoverageScore
        OutlierImpactScore           = $outlierImpactScore
        MissingDataImpactScore       = $missingDataImpactScore
        OverallQualityScore          = $overallQualityScore
        OverallQualityCategory       = $overallQualityCategory
        Recommendations              = $recommendations
    }
}

#endregion

<#
.SYNOPSIS
    Etablit les criteres de qualite pour l'analyse confirmatoire.

.DESCRIPTION
    Cette fonction definit et evalue les criteres de qualite specifiques a l'analyse
    confirmatoire, notamment en termes de taille d'echantillon, puissance statistique,
    controle des erreurs, et techniques recommandees.

.PARAMETER SampleSize
    La taille de l'echantillon utilise ou prevu.

.PARAMETER Power
    La puissance statistique souhaitee ou calculee (entre 0 et 1).

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par defaut 0.05).

.PARAMETER EffectSize
    La taille d'effet attendue ou observee (Cohen's d).

.PARAMETER DataDistribution
    Le type de distribution des donnees (par defaut "Inconnue").

.PARAMETER VarianceHomogeneity
    Le niveau d'homogeneite des variances (pour les tests de comparaison).

.PARAMETER OutlierPercentage
    Le pourcentage de valeurs aberrantes dans les donnees (par defaut 0).

.PARAMETER MissingDataPercentage
    Le pourcentage de donnees manquantes (par defaut 0).

.PARAMETER TechniquesUsed
    Les techniques d'analyse utilisees ou prevues.

.EXAMPLE
    Get-ConfirmatoryAnalysisQualityCriteria -SampleSize 100 -Power 0.8 -Alpha 0.05 -EffectSize 0.5 -DataDistribution "Normale" -VarianceHomogeneity "Elevee" -OutlierPercentage 2 -MissingDataPercentage 5 -TechniquesUsed @("Tests d'hypotheses", "ANOVA")
    Evalue les criteres de qualite pour une analyse confirmatoire avec un echantillon de 100 sujets.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ConfirmatoryAnalysisQualityCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Power,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 0.5)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0.01, 5)]
        [double]$EffectSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Asymetrique", "Multimodale", "Queue lourde", "Mixte", "Inconnue")]
        [string]$DataDistribution = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Tres elevee", "Elevee", "Moderee", "Faible", "Tres faible", "Inconnue")]
        [string]$VarianceHomogeneity = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$OutlierPercentage = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$MissingDataPercentage = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$TechniquesUsed = @()
    )

    # Evaluer la taille d'echantillon
    $sampleSizeCategory = if ($SampleSize -lt $script:SampleSizeThresholds["Analyse confirmatoire"]["Minimal"]) {
        "Insuffisant"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse confirmatoire"]["Acceptable"]) {
        "Minimal"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse confirmatoire"]["Recommande"]) {
        "Acceptable"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse confirmatoire"]["Optimal"]) {
        "Recommande"
    } else {
        "Optimal"
    }

    $isSampleSizeSufficient = $sampleSizeCategory -ne "Insuffisant"

    # Evaluer la puissance statistique
    $recommendedPower = $script:PowerThresholds["Analyse confirmatoire"]
    $isPowerSufficient = $Power -ge $recommendedPower

    $powerCategory = if ($Power -lt 0.5) {
        "Tres faible"
    } elseif ($Power -lt 0.7) {
        "Faible"
    } elseif ($Power -lt $recommendedPower) {
        "Moderee"
    } elseif ($Power -lt 0.9) {
        "Adequate"
    } else {
        "Elevee"
    }

    # Evaluer le niveau de signification (alpha)
    $recommendedAlpha = $script:AlphaThresholds["Analyse confirmatoire"]
    $isAlphaAppropriate = $Alpha -le $recommendedAlpha

    $alphaCategory = if ($Alpha -gt 0.1) {
        "Trop eleve"
    } elseif ($Alpha -gt $recommendedAlpha) {
        "Eleve"
    } elseif ($Alpha -eq $recommendedAlpha) {
        "Standard"
    } elseif ($Alpha -ge 0.01) {
        "Conservateur"
    } else {
        "Tres conservateur"
    }

    # Evaluer la taille d'effet
    $effectSizeCategory = if ($EffectSize -lt 0.2) {
        "Tres petit"
    } elseif ($EffectSize -lt 0.5) {
        "Petit"
    } elseif ($EffectSize -lt 0.8) {
        "Moyen"
    } elseif ($EffectSize -lt 1.2) {
        "Grand"
    } else {
        "Tres grand"
    }

    # Evaluer la couverture des techniques recommandees
    $recommendedTechniques = $script:RecommendedTechniques["Analyse confirmatoire"]
    $usedRecommendedTechniques = $TechniquesUsed | Where-Object { $recommendedTechniques -contains $_ }
    $techniquesCoveragePercentage = if ($recommendedTechniques.Count -gt 0) {
        [Math]::Round(($usedRecommendedTechniques.Count / $recommendedTechniques.Count) * 100, 2)
    } else {
        0
    }

    $techniquesCoverageCategory = if ($techniquesCoveragePercentage -lt 25) {
        "Insuffisant"
    } elseif ($techniquesCoveragePercentage -lt 50) {
        "Minimal"
    } elseif ($techniquesCoveragePercentage -lt 75) {
        "Acceptable"
    } else {
        "Complet"
    }

    # Evaluer l'impact des valeurs aberrantes
    $outlierImpactCategory = if ($OutlierPercentage -gt 15) {
        "Severe"
    } elseif ($OutlierPercentage -gt 10) {
        "Eleve"
    } elseif ($OutlierPercentage -gt 5) {
        "Modere"
    } elseif ($OutlierPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Evaluer l'impact des donnees manquantes
    $missingDataImpactCategory = if ($MissingDataPercentage -gt 20) {
        "Severe"
    } elseif ($MissingDataPercentage -gt 10) {
        "Eleve"
    } elseif ($MissingDataPercentage -gt 5) {
        "Modere"
    } elseif ($MissingDataPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Evaluer l'adequation des hypotheses statistiques
    $normalityRequirement = $script:NormalityRequirements["Analyse confirmatoire"]
    $isNormalityAdequate = if ($DataDistribution -eq "Normale" -or $DataDistribution -eq "Inconnue") {
        $true
    } else {
        $false
    }

    $varianceHomogeneityRequirement = $script:VarianceHomogeneityRequirements["Analyse confirmatoire"]
    $isVarianceHomogeneityAdequate = if ($VarianceHomogeneity -in @("Tres elevee", "Elevee", "Moderee", "Inconnue")) {
        $true
    } else {
        $false
    }

    # Calculer un score global de qualite (0-100)
    $sampleSizeScore = switch ($sampleSizeCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 25 }
        "Acceptable" { 50 }
        "Recommande" { 75 }
        "Optimal" { 100 }
        default { 0 }
    }

    $powerScore = if ($isPowerSufficient) {
        [Math]::Min(100, [Math]::Round($Power / $recommendedPower * 100, 0))
    } else {
        [Math]::Max(0, [Math]::Round($Power / $recommendedPower * 80, 0))
    }

    $alphaScore = if ($isAlphaAppropriate) {
        100
    } else {
        [Math]::Max(0, [Math]::Round(($recommendedAlpha / $Alpha) * 80, 0))
    }

    $techniquesCoverageScore = switch ($techniquesCoverageCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 33 }
        "Acceptable" { 67 }
        "Complet" { 100 }
        default { 0 }
    }

    $outlierImpactScore = switch ($outlierImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    $missingDataImpactScore = switch ($missingDataImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    $hypothesesScore = 0
    if ($isNormalityAdequate) { $hypothesesScore += 50 }
    if ($isVarianceHomogeneityAdequate) { $hypothesesScore += 50 }
    $hypothesesScore = [Math]::Min(100, $hypothesesScore)

    # Ponderation des scores
    $overallQualityScore = [Math]::Round(
        ($sampleSizeScore * 0.2) +
        ($powerScore * 0.2) +
        ($alphaScore * 0.1) +
        ($techniquesCoverageScore * 0.15) +
        ($outlierImpactScore * 0.1) +
        ($missingDataImpactScore * 0.1) +
        ($hypothesesScore * 0.15),
        2
    )

    # Determiner le niveau global de qualite
    $overallQualityCategory = if ($overallQualityScore -ge 90) {
        "Excellent"
    } elseif ($overallQualityScore -ge 75) {
        "Bon"
    } elseif ($overallQualityScore -ge 60) {
        "Acceptable"
    } elseif ($overallQualityScore -ge 40) {
        "Limite"
    } else {
        "Insuffisant"
    }

    # Generer des recommandations
    $recommendations = @()

    if ($sampleSizeCategory -eq "Insuffisant") {
        $recommendations += "La taille d'echantillon est insuffisante pour une analyse confirmatoire fiable."
        $recommendations += "Augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse confirmatoire"]["Minimal"]) observations."
    } elseif ($sampleSizeCategory -in @("Minimal", "Acceptable")) {
        $recommendations += "Envisager d'augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse confirmatoire"]["Recommande"]) observations pour des resultats plus fiables."
    }

    if (-not $isPowerSufficient) {
        $recommendations += "La puissance statistique ($([Math]::Round($Power, 2))) est inferieure au seuil recommande ($recommendedPower) pour l'analyse confirmatoire."
        $recommendations += "Augmenter la taille de l'echantillon ou reduire la variabilite pour ameliorer la puissance."
    }

    if (-not $isAlphaAppropriate) {
        $recommendations += "Le niveau de signification (alpha = $Alpha) est superieur au seuil recommande ($recommendedAlpha) pour l'analyse confirmatoire."
        $recommendations += "Envisager de reduire alpha a $recommendedAlpha pour limiter le risque d'erreur de type I."
    }

    if ($techniquesCoverageCategory -in @("Insuffisant", "Minimal")) {
        $missingTechniques = $recommendedTechniques | Where-Object { $TechniquesUsed -notcontains $_ }
        $recommendations += "La couverture des techniques recommandees est insuffisante."
        $recommendations += "Envisager d'inclure les techniques suivantes: $($missingTechniques -join ', ')."
    }

    if ($outlierImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de valeurs aberrantes ($OutlierPercentage%) peut affecter la fiabilite des resultats."
        $recommendations += "Traiter les valeurs aberrantes avant l'analyse (elimination, transformation ou modelisation)."
    }

    if ($missingDataImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de donnees manquantes ($MissingDataPercentage%) peut biaiser les resultats."
        $recommendations += "Utiliser des techniques d'imputation appropriees (MICE, maximum de vraisemblance)."
    }

    if (-not $isNormalityAdequate) {
        $recommendations += "La distribution des donnees ($DataDistribution) ne respecte pas l'hypothese de normalite requise pour certains tests parametriques."

        if ($DataDistribution -eq "Asymetrique") {
            $recommendations += "Envisager des transformations (log, racine carree) ou des tests non-parametriques."
        } elseif ($DataDistribution -eq "Multimodale") {
            $recommendations += "Verifier si les donnees contiennent des sous-populations distinctes avant l'analyse."
        } elseif ($DataDistribution -eq "Queue lourde") {
            $recommendations += "Utiliser des tests robustes ou des methodes non-parametriques."
        }
    }

    if (-not $isVarianceHomogeneityAdequate) {
        $recommendations += "L'homogeneite des variances ($VarianceHomogeneity) est insuffisante pour certains tests parametriques."
        $recommendations += "Envisager des tests avec correction pour variances inegales ou des tests non-parametriques."
    }

    # Retourner les resultats
    return @{
        AnalysisType                  = "Analyse confirmatoire"
        SampleSize                    = $SampleSize
        SampleSizeCategory            = $sampleSizeCategory
        IsSampleSizeSufficient        = $isSampleSizeSufficient
        Power                         = $Power
        PowerCategory                 = $powerCategory
        RecommendedPower              = $recommendedPower
        IsPowerSufficient             = $isPowerSufficient
        Alpha                         = $Alpha
        AlphaCategory                 = $alphaCategory
        RecommendedAlpha              = $recommendedAlpha
        IsAlphaAppropriate            = $isAlphaAppropriate
        EffectSize                    = $EffectSize
        EffectSizeCategory            = $effectSizeCategory
        DataDistribution              = $DataDistribution
        IsNormalityAdequate           = $isNormalityAdequate
        VarianceHomogeneity           = $VarianceHomogeneity
        IsVarianceHomogeneityAdequate = $isVarianceHomogeneityAdequate
        OutlierPercentage             = $OutlierPercentage
        OutlierImpactCategory         = $outlierImpactCategory
        MissingDataPercentage         = $MissingDataPercentage
        MissingDataImpactCategory     = $missingDataImpactCategory
        TechniquesUsed                = $TechniquesUsed
        RecommendedTechniques         = $recommendedTechniques
        TechniquesCoveragePercentage  = $techniquesCoveragePercentage
        TechniquesCoverageCategory    = $techniquesCoverageCategory
        SampleSizeScore               = $sampleSizeScore
        PowerScore                    = $powerScore
        AlphaScore                    = $alphaScore
        TechniquesCoverageScore       = $techniquesCoverageScore
        OutlierImpactScore            = $outlierImpactScore
        MissingDataImpactScore        = $missingDataImpactScore
        HypothesesScore               = $hypothesesScore
        OverallQualityScore           = $overallQualityScore
        OverallQualityCategory        = $overallQualityCategory
        Recommendations               = $recommendations
    }
}

<#
.SYNOPSIS
    Definit les criteres de qualite pour l'analyse predictive.

.DESCRIPTION
    Cette fonction definit et evalue les criteres de qualite specifiques a l'analyse
    predictive, notamment en termes de taille d'echantillon, validation croisee,
    metriques d'evaluation, et techniques recommandees.

.PARAMETER SampleSize
    La taille de l'echantillon utilise ou prevu.

.PARAMETER ValidationMethod
    La methode de validation utilisee (par defaut "Aucune").

.PARAMETER NumberOfFolds
    Le nombre de plis pour la validation croisee (par defaut 0).

.PARAMETER TestSetPercentage
    Le pourcentage de donnees reservees pour le test (par defaut 0).

.PARAMETER FeatureCount
    Le nombre de caracteristiques (variables predictives) utilisees.

.PARAMETER OutlierPercentage
    Le pourcentage de valeurs aberrantes dans les donnees (par defaut 0).

.PARAMETER MissingDataPercentage
    Le pourcentage de donnees manquantes (par defaut 0).

.PARAMETER TechniquesUsed
    Les techniques d'analyse utilisees ou prevues.

.PARAMETER EvaluationMetricsUsed
    Les metriques d'evaluation utilisees pour mesurer la performance du modele.

.EXAMPLE
    Get-PredictiveAnalysisQualityCriteria -SampleSize 500 -ValidationMethod "Validation croisee" -NumberOfFolds 5 -FeatureCount 10 -OutlierPercentage 2 -MissingDataPercentage 5 -TechniquesUsed @("Regression lineaire", "Forets aleatoires") -EvaluationMetricsUsed @("R²", "RMSE", "MAE")
    Evalue les criteres de qualite pour une analyse predictive avec un echantillon de 500 observations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-PredictiveAnalysisQualityCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucune", "Train-test split", "Validation croisee", "Leave-one-out", "Bootstrap")]
        [string]$ValidationMethod = "Aucune",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$NumberOfFolds = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 90)]
        [double]$TestSetPercentage = 0,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$FeatureCount,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$OutlierPercentage = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$MissingDataPercentage = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$TechniquesUsed = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$EvaluationMetricsUsed = @()
    )

    # Evaluer la taille d'echantillon
    $sampleSizeCategory = if ($SampleSize -lt $script:SampleSizeThresholds["Analyse predictive"]["Minimal"]) {
        "Insuffisant"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse predictive"]["Acceptable"]) {
        "Minimal"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse predictive"]["Recommande"]) {
        "Acceptable"
    } elseif ($SampleSize -lt $script:SampleSizeThresholds["Analyse predictive"]["Optimal"]) {
        "Recommande"
    } else {
        "Optimal"
    }

    $isSampleSizeSufficient = $sampleSizeCategory -ne "Insuffisant"

    # Evaluer le ratio observations/caracteristiques
    $observationToFeatureRatio = if ($FeatureCount -gt 0) {
        $SampleSize / $FeatureCount
    } else {
        [double]::PositiveInfinity
    }

    $observationToFeatureRatioCategory = if ($observationToFeatureRatio -lt 5) {
        "Critique"
    } elseif ($observationToFeatureRatio -lt 10) {
        "Insuffisant"
    } elseif ($observationToFeatureRatio -lt 20) {
        "Acceptable"
    } elseif ($observationToFeatureRatio -lt 50) {
        "Bon"
    } else {
        "Excellent"
    }

    $isObservationToFeatureRatioSufficient = $observationToFeatureRatioCategory -ne "Critique" -and $observationToFeatureRatioCategory -ne "Insuffisant"

    # Evaluer la methode de validation
    $validationMethodCategory = switch ($ValidationMethod) {
        "Aucune" { "Insuffisant" }
        "Train-test split" { "Minimal" }
        "Validation croisee" { "Recommande" }
        "Leave-one-out" { "Acceptable" }
        "Bootstrap" { "Recommande" }
        default { "Insuffisant" }
    }

    $isValidationMethodSufficient = $validationMethodCategory -ne "Insuffisant"

    # Evaluer la configuration de la validation
    $validationConfigurationCategory = "Non applicable"
    $isValidationConfigurationSufficient = $false

    if ($ValidationMethod -eq "Validation croisee") {
        $validationConfigurationCategory = if ($NumberOfFolds -lt 3) {
            "Insuffisant"
        } elseif ($NumberOfFolds -lt 5) {
            "Minimal"
        } elseif ($NumberOfFolds -lt 10) {
            "Recommande"
        } else {
            "Optimal"
        }
        $isValidationConfigurationSufficient = $validationConfigurationCategory -ne "Insuffisant"
    } elseif ($ValidationMethod -eq "Train-test split") {
        $validationConfigurationCategory = if ($TestSetPercentage -lt 10) {
            "Insuffisant"
        } elseif ($TestSetPercentage -lt 20) {
            "Minimal"
        } elseif ($TestSetPercentage -lt 30) {
            "Recommande"
        } else {
            "Optimal"
        }
        $isValidationConfigurationSufficient = $validationConfigurationCategory -ne "Insuffisant"
    } elseif ($ValidationMethod -eq "Bootstrap") {
        $validationConfigurationCategory = "Acceptable"
        $isValidationConfigurationSufficient = $true
    } elseif ($ValidationMethod -eq "Leave-one-out") {
        $validationConfigurationCategory = "Acceptable"
        $isValidationConfigurationSufficient = $true
    }

    # Evaluer la couverture des techniques recommandees
    $recommendedTechniques = $script:RecommendedTechniques["Analyse predictive"]
    $usedRecommendedTechniques = $TechniquesUsed | Where-Object { $recommendedTechniques -contains $_ }
    $techniquesCoveragePercentage = if ($recommendedTechniques.Count -gt 0) {
        [Math]::Round(($usedRecommendedTechniques.Count / $recommendedTechniques.Count) * 100, 2)
    } else {
        0
    }

    $techniquesCoverageCategory = if ($techniquesCoveragePercentage -lt 25) {
        "Insuffisant"
    } elseif ($techniquesCoveragePercentage -lt 50) {
        "Minimal"
    } elseif ($techniquesCoveragePercentage -lt 75) {
        "Acceptable"
    } else {
        "Complet"
    }

    # Evaluer la couverture des metriques d'evaluation
    $recommendedEvaluationMetrics = $script:EvaluationMetrics["Analyse predictive"]
    $usedRecommendedEvaluationMetrics = $EvaluationMetricsUsed | Where-Object { $recommendedEvaluationMetrics -contains $_ }
    $evaluationMetricsCoveragePercentage = if ($recommendedEvaluationMetrics.Count -gt 0) {
        [Math]::Round(($usedRecommendedEvaluationMetrics.Count / $recommendedEvaluationMetrics.Count) * 100, 2)
    } else {
        0
    }

    $evaluationMetricsCoverageCategory = if ($evaluationMetricsCoveragePercentage -lt 25) {
        "Insuffisant"
    } elseif ($evaluationMetricsCoveragePercentage -lt 50) {
        "Minimal"
    } elseif ($evaluationMetricsCoveragePercentage -lt 75) {
        "Acceptable"
    } else {
        "Complet"
    }

    # Evaluer l'impact des valeurs aberrantes
    $outlierImpactCategory = if ($OutlierPercentage -gt 15) {
        "Severe"
    } elseif ($OutlierPercentage -gt 10) {
        "Eleve"
    } elseif ($OutlierPercentage -gt 5) {
        "Modere"
    } elseif ($OutlierPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Evaluer l'impact des donnees manquantes
    $missingDataImpactCategory = if ($MissingDataPercentage -gt 20) {
        "Severe"
    } elseif ($MissingDataPercentage -gt 10) {
        "Eleve"
    } elseif ($MissingDataPercentage -gt 5) {
        "Modere"
    } elseif ($MissingDataPercentage -gt 0) {
        "Faible"
    } else {
        "Aucun"
    }

    # Calculer un score global de qualite (0-100)
    $sampleSizeScore = switch ($sampleSizeCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 25 }
        "Acceptable" { 50 }
        "Recommande" { 75 }
        "Optimal" { 100 }
        default { 0 }
    }

    $observationToFeatureRatioScore = switch ($observationToFeatureRatioCategory) {
        "Critique" { 0 }
        "Insuffisant" { 25 }
        "Acceptable" { 50 }
        "Bon" { 75 }
        "Excellent" { 100 }
        default { 0 }
    }

    $validationMethodScore = switch ($validationMethodCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 25 }
        "Acceptable" { 50 }
        "Recommande" { 75 }
        "Optimal" { 100 }
        default { 0 }
    }

    $validationConfigurationScore = switch ($validationConfigurationCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 25 }
        "Acceptable" { 50 }
        "Recommande" { 75 }
        "Optimal" { 100 }
        "Non applicable" { 0 }
        default { 0 }
    }

    $techniquesCoverageScore = switch ($techniquesCoverageCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 33 }
        "Acceptable" { 67 }
        "Complet" { 100 }
        default { 0 }
    }

    $evaluationMetricsCoverageScore = switch ($evaluationMetricsCoverageCategory) {
        "Insuffisant" { 0 }
        "Minimal" { 33 }
        "Acceptable" { 67 }
        "Complet" { 100 }
        default { 0 }
    }

    $outlierImpactScore = switch ($outlierImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    $missingDataImpactScore = switch ($missingDataImpactCategory) {
        "Severe" { 0 }
        "Eleve" { 25 }
        "Modere" { 50 }
        "Faible" { 75 }
        "Aucun" { 100 }
        default { 0 }
    }

    # Ponderation des scores
    $overallQualityScore = [Math]::Round(
        ($sampleSizeScore * 0.15) +
        ($observationToFeatureRatioScore * 0.15) +
        ($validationMethodScore * 0.15) +
        ($validationConfigurationScore * 0.1) +
        ($techniquesCoverageScore * 0.1) +
        ($evaluationMetricsCoverageScore * 0.1) +
        ($outlierImpactScore * 0.125) +
        ($missingDataImpactScore * 0.125),
        2
    )

    # Determiner le niveau global de qualite
    $overallQualityCategory = if ($overallQualityScore -ge 90) {
        "Excellent"
    } elseif ($overallQualityScore -ge 75) {
        "Bon"
    } elseif ($overallQualityScore -ge 60) {
        "Acceptable"
    } elseif ($overallQualityScore -ge 40) {
        "Limite"
    } else {
        "Insuffisant"
    }

    # Generer des recommandations
    $recommendations = @()

    if ($sampleSizeCategory -eq "Insuffisant") {
        $recommendations += "La taille d'echantillon est insuffisante pour une analyse predictive fiable."
        $recommendations += "Augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse predictive"]["Minimal"]) observations."
    } elseif ($sampleSizeCategory -in @("Minimal", "Acceptable")) {
        $recommendations += "Envisager d'augmenter la taille d'echantillon a au moins $($script:SampleSizeThresholds["Analyse predictive"]["Recommande"]) observations pour des resultats plus fiables."
    }

    if (-not $isObservationToFeatureRatioSufficient) {
        $recommendations += "Le ratio observations/caracteristiques ($([Math]::Round($observationToFeatureRatio, 2))) est insuffisant."
        $recommendations += "Augmenter la taille de l'echantillon ou reduire le nombre de caracteristiques pour atteindre un ratio d'au moins 10:1."
    }

    if (-not $isValidationMethodSufficient) {
        $recommendations += "Aucune methode de validation n'est utilisee, ce qui est insuffisant pour une analyse predictive fiable."
        $recommendations += "Implementer une methode de validation croisee ou au minimum un train-test split."
    } elseif ($ValidationMethod -eq "Train-test split" -and -not $isValidationConfigurationSufficient) {
        $recommendations += "Le pourcentage de donnees de test ($TestSetPercentage%) est insuffisant."
        $recommendations += "Augmenter le pourcentage a au moins 20% pour une evaluation plus fiable."
    } elseif ($ValidationMethod -eq "Validation croisee" -and -not $isValidationConfigurationSufficient) {
        $recommendations += "Le nombre de plis ($NumberOfFolds) est insuffisant pour la validation croisee."
        $recommendations += "Utiliser au moins 5 plis pour une evaluation plus fiable."
    }

    if ($techniquesCoverageCategory -in @("Insuffisant", "Minimal")) {
        $missingTechniques = $recommendedTechniques | Where-Object { $TechniquesUsed -notcontains $_ }
        $recommendations += "La couverture des techniques recommandees est insuffisante."
        $recommendations += "Envisager d'inclure les techniques suivantes: $($missingTechniques -join ', ')."
    }

    if ($evaluationMetricsCoverageCategory -in @("Insuffisant", "Minimal")) {
        $missingMetrics = $recommendedEvaluationMetrics | Where-Object { $EvaluationMetricsUsed -notcontains $_ }
        $recommendations += "La couverture des metriques d'evaluation est insuffisante."
        $recommendations += "Envisager d'inclure les metriques suivantes: $($missingMetrics -join ', ')."
    }

    if ($outlierImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de valeurs aberrantes ($OutlierPercentage%) peut affecter la fiabilite des resultats."
        $recommendations += "Traiter les valeurs aberrantes avant l'analyse (elimination, transformation ou modelisation robuste)."
    }

    if ($missingDataImpactCategory -in @("Modere", "Eleve", "Severe")) {
        $recommendations += "Le pourcentage de donnees manquantes ($MissingDataPercentage%) peut biaiser les resultats."
        $recommendations += "Utiliser des techniques d'imputation multiple ou des modeles tolerants aux donnees manquantes."
    }

    # Retourner les resultats
    return @{
        AnalysisType                          = "Analyse predictive"
        SampleSize                            = $SampleSize
        SampleSizeCategory                    = $sampleSizeCategory
        IsSampleSizeSufficient                = $isSampleSizeSufficient
        FeatureCount                          = $FeatureCount
        ObservationToFeatureRatio             = $observationToFeatureRatio
        ObservationToFeatureRatioCategory     = $observationToFeatureRatioCategory
        IsObservationToFeatureRatioSufficient = $isObservationToFeatureRatioSufficient
        ValidationMethod                      = $ValidationMethod
        ValidationMethodCategory              = $validationMethodCategory
        IsValidationMethodSufficient          = $isValidationMethodSufficient
        ValidationConfigurationCategory       = $validationConfigurationCategory
        IsValidationConfigurationSufficient   = $isValidationConfigurationSufficient
        NumberOfFolds                         = $NumberOfFolds
        TestSetPercentage                     = $TestSetPercentage
        OutlierPercentage                     = $OutlierPercentage
        OutlierImpactCategory                 = $outlierImpactCategory
        MissingDataPercentage                 = $MissingDataPercentage
        MissingDataImpactCategory             = $missingDataImpactCategory
        TechniquesUsed                        = $TechniquesUsed
        RecommendedTechniques                 = $recommendedTechniques
        TechniquesCoveragePercentage          = $techniquesCoveragePercentage
        TechniquesCoverageCategory            = $techniquesCoverageCategory
        EvaluationMetricsUsed                 = $EvaluationMetricsUsed
        RecommendedEvaluationMetrics          = $recommendedEvaluationMetrics
        EvaluationMetricsCoveragePercentage   = $evaluationMetricsCoveragePercentage
        EvaluationMetricsCoverageCategory     = $evaluationMetricsCoverageCategory
        SampleSizeScore                       = $sampleSizeScore
        ObservationToFeatureRatioScore        = $observationToFeatureRatioScore
        ValidationMethodScore                 = $validationMethodScore
        ValidationConfigurationScore          = $validationConfigurationScore
        TechniquesCoverageScore               = $techniquesCoverageScore
        EvaluationMetricsCoverageScore        = $evaluationMetricsCoverageScore
        OutlierImpactScore                    = $outlierImpactScore
        MissingDataImpactScore                = $missingDataImpactScore
        OverallQualityScore                   = $overallQualityScore
        OverallQualityCategory                = $overallQualityCategory
        Recommendations                       = $recommendations
    }
}

<#
.SYNOPSIS
    Cree un tableau comparatif des criteres de qualite par domaine d'application.

.DESCRIPTION
    Cette fonction genere un tableau comparatif des criteres de qualite pour differents
    types d'analyses statistiques (exploratoire, confirmatoire, predictive), permettant
    une comparaison directe des exigences et recommandations.

.PARAMETER Format
    Le format de sortie du tableau (par defaut "Text").

.PARAMETER IncludeDetails
    Indique si des details supplementaires doivent etre inclus dans le tableau (par defaut $false).

.EXAMPLE
    Get-AnalysisQualityCriteriaComparison -Format "Text" -IncludeDetails $false
    Genere un tableau comparatif des criteres de qualite au format texte.

.OUTPUTS
    System.String
#>
function Get-AnalysisQualityCriteriaComparison {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "HTML", "JSON")]
        [string]$Format = "Text",

        [Parameter(Mandatory = $false)]
        [bool]$IncludeDetails = $false
    )

    # Definir les categories de criteres
    $criteriaCategories = @(
        "Taille d'echantillon",
        "Puissance statistique",
        "Niveau de signification (alpha)",
        "Distribution des donnees",
        "Homogeneite des variances",
        "Valeurs aberrantes",
        "Donnees manquantes",
        "Techniques recommandees",
        "Metriques d'evaluation"
    )

    # Definir les types d'analyses
    $analysisTypes = @(
        "Analyse exploratoire",
        "Analyse confirmatoire",
        "Analyse predictive"
    )

    # Creer la structure du tableau comparatif
    $comparisonTable = @{}

    # Remplir le tableau avec les criteres de taille d'echantillon
    $comparisonTable["Taille d'echantillon"] = @{
        "Analyse exploratoire"  = @{
            "Minimal"     = $script:SampleSizeThresholds["Analyse exploratoire"]["Minimal"]
            "Acceptable"  = $script:SampleSizeThresholds["Analyse exploratoire"]["Acceptable"]
            "Recommande"  = $script:SampleSizeThresholds["Analyse exploratoire"]["Recommande"]
            "Optimal"     = $script:SampleSizeThresholds["Analyse exploratoire"]["Optimal"]
            "Description" = "Taille d'echantillon necessaire pour identifier les patterns et tendances dans les donnees."
        }
        "Analyse confirmatoire" = @{
            "Minimal"     = $script:SampleSizeThresholds["Analyse confirmatoire"]["Minimal"]
            "Acceptable"  = $script:SampleSizeThresholds["Analyse confirmatoire"]["Acceptable"]
            "Recommande"  = $script:SampleSizeThresholds["Analyse confirmatoire"]["Recommande"]
            "Optimal"     = $script:SampleSizeThresholds["Analyse confirmatoire"]["Optimal"]
            "Description" = "Taille d'echantillon necessaire pour tester des hypotheses avec une puissance statistique adequate."
        }
        "Analyse predictive"    = @{
            "Minimal"     = $script:SampleSizeThresholds["Analyse predictive"]["Minimal"]
            "Acceptable"  = $script:SampleSizeThresholds["Analyse predictive"]["Acceptable"]
            "Recommande"  = $script:SampleSizeThresholds["Analyse predictive"]["Recommande"]
            "Optimal"     = $script:SampleSizeThresholds["Analyse predictive"]["Optimal"]
            "Description" = "Taille d'echantillon necessaire pour construire et valider des modeles predictifs robustes."
        }
    }

    # Remplir le tableau avec les criteres de puissance statistique
    $comparisonTable["Puissance statistique"] = @{
        "Analyse exploratoire"  = @{
            "Valeur"      = $script:PowerThresholds["Analyse exploratoire"]
            "Description" = "Moins critique pour l'analyse exploratoire, mais utile pour planifier des etudes confirmatoires ulterieures."
        }
        "Analyse confirmatoire" = @{
            "Valeur"      = $script:PowerThresholds["Analyse confirmatoire"]
            "Description" = "Essentielle pour garantir la capacite a detecter des effets reels lorsqu'ils existent."
        }
        "Analyse predictive"    = @{
            "Valeur"      = $script:PowerThresholds["Analyse predictive"]
            "Description" = "Importante pour les tests statistiques utilises dans l'evaluation des modeles."
        }
    }

    # Remplir le tableau avec les criteres de niveau de signification
    $comparisonTable["Niveau de signification (alpha)"] = @{
        "Analyse exploratoire"  = @{
            "Valeur"      = $script:AlphaThresholds["Analyse exploratoire"]
            "Description" = "Peut etre plus permissif pour encourager l'exploration et la generation d'hypotheses."
        }
        "Analyse confirmatoire" = @{
            "Valeur"      = $script:AlphaThresholds["Analyse confirmatoire"]
            "Description" = "Standard pour equilibrer les risques d'erreurs de type I et II."
        }
        "Analyse predictive"    = @{
            "Valeur"      = $script:AlphaThresholds["Analyse predictive"]
            "Description" = "Plus conservateur pour minimiser les faux positifs dans les modeles."
        }
    }

    # Remplir le tableau avec les criteres de distribution des donnees
    $comparisonTable["Distribution des donnees"] = @{
        "Analyse exploratoire"  = @{
            "Exigence"    = $script:NormalityRequirements["Analyse exploratoire"]
            "Description" = "Peu d'exigences formelles; l'objectif est de comprendre la distribution reelle des donnees."
        }
        "Analyse confirmatoire" = @{
            "Exigence"    = $script:NormalityRequirements["Analyse confirmatoire"]
            "Description" = "Importante pour les tests parametriques; des transformations ou des tests non-parametriques peuvent etre necessaires."
        }
        "Analyse predictive"    = @{
            "Exigence"    = $script:NormalityRequirements["Analyse predictive"]
            "Description" = "Critique pour certains modeles (regression lineaire); moins importante pour d'autres (arbres de decision)."
        }
    }

    # Remplir le tableau avec les criteres d'homogeneite des variances
    $comparisonTable["Homogeneite des variances"] = @{
        "Analyse exploratoire"  = @{
            "Exigence"    = $script:VarianceHomogeneityRequirements["Analyse exploratoire"]
            "Description" = "Peu d'exigences formelles; l'heteroscedasticite peut etre un resultat interessant en soi."
        }
        "Analyse confirmatoire" = @{
            "Exigence"    = $script:VarianceHomogeneityRequirements["Analyse confirmatoire"]
            "Description" = "Importante pour les tests parametriques comme l'ANOVA; des corrections peuvent etre necessaires."
        }
        "Analyse predictive"    = @{
            "Exigence"    = $script:VarianceHomogeneityRequirements["Analyse predictive"]
            "Description" = "Peut affecter la precision et la generalisation des modeles; des transformations peuvent etre necessaires."
        }
    }

    # Remplir le tableau avec les criteres de traitement des valeurs aberrantes
    $comparisonTable["Valeurs aberrantes"] = @{
        "Analyse exploratoire"  = @{
            "Traitement"  = $script:OutlierRequirements["Analyse exploratoire"]
            "Description" = "Les valeurs aberrantes doivent etre identifiees et examinees, mais pas necessairement eliminees."
        }
        "Analyse confirmatoire" = @{
            "Traitement"  = $script:OutlierRequirements["Analyse confirmatoire"]
            "Description" = "Les valeurs aberrantes doivent etre traitees pour eviter de biaiser les resultats des tests."
        }
        "Analyse predictive"    = @{
            "Traitement"  = $script:OutlierRequirements["Analyse predictive"]
            "Description" = "Les valeurs aberrantes doivent etre eliminees ou modelisees specifiquement pour ameliorer la precision."
        }
    }

    # Remplir le tableau avec les criteres de traitement des donnees manquantes
    $comparisonTable["Donnees manquantes"] = @{
        "Analyse exploratoire"  = @{
            "Traitement"  = $script:MissingDataRequirements["Analyse exploratoire"]
            "Description" = "Les patterns de donnees manquantes doivent etre identifies et analyses."
        }
        "Analyse confirmatoire" = @{
            "Traitement"  = $script:MissingDataRequirements["Analyse confirmatoire"]
            "Description" = "Les donnees manquantes doivent etre imputees ou traitees par des methodes appropriees."
        }
        "Analyse predictive"    = @{
            "Traitement"  = $script:MissingDataRequirements["Analyse predictive"]
            "Description" = "Les donnees manquantes necessitent des techniques d'imputation avancees ou une modelisation specifique."
        }
    }

    # Remplir le tableau avec les techniques recommandees
    $comparisonTable["Techniques recommandees"] = @{
        "Analyse exploratoire"  = @{
            "Techniques"  = $script:RecommendedTechniques["Analyse exploratoire"]
            "Description" = "Techniques pour explorer et visualiser les donnees, identifier les patterns et generer des hypotheses."
        }
        "Analyse confirmatoire" = @{
            "Techniques"  = $script:RecommendedTechniques["Analyse confirmatoire"]
            "Description" = "Techniques pour tester formellement des hypotheses et evaluer leur significativite statistique."
        }
        "Analyse predictive"    = @{
            "Techniques"  = $script:RecommendedTechniques["Analyse predictive"]
            "Description" = "Techniques pour construire des modeles predictifs et evaluer leur performance."
        }
    }

    # Remplir le tableau avec les metriques d'evaluation
    $comparisonTable["Metriques d'evaluation"] = @{
        "Analyse exploratoire"  = @{
            "Metriques"   = $script:EvaluationMetrics["Analyse exploratoire"]
            "Description" = "Metriques pour evaluer la qualite de l'exploration et la decouverte de patterns."
        }
        "Analyse confirmatoire" = @{
            "Metriques"   = $script:EvaluationMetrics["Analyse confirmatoire"]
            "Description" = "Metriques pour evaluer la validite et la fiabilite des tests d'hypotheses."
        }
        "Analyse predictive"    = @{
            "Metriques"   = $script:EvaluationMetrics["Analyse predictive"]
            "Description" = "Metriques pour evaluer la precision, la generalisation et l'utilite des modeles predictifs."
        }
    }

    # Generer le tableau au format demande
    switch ($Format) {
        "Text" {
            $result = "=== Tableau comparatif des criteres de qualite par domaine d'application ===`n`n"

            foreach ($category in $criteriaCategories) {
                $result += "## $category`n`n"

                if ($category -eq "Taille d'echantillon") {
                    $result += "| Type d'analyse | Minimal | Acceptable | Recommande | Optimal |`n"
                    $result += "|---------------|---------|------------|------------|---------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $minimal = $comparisonTable[$category][$analysisType]["Minimal"]
                        $acceptable = $comparisonTable[$category][$analysisType]["Acceptable"]
                        $recommande = $comparisonTable[$category][$analysisType]["Recommande"]
                        $optimal = $comparisonTable[$category][$analysisType]["Optimal"]

                        $result += "| $analysisType | $minimal | $acceptable | $recommande | $optimal |`n"
                    }
                } elseif ($category -in @("Puissance statistique", "Niveau de signification (alpha)")) {
                    $result += "| Type d'analyse | Valeur |`n"
                    $result += "|---------------|--------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $value = $comparisonTable[$category][$analysisType]["Valeur"]
                        $result += "| $analysisType | $value |`n"
                    }
                } elseif ($category -in @("Distribution des donnees", "Homogeneite des variances")) {
                    $result += "| Type d'analyse | Exigence |`n"
                    $result += "|---------------|----------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $requirement = $comparisonTable[$category][$analysisType]["Exigence"]
                        $result += "| $analysisType | $requirement |`n"
                    }
                } elseif ($category -in @("Valeurs aberrantes", "Donnees manquantes")) {
                    $result += "| Type d'analyse | Traitement |`n"
                    $result += "|---------------|------------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $treatment = $comparisonTable[$category][$analysisType]["Traitement"]
                        $result += "| $analysisType | $treatment |`n"
                    }
                } elseif ($category -eq "Techniques recommandees") {
                    $result += "| Type d'analyse | Techniques |`n"
                    $result += "|---------------|-----------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $techniques = $comparisonTable[$category][$analysisType]["Techniques"] -join ", "
                        $result += "| $analysisType | $techniques |`n"
                    }
                } elseif ($category -eq "Metriques d'evaluation") {
                    $result += "| Type d'analyse | Metriques |`n"
                    $result += "|---------------|-----------|`n"

                    foreach ($analysisType in $analysisTypes) {
                        $metrics = $comparisonTable[$category][$analysisType]["Metriques"] -join ", "
                        $result += "| $analysisType | $metrics |`n"
                    }
                }

                if ($IncludeDetails) {
                    $result += "`nDetails:`n"

                    foreach ($analysisType in $analysisTypes) {
                        $description = $comparisonTable[$category][$analysisType]["Description"]
                        $result += "- $analysisType : $description`n"
                    }
                }

                $result += "`n"
            }

            $result += "=== Fin du tableau comparatif ==="
        }
        "CSV" {
            $result = ""

            foreach ($category in $criteriaCategories) {
                if ($category -eq "Taille d'echantillon") {
                    $result += "Categorie,Type d'analyse,Minimal,Acceptable,Recommande,Optimal`n"

                    foreach ($analysisType in $analysisTypes) {
                        $minimal = $comparisonTable[$category][$analysisType]["Minimal"]
                        $acceptable = $comparisonTable[$category][$analysisType]["Acceptable"]
                        $recommande = $comparisonTable[$category][$analysisType]["Recommande"]
                        $optimal = $comparisonTable[$category][$analysisType]["Optimal"]

                        $result += "$category,$analysisType,$minimal,$acceptable,$recommande,$optimal`n"
                    }
                } elseif ($category -in @("Puissance statistique", "Niveau de signification (alpha)")) {
                    $result += "Categorie,Type d'analyse,Valeur`n"

                    foreach ($analysisType in $analysisTypes) {
                        $value = $comparisonTable[$category][$analysisType]["Valeur"]
                        $result += "$category,$analysisType,$value`n"
                    }
                } elseif ($category -in @("Distribution des donnees", "Homogeneite des variances")) {
                    $result += "Categorie,Type d'analyse,Exigence`n"

                    foreach ($analysisType in $analysisTypes) {
                        $requirement = $comparisonTable[$category][$analysisType]["Exigence"]
                        $result += "$category,$analysisType,$requirement`n"
                    }
                } elseif ($category -in @("Valeurs aberrantes", "Donnees manquantes")) {
                    $result += "Categorie,Type d'analyse,Traitement`n"

                    foreach ($analysisType in $analysisTypes) {
                        $treatment = $comparisonTable[$category][$analysisType]["Traitement"]
                        $result += "$category,$analysisType,$treatment`n"
                    }
                } elseif ($category -eq "Techniques recommandees") {
                    $result += "Categorie,Type d'analyse,Techniques`n"

                    foreach ($analysisType in $analysisTypes) {
                        $techniques = """" + ($comparisonTable[$category][$analysisType]["Techniques"] -join "; ") + """"
                        $result += "$category,$analysisType,$techniques`n"
                    }
                } elseif ($category -eq "Metriques d'evaluation") {
                    $result += "Categorie,Type d'analyse,Metriques`n"

                    foreach ($analysisType in $analysisTypes) {
                        $metrics = """" + ($comparisonTable[$category][$analysisType]["Metriques"] -join "; ") + """"
                        $result += "$category,$analysisType,$metrics`n"
                    }
                }

                if ($IncludeDetails) {
                    $result += "Categorie,Type d'analyse,Description`n"

                    foreach ($analysisType in $analysisTypes) {
                        $description = """" + $comparisonTable[$category][$analysisType]["Description"] + """"
                        $result += "$category,$analysisType,$description`n"
                    }
                }

                $result += "`n"
            }
        }
        "HTML" {
            $result = "<html>`n<head>`n<title>Tableau comparatif des criteres de qualite par domaine d'application</title>`n"
            $result += "<style>`n"
            $result += "table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }`n"
            $result += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }`n"
            $result += "th { background-color: #f2f2f2; }`n"
            $result += "h2 { margin-top: 20px; }`n"
            $result += ".details { margin-left: 20px; margin-bottom: 20px; }`n"
            $result += "</style>`n</head>`n<body>`n"
            $result += "<h1>Tableau comparatif des criteres de qualite par domaine d'application</h1>`n"

            foreach ($category in $criteriaCategories) {
                $result += "<h2>$category</h2>`n"
                $result += "<table>`n"

                if ($category -eq "Taille d'echantillon") {
                    $result += "<tr><th>Type d'analyse</th><th>Minimal</th><th>Acceptable</th><th>Recommande</th><th>Optimal</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $minimal = $comparisonTable[$category][$analysisType]["Minimal"]
                        $acceptable = $comparisonTable[$category][$analysisType]["Acceptable"]
                        $recommande = $comparisonTable[$category][$analysisType]["Recommande"]
                        $optimal = $comparisonTable[$category][$analysisType]["Optimal"]

                        $result += "<tr><td>$analysisType</td><td>$minimal</td><td>$acceptable</td><td>$recommande</td><td>$optimal</td></tr>`n"
                    }
                } elseif ($category -in @("Puissance statistique", "Niveau de signification (alpha)")) {
                    $result += "<tr><th>Type d'analyse</th><th>Valeur</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $value = $comparisonTable[$category][$analysisType]["Valeur"]
                        $result += "<tr><td>$analysisType</td><td>$value</td></tr>`n"
                    }
                } elseif ($category -in @("Distribution des donnees", "Homogeneite des variances")) {
                    $result += "<tr><th>Type d'analyse</th><th>Exigence</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $requirement = $comparisonTable[$category][$analysisType]["Exigence"]
                        $result += "<tr><td>$analysisType</td><td>$requirement</td></tr>`n"
                    }
                } elseif ($category -in @("Valeurs aberrantes", "Donnees manquantes")) {
                    $result += "<tr><th>Type d'analyse</th><th>Traitement</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $treatment = $comparisonTable[$category][$analysisType]["Traitement"]
                        $result += "<tr><td>$analysisType</td><td>$treatment</td></tr>`n"
                    }
                } elseif ($category -eq "Techniques recommandees") {
                    $result += "<tr><th>Type d'analyse</th><th>Techniques</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $techniques = $comparisonTable[$category][$analysisType]["Techniques"] -join "<br>"
                        $result += "<tr><td>$analysisType</td><td>$techniques</td></tr>`n"
                    }
                } elseif ($category -eq "Metriques d'evaluation") {
                    $result += "<tr><th>Type d'analyse</th><th>Metriques</th></tr>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $metrics = $comparisonTable[$category][$analysisType]["Metriques"] -join "<br>"
                        $result += "<tr><td>$analysisType</td><td>$metrics</td></tr>`n"
                    }
                }

                $result += "</table>`n"

                if ($IncludeDetails) {
                    $result += "<div class='details'>`n<h3>Details</h3>`n<ul>`n"

                    foreach ($analysisType in $analysisTypes) {
                        $description = $comparisonTable[$category][$analysisType]["Description"]
                        $result += "<li><strong>$analysisType</strong> : $description</li>`n"
                    }

                    $result += "</ul>`n</div>`n"
                }
            }

            $result += "</body>`n</html>"
        }
        "JSON" {
            $jsonObject = @{
                "title"      = "Tableau comparatif des criteres de qualite par domaine d'application"
                "categories" = @()
            }

            foreach ($category in $criteriaCategories) {
                $categoryObject = @{
                    "name" = $category
                    "data" = @{}
                }

                foreach ($analysisType in $analysisTypes) {
                    $categoryObject["data"][$analysisType] = $comparisonTable[$category][$analysisType]
                }

                $jsonObject["categories"] += $categoryObject
            }

            $result = $jsonObject | ConvertTo-Json -Depth 5
        }
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ExploratoryAnalysisQualityCriteria, Get-ConfirmatoryAnalysisQualityCriteria, Get-PredictiveAnalysisQualityCriteria, Get-AnalysisQualityCriteriaComparison
