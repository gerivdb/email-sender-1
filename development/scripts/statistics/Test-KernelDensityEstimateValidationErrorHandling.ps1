# Test-KernelDensityEstimateValidationErrorHandling.ps1
# Script to test the validation error handling in the kernel density estimation module

# Import the module
Import-Module .\KernelDensityEstimateWithErrorHandling.psm1 -Force

# Function to test error handling
function Test-ErrorHandling {
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
        $exception = $_.Exception
        
        # Check if the exception has the expected error code
        if ($exception.ErrorCode -eq $ExpectedErrorCode) {
            Write-Host "PASSED: $TestName" -ForegroundColor Green
            Write-Host "  Error code: $($exception.ErrorCode)" -ForegroundColor Green
            Write-Host "  Message: $($exception.Message)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED: $TestName - Wrong error code" -ForegroundColor Red
            Write-Host "  Expected: $ExpectedErrorCode" -ForegroundColor Red
            Write-Host "  Actual: $($exception.ErrorCode)" -ForegroundColor Red
            Write-Host "  Message: $($exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Test data validation errors
Write-Host "Testing data validation errors..." -ForegroundColor Cyan

# Test null data
$test1 = Test-ErrorHandling -TestName "Null data" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data $null
} -ExpectedErrorCode "V001"

# Test empty data
$test2 = Test-ErrorHandling -TestName "Empty data" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @()
} -ExpectedErrorCode "V001"

# Test data with too few points
$test3 = Test-ErrorHandling -TestName "Data with too few points" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1)
} -ExpectedErrorCode "V002"

# Test data with NaN
$test4 = Test-ErrorHandling -TestName "Data with NaN" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, [double]::NaN, 4)
} -ExpectedErrorCode "V003"

# Test data with infinity
$test5 = Test-ErrorHandling -TestName "Data with infinity" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, [double]::PositiveInfinity, 4)
} -ExpectedErrorCode "V004"

# Test data with non-numeric values
$test6 = Test-ErrorHandling -TestName "Data with non-numeric values" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, "three", 4)
} -ExpectedErrorCode "V005"

# Test evaluation points validation errors
Write-Host "`nTesting evaluation points validation errors..." -ForegroundColor Cyan

# Test empty evaluation points
$test7 = Test-ErrorHandling -TestName "Empty evaluation points" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -EvaluationPoints @()
} -ExpectedErrorCode "V101"

# Test evaluation points with NaN
$test8 = Test-ErrorHandling -TestName "Evaluation points with NaN" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -EvaluationPoints @(1, 2, [double]::NaN, 4)
} -ExpectedErrorCode "V102"

# Test evaluation points with infinity
$test9 = Test-ErrorHandling -TestName "Evaluation points with infinity" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -EvaluationPoints @(1, 2, [double]::PositiveInfinity, 4)
} -ExpectedErrorCode "V103"

# Test evaluation points with non-numeric values
$test10 = Test-ErrorHandling -TestName "Evaluation points with non-numeric values" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -EvaluationPoints @(1, 2, "three", 4)
} -ExpectedErrorCode "V104"

# Test bandwidth validation errors
Write-Host "`nTesting bandwidth validation errors..." -ForegroundColor Cyan

# Test negative bandwidth
$test11 = Test-ErrorHandling -TestName "Negative bandwidth" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -Bandwidth -1
} -ExpectedErrorCode "V201"

# Test zero bandwidth (when explicitly specified)
$test12 = Test-ErrorHandling -TestName "Zero bandwidth (explicitly specified)" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -Bandwidth 0
} -ExpectedErrorCode "V202"

# Test bandwidth with NaN
$test13 = Test-ErrorHandling -TestName "Bandwidth with NaN" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -Bandwidth ([double]::NaN)
} -ExpectedErrorCode "V203"

# Test bandwidth with infinity
$test14 = Test-ErrorHandling -TestName "Bandwidth with infinity" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -Bandwidth ([double]::PositiveInfinity)
} -ExpectedErrorCode "V204"

# Test kernel type validation errors
Write-Host "`nTesting kernel type validation errors..." -ForegroundColor Cyan

# Test invalid kernel type
$test15 = Test-ErrorHandling -TestName "Invalid kernel type" -TestBlock {
    Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -KernelType "InvalidKernel"
} -ExpectedErrorCode "V301"

# Test successful case
Write-Host "`nTesting successful case..." -ForegroundColor Cyan
try {
    $result = Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4)
    Write-Host "PASSED: Successful case" -ForegroundColor Green
    Write-Host "  Data count: $($result.Data.Count)" -ForegroundColor Green
    Write-Host "  Evaluation points count: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Density estimates count: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.Parameters.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Parameters.Bandwidth)" -ForegroundColor Green
    $test16 = $true
} catch {
    Write-Host "FAILED: Successful case - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test16 = $false
}

# Test successful case with custom parameters
Write-Host "`nTesting successful case with custom parameters..." -ForegroundColor Cyan
try {
    $result = Get-KernelDensityEstimateWithErrorHandling -Data @(1, 2, 3, 4) -KernelType "Epanechnikov" -Bandwidth 1.5 -Normalize
    Write-Host "PASSED: Successful case with custom parameters" -ForegroundColor Green
    Write-Host "  Data count: $($result.Data.Count)" -ForegroundColor Green
    Write-Host "  Evaluation points count: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Density estimates count: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.Parameters.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Parameters.Bandwidth)" -ForegroundColor Green
    Write-Host "  Normalize: $($result.Parameters.Normalize)" -ForegroundColor Green
    $test17 = $true
} catch {
    Write-Host "FAILED: Successful case with custom parameters - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test17 = $false
}

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
