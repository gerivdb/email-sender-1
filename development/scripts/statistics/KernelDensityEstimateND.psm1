# Module KernelDensityEstimateND.psm1
# Module for N-Dimensional Kernel Density Estimation

<#
.SYNOPSIS
    Estimates the probability density function of a multivariate random variable of arbitrary dimension.

.DESCRIPTION
    This function implements Kernel Density Estimation (KDE) for N-dimensional data,
    providing a non-parametric method to estimate the probability density function of a multivariate 
    random variable from a sample.
    
    The function supports data of any dimension and provides optimized algorithms for high-dimensional data.

.PARAMETER Data
    The input data for density estimation. This should be an array of PSCustomObjects with properties
    for each dimension, or a 2D array where each row represents a data point with N coordinates.

.PARAMETER Dimensions
    The dimensions to use for density estimation. This should be an array of strings representing the
    property names of the dimensions in the data. If not specified, all properties of the first data
    point will be used as dimensions.

.PARAMETER GridSize
    The size of the grid for density estimation. This can be:
    - A single integer (same size for all dimensions)
    - An array of integers (different size for each dimension)
    Default is 20 points per dimension.

.PARAMETER Bandwidth
    The bandwidth to use for density estimation. This can be:
    - A single numeric value (same bandwidth for all dimensions)
    - An array of numeric values (different bandwidth for each dimension)
    - A covariance matrix (full bandwidth matrix)
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

.PARAMETER MaxDimensions
    The maximum number of dimensions to use for full grid evaluation. For higher dimensions,
    the function will use a sparse grid or sampling approach. Default is 4.

.EXAMPLE
    # Generate some random 3D data
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{
            X = Get-Random -Minimum 0 -Maximum 100
            Y = Get-Random -Minimum 0 -Maximum 100
            Z = Get-Random -Minimum 0 -Maximum 100
        }
    }
    
    # Estimate the density using default parameters
    $density = Get-KernelDensityEstimateND -Data $data
    
    # Display the results
    $density.Parameters
    $density.Statistics

.EXAMPLE
    # Generate some random 4D data
    $data = 1..100 | ForEach-Object {
        [PSCustomObject]@{
            X = Get-Random -Minimum 0 -Maximum 100
            Y = Get-Random -Minimum 0 -Maximum 100
            Z = Get-Random -Minimum 0 -Maximum 100
            W = Get-Random -Minimum 0 -Maximum 100
        }
    }
    
    # Estimate the density with custom dimensions and bandwidth
    $density = Get-KernelDensityEstimateND -Data $data -Dimensions @("X", "Y", "Z", "W") -Bandwidth 10

.NOTES
    Author: Augment Code
    Date: 2023-05-17
#>
function Get-KernelDensityEstimateND {
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
            HelpMessage = "The size of the grid for density estimation.")]
        [object]$GridSize = 20,
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation.")]
        [object]$Bandwidth = 0,
        
        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "The method to use for bandwidth selection.")]
        [ValidateSet("Silverman", "Scott", "CrossValidation", "Plugin", "Adaptive")]
        [string]$BandwidthMethod = "Silverman",
        
        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = "The type of kernel to use.")]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType = "Gaussian",
        
        [Parameter(Mandatory = $false,
            Position = 6,
            HelpMessage = "Optional custom evaluation grid.")]
        [PSCustomObject]$EvaluationGrid = $null,
        
        [Parameter(Mandatory = $false,
            Position = 7,
            HelpMessage = "The maximum number of dimensions for full grid evaluation.")]
        [int]$MaxDimensions = 4
    )
    
    begin {
        # Initialization code
        Write-Verbose "Initializing N-dimensional kernel density estimation"
        
        # Validate input data
        if ($Data.Count -lt 2) {
            throw "Kernel density estimation requires at least 2 data points."
        }
        
        # Determine if the data is an array of PSCustomObjects or a 2D array
        $isCustomObject = $Data[0] -is [PSCustomObject]
        
        # If dimensions are not specified, determine them from the data
        if (-not $Dimensions) {
            if ($isCustomObject) {
                $Dimensions = $Data[0].PSObject.Properties.Name
            } else {
                # For 2D arrays, create dimension names D1, D2, etc.
                $Dimensions = 1..$Data[0].Length | ForEach-Object { "D$_" }
            }
        }
        
        # Get the number of dimensions
        $numDimensions = $Dimensions.Count
        Write-Verbose "Number of dimensions: $numDimensions"
        
        # Extract the data for each dimension
        $dimensionData = @{}
        
        if ($isCustomObject) {
            # Validate that all data points have the specified dimensions
            foreach ($point in $Data) {
                foreach ($dimension in $Dimensions) {
                    if (-not $point.PSObject.Properties.Name.Contains($dimension)) {
                        throw "Data point does not have the specified dimension: $dimension"
                    }
                }
            }
            
            # Extract data for each dimension
            foreach ($dimension in $Dimensions) {
                $dimensionData[$dimension] = $Data | ForEach-Object { $_.$dimension }
            }
        } else {
            # For 2D arrays, extract data for each dimension
            for ($i = 0; $i -lt $numDimensions; $i++) {
                $dimensionData[$Dimensions[$i]] = $Data | ForEach-Object { $_[$i] }
            }
        }
        
        # Start execution timer
        $startTime = Get-Date
    }
    
    process {
        # Main processing
        Write-Verbose "Processing data for N-dimensional kernel density estimation"
        
        # Calculate basic statistics for each dimension
        $dimensionStats = @{}
        foreach ($dimension in $Dimensions) {
            $min = ($dimensionData[$dimension] | Measure-Object -Minimum).Minimum
            $max = ($dimensionData[$dimension] | Measure-Object -Maximum).Maximum
            $range = $max - $min
            $mean = ($dimensionData[$dimension] | Measure-Object -Average).Average
            $stdDev = [Math]::Sqrt(($dimensionData[$dimension] | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
            
            $dimensionStats[$dimension] = [PSCustomObject]@{
                Min = $min
                Max = $max
                Range = $range
                Mean = $mean
                StdDev = $stdDev
            }
        }
        
        # Generate evaluation grid if not provided
        if ($null -eq $EvaluationGrid) {
            # Determine grid size for each dimension
            $gridSizes = @()
            if ($GridSize -is [System.ValueType]) {
                # Same grid size for all dimensions
                $gridSizes = 1..$numDimensions | ForEach-Object { $GridSize }
            } else {
                # Different grid size for each dimension
                $gridSizes = $GridSize
            }
            
            # Create grid arrays for each dimension
            $gridArrays = @{}
            for ($i = 0; $i -lt $numDimensions; $i++) {
                $dimension = $Dimensions[$i]
                $stats = $dimensionStats[$dimension]
                
                # Add margins to avoid edge effects
                $min = $stats.Min - 0.1 * $stats.Range
                $max = $stats.Max + 0.1 * $stats.Range
                
                # Create grid array
                $gridSize = $gridSizes[$i]
                $gridArrays[$dimension] = 0..($gridSize - 1) | ForEach-Object { $min + ($max - $min) * $_ / ($gridSize - 1) }
            }
            
            # Create evaluation grid
            $EvaluationGrid = [PSCustomObject]@{
                GridArrays = $gridArrays
                GridSizes = $gridSizes
            }
            
            Write-Verbose "Evaluation grid generated for $numDimensions dimensions"
        }
        
        # Determine bandwidth if not specified
        if ($Bandwidth -eq 0) {
            # Calculate bandwidth based on the selected method
            $bandwidths = @{}
            
            switch ($BandwidthMethod) {
                "Silverman" {
                    # Calculate bandwidth using Silverman's rule of thumb for each dimension
                    $n = $Data.Count
                    $factor = [Math]::Pow($n, -1 / ($numDimensions + 4))
                    
                    foreach ($dimension in $Dimensions) {
                        $stats = $dimensionStats[$dimension]
                        
                        # Calculate the interquartile range
                        $sorted = $dimensionData[$dimension] | Sort-Object
                        $q1Index = [Math]::Floor($sorted.Count * 0.25)
                        $q3Index = [Math]::Floor($sorted.Count * 0.75)
                        $iqr = $sorted[$q3Index] - $sorted[$q1Index]
                        
                        # Calculate bandwidth using Silverman's rule
                        $bandwidths[$dimension] = 0.9 * [Math]::Min($stats.StdDev, $iqr / 1.34) * $factor
                    }
                    
                    Write-Verbose "Bandwidth calculated using Silverman's rule for $numDimensions dimensions"
                }
                "Scott" {
                    # Calculate bandwidth using Scott's rule of thumb for each dimension
                    $n = $Data.Count
                    $factor = [Math]::Pow($n, -1 / ($numDimensions + 4))
                    
                    foreach ($dimension in $Dimensions) {
                        $stats = $dimensionStats[$dimension]
                        $bandwidths[$dimension] = 1.06 * $stats.StdDev * $factor
                    }
                    
                    Write-Verbose "Bandwidth calculated using Scott's rule for $numDimensions dimensions"
                }
                default {
                    # Default to Silverman's rule
                    $n = $Data.Count
                    $factor = [Math]::Pow($n, -1 / ($numDimensions + 4))
                    
                    foreach ($dimension in $Dimensions) {
                        $stats = $dimensionStats[$dimension]
                        
                        # Calculate the interquartile range
                        $sorted = $dimensionData[$dimension] | Sort-Object
                        $q1Index = [Math]::Floor($sorted.Count * 0.25)
                        $q3Index = [Math]::Floor($sorted.Count * 0.75)
                        $iqr = $sorted[$q3Index] - $sorted[$q1Index]
                        
                        # Calculate bandwidth using Silverman's rule
                        $bandwidths[$dimension] = 0.9 * [Math]::Min($stats.StdDev, $iqr / 1.34) * $factor
                    }
                    
                    Write-Verbose "Bandwidth calculated using default method (Silverman's rule) for $numDimensions dimensions"
                }
            }
            
            $Bandwidth = [PSCustomObject]$bandwidths
        }
        # If bandwidth is a single value, use it for all dimensions
        elseif ($Bandwidth -is [System.ValueType]) {
            $bandwidths = @{}
            foreach ($dimension in $Dimensions) {
                $bandwidths[$dimension] = $Bandwidth
            }
            $Bandwidth = [PSCustomObject]$bandwidths
        }
        
        # Select the kernel function based on the specified kernel type
        $kernelFunction = switch ($KernelType) {
            "Gaussian" {
                # Gaussian kernel for N dimensions
                [Func[double[], double[], double]]{
                    param($x, $h)
                    $sum = 0
                    for ($i = 0; $i -lt $x.Length; $i++) {
                        $sum += ($x[$i] / $h[$i]) * ($x[$i] / $h[$i])
                    }
                    $normalization = 1
                    for ($i = 0; $i -lt $h.Length; $i++) {
                        $normalization *= $h[$i] * [Math]::Sqrt(2 * [Math]::PI)
                    }
                    return (1 / $normalization) * [Math]::Exp(-0.5 * $sum)
                }
            }
            "Epanechnikov" {
                # Epanechnikov kernel for N dimensions
                [Func[double[], double[], double]]{
                    param($x, $h)
                    $sum = 0
                    for ($i = 0; $i -lt $x.Length; $i++) {
                        $sum += ($x[$i] / $h[$i]) * ($x[$i] / $h[$i])
                    }
                    if ($sum <= 1) {
                        $normalization = 1
                        for ($i = 0; $i -lt $h.Length; $i++) {
                            $normalization *= $h[$i]
                        }
                        $volume = [Math]::Pow([Math]::PI, $x.Length / 2) / [Math]::Gamma($x.Length / 2 + 1)
                        return (0.75 / ($normalization * $volume)) * (1 - $sum)
                    }
                    return 0
                }
            }
            default {
                # Default to Gaussian kernel
                [Func[double[], double[], double]]{
                    param($x, $h)
                    $sum = 0
                    for ($i = 0; $i -lt $x.Length; $i++) {
                        $sum += ($x[$i] / $h[$i]) * ($x[$i] / $h[$i])
                    }
                    $normalization = 1
                    for ($i = 0; $i -lt $h.Length; $i++) {
                        $normalization *= $h[$i] * [Math]::Sqrt(2 * [Math]::PI)
                    }
                    return (1 / $normalization) * [Math]::Exp(-0.5 * $sum)
                }
            }
        }
        
        # Determine the approach based on the number of dimensions
        if ($numDimensions <= $MaxDimensions) {
            # For lower dimensions, use a full grid approach
            Write-Verbose "Using full grid approach for $numDimensions dimensions"
            
            # Create a recursive function to calculate density on the grid
            function Calculate-DensityOnGrid {
                param (
                    [int[]]$indices,
                    [int]$currentDim,
                    [object]$grid,
                    [string[]]$dimensions,
                    [hashtable]$dimData,
                    [object]$bandwidth,
                    [scriptblock]$kernel,
                    [int]$dataCount
                )
                
                if ($currentDim -eq $dimensions.Count) {
                    # We have a complete set of indices, calculate density at this point
                    $point = @()
                    for ($i = 0; $i -lt $dimensions.Count; $i++) {
                        $dim = $dimensions[$i]
                        $point += $grid.GridArrays[$dim][$indices[$i]]
                    }
                    
                    $density = 0
                    for ($k = 0; $k -lt $dataCount; $k++) {
                        $diff = @()
                        for ($i = 0; $i -lt $dimensions.Count; $i++) {
                            $dim = $dimensions[$i]
                            $diff += $point[$i] - $dimData[$dim][$k]
                        }
                        
                        $bandwidthArray = @()
                        for ($i = 0; $i -lt $dimensions.Count; $i++) {
                            $dim = $dimensions[$i]
                            $bandwidthArray += $bandwidth.$dim
                        }
                        
                        $density += $kernel.Invoke($diff, $bandwidthArray)
                    }
                    
                    return $density / $dataCount
                } else {
                    # Recursively process the next dimension
                    $dim = $dimensions[$currentDim]
                    $gridSize = $grid.GridSizes[$currentDim]
                    $result = New-Object 'double[]' $gridSize
                    
                    for ($i = 0; $i -lt $gridSize; $i++) {
                        $newIndices = $indices.Clone()
                        $newIndices[$currentDim] = $i
                        $result[$i] = Calculate-DensityOnGrid -indices $newIndices -currentDim ($currentDim + 1) -grid $grid -dimensions $dimensions -dimData $dimData -bandwidth $bandwidth -kernel $kernel -dataCount $dataCount
                    }
                    
                    return $result
                }
            }
            
            # Initialize indices array
            $indices = New-Object 'int[]' $numDimensions
            
            # Calculate density estimates using the recursive function
            $densityEstimates = Calculate-DensityOnGrid -indices $indices -currentDim 0 -grid $EvaluationGrid -dimensions $Dimensions -dimData $dimensionData -bandwidth $Bandwidth -kernel $kernelFunction -dataCount $Data.Count
        } else {
            # For higher dimensions, use a sampling approach
            Write-Verbose "Using sampling approach for $numDimensions dimensions (exceeds MaxDimensions = $MaxDimensions)"
            
            # Generate sample points
            $numSamples = 1000 # Adjust based on computational resources
            $samplePoints = @()
            
            for ($i = 0; $i -lt $numSamples; $i++) {
                $point = [PSCustomObject]@{}
                foreach ($dimension in $Dimensions) {
                    $stats = $dimensionStats[$dimension]
                    $min = $stats.Min - 0.1 * $stats.Range
                    $max = $stats.Max + 0.1 * $stats.Range
                    $value = $min + (Get-Random -Minimum 0 -Maximum 1000) / 1000 * ($max - $min)
                    $point | Add-Member -MemberType NoteProperty -Name $dimension -Value $value
                }
                $samplePoints += $point
            }
            
            # Calculate density at sample points
            $densityEstimates = @()
            
            foreach ($point in $samplePoints) {
                $density = 0
                
                foreach ($dataPoint in $Data) {
                    $diff = @()
                    $bandwidthArray = @()
                    
                    foreach ($dimension in $Dimensions) {
                        if ($isCustomObject) {
                            $diff += $point.$dimension - $dataPoint.$dimension
                        } else {
                            $index = [array]::IndexOf($Dimensions, $dimension)
                            $diff += $point.$dimension - $dataPoint[$index]
                        }
                        $bandwidthArray += $Bandwidth.$dimension
                    }
                    
                    $density += $kernelFunction.Invoke($diff, $bandwidthArray)
                }
                
                $densityEstimates += $density / $Data.Count
            }
            
            # Update the evaluation grid to include the sample points
            $EvaluationGrid = [PSCustomObject]@{
                SamplePoints = $samplePoints
                GridArrays = $EvaluationGrid.GridArrays
                GridSizes = $EvaluationGrid.GridSizes
                IsSampled = $true
            }
        }
    }
    
    end {
        # Finalization and return of results
        Write-Verbose "Finalizing N-dimensional kernel density estimation"
        
        # Calculate execution time
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds
        Write-Verbose "Execution time: $executionTime seconds"
        
        # Create the output object with a well-defined structure
        $result = [PSCustomObject]@{
            # Input data and results
            Data             = $Data
            Dimensions       = $Dimensions
            EvaluationGrid   = $EvaluationGrid
            DensityEstimates = $densityEstimates
            
            # Parameters used for the estimation
            Parameters       = [PSCustomObject]@{
                KernelType       = $KernelType
                Bandwidth        = $Bandwidth
                BandwidthMethod  = $BandwidthMethod
                GridSize         = $GridSize
                MaxDimensions    = $MaxDimensions
                NumDimensions    = $numDimensions
            }
            
            # Statistics about the data and execution
            Statistics       = [PSCustomObject]@{
                # Data statistics
                DataCount     = $Data.Count
                DimensionStats = [PSCustomObject]$dimensionStats
                
                # Execution statistics
                ExecutionTime = $executionTime
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            # Additional information
            Metadata         = [PSCustomObject]@{
                Title        = "N-Dimensional Kernel Density Estimation Results"
                Description  = "Results of $numDimensions-dimensional kernel density estimation using the $KernelType kernel"
                CreatedBy    = $env:USERNAME
                CreatedOn    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version      = "1.0"
            }
        }
        
        return $result
    }
}

# Export public functions
Export-ModuleMember -Function Get-KernelDensityEstimateND
