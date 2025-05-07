# Test-KernelDensityEstimateErrorMessages.ps1
# Script to test the enhanced error messages for kernel density estimation

# Add debug information
Write-Host "Starting test script..." -ForegroundColor Yellow
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow

# Import the error messages module
Write-Host "Importing error messages module..." -ForegroundColor Yellow
. .\KernelDensityEstimateErrorMessages.ps1
Write-Host "Import completed." -ForegroundColor Yellow

# Test getting enhanced error messages
Write-Host "Testing Get-EnhancedErrorMessage function..." -ForegroundColor Cyan

# Test getting an enhanced error message for a data validation error
try {
    $errorMessage = Get-EnhancedErrorMessage -ErrorCode $ErrorCodes.DataNullOrEmpty
    
    Write-Host "PASSED: Get enhanced error message for DataNullOrEmpty" -ForegroundColor Green
    Write-Host "  Message: $($errorMessage.Message)" -ForegroundColor Green
    Write-Host "  Context: $($errorMessage.Context)" -ForegroundColor Green
    Write-Host "  Resolution: $($errorMessage.Resolution)" -ForegroundColor Green
    Write-Host "  Example: $($errorMessage.Example)" -ForegroundColor Green
    $test1 = $true
} catch {
    Write-Host "FAILED: Get enhanced error message for DataNullOrEmpty - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test1 = $false
}

# Test getting an enhanced error message with arguments
try {
    $errorMessage = Get-EnhancedErrorMessage -ErrorCode $ErrorCodes.DataTooSmall -Args @(1)
    
    Write-Host "`nPASSED: Get enhanced error message with arguments" -ForegroundColor Green
    Write-Host "  Message: $($errorMessage.Message)" -ForegroundColor Green
    Write-Host "  Context: $($errorMessage.Context)" -ForegroundColor Green
    Write-Host "  Resolution: $($errorMessage.Resolution)" -ForegroundColor Green
    Write-Host "  Example: $($errorMessage.Example)" -ForegroundColor Green
    $test2 = $true
} catch {
    Write-Host "`nFAILED: Get enhanced error message with arguments - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test2 = $false
}

# Test getting an enhanced error message for an unknown error code
try {
    $errorMessage = Get-EnhancedErrorMessage -ErrorCode "UNKNOWN_ERROR_CODE"
    
    Write-Host "`nPASSED: Get enhanced error message for unknown error code" -ForegroundColor Green
    Write-Host "  Message: $($errorMessage.Message)" -ForegroundColor Green
    Write-Host "  Context: $($errorMessage.Context)" -ForegroundColor Green
    Write-Host "  Resolution: $($errorMessage.Resolution)" -ForegroundColor Green
    Write-Host "  Example: $($errorMessage.Example)" -ForegroundColor Green
    $test3 = $true
} catch {
    Write-Host "`nFAILED: Get enhanced error message for unknown error code - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test3 = $false
}

# Test throwing enhanced errors
Write-Host "`nTesting Throw-EnhancedError function..." -ForegroundColor Cyan

# Test throwing an enhanced error
try {
    Throw-EnhancedError -ErrorCode $ErrorCodes.DataNullOrEmpty
    
    Write-Host "FAILED: Throw enhanced error - No exception was thrown" -ForegroundColor Red
    $test4 = $false
} catch {
    $exception = $_.Exception
    
    if ($exception.ErrorCode -eq $ErrorCodes.DataNullOrEmpty) {
        Write-Host "PASSED: Throw enhanced error" -ForegroundColor Green
        Write-Host "  Error code: $($exception.ErrorCode)" -ForegroundColor Green
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Green
        $test4 = $true
    } else {
        Write-Host "FAILED: Throw enhanced error - Wrong error code" -ForegroundColor Red
        Write-Host "  Expected: $($ErrorCodes.DataNullOrEmpty)" -ForegroundColor Red
        Write-Host "  Actual: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Red
        $test4 = $false
    }
}

# Test throwing an enhanced error with arguments
try {
    Throw-EnhancedError -ErrorCode $ErrorCodes.DataTooSmall -Args @(1)
    
    Write-Host "`nFAILED: Throw enhanced error with arguments - No exception was thrown" -ForegroundColor Red
    $test5 = $false
} catch {
    $exception = $_.Exception
    
    if ($exception.ErrorCode -eq $ErrorCodes.DataTooSmall) {
        Write-Host "`nPASSED: Throw enhanced error with arguments" -ForegroundColor Green
        Write-Host "  Error code: $($exception.ErrorCode)" -ForegroundColor Green
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Green
        $test5 = $true
    } else {
        Write-Host "`nFAILED: Throw enhanced error with arguments - Wrong error code" -ForegroundColor Red
        Write-Host "  Expected: $($ErrorCodes.DataTooSmall)" -ForegroundColor Red
        Write-Host "  Actual: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Red
        $test5 = $false
    }
}

# Test throwing an enhanced error with help information
try {
    Throw-EnhancedError -ErrorCode $ErrorCodes.DataNullOrEmpty -IncludeHelp
    
    Write-Host "`nFAILED: Throw enhanced error with help information - No exception was thrown" -ForegroundColor Red
    $test6 = $false
} catch {
    $exception = $_.Exception
    
    if ($exception.ErrorCode -eq $ErrorCodes.DataNullOrEmpty) {
        Write-Host "`nPASSED: Throw enhanced error with help information" -ForegroundColor Green
        Write-Host "  Error code: $($exception.ErrorCode)" -ForegroundColor Green
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Green
        $test6 = $true
    } else {
        Write-Host "`nFAILED: Throw enhanced error with help information - Wrong error code" -ForegroundColor Red
        Write-Host "  Expected: $($ErrorCodes.DataNullOrEmpty)" -ForegroundColor Red
        Write-Host "  Actual: $($exception.ErrorCode)" -ForegroundColor Red
        Write-Host "  Message: $($exception.Message)" -ForegroundColor Red
        $test6 = $false
    }
}

# Test formatting error messages
Write-Host "`nTesting Format-ErrorMessage function..." -ForegroundColor Cyan

# Create a test exception
try {
    Throw-ValidationError -ErrorCode $ErrorCodes.DataNullOrEmpty
} catch {
    $testException = $_.Exception
}

# Test formatting an error message
try {
    $formattedMessage = Format-ErrorMessage -Exception $testException
    
    Write-Host "PASSED: Format error message" -ForegroundColor Green
    Write-Host "  Formatted message: $formattedMessage" -ForegroundColor Green
    $test7 = $true
} catch {
    Write-Host "FAILED: Format error message - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test7 = $false
}

# Test formatting an error message with help information
try {
    $formattedMessage = Format-ErrorMessage -Exception $testException -IncludeHelp
    
    Write-Host "`nPASSED: Format error message with help information" -ForegroundColor Green
    Write-Host "  Formatted message: $formattedMessage" -ForegroundColor Green
    $test8 = $true
} catch {
    Write-Host "`nFAILED: Format error message with help information - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test8 = $false
}

# Test formatting an error message with stack trace
try {
    $formattedMessage = Format-ErrorMessage -Exception $testException -IncludeStackTrace
    
    Write-Host "`nPASSED: Format error message with stack trace" -ForegroundColor Green
    Write-Host "  Formatted message: $formattedMessage" -ForegroundColor Green
    $test9 = $true
} catch {
    Write-Host "`nFAILED: Format error message with stack trace - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test9 = $false
}

# Test formatting an error message with help information and stack trace
try {
    $formattedMessage = Format-ErrorMessage -Exception $testException -IncludeHelp -IncludeStackTrace
    
    Write-Host "`nPASSED: Format error message with help information and stack trace" -ForegroundColor Green
    Write-Host "  Formatted message: $formattedMessage" -ForegroundColor Green
    $test10 = $true
} catch {
    Write-Host "`nFAILED: Format error message with help information and stack trace - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test10 = $false
}

# Test formatting an error message for a regular exception
try {
    $regularException = [System.Exception]::new("This is a regular exception")
    $formattedMessage = Format-ErrorMessage -Exception $regularException
    
    Write-Host "`nPASSED: Format error message for a regular exception" -ForegroundColor Green
    Write-Host "  Formatted message: $formattedMessage" -ForegroundColor Green
    $test11 = $true
} catch {
    Write-Host "`nFAILED: Format error message for a regular exception - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test11 = $false
}

# Summary
$totalTests = 11
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9, $test10, $test11).Where({ $_ -eq $true }).Count

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed tests: $passedTests" -ForegroundColor Cyan
Write-Host "Failed tests: $($totalTests - $passedTests)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
}
