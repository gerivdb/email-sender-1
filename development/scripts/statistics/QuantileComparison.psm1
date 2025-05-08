# QuantileComparison.psm1
# Module pour l'analyse comparative des quantiles

<#
.SYNOPSIS
    Génère les données pour un graphique quantile-quantile (Q-Q plot) comparant deux distributions.

.DESCRIPTION
    Cette fonction calcule les points pour un graphique quantile-quantile (Q-Q plot)
    qui permet de comparer visuellement deux distributions.

.PARAMETER ReferenceData
    Les données de la distribution de référence.

.PARAMETER ComparisonData
    Les données de la distribution à comparer.

.PARAMETER Quantiles
    Les quantiles à utiliser pour la comparaison (par défaut, 100 quantiles équidistants).

.PARAMETER ConfidenceBands
    Indique si des bandes de confiance doivent être calculées.

.PARAMETER ConfidenceLevel
    Le niveau de confiance pour les bandes de confiance (par défaut, 0.95).

.EXAMPLE
    Get-QuantileQuantilePlot -ReferenceData $normalData -ComparisonData $skewedData
    Génère les données pour un graphique Q-Q comparant une distribution normale et une distribution asymétrique.

.OUTPUTS
    PSObject
#>
function Get-QuantileQuantilePlot {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$ReferenceData,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$ComparisonData,

        [Parameter(Mandatory = $false)]
        [double[]]$Quantiles = $null,

        [Parameter(Mandatory = $false)]
        [switch]$ConfidenceBands,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceLevel = 0.95
    )

    # Vérifier que les données ne sont pas vides
    if ($ReferenceData.Count -eq 0 -or $ComparisonData.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Créer les quantiles si non spécifiés
    if ($null -eq $Quantiles) {
        $n = [Math]::Min(100, [Math]::Min($ReferenceData.Count, $ComparisonData.Count))
        $Quantiles = 1..$n | ForEach-Object { $_ / ($n + 1) }
    }

    # Trier les données
    $sortedReferenceData = $ReferenceData | Sort-Object
    $sortedComparisonData = $ComparisonData | Sort-Object

    # Calculer les quantiles pour chaque distribution
    $referenceQuantiles = @()
    $comparisonQuantiles = @()

    foreach ($p in $Quantiles) {
        $refIndex = [Math]::Floor($p * $sortedReferenceData.Count)
        $compIndex = [Math]::Floor($p * $sortedComparisonData.Count)

        # Ajuster les indices pour éviter les dépassements
        if ($refIndex -ge $sortedReferenceData.Count) { $refIndex = $sortedReferenceData.Count - 1 }
        if ($compIndex -ge $sortedComparisonData.Count) { $compIndex = $sortedComparisonData.Count - 1 }

        $referenceQuantiles += $sortedReferenceData[$refIndex]
        $comparisonQuantiles += $sortedComparisonData[$compIndex]
    }

    # Calculer les bandes de confiance si demandé
    $lowerBand = $null
    $upperBand = $null

    if ($ConfidenceBands) {
        $alpha = 1 - $ConfidenceLevel
        $z = Get-NormalQuantile -Probability (1 - $alpha / 2)

        $lowerBand = @()
        $upperBand = @()

        for ($i = 0; $i -lt $referenceQuantiles.Count; $i++) {
            $p = $Quantiles[$i]
            $se = [Math]::Sqrt($p * (1 - $p) / $sortedReferenceData.Count)
            $width = $z * $se * ($sortedReferenceData[-1] - $sortedReferenceData[0])

            $lowerBand += $referenceQuantiles[$i] - $width
            $upperBand += $referenceQuantiles[$i] + $width
        }
    }

    # Calculer les métriques de déviation
    $deviations = @()
    for ($i = 0; $i -lt $referenceQuantiles.Count; $i++) {
        $deviation = $comparisonQuantiles[$i] - $referenceQuantiles[$i]
        $deviations += $deviation
    }

    $meanDeviation = ($deviations | Measure-Object -Average).Average
    $maxDeviation = ($deviations | Measure-Object -Maximum).Maximum
    $minDeviation = ($deviations | Measure-Object -Minimum).Minimum
    $sumSquaredDeviation = ($deviations | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Probabilities       = $Quantiles
        ReferenceQuantiles  = $referenceQuantiles
        ComparisonQuantiles = $comparisonQuantiles
        LowerBand           = $lowerBand
        UpperBand           = $upperBand
        Deviations          = $deviations
        MeanDeviation       = $meanDeviation
        MaxDeviation        = $maxDeviation
        MinDeviation        = $minDeviation
        SumSquaredDeviation = $sumSquaredDeviation
        ReferenceData       = $ReferenceData
        ComparisonData      = $ComparisonData
    }

    return $result
}

<#
.SYNOPSIS
    Calcule le quantile d'une distribution normale standard.

.DESCRIPTION
    Cette fonction calcule le quantile d'une distribution normale standard
    pour une probabilité donnée.

.PARAMETER Probability
    La probabilité du quantile à calculer (entre 0 et 1).

.EXAMPLE
    Get-NormalQuantile -Probability 0.975
    Calcule le quantile 0.975 de la distribution normale standard (environ 1.96).

.OUTPUTS
    System.Double
#>
function Get-NormalQuantile {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Probability
    )

    # Cas particuliers
    if ($Probability -eq 0) { return [double]::NegativeInfinity }
    if ($Probability -eq 1) { return [double]::PositiveInfinity }
    if ($Probability -eq 0.5) { return 0 }

    # Approximation du quantile de la loi normale standard
    # Méthode de Acklam (2009)

    # Coefficients pour l'approximation
    $a1 = -3.969683028665376e+01
    $a2 = 2.209460984245205e+02
    $a3 = -2.759285104469687e+02
    $a4 = 1.383577518672690e+02
    $a5 = -3.066479806614716e+01
    $a6 = 2.506628277459239e+00

    $b1 = -5.447609879822406e+01
    $b2 = 1.615858368580409e+02
    $b3 = -1.556989798598866e+02
    $b4 = 6.680131188771972e+01
    $b5 = -1.328068155288572e+01

    $c1 = -7.784894002430293e-03
    $c2 = -3.223964580411365e-01
    $c3 = -2.400758277161838e+00
    $c4 = -2.549732539343734e+00
    $c5 = 4.374664141464968e+00
    $c6 = 2.938163982698783e+00

    $d1 = 7.784695709041462e-03
    $d2 = 3.224671290700398e-01
    $d3 = 2.445134137142996e+00
    $d4 = 3.754408661907416e+00

    # Ajuster la probabilité pour la symétrie
    $q = $Probability
    $r = 0

    if ($q -lt 0.5) {
        $q = 1 - $q
        $r = 1
    }

    # Transformation pour améliorer la précision
    $p = $q - 0.5

    # Calcul du quantile selon la région
    $result = 0

    if ([Math]::Abs($p) -le 0.425) {
        # Région centrale
        $x = $p * $p
        $num = (($a1 * $x + $a2) * $x + $a3) * $x + $a4
        $num = (($num * $x + $a5) * $x + $a6) * $p
        $den = (($b1 * $x + $b2) * $x + $b3) * $x + $b4
        $den = ($den * $x + $b5) * $x + 1
        $result = $num / $den
    } else {
        # Régions extrêmes
        if ($p -gt 0) {
            $x = [Math]::Sqrt(-2 * [Math]::Log($q))
        } else {
            $x = [Math]::Sqrt(-2 * [Math]::Log(1 - $q))
        }

        $num = (($c1 * $x + $c2) * $x + $c3) * $x + $c4
        $num = (($num * $x + $c5) * $x + $c6)
        $den = (($d1 * $x + $d2) * $x + $d3) * $x + $d4
        $den = $den * $x + 1
        $result = $num / $den
    }

    # Ajuster le signe selon la symétrie
    if ($r -eq 1) {
        $result = - $result
    }

    return $result
}

<#
.SYNOPSIS
    Calcule des métriques de comparaison entre deux distributions basées sur les quantiles.

.DESCRIPTION
    Cette fonction calcule diverses métriques pour comparer deux distributions
    en utilisant leurs quantiles.

.PARAMETER ReferenceData
    Les données de la distribution de référence.

.PARAMETER ComparisonData
    Les données de la distribution à comparer.

.PARAMETER Quantiles
    Les quantiles à utiliser pour la comparaison (par défaut, 100 quantiles équidistants).

.PARAMETER Metrics
    Les métriques à calculer (par défaut, toutes les métriques disponibles).
    Les métriques disponibles sont :
    - KolmogorovSmirnov : Distance maximale entre les fonctions de répartition
    - CramerVonMises : Somme des carrés des différences entre les fonctions de répartition
    - AndersonDarling : Somme pondérée des carrés des différences entre les fonctions de répartition
    - Wasserstein : Distance moyenne entre les quantiles
    - All : Toutes les métriques ci-dessus

.EXAMPLE
    Get-QuantileComparisonMetrics -ReferenceData $normalData -ComparisonData $skewedData -Metrics @("KolmogorovSmirnov", "Wasserstein")
    Calcule les métriques de Kolmogorov-Smirnov et de Wasserstein pour comparer une distribution normale et une distribution asymétrique.

.OUTPUTS
    PSObject
#>
function Get-QuantileComparisonMetrics {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$ReferenceData,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$ComparisonData,

        [Parameter(Mandatory = $false)]
        [double[]]$Quantiles = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("KolmogorovSmirnov", "CramerVonMises", "AndersonDarling", "Wasserstein", "All")]
        [string[]]$Metrics = @("All")
    )

    # Vérifier que les données ne sont pas vides
    if ($ReferenceData.Count -eq 0 -or $ComparisonData.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Créer les quantiles si non spécifiés
    if ($null -eq $Quantiles) {
        $n = [Math]::Min(100, [Math]::Min($ReferenceData.Count, $ComparisonData.Count))
        $Quantiles = 1..$n | ForEach-Object { $_ / ($n + 1) }
    }

    # Trier les données
    $sortedReferenceData = $ReferenceData | Sort-Object
    $sortedComparisonData = $ComparisonData | Sort-Object

    # Calculer les quantiles pour chaque distribution
    $referenceQuantiles = @()
    $comparisonQuantiles = @()

    foreach ($p in $Quantiles) {
        $refIndex = [Math]::Floor($p * $sortedReferenceData.Count)
        $compIndex = [Math]::Floor($p * $sortedComparisonData.Count)

        # Ajuster les indices pour éviter les dépassements
        if ($refIndex -ge $sortedReferenceData.Count) { $refIndex = $sortedReferenceData.Count - 1 }
        if ($compIndex -ge $sortedComparisonData.Count) { $compIndex = $sortedComparisonData.Count - 1 }

        $referenceQuantiles += $sortedReferenceData[$refIndex]
        $comparisonQuantiles += $sortedComparisonData[$compIndex]
    }

    # Calculer les métriques demandées
    $result = [PSCustomObject]@{
        Metrics             = @{}
        ReferenceData       = $ReferenceData
        ComparisonData      = $ComparisonData
        Quantiles           = $Quantiles
        ReferenceQuantiles  = $referenceQuantiles
        ComparisonQuantiles = $comparisonQuantiles
    }

    # Calculer toutes les métriques si "All" est spécifié
    if ($Metrics -contains "All") {
        $Metrics = @("KolmogorovSmirnov", "CramerVonMises", "AndersonDarling", "Wasserstein")
    }

    # Calculer la métrique de Kolmogorov-Smirnov
    if ($Metrics -contains "KolmogorovSmirnov") {
        $maxDiff = 0
        for ($i = 0; $i -lt $Quantiles.Count; $i++) {
            $diff = [Math]::Abs($referenceQuantiles[$i] - $comparisonQuantiles[$i])
            if ($diff -gt $maxDiff) {
                $maxDiff = $diff
            }
        }
        $result.Metrics["KolmogorovSmirnov"] = $maxDiff
    }

    # Calculer la métrique de Cramer-von Mises
    if ($Metrics -contains "CramerVonMises") {
        $sum = 0
        for ($i = 0; $i -lt $Quantiles.Count; $i++) {
            $diff = $referenceQuantiles[$i] - $comparisonQuantiles[$i]
            $sum += $diff * $diff
        }
        $result.Metrics["CramerVonMises"] = $sum / $Quantiles.Count
    }

    # Calculer la métrique d'Anderson-Darling
    if ($Metrics -contains "AndersonDarling") {
        $sum = 0
        for ($i = 0; $i -lt $Quantiles.Count; $i++) {
            $p = $Quantiles[$i]
            $weight = 1 / ($p * (1 - $p))
            $diff = $referenceQuantiles[$i] - $comparisonQuantiles[$i]
            $sum += $weight * $diff * $diff
        }
        $result.Metrics["AndersonDarling"] = $sum / $Quantiles.Count
    }

    # Calculer la métrique de Wasserstein
    if ($Metrics -contains "Wasserstein") {
        $sum = 0
        for ($i = 0; $i -lt $Quantiles.Count; $i++) {
            $diff = [Math]::Abs($referenceQuantiles[$i] - $comparisonQuantiles[$i])
            $sum += $diff
        }
        $result.Metrics["Wasserstein"] = $sum / $Quantiles.Count
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-QuantileQuantilePlot, Get-NormalQuantile, Get-QuantileComparisonMetrics
