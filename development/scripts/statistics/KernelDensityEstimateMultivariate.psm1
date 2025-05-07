# Module KernelDensityEstimateMultivariate.psm1
# Module for Multivariate Kernel Density Estimation

<#
.SYNOPSIS
    Estimates the probability density function of a multivariate random variable from a sample.

.DESCRIPTION
    This function implements Kernel Density Estimation (KDE) for multivariate data,
    a non-parametric method to estimate the probability density function of a random variable from a sample.
    
    The function supports both univariate and multivariate data. For multivariate data, each data point
    should be represented as a PSCustomObject with properties for each dimension.

.PARAMETER Data
    The input data for density estimation. For univariate data, this should be an array of numeric values.
    For multivariate data, this should be an array of PSCustomObjects with properties for each dimension.

.PARAMETER Dimensions
    The dimensions to use for density estimation. This should be an array of strings representing the
    property names of the dimensions in the data. If not specified, all properties of the first data
    point will be used as dimensions.

.PARAMETER EvaluationPoints
    The points where the density will be evaluated. For univariate data, this should be an array of
    numeric values. For multivariate data, this should be an array of PSCustomObjects with properties
    for each dimension. If not specified, the function automatically generates a grid of points based
    on the input data.

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. For univariate data, this should be a single numeric value.
    For multivariate data, this should be a PSCustomObject with properties for each dimension. If not
    specified (or set to 0), it will be automatically determined using Silverman's rule of thumb.

.EXAMPLE
    # Univariate data
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $density = Get-KernelDensityEstimateMultivariate -Data $data
    
    Estimates the probability density function of a sample of 100 random values between 0 and 100.

.EXAMPLE
    # Bivariate data
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{
            X = Get-Random -Minimum 0 -Maximum 100
            Y = Get-Random -Minimum 0 -Maximum 100
        }
    }
    $density = Get-KernelDensityEstimateMultivariate -Data $data -Dimensions @("X", "Y")
    
    Estimates the probability density function of a sample of 100 random points in 2D space.

.NOTES
    Author: Augment Code
    Date: 2023-05-16
#>
function Get-KernelDensityEstimateMultivariate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "The input data for density estimation.")]
        [ValidateNotNullOrEmpty()]
        [object[]]$Data,

        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "The dimensions to use for density estimation.")]
        [string[]]$Dimensions,
        
        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The points where the density will be evaluated.")]
        [object[]]$EvaluationPoints,
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation.")]
        [object]$Bandwidth = 0
    )
    
    begin {
        # Initialization code
        Write-Verbose "Initializing kernel density estimation"
        
        # Validate input data
        if ($Data.Count -lt 2) {
            throw "Kernel density estimation requires at least 2 data points."
        }
        
        # Determine if the data is univariate or multivariate
        $isMultivariate = $Data[0] -is [PSCustomObject]
        
        # If multivariate, determine the dimensions
        if ($isMultivariate) {
            if (-not $Dimensions) {
                $Dimensions = $Data[0].PSObject.Properties.Name
            }
            
            # Validate that all data points have the specified dimensions
            foreach ($point in $Data) {
                foreach ($dimension in $Dimensions) {
                    if (-not $point.PSObject.Properties.Name.Contains($dimension)) {
                        throw "Data point does not have the specified dimension: $dimension"
                    }
                }
            }
            
            # Extract the data for each dimension
            $dimensionData = @{}
            foreach ($dimension in $Dimensions) {
                $dimensionData[$dimension] = $Data | ForEach-Object { $_.$dimension }
            }
        }
        
        # Start execution timer
        $startTime = Get-Date
    }
    
    process {
        # Main processing
        Write-Verbose "Processing data for kernel density estimation"
        
        if ($isMultivariate) {
            # Multivariate data processing
            
            # If evaluation points are not specified, generate them automatically
            if (-not $EvaluationPoints) {
                # Generate a grid of evaluation points for each dimension
                $dimensionEvalPoints = @{}
                foreach ($dimension in $Dimensions) {
                    $min = ($dimensionData[$dimension] | Measure-Object -Minimum).Minimum
                    $max = ($dimensionData[$dimension] | Measure-Object -Maximum).Maximum
                    $range = $max - $min
                    
                    # Add a margin to avoid edge effects
                    $min = $min - 0.1 * $range
                    $max = $max + 0.1 * $range
                    
                    # Generate a grid of evaluation points (10 points per dimension by default)
                    $numPoints = 10
                    $step = ($max - $min) / ($numPoints - 1)
                    $dimensionEvalPoints[$dimension] = 0..($numPoints - 1) | ForEach-Object { $min + $_ * $step }
                }
                
                # Generate the Cartesian product of the evaluation points
                $EvaluationPoints = Get-CartesianProduct -Dimensions $Dimensions -DimensionValues $dimensionEvalPoints
                
                Write-Verbose "Evaluation points generated: $($EvaluationPoints.Count) points"
            }
            
            # If bandwidth is not specified, calculate it for each dimension
            if ($Bandwidth -eq 0) {
                $Bandwidth = [PSCustomObject]@{}
                foreach ($dimension in $Dimensions) {
                    # Calculate the standard deviation of the data for this dimension
                    $stdDev = [Math]::Sqrt(($dimensionData[$dimension] | ForEach-Object { [Math]::Pow($_ - ($dimensionData[$dimension] | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                    
                    # Calculate the interquartile range for this dimension
                    $sortedData = $dimensionData[$dimension] | Sort-Object
                    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
                    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
                    $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]
                    
                    # Calculate the bandwidth using Silverman's rule of thumb
                    $n = $Data.Count
                    $dimensionBandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2 / $Dimensions.Count)
                    
                    # Add the bandwidth for this dimension
                    $Bandwidth | Add-Member -MemberType NoteProperty -Name $dimension -Value $dimensionBandwidth
                }
                
                Write-Verbose "Bandwidth calculated for each dimension"
            }
            
            # Initialize the density estimates
            $densityEstimates = New-Object double[] $EvaluationPoints.Count
            
            # Calculate the density estimates using the Gaussian kernel
            for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
                $point = $EvaluationPoints[$i]
                $density = 0
                
                foreach ($dataPoint in $Data) {
                    $kernelProduct = 1.0
                    
                    foreach ($dimension in $Dimensions) {
                        $x = ($point.$dimension - $dataPoint.$dimension) / $Bandwidth.$dimension
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $kernelProduct *= $kernelValue
                    }
                    
                    $density += $kernelProduct
                }
                
                $bandwidthProduct = 1.0
                foreach ($dimension in $Dimensions) {
                    $bandwidthProduct *= $Bandwidth.$dimension
                }
                
                $densityEstimates[$i] = $density / ($bandwidthProduct * $Data.Count)
            }
        } else {
            # Univariate data processing (similar to KernelDensityEstimateBasic)
            
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
                
                # Calculate the bandwidth using Silverman's rule of thumb
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
            Dimensions       = $Dimensions
            IsMultivariate   = $isMultivariate
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            
            # Parameters used for the estimation
            Parameters       = [PSCustomObject]@{
                KernelType    = "Gaussian"
                Bandwidth     = $Bandwidth
            }
            
            # Statistics about the data and execution
            Statistics       = [PSCustomObject]@{
                # Data statistics
                DataCount     = $Data.Count
                
                # Execution statistics
                ExecutionTime = $executionTime
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            # Additional information
            Metadata         = [PSCustomObject]@{
                Title        = "Kernel Density Estimation Results"
                Description  = "Results of kernel density estimation using the Gaussian kernel"
                CreatedBy    = $env:USERNAME
                CreatedOn    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version      = "1.0"
            }
        }
        
        # Add dimension-specific statistics for multivariate data
        if ($isMultivariate) {
            $dimensionStats = [PSCustomObject]@{}
            foreach ($dimension in $Dimensions) {
                $dimensionStats | Add-Member -MemberType NoteProperty -Name $dimension -Value ([PSCustomObject]@{
                    Min    = ($dimensionData[$dimension] | Measure-Object -Minimum).Minimum
                    Max    = ($dimensionData[$dimension] | Measure-Object -Maximum).Maximum
                    Mean   = ($dimensionData[$dimension] | Measure-Object -Average).Average
                    Median = $dimensionData[$dimension] | Sort-Object | Select-Object -Index ([Math]::Floor($Data.Count / 2))
                    StdDev = [Math]::Sqrt(($dimensionData[$dimension] | ForEach-Object { [Math]::Pow($_ - ($dimensionData[$dimension] | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
                })
            }
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DimensionStats" -Value $dimensionStats
        } else {
            # Add univariate statistics
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataMin" -Value ($Data | Measure-Object -Minimum).Minimum
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataMax" -Value ($Data | Measure-Object -Maximum).Maximum
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataRange" -Value (($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum)
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataMean" -Value ($Data | Measure-Object -Average).Average
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataMedian" -Value ($Data | Sort-Object | Select-Object -Index ([Math]::Floor($Data.Count / 2)))
            $result.Statistics | Add-Member -MemberType NoteProperty -Name "DataStdDev" -Value ([Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average))
        }
        
        return $result
    }
}

# Helper function to generate the Cartesian product of multiple dimensions
function Get-CartesianProduct {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Dimensions,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$DimensionValues
    )
    
    # Initialize the result with a single empty object
    $result = @([PSCustomObject]@{})
    
    # For each dimension, create a new result by combining the current result with each value of the dimension
    foreach ($dimension in $Dimensions) {
        $newResult = @()
        
        foreach ($item in $result) {
            foreach ($value in $DimensionValues[$dimension]) {
                $newItem = $item.PSObject.Copy()
                $newItem | Add-Member -MemberType NoteProperty -Name $dimension -Value $value -Force
                $newResult += $newItem
            }
        }
        
        $result = $newResult
    }
    
    return $result
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimateMultivariate
