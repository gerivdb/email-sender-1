# KernelDensityEstimateTestData.ps1
# Functions to generate test data for kernel density estimation

# Function to generate a normal distribution
function New-NormalDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the normal distribution
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        # Box-Muller transform to generate normal distribution
        $u1 = $random.NextDouble()
        $u2 = $random.NextDouble()

        $z0 = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)

        # Transform to desired mean and standard deviation
        $samples[$i] = $Mean + $StdDev * $z0
    }

    return $samples
}

# Function to generate a uniform distribution
function New-UniformDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Min = 0,

        [Parameter(Mandatory = $false)]
        [double]$Max = 1,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the uniform distribution
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        $samples[$i] = $Min + ($Max - $Min) * $random.NextDouble()
    }

    return $samples
}

# Function to generate an exponential distribution
function New-ExponentialDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Rate = 1,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the exponential distribution
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        $u = $random.NextDouble()
        $samples[$i] = - [Math]::Log($u) / $Rate
    }

    return $samples
}

# Function to generate a gamma distribution
function New-GammaDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Shape = 1,

        [Parameter(Mandatory = $false)]
        [double]$Scale = 1,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the gamma distribution using the Marsaglia and Tsang method
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        if ($Shape -lt 1) {
            # For shape < 1, use the transformation method
            $u = $random.NextDouble()
            $samples[$i] = New-GammaDistribution -SampleSize 1 -Shape ($Shape + 1) -Scale $Scale -Seed ($Seed + $i) | Select-Object -First 1
            $samples[$i] *= [Math]::Pow($u, 1 / $Shape)
        } else {
            # For shape >= 1, use the Marsaglia and Tsang method
            $d = $Shape - 1 / 3
            $c = 1 / [Math]::Sqrt(9 * $d)

            do {
                $z = New-NormalDistribution -SampleSize 1 -Seed ($Seed + $i) | Select-Object -First 1
                $u = $random.NextDouble()
                $v = [Math]::Pow(1 + $c * $z, 3)
                $condition = $z -gt -1 / $c -and [Math]::Log($u) -lt 0.5 * $z * $z + $d - $d * $v + $d * [Math]::Log($v)
            } while (-not $condition)

            $samples[$i] = $d * $v * $Scale
        }
    }

    return $samples
}

# Function to generate a beta distribution
function New-BetaDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 2,

        [Parameter(Mandatory = $false)]
        [double]$Beta = 2,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Generate the beta distribution using the relationship with gamma distributions
    $gammaA = New-GammaDistribution -SampleSize $SampleSize -Shape $Alpha -Scale 1 -Seed $Seed
    $gammaB = New-GammaDistribution -SampleSize $SampleSize -Shape $Beta -Scale 1 -Seed ($Seed + 1)

    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        $samples[$i] = $gammaA[$i] / ($gammaA[$i] + $gammaB[$i])
    }

    return $samples
}

# Function to generate a mixture of normal distributions (multimodal)
function New-MultimodalDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double[]]$Means = @(0, 5),

        [Parameter(Mandatory = $false)]
        [double[]]$StdDevs = @(1, 1),

        [Parameter(Mandatory = $false)]
        [double[]]$Weights = @(0.5, 0.5),

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Validate parameters
    if ($Means.Count -ne $StdDevs.Count -or $Means.Count -ne $Weights.Count) {
        throw "The number of means, standard deviations, and weights must be the same."
    }

    # Normalize weights
    $weightSum = ($Weights | Measure-Object -Sum).Sum
    $normalizedWeights = $Weights | ForEach-Object { $_ / $weightSum }

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the multimodal distribution
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        # Select a component based on the weights
        $u = $random.NextDouble()
        $cumulativeWeight = 0
        $componentIndex = 0

        for ($j = 0; $j -lt $normalizedWeights.Count; $j++) {
            $cumulativeWeight += $normalizedWeights[$j]
            if ($u -le $cumulativeWeight) {
                $componentIndex = $j
                break
            }
        }

        # Generate a sample from the selected component
        $mean = $Means[$componentIndex]
        $stdDev = $StdDevs[$componentIndex]

        $samples[$i] = (New-NormalDistribution -SampleSize 1 -Mean $mean -StdDev $stdDev -Seed ($Seed + $i)) | Select-Object -First 1
    }

    return $samples
}

# Function to generate a skewed normal distribution
function New-SkewedDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Location = 0,

        [Parameter(Mandatory = $false)]
        [double]$Scale = 1,

        [Parameter(Mandatory = $false)]
        [double]$Shape = 5,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Generate normal samples
    $normalSamples = New-NormalDistribution -SampleSize $SampleSize -Mean 0 -StdDev 1 -Seed $Seed
    $absSamples = New-NormalDistribution -SampleSize $SampleSize -Mean 0 -StdDev 1 -Seed ($Seed + 1) | ForEach-Object { [Math]::Abs($_) }

    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        $delta = $Shape / [Math]::Sqrt(1 + $Shape * $Shape)
        $samples[$i] = $Location + $Scale * ($delta * $absSamples[$i] + [Math]::Sqrt(1 - $delta * $delta) * $normalSamples[$i])
    }

    return $samples
}

# Function to generate a bimodal distribution with different shapes
function New-BimodalDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Mean1 = -3,

        [Parameter(Mandatory = $false)]
        [double]$StdDev1 = 1,

        [Parameter(Mandatory = $false)]
        [double]$Mean2 = 3,

        [Parameter(Mandatory = $false)]
        [double]$StdDev2 = 1,

        [Parameter(Mandatory = $false)]
        [double]$Weight = 0.5,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }

    # Generate the bimodal distribution
    $samples = New-Object double[] $SampleSize

    for ($i = 0; $i -lt $SampleSize; $i++) {
        # Select a component based on the weight
        if ($random.NextDouble() -lt $Weight) {
            $samples[$i] = (New-NormalDistribution -SampleSize 1 -Mean $Mean1 -StdDev $StdDev1 -Seed ($Seed + $i)) | Select-Object -First 1
        } else {
            $samples[$i] = (New-NormalDistribution -SampleSize 1 -Mean $Mean2 -StdDev $StdDev2 -Seed ($Seed + $i + $SampleSize)) | Select-Object -First 1
        }
    }

    return $samples
}

# Function to generate a dataset with outliers
function New-DatasetWithOutliers {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1,

        [Parameter(Mandatory = $false)]
        [int]$NumOutliers = 5,

        [Parameter(Mandatory = $false)]
        [double]$OutlierMean = 10,

        [Parameter(Mandatory = $false)]
        [double]$OutlierStdDev = 1,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Generate the main dataset
    $mainSamples = New-NormalDistribution -SampleSize ($SampleSize - $NumOutliers) -Mean $Mean -StdDev $StdDev -Seed $Seed

    # Generate the outliers
    $outlierSamples = New-NormalDistribution -SampleSize $NumOutliers -Mean $OutlierMean -StdDev $OutlierStdDev -Seed ($Seed + $SampleSize)

    # Combine the samples
    $samples = $mainSamples + $outlierSamples

    # Shuffle the samples
    $random = New-Object System.Random($Seed)
    $samples = $samples | Sort-Object { $random.Next() }

    return $samples
}

# Function to generate a dataset from a known theoretical distribution
function New-TheoreticalDistribution {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Uniform", "Exponential", "Gamma", "Beta", "Multimodal", "Skewed", "Bimodal", "WithOutliers")]
        [string]$DistributionType = "Normal",

        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Set default parameters if not provided
    switch ($DistributionType) {
        "Normal" {
            if (-not $Parameters.ContainsKey("Mean")) { $Parameters["Mean"] = 0 }
            if (-not $Parameters.ContainsKey("StdDev")) { $Parameters["StdDev"] = 1 }
            $samples = New-NormalDistribution -SampleSize $SampleSize -Mean $Parameters["Mean"] -StdDev $Parameters["StdDev"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $mean = $parameters["Mean"]
                $stdDev = $parameters["StdDev"]
                return (1 / ($stdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $mean) / $stdDev, 2))
            }
        }
        "Uniform" {
            if (-not $Parameters.ContainsKey("Min")) { $Parameters["Min"] = 0 }
            if (-not $Parameters.ContainsKey("Max")) { $Parameters["Max"] = 1 }
            $samples = New-UniformDistribution -SampleSize $SampleSize -Min $Parameters["Min"] -Max $Parameters["Max"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $min = $parameters["Min"]
                $max = $parameters["Max"]
                if ($x -ge $min -and $x -le $max) {
                    return 1 / ($max - $min)
                } else {
                    return 0
                }
            }
        }
        "Exponential" {
            if (-not $Parameters.ContainsKey("Rate")) { $Parameters["Rate"] = 1 }
            $samples = New-ExponentialDistribution -SampleSize $SampleSize -Rate $Parameters["Rate"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $rate = $parameters["Rate"]
                if ($x -ge 0) {
                    return $rate * [Math]::Exp(-$rate * $x)
                } else {
                    return 0
                }
            }
        }
        "Gamma" {
            if (-not $Parameters.ContainsKey("Shape")) { $Parameters["Shape"] = 1 }
            if (-not $Parameters.ContainsKey("Scale")) { $Parameters["Scale"] = 1 }
            $samples = New-GammaDistribution -SampleSize $SampleSize -Shape $Parameters["Shape"] -Scale $Parameters["Scale"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $shape = $parameters["Shape"]
                $scale = $parameters["Scale"]
                if ($x -gt 0) {
                    $gamma = [Math]::Exp([Math]::Log($x) * ($shape - 1) - $x / $scale - [Math]::Log($scale) * $shape - [Math]::Log([Math]::Gamma($shape)))
                    return $gamma
                } else {
                    return 0
                }
            }
        }
        "Beta" {
            if (-not $Parameters.ContainsKey("Alpha")) { $Parameters["Alpha"] = 2 }
            if (-not $Parameters.ContainsKey("Beta")) { $Parameters["Beta"] = 2 }
            $samples = New-BetaDistribution -SampleSize $SampleSize -Alpha $Parameters["Alpha"] -Beta $Parameters["Beta"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $alpha = $parameters["Alpha"]
                $beta = $parameters["Beta"]
                if ($x -gt 0 -and $x -lt 1) {
                    $betaFunc = [Math]::Exp([Math]::Log($x) * ($alpha - 1) + [Math]::Log(1 - $x) * ($beta - 1) - [Math]::Log([Math]::Beta($alpha, $beta)))
                    return $betaFunc
                } else {
                    return 0
                }
            }
        }
        "Multimodal" {
            if (-not $Parameters.ContainsKey("Means")) { $Parameters["Means"] = @(0, 5) }
            if (-not $Parameters.ContainsKey("StdDevs")) { $Parameters["StdDevs"] = @(1, 1) }
            if (-not $Parameters.ContainsKey("Weights")) { $Parameters["Weights"] = @(0.5, 0.5) }
            $samples = New-MultimodalDistribution -SampleSize $SampleSize -Means $Parameters["Means"] -StdDevs $Parameters["StdDevs"] -Weights $Parameters["Weights"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $means = $parameters["Means"]
                $stdDevs = $parameters["StdDevs"]
                $weights = $parameters["Weights"]
                $weightSum = ($weights | Measure-Object -Sum).Sum
                $normalizedWeights = $weights | ForEach-Object { $_ / $weightSum }

                $result = 0
                for ($i = 0; $i -lt $means.Count; $i++) {
                    $mean = $means[$i]
                    $stdDev = $stdDevs[$i]
                    $weight = $normalizedWeights[$i]
                    $result += $weight * (1 / ($stdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $mean) / $stdDev, 2))
                }
                return $result
            }
        }
        "Skewed" {
            if (-not $Parameters.ContainsKey("Location")) { $Parameters["Location"] = 0 }
            if (-not $Parameters.ContainsKey("Scale")) { $Parameters["Scale"] = 1 }
            if (-not $Parameters.ContainsKey("Shape")) { $Parameters["Shape"] = 5 }
            $samples = New-SkewedDistribution -SampleSize $SampleSize -Location $Parameters["Location"] -Scale $Parameters["Scale"] -Shape $Parameters["Shape"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                # Approximation of the skewed normal PDF
                $location = $parameters["Location"]
                $scale = $parameters["Scale"]
                $shape = $parameters["Shape"]

                $z = ($x - $location) / $scale
                $normalPdf = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $z * $z)
                $normalCdf = 0.5 * (1 + [Math]::Erf($shape * $z / [Math]::Sqrt(2)))

                return (2 / $scale) * $normalPdf * $normalCdf
            }
        }
        "Bimodal" {
            if (-not $Parameters.ContainsKey("Mean1")) { $Parameters["Mean1"] = -3 }
            if (-not $Parameters.ContainsKey("StdDev1")) { $Parameters["StdDev1"] = 1 }
            if (-not $Parameters.ContainsKey("Mean2")) { $Parameters["Mean2"] = 3 }
            if (-not $Parameters.ContainsKey("StdDev2")) { $Parameters["StdDev2"] = 1 }
            if (-not $Parameters.ContainsKey("Weight")) { $Parameters["Weight"] = 0.5 }
            $samples = New-BimodalDistribution -SampleSize $SampleSize -Mean1 $Parameters["Mean1"] -StdDev1 $Parameters["StdDev1"] -Mean2 $Parameters["Mean2"] -StdDev2 $Parameters["StdDev2"] -Weight $Parameters["Weight"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $mean1 = $parameters["Mean1"]
                $stdDev1 = $parameters["StdDev1"]
                $mean2 = $parameters["Mean2"]
                $stdDev2 = $parameters["StdDev2"]
                $weight = $parameters["Weight"]

                $pdf1 = (1 / ($stdDev1 * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $mean1) / $stdDev1, 2))
                $pdf2 = (1 / ($stdDev2 * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $mean2) / $stdDev2, 2))

                return $weight * $pdf1 + (1 - $weight) * $pdf2
            }
        }
        "WithOutliers" {
            if (-not $Parameters.ContainsKey("Mean")) { $Parameters["Mean"] = 0 }
            if (-not $Parameters.ContainsKey("StdDev")) { $Parameters["StdDev"] = 1 }
            if (-not $Parameters.ContainsKey("NumOutliers")) { $Parameters["NumOutliers"] = 5 }
            if (-not $Parameters.ContainsKey("OutlierMean")) { $Parameters["OutlierMean"] = 10 }
            if (-not $Parameters.ContainsKey("OutlierStdDev")) { $Parameters["OutlierStdDev"] = 1 }
            $samples = New-DatasetWithOutliers -SampleSize $SampleSize -Mean $Parameters["Mean"] -StdDev $Parameters["StdDev"] -NumOutliers $Parameters["NumOutliers"] -OutlierMean $Parameters["OutlierMean"] -OutlierStdDev $Parameters["OutlierStdDev"] -Seed $Seed
            $theoreticalFunction = {
                param($x, $parameters)
                $mean = $parameters["Mean"]
                $stdDev = $parameters["StdDev"]
                $numOutliers = $parameters["NumOutliers"]
                $outlierMean = $parameters["OutlierMean"]
                $outlierStdDev = $parameters["OutlierStdDev"]
                $sampleSize = $parameters["SampleSize"]

                $mainWeight = ($sampleSize - $numOutliers) / $sampleSize
                $outlierWeight = $numOutliers / $sampleSize

                $mainPdf = (1 / ($stdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $mean) / $stdDev, 2))
                $outlierPdf = (1 / ($outlierStdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * [Math]::Pow(($x - $outlierMean) / $outlierStdDev, 2))

                return $mainWeight * $mainPdf + $outlierWeight * $outlierPdf
            }
        }
    }

    # Add the sample size to the parameters for use in the theoretical function
    $Parameters["SampleSize"] = $SampleSize

    # Create the result object
    $result = [PSCustomObject]@{
        DistributionType    = $DistributionType
        Parameters          = $Parameters
        Samples             = $samples
        TheoreticalFunction = $theoreticalFunction
    }

    return $result
}

# Function to generate a test dataset collection
function New-TestDatasetCollection {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )

    # Create a collection of test datasets
    $datasets = @(
        New-TheoreticalDistribution -DistributionType "Normal" -SampleSize $SampleSize -Parameters @{ Mean = 0; StdDev = 1 } -Seed $Seed
        New-TheoreticalDistribution -DistributionType "Uniform" -SampleSize $SampleSize -Parameters @{ Min = -3; Max = 3 } -Seed ($Seed + 1)
        New-TheoreticalDistribution -DistributionType "Exponential" -SampleSize $SampleSize -Parameters @{ Rate = 0.5 } -Seed ($Seed + 2)
        New-TheoreticalDistribution -DistributionType "Gamma" -SampleSize $SampleSize -Parameters @{ Shape = 2; Scale = 2 } -Seed ($Seed + 3)
        New-TheoreticalDistribution -DistributionType "Beta" -SampleSize $SampleSize -Parameters @{ Alpha = 2; Beta = 5 } -Seed ($Seed + 4)
        New-TheoreticalDistribution -DistributionType "Multimodal" -SampleSize $SampleSize -Parameters @{ Means = @(-5, 0, 5); StdDevs = @(1, 1, 1); Weights = @(0.3, 0.4, 0.3) } -Seed ($Seed + 5)
        New-TheoreticalDistribution -DistributionType "Skewed" -SampleSize $SampleSize -Parameters @{ Location = 0; Scale = 1; Shape = 5 } -Seed ($Seed + 6)
        New-TheoreticalDistribution -DistributionType "Bimodal" -SampleSize $SampleSize -Parameters @{ Mean1 = -3; StdDev1 = 1; Mean2 = 3; StdDev2 = 1; Weight = 0.5 } -Seed ($Seed + 7)
        New-TheoreticalDistribution -DistributionType "WithOutliers" -SampleSize $SampleSize -Parameters @{ Mean = 0; StdDev = 1; NumOutliers = 5; OutlierMean = 10; OutlierStdDev = 1 } -Seed ($Seed + 8)
    )

    return $datasets
}

# Export functions if the script is imported as a module
if ($MyInvocation.InvocationName -ne $MyInvocation.MyCommand.Name) {
    Export-ModuleMember -Function New-NormalDistribution, New-UniformDistribution, New-ExponentialDistribution, New-GammaDistribution, New-BetaDistribution, New-MultimodalDistribution, New-SkewedDistribution, New-BimodalDistribution, New-DatasetWithOutliers, New-TheoreticalDistribution, New-TestDatasetCollection
}
