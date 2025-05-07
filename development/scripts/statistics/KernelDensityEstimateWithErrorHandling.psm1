# Module KernelDensityEstimateWithErrorHandling.psm1
# Module for Kernel Density Estimation with robust error handling

# Import the error types
. "$PSScriptRoot\KernelDensityEstimateErrorTypes.ps1"

<#
.SYNOPSIS
    Estimates the probability density function of a random variable from a sample.

.DESCRIPTION
    This function implements a basic version of Kernel Density Estimation (KDE)
    using the Gaussian kernel, with robust error handling.

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
    $density = Get-KernelDensityEstimateWithErrorHandling -Data $data
    
    Estimates the probability density function of a sample of 100 random values between 0 and 100.

.NOTES
    Author: Augment Code
    Date: 2023-05-16
#>
function Get-KernelDensityEstimateWithErrorHandling {
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
        try {
            # Check if data is null or empty
            if ($null -eq $Data -or $Data.Count -eq 0) {
                Throw-KernelDensityEstimationException -ErrorCode "V001"
            }
            
            # Check if data has enough points
            if ($Data.Count -lt 2) {
                Throw-KernelDensityEstimationException -ErrorCode "V002" -Args @($Data.Count)
            }
            
            # Check if data contains NaN or infinity values
            foreach ($value in $Data) {
                if ($value -isnot [ValueType] -and $value -isnot [string]) {
                    Throw-KernelDensityEstimationException -ErrorCode "V005"
                }
                
                if ($value -is [string]) {
                    # Try to convert string to double
                    try {
                        $doubleValue = [double]$value
                    } catch {
                        Throw-KernelDensityEstimationException -ErrorCode "V005"
                    }
                    
                    if ([double]::IsNaN($doubleValue)) {
                        Throw-KernelDensityEstimationException -ErrorCode "V003"
                    }
                    
                    if ([double]::IsInfinity($doubleValue)) {
                        Throw-KernelDensityEstimationException -ErrorCode "V004"
                    }
                } else {
                    # Check if value is NaN or infinity
                    if ([double]::IsNaN($value)) {
                        Throw-KernelDensityEstimationException -ErrorCode "V003"
                    }
                    
                    if ([double]::IsInfinity($value)) {
                        Throw-KernelDensityEstimationException -ErrorCode "V004"
                    }
                }
            }
            
            # Convert data to double array
            $Data = $Data | ForEach-Object { [double]$_ }
        } catch [KernelDensityEstimationException] {
            # Re-throw the exception
            throw
        } catch {
            # Wrap other exceptions
            Throw-KernelDensityEstimationException -ErrorCode "V005" -InnerException $_.Exception
        }
        
        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            try {
                # Check if evaluation points is null or empty
                if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                    Throw-KernelDensityEstimationException -ErrorCode "V101"
                }
                
                # Check if evaluation points contain NaN or infinity values
                foreach ($value in $EvaluationPoints) {
                    if ($value -isnot [ValueType] -and $value -isnot [string]) {
                        Throw-KernelDensityEstimationException -ErrorCode "V104"
                    }
                    
                    if ($value -is [string]) {
                        # Try to convert string to double
                        try {
                            $doubleValue = [double]$value
                        } catch {
                            Throw-KernelDensityEstimationException -ErrorCode "V104"
                        }
                        
                        if ([double]::IsNaN($doubleValue)) {
                            Throw-KernelDensityEstimationException -ErrorCode "V102"
                        }
                        
                        if ([double]::IsInfinity($doubleValue)) {
                            Throw-KernelDensityEstimationException -ErrorCode "V103"
                        }
                    } else {
                        # Check if value is NaN or infinity
                        if ([double]::IsNaN($value)) {
                            Throw-KernelDensityEstimationException -ErrorCode "V102"
                        }
                        
                        if ([double]::IsInfinity($value)) {
                            Throw-KernelDensityEstimationException -ErrorCode "V103"
                        }
                    }
                }
                
                # Convert evaluation points to double array
                $EvaluationPoints = $EvaluationPoints | ForEach-Object { [double]$_ }
            } catch [KernelDensityEstimationException] {
                # Re-throw the exception
                throw
            } catch {
                # Wrap other exceptions
                Throw-KernelDensityEstimationException -ErrorCode "V104" -InnerException $_.Exception
            }
        }
        
        # Validate bandwidth
        try {
            if ($Bandwidth -lt 0) {
                Throw-KernelDensityEstimationException -ErrorCode "V201" -Args @($Bandwidth)
            }
            
            if ($Bandwidth -eq 0 -and $PSBoundParameters.ContainsKey('Bandwidth')) {
                Throw-KernelDensityEstimationException -ErrorCode "V202"
            }
            
            if ([double]::IsNaN($Bandwidth)) {
                Throw-KernelDensityEstimationException -ErrorCode "V203"
            }
            
            if ([double]::IsInfinity($Bandwidth)) {
                Throw-KernelDensityEstimationException -ErrorCode "V204"
            }
        } catch [KernelDensityEstimationException] {
            # Re-throw the exception
            throw
        } catch {
            # Wrap other exceptions
            Throw-KernelDensityEstimationException -ErrorCode "V201" -InnerException $_.Exception
        }
        
        # Validate kernel type
        try {
            $validKernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform")
            if ($KernelType -notin $validKernelTypes) {
                Throw-KernelDensityEstimationException -ErrorCode "V301" -Args @($KernelType, ($validKernelTypes -join ", "))
            }
        } catch [KernelDensityEstimationException] {
            # Re-throw the exception
            throw
        } catch {
            # Wrap other exceptions
            Throw-KernelDensityEstimationException -ErrorCode "V301" -InnerException $_.Exception
        }
        
        # Start execution timer
        $startTime = Get-Date
    }
    
    process {
        # Main processing
        Write-Verbose "Processing data for kernel density estimation"
        
        try {
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
                try {
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
                    
                    # Check if bandwidth calculation failed
                    if ($Bandwidth -eq 0) {
                        Throw-KernelDensityEstimationException -ErrorCode "C001" -Details "Bandwidth calculation resulted in zero. This may be due to all data points being identical."
                    }
                    
                    if ([double]::IsNaN($Bandwidth)) {
                        Throw-KernelDensityEstimationException -ErrorCode "C001" -Details "Bandwidth calculation resulted in NaN."
                    }
                    
                    if ([double]::IsInfinity($Bandwidth)) {
                        Throw-KernelDensityEstimationException -ErrorCode "C001" -Details "Bandwidth calculation resulted in infinity."
                    }
                    
                    # Check if bandwidth is too small
                    $minBandwidth = 1e-10
                    if ($Bandwidth -lt $minBandwidth) {
                        Throw-KernelDensityEstimationException -ErrorCode "C002" -Args @($Bandwidth, $minBandwidth)
                    }
                    
                    # Check if bandwidth is too large
                    $maxBandwidth = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
                    if ($Bandwidth -gt $maxBandwidth) {
                        Throw-KernelDensityEstimationException -ErrorCode "C003" -Args @($Bandwidth, $maxBandwidth)
                    }
                    
                    Write-Verbose "Bandwidth calculated using Silverman's rule: $Bandwidth"
                } catch [KernelDensityEstimationException] {
                    # Re-throw the exception
                    throw
                } catch {
                    # Wrap other exceptions
                    Throw-KernelDensityEstimationException -ErrorCode "C001" -Details "Bandwidth calculation failed: $($_.Exception.Message)" -InnerException $_.Exception
                }
            }
            
            # Initialize the density estimates
            $densityEstimates = New-Object double[] $EvaluationPoints.Count
            
            # Calculate the density estimates using the specified kernel
            for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
                $point = $EvaluationPoints[$i]
                $density = 0
                
                foreach ($dataPoint in $Data) {
                    $x = ($point - $dataPoint) / $Bandwidth
                    
                    # Apply the kernel function
                    try {
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
                        
                        # Check if kernel calculation failed
                        if ([double]::IsNaN($kernelValue)) {
                            Throw-KernelDensityEstimationException -ErrorCode "C101" -Details "Kernel calculation resulted in NaN for x = $x."
                        }
                        
                        if ([double]::IsInfinity($kernelValue)) {
                            Throw-KernelDensityEstimationException -ErrorCode "C101" -Details "Kernel calculation resulted in infinity for x = $x."
                        }
                        
                        $density += $kernelValue
                    } catch [KernelDensityEstimationException] {
                        # Re-throw the exception
                        throw
                    } catch {
                        # Wrap other exceptions
                        Throw-KernelDensityEstimationException -ErrorCode "C101" -Details "Kernel calculation failed for x = $x: $($_.Exception.Message)" -InnerException $_.Exception
                    }
                }
                
                $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
                
                # Check if density estimation failed
                if ([double]::IsNaN($densityEstimates[$i])) {
                    Throw-KernelDensityEstimationException -ErrorCode "C203"
                }
                
                if ([double]::IsInfinity($densityEstimates[$i])) {
                    Throw-KernelDensityEstimationException -ErrorCode "C204"
                }
                
                if ($densityEstimates[$i] -lt 0) {
                    Throw-KernelDensityEstimationException -ErrorCode "C205"
                }
            }
            
            # Normalize the density estimates if requested
            if ($Normalize) {
                try {
                    $sum = ($densityEstimates | Measure-Object -Sum).Sum
                    
                    # Check if normalization failed
                    if ($sum -eq 0) {
                        Throw-KernelDensityEstimationException -ErrorCode "C202"
                    }
                    
                    for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                        $densityEstimates[$i] = $densityEstimates[$i] / $sum
                    }
                } catch [KernelDensityEstimationException] {
                    # Re-throw the exception
                    throw
                } catch {
                    # Wrap other exceptions
                    Throw-KernelDensityEstimationException -ErrorCode "C202" -Details "Density normalization failed: $($_.Exception.Message)" -InnerException $_.Exception
                }
            }
        } catch [KernelDensityEstimationException] {
            # Re-throw the exception
            throw
        } catch {
            # Wrap other exceptions
            Throw-KernelDensityEstimationException -ErrorCode "C201" -Details "Density estimation failed: $($_.Exception.Message)" -InnerException $_.Exception
        }
    }
    
    end {
        # Finalization and return of results
        Write-Verbose "Finalizing kernel density estimation"
        
        try {
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
        } catch {
            # Wrap other exceptions
            Throw-KernelDensityEstimationException -ErrorCode "C201" -Details "Failed to create result object: $($_.Exception.Message)" -InnerException $_.Exception
        }
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimateWithErrorHandling
