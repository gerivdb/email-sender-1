# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'évaluation de l'asymétrie basée sur les ratios de densité.

.DESCRIPTION
    Ce module fournit des fonctions pour évaluer l'asymétrie des distributions
    en utilisant les ratios de densité entre les queues de distribution.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-01
#>

#region Variables globales et constantes

# Seuils d'interprétation pour les ratios de densité
$script:DensityRatioThresholds = @{
    "Symétrie parfaite"       = 1.0    # Ratio de densité = 1.0
    "Quasi-symétrique"        = 1.2    # Ratio de densité < 1.2
    "Légèrement asymétrique"  = 1.5    # Ratio de densité < 1.5
    "Modérément asymétrique"  = 2.0    # Ratio de densité < 2.0
    "Fortement asymétrique"   = 3.0    # Ratio de densité < 3.0
    "Très asymétrique"        = 5.0    # Ratio de densité < 5.0
    "Extrêmement asymétrique" = 10.0  # Ratio de densité >= 5.0
}

# Facteurs d'ajustement par taille d'échantillon
$script:SampleSizeAdjustmentFactors = @{
    "Très petit (< 30)"   = 0.7   # Facteur plus bas pour les petits échantillons (plus conservateur)
    "Petit (30-100)"      = 0.8   # Facteur légèrement plus bas pour les échantillons petits
    "Moyen (100-500)"     = 1.0   # Facteur standard pour les échantillons moyens
    "Grand (500-1000)"    = 1.2   # Facteur légèrement plus élevé pour les grands échantillons
    "Très grand (> 1000)" = 1.5   # Facteur plus élevé pour les très grands échantillons
}

# Seuils de référence basés sur des simulations pour différentes distributions
$script:SimulationBasedThresholds = @{
    "Normale"       = @{
        "Percentile_5"  = 1.05
        "Percentile_25" = 1.10
        "Percentile_50" = 1.15
        "Percentile_75" = 1.25
        "Percentile_95" = 1.40
    }
    "Exponentielle" = @{
        "Percentile_5"  = 1.50
        "Percentile_25" = 2.00
        "Percentile_50" = 2.50
        "Percentile_75" = 3.50
        "Percentile_95" = 5.00
    }
    "LogNormale"    = @{
        "Percentile_5"  = 1.30
        "Percentile_25" = 1.80
        "Percentile_50" = 2.20
        "Percentile_75" = 3.00
        "Percentile_95" = 4.50
    }
    "Uniforme"      = @{
        "Percentile_5"  = 1.02
        "Percentile_25" = 1.05
        "Percentile_50" = 1.10
        "Percentile_75" = 1.15
        "Percentile_95" = 1.25
    }
    "T-Student"     = @{
        "Percentile_5"  = 1.10
        "Percentile_25" = 1.20
        "Percentile_50" = 1.30
        "Percentile_75" = 1.50
        "Percentile_95" = 2.00
    }
}

# Échelle d'intensité d'asymétrie basée sur les ratios de densité
$script:AsymmetryIntensityScale = @{
    "Négligeable" = @{
        "Min"         = 0.95
        "Max"         = 1.05
        "Description" = "Asymétrie négligeable, distribution pratiquement symétrique"
        "Impact"      = "Aucun impact sur les analyses statistiques"
    }
    "Très faible" = @{
        "Min"         = 1.05
        "Max"         = 1.20
        "Description" = "Asymétrie très faible, distribution quasi-symétrique"
        "Impact"      = "Impact minimal sur les analyses statistiques"
    }
    "Faible"      = @{
        "Min"         = 1.20
        "Max"         = 1.50
        "Description" = "Asymétrie faible mais détectable"
        "Impact"      = "Impact léger sur les analyses paramétriques"
    }
    "Modérée"     = @{
        "Min"         = 1.50
        "Max"         = 2.00
        "Description" = "Asymétrie modérée, queue clairement plus longue d'un côté"
        "Impact"      = "Impact modéré, considérer des transformations ou méthodes non paramétriques"
    }
    "Forte"       = @{
        "Min"         = 2.00
        "Max"         = 3.00
        "Description" = "Asymétrie forte, distribution clairement déséquilibrée"
        "Impact"      = "Impact important, utiliser des méthodes robustes ou des transformations"
    }
    "Très forte"  = @{
        "Min"         = 3.00
        "Max"         = 5.00
        "Description" = "Asymétrie très forte, distribution fortement déséquilibrée"
        "Impact"      = "Impact très important, éviter les méthodes paramétriques standards"
    }
    "Extrême"     = @{
        "Min"         = 5.00
        "Max"         = [double]::PositiveInfinity
        "Description" = "Asymétrie extrême, distribution extrêmement déséquilibrée"
        "Impact"      = "Impact critique, utiliser uniquement des méthodes spécifiques pour distributions très asymétriques"
    }
}

#endregion

#region Fonctions principales

<#
.SYNOPSIS
    Établit des seuils d'interprétation pour les ratios de densité basés sur des simulations.

.DESCRIPTION
    Cette fonction établit des seuils d'interprétation pour les ratios de densité
    en se basant sur des simulations de distributions connues.

.PARAMETER DistributionType
    Le type de distribution de référence.

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour les seuils (par défaut "95%").

.PARAMETER SampleSize
    La taille de l'échantillon.

.EXAMPLE
    Get-DensityRatioThresholds -DistributionType "Normale" -ConfidenceLevel "95%" -SampleSize 100
    Obtient les seuils d'interprétation pour les ratios de densité basés sur une distribution normale.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DensityRatioThresholds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Exponentielle", "LogNormale", "Uniforme", "T-Student", "Auto")]
        [string]$DistributionType = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%",

        [Parameter(Mandatory = $true)]
        [ValidateRange(10, [int]::MaxValue)]
        [int]$SampleSize
    )

    # Déterminer la catégorie de taille d'échantillon
    $sizeCategory = switch ($SampleSize) {
        { $_ -lt 30 } { "Très petit (< 30)" }
        { $_ -ge 30 -and $_ -lt 100 } { "Petit (30-100)" }
        { $_ -ge 100 -and $_ -lt 500 } { "Moyen (100-500)" }
        { $_ -ge 500 -and $_ -lt 1000 } { "Grand (500-1000)" }
        default { "Très grand (> 1000)" }
    }

    # Obtenir le facteur d'ajustement pour cette taille d'échantillon
    $sizeAdjustmentFactor = $script:SampleSizeAdjustmentFactors[$sizeCategory]

    # Déterminer le percentile à utiliser en fonction du niveau de confiance
    $percentile = switch ($ConfidenceLevel) {
        "90%" { "Percentile_75" }
        "95%" { "Percentile_95" }
        "99%" { "Percentile_95" } # Utiliser Percentile_95 car Percentile_99 n'est pas défini
        default { "Percentile_95" }
    }

    # Si le type de distribution est "Auto", utiliser "Normale" comme référence conservative
    if ($DistributionType -eq "Auto") {
        $DistributionType = "Normale"
    }

    # Obtenir les seuils de base pour ce type de distribution
    $baseThresholds = $script:SimulationBasedThresholds[$DistributionType]

    # Si le percentile demandé n'existe pas, utiliser le plus proche disponible
    if (-not $baseThresholds.ContainsKey($percentile)) {
        $percentile = "Percentile_95"
    }

    # Obtenir le seuil de base
    $baseThreshold = $baseThresholds[$percentile]

    # Ajuster le seuil en fonction de la taille d'échantillon
    $adjustedThreshold = $baseThreshold * $sizeAdjustmentFactor

    # Créer l'objet de résultat
    $result = @{
        DistributionType     = $DistributionType
        ConfidenceLevel      = $ConfidenceLevel
        SampleSize           = $SampleSize
        SizeCategory         = $sizeCategory
        SizeAdjustmentFactor = $sizeAdjustmentFactor
        BaseThreshold        = $baseThreshold
        AdjustedThreshold    = $adjustedThreshold
    }

    return $result
}

<#
.SYNOPSIS
    Développe des seuils adaptatifs pour les ratios de densité basés sur la taille d'échantillon.

.DESCRIPTION
    Cette fonction développe des seuils adaptatifs pour les ratios de densité
    en fonction de la taille d'échantillon et d'autres paramètres.

.PARAMETER SampleSize
    La taille de l'échantillon.

.PARAMETER DistributionType
    Le type de distribution attendu (par défaut "Auto").

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour les seuils (par défaut "95%").

.EXAMPLE
    Get-AdaptiveDensityRatioThresholds -SampleSize 100 -DistributionType "Normale" -ConfidenceLevel "95%"
    Développe des seuils adaptatifs pour un échantillon de 100 observations d'une distribution normale.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-AdaptiveDensityRatioThresholds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(10, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Exponentielle", "LogNormale", "Uniforme", "T-Student", "Auto")]
        [string]$DistributionType = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%"
    )

    # Obtenir les seuils de base
    $baseThresholds = Get-DensityRatioThresholds -DistributionType $DistributionType -ConfidenceLevel $ConfidenceLevel -SampleSize $SampleSize

    # Calculer le facteur d'adaptation en fonction de la taille d'échantillon
    # Plus l'échantillon est petit, plus le facteur est conservateur (seuils plus bas)
    $adaptiveFactor = 1.0
    if ($SampleSize -lt 30) {
        $adaptiveFactor = 0.7 + ($SampleSize / 100)
    } elseif ($SampleSize -lt 100) {
        $adaptiveFactor = 0.8 + ($SampleSize / 500)
    } elseif ($SampleSize -lt 500) {
        $adaptiveFactor = 0.9 + ($SampleSize / 5000)
    } elseif ($SampleSize -lt 1000) {
        $adaptiveFactor = 1.0 + ($SampleSize / 10000)
    } else {
        $adaptiveFactor = 1.1 + ($SampleSize / 20000)
    }

    # Limiter le facteur adaptatif
    $adaptiveFactor = [Math]::Max(0.5, [Math]::Min($adaptiveFactor, 2.0))

    # Ajuster les seuils en fonction du facteur adaptatif
    $adaptiveThresholds = @{}
    foreach ($key in $script:DensityRatioThresholds.Keys) {
        $baseValue = $script:DensityRatioThresholds[$key]

        # Ajuster la valeur en fonction du facteur adaptatif
        # Pour les valeurs proches de 1, l'ajustement est plus conservateur
        if ($baseValue -le 1.2) {
            $adaptiveValue = 1.0 + (($baseValue - 1.0) * $adaptiveFactor)
        } else {
            $adaptiveValue = $baseValue * $adaptiveFactor
        }

        $adaptiveThresholds[$key] = $adaptiveValue
    }

    # Créer l'objet de résultat
    $result = @{
        SampleSize         = $SampleSize
        DistributionType   = $baseThresholds.DistributionType
        ConfidenceLevel    = $baseThresholds.ConfidenceLevel
        SizeCategory       = $baseThresholds.SizeCategory
        BaseThreshold      = $baseThresholds.BaseThreshold
        AdaptiveFactor     = $adaptiveFactor
        AdaptiveThresholds = $adaptiveThresholds
    }

    return $result
}

<#
.SYNOPSIS
    Crée une échelle d'intensité d'asymétrie basée sur les ratios de densité.

.DESCRIPTION
    Cette fonction crée une échelle d'intensité d'asymétrie basée sur les ratios de densité
    et fournit des interprétations pour différents niveaux d'asymétrie.

.PARAMETER DensityRatio
    Le ratio de densité calculé.

.PARAMETER SampleSize
    La taille de l'échantillon.

.PARAMETER DistributionType
    Le type de distribution attendu (par défaut "Auto").

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour les seuils (par défaut "95%").

.EXAMPLE
    Get-AsymmetryIntensityScale -DensityRatio 2.5 -SampleSize 100
    Évalue l'intensité de l'asymétrie pour un ratio de densité de 2.5 avec un échantillon de 100 observations.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-AsymmetryIntensityScale {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, [double]::PositiveInfinity)]
        [double]$DensityRatio,

        [Parameter(Mandatory = $true)]
        [ValidateRange(10, [int]::MaxValue)]
        [int]$SampleSize,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normale", "Exponentielle", "LogNormale", "Uniforme", "T-Student", "Auto")]
        [string]$DistributionType = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%"
    )

    # Obtenir les seuils adaptatifs
    $adaptiveThresholds = Get-AdaptiveDensityRatioThresholds -SampleSize $SampleSize -DistributionType $DistributionType -ConfidenceLevel $ConfidenceLevel

    # Déterminer l'intensité de l'asymétrie
    $intensityLevel = "Négligeable"
    $intensityValue = 0.0

    # Normaliser le ratio de densité (si < 1, prendre l'inverse pour toujours avoir un ratio >= 1)
    $normalizedRatio = if ($DensityRatio -lt 1.0) { 1.0 / $DensityRatio } else { $DensityRatio }

    # Déterminer le niveau d'intensité en fonction du ratio normalisé
    foreach ($level in $script:AsymmetryIntensityScale.Keys) {
        $minValue = $script:AsymmetryIntensityScale[$level].Min
        $maxValue = $script:AsymmetryIntensityScale[$level].Max

        if ($normalizedRatio -ge $minValue -and $normalizedRatio -lt $maxValue) {
            $intensityLevel = $level

            # Calculer une valeur d'intensité normalisée entre 0 et 1 pour ce niveau
            $rangeSize = $maxValue - $minValue
            $positionInRange = $normalizedRatio - $minValue
            $intensityValue = [Math]::Min(1.0, $positionInRange / $rangeSize)

            break
        }
    }

    # Si le ratio est très élevé, utiliser le niveau "Extrême"
    if ($normalizedRatio -ge $script:AsymmetryIntensityScale["Extrême"].Min) {
        $intensityLevel = "Extrême"
        $intensityValue = 1.0
    }

    # Déterminer la direction de l'asymétrie
    $asymmetryDirection = if ($DensityRatio -gt 1.0) {
        "Positive (queue à droite)"
    } elseif ($DensityRatio -lt 1.0) {
        "Négative (queue à gauche)"
    } else {
        "Aucune (symétrique)"
    }

    # Obtenir la description et l'impact pour ce niveau d'intensité
    $description = $script:AsymmetryIntensityScale[$intensityLevel].Description
    $impact = $script:AsymmetryIntensityScale[$intensityLevel].Impact

    # Générer des recommandations spécifiques
    $recommendations = @()

    # Recommandations basées sur l'intensité de l'asymétrie
    $recommendations += "Le ratio de densité de $([Math]::Round($DensityRatio, 2)) indique une asymétrie de niveau '$intensityLevel'."
    $recommendations += "Description: $description"
    $recommendations += "Impact sur les analyses: $impact"

    # Recommandations basées sur la direction de l'asymétrie
    if ($asymmetryDirection -eq "Positive (queue à droite)" -and $intensityLevel -ne "Négligeable") {
        $recommendations += "La distribution présente une asymétrie positive (queue à droite), ce qui suggère la présence de valeurs extrêmes élevées."

        if ($intensityLevel -eq "Faible" -or $intensityLevel -eq "Très faible") {
            $recommendations += "Pour cette asymétrie $($intensityLevel.ToLower()), les méthodes paramétriques standards peuvent généralement être utilisées."
        } elseif ($intensityLevel -eq "Modérée") {
            $recommendations += "Pour cette asymétrie modérée, considérer des transformations (logarithmique, racine carrée) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Pour cette asymétrie $($intensityLevel.ToLower()), utiliser des méthodes non paramétriques ou des transformations appropriées (logarithmique, Box-Cox)."
        }
    } elseif ($asymmetryDirection -eq "Négative (queue à gauche)" -and $intensityLevel -ne "Négligeable") {
        $recommendations += "La distribution présente une asymétrie négative (queue à gauche), ce qui suggère la présence de valeurs extrêmes basses."

        if ($intensityLevel -eq "Faible" -or $intensityLevel -eq "Très faible") {
            $recommendations += "Pour cette asymétrie $($intensityLevel.ToLower()), les méthodes paramétriques standards peuvent généralement être utilisées."
        } elseif ($intensityLevel -eq "Modérée") {
            $recommendations += "Pour cette asymétrie modérée, considérer des transformations (exponentielle, élévation au carré) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Pour cette asymétrie $($intensityLevel.ToLower()), utiliser des méthodes non paramétriques ou des transformations appropriées (exponentielle, Box-Cox)."
        }
    } else {
        $recommendations += "La distribution est approximativement symétrique. Les méthodes statistiques paramétriques peuvent être utilisées."
    }

    # Recommandations basées sur la taille d'échantillon
    if ($SampleSize -lt 30) {
        $recommendations += "Attention: La taille d'échantillon est très petite ($SampleSize observations), ce qui peut rendre l'estimation de l'asymétrie moins fiable."
    } elseif ($SampleSize -lt 100) {
        $recommendations += "Note: La taille d'échantillon est petite ($SampleSize observations), l'estimation de l'asymétrie peut être légèrement moins précise."
    }

    # Créer l'objet de résultat
    $result = @{
        DensityRatio       = $DensityRatio
        NormalizedRatio    = $normalizedRatio
        SampleSize         = $SampleSize
        DistributionType   = $adaptiveThresholds.DistributionType
        ConfidenceLevel    = $adaptiveThresholds.ConfidenceLevel
        IntensityLevel     = $intensityLevel
        IntensityValue     = $intensityValue
        AsymmetryDirection = $asymmetryDirection
        Description        = $description
        Impact             = $impact
        Recommendations    = $recommendations
        AdaptiveThresholds = $adaptiveThresholds.AdaptiveThresholds
    }

    return $result
}

<#
.SYNOPSIS
    Développe une fonction d'évaluation de l'asymétrie basée sur la densité des queues.

.DESCRIPTION
    Cette fonction évalue l'asymétrie d'une distribution en calculant le ratio de densité
    entre les queues droite et gauche de la distribution.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER BandwidthMethod
    La méthode de calcul de la largeur de bande pour l'estimation de densité (par défaut "Silverman").

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour les seuils (par défaut "95%").

.EXAMPLE
    Get-DensityBasedAsymmetry -Data $data -TailProportion 0.1
    Évalue l'asymétrie d'une distribution en utilisant les 10% de données les plus extrêmes de chaque côté.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DensityBasedAsymmetry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "Manual")]
        [string]$BandwidthMethod = "Silverman",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [double]::PositiveInfinity)]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("90%", "95%", "99%")]
        [string]$ConfidenceLevel = "95%"
    )

    # Vérifier que les données contiennent au moins 10 points
    if ($Data.Count -lt 10) {
        throw "Les données doivent contenir au moins 10 points pour évaluer l'asymétrie basée sur la densité."
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer les statistiques de base
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer les quantiles pour définir les queues
    $lowerQuantile = $TailProportion
    $upperQuantile = 1 - $TailProportion

    $lowerIndex = [Math]::Floor($sortedData.Count * $lowerQuantile)
    $upperIndex = [Math]::Floor($sortedData.Count * $upperQuantile)

    $lowerThreshold = $sortedData[$lowerIndex]
    $upperThreshold = $sortedData[$upperIndex]

    # Extraire les données des queues
    $leftTailData = $sortedData[0..$lowerIndex]
    $rightTailData = $sortedData[$upperIndex..($sortedData.Count - 1)]

    # Calculer la largeur de bande pour l'estimation de densité
    if ($BandwidthMethod -eq "Silverman") {
        # Règle de Silverman: h = 0.9 * min(std, IQR/1.34) * n^(-1/5)
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1
        $bandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($sortedData.Count, -0.2)
    } elseif ($BandwidthMethod -eq "Scott") {
        # Règle de Scott: h = 1.06 * std * n^(-1/5)
        $bandwidth = 1.06 * $stdDev * [Math]::Pow($sortedData.Count, -0.2)
    } elseif ($BandwidthMethod -eq "Manual" -and $Bandwidth -gt 0) {
        # Utiliser la largeur de bande spécifiée
        $bandwidth = $Bandwidth
    } else {
        # Par défaut, utiliser la règle de Silverman
        $bandwidth = 0.9 * $stdDev * [Math]::Pow($sortedData.Count, -0.2)
    }

    # Estimer la densité aux points des queues
    # Pour simplifier, nous utilisons une approche basée sur la densité de noyau gaussien
    function Get-KernelDensity {
        param (
            [double[]]$Points,
            [double[]]$EvaluationPoints,
            [double]$Bandwidth
        )

        $densities = @()
        foreach ($x in $EvaluationPoints) {
            $density = 0
            foreach ($point in $Points) {
                $z = ($x - $point) / $Bandwidth
                $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $z * $z)
                $density += $kernelValue
            }
            $density /= ($Points.Count * $Bandwidth)
            $densities += $density
        }
        return $densities
    }

    # Calculer les points d'évaluation pour les queues
    $leftTailRange = $lowerThreshold - $mean
    $rightTailRange = $upperThreshold - $mean
    $leftEvaluationPoint = $mean - [Math]::Abs($leftTailRange) / 2
    $rightEvaluationPoint = $mean + [Math]::Abs($rightTailRange) / 2

    # Estimer la densité aux points d'évaluation
    $leftTailDensity = (Get-KernelDensity -Points $Data -EvaluationPoints @($leftEvaluationPoint) -Bandwidth $bandwidth)[0]
    $rightTailDensity = (Get-KernelDensity -Points $Data -EvaluationPoints @($rightEvaluationPoint) -Bandwidth $bandwidth)[0]

    # Calculer le ratio de densité (droite/gauche)
    $densityRatio = if ($leftTailDensity -ne 0) {
        $rightTailDensity / $leftTailDensity
    } else {
        [double]::PositiveInfinity
    }

    # Évaluer l'intensité de l'asymétrie
    $asymmetryEvaluation = Get-AsymmetryIntensityScale -DensityRatio $densityRatio -SampleSize $Data.Count -DistributionType "Auto" -ConfidenceLevel $ConfidenceLevel

    # Créer l'objet de résultat
    $result = @{
        Data                 = $Data
        SampleSize           = $Data.Count
        Mean                 = $mean
        Median               = $median
        StdDev               = $stdDev
        TailProportion       = $TailProportion
        LowerThreshold       = $lowerThreshold
        UpperThreshold       = $upperThreshold
        LeftTailSize         = $leftTailData.Count
        RightTailSize        = $rightTailData.Count
        BandwidthMethod      = $BandwidthMethod
        Bandwidth            = $bandwidth
        LeftEvaluationPoint  = $leftEvaluationPoint
        RightEvaluationPoint = $rightEvaluationPoint
        LeftTailDensity      = $leftTailDensity
        RightTailDensity     = $rightTailDensity
        DensityRatio         = $densityRatio
        AsymmetryEvaluation  = $asymmetryEvaluation
    }

    return $result
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-DensityRatioThresholds, Get-AdaptiveDensityRatioThresholds, Get-AsymmetryIntensityScale, Get-DensityBasedAsymmetry
