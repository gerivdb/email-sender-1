# Test-KernelDensityEstimateExceptions.ps1
# Script to test the custom exception classes for kernel density estimation

# Import the exceptions module
Import-Module .\KernelDensityEstimateExceptions.psm1 -Force

# Function to test throwing and catching exceptions
function Test-Exception {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ThrowBlock,
        
        [Parameter(Mandatory = $true)]
        [type]$ExpectedExceptionType,
        
        [Parameter(Mandatory = $false)]
        [string]$ExpectedErrorCode = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ExpectedMessagePattern = ""
    )
    
    try {
        # Execute the block that should throw an exception
        & $ThrowBlock
        
        # If we get here, the exception was not thrown
        Write-Host "FAILED: $TestName - Exception was not thrown" -ForegroundColor Red
        return $false
    } catch {
        $exception = $_.Exception
        
        # Check if the exception is of the expected type
        if ($exception -is $ExpectedExceptionType) {
            # Check if the error code matches (if specified)
            if ($ExpectedErrorCode -and $exception.ErrorCode -ne $ExpectedErrorCode) {
                Write-Host "FAILED: $TestName - Expected error code '$ExpectedErrorCode', got '$($exception.ErrorCode)'" -ForegroundColor Red
                return $false
            }
            
            # Check if the message matches the pattern (if specified)
            if ($ExpectedMessagePattern -and $exception.Message -notmatch $ExpectedMessagePattern) {
                Write-Host "FAILED: $TestName - Message does not match pattern '$ExpectedMessagePattern'" -ForegroundColor Red
                Write-Host "  Actual message: $($exception.Message)" -ForegroundColor Red
                return $false
            }
            
            # All checks passed
            Write-Host "PASSED: $TestName" -ForegroundColor Green
            return $true
        } else {
            # Wrong exception type
            Write-Host "FAILED: $TestName - Expected exception type $($ExpectedExceptionType.Name), got $($exception.GetType().Name)" -ForegroundColor Red
            Write-Host "  Exception message: $($exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Test the base exception class
$test1 = Test-Exception -TestName "Base exception" -ThrowBlock {
    throw [KernelDensityEstimationException]::new("TEST", "Test message")
} -ExpectedExceptionType ([KernelDensityEstimationException]) -ExpectedErrorCode "TEST" -ExpectedMessagePattern "Test message"

# Test the validation exception class
$test2 = Test-Exception -TestName "Validation exception" -ThrowBlock {
    throw [KernelDensityEstimationValidationException]::new("V999", "Validation test message")
} -ExpectedExceptionType ([KernelDensityEstimationValidationException]) -ExpectedErrorCode "V999" -ExpectedMessagePattern "Validation test message"

# Test the calculation exception class
$test3 = Test-Exception -TestName "Calculation exception" -ThrowBlock {
    throw [KernelDensityEstimationCalculationException]::new("C999", "Calculation test message")
} -ExpectedExceptionType ([KernelDensityEstimationCalculationException]) -ExpectedErrorCode "C999" -ExpectedMessagePattern "Calculation test message"

# Test the memory exception class
$test4 = Test-Exception -TestName "Memory exception" -ThrowBlock {
    throw [KernelDensityEstimationMemoryException]::new("M999", "Memory test message")
} -ExpectedExceptionType ([KernelDensityEstimationMemoryException]) -ExpectedErrorCode "M999" -ExpectedMessagePattern "Memory test message"

# Test specific exception classes
$test5 = Test-Exception -TestName "DataTooSmallException" -ThrowBlock {
    throw [DataTooSmallException]::new(1)
} -ExpectedExceptionType ([DataTooSmallException]) -ExpectedErrorCode "V002" -ExpectedMessagePattern "too few points.*Minimum required: 2, Actual: 1"

$test6 = Test-Exception -TestName "BandwidthNegativeException" -ThrowBlock {
    throw [BandwidthNegativeException]::new(-1.5)
} -ExpectedExceptionType ([BandwidthNegativeException]) -ExpectedErrorCode "V201" -ExpectedMessagePattern "bandwidth is negative: -1.5"

$test7 = Test-Exception -TestName "InvalidKernelTypeException" -ThrowBlock {
    throw [InvalidKernelTypeException]::new("InvalidKernel", "Gaussian, Epanechnikov, Triangular")
} -ExpectedExceptionType ([InvalidKernelTypeException]) -ExpectedErrorCode "V301" -ExpectedMessagePattern "kernel type 'InvalidKernel' is not valid.*Gaussian, Epanechnikov, Triangular"

$test8 = Test-Exception -TestName "DensityEstimationFailedException" -ThrowBlock {
    throw [DensityEstimationFailedException]::new("Test failure details")
} -ExpectedExceptionType ([DensityEstimationFailedException]) -ExpectedErrorCode "C201" -ExpectedMessagePattern "density estimation failed.*Test failure details"

# Test the helper function
$test9 = Test-Exception -TestName "Throw-KernelDensityEstimationException (V002)" -ThrowBlock {
    Throw-KernelDensityEstimationException -ErrorCode "V002" -Args @(1)
} -ExpectedExceptionType ([DataTooSmallException]) -ExpectedErrorCode "V002" -ExpectedMessagePattern "too few points.*Minimum required: 2, Actual: 1"

$test10 = Test-Exception -TestName "Throw-KernelDensityEstimationException (V301)" -ThrowBlock {
    Throw-KernelDensityEstimationException -ErrorCode "V301" -Args @("InvalidKernel", "Gaussian, Epanechnikov, Triangular")
} -ExpectedExceptionType ([InvalidKernelTypeException]) -ExpectedErrorCode "V301" -ExpectedMessagePattern "kernel type 'InvalidKernel' is not valid.*Gaussian, Epanechnikov, Triangular"

$test11 = Test-Exception -TestName "Throw-KernelDensityEstimationException (C201)" -ThrowBlock {
    Throw-KernelDensityEstimationException -ErrorCode "C201" -Details "Test failure details"
} -ExpectedExceptionType ([DensityEstimationFailedException]) -ExpectedErrorCode "C201" -ExpectedMessagePattern "density estimation failed.*Test failure details"

$test12 = Test-Exception -TestName "Throw-KernelDensityEstimationException (Unknown)" -ThrowBlock {
    Throw-KernelDensityEstimationException -ErrorCode "UNKNOWN" -Details "Unknown error details"
} -ExpectedExceptionType ([KernelDensityEstimationException]) -ExpectedErrorCode "UNKNOWN" -ExpectedMessagePattern "Unknown error: Unknown error details"

# Test inheritance (catching a specific exception type)
$test13 = Test-Exception -TestName "Inheritance (DataTooSmallException is KernelDensityEstimationValidationException)" -ThrowBlock {
    try {
        throw [DataTooSmallException]::new(1)
    } catch [KernelDensityEstimationValidationException] {
        # This should catch the exception
        # Re-throw it to be caught by the Test-Exception function
        throw $_.Exception
    }
} -ExpectedExceptionType ([DataTooSmallException]) -ExpectedErrorCode "V002"

$test14 = Test-Exception -TestName "Inheritance (DataTooSmallException is KernelDensityEstimationException)" -ThrowBlock {
    try {
        throw [DataTooSmallException]::new(1)
    } catch [KernelDensityEstimationException] {
        # This should catch the exception
        # Re-throw it to be caught by the Test-Exception function
        throw $_.Exception
    }
} -ExpectedExceptionType ([DataTooSmallException]) -ExpectedErrorCode "V002"

# Test inheritance (catching a base exception type)
$test15 = Test-Exception -TestName "Inheritance (KernelDensityEstimationValidationException is Exception)" -ThrowBlock {
    try {
        throw [KernelDensityEstimationValidationException]::new("V999", "Test message")
    } catch [Exception] {
        # This should catch the exception
        # Re-throw it to be caught by the Test-Exception function
        throw $_.Exception
    }
} -ExpectedExceptionType ([KernelDensityEstimationValidationException]) -ExpectedErrorCode "V999"

# Test inner exceptions
$test16 = Test-Exception -TestName "Inner exception" -ThrowBlock {
    try {
        # Simulate a division by zero error
        $result = 1 / 0
    } catch {
        # Wrap the exception in a custom exception
        throw [KernelDensityEstimationCalculationException]::new("C999", "Calculation error", $_.Exception)
    }
} -ExpectedExceptionType ([KernelDensityEstimationCalculationException]) -ExpectedErrorCode "C999" -ExpectedMessagePattern "Calculation error"

# Test inner exceptions with the helper function
$test17 = Test-Exception -TestName "Inner exception with helper function" -ThrowBlock {
    try {
        # Simulate a division by zero error
        $result = 1 / 0
    } catch {
        # Wrap the exception in a custom exception
        Throw-KernelDensityEstimationException -ErrorCode "UNKNOWN" -Details "Calculation error" -InnerException $_.Exception
    }
} -ExpectedExceptionType ([KernelDensityEstimationException]) -ExpectedErrorCode "UNKNOWN" -ExpectedMessagePattern "Unknown error: Calculation error"

# Summary
$totalTests = 17
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9, $test10, $test11, $test12, $test13, $test14, $test15, $test16, $test17).Where({ $_ -eq $true }).Count

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed tests: $passedTests" -ForegroundColor Cyan
Write-Host "Failed tests: $($totalTests - $passedTests)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
}
