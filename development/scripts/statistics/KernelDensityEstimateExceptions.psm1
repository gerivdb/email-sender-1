# KernelDensityEstimateExceptions.psm1
# Module defining custom exception classes for kernel density estimation

# Base exception class for all kernel density estimation errors
class KernelDensityEstimationException : Exception {
    [string]$ErrorCode

    KernelDensityEstimationException([string]$errorCode, [string]$message) : base($message) {
        $this.ErrorCode = $errorCode
    }

    KernelDensityEstimationException([string]$errorCode, [string]$message, [Exception]$innerException) : base($message, $innerException) {
        $this.ErrorCode = $errorCode
    }
}

# Exception class for validation errors
class KernelDensityEstimationValidationException : KernelDensityEstimationException {
    KernelDensityEstimationValidationException([string]$errorCode, [string]$message) : base($errorCode, $message) {}

    KernelDensityEstimationValidationException([string]$errorCode, [string]$message, [Exception]$innerException) : base($errorCode, $message, $innerException) {}
}

# Exception class for calculation errors
class KernelDensityEstimationCalculationException : KernelDensityEstimationException {
    KernelDensityEstimationCalculationException([string]$errorCode, [string]$message) : base($errorCode, $message) {}

    KernelDensityEstimationCalculationException([string]$errorCode, [string]$message, [Exception]$innerException) : base($errorCode, $message, $innerException) {}
}

# Exception class for memory errors
class KernelDensityEstimationMemoryException : KernelDensityEstimationException {
    KernelDensityEstimationMemoryException([string]$errorCode, [string]$message) : base($errorCode, $message) {}

    KernelDensityEstimationMemoryException([string]$errorCode, [string]$message, [Exception]$innerException) : base($errorCode, $message, $innerException) {}
}

# Data validation exception classes
class DataNullOrEmptyException : KernelDensityEstimationValidationException {
    DataNullOrEmptyException() : base("V001", "The input data is null or empty.") {}
}

class DataTooSmallException : KernelDensityEstimationValidationException {
    DataTooSmallException([int]$count) : base("V002", "The input data has too few points. Minimum required: 2, Actual: $count.") {}
}

class DataContainsNaNException : KernelDensityEstimationValidationException {
    DataContainsNaNException() : base("V003", "The input data contains NaN values.") {}
}

class DataContainsInfinityException : KernelDensityEstimationValidationException {
    DataContainsInfinityException() : base("V004", "The input data contains infinity values.") {}
}

class DataNotNumericException : KernelDensityEstimationValidationException {
    DataNotNumericException() : base("V005", "The input data contains non-numeric values.") {}
}

class DataDimensionMismatchException : KernelDensityEstimationValidationException {
    DataDimensionMismatchException([string]$details) : base("V006", "The input data points have inconsistent dimensions. $details") {}
}

# Evaluation points validation exception classes
class EvalPointsEmptyException : KernelDensityEstimationValidationException {
    EvalPointsEmptyException() : base("V101", "The evaluation points array is empty.") {}
}

class EvalPointsContainsNaNException : KernelDensityEstimationValidationException {
    EvalPointsContainsNaNException() : base("V102", "The evaluation points contain NaN values.") {}
}

class EvalPointsContainsInfinityException : KernelDensityEstimationValidationException {
    EvalPointsContainsInfinityException() : base("V103", "The evaluation points contain infinity values.") {}
}

class EvalPointsNotNumericException : KernelDensityEstimationValidationException {
    EvalPointsNotNumericException() : base("V104", "The evaluation points contain non-numeric values.") {}
}

class EvalPointsDimensionMismatchException : KernelDensityEstimationValidationException {
    EvalPointsDimensionMismatchException([string]$details) : base("V105", "The evaluation points have inconsistent dimensions. $details") {}
}

# Bandwidth validation exception classes
class BandwidthNegativeException : KernelDensityEstimationValidationException {
    BandwidthNegativeException([double]$bandwidth) : base("V201", "The bandwidth is negative: $bandwidth.") {}
}

class BandwidthZeroException : KernelDensityEstimationValidationException {
    BandwidthZeroException() : base("V202", "The bandwidth is zero. This is only allowed when automatic bandwidth selection is enabled.") {}
}

class BandwidthContainsNaNException : KernelDensityEstimationValidationException {
    BandwidthContainsNaNException() : base("V203", "The bandwidth contains NaN values.") {}
}

class BandwidthContainsInfinityException : KernelDensityEstimationValidationException {
    BandwidthContainsInfinityException() : base("V204", "The bandwidth contains infinity values.") {}
}

class BandwidthDimensionMismatchException : KernelDensityEstimationValidationException {
    BandwidthDimensionMismatchException([string]$details) : base("V205", "The bandwidth dimensions do not match the data dimensions. $details") {}
}

# Other parameter validation exception classes
class InvalidKernelTypeException : KernelDensityEstimationValidationException {
    InvalidKernelTypeException([string]$kernelType, [string]$validKernelTypes) : base("V301", "The kernel type '$kernelType' is not valid. Valid kernel types are: $validKernelTypes.") {}
}

class InvalidMethodException : KernelDensityEstimationValidationException {
    InvalidMethodException([string]$method, [string]$validMethods) : base("V302", "The bandwidth selection method '$method' is not valid. Valid methods are: $validMethods.") {}
}

class InvalidObjectiveException : KernelDensityEstimationValidationException {
    InvalidObjectiveException([string]$objective, [string]$validObjectives) : base("V303", "The objective '$objective' is not valid. Valid objectives are: $validObjectives.") {}
}

class KFoldsTooSmallException : KernelDensityEstimationValidationException {
    KFoldsTooSmallException([int]$kFolds) : base("V304", "The number of folds ($kFolds) is too small. Minimum required: 2.") {}
}

class KFoldsTooLargeException : KernelDensityEstimationValidationException {
    KFoldsTooLargeException([int]$kFolds, [int]$dataCount) : base("V305", "The number of folds ($kFolds) is larger than the number of data points ($dataCount).") {}
}

class MaxIterationsTooSmallException : KernelDensityEstimationValidationException {
    MaxIterationsTooSmallException([int]$maxIterations) : base("V306", "The maximum number of iterations ($maxIterations) is too small. Minimum required: 1.") {}
}

class DimensionsNotSpecifiedException : KernelDensityEstimationValidationException {
    DimensionsNotSpecifiedException() : base("V307", "The dimensions are not specified for multivariate data.") {}
}

class DimensionsNotFoundException : KernelDensityEstimationValidationException {
    DimensionsNotFoundException([string]$dimension, [string]$availableDimensions) : base("V308", "The specified dimension '$dimension' is not found in the data. Available dimensions are: $availableDimensions.") {}
}

# Bandwidth calculation exception classes
class BandwidthCalculationFailedException : KernelDensityEstimationCalculationException {
    BandwidthCalculationFailedException([string]$details) : base("C001", "The bandwidth calculation failed. $details") {}
}

class BandwidthTooSmallException : KernelDensityEstimationCalculationException {
    BandwidthTooSmallException([double]$bandwidth, [double]$minBandwidth) : base("C002", "The calculated bandwidth ($bandwidth) is too small. Minimum allowed: $minBandwidth.") {}
}

class BandwidthTooLargeException : KernelDensityEstimationCalculationException {
    BandwidthTooLargeException([double]$bandwidth, [double]$maxBandwidth) : base("C003", "The calculated bandwidth ($bandwidth) is too large. Maximum allowed: $maxBandwidth.") {}
}

class BandwidthOptimizationFailedException : KernelDensityEstimationCalculationException {
    BandwidthOptimizationFailedException([string]$details) : base("C004", "The bandwidth optimization failed to converge. $details") {}
}

# Kernel calculation exception classes
class KernelCalculationFailedException : KernelDensityEstimationCalculationException {
    KernelCalculationFailedException([string]$details) : base("C101", "The kernel calculation failed. $details") {}
}

class KernelNormalizationFailedException : KernelDensityEstimationCalculationException {
    KernelNormalizationFailedException() : base("C102", "The kernel normalization failed because all density estimates are zero.") {}
}

class KernelIntegrationFailedException : KernelDensityEstimationCalculationException {
    KernelIntegrationFailedException([string]$details) : base("C103", "The kernel integration failed. $details") {}
}

# Density estimation exception classes
class DensityEstimationFailedException : KernelDensityEstimationCalculationException {
    DensityEstimationFailedException([string]$details) : base("C201", "The density estimation failed. $details") {}
}

class DensityNormalizationFailedException : KernelDensityEstimationCalculationException {
    DensityNormalizationFailedException() : base("C202", "The density normalization failed because all density estimates are zero.") {}
}

class DensityContainsNaNException : KernelDensityEstimationCalculationException {
    DensityContainsNaNException() : base("C203", "The density estimates contain NaN values.") {}
}

class DensityContainsInfinityException : KernelDensityEstimationCalculationException {
    DensityContainsInfinityException() : base("C204", "The density estimates contain infinity values.") {}
}

class DensityNegativeException : KernelDensityEstimationCalculationException {
    DensityNegativeException() : base("C205", "The density estimates contain negative values.") {}
}

# Memory allocation exception classes
class MemoryAllocationFailedException : KernelDensityEstimationMemoryException {
    MemoryAllocationFailedException([string]$details) : base("M001", "Failed to allocate memory. $details") {}
}

class ArrayTooLargeException : KernelDensityEstimationMemoryException {
    ArrayTooLargeException([string]$arrayName, [int]$size) : base("M002", "The $arrayName array is too large to allocate ($size elements).") {}
}

class OutOfMemoryException : KernelDensityEstimationMemoryException {
    OutOfMemoryException() : base("M003", "The system is out of memory.") {}
}

# Performance exception classes
class PerformanceWarningException : KernelDensityEstimationMemoryException {
    PerformanceWarningException([string]$details) : base("M101", "Performance warning: $details") {}
}

class DimensionalityWarningException : KernelDensityEstimationMemoryException {
    DimensionalityWarningException([int]$dimensions) : base("M102", "Dimensionality warning: The data has $dimensions dimensions, which may cause performance issues.") {}
}

class ParallelizationFailedException : KernelDensityEstimationMemoryException {
    ParallelizationFailedException([string]$details) : base("M103", "Failed to parallelize the computation. $details") {}
}

# Helper function to throw the appropriate exception based on the error code
function Write-KernelDensityEstimationException {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorCode,

        [Parameter(Mandatory = $false)]
        [string]$Details = "",

        [Parameter(Mandatory = $false)]
        [object[]]$Args = @(),

        [Parameter(Mandatory = $false)]
        [Exception]$InnerException = $null
    )

    switch ($ErrorCode) {
        # Data validation exceptions
        "V001" { throw [DataNullOrEmptyException]::new() }
        "V002" { throw [DataTooSmallException]::new($Args[0]) }
        "V003" { throw [DataContainsNaNException]::new() }
        "V004" { throw [DataContainsInfinityException]::new() }
        "V005" { throw [DataNotNumericException]::new() }
        "V006" { throw [DataDimensionMismatchException]::new($Details) }

        # Evaluation points validation exceptions
        "V101" { throw [EvalPointsEmptyException]::new() }
        "V102" { throw [EvalPointsContainsNaNException]::new() }
        "V103" { throw [EvalPointsContainsInfinityException]::new() }
        "V104" { throw [EvalPointsNotNumericException]::new() }
        "V105" { throw [EvalPointsDimensionMismatchException]::new($Details) }

        # Bandwidth validation exceptions
        "V201" { throw [BandwidthNegativeException]::new($Args[0]) }
        "V202" { throw [BandwidthZeroException]::new() }
        "V203" { throw [BandwidthContainsNaNException]::new() }
        "V204" { throw [BandwidthContainsInfinityException]::new() }
        "V205" { throw [BandwidthDimensionMismatchException]::new($Details) }

        # Other parameter validation exceptions
        "V301" { throw [InvalidKernelTypeException]::new($Args[0], $Args[1]) }
        "V302" { throw [InvalidMethodException]::new($Args[0], $Args[1]) }
        "V303" { throw [InvalidObjectiveException]::new($Args[0], $Args[1]) }
        "V304" { throw [KFoldsTooSmallException]::new($Args[0]) }
        "V305" { throw [KFoldsTooLargeException]::new($Args[0], $Args[1]) }
        "V306" { throw [MaxIterationsTooSmallException]::new($Args[0]) }
        "V307" { throw [DimensionsNotSpecifiedException]::new() }
        "V308" { throw [DimensionsNotFoundException]::new($Args[0], $Args[1]) }

        # Bandwidth calculation exceptions
        "C001" { throw [BandwidthCalculationFailedException]::new($Details) }
        "C002" { throw [BandwidthTooSmallException]::new($Args[0], $Args[1]) }
        "C003" { throw [BandwidthTooLargeException]::new($Args[0], $Args[1]) }
        "C004" { throw [BandwidthOptimizationFailedException]::new($Details) }

        # Kernel calculation exceptions
        "C101" { throw [KernelCalculationFailedException]::new($Details) }
        "C102" { throw [KernelNormalizationFailedException]::new() }
        "C103" { throw [KernelIntegrationFailedException]::new($Details) }

        # Density estimation exceptions
        "C201" { throw [DensityEstimationFailedException]::new($Details) }
        "C202" { throw [DensityNormalizationFailedException]::new() }
        "C203" { throw [DensityContainsNaNException]::new() }
        "C204" { throw [DensityContainsInfinityException]::new() }
        "C205" { throw [DensityNegativeException]::new() }

        # Memory allocation exceptions
        "M001" { throw [MemoryAllocationFailedException]::new($Details) }
        "M002" { throw [ArrayTooLargeException]::new($Args[0], $Args[1]) }
        "M003" { throw [OutOfMemoryException]::new() }

        # Performance exceptions
        "M101" { throw [PerformanceWarningException]::new($Details) }
        "M102" { throw [DimensionalityWarningException]::new($Args[0]) }
        "M103" { throw [ParallelizationFailedException]::new($Details) }

        # Default case for unknown error codes
        default {
            if ($InnerException) {
                throw [KernelDensityEstimationException]::new($ErrorCode, "Unknown error: $Details", $InnerException)
            } else {
                throw [KernelDensityEstimationException]::new($ErrorCode, "Unknown error: $Details")
            }
        }
    }
}

# Export the exception classes and helper function
# Note: Classes are not automatically exported with Export-ModuleMember
# We need to use the -Variable parameter with * to export all variables, including classes
Export-ModuleMember -function Write-KernelDensityEstimationException -Variable *

