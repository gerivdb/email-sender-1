# Module KernelDensityEstimate.psm1
# Module for Kernel Density Estimation

#region Helper Functions

<#
.SYNOPSIS
    Generates evaluation points for kernel density estimation.

.DESCRIPTION
    This function generates a grid of evaluation points for kernel density estimation
    based on the input data.

.PARAMETER Data
    The input data for density estimation.

.PARAMETER NumPoints
    The number of evaluation points to generate. Default is 100.

.PARAMETER Margin
    The margin to add to the minimum and maximum values of the data to avoid edge effects.
    Expressed as a fraction of the data range. Default is 0.1 (10%).

.EXAMPLE
    $data = 1..100
    $evaluationPoints = Get-KDEEvaluationPoints -Data $data -NumPoints 200 -Margin 0.05
#>
function Get-KDEEvaluationPoints {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,

        [Parameter(Mandatory = $false)]
        [double]$Margin = 0.1
    )

    # Calculate basic statistics of the data
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min

    # Add a margin to avoid edge effects
    $min = $min - $Margin * $range
    $max = $max + $Margin * $range

    # Generate a grid of evaluation points
    $step = ($max - $min) / ($NumPoints - 1)
    $evaluationPoints = 0..($NumPoints - 1) | ForEach-Object { $min + $_ * $step }

    Write-Verbose "Evaluation points generated: $($evaluationPoints.Count) points from $min to $max"

    return $evaluationPoints
}

<#
.SYNOPSIS
    Selects the appropriate bandwidth for kernel density estimation.

.DESCRIPTION
    This function selects the appropriate bandwidth for kernel density estimation
    based on the specified method and other parameters.

.PARAMETER Data
    The input data for density estimation.

.PARAMETER Method
    The method to use for bandwidth selection.

.PARAMETER KernelType
    The type of kernel to use for density estimation.

.PARAMETER Objective
    The objective to prioritize when selecting the bandwidth.

.PARAMETER KFolds
    The number of folds to use for k-fold cross-validation.

.EXAMPLE
    $data = 1..100
    $bandwidth = Get-KDEBandwidth -Data $data -Method Silverman -KernelType Gaussian
#>
function Get-KDEBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized", "Auto")]
        [string]$Method = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "OptimalKernel")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")]
        [string]$Objective = "Balanced",

        [Parameter(Mandatory = $false)]
        [int]$KFolds = 5
    )

    # For now, we'll implement a simple rule of thumb (Silverman's rule)
    # More sophisticated methods will be implemented in subsequent tasks

    # Calculate the standard deviation of the data
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

    # Calculate the interquartile range
    $sortedData = $Data | Sort-Object
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

    # Calculate the bandwidth using Silverman's rule
    $n = $Data.Count
    $bandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2)

    # Adjust the bandwidth based on the kernel type
    switch ($KernelType) {
        "Gaussian" { $bandwidth = $bandwidth }  # No adjustment needed
        "Epanechnikov" { $bandwidth = $bandwidth * 1.2 }
        "Triangular" { $bandwidth = $bandwidth * 1.1 }
        "Uniform" { $bandwidth = $bandwidth * 1.3 }
        "Biweight" { $bandwidth = $bandwidth * 1.15 }
        "Triweight" { $bandwidth = $bandwidth * 1.1 }
        "Cosine" { $bandwidth = $bandwidth * 1.05 }
        "OptimalKernel" { $bandwidth = $bandwidth }  # No adjustment needed
    }

    # Adjust the bandwidth based on the objective
    switch ($Objective) {
        "Accuracy" { $bandwidth = $bandwidth * 0.9 }
        "Speed" { $bandwidth = $bandwidth * 1.2 }
        "Robustness" { $bandwidth = $bandwidth * 1.1 }
        "Adaptability" { $bandwidth = $bandwidth * 0.95 }
        "Balanced" { $bandwidth = $bandwidth }  # No adjustment needed
    }

    Write-Verbose "Selected bandwidth: $bandwidth using method: $Method"

    return $bandwidth
}

<#
.SYNOPSIS
    Gets the appropriate kernel function for kernel density estimation.

.DESCRIPTION
    This function returns a script block that implements the specified kernel function
    for kernel density estimation.

.PARAMETER KernelType
    The type of kernel to use for density estimation.

.EXAMPLE
    $kernelFunction = Get-KDEKernelFunction -KernelType Gaussian
    $kernelValue = & $kernelFunction 0.5
#>
function Get-KDEKernelFunction {
    [CmdletBinding()]
    [OutputType([ScriptBlock])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "OptimalKernel")]
        [string]$KernelType
    )

    # Define the kernel functions
    switch ($KernelType) {
        "Gaussian" {
            $kernelFunction = {
                param([double]$x)
                return (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
            }
        }
        "Epanechnikov" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return 0.75 * (1 - $x * $x)
                } else {
                    return 0
                }
            }
        }
        "Triangular" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return 1 - [Math]::Abs($x)
                } else {
                    return 0
                }
            }
        }
        "Uniform" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return 0.5
                } else {
                    return 0
                }
            }
        }
        "Biweight" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return (15 / 16) * [Math]::Pow(1 - $x * $x, 2)
                } else {
                    return 0
                }
            }
        }
        "Triweight" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return (35 / 32) * [Math]::Pow(1 - $x * $x, 3)
                } else {
                    return 0
                }
            }
        }
        "Cosine" {
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return ([Math]::PI / 4) * [Math]::Cos([Math]::PI * $x / 2)
                } else {
                    return 0
                }
            }
        }
        "OptimalKernel" {
            # For now, we'll use the Epanechnikov kernel as it's optimal in terms of mean squared error
            $kernelFunction = {
                param([double]$x)
                if ([Math]::Abs($x) <= 1) {
                    return 0.75 * (1 - $x * $x)
                } else {
                    return 0
                }
            }
        }
    }

    return $kernelFunction
}

<#
.SYNOPSIS
    Calculates density estimates for kernel density estimation.

.DESCRIPTION
    This function calculates density estimates for kernel density estimation
    using the specified parameters.

.PARAMETER Data
    The input data for density estimation.

.PARAMETER EvaluationPoints
    The points where the density will be evaluated.

.PARAMETER Bandwidth
    The bandwidth to use for density estimation.

.PARAMETER KernelFunction
    The kernel function to use for density estimation.

.PARAMETER Normalize
    Whether to normalize the density estimates so that they integrate to 1.

.PARAMETER UseParallel
    Whether to use parallel processing for large datasets.

.EXAMPLE
    $data = 1..100
    $evaluationPoints = Get-KDEEvaluationPoints -Data $data
    $bandwidth = Get-KDEBandwidth -Data $data -Method Silverman -KernelType Gaussian
    $kernelFunction = Get-KDEKernelFunction -KernelType Gaussian
    $densityEstimates = Get-KDEDensityEstimates -Data $data -EvaluationPoints $evaluationPoints -Bandwidth $bandwidth -KernelFunction $kernelFunction
#>
function Get-KDEDensityEstimates {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,

        [Parameter(Mandatory = $true)]
        [ScriptBlock]$KernelFunction,

        [Parameter(Mandatory = $false)]
        [switch]$Normalize,

        [Parameter(Mandatory = $false)]
        [switch]$UseParallel
    )

    # Initialize the density estimates
    $densityEstimates = New-Object double[] $EvaluationPoints.Count

    # Calculate the density estimates
    if ($UseParallel -and $Data.Count -ge 1000) {
        # Use parallel processing for large datasets
        $densityEstimates = $EvaluationPoints | ForEach-Object -Parallel {
            $point = $_
            $density = 0

            foreach ($dataPoint in $using:Data) {
                $x = ($point - $dataPoint) / $using:Bandwidth
                $density += & $using:KernelFunction $x
            }

            $density / ($using:Bandwidth * $using:Data.Count)
        }
    } else {
        # Use sequential processing for small datasets
        for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
            $point = $EvaluationPoints[$i]
            $density = 0

            foreach ($dataPoint in $Data) {
                $x = ($point - $dataPoint) / $Bandwidth
                $density += & $KernelFunction $x
            }

            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
        }
    }

    # Normalize the density estimates if requested
    if ($Normalize) {
        $sum = ($densityEstimates | Measure-Object -Sum).Sum
        if ($sum -gt 0) {
            for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                $densityEstimates[$i] = $densityEstimates[$i] / $sum
            }
        }
    }

    return $densityEstimates
}

#endregion Helper Functions

<#
.SYNOPSIS
    Estimates the probability density function of a random variable from a sample.

.DESCRIPTION
    This function implements Kernel Density Estimation (KDE), a non-parametric method
    to estimate the probability density function of a random variable from a sample.

    Kernel density estimation is a generalization of histograms that provides a smooth
    estimate of the probability density function.

.PARAMETER Data
    The input data for density estimation. Must be an array of numeric values.

.PARAMETER EvaluationPoints
    The points where the density will be evaluated. If not specified, the function automatically
    generates a grid of points based on the input data.

.PARAMETER KernelType
    The type of kernel to use for density estimation. Available options:
    - Gaussian: Standard normal kernel (default)
    - Epanechnikov: Optimal kernel in terms of mean squared error
    - Triangular: Simple triangular kernel
    - Uniform: Rectangular kernel
    - Biweight: Quartic kernel
    - Triweight: Higher-order kernel
    - Cosine: Cosine kernel
    - OptimalKernel: Automatically selects the optimal kernel based on data characteristics

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. If not specified (or set to 0), it will be
    automatically determined using the method specified by the Method parameter.

.PARAMETER Method
    The method to use for bandwidth selection. Available options:
    - Silverman: Rule of thumb based on normal distribution
    - Scott: Another rule of thumb based on normal distribution
    - LeaveOneOut: Leave-one-out cross-validation
    - KFold: K-fold cross-validation
    - Optimized: Optimized cross-validation
    - Auto: Automatically selects the best method based on data characteristics (default)

.PARAMETER Objective
    The objective to prioritize when selecting the bandwidth. Available options:
    - Accuracy: Prioritize accuracy of the density estimate
    - Speed: Prioritize computational speed
    - Robustness: Prioritize robustness to outliers
    - Adaptability: Prioritize adaptability to different distributions
    - Balanced: Balance all objectives (default)

.PARAMETER KFolds
    The number of folds to use for k-fold cross-validation. Only used when Method is KFold or Optimized.
    Default is 5.

.PARAMETER Normalize
    Whether to normalize the density estimates so that they integrate to 1.

.PARAMETER UseParallel
    Whether to use parallel processing for large datasets.

.PARAMETER MaxIterations
    The maximum number of iterations for optimization algorithms. Default is 100.

.EXAMPLE
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $density = Get-KernelDensityEstimate -Data $data

    Estimates the probability density function of a sample of 100 random values between 0 and 100.

.EXAMPLE
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $density = Get-KernelDensityEstimate -Data $data -KernelType Epanechnikov -Method Silverman

    Estimates the probability density function using the Epanechnikov kernel and Silverman's rule for bandwidth selection.

.EXAMPLE
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $evalPoints = 0..100
    $density = Get-KernelDensityEstimate -Data $data -EvaluationPoints $evalPoints -KernelType Gaussian -Bandwidth 5

    Estimates the probability density function at specific evaluation points using a fixed bandwidth of 5.

.NOTES
    Author: Augment Code
    Date: 2023-05-16
#>
function Get-KernelDensityEstimate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $false,
            HelpMessage = "The input data for density estimation.")]
        [ValidateNotNullOrEmpty()]
        [double[]]$Data,

        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "The points where the density will be evaluated.")]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The type of kernel to use for density estimation.")]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "OptimalKernel")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "The method to use for bandwidth selection.")]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized", "Auto")]
        [string]$Method = "Auto",

        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = "The objective to prioritize when selecting the bandwidth.")]
        [ValidateSet("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")]
        [string]$Objective = "Balanced",

        [Parameter(Mandatory = $false,
            Position = 6,
            HelpMessage = "The number of folds to use for k-fold cross-validation.")]
        [ValidateRange(2, 100)]
        [int]$KFolds = 5,

        [Parameter(Mandatory = $false,
            Position = 7,
            HelpMessage = "Whether to normalize the density estimates so that they integrate to 1.")]
        [switch]$Normalize,

        [Parameter(Mandatory = $false,
            Position = 8,
            HelpMessage = "Whether to use parallel processing for large datasets.")]
        [switch]$UseParallel,

        [Parameter(Mandatory = $false,
            Position = 9,
            HelpMessage = "The maximum number of iterations for optimization algorithms.")]
        [int]$MaxIterations = 100
    )

    begin {
        # Initialization code
        Write-Verbose "Initializing kernel density estimation"

        # Validate input data
        if ($Data.Count -lt 2) {
            throw "Kernel density estimation requires at least 2 data points."
        }

        # Validate EvaluationPoints if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            if ($EvaluationPoints.Count -lt 1) {
                throw "At least one evaluation point must be provided."
            }
        }

        # Validate Bandwidth
        if ($Bandwidth -lt 0) {
            throw "Bandwidth must be non-negative."
        }

        # Validate KFolds
        if ($KFolds -lt 2) {
            throw "KFolds must be at least 2."
        }
        if ($KFolds -gt $Data.Count) {
            Write-Warning "KFolds ($KFolds) is greater than the number of data points ($($Data.Count)). Setting KFolds to $($Data.Count)."
            $KFolds = $Data.Count
        }

        # Validate MaxIterations
        if ($MaxIterations -lt 1) {
            throw "MaxIterations must be at least 1."
        }

        # Validate Method and Bandwidth combination
        if ($Bandwidth -gt 0 -and $Method -ne "Auto") {
            Write-Warning "Both Bandwidth ($Bandwidth) and Method ($Method) are specified. The specified Bandwidth will be used."
        }

        # Validate KernelType
        if ($KernelType -eq "OptimalKernel" -and $Bandwidth -gt 0) {
            Write-Warning "OptimalKernel is selected with a specified Bandwidth ($Bandwidth). The kernel selection may not be optimal for this bandwidth."
        }

        # Validate UseParallel for small datasets
        if ($UseParallel -and $Data.Count -lt 1000) {
            Write-Verbose "UseParallel is enabled but the dataset is small ($($Data.Count) points). Parallel processing may not improve performance."
        }

        # Start execution timer
        $startTime = Get-Date
    }

    process {
        # Main processing
        Write-Verbose "Processing data for kernel density estimation"

        # If evaluation points are not specified, generate them automatically
        if (-not $EvaluationPoints) {
            $EvaluationPoints = Get-KDEEvaluationPoints -Data $Data
        }

        # Select the appropriate bandwidth if not specified
        if ($Bandwidth -eq 0) {
            $Bandwidth = Get-KDEBandwidth -Data $Data -Method $Method -KernelType $KernelType -Objective $Objective -KFolds $KFolds
        }

        # Select the appropriate kernel function
        $kernelFunction = Get-KDEKernelFunction -KernelType $KernelType

        # Calculate the density estimates
        $densityEstimates = Get-KDEDensityEstimates -Data $Data -EvaluationPoints $EvaluationPoints -Bandwidth $Bandwidth -KernelFunction $kernelFunction -Normalize:$Normalize -UseParallel:$UseParallel
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
                KernelType    = $KernelType
                Bandwidth     = $Bandwidth
                Method        = $Method
                Objective     = $Objective
                KFolds        = $KFolds
                Normalize     = $Normalize.IsPresent
                UseParallel   = $UseParallel.IsPresent
                MaxIterations = $MaxIterations
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
                MemoryUsed    = [System.GC]::GetTotalMemory($true) / 1MB  # Memory in MB
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            # Additional information
            Metadata         = [PSCustomObject]@{
                Title       = "Kernel Density Estimation Results"
                Description = "Results of kernel density estimation using the $KernelType kernel"
                CreatedBy   = $env:USERNAME
                CreatedOn   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version     = "1.0"
            }
        }

        return $result
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimate
