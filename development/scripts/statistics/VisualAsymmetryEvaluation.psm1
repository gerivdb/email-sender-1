# VisualAsymmetryEvaluation.psm1
# Module pour l'évaluation visuelle de l'asymétrie d'une distribution

<#
.SYNOPSIS
    Calcule l'asymétrie visuelle basée sur la forme de l'histogramme.

.DESCRIPTION
    Cette fonction calcule l'asymétrie visuelle d'une distribution en analysant
    la forme de l'histogramme et en comparant les deux moitiés de la distribution.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER BinCount
    Le nombre de classes pour l'histogramme (par défaut 20).

.PARAMETER Normalize
    Indique si l'histogramme doit être normalisé (par défaut $true).

.PARAMETER Method
    La méthode de calcul de l'asymétrie visuelle (par défaut "AreaDifference").
    Les méthodes disponibles sont :
    - AreaDifference : Différence d'aire entre les deux moitiés de l'histogramme
    - ShapeDifference : Différence de forme entre les deux moitiés de l'histogramme
    - PeakOffset : Décalage du pic par rapport à la médiane
    - TailRatio : Rapport entre les queues de la distribution

.EXAMPLE
    Get-HistogramAsymmetry -Data $data -BinCount 20 -Method "AreaDifference"
    Calcule l'asymétrie visuelle de la distribution $data en utilisant la méthode de différence d'aire.

.OUTPUTS
    PSObject
#>
function Get-HistogramAsymmetry {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 100)]
        [int]$BinCount = 20,

        [Parameter(Mandatory = $false)]
        [switch]$Normalize = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AreaDifference", "ShapeDifference", "PeakOffset", "TailRatio")]
        [string]$Method = "AreaDifference"
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Calculer l'histogramme
    $histogram = Get-Histogram -Data $Data -BinCount $BinCount -Normalize:$Normalize

    # Calculer la médiane
    $median = Get-Median -Data $Data

    # Trouver l'indice de la classe contenant la médiane
    $medianBinIndex = 0
    for ($i = 0; $i -lt $histogram.Bins.Count - 1; $i++) {
        if ($median -ge $histogram.Bins[$i] -and $median -lt $histogram.Bins[$i + 1]) {
            $medianBinIndex = $i
            break
        }
    }

    # Calculer l'asymétrie visuelle selon la méthode choisie
    $result = $null
    switch ($Method) {
        "AreaDifference" {
            $result = Get-AreaDifferenceAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
        }
        "ShapeDifference" {
            $result = Get-ShapeDifferenceAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
        }
        "PeakOffset" {
            $result = Get-PeakOffsetAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex -Median $median
        }
        "TailRatio" {
            $result = Get-TailRatioAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
        }
        default {
            throw "Méthode de calcul de l'asymétrie visuelle non reconnue: $Method"
        }
    }

    return $result
}

<#
.SYNOPSIS
    Calcule l'histogramme d'une distribution.

.DESCRIPTION
    Cette fonction calcule l'histogramme d'une distribution en divisant les données
    en classes et en comptant le nombre de valeurs dans chaque classe.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER BinCount
    Le nombre de classes pour l'histogramme (par défaut 20).

.PARAMETER Normalize
    Indique si l'histogramme doit être normalisé (par défaut $false).

.EXAMPLE
    Get-Histogram -Data $data -BinCount 20 -Normalize
    Calcule l'histogramme normalisé de la distribution $data avec 20 classes.

.OUTPUTS
    PSObject
#>
function Get-Histogram {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 100)]
        [int]$BinCount = 20,

        [Parameter(Mandatory = $false)]
        [switch]$Normalize = $false
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Calculer les bornes des classes
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min
    $binWidth = $range / $BinCount

    # Créer les classes
    $bins = @()
    for ($i = 0; $i -le $BinCount; $i++) {
        $bins += $min + $i * $binWidth
    }

    # Compter les fréquences
    $frequencies = New-Object int[] $BinCount
    foreach ($value in $Data) {
        $binIndex = [Math]::Min($BinCount - 1, [Math]::Floor(($value - $min) / $binWidth))
        $frequencies[$binIndex]++
    }

    # Normaliser les fréquences si demandé
    if ($Normalize) {
        $sum = ($frequencies | Measure-Object -Sum).Sum
        $normalizedFrequencies = $frequencies | ForEach-Object { $_ / $sum }
        $frequencies = $normalizedFrequencies
    }

    # Créer l'objet histogramme
    $histogram = [PSCustomObject]@{
        Bins        = $bins
        Frequencies = $frequencies
        BinWidth    = $binWidth
        Min         = $min
        Max         = $max
        BinCount    = $BinCount
        Normalized  = $Normalize
    }

    return $histogram
}

<#
.SYNOPSIS
    Calcule la médiane d'une distribution.

.DESCRIPTION
    Cette fonction calcule la médiane d'une distribution.

.PARAMETER Data
    Les données de la distribution.

.EXAMPLE
    Get-Median -Data $data
    Calcule la médiane de la distribution $data.

.OUTPUTS
    System.Double
#>
function Get-Median {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer la médiane
    $n = $sortedData.Count
    if ($n % 2 -eq 0) {
        # Nombre pair d'éléments
        $median = ($sortedData[$n / 2 - 1] + $sortedData[$n / 2]) / 2
    } else {
        # Nombre impair d'éléments
        $median = $sortedData[[Math]::Floor($n / 2)]
    }

    return $median
}

<#
.SYNOPSIS
    Calcule l'asymétrie visuelle basée sur la différence d'aire entre les deux moitiés de l'histogramme.

.DESCRIPTION
    Cette fonction calcule l'asymétrie visuelle d'une distribution en comparant
    les aires des deux moitiés de l'histogramme par rapport à la médiane.

.PARAMETER Histogram
    L'histogramme de la distribution.

.PARAMETER MedianBinIndex
    L'indice de la classe contenant la médiane.

.EXAMPLE
    Get-AreaDifferenceAsymmetry -Histogram $histogram -MedianBinIndex 10
    Calcule l'asymétrie visuelle basée sur la différence d'aire entre les deux moitiés de l'histogramme.

.OUTPUTS
    PSObject
#>
function Get-AreaDifferenceAsymmetry {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject]$Histogram,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$MedianBinIndex
    )

    # Calculer l'aire de la moitié gauche de l'histogramme
    $leftArea = 0
    for ($i = 0; $i -le $MedianBinIndex; $i++) {
        $leftArea += $Histogram.Frequencies[$i]
    }

    # Calculer l'aire de la moitié droite de l'histogramme
    $rightArea = 0
    for ($i = $MedianBinIndex + 1; $i -lt $Histogram.BinCount; $i++) {
        $rightArea += $Histogram.Frequencies[$i]
    }

    # Calculer la différence d'aire relative
    $totalArea = $leftArea + $rightArea
    $areaDifference = ($rightArea - $leftArea) / $totalArea

    # Déterminer la direction et l'intensité de l'asymétrie
    $direction = if ($areaDifference -gt 0) { "Positive" } elseif ($areaDifference -lt 0) { "Negative" } else { "Symmetric" }
    $intensity = Get-AsymmetryIntensity -Score ([Math]::Abs($areaDifference))

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Method             = "AreaDifference"
        Score              = $areaDifference
        AbsoluteScore      = [Math]::Abs($areaDifference)
        LeftArea           = $leftArea
        RightArea          = $rightArea
        TotalArea          = $totalArea
        AsymmetryDirection = $direction
        AsymmetryIntensity = $intensity
    }

    return $result
}

<#
.SYNOPSIS
    Calcule l'asymétrie visuelle basée sur la différence de forme entre les deux moitiés de l'histogramme.

.DESCRIPTION
    Cette fonction calcule l'asymétrie visuelle d'une distribution en comparant
    les formes des deux moitiés de l'histogramme par rapport à la médiane.

.PARAMETER Histogram
    L'histogramme de la distribution.

.PARAMETER MedianBinIndex
    L'indice de la classe contenant la médiane.

.EXAMPLE
    Get-ShapeDifferenceAsymmetry -Histogram $histogram -MedianBinIndex 10
    Calcule l'asymétrie visuelle basée sur la différence de forme entre les deux moitiés de l'histogramme.

.OUTPUTS
    PSObject
#>
function Get-ShapeDifferenceAsymmetry {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject]$Histogram,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$MedianBinIndex
    )

    # Déterminer le nombre de classes à comparer
    $leftBinCount = $MedianBinIndex + 1
    $rightBinCount = $Histogram.BinCount - $MedianBinIndex - 1
    $compareBinCount = [Math]::Min($leftBinCount, $rightBinCount)

    # Extraire les fréquences des deux moitiés
    $leftFrequencies = @()
    for ($i = $MedianBinIndex; $i -ge $MedianBinIndex - $compareBinCount + 1; $i--) {
        if ($i -ge 0) {
            $leftFrequencies += $Histogram.Frequencies[$i]
        } else {
            $leftFrequencies += 0
        }
    }

    $rightFrequencies = @()
    for ($i = $MedianBinIndex + 1; $i -lt $MedianBinIndex + 1 + $compareBinCount; $i++) {
        if ($i -lt $Histogram.BinCount) {
            $rightFrequencies += $Histogram.Frequencies[$i]
        } else {
            $rightFrequencies += 0
        }
    }

    # Calculer la différence de forme (distance euclidienne normalisée)
    $sumSquaredDiff = 0
    $sumSquaredLeft = 0
    $sumSquaredRight = 0
    for ($i = 0; $i -lt $compareBinCount; $i++) {
        $sumSquaredDiff += [Math]::Pow($leftFrequencies[$i] - $rightFrequencies[$i], 2)
        $sumSquaredLeft += [Math]::Pow($leftFrequencies[$i], 2)
        $sumSquaredRight += [Math]::Pow($rightFrequencies[$i], 2)
    }

    $shapeDifference = 0
    if ($sumSquaredLeft + $sumSquaredRight -gt 0) {
        $shapeDifference = $sumSquaredDiff / ($sumSquaredLeft + $sumSquaredRight)
    }

    # Déterminer la direction de l'asymétrie
    $leftSum = ($leftFrequencies | Measure-Object -Sum).Sum
    $rightSum = ($rightFrequencies | Measure-Object -Sum).Sum
    $direction = if ($rightSum -gt $leftSum) { "Positive" } elseif ($leftSum -gt $rightSum) { "Negative" } else { "Symmetric" }

    # Ajuster le score en fonction de la direction
    if ($direction -eq "Negative") {
        $shapeDifference = - $shapeDifference
    }

    # Déterminer l'intensité de l'asymétrie
    $intensity = Get-AsymmetryIntensity -Score ([Math]::Abs($shapeDifference))

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Method             = "ShapeDifference"
        Score              = $shapeDifference
        AbsoluteScore      = [Math]::Abs($shapeDifference)
        LeftFrequencies    = $leftFrequencies
        RightFrequencies   = $rightFrequencies
        CompareBinCount    = $compareBinCount
        AsymmetryDirection = $direction
        AsymmetryIntensity = $intensity
    }

    return $result
}

<#
.SYNOPSIS
    Calcule l'asymétrie visuelle basée sur le décalage du pic par rapport à la médiane.

.DESCRIPTION
    Cette fonction calcule l'asymétrie visuelle d'une distribution en mesurant
    le décalage du pic (mode) par rapport à la médiane.

.PARAMETER Histogram
    L'histogramme de la distribution.

.PARAMETER MedianBinIndex
    L'indice de la classe contenant la médiane.

.PARAMETER Median
    La médiane de la distribution.

.EXAMPLE
    Get-PeakOffsetAsymmetry -Histogram $histogram -MedianBinIndex 10 -Median 5.0
    Calcule l'asymétrie visuelle basée sur le décalage du pic par rapport à la médiane.

.OUTPUTS
    PSObject
#>
function Get-PeakOffsetAsymmetry {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject]$Histogram,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$MedianBinIndex,

        [Parameter(Mandatory = $true)]
        [double]$Median
    )

    # Trouver l'indice de la classe contenant le pic (mode)
    $maxFrequency = 0
    $peakBinIndex = 0
    for ($i = 0; $i -lt $Histogram.BinCount; $i++) {
        if ($Histogram.Frequencies[$i] -gt $maxFrequency) {
            $maxFrequency = $Histogram.Frequencies[$i]
            $peakBinIndex = $i
        }
    }

    # Calculer le centre de la classe contenant le pic
    $peakBinCenter = $Histogram.Bins[$peakBinIndex] + $Histogram.BinWidth / 2

    # Calculer le décalage du pic par rapport à la médiane
    $peakOffset = ($peakBinCenter - $Median) / ($Histogram.Max - $Histogram.Min)

    # Déterminer la direction et l'intensité de l'asymétrie
    $direction = if ($peakOffset -gt 0) { "Negative" } elseif ($peakOffset -lt 0) { "Positive" } else { "Symmetric" }
    $intensity = Get-AsymmetryIntensity -Score ([Math]::Abs($peakOffset))

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Method             = "PeakOffset"
        Score              = $peakOffset
        AbsoluteScore      = [Math]::Abs($peakOffset)
        PeakBinIndex       = $peakBinIndex
        PeakBinCenter      = $peakBinCenter
        Median             = $Median
        AsymmetryDirection = $direction
        AsymmetryIntensity = $intensity
    }

    return $result
}

<#
.SYNOPSIS
    Calcule l'asymétrie visuelle basée sur le rapport entre les queues de la distribution.

.DESCRIPTION
    Cette fonction calcule l'asymétrie visuelle d'une distribution en comparant
    les queues gauche et droite de la distribution.

.PARAMETER Histogram
    L'histogramme de la distribution.

.PARAMETER MedianBinIndex
    L'indice de la classe contenant la médiane.

.EXAMPLE
    Get-TailRatioAsymmetry -Histogram $histogram -MedianBinIndex 10
    Calcule l'asymétrie visuelle basée sur le rapport entre les queues de la distribution.

.OUTPUTS
    PSObject
#>
function Get-TailRatioAsymmetry {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSObject]$Histogram,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$MedianBinIndex
    )

    # Définir la proportion de la queue (par exemple, 20% des classes)
    $tailProportion = 0.2
    $tailBinCount = [Math]::Max(1, [Math]::Floor($Histogram.BinCount * $tailProportion))

    # Calculer l'aire de la queue gauche
    $leftTailArea = 0
    for ($i = 0; $i -lt $tailBinCount; $i++) {
        if ($i -lt $Histogram.BinCount) {
            $leftTailArea += $Histogram.Frequencies[$i]
        }
    }

    # Calculer l'aire de la queue droite
    $rightTailArea = 0
    for ($i = $Histogram.BinCount - 1; $i -ge $Histogram.BinCount - $tailBinCount; $i--) {
        if ($i -ge 0) {
            $rightTailArea += $Histogram.Frequencies[$i]
        }
    }

    # Calculer le rapport entre les queues
    $tailRatio = 0
    if ($leftTailArea + $rightTailArea -gt 0) {
        $tailRatio = ($rightTailArea - $leftTailArea) / ($rightTailArea + $leftTailArea)
    }

    # Déterminer la direction et l'intensité de l'asymétrie
    $direction = if ($tailRatio -gt 0) { "Positive" } elseif ($tailRatio -lt 0) { "Negative" } else { "Symmetric" }
    $intensity = Get-AsymmetryIntensity -Score ([Math]::Abs($tailRatio))

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Method             = "TailRatio"
        Score              = $tailRatio
        AbsoluteScore      = [Math]::Abs($tailRatio)
        LeftTailArea       = $leftTailArea
        RightTailArea      = $rightTailArea
        TailBinCount       = $tailBinCount
        AsymmetryDirection = $direction
        AsymmetryIntensity = $intensity
    }

    return $result
}

<#
.SYNOPSIS
    Détermine l'intensité de l'asymétrie en fonction du score.

.DESCRIPTION
    Cette fonction détermine l'intensité de l'asymétrie en fonction du score d'asymétrie.

.PARAMETER Score
    Le score d'asymétrie (valeur absolue).

.EXAMPLE
    Get-AsymmetryIntensity -Score 0.3
    Détermine l'intensité de l'asymétrie pour un score de 0.3.

.OUTPUTS
    System.String
#>
function Get-AsymmetryIntensity {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$Score
    )

    if ($Score -lt 0.05) {
        return "Negligible"
    } elseif ($Score -lt 0.1) {
        return "VeryWeak"
    } elseif ($Score -lt 0.2) {
        return "Weak"
    } elseif ($Score -lt 0.3) {
        return "Moderate"
    } elseif ($Score -lt 0.4) {
        return "Strong"
    } elseif ($Score -lt 0.5) {
        return "VeryStrong"
    } else {
        return "Extreme"
    }
}

<#
.SYNOPSIS
    Évalue l'asymétrie visuelle d'une distribution en utilisant plusieurs méthodes.

.DESCRIPTION
    Cette fonction évalue l'asymétrie visuelle d'une distribution en utilisant
    plusieurs méthodes et en combinant les résultats pour obtenir une évaluation globale.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER BinCount
    Le nombre de classes pour l'histogramme (par défaut 20).

.PARAMETER Methods
    Les méthodes d'évaluation visuelle à utiliser (par défaut toutes).

.PARAMETER Weights
    Les poids à attribuer à chaque méthode (par défaut égaux).

.EXAMPLE
    Get-VisualAsymmetryEvaluation -Data $data -BinCount 20 -Methods @("AreaDifference", "ShapeDifference")
    Évalue l'asymétrie visuelle de la distribution $data en utilisant les méthodes de différence d'aire et de forme.

.OUTPUTS
    PSObject
#>
function Get-VisualAsymmetryEvaluation {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 100)]
        [int]$BinCount = 20,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AreaDifference", "ShapeDifference", "PeakOffset", "TailRatio", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{}
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Déterminer les méthodes à utiliser
    $methodsToUse = @()
    if ($Methods -contains "All") {
        $methodsToUse = @("AreaDifference", "ShapeDifference", "PeakOffset", "TailRatio")
    } else {
        $methodsToUse = $Methods
    }

    # Définir les poids par défaut si non spécifiés
    if ($Weights.Count -eq 0) {
        $defaultWeight = 1.0 / $methodsToUse.Count
        foreach ($method in $methodsToUse) {
            $Weights[$method] = $defaultWeight
        }
    }

    # Calculer l'histogramme
    $histogram = Get-Histogram -Data $Data -BinCount $BinCount -Normalize

    # Calculer la médiane
    $median = Get-Median -Data $Data

    # Trouver l'indice de la classe contenant la médiane
    $medianBinIndex = 0
    for ($i = 0; $i -lt $histogram.Bins.Count - 1; $i++) {
        if ($median -ge $histogram.Bins[$i] -and $median -lt $histogram.Bins[$i + 1]) {
            $medianBinIndex = $i
            break
        }
    }

    # Évaluer l'asymétrie visuelle avec chaque méthode
    $results = @{}
    foreach ($method in $methodsToUse) {
        $result = $null
        switch ($method) {
            "AreaDifference" {
                $result = Get-AreaDifferenceAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
            }
            "ShapeDifference" {
                $result = Get-ShapeDifferenceAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
            }
            "PeakOffset" {
                $result = Get-PeakOffsetAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex -Median $median
            }
            "TailRatio" {
                $result = Get-TailRatioAsymmetry -Histogram $histogram -MedianBinIndex $medianBinIndex
            }
        }
        $results[$method] = $result
    }

    # Calculer le score composite
    $compositeScore = 0
    $totalWeight = 0
    foreach ($method in $methodsToUse) {
        $weight = $Weights[$method]
        $score = $results[$method].Score
        $compositeScore += $weight * $score
        $totalWeight += $weight
    }
    if ($totalWeight -gt 0) {
        $compositeScore = $compositeScore / $totalWeight
    }

    # Déterminer la direction et l'intensité de l'asymétrie composite
    $direction = if ($compositeScore -gt 0) { "Positive" } elseif ($compositeScore -lt 0) { "Negative" } else { "Symmetric" }
    $intensity = Get-AsymmetryIntensity -Score ([Math]::Abs($compositeScore))

    # Déterminer la méthode la plus cohérente
    $consistencyScores = @{}
    foreach ($method1 in $methodsToUse) {
        $consistencyScore = 0
        foreach ($method2 in $methodsToUse) {
            if ($method1 -ne $method2) {
                $direction1 = $results[$method1].AsymmetryDirection
                $direction2 = $results[$method2].AsymmetryDirection
                if ($direction1 -eq $direction2) {
                    $consistencyScore += 1
                }
            }
        }
        $consistencyScores[$method1] = $consistencyScore
    }
    $mostConsistentMethod = $methodsToUse | Sort-Object { $consistencyScores[$_] } -Descending | Select-Object -First 1

    # Créer l'objet résultat
    $evaluationResult = [PSCustomObject]@{
        Methods              = $methodsToUse
        Results              = $results
        CompositeScore       = $compositeScore
        AsymmetryDirection   = $direction
        AsymmetryIntensity   = $intensity
        MostConsistentMethod = $mostConsistentMethod
        ConsistencyScores    = $consistencyScores
        Histogram            = $histogram
        Median               = $median
        MedianBinIndex       = $medianBinIndex
    }

    return $evaluationResult
}

<#
.SYNOPSIS
    Génère une visualisation de l'asymétrie d'une distribution.

.DESCRIPTION
    Cette fonction génère une visualisation de l'asymétrie d'une distribution
    sous forme de graphique HTML interactif.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER BinCount
    Le nombre de classes pour l'histogramme (par défaut 20).

.PARAMETER Methods
    Les méthodes d'évaluation visuelle à utiliser (par défaut toutes).

.PARAMETER OutputPath
    Le chemin du fichier de sortie HTML (optionnel).

.PARAMETER Title
    Le titre du graphique (par défaut "Visualisation de l'asymétrie").

.PARAMETER Width
    La largeur du graphique en pixels (par défaut 800).

.PARAMETER Height
    La hauteur du graphique en pixels (par défaut 600).

.EXAMPLE
    Get-AsymmetryVisualization -Data $data -BinCount 20 -OutputPath "asymmetry.html"
    Génère une visualisation de l'asymétrie de la distribution $data et l'enregistre dans le fichier "asymmetry.html".

.OUTPUTS
    System.String
#>
function Get-AsymmetryVisualization {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 100)]
        [int]$BinCount = 20,

        [Parameter(Mandatory = $false)]
        [ValidateSet("AreaDifference", "ShapeDifference", "PeakOffset", "TailRatio", "All")]
        [string[]]$Methods = @("All"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$Title = "Visualisation de l'asymétrie",

        [Parameter(Mandatory = $false)]
        [int]$Width = 800,

        [Parameter(Mandatory = $false)]
        [int]$Height = 600
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Évaluer l'asymétrie visuelle
    $evaluation = Get-VisualAsymmetryEvaluation -Data $Data -BinCount $BinCount -Methods $Methods

    # Créer l'histogramme
    $histogram = $evaluation.Histogram
    $bins = $histogram.Bins
    $frequencies = $histogram.Frequencies
    $binLabels = @()
    for ($i = 0; $i -lt $bins.Count - 1; $i++) {
        $binLabels += "[$([Math]::Round($bins[$i], 2)), $([Math]::Round($bins[$i + 1], 2)))"
    }

    # Créer les données pour le graphique
    $histogramData = @()
    for ($i = 0; $i -lt $binLabels.Count; $i++) {
        $histogramData += @{
            bin       = $binLabels[$i]
            frequency = $frequencies[$i]
            color     = if ($i -le $evaluation.MedianBinIndex) { "rgba(54, 162, 235, 0.6)" } else { "rgba(255, 99, 132, 0.6)" }
        }
    }
    $histogramDataJson = $histogramData | ConvertTo-Json

    # Créer les données pour le tableau des résultats
    $resultsData = @()
    foreach ($method in $evaluation.Methods) {
        $result = $evaluation.Results[$method]
        $resultsData += @{
            method      = $method
            score       = [Math]::Round($result.Score, 4)
            direction   = $result.AsymmetryDirection
            intensity   = $result.AsymmetryIntensity
            consistency = $evaluation.ConsistencyScores[$method]
        }
    }
    $resultsDataJson = $resultsData | ConvertTo-Json

    # Créer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .chart-container {
            flex: 2;
            min-width: 500px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .results-container {
            flex: 1;
            min-width: 300px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .summary {
            margin-top: 20px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        table th, table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        table th {
            background-color: #f2f2f2;
        }
        .positive {
            color: #27ae60;
        }
        .negative {
            color: #e74c3c;
        }
        .symmetric {
            color: #3498db;
        }
        .negligible {
            font-weight: normal;
        }
        .veryweak, .weak {
            font-weight: normal;
        }
        .moderate {
            font-weight: bold;
        }
        .strong, .verystrong, .extreme {
            font-weight: bold;
            text-decoration: underline;
        }
        @media (max-width: 768px) {
            .container {
                flex-direction: column;
            }
            .chart-container, .results-container {
                min-width: 100%;
            }
        }
    </style>
</head>
<body>
    <h1>$Title</h1>

    <div class="summary">
        <h2>Résumé</h2>
        <p>
            <strong>Direction d'asymétrie:</strong> <span class="$($evaluation.AsymmetryDirection.ToLower())">$($evaluation.AsymmetryDirection)</span><br>
            <strong>Intensité d'asymétrie:</strong> <span class="$($evaluation.AsymmetryIntensity.ToLower())">$($evaluation.AsymmetryIntensity)</span><br>
            <strong>Score composite:</strong> $([Math]::Round($evaluation.CompositeScore, 4))<br>
            <strong>Méthode la plus cohérente:</strong> $($evaluation.MostConsistentMethod)<br>
            <strong>Taille de l'échantillon:</strong> $($Data.Count) points
        </p>
    </div>

    <div class="container">
        <div class="chart-container">
            <h2>Histogramme</h2>
            <canvas id="histogramChart"></canvas>
        </div>

        <div class="results-container">
            <h2>Résultats par méthode</h2>
            <table id="resultsTable">
                <thead>
                    <tr>
                        <th>Méthode</th>
                        <th>Score</th>
                        <th>Direction</th>
                        <th>Intensité</th>
                    </tr>
                </thead>
                <tbody>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        // Données de l'histogramme
        const histogramData = $histogramDataJson;

        // Données des résultats
        const resultsData = $resultsDataJson;

        // Créer l'histogramme
        const ctx = document.getElementById('histogramChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: histogramData.map(d => d.bin),
                datasets: [{
                    label: 'Fréquence',
                    data: histogramData.map(d => d.frequency),
                    backgroundColor: histogramData.map(d => d.color),
                    borderColor: histogramData.map(d => d.color.replace('0.6', '1')),
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        callbacks: {
                            title: function(tooltipItems) {
                                return tooltipItems[0].label;
                            },
                            label: function(context) {
                                return `Fréquence: ${context.raw}`;
                            }
                        }
                    },
                    annotation: {
                        annotations: {
                            line1: {
                                type: 'line',
                                yMin: 0,
                                yMax: 1,
                                xMin: $($evaluation.MedianBinIndex),
                                xMax: $($evaluation.MedianBinIndex),
                                borderColor: 'rgba(0, 0, 0, 0.5)',
                                borderWidth: 2,
                                label: {
                                    content: 'Médiane',
                                    enabled: true,
                                    position: 'top'
                                }
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Fréquence'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Classes'
                        }
                    }
                }
            }
        });

        // Remplir le tableau des résultats
        const tbody = document.querySelector('#resultsTable tbody');
        resultsData.forEach(result => {
            const row = document.createElement('tr');

            const methodCell = document.createElement('td');
            methodCell.textContent = result.method;
            row.appendChild(methodCell);

            const scoreCell = document.createElement('td');
            scoreCell.textContent = result.score;
            row.appendChild(scoreCell);

            const directionCell = document.createElement('td');
            directionCell.textContent = result.direction;
            directionCell.className = result.direction.toLowerCase();
            row.appendChild(directionCell);

            const intensityCell = document.createElement('td');
            intensityCell.textContent = result.intensity;
            intensityCell.className = result.intensity.toLowerCase();
            row.appendChild(intensityCell);

            tbody.appendChild(row);
        });
    </script>
</body>
</html>
"@

    # Écrire le HTML dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Visualisation HTML écrite dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture de la visualisation HTML dans le fichier: $_"
        }
    }

    return $html
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-HistogramAsymmetry, Get-Histogram, Get-Median, Get-AreaDifferenceAsymmetry, Get-ShapeDifferenceAsymmetry, Get-PeakOffsetAsymmetry, Get-TailRatioAsymmetry, Get-AsymmetryIntensity, Get-VisualAsymmetryEvaluation, Get-AsymmetryVisualization
