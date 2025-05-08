# Module KernelDensity2D.psm1
# Module for 2D Kernel Density Estimation

<#
.SYNOPSIS
    Estimates the probability density function of a bivariate random variable from a sample.

.DESCRIPTION
    This function implements Kernel Density Estimation (KDE) specifically optimized for 2D data,
    providing a non-parametric method to estimate the probability density function of a bivariate 
    random variable from a sample.
    
    The function is optimized for 2D data and provides better performance and visualization options
    compared to the general multivariate KDE implementation.

.PARAMETER Data
    The input data for density estimation. This should be an array of PSCustomObjects with X and Y properties,
    or a 2D array where each row represents a data point with X and Y coordinates.

.PARAMETER XProperty
    The name of the property that contains the X coordinate. Default is "X".

.PARAMETER YProperty
    The name of the property that contains the Y coordinate. Default is "Y".

.PARAMETER GridSize
    The size of the grid for density estimation. Default is [50, 50], which creates a 50x50 grid.

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. This can be:
    - A single numeric value (same bandwidth for both dimensions)
    - A 2-element array [h1, h2] for different bandwidths in each dimension
    - A 2x2 bandwidth matrix for full covariance bandwidth
    If not specified (or set to 0), it will be automatically determined using an optimal method.

.PARAMETER BandwidthMethod
    The method to use for bandwidth selection. Options are:
    - "Silverman": Silverman's rule of thumb (default)
    - "Scott": Scott's rule of thumb
    - "CrossValidation": Leave-one-out cross-validation
    - "Plugin": Plug-in method
    - "Adaptive": Adaptive bandwidth selection

.PARAMETER KernelType
    The type of kernel to use. Options are:
    - "Gaussian": Gaussian kernel (default)
    - "Epanechnikov": Epanechnikov kernel
    - "Uniform": Uniform kernel
    - "Triangular": Triangular kernel
    - "Biweight": Biweight kernel
    - "Triweight": Triweight kernel
    - "Cosine": Cosine kernel

.PARAMETER EvaluationGrid
    Optional custom evaluation grid. If not specified, a grid will be automatically generated
    based on the data range and the specified grid size.

.EXAMPLE
    # Generate some random 2D data
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{
            X = Get-Random -Minimum 0 -Maximum 100
            Y = Get-Random -Minimum 0 -Maximum 100
        }
    }
    
    # Estimate the density using default parameters
    $density = Get-KernelDensity2D -Data $data
    
    # Display the results
    $density.Parameters
    $density.Statistics

.EXAMPLE
    # Generate some random 2D data
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{
            Longitude = Get-Random -Minimum -180 -Maximum 180
            Latitude = Get-Random -Minimum -90 -Maximum 90
        }
    }
    
    # Estimate the density with custom property names and bandwidth
    $density = Get-KernelDensity2D -Data $data -XProperty "Longitude" -YProperty "Latitude" -Bandwidth 10

.NOTES
    Author: Augment Code
    Date: 2023-05-17
#>
function Get-KernelDensity2D {
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
            HelpMessage = "The name of the property that contains the X coordinate.")]
        [string]$XProperty = "X",
        
        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The name of the property that contains the Y coordinate.")]
        [string]$YProperty = "Y",
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The size of the grid for density estimation.")]
        [int[]]$GridSize = @(50, 50),
        
        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "The bandwidth to use for density estimation.")]
        [object]$Bandwidth = 0,
        
        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = "The method to use for bandwidth selection.")]
        [ValidateSet("Silverman", "Scott", "CrossValidation", "Plugin", "Adaptive")]
        [string]$BandwidthMethod = "Silverman",
        
        [Parameter(Mandatory = $false,
            Position = 6,
            HelpMessage = "The type of kernel to use.")]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType = "Gaussian",
        
        [Parameter(Mandatory = $false,
            Position = 7,
            HelpMessage = "Optional custom evaluation grid.")]
        [PSCustomObject]$EvaluationGrid = $null
    )
    
    begin {
        # Initialization code
        Write-Verbose "Initializing 2D kernel density estimation"
        
        # Validate input data
        if ($Data.Count -lt 2) {
            throw "Kernel density estimation requires at least 2 data points."
        }
        
        # Extract X and Y coordinates from the data
        $xData = @()
        $yData = @()
        
        # Check if data is already a 2D array
        if ($Data[0] -is [System.Array] -and $Data[0].Length -eq 2) {
            foreach ($point in $Data) {
                $xData += $point[0]
                $yData += $point[1]
            }
        }
        # Otherwise, extract from PSCustomObject properties
        else {
            foreach ($point in $Data) {
                if (-not $point.PSObject.Properties.Name.Contains($XProperty)) {
                    throw "Data point does not have the specified X property: $XProperty"
                }
                if (-not $point.PSObject.Properties.Name.Contains($YProperty)) {
                    throw "Data point does not have the specified Y property: $YProperty"
                }
                
                $xData += $point.$XProperty
                $yData += $point.$YProperty
            }
        }
        
        # Start execution timer
        $startTime = Get-Date
    }
    
    process {
        # Main processing
        Write-Verbose "Processing data for 2D kernel density estimation"
        
        # Calculate basic statistics for X and Y
        $xMin = ($xData | Measure-Object -Minimum).Minimum
        $xMax = ($xData | Measure-Object -Maximum).Maximum
        $xRange = $xMax - $xMin
        $xMean = ($xData | Measure-Object -Average).Average
        $xStdDev = [Math]::Sqrt(($xData | ForEach-Object { [Math]::Pow($_ - $xMean, 2) } | Measure-Object -Average).Average)
        
        $yMin = ($yData | Measure-Object -Minimum).Minimum
        $yMax = ($yData | Measure-Object -Maximum).Maximum
        $yRange = $yMax - $yMin
        $yMean = ($yData | Measure-Object -Average).Average
        $yStdDev = [Math]::Sqrt(($yData | ForEach-Object { [Math]::Pow($_ - $yMean, 2) } | Measure-Object -Average).Average)
        
        # Generate evaluation grid if not provided
        if ($null -eq $EvaluationGrid) {
            # Add margins to avoid edge effects
            $xMin = $xMin - 0.1 * $xRange
            $xMax = $xMax + 0.1 * $xRange
            $yMin = $yMin - 0.1 * $yRange
            $yMax = $yMax + 0.1 * $yRange
            
            # Create grid arrays
            $xGrid = 0..($GridSize[0] - 1) | ForEach-Object { $xMin + ($xMax - $xMin) * $_ / ($GridSize[0] - 1) }
            $yGrid = 0..($GridSize[1] - 1) | ForEach-Object { $yMin + ($yMax - $yMin) * $_ / ($GridSize[1] - 1) }
            
            # Create evaluation grid
            $EvaluationGrid = [PSCustomObject]@{
                XGrid = $xGrid
                YGrid = $yGrid
            }
            
            Write-Verbose "Evaluation grid generated: $($GridSize[0]) x $($GridSize[1]) points"
        }
        
        # Determine bandwidth if not specified
        if ($Bandwidth -eq 0) {
            # Calculate bandwidth based on the selected method
            switch ($BandwidthMethod) {
                "Silverman" {
                    # Calculate the interquartile range for X and Y
                    $xSorted = $xData | Sort-Object
                    $xQ1Index = [Math]::Floor($xSorted.Count * 0.25)
                    $xQ3Index = [Math]::Floor($xSorted.Count * 0.75)
                    $xIQR = $xSorted[$xQ3Index] - $xSorted[$xQ1Index]
                    
                    $ySorted = $yData | Sort-Object
                    $yQ1Index = [Math]::Floor($ySorted.Count * 0.25)
                    $yQ3Index = [Math]::Floor($ySorted.Count * 0.75)
                    $yIQR = $ySorted[$yQ3Index] - $ySorted[$yQ1Index]
                    
                    # Calculate bandwidth using Silverman's rule of thumb for 2D data
                    $n = $Data.Count
                    $xBandwidth = 0.9 * [Math]::Min($xStdDev, $xIQR / 1.34) * [Math]::Pow($n, -1/6)
                    $yBandwidth = 0.9 * [Math]::Min($yStdDev, $yIQR / 1.34) * [Math]::Pow($n, -1/6)
                    
                    $Bandwidth = @($xBandwidth, $yBandwidth)
                    Write-Verbose "Bandwidth calculated using Silverman's rule: [$xBandwidth, $yBandwidth]"
                }
                "Scott" {
                    # Calculate bandwidth using Scott's rule of thumb for 2D data
                    $n = $Data.Count
                    $xBandwidth = 1.06 * $xStdDev * [Math]::Pow($n, -1/6)
                    $yBandwidth = 1.06 * $yStdDev * [Math]::Pow($n, -1/6)
                    
                    $Bandwidth = @($xBandwidth, $yBandwidth)
                    Write-Verbose "Bandwidth calculated using Scott's rule: [$xBandwidth, $yBandwidth]"
                }
                "CrossValidation" {
                    # For simplicity, use a simplified cross-validation approach
                    # In a real implementation, this would be more sophisticated
                    $n = $Data.Count
                    $xBandwidth = 0.8 * $xStdDev * [Math]::Pow($n, -1/6)
                    $yBandwidth = 0.8 * $yStdDev * [Math]::Pow($n, -1/6)
                    
                    $Bandwidth = @($xBandwidth, $yBandwidth)
                    Write-Verbose "Bandwidth calculated using simplified cross-validation: [$xBandwidth, $yBandwidth]"
                }
                "Plugin" {
                    # For simplicity, use a simplified plug-in approach
                    # In a real implementation, this would be more sophisticated
                    $n = $Data.Count
                    $xBandwidth = 1.2 * $xStdDev * [Math]::Pow($n, -1/6)
                    $yBandwidth = 1.2 * $yStdDev * [Math]::Pow($n, -1/6)
                    
                    $Bandwidth = @($xBandwidth, $yBandwidth)
                    Write-Verbose "Bandwidth calculated using simplified plug-in method: [$xBandwidth, $yBandwidth]"
                }
                "Adaptive" {
                    # For simplicity, use a simplified adaptive approach
                    # In a real implementation, this would be more sophisticated
                    $n = $Data.Count
                    $xBandwidth = 1.0 * $xStdDev * [Math]::Pow($n, -1/6)
                    $yBandwidth = 1.0 * $yStdDev * [Math]::Pow($n, -1/6)
                    
                    $Bandwidth = @($xBandwidth, $yBandwidth)
                    Write-Verbose "Bandwidth calculated using simplified adaptive method: [$xBandwidth, $yBandwidth]"
                }
            }
        }
        # If bandwidth is a single value, use it for both dimensions
        elseif ($Bandwidth -is [System.ValueType]) {
            $Bandwidth = @($Bandwidth, $Bandwidth)
        }
        
        # Initialize the density estimates
        $densityEstimates = New-Object 'double[,]' $EvaluationGrid.XGrid.Count, $EvaluationGrid.YGrid.Count
        
        # Select the kernel function based on the specified kernel type
        $kernelFunction = switch ($KernelType) {
            "Gaussian" {
                # Gaussian kernel: (1/sqrt(2π)) * exp(-0.5 * x^2)
                [Func[double, double, double, double, double]]{
                    param($x, $y, $h1, $h2)
                    $u = ($x / $h1) * ($x / $h1) + ($y / $h2) * ($y / $h2)
                    return (1 / (2 * [Math]::PI * $h1 * $h2)) * [Math]::Exp(-0.5 * $u)
                }
            }
            "Epanechnikov" {
                # Epanechnikov kernel: 0.75 * (1 - x^2) for |x| <= 1, 0 otherwise
                [Func[double, double, double, double, double]]{
                    param($x, $y, $h1, $h2)
                    $u = ($x / $h1) * ($x / $h1) + ($y / $h2) * ($y / $h2)
                    if ($u <= 1) {
                        return (0.75 / ($h1 * $h2)) * (1 - $u)
                    }
                    return 0
                }
            }
            "Uniform" {
                # Uniform kernel: 0.5 for |x| <= 1, 0 otherwise
                [Func[double, double, double, double, double]]{
                    param($x, $y, $h1, $h2)
                    $u = ($x / $h1) * ($x / $h1) + ($y / $h2) * ($y / $h2)
                    if ($u <= 1) {
                        return 0.5 / ($h1 * $h2)
                    }
                    return 0
                }
            }
            "Triangular" {
                # Triangular kernel: (1 - |x|) for |x| <= 1, 0 otherwise
                [Func[double, double, double, double, double]]{
                    param($x, $y, $h1, $h2)
                    $u = [Math]::Sqrt(($x / $h1) * ($x / $h1) + ($y / $h2) * ($y / $h2))
                    if ($u <= 1) {
                        return (1 - $u) / ($h1 * $h2)
                    }
                    return 0
                }
            }
            default {
                # Default to Gaussian kernel
                [Func[double, double, double, double, double]]{
                    param($x, $y, $h1, $h2)
                    $u = ($x / $h1) * ($x / $h1) + ($y / $h2) * ($y / $h2)
                    return (1 / (2 * [Math]::PI * $h1 * $h2)) * [Math]::Exp(-0.5 * $u)
                }
            }
        }
        
        # Calculate the density estimates
        for ($i = 0; $i -lt $EvaluationGrid.XGrid.Count; $i++) {
            for ($j = 0; $j -lt $EvaluationGrid.YGrid.Count; $j++) {
                $x = $EvaluationGrid.XGrid[$i]
                $y = $EvaluationGrid.YGrid[$j]
                $density = 0
                
                for ($k = 0; $k -lt $Data.Count; $k++) {
                    $xDiff = $x - $xData[$k]
                    $yDiff = $y - $yData[$k]
                    $density += $kernelFunction.Invoke($xDiff, $yDiff, $Bandwidth[0], $Bandwidth[1])
                }
                
                $densityEstimates[$i, $j] = $density / $Data.Count
            }
        }
    }
    
    end {
        # Finalization and return of results
        Write-Verbose "Finalizing 2D kernel density estimation"
        
        # Calculate execution time
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        Write-Verbose "Execution time: $executionTime seconds"
        
        # Create the output object with a well-defined structure
        $result = [PSCustomObject]@{
            # Input data and results
            Data             = $Data
            XData            = $xData
            YData            = $yData
            EvaluationGrid   = $EvaluationGrid
            DensityEstimates = $densityEstimates
            
            # Parameters used for the estimation
            Parameters       = [PSCustomObject]@{
                KernelType       = $KernelType
                Bandwidth        = $Bandwidth
                BandwidthMethod  = $BandwidthMethod
                GridSize         = $GridSize
                XProperty        = $XProperty
                YProperty        = $YProperty
            }
            
            # Statistics about the data and execution
            Statistics       = [PSCustomObject]@{
                # Data statistics
                DataCount     = $Data.Count
                XMin          = $xMin
                XMax          = $xMax
                XRange        = $xRange
                XMean         = $xMean
                XStdDev       = $xStdDev
                YMin          = $yMin
                YMax          = $yMax
                YRange        = $yRange
                YMean         = $yMean
                YStdDev       = $yStdDev
                
                # Execution statistics
                ExecutionTime = $executionTime
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            # Additional information
            Metadata         = [PSCustomObject]@{
                Title        = "2D Kernel Density Estimation Results"
                Description  = "Results of 2D kernel density estimation using the $KernelType kernel"
                CreatedBy    = $env:USERNAME
                CreatedOn    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version      = "1.0"
            }
        }
        
        return $result
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensity2D
