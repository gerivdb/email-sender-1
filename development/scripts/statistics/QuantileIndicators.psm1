# QuantileIndicators.psm1
# Module pour le calcul des quantiles et des indicateurs basés sur les quantiles

<#
.SYNOPSIS
    Calcule un quantile d'une distribution.

.DESCRIPTION
    Cette fonction calcule un quantile d'une distribution selon différentes méthodes.
    Les méthodes disponibles sont :
    - R1 : Inverse de la fonction de répartition empirique (méthode par défaut)
    - R2 : Méthode des moyennes pondérées des deux valeurs adjacentes
    - R3 : Méthode de l'observation la plus proche
    - R4 : Méthode de l'interpolation linéaire
    - R5 : Méthode de l'interpolation parabolique
    - R6 : Méthode de l'interpolation par fonction de répartition
    - R7 : Méthode de l'interpolation par fonction de densité
    - R8 : Méthode des rangs moyens
    - R9 : Méthode des rangs normaux

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Probability
    La probabilité du quantile à calculer (entre 0 et 1).

.PARAMETER Method
    La méthode de calcul du quantile (par défaut "R7").

.EXAMPLE
    Get-Quantile -Data $data -Probability 0.5 -Method "R7"
    Calcule la médiane (quantile 0.5) de la distribution $data selon la méthode R7.

.OUTPUTS
    System.Double
#>
function Get-Quantile {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Probability,

        [Parameter(Mandatory = $false)]
        [ValidateSet("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9")]
        [string]$Method = "R7"
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Cas particuliers
    if ($Probability -eq 0) {
        return ($Data | Measure-Object -Minimum).Minimum
    }
    if ($Probability -eq 1) {
        return ($Data | Measure-Object -Maximum).Maximum
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer le rang
    $n = $sortedData.Count
    $index = $Probability * $n

    # Calculer le quantile selon la méthode choisie
    switch ($Method) {
        "R1" {
            # Inverse de la fonction de répartition empirique
            $k = [Math]::Ceiling($index)
            if ($k -eq 0) { $k = 1 }
            return $sortedData[$k - 1]
        }
        "R2" {
            # Méthode des moyennes pondérées des deux valeurs adjacentes
            $k = [Math]::Ceiling($index)
            if ($k -eq 0) { $k = 1 }
            if ($k -eq $n) { return $sortedData[$n - 1] }
            $alpha = $index - [Math]::Floor($index)
            return $sortedData[$k - 1] * (1 - $alpha) + $sortedData[$k] * $alpha
        }
        "R3" {
            # Méthode de l'observation la plus proche
            $k = [Math]::Round($index)
            if ($k -eq 0) { $k = 1 }
            if ($k -gt $n) { $k = $n }
            return $sortedData[$k - 1]
        }
        "R4" {
            # Méthode de l'interpolation linéaire
            $k = [Math]::Floor($index)
            $d = $index - $k
            if ($k -eq 0) { return $sortedData[0] }
            if ($k -ge $n) { return $sortedData[$n - 1] }
            return $sortedData[$k - 1] + $d * ($sortedData[$k] - $sortedData[$k - 1])
        }
        "R5" {
            # Méthode de l'interpolation parabolique
            $k = [Math]::Floor($index)
            $d = $index - $k
            if ($k -le 0) { return $sortedData[0] }
            if ($k -ge $n - 1) { return $sortedData[$n - 1] }
            $a = ($sortedData[$k + 1] - $sortedData[$k - 1]) / 2
            $b = $sortedData[$k] - $sortedData[$k - 1] - $a
            return $sortedData[$k - 1] + $d * ($a + $b * (2 * $d - 1))
        }
        "R6" {
            # Méthode de l'interpolation par fonction de répartition
            $k = [Math]::Floor($index)
            $d = $index - $k
            if ($k -eq 0) { return $sortedData[0] }
            if ($k -ge $n) { return $sortedData[$n - 1] }
            $h = ($k + $d) / $n
            return $sortedData[$k - 1] * (1 - $h) + $sortedData[$k] * $h
        }
        "R7" {
            # Méthode de l'interpolation par fonction de densité (méthode par défaut)
            $h = $n * $Probability + 0.5
            $k = [Math]::Floor($h)
            $d = $h - $k
            if ($k -eq 0) { return $sortedData[0] }
            if ($k -ge $n) { return $sortedData[$n - 1] }
            return $sortedData[$k - 1] + $d * ($sortedData[$k] - $sortedData[$k - 1])
        }
        "R8" {
            # Méthode des rangs moyens
            $h = $n * $Probability + 0.5
            $k = [Math]::Floor($h)
            if ($k -eq 0) { return $sortedData[0] }
            if ($k -ge $n) { return $sortedData[$n - 1] }
            return $sortedData[$k - 1]
        }
        "R9" {
            # Méthode des rangs normaux
            $h = $n * $Probability + 1 / 3
            $k = [Math]::Floor($h)
            $d = $h - $k
            if ($k -eq 0) { return $sortedData[0] }
            if ($k -ge $n) { return $sortedData[$n - 1] }
            return $sortedData[$k - 1] + $d * ($sortedData[$k] - $sortedData[$k - 1])
        }
        default {
            throw "Méthode de calcul du quantile non reconnue: $Method"
        }
    }
}

<#
.SYNOPSIS
    Calcule un quantile pondéré d'une distribution.

.DESCRIPTION
    Cette fonction calcule un quantile pondéré d'une distribution selon différentes méthodes de pondération.
    Les méthodes de pondération disponibles sont :
    - Frequency : Pondération par fréquence (méthode par défaut)
    - Importance : Pondération par importance
    - Distance : Pondération par distance
    - Custom : Pondération personnalisée

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Weights
    Les poids associés à chaque valeur de la distribution.

.PARAMETER Probability
    La probabilité du quantile à calculer (entre 0 et 1).

.PARAMETER WeightingMethod
    La méthode de pondération à utiliser (par défaut "Frequency").

.PARAMETER QuantileMethod
    La méthode de calcul du quantile (par défaut "R7").

.EXAMPLE
    Get-WeightedQuantile -Data $data -Weights $weights -Probability 0.5 -WeightingMethod "Frequency"
    Calcule la médiane pondérée (quantile 0.5) de la distribution $data avec les poids $weights selon la méthode de pondération par fréquence.

.OUTPUTS
    System.Double
#>
function Get-WeightedQuantile {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Weights,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Probability,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Frequency", "Importance", "Distance", "Custom")]
        [string]$WeightingMethod = "Frequency",

        [Parameter(Mandatory = $false)]
        [ValidateSet("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9")]
        [string]$QuantileMethod = "R7"
    )

    # Vérifier que les données et les poids ont la même taille
    if ($Data.Count -ne $Weights.Count) {
        throw "Les données et les poids doivent avoir la même taille."
    }

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Vérifier que les poids sont positifs
    if (($Weights | Where-Object { $_ -lt 0 }).Count -gt 0) {
        throw "Les poids doivent être positifs."
    }

    # Cas particuliers
    if ($Probability -eq 0) {
        $minIndex = 0
        $minValue = $Data[0]
        for ($i = 1; $i -lt $Data.Count; $i++) {
            if ($Data[$i] -lt $minValue) {
                $minValue = $Data[$i]
                $minIndex = $i
            }
        }
        return $Data[$minIndex]
    }
    if ($Probability -eq 1) {
        $maxIndex = 0
        $maxValue = $Data[0]
        for ($i = 1; $i -lt $Data.Count; $i++) {
            if ($Data[$i] -gt $maxValue) {
                $maxValue = $Data[$i]
                $maxIndex = $i
            }
        }
        return $Data[$maxIndex]
    }

    # Normaliser les poids selon la méthode de pondération
    $normalizedWeights = @()
    switch ($WeightingMethod) {
        "Frequency" {
            # Pondération par fréquence (méthode par défaut)
            $sum = ($Weights | Measure-Object -Sum).Sum
            $normalizedWeights = $Weights | ForEach-Object { $_ / $sum }
        }
        "Importance" {
            # Pondération par importance
            $max = ($Weights | Measure-Object -Maximum).Maximum
            $normalizedWeights = $Weights | ForEach-Object { $_ / $max }
            $sum = ($normalizedWeights | Measure-Object -Sum).Sum
            $normalizedWeights = $normalizedWeights | ForEach-Object { $_ / $sum }
        }
        "Distance" {
            # Pondération par distance
            $mean = ($Data | Measure-Object -Average).Average
            $distances = $Data | ForEach-Object { [Math]::Abs($_ - $mean) }
            $maxDistance = ($distances | Measure-Object -Maximum).Maximum
            $normalizedDistances = $distances | ForEach-Object { 1 - ($_ / $maxDistance) }
            $normalizedWeights = @()
            for ($i = 0; $i -lt $Weights.Count; $i++) {
                $normalizedWeights += $Weights[$i] * $normalizedDistances[$i]
            }
            $sum = ($normalizedWeights | Measure-Object -Sum).Sum
            $normalizedWeights = $normalizedWeights | ForEach-Object { $_ / $sum }
        }
        "Custom" {
            # Pondération personnalisée (les poids sont déjà normalisés)
            $sum = ($Weights | Measure-Object -Sum).Sum
            $normalizedWeights = $Weights | ForEach-Object { $_ / $sum }
        }
        default {
            throw "Méthode de pondération non reconnue: $WeightingMethod"
        }
    }

    # Calculer la fonction de répartition empirique pondérée
    $cumulativeWeights = @()
    $cumulativeSum = 0
    foreach ($weight in $normalizedWeights) {
        $cumulativeSum += $weight
        $cumulativeWeights += $cumulativeSum
    }

    # Trier les données et les poids
    $sortedIndices = [Array]::CreateInstance([int], $Data.Count)
    for ($i = 0; $i -lt $Data.Count; $i++) {
        $sortedIndices[$i] = $i
    }
    [Array]::Sort($Data, $sortedIndices)
    $sortedWeights = [Array]::CreateInstance([double], $Weights.Count)
    $sortedCumulativeWeights = [Array]::CreateInstance([double], $cumulativeWeights.Count)
    for ($i = 0; $i -lt $Weights.Count; $i++) {
        $sortedWeights[$i] = $normalizedWeights[$sortedIndices[$i]]
        $sortedCumulativeWeights[$i] = $cumulativeWeights[$sortedIndices[$i]]
    }

    # Calculer le quantile pondéré
    $index = 0
    while ($index -lt $sortedCumulativeWeights.Count -and $sortedCumulativeWeights[$index] -lt $Probability) {
        $index++
    }

    if ($index -eq 0) {
        return $Data[0]
    }
    if ($index -eq $sortedCumulativeWeights.Count) {
        return $Data[$Data.Count - 1]
    }

    # Interpolation linéaire
    $x1 = $sortedCumulativeWeights[$index - 1]
    $x2 = $sortedCumulativeWeights[$index]
    $y1 = $Data[$index - 1]
    $y2 = $Data[$index]
    $t = ($Probability - $x1) / ($x2 - $x1)
    return $y1 + $t * ($y2 - $y1)
}

<#
.SYNOPSIS
    Calcule l'écart interquartile (IQR) d'une distribution.

.DESCRIPTION
    Cette fonction calcule l'écart interquartile (IQR) d'une distribution,
    qui est la différence entre le troisième quartile (Q3) et le premier quartile (Q1).

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Method
    La méthode de calcul des quantiles (par défaut "R7").

.EXAMPLE
    Get-InterquartileRange -Data $data -Method "R7"
    Calcule l'écart interquartile de la distribution $data selon la méthode R7.

.OUTPUTS
    System.Double
#>
function Get-InterquartileRange {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9")]
        [string]$Method = "R7"
    )

    # Calculer le premier quartile (Q1)
    $q1 = Get-Quantile -Data $Data -Probability 0.25 -Method $Method

    # Calculer le troisième quartile (Q3)
    $q3 = Get-Quantile -Data $Data -Probability 0.75 -Method $Method

    # Calculer l'écart interquartile (IQR)
    return $q3 - $q1
}

<#
.SYNOPSIS
    Calcule le coefficient d'asymétrie de Bowley d'une distribution.

.DESCRIPTION
    Cette fonction calcule le coefficient d'asymétrie de Bowley d'une distribution,
    qui est basé sur les quartiles et est robuste aux valeurs aberrantes.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Method
    La méthode de calcul des quantiles (par défaut "R7").

.EXAMPLE
    Get-BowleySkewness -Data $data -Method "R7"
    Calcule le coefficient d'asymétrie de Bowley de la distribution $data selon la méthode R7.

.OUTPUTS
    System.Double
#>
function Get-BowleySkewness {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9")]
        [string]$Method = "R7"
    )

    # Calculer le premier quartile (Q1)
    $q1 = Get-Quantile -Data $Data -Probability 0.25 -Method $Method

    # Calculer le deuxième quartile (Q2 = médiane)
    $q2 = Get-Quantile -Data $Data -Probability 0.5 -Method $Method

    # Calculer le troisième quartile (Q3)
    $q3 = Get-Quantile -Data $Data -Probability 0.75 -Method $Method

    # Calculer le coefficient d'asymétrie de Bowley
    if ($q3 - $q1 -eq 0) {
        return 0
    }
    return (($q3 - $q2) - ($q2 - $q1)) / ($q3 - $q1)
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-Quantile, Get-WeightedQuantile, Get-InterquartileRange, Get-BowleySkewness
