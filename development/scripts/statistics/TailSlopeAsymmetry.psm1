# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Module pour l'évaluation de l'asymétrie basée sur les pentes des queues de distribution.

.DESCRIPTION
    Ce module fournit des fonctions pour évaluer l'asymétrie des distributions
    en utilisant les pentes des queues de distribution obtenues par régression linéaire.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-06-02
#>

#region Variables globales et constantes

# Méthodes de détermination des seuils de queue
$script:TailThresholdMethods = @{
    "Quantile"      = "Utilise des quantiles fixes pour déterminer les queues"
    "Adaptive"      = "Ajuste les seuils en fonction de la forme de la distribution"
    "KernelDensity" = "Utilise l'estimation de densité par noyau pour identifier les queues"
    "Percentile"    = "Utilise des percentiles pour déterminer les queues"
}

# Méthodes de régression pour les queues
$script:TailRegressionMethods = @{
    "Linear"   = "Régression linéaire standard"
    "Robust"   = "Régression robuste moins sensible aux valeurs aberrantes"
    "Weighted" = "Régression pondérée donnant plus de poids aux points extrêmes"
}

#endregion

#region Fonctions principales

<#
.SYNOPSIS
    Extrait les points des queues d'une distribution.

.DESCRIPTION
    Cette fonction extrait les points des queues gauche et droite d'une distribution
    en utilisant différentes méthodes pour déterminer les seuils de queue.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER Method
    La méthode à utiliser pour déterminer les seuils de queue (par défaut "Quantile").

.PARAMETER AdaptiveThreshold
    Le seuil adaptatif à utiliser si la méthode est "Adaptive" (par défaut 1.5).

.EXAMPLE
    Get-DistributionTails -Data $data -TailProportion 0.1 -Method "Quantile"
    Extrait les 10% de points les plus extrêmes de chaque côté de la distribution.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DistributionTails {
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
        [ValidateSet("Quantile", "Adaptive", "KernelDensity", "Percentile")]
        [string]$Method = "Quantile",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.5, 3.0)]
        [double]$AdaptiveThreshold = 1.5
    )

    # Vérifier que les données contiennent au moins 10 points
    if ($Data.Count -lt 10) {
        throw "Les données doivent contenir au moins 10 points pour extraire les queues de distribution."
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

    # Déterminer les seuils de queue en fonction de la méthode choisie
    $lowerThreshold = 0
    $upperThreshold = 0

    switch ($Method) {
        "Quantile" {
            # Utiliser des quantiles fixes
            $lowerIndex = [Math]::Floor($sortedData.Count * $TailProportion)
            $upperIndex = [Math]::Floor($sortedData.Count * (1 - $TailProportion))
            $lowerThreshold = $sortedData[$lowerIndex]
            $upperThreshold = $sortedData[$upperIndex]
        }
        "Adaptive" {
            # Utiliser des seuils adaptatifs basés sur l'écart-type
            $lowerThreshold = $mean - ($AdaptiveThreshold * $stdDev)
            $upperThreshold = $mean + ($AdaptiveThreshold * $stdDev)
        }
        "KernelDensity" {
            # Utiliser l'estimation de densité par noyau pour identifier les queues
            # Cette méthode est plus complexe et sera implémentée ultérieurement
            # Pour l'instant, utiliser la méthode des quantiles comme fallback
            $lowerIndex = [Math]::Floor($sortedData.Count * $TailProportion)
            $upperIndex = [Math]::Floor($sortedData.Count * (1 - $TailProportion))
            $lowerThreshold = $sortedData[$lowerIndex]
            $upperThreshold = $sortedData[$upperIndex]
        }
        "Percentile" {
            # Utiliser des percentiles
            $lowerPercentile = $TailProportion * 100
            $upperPercentile = (1 - $TailProportion) * 100
            $lowerThreshold = Get-Percentile -Data $sortedData -Percentile $lowerPercentile
            $upperThreshold = Get-Percentile -Data $sortedData -Percentile $upperPercentile
        }
        default {
            # Par défaut, utiliser la méthode des quantiles
            $lowerIndex = [Math]::Floor($sortedData.Count * $TailProportion)
            $upperIndex = [Math]::Floor($sortedData.Count * (1 - $TailProportion))
            $lowerThreshold = $sortedData[$lowerIndex]
            $upperThreshold = $sortedData[$upperIndex]
        }
    }

    # Extraire les points des queues
    $leftTailData = @()
    $rightTailData = @()

    # Extraire les points de la queue gauche (valeurs inférieures au seuil inférieur)
    for ($i = 0; $i -lt $sortedData.Count; $i++) {
        if ($sortedData[$i] -le $lowerThreshold) {
            $leftTailData += @{
                Value             = $sortedData[$i]
                Index             = $i
                Position          = $i / $sortedData.Count
                StandardizedValue = ($sortedData[$i] - $mean) / $stdDev
            }
        }
    }

    # Extraire les points de la queue droite (valeurs supérieures au seuil supérieur)
    for ($i = 0; $i -lt $sortedData.Count; $i++) {
        if ($sortedData[$i] -ge $upperThreshold) {
            $rightTailData += @{
                Value             = $sortedData[$i]
                Index             = $i
                Position          = $i / $sortedData.Count
                StandardizedValue = ($sortedData[$i] - $mean) / $stdDev
            }
        }
    }

    # Créer l'objet de résultat
    $result = @{
        Data              = $Data
        SortedData        = $sortedData
        Mean              = $mean
        Median            = $median
        StdDev            = $stdDev
        Method            = $Method
        TailProportion    = $TailProportion
        AdaptiveThreshold = $AdaptiveThreshold
        LowerThreshold    = $lowerThreshold
        UpperThreshold    = $upperThreshold
        LeftTailData      = $leftTailData
        RightTailData     = $rightTailData
        LeftTailSize      = $leftTailData.Count
        RightTailSize     = $rightTailData.Count
    }

    return $result
}

<#
.SYNOPSIS
    Calcule un percentile spécifique pour un ensemble de données.

.DESCRIPTION
    Cette fonction calcule un percentile spécifique pour un ensemble de données triées.

.PARAMETER Data
    Les données triées.

.PARAMETER Percentile
    Le percentile à calculer (entre 0 et 100).

.EXAMPLE
    Get-Percentile -Data $sortedData -Percentile 25
    Calcule le 25e percentile (premier quartile) des données.

.OUTPUTS
    System.Double
#>
function Get-Percentile {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [double]$Percentile
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Calculer l'indice correspondant au percentile
    $index = $Percentile / 100 * ($Data.Count - 1)
    $lowerIndex = [Math]::Floor($index)
    $upperIndex = [Math]::Ceiling($index)

    # Si l'indice est un entier, retourner directement la valeur correspondante
    if ($lowerIndex -eq $upperIndex) {
        return $Data[$lowerIndex]
    }

    # Sinon, interpoler entre les deux valeurs adjacentes
    $fraction = $index - $lowerIndex
    $lowerValue = $Data[$lowerIndex]
    $upperValue = $Data[$upperIndex]
    $interpolatedValue = $lowerValue + $fraction * ($upperValue - $lowerValue)

    return $interpolatedValue
}

<#
.SYNOPSIS
    Calcule la régression linéaire pour une queue de distribution.

.DESCRIPTION
    Cette fonction calcule la régression linéaire pour une queue de distribution
    en utilisant différentes méthodes de régression.

.PARAMETER TailData
    Les données de la queue de distribution (obtenues via Get-DistributionTails).

.PARAMETER Method
    La méthode de régression à utiliser (par défaut "Linear").

.PARAMETER WeightFunction
    La fonction de pondération à utiliser si la méthode est "Weighted" (par défaut "Exponential").

.EXAMPLE
    Get-TailLinearRegression -TailData $leftTailData -Method "Linear"
    Calcule la régression linéaire pour la queue gauche de la distribution.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-TailLinearRegression {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject[]]$TailData,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Linear", "Robust", "Weighted")]
        [string]$Method = "Linear",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Exponential", "Linear", "Quadratic")]
        [string]$WeightFunction = "Exponential"
    )

    # Vérifier que les données ne sont pas vides
    if ($TailData.Count -eq 0) {
        throw "Les données de queue ne peuvent pas être vides."
    }

    # Extraire les valeurs et les positions pour la régression
    $xValues = @()
    $yValues = @()
    $weights = @()

    foreach ($point in $TailData) {
        $xValues += $point.Position
        $yValues += $point.Value

        # Calculer les poids pour la régression pondérée
        switch ($WeightFunction) {
            "Exponential" {
                # Poids exponentiels (plus de poids aux points extrêmes)
                $weights += [Math]::Exp([Math]::Abs($point.StandardizedValue))
            }
            "Linear" {
                # Poids linéaires
                $weights += 1 + [Math]::Abs($point.StandardizedValue)
            }
            "Quadratic" {
                # Poids quadratiques
                $weights += 1 + [Math]::Pow($point.StandardizedValue, 2)
            }
            default {
                # Par défaut, poids égaux
                $weights += 1
            }
        }
    }

    # Calculer la régression linéaire en fonction de la méthode choisie
    $slope = 0
    $intercept = 0
    $rSquared = 0
    $standardError = 0

    switch ($Method) {
        "Linear" {
            # Régression linéaire standard (méthode des moindres carrés)
            $result = Get-LinearRegression -XValues $xValues -YValues $yValues
            $slope = $result.Slope
            $intercept = $result.Intercept
            $rSquared = $result.RSquared
            $standardError = $result.StandardError
        }
        "Robust" {
            # Régression robuste (méthode des moindres déviations absolues)
            # Cette méthode est plus complexe et sera implémentée ultérieurement
            # Pour l'instant, utiliser la régression linéaire standard comme fallback
            $result = Get-LinearRegression -XValues $xValues -YValues $yValues
            $slope = $result.Slope
            $intercept = $result.Intercept
            $rSquared = $result.RSquared
            $standardError = $result.StandardError
        }
        "Weighted" {
            # Régression pondérée
            $result = Get-WeightedLinearRegression -XValues $xValues -YValues $yValues -Weights $weights
            $slope = $result.Slope
            $intercept = $result.Intercept
            $rSquared = $result.RSquared
            $standardError = $result.StandardError
        }
        default {
            # Par défaut, utiliser la régression linéaire standard
            $result = Get-LinearRegression -XValues $xValues -YValues $yValues
            $slope = $result.Slope
            $intercept = $result.Intercept
            $rSquared = $result.RSquared
            $standardError = $result.StandardError
        }
    }

    # Créer l'objet de résultat
    $result = @{
        TailData        = $TailData
        Method          = $Method
        WeightFunction  = $WeightFunction
        Slope           = $slope
        Intercept       = $intercept
        RSquared        = $rSquared
        StandardError   = $standardError
        XValues         = $xValues
        YValues         = $yValues
        Weights         = $weights
        PredictedValues = @()
        Residuals       = @()
    }

    # Calculer les valeurs prédites et les résidus
    for ($i = 0; $i -lt $xValues.Count; $i++) {
        $predictedValue = $intercept + $slope * $xValues[$i]
        $result.PredictedValues += $predictedValue
        $result.Residuals += $yValues[$i] - $predictedValue
    }

    return $result
}

<#
.SYNOPSIS
    Calcule la régression linéaire standard.

.DESCRIPTION
    Cette fonction calcule la régression linéaire standard (méthode des moindres carrés)
    pour un ensemble de valeurs x et y.

.PARAMETER XValues
    Les valeurs x.

.PARAMETER YValues
    Les valeurs y.

.EXAMPLE
    Get-LinearRegression -XValues $xValues -YValues $yValues
    Calcule la régression linéaire pour les valeurs x et y.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-LinearRegression {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$XValues,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$YValues
    )

    # Vérifier que les tableaux ont la même taille
    if ($XValues.Count -ne $YValues.Count) {
        throw "Les tableaux XValues et YValues doivent avoir la même taille."
    }

    # Vérifier qu'il y a au moins 2 points
    if ($XValues.Count -lt 2) {
        throw "Il faut au moins 2 points pour calculer une régression linéaire."
    }

    # Calculer les moyennes
    $n = $XValues.Count
    $meanX = ($XValues | Measure-Object -Average).Average
    $meanY = ($YValues | Measure-Object -Average).Average

    # Calculer les sommes nécessaires pour la régression
    $sumXY = 0
    $sumXX = 0
    $sumYY = 0
    $sumResidualSquared = 0

    for ($i = 0; $i -lt $n; $i++) {
        $xDiff = $XValues[$i] - $meanX
        $yDiff = $YValues[$i] - $meanY
        $sumXY += $xDiff * $yDiff
        $sumXX += $xDiff * $xDiff
        $sumYY += $yDiff * $yDiff
    }

    # Calculer la pente et l'ordonnée à l'origine
    $slope = if ($sumXX -ne 0) { $sumXY / $sumXX } else { 0 }
    $intercept = $meanY - $slope * $meanX

    # Calculer les valeurs prédites et les résidus
    $predictedValues = @()
    $residuals = @()

    for ($i = 0; $i -lt $n; $i++) {
        $predictedValue = $intercept + $slope * $XValues[$i]
        $predictedValues += $predictedValue
        $residual = $YValues[$i] - $predictedValue
        $residuals += $residual
        $sumResidualSquared += $residual * $residual
    }

    # Calculer le coefficient de détermination (R²)
    $rSquared = if ($sumYY -ne 0) { 1 - ($sumResidualSquared / $sumYY) } else { 0 }

    # Calculer l'erreur standard de la pente
    $standardError = if ($n -gt 2 -and $sumXX -ne 0) {
        [Math]::Sqrt($sumResidualSquared / (($n - 2) * $sumXX))
    } else {
        0
    }

    # Créer l'objet de résultat
    $result = @{
        Slope           = $slope
        Intercept       = $intercept
        RSquared        = $rSquared
        StandardError   = $standardError
        PredictedValues = $predictedValues
        Residuals       = $residuals
    }

    return $result
}

<#
.SYNOPSIS
    Calcule la régression linéaire pondérée.

.DESCRIPTION
    Cette fonction calcule la régression linéaire pondérée
    pour un ensemble de valeurs x et y avec des poids.

.PARAMETER XValues
    Les valeurs x.

.PARAMETER YValues
    Les valeurs y.

.PARAMETER Weights
    Les poids pour chaque point.

.EXAMPLE
    Get-WeightedLinearRegression -XValues $xValues -YValues $yValues -Weights $weights
    Calcule la régression linéaire pondérée pour les valeurs x et y avec les poids spécifiés.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-WeightedLinearRegression {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$XValues,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$YValues,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Weights
    )

    # Vérifier que les tableaux ont la même taille
    if ($XValues.Count -ne $YValues.Count -or $XValues.Count -ne $Weights.Count) {
        throw "Les tableaux XValues, YValues et Weights doivent avoir la même taille."
    }

    # Vérifier qu'il y a au moins 2 points
    if ($XValues.Count -lt 2) {
        throw "Il faut au moins 2 points pour calculer une régression linéaire."
    }

    # Calculer les sommes pondérées
    $n = $XValues.Count
    $sumWeights = ($Weights | Measure-Object -Sum).Sum
    $sumWeightedX = 0
    $sumWeightedY = 0
    $sumWeightedXY = 0
    $sumWeightedXX = 0
    $sumWeightedYY = 0
    $sumWeightedResidualSquared = 0

    for ($i = 0; $i -lt $n; $i++) {
        $sumWeightedX += $Weights[$i] * $XValues[$i]
        $sumWeightedY += $Weights[$i] * $YValues[$i]
        $sumWeightedXY += $Weights[$i] * $XValues[$i] * $YValues[$i]
        $sumWeightedXX += $Weights[$i] * $XValues[$i] * $XValues[$i]
        $sumWeightedYY += $Weights[$i] * $YValues[$i] * $YValues[$i]
    }

    # Calculer les moyennes pondérées
    $weightedMeanX = if ($sumWeights -ne 0) { $sumWeightedX / $sumWeights } else { 0 }
    $weightedMeanY = if ($sumWeights -ne 0) { $sumWeightedY / $sumWeights } else { 0 }

    # Calculer la pente et l'ordonnée à l'origine
    $numerator = $sumWeightedXY - $weightedMeanY * $sumWeightedX
    $denominator = $sumWeightedXX - $weightedMeanX * $sumWeightedX
    $slope = if ($denominator -ne 0) { $numerator / $denominator } else { 0 }
    $intercept = $weightedMeanY - $slope * $weightedMeanX

    # Calculer les valeurs prédites et les résidus
    $predictedValues = @()
    $residuals = @()

    for ($i = 0; $i -lt $n; $i++) {
        $predictedValue = $intercept + $slope * $XValues[$i]
        $predictedValues += $predictedValue
        $residual = $YValues[$i] - $predictedValue
        $residuals += $residual
        $sumWeightedResidualSquared += $Weights[$i] * $residual * $residual
    }

    # Calculer le coefficient de détermination pondéré (R²)
    $totalSumOfSquares = $sumWeightedYY - $sumWeights * $weightedMeanY * $weightedMeanY
    $rSquared = if ($totalSumOfSquares -ne 0) { 1 - ($sumWeightedResidualSquared / $totalSumOfSquares) } else { 0 }

    # Calculer l'erreur standard de la pente
    $standardError = if ($n -gt 2 -and $denominator -ne 0) {
        [Math]::Sqrt($sumWeightedResidualSquared / (($n - 2) * $denominator))
    } else {
        0
    }

    # Créer l'objet de résultat
    $result = @{
        Slope           = $slope
        Intercept       = $intercept
        RSquared        = $rSquared
        StandardError   = $standardError
        PredictedValues = $predictedValues
        Residuals       = $residuals
    }

    return $result
}

<#
.SYNOPSIS
    Calcule le ratio des pentes entre les queues d'une distribution.

.DESCRIPTION
    Cette fonction calcule le ratio des pentes entre les queues droite et gauche
    d'une distribution, ce qui permet d'évaluer l'asymétrie de la distribution.

.PARAMETER LeftTailRegression
    Les résultats de la régression linéaire pour la queue gauche.

.PARAMETER RightTailRegression
    Les résultats de la régression linéaire pour la queue droite.

.PARAMETER NormalizationMethod
    La méthode de normalisation à utiliser pour comparer les pentes (par défaut "Absolute").

.EXAMPLE
    Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression
    Calcule le ratio des pentes entre les queues droite et gauche de la distribution.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-TailSlopeRatio {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$LeftTailRegression,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$RightTailRegression,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Absolute", "Signed", "Normalized")]
        [string]$NormalizationMethod = "Absolute"
    )

    # Extraire les pentes des régressions
    $leftSlope = $LeftTailRegression.Slope
    $rightSlope = $RightTailRegression.Slope

    # Calculer le ratio des pentes en fonction de la méthode de normalisation
    $slopeRatio = 0
    $normalizedLeftSlope = 0
    $normalizedRightSlope = 0
    $asymmetryDirection = "Symétrique"

    switch ($NormalizationMethod) {
        "Absolute" {
            # Utiliser les valeurs absolues des pentes
            $absLeftSlope = [Math]::Abs($leftSlope)
            $absRightSlope = [Math]::Abs($rightSlope)

            # Calculer le ratio (plus grande pente / plus petite pente)
            if ($absLeftSlope -eq 0 -and $absRightSlope -eq 0) {
                $slopeRatio = 1.0
            } elseif ($absLeftSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } elseif ($absRightSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } else {
                $slopeRatio = if ($absLeftSlope -gt $absRightSlope) {
                    $absLeftSlope / $absRightSlope
                } else {
                    $absRightSlope / $absLeftSlope
                }
            }

            # Déterminer la direction de l'asymétrie
            if ($absLeftSlope -gt $absRightSlope) {
                $asymmetryDirection = "Queue gauche plus pentue"
            } elseif ($absRightSlope -gt $absLeftSlope) {
                $asymmetryDirection = "Queue droite plus pentue"
            } else {
                $asymmetryDirection = "Symétrique"
            }

            # Normaliser les pentes pour la comparaison
            $normalizedLeftSlope = $absLeftSlope
            $normalizedRightSlope = $absRightSlope
        }
        "Signed" {
            # Utiliser les signes des pentes pour déterminer la direction de l'asymétrie
            # Pour une distribution normale, les pentes devraient être de signes opposés
            # (positive pour la queue gauche, négative pour la queue droite)
            $signedRatio = if ($leftSlope -ne 0 -and $rightSlope -ne 0) {
                $leftSlope / $rightSlope
            } else {
                0
            }

            # Calculer le ratio des valeurs absolues
            $absLeftSlope = [Math]::Abs($leftSlope)
            $absRightSlope = [Math]::Abs($rightSlope)

            if ($absLeftSlope -eq 0 -and $absRightSlope -eq 0) {
                $slopeRatio = 1.0
            } elseif ($absLeftSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } elseif ($absRightSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } else {
                $slopeRatio = if ($absLeftSlope -gt $absRightSlope) {
                    $absLeftSlope / $absRightSlope
                } else {
                    $absRightSlope / $absLeftSlope
                }
            }

            # Déterminer la direction de l'asymétrie
            if ($signedRatio -gt 0) {
                # Les pentes ont le même signe (asymétrie)
                if ($leftSlope -gt 0 -and $rightSlope -gt 0) {
                    $asymmetryDirection = "Asymétrie positive (pentes positives)"
                } else {
                    $asymmetryDirection = "Asymétrie négative (pentes négatives)"
                }
            } else {
                # Les pentes ont des signes opposés (normal)
                if ($absLeftSlope -gt $absRightSlope) {
                    $asymmetryDirection = "Queue gauche plus pentue"
                } elseif ($absRightSlope -gt $absLeftSlope) {
                    $asymmetryDirection = "Queue droite plus pentue"
                } else {
                    $asymmetryDirection = "Symétrique"
                }
            }

            # Normaliser les pentes pour la comparaison
            $normalizedLeftSlope = $leftSlope
            $normalizedRightSlope = $rightSlope
        }
        "Normalized" {
            # Normaliser les pentes par rapport à la moyenne des valeurs absolues
            $absLeftSlope = [Math]::Abs($leftSlope)
            $absRightSlope = [Math]::Abs($rightSlope)
            $meanAbsSlope = ($absLeftSlope + $absRightSlope) / 2

            if ($meanAbsSlope -eq 0) {
                $normalizedLeftSlope = 0
                $normalizedRightSlope = 0
                $slopeRatio = 1.0
            } else {
                $normalizedLeftSlope = $absLeftSlope / $meanAbsSlope
                $normalizedRightSlope = $absRightSlope / $meanAbsSlope

                # Calculer le ratio normalisé
                if ($normalizedLeftSlope -eq 0 -and $normalizedRightSlope -eq 0) {
                    $slopeRatio = 1.0
                } elseif ($normalizedLeftSlope -eq 0) {
                    $slopeRatio = [double]::PositiveInfinity
                } elseif ($normalizedRightSlope -eq 0) {
                    $slopeRatio = [double]::PositiveInfinity
                } else {
                    $slopeRatio = if ($normalizedLeftSlope -gt $normalizedRightSlope) {
                        $normalizedLeftSlope / $normalizedRightSlope
                    } else {
                        $normalizedRightSlope / $normalizedLeftSlope
                    }
                }
            }

            # Déterminer la direction de l'asymétrie
            if ($absLeftSlope -gt $absRightSlope) {
                $asymmetryDirection = "Queue gauche plus pentue"
            } elseif ($absRightSlope -gt $absLeftSlope) {
                $asymmetryDirection = "Queue droite plus pentue"
            } else {
                $asymmetryDirection = "Symétrique"
            }
        }
        default {
            # Par défaut, utiliser la méthode "Absolute"
            $absLeftSlope = [Math]::Abs($leftSlope)
            $absRightSlope = [Math]::Abs($rightSlope)

            # Calculer le ratio (plus grande pente / plus petite pente)
            if ($absLeftSlope -eq 0 -and $absRightSlope -eq 0) {
                $slopeRatio = 1.0
            } elseif ($absLeftSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } elseif ($absRightSlope -eq 0) {
                $slopeRatio = [double]::PositiveInfinity
            } else {
                $slopeRatio = if ($absLeftSlope -gt $absRightSlope) {
                    $absLeftSlope / $absRightSlope
                } else {
                    $absRightSlope / $absLeftSlope
                }
            }

            # Déterminer la direction de l'asymétrie
            if ($absLeftSlope -gt $absRightSlope) {
                $asymmetryDirection = "Queue gauche plus pentue"
            } elseif ($absRightSlope -gt $absLeftSlope) {
                $asymmetryDirection = "Queue droite plus pentue"
            } else {
                $asymmetryDirection = "Symétrique"
            }

            # Normaliser les pentes pour la comparaison
            $normalizedLeftSlope = $absLeftSlope
            $normalizedRightSlope = $absRightSlope
        }
    }

    # Créer l'objet de résultat
    $result = @{
        LeftSlope              = $leftSlope
        RightSlope             = $rightSlope
        NormalizationMethod    = $NormalizationMethod
        NormalizedLeftSlope    = $normalizedLeftSlope
        NormalizedRightSlope   = $normalizedRightSlope
        SlopeRatio             = $slopeRatio
        AsymmetryDirection     = $asymmetryDirection
        LeftTailRSquared       = $LeftTailRegression.RSquared
        RightTailRSquared      = $RightTailRegression.RSquared
        LeftTailStandardError  = $LeftTailRegression.StandardError
        RightTailStandardError = $RightTailRegression.StandardError
    }

    return $result
}

<#
.SYNOPSIS
    Évalue l'asymétrie d'une distribution basée sur les pentes des queues.

.DESCRIPTION
    Cette fonction évalue l'asymétrie d'une distribution en calculant les pentes des queues
    et en analysant leur ratio, ce qui permet de détecter et de quantifier l'asymétrie.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER TailMethod
    La méthode à utiliser pour déterminer les seuils de queue (par défaut "Quantile").

.PARAMETER RegressionMethod
    La méthode de régression à utiliser (par défaut "Linear").

.PARAMETER NormalizationMethod
    La méthode de normalisation à utiliser pour comparer les pentes (par défaut "Absolute").

.EXAMPLE
    Get-TailSlopeAsymmetry -Data $data -TailProportion 0.1
    Évalue l'asymétrie d'une distribution en utilisant les pentes des queues.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-TailSlopeAsymmetry {
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
        [ValidateSet("Quantile", "Adaptive", "KernelDensity", "Percentile")]
        [string]$TailMethod = "Quantile",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Linear", "Robust", "Weighted")]
        [string]$RegressionMethod = "Linear",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Absolute", "Signed", "Normalized")]
        [string]$NormalizationMethod = "Absolute"
    )

    # Extraire les queues de la distribution
    $tails = Get-DistributionTails -Data $Data -TailProportion $TailProportion -Method $TailMethod

    # Calculer les régressions linéaires pour les queues
    $leftTailRegression = Get-TailLinearRegression -TailData $tails.LeftTailData -Method $RegressionMethod
    $rightTailRegression = Get-TailLinearRegression -TailData $tails.RightTailData -Method $RegressionMethod

    # Calculer le ratio des pentes
    $slopeRatio = Get-TailSlopeRatio -LeftTailRegression $leftTailRegression -RightTailRegression $rightTailRegression -NormalizationMethod $NormalizationMethod

    # Évaluer l'intensité de l'asymétrie
    $asymmetryIntensity = "Négligeable"
    $asymmetryValue = 0.0

    # Déterminer l'intensité de l'asymétrie en fonction du ratio des pentes
    if ($slopeRatio.SlopeRatio -lt 1.1) {
        $asymmetryIntensity = "Négligeable"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 1.0) / 0.1
    } elseif ($slopeRatio.SlopeRatio -lt 1.3) {
        $asymmetryIntensity = "Très faible"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 1.1) / 0.2 + 1.0
    } elseif ($slopeRatio.SlopeRatio -lt 1.5) {
        $asymmetryIntensity = "Faible"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 1.3) / 0.2 + 2.0
    } elseif ($slopeRatio.SlopeRatio -lt 2.0) {
        $asymmetryIntensity = "Modérée"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 1.5) / 0.5 + 3.0
    } elseif ($slopeRatio.SlopeRatio -lt 3.0) {
        $asymmetryIntensity = "Forte"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 2.0) / 1.0 + 4.0
    } elseif ($slopeRatio.SlopeRatio -lt 5.0) {
        $asymmetryIntensity = "Très forte"
        $asymmetryValue = ($slopeRatio.SlopeRatio - 3.0) / 2.0 + 5.0
    } else {
        $asymmetryIntensity = "Extrême"
        $asymmetryValue = 7.0
    }

    # Limiter la valeur d'asymétrie entre 0 et 7
    $asymmetryValue = [Math]::Max(0.0, [Math]::Min($asymmetryValue, 7.0))

    # Générer des recommandations basées sur l'asymétrie
    $recommendations = @()

    # Recommandations basées sur l'intensité de l'asymétrie
    $recommendations += "Le ratio des pentes de $([Math]::Round($slopeRatio.SlopeRatio, 2)) indique une asymétrie de niveau '$asymmetryIntensity'."

    # Recommandations basées sur la direction de l'asymétrie
    if ($slopeRatio.AsymmetryDirection -eq "Queue gauche plus pentue") {
        $recommendations += "La queue gauche est plus pentue que la queue droite, ce qui suggère une asymétrie négative."

        if ($asymmetryIntensity -eq "Négligeable" -or $asymmetryIntensity -eq "Très faible") {
            $recommendations += "Cette asymétrie négligeable à très faible n'aura probablement pas d'impact significatif sur les analyses statistiques."
        } elseif ($asymmetryIntensity -eq "Faible") {
            $recommendations += "Cette asymétrie faible peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
        } elseif ($asymmetryIntensity -eq "Modérée") {
            $recommendations += "Cette asymétrie modérée peut affecter les analyses paramétriques. Considérer des transformations (exponentielle, élévation au carré) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Cette asymétrie $($asymmetryIntensity.ToLower()) nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
        }
    } elseif ($slopeRatio.AsymmetryDirection -eq "Queue droite plus pentue") {
        $recommendations += "La queue droite est plus pentue que la queue gauche, ce qui suggère une asymétrie positive."

        if ($asymmetryIntensity -eq "Négligeable" -or $asymmetryIntensity -eq "Très faible") {
            $recommendations += "Cette asymétrie négligeable à très faible n'aura probablement pas d'impact significatif sur les analyses statistiques."
        } elseif ($asymmetryIntensity -eq "Faible") {
            $recommendations += "Cette asymétrie faible peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
        } elseif ($asymmetryIntensity -eq "Modérée") {
            $recommendations += "Cette asymétrie modérée peut affecter les analyses paramétriques. Considérer des transformations (logarithmique, racine carrée) ou des méthodes non paramétriques."
        } else {
            $recommendations += "Cette asymétrie $($asymmetryIntensity.ToLower()) nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
        }
    } else {
        $recommendations += "Les queues ont des pentes similaires, ce qui suggère une distribution approximativement symétrique."
        $recommendations += "Les méthodes statistiques paramétriques peuvent généralement être utilisées."
    }

    # Recommandations basées sur la qualité de la régression
    if ($leftTailRegression.RSquared -lt 0.7 -or $rightTailRegression.RSquared -lt 0.7) {
        $recommendations += "Attention: La qualité de la régression est faible (R² < 0.7), ce qui peut rendre l'évaluation de l'asymétrie moins fiable."
    }

    # Recommandations basées sur la taille d'échantillon
    if ($Data.Count -lt 30) {
        $recommendations += "Attention: La taille d'échantillon est très petite ($($Data.Count) observations), ce qui peut rendre l'évaluation de l'asymétrie moins fiable."
    } elseif ($Data.Count -lt 100) {
        $recommendations += "Note: La taille d'échantillon est petite ($($Data.Count) observations), l'évaluation de l'asymétrie peut être légèrement moins précise."
    }

    # Créer l'objet de résultat
    $result = @{
        Data                = $Data
        SampleSize          = $Data.Count
        TailProportion      = $TailProportion
        TailMethod          = $TailMethod
        RegressionMethod    = $RegressionMethod
        NormalizationMethod = $NormalizationMethod
        Tails               = $tails
        LeftTailRegression  = $leftTailRegression
        RightTailRegression = $rightTailRegression
        SlopeRatio          = $slopeRatio
        AsymmetryIntensity  = $asymmetryIntensity
        AsymmetryValue      = $asymmetryValue
        AsymmetryDirection  = $slopeRatio.AsymmetryDirection
        Recommendations     = $recommendations
    }

    return $result
}

<#
.SYNOPSIS
    Compare différentes méthodes d'évaluation de l'asymétrie d'une distribution.

.DESCRIPTION
    Cette fonction compare différentes méthodes d'évaluation de l'asymétrie d'une distribution
    et fournit une analyse comparative des résultats.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes d'évaluation de l'asymétrie à comparer (par défaut toutes).

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.EXAMPLE
    Compare-AsymmetryMethods -Data $data -Methods @("Density", "Slope")
    Compare les méthodes d'évaluation de l'asymétrie basées sur la densité et les pentes des queues.

.OUTPUTS
    System.Collections.Hashtable
#>
function Compare-AsymmetryMethods {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Density", "Slope", "Moments", "Quantiles", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1
    )

    # Si "All" est spécifié, utiliser toutes les méthodes disponibles
    if ($Methods -contains "All") {
        $Methods = @("Density", "Slope", "Moments", "Quantiles")
    }

    # Initialiser les résultats
    $results = @{
        Data              = $Data
        SampleSize        = $Data.Count
        TailProportion    = $TailProportion
        Methods           = $Methods
        Results           = @{}
        Comparison        = @{}
        ConsistencyScore  = 0.0
        RecommendedMethod = ""
        MethodScores      = @{}
    }

    # Calculer les statistiques de base
    $sortedData = $Data | Sort-Object
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer les moments centraux
    $m2 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    $m4 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 4) } | Measure-Object -Average).Average

    # Calculer le coefficient d'asymétrie (skewness) basé sur les moments
    $skewness = $m3 / [Math]::Pow($m2, 1.5)
    $kurtosis = $m4 / [Math]::Pow($m2, 2) - 3

    # Ajouter les statistiques de base aux résultats
    $results.BasicStats = @{
        Mean     = $mean
        Median   = $median
        StdDev   = $stdDev
        Skewness = $skewness
        Kurtosis = $kurtosis
    }

    # Évaluer l'asymétrie avec chaque méthode spécifiée
    foreach ($method in $Methods) {
        switch ($method) {
            "Density" {
                # Utiliser la méthode basée sur la densité des queues
                # Cette méthode nécessite un module externe DensityRatioAsymmetry.psm1
                try {
                    # Vérifier si le module DensityRatioAsymmetry est disponible
                    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "DensityRatioAsymmetry.psm1"
                    if (Test-Path -Path $modulePath) {
                        # Importer le module
                        Import-Module -Name $modulePath -Force -ErrorAction Stop

                        # Utiliser la fonction Get-DensityRatioAsymmetry
                        $densityAsymmetry = Get-DensityRatioAsymmetry -Data $Data -TailProportion $TailProportion

                        # Ajouter les résultats
                        $results.Results.Density = $densityAsymmetry

                        # Calculer un score normalisé (entre -1 et 1) pour la méthode de densité
                        $densityScore = 0.0
                        if ($densityAsymmetry.AsymmetryDirection -eq "Queue gauche plus dense") {
                            $densityScore = -1 * ($densityAsymmetry.AsymmetryValue / 7.0)
                        } elseif ($densityAsymmetry.AsymmetryDirection -eq "Queue droite plus dense") {
                            $densityScore = $densityAsymmetry.AsymmetryValue / 7.0
                        }

                        $results.MethodScores.Density = $densityScore
                    } else {
                        Write-Warning "Le module DensityRatioAsymmetry.psm1 n'est pas disponible. La méthode de densité ne sera pas utilisée."
                        $results.Results.Density = @{
                            Error = "Module non disponible"
                        }
                        $results.MethodScores.Density = 0.0
                    }
                } catch {
                    Write-Warning "Erreur lors de l'évaluation de l'asymétrie par la méthode de densité: $_"
                    $results.Results.Density = @{
                        Error = $_.Exception.Message
                    }
                    $results.MethodScores.Density = 0.0
                }
            }
            "Slope" {
                # Utiliser la méthode basée sur les pentes des queues
                try {
                    $slopeAsymmetry = Get-TailSlopeAsymmetry -Data $Data -TailProportion $TailProportion
                    $results.Results.Slope = $slopeAsymmetry

                    # Calculer un score normalisé (entre -1 et 1) pour la méthode de pente
                    $slopeScore = 0.0
                    if ($slopeAsymmetry.AsymmetryDirection -eq "Queue gauche plus pentue") {
                        $slopeScore = -1 * ($slopeAsymmetry.AsymmetryValue / 7.0)
                    } elseif ($slopeAsymmetry.AsymmetryDirection -eq "Queue droite plus pentue") {
                        $slopeScore = $slopeAsymmetry.AsymmetryValue / 7.0
                    }

                    $results.MethodScores.Slope = $slopeScore
                } catch {
                    Write-Warning "Erreur lors de l'évaluation de l'asymétrie par la méthode de pente: $_"
                    $results.Results.Slope = @{
                        Error = $_.Exception.Message
                    }
                    $results.MethodScores.Slope = 0.0
                }
            }
            "Moments" {
                # Utiliser la méthode basée sur les moments
                try {
                    # Le coefficient d'asymétrie (skewness) est déjà calculé
                    $momentAsymmetry = @{
                        Skewness           = $skewness
                        Kurtosis           = $kurtosis
                        AsymmetryValue     = [Math]::Abs($skewness)
                        AsymmetryDirection = if ($skewness -lt 0) { "Asymétrie négative" } elseif ($skewness -gt 0) { "Asymétrie positive" } else { "Symétrique" }
                        AsymmetryIntensity = if ([Math]::Abs($skewness) -lt 0.2) {
                            "Négligeable"
                        } elseif ([Math]::Abs($skewness) -lt 0.5) {
                            "Très faible"
                        } elseif ([Math]::Abs($skewness) -lt 1.0) {
                            "Faible"
                        } elseif ([Math]::Abs($skewness) -lt 1.5) {
                            "Modérée"
                        } elseif ([Math]::Abs($skewness) -lt 2.0) {
                            "Forte"
                        } elseif ([Math]::Abs($skewness) -lt 3.0) {
                            "Très forte"
                        } else {
                            "Extrême"
                        }
                    }

                    # Ajouter des recommandations
                    $momentAsymmetry.Recommendations = @()
                    $momentAsymmetry.Recommendations += "Le coefficient d'asymétrie (skewness) de $([Math]::Round($skewness, 2)) indique une asymétrie de niveau '$($momentAsymmetry.AsymmetryIntensity)'."

                    if ($skewness -lt 0) {
                        $momentAsymmetry.Recommendations += "L'asymétrie négative suggère une distribution avec une queue gauche plus longue ou plus lourde."
                    } elseif ($skewness -gt 0) {
                        $momentAsymmetry.Recommendations += "L'asymétrie positive suggère une distribution avec une queue droite plus longue ou plus lourde."
                    } else {
                        $momentAsymmetry.Recommendations += "La distribution semble symétrique selon le coefficient d'asymétrie."
                    }

                    if ([Math]::Abs($skewness) -lt 0.5) {
                        $momentAsymmetry.Recommendations += "Cette asymétrie négligeable à très faible n'aura probablement pas d'impact significatif sur les analyses statistiques."
                    } elseif ([Math]::Abs($skewness) -lt 1.0) {
                        $momentAsymmetry.Recommendations += "Cette asymétrie faible peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
                    } elseif ([Math]::Abs($skewness) -lt 2.0) {
                        $momentAsymmetry.Recommendations += "Cette asymétrie modérée à forte peut affecter les analyses paramétriques. Considérer des transformations ou des méthodes non paramétriques."
                    } else {
                        $momentAsymmetry.Recommendations += "Cette asymétrie très forte à extrême nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
                    }

                    $results.Results.Moments = $momentAsymmetry

                    # Calculer un score normalisé (entre -1 et 1) pour la méthode des moments
                    $momentScore = -1 * $skewness / 3.0  # Normaliser entre -1 et 1 (la plupart des skewness sont entre -3 et 3)
                    if ($momentScore -lt -1) { $momentScore = -1 }
                    if ($momentScore -gt 1) { $momentScore = 1 }

                    $results.MethodScores.Moments = $momentScore
                } catch {
                    Write-Warning "Erreur lors de l'évaluation de l'asymétrie par la méthode des moments: $_"
                    $results.Results.Moments = @{
                        Error = $_.Exception.Message
                    }
                    $results.MethodScores.Moments = 0.0
                }
            }
            "Quantiles" {
                # Utiliser la méthode basée sur les quantiles
                try {
                    # Calculer les quantiles
                    $q1 = Get-Percentile -Data $sortedData -Percentile 25
                    $q2 = $median  # Le médian est déjà calculé
                    $q3 = Get-Percentile -Data $sortedData -Percentile 75

                    # Calculer l'asymétrie basée sur les quantiles (Bowley's coefficient of skewness)
                    $bowleySkewness = (($q3 - $q2) - ($q2 - $q1)) / ($q3 - $q1)

                    $quantileAsymmetry = @{
                        Q1                 = $q1
                        Q2                 = $q2
                        Q3                 = $q3
                        BowleySkewness     = $bowleySkewness
                        AsymmetryValue     = [Math]::Abs($bowleySkewness)
                        AsymmetryDirection = if ($bowleySkewness -lt 0) { "Asymétrie négative" } elseif ($bowleySkewness -gt 0) { "Asymétrie positive" } else { "Symétrique" }
                        AsymmetryIntensity = if ([Math]::Abs($bowleySkewness) -lt 0.05) {
                            "Négligeable"
                        } elseif ([Math]::Abs($bowleySkewness) -lt 0.1) {
                            "Très faible"
                        } elseif ([Math]::Abs($bowleySkewness) -lt 0.2) {
                            "Faible"
                        } elseif ([Math]::Abs($bowleySkewness) -lt 0.3) {
                            "Modérée"
                        } elseif ([Math]::Abs($bowleySkewness) -lt 0.4) {
                            "Forte"
                        } elseif ([Math]::Abs($bowleySkewness) -lt 0.5) {
                            "Très forte"
                        } else {
                            "Extrême"
                        }
                    }

                    # Ajouter des recommandations
                    $quantileAsymmetry.Recommendations = @()
                    $quantileAsymmetry.Recommendations += "Le coefficient d'asymétrie de Bowley de $([Math]::Round($bowleySkewness, 2)) indique une asymétrie de niveau '$($quantileAsymmetry.AsymmetryIntensity)'."

                    if ($bowleySkewness -lt 0) {
                        $quantileAsymmetry.Recommendations += "L'asymétrie négative suggère une distribution avec une queue gauche plus longue ou plus lourde."
                    } elseif ($bowleySkewness -gt 0) {
                        $quantileAsymmetry.Recommendations += "L'asymétrie positive suggère une distribution avec une queue droite plus longue ou plus lourde."
                    } else {
                        $quantileAsymmetry.Recommendations += "La distribution semble symétrique selon le coefficient d'asymétrie de Bowley."
                    }

                    if ([Math]::Abs($bowleySkewness) -lt 0.1) {
                        $quantileAsymmetry.Recommendations += "Cette asymétrie négligeable à très faible n'aura probablement pas d'impact significatif sur les analyses statistiques."
                    } elseif ([Math]::Abs($bowleySkewness) -lt 0.3) {
                        $quantileAsymmetry.Recommendations += "Cette asymétrie faible à modérée peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
                    } else {
                        $quantileAsymmetry.Recommendations += "Cette asymétrie forte à extrême peut affecter les analyses paramétriques. Considérer des transformations ou des méthodes non paramétriques."
                    }

                    $results.Results.Quantiles = $quantileAsymmetry

                    # Calculer un score normalisé (entre -1 et 1) pour la méthode des quantiles
                    $quantileScore = -1 * $bowleySkewness / 0.5  # Normaliser entre -1 et 1 (la plupart des bowleySkewness sont entre -0.5 et 0.5)
                    if ($quantileScore -lt -1) { $quantileScore = -1 }
                    if ($quantileScore -gt 1) { $quantileScore = 1 }

                    $results.MethodScores.Quantiles = $quantileScore
                } catch {
                    Write-Warning "Erreur lors de l'évaluation de l'asymétrie par la méthode des quantiles: $_"
                    $results.Results.Quantiles = @{
                        Error = $_.Exception.Message
                    }
                    $results.MethodScores.Quantiles = 0.0
                }
            }
        }
    }

    # Comparer les résultats des différentes méthodes
    $validMethods = $Methods | Where-Object { $results.Results.$_ -and -not $results.Results.$_.Error }
    $methodCount = $validMethods.Count

    if ($methodCount -gt 1) {
        # Calculer la cohérence entre les méthodes
        $scores = @()
        foreach ($method in $validMethods) {
            $scores += $results.MethodScores.$method
        }

        # Calculer la moyenne des scores
        $meanScore = ($scores | Measure-Object -Average).Average

        # Calculer l'écart-type des scores
        $scoreStdDev = [Math]::Sqrt(($scores | ForEach-Object { [Math]::Pow($_ - $meanScore, 2) } | Measure-Object -Average).Average)

        # Calculer la cohérence (1 - écart-type normalisé)
        $consistencyScore = 1 - ($scoreStdDev / 2.0)  # Normaliser pour que la cohérence soit entre 0 et 1
        if ($consistencyScore -lt 0) { $consistencyScore = 0 }
        if ($consistencyScore -gt 1) { $consistencyScore = 1 }

        $results.ConsistencyScore = $consistencyScore
        $results.MeanScore = $meanScore

        # Déterminer la méthode recommandée
        $recommendedMethod = ""
        $maxReliability = 0.0

        foreach ($method in $validMethods) {
            # Calculer la fiabilité de chaque méthode
            $reliability = 0.0

            switch ($method) {
                "Density" {
                    # La fiabilité dépend de la taille de l'échantillon et de la qualité des queues
                    $reliability = 0.7
                    if ($Data.Count -lt 30) { $reliability *= 0.7 }
                    if ($Data.Count -lt 100) { $reliability *= 0.9 }
                    if ($results.Results.Density.LeftTailSize -lt 5 -or $results.Results.Density.RightTailSize -lt 5) { $reliability *= 0.8 }
                }
                "Slope" {
                    # La fiabilité dépend de la taille de l'échantillon et de la qualité de la régression
                    $reliability = 0.75
                    if ($Data.Count -lt 30) { $reliability *= 0.7 }
                    if ($Data.Count -lt 100) { $reliability *= 0.9 }
                    if ($results.Results.Slope.LeftTailRegression.RSquared -lt 0.7 -or $results.Results.Slope.RightTailRegression.RSquared -lt 0.7) { $reliability *= 0.8 }
                }
                "Moments" {
                    # La fiabilité dépend de la taille de l'échantillon
                    $reliability = 0.8
                    if ($Data.Count -lt 30) { $reliability *= 0.6 }
                    if ($Data.Count -lt 100) { $reliability *= 0.8 }
                }
                "Quantiles" {
                    # La fiabilité dépend de la taille de l'échantillon
                    $reliability = 0.85
                    if ($Data.Count -lt 30) { $reliability *= 0.7 }
                    if ($Data.Count -lt 100) { $reliability *= 0.9 }
                }
            }

            # Ajuster la fiabilité en fonction de la cohérence avec les autres méthodes
            $methodScore = $results.MethodScores.$method
            $scoreDeviation = [Math]::Abs($methodScore - $meanScore)
            $consistencyFactor = 1 - ($scoreDeviation / 2.0)
            if ($consistencyFactor -lt 0) { $consistencyFactor = 0 }
            if ($consistencyFactor -gt 1) { $consistencyFactor = 1 }

            $reliability *= (0.7 + 0.3 * $consistencyFactor)

            # Stocker la fiabilité
            $results.Comparison.$method = @{
                Score             = $methodScore
                Reliability       = $reliability
                ConsistencyFactor = $consistencyFactor
            }

            # Mettre à jour la méthode recommandée si nécessaire
            if ($reliability -gt $maxReliability) {
                $maxReliability = $reliability
                $recommendedMethod = $method
            }
        }

        $results.RecommendedMethod = $recommendedMethod
    } elseif ($methodCount -eq 1) {
        # S'il n'y a qu'une seule méthode, c'est la méthode recommandée
        $results.RecommendedMethod = $validMethods[0]
        $results.ConsistencyScore = 1.0
        $results.MeanScore = $results.MethodScores.($validMethods[0])
    } else {
        # Aucune méthode valide
        $results.RecommendedMethod = "Aucune"
        $results.ConsistencyScore = 0.0
        $results.MeanScore = 0.0
    }

    # Générer des recommandations globales
    $results.Recommendations = @()

    if ($methodCount -gt 0) {
        # Recommandation basée sur la méthode recommandée
        if ($results.RecommendedMethod -ne "Aucune") {
            $recommendedScore = $results.MethodScores.($results.RecommendedMethod)
            $asymmetryDirection = if ($recommendedScore -lt 0) { "négative" } elseif ($recommendedScore -gt 0) { "positive" } else { "symétrique" }
            $asymmetryIntensity = if ([Math]::Abs($recommendedScore) -lt 0.2) {
                "négligeable"
            } elseif ([Math]::Abs($recommendedScore) -lt 0.4) {
                "faible"
            } elseif ([Math]::Abs($recommendedScore) -lt 0.6) {
                "modérée"
            } elseif ([Math]::Abs($recommendedScore) -lt 0.8) {
                "forte"
            } else {
                "extrême"
            }

            $results.Recommendations += "Selon la méthode $($results.RecommendedMethod), la distribution présente une asymétrie $asymmetryDirection $asymmetryIntensity."
        }

        # Recommandation basée sur la cohérence entre les méthodes
        if ($methodCount -gt 1) {
            if ($results.ConsistencyScore -gt 0.9) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie sont très cohérentes entre elles, ce qui renforce la confiance dans les résultats."
            } elseif ($results.ConsistencyScore -gt 0.7) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie sont relativement cohérentes entre elles."
            } elseif ($results.ConsistencyScore -gt 0.5) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie montrent une cohérence modérée. Considérer la méthode recommandée comme la plus fiable."
            } else {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie montrent peu de cohérence entre elles. Les résultats doivent être interprétés avec prudence."
            }
        }

        # Recommandation basée sur la taille de l'échantillon
        if ($Data.Count -lt 30) {
            $results.Recommendations += "Attention: La taille d'échantillon est très petite ($($Data.Count) observations), ce qui peut rendre l'évaluation de l'asymétrie moins fiable."
        } elseif ($Data.Count -lt 100) {
            $results.Recommendations += "Note: La taille d'échantillon est petite ($($Data.Count) observations), l'évaluation de l'asymétrie peut être légèrement moins précise."
        }

        # Recommandation basée sur l'intensité de l'asymétrie
        if ([Math]::Abs($results.MeanScore) -lt 0.2) {
            $results.Recommendations += "L'asymétrie détectée est négligeable et n'aura probablement pas d'impact significatif sur les analyses statistiques."
        } elseif ([Math]::Abs($results.MeanScore) -lt 0.4) {
            $results.Recommendations += "L'asymétrie détectée est faible et peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
        } elseif ([Math]::Abs($results.MeanScore) -lt 0.6) {
            $results.Recommendations += "L'asymétrie détectée est modérée et peut affecter les analyses paramétriques. Considérer des transformations ou des méthodes non paramétriques."
        } elseif ([Math]::Abs($results.MeanScore) -lt 0.8) {
            $results.Recommendations += "L'asymétrie détectée est forte et nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
        } else {
            $results.Recommendations += "L'asymétrie détectée est extrême et nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
        }

        # Recommandation de transformation si nécessaire
        if ($results.MeanScore -gt 0.4) {
            $results.Recommendations += "Pour corriger l'asymétrie positive, considérer une transformation logarithmique, racine carrée ou inverse."
        } elseif ($results.MeanScore -lt -0.4) {
            $results.Recommendations += "Pour corriger l'asymétrie négative, considérer une transformation exponentielle, élévation au carré ou Box-Cox."
        }
    } else {
        $results.Recommendations += "Aucune méthode d'évaluation de l'asymétrie n'a pu être appliquée avec succès."
    }

    return $results
}

<#
.SYNOPSIS
    Calcule un score composite d'asymétrie basé sur plusieurs méthodes.

.DESCRIPTION
    Cette fonction calcule un score composite d'asymétrie en combinant les résultats
    de plusieurs méthodes d'évaluation de l'asymétrie, pondérés par leur fiabilité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes d'évaluation de l'asymétrie à utiliser (par défaut toutes).

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER Weights
    Les poids à attribuer à chaque méthode (par défaut, poids égaux).

.EXAMPLE
    Get-CompositeAsymmetryScore -Data $data -Methods @("Density", "Slope", "Moments")
    Calcule un score composite d'asymétrie en utilisant les méthodes spécifiées.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-CompositeAsymmetryScore {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Density", "Slope", "Moments", "Quantiles", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1,

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{}
    )

    # Comparer les méthodes d'évaluation de l'asymétrie
    $comparison = Compare-AsymmetryMethods -Data $Data -Methods $Methods -TailProportion $TailProportion

    # Initialiser les résultats
    $results = @{
        Data               = $Data
        SampleSize         = $Data.Count
        TailProportion     = $TailProportion
        Methods            = $comparison.Methods
        MethodScores       = $comparison.MethodScores
        MethodWeights      = @{}
        CompositeScore     = 0.0
        AsymmetryDirection = ""
        AsymmetryIntensity = ""
        Recommendations    = @()
    }

    # Récupérer les méthodes valides
    $validMethods = $comparison.Methods | Where-Object { $comparison.Results.$_ -and -not $comparison.Results.$_.Error }
    $methodCount = $validMethods.Count

    if ($methodCount -gt 0) {
        # Déterminer les poids pour chaque méthode
        $totalWeight = 0.0

        foreach ($method in $validMethods) {
            # Utiliser les poids spécifiés ou calculer des poids basés sur la fiabilité
            $weight = 0.0

            if ($Weights.ContainsKey($method)) {
                $weight = $Weights[$method]
            } elseif ($comparison.Comparison.ContainsKey($method)) {
                $weight = $comparison.Comparison.$method.Reliability
            } else {
                # Poids par défaut si la fiabilité n'est pas disponible
                switch ($method) {
                    "Density" { $weight = 0.7 }
                    "Slope" { $weight = 0.75 }
                    "Moments" { $weight = 0.8 }
                    "Quantiles" { $weight = 0.85 }
                    default { $weight = 0.7 }
                }
            }

            $results.MethodWeights[$method] = $weight
            $totalWeight += $weight
        }

        # Normaliser les poids
        if ($totalWeight -gt 0) {
            foreach ($method in $validMethods) {
                $results.MethodWeights[$method] = $results.MethodWeights[$method] / $totalWeight
            }
        }

        # Calculer le score composite
        $compositeScore = 0.0

        foreach ($method in $validMethods) {
            $methodScore = $comparison.MethodScores.$method
            $methodWeight = $results.MethodWeights[$method]
            $compositeScore += $methodScore * $methodWeight
        }

        $results.CompositeScore = $compositeScore

        # Déterminer la direction de l'asymétrie
        if ($compositeScore -lt -0.05) {
            $results.AsymmetryDirection = "Asymétrie négative"
        } elseif ($compositeScore -gt 0.05) {
            $results.AsymmetryDirection = "Asymétrie positive"
        } else {
            $results.AsymmetryDirection = "Symétrique"
        }

        # Déterminer l'intensité de l'asymétrie
        $absScore = [Math]::Abs($compositeScore)
        if ($absScore -lt 0.2) {
            $results.AsymmetryIntensity = "Négligeable"
        } elseif ($absScore -lt 0.4) {
            $results.AsymmetryIntensity = "Faible"
        } elseif ($absScore -lt 0.6) {
            $results.AsymmetryIntensity = "Modérée"
        } elseif ($absScore -lt 0.8) {
            $results.AsymmetryIntensity = "Forte"
        } else {
            $results.AsymmetryIntensity = "Extrême"
        }

        # Générer des recommandations
        $results.Recommendations += "Le score composite d'asymétrie de $([Math]::Round($compositeScore, 2)) indique une distribution $($results.AsymmetryDirection.ToLower()) avec une asymétrie de niveau '$($results.AsymmetryIntensity.ToLower())'."

        # Ajouter des recommandations spécifiques en fonction de l'intensité et de la direction
        if ($absScore -lt 0.2) {
            $results.Recommendations += "Cette asymétrie négligeable n'aura probablement pas d'impact significatif sur les analyses statistiques."
        } elseif ($absScore -lt 0.4) {
            $results.Recommendations += "Cette asymétrie faible peut avoir un léger impact sur les analyses paramétriques. Considérer des tests de normalité."
        } elseif ($absScore -lt 0.6) {
            $results.Recommendations += "Cette asymétrie modérée peut affecter les analyses paramétriques. Considérer des transformations ou des méthodes non paramétriques."
        } else {
            $results.Recommendations += "Cette asymétrie $($results.AsymmetryIntensity.ToLower()) nécessite l'utilisation de méthodes non paramétriques ou des transformations appropriées."
        }

        # Recommandation de transformation si nécessaire
        if ($compositeScore -gt 0.4) {
            $results.Recommendations += "Pour corriger l'asymétrie positive, considérer une transformation logarithmique, racine carrée ou inverse."
        } elseif ($compositeScore -lt -0.4) {
            $results.Recommendations += "Pour corriger l'asymétrie négative, considérer une transformation exponentielle, élévation au carré ou Box-Cox."
        }

        # Ajouter des informations sur les méthodes utilisées
        $methodsInfo = "Ce score composite est basé sur les méthodes suivantes: "
        $methodInfos = @()
        foreach ($method in $validMethods) {
            $methodInfos += "$method (poids: $([Math]::Round($results.MethodWeights[$method], 2)))"
        }
        $results.Recommendations += $methodsInfo + ($methodInfos -join ", ") + "."

        # Ajouter des informations sur la cohérence entre les méthodes
        if ($methodCount -gt 1) {
            if ($comparison.ConsistencyScore -gt 0.9) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie sont très cohérentes entre elles (score de cohérence: $([Math]::Round($comparison.ConsistencyScore, 2))), ce qui renforce la confiance dans le score composite."
            } elseif ($comparison.ConsistencyScore -gt 0.7) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie sont relativement cohérentes entre elles (score de cohérence: $([Math]::Round($comparison.ConsistencyScore, 2)))."
            } elseif ($comparison.ConsistencyScore -gt 0.5) {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie montrent une cohérence modérée (score de cohérence: $([Math]::Round($comparison.ConsistencyScore, 2))). Le score composite doit être interprété avec une certaine prudence."
            } else {
                $results.Recommendations += "Les différentes méthodes d'évaluation de l'asymétrie montrent peu de cohérence entre elles (score de cohérence: $([Math]::Round($comparison.ConsistencyScore, 2))). Le score composite doit être interprété avec prudence."
            }
        }
    } else {
        # Aucune méthode valide
        $results.CompositeScore = 0.0
        $results.AsymmetryDirection = "Indéterminée"
        $results.AsymmetryIntensity = "Indéterminée"
        $results.Recommendations += "Aucune méthode d'évaluation de l'asymétrie n'a pu être appliquée avec succès."
    }

    return $results
}

<#
.SYNOPSIS
    Détermine automatiquement la meilleure méthode d'évaluation de l'asymétrie pour une distribution.

.DESCRIPTION
    Cette fonction analyse les caractéristiques de la distribution et détermine
    automatiquement la méthode d'évaluation de l'asymétrie la plus appropriée.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.EXAMPLE
    Get-OptimalAsymmetryMethod -Data $data
    Détermine la méthode d'évaluation de l'asymétrie la plus appropriée pour la distribution.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-OptimalAsymmetryMethod {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1
    )

    # Initialiser les résultats
    $results = @{
        Data                        = $Data
        SampleSize                  = $Data.Count
        TailProportion              = $TailProportion
        OptimalMethod               = ""
        RecommendedMethods          = @()
        Justification               = @()
        DistributionCharacteristics = @{}
    }

    # Calculer les statistiques de base
    $sortedData = $Data | Sort-Object
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

    # Calculer les moments centraux
    $m2 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    $m4 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 4) } | Measure-Object -Average).Average

    # Calculer le coefficient d'asymétrie (skewness) et le kurtosis
    $skewness = $m3 / [Math]::Pow($m2, 1.5)
    $kurtosis = $m4 / [Math]::Pow($m2, 2) - 3

    # Calculer les quantiles
    $q1 = Get-Percentile -Data $sortedData -Percentile 25
    $q3 = Get-Percentile -Data $sortedData -Percentile 75
    $iqr = $q3 - $q1

    # Calculer le coefficient d'asymétrie de Bowley
    $bowleySkewness = (($q3 - $median) - ($median - $q1)) / ($q3 - $q1)

    # Stocker les caractéristiques de la distribution
    $results.DistributionCharacteristics = @{
        Mean           = $mean
        Median         = $median
        StdDev         = $stdDev
        Skewness       = $skewness
        Kurtosis       = $kurtosis
        Q1             = $q1
        Q3             = $q3
        IQR            = $iqr
        BowleySkewness = $bowleySkewness
    }

    # Évaluer les caractéristiques de la distribution pour déterminer la méthode optimale
    $methodScores = @{
        "Moments"   = 0.0
        "Quantiles" = 0.0
        "Slope"     = 0.0
        "Density"   = 0.0
    }

    # Taille de l'échantillon
    if ($Data.Count -lt 30) {
        # Échantillon très petit
        $methodScores["Quantiles"] += 0.3
        $methodScores["Moments"] -= 0.2
        $methodScores["Slope"] -= 0.1
        $methodScores["Density"] -= 0.1
        $results.Justification += "La taille d'échantillon est très petite ($($Data.Count) observations), ce qui favorise les méthodes basées sur les quantiles."
    } elseif ($Data.Count -lt 100) {
        # Échantillon petit
        $methodScores["Quantiles"] += 0.2
        $methodScores["Moments"] += 0.1
        $results.Justification += "La taille d'échantillon est petite ($($Data.Count) observations), ce qui favorise légèrement les méthodes basées sur les quantiles."
    } else {
        # Échantillon grand
        $methodScores["Moments"] += 0.2
        $methodScores["Slope"] += 0.2
        $methodScores["Density"] += 0.2
        $results.Justification += "La taille d'échantillon est grande ($($Data.Count) observations), ce qui favorise les méthodes basées sur les moments, les pentes et la densité."
    }

    # Présence de valeurs extrêmes
    $lowerBound = $q1 - 1.5 * $iqr
    $upperBound = $q3 + 1.5 * $iqr
    $outliers = $sortedData | Where-Object { $_ -lt $lowerBound -or $_ -gt $upperBound }
    $outlierCount = $outliers.Count

    if ($outlierCount -gt 0) {
        $outlierProportion = $outlierCount / $Data.Count
        if ($outlierProportion -gt 0.05) {
            # Beaucoup de valeurs extrêmes
            $methodScores["Quantiles"] += 0.3
            $methodScores["Moments"] -= 0.3
            $results.Justification += "La distribution contient beaucoup de valeurs extrêmes ($outlierCount, soit $([Math]::Round($outlierProportion * 100, 1))% des observations), ce qui favorise les méthodes basées sur les quantiles et pénalise les méthodes basées sur les moments."
        } else {
            # Quelques valeurs extrêmes
            $methodScores["Quantiles"] += 0.2
            $methodScores["Moments"] -= 0.1
            $results.Justification += "La distribution contient quelques valeurs extrêmes ($outlierCount, soit $([Math]::Round($outlierProportion * 100, 1))% des observations), ce qui favorise légèrement les méthodes basées sur les quantiles."
        }
    }

    # Kurtosis
    if ([Math]::Abs($kurtosis) -gt 3) {
        # Distribution à queues lourdes ou légères
        $methodScores["Slope"] += 0.2
        $methodScores["Density"] += 0.2
        $results.Justification += "La distribution a un kurtosis élevé ($([Math]::Round($kurtosis, 2))), ce qui favorise les méthodes basées sur les pentes et la densité des queues."
    }

    # Asymétrie
    if ([Math]::Abs($skewness) -gt 1) {
        # Asymétrie forte
        $methodScores["Slope"] += 0.2
        $methodScores["Density"] += 0.2
        $results.Justification += "La distribution présente une forte asymétrie (skewness = $([Math]::Round($skewness, 2))), ce qui favorise les méthodes basées sur les pentes et la densité des queues."
    }

    # Déterminer la méthode optimale
    $optimalMethod = $methodScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1 -ExpandProperty Key
    $results.OptimalMethod = $optimalMethod

    # Déterminer les méthodes recommandées (score > 0)
    $recommendedMethods = $methodScores.GetEnumerator() | Where-Object { $_.Value -gt 0 } | Sort-Object -Property Value -Descending | Select-Object -ExpandProperty Key
    $results.RecommendedMethods = $recommendedMethods

    # Ajouter des justifications supplémentaires
    $results.Justification += "La méthode optimale pour cette distribution est '$optimalMethod' avec un score de $([Math]::Round($methodScores[$optimalMethod], 2))."

    if ($recommendedMethods.Count -gt 1) {
        $otherMethods = $recommendedMethods | Where-Object { $_ -ne $optimalMethod }
        $results.Justification += "Les autres méthodes recommandées sont: $($otherMethods -join ", ")."
    }

    # Ajouter des recommandations pour l'utilisation
    $results.Recommendations = @()
    $results.Recommendations += "Pour cette distribution, il est recommandé d'utiliser la méthode '$optimalMethod' pour évaluer l'asymétrie."

    if ($recommendedMethods.Count -gt 1) {
        $results.Recommendations += "Pour une analyse plus complète, considérer également l'utilisation d'un score composite basé sur les méthodes suivantes: $($recommendedMethods -join ", ")."
    }

    if ($Data.Count -lt 30) {
        $results.Recommendations += "Attention: La taille d'échantillon est très petite, les résultats doivent être interprétés avec prudence."
    }

    return $results
}

<#
.SYNOPSIS
    Génère un rapport textuel détaillé sur l'asymétrie d'une distribution.

.DESCRIPTION
    Cette fonction génère un rapport textuel détaillé sur l'asymétrie d'une distribution,
    en utilisant différentes méthodes d'évaluation et en fournissant des recommandations.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes d'évaluation de l'asymétrie à utiliser (par défaut toutes).

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER DetailLevel
    Le niveau de détail du rapport (par défaut "Normal").

.PARAMETER OutputPath
    Le chemin du fichier de sortie (optionnel). Si non spécifié, le rapport est retourné sous forme de chaîne.

.EXAMPLE
    Get-AsymmetryTextReport -Data $data -Methods @("Slope", "Moments") -DetailLevel "Detailed"
    Génère un rapport textuel détaillé sur l'asymétrie de la distribution.

.OUTPUTS
    System.String
#>
function Get-AsymmetryTextReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Density", "Slope", "Moments", "Quantiles", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Verbose")]
        [string]$DetailLevel = "Normal",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    # Initialiser le rapport
    $report = @()
    $report += "=== RAPPORT D'ANALYSE D'ASYMÉTRIE ==="
    $report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Taille d'échantillon: $($Data.Count) observations"
    $report += ""

    # Calculer les statistiques de base
    $sortedData = $Data | Sort-Object
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
    $min = $sortedData[0]
    $max = $sortedData[-1]
    $range = $max - $min

    # Calculer les quantiles
    $q1 = Get-Percentile -Data $sortedData -Percentile 25
    $q3 = Get-Percentile -Data $sortedData -Percentile 75
    $iqr = $q3 - $q1

    # Calculer les moments centraux
    $m2 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    $m4 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 4) } | Measure-Object -Average).Average

    # Calculer le coefficient d'asymétrie (skewness) et le kurtosis
    $skewness = $m3 / [Math]::Pow($m2, 1.5)
    $kurtosis = $m4 / [Math]::Pow($m2, 2) - 3

    # Ajouter les statistiques descriptives au rapport
    $report += "=== STATISTIQUES DESCRIPTIVES ==="
    $report += "Minimum: $([Math]::Round($min, 4))"
    $report += "Maximum: $([Math]::Round($max, 4))"
    $report += "Étendue: $([Math]::Round($range, 4))"
    $report += "Moyenne: $([Math]::Round($mean, 4))"
    $report += "Médiane: $([Math]::Round($median, 4))"
    $report += "Écart-type: $([Math]::Round($stdDev, 4))"
    $report += "Q1 (25%): $([Math]::Round($q1, 4))"
    $report += "Q3 (75%): $([Math]::Round($q3, 4))"
    $report += "IQR: $([Math]::Round($iqr, 4))"
    $report += "Coefficient d'asymétrie (skewness): $([Math]::Round($skewness, 4))"
    $report += "Kurtosis: $([Math]::Round($kurtosis, 4))"
    $report += ""

    # Déterminer la méthode optimale
    $optimalMethod = Get-OptimalAsymmetryMethod -Data $Data -TailProportion $TailProportion

    $report += "=== MÉTHODE OPTIMALE ==="
    $report += "Méthode recommandée: $($optimalMethod.OptimalMethod)"
    if ($optimalMethod.RecommendedMethods.Count -gt 1) {
        $report += "Autres méthodes recommandées: $($optimalMethod.RecommendedMethods | Where-Object { $_ -ne $optimalMethod.OptimalMethod } | ForEach-Object { $_ }) "
    }
    $report += ""

    if ($DetailLevel -eq "Detailed" -or $DetailLevel -eq "Verbose") {
        $report += "Justification:"
        foreach ($justification in $optimalMethod.Justification) {
            $report += "- $justification"
        }
        $report += ""
    }

    # Comparer les méthodes d'évaluation de l'asymétrie
    $comparison = Compare-AsymmetryMethods -Data $Data -Methods $Methods -TailProportion $TailProportion

    $report += "=== COMPARAISON DES MÉTHODES ==="
    $report += "Méthodes utilisées: $($comparison.Methods -join ", ")"
    $report += "Méthode recommandée: $($comparison.RecommendedMethod)"
    $report += "Score de cohérence: $([Math]::Round($comparison.ConsistencyScore, 4))"
    $report += ""

    $report += "Scores par méthode:"
    foreach ($method in $comparison.Methods) {
        if ($comparison.MethodScores.ContainsKey($method)) {
            $score = [Math]::Round($comparison.MethodScores[$method], 4)
            $report += "- $method : $score"
        }
    }
    $report += ""

    if ($DetailLevel -eq "Detailed" -or $DetailLevel -eq "Verbose") {
        $report += "Fiabilité par méthode:"
        foreach ($method in $comparison.Methods) {
            if ($comparison.Comparison.ContainsKey($method)) {
                $reliability = [Math]::Round($comparison.Comparison[$method].Reliability, 4)
                $report += "- $method : $reliability"
            }
        }
        $report += ""
    }

    # Calculer le score composite
    $compositeScore = Get-CompositeAsymmetryScore -Data $Data -Methods $Methods -TailProportion $TailProportion

    $report += "=== SCORE COMPOSITE ==="
    $report += "Score composite: $([Math]::Round($compositeScore.CompositeScore, 4))"
    $report += "Direction de l'asymétrie: $($compositeScore.AsymmetryDirection)"
    $report += "Intensité de l'asymétrie: $($compositeScore.AsymmetryIntensity)"
    $report += ""

    if ($DetailLevel -eq "Detailed" -or $DetailLevel -eq "Verbose") {
        $report += "Poids par méthode:"
        foreach ($method in $compositeScore.Methods) {
            if ($compositeScore.MethodWeights.ContainsKey($method)) {
                $weight = [Math]::Round($compositeScore.MethodWeights[$method], 4)
                $report += "- $method : $weight"
            }
        }
        $report += ""
    }

    # Ajouter les détails spécifiques à chaque méthode
    if ($DetailLevel -eq "Detailed" -or $DetailLevel -eq "Verbose") {
        foreach ($method in $comparison.Methods) {
            if ($comparison.Results.ContainsKey($method) -and -not $comparison.Results[$method].Error) {
                $report += "=== DÉTAILS DE LA MÉTHODE $method ==="

                switch ($method) {
                    "Slope" {
                        $slopeResult = $comparison.Results.Slope
                        $report += "Ratio des pentes: $([Math]::Round($slopeResult.SlopeRatio.SlopeRatio, 4))"
                        $report += "Direction de l'asymétrie: $($slopeResult.AsymmetryDirection)"
                        $report += "Intensité de l'asymétrie: $($slopeResult.AsymmetryIntensity)"

                        if ($DetailLevel -eq "Verbose") {
                            $report += "Pente de la queue gauche: $([Math]::Round($slopeResult.SlopeRatio.LeftSlope, 4))"
                            $report += "Pente de la queue droite: $([Math]::Round($slopeResult.SlopeRatio.RightSlope, 4))"
                            $report += "R² de la queue gauche: $([Math]::Round($slopeResult.LeftTailRegression.RSquared, 4))"
                            $report += "R² de la queue droite: $([Math]::Round($slopeResult.RightTailRegression.RSquared, 4))"
                        }
                    }
                    "Moments" {
                        $momentResult = $comparison.Results.Moments
                        $report += "Coefficient d'asymétrie (skewness): $([Math]::Round($momentResult.Skewness, 4))"
                        $report += "Kurtosis: $([Math]::Round($momentResult.Kurtosis, 4))"
                        $report += "Direction de l'asymétrie: $($momentResult.AsymmetryDirection)"
                        $report += "Intensité de l'asymétrie: $($momentResult.AsymmetryIntensity)"
                    }
                    "Quantiles" {
                        $quantileResult = $comparison.Results.Quantiles
                        $report += "Coefficient d'asymétrie de Bowley: $([Math]::Round($quantileResult.BowleySkewness, 4))"
                        $report += "Direction de l'asymétrie: $($quantileResult.AsymmetryDirection)"
                        $report += "Intensité de l'asymétrie: $($quantileResult.AsymmetryIntensity)"

                        if ($DetailLevel -eq "Verbose") {
                            $report += "Q1: $([Math]::Round($quantileResult.Q1, 4))"
                            $report += "Q2 (médiane): $([Math]::Round($quantileResult.Q2, 4))"
                            $report += "Q3: $([Math]::Round($quantileResult.Q3, 4))"
                        }
                    }
                    "Density" {
                        if ($comparison.Results.ContainsKey("Density")) {
                            $densityResult = $comparison.Results.Density
                            if (-not $densityResult.Error) {
                                $report += "Ratio de densité: $([Math]::Round($densityResult.DensityRatio, 4))"
                                $report += "Direction de l'asymétrie: $($densityResult.AsymmetryDirection)"
                                $report += "Intensité de l'asymétrie: $($densityResult.AsymmetryIntensity)"

                                if ($DetailLevel -eq "Verbose") {
                                    $report += "Densité de la queue gauche: $([Math]::Round($densityResult.LeftTailDensity, 4))"
                                    $report += "Densité de la queue droite: $([Math]::Round($densityResult.RightTailDensity, 4))"
                                }
                            } else {
                                $report += "Erreur: $($densityResult.Error)"
                            }
                        } else {
                            $report += "Méthode non disponible."
                        }
                    }
                }

                $report += ""
            }
        }
    }

    # Ajouter les recommandations
    $report += "=== RECOMMANDATIONS ==="
    foreach ($recommendation in $compositeScore.Recommendations) {
        $report += "- $recommendation"
    }
    $report += ""

    # Ajouter des informations sur la distribution des données
    if ($DetailLevel -eq "Verbose") {
        $report += "=== DISTRIBUTION DES DONNÉES ==="
        $report += "Histogramme (10 classes):"

        # Créer un histogramme simple
        $min = $sortedData[0]
        $max = $sortedData[-1]
        $range = $max - $min
        $binWidth = $range / 10
        $bins = @(0) * 10

        foreach ($value in $sortedData) {
            $binIndex = [Math]::Min(9, [Math]::Floor(($value - $min) / $binWidth))
            $bins[$binIndex]++
        }

        $maxBinCount = ($bins | Measure-Object -Maximum).Maximum
        $scale = [Math]::Min(50, $maxBinCount)

        for ($i = 0; $i -lt 10; $i++) {
            $lowerBound = $min + $i * $binWidth
            $upperBound = $min + ($i + 1) * $binWidth
            $count = $bins[$i]
            $barLength = [Math]::Round($count / $maxBinCount * $scale)
            $bar = "#" * $barLength
            $report += "[$([Math]::Round($lowerBound, 2)), $([Math]::Round($upperBound, 2))): $bar ($count)"
        }

        $report += ""
    }

    # Ajouter un pied de page
    $report += "=== FIN DU RAPPORT ==="
    $report += "Généré par le module TailSlopeAsymmetry"
    $report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Joindre les lignes du rapport
    $reportText = $report -join [Environment]::NewLine

    # Écrire le rapport dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $reportText | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport écrit dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture du rapport dans le fichier: $_"
        }
    }

    return $reportText
}

<#
.SYNOPSIS
    Génère un rapport HTML sur l'asymétrie d'une distribution avec visualisations.

.DESCRIPTION
    Cette fonction génère un rapport HTML interactif sur l'asymétrie d'une distribution,
    incluant des visualisations et des graphiques interactifs.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes d'évaluation de l'asymétrie à utiliser (par défaut toutes).

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER Title
    Le titre du rapport (par défaut "Rapport d'analyse d'asymétrie").

.PARAMETER OutputPath
    Le chemin du fichier de sortie (optionnel). Si non spécifié, le rapport est retourné sous forme de chaîne HTML.

.EXAMPLE
    Get-AsymmetryHtmlReport -Data $data -Methods @("Slope", "Moments") -OutputPath "rapport.html"
    Génère un rapport HTML interactif sur l'asymétrie de la distribution et l'enregistre dans le fichier "rapport.html".

.OUTPUTS
    System.String
#>
function Get-AsymmetryHtmlReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Density", "Slope", "Moments", "Quantiles", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'analyse d'asymétrie",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Positive", "Negative", "Symmetric", "Negligible", "VeryWeak", "Weak", "Moderate", "Strong", "VeryStrong", "Extreme")]
        [string]$Filter = "All"
    )

    # Charger le template HTML
    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath "templates\AsymmetryReportTemplate.html"
    if (-not (Test-Path -Path $templatePath)) {
        Write-Error "Le fichier template HTML n'a pas été trouvé: $templatePath"
        return $null
    }
    $template = Get-Content -Path $templatePath -Raw -Encoding UTF8

    # Obtenir les résultats d'analyse
    $comparison = Compare-AsymmetryMethods -Data $Data -Methods $Methods -TailProportion $TailProportion
    $compositeScore = Get-CompositeAsymmetryScore -Data $Data -Methods $Methods -TailProportion $TailProportion

    # Appliquer le filtre si nécessaire
    $filteredResults = @{}
    $filteredMethodScores = @{}
    $filteredMethods = @()

    # Déterminer si le filtre est basé sur la direction ou l'intensité
    $directionFilters = @("Positive", "Negative", "Symmetric")
    $intensityFilters = @("Negligible", "VeryWeak", "Weak", "Moderate", "Strong", "VeryStrong", "Extreme")

    $isDirectionFilter = $directionFilters -contains $Filter
    $isIntensityFilter = $intensityFilters -contains $Filter

    if ($Filter -ne "All") {
        foreach ($method in $comparison.Methods) {
            if ($comparison.Results.ContainsKey($method) -and -not $comparison.Results[$method].Error) {
                $result = $comparison.Results[$method]
                $includeMethod = $false

                if ($isDirectionFilter) {
                    # Filtrer par direction d'asymétrie
                    switch ($Filter) {
                        "Positive" { $includeMethod = $result.AsymmetryDirection -eq "Positive" -or $result.AsymmetryDirection -eq "Queue droite plus longue" }
                        "Negative" { $includeMethod = $result.AsymmetryDirection -eq "Negative" -or $result.AsymmetryDirection -eq "Queue gauche plus longue" }
                        "Symmetric" { $includeMethod = $result.AsymmetryDirection -eq "Symmetric" -or $result.AsymmetryDirection -eq "Symétrique" }
                    }
                } elseif ($isIntensityFilter) {
                    # Filtrer par intensité d'asymétrie
                    $includeMethod = $result.AsymmetryIntensity -eq $Filter
                }

                if ($includeMethod) {
                    $filteredResults[$method] = $result
                    $filteredMethodScores[$method] = $comparison.MethodScores[$method]
                    $filteredMethods += $method
                }
            }
        }

        # Si aucune méthode ne correspond au filtre, utiliser toutes les méthodes
        if ($filteredMethods.Count -eq 0) {
            $filteredResults = $comparison.Results
            $filteredMethodScores = $comparison.MethodScores
            $filteredMethods = $comparison.Methods
        } else {
            # Mettre à jour les résultats de comparaison avec les méthodes filtrées
            $comparison = @{
                Results           = $filteredResults
                MethodScores      = $filteredMethodScores
                Methods           = $filteredMethods
                RecommendedMethod = $comparison.RecommendedMethod
                ConsistencyScore  = $comparison.ConsistencyScore
            }
        }
    }

    # Calculer les statistiques descriptives
    $sortedData = $Data | Sort-Object
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
    $min = $sortedData[0]
    $max = $sortedData[-1]
    $range = $max - $min

    # Calculer les quantiles
    $q1 = Get-Percentile -Data $sortedData -Percentile 25
    $q3 = Get-Percentile -Data $sortedData -Percentile 75
    $iqr = $q3 - $q1

    # Calculer les moments centraux
    $m2 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    $m4 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 4) } | Measure-Object -Average).Average

    # Calculer le coefficient d'asymétrie (skewness) et le kurtosis
    $skewness = $m3 / [Math]::Pow($m2, 1.5)
    $kurtosis = $m4 / [Math]::Pow($m2, 2) - 3

    # Préparer les données pour le template
    $now = Get-Date
    $dateStr = $now.ToString("yyyy-MM-dd HH:mm:ss")

    # Déterminer la classe de badge pour l'intensité de l'asymétrie
    $intensityClass = switch ($compositeScore.AsymmetryIntensity) {
        "Négligeable" { "info" }
        "Très faible" { "info" }
        "Faible" { "success" }
        "Modérée" { "warning" }
        "Forte" { "warning" }
        "Très forte" { "danger" }
        "Extrême" { "danger" }
        default { "secondary" }
    }

    # Préparer les lignes du tableau des statistiques
    $statisticsRows = @()
    $statisticsRows += "<tr><td>Minimum</td><td>$([Math]::Round($min, 4))</td></tr>"
    $statisticsRows += "<tr><td>Maximum</td><td>$([Math]::Round($max, 4))</td></tr>"
    $statisticsRows += "<tr><td>Étendue</td><td>$([Math]::Round($range, 4))</td></tr>"
    $statisticsRows += "<tr><td>Moyenne</td><td>$([Math]::Round($mean, 4))</td></tr>"
    $statisticsRows += "<tr><td>Médiane</td><td>$([Math]::Round($median, 4))</td></tr>"
    $statisticsRows += "<tr><td>Écart-type</td><td>$([Math]::Round($stdDev, 4))</td></tr>"
    $statisticsRows += "<tr><td>Q1 (25%)</td><td>$([Math]::Round($q1, 4))</td></tr>"
    $statisticsRows += "<tr><td>Q3 (75%)</td><td>$([Math]::Round($q3, 4))</td></tr>"
    $statisticsRows += "<tr><td>IQR</td><td>$([Math]::Round($iqr, 4))</td></tr>"
    $statisticsRows += "<tr><td>Coefficient d'asymétrie (skewness)</td><td>$([Math]::Round($skewness, 4))</td></tr>"
    $statisticsRows += "<tr><td>Kurtosis</td><td>$([Math]::Round($kurtosis, 4))</td></tr>"

    # Préparer les détails des méthodes
    $methodsDetails = ""
    foreach ($method in $comparison.Methods) {
        if ($comparison.Results.ContainsKey($method) -and -not $comparison.Results[$method].Error) {
            $methodsDetails += "<div class='card'>"
            $methodsDetails += "<div class='card-header'>Méthode: $method</div>"

            switch ($method) {
                "Slope" {
                    $slopeResult = $comparison.Results.Slope
                    $methodsDetails += "<div>Ratio des pentes: $([Math]::Round($slopeResult.SlopeRatio.SlopeRatio, 4))</div>"
                    $methodsDetails += "<div>Direction de l'asymétrie: $($slopeResult.AsymmetryDirection)</div>"
                    $methodsDetails += "<div>Intensité de l'asymétrie: $($slopeResult.AsymmetryIntensity)</div>"
                    $methodsDetails += "<div>Pente de la queue gauche: $([Math]::Round($slopeResult.SlopeRatio.LeftSlope, 4))</div>"
                    $methodsDetails += "<div>Pente de la queue droite: $([Math]::Round($slopeResult.SlopeRatio.RightSlope, 4))</div>"
                }
                "Moments" {
                    $momentResult = $comparison.Results.Moments
                    $methodsDetails += "<div>Coefficient d'asymétrie (skewness): $([Math]::Round($momentResult.Skewness, 4))</div>"
                    $methodsDetails += "<div>Kurtosis: $([Math]::Round($momentResult.Kurtosis, 4))</div>"
                    $methodsDetails += "<div>Direction de l'asymétrie: $($momentResult.AsymmetryDirection)</div>"
                    $methodsDetails += "<div>Intensité de l'asymétrie: $($momentResult.AsymmetryIntensity)</div>"
                }
                "Quantiles" {
                    $quantileResult = $comparison.Results.Quantiles
                    $methodsDetails += "<div>Coefficient d'asymétrie de Bowley: $([Math]::Round($quantileResult.BowleySkewness, 4))</div>"
                    $methodsDetails += "<div>Direction de l'asymétrie: $($quantileResult.AsymmetryDirection)</div>"
                    $methodsDetails += "<div>Intensité de l'asymétrie: $($quantileResult.AsymmetryIntensity)</div>"
                    $methodsDetails += "<div>Q1: $([Math]::Round($quantileResult.Q1, 4))</div>"
                    $methodsDetails += "<div>Q2 (médiane): $([Math]::Round($quantileResult.Q2, 4))</div>"
                    $methodsDetails += "<div>Q3: $([Math]::Round($quantileResult.Q3, 4))</div>"
                }
                "Density" {
                    if ($comparison.Results.ContainsKey("Density")) {
                        $densityResult = $comparison.Results.Density
                        if (-not $densityResult.Error) {
                            $methodsDetails += "<div>Ratio de densité: $([Math]::Round($densityResult.DensityRatio, 4))</div>"
                            $methodsDetails += "<div>Direction de l'asymétrie: $($densityResult.AsymmetryDirection)</div>"
                            $methodsDetails += "<div>Intensité de l'asymétrie: $($densityResult.AsymmetryIntensity)</div>"
                        } else {
                            $methodsDetails += "<div>Erreur: $($densityResult.Error)</div>"
                        }
                    } else {
                        $methodsDetails += "<div>Méthode non disponible.</div>"
                    }
                }
            }

            $methodsDetails += "</div>"
        }
    }

    # Préparer les recommandations
    $recommendations = ""
    foreach ($recommendation in $compositeScore.Recommendations) {
        $recommendations += "<li>$recommendation</li>"
    }

    # Préparer les scripts pour les graphiques
    $chartScripts = ""

    # Script pour l'histogramme
    $chartScripts += @"
// Histogramme
const histogramCtx = document.getElementById('histogramChart').getContext('2d');

// Créer les données de l'histogramme
const histogramData = {
    labels: [],
    datasets: [{
        label: 'Fréquence',
        data: [],
        backgroundColor: 'rgba(52, 152, 219, 0.5)',
        borderColor: 'rgba(52, 152, 219, 1)',
        borderWidth: 1
    }]
};

// Calculer les classes de l'histogramme
const min = $min;
const max = $max;
const range = max - min;
const binCount = 10;
const binWidth = range / binCount;

// Initialiser les compteurs de fréquence
const bins = Array(binCount).fill(0);
const binLabels = [];

// Calculer les étiquettes des classes
for (let i = 0; i < binCount; i++) {
    const lowerBound = min + i * binWidth;
    const upperBound = min + (i + 1) * binWidth;
    binLabels.push(`[\${lowerBound.toFixed(2)}, \${upperBound.toFixed(2)})`);
}

// Compter les fréquences
const data = [$(($Data | ForEach-Object { $_.ToString() }) -join ',')];
data.forEach(value => {
    const binIndex = Math.min(binCount - 1, Math.floor((value - min) / binWidth));
    bins[binIndex]++;
});

// Mettre à jour les données de l'histogramme
histogramData.labels = binLabels;
histogramData.datasets[0].data = bins;

// Créer l'histogramme
const histogramChart = new Chart(histogramCtx, {
    type: 'bar',
    data: histogramData,
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'top',
                labels: {
                    boxWidth: 12,
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                }
            },
            title: {
                display: true,
                text: 'Distribution des données',
                font: {
                    size: function() {
                        return window.innerWidth < 768 ? 14 : 16;
                    }
                }
            },
            tooltip: {
                enabled: true,
                mode: 'index',
                intersect: false,
                bodyFont: {
                    size: function() {
                        return window.innerWidth < 768 ? 10 : 12;
                    }
                },
                titleFont: {
                    size: function() {
                        return window.innerWidth < 768 ? 11 : 13;
                    }
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Fréquence',
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                },
                ticks: {
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 9 : 11;
                        }
                    },
                    maxTicksLimit: function() {
                        return window.innerWidth < 768 ? 5 : 10;
                    }
                }
            },
            x: {
                title: {
                    display: true,
                    text: 'Valeurs',
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                },
                ticks: {
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 9 : 11;
                        }
                    },
                    maxRotation: function() {
                        return window.innerWidth < 768 ? 45 : 0;
                    },
                    autoSkip: true,
                    maxTicksLimit: function() {
                        return window.innerWidth < 768 ? 5 : 10;
                    }
                }
            }
        }
    }
});
"@

    # Script pour le graphique de comparaison des méthodes
    $chartScripts += @"

// Graphique de comparaison des méthodes
const methodsCtx = document.getElementById('methodsChart').getContext('2d');

// Créer les données pour le graphique de comparaison des méthodes
const methodsData = {
    labels: [],
    datasets: [{
        label: 'Score d\'asymétrie',
        data: [],
        backgroundColor: [
            'rgba(52, 152, 219, 0.5)',
            'rgba(46, 204, 113, 0.5)',
            'rgba(155, 89, 182, 0.5)',
            'rgba(243, 156, 18, 0.5)'
        ],
        borderColor: [
            'rgba(52, 152, 219, 1)',
            'rgba(46, 204, 113, 1)',
            'rgba(155, 89, 182, 1)',
            'rgba(243, 156, 18, 1)'
        ],
        borderWidth: 1
    }]
};

// Ajouter les données des méthodes
"@

    # Ajouter les données des méthodes au graphique
    $methodsDataScript = ""
    foreach ($method in $comparison.Methods) {
        if ($comparison.MethodScores.ContainsKey($method)) {
            $score = [Math]::Round($comparison.MethodScores[$method], 4)
            $methodsDataScript += "methodsData.labels.push('$method');"
            $methodsDataScript += "methodsData.datasets[0].data.push($score);"
        }
    }
    $chartScripts += $methodsDataScript

    # Finaliser le script du graphique de comparaison des méthodes
    $chartScripts += @"

// Créer le graphique de comparaison des méthodes
const methodsChart = new Chart(methodsCtx, {
    type: 'bar',
    data: methodsData,
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'top',
                labels: {
                    boxWidth: 12,
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                }
            },
            title: {
                display: true,
                text: 'Comparaison des méthodes d\'évaluation de l\'asymétrie',
                font: {
                    size: function() {
                        return window.innerWidth < 768 ? 14 : 16;
                    }
                }
            },
            tooltip: {
                enabled: true,
                mode: 'index',
                intersect: false,
                bodyFont: {
                    size: function() {
                        return window.innerWidth < 768 ? 10 : 12;
                    }
                },
                titleFont: {
                    size: function() {
                        return window.innerWidth < 768 ? 11 : 13;
                    }
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Score d\'asymétrie',
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                },
                ticks: {
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 9 : 11;
                        }
                    },
                    maxTicksLimit: function() {
                        return window.innerWidth < 768 ? 5 : 10;
                    }
                }
            },
            x: {
                title: {
                    display: true,
                    text: 'Méthode',
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 10 : 12;
                        }
                    }
                },
                ticks: {
                    font: {
                        size: function() {
                            return window.innerWidth < 768 ? 9 : 11;
                        }
                    },
                    maxRotation: function() {
                        return window.innerWidth < 768 ? 45 : 0;
                    }
                }
            }
        }
    }
});
"@

    # Préparer les sélections des filtres
    $directionSelections = @{
        "All"       = ""
        "Positive"  = ""
        "Negative"  = ""
        "Symmetric" = ""
    }

    $intensitySelections = @{
        "All"        = ""
        "Negligible" = ""
        "VeryWeak"   = ""
        "Weak"       = ""
        "Moderate"   = ""
        "Strong"     = ""
        "VeryStrong" = ""
        "Extreme"    = ""
    }

    # Définir la sélection active
    $directionFilters = @("Positive", "Negative", "Symmetric")
    $intensityFilters = @("Negligible", "VeryWeak", "Weak", "Moderate", "Strong", "VeryStrong", "Extreme")

    if ($directionFilters -contains $Filter) {
        $directionSelections[$Filter] = "selected"
    } elseif ($intensityFilters -contains $Filter) {
        $intensitySelections[$Filter] = "selected"
    } else {
        $directionSelections["All"] = "selected"
        $intensitySelections["All"] = "selected"
    }

    # Remplacer les placeholders dans le template
    $html = $template
    $html = $html.Replace("{{TITLE}}", $Title)
    $html = $html.Replace("{{DATE}}", $dateStr)
    $html = $html.Replace("{{SAMPLE_SIZE}}", $Data.Count)
    $html = $html.Replace("{{SUMMARY}}", "L'analyse de l'asymétrie de la distribution a révélé une asymétrie $($compositeScore.AsymmetryDirection.ToLower()) de niveau $($compositeScore.AsymmetryIntensity.ToLower()).")
    $html = $html.Replace("{{ASYMMETRY_DIRECTION}}", $compositeScore.AsymmetryDirection)
    $html = $html.Replace("{{ASYMMETRY_INTENSITY}}", $compositeScore.AsymmetryIntensity)
    $html = $html.Replace("{{ASYMMETRY_INTENSITY_CLASS}}", $intensityClass)
    $html = $html.Replace("{{COMPOSITE_SCORE}}", [Math]::Round($compositeScore.CompositeScore, 4))
    $html = $html.Replace("{{RECOMMENDED_METHOD}}", $comparison.RecommendedMethod)
    $html = $html.Replace("{{CONSISTENCY_SCORE}}", [Math]::Round($comparison.ConsistencyScore, 4))
    $html = $html.Replace("{{STATISTICS_ROWS}}", ($statisticsRows -join ""))
    $html = $html.Replace("{{METHODS_DETAILS}}", $methodsDetails)
    $html = $html.Replace("{{RECOMMENDATIONS}}", $recommendations)
    $html = $html.Replace("{{GENERATION_DATE}}", $dateStr)
    $html = $html.Replace("{{CHART_SCRIPTS}}", $chartScripts)

    # Remplacer les placeholders des filtres
    $html = $html.Replace("{{DIRECTION_ALL_SELECTED}}", $directionSelections["All"])
    $html = $html.Replace("{{DIRECTION_POSITIVE_SELECTED}}", $directionSelections["Positive"])
    $html = $html.Replace("{{DIRECTION_NEGATIVE_SELECTED}}", $directionSelections["Negative"])
    $html = $html.Replace("{{DIRECTION_SYMMETRIC_SELECTED}}", $directionSelections["Symmetric"])

    $html = $html.Replace("{{INTENSITY_ALL_SELECTED}}", $intensitySelections["All"])
    $html = $html.Replace("{{INTENSITY_NEGLIGIBLE_SELECTED}}", $intensitySelections["Negligible"])
    $html = $html.Replace("{{INTENSITY_VERYWEAK_SELECTED}}", $intensitySelections["VeryWeak"])
    $html = $html.Replace("{{INTENSITY_WEAK_SELECTED}}", $intensitySelections["Weak"])
    $html = $html.Replace("{{INTENSITY_MODERATE_SELECTED}}", $intensitySelections["Moderate"])
    $html = $html.Replace("{{INTENSITY_STRONG_SELECTED}}", $intensitySelections["Strong"])
    $html = $html.Replace("{{INTENSITY_VERYSTRONG_SELECTED}}", $intensitySelections["VeryStrong"])
    $html = $html.Replace("{{INTENSITY_EXTREME_SELECTED}}", $intensitySelections["Extreme"])

    # Écrire le rapport dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport HTML écrit dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture du rapport HTML dans le fichier: $_"
        }
    }

    return $html
}

<#
.SYNOPSIS
    Génère un rapport JSON sur l'asymétrie d'une distribution pour l'intégration avec d'autres outils.

.DESCRIPTION
    Cette fonction génère un rapport JSON standardisé sur l'asymétrie d'une distribution,
    suivant un schéma prédéfini pour faciliter l'intégration avec d'autres outils.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Methods
    Les méthodes d'évaluation de l'asymétrie à utiliser (par défaut toutes).

.PARAMETER TailProportion
    La proportion de données à considérer comme faisant partie des queues (par défaut 0.1, soit 10%).

.PARAMETER SchemaVersion
    La version du schéma JSON à utiliser (par défaut "1.0").

.PARAMETER IncludeHistogramData
    Indique si les données de l'histogramme doivent être incluses dans le rapport (par défaut $false).

.PARAMETER OutputPath
    Le chemin du fichier de sortie (optionnel). Si non spécifié, le rapport est retourné sous forme de chaîne JSON.

.EXAMPLE
    Get-AsymmetryJsonReport -Data $data -Methods @("Slope", "Moments") -OutputPath "rapport.json"
    Génère un rapport JSON sur l'asymétrie de la distribution et l'enregistre dans le fichier "rapport.json".

.OUTPUTS
    System.String
#>
function Get-AsymmetryJsonReport {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Density", "Slope", "Moments", "Quantiles", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 0.49)]
        [double]$TailProportion = 0.1,

        [Parameter(Mandatory = $false)]
        [string]$SchemaVersion = "1.0",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistogramData = $false,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    # Obtenir les résultats d'analyse
    $comparison = Compare-AsymmetryMethods -Data $Data -Methods $Methods -TailProportion $TailProportion
    $compositeScore = Get-CompositeAsymmetryScore -Data $Data -Methods $Methods -TailProportion $TailProportion

    # Calculer les statistiques descriptives
    $sortedData = $Data | Sort-Object
    $mean = ($sortedData | Measure-Object -Average).Average
    $median = if ($sortedData.Count % 2 -eq 0) {
        ($sortedData[$sortedData.Count / 2 - 1] + $sortedData[$sortedData.Count / 2]) / 2
    } else {
        $sortedData[[Math]::Floor($sortedData.Count / 2)]
    }
    $stdDev = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
    $min = $sortedData[0]
    $max = $sortedData[-1]
    $range = $max - $min

    # Calculer les quantiles
    $q1 = Get-Percentile -Data $sortedData -Percentile 25
    $q2 = $median
    $q3 = Get-Percentile -Data $sortedData -Percentile 75
    $iqr = $q3 - $q1
    $p10 = Get-Percentile -Data $sortedData -Percentile 10
    $p90 = Get-Percentile -Data $sortedData -Percentile 90

    # Calculer les moments centraux
    $m2 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $m3 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 3) } | Measure-Object -Average).Average
    $m4 = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 4) } | Measure-Object -Average).Average

    # Calculer le coefficient d'asymétrie (skewness) et le kurtosis
    $skewness = $m3 / [Math]::Pow($m2, 1.5)
    $kurtosis = $m4 / [Math]::Pow($m2, 2) - 3

    # Préparer les données pour le rapport JSON
    $now = Get-Date
    $dateStr = $now.ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Créer l'objet JSON
    $jsonReport = @{
        metadata        = @{
            title          = "Rapport d'analyse d'asymétrie"
            generationDate = $dateStr
            version        = $SchemaVersion
            sampleSize     = $Data.Count
        }
        summary         = @{
            asymmetryDirection = $compositeScore.AsymmetryDirection
            asymmetryIntensity = $compositeScore.AsymmetryIntensity
            compositeScore     = [Math]::Round($compositeScore.CompositeScore, 4)
            recommendedMethod  = $comparison.RecommendedMethod
            consistencyScore   = [Math]::Round($comparison.ConsistencyScore, 4)
            summaryText        = "L'analyse de l'asymétrie de la distribution a révélé une asymétrie $($compositeScore.AsymmetryDirection.ToLower()) de niveau $($compositeScore.AsymmetryIntensity.ToLower())."
        }
        statistics      = @{
            min       = [Math]::Round($min, 4)
            max       = [Math]::Round($max, 4)
            range     = [Math]::Round($range, 4)
            mean      = [Math]::Round($mean, 4)
            median    = [Math]::Round($median, 4)
            stdDev    = [Math]::Round($stdDev, 4)
            skewness  = [Math]::Round($skewness, 4)
            kurtosis  = [Math]::Round($kurtosis, 4)
            quantiles = @{
                q1  = [Math]::Round($q1, 4)
                q2  = [Math]::Round($q2, 4)
                q3  = [Math]::Round($q3, 4)
                iqr = [Math]::Round($iqr, 4)
                p10 = [Math]::Round($p10, 4)
                p90 = [Math]::Round($p90, 4)
            }
        }
        methods         = @{}
        recommendations = $compositeScore.Recommendations
    }

    # Ajouter les résultats des méthodes
    foreach ($method in $comparison.Methods) {
        if ($comparison.Results.ContainsKey($method) -and -not $comparison.Results[$method].Error) {
            $result = $comparison.Results[$method]

            switch ($method) {
                "Slope" {
                    $jsonReport.methods.slope = @{
                        slopeRatio         = [Math]::Round($result.SlopeRatio.SlopeRatio, 4)
                        leftSlope          = [Math]::Round($result.SlopeRatio.LeftSlope, 4)
                        rightSlope         = [Math]::Round($result.SlopeRatio.RightSlope, 4)
                        asymmetryDirection = $result.AsymmetryDirection
                        asymmetryIntensity = $result.AsymmetryIntensity
                        score              = [Math]::Round($comparison.MethodScores[$method], 4)
                    }
                }
                "Moments" {
                    $jsonReport.methods.moments = @{
                        skewness           = [Math]::Round($result.Skewness, 4)
                        kurtosis           = [Math]::Round($result.Kurtosis, 4)
                        asymmetryDirection = $result.AsymmetryDirection
                        asymmetryIntensity = $result.AsymmetryIntensity
                        score              = [Math]::Round($comparison.MethodScores[$method], 4)
                    }
                }
                "Quantiles" {
                    $jsonReport.methods.quantiles = @{
                        bowleySkewness     = [Math]::Round($result.BowleySkewness, 4)
                        q1                 = [Math]::Round($result.Q1, 4)
                        q2                 = [Math]::Round($result.Q2, 4)
                        q3                 = [Math]::Round($result.Q3, 4)
                        asymmetryDirection = $result.AsymmetryDirection
                        asymmetryIntensity = $result.AsymmetryIntensity
                        score              = [Math]::Round($comparison.MethodScores[$method], 4)
                    }
                }
                "Density" {
                    if ($comparison.Results.ContainsKey("Density")) {
                        $densityResult = $comparison.Results.Density
                        if (-not $densityResult.Error) {
                            $jsonReport.methods.density = @{
                                densityRatio       = [Math]::Round($densityResult.DensityRatio, 4)
                                asymmetryDirection = $densityResult.AsymmetryDirection
                                asymmetryIntensity = $densityResult.AsymmetryIntensity
                                score              = [Math]::Round($comparison.MethodScores[$method], 4)
                            }
                        }
                    }
                }
            }
        }
    }

    # Ajouter les données de l'histogramme si demandé
    if ($IncludeHistogramData) {
        # Calculer les classes de l'histogramme
        $binCount = 10
        $binWidth = $range / $binCount
        $bins = @()
        $frequencies = @()

        # Initialiser les compteurs de fréquence
        $binFrequencies = New-Object int[] $binCount

        # Calculer les bornes des classes
        for ($i = 0; $i -lt $binCount; $i++) {
            $lowerBound = $min + $i * $binWidth
            $upperBound = $min + ($i + 1) * $binWidth
            $bins += [Math]::Round($lowerBound, 4)
            if ($i -eq $binCount - 1) {
                $bins += [Math]::Round($upperBound, 4)
            }
        }

        # Compter les fréquences
        foreach ($value in $Data) {
            $binIndex = [Math]::Min($binCount - 1, [Math]::Floor(($value - $min) / $binWidth))
            $binFrequencies[$binIndex]++
        }

        # Ajouter les fréquences à l'objet JSON
        $frequencies = $binFrequencies

        $jsonReport.data = @{
            histogram = @{
                bins        = $bins
                frequencies = $frequencies
            }
        }
    }

    # Convertir l'objet en JSON
    $jsonString = $jsonReport | ConvertTo-Json -Depth 10

    # Écrire le rapport dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $jsonString | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Rapport JSON écrit dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture du rapport JSON dans le fichier: $_"
        }
    }

    return $jsonString
}

# Importer les fonctions de calcul des quantiles et des indicateurs basés sur les quantiles
$quantileIndicatorsModulePath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileIndicators.psm1"
if (Test-Path -Path $quantileIndicatorsModulePath) {
    Import-Module $quantileIndicatorsModulePath -Force
    # Exporter les fonctions importées
    Export-ModuleMember -Function Get-Quantile, Get-WeightedQuantile, Get-InterquartileRange, Get-BowleySkewness
}

# Importer les fonctions d'évaluation visuelle de l'asymétrie
$visualAsymmetryEvaluationModulePath = Join-Path -Path $PSScriptRoot -ChildPath "VisualAsymmetryEvaluation.psm1"
if (Test-Path -Path $visualAsymmetryEvaluationModulePath) {
    Import-Module $visualAsymmetryEvaluationModulePath -Force
    # Exporter les fonctions importées
    Export-ModuleMember -Function Get-HistogramAsymmetry, Get-Histogram, Get-VisualAsymmetryEvaluation, Get-AsymmetryVisualization
}

# Importer les fonctions de rapport visuel d'asymétrie
$visualAsymmetryReportModulePath = Join-Path -Path $PSScriptRoot -ChildPath "VisualAsymmetryReport.psm1"
if (Test-Path -Path $visualAsymmetryReportModulePath) {
    Import-Module $visualAsymmetryReportModulePath -Force
    # Exporter les fonctions importées
    Export-ModuleMember -Function Get-AsymmetryVisualReport
}

# Importer les fonctions d'analyse comparative des quantiles
$quantileComparisonPath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileComparison.psm1"
if (Test-Path -Path $quantileComparisonPath) {
    Import-Module $quantileComparisonPath -Force
    # Exporter les fonctions importées
    Export-ModuleMember -Function Get-QuantileQuantilePlot, Get-NormalQuantile, Get-QuantileComparisonMetrics
}

# Importer les fonctions de visualisation des comparaisons de quantiles
$quantileComparisonVisualizationPath = Join-Path -Path $PSScriptRoot -ChildPath "QuantileComparisonVisualization.psm1"
if (Test-Path -Path $quantileComparisonVisualizationPath) {
    Import-Module $quantileComparisonVisualizationPath -Force
    # Exporter les fonctions importées
    Export-ModuleMember -Function Get-QuantileQuantilePlotVisualization, Get-ComparisonMetricsVisualization
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-DistributionTails, Get-TailLinearRegression, Get-TailSlopeRatio, Get-TailSlopeAsymmetry, Compare-AsymmetryMethods, Get-CompositeAsymmetryScore, Get-OptimalAsymmetryMethod, Get-AsymmetryTextReport, Get-AsymmetryHtmlReport, Get-AsymmetryJsonReport
