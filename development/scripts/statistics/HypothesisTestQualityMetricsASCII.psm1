# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour definir les metriques de qualite pour les tests d'hypotheses.

.DESCRIPTION
    Ce module fournit des fonctions pour evaluer la qualite des tests d'hypotheses,
    notamment en termes de puissance statistique, controle des erreurs, robustesse
    et efficacite computationnelle.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-15
#>

#region Variables globales et constantes

# Table des valeurs Z pour differents niveaux de confiance
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

# Seuils de puissance statistique recommandes par domaine d'application
$script:PowerThresholds = @{
    "Recherche exploratoire"       = 0.70
    "Recherche standard"           = 0.80
    "Recherche clinique"           = 0.85
    "Recherche critique"           = 0.90
    "Recherche de haute precision" = 0.95
}

# Seuils d'effet (Cohen's d) par taille
$script:EffectSizeThresholds = @{
    "Petit"      = 0.2
    "Moyen"      = 0.5
    "Grand"      = 0.8
    "Tres grand" = 1.2
}

#endregion

#region Fonctions utilitaires

<#
.SYNOPSIS
    Obtient la valeur Z pour un niveau de confiance donne.

.DESCRIPTION
    Cette fonction retourne la valeur Z correspondant a un niveau de confiance specifie.
    Si le niveau de confiance exact n'est pas dans la table, la valeur la plus proche est utilisee.

.PARAMETER ConfidenceLevel
    Le niveau de confiance souhaite (entre 0 et 1).

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

    # Verifier si le niveau de confiance est directement dans la table
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
    Calcule la taille d'echantillon requise pour un test d'hypothese.

.DESCRIPTION
    Cette fonction calcule la taille d'echantillon necessaire pour atteindre une puissance
    statistique donnee, etant donne une taille d'effet et un niveau de signification.

.PARAMETER EffectSize
    La taille d'effet attendue (Cohen's d).

.PARAMETER Power
    La puissance statistique souhaitee (entre 0 et 1).

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par defaut 0.05).

.PARAMETER TestType
    Le type de test (unilateral ou bilateral, par defaut "bilateral").

.EXAMPLE
    Get-RequiredSampleSize -EffectSize 0.5 -Power 0.8 -Alpha 0.05 -TestType "bilateral"
    Calcule la taille d'echantillon necessaire pour detecter un effet moyen avec une puissance de 80%.

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
        [ValidateSet("unilateral", "bilateral")]
        [string]$TestType = "bilateral"
    )

    # Obtenir les valeurs Z pour alpha et power
    $zAlpha = if ($TestType -eq "bilateral") {
        Get-ZScore -ConfidenceLevel (1 - $Alpha / 2)
    } else {
        Get-ZScore -ConfidenceLevel (1 - $Alpha)
    }

    $zPower = Get-ZScore -ConfidenceLevel $Power

    # Calculer la taille d'echantillon (formule pour test de comparaison de moyennes)
    $n = [Math]::Ceiling(2 * [Math]::Pow(($zAlpha + $zPower) / $EffectSize, 2))

    return $n
}

<#
.SYNOPSIS
    Calcule la puissance statistique pour un test d'hypothese.

.DESCRIPTION
    Cette fonction calcule la puissance statistique d'un test d'hypothese
    etant donne une taille d'effet, une taille d'echantillon et un niveau de signification.

.PARAMETER EffectSize
    La taille d'effet attendue (Cohen's d).

.PARAMETER SampleSize
    La taille de l'echantillon.

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par defaut 0.05).

.PARAMETER TestType
    Le type de test (unilateral ou bilateral, par defaut "bilateral").

.EXAMPLE
    Get-StatisticalPower -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilateral"
    Calcule la puissance statistique pour detecter un effet moyen avec un echantillon de 64 sujets.

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
        [ValidateSet("unilateral", "bilateral")]
        [string]$TestType = "bilateral"
    )

    # Obtenir la valeur Z pour alpha
    $zAlpha = if ($TestType -eq "bilateral") {
        Get-ZScore -ConfidenceLevel (1 - $Alpha / 2)
    } else {
        Get-ZScore -ConfidenceLevel (1 - $Alpha)
    }

    # Calculer le parametre non-centralite
    $ncp = $EffectSize * [Math]::Sqrt($SampleSize / 2)

    # Calculer la puissance (approximation)
    $zBeta = $ncp - $zAlpha

    # Convertir z-score en probabilite (approximation de la fonction de repartition de la loi normale)
    $power = if ($zBeta -le 0) {
        0.5
    } else {
        # Approximation de la fonction de repartition de la loi normale centree reduite
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
    Etablit les criteres de puissance statistique pour un test d'hypothese.

.DESCRIPTION
    Cette fonction evalue la puissance statistique d'un test d'hypothese et fournit
    des recommandations basees sur les criteres de qualite etablis.

.PARAMETER EffectSize
    La taille d'effet attendue ou observee (Cohen's d).

.PARAMETER SampleSize
    La taille de l'echantillon utilise ou prevu.

.PARAMETER Alpha
    Le niveau de signification (risque d'erreur de type I, par defaut 0.05).

.PARAMETER TestType
    Le type de test (unilateral ou bilateral, par defaut "bilateral").

.PARAMETER ApplicationDomain
    Le domaine d'application de la recherche (par defaut "Recherche standard").

.EXAMPLE
    Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche standard"
    Evalue la puissance statistique et fournit des recommandations pour un test avec un effet moyen et 64 sujets.

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
        [ValidateSet("unilateral", "bilateral")]
        [string]$TestType = "bilateral",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Recherche exploratoire", "Recherche standard", "Recherche clinique", "Recherche critique", "Recherche de haute precision")]
        [string]$ApplicationDomain = "Recherche standard"
    )

    # Calculer la puissance statistique
    $power = Get-StatisticalPower -EffectSize $EffectSize -SampleSize $SampleSize -Alpha $Alpha -TestType $TestType

    # Determiner le seuil de puissance recommande pour le domaine d'application
    $recommendedPower = $script:PowerThresholds[$ApplicationDomain]

    # Evaluer si la puissance est suffisante
    $isPowerSufficient = $power -ge $recommendedPower

    # Calculer la taille d'echantillon recommandee si la puissance est insuffisante
    $recommendedSampleSize = if (-not $isPowerSufficient) {
        Get-RequiredSampleSize -EffectSize $EffectSize -Power $recommendedPower -Alpha $Alpha -TestType $TestType
    } else {
        $SampleSize
    }

    # Determiner la taille d'effet (petit, moyen, grand)
    $effectSizeCategory = "Personnalise"
    foreach ($category in $script:EffectSizeThresholds.Keys) {
        if ($EffectSize -ge $script:EffectSizeThresholds[$category]) {
            $effectSizeCategory = $category
        }
    }

    # Generer des recommandations
    $recommendations = @()

    if (-not $isPowerSufficient) {
        $recommendations += "La puissance statistique est insuffisante pour le domaine d'application specifie."
        $recommendations += "Augmenter la taille de l'echantillon a au moins $recommendedSampleSize pour atteindre une puissance de $recommendedPower."
    } else {
        $recommendations += "La puissance statistique est suffisante pour le domaine d'application specifie."
    }

    if ($effectSizeCategory -eq "Petit" -and $power -lt 0.8) {
        $recommendations += "Pour detecter un effet de petite taille, une puissance d'au moins 0.8 est generalement recommandee."
    }

    if ($Alpha -gt 0.01 -and $ApplicationDomain -in @("Recherche clinique", "Recherche critique", "Recherche de haute precision")) {
        $recommendations += "Pour $ApplicationDomain, envisager de reduire le niveau de signification (alpha) a 0.01 pour minimiser le risque d'erreur de type I."
    }

    # Retourner les resultats
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

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ZScore, Get-RequiredSampleSize, Get-StatisticalPower, Get-PowerStatisticsCriteria
