# KernelDensityEstimateMemoryErrorHandling.ps1
# Script implementing memory error handling functions for kernel density estimation

# Import the validation and calculation error handling functions
. "$PSScriptRoot\KernelDensityEstimateValidation.ps1"
. "$PSScriptRoot\KernelDensityEstimateCalculationErrorHandling.ps1"

# Add memory error codes to the ErrorCodes hashtable if they don't exist
if (-not $ErrorCodes.ContainsKey("MemoryAllocationFailed")) {
    # Memory allocation errors
    $ErrorCodes.MemoryAllocationFailed = "M001"
    $ErrorCodes.ArrayTooLarge = "M002"
    $ErrorCodes.OutOfMemory = "M003"

    # Performance errors
    $ErrorCodes.PerformanceWarning = "M101"
    $ErrorCodes.DimensionalityWarning = "M102"
    $ErrorCodes.ParallelizationFailed = "M103"
}

# Add memory error messages to the ErrorMessages hashtable if they don't exist
if (-not $ErrorMessages.ContainsKey($ErrorCodes.MemoryAllocationFailed)) {
    # Memory allocation errors
    $ErrorMessages[$ErrorCodes.MemoryAllocationFailed] = "Failed to allocate memory. {0}"
    $ErrorMessages[$ErrorCodes.ArrayTooLarge] = "The {0} array is too large to allocate ({1} elements)."
    $ErrorMessages[$ErrorCodes.OutOfMemory] = "The system is out of memory."

    # Performance errors
    $ErrorMessages[$ErrorCodes.PerformanceWarning] = "Performance warning: {0}"
    $ErrorMessages[$ErrorCodes.DimensionalityWarning] = "Dimensionality warning: The data has {0} dimensions, which may cause performance issues."
    $ErrorMessages[$ErrorCodes.ParallelizationFailed] = "Failed to parallelize the computation. {0}"
}

# Function to check available memory
function Get-AvailableMemory {
    [CmdletBinding()]
    [OutputType([double])]
    param()

    try {
        # Get available memory in bytes
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $availableMemoryBytes = $osInfo.FreePhysicalMemory * 1KB

        # Convert to MB for easier reading
        $availableMemoryMB = $availableMemoryBytes / 1MB

        Write-Verbose "Available memory: $availableMemoryMB MB"
        return $availableMemoryMB
    } catch {
        Write-Verbose "Failed to get available memory: $($_.Exception.Message)"
        return 0
    }
}

# Function to estimate memory requirements for kernel density estimation
function Get-KDEMemoryRequirements {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$DataCount,

        [Parameter(Mandatory = $true)]
        [int]$EvaluationPointsCount,

        [Parameter(Mandatory = $false)]
        [int]$Dimensions = 1,

        [Parameter(Mandatory = $false)]
        [switch]$UseParallel
    )

    try {
        # Estimate memory requirements in bytes
        # Each double takes 8 bytes
        $bytesPerDouble = 8

        # Memory for data
        $dataMemory = $DataCount * $bytesPerDouble * $Dimensions

        # Memory for evaluation points
        $evalPointsMemory = $EvaluationPointsCount * $bytesPerDouble * $Dimensions

        # Memory for density estimates
        $densityEstimatesMemory = $EvaluationPointsCount * $bytesPerDouble

        # Memory for intermediate calculations
        # For each evaluation point, we need to calculate the kernel value for each data point
        $intermediateMemory = $DataCount * $EvaluationPointsCount * $bytesPerDouble

        # Total memory
        $totalMemory = $dataMemory + $evalPointsMemory + $densityEstimatesMemory + $intermediateMemory

        # Add overhead for parallel processing if requested
        if ($UseParallel) {
            # Parallel processing can use more memory due to copying data to each thread
            $totalMemory = $totalMemory * 1.5
        }

        # Convert to MB for easier reading
        $totalMemoryMB = $totalMemory / 1MB

        # Create result object
        $result = [PSCustomObject]@{
            DataMemoryMB             = $dataMemory / 1MB
            EvalPointsMemoryMB       = $evalPointsMemory / 1MB
            DensityEstimatesMemoryMB = $densityEstimatesMemory / 1MB
            IntermediateMemoryMB     = $intermediateMemory / 1MB
            TotalMemoryMB            = $totalMemoryMB
            UseParallel              = $UseParallel.IsPresent
        }

        Write-Verbose "Estimated memory requirements: $totalMemoryMB MB"
        return $result
    } catch {
        Write-Verbose "Failed to estimate memory requirements: $($_.Exception.Message)"
        Throw-ValidationError -ErrorCode $ErrorCodes.MemoryAllocationFailed -Args @("Failed to estimate memory requirements: $($_.Exception.Message)")
    }
}

# Function to check if there is enough memory for kernel density estimation
function Test-KDEMemoryRequirements {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$MemoryRequirements,

        [Parameter(Mandatory = $false)]
        [double]$SafetyFactor = 1.5,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    try {
        # Get available memory
        $availableMemoryMB = Get-AvailableMemory

        # Calculate required memory with safety factor
        $requiredMemoryMB = $MemoryRequirements.TotalMemoryMB * $SafetyFactor

        # Check if there is enough memory
        $hasEnoughMemory = $availableMemoryMB -ge $requiredMemoryMB

        if (-not $hasEnoughMemory) {
            $message = "Not enough memory for kernel density estimation. Required: $requiredMemoryMB MB, Available: $availableMemoryMB MB"
            Write-Verbose $message

            if ($ThrowOnFailure) {
                Throw-ValidationError -ErrorCode $ErrorCodes.OutOfMemory
            }
        }

        return $hasEnoughMemory
    } catch {
        if ($_.Exception.ErrorCode) {
            # Re-throw validation errors
            throw $_.Exception
        } else {
            # Wrap other exceptions
            Write-Verbose "Failed to check memory requirements: $($_.Exception.Message)"

            if ($ThrowOnFailure) {
                Throw-ValidationError -ErrorCode $ErrorCodes.MemoryAllocationFailed -Args @("Failed to check memory requirements: $($_.Exception.Message)")
            }

            return $false
        }
    }
}

# Function to create a chunked array for processing large datasets
function Get-ChunkedArray {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Array,

        [Parameter(Mandatory = $true)]
        [int]$ChunkSize
    )

    try {
        # Validate chunk size
        if ($ChunkSize -lt 1) {
            Throw-ValidationError -ErrorCode $ErrorCodes.MemoryAllocationFailed -Args @("ChunkSize must be at least 1.")
        }

        # Create chunked array
        $chunks = New-Object System.Collections.ArrayList

        for ($i = 0; $i -lt $Array.Count; $i += $ChunkSize) {
            $end = [Math]::Min($i + $ChunkSize - 1, $Array.Count - 1)
            $chunk = $Array[$i..$end]
            [void]$chunks.Add($chunk)
        }

        return $chunks
    } catch {
        if ($_.Exception.ErrorCode) {
            # Re-throw validation errors
            throw $_.Exception
        } else {
            # Wrap other exceptions
            Throw-ValidationError -ErrorCode $ErrorCodes.MemoryAllocationFailed -Args @("Failed to create chunked array: $($_.Exception.Message)")
        }
    }
}

# Function to perform kernel density estimation with memory optimization
function Get-KernelDensityEstimateMemoryOptimized {
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
        [switch]$Normalize,

        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = "Whether to use parallel processing for large datasets.")]
        [switch]$UseParallel,

        [Parameter(Mandatory = $false,
            Position = 6,
            HelpMessage = "The maximum number of data points to process at once.")]
        [int]$ChunkSize = 10000,

        [Parameter(Mandatory = $false,
            Position = 7,
            HelpMessage = "Whether to check memory requirements before processing.")]
        [switch]$CheckMemory,

        [Parameter(Mandatory = $false,
            Position = 8,
            HelpMessage = "The safety factor to use when checking memory requirements.")]
        [double]$MemorySafetyFactor = 1.5
    )

    begin {
        # Start execution timer
        $startTime = Get-Date

        # Validate input data
        $Data = Test-KDEData -Data $Data

        # Generate evaluation points if not provided
        if (-not $EvaluationPoints) {
            $EvaluationPoints = Get-EvaluationPoints -Data $Data
        } else {
            $EvaluationPoints = Test-KDEEvaluationPoints -EvaluationPoints $EvaluationPoints
        }

        # Calculate bandwidth if not provided
        if ($Bandwidth -eq 0) {
            $Bandwidth = Get-SilvermanBandwidth -Data $Data
        } else {
            $Bandwidth = Test-KDEBandwidth -Bandwidth $Bandwidth
        }

        # Validate kernel type
        $KernelType = Test-KDEKernelType -KernelType $KernelType

        # Check memory requirements if requested
        if ($CheckMemory) {
            $memoryRequirements = Get-KDEMemoryRequirements -DataCount $Data.Count -EvaluationPointsCount $EvaluationPoints.Count -UseParallel:$UseParallel
            $hasEnoughMemory = Test-KDEMemoryRequirements -MemoryRequirements $memoryRequirements -SafetyFactor $MemorySafetyFactor -ThrowOnFailure
        }

        # Check if the dataset is large enough to benefit from chunking
        $useChunking = $Data.Count -gt $ChunkSize

        # Check if the dataset is large enough to benefit from parallel processing
        $useParallel = $UseParallel -and $Data.Count -gt 1000

        # Issue performance warnings for large datasets
        if ($Data.Count -gt 100000) {
            Write-Verbose "Performance warning: Large dataset ($($Data.Count) data points). Processing may take a while."
        }

        if ($EvaluationPoints.Count -gt 10000) {
            Write-Verbose "Performance warning: Large number of evaluation points ($($EvaluationPoints.Count)). Processing may take a while."
        }
    }

    process {
        try {
            # Initialize the density estimates
            $densityEstimates = New-Object double[] $EvaluationPoints.Count

            if ($useChunking) {
                # Process data in chunks to reduce memory usage
                $dataChunks = Get-ChunkedArray -Array $Data -ChunkSize $ChunkSize

                Write-Verbose "Processing data in $($dataChunks.Count) chunks of up to $ChunkSize data points each."

                foreach ($chunk in $dataChunks) {
                    # Calculate partial density estimates for this chunk
                    $partialDensityEstimates = Get-DensityEstimate -Data $chunk -EvaluationPoints $EvaluationPoints -KernelType $KernelType -Bandwidth $Bandwidth

                    # Add partial density estimates to the total
                    for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                        $densityEstimates[$i] += $partialDensityEstimates[$i] * ($chunk.Count / $Data.Count)
                    }
                }
            } else {
                # Process all data at once
                $densityEstimates = Get-DensityEstimate -Data $Data -EvaluationPoints $EvaluationPoints -KernelType $KernelType -Bandwidth $Bandwidth -Normalize:$Normalize
            }

            # Normalize the density estimates if requested
            if ($Normalize -and $useChunking) {
                # Normalize the density estimates
                $sum = ($densityEstimates | Measure-Object -Sum).Sum

                if ($sum -eq 0) {
                    Throw-ValidationError -ErrorCode $ErrorCodes.DensityNormalizationFailed
                }

                for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                    $densityEstimates[$i] = $densityEstimates[$i] / $sum
                }
            }
        } catch {
            if ($_.Exception.ErrorCode) {
                # Re-throw validation errors
                throw $_.Exception
            } else {
                # Wrap other exceptions
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityEstimationFailed -Args @("Failed to calculate density estimate: $($_.Exception.Message)")
            }
        }
    }

    end {
        # Calculate execution time
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalSeconds

        # Create the output object
        $result = [PSCustomObject]@{
            # Input data and results
            Data             = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates

            # Parameters used for the estimation
            Parameters       = [PSCustomObject]@{
                KernelType  = $KernelType
                Bandwidth   = $Bandwidth
                Normalize   = $Normalize.IsPresent
                UseParallel = $useParallel
                UseChunking = $useChunking
                ChunkSize   = $ChunkSize
            }

            # Statistics about the data and execution
            Statistics       = [PSCustomObject]@{
                # Data statistics
                DataCount     = $Data.Count
                DataMin       = ($Data | Measure-Object -Minimum).Minimum
                DataMax       = ($Data | Measure-Object -Maximum).Maximum
                DataRange     = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
                DataMean      = ($Data | Measure-Object -Average).Average

                # Execution statistics
                ExecutionTime = $executionTime
                Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            # Memory statistics
            MemoryStatistics = [PSCustomObject]@{
                EstimatedMemoryMB = if ($CheckMemory) { $memoryRequirements.TotalMemoryMB } else { 0 }
                AvailableMemoryMB = if ($CheckMemory) { Get-AvailableMemory } else { 0 }
                UseChunking       = $useChunking
                ChunkCount        = if ($useChunking) { $dataChunks.Count } else { 1 }
                ChunkSize         = $ChunkSize
            }
        }

        return $result
    }
}

# Export the functions
Export-ModuleMember -Function Get-AvailableMemory, Get-KDEMemoryRequirements, Test-KDEMemoryRequirements, Get-ChunkedArray, Get-KernelDensityEstimateMemoryOptimized
