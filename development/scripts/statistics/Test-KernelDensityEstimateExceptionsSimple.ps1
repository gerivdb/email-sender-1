# Test-KernelDensityEstimateExceptionsSimple.ps1
# Script to test the custom exception classes for kernel density estimation

# Import the exceptions module
# Using dot-sourcing to make the classes available in the current scope
. .\KernelDensityEstimateExceptions.psm1

# Test the base exception class
Write-Host "Testing base exception class..." -ForegroundColor Cyan
try {
    throw [KernelDensityEstimationException]::new("TEST", "Test message")
} catch {
    $exception = $_.Exception
    if ($exception -is [KernelDensityEstimationException] -and $exception.ErrorCode -eq "TEST" -and $exception.Message -eq "Test message") {
        Write-Host "  PASSED: Base exception class" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Base exception class" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
    }
}

# Test the validation exception class
Write-Host "`nTesting validation exception class..." -ForegroundColor Cyan
try {
    throw [KernelDensityEstimationValidationException]::new("V999", "Validation test message")
} catch {
    $exception = $_.Exception
    if ($exception -is [KernelDensityEstimationValidationException] -and $exception.ErrorCode -eq "V999" -and $exception.Message -eq "Validation test message") {
        Write-Host "  PASSED: Validation exception class" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Validation exception class" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
    }
}

# Test a specific exception class
Write-Host "`nTesting specific exception class (DataTooSmallException)..." -ForegroundColor Cyan
try {
    throw [DataTooSmallException]::new(1)
} catch {
    $exception = $_.Exception
    if ($exception -is [DataTooSmallException] -and $exception.ErrorCode -eq "V002" -and $exception.Message -match "too few points.*Minimum required: 2, Actual: 1") {
        Write-Host "  PASSED: DataTooSmallException" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: DataTooSmallException" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
    }
}

# Test the helper function
Write-Host "`nTesting helper function (Throw-KernelDensityEstimationException)..." -ForegroundColor Cyan
try {
    Throw-KernelDensityEstimationException -ErrorCode "V002" -Args @(1)
} catch {
    $exception = $_.Exception
    if ($exception -is [DataTooSmallException] -and $exception.ErrorCode -eq "V002" -and $exception.Message -match "too few points.*Minimum required: 2, Actual: 1") {
        Write-Host "  PASSED: Throw-KernelDensityEstimationException (V002)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Throw-KernelDensityEstimationException (V002)" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
    }
}

# Test inheritance (catching a specific exception type)
Write-Host "`nTesting inheritance (DataTooSmallException is KernelDensityEstimationValidationException)..." -ForegroundColor Cyan
try {
    try {
        throw [DataTooSmallException]::new(1)
    } catch [KernelDensityEstimationValidationException] {
        # This should catch the exception
        Write-Host "  PASSED: DataTooSmallException is caught as KernelDensityEstimationValidationException" -ForegroundColor Green
        # Re-throw it to be caught by the outer try/catch
        throw
    }
} catch {
    $exception = $_.Exception
    if ($exception -is [DataTooSmallException]) {
        Write-Host "  PASSED: Exception is still DataTooSmallException" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Exception is not DataTooSmallException" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
    }
}

# Test inheritance (catching a base exception type)
Write-Host "`nTesting inheritance (KernelDensityEstimationValidationException is KernelDensityEstimationException)..." -ForegroundColor Cyan
try {
    try {
        throw [KernelDensityEstimationValidationException]::new("V999", "Test message")
    } catch [KernelDensityEstimationException] {
        # This should catch the exception
        Write-Host "  PASSED: KernelDensityEstimationValidationException is caught as KernelDensityEstimationException" -ForegroundColor Green
        # Re-throw it to be caught by the outer try/catch
        throw
    }
} catch {
    $exception = $_.Exception
    if ($exception -is [KernelDensityEstimationValidationException]) {
        Write-Host "  PASSED: Exception is still KernelDensityEstimationValidationException" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Exception is not KernelDensityEstimationValidationException" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
    }
}

# Test inner exceptions
Write-Host "`nTesting inner exceptions..." -ForegroundColor Cyan
try {
    try {
        # Simulate a division by zero error
        $result = 1 / 0
    } catch {
        # Wrap the exception in a custom exception
        throw [KernelDensityEstimationCalculationException]::new("C999", "Calculation error", $_.Exception)
    }
} catch {
    $exception = $_.Exception
    if ($exception -is [KernelDensityEstimationCalculationException] -and $exception.ErrorCode -eq "C999" -and $exception.Message -eq "Calculation error" -and $exception.InnerException -ne $null) {
        Write-Host "  PASSED: Inner exception" -ForegroundColor Green
        Write-Host "    Inner exception type: $($exception.InnerException.GetType().Name)" -ForegroundColor Green
        Write-Host "    Inner exception message: $($exception.InnerException.Message)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Inner exception" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
        Write-Host "    Has inner exception: $($exception.InnerException -ne $null)" -ForegroundColor Red
    }
}

# Test inner exceptions with the helper function
Write-Host "`nTesting inner exceptions with helper function..." -ForegroundColor Cyan
try {
    try {
        # Simulate a division by zero error
        $result = 1 / 0
    } catch {
        # Wrap the exception in a custom exception
        Throw-KernelDensityEstimationException -ErrorCode "UNKNOWN" -Details "Calculation error" -InnerException $_.Exception
    }
} catch {
    $exception = $_.Exception
    if ($exception -is [KernelDensityEstimationException] -and $exception.ErrorCode -eq "UNKNOWN" -and $exception.Message -match "Unknown error: Calculation error" -and $exception.InnerException -ne $null) {
        Write-Host "  PASSED: Inner exception with helper function" -ForegroundColor Green
        Write-Host "    Inner exception type: $($exception.InnerException.GetType().Name)" -ForegroundColor Green
        Write-Host "    Inner exception message: $($exception.InnerException.Message)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Inner exception with helper function" -ForegroundColor Red
        Write-Host "    Exception type: $($exception.GetType().Name)" -ForegroundColor Red
        Write-Host "    Error code: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "    Message: $($exception.Message)" -ForegroundColor Red
        Write-Host "    Has inner exception: $($exception.InnerException -ne $null)" -ForegroundColor Red
    }
}

Write-Host "`nAll tests completed." -ForegroundColor Cyan
