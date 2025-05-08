# KernelQuantileEstimation.psm1
# Module pour le calcul des quantiles par estimation de densité

<#
.SYNOPSIS
    Calcule la densité de probabilité d'une distribution en utilisant l'estimation par noyau.

.DESCRIPTION
    Cette fonction calcule la densité de probabilité d'une distribution en utilisant
    l'estimation par noyau (Kernel Density Estimation, KDE).

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Points
    Les points où calculer la densité (par défaut, 100 points répartis uniformément).

.PARAMETER Bandwidth
    La largeur de bande (par défaut, sélection automatique par la règle de Silverman).

.PARAMETER Kernel
    Le noyau à utiliser (par défaut "Gaussian").
    Les noyaux disponibles sont :
    - Gaussian : Noyau gaussien
    - Epanechnikov : Noyau d'Epanechnikov
    - Uniform : Noyau uniforme
    - Triangular : Noyau triangulaire
    - Biweight : Noyau biweight
    - Triweight : Noyau triweight
    - Cosine : Noyau cosinus

.EXAMPLE
    Get-KernelDensity -Data $data -Points $points -Bandwidth 0.5 -Kernel "Gaussian"
    Calcule la densité de probabilité de la distribution $data aux points $points
    en utilisant un noyau gaussien avec une largeur de bande de 0.5.

.OUTPUTS
    PSObject
#>
function Get-KernelDensity {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double[]]$Points = $null,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$Kernel = "Gaussian"
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Créer les points d'évaluation si non spécifiés
    if ($null -eq $Points) {
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        $range = $max - $min
        $padding = $range * 0.1
        $min = $min - $padding
        $max = $max + $padding
        $Points = $min..$max | ForEach-Object { $min + $_ * ($max - $min) / 100 }
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        $Bandwidth = Get-OptimalBandwidth -Data $Data -Method "Silverman"
    }

    # Sélectionner la fonction de noyau
    $kernelFunction = switch ($Kernel) {
        "Gaussian" { { param($x) [Math]::Exp(-0.5 * $x * $x) / [Math]::Sqrt(2 * [Math]::PI) } }
        "Epanechnikov" { { param($x) if ([Math]::Abs($x) -le 1) { 0.75 * (1 - $x * $x) } else { 0 } } }
        "Uniform" { { param($x) if ([Math]::Abs($x) -le 1) { 0.5 } else { 0 } } }
        "Triangular" { { param($x) if ([Math]::Abs($x) -le 1) { 1 - [Math]::Abs($x) } else { 0 } } }
        "Biweight" { { param($x) if ([Math]::Abs($x) -le 1) { (15.0 / 16.0) * [Math]::Pow(1 - $x * $x, 2) } else { 0 } } }
        "Triweight" { { param($x) if ([Math]::Abs($x) -le 1) { (35.0 / 32.0) * [Math]::Pow(1 - $x * $x, 3) } else { 0 } } }
        "Cosine" { { param($x) if ([Math]::Abs($x) -le 1) { ([Math]::PI / 4) * [Math]::Cos([Math]::PI * $x / 2) } else { 0 } } }
        default { { param($x) [Math]::Exp(-0.5 * $x * $x) / [Math]::Sqrt(2 * [Math]::PI) } }
    }

    # Calculer la densité à chaque point
    $densities = @()
    foreach ($point in $Points) {
        $density = 0
        foreach ($value in $Data) {
            $z = ($point - $value) / $Bandwidth
            $density += & $kernelFunction $z
        }
        $density = $density / ($Data.Count * $Bandwidth)
        $densities += $density
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Points    = $Points
        Densities = $densities
        Bandwidth = $Bandwidth
        Kernel    = $Kernel
        Data      = $Data
    }

    return $result
}

<#
.SYNOPSIS
    Calcule la largeur de bande optimale pour l'estimation par noyau.

.DESCRIPTION
    Cette fonction calcule la largeur de bande optimale pour l'estimation par noyau
    en utilisant différentes méthodes.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Method
    La méthode de calcul de la largeur de bande (par défaut "Silverman").
    Les méthodes disponibles sont :
    - Silverman : Règle de Silverman (règle du pouce)
    - Scott : Règle de Scott
    - ISJ : Méthode de Sheather-Jones par plug-in itératif

.EXAMPLE
    Get-OptimalBandwidth -Data $data -Method "Silverman"
    Calcule la largeur de bande optimale pour la distribution $data
    en utilisant la règle de Silverman.

.OUTPUTS
    System.Double
#>
function Get-OptimalBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "ISJ")]
        [string]$Method = "Silverman"
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Calculer la largeur de bande optimale selon la méthode choisie
    $n = $Data.Count

    # Calculer l'écart-type manuellement
    $mean = ($Data | Measure-Object -Average).Average
    $sumSquaredDiff = 0
    foreach ($value in $Data) {
        $sumSquaredDiff += [Math]::Pow($value - $mean, 2)
    }
    $variance = $sumSquaredDiff / $n
    $stdDev = [Math]::Sqrt($variance)

    $iqr = Get-InterquartileRange -Data $Data

    # Utiliser l'écart interquartile si disponible, sinon l'écart-type
    $sigma = if ($iqr -gt 0) { $iqr / 1.349 } else { $stdDev }

    # Calculer la largeur de bande selon la méthode choisie
    switch ($Method) {
        "Silverman" {
            # Règle de Silverman (règle du pouce)
            $bandwidth = 0.9 * $sigma * [Math]::Pow($n, -0.2)
        }
        "Scott" {
            # Règle de Scott
            $bandwidth = 1.06 * $sigma * [Math]::Pow($n, -0.2)
        }
        "ISJ" {
            # Méthode de Sheather-Jones par plug-in itératif (approximation simplifiée)
            $bandwidth = 0.9 * $sigma * [Math]::Pow($n, -0.2)

            # Itérations pour affiner l'estimation
            for ($i = 0; $i -lt 3; $i++) {
                $pilotBandwidth = 1.5 * $bandwidth

                # Calculer la dérivée seconde de la densité
                $sum = 0
                foreach ($x in $Data) {
                    foreach ($y in $Data) {
                        $z = ($x - $y) / $pilotBandwidth
                        $k = [Math]::Exp(-0.5 * $z * $z) / [Math]::Sqrt(2 * [Math]::PI)
                        $d2k = (($z * $z) - 1) * $k
                        $sum += $d2k
                    }
                }
                $d2f = $sum / ($n * $n * [Math]::Pow($pilotBandwidth, 3))

                # Mettre à jour la largeur de bande
                $bandwidth = [Math]::Pow(1 / ([Math]::Abs($d2f) * $n), 0.2)
            }
        }
        default {
            # Règle de Silverman par défaut
            $bandwidth = 0.9 * $sigma * [Math]::Pow($n, -0.2)
        }
    }

    return $bandwidth
}

<#
.SYNOPSIS
    Calcule l'écart interquartile (IQR) d'une distribution.

.DESCRIPTION
    Cette fonction calcule l'écart interquartile (IQR) d'une distribution,
    qui est la différence entre le troisième quartile (Q3) et le premier quartile (Q1).

.PARAMETER Data
    Les données de la distribution.

.EXAMPLE
    Get-InterquartileRange -Data $data
    Calcule l'écart interquartile de la distribution $data.

.OUTPUTS
    System.Double
#>
function Get-InterquartileRange {
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

    # Calculer les indices des quartiles
    $n = $sortedData.Count
    $q1Index = [Math]::Floor($n * 0.25)
    $q3Index = [Math]::Floor($n * 0.75)

    # Calculer les quartiles
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]

    # Calculer l'écart interquartile
    return $q3 - $q1
}

<#
.SYNOPSIS
    Calcule la fonction de répartition empirique d'une distribution.

.DESCRIPTION
    Cette fonction calcule la fonction de répartition empirique (CDF) d'une distribution.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Points
    Les points où calculer la fonction de répartition (par défaut, 100 points répartis uniformément).

.EXAMPLE
    Get-EmpiricalCDF -Data $data -Points $points
    Calcule la fonction de répartition empirique de la distribution $data aux points $points.

.OUTPUTS
    PSObject
#>
function Get-EmpiricalCDF {
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double[]]$Points = $null
    )

    # Vérifier que les données ne sont pas vides
    if ($Data.Count -eq 0) {
        throw "Les données ne peuvent pas être vides."
    }

    # Créer les points d'évaluation si non spécifiés
    if ($null -eq $Points) {
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        $range = $max - $min
        $padding = $range * 0.1
        $min = $min - $padding
        $max = $max + $padding
        $Points = $min..$max | ForEach-Object { $min + $_ * ($max - $min) / 100 }
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Calculer la fonction de répartition à chaque point
    $cdf = @()
    foreach ($point in $Points) {
        $count = ($sortedData | Where-Object { $_ -le $point }).Count
        $probability = $count / $sortedData.Count
        $cdf += $probability
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Points = $Points
        CDF    = $cdf
        Data   = $Data
    }

    return $result
}

<#
.SYNOPSIS
    Calcule un quantile d'une distribution en utilisant l'estimation par noyau.

.DESCRIPTION
    Cette fonction calcule un quantile d'une distribution en utilisant l'estimation
    par noyau de la fonction de répartition.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Probability
    La probabilité du quantile à calculer (entre 0 et 1).

.PARAMETER Bandwidth
    La largeur de bande (par défaut, sélection automatique par la règle de Silverman).

.PARAMETER Kernel
    Le noyau à utiliser (par défaut "Gaussian").

.PARAMETER Method
    La méthode de calcul du quantile (par défaut "Interpolation").
    Les méthodes disponibles sont :
    - Interpolation : Interpolation linéaire de la fonction de répartition
    - Newton : Méthode de Newton pour trouver le quantile
    - Bisection : Méthode de la bissection pour trouver le quantile

.PARAMETER Tolerance
    La tolérance pour les méthodes itératives (par défaut 1e-6).

.PARAMETER MaxIterations
    Le nombre maximum d'itérations pour les méthodes itératives (par défaut 100).

.EXAMPLE
    Get-KernelQuantile -Data $data -Probability 0.5 -Bandwidth 0.5 -Kernel "Gaussian" -Method "Interpolation"
    Calcule la médiane (quantile 0.5) de la distribution $data en utilisant l'estimation par noyau
    avec un noyau gaussien et une largeur de bande de 0.5.

.OUTPUTS
    System.Double
#>
function Get-KernelQuantile {
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
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$Kernel = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Interpolation", "Newton", "Bisection")]
        [string]$Method = "Interpolation",

        [Parameter(Mandatory = $false)]
        [double]$Tolerance = 1e-6,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 100
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

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        $Bandwidth = Get-OptimalBandwidth -Data $Data -Method "Silverman"
    }

    # Créer les points d'évaluation
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min
    $padding = $range * 0.1
    $min = $min - $padding
    $max = $max + $padding
    $numPoints = 200
    $points = $min..$max | ForEach-Object { $min + $_ * ($max - $min) / $numPoints }

    # Calculer la fonction de répartition par noyau
    $cdf = @()
    $kde = Get-KernelDensity -Data $Data -Points $points -Bandwidth $Bandwidth -Kernel $Kernel
    $densities = $kde.Densities

    # Intégrer la densité pour obtenir la fonction de répartition
    $cumulativeDensity = 0
    for ($i = 0; $i -lt $densities.Count - 1; $i++) {
        $width = $points[$i + 1] - $points[$i]
        $height = ($densities[$i] + $densities[$i + 1]) / 2
        $area = $width * $height
        $cumulativeDensity += $area
        $cdf += $cumulativeDensity
    }

    # Normaliser la fonction de répartition
    if ($cumulativeDensity -gt 0) {
        $cdf = $cdf | ForEach-Object { $_ / $cumulativeDensity }
    } else {
        $cdf = $cdf | ForEach-Object { 0 }
    }

    # Ajouter un point à 0 pour le début de la fonction de répartition
    $cdf = @(0) + $cdf

    # Calculer le quantile selon la méthode choisie
    switch ($Method) {
        "Interpolation" {
            # Méthode de l'interpolation linéaire
            $index = 0
            while ($index -lt $cdf.Count - 1 -and $cdf[$index] -lt $Probability) {
                $index++
            }

            if ($index -eq 0) {
                return $points[0]
            }
            if ($index -eq $cdf.Count - 1) {
                return $points[-1]
            }

            $x1 = $points[$index - 1]
            $x2 = $points[$index]
            $y1 = $cdf[$index - 1]
            $y2 = $cdf[$index]
            $t = ($Probability - $y1) / ($y2 - $y1)
            return $x1 + $t * ($x2 - $x1)
        }
        "Newton" {
            # Méthode de Newton
            $x = $min + $range * $Probability
            for ($i = 0; $i -lt $MaxIterations; $i++) {
                $fx = 0
                $dfx = 0
                foreach ($value in $Data) {
                    $z = ($x - $value) / $Bandwidth
                    $k = [Math]::Exp(-0.5 * $z * $z) / [Math]::Sqrt(2 * [Math]::PI)
                    $fx += $k
                    $dfx += - $z * $k / $Bandwidth
                }
                $fx = $fx / ($Data.Count * $Bandwidth) - $Probability
                $dfx = $dfx / ($Data.Count * $Bandwidth)

                $delta = $fx / $dfx
                $x = $x - $delta

                if ([Math]::Abs($delta) -lt $Tolerance) {
                    break
                }
            }
            return $x
        }
        "Bisection" {
            # Méthode de la bissection
            $a = $min
            $b = $max
            for ($i = 0; $i -lt $MaxIterations; $i++) {
                $c = ($a + $b) / 2

                $fc = 0
                foreach ($value in $Data) {
                    $z = ($c - $value) / $Bandwidth
                    $k = [Math]::Exp(-0.5 * $z * $z) / [Math]::Sqrt(2 * [Math]::PI)
                    $fc += $k
                }
                $fc = $fc / ($Data.Count * $Bandwidth) - $Probability

                if ([Math]::Abs($fc) -lt $Tolerance) {
                    return $c
                }

                $fa = 0
                foreach ($value in $Data) {
                    $z = ($a - $value) / $Bandwidth
                    $k = [Math]::Exp(-0.5 * $z * $z) / [Math]::Sqrt(2 * [Math]::PI)
                    $fa += $k
                }
                $fa = $fa / ($Data.Count * $Bandwidth) - $Probability

                if ($fa * $fc -lt 0) {
                    $b = $c
                } else {
                    $a = $c
                }

                if ($b - $a -lt $Tolerance) {
                    return $c
                }
            }
            return ($a + $b) / 2
        }
        default {
            # Méthode de l'interpolation linéaire par défaut
            $index = 0
            while ($index -lt $cdf.Count - 1 -and $cdf[$index] -lt $Probability) {
                $index++
            }

            if ($index -eq 0) {
                return $points[0]
            }
            if ($index -eq $cdf.Count - 1) {
                return $points[-1]
            }

            $x1 = $points[$index - 1]
            $x2 = $points[$index]
            $y1 = $cdf[$index - 1]
            $y2 = $cdf[$index]
            $t = ($Probability - $y1) / ($y2 - $y1)
            return $x1 + $t * ($x2 - $x1)
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-KernelDensity, Get-OptimalBandwidth, Get-InterquartileRange, Get-EmpiricalCDF, Get-KernelQuantile
