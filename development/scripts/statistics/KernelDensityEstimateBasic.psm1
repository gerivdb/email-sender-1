# Module KernelDensityEstimateBasic.psm1
# Module for Kernel Density Estimation (Basic Version)

<#
.SYNOPSIS
    Estimates the probability density function of a random variable from a sample using kernel density estimation.

.DESCRIPTION
    The Get-KernelDensityEstimateBasic function implements a basic version of Kernel Density Estimation (KDE),
    a non-parametric method to estimate the probability density function of a random variable from a sample.

    Kernel density estimation is a generalization of histograms that provides a smooth estimate of the
    probability density function. It works by placing a kernel (a smooth, symmetric function) at each
    data point and then summing these kernels to obtain the density estimate.

    This function uses the Gaussian kernel, which is the standard normal probability density function.
    The bandwidth parameter controls the width of the kernel and thus the smoothness of the resulting
    density estimate. A larger bandwidth results in a smoother estimate but may obscure important
    features of the data, while a smaller bandwidth can reveal more detail but may introduce noise.

    If the bandwidth is not specified, it is automatically determined using Silverman's rule of thumb,
    which is a simple and widely used method for bandwidth selection.

    The function returns a rich object containing the density estimates, the parameters used, and
    various statistics about the data and the estimation process.

.PARAMETER Data
    The input data for density estimation. Must be an array of numeric values with at least 2 data points.
    This parameter is mandatory.

.PARAMETER EvaluationPoints
    The points where the density will be evaluated. If not specified, the function automatically
    generates a grid of 100 points based on the input data, with a margin of 10% on each side to
    avoid edge effects.

    This parameter is optional.

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. The bandwidth controls the width of the kernel and
    thus the smoothness of the resulting density estimate. A larger bandwidth results in a smoother
    estimate but may obscure important features of the data, while a smaller bandwidth can reveal
    more detail but may introduce noise.

    If not specified (or set to 0), the bandwidth will be automatically determined using Silverman's
    rule of thumb, which is a simple and widely used method for bandwidth selection.

    This parameter is optional and must be non-negative.

.EXAMPLE
    # Generate some random data
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

    # Estimate the density using default parameters
    $density = Get-KernelDensityEstimateBasic -Data $data

    # Display the results
    $density.Parameters
    $density.Statistics

    # This example estimates the probability density function of a sample of 100 random values
    # between 0 and 100 using the default parameters (Gaussian kernel, automatic bandwidth selection).

.EXAMPLE
    # Generate some random data
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

    # Estimate the density with a custom bandwidth
    $density = Get-KernelDensityEstimateBasic -Data $data -Bandwidth 5

    # Display the results
    $density.Parameters
    $density.Statistics

    # This example estimates the probability density function of a sample of 100 random values
    # between 0 and 100 using a custom bandwidth of 5.

.EXAMPLE
    # Generate some random data
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

    # Define custom evaluation points
    $evalPoints = 0..10 | ForEach-Object { $_ * 10 }  # 0, 10, 20, ..., 100

    # Estimate the density at the custom evaluation points
    $density = Get-KernelDensityEstimateBasic -Data $data -EvaluationPoints $evalPoints

    # Display the results
    $density.EvaluationPoints
    $density.DensityEstimates

    # This example estimates the probability density function of a sample of 100 random values
    # between 0 and 100 at specific evaluation points (0, 10, 20, ..., 100).

.INPUTS
    System.Double[]
    You can pipe an array of double values to Get-KernelDensityEstimateBasic.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    Get-KernelDensityEstimateBasic returns a PSCustomObject with the following properties:
    - Data: The input data
    - EvaluationPoints: The points where the density was evaluated
    - DensityEstimates: The estimated density at each evaluation point
    - Parameters: The parameters used for the estimation (KernelType, Bandwidth)
    - Statistics: Various statistics about the data and the estimation process
    - Metadata: Additional information about the results

.NOTES
    Author: Augment Code
    Date: 2023-05-16
    Version: 1.0

    The function uses the Gaussian kernel, which is the standard normal probability density function.
    For more advanced kernel density estimation, including different kernels and bandwidth selection
    methods, see the full version of the function.

    References:
    - Silverman, B. W. (1986). Density Estimation for Statistics and Data Analysis. Chapman & Hall/CRC.
    - Scott, D. W. (2015). Multivariate Density Estimation: Theory, Practice, and Visualization. John Wiley & Sons.

.LINK
    https://en.wikipedia.org/wiki/Kernel_density_estimation
    https://en.wikipedia.org/wiki/Kernel_(statistics)
    https://en.wikipedia.org/wiki/Bandwidth_(statistics)
#>
function Get-KernelDensityEstimateBasic {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "The input data for density estimation.")]
        [ValidateNotNullOrEmpty()]
        [double[]]$Data,

        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "The points where the density will be evaluated.")]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0
    )

    begin {
        # Initialization code
        Write-Verbose "Initializing kernel density estimation"

        # Validate input data
        if ($Data.Count -lt 2) {
            throw "Kernel density estimation requires at least 2 data points."
        }

        # Validate Bandwidth
        if ($Bandwidth -lt 0) {
            throw "Bandwidth must be non-negative."
        }

        # Start execution timer
        $startTime = Get-Date
    }

    process {
        # Main processing
        Write-Verbose "Processing data for kernel density estimation"

        # If evaluation points are not specified, generate them automatically
        if (-not $EvaluationPoints) {
            # Calculate basic statistics of the data
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

            Write-Verbose "Evaluation points generated: $($EvaluationPoints.Count) points from $min to $max"
        }

        # If bandwidth is not specified, calculate it using Silverman's rule of thumb
        if ($Bandwidth -eq 0) {
            # Calculate the standard deviation of the data
            $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

            # Calculate the interquartile range
            $sortedData = $Data | Sort-Object
            $q1Index = [Math]::Floor($sortedData.Count * 0.25)
            $q3Index = [Math]::Floor($sortedData.Count * 0.75)
            $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

            # Calculate the bandwidth using Silverman's rule
            $n = $Data.Count
            $Bandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2)

            Write-Verbose "Bandwidth calculated using Silverman's rule: $Bandwidth"
        }

        # Initialize the density estimates
        $densityEstimates = New-Object double[] $EvaluationPoints.Count

        # Calculate the density estimates using the Gaussian kernel
        for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
            $point = $EvaluationPoints[$i]
            $density = 0

            foreach ($dataPoint in $Data) {
                $x = ($point - $dataPoint) / $Bandwidth
                $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                $density += $kernelValue
            }

            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
        }
    }

    end {
        # Finalization and return of results
        Write-Verbose "Finalizing kernel density estimation"

        # Calculate execution time
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        Write-Verbose "Execution time: $executionTime seconds"

        # Create the output object with a well-defined structure
        $result = [PSCustomObject]@{
            # Input data and results
            Data             = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates

            # Parameters used for the estimation
            Parameters       = [PSCustomObject]@{
                KernelType = "Gaussian"
                Bandwidth  = $Bandwidth
            }

            # Statistics about the data and execution
            Statistics       = [PSCustomObject]@{
                # Data statistics
                DataCount     = $Data.Count
                DataMin       = ($Data | Measure-Object -Minimum).Minimum
                DataMax       = ($Data | Measure-Object -Maximum).Maximum
                DataRange     = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
                DataMean      = ($Data | Measure-Object -Average).Average
                DataMedian    = $Data | Sort-Object | Select-Object -Index ([Math]::Floor($Data.Count / 2))
                DataStdDev    = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

                # Execution statistics
                ExecutionTime = $executionTime
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            # Additional information
            Metadata         = [PSCustomObject]@{
                Title       = "Kernel Density Estimation Results"
                Description = "Results of kernel density estimation using the Gaussian kernel"
                CreatedBy   = $env:USERNAME
                CreatedOn   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version     = "1.0"
            }
        }

        return $result
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimateBasic
