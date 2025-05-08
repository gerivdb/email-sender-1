<#
.SYNOPSIS
    Module pour la sélection automatique du noyau optimal pour l'estimation de densité par noyau.

.DESCRIPTION
    Ce module implémente les fonctions nécessaires pour la sélection automatique du noyau optimal
    pour l'estimation de densité par noyau en fonction des caractéristiques des données et des objectifs d'analyse.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

<#
.SYNOPSIS
    Détecte automatiquement les caractéristiques des données.

.DESCRIPTION
    Cette fonction analyse les données pour détecter automatiquement leurs caractéristiques,
    telles que la normalité, l'asymétrie, la multimodalité, la présence de valeurs aberrantes, etc.
    Ces caractéristiques peuvent être utilisées pour choisir le noyau optimal pour l'estimation de densité par noyau.

.PARAMETER Data
    Les données à analyser.

.PARAMETER Verbose
    Affiche des informations détaillées sur les caractéristiques détectées.

.EXAMPLE
    Get-DataCharacteristics -Data $data
    Détecte automatiquement les caractéristiques des données fournies.

.EXAMPLE
    Get-DataCharacteristics -Data $data -Verbose
    Détecte automatiquement les caractéristiques des données fournies et affiche des informations détaillées.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DataCharacteristics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour détecter leurs caractéristiques."
    }

    # Initialiser les caractéristiques
    $characteristics = @{
        SampleSize        = $Data.Count
        Mean              = 0
        Median            = 0
        StdDev            = 0
        Min               = 0
        Max               = 0
        Range             = 0
        IQR               = 0
        Skewness          = 0
        Kurtosis          = 0
        IsNormal          = $false
        IsSkewed          = $false
        IsMultimodal      = $false
        HasOutliers       = $false
        OutlierCount      = 0
        OutlierPercentage = 0
        Modes             = @()
        ModeCount         = 0
        Complexity        = "Low"  # Low, Medium, High
        RecommendedKernel = "Gaussian"  # Gaussian, Epanechnikov, Triangular, Uniform, Biweight, Triweight, Cosine
    }

    # Trier les données
    $sortedData = $Data | Sort-Object
    $n = $sortedData.Count

    # Calculer les statistiques de base
    $characteristics.Min = $sortedData[0]
    $characteristics.Max = $sortedData[$n - 1]
    $characteristics.Range = $characteristics.Max - $characteristics.Min
    $characteristics.Mean = ($Data | Measure-Object -Average).Average

    # Calculer la médiane
    if ($n % 2 -eq 0) {
        $characteristics.Median = ($sortedData[$n / 2 - 1] + $sortedData[$n / 2]) / 2
    } else {
        $characteristics.Median = $sortedData[[Math]::Floor($n / 2)]
    }

    # Calculer l'écart-type
    $characteristics.StdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $characteristics.Mean, 2) } | Measure-Object -Average).Average)

    # Calculer l'IQR (écart interquartile)
    $q1Index = [Math]::Floor($n * 0.25)
    $q3Index = [Math]::Floor($n * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $characteristics.IQR = $q3 - $q1

    # Calculer l'asymétrie (skewness)
    $skewnessSum = 0
    foreach ($x in $Data) {
        $skewnessSum += [Math]::Pow(($x - $characteristics.Mean) / $characteristics.StdDev, 3)
    }
    $characteristics.Skewness = $skewnessSum / $n

    # Calculer l'aplatissement (kurtosis)
    $kurtosisSum = 0
    foreach ($x in $Data) {
        $kurtosisSum += [Math]::Pow(($x - $characteristics.Mean) / $characteristics.StdDev, 4)
    }
    $characteristics.Kurtosis = $kurtosisSum / $n - 3  # Excess kurtosis (normal = 0)

    # Détecter la normalité
    # Test de Jarque-Bera simplifié
    $jbStat = $n * ($characteristics.Skewness * $characteristics.Skewness / 6 + $characteristics.Kurtosis * $characteristics.Kurtosis / 24)
    $characteristics.IsNormal = $jbStat -lt 5.99  # Valeur critique pour alpha = 0.05

    # Détecter l'asymétrie
    $characteristics.IsSkewed = [Math]::Abs($characteristics.Skewness) -gt 0.5

    # Détecter les valeurs aberrantes
    $lowerBound = $q1 - 1.5 * $characteristics.IQR
    $upperBound = $q3 + 1.5 * $characteristics.IQR
    $outliers = $Data | Where-Object { $_ -lt $lowerBound -or $_ -gt $upperBound }
    $characteristics.HasOutliers = $outliers.Count -gt 0
    $characteristics.OutlierCount = $outliers.Count
    $characteristics.OutlierPercentage = 100 * $outliers.Count / $n

    # Détecter la multimodalité
    # Utiliser une estimation de densité par noyau pour détecter les modes
    $bandwidth = 1.06 * $characteristics.StdDev * [Math]::Pow($n, -0.2)  # Règle de Silverman
    $gridSize = 512
    $min = $characteristics.Min - 3 * $bandwidth
    $max = $characteristics.Max + 3 * $bandwidth
    $step = ($max - $min) / ($gridSize - 1)
    $grid = 0..($gridSize - 1) | ForEach-Object { $min + $_ * $step }
    $density = New-Object double[] $gridSize

    # Calculer la densité pour chaque point de la grille
    for ($i = 0; $i -lt $gridSize; $i++) {
        $x = $grid[$i]
        $sum = 0
        foreach ($dataPoint in $Data) {
            $z = ($x - $dataPoint) / $bandwidth
            $sum += (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $z * $z)
        }
        $density[$i] = $sum / ($n * $bandwidth)
    }

    # Détecter les modes
    $modes = @()
    for ($i = 1; $i -lt $gridSize - 1; $i++) {
        if ($density[$i] -gt $density[$i - 1] -and $density[$i] -gt $density[$i + 1]) {
            $modes += $grid[$i]
        }
    }

    # Filtrer les modes mineurs
    $maxDensity = ($density | Measure-Object -Maximum).Maximum
    $significantModes = $modes | Where-Object {
        $index = [Array]::IndexOf($grid, $_)
        $density[$index] -gt 0.1 * $maxDensity
    }

    $characteristics.Modes = $significantModes
    $characteristics.ModeCount = $significantModes.Count
    $characteristics.IsMultimodal = $significantModes.Count -gt 1

    # Déterminer la complexité des données
    if ($characteristics.IsNormal -and -not $characteristics.HasOutliers -and -not $characteristics.IsMultimodal) {
        $characteristics.Complexity = "Low"
    } elseif ($characteristics.IsMultimodal -or ($characteristics.HasOutliers -and $characteristics.OutlierPercentage -gt 5)) {
        $characteristics.Complexity = "High"
    } else {
        $characteristics.Complexity = "Medium"
    }

    # Recommander un noyau en fonction des caractéristiques
    if ($characteristics.IsNormal) {
        $characteristics.RecommendedKernel = "Gaussian"
    } elseif ($characteristics.IsMultimodal) {
        $characteristics.RecommendedKernel = "Epanechnikov"
    } elseif ($characteristics.IsSkewed) {
        $characteristics.RecommendedKernel = "Biweight"
    } elseif ($characteristics.HasOutliers) {
        $characteristics.RecommendedKernel = "Triweight"
    } else {
        $characteristics.RecommendedKernel = "Gaussian"
    }

    # Afficher les caractéristiques si verbose
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Verbose "Caractéristiques des données:"
        Write-Verbose "- Taille de l'échantillon: $($characteristics.SampleSize)"
        Write-Verbose "- Moyenne: $($characteristics.Mean)"
        Write-Verbose "- Médiane: $($characteristics.Median)"
        Write-Verbose "- Écart-type: $($characteristics.StdDev)"
        Write-Verbose "- Minimum: $($characteristics.Min)"
        Write-Verbose "- Maximum: $($characteristics.Max)"
        Write-Verbose "- Étendue: $($characteristics.Range)"
        Write-Verbose "- IQR: $($characteristics.IQR)"
        Write-Verbose "- Asymétrie: $($characteristics.Skewness)"
        Write-Verbose "- Aplatissement: $($characteristics.Kurtosis)"
        Write-Verbose "- Distribution normale: $($characteristics.IsNormal)"
        Write-Verbose "- Distribution asymétrique: $($characteristics.IsSkewed)"
        Write-Verbose "- Distribution multimodale: $($characteristics.IsMultimodal)"
        Write-Verbose "- Présence de valeurs aberrantes: $($characteristics.HasOutliers)"
        Write-Verbose "- Nombre de valeurs aberrantes: $($characteristics.OutlierCount)"
        Write-Verbose "- Pourcentage de valeurs aberrantes: $($characteristics.OutlierPercentage)%"
        Write-Verbose "- Modes: $($characteristics.Modes -join ', ')"
        Write-Verbose "- Nombre de modes: $($characteristics.ModeCount)"
        Write-Verbose "- Complexité: $($characteristics.Complexity)"
        Write-Verbose "- Noyau recommandé: $($characteristics.RecommendedKernel)"
    }

    return $characteristics
}

<#
.SYNOPSIS
    Sélectionne automatiquement le noyau optimal pour l'estimation de densité par noyau.

.DESCRIPTION
    Cette fonction sélectionne automatiquement le noyau optimal pour l'estimation de densité par noyau
    en fonction des caractéristiques des données et des objectifs d'analyse.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Objective
    L'objectif de l'analyse (par défaut "Balance").
    - "Precision": Privilégie la précision de l'estimation (favorise le noyau d'Epanechnikov)
    - "Smoothness": Privilégie le lissage de l'estimation (favorise le noyau gaussien)
    - "Speed": Privilégie la vitesse de calcul (favorise le noyau triangulaire)
    - "Balance": Équilibre entre précision, lissage et vitesse

.PARAMETER DataCharacteristics
    Les caractéristiques des données (par défaut $null, détectées automatiquement).
    - "Normal": Distribution normale
    - "Skewed": Distribution asymétrique
    - "Multimodal": Distribution multimodale
    - "HeavyTailed": Distribution à queue lourde
    - "Sparse": Données éparses

.EXAMPLE
    Get-OptimalKernel -Data $data
    Sélectionne automatiquement le noyau optimal en fonction des caractéristiques des données.

.EXAMPLE
    Get-OptimalKernel -Data $data -Objective "Precision"
    Sélectionne le noyau optimal en privilégiant la précision de l'estimation.

.OUTPUTS
    System.String
#>
function Get-OptimalKernel {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Precision", "Smoothness", "Speed", "Balance")]
        [string]$Objective = "Balance",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Skewed", "Multimodal", "HeavyTailed", "Sparse", $null)]
        [string]$DataCharacteristics = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour sélectionner le noyau optimal."
    }

    # Si les caractéristiques des données ne sont pas spécifiées, les détecter automatiquement
    if ($null -eq $DataCharacteristics) {
        $characteristics = Get-DataCharacteristics -Data $Data
        
        if ($characteristics.IsNormal) {
            $DataCharacteristics = "Normal"
        } elseif ($characteristics.IsSkewed) {
            $DataCharacteristics = "Skewed"
        } elseif ($characteristics.IsMultimodal) {
            $DataCharacteristics = "Multimodal"
        } elseif ($characteristics.Kurtosis -gt 1.0) {
            $DataCharacteristics = "HeavyTailed"
        } elseif ($Data.Count -lt 30) {
            $DataCharacteristics = "Sparse"
        } else {
            $DataCharacteristics = "Normal"
        }
    }

    # Sélectionner le noyau optimal en fonction des caractéristiques des données et de l'objectif
    switch ($Objective) {
        "Precision" {
            switch ($DataCharacteristics) {
                "Normal" { return "Epanechnikov" }
                "Skewed" { return "Biweight" }
                "Multimodal" { return "Epanechnikov" }
                "HeavyTailed" { return "Triweight" }
                "Sparse" { return "Gaussian" }
                default { return "Epanechnikov" }
            }
        }
        "Smoothness" {
            switch ($DataCharacteristics) {
                "Normal" { return "Gaussian" }
                "Skewed" { return "Cosine" }
                "Multimodal" { return "Gaussian" }
                "HeavyTailed" { return "Triweight" }
                "Sparse" { return "Gaussian" }
                default { return "Gaussian" }
            }
        }
        "Speed" {
            switch ($DataCharacteristics) {
                "Normal" { return "Triangular" }
                "Skewed" { return "Triangular" }
                "Multimodal" { return "Uniform" }
                "HeavyTailed" { return "Triangular" }
                "Sparse" { return "Uniform" }
                default { return "Triangular" }
            }
        }
        "Balance" {
            switch ($DataCharacteristics) {
                "Normal" { return "Gaussian" }
                "Skewed" { return "Biweight" }
                "Multimodal" { return "Epanechnikov" }
                "HeavyTailed" { return "Triweight" }
                "Sparse" { return "Cosine" }
                default { return "Gaussian" }
            }
        }
        default {
            return "Gaussian"
        }
    }
}
