# Test-KernelDensityEstimatePester.ps1
# Pester tests for kernel density estimation

# Function to perform kernel density estimation
function Get-KernelDensityEstimate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "The input data for density estimation.")]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Data,

        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "The points where the density will be evaluated.")]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$EvaluationPoints,

        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The type of kernel to use for density estimation.")]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0
    )

    try {
        # Validate input data
        if ($null -eq $Data -or $Data.Count -eq 0) {
            $errorMessage = "The input data is null or empty."
            throw $errorMessage
        }

        if ($Data.Count -lt 2) {
            $errorMessage = "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
            throw $errorMessage
        }

        # Convert data to double array
        $Data = $Data | ForEach-Object { [double]$_ }

        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                $errorMessage = "The evaluation points are null or empty."
                throw $errorMessage
            }

            # Convert evaluation points to double array
            $EvaluationPoints = $EvaluationPoints | ForEach-Object { [double]$_ }
        } else {
            # Generate evaluation points automatically
            $min = ($Data | Measure-Object -Minimum).Minimum
            $max = ($Data | Measure-Object -Maximum).Maximum
            $range = $max - $min

            # Add a margin to avoid edge effects
            $min = $min - 0.1 * $range
            $max = $max + 0.1 * $range

            # Generate a grid of evaluation points (100 points by default)
            $numPoints = 100
            $step = ($max - $min) / ($numPoints - 1)
            $EvaluationPoints = 0..($numPoints - 1) | ForEach-Object { $min + $_ * $step }
        }

        # Validate bandwidth
        if ($Bandwidth -lt 0) {
            $errorMessage = "The bandwidth is negative: $Bandwidth."
            throw $errorMessage
        }

        # Calculate bandwidth if not provided
        if ($Bandwidth -eq 0) {
            # Calculate the standard deviation of the data
            $mean = ($Data | Measure-Object -Average).Average
            $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

            # Calculate the interquartile range
            $sortedData = $Data | Sort-Object
            $q1Index = [Math]::Floor($sortedData.Count * 0.25)
            $q3Index = [Math]::Floor($sortedData.Count * 0.75)
            $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

            # Calculate the bandwidth using Silverman's rule
            $n = $Data.Count
            $minValue = [Math]::Min($stdDev, $iqr / 1.34)

            # Handle the case where both stdDev and iqr are 0 (all data points are identical)
            if ($minValue -eq 0) {
                # Use a small default bandwidth based on the range of the data
                $range = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
                if ($range -eq 0) {
                    # If all data points are identical, use a small value relative to the data
                    $Bandwidth = [Math]::Max(0.1, [Math]::Abs($Data[0]) * 0.1)
                } else {
                    $Bandwidth = $range * 0.1
                }
            } else {
                $Bandwidth = 0.9 * $minValue * [Math]::Pow($n, -0.2)
            }
        }

        # Initialize the density estimates
        $densityEstimates = New-Object double[] $EvaluationPoints.Count

        # Calculate the density estimates
        for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
            $point = $EvaluationPoints[$i]
            $density = 0

            foreach ($dataPoint in $Data) {
                $x = ($point - $dataPoint) / $Bandwidth

                # Apply the kernel function
                switch ($KernelType) {
                    "Gaussian" {
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                    }
                    "Epanechnikov" {
                        if ([Math]::Abs($x) -le 1) {
                            $kernelValue = 0.75 * (1 - $x * $x)
                        } else {
                            $kernelValue = 0
                        }
                    }
                    "Triangular" {
                        if ([Math]::Abs($x) -le 1) {
                            $kernelValue = 1 - [Math]::Abs($x)
                        } else {
                            $kernelValue = 0
                        }
                    }
                    "Uniform" {
                        if ([Math]::Abs($x) -le 1) {
                            $kernelValue = 0.5
                        } else {
                            $kernelValue = 0
                        }
                    }
                }

                $density += $kernelValue
            }

            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
        }

        # Create the output object
        $result = [PSCustomObject]@{
            Data             = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            KernelType       = $KernelType
            Bandwidth        = $Bandwidth
        }

        return $result
    } catch {
        # Re-throw the exception
        throw
    }
}

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

# Pester tests
Describe "Get-KernelDensityEstimate" {
    BeforeAll {
        # Generate test data
        $script:testData = 1..20 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 -SetSeed 42 }
        $script:normalData = New-NormalDistribution -SampleSize 100 -Mean 0 -StdDev 1 -Seed 42
    }

    Context "Parameter validation" {
        It "Should throw an error when data is null" {
            { Get-KernelDensityEstimate -Data $null } | Should -Throw "The input data is null or empty."
        }

        It "Should throw an error when data is empty" {
            { Get-KernelDensityEstimate -Data @() } | Should -Throw "The input data is null or empty."
        }

        It "Should throw an error when data has less than 2 points" {
            { Get-KernelDensityEstimate -Data @(1) } | Should -Throw "The input data has too few points. Minimum required: 2, Actual: 1."
        }

        It "Should throw an error when evaluation points are null" {
            { Get-KernelDensityEstimate -Data $script:testData -EvaluationPoints $null } | Should -Throw "The evaluation points are null or empty."
        }

        It "Should throw an error when evaluation points are empty" {
            { Get-KernelDensityEstimate -Data $script:testData -EvaluationPoints @() } | Should -Throw "The evaluation points are null or empty."
        }

        It "Should throw an error when bandwidth is negative" {
            { Get-KernelDensityEstimate -Data $script:testData -Bandwidth -1 } | Should -Throw "The bandwidth is negative: -1."
        }
    }

    Context "Default parameters" {
        It "Should return a result with default parameters" {
            $result = Get-KernelDensityEstimate -Data $script:testData
            $result | Should -Not -BeNullOrEmpty
            $result.Data.Count | Should -Be $script:testData.Count
            $result.EvaluationPoints.Count | Should -Be 100
            $result.DensityEstimates.Count | Should -Be 100
            $result.KernelType | Should -Be "Gaussian"
            $result.Bandwidth | Should -BeGreaterThan 0
        }
    }

    Context "Kernel types" {
        It "Should work with Gaussian kernel" {
            $result = Get-KernelDensityEstimate -Data $script:testData -KernelType Gaussian
            $result.KernelType | Should -Be "Gaussian"
        }

        It "Should work with Epanechnikov kernel" {
            $result = Get-KernelDensityEstimate -Data $script:testData -KernelType Epanechnikov
            $result.KernelType | Should -Be "Epanechnikov"
        }

        It "Should work with Triangular kernel" {
            $result = Get-KernelDensityEstimate -Data $script:testData -KernelType Triangular
            $result.KernelType | Should -Be "Triangular"
        }

        It "Should work with Uniform kernel" {
            $result = Get-KernelDensityEstimate -Data $script:testData -KernelType Uniform
            $result.KernelType | Should -Be "Uniform"
        }
    }

    Context "Bandwidth selection" {
        It "Should calculate bandwidth automatically when not provided" {
            $result = Get-KernelDensityEstimate -Data $script:testData
            $result.Bandwidth | Should -BeGreaterThan 0
        }

        It "Should use the provided bandwidth" {
            $bandwidth = 5
            $result = Get-KernelDensityEstimate -Data $script:testData -Bandwidth $bandwidth
            $result.Bandwidth | Should -Be $bandwidth
        }
    }

    Context "Evaluation points" {
        It "Should generate evaluation points automatically when not provided" {
            $result = Get-KernelDensityEstimate -Data $script:testData
            $result.EvaluationPoints.Count | Should -Be 100
        }

        It "Should use the provided evaluation points" {
            $evalPoints = 0..10 | ForEach-Object { $_ * 10 }
            $result = Get-KernelDensityEstimate -Data $script:testData -EvaluationPoints $evalPoints
            $result.EvaluationPoints.Count | Should -Be $evalPoints.Count
            $result.EvaluationPoints | Should -Be $evalPoints
        }
    }

    Context "Density estimation" {
        It "Should produce non-negative density estimates" {
            $result = Get-KernelDensityEstimate -Data $script:testData
            $result.DensityEstimates | ForEach-Object { $_ | Should -BeGreaterOrEqual 0 }
        }

        It "Should produce density estimates that integrate to approximately 1" {
            $result = Get-KernelDensityEstimate -Data $script:normalData

            # Calculate the approximate integral of the density estimates
            $integral = 0
            for ($i = 1; $i -lt $result.EvaluationPoints.Count; $i++) {
                $width = $result.EvaluationPoints[$i] - $result.EvaluationPoints[$i - 1]
                $height = ($result.DensityEstimates[$i] + $result.DensityEstimates[$i - 1]) / 2
                $integral += $width * $height
            }

            # The integral should be approximately 1 (with some tolerance)
            $integral | Should -BeGreaterOrEqual 0.9
            $integral | Should -BeLessOrEqual 1.1
        }
    }
}

# Run the Pester tests if the script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-Pester -Path $PSCommandPath -Output Detailed
}
