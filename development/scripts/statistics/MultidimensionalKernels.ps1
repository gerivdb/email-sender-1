<#
.SYNOPSIS
    Implémente les fonctions pour l'estimation de densité par noyau multidimensionnelle.

.DESCRIPTION
    Ce script implémente les fonctions pour l'estimation de densité par noyau multidimensionnelle
    pour différents types de noyaux (Gaussian, Epanechnikov, Triangular, Uniform, Biweight, Triweight, Cosine).

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\GaussianKernel.ps1"
. "$scriptPath\EpanechnikovKernel.ps1"
. "$scriptPath\TriangularKernel.ps1"
. "$scriptPath\UniformKernel.ps1"
. "$scriptPath\BiweightKernel.ps1"
. "$scriptPath\TriweightKernel.ps1"
. "$scriptPath\CosineKernel.ps1"

<#
.SYNOPSIS
    Calcule la largeur de bande optimale selon la méthode de Silverman.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale selon la méthode de Silverman
    pour l'estimation de densité par noyau.

.PARAMETER Data
    Les données pour lesquelles calculer la largeur de bande optimale.

.EXAMPLE
    Get-SilvermanBandwidth -Data @(1, 2, 3, 4, 5)
    Calcule la largeur de bande optimale selon la méthode de Silverman pour les données spécifiées.

.OUTPUTS
    System.Double
#>
function Get-SilvermanBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer la largeur de bande optimale."
    }

    # Calculer l'écart-type des données
    $mean = ($Data | Measure-Object -Average).Average
    $variance = 0
    foreach ($x in $Data) {
        $variance += [Math]::Pow($x - $mean, 2)
    }
    $variance /= $Data.Count
    $stdDev = [Math]::Sqrt($variance)

    # Calculer la largeur de bande optimale selon la méthode de Silverman
    $n = $Data.Count
    $bandwidth = 0.9 * $stdDev * [Math]::Pow($n, -0.2)

    return $bandwidth
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau gaussien multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau gaussien
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-GaussianKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau gaussien
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-GaussianKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0

    foreach ($dataPoint in $Data) {
        $exponent = 0
        $normalization = 1

        foreach ($dimension in $Dimensions) {
            $diff = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]
            $exponent += $diff * $diff
            $normalization *= $bandwidthByDimension[$dimension] * [Math]::Sqrt(2 * [Math]::PI)
        }

        $density += [Math]::Exp(-0.5 * $exponent) / $normalization
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau d'Epanechnikov multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau d'Epanechnikov
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-EpanechnikovKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau d'Epanechnikov
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-EpanechnikovKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $d = $Dimensions.Count

    foreach ($dataPoint in $Data) {
        $sumSquaredDiff = 0
        $product = 1

        foreach ($dimension in $Dimensions) {
            $diff = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]
            $sumSquaredDiff += $diff * $diff
            $product *= $bandwidthByDimension[$dimension]
        }

        if ($sumSquaredDiff -le 1) {
            $c_d = 2 * [Math]::Pow([Math]::PI, $d / 2) / ($d * [Math]::Gamma($d / 2))
            $density += (1 / $product) * (0.75 / $c_d) * (1 - $sumSquaredDiff)
        }
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau triangulaire multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau triangulaire
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-TriangularKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau triangulaire
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-TriangularKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0

    foreach ($dataPoint in $Data) {
        $product = 1
        $kernelProduct = 1

        foreach ($dimension in $Dimensions) {
            $diff = [Math]::Abs(($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension])
            if ($diff -ge 1) {
                $kernelProduct = 0
                break
            }
            $kernelProduct *= (1 - $diff)
            $product *= $bandwidthByDimension[$dimension]
        }

        $density += $kernelProduct / $product
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau biweight multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau biweight
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-BiweightKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau biweight
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-BiweightKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $d = $Dimensions.Count

    foreach ($dataPoint in $Data) {
        $sumSquaredDiff = 0
        $product = 1

        foreach ($dimension in $Dimensions) {
            $diff = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]
            $sumSquaredDiff += $diff * $diff
            $product *= $bandwidthByDimension[$dimension]
        }

        if ($sumSquaredDiff -le 1) {
            $c_d = 2 * [Math]::Pow([Math]::PI, $d / 2) / ($d * [Math]::Gamma($d / 2))
            $density += (1 / $product) * (15 / (16 * $c_d)) * [Math]::Pow(1 - $sumSquaredDiff, 2)
        }
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau triweight multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau triweight
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-TriweightKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau triweight
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-TriweightKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $d = $Dimensions.Count

    foreach ($dataPoint in $Data) {
        $sumSquaredDiff = 0
        $product = 1

        foreach ($dimension in $Dimensions) {
            $diff = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]
            $sumSquaredDiff += $diff * $diff
            $product *= $bandwidthByDimension[$dimension]
        }

        if ($sumSquaredDiff -le 1) {
            $c_d = 2 * [Math]::Pow([Math]::PI, $d / 2) / ($d * [Math]::Gamma($d / 2))
            $density += (1 / $product) * (35 / (32 * $c_d)) * [Math]::Pow(1 - $sumSquaredDiff, 3)
        }
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau cosinus multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau cosinus
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-CosineKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau cosinus
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-CosineKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $d = $Dimensions.Count

    foreach ($dataPoint in $Data) {
        $sumSquaredDiff = 0
        $product = 1
        $kernelProduct = 1

        foreach ($dimension in $Dimensions) {
            $diff = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]
            $sumSquaredDiff += $diff * $diff
            $product *= $bandwidthByDimension[$dimension]
        }

        if ($sumSquaredDiff -le 1) {
            $c_d = 2 * [Math]::Pow([Math]::PI, $d / 2) / ($d * [Math]::Gamma($d / 2))
            $density += (1 / $product) * (1 / $c_d) * [Math]::Cos([Math]::PI * [Math]::Sqrt($sumSquaredDiff) / 2)
        }
    }

    $density /= $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme multidimensionnelle.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme
    pour des données multidimensionnelles.

.PARAMETER Point
    Le point où calculer la densité. Doit être un PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution. Doit être un tableau de PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier
    élément de Data seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable
    avec une largeur de bande pour chaque dimension. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-UniformKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau uniforme
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-UniformKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            $dimensionData = $Data | ForEach-Object { $_.$dimension }
            $bandwidthByDimension[$dimension] = Get-SilvermanBandwidth -Data $dimensionData
        }
    } elseif ($Bandwidth -is [double]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [hashtable] -or $Bandwidth -is [PSCustomObject]) {
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Le paramètre Bandwidth doit être un nombre, un hashtable ou un PSCustomObject."
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $d = $Dimensions.Count

    foreach ($dataPoint in $Data) {
        $inRange = $true
        $product = 1

        foreach ($dimension in $Dimensions) {
            $diff = [Math]::Abs(($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension])
            if ($diff -gt 0.5) {
                $inRange = $false
                break
            }
            $product *= $bandwidthByDimension[$dimension]
        }

        if ($inRange) {
            $density += 1 / $product
        }
    }

    $density /= $n

    return $density
}

# Exporter les fonctions
# Export-ModuleMember -Function Get-GaussianKernelDensityND, Get-EpanechnikovKernelDensityND, Get-TriangularKernelDensityND, Get-BiweightKernelDensityND, Get-TriweightKernelDensityND, Get-CosineKernelDensityND, Get-UniformKernelDensityND
