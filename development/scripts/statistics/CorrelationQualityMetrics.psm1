#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour établir les critères de précision pour l'analyse de corrélation.

.DESCRIPTION
    Ce module fournit des fonctions pour évaluer la qualité des estimations de corrélation,
    notamment pour les coefficients de Pearson et Spearman, et définir des seuils d'erreur
    acceptables pour différents types d'analyses.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

# Fonction pour obtenir la valeur critique Z pour un niveau de confiance donné
function Get-ZScore {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$ConfidenceLevel
    )

    # Table de valeurs Z courantes
    $zTable = @{
        0.80  = 1.282
        0.85  = 1.440
        0.90  = 1.645
        0.95  = 1.960
        0.98  = 2.326
        0.99  = 2.576
        0.995 = 2.807
        0.999 = 3.291
    }

    # Vérifier si le niveau de confiance est dans la table
    if ($zTable.ContainsKey($ConfidenceLevel)) {
        return $zTable[$ConfidenceLevel]
    }

    # Sinon, utiliser l'approximation la plus proche
    $closestKey = $zTable.Keys | Sort-Object -Property { [Math]::Abs($_ - $ConfidenceLevel) } | Select-Object -First 1
    Write-Warning "Niveau de confiance $ConfidenceLevel non trouvé dans la table. Utilisation de la valeur pour $closestKey."
    return $zTable[$closestKey]
}

#region Private Functions

# Fonction interne pour calculer l'intervalle de confiance pour le coefficient de corrélation de Pearson
function Get-PearsonConfidenceInterval {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceLevel = 0.95
    )

    # Vérifier que le coefficient est dans l'intervalle valide
    if ($CorrelationCoefficient -lt -1 -or $CorrelationCoefficient -gt 1) {
        throw "Le coefficient de corrélation doit être compris entre -1 et 1."
    }

    # Vérifier que la taille d'échantillon est suffisante
    if ($SampleSize -lt 4) {
        throw "La taille d'échantillon doit être d'au moins 4 pour calculer un intervalle de confiance."
    }

    # Calculer le z-score pour le niveau de confiance spécifié
    $zScore = Get-ZScore -ConfidenceLevel $ConfidenceLevel

    # Transformation de Fisher (z-transformation)
    $fisherZ = 0.5 * [Math]::Log((1 + $CorrelationCoefficient) / (1 - $CorrelationCoefficient))

    # Erreur standard de la transformation de Fisher
    $standardError = 1 / [Math]::Sqrt($SampleSize - 3)

    # Calculer les limites de l'intervalle de confiance en z-space
    $lowerZ = $fisherZ - $zScore * $standardError
    $upperZ = $fisherZ + $zScore * $standardError

    # Transformation inverse pour obtenir les limites en termes de coefficient de corrélation
    $lowerR = ([Math]::Exp(2 * $lowerZ) - 1) / ([Math]::Exp(2 * $lowerZ) + 1)
    $upperR = ([Math]::Exp(2 * $upperZ) - 1) / ([Math]::Exp(2 * $upperZ) + 1)

    # Retourner les résultats
    return @{
        Coefficient     = $CorrelationCoefficient
        SampleSize      = $SampleSize
        ConfidenceLevel = $ConfidenceLevel
        LowerBound      = $lowerR
        UpperBound      = $upperR
        Width           = $upperR - $lowerR
        StandardError   = $standardError
    }
}

# Fonction interne pour calculer l'erreur standard du coefficient de corrélation de Pearson
function Get-PearsonStandardError {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize
    )

    # Vérifier que le coefficient est dans l'intervalle valide
    if ($CorrelationCoefficient -lt -1 -or $CorrelationCoefficient -gt 1) {
        throw "Le coefficient de corrélation doit être compris entre -1 et 1."
    }

    # Vérifier que la taille d'échantillon est suffisante
    if ($SampleSize -lt 4) {
        throw "La taille d'échantillon doit être d'au moins 4 pour calculer l'erreur standard."
    }

    # Calculer l'erreur standard
    $standardError = [Math]::Sqrt((1 - [Math]::Pow($CorrelationCoefficient, 2)) / ($SampleSize - 2))

    return $standardError
}

# Fonction interne pour calculer l'intervalle de confiance pour le coefficient de corrélation de Spearman
function Get-SpearmanConfidenceInterval {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceLevel = 0.95
    )

    # Vérifier que le coefficient est dans l'intervalle valide
    if ($CorrelationCoefficient -lt -1 -or $CorrelationCoefficient -gt 1) {
        throw "Le coefficient de corrélation doit être compris entre -1 et 1."
    }

    # Vérifier que la taille d'échantillon est suffisante
    if ($SampleSize -lt 10) {
        throw "La taille d'échantillon doit être d'au moins 10 pour calculer un intervalle de confiance fiable pour Spearman."
    }

    # Calculer le z-score pour le niveau de confiance spécifié
    $zScore = Get-ZScore -ConfidenceLevel $ConfidenceLevel

    # Pour Spearman, l'erreur standard est approximée par 1/sqrt(n-1)
    $standardError = 1 / [Math]::Sqrt($SampleSize - 1)

    # Calculer les limites de l'intervalle de confiance
    $lowerBound = [Math]::Max(-1, $CorrelationCoefficient - $zScore * $standardError)
    $upperBound = [Math]::Min(1, $CorrelationCoefficient + $zScore * $standardError)

    # Retourner les résultats
    return @{
        Coefficient     = $CorrelationCoefficient
        SampleSize      = $SampleSize
        ConfidenceLevel = $ConfidenceLevel
        LowerBound      = $lowerBound
        UpperBound      = $upperBound
        Width           = $upperBound - $lowerBound
        StandardError   = $standardError
    }
}

# Fonction interne pour calculer l'erreur standard du coefficient de corrélation de Spearman
function Get-SpearmanStandardError {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize
    )

    # Vérifier que le coefficient est dans l'intervalle valide
    if ($CorrelationCoefficient -lt -1 -or $CorrelationCoefficient -gt 1) {
        throw "Le coefficient de corrélation doit être compris entre -1 et 1."
    }

    # Vérifier que la taille d'échantillon est suffisante
    if ($SampleSize -lt 10) {
        throw "La taille d'échantillon doit être d'au moins 10 pour calculer l'erreur standard de Spearman."
    }

    # Pour Spearman, l'erreur standard est approximée par 1/sqrt(n-1)
    $standardError = 1 / [Math]::Sqrt($SampleSize - 1)

    return $standardError
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Établit les critères de précision pour l'estimation de la corrélation de Pearson.

.DESCRIPTION
    Cette fonction définit les critères de précision pour l'estimation du coefficient de corrélation
    de Pearson en fonction de la taille de l'échantillon et du niveau de confiance souhaité.

.PARAMETER SampleSize
    La taille de l'échantillon utilisé pour calculer le coefficient de corrélation.

.PARAMETER CorrelationCoefficient
    Le coefficient de corrélation de Pearson calculé.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaité (par défaut 0.95, soit 95%).

.EXAMPLE
    $criteria = Get-PearsonCorrelationPrecisionCriteria -SampleSize 50 -CorrelationCoefficient 0.7 -ConfidenceLevel 0.95

.OUTPUTS
    Un objet hashtable contenant les critères de précision, notamment l'intervalle de confiance,
    l'erreur standard, et des recommandations sur la fiabilité de l'estimation.
#>
function Get-PearsonCorrelationPrecisionCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceLevel = 0.95
    )

    # Aucune initialisation nécessaire

    # Calculer l'intervalle de confiance
    $confidenceInterval = Get-PearsonConfidenceInterval -CorrelationCoefficient $CorrelationCoefficient -SampleSize $SampleSize -ConfidenceLevel $ConfidenceLevel

    # Calculer l'erreur standard
    $standardError = Get-PearsonStandardError -CorrelationCoefficient $CorrelationCoefficient -SampleSize $SampleSize

    # Déterminer la précision de l'estimation
    $precisionLevel = if ($confidenceInterval.Width -lt 0.2) {
        "Élevée"
    } elseif ($confidenceInterval.Width -lt 0.4) {
        "Moyenne"
    } else {
        "Faible"
    }

    # Déterminer si la taille d'échantillon est suffisante
    $sampleSizeAdequacy = if ($SampleSize -lt 10) {
        "Insuffisante"
    } elseif ($SampleSize -lt 30) {
        "Minimale"
    } elseif ($SampleSize -lt 100) {
        "Adéquate"
    } else {
        "Excellente"
    }

    # Calculer la puissance statistique pour détecter une corrélation significative
    # (approximation simplifiée)
    $alpha = 1 - $ConfidenceLevel
    $criticalR = [Math]::Sqrt($alpha / $SampleSize)
    $statisticalPower = if ([Math]::Abs($CorrelationCoefficient) -lt $criticalR) {
        "Insuffisante"
    } elseif ([Math]::Abs($CorrelationCoefficient) -lt 2 * $criticalR) {
        "Marginale"
    } else {
        "Adéquate"
    }

    # Générer des recommandations
    $recommendations = @()

    if ($sampleSizeAdequacy -eq "Insuffisante") {
        $recommendations += "Augmenter la taille de l'échantillon à au moins 30 observations."
    }

    if ($precisionLevel -eq "Faible") {
        $recommendations += "L'intervalle de confiance est large. Envisager d'augmenter la taille de l'échantillon."
    }

    if ($statisticalPower -eq "Insuffisante") {
        $recommendations += "La puissance statistique est faible. La corrélation pourrait ne pas être significative."
    }

    # Retourner les résultats
    return @{
        CorrelationCoefficient       = $CorrelationCoefficient
        SampleSize                   = $SampleSize
        ConfidenceLevel              = $ConfidenceLevel
        ConfidenceInterval           = @{
            LowerBound = $confidenceInterval.LowerBound
            UpperBound = $confidenceInterval.UpperBound
            Width      = $confidenceInterval.Width
        }
        StandardError                = $standardError
        PrecisionLevel               = $precisionLevel
        SampleSizeAdequacy           = $sampleSizeAdequacy
        StatisticalPower             = $statisticalPower
        Recommendations              = $recommendations
        MinimumSampleSizeRecommended = [Math]::Max(30, [Math]::Ceiling(4 / [Math]::Pow($CorrelationCoefficient, 2)))
    }
}

<#
.SYNOPSIS
    Établit les critères de précision pour l'estimation de la corrélation de Spearman.

.DESCRIPTION
    Cette fonction définit les critères de précision pour l'estimation du coefficient de corrélation
    de Spearman en fonction de la taille de l'échantillon et du niveau de confiance souhaité.

.PARAMETER SampleSize
    La taille de l'échantillon utilisé pour calculer le coefficient de corrélation.

.PARAMETER CorrelationCoefficient
    Le coefficient de corrélation de Spearman calculé.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaité (par défaut 0.95, soit 95%).

.EXAMPLE
    $criteria = Get-SpearmanCorrelationPrecisionCriteria -SampleSize 50 -CorrelationCoefficient 0.7 -ConfidenceLevel 0.95

.OUTPUTS
    Un objet hashtable contenant les critères de précision, notamment l'intervalle de confiance,
    l'erreur standard, et des recommandations sur la fiabilité de l'estimation.
#>
function Get-SpearmanCorrelationPrecisionCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceLevel = 0.95
    )

    # Aucune initialisation nécessaire

    # Calculer l'intervalle de confiance
    $confidenceInterval = Get-SpearmanConfidenceInterval -CorrelationCoefficient $CorrelationCoefficient -SampleSize $SampleSize -ConfidenceLevel $ConfidenceLevel

    # Calculer l'erreur standard
    $standardError = Get-SpearmanStandardError -CorrelationCoefficient $CorrelationCoefficient -SampleSize $SampleSize

    # Déterminer la précision de l'estimation
    $precisionLevel = if ($confidenceInterval.Width -lt 0.3) {
        "Élevée"
    } elseif ($confidenceInterval.Width -lt 0.5) {
        "Moyenne"
    } else {
        "Faible"
    }

    # Déterminer si la taille d'échantillon est suffisante
    $sampleSizeAdequacy = if ($SampleSize -lt 20) {
        "Insuffisante"
    } elseif ($SampleSize -lt 50) {
        "Minimale"
    } elseif ($SampleSize -lt 100) {
        "Adéquate"
    } else {
        "Excellente"
    }

    # Calculer la puissance statistique pour détecter une corrélation significative
    # (approximation simplifiée pour Spearman)
    # Utiliser directement 1.96 comme valeur critique pour un niveau de confiance de 95%
    # Pour d'autres niveaux de confiance, on pourrait calculer la valeur critique correspondante
    $criticalR = 1.96 / [Math]::Sqrt($SampleSize)  # Approximation pour p=0.05
    $statisticalPower = if ([Math]::Abs($CorrelationCoefficient) -lt $criticalR) {
        "Insuffisante"
    } elseif ([Math]::Abs($CorrelationCoefficient) -lt 2 * $criticalR) {
        "Marginale"
    } else {
        "Adéquate"
    }

    # Générer des recommandations
    $recommendations = @()

    if ($sampleSizeAdequacy -eq "Insuffisante") {
        $recommendations += "Augmenter la taille de l'échantillon à au moins 50 observations pour Spearman."
    }

    if ($precisionLevel -eq "Faible") {
        $recommendations += "L'intervalle de confiance est large. Envisager d'augmenter la taille de l'échantillon."
    }

    if ($statisticalPower -eq "Insuffisante") {
        $recommendations += "La puissance statistique est faible. La corrélation pourrait ne pas être significative."
    }

    # Ajouter une recommandation spécifique à Spearman
    $recommendations += "Pour les distributions non normales ou en présence de valeurs aberrantes, Spearman est plus robuste que Pearson."

    # Retourner les résultats
    return @{
        CorrelationCoefficient       = $CorrelationCoefficient
        SampleSize                   = $SampleSize
        ConfidenceLevel              = $ConfidenceLevel
        ConfidenceInterval           = @{
            LowerBound = $confidenceInterval.LowerBound
            UpperBound = $confidenceInterval.UpperBound
            Width      = $confidenceInterval.Width
        }
        StandardError                = $standardError
        PrecisionLevel               = $precisionLevel
        SampleSizeAdequacy           = $sampleSizeAdequacy
        StatisticalPower             = $statisticalPower
        Recommendations              = $recommendations
        MinimumSampleSizeRecommended = [Math]::Max(50, [Math]::Ceiling(10 / [Math]::Pow($CorrelationCoefficient, 2)))
    }
}

<#
.SYNOPSIS
    Définit les seuils d'erreur acceptables pour les mesures de corrélation.

.DESCRIPTION
    Cette fonction définit les seuils d'erreur acceptables pour les mesures de corrélation
    en fonction du contexte d'application et du niveau de précision requis.

.PARAMETER ApplicationContext
    Le contexte d'application pour lequel les seuils sont définis.
    Valeurs possibles : "Recherche", "Industriel", "Exploratoire", "Critique".

.PARAMETER PrecisionLevel
    Le niveau de précision requis.
    Valeurs possibles : "Faible", "Moyen", "Élevé", "Très élevé".

.PARAMETER CorrelationType
    Le type de corrélation pour lequel les seuils sont définis.
    Valeurs possibles : "Pearson", "Spearman", "Tous".

.EXAMPLE
    $thresholds = Get-CorrelationErrorThresholds -ApplicationContext "Recherche" -PrecisionLevel "Élevé" -CorrelationType "Pearson"

.OUTPUTS
    Un objet hashtable contenant les seuils d'erreur acceptables pour les mesures de corrélation.
#>
function Get-CorrelationErrorThresholds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Recherche", "Industriel", "Exploratoire", "Critique")]
        [string]$ApplicationContext,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Faible", "Moyen", "Élevé", "Très élevé")]
        [string]$PrecisionLevel,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Pearson", "Spearman", "Tous")]
        [string]$CorrelationType = "Tous"
    )

    # Définir les seuils de base pour chaque contexte d'application
    $baseThresholds = @{
        "Recherche"    = @{
            "MinSampleSize"              = 30
            "MaxStandardError"           = 0.15
            "MaxConfidenceIntervalWidth" = 0.3
            "MinConfidenceLevel"         = 0.95
        }
        "Industriel"   = @{
            "MinSampleSize"              = 50
            "MaxStandardError"           = 0.1
            "MaxConfidenceIntervalWidth" = 0.25
            "MinConfidenceLevel"         = 0.9
        }
        "Exploratoire" = @{
            "MinSampleSize"              = 20
            "MaxStandardError"           = 0.2
            "MaxConfidenceIntervalWidth" = 0.4
            "MinConfidenceLevel"         = 0.9
        }
        "Critique"     = @{
            "MinSampleSize"              = 100
            "MaxStandardError"           = 0.05
            "MaxConfidenceIntervalWidth" = 0.15
            "MinConfidenceLevel"         = 0.99
        }
    }

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultipliers = @{
        "Faible"     = 1.5
        "Moyen"      = 1.0
        "Élevé"      = 0.7
        "Très élevé" = 0.5
    }

    # Ajuster les seuils en fonction du type de corrélation
    $correlationTypeAdjustments = @{
        "Pearson"  = @{
            "MinSampleSizeMultiplier"              = 1.0
            "MaxStandardErrorMultiplier"           = 1.0
            "MaxConfidenceIntervalWidthMultiplier" = 1.0
        }
        "Spearman" = @{
            "MinSampleSizeMultiplier"              = 1.2  # Spearman nécessite généralement plus d'observations
            "MaxStandardErrorMultiplier"           = 1.1
            "MaxConfidenceIntervalWidthMultiplier" = 1.1
        }
    }

    # Sélectionner les seuils de base pour le contexte d'application
    $thresholds = $baseThresholds[$ApplicationContext].Clone()

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultiplier = $precisionMultipliers[$PrecisionLevel]
    $thresholds["MaxStandardError"] *= $precisionMultiplier
    $thresholds["MaxConfidenceIntervalWidth"] *= $precisionMultiplier

    # Ajuster les seuils en fonction du type de corrélation
    if ($CorrelationType -ne "Tous") {
        $typeAdjustments = $correlationTypeAdjustments[$CorrelationType]
        $thresholds["MinSampleSize"] = [Math]::Ceiling($thresholds["MinSampleSize"] * $typeAdjustments["MinSampleSizeMultiplier"])
        $thresholds["MaxStandardError"] *= $typeAdjustments["MaxStandardErrorMultiplier"]
        $thresholds["MaxConfidenceIntervalWidth"] *= $typeAdjustments["MaxConfidenceIntervalWidthMultiplier"]
    } else {
        # Pour "Tous", utiliser les seuils les plus stricts entre Pearson et Spearman
        $pearsonAdjustments = $correlationTypeAdjustments["Pearson"]
        $spearmanAdjustments = $correlationTypeAdjustments["Spearman"]

        $thresholds["MinSampleSize"] = [Math]::Ceiling($thresholds["MinSampleSize"] * [Math]::Max($pearsonAdjustments["MinSampleSizeMultiplier"], $spearmanAdjustments["MinSampleSizeMultiplier"]))
        $thresholds["MaxStandardError"] *= [Math]::Min($pearsonAdjustments["MaxStandardErrorMultiplier"], $spearmanAdjustments["MaxStandardErrorMultiplier"])
        $thresholds["MaxConfidenceIntervalWidth"] *= [Math]::Min($pearsonAdjustments["MaxConfidenceIntervalWidthMultiplier"], $spearmanAdjustments["MaxConfidenceIntervalWidthMultiplier"])
    }

    # Ajouter des recommandations spécifiques
    $recommendations = @()

    if ($ApplicationContext -eq "Critique") {
        $recommendations += "Pour les applications critiques, envisager de valider les résultats avec plusieurs méthodes de corrélation."
    }

    if ($PrecisionLevel -eq "Très élevé") {
        $recommendations += "Pour une précision très élevée, envisager d'augmenter la taille de l'échantillon au-delà du minimum recommandé."
    }

    if ($CorrelationType -eq "Pearson") {
        $recommendations += "Vérifier la normalité des distributions avant d'utiliser la corrélation de Pearson."
    } elseif ($CorrelationType -eq "Spearman") {
        $recommendations += "La corrélation de Spearman est plus robuste aux valeurs aberrantes mais peut être moins puissante que Pearson pour les relations linéaires."
    }

    $thresholds["Recommendations"] = $recommendations

    return $thresholds
}

<#
.SYNOPSIS
    Établit les critères de résistance aux valeurs aberrantes pour les analyses de corrélation.

.DESCRIPTION
    Cette fonction évalue la résistance d'une analyse de corrélation aux valeurs aberrantes
    en comparant les coefficients de corrélation calculés avec et sans les valeurs extrêmes.

.PARAMETER CorrelationCoefficient
    Le coefficient de corrélation calculé sur l'ensemble complet des données.

.PARAMETER TrimmedCorrelationCoefficient
    Le coefficient de corrélation calculé après suppression des valeurs extrêmes.

.PARAMETER OutlierPercentage
    Le pourcentage de valeurs considérées comme aberrantes et supprimées pour le calcul du coefficient tronqué.

.PARAMETER CorrelationType
    Le type de corrélation utilisé (Pearson ou Spearman).

.EXAMPLE
    $robustness = Test-CorrelationOutlierResistance -CorrelationCoefficient 0.75 -TrimmedCorrelationCoefficient 0.72 -OutlierPercentage 5 -CorrelationType "Pearson"

.OUTPUTS
    Un objet hashtable contenant les critères de résistance aux valeurs aberrantes, notamment
    l'indice de stabilité, le niveau de robustesse, et des recommandations.
#>
function Test-CorrelationOutlierResistance {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$CorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [double]$TrimmedCorrelationCoefficient,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 50)]
        [double]$OutlierPercentage,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Pearson", "Spearman")]
        [string]$CorrelationType
    )

    # Vérifier que les coefficients sont dans l'intervalle valide
    if ($CorrelationCoefficient -lt -1 -or $CorrelationCoefficient -gt 1 -or
        $TrimmedCorrelationCoefficient -lt -1 -or $TrimmedCorrelationCoefficient -gt 1) {
        throw "Les coefficients de corrélation doivent être compris entre -1 et 1."
    }

    # Calculer la différence absolue entre les coefficients
    $absoluteDifference = [Math]::Abs($CorrelationCoefficient - $TrimmedCorrelationCoefficient)

    # Calculer la différence relative (en pourcentage)
    $relativeDifference = if ($CorrelationCoefficient -ne 0) {
        $absoluteDifference / [Math]::Abs($CorrelationCoefficient) * 100
    } else {
        if ($TrimmedCorrelationCoefficient -eq 0) {
            0
        } else {
            100 # Différence maximale si l'un est zéro et l'autre non
        }
    }

    # Calculer l'indice de stabilité (inversement proportionnel à la différence relative)
    $stabilityIndex = [Math]::Max(0, 100 - $relativeDifference)

    # Déterminer le niveau de robustesse
    $robustnessLevel = if ($stabilityIndex -ge 95) {
        "Très élevé"
    } elseif ($stabilityIndex -ge 90) {
        "Élevé"
    } elseif ($stabilityIndex -ge 80) {
        "Moyen"
    } elseif ($stabilityIndex -ge 70) {
        "Faible"
    } else {
        "Très faible"
    }

    # Calculer le seuil de différence acceptable en fonction du pourcentage de valeurs aberrantes
    $acceptableDifferenceThreshold = $OutlierPercentage * 0.01 # 1% de différence pour chaque 1% de valeurs aberrantes

    # Déterminer si la différence est acceptable
    $isDifferenceAcceptable = $relativeDifference -le $acceptableDifferenceThreshold

    # Générer des recommandations
    $recommendations = @()

    if (-not $isDifferenceAcceptable) {
        $recommendations += "La différence entre les coefficients est trop importante par rapport au pourcentage de valeurs aberrantes supprimées."

        if ($CorrelationType -eq "Pearson") {
            $recommendations += "Envisager d'utiliser la corrélation de Spearman qui est plus robuste aux valeurs aberrantes."
        }

        $recommendations += "Examiner les valeurs aberrantes pour déterminer si elles sont des erreurs de mesure ou des observations légitimes."
    }

    if ($robustnessLevel -eq "Très faible" -or $robustnessLevel -eq "Faible") {
        $recommendations += "Les résultats de l'analyse de corrélation sont fortement influencés par les valeurs aberrantes."
        $recommendations += "Envisager d'utiliser des méthodes robustes comme la corrélation de rang ou des estimateurs robustes."
    }

    # Retourner les résultats
    return @{
        CorrelationCoefficient        = $CorrelationCoefficient
        TrimmedCorrelationCoefficient = $TrimmedCorrelationCoefficient
        OutlierPercentage             = $OutlierPercentage
        AbsoluteDifference            = $absoluteDifference
        RelativeDifference            = $relativeDifference
        StabilityIndex                = $stabilityIndex
        RobustnessLevel               = $robustnessLevel
        AcceptableDifferenceThreshold = $acceptableDifferenceThreshold
        IsDifferenceAcceptable        = $isDifferenceAcceptable
        CorrelationType               = $CorrelationType
        Recommendations               = $recommendations
    }
}

<#
.SYNOPSIS
    Définit les métriques de stabilité face aux variations d'échantillonnage pour les analyses de corrélation.

.DESCRIPTION
    Cette fonction évalue la stabilité d'un coefficient de corrélation face aux variations d'échantillonnage
    en analysant les résultats de plusieurs sous-échantillons.

.PARAMETER CorrelationCoefficients
    Un tableau de coefficients de corrélation calculés sur différents sous-échantillons.

.PARAMETER SampleSizes
    Un tableau des tailles des sous-échantillons correspondant aux coefficients de corrélation.

.PARAMETER CorrelationType
    Le type de corrélation utilisé (Pearson ou Spearman).

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaité pour l'évaluation de la stabilité (par défaut 0.95, soit 95%).

.EXAMPLE
    $stability = Test-CorrelationSamplingStability -CorrelationCoefficients @(0.72, 0.68, 0.75, 0.71, 0.73) -SampleSizes @(50, 50, 50, 50, 50) -CorrelationType "Pearson" -ConfidenceLevel 0.95

.OUTPUTS
    Un objet hashtable contenant les métriques de stabilité, notamment l'écart-type des coefficients,
    le coefficient de variation, le niveau de stabilité, et des recommandations.
#>
function Test-CorrelationSamplingStability {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$CorrelationCoefficients,

        [Parameter(Mandatory = $true)]
        [int[]]$SampleSizes,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Pearson", "Spearman")]
        [string]$CorrelationType,

        [Parameter(Mandatory = $false)]
        [double]$ConfidenceLevel = 0.95
    )

    # Vérifier que les tableaux ont la même longueur
    if ($CorrelationCoefficients.Length -ne $SampleSizes.Length) {
        throw "Les tableaux de coefficients de corrélation et de tailles d'échantillon doivent avoir la même longueur."
    }

    # Vérifier qu'il y a au moins 2 échantillons
    if ($CorrelationCoefficients.Length -lt 2) {
        throw "Au moins 2 échantillons sont nécessaires pour évaluer la stabilité."
    }

    # Calculer la moyenne des coefficients de corrélation
    $meanCorrelation = ($CorrelationCoefficients | Measure-Object -Average).Average

    # Calculer l'écart-type des coefficients de corrélation
    $stdDevCorrelation = [Math]::Sqrt(($CorrelationCoefficients | ForEach-Object { [Math]::Pow($_ - $meanCorrelation, 2) } | Measure-Object -Average).Average)

    # Calculer le coefficient de variation (en pourcentage)
    $coefficientOfVariation = if ($meanCorrelation -ne 0) {
        $stdDevCorrelation / [Math]::Abs($meanCorrelation) * 100
    } else {
        if ($stdDevCorrelation -eq 0) {
            0
        } else {
            100 # Valeur maximale si la moyenne est zéro mais l'écart-type non
        }
    }

    # Calculer la taille moyenne des échantillons
    $meanSampleSize = ($SampleSizes | Measure-Object -Average).Average

    # Calculer l'erreur standard moyenne attendue
    $expectedStandardError = if ($CorrelationType -eq "Pearson") {
        # Approximation pour Pearson
        [Math]::Sqrt((1 - [Math]::Pow($meanCorrelation, 2)) / ($meanSampleSize - 2))
    } else {
        # Approximation pour Spearman
        1 / [Math]::Sqrt($meanSampleSize - 1)
    }

    # Calculer le ratio entre l'écart-type observé et l'erreur standard attendue
    $stabilityRatio = $stdDevCorrelation / $expectedStandardError

    # Déterminer le niveau de stabilité
    $stabilityLevel = if ($stabilityRatio -le 0.5) {
        "Très élevé"
    } elseif ($stabilityRatio -le 1.0) {
        "Élevé"
    } elseif ($stabilityRatio -le 1.5) {
        "Moyen"
    } elseif ($stabilityRatio -le 2.0) {
        "Faible"
    } else {
        "Très faible"
    }

    # Calculer l'intervalle de confiance pour la moyenne des coefficients
    $zScore = Get-ZScore -ConfidenceLevel $ConfidenceLevel
    $standardErrorOfMean = $stdDevCorrelation / [Math]::Sqrt($CorrelationCoefficients.Length)
    $ciLowerBound = [Math]::Max(-1, $meanCorrelation - $zScore * $standardErrorOfMean)
    $ciUpperBound = [Math]::Min(1, $meanCorrelation + $zScore * $standardErrorOfMean)

    # Générer des recommandations
    $recommendations = @()

    if ($stabilityLevel -eq "Très faible" -or $stabilityLevel -eq "Faible") {
        $recommendations += "La stabilité de l'estimation est faible. Les résultats peuvent varier considérablement selon l'échantillon."
        $recommendations += "Envisager d'augmenter la taille des échantillons pour améliorer la stabilité."
    }

    if ($coefficientOfVariation -gt 20) {
        $recommendations += "La variabilité des coefficients est élevée. Vérifier l'homogénéité des échantillons."
    }

    if ($CorrelationCoefficients.Length -lt 5) {
        $recommendations += "Utiliser plus de sous-échantillons (au moins 5) pour une évaluation plus fiable de la stabilité."
    }

    # Retourner les résultats
    return @{
        MeanCorrelation        = $meanCorrelation
        StandardDeviation      = $stdDevCorrelation
        CoefficientOfVariation = $coefficientOfVariation
        MeanSampleSize         = $meanSampleSize
        ExpectedStandardError  = $expectedStandardError
        StabilityRatio         = $stabilityRatio
        StabilityLevel         = $stabilityLevel
        ConfidenceInterval     = @{
            LowerBound = $ciLowerBound
            UpperBound = $ciUpperBound
            Width      = $ciUpperBound - $ciLowerBound
        }
        NumberOfSamples        = $CorrelationCoefficients.Length
        CorrelationType        = $CorrelationType
        Recommendations        = $recommendations
    }
}

<#
.SYNOPSIS
    Établit les seuils de robustesse pour différents types de distributions dans les analyses de corrélation.

.DESCRIPTION
    Cette fonction définit les seuils de robustesse acceptables pour les analyses de corrélation
    en fonction du type de distribution des données et du niveau de précision requis.

.PARAMETER DistributionType
    Le type de distribution des données.
    Valeurs possibles : "Normale", "Asymétrique", "Multimodale", "Queue lourde", "Mixte".

.PARAMETER PrecisionLevel
    Le niveau de précision requis.
    Valeurs possibles : "Faible", "Moyen", "Élevé", "Très élevé".

.PARAMETER CorrelationType
    Le type de corrélation pour lequel les seuils sont définis.
    Valeurs possibles : "Pearson", "Spearman", "Tous".

.EXAMPLE
    $thresholds = Get-CorrelationRobustnessThresholds -DistributionType "Asymétrique" -PrecisionLevel "Élevé" -CorrelationType "Pearson"

.OUTPUTS
    Un objet hashtable contenant les seuils de robustesse pour les analyses de corrélation.
#>
function Get-CorrelationRobustnessThresholds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Normale", "Asymétrique", "Multimodale", "Queue lourde", "Mixte")]
        [string]$DistributionType,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Faible", "Moyen", "Élevé", "Très élevé")]
        [string]$PrecisionLevel,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Pearson", "Spearman", "Tous")]
        [string]$CorrelationType = "Tous"
    )

    # Définir les seuils de base pour chaque type de distribution
    $baseThresholds = @{
        "Normale"      = @{
            "MaxOutlierImpact"           = 0.1  # Impact maximal des valeurs aberrantes (différence relative)
            "MaxSamplingVariability"     = 0.15 # Coefficient de variation maximal entre échantillons
            "MinStabilityIndex"          = 85   # Indice de stabilité minimal
            "RecommendedCorrelationType" = "Pearson"
        }
        "Asymétrique"  = @{
            "MaxOutlierImpact"           = 0.15
            "MaxSamplingVariability"     = 0.2
            "MinStabilityIndex"          = 80
            "RecommendedCorrelationType" = "Spearman"
        }
        "Multimodale"  = @{
            "MaxOutlierImpact"           = 0.2
            "MaxSamplingVariability"     = 0.25
            "MinStabilityIndex"          = 75
            "RecommendedCorrelationType" = "Spearman"
        }
        "Queue lourde" = @{
            "MaxOutlierImpact"           = 0.25
            "MaxSamplingVariability"     = 0.3
            "MinStabilityIndex"          = 70
            "RecommendedCorrelationType" = "Spearman"
        }
        "Mixte"        = @{
            "MaxOutlierImpact"           = 0.2
            "MaxSamplingVariability"     = 0.25
            "MinStabilityIndex"          = 75
            "RecommendedCorrelationType" = "Spearman"
        }
    }

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultipliers = @{
        "Faible"     = 1.5
        "Moyen"      = 1.0
        "Élevé"      = 0.7
        "Très élevé" = 0.5
    }

    # Ajuster les seuils en fonction du type de corrélation
    $correlationTypeAdjustments = @{
        "Pearson"  = @{
            "MaxOutlierImpactMultiplier"       = 0.8  # Pearson est plus sensible aux valeurs aberrantes
            "MaxSamplingVariabilityMultiplier" = 0.9
            "MinStabilityIndexMultiplier"      = 1.1  # Exigence plus élevée pour Pearson
        }
        "Spearman" = @{
            "MaxOutlierImpactMultiplier"       = 1.2  # Spearman est plus robuste aux valeurs aberrantes
            "MaxSamplingVariabilityMultiplier" = 1.1
            "MinStabilityIndexMultiplier"      = 0.9  # Exigence moins élevée pour Spearman
        }
    }

    # Sélectionner les seuils de base pour le type de distribution
    $thresholds = $baseThresholds[$DistributionType].Clone()

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultiplier = $precisionMultipliers[$PrecisionLevel]
    $thresholds["MaxOutlierImpact"] *= $precisionMultiplier
    $thresholds["MaxSamplingVariability"] *= $precisionMultiplier
    $thresholds["MinStabilityIndex"] = [Math]::Min(100, $thresholds["MinStabilityIndex"] / $precisionMultiplier)

    # Ajuster les seuils en fonction du type de corrélation
    if ($CorrelationType -ne "Tous") {
        $typeAdjustments = $correlationTypeAdjustments[$CorrelationType]
        $thresholds["MaxOutlierImpact"] *= $typeAdjustments["MaxOutlierImpactMultiplier"]
        $thresholds["MaxSamplingVariability"] *= $typeAdjustments["MaxSamplingVariabilityMultiplier"]
        $thresholds["MinStabilityIndex"] = [Math]::Min(100, $thresholds["MinStabilityIndex"] * $typeAdjustments["MinStabilityIndexMultiplier"])
    }

    # Ajouter des recommandations spécifiques
    $recommendations = @()

    if ($DistributionType -ne "Normale" -and $CorrelationType -eq "Pearson") {
        $recommendations += "Pour les distributions $DistributionType, la corrélation de Spearman est généralement plus appropriée que Pearson."
    }

    if ($DistributionType -eq "Queue lourde") {
        $recommendations += "Pour les distributions à queue lourde, envisager d'utiliser des méthodes robustes comme la corrélation de rang ou des estimateurs robustes."
    }

    if ($PrecisionLevel -eq "Très élevé" -and $DistributionType -ne "Normale") {
        $recommendations += "Pour atteindre un niveau de précision très élevé avec des distributions $DistributionType, augmenter considérablement la taille de l'échantillon."
    }

    # Ajouter les recommandations aux seuils
    $thresholds["Recommendations"] = $recommendations

    # Ajouter des informations supplémentaires
    $thresholds["DistributionType"] = $DistributionType
    $thresholds["PrecisionLevel"] = $PrecisionLevel
    $thresholds["CorrelationType"] = $CorrelationType

    return $thresholds
}

<#
.SYNOPSIS
    Établit les critères de détection des relations quadratiques dans les analyses de corrélation.

.DESCRIPTION
    Cette fonction évalue la présence potentielle d'une relation quadratique entre deux variables
    en comparant les coefficients de corrélation linéaire et non linéaire.

.PARAMETER LinearCorrelation
    Le coefficient de corrélation linéaire (Pearson ou Spearman) entre les variables.

.PARAMETER QuadraticCorrelation
    Le coefficient de corrélation après transformation quadratique (généralement obtenu en corrélant
    une variable avec le carré de l'autre variable).

.PARAMETER SampleSize
    La taille de l'échantillon utilisé pour calculer les coefficients de corrélation.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaité pour l'évaluation (par défaut 0.95, soit 95%).

.EXAMPLE
    $detection = Test-QuadraticRelationship -LinearCorrelation 0.3 -QuadraticCorrelation 0.7 -SampleSize 50 -ConfidenceLevel 0.95

.OUTPUTS
    Un objet hashtable contenant les critères de détection, notamment l'indice de non-linéarité,
    la probabilité de relation quadratique, et des recommandations.
#>
function Test-QuadraticRelationship {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(-1, 1)]
        [double]$LinearCorrelation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(-1, 1)]
        [double]$QuadraticCorrelation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(10, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.8, 0.999)]
        [double]$ConfidenceLevel = 0.95
    )

    # Calculer la différence absolue entre les coefficients
    $correlationDifference = [Math]::Abs($QuadraticCorrelation) - [Math]::Abs($LinearCorrelation)

    # Calculer l'indice de non-linéarité (0-100)
    $nonLinearityIndex = [Math]::Min(100, [Math]::Max(0, $correlationDifference * 100))

    # Nous n'utilisons pas directement le z-score ici, mais nous calculons la p-value

    # Calculer les erreurs standard pour les deux coefficients
    $linearStandardError = 1 / [Math]::Sqrt($SampleSize - 3)
    $quadraticStandardError = 1 / [Math]::Sqrt($SampleSize - 3)

    # Calculer la statistique Z pour la différence entre les coefficients
    # Utiliser la transformation de Fisher pour normaliser les coefficients
    $linearFisherZ = 0.5 * [Math]::Log((1 + [Math]::Abs($LinearCorrelation)) / (1 - [Math]::Abs($LinearCorrelation)))
    $quadraticFisherZ = 0.5 * [Math]::Log((1 + [Math]::Abs($QuadraticCorrelation)) / (1 - [Math]::Abs($QuadraticCorrelation)))
    $fisherZDifference = $quadraticFisherZ - $linearFisherZ
    $differenceStandardError = [Math]::Sqrt($linearStandardError * $linearStandardError + $quadraticStandardError * $quadraticStandardError)
    $zStatistic = $fisherZDifference / $differenceStandardError

    # Calculer la p-value pour la différence (approximation)
    # Utiliser une fonction simplifiée pour la distribution normale
    $pValue = if ($zStatistic -le 0) {
        0.5
    } else {
        # Approximation de la fonction de répartition de la loi normale centrée réduite
        $t = 1 / (1 + 0.2316419 * $zStatistic)
        $d = 0.3989423 * [Math]::Exp(-$zStatistic * $zStatistic / 2)
        $p = $d * $t * (0.3193815 + $t * (-0.3565638 + $t * (1.781478 + $t * (-1.821256 + $t * 1.330274))))
        1 - $p
    }

    # Déterminer si la relation quadratique est statistiquement significative
    $isSignificant = $pValue -lt (1 - $ConfidenceLevel)

    # Nous utilisons directement la p-value et isSignificant pour l'évaluation

    # Déterminer le niveau de confiance dans la détection
    $detectionConfidenceLevel = if ($nonLinearityIndex -ge 50 -and $isSignificant) {
        "Élevé"
    } elseif ($nonLinearityIndex -ge 30 -and $isSignificant) {
        "Moyen"
    } elseif ($nonLinearityIndex -ge 10 -or $isSignificant) {
        "Faible"
    } else {
        "Très faible"
    }

    # Générer des recommandations
    $recommendations = @()

    if ($detectionConfidenceLevel -eq "Élevé" -or $detectionConfidenceLevel -eq "Moyen") {
        $recommendations += "Une relation quadratique est probable. Envisager d'utiliser des modèles non linéaires pour l'analyse."
    }

    if ($nonLinearityIndex -ge 30 -and -not $isSignificant) {
        $recommendations += "L'indice de non-linéarité est élevé mais la différence n'est pas statistiquement significative. Augmenter la taille de l'échantillon pour confirmer."
    }

    if ([Math]::Abs($LinearCorrelation) -lt 0.3 -and [Math]::Abs($QuadraticCorrelation) -ge 0.5) {
        $recommendations += "La corrélation linéaire est faible mais la corrélation quadratique est modérée à forte. Une relation en forme de U ou de cloche est probable."
    }

    if ($SampleSize -lt 30) {
        $recommendations += "La taille de l'échantillon est petite. Les résultats peuvent ne pas être fiables."
    }

    # Retourner les résultats
    return @{
        LinearCorrelation        = $LinearCorrelation
        QuadraticCorrelation     = $QuadraticCorrelation
        SampleSize               = $SampleSize
        CorrelationDifference    = $correlationDifference
        NonLinearityIndex        = $nonLinearityIndex
        ZStatistic               = $zStatistic
        PValue                   = $pValue
        IsSignificant            = $isSignificant
        ConfidenceLevel          = $ConfidenceLevel
        DetectionConfidenceLevel = $detectionConfidenceLevel
        Recommendations          = $recommendations
    }
}

<#
.SYNOPSIS
    Établit les critères de détection des relations exponentielles dans les analyses de corrélation.

.DESCRIPTION
    Cette fonction évalue la présence potentielle d'une relation exponentielle entre deux variables
    en comparant les coefficients de corrélation avant et après transformation logarithmique.

.PARAMETER LinearCorrelation
    Le coefficient de corrélation linéaire (Pearson ou Spearman) entre les variables originales.

.PARAMETER LogTransformedCorrelation
    Le coefficient de corrélation après transformation logarithmique (généralement obtenu en corrélant
    une variable avec le logarithme de l'autre variable).

.PARAMETER SampleSize
    La taille de l'échantillon utilisé pour calculer les coefficients de corrélation.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaité pour l'évaluation (par défaut 0.95, soit 95%).

.EXAMPLE
    $detection = Test-ExponentialRelationship -LinearCorrelation 0.4 -LogTransformedCorrelation 0.8 -SampleSize 50 -ConfidenceLevel 0.95

.OUTPUTS
    Un objet hashtable contenant les critères de détection, notamment l'indice de non-linéarité,
    la probabilité de relation exponentielle, et des recommandations.
#>
function Test-ExponentialRelationship {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(-1, 1)]
        [double]$LinearCorrelation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(-1, 1)]
        [double]$LogTransformedCorrelation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(10, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.8, 0.999)]
        [double]$ConfidenceLevel = 0.95
    )

    # Calculer la différence absolue entre les coefficients
    $correlationDifference = [Math]::Abs($LogTransformedCorrelation) - [Math]::Abs($LinearCorrelation)

    # Calculer l'indice de non-linéarité (0-100)
    $nonLinearityIndex = [Math]::Min(100, [Math]::Max(0, $correlationDifference * 100))

    # Nous n'utilisons pas directement le z-score ici, mais nous calculons la p-value

    # Calculer les erreurs standard pour les deux coefficients
    $linearStandardError = 1 / [Math]::Sqrt($SampleSize - 3)
    $logStandardError = 1 / [Math]::Sqrt($SampleSize - 3)

    # Calculer la statistique Z pour la différence entre les coefficients
    # Utiliser la transformation de Fisher pour normaliser les coefficients
    $linearFisherZ = 0.5 * [Math]::Log((1 + [Math]::Abs($LinearCorrelation)) / (1 - [Math]::Abs($LinearCorrelation)))
    $logFisherZ = 0.5 * [Math]::Log((1 + [Math]::Abs($LogTransformedCorrelation)) / (1 - [Math]::Abs($LogTransformedCorrelation)))
    $fisherZDifference = $logFisherZ - $linearFisherZ
    $differenceStandardError = [Math]::Sqrt($linearStandardError * $linearStandardError + $logStandardError * $logStandardError)
    $zStatistic = $fisherZDifference / $differenceStandardError

    # Calculer la p-value pour la différence (approximation)
    # Utiliser une fonction simplifiée pour la distribution normale
    $pValue = if ($zStatistic -le 0) {
        0.5
    } else {
        # Approximation de la fonction de répartition de la loi normale centrée réduite
        $t = 1 / (1 + 0.2316419 * $zStatistic)
        $d = 0.3989423 * [Math]::Exp(-$zStatistic * $zStatistic / 2)
        $p = $d * $t * (0.3193815 + $t * (-0.3565638 + $t * (1.781478 + $t * (-1.821256 + $t * 1.330274))))
        1 - $p
    }

    # Déterminer si la relation exponentielle est statistiquement significative
    $isSignificant = $pValue -lt (1 - $ConfidenceLevel)

    # Nous utilisons directement la p-value et isSignificant pour l'évaluation

    # Déterminer le niveau de confiance dans la détection
    $detectionConfidenceLevel = if ($nonLinearityIndex -ge 50 -and $isSignificant) {
        "Élevé"
    } elseif ($nonLinearityIndex -ge 30 -and $isSignificant) {
        "Moyen"
    } elseif ($nonLinearityIndex -ge 10 -or $isSignificant) {
        "Faible"
    } else {
        "Très faible"
    }

    # Déterminer le type de relation exponentielle (croissance ou décroissance)
    $relationshipType = if ($LogTransformedCorrelation -gt 0) {
        "Croissance exponentielle"
    } else {
        "Décroissance exponentielle"
    }

    # Générer des recommandations
    $recommendations = @()

    if ($detectionConfidenceLevel -eq "Élevé" -or $detectionConfidenceLevel -eq "Moyen") {
        $recommendations += "Une relation exponentielle ($relationshipType) est probable. Envisager d'utiliser des transformations logarithmiques pour l'analyse."
    }

    if ($nonLinearityIndex -ge 30 -and -not $isSignificant) {
        $recommendations += "L'indice de non-linéarité est élevé mais la différence n'est pas statistiquement significative. Augmenter la taille de l'échantillon pour confirmer."
    }

    if ([Math]::Abs($LinearCorrelation) -lt 0.3 -and [Math]::Abs($LogTransformedCorrelation) -ge 0.5) {
        $recommendations += "La corrélation linéaire est faible mais la corrélation après transformation logarithmique est modérée à forte. Une relation exponentielle est probable."
    }

    if ($SampleSize -lt 30) {
        $recommendations += "La taille de l'échantillon est petite. Les résultats peuvent ne pas être fiables."
    }

    # Retourner les résultats
    return @{
        LinearCorrelation         = $LinearCorrelation
        LogTransformedCorrelation = $LogTransformedCorrelation
        SampleSize                = $SampleSize
        CorrelationDifference     = $correlationDifference
        NonLinearityIndex         = $nonLinearityIndex
        ZStatistic                = $zStatistic
        PValue                    = $pValue
        IsSignificant             = $isSignificant
        ConfidenceLevel           = $ConfidenceLevel
        DetectionConfidenceLevel  = $detectionConfidenceLevel
        RelationshipType          = $relationshipType
        Recommendations           = $recommendations
    }
}

<#
.SYNOPSIS
    Définit les seuils de sensibilité pour la détection des corrélations complexes.

.DESCRIPTION
    Cette fonction définit les seuils de sensibilité pour la détection des corrélations complexes
    en fonction du type de relation non linéaire et du niveau de précision requis.

.PARAMETER RelationshipType
    Le type de relation non linéaire.
    Valeurs possibles : "Quadratique", "Exponentielle", "Logarithmique", "Puissance", "Périodique", "Complexe".

.PARAMETER PrecisionLevel
    Le niveau de précision requis.
    Valeurs possibles : "Faible", "Moyen", "Élevé", "Très élevé".

.PARAMETER SampleSizeCategory
    La catégorie de taille d'échantillon.
    Valeurs possibles : "Petit" (< 30), "Moyen" (30-100), "Grand" (> 100).

.EXAMPLE
    $thresholds = Get-NonLinearCorrelationThresholds -RelationshipType "Quadratique" -PrecisionLevel "Élevé" -SampleSizeCategory "Moyen"

.OUTPUTS
    Un objet hashtable contenant les seuils de sensibilité pour la détection des corrélations complexes.
#>
function Get-NonLinearCorrelationThresholds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Quadratique", "Exponentielle", "Logarithmique", "Puissance", "Périodique", "Complexe")]
        [string]$RelationshipType,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Faible", "Moyen", "Élevé", "Très élevé")]
        [string]$PrecisionLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Petit", "Moyen", "Grand")]
        [string]$SampleSizeCategory
    )

    # Définir les seuils de base pour chaque type de relation
    $baseThresholds = @{
        "Quadratique"   = @{
            "MinNonLinearityIndex"        = 20   # Indice minimal de non-linéarité
            "MinCorrelationDifference"    = 0.15 # Différence minimale entre corrélations
            "MaxPValue"                   = 0.05 # P-value maximale pour la significativité
            "MinDetectionConfidenceLevel" = "Moyen"
            "TransformationRecommended"   = "Régression polynomiale de degré 2"
        }
        "Exponentielle" = @{
            "MinNonLinearityIndex"        = 25
            "MinCorrelationDifference"    = 0.2
            "MaxPValue"                   = 0.05
            "MinDetectionConfidenceLevel" = "Moyen"
            "TransformationRecommended"   = "Transformation logarithmique"
        }
        "Logarithmique" = @{
            "MinNonLinearityIndex"        = 25
            "MinCorrelationDifference"    = 0.2
            "MaxPValue"                   = 0.05
            "MinDetectionConfidenceLevel" = "Moyen"
            "TransformationRecommended"   = "Transformation exponentielle"
        }
        "Puissance"     = @{
            "MinNonLinearityIndex"        = 30
            "MinCorrelationDifference"    = 0.25
            "MaxPValue"                   = 0.05
            "MinDetectionConfidenceLevel" = "Moyen"
            "TransformationRecommended"   = "Transformation log-log"
        }
        "Périodique"    = @{
            "MinNonLinearityIndex"        = 35
            "MinCorrelationDifference"    = 0.3
            "MaxPValue"                   = 0.01
            "MinDetectionConfidenceLevel" = "Élevé"
            "TransformationRecommended"   = "Analyse de Fourier ou modèles sinusoïdaux"
        }
        "Complexe"      = @{
            "MinNonLinearityIndex"        = 40
            "MinCorrelationDifference"    = 0.35
            "MaxPValue"                   = 0.01
            "MinDetectionConfidenceLevel" = "Élevé"
            "TransformationRecommended"   = "Méthodes non paramétriques ou apprentissage automatique"
        }
    }

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultipliers = @{
        "Faible"     = 0.7  # Seuils plus permissifs
        "Moyen"      = 1.0  # Seuils de base
        "Élevé"      = 1.3  # Seuils plus stricts
        "Très élevé" = 1.5  # Seuils très stricts
    }

    # Ajuster les seuils en fonction de la taille d'échantillon
    $sampleSizeAdjustments = @{
        "Petit" = @{
            "MinNonLinearityIndexMultiplier"     = 1.2  # Exigence plus élevée pour les petits échantillons
            "MinCorrelationDifferenceMultiplier" = 1.3
            "MaxPValueMultiplier"                = 0.5  # P-value plus stricte (plus petite)
        }
        "Moyen" = @{
            "MinNonLinearityIndexMultiplier"     = 1.0  # Pas d'ajustement
            "MinCorrelationDifferenceMultiplier" = 1.0
            "MaxPValueMultiplier"                = 1.0
        }
        "Grand" = @{
            "MinNonLinearityIndexMultiplier"     = 0.8  # Exigence moins élevée pour les grands échantillons
            "MinCorrelationDifferenceMultiplier" = 0.7
            "MaxPValueMultiplier"                = 2.0  # P-value moins stricte (plus grande)
        }
    }

    # Sélectionner les seuils de base pour le type de relation
    $thresholds = $baseThresholds[$RelationshipType].Clone()

    # Ajuster les seuils en fonction du niveau de précision
    $precisionMultiplier = $precisionMultipliers[$PrecisionLevel]
    $thresholds["MinNonLinearityIndex"] *= $precisionMultiplier
    $thresholds["MinCorrelationDifference"] *= $precisionMultiplier
    $thresholds["MaxPValue"] /= $precisionMultiplier  # Division car plus petit = plus strict

    # Ajuster les seuils en fonction de la taille d'échantillon
    $sizeAdjustments = $sampleSizeAdjustments[$SampleSizeCategory]
    $thresholds["MinNonLinearityIndex"] *= $sizeAdjustments["MinNonLinearityIndexMultiplier"]
    $thresholds["MinCorrelationDifference"] *= $sizeAdjustments["MinCorrelationDifferenceMultiplier"]
    $thresholds["MaxPValue"] *= $sizeAdjustments["MaxPValueMultiplier"]

    # Ajuster le niveau de confiance minimal en fonction de la précision et de la taille d'échantillon
    $confidenceLevels = @("Très faible", "Faible", "Moyen", "Élevé", "Très élevé")
    $baseConfidenceIndex = [Array]::IndexOf($confidenceLevels, $thresholds["MinDetectionConfidenceLevel"])

    # Ajuster l'indice en fonction de la précision (plus élevé = plus strict)
    $precisionAdjustment = switch ($PrecisionLevel) {
        "Faible" { -1 }
        "Moyen" { 0 }
        "Élevé" { 1 }
        "Très élevé" { 2 }
    }

    # Ajuster l'indice en fonction de la taille d'échantillon (plus grand = moins strict)
    $sizeAdjustment = switch ($SampleSizeCategory) {
        "Petit" { 1 }
        "Moyen" { 0 }
        "Grand" { -1 }
    }

    # Calculer le nouvel indice et s'assurer qu'il est dans les limites
    $adjustedConfidenceIndex = [Math]::Max(0, [Math]::Min(4, $baseConfidenceIndex + $precisionAdjustment + $sizeAdjustment))
    $thresholds["MinDetectionConfidenceLevel"] = $confidenceLevels[$adjustedConfidenceIndex]

    # Générer des recommandations spécifiques
    $recommendations = @()

    if ($SampleSizeCategory -eq "Petit") {
        $recommendations += "Pour les petits échantillons, les seuils sont plus stricts pour éviter les faux positifs. Envisager d'augmenter la taille de l'échantillon."
    }

    if ($PrecisionLevel -eq "Très élevé") {
        $recommendations += "Les seuils très élevés peuvent conduire à des faux négatifs. Vérifier visuellement les données avec des graphiques de dispersion."
    }

    if ($RelationshipType -eq "Complexe" -or $RelationshipType -eq "Périodique") {
        $recommendations += "Les relations $RelationshipType sont difficiles à détecter avec des méthodes simples. Envisager des approches plus sophistiquées."
    }

    # Ajouter les recommandations aux seuils
    $thresholds["Recommendations"] = $recommendations

    # Ajouter des informations supplémentaires
    $thresholds["RelationshipType"] = $RelationshipType
    $thresholds["PrecisionLevel"] = $PrecisionLevel
    $thresholds["SampleSizeCategory"] = $SampleSizeCategory

    return $thresholds
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-PearsonCorrelationPrecisionCriteria, Get-SpearmanCorrelationPrecisionCriteria, Get-CorrelationErrorThresholds, Test-CorrelationOutlierResistance, Test-CorrelationSamplingStability, Get-CorrelationRobustnessThresholds, Test-QuadraticRelationship, Test-ExponentialRelationship, Get-NonLinearCorrelationThresholds
