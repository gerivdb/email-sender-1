# Test-KernelDensityEstimateValidation.ps1
# Script to test the validation functions for kernel density estimation

# Import the validation functions
. .\KernelDensityEstimateValidation.ps1

# Function to test error handling
function Test-ValidationFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestBlock,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedErrorCode
    )

    try {
        # Execute the test block
        & $TestBlock

        # If we get here, the test failed
        Write-Host "FAILED: $TestName - No exception was thrown" -ForegroundColor Red
        return $false
    } catch {
        $errorRecord = $_

        # Get the error code from the exception
        $actualErrorCode = $null
        if ($errorRecord.Exception.PSObject.Properties.Name -contains "ErrorCode") {
            $actualErrorCode = $errorRecord.Exception.ErrorCode
        }

        if ($actualErrorCode -eq $ExpectedErrorCode) {
            Write-Host "PASSED: $TestName" -ForegroundColor Green
            Write-Host "  Error code: $actualErrorCode" -ForegroundColor Green
            Write-Host "  Message: $($errorRecord.Exception.Message)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED: $TestName - Wrong error code" -ForegroundColor Red
            Write-Host "  Expected: $ExpectedErrorCode" -ForegroundColor Red
            Write-Host "  Actual: $actualErrorCode" -ForegroundColor Red
            Write-Host "  Message: $($errorRecord.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Test data validation
Write-Host "Testing data validation..." -ForegroundColor Cyan

# Test null data
$test1 = Test-ValidationFunction -TestName "Null data" -TestBlock {
    Test-KDEData -Data $null
} -ExpectedErrorCode $ErrorCodes.DataNullOrEmpty

# Test empty data
$test2 = Test-ValidationFunction -TestName "Empty data" -TestBlock {
    Test-KDEData -Data @()
} -ExpectedErrorCode $ErrorCodes.DataNullOrEmpty

# Test data with too few points
$test3 = Test-ValidationFunction -TestName "Data with too few points" -TestBlock {
    Test-KDEData -Data @(1)
} -ExpectedErrorCode $ErrorCodes.DataTooSmall

# Test data with NaN
$test4 = Test-ValidationFunction -TestName "Data with NaN" -TestBlock {
    Test-KDEData -Data @(1, 2, [double]::NaN, 4)
} -ExpectedErrorCode $ErrorCodes.DataContainsNaN

# Test data with infinity
$test5 = Test-ValidationFunction -TestName "Data with infinity" -TestBlock {
    Test-KDEData -Data @(1, 2, [double]::PositiveInfinity, 4)
} -ExpectedErrorCode $ErrorCodes.DataContainsInfinity

# Test data with non-numeric values
$test6 = Test-ValidationFunction -TestName "Data with non-numeric values" -TestBlock {
    Test-KDEData -Data @(1, 2, "three", 4)
} -ExpectedErrorCode $ErrorCodes.DataNotNumeric

# Test valid data
try {
    $result = Test-KDEData -Data @(1, 2, 3, 4)
    # Check if all elements are doubles
    $allDoubles = $true
    foreach ($item in $result) {
        if ($item -isnot [double]) {
            $allDoubles = $false
            break
        }
    }

    if ($allDoubles -and $result.Count -eq 4) {
        Write-Host "PASSED: Valid data" -ForegroundColor Green
        Write-Host "  Result count: $($result.Count)" -ForegroundColor Green
        Write-Host "  First element type: $($result[0].GetType().FullName)" -ForegroundColor Green
        $test7 = $true
    } else {
        Write-Host "FAILED: Valid data - Wrong result type or count" -ForegroundColor Red
        Write-Host "  Result type: $($result.GetType().FullName)" -ForegroundColor Red
        Write-Host "  Result count: $($result.Count)" -ForegroundColor Red
        Write-Host "  All elements are doubles: $allDoubles" -ForegroundColor Red
        if ($result.Count -gt 0) {
            Write-Host "  First element type: $($result[0].GetType().FullName)" -ForegroundColor Red
        }
        $test7 = $false
    }
} catch {
    Write-Host "FAILED: Valid data - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test7 = $false
}

# Test evaluation points validation
Write-Host "`nTesting evaluation points validation..." -ForegroundColor Cyan

# Test null evaluation points
$test8 = Test-ValidationFunction -TestName "Null evaluation points" -TestBlock {
    Test-KDEEvaluationPoints -EvaluationPoints $null
} -ExpectedErrorCode $ErrorCodes.EvalPointsEmpty

# Test empty evaluation points
$test9 = Test-ValidationFunction -TestName "Empty evaluation points" -TestBlock {
    Test-KDEEvaluationPoints -EvaluationPoints @()
} -ExpectedErrorCode $ErrorCodes.EvalPointsEmpty

# Test evaluation points with NaN
$test10 = Test-ValidationFunction -TestName "Evaluation points with NaN" -TestBlock {
    Test-KDEEvaluationPoints -EvaluationPoints @(1, 2, [double]::NaN, 4)
} -ExpectedErrorCode $ErrorCodes.EvalPointsContainsNaN

# Test evaluation points with infinity
$test11 = Test-ValidationFunction -TestName "Evaluation points with infinity" -TestBlock {
    Test-KDEEvaluationPoints -EvaluationPoints @(1, 2, [double]::PositiveInfinity, 4)
} -ExpectedErrorCode $ErrorCodes.EvalPointsContainsInfinity

# Test evaluation points with non-numeric values
$test12 = Test-ValidationFunction -TestName "Evaluation points with non-numeric values" -TestBlock {
    Test-KDEEvaluationPoints -EvaluationPoints @(1, 2, "three", 4)
} -ExpectedErrorCode $ErrorCodes.EvalPointsNotNumeric

# Test valid evaluation points
try {
    $result = Test-KDEEvaluationPoints -EvaluationPoints @(1, 2, 3, 4)
    # Check if all elements are doubles
    $allDoubles = $true
    foreach ($item in $result) {
        if ($item -isnot [double]) {
            $allDoubles = $false
            break
        }
    }

    if ($allDoubles -and $result.Count -eq 4) {
        Write-Host "PASSED: Valid evaluation points" -ForegroundColor Green
        Write-Host "  Result count: $($result.Count)" -ForegroundColor Green
        Write-Host "  First element type: $($result[0].GetType().FullName)" -ForegroundColor Green
        $test13 = $true
    } else {
        Write-Host "FAILED: Valid evaluation points - Wrong result type or count" -ForegroundColor Red
        Write-Host "  Result type: $($result.GetType().FullName)" -ForegroundColor Red
        Write-Host "  Result count: $($result.Count)" -ForegroundColor Red
        Write-Host "  All elements are doubles: $allDoubles" -ForegroundColor Red
        if ($result.Count -gt 0) {
            Write-Host "  First element type: $($result[0].GetType().FullName)" -ForegroundColor Red
        }
        $test13 = $false
    }
} catch {
    Write-Host "FAILED: Valid evaluation points - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test13 = $false
}

# Test bandwidth validation
Write-Host "`nTesting bandwidth validation..." -ForegroundColor Cyan

# Test negative bandwidth
$test14 = Test-ValidationFunction -TestName "Negative bandwidth" -TestBlock {
    Test-KDEBandwidth -Bandwidth -1
} -ExpectedErrorCode $ErrorCodes.BandwidthNegative

# Test zero bandwidth (when not allowed)
$test15 = Test-ValidationFunction -TestName "Zero bandwidth (when not allowed)" -TestBlock {
    Test-KDEBandwidth -Bandwidth 0
} -ExpectedErrorCode $ErrorCodes.BandwidthZero

# Test bandwidth with NaN
$test16 = Test-ValidationFunction -TestName "Bandwidth with NaN" -TestBlock {
    Test-KDEBandwidth -Bandwidth ([double]::NaN)
} -ExpectedErrorCode $ErrorCodes.BandwidthContainsNaN

# Test bandwidth with infinity
$test17 = Test-ValidationFunction -TestName "Bandwidth with infinity" -TestBlock {
    Test-KDEBandwidth -Bandwidth ([double]::PositiveInfinity)
} -ExpectedErrorCode $ErrorCodes.BandwidthContainsInfinity

# Test valid bandwidth
try {
    $result = Test-KDEBandwidth -Bandwidth 1.5
    if ($result -eq 1.5) {
        Write-Host "PASSED: Valid bandwidth" -ForegroundColor Green
        $test18 = $true
    } else {
        Write-Host "FAILED: Valid bandwidth - Wrong result" -ForegroundColor Red
        Write-Host "  Expected: 1.5" -ForegroundColor Red
        Write-Host "  Actual: $result" -ForegroundColor Red
        $test18 = $false
    }
} catch {
    Write-Host "FAILED: Valid bandwidth - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test18 = $false
}

# Test zero bandwidth (when allowed)
try {
    $result = Test-KDEBandwidth -Bandwidth 0 -AllowZero
    if ($result -eq 0) {
        Write-Host "PASSED: Zero bandwidth (when allowed)" -ForegroundColor Green
        $test19 = $true
    } else {
        Write-Host "FAILED: Zero bandwidth (when allowed) - Wrong result" -ForegroundColor Red
        Write-Host "  Expected: 0" -ForegroundColor Red
        Write-Host "  Actual: $result" -ForegroundColor Red
        $test19 = $false
    }
} catch {
    Write-Host "FAILED: Zero bandwidth (when allowed) - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test19 = $false
}

# Test kernel type validation
Write-Host "`nTesting kernel type validation..." -ForegroundColor Cyan

# Test invalid kernel type
$test20 = Test-ValidationFunction -TestName "Invalid kernel type" -TestBlock {
    Test-KDEKernelType -KernelType "InvalidKernel"
} -ExpectedErrorCode $ErrorCodes.InvalidKernelType

# Test valid kernel type
try {
    $result = Test-KDEKernelType -KernelType "Gaussian"
    if ($result -eq "Gaussian") {
        Write-Host "PASSED: Valid kernel type" -ForegroundColor Green
        $test21 = $true
    } else {
        Write-Host "FAILED: Valid kernel type - Wrong result" -ForegroundColor Red
        Write-Host "  Expected: Gaussian" -ForegroundColor Red
        Write-Host "  Actual: $result" -ForegroundColor Red
        $test21 = $false
    }
} catch {
    Write-Host "FAILED: Valid kernel type - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test21 = $false
}

# Summary
$totalTests = 21
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9, $test10, $test11, $test12, $test13, $test14, $test15, $test16, $test17, $test18, $test19, $test20, $test21).Where({ $_ -eq $true }).Count

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed tests: $passedTests" -ForegroundColor Cyan
Write-Host "Failed tests: $($totalTests - $passedTests)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
}
