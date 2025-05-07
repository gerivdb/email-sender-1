# Module pour l'estimation de densité par noyau (KDE)
# Ce module contient des fonctions pour l'estimation de densité par noyau (KDE)
# et l'analyse des queues de distribution.

<#
.SYNOPSIS
    Implémente le noyau gaussien pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction implémente le noyau gaussien (normal) pour l'estimation de densité par noyau (KDE).
    Le noyau gaussien est défini par K(u) = (1/√(2π)) * exp(-u²/2).

.PARAMETER U
    La valeur normalisée (x-x_i)/h où x est le point d'évaluation, x_i est un point de données
    et h est la largeur de bande.

.EXAMPLE
    Get-GaussianKernel -U 0
    Retourne la valeur du noyau gaussien au point central (0.3989).

.EXAMPLE
    Get-GaussianKernel -U 1.5
    Retourne la valeur du noyau gaussien à 1.5 écarts-types du centre.

.OUTPUTS
    System.Double
#>
function Get-GaussianKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$U
    )

    # Noyau gaussien: K(u) = (1/√(2π)) * exp(-u²/2)
    $result = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp( - ($U * $U) / 2)
    return $result
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau gaussien.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau gaussien.
    La formule est: f(x) = (1/nh) * Σ K((x-x_i)/h) où K est le noyau gaussien, n est le nombre de points,
    h est la largeur de bande, et x_i sont les points de données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman.

.EXAMPLE
    Get-GaussianKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau gaussien
    avec une largeur de bande optimale.

.EXAMPLE
    Get-GaussianKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau gaussien
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-GaussianKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Si la largeur de bande n'est pas spécifiée, calculer une largeur de bande optimale
    # en utilisant la règle de Silverman: h = 0.9 * min(σ, IQR/1.34) * n^(-1/5)
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'IQR (écart interquartile)
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1

        # Calculer la largeur de bande optimale
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        if ($minValue -le 0) {
            $minValue = $stdDev  # Fallback si IQR est trop petit
        }
        $Bandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)
    }

    # Calculer la densité en utilisant l'estimation de densité par noyau gaussien
    $n = $Data.Count
    $sum = 0
    foreach ($xi in $Data) {
        $u = ($X - $xi) / $Bandwidth
        $sum += Get-GaussianKernel -U $u
    }
    $density = $sum / ($n * $Bandwidth)

    return $density
}

<#
.SYNOPSIS
    Implémente le noyau d'Epanechnikov pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction implémente le noyau d'Epanechnikov pour l'estimation de densité par noyau (KDE).
    Le noyau d'Epanechnikov est défini par K(u) = (3/4) * (1 - u²) pour |u| ≤ 1, 0 sinon.
    Ce noyau est considéré comme optimal en termes de minimisation de l'erreur quadratique moyenne.

.PARAMETER U
    La valeur normalisée (x-x_i)/h où x est le point d'évaluation, x_i est un point de données
    et h est la largeur de bande.

.EXAMPLE
    Get-EpanechnikovKernel -U 0
    Retourne la valeur du noyau d'Epanechnikov au point central (0.75).

.EXAMPLE
    Get-EpanechnikovKernel -U 0.5
    Retourne la valeur du noyau d'Epanechnikov à mi-chemin entre le centre et la limite.

.OUTPUTS
    System.Double
#>
function Get-EpanechnikovKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$U
    )

    # Noyau d'Epanechnikov: K(u) = (3/4) * (1 - u²) pour |u| ≤ 1, 0 sinon
    if ([Math]::Abs($U) -le 1) {
        $result = 0.75 * (1 - ($U * $U))
        return $result
    } else {
        return 0
    }
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau d'Epanechnikov.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau d'Epanechnikov.
    La formule est: f(x) = (1/nh) * Σ K((x-x_i)/h) où K est le noyau d'Epanechnikov, n est le nombre de points,
    h est la largeur de bande, et x_i sont les points de données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau d'Epanechnikov.

.EXAMPLE
    Get-EpanechnikovKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau d'Epanechnikov
    avec une largeur de bande optimale.

.EXAMPLE
    Get-EpanechnikovKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau d'Epanechnikov
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-EpanechnikovKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Si la largeur de bande n'est pas spécifiée, calculer une largeur de bande optimale
    # en utilisant la règle de Silverman ajustée pour le noyau d'Epanechnikov
    # Le facteur d'ajustement est environ 1.05 par rapport au noyau gaussien
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'IQR (écart interquartile)
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1

        # Calculer la largeur de bande optimale avec ajustement pour le noyau d'Epanechnikov
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        if ($minValue -le 0) {
            $minValue = $stdDev  # Fallback si IQR est trop petit
        }
        $Bandwidth = 1.05 * 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)
    }

    # Calculer la densité en utilisant l'estimation de densité par noyau d'Epanechnikov
    $n = $Data.Count
    $sum = 0
    foreach ($xi in $Data) {
        $u = ($X - $xi) / $Bandwidth
        $sum += Get-EpanechnikovKernel -U $u
    }
    $density = $sum / ($n * $Bandwidth)

    return $density
}

<#
.SYNOPSIS
    Implémente le noyau triangulaire pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction implémente le noyau triangulaire pour l'estimation de densité par noyau (KDE).
    Le noyau triangulaire est défini par K(u) = (1 - |u|) pour |u| ≤ 1, 0 sinon.
    Ce noyau est simple à calculer et offre un bon compromis entre efficacité et précision.

.PARAMETER U
    La valeur normalisée (x-x_i)/h où x est le point d'évaluation, x_i est un point de données
    et h est la largeur de bande.

.EXAMPLE
    Get-TriangularKernel -U 0
    Retourne la valeur du noyau triangulaire au point central (1.0).

.EXAMPLE
    Get-TriangularKernel -U 0.5
    Retourne la valeur du noyau triangulaire à mi-chemin entre le centre et la limite.

.OUTPUTS
    System.Double
#>
function Get-TriangularKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$U
    )

    # Noyau triangulaire: K(u) = (1 - |u|) pour |u| ≤ 1, 0 sinon
    $absU = [Math]::Abs($U)
    if ($absU -le 1) {
        return 1 - $absU
    } else {
        return 0
    }
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau triangulaire.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau triangulaire.
    La formule est: f(x) = (1/nh) * Σ K((x-x_i)/h) où K est le noyau triangulaire, n est le nombre de points,
    h est la largeur de bande, et x_i sont les points de données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau triangulaire.

.EXAMPLE
    Get-TriangularKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triangulaire
    avec une largeur de bande optimale.

.EXAMPLE
    Get-TriangularKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triangulaire
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-TriangularKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Si la largeur de bande n'est pas spécifiée, calculer une largeur de bande optimale
    # en utilisant la règle de Silverman ajustée pour le noyau triangulaire
    # Le facteur d'ajustement est environ 1.1 par rapport au noyau gaussien
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'IQR (écart interquartile)
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1

        # Calculer la largeur de bande optimale avec ajustement pour le noyau triangulaire
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        if ($minValue -le 0) {
            $minValue = $stdDev  # Fallback si IQR est trop petit
        }
        $Bandwidth = 1.1 * 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)
    }

    # Calculer la densité en utilisant l'estimation de densité par noyau triangulaire
    $n = $Data.Count
    $sum = 0
    foreach ($xi in $Data) {
        $u = ($X - $xi) / $Bandwidth
        $sum += Get-TriangularKernel -U $u
    }
    $density = $sum / ($n * $Bandwidth)

    return $density
}

<#
.SYNOPSIS
    Sélectionne automatiquement le noyau optimal pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction sélectionne automatiquement le noyau optimal pour l'estimation de densité par noyau (KDE)
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
        # Calculer les statistiques de base
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Calculer le coefficient d'asymétrie (skewness)
        $skewness = 0
        $n = $Data.Count
        if ($n -gt 2) {
            $sumCubed = 0
            foreach ($value in $Data) {
                $sumCubed += [Math]::Pow(($value - $mean) / $stdDev, 3)
            }
            $skewness = $n * $sumCubed / (($n - 1) * ($n - 2))
        }

        # Calculer le coefficient d'aplatissement (kurtosis)
        $kurtosis = 0
        if ($n -gt 3) {
            $sumPow4 = 0
            foreach ($value in $Data) {
                $sumPow4 += [Math]::Pow(($value - $mean) / $stdDev, 4)
            }
            $kurtosis = $n * ($n + 1) * $sumPow4 / (($n - 1) * ($n - 2) * ($n - 3)) - 3 * [Math]::Pow($n - 1, 2) / (($n - 2) * ($n - 3))
        }

        # Détecter les caractéristiques des données
        if ([Math]::Abs($skewness) -gt 1.0) {
            $DataCharacteristics = "Skewed"
        } elseif ($kurtosis -gt 4.0) {
            $DataCharacteristics = "HeavyTailed"
        } elseif ($n -lt 30) {
            $DataCharacteristics = "Sparse"
        } else {
            $DataCharacteristics = "Normal"
        }
    }

    # Sélectionner le noyau optimal en fonction des caractéristiques des données et de l'objectif
    $kernelScores = @{
        "Gaussian"     = 0
        "Epanechnikov" = 0
        "Triangular"   = 0
    }

    # Scores de base pour chaque noyau
    # Le noyau d'Epanechnikov est optimal en termes de minimisation de l'erreur quadratique moyenne
    # Le noyau gaussien offre le meilleur lissage
    # Le noyau triangulaire est le plus rapide à calculer
    switch ($Objective) {
        "Precision" {
            $kernelScores["Gaussian"] = 7
            $kernelScores["Epanechnikov"] = 10
            $kernelScores["Triangular"] = 6
        }
        "Smoothness" {
            $kernelScores["Gaussian"] = 10
            $kernelScores["Epanechnikov"] = 7
            $kernelScores["Triangular"] = 5
        }
        "Speed" {
            $kernelScores["Gaussian"] = 5
            $kernelScores["Epanechnikov"] = 7
            $kernelScores["Triangular"] = 10
        }
        "Balance" {
            $kernelScores["Gaussian"] = 8
            $kernelScores["Epanechnikov"] = 9
            $kernelScores["Triangular"] = 7
        }
    }

    # Ajuster les scores en fonction des caractéristiques des données
    switch ($DataCharacteristics) {
        "Normal" {
            $kernelScores["Gaussian"] += 2
            $kernelScores["Epanechnikov"] += 1
            $kernelScores["Triangular"] += 0
        }
        "Skewed" {
            $kernelScores["Gaussian"] += 0
            $kernelScores["Epanechnikov"] += 2
            $kernelScores["Triangular"] += 1
        }
        "Multimodal" {
            $kernelScores["Gaussian"] += 1
            $kernelScores["Epanechnikov"] += 2
            $kernelScores["Triangular"] += 0
        }
        "HeavyTailed" {
            $kernelScores["Gaussian"] += 0
            $kernelScores["Epanechnikov"] += 2
            $kernelScores["Triangular"] += 1
        }
        "Sparse" {
            $kernelScores["Gaussian"] += 2
            $kernelScores["Epanechnikov"] += 0
            $kernelScores["Triangular"] += 1
        }
    }

    # Sélectionner le noyau avec le score le plus élevé
    $optimalKernel = $kernelScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1 -ExpandProperty Name

    return $optimalKernel
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau optimal.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau optimal.
    Le noyau optimal est sélectionné automatiquement en fonction des caractéristiques des données et de l'objectif.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en fonction du noyau sélectionné.

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
    Get-OptimalKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau optimal.

.EXAMPLE
    Get-OptimalKernelDensity -X 10 -Data $data -Objective "Precision"
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau optimal
    en privilégiant la précision de l'estimation.

.OUTPUTS
    System.Double
#>
function Get-OptimalKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Precision", "Smoothness", "Speed", "Balance")]
        [string]$Objective = "Balance",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Skewed", "Multimodal", "HeavyTailed", "Sparse", $null)]
        [string]$DataCharacteristics = $null
    )

    # Sélectionner le noyau optimal
    $optimalKernel = Get-OptimalKernel -Data $Data -Objective $Objective -DataCharacteristics $DataCharacteristics

    # Calculer la densité en utilisant le noyau optimal
    switch ($optimalKernel) {
        "Gaussian" {
            return Get-GaussianKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Epanechnikov" {
            return Get-EpanechnikovKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
        "Triangular" {
            return Get-TriangularKernelDensity -X $X -Data $Data -Bandwidth $Bandwidth
        }
    }
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale en utilisant la règle de Silverman.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation de densité par noyau (KDE)
    en utilisant la règle de Silverman. Cette règle est basée sur l'hypothèse que les données suivent
    approximativement une distribution normale.

    La formule de base est: h = 0.9 * min(σ, IQR/1.34) * n^(-1/5)
    où σ est l'écart-type, IQR est l'écart interquartile, et n est le nombre de points.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER DistributionType
    Le type de distribution des données (par défaut $null, détecté automatiquement).
    - "Normal": Distribution normale
    - "Skewed": Distribution asymétrique
    - "HeavyTailed": Distribution à queue lourde
    - "Multimodal": Distribution multimodale
    - "Sparse": Données éparses

.EXAMPLE
    Get-SilvermanBandwidth -Data $data
    Calcule la largeur de bande optimale en utilisant la règle de Silverman avec le noyau gaussien.

.EXAMPLE
    Get-SilvermanBandwidth -Data $data -KernelType "Epanechnikov" -DistributionType "Skewed"
    Calcule la largeur de bande optimale en utilisant la règle de Silverman avec le noyau d'Epanechnikov
    pour une distribution asymétrique.

.OUTPUTS
    System.Double
#>
function Get-SilvermanBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Skewed", "HeavyTailed", "Multimodal", "Sparse", "")]
        [string]$DistributionType = ""
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer la largeur de bande optimale."
    }

    # Si le type de distribution n'est pas spécifié, le détecter automatiquement
    if ([string]::IsNullOrEmpty($DistributionType)) {
        # Calculer les statistiques de base
        $mean = ($Data | Measure-Object -Average).Average
        $sortedData = $Data | Sort-Object
        $n = $Data.Count

        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Calculer le coefficient d'asymétrie (skewness)
        $skewness = 0
        if ($n -gt 2 -and $stdDev -gt 0) {
            $sumCubed = 0
            foreach ($value in $Data) {
                $sumCubed += [Math]::Pow(($value - $mean) / $stdDev, 3)
            }
            $skewness = $n * $sumCubed / (($n - 1) * ($n - 2))
        }

        # Calculer le coefficient d'aplatissement (kurtosis)
        $kurtosis = 0
        if ($n -gt 3 -and $stdDev -gt 0) {
            $sumPow4 = 0
            foreach ($value in $Data) {
                $sumPow4 += [Math]::Pow(($value - $mean) / $stdDev, 4)
            }
            $kurtosis = $n * ($n + 1) * $sumPow4 / (($n - 1) * ($n - 2) * ($n - 3)) - 3 * [Math]::Pow($n - 1, 2) / (($n - 2) * ($n - 3))
        }

        # Détecter le type de distribution
        if ($n -lt 30) {
            $DistributionType = "Sparse"
        } elseif ([Math]::Abs($skewness) -gt 1.0) {
            $DistributionType = "Skewed"
        } elseif ($kurtosis -gt 4.0) {
            $DistributionType = "HeavyTailed"
        } else {
            $DistributionType = "Normal"
        }

        Write-Verbose "Type de distribution détecté: $DistributionType (skewness: $([Math]::Round($skewness, 2)), kurtosis: $([Math]::Round($kurtosis, 2)), n: $n)"
    }

    # Calculer l'écart-type
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

    # Calculer l'IQR (écart interquartile)
    $sortedData = $Data | Sort-Object
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $iqr = $q3 - $q1

    # Calculer la largeur de bande optimale de base
    $minValue = [Math]::Min($stdDev, $iqr / 1.34)
    if ($minValue -le 0) {
        $minValue = $stdDev  # Fallback si IQR est trop petit
    }
    $bandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)

    # Appliquer des facteurs de correction en fonction du type de noyau
    switch ($KernelType) {
        "Gaussian" {
            # Le noyau gaussien est le noyau de référence, pas de correction nécessaire
            $kernelFactor = 1.0
        }
        "Epanechnikov" {
            # Le noyau d'Epanechnikov est plus efficace que le noyau gaussien
            $kernelFactor = 1.05
        }
        "Triangular" {
            # Le noyau triangulaire est moins efficace que le noyau gaussien
            $kernelFactor = 1.1
        }
    }
    $bandwidth *= $kernelFactor

    # Appliquer des ajustements en fonction du type de distribution
    switch ($DistributionType) {
        "Normal" {
            # La règle de Silverman est optimale pour les distributions normales
            $distributionFactor = 1.0
        }
        "Skewed" {
            # Pour les distributions asymétriques, augmenter légèrement la largeur de bande
            $distributionFactor = 1.1
        }
        "HeavyTailed" {
            # Pour les distributions à queue lourde, augmenter davantage la largeur de bande
            $distributionFactor = 1.2
        }
        "Multimodal" {
            # Pour les distributions multimodales, réduire la largeur de bande
            $distributionFactor = 0.8
        }
        "Sparse" {
            # Pour les petits échantillons, augmenter la largeur de bande
            $distributionFactor = 1.2
        }
    }
    $bandwidth *= $distributionFactor

    return $bandwidth
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale en utilisant la méthode de Scott.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation de densité par noyau (KDE)
    en utilisant la méthode de Scott. Cette méthode est basée sur l'hypothèse que les données suivent
    approximativement une distribution normale.

    La formule de base est: h = 1.06 * σ * n^(-1/5)
    où σ est l'écart-type et n est le nombre de points.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER DistributionType
    Le type de distribution des données (par défaut "", détecté automatiquement).
    - "Normal": Distribution normale
    - "Skewed": Distribution asymétrique
    - "HeavyTailed": Distribution à queue lourde
    - "Multimodal": Distribution multimodale
    - "Sparse": Données éparses

.EXAMPLE
    Get-ScottBandwidth -Data $data
    Calcule la largeur de bande optimale en utilisant la méthode de Scott avec le noyau gaussien.

.EXAMPLE
    Get-ScottBandwidth -Data $data -KernelType "Epanechnikov" -DistributionType "Skewed"
    Calcule la largeur de bande optimale en utilisant la méthode de Scott avec le noyau d'Epanechnikov
    pour une distribution asymétrique.

.OUTPUTS
    System.Double
#>
function Get-ScottBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Skewed", "HeavyTailed", "Multimodal", "Sparse", "")]
        [string]$DistributionType = ""
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer la largeur de bande optimale."
    }

    # Si le type de distribution n'est pas spécifié, le détecter automatiquement
    if ([string]::IsNullOrEmpty($DistributionType)) {
        # Calculer les statistiques de base
        $mean = ($Data | Measure-Object -Average).Average
        $n = $Data.Count

        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Calculer le coefficient d'asymétrie (skewness)
        $skewness = 0
        if ($n -gt 2 -and $stdDev -gt 0) {
            $sumCubed = 0
            foreach ($value in $Data) {
                $sumCubed += [Math]::Pow(($value - $mean) / $stdDev, 3)
            }
            $skewness = $n * $sumCubed / (($n - 1) * ($n - 2))
        }

        # Calculer le coefficient d'aplatissement (kurtosis)
        $kurtosis = 0
        if ($n -gt 3 -and $stdDev -gt 0) {
            $sumPow4 = 0
            foreach ($value in $Data) {
                $sumPow4 += [Math]::Pow(($value - $mean) / $stdDev, 4)
            }
            $kurtosis = $n * ($n + 1) * $sumPow4 / (($n - 1) * ($n - 2) * ($n - 3)) - 3 * [Math]::Pow($n - 1, 2) / (($n - 2) * ($n - 3))
        }

        # Détecter le type de distribution
        if ($n -lt 30) {
            $DistributionType = "Sparse"
        } elseif ([Math]::Abs($skewness) -gt 1.0) {
            $DistributionType = "Skewed"
        } elseif ($kurtosis -gt 4.0) {
            $DistributionType = "HeavyTailed"
        } else {
            $DistributionType = "Normal"
        }

        Write-Verbose "Type de distribution détecté: $DistributionType (skewness: $([Math]::Round($skewness, 2)), kurtosis: $([Math]::Round($kurtosis, 2)), n: $n)"
    }

    # Calculer l'écart-type
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

    # Calculer la largeur de bande optimale de base selon la méthode de Scott
    # h = 1.06 * σ * n^(-1/5)
    $bandwidth = 1.06 * $stdDev * [Math]::Pow($Data.Count, -0.2)

    # Appliquer des facteurs de correction en fonction du type de noyau
    switch ($KernelType) {
        "Gaussian" {
            # Le noyau gaussien est le noyau de référence, pas de correction nécessaire
            $kernelFactor = 1.0
        }
        "Epanechnikov" {
            # Le noyau d'Epanechnikov est plus efficace que le noyau gaussien
            $kernelFactor = 1.05
        }
        "Triangular" {
            # Le noyau triangulaire est moins efficace que le noyau gaussien
            $kernelFactor = 1.1
        }
    }
    $bandwidth *= $kernelFactor

    # Appliquer des ajustements en fonction du type de distribution
    switch ($DistributionType) {
        "Normal" {
            # La méthode de Scott est optimale pour les distributions normales
            $distributionFactor = 1.0
        }
        "Skewed" {
            # Pour les distributions asymétriques, augmenter légèrement la largeur de bande
            $distributionFactor = 1.1
        }
        "HeavyTailed" {
            # Pour les distributions à queue lourde, augmenter davantage la largeur de bande
            $distributionFactor = 1.2
        }
        "Multimodal" {
            # Pour les distributions multimodales, réduire la largeur de bande
            $distributionFactor = 0.8
        }
        "Sparse" {
            # Pour les petits échantillons, augmenter la largeur de bande
            $distributionFactor = 1.2
        }
    }
    $bandwidth *= $distributionFactor

    return $bandwidth
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale en utilisant la validation croisée par leave-one-out.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation de densité par noyau (KDE)
    en utilisant la validation croisée par leave-one-out. Cette méthode est basée sur la minimisation
    de l'erreur de prédiction en excluant chaque point à tour de rôle.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER BandwidthRange
    La plage de largeurs de bande à tester (par défaut $null, calculée automatiquement).
    Format: @(min, max, step)

.PARAMETER MaxIterations
    Le nombre maximum d'itérations pour l'optimisation (par défaut 100).

.EXAMPLE
    Get-LeaveOneOutCVBandwidth -Data $data
    Calcule la largeur de bande optimale en utilisant la validation croisée par leave-one-out avec le noyau gaussien.

.EXAMPLE
    Get-LeaveOneOutCVBandwidth -Data $data -KernelType "Epanechnikov" -BandwidthRange @(0.1, 10, 0.1)
    Calcule la largeur de bande optimale en utilisant la validation croisée par leave-one-out avec le noyau d'Epanechnikov
    et une plage de largeurs de bande de 0.1 à 10 avec un pas de 0.1.

.OUTPUTS
    System.Double
#>
function Get-LeaveOneOutCVBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [double[]]$BandwidthRange = $null,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 100
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour la validation croisée par leave-one-out."
    }

    # Si la plage de largeurs de bande n'est pas spécifiée, la calculer automatiquement
    if ($null -eq $BandwidthRange) {
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'IQR (écart interquartile)
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1

        # Calculer la largeur de bande de référence (règle de Silverman)
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        if ($minValue -le 0) {
            $minValue = $stdDev  # Fallback si IQR est trop petit
        }
        $referenceBandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)

        # Définir la plage de largeurs de bande à tester (de 0.1 à 2 fois la largeur de bande de référence)
        $minBandwidth = $referenceBandwidth * 0.1
        $maxBandwidth = $referenceBandwidth * 2
        $step = ($maxBandwidth - $minBandwidth) / 20  # 20 pas
        $BandwidthRange = @($minBandwidth, $maxBandwidth, $step)

        Write-Verbose "Plage de largeurs de bande calculée automatiquement: [$minBandwidth, $maxBandwidth] avec un pas de $step"
    }

    # Fonction pour calculer la densité en un point en utilisant l'estimation de densité par noyau
    function Get-KernelDensity {
        param (
            [double]$X,
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel
        )

        $n = $DataPoints.Count
        $sum = 0

        foreach ($xi in $DataPoints) {
            $u = ($X - $xi) / $Bandwidth

            switch ($Kernel) {
                "Gaussian" {
                    $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp( - ($u * $u) / 2)
                }
                "Epanechnikov" {
                    if ([Math]::Abs($u) -le 1) {
                        $kernelValue = 0.75 * (1 - ($u * $u))
                    } else {
                        $kernelValue = 0
                    }
                }
                "Triangular" {
                    $absU = [Math]::Abs($u)
                    if ($absU -le 1) {
                        $kernelValue = 1 - $absU
                    } else {
                        $kernelValue = 0
                    }
                }
            }

            $sum += $kernelValue
        }

        $density = $sum / ($n * $Bandwidth)
        return $density
    }

    # Fonction pour calculer l'erreur de validation croisée par leave-one-out
    function Get-LeaveOneOutCVError {
        param (
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel
        )

        $n = $DataPoints.Count
        $cvError = 0

        for ($i = 0; $i -lt $n; $i++) {
            # Exclure le point i
            $trainingData = @()
            for ($j = 0; $j -lt $n; $j++) {
                if ($j -ne $i) {
                    $trainingData += $DataPoints[$j]
                }
            }

            # Calculer la densité au point i en utilisant les données d'entraînement
            $density = Get-KernelDensity -X $DataPoints[$i] -DataPoints $trainingData -Bandwidth $Bandwidth -Kernel $Kernel

            # Calculer l'erreur quadratique
            $cvError += [Math]::Pow(1 - $density, 2)
        }

        $cvError = $cvError / $n
        return $cvError
    }

    # Recherche de la largeur de bande optimale par grid search
    $minBandwidth = $BandwidthRange[0]
    $maxBandwidth = $BandwidthRange[1]
    $step = $BandwidthRange[2]

    $bestBandwidth = $minBandwidth
    $minError = [double]::MaxValue

    $bandwidth = $minBandwidth
    $iteration = 0

    while ($bandwidth -le $maxBandwidth -and $iteration -lt $MaxIterations) {
        $cvError = Get-LeaveOneOutCVError -DataPoints $Data -Bandwidth $bandwidth -Kernel $KernelType

        if ($cvError -lt $minError) {
            $minError = $cvError
            $bestBandwidth = $bandwidth
        }

        $bandwidth += $step
        $iteration++

        Write-Verbose "Iteration $iteration - Bandwidth = $bandwidth - Error = $cvError"
    }

    Write-Verbose "Optimal bandwidth found: $bestBandwidth with error = $minError"

    return $bestBandwidth
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale en utilisant la validation croisée par k-fold.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation de densité par noyau (KDE)
    en utilisant la validation croisée par k-fold. Cette méthode divise les données en k sous-ensembles
    et utilise k-1 sous-ensembles pour l'entraînement et 1 sous-ensemble pour la validation.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER BandwidthRange
    La plage de largeurs de bande à tester (par défaut $null, calculée automatiquement).
    Format: @(min, max, step)

.PARAMETER K
    Le nombre de plis (folds) à utiliser pour la validation croisée (par défaut 5).

.PARAMETER MaxIterations
    Le nombre maximum d'itérations pour l'optimisation (par défaut 100).

.EXAMPLE
    Get-KFoldCVBandwidth -Data $data
    Calcule la largeur de bande optimale en utilisant la validation croisée par k-fold avec le noyau gaussien.

.EXAMPLE
    Get-KFoldCVBandwidth -Data $data -KernelType "Epanechnikov" -BandwidthRange @(0.1, 10, 0.1) -K 10
    Calcule la largeur de bande optimale en utilisant la validation croisée par k-fold avec le noyau d'Epanechnikov,
    une plage de largeurs de bande de 0.1 à 10 avec un pas de 0.1, et 10 plis.

.OUTPUTS
    System.Double
#>
function Get-KFoldCVBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [double[]]$BandwidthRange = $null,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$K = 5,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 100
    )

    # Vérifier que les données contiennent au moins K points
    if ($Data.Count -lt $K) {
        throw "Les données doivent contenir au moins $K points pour la validation croisée par $K-fold."
    }

    # Si la plage de largeurs de bande n'est pas spécifiée, la calculer automatiquement
    if ($null -eq $BandwidthRange) {
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'IQR (écart interquartile)
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1

        # Calculer la largeur de bande de référence (règle de Silverman)
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        if ($minValue -le 0) {
            $minValue = $stdDev  # Fallback si IQR est trop petit
        }
        $referenceBandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)

        # Définir la plage de largeurs de bande à tester (de 0.1 à 2 fois la largeur de bande de référence)
        $minBandwidth = $referenceBandwidth * 0.1
        $maxBandwidth = $referenceBandwidth * 2
        $step = ($maxBandwidth - $minBandwidth) / 20  # 20 pas
        $BandwidthRange = @($minBandwidth, $maxBandwidth, $step)

        Write-Verbose "Bandwidth range automatically calculated: [$minBandwidth, $maxBandwidth] with step $step"
    }

    # Fonction pour calculer la densité en un point en utilisant l'estimation de densité par noyau
    function Get-KernelDensity {
        param (
            [double]$X,
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel
        )

        $n = $DataPoints.Count
        $sum = 0

        foreach ($xi in $DataPoints) {
            $u = ($X - $xi) / $Bandwidth

            switch ($Kernel) {
                "Gaussian" {
                    $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp( - ($u * $u) / 2)
                }
                "Epanechnikov" {
                    if ([Math]::Abs($u) -le 1) {
                        $kernelValue = 0.75 * (1 - ($u * $u))
                    } else {
                        $kernelValue = 0
                    }
                }
                "Triangular" {
                    $absU = [Math]::Abs($u)
                    if ($absU -le 1) {
                        $kernelValue = 1 - $absU
                    } else {
                        $kernelValue = 0
                    }
                }
            }

            $sum += $kernelValue
        }

        $density = $sum / ($n * $Bandwidth)
        return $density
    }

    # Fonction pour diviser les données en K plis
    function Split-DataIntoFolds {
        param (
            [double[]]$DataPoints,
            [int]$NumFolds
        )

        # Mélanger les données
        $shuffledIndices = 0..($DataPoints.Count - 1) | Sort-Object { Get-Random }
        $shuffledData = @()
        foreach ($index in $shuffledIndices) {
            $shuffledData += $DataPoints[$index]
        }

        # Diviser les données en K plis
        $folds = @()
        $foldSize = [Math]::Floor($shuffledData.Count / $NumFolds)
        $remainder = $shuffledData.Count % $NumFolds

        $startIndex = 0
        for ($i = 0; $i -lt $NumFolds; $i++) {
            $currentFoldSize = $foldSize
            if ($i -lt $remainder) {
                $currentFoldSize++
            }

            $fold = @()
            for ($j = 0; $j -lt $currentFoldSize; $j++) {
                $fold += $shuffledData[$startIndex + $j]
            }

            $folds += , $fold
            $startIndex += $currentFoldSize
        }

        return $folds
    }

    # Fonction pour calculer l'erreur de validation croisée par k-fold
    function Get-KFoldCVError {
        param (
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel,
            [int]$NumFolds
        )

        # Diviser les données en K plis
        $folds = Split-DataIntoFolds -DataPoints $DataPoints -NumFolds $NumFolds

        $totalError = 0

        # Pour chaque pli
        for ($i = 0; $i -lt $NumFolds; $i++) {
            # Utiliser le pli i comme ensemble de validation
            $validationSet = $folds[$i]

            # Utiliser les autres plis comme ensemble d'entraînement
            $trainingSet = @()
            for ($j = 0; $j -lt $NumFolds; $j++) {
                if ($j -ne $i) {
                    $trainingSet += $folds[$j]
                }
            }

            # Calculer l'erreur sur l'ensemble de validation
            $foldError = 0
            foreach ($point in $validationSet) {
                $density = Get-KernelDensity -X $point -DataPoints $trainingSet -Bandwidth $Bandwidth -Kernel $Kernel
                $foldError += [Math]::Pow(1 - $density, 2)
            }

            $foldError = $foldError / $validationSet.Count
            $totalError += $foldError
        }

        $avgError = $totalError / $NumFolds
        return $avgError
    }

    # Recherche de la largeur de bande optimale par grid search
    $minBandwidth = $BandwidthRange[0]
    $maxBandwidth = $BandwidthRange[1]
    $step = $BandwidthRange[2]

    $bestBandwidth = $minBandwidth
    $minError = [double]::MaxValue

    $bandwidth = $minBandwidth
    $iteration = 0

    while ($bandwidth -le $maxBandwidth -and $iteration -lt $MaxIterations) {
        $cvError = Get-KFoldCVError -DataPoints $Data -Bandwidth $bandwidth -Kernel $KernelType -NumFolds $K

        if ($cvError -lt $minError) {
            $minError = $cvError
            $bestBandwidth = $bandwidth
        }

        $bandwidth += $step
        $iteration++

        Write-Verbose "Iteration $iteration - Bandwidth = $bandwidth - Error = $cvError"
    }

    Write-Verbose "Optimal bandwidth found: $bestBandwidth with error = $minError"

    return $bestBandwidth
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale en utilisant une méthode d'optimisation avancée.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation de densité par noyau (KDE)
    en utilisant une méthode d'optimisation avancée basée sur la recherche par section d'or.
    Cette méthode est plus efficace que la recherche par grille pour trouver la largeur de bande optimale.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER ValidationMethod
    La méthode de validation à utiliser (par défaut "KFold").
    - "LeaveOneOut": Validation croisée par leave-one-out
    - "KFold": Validation croisée par k-fold

.PARAMETER K
    Le nombre de plis (folds) à utiliser pour la validation croisée par k-fold (par défaut 5).
    Ignoré si ValidationMethod est "LeaveOneOut".

.PARAMETER Tolerance
    La tolérance pour la convergence de l'algorithme d'optimisation (par défaut 0.001).

.PARAMETER MaxIterations
    Le nombre maximum d'itérations pour l'optimisation (par défaut 100).

.EXAMPLE
    Get-OptimizedCVBandwidth -Data $data
    Calcule la largeur de bande optimale en utilisant la validation croisée par k-fold avec le noyau gaussien.

.EXAMPLE
    Get-OptimizedCVBandwidth -Data $data -KernelType "Epanechnikov" -ValidationMethod "LeaveOneOut" -Tolerance 0.0001
    Calcule la largeur de bande optimale en utilisant la validation croisée par leave-one-out avec le noyau d'Epanechnikov
    et une tolérance de 0.0001.

.OUTPUTS
    System.Double
#>
function Get-OptimizedCVBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("LeaveOneOut", "KFold")]
        [string]$ValidationMethod = "KFold",

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$K = 5,

        [Parameter(Mandatory = $false)]
        [double]$Tolerance = 0.001,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 100
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour l'optimisation de la largeur de bande."
    }

    # Calculer les limites initiales pour la recherche
    # Calculer l'écart-type
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

    # Calculer l'IQR (écart interquartile)
    $sortedData = $Data | Sort-Object
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $iqr = $q3 - $q1

    # Calculer la largeur de bande de référence (règle de Silverman)
    $minValue = [Math]::Min($stdDev, $iqr / 1.34)
    if ($minValue -le 0) {
        $minValue = $stdDev  # Fallback si IQR est trop petit
    }
    $referenceBandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)

    # Définir les limites pour la recherche (de 0.1 à 3 fois la largeur de bande de référence)
    $lowerBound = $referenceBandwidth * 0.1
    $upperBound = $referenceBandwidth * 3

    Write-Verbose "Initial search bounds: [$lowerBound, $upperBound]"

    # Fonction pour calculer l'erreur de validation croisée
    function Get-CVError {
        param (
            [double]$Bandwidth
        )

        if ($ValidationMethod -eq "LeaveOneOut") {
            # Utiliser la validation croisée par leave-one-out
            $cvError = Get-LeaveOneOutCVError -DataPoints $Data -Bandwidth $Bandwidth -Kernel $KernelType
        } else {
            # Utiliser la validation croisée par k-fold
            $cvError = Get-KFoldCVError -DataPoints $Data -Bandwidth $Bandwidth -Kernel $KernelType -NumFolds $K
        }

        return $cvError
    }

    # Fonction pour calculer l'erreur de validation croisée par leave-one-out
    function Get-LeaveOneOutCVError {
        param (
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel
        )

        $n = $DataPoints.Count
        $cvError = 0

        for ($i = 0; $i -lt $n; $i++) {
            # Exclure le point i
            $trainingData = @()
            for ($j = 0; $j -lt $n; $j++) {
                if ($j -ne $i) {
                    $trainingData += $DataPoints[$j]
                }
            }

            # Calculer la densité au point i en utilisant les données d'entraînement
            $density = Get-KernelDensity -X $DataPoints[$i] -DataPoints $trainingData -Bandwidth $Bandwidth -Kernel $Kernel

            # Calculer l'erreur quadratique
            $cvError += [Math]::Pow(1 - $density, 2)
        }

        $cvError = $cvError / $n
        return $cvError
    }

    # Fonction pour calculer l'erreur de validation croisée par k-fold
    function Get-KFoldCVError {
        param (
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel,
            [int]$NumFolds
        )

        # Diviser les données en K plis
        $folds = Split-DataIntoFolds -DataPoints $DataPoints -NumFolds $NumFolds

        $totalError = 0

        # Pour chaque pli
        for ($i = 0; $i -lt $NumFolds; $i++) {
            # Utiliser le pli i comme ensemble de validation
            $validationSet = $folds[$i]

            # Utiliser les autres plis comme ensemble d'entraînement
            $trainingSet = @()
            for ($j = 0; $j -lt $NumFolds; $j++) {
                if ($j -ne $i) {
                    $trainingSet += $folds[$j]
                }
            }

            # Calculer l'erreur sur l'ensemble de validation
            $foldError = 0
            foreach ($point in $validationSet) {
                $density = Get-KernelDensity -X $point -DataPoints $trainingSet -Bandwidth $Bandwidth -Kernel $Kernel
                $foldError += [Math]::Pow(1 - $density, 2)
            }

            $foldError = $foldError / $validationSet.Count
            $totalError += $foldError
        }

        $avgError = $totalError / $NumFolds
        return $avgError
    }

    # Fonction pour diviser les données en K plis
    function Split-DataIntoFolds {
        param (
            [double[]]$DataPoints,
            [int]$NumFolds
        )

        # Mélanger les données
        $shuffledIndices = 0..($DataPoints.Count - 1) | Sort-Object { Get-Random }
        $shuffledData = @()
        foreach ($index in $shuffledIndices) {
            $shuffledData += $DataPoints[$index]
        }

        # Diviser les données en K plis
        $folds = @()
        $foldSize = [Math]::Floor($shuffledData.Count / $NumFolds)
        $remainder = $shuffledData.Count % $NumFolds

        $startIndex = 0
        for ($i = 0; $i -lt $NumFolds; $i++) {
            $currentFoldSize = $foldSize
            if ($i -lt $remainder) {
                $currentFoldSize++
            }

            $fold = @()
            for ($j = 0; $j -lt $currentFoldSize; $j++) {
                $fold += $shuffledData[$startIndex + $j]
            }

            $folds += , $fold
            $startIndex += $currentFoldSize
        }

        return $folds
    }

    # Fonction pour calculer la densité en un point en utilisant l'estimation de densité par noyau
    function Get-KernelDensity {
        param (
            [double]$X,
            [double[]]$DataPoints,
            [double]$Bandwidth,
            [string]$Kernel
        )

        $n = $DataPoints.Count
        $sum = 0

        foreach ($xi in $DataPoints) {
            $u = ($X - $xi) / $Bandwidth

            switch ($Kernel) {
                "Gaussian" {
                    $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp( - ($u * $u) / 2)
                }
                "Epanechnikov" {
                    if ([Math]::Abs($u) -le 1) {
                        $kernelValue = 0.75 * (1 - ($u * $u))
                    } else {
                        $kernelValue = 0
                    }
                }
                "Triangular" {
                    $absU = [Math]::Abs($u)
                    if ($absU -le 1) {
                        $kernelValue = 1 - $absU
                    } else {
                        $kernelValue = 0
                    }
                }
            }

            $sum += $kernelValue
        }

        $density = $sum / ($n * $Bandwidth)
        return $density
    }

    # Algorithme de recherche par section d'or
    $goldenRatio = (1 + [Math]::Sqrt(5)) / 2

    $x1 = $lowerBound
    $x4 = $upperBound

    $x2 = $x4 - ($x4 - $x1) / $goldenRatio
    $x3 = $x1 + ($x4 - $x1) / $goldenRatio

    $f2 = Get-CVError -Bandwidth $x2
    $f3 = Get-CVError -Bandwidth $x3

    $iteration = 0

    while ([Math]::Abs($x4 - $x1) -gt $Tolerance -and $iteration -lt $MaxIterations) {
        $iteration++

        if ($f2 -lt $f3) {
            $x4 = $x3
            $x3 = $x2
            $f3 = $f2
            $x2 = $x4 - ($x4 - $x1) / $goldenRatio
            $f2 = Get-CVError -Bandwidth $x2
        } else {
            $x1 = $x2
            $x2 = $x3
            $f2 = $f3
            $x3 = $x1 + ($x4 - $x1) / $goldenRatio
            $f3 = Get-CVError -Bandwidth $x3
        }

        Write-Verbose "Iteration $iteration - Bounds: [$x1, $x4] - Error: $([Math]::Min($f2, $f3))"
    }

    # Retourner la meilleure largeur de bande trouvée
    $bestBandwidth = if ($f2 -lt $f3) { $x2 } else { $x3 }
    $minError = if ($f2 -lt $f3) { $f2 } else { $f3 }

    Write-Verbose "Optimal bandwidth found: $bestBandwidth with error = $minError after $iteration iterations"

    return $bestBandwidth
}

<#
.SYNOPSIS
    Évalue les performances des différentes méthodes de sélection de largeur de bande.

.DESCRIPTION
    Cette fonction évalue les performances des différentes méthodes de sélection de largeur de bande
    en utilisant plusieurs critères : précision, temps d'exécution, robustesse et adaptabilité.
    Elle retourne un score pour chaque méthode, ce qui permet de choisir la méthode la plus appropriée
    pour un ensemble de données donné.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER Methods
    Les méthodes à évaluer (par défaut toutes les méthodes disponibles).
    - "Silverman": Règle de Silverman
    - "Scott": Méthode de Scott
    - "LeaveOneOut": Validation croisée par leave-one-out
    - "KFold": Validation croisée par k-fold
    - "Optimized": Optimisation par validation croisée

.PARAMETER Criteria
    Les critères à utiliser pour l'évaluation (par défaut tous les critères).
    - "Accuracy": Précision de l'estimation
    - "Speed": Temps d'exécution
    - "Robustness": Robustesse face aux valeurs aberrantes
    - "Adaptability": Adaptabilité à différents types de distributions

.PARAMETER Weights
    Les poids à attribuer à chaque critère (par défaut tous les critères ont le même poids).
    Format: @{Accuracy = 1; Speed = 1; Robustness = 1; Adaptability = 1}

.EXAMPLE
    Get-BandwidthMethodScores -Data $data
    Évalue les performances de toutes les méthodes de sélection de largeur de bande sur les données fournies.

.EXAMPLE
    Get-BandwidthMethodScores -Data $data -KernelType "Epanechnikov" -Methods @("Silverman", "Scott") -Criteria @("Accuracy", "Speed") -Weights @{Accuracy = 2; Speed = 1}
    Évalue les performances des méthodes de Silverman et Scott avec le noyau d'Epanechnikov, en utilisant les critères de précision et de temps d'exécution,
    avec un poids double pour la précision.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-BandwidthMethodScores {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")]
        [string[]]$Methods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Accuracy", "Speed", "Robustness", "Adaptability")]
        [string[]]$Criteria = @("Accuracy", "Speed", "Robustness", "Adaptability"),

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            Accuracy     = 1
            Speed        = 1
            Robustness   = 1
            Adaptability = 1
        }
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour évaluer les méthodes de sélection de largeur de bande."
    }

    # Initialiser les scores
    $scores = @{}
    foreach ($method in $Methods) {
        $scores[$method] = @{
            Bandwidth     = 0
            ExecutionTime = 0
            Scores        = @{
                Accuracy     = 0
                Speed        = 0
                Robustness   = 0
                Adaptability = 0
            }
            TotalScore    = 0
        }
    }

    # Calculer les largeurs de bande et les temps d'exécution pour chaque méthode
    foreach ($method in $Methods) {
        $startTime = Get-Date

        switch ($method) {
            "Silverman" {
                $bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType
            }
            "Scott" {
                $bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType
            }
            "LeaveOneOut" {
                # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($Data.Count, -0.2)
                $minBandwidth = $referenceBandwidth * 0.5
                $maxBandwidth = $referenceBandwidth * 2
                $step = ($maxBandwidth - $minBandwidth) / 10

                $bandwidth = Get-LeaveOneOutCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -MaxIterations 10
            }
            "KFold" {
                # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($Data.Count, -0.2)
                $minBandwidth = $referenceBandwidth * 0.5
                $maxBandwidth = $referenceBandwidth * 2
                $step = ($maxBandwidth - $minBandwidth) / 10

                $bandwidth = Get-KFoldCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -K 5 -MaxIterations 10
            }
            "Optimized" {
                $bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "KFold" -K 5 -MaxIterations 10 -Tolerance 0.1
            }
        }

        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds

        $scores[$method].Bandwidth = $bandwidth
        $scores[$method].ExecutionTime = $executionTime
    }

    # Évaluer la précision (Accuracy)
    if ($Criteria -contains "Accuracy") {
        # Générer des données de validation
        $validationData = @()
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        for ($i = 0; $i -lt 100; $i++) {
            $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            if ($u1 -eq 0) { $u1 = 0.0001 }

            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $validationData += $mean + $stdDev * $z
        }

        # Calculer l'erreur quadratique moyenne pour chaque méthode
        $mseScores = @{}

        foreach ($method in $Methods) {
            $bandwidth = $scores[$method].Bandwidth
            $mse = 0

            foreach ($point in $validationData) {
                $density = 0

                switch ($KernelType) {
                    "Gaussian" {
                        $density = Get-GaussianKernelDensity -X $point -Data $Data -Bandwidth $bandwidth
                    }
                    "Epanechnikov" {
                        $density = Get-EpanechnikovKernelDensity -X $point -Data $Data -Bandwidth $bandwidth
                    }
                    "Triangular" {
                        $density = Get-TriangularKernelDensity -X $point -Data $Data -Bandwidth $bandwidth
                    }
                }

                # Calculer l'erreur quadratique par rapport à la densité théorique
                $theoreticalDensity = (1 / ($stdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp( - [Math]::Pow(($point - $mean) / $stdDev, 2) / 2)
                $mse += [Math]::Pow($density - $theoreticalDensity, 2)
            }

            $mse = $mse / $validationData.Count
            $mseScores[$method] = $mse
        }

        # Normaliser les scores de précision (plus le MSE est bas, meilleur est le score)
        $minMse = ($mseScores.Values | Measure-Object -Minimum).Minimum
        $maxMse = ($mseScores.Values | Measure-Object -Maximum).Maximum
        $mseRange = $maxMse - $minMse

        if ($mseRange -eq 0) {
            # Toutes les méthodes ont le même MSE
            foreach ($method in $Methods) {
                $scores[$method].Scores.Accuracy = 10
            }
        } else {
            foreach ($method in $Methods) {
                $normalizedScore = 10 - 9 * (($mseScores[$method] - $minMse) / $mseRange)
                $scores[$method].Scores.Accuracy = $normalizedScore
            }
        }
    }

    # Évaluer la vitesse (Speed)
    if ($Criteria -contains "Speed") {
        # Normaliser les scores de vitesse (plus le temps d'exécution est bas, meilleur est le score)
        $executionTimes = @{}
        foreach ($method in $Methods) {
            $executionTimes[$method] = $scores[$method].ExecutionTime
        }

        $minTime = ($executionTimes.Values | Measure-Object -Minimum).Minimum
        $maxTime = ($executionTimes.Values | Measure-Object -Maximum).Maximum
        $timeRange = $maxTime - $minTime

        if ($timeRange -eq 0) {
            # Toutes les méthodes ont le même temps d'exécution
            foreach ($method in $Methods) {
                $scores[$method].Scores.Speed = 10
            }
        } else {
            foreach ($method in $Methods) {
                $normalizedScore = 10 - 9 * (($executionTimes[$method] - $minTime) / $timeRange)
                $scores[$method].Scores.Speed = $normalizedScore
            }
        }
    }

    # Évaluer la robustesse (Robustness)
    if ($Criteria -contains "Robustness") {
        # Ajouter des valeurs aberrantes aux données
        $outlierData = $Data.Clone()
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Ajouter 5% de valeurs aberrantes
        $numOutliers = [Math]::Max(1, [Math]::Floor($Data.Count * 0.05))
        for ($i = 0; $i -lt $numOutliers; $i++) {
            $outlierData += $mean + $stdDev * 5 * (Get-Random -Minimum -1 -Maximum 2)
        }

        # Calculer les largeurs de bande avec et sans valeurs aberrantes
        $robustnessScores = @{}

        foreach ($method in $Methods) {
            $originalBandwidth = $scores[$method].Bandwidth
            $outlierBandwidth = 0

            switch ($method) {
                "Silverman" {
                    $outlierBandwidth = Get-SilvermanBandwidth -Data $outlierData -KernelType $KernelType
                }
                "Scott" {
                    $outlierBandwidth = Get-ScottBandwidth -Data $outlierData -KernelType $KernelType
                }
                "LeaveOneOut" {
                    # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                    $stdDev = [Math]::Sqrt(($outlierData | ForEach-Object { [Math]::Pow($_ - ($outlierData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                    $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($outlierData.Count, -0.2)
                    $minBandwidth = $referenceBandwidth * 0.5
                    $maxBandwidth = $referenceBandwidth * 2
                    $step = ($maxBandwidth - $minBandwidth) / 10

                    $outlierBandwidth = Get-LeaveOneOutCVBandwidth -Data $outlierData -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -MaxIterations 10
                }
                "KFold" {
                    # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                    $stdDev = [Math]::Sqrt(($outlierData | ForEach-Object { [Math]::Pow($_ - ($outlierData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                    $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($outlierData.Count, -0.2)
                    $minBandwidth = $referenceBandwidth * 0.5
                    $maxBandwidth = $referenceBandwidth * 2
                    $step = ($maxBandwidth - $minBandwidth) / 10

                    $outlierBandwidth = Get-KFoldCVBandwidth -Data $outlierData -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -K 5 -MaxIterations 10
                }
                "Optimized" {
                    $outlierBandwidth = Get-OptimizedCVBandwidth -Data $outlierData -KernelType $KernelType -ValidationMethod "KFold" -K 5 -MaxIterations 10 -Tolerance 0.1
                }
            }

            # Calculer la différence relative entre les largeurs de bande
            $relativeDifference = [Math]::Abs(($outlierBandwidth - $originalBandwidth) / $originalBandwidth)
            $robustnessScores[$method] = $relativeDifference
        }

        # Normaliser les scores de robustesse (plus la différence est petite, meilleur est le score)
        $minDiff = ($robustnessScores.Values | Measure-Object -Minimum).Minimum
        $maxDiff = ($robustnessScores.Values | Measure-Object -Maximum).Maximum
        $diffRange = $maxDiff - $minDiff

        if ($diffRange -eq 0) {
            # Toutes les méthodes ont la même robustesse
            foreach ($method in $Methods) {
                $scores[$method].Scores.Robustness = 10
            }
        } else {
            foreach ($method in $Methods) {
                $normalizedScore = 10 - 9 * (($robustnessScores[$method] - $minDiff) / $diffRange)
                $scores[$method].Scores.Robustness = $normalizedScore
            }
        }
    }

    # Évaluer l'adaptabilité (Adaptability)
    if ($Criteria -contains "Adaptability") {
        # Générer différents types de distributions
        $distributions = @{
            Normal     = @()
            Skewed     = @()
            Multimodal = @()
        }

        # Distribution normale
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        for ($i = 0; $i -lt 50; $i++) {
            $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            if ($u1 -eq 0) { $u1 = 0.0001 }

            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $distributions.Normal += $mean + $stdDev * $z
        }

        # Distribution asymétrique (log-normale)
        for ($i = 0; $i -lt 50; $i++) {
            $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            if ($u1 -eq 0) { $u1 = 0.0001 }

            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $distributions.Skewed += $mean + $stdDev * [Math]::Exp($z / 2)
        }

        # Distribution multimodale
        for ($i = 0; $i -lt 25; $i++) {
            $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            if ($u1 -eq 0) { $u1 = 0.0001 }

            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $distributions.Multimodal += ($mean - 20) + ($stdDev / 2) * $z
        }

        for ($i = 0; $i -lt 25; $i++) {
            $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
            if ($u1 -eq 0) { $u1 = 0.0001 }

            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $distributions.Multimodal += ($mean + 20) + ($stdDev / 2) * $z
        }

        # Calculer les largeurs de bande pour chaque distribution
        $adaptabilityScores = @{}

        foreach ($method in $Methods) {
            $bandwidths = @{}

            foreach ($distType in $distributions.Keys) {
                $distData = $distributions[$distType]

                switch ($method) {
                    "Silverman" {
                        $bandwidths[$distType] = Get-SilvermanBandwidth -Data $distData -KernelType $KernelType
                    }
                    "Scott" {
                        $bandwidths[$distType] = Get-ScottBandwidth -Data $distData -KernelType $KernelType
                    }
                    "LeaveOneOut" {
                        # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                        $distStdDev = [Math]::Sqrt(($distData | ForEach-Object { [Math]::Pow($_ - ($distData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                        $referenceBandwidth = 0.9 * $distStdDev * [Math]::Pow($distData.Count, -0.2)
                        $minBandwidth = $referenceBandwidth * 0.5
                        $maxBandwidth = $referenceBandwidth * 2
                        $step = ($maxBandwidth - $minBandwidth) / 10

                        $bandwidths[$distType] = Get-LeaveOneOutCVBandwidth -Data $distData -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -MaxIterations 10
                    }
                    "KFold" {
                        # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                        $distStdDev = [Math]::Sqrt(($distData | ForEach-Object { [Math]::Pow($_ - ($distData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                        $referenceBandwidth = 0.9 * $distStdDev * [Math]::Pow($distData.Count, -0.2)
                        $minBandwidth = $referenceBandwidth * 0.5
                        $maxBandwidth = $referenceBandwidth * 2
                        $step = ($maxBandwidth - $minBandwidth) / 10

                        $bandwidths[$distType] = Get-KFoldCVBandwidth -Data $distData -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -K 5 -MaxIterations 10
                    }
                    "Optimized" {
                        $bandwidths[$distType] = Get-OptimizedCVBandwidth -Data $distData -KernelType $KernelType -ValidationMethod "KFold" -K 5 -MaxIterations 10 -Tolerance 0.1
                    }
                }
            }

            # Calculer la variance des largeurs de bande normalisées
            $normalizedBandwidths = @()
            foreach ($distType in $distributions.Keys) {
                $distData = $distributions[$distType]
                $distStdDev = [Math]::Sqrt(($distData | ForEach-Object { [Math]::Pow($_ - ($distData | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                $normalizedBandwidths += $bandwidths[$distType] / $distStdDev
            }

            $meanNormalizedBandwidth = ($normalizedBandwidths | Measure-Object -Average).Average
            $varianceSum = 0
            foreach ($normBandwidth in $normalizedBandwidths) {
                $varianceSum += [Math]::Pow($normBandwidth - $meanNormalizedBandwidth, 2)
            }
            $variance = $varianceSum / $normalizedBandwidths.Count

            $adaptabilityScores[$method] = $variance
        }

        # Normaliser les scores d'adaptabilité (plus la variance est petite, meilleur est le score)
        $minVar = ($adaptabilityScores.Values | Measure-Object -Minimum).Minimum
        $maxVar = ($adaptabilityScores.Values | Measure-Object -Maximum).Maximum
        $varRange = $maxVar - $minVar

        if ($varRange -eq 0) {
            # Toutes les méthodes ont la même adaptabilité
            foreach ($method in $Methods) {
                $scores[$method].Scores.Adaptability = 10
            }
        } else {
            foreach ($method in $Methods) {
                $normalizedScore = 10 - 9 * (($adaptabilityScores[$method] - $minVar) / $varRange)
                $scores[$method].Scores.Adaptability = $normalizedScore
            }
        }
    }

    # Calculer les scores totaux en fonction des poids
    foreach ($method in $Methods) {
        $totalScore = 0
        $totalWeight = 0

        foreach ($criterion in $Criteria) {
            $weight = $Weights[$criterion]
            $totalWeight += $weight
            $totalScore += $scores[$method].Scores[$criterion] * $weight
        }

        if ($totalWeight -gt 0) {
            $scores[$method].TotalScore = $totalScore / $totalWeight
        }
    }

    return $scores
}

<#
.SYNOPSIS
    Détecte automatiquement les caractéristiques des données.

.DESCRIPTION
    Cette fonction analyse les données pour détecter automatiquement leurs caractéristiques,
    telles que la normalité, l'asymétrie, la multimodalité, la présence de valeurs aberrantes, etc.
    Ces caractéristiques peuvent être utilisées pour choisir la méthode de sélection de largeur de bande
    la plus appropriée pour l'estimation de densité par noyau.

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
        RecommendedMethod = "Silverman"  # Silverman, Scott, LeaveOneOut, KFold, Optimized
    }

    # Calculer les statistiques de base
    $sortedData = $Data | Sort-Object
    $characteristics.Min = $sortedData[0]
    $characteristics.Max = $sortedData[-1]
    $characteristics.Range = $characteristics.Max - $characteristics.Min
    $characteristics.Mean = ($Data | Measure-Object -Average).Average

    # Calculer la médiane
    $n = $sortedData.Count
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
    $bandwidth = 0.9 * $characteristics.StdDev * [Math]::Pow($n, -0.2)  # Règle de Silverman
    $gridSize = 100
    $gridMin = $characteristics.Min - $characteristics.StdDev
    $gridMax = $characteristics.Max + $characteristics.StdDev
    $gridStep = ($gridMax - $gridMin) / $gridSize

    $densities = @()
    for ($i = 0; $i -le $gridSize; $i++) {
        $x = $gridMin + $i * $gridStep
        $density = 0

        foreach ($dataPoint in $Data) {
            $u = ($x - $dataPoint) / $bandwidth
            $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp( - ($u * $u) / 2)
            $density += $kernelValue
        }

        $density = $density / ($n * $bandwidth)
        $densities += @{X = $x; Density = $density }
    }

    # Détecter les modes (maxima locaux)
    $modes = @()
    for ($i = 1; $i -lt $gridSize; $i++) {
        if ($densities[$i].Density -gt $densities[$i - 1].Density -and $densities[$i].Density -gt $densities[$i + 1].Density) {
            # Vérifier que le mode est significatif (au moins 10% de la densité maximale)
            $maxDensity = ($densities | ForEach-Object { $_.Density } | Measure-Object -Maximum).Maximum
            if ($densities[$i].Density -gt 0.1 * $maxDensity) {
                $modes += $densities[$i].X
            }
        }
    }

    $characteristics.Modes = $modes
    $characteristics.ModeCount = $modes.Count
    $characteristics.IsMultimodal = $modes.Count -gt 1

    # Déterminer la complexité des données
    if ($characteristics.IsNormal -and -not $characteristics.HasOutliers -and -not $characteristics.IsMultimodal) {
        $characteristics.Complexity = "Low"
    } elseif ($characteristics.IsMultimodal -or ($characteristics.HasOutliers -and $characteristics.OutlierPercentage -gt 5)) {
        $characteristics.Complexity = "High"
    } else {
        $characteristics.Complexity = "Medium"
    }

    # Recommander une méthode de sélection de largeur de bande
    if ($characteristics.Complexity -eq "Low") {
        # Pour les données simples (normales, sans valeurs aberrantes), utiliser Silverman ou Scott
        if ([Math]::Abs($characteristics.Kurtosis) -lt 0.5) {
            $characteristics.RecommendedMethod = "Silverman"
        } else {
            $characteristics.RecommendedMethod = "Scott"
        }
    } elseif ($characteristics.Complexity -eq "Medium") {
        # Pour les données moyennement complexes, utiliser la validation croisée
        if ($n -lt 100) {
            $characteristics.RecommendedMethod = "LeaveOneOut"
        } else {
            $characteristics.RecommendedMethod = "KFold"
        }
    } else {
        # Pour les données complexes, utiliser l'optimisation par validation croisée
        $characteristics.RecommendedMethod = "Optimized"
    }

    # Afficher les caractéristiques détectées en mode verbose
    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
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
        Write-Verbose "- Méthode recommandée: $($characteristics.RecommendedMethod)"
    }

    return $characteristics
}

<#
.SYNOPSIS
    Sélectionne automatiquement la méthode de sélection de largeur de bande optimale.

.DESCRIPTION
    Cette fonction sélectionne automatiquement la méthode de sélection de largeur de bande
    la plus appropriée en fonction des caractéristiques des données et des objectifs de l'utilisateur.
    Elle utilise les fonctions Get-DataCharacteristics et Get-BandwidthMethodScores pour analyser
    les données et évaluer les performances des différentes méthodes.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire

.PARAMETER Objective
    L'objectif principal de l'estimation de densité (par défaut "Balanced").
    - "Accuracy": Privilégier la précision de l'estimation
    - "Speed": Privilégier la vitesse d'exécution
    - "Robustness": Privilégier la robustesse face aux valeurs aberrantes
    - "Adaptability": Privilégier l'adaptabilité à différents types de distributions
    - "Balanced": Équilibrer tous les critères

.PARAMETER Methods
    Les méthodes à considérer (par défaut toutes les méthodes disponibles).
    - "Silverman": Règle de Silverman
    - "Scott": Méthode de Scott
    - "LeaveOneOut": Validation croisée par leave-one-out
    - "KFold": Validation croisée par k-fold
    - "Optimized": Optimisation par validation croisée

.PARAMETER AutoDetect
    Indique si la fonction doit détecter automatiquement les caractéristiques des données (par défaut $true).
    Si $false, la fonction utilisera uniquement le système de scoring pour sélectionner la méthode optimale.

.EXAMPLE
    Get-OptimalBandwidthMethod -Data $data
    Sélectionne automatiquement la méthode de sélection de largeur de bande optimale pour les données fournies.

.EXAMPLE
    Get-OptimalBandwidthMethod -Data $data -KernelType "Epanechnikov" -Objective "Speed"
    Sélectionne automatiquement la méthode de sélection de largeur de bande optimale pour les données fournies,
    en utilisant le noyau d'Epanechnikov et en privilégiant la vitesse d'exécution.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-OptimalBandwidthMethod {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")]
        [string]$Objective = "Balanced",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")]
        [string[]]$Methods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized"),

        [Parameter(Mandatory = $false)]
        [bool]$AutoDetect = $true
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour sélectionner la méthode optimale."
    }

    # Initialiser le résultat
    $result = @{
        SelectedMethod      = ""
        Bandwidth           = 0
        ExecutionTime       = 0
        Characteristics     = $null
        Scores              = $null
        Weights             = @{}
        RecommendationBasis = ""
    }

    # Définir les poids en fonction de l'objectif
    switch ($Objective) {
        "Accuracy" {
            $result.Weights = @{
                Accuracy     = 3
                Speed        = 1
                Robustness   = 1
                Adaptability = 1
            }
        }
        "Speed" {
            $result.Weights = @{
                Accuracy     = 1
                Speed        = 3
                Robustness   = 1
                Adaptability = 1
            }
        }
        "Robustness" {
            $result.Weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 3
                Adaptability = 1
            }
        }
        "Adaptability" {
            $result.Weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 1
                Adaptability = 3
            }
        }
        "Balanced" {
            $result.Weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 1
                Adaptability = 1
            }
        }
    }

    # Si la détection automatique est activée, analyser les caractéristiques des données
    if ($AutoDetect) {
        $characteristics = Get-DataCharacteristics -Data $Data
        $result.Characteristics = $characteristics

        # Filtrer les méthodes en fonction des caractéristiques des données
        $filteredMethods = @()

        # Pour les données simples (normales, sans valeurs aberrantes), privilégier Silverman et Scott
        if ($characteristics.Complexity -eq "Low") {
            if ($Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }

            # Si l'objectif est la vitesse, ne considérer que Silverman et Scott
            if ($Objective -eq "Speed") {
                $result.SelectedMethod = if ($filteredMethods.Count -gt 0) { $filteredMethods[0] } else { "Silverman" }
                $result.RecommendationBasis = "Détection automatique (données simples, objectif: vitesse)"

                # Calculer la largeur de bande avec la méthode sélectionnée
                $startTime = Get-Date
                switch ($result.SelectedMethod) {
                    "Silverman" {
                        $result.Bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType
                    }
                    "Scott" {
                        $result.Bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType
                    }
                }
                $endTime = Get-Date
                $result.ExecutionTime = ($endTime - $startTime).TotalSeconds

                return $result
            }
        }
        # Pour les données moyennement complexes, privilégier la validation croisée
        elseif ($characteristics.Complexity -eq "Medium") {
            if ($Data.Count -lt 100) {
                if ($Methods -contains "LeaveOneOut") {
                    $filteredMethods += "LeaveOneOut"
                }
            } else {
                if ($Methods -contains "KFold") {
                    $filteredMethods += "KFold"
                }
            }

            # Ajouter Silverman et Scott si disponibles
            if ($Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }
        }
        # Pour les données complexes, privilégier l'optimisation par validation croisée
        else {
            if ($Methods -contains "Optimized") {
                $filteredMethods += "Optimized"
            }
            if ($Methods -contains "KFold") {
                $filteredMethods += "KFold"
            }
            if ($Methods -contains "LeaveOneOut") {
                $filteredMethods += "LeaveOneOut"
            }
        }

        # Si aucune méthode n'a été filtrée, utiliser toutes les méthodes disponibles
        if ($filteredMethods.Count -eq 0) {
            $filteredMethods = $Methods
        }

        # Si une seule méthode a été filtrée, la sélectionner directement
        if ($filteredMethods.Count -eq 1) {
            $result.SelectedMethod = $filteredMethods[0]
            $result.RecommendationBasis = "Détection automatique (complexité: $($characteristics.Complexity))"

            # Calculer la largeur de bande avec la méthode sélectionnée
            $startTime = Get-Date
            switch ($result.SelectedMethod) {
                "Silverman" {
                    $result.Bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType
                }
                "Scott" {
                    $result.Bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType
                }
                "LeaveOneOut" {
                    # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                    $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($Data.Count, -0.2)
                    $minBandwidth = $referenceBandwidth * 0.5
                    $maxBandwidth = $referenceBandwidth * 2
                    $step = ($maxBandwidth - $minBandwidth) / 10

                    $result.Bandwidth = Get-LeaveOneOutCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -MaxIterations 20
                }
                "KFold" {
                    # Utiliser une plage de largeurs de bande réduite pour accélérer le calcul
                    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                    $referenceBandwidth = 0.9 * $stdDev * [Math]::Pow($Data.Count, -0.2)
                    $minBandwidth = $referenceBandwidth * 0.5
                    $maxBandwidth = $referenceBandwidth * 2
                    $step = ($maxBandwidth - $minBandwidth) / 10

                    $result.Bandwidth = Get-KFoldCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @($minBandwidth, $maxBandwidth, $step) -K 5 -MaxIterations 20
                }
                "Optimized" {
                    $result.Bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "KFold" -K 5 -MaxIterations 20 -Tolerance 0.1
                }
            }
            $endTime = Get-Date
            $result.ExecutionTime = ($endTime - $startTime).TotalSeconds

            return $result
        }

        # Utiliser les méthodes filtrées pour le scoring
        $Methods = $filteredMethods
    }

    # Calculer les scores pour les méthodes sélectionnées
    $scores = Get-BandwidthMethodScores -Data $Data -KernelType $KernelType -Methods $Methods -Criteria @("Accuracy", "Speed", "Robustness", "Adaptability") -Weights $result.Weights
    $result.Scores = $scores

    # Sélectionner la méthode avec le meilleur score total
    $bestMethod = ""
    $bestScore = 0

    foreach ($method in $scores.Keys) {
        if ($scores[$method].TotalScore -gt $bestScore) {
            $bestScore = $scores[$method].TotalScore
            $bestMethod = $method
        }
    }

    $result.SelectedMethod = $bestMethod
    $result.Bandwidth = $scores[$bestMethod].Bandwidth
    $result.ExecutionTime = $scores[$bestMethod].ExecutionTime

    if ($AutoDetect) {
        $result.RecommendationBasis = "Détection automatique + Scoring (complexité: $($characteristics.Complexity), objectif: $Objective)"
    } else {
        $result.RecommendationBasis = "Scoring (objectif: $Objective)"
    }

    return $result
}

<#
.SYNOPSIS
    Effectue une estimation de densité par noyau (KDE) sur un ensemble de données.

.DESCRIPTION
    Cette fonction effectue une estimation de densité par noyau (KDE) sur un ensemble de données.
    Elle permet de spécifier le type de noyau, la méthode de sélection de la largeur de bande,
    les points d'évaluation, et d'autres paramètres pour personnaliser l'estimation.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER EvaluationPoints
    Les points où évaluer la densité. Si non spécifiés, ils seront générés automatiquement.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Optimal").
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire
    - "Optimal": Sélection automatique du noyau optimal

.PARAMETER BandwidthMethod
    La méthode de sélection de la largeur de bande (par défaut "Silverman").
    - "Silverman": Règle de Silverman
    - "Scott": Méthode de Scott
    - "LeaveOneOutCV": Validation croisée par leave-one-out
    - "KFoldCV": Validation croisée par k-fold
    - "Optimized": Méthode d'optimisation avancée
    - "Manual": Largeur de bande spécifiée manuellement

.PARAMETER Bandwidth
    La largeur de bande à utiliser si BandwidthMethod est "Manual".

.PARAMETER Normalize
    Indique si les estimations de densité doivent être normalisées pour que leur intégrale soit égale à 1.

.PARAMETER K
    Le nombre de plis (folds) à utiliser pour la validation croisée par k-fold.
    Ignoré si BandwidthMethod n'est pas "KFoldCV".

.PARAMETER Objective
    L'objectif de l'analyse pour la sélection du noyau optimal.
    - "Precision": Privilégie la précision de l'estimation
    - "Smoothness": Privilégie le lissage de l'estimation
    - "Speed": Privilégie la vitesse de calcul
    - "Balance": Équilibre entre précision, lissage et vitesse

.PARAMETER DistributionType
    Le type de distribution des données pour la sélection de la largeur de bande.
    Si non spécifié, il sera détecté automatiquement.
    - "Normal": Distribution normale
    - "Skewed": Distribution asymétrique
    - "HeavyTailed": Distribution à queue lourde
    - "Multimodal": Distribution multimodale
    - "Sparse": Données éparses

.PARAMETER NumPoints
    Le nombre de points d'évaluation à générer si EvaluationPoints n'est pas spécifié.

.PARAMETER Parallel
    Indique si le calcul doit être effectué en parallèle pour améliorer les performances.

.EXAMPLE
    Get-KernelDensityEstimation -Data $data
    Effectue une estimation de densité par noyau sur les données en utilisant les paramètres par défaut.

.EXAMPLE
    Get-KernelDensityEstimation -Data $data -KernelType "Epanechnikov" -BandwidthMethod "Scott"
    Effectue une estimation de densité par noyau sur les données en utilisant le noyau d'Epanechnikov
    et la méthode de Scott pour la sélection de la largeur de bande.

.EXAMPLE
    Get-KernelDensityEstimation -Data $data -BandwidthMethod "Manual" -Bandwidth 0.5
    Effectue une estimation de densité par noyau sur les données en utilisant une largeur de bande fixe de 0.5.

.OUTPUTS
    PSCustomObject
#>
function Get-KernelDensityEstimation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [double[]]$Data,

        [Parameter(Mandatory = $false, Position = 1)]
        [double[]]$EvaluationPoints = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Optimal")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOutCV", "KFoldCV", "Optimized", "Manual")]
        [string]$BandwidthMethod = "Silverman",

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Normalize = $true,

        [Parameter(Mandatory = $false)]
        [int]$K = 5,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Precision", "Smoothness", "Speed", "Balance")]
        [string]$Objective = "Balance",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Skewed", "HeavyTailed", "Multimodal", "Sparse", "")]
        [string]$DistributionType = "",

        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,

        [Parameter(Mandatory = $false)]
        [switch]$Parallel = $false
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Générer les points d'évaluation si non spécifiés
    if ($null -eq $EvaluationPoints) {
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        $range = $max - $min

        # Ajouter une marge pour éviter les effets de bord
        $min = $min - 0.1 * $range
        $max = $max + 0.1 * $range

        # Générer les points d'évaluation
        $step = ($max - $min) / ($NumPoints - 1)
        $EvaluationPoints = 0..($NumPoints - 1) | ForEach-Object { $min + $_ * $step }
    }

    # Sélectionner le noyau optimal si demandé
    if ($KernelType -eq "Optimal") {
        $KernelType = Get-OptimalKernel -Data $Data -Objective $Objective -DataCharacteristics $DistributionType
    }

    # Sélectionner la largeur de bande en fonction de la méthode spécifiée
    if ($BandwidthMethod -ne "Manual" -or $Bandwidth -le 0) {
        switch ($BandwidthMethod) {
            "Silverman" {
                $Bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType -DistributionType $DistributionType
            }
            "Scott" {
                $Bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType -DistributionType $DistributionType
            }
            "LeaveOneOutCV" {
                $Bandwidth = Get-LeaveOneOutCVBandwidth -Data $Data -KernelType $KernelType
            }
            "KFoldCV" {
                $Bandwidth = Get-KFoldCVBandwidth -Data $Data -KernelType $KernelType -K $K
            }
            "Optimized" {
                $Bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "KFold" -K $K
            }
            "Manual" {
                # Si la largeur de bande est <= 0, utiliser la méthode de Silverman comme fallback
                if ($Bandwidth -le 0) {
                    $Bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType -DistributionType $DistributionType
                }
            }
        }
    }

    # Calculer les estimations de densité
    $densityEstimates = New-Object double[] $EvaluationPoints.Count

    # Sélectionner la fonction de noyau appropriée
    $kernelFunction = switch ($KernelType) {
        "Gaussian" { Get-Command -Name Get-GaussianKernel }
        "Epanechnikov" { Get-Command -Name Get-EpanechnikovKernel }
        "Triangular" { Get-Command -Name Get-TriangularKernel }
    }

    # Calculer les estimations de densité en parallèle ou en séquentiel
    if ($Parallel -and $EvaluationPoints.Count -gt 10) {
        # Vérifier si PowerShell 7+ est utilisé (nécessaire pour ForEach-Object -Parallel)
        $isPowerShell7Plus = $PSVersionTable.PSVersion.Major -ge 7

        if ($isPowerShell7Plus) {
            # Calculer en parallèle
            $results = $EvaluationPoints | ForEach-Object -Parallel {
                $point = $_
                $data = $using:Data
                $bandwidth = $using:Bandwidth
                $kernelType = $using:KernelType

                $density = 0
                foreach ($dataPoint in $data) {
                    $u = ($point - $dataPoint) / $bandwidth

                    $kernelValue = switch ($kernelType) {
                        "Gaussian" {
                            (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $u * $u)
                        }
                        "Epanechnikov" {
                            if ([Math]::Abs($u) -le 1) {
                                0.75 * (1 - $u * $u)
                            } else {
                                0
                            }
                        }
                        "Triangular" {
                            if ([Math]::Abs($u) -le 1) {
                                1 - [Math]::Abs($u)
                            } else {
                                0
                            }
                        }
                    }

                    $density += $kernelValue
                }

                $density = $density / ($bandwidth * $data.Count)

                [PSCustomObject]@{
                    Point   = $point
                    Density = $density
                }
            }

            # Trier les résultats par point d'évaluation
            $results = $results | Sort-Object -Property Point

            # Extraire les estimations de densité
            for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
                $densityEstimates[$i] = $results[$i].Density
            }
        } else {
            # Fallback au calcul séquentiel si PowerShell 7+ n'est pas disponible
            for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
                $point = $EvaluationPoints[$i]
                $density = 0

                foreach ($dataPoint in $Data) {
                    $u = ($point - $dataPoint) / $Bandwidth
                    $kernelValue = & $kernelFunction -U $u
                    $density += $kernelValue
                }

                $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
            }
        }
    } else {
        # Calculer en séquentiel
        for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
            $point = $EvaluationPoints[$i]
            $density = 0

            foreach ($dataPoint in $Data) {
                $u = ($point - $dataPoint) / $Bandwidth
                $kernelValue = & $kernelFunction -U $u
                $density += $kernelValue
            }

            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
        }
    }

    # Normaliser les estimations de densité si demandé
    if ($Normalize) {
        # Calculer l'intégrale des estimations de densité
        $integral = 0
        for ($i = 1; $i -lt $EvaluationPoints.Count; $i++) {
            $width = $EvaluationPoints[$i] - $EvaluationPoints[$i - 1]
            $height = ($densityEstimates[$i] + $densityEstimates[$i - 1]) / 2
            $integral += $width * $height
        }

        # Normaliser les estimations de densité
        if ($integral -ne 0) {
            for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                $densityEstimates[$i] = $densityEstimates[$i] / $integral
            }
        }
    }

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Data             = $Data
        EvaluationPoints = $EvaluationPoints
        DensityEstimates = $densityEstimates
        KernelType       = $KernelType
        Bandwidth        = $Bandwidth
        BandwidthMethod  = $BandwidthMethod
        Normalized       = $Normalize
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-GaussianKernel, Get-GaussianKernelDensity, Get-EpanechnikovKernel, Get-EpanechnikovKernelDensity, Get-TriangularKernel, Get-TriangularKernelDensity, Get-OptimalKernel, Get-OptimalKernelDensity, Get-SilvermanBandwidth, Get-ScottBandwidth, Get-LeaveOneOutCVBandwidth, Get-KFoldCVBandwidth, Get-OptimizedCVBandwidth, Get-BandwidthMethodScores, Get-DataCharacteristics, Get-OptimalBandwidthMethod, Get-KernelDensityEstimation
