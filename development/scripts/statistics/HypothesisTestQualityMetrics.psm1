# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour dÃ©finir les mÃ©triques de qualitÃ© pour les tests d'hypothÃ¨ses.

.DESCRIPTION
    Ce module fournit des fonctions pour Ã©valuer la qualitÃ© des tests d'hypothÃ¨ses,
    notamment en termes de puissance statistique, contrÃ´le des erreurs, robustesse
    et efficacitÃ© computationnelle.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

#region Variables globales et constantes

# Table des valeurs Z pour diffÃ©rents niveaux de confiance
$script:ZScoreTable = @{
    0.80  = 1.282
    0.85  = 1.440
    0.90  = 1.645
    0.95  = 1.960
    0.975 = 2.240
    0.99  = 2.576
    0.995 = 2.807
    0.999 = 3.291
}

# Seuils de puissance statistique recommandÃ©s par domaine d'application
$script:PowerThresholds = @{
    "Recherche exploratoire"       = 0.70
    "Recherche standard"           = 0.80
    "Recherche clinique"           = 0.85
    "Recherche critique"           = 0.90
    "Recherche de haute prÃ©cision" = 0.95
}

# Seuils d'effet (Cohen's d) par taille
$script:EffectSizeThresholds = @{
    "Petit"      = 0.2
    "Moyen"      = 0.5
    "Grand"      = 0.8
    "TrÃ¨s grand" = 1.2
}

#endregion

#region Fonctions utilitaires

<#
.SYNOPSIS
    Obtient la valeur Z pour un niveau de confiance donnÃ©.

.DESCRIPTION
    Cette fonction retourne la valeur Z correspondant Ã  un niveau de confiance spÃ©cifiÃ©.
    Si le niveau de confiance exact n'est pas dans la table, la valeur la plus proche est utilisÃ©e.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaitÃ© (entre 0 et 1).

.EXAMPLE
    Get-ZScore -ConfidenceLevel 0.95
    Retourne 1.96 (valeur Z pour un niveau de confiance de 95%).

.OUTPUTS
    System.Double
#>
function Get-ZScore {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceLevel
    )

    # VÃ©rifier si le niveau de confiance est directement dans la table
    if ($script:ZScoreTable.ContainsKey($ConfidenceLevel)) {
        return $script:ZScoreTable[$ConfidenceLevel]
    }

    # Sinon, trouver la valeur la plus proche
    $closestKey = $script:ZScoreTable.Keys |
        ForEach-Object { [PSCustomObject]@{ Key = $_; Diff = [Math]::Abs($_ - $ConfidenceLevel) } } |
        Sort-Object Diff |
        Select-Object -First 1 -ExpandProperty Key

    return $script:ZScoreTable[$closestKey]
}

<#
.SYNOPSIS
    Calcule la taille d'Ã©chantillon requise pour un test d'hypothÃ¨se.

.DESCRIPTION
    Cette fonction calcule la taille d'Ã©chantillon nÃ©cessaire pour atteindre une puissance
    statistique donnÃ©e, Ã©tant donnÃ© une taille d'effet et un niveau de signification.

.PARAMETER EffectSize
    La taille d'effet attendue (Cohen's d).

.PARAMETER Power
    La puissance statistique souhaitÃ©e (entre 0 et 1).

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par dÃ©faut 0.05).

.PARAMETER TestType
    Le type de test (unilatÃ©ral ou bilatÃ©ral, par dÃ©faut "bilatÃ©ral").

.EXAMPLE
    Get-RequiredSampleSize -EffectSize 0.5 -Power 0.8 -Alpha 0.05 -TestType "bilatÃ©ral"
    Calcule la taille d'Ã©chantillon nÃ©cessaire pour dÃ©tecter un effet moyen avec une puissance de 80%.

.OUTPUTS
    System.Int32
#>
function Get-RequiredSampleSize {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0.01, 5)]
        [double]$EffectSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Power,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 0.5)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("unilatÃ©ral", "bilatÃ©ral")]
        [string]$TestType = "bilatÃ©ral"
    )

    # Obtenir les valeurs Z pour alpha et power
    $zAlpha = if ($TestType -eq "bilatÃ©ral") {
        Get-ZScore -ConfidenceLevel (1 - $Alpha / 2)
    } else {
        Get-ZScore -ConfidenceLevel (1 - $Alpha)
    }

    $zPower = Get-ZScore -ConfidenceLevel $Power

    # Calculer la taille d'Ã©chantillon (formule pour test de comparaison de moyennes)
    $n = [Math]::Ceiling(2 * [Math]::Pow(($zAlpha + $zPower) / $EffectSize, 2))

    return $n
}

<#
.SYNOPSIS
    Calcule la puissance statistique pour un test d'hypothÃ¨se.

.DESCRIPTION
    Cette fonction calcule la puissance statistique d'un test d'hypothÃ¨se
    Ã©tant donnÃ© une taille d'effet, une taille d'Ã©chantillon et un niveau de signification.

.PARAMETER EffectSize
    La taille d'effet attendue (Cohen's d).

.PARAMETER SampleSize
    La taille de l'Ã©chantillon.

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par dÃ©faut 0.05).

.PARAMETER TestType
    Le type de test (unilatÃ©ral ou bilatÃ©ral, par dÃ©faut "bilatÃ©ral").

.EXAMPLE
    Get-StatisticalPower -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilatÃ©ral"
    Calcule la puissance statistique pour dÃ©tecter un effet moyen avec un Ã©chantillon de 64 sujets.

.OUTPUTS
    System.Double
#>
function Get-StatisticalPower {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0.01, 5)]
        [double]$EffectSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 0.5)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("unilatÃ©ral", "bilatÃ©ral")]
        [string]$TestType = "bilatÃ©ral"
    )

    # Obtenir la valeur Z pour alpha
    $zAlpha = if ($TestType -eq "bilatÃ©ral") {
        Get-ZScore -ConfidenceLevel (1 - $Alpha / 2)
    } else {
        Get-ZScore -ConfidenceLevel (1 - $Alpha)
    }

    # Calculer le paramÃ¨tre non-centralitÃ©
    $ncp = $EffectSize * [Math]::Sqrt($SampleSize / 2)

    # Calculer la puissance (approximation)
    $zBeta = $ncp - $zAlpha

    # Convertir z-score en probabilitÃ© (approximation de la fonction de rÃ©partition de la loi normale)
    $power = if ($zBeta -le 0) {
        0.5
    } else {
        # Approximation de la fonction de rÃ©partition de la loi normale centrÃ©e rÃ©duite
        $t = 1 / (1 + 0.2316419 * $zBeta)
        $d = 0.3989423 * [Math]::Exp(-$zBeta * $zBeta / 2)
        $p = $d * $t * (0.3193815 + $t * (-0.3565638 + $t * (1.781478 + $t * (-1.821256 + $t * 1.330274))))
        1 - $p
    }

    return [Math]::Min(1, [Math]::Max(0, $power))
}

#endregion

#region Fonctions principales

<#
.SYNOPSIS
    Ã‰tablit les critÃ¨res de puissance statistique pour un test d'hypothÃ¨se.

.DESCRIPTION
    Cette fonction Ã©value la puissance statistique d'un test d'hypothÃ¨se et fournit
    des recommandations basÃ©es sur les critÃ¨res de qualitÃ© Ã©tablis.

.PARAMETER EffectSize
    La taille d'effet attendue ou observÃ©e (Cohen's d).

.PARAMETER SampleSize
    La taille de l'Ã©chantillon utilisÃ© ou prÃ©vu.

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par dÃ©faut 0.05).

.PARAMETER TestType
    Le type de test (unilatÃ©ral ou bilatÃ©ral, par dÃ©faut "bilatÃ©ral").

.PARAMETER ApplicationDomain
    Le domaine d'application de la recherche (par dÃ©faut "Recherche standard").

.EXAMPLE
    Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
    Ã‰value la puissance statistique et fournit des recommandations pour un test avec un effet moyen et 64 sujets.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-PowerStatisticsCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0.01, 5)]
        [double]$EffectSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 0.5)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("unilatÃ©ral", "bilatÃ©ral")]
        [string]$TestType = "bilatÃ©ral",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Recherche exploratoire", "Recherche standard", "Recherche clinique", "Recherche critique", "Recherche de haute prÃ©cision")]
        [string]$ApplicationDomain = "Recherche standard"
    )

    # Calculer la puissance statistique
    $power = Get-StatisticalPower -EffectSize $EffectSize -SampleSize $SampleSize -Alpha $Alpha -TestType $TestType

    # DÃ©terminer le seuil de puissance recommandÃ© pour le domaine d'application
    $recommendedPower = $script:PowerThresholds[$ApplicationDomain]

    # Ã‰valuer si la puissance est suffisante
    $isPowerSufficient = $power -ge $recommendedPower

    # Calculer la taille d'Ã©chantillon recommandÃ©e si la puissance est insuffisante
    $recommendedSampleSize = if (-not $isPowerSufficient) {
        Get-RequiredSampleSize -EffectSize $EffectSize -Power $recommendedPower -Alpha $Alpha -TestType $TestType
    } else {
        $SampleSize
    }

    # DÃ©terminer la taille d'effet (petit, moyen, grand)
    $effectSizeCategory = "PersonnalisÃ©"
    foreach ($category in $script:EffectSizeThresholds.Keys) {
        if ($EffectSize -ge $script:EffectSizeThresholds[$category]) {
            $effectSizeCategory = $category
        }
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if (-not $isPowerSufficient) {
        $recommendations += "La puissance statistique est insuffisante pour le domaine d'application spÃ©cifiÃ©."
        $recommendations += "Augmenter la taille de l'Ã©chantillon Ã  au moins $recommendedSampleSize pour atteindre une puissance de $recommendedPower."
    } else {
        $recommendations += "La puissance statistique est suffisante pour le domaine d'application spÃ©cifiÃ©."
    }

    if ($effectSizeCategory -eq "Petit" -and $power -lt 0.8) {
        $recommendations += "Pour dÃ©tecter un effet de petite taille, une puissance d'au moins 0.8 est gÃ©nÃ©ralement recommandÃ©e."
    }

    if ($Alpha -gt 0.01 -and $ApplicationDomain -in @("Recherche clinique", "Recherche critique", "Recherche de haute prÃ©cision")) {
        $recommendations += "Pour $ApplicationDomain, envisager de rÃ©duire le niveau de signification (alpha) Ã  0.01 pour minimiser le risque d'erreur de type I."
    }

    # Retourner les rÃ©sultats
    return @{
        EffectSize            = $EffectSize
        EffectSizeCategory    = $effectSizeCategory
        SampleSize            = $SampleSize
        Alpha                 = $Alpha
        TestType              = $TestType
        ApplicationDomain     = $ApplicationDomain
        CalculatedPower       = $power
        RecommendedPower      = $recommendedPower
        IsPowerSufficient     = $isPowerSufficient
        RecommendedSampleSize = $recommendedSampleSize
        Recommendations       = $recommendations
    }
}

#endregion

<#
.SYNOPSIS
    DÃ©finit les mÃ©triques de contrÃ´le des erreurs de type I et II pour les tests d'hypothÃ¨ses.

.DESCRIPTION
    Cette fonction Ã©value les risques d'erreurs de type I (faux positifs) et de type II (faux nÃ©gatifs)
    pour un test d'hypothÃ¨se et fournit des recommandations pour leur contrÃ´le.

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I).

.PARAMETER Power
    La puissance statistique (1 - risque d'erreur de type II).

.PARAMETER SampleSize
    La taille de l'Ã©chantillon utilisÃ© ou prÃ©vu.

.PARAMETER EffectSize
    La taille d'effet attendue ou observÃ©e (Cohen's d).

.PARAMETER TestType
    Le type de test (unilatÃ©ral ou bilatÃ©ral, par dÃ©faut "bilatÃ©ral").

.PARAMETER ApplicationDomain
    Le domaine d'application de la recherche (par dÃ©faut "Recherche standard").

.PARAMETER MultipleTestingCorrection
    La mÃ©thode de correction pour les tests multiples (par dÃ©faut "Aucune").

.PARAMETER NumberOfTests
    Le nombre de tests effectuÃ©s (pertinent uniquement si MultipleTestingCorrection n'est pas "Aucune").

.EXAMPLE
    Get-ErrorControlMetrics -Alpha 0.05 -Power 0.8 -SampleSize 64 -EffectSize 0.5 -TestType "bilatÃ©ral" -ApplicationDomain "Recherche standard"
    Ã‰value les risques d'erreurs et fournit des recommandations pour leur contrÃ´le.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ErrorControlMetrics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0.001, 0.5)]
        [double]$Alpha,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Power,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0.01, 5)]
        [double]$EffectSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("unilatÃ©ral", "bilatÃ©ral")]
        [string]$TestType = "bilatÃ©ral",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Recherche exploratoire", "Recherche standard", "Recherche clinique", "Recherche critique", "Recherche de haute prÃ©cision")]
        [string]$ApplicationDomain = "Recherche standard",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Aucune", "Bonferroni", "Holm", "Benjamini-Hochberg", "Å idÃ¡k")]
        [string]$MultipleTestingCorrection = "Aucune",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10000)]
        [int]$NumberOfTests = 1
    )

    # Calculer le risque d'erreur de type II (bÃªta)
    $beta = 1 - $Power

    # Calculer l'alpha ajustÃ© en fonction de la mÃ©thode de correction pour tests multiples
    $adjustedAlpha = switch ($MultipleTestingCorrection) {
        "Aucune" { $Alpha }
        "Bonferroni" { $Alpha / $NumberOfTests }
        "Å idÃ¡k" { 1 - [Math]::Pow(1 - $Alpha, 1 / $NumberOfTests) }
        "Holm" { $Alpha } # Valeur initiale, l'ajustement de Holm est sÃ©quentiel et dÃ©pend des p-values
        "Benjamini-Hochberg" { $Alpha } # Valeur initiale, l'ajustement BH dÃ©pend des p-values ordonnÃ©es
        default { $Alpha }
    }

    # Calculer le ratio de faux positifs attendu (si H0 est vraie)
    $falsePositiveRate = $adjustedAlpha

    # Calculer le ratio de faux nÃ©gatifs attendu (si H1 est vraie)
    $falseNegativeRate = $beta

    # Calculer le ratio de vrais positifs attendu (si H1 est vraie)
    $truePositiveRate = $Power

    # Calculer le ratio de vrais nÃ©gatifs attendu (si H0 est vraie)
    $trueNegativeRate = 1 - $adjustedAlpha

    # DÃ©terminer les seuils recommandÃ©s en fonction du domaine d'application
    $recommendedAlpha = switch ($ApplicationDomain) {
        "Recherche exploratoire" { 0.10 }
        "Recherche standard" { 0.05 }
        "Recherche clinique" { 0.01 }
        "Recherche critique" { 0.005 }
        "Recherche de haute prÃ©cision" { 0.001 }
        default { 0.05 }
    }

    $recommendedBeta = switch ($ApplicationDomain) {
        "Recherche exploratoire" { 0.30 }
        "Recherche standard" { 0.20 }
        "Recherche clinique" { 0.15 }
        "Recherche critique" { 0.10 }
        "Recherche de haute prÃ©cision" { 0.05 }
        default { 0.20 }
    }

    # DÃ©terminer si les risques d'erreur sont acceptables
    $isAlphaAcceptable = $adjustedAlpha -le $recommendedAlpha
    $isBetaAcceptable = $beta -le $recommendedBeta

    # Calculer le ratio alpha/beta (Ã©quilibre entre les types d'erreurs)
    $alphaToBetalRatio = if ($beta -ne 0) { $adjustedAlpha / $beta } else { [double]::PositiveInfinity }

    # Ã‰valuer l'Ã©quilibre entre les erreurs de type I et II
    $errorBalanceCategory = if ($alphaToBetalRatio -lt 0.1) {
        "Fortement biaisÃ© vers l'erreur de type II"
    } elseif ($alphaToBetalRatio -lt 0.5) {
        "BiaisÃ© vers l'erreur de type II"
    } elseif ($alphaToBetalRatio -gt 10) {
        "Fortement biaisÃ© vers l'erreur de type I"
    } elseif ($alphaToBetalRatio -gt 2) {
        "BiaisÃ© vers l'erreur de type I"
    } else {
        "Ã‰quilibrÃ©"
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if (-not $isAlphaAcceptable) {
        $recommendations += "Le risque d'erreur de type I (alpha = $([Math]::Round($adjustedAlpha, 4))) est supÃ©rieur au seuil recommandÃ© ($recommendedAlpha) pour $ApplicationDomain."
        $recommendations += "Envisager de rÃ©duire le niveau de signification Ã  $recommendedAlpha."
    }

    if (-not $isBetaAcceptable) {
        $recommendations += "Le risque d'erreur de type II (bÃªta = $([Math]::Round($beta, 4))) est supÃ©rieur au seuil recommandÃ© ($recommendedBeta) pour $ApplicationDomain."
        $recommendations += "Envisager d'augmenter la taille de l'Ã©chantillon pour amÃ©liorer la puissance statistique."
    }

    if ($NumberOfTests -gt 1 -and $MultipleTestingCorrection -eq "Aucune") {
        $recommendations += "Aucune correction pour tests multiples n'est appliquÃ©e alors que $NumberOfTests tests sont effectuÃ©s."
        $recommendations += "Envisager d'appliquer une correction comme Bonferroni ou Benjamini-Hochberg pour contrÃ´ler le taux d'erreur global."
    }

    if ($errorBalanceCategory -match "Fortement biaisÃ©") {
        $recommendations += "L'Ã©quilibre entre les erreurs de type I et II est $errorBalanceCategory."
        if ($alphaToBetalRatio -lt 0.1) {
            $recommendations += "Envisager d'augmenter alpha ou de rÃ©duire bÃªta pour un meilleur Ã©quilibre."
        } elseif ($alphaToBetalRatio -gt 10) {
            $recommendations += "Envisager de rÃ©duire alpha ou d'augmenter bÃªta pour un meilleur Ã©quilibre."
        }
    }

    if ($MultipleTestingCorrection -eq "Bonferroni" -and $NumberOfTests -gt 20) {
        $recommendations += "La correction de Bonferroni peut Ãªtre trop conservative pour $NumberOfTests tests."
        $recommendations += "Envisager d'utiliser la mÃ©thode de Benjamini-Hochberg pour contrÃ´ler le taux de fausses dÃ©couvertes."
    }

    # Retourner les rÃ©sultats
    return @{
        Alpha                     = $Alpha
        AdjustedAlpha             = $adjustedAlpha
        Beta                      = $beta
        Power                     = $Power
        SampleSize                = $SampleSize
        EffectSize                = $EffectSize
        TestType                  = $TestType
        ApplicationDomain         = $ApplicationDomain
        MultipleTestingCorrection = $MultipleTestingCorrection
        NumberOfTests             = $NumberOfTests
        FalsePositiveRate         = $falsePositiveRate
        FalseNegativeRate         = $falseNegativeRate
        TruePositiveRate          = $truePositiveRate
        TrueNegativeRate          = $trueNegativeRate
        RecommendedAlpha          = $recommendedAlpha
        RecommendedBeta           = $recommendedBeta
        IsAlphaAcceptable         = $isAlphaAcceptable
        IsBetaAcceptable          = $isBetaAcceptable
        AlphaToBetaRatio          = $alphaToBetalRatio
        ErrorBalanceCategory      = $errorBalanceCategory
        Recommendations           = $recommendations
    }
}

<#
.SYNOPSIS
    Ã‰tablit les critÃ¨res de robustesse pour les tests paramÃ©triques et non-paramÃ©triques.

.DESCRIPTION
    Cette fonction Ã©value la robustesse d'un test d'hypothÃ¨se face aux violations des hypothÃ¨ses
    sous-jacentes et fournit des recommandations pour le choix entre tests paramÃ©triques et non-paramÃ©triques.

.PARAMETER TestType
    Le type de test (paramÃ©trique ou non-paramÃ©trique).

.PARAMETER SampleSize
    La taille de l'Ã©chantillon utilisÃ© ou prÃ©vu.

.PARAMETER DistributionType
    Le type de distribution des donnÃ©es.

.PARAMETER VarianceHomogeneity
    Le niveau d'homogÃ©nÃ©itÃ© des variances (pour les tests de comparaison).

.PARAMETER OutlierPercentage
    Le pourcentage de valeurs aberrantes dans les donnÃ©es.

.PARAMETER MissingDataPercentage
    Le pourcentage de donnÃ©es manquantes.

.PARAMETER ApplicationDomain
    Le domaine d'application de la recherche (par dÃ©faut "Recherche standard").

.EXAMPLE
    Get-TestRobustnessCriteria -TestType "ParamÃ©trique" -SampleSize 30 -DistributionType "Normale" -VarianceHomogeneity "Ã‰levÃ©e" -OutlierPercentage 2 -MissingDataPercentage 5 -ApplicationDomain "Recherche standard"
    Ã‰value la robustesse d'un test paramÃ©trique et fournit des recommandations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-TestRobustnessCriteria {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ParamÃ©trique", "Non-paramÃ©trique")]
        [string]$TestType,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Normale", "AsymÃ©trique", "Multimodale", "Queue lourde", "Mixte", "Inconnue")]
        [string]$DistributionType,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TrÃ¨s Ã©levÃ©e", "Ã‰levÃ©e", "ModÃ©rÃ©e", "Faible", "TrÃ¨s faible", "Inconnue")]
        [string]$VarianceHomogeneity = "Inconnue",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$OutlierPercentage = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [double]$MissingDataPercentage = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Recherche exploratoire", "Recherche standard", "Recherche clinique", "Recherche critique", "Recherche de haute prÃ©cision")]
        [string]$ApplicationDomain = "Recherche standard"
    )

    # Calculer le score de robustesse pour les tests paramÃ©triques
    $parametricRobustnessScore = 100

    # Ajuster le score en fonction de la taille d'Ã©chantillon
    if ($SampleSize -lt 10) {
        $parametricRobustnessScore -= 50
    } elseif ($SampleSize -lt 20) {
        $parametricRobustnessScore -= 30
    } elseif ($SampleSize -lt 30) {
        $parametricRobustnessScore -= 15
    } elseif ($SampleSize -lt 50) {
        $parametricRobustnessScore -= 5
    }

    # Ajuster le score en fonction du type de distribution
    switch ($DistributionType) {
        "Normale" { $parametricRobustnessScore -= 0 }
        "AsymÃ©trique" { $parametricRobustnessScore -= 15 }
        "Multimodale" { $parametricRobustnessScore -= 25 }
        "Queue lourde" { $parametricRobustnessScore -= 30 }
        "Mixte" { $parametricRobustnessScore -= 35 }
        "Inconnue" { $parametricRobustnessScore -= 20 }
    }

    # Ajuster le score en fonction de l'homogÃ©nÃ©itÃ© des variances
    switch ($VarianceHomogeneity) {
        "TrÃ¨s Ã©levÃ©e" { $parametricRobustnessScore -= 0 }
        "Ã‰levÃ©e" { $parametricRobustnessScore -= 5 }
        "ModÃ©rÃ©e" { $parametricRobustnessScore -= 15 }
        "Faible" { $parametricRobustnessScore -= 25 }
        "TrÃ¨s faible" { $parametricRobustnessScore -= 35 }
        "Inconnue" { $parametricRobustnessScore -= 20 }
    }

    # Ajuster le score en fonction du pourcentage de valeurs aberrantes
    if ($OutlierPercentage -gt 10) {
        $parametricRobustnessScore -= 40
    } elseif ($OutlierPercentage -gt 5) {
        $parametricRobustnessScore -= 25
    } elseif ($OutlierPercentage -gt 2) {
        $parametricRobustnessScore -= 15
    } elseif ($OutlierPercentage -gt 0) {
        $parametricRobustnessScore -= 5
    }

    # Ajuster le score en fonction du pourcentage de donnÃ©es manquantes
    if ($MissingDataPercentage -gt 20) {
        $parametricRobustnessScore -= 40
    } elseif ($MissingDataPercentage -gt 10) {
        $parametricRobustnessScore -= 25
    } elseif ($MissingDataPercentage -gt 5) {
        $parametricRobustnessScore -= 15
    } elseif ($MissingDataPercentage -gt 0) {
        $parametricRobustnessScore -= 5
    }

    # S'assurer que le score reste dans l'intervalle [0, 100]
    $parametricRobustnessScore = [Math]::Max(0, [Math]::Min(100, $parametricRobustnessScore))

    # Calculer le score de robustesse pour les tests non-paramÃ©triques
    $nonParametricRobustnessScore = 80 # Base plus faible car moins puissants en gÃ©nÃ©ral

    # Ajuster le score en fonction de la taille d'Ã©chantillon
    if ($SampleSize -lt 5) {
        $nonParametricRobustnessScore -= 40
    } elseif ($SampleSize -lt 10) {
        $nonParametricRobustnessScore -= 20
    } elseif ($SampleSize -lt 15) {
        $nonParametricRobustnessScore -= 10
    } elseif ($SampleSize -lt 20) {
        $nonParametricRobustnessScore -= 5
    }

    # Ajuster le score en fonction du type de distribution (moins sensible)
    switch ($DistributionType) {
        "Normale" { $nonParametricRobustnessScore -= 0 }
        "AsymÃ©trique" { $nonParametricRobustnessScore -= 0 }
        "Multimodale" { $nonParametricRobustnessScore -= 5 }
        "Queue lourde" { $nonParametricRobustnessScore -= 0 }
        "Mixte" { $nonParametricRobustnessScore -= 5 }
        "Inconnue" { $nonParametricRobustnessScore -= 5 }
    }

    # Ajuster le score en fonction de l'homogÃ©nÃ©itÃ© des variances (moins sensible)
    switch ($VarianceHomogeneity) {
        "TrÃ¨s Ã©levÃ©e" { $nonParametricRobustnessScore -= 0 }
        "Ã‰levÃ©e" { $nonParametricRobustnessScore -= 0 }
        "ModÃ©rÃ©e" { $nonParametricRobustnessScore -= 5 }
        "Faible" { $nonParametricRobustnessScore -= 10 }
        "TrÃ¨s faible" { $nonParametricRobustnessScore -= 15 }
        "Inconnue" { $nonParametricRobustnessScore -= 10 }
    }

    # Ajuster le score en fonction du pourcentage de valeurs aberrantes (moins sensible)
    if ($OutlierPercentage -gt 15) {
        $nonParametricRobustnessScore -= 15
    } elseif ($OutlierPercentage -gt 10) {
        $nonParametricRobustnessScore -= 10
    } elseif ($OutlierPercentage -gt 5) {
        $nonParametricRobustnessScore -= 5
    }

    # Ajuster le score en fonction du pourcentage de donnÃ©es manquantes
    if ($MissingDataPercentage -gt 30) {
        $nonParametricRobustnessScore -= 30
    } elseif ($MissingDataPercentage -gt 20) {
        $nonParametricRobustnessScore -= 20
    } elseif ($MissingDataPercentage -gt 10) {
        $nonParametricRobustnessScore -= 10
    } elseif ($MissingDataPercentage -gt 5) {
        $nonParametricRobustnessScore -= 5
    }

    # S'assurer que le score reste dans l'intervalle [0, 100]
    $nonParametricRobustnessScore = [Math]::Max(0, [Math]::Min(100, $nonParametricRobustnessScore))

    # DÃ©terminer le test recommandÃ© en fonction des scores de robustesse
    $recommendedTestType = if ($parametricRobustnessScore -ge $nonParametricRobustnessScore) {
        "ParamÃ©trique"
    } else {
        "Non-paramÃ©trique"
    }

    # DÃ©terminer le niveau de robustesse du test actuel
    $currentTestRobustnessScore = if ($TestType -eq "ParamÃ©trique") {
        $parametricRobustnessScore
    } else {
        $nonParametricRobustnessScore
    }

    # CatÃ©goriser le niveau de robustesse
    $robustnessLevel = if ($currentTestRobustnessScore -ge 90) {
        "TrÃ¨s Ã©levÃ©"
    } elseif ($currentTestRobustnessScore -ge 75) {
        "Ã‰levÃ©"
    } elseif ($currentTestRobustnessScore -ge 60) {
        "ModÃ©rÃ©"
    } elseif ($currentTestRobustnessScore -ge 40) {
        "Faible"
    } else {
        "TrÃ¨s faible"
    }

    # DÃ©terminer si le test actuel est appropriÃ©
    $isCurrentTestAppropriate = if ($TestType -eq $recommendedTestType) {
        $true
    } else {
        $false
    }

    # DÃ©terminer le seuil de robustesse minimal en fonction du domaine d'application
    $minRobustnessThreshold = switch ($ApplicationDomain) {
        "Recherche exploratoire" { 50 }
        "Recherche standard" { 60 }
        "Recherche clinique" { 75 }
        "Recherche critique" { 85 }
        "Recherche de haute prÃ©cision" { 90 }
        default { 60 }
    }

    # DÃ©terminer si le niveau de robustesse est acceptable
    $isRobustnessAcceptable = $currentTestRobustnessScore -ge $minRobustnessThreshold

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if (-not $isCurrentTestAppropriate) {
        $recommendations += "Le type de test actuel ($TestType) n'est pas optimal pour les caractÃ©ristiques des donnÃ©es."
        $recommendations += "Envisager d'utiliser un test $recommendedTestType pour une meilleure robustesse."
    }

    if (-not $isRobustnessAcceptable) {
        $recommendations += "Le niveau de robustesse ($robustnessLevel) est infÃ©rieur au seuil minimal recommandÃ© pour $ApplicationDomain."

        if ($TestType -eq "ParamÃ©trique") {
            if ($DistributionType -ne "Normale") {
                $recommendations += "La distribution des donnÃ©es ($DistributionType) ne respecte pas l'hypothÃ¨se de normalitÃ©."
                $recommendations += "Envisager une transformation des donnÃ©es ou un test non-paramÃ©trique."
            }

            if ($VarianceHomogeneity -in @("Faible", "TrÃ¨s faible")) {
                $recommendations += "L'homogÃ©nÃ©itÃ© des variances est $VarianceHomogeneity, ce qui viole une hypothÃ¨se importante des tests paramÃ©triques."
                $recommendations += "Envisager un test avec correction pour variances inÃ©gales ou un test non-paramÃ©trique."
            }

            if ($OutlierPercentage -gt 5) {
                $recommendations += "Le pourcentage Ã©levÃ© de valeurs aberrantes ($OutlierPercentage%) peut affecter la fiabilitÃ© des tests paramÃ©triques."
                $recommendations += "Envisager de traiter les valeurs aberrantes ou d'utiliser un test non-paramÃ©trique."
            }
        } else {
            if ($SampleSize -lt 10) {
                $recommendations += "La taille d'Ã©chantillon ($SampleSize) est trÃ¨s petite, ce qui peut affecter la puissance des tests non-paramÃ©triques."
                $recommendations += "Envisager d'augmenter la taille de l'Ã©chantillon si possible."
            }
        }

        if ($MissingDataPercentage -gt 10) {
            $recommendations += "Le pourcentage Ã©levÃ© de donnÃ©es manquantes ($MissingDataPercentage%) peut affecter la fiabilitÃ© des rÃ©sultats."
            $recommendations += "Envisager d'utiliser des mÃ©thodes d'imputation ou d'analyse adaptÃ©es aux donnÃ©es manquantes."
        }
    }

    # Suggestions de tests spÃ©cifiques
    if ($recommendedTestType -eq "ParamÃ©trique") {
        $recommendations += "Tests paramÃ©triques recommandÃ©s: " + (Get-ParametricTestRecommendations -DistributionType $DistributionType -VarianceHomogeneity $VarianceHomogeneity)
    } else {
        $recommendations += "Tests non-paramÃ©triques recommandÃ©s: " + (Get-NonParametricTestRecommendations -SampleSize $SampleSize)
    }

    # Retourner les rÃ©sultats
    return @{
        TestType                     = $TestType
        SampleSize                   = $SampleSize
        DistributionType             = $DistributionType
        VarianceHomogeneity          = $VarianceHomogeneity
        OutlierPercentage            = $OutlierPercentage
        MissingDataPercentage        = $MissingDataPercentage
        ApplicationDomain            = $ApplicationDomain
        ParametricRobustnessScore    = $parametricRobustnessScore
        NonParametricRobustnessScore = $nonParametricRobustnessScore
        CurrentTestRobustnessScore   = $currentTestRobustnessScore
        RobustnessLevel              = $robustnessLevel
        RecommendedTestType          = $recommendedTestType
        IsCurrentTestAppropriate     = $isCurrentTestAppropriate
        MinRobustnessThreshold       = $minRobustnessThreshold
        IsRobustnessAcceptable       = $isRobustnessAcceptable
        Recommendations              = $recommendations
    }
}

<#
.SYNOPSIS
    Fournit des recommandations de tests paramÃ©triques en fonction des caractÃ©ristiques des donnÃ©es.

.DESCRIPTION
    Cette fonction interne suggÃ¨re des tests paramÃ©triques appropriÃ©s en fonction du type de distribution
    et de l'homogÃ©nÃ©itÃ© des variances.

.PARAMETER DistributionType
    Le type de distribution des donnÃ©es.

.PARAMETER VarianceHomogeneity
    Le niveau d'homogÃ©nÃ©itÃ© des variances.

.OUTPUTS
    System.String
#>
function Get-ParametricTestRecommendations {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Normale", "AsymÃ©trique", "Multimodale", "Queue lourde", "Mixte", "Inconnue")]
        [string]$DistributionType,

        [Parameter(Mandatory = $true)]
        [ValidateSet("TrÃ¨s Ã©levÃ©e", "Ã‰levÃ©e", "ModÃ©rÃ©e", "Faible", "TrÃ¨s faible", "Inconnue")]
        [string]$VarianceHomogeneity
    )

    $recommendations = @()

    if ($DistributionType -in @("Normale", "Inconnue")) {
        if ($VarianceHomogeneity -in @("TrÃ¨s Ã©levÃ©e", "Ã‰levÃ©e", "ModÃ©rÃ©e", "Inconnue")) {
            $recommendations += "Test t de Student, ANOVA"
        } else {
            $recommendations += "Test t de Welch, ANOVA avec correction de Welch"
        }
    } elseif ($DistributionType -eq "AsymÃ©trique") {
        $recommendations += "Test t sur donnÃ©es transformÃ©es (log, racine carrÃ©e), ANOVA sur donnÃ©es transformÃ©es"
    } else {
        $recommendations += "ModÃ¨les linÃ©aires gÃ©nÃ©ralisÃ©s, tests robustes"
    }

    return $recommendations -join ", "
}

<#
.SYNOPSIS
    Fournit des recommandations de tests non-paramÃ©triques en fonction de la taille d'Ã©chantillon.

.DESCRIPTION
    Cette fonction interne suggÃ¨re des tests non-paramÃ©triques appropriÃ©s en fonction de la taille d'Ã©chantillon.

.PARAMETER SampleSize
    La taille de l'Ã©chantillon.

.OUTPUTS
    System.String
#>
function Get-NonParametricTestRecommendations {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize
    )

    $recommendations = @()

    if ($SampleSize -lt 5) {
        $recommendations += "Test exact de Fisher, test binomial exact"
    } elseif ($SampleSize -lt 20) {
        $recommendations += "Test de Mann-Whitney U, test de Wilcoxon, test de Kruskal-Wallis"
    } else {
        $recommendations += "Test de Mann-Whitney U, test de Wilcoxon, test de Kruskal-Wallis, test de Friedman"
    }

    return $recommendations -join ", "
}

<#
.SYNOPSIS
    DÃ©finit les mÃ©triques d'efficacitÃ© computationnelle pour les tests d'hypothÃ¨ses.

.DESCRIPTION
    Cette fonction Ã©value l'efficacitÃ© computationnelle d'un test d'hypothÃ¨se en termes de
    temps d'exÃ©cution, utilisation de mÃ©moire, et complexitÃ© algorithmique.

.PARAMETER TestType
    Le type de test (paramÃ©trique ou non-paramÃ©trique).

.PARAMETER TestName
    Le nom spÃ©cifique du test statistique.

.PARAMETER SampleSize
    La taille de l'Ã©chantillon utilisÃ© ou prÃ©vu.

.PARAMETER NumberOfVariables
    Le nombre de variables impliquÃ©es dans le test.

.PARAMETER NumberOfGroups
    Le nombre de groupes ou conditions dans le test (pour les tests de comparaison).

.PARAMETER ExecutionTimeMilliseconds
    Le temps d'exÃ©cution du test en millisecondes (si disponible).

.PARAMETER MemoryUsageKB
    L'utilisation de mÃ©moire du test en kilooctets (si disponible).

.PARAMETER ComputationalEnvironment
    L'environnement de calcul utilisÃ© (par dÃ©faut "Standard").

.EXAMPLE
    Get-ComputationalEfficiencyMetrics -TestType "ParamÃ©trique" -TestName "ANOVA" -SampleSize 100 -NumberOfVariables 3 -NumberOfGroups 4 -ExecutionTimeMilliseconds 150 -MemoryUsageKB 2048 -ComputationalEnvironment "Standard"
    Ã‰value l'efficacitÃ© computationnelle d'une ANOVA et fournit des recommandations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ComputationalEfficiencyMetrics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ParamÃ©trique", "Non-paramÃ©trique", "BayÃ©sien", "Bootstrap", "Permutation")]
        [string]$TestType,

        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(2, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$NumberOfVariables,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$NumberOfGroups = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [double]$ExecutionTimeMilliseconds = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [double]$MemoryUsageKB = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("LimitÃ©", "Standard", "Haute performance", "Cloud")]
        [string]$ComputationalEnvironment = "Standard"
    )

    # DÃ©finir les complexitÃ©s algorithmiques typiques pour diffÃ©rents types de tests
    $algorithmicComplexities = @{
        "ParamÃ©trique"     = @{
            "t-test"              = @{
                "Time"        = "O(n)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© linÃ©aire en fonction de la taille de l'Ã©chantillon"
            }
            "ANOVA"               = @{
                "Time"        = "O(n * g)"
                "Memory"      = "O(n + g)"
                "Description" = "ComplexitÃ© linÃ©aire en fonction de la taille de l'Ã©chantillon et du nombre de groupes"
            }
            "RÃ©gression linÃ©aire" = @{
                "Time"        = "O(n * v^2)"
                "Memory"      = "O(n * v)"
                "Description" = "ComplexitÃ© quadratique en fonction du nombre de variables"
            }
            "MANOVA"              = @{
                "Time"        = "O(n * v^2 * g)"
                "Memory"      = "O(n * v + g * v^2)"
                "Description" = "ComplexitÃ© Ã©levÃ©e en fonction du nombre de variables et de groupes"
            }
            "Default"             = @{
                "Time"        = "O(n * v)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© linÃ©aire typique pour les tests paramÃ©triques"
            }
        }
        "Non-paramÃ©trique" = @{
            "Mann-Whitney U" = @{
                "Time"        = "O(n log n)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© quasi-linÃ©aire due au tri des rangs"
            }
            "Kruskal-Wallis" = @{
                "Time"        = "O(n log n)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© quasi-linÃ©aire due au tri des rangs"
            }
            "Wilcoxon"       = @{
                "Time"        = "O(n log n)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© quasi-linÃ©aire due au tri des rangs"
            }
            "Friedman"       = @{
                "Time"        = "O(n * g * log(n * g))"
                "Memory"      = "O(n * g)"
                "Description" = "ComplexitÃ© quasi-linÃ©aire avec facteur multiplicatif pour les groupes"
            }
            "Default"        = @{
                "Time"        = "O(n log n)"
                "Memory"      = "O(n)"
                "Description" = "ComplexitÃ© quasi-linÃ©aire typique pour les tests non-paramÃ©triques"
            }
        }
        "BayÃ©sien"         = @{
            "Default" = @{
                "Time"        = "O(n * i)"
                "Memory"      = "O(n * i)"
                "Description" = "ComplexitÃ© dÃ©pendant de la taille de l'Ã©chantillon et du nombre d'itÃ©rations MCMC"
            }
        }
        "Bootstrap"        = @{
            "Default" = @{
                "Time"        = "O(n * b)"
                "Memory"      = "O(n * b)"
                "Description" = "ComplexitÃ© linÃ©aire en fonction de la taille de l'Ã©chantillon et du nombre de rÃ©plications"
            }
        }
        "Permutation"      = @{
            "Default" = @{
                "Time"        = "O(n * p)"
                "Memory"      = "O(n * p)"
                "Description" = "ComplexitÃ© linÃ©aire en fonction de la taille de l'Ã©chantillon et du nombre de permutations"
            }
        }
    }

    # Obtenir la complexitÃ© algorithmique pour le test spÃ©cifiÃ©
    $complexity = if ($algorithmicComplexities[$TestType].ContainsKey($TestName)) {
        $algorithmicComplexities[$TestType][$TestName]
    } else {
        $algorithmicComplexities[$TestType]["Default"]
    }

    # Estimer le temps d'exÃ©cution thÃ©orique (en millisecondes) si non fourni
    $theoreticalExecutionTime = if ($ExecutionTimeMilliseconds -eq 0) {
        switch ($complexity["Time"]) {
            "O(n)" { 0.1 * $SampleSize }
            "O(n log n)" { 0.2 * $SampleSize * [Math]::Log($SampleSize) }
            "O(n * g)" { 0.1 * $SampleSize * $NumberOfGroups }
            "O(n * v)" { 0.1 * $SampleSize * $NumberOfVariables }
            "O(n * v^2)" { 0.1 * $SampleSize * [Math]::Pow($NumberOfVariables, 2) }
            "O(n * v^2 * g)" { 0.1 * $SampleSize * [Math]::Pow($NumberOfVariables, 2) * $NumberOfGroups }
            "O(n * g * log(n * g))" { 0.2 * $SampleSize * $NumberOfGroups * [Math]::Log($SampleSize * $NumberOfGroups) }
            "O(n * i)" { 0.5 * $SampleSize * 1000 } # Estimation pour 1000 itÃ©rations MCMC
            "O(n * b)" { 0.2 * $SampleSize * 1000 } # Estimation pour 1000 rÃ©plications bootstrap
            "O(n * p)" { 0.2 * $SampleSize * 1000 } # Estimation pour 1000 permutations
            default { 0.1 * $SampleSize }
        }
    } else {
        $ExecutionTimeMilliseconds
    }

    # Estimer l'utilisation de mÃ©moire thÃ©orique (en KB) si non fournie
    $theoreticalMemoryUsage = if ($MemoryUsageKB -eq 0) {
        switch ($complexity["Memory"]) {
            "O(n)" { 0.1 * $SampleSize }
            "O(n + g)" { 0.1 * ($SampleSize + $NumberOfGroups) }
            "O(n * v)" { 0.1 * $SampleSize * $NumberOfVariables }
            "O(n * v + g * v^2)" { 0.1 * ($SampleSize * $NumberOfVariables + $NumberOfGroups * [Math]::Pow($NumberOfVariables, 2)) }
            "O(n * g)" { 0.1 * $SampleSize * $NumberOfGroups }
            "O(n * i)" { 0.2 * $SampleSize * 1000 } # Estimation pour 1000 itÃ©rations MCMC
            "O(n * b)" { 0.2 * $SampleSize * 1000 } # Estimation pour 1000 rÃ©plications bootstrap
            "O(n * p)" { 0.2 * $SampleSize * 1000 } # Estimation pour 1000 permutations
            default { 0.1 * $SampleSize }
        }
    } else {
        $MemoryUsageKB
    }

    # DÃ©finir les seuils d'efficacitÃ© en fonction de l'environnement de calcul
    $executionTimeThresholds = switch ($ComputationalEnvironment) {
        "LimitÃ©" { @{ "Excellent" = 100; "Bon" = 500; "Acceptable" = 2000; "ProblÃ©matique" = 10000 } }
        "Standard" { @{ "Excellent" = 500; "Bon" = 2000; "Acceptable" = 10000; "ProblÃ©matique" = 60000 } }
        "Haute performance" { @{ "Excellent" = 2000; "Bon" = 10000; "Acceptable" = 60000; "ProblÃ©matique" = 300000 } }
        "Cloud" { @{ "Excellent" = 1000; "Bon" = 5000; "Acceptable" = 30000; "ProblÃ©matique" = 180000 } }
        default { @{ "Excellent" = 500; "Bon" = 2000; "Acceptable" = 10000; "ProblÃ©matique" = 60000 } }
    }

    $memoryUsageThresholds = switch ($ComputationalEnvironment) {
        "LimitÃ©" { @{ "Excellent" = 1024; "Bon" = 4096; "Acceptable" = 16384; "ProblÃ©matique" = 65536 } }
        "Standard" { @{ "Excellent" = 4096; "Bon" = 16384; "Acceptable" = 65536; "ProblÃ©matique" = 262144 } }
        "Haute performance" { @{ "Excellent" = 16384; "Bon" = 65536; "Acceptable" = 262144; "ProblÃ©matique" = 1048576 } }
        "Cloud" { @{ "Excellent" = 8192; "Bon" = 32768; "Acceptable" = 131072; "ProblÃ©matique" = 524288 } }
        default { @{ "Excellent" = 4096; "Bon" = 16384; "Acceptable" = 65536; "ProblÃ©matique" = 262144 } }
    }

    # Ã‰valuer l'efficacitÃ© du temps d'exÃ©cution
    $executionTimeEfficiency = if ($theoreticalExecutionTime -le $executionTimeThresholds["Excellent"]) {
        "Excellent"
    } elseif ($theoreticalExecutionTime -le $executionTimeThresholds["Bon"]) {
        "Bon"
    } elseif ($theoreticalExecutionTime -le $executionTimeThresholds["Acceptable"]) {
        "Acceptable"
    } elseif ($theoreticalExecutionTime -le $executionTimeThresholds["ProblÃ©matique"]) {
        "ProblÃ©matique"
    } else {
        "Critique"
    }

    # Ã‰valuer l'efficacitÃ© de l'utilisation de mÃ©moire
    $memoryUsageEfficiency = if ($theoreticalMemoryUsage -le $memoryUsageThresholds["Excellent"]) {
        "Excellent"
    } elseif ($theoreticalMemoryUsage -le $memoryUsageThresholds["Bon"]) {
        "Bon"
    } elseif ($theoreticalMemoryUsage -le $memoryUsageThresholds["Acceptable"]) {
        "Acceptable"
    } elseif ($theoreticalMemoryUsage -le $memoryUsageThresholds["ProblÃ©matique"]) {
        "ProblÃ©matique"
    } else {
        "Critique"
    }

    # Calculer un score global d'efficacitÃ© (0-100)
    $executionTimeScore = switch ($executionTimeEfficiency) {
        "Excellent" { 100 }
        "Bon" { 80 }
        "Acceptable" { 60 }
        "ProblÃ©matique" { 30 }
        "Critique" { 10 }
        default { 50 }
    }

    $memoryUsageScore = switch ($memoryUsageEfficiency) {
        "Excellent" { 100 }
        "Bon" { 80 }
        "Acceptable" { 60 }
        "ProblÃ©matique" { 30 }
        "Critique" { 10 }
        default { 50 }
    }

    $overallEfficiencyScore = ($executionTimeScore + $memoryUsageScore) / 2

    # DÃ©terminer le niveau global d'efficacitÃ©
    $overallEfficiencyLevel = if ($overallEfficiencyScore -ge 90) {
        "Excellent"
    } elseif ($overallEfficiencyScore -ge 70) {
        "Bon"
    } elseif ($overallEfficiencyScore -ge 50) {
        "Acceptable"
    } elseif ($overallEfficiencyScore -ge 30) {
        "ProblÃ©matique"
    } else {
        "Critique"
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if ($executionTimeEfficiency -in @("ProblÃ©matique", "Critique")) {
        $recommendations += "Le temps d'exÃ©cution estimÃ© est $executionTimeEfficiency ($([Math]::Round($theoreticalExecutionTime, 2)) ms)."

        if ($SampleSize -gt 10000) {
            $recommendations += "Envisager d'utiliser un Ã©chantillonnage ou une stratification pour rÃ©duire la taille de l'Ã©chantillon."
        }

        if ($NumberOfVariables -gt 10) {
            $recommendations += "Envisager de rÃ©duire le nombre de variables par sÃ©lection de caractÃ©ristiques ou analyse en composantes principales."
        }

        if ($TestType -in @("Bootstrap", "Permutation")) {
            $recommendations += "RÃ©duire le nombre de rÃ©plications ou utiliser des mÃ©thodes d'approximation."
        }

        if ($TestType -eq "BayÃ©sien") {
            $recommendations += "RÃ©duire le nombre d'itÃ©rations MCMC ou utiliser des algorithmes d'Ã©chantillonnage plus efficaces."
        }
    }

    if ($memoryUsageEfficiency -in @("ProblÃ©matique", "Critique")) {
        $recommendations += "L'utilisation de mÃ©moire estimÃ©e est $memoryUsageEfficiency ($([Math]::Round($theoreticalMemoryUsage, 2)) KB)."

        if ($SampleSize -gt 10000) {
            $recommendations += "Envisager de traiter les donnÃ©es par lots pour rÃ©duire l'empreinte mÃ©moire."
        }

        if ($TestType -in @("Bootstrap", "Permutation", "BayÃ©sien")) {
            $recommendations += "Utiliser des techniques de calcul incrÃ©mental pour rÃ©duire l'utilisation de mÃ©moire."
        }
    }

    if ($overallEfficiencyLevel -in @("ProblÃ©matique", "Critique") -and $ComputationalEnvironment -eq "LimitÃ©") {
        $recommendations += "L'environnement de calcul actuel (LimitÃ©) peut Ãªtre insuffisant pour ce test. Envisager d'utiliser un environnement plus puissant."
    }

    # Alternatives plus efficaces
    if ($overallEfficiencyLevel -in @("ProblÃ©matique", "Critique")) {
        $recommendations += "Alternatives plus efficaces Ã  considÃ©rer:"

        if ($TestType -eq "ParamÃ©trique" -and $TestName -eq "MANOVA") {
            $recommendations += "  - Utiliser des ANOVA sÃ©parÃ©es avec correction de Bonferroni"
        }

        if ($TestType -eq "Bootstrap" -and $SampleSize -gt 1000) {
            $recommendations += "  - Utiliser des mÃ©thodes asymptotiques ou des approximations"
        }

        if ($TestType -eq "Permutation" -and $SampleSize -gt 100) {
            $recommendations += "  - Utiliser des approximations de Monte Carlo ou des tests non-paramÃ©triques standards"
        }

        if ($TestType -eq "BayÃ©sien") {
            $recommendations += "  - Utiliser des approximations variationnelles ou des modÃ¨les bayÃ©siens simplifiÃ©s"
        }
    }

    # Retourner les rÃ©sultats
    return @{
        TestType                    = $TestType
        TestName                    = $TestName
        SampleSize                  = $SampleSize
        NumberOfVariables           = $NumberOfVariables
        NumberOfGroups              = $NumberOfGroups
        ComputationalEnvironment    = $ComputationalEnvironment
        AlgorithmicComplexityTime   = $complexity["Time"]
        AlgorithmicComplexityMemory = $complexity["Memory"]
        ComplexityDescription       = $complexity["Description"]
        TheoreticalExecutionTime    = $theoreticalExecutionTime
        TheoreticalMemoryUsage      = $theoreticalMemoryUsage
        ExecutionTimeEfficiency     = $executionTimeEfficiency
        MemoryUsageEfficiency       = $memoryUsageEfficiency
        ExecutionTimeScore          = $executionTimeScore
        MemoryUsageScore            = $memoryUsageScore
        OverallEfficiencyScore      = $overallEfficiencyScore
        OverallEfficiencyLevel      = $overallEfficiencyLevel
        Recommendations             = $recommendations
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-PowerStatisticsCriteria, Get-StatisticalPower, Get-RequiredSampleSize, Get-ErrorControlMetrics, Get-TestRobustnessCriteria, Get-ComputationalEfficiencyMetrics
