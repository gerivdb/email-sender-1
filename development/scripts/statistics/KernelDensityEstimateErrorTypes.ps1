# KernelDensityEstimateErrorTypes.ps1
# Script defining error types for kernel density estimation

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

# Helper function to throw the appropriate exception based on the error code
function Throw-KernelDensityEstimationException {
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

# Simple test to verify that the error types work
Write-Host "Testing error types..." -ForegroundColor Cyan

# Test the base exception class
try {
    throw [KernelDensityEstimationException]::new("TEST", "Test message")
} catch {
    Write-Host "  PASSED: Base exception class" -ForegroundColor Green
    Write-Host "    Error code: $($_.Exception.ErrorCode)" -ForegroundColor Green
    Write-Host "    Message: $($_.Exception.Message)" -ForegroundColor Green
}

# Test a specific exception class
try {
    throw [DataTooSmallException]::new(1)
} catch {
    Write-Host "`n  PASSED: DataTooSmallException" -ForegroundColor Green
    Write-Host "    Error code: $($_.Exception.ErrorCode)" -ForegroundColor Green
    Write-Host "    Message: $($_.Exception.Message)" -ForegroundColor Green
}

# Test the helper function
try {
    Throw-KernelDensityEstimationException -ErrorCode "V002" -Args @(1)
} catch {
    Write-Host "`n  PASSED: Throw-KernelDensityEstimationException (V002)" -ForegroundColor Green
    Write-Host "    Error code: $($_.Exception.ErrorCode)" -ForegroundColor Green
    Write-Host "    Message: $($_.Exception.Message)" -ForegroundColor Green
}

Write-Host "`nAll tests completed." -ForegroundColor Cyan
