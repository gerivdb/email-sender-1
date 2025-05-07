# Module KernelDensityEstimateSimple.psm1
# Module for Kernel Density Estimation (Simplified Version)

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

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. If not specified (or set to 0), it will be
    automatically determined using Silverman's rule of thumb.

.PARAMETER Normalize
    Whether to normalize the density estimates so that they integrate to 1.

.EXAMPLE
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $density = Get-KernelDensityEstimate -Data $data
    
    Estimates the probability density function of a sample of 100 random values between 0 and 100.

.EXAMPLE
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $density = Get-KernelDensityEstimate -Data $data -KernelType Epanechnikov
    
    Estimates the probability density function using the Epanechnikov kernel.

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
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform")]
        [string]$KernelType = "Gaussian",
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0,
        
        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "Whether to normalize the density estimates so that they integrate to 1.")]
        [switch]$Normalize
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
                        if ([Math]::Abs($x) <= 1) {
                            $kernelValue = 0.75 * (1 - $x * $x)
                        } else {
                            $kernelValue = 0
                        }
                    }
                    "Triangular" {
                        if ([Math]::Abs($x) <= 1) {
                            $kernelValue = 1 - [Math]::Abs($x)
                        } else {
                            $kernelValue = 0
                        }
                    }
                    "Uniform" {
                        if ([Math]::Abs($x) <= 1) {
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
        
        # Normalize the density estimates if requested
        if ($Normalize) {
            $sum = ($densityEstimates | Measure-Object -Sum).Sum
            if ($sum -gt 0) {
                for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                    $densityEstimates[$i] = $densityEstimates[$i] / $sum
                }
            }
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
                KernelType    = $KernelType
                Bandwidth     = $Bandwidth
                Normalize     = $Normalize.IsPresent
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
                Title        = "Kernel Density Estimation Results"
                Description  = "Results of kernel density estimation using the $KernelType kernel"
                CreatedBy    = $env:USERNAME
                CreatedOn    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version      = "1.0"
            }
        }
        
        return $result
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimate
