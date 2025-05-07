# Test-KernelDensityEstimateCalculationErrorHandling.ps1
# Script to test the calculation error handling functions for kernel density estimation

# Add debug information
Write-Host "Starting test script..." -ForegroundColor Yellow
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow

# Import the calculation error handling functions
Write-Host "Importing calculation error handling functions..." -ForegroundColor Yellow
. .\KernelDensityEstimateCalculationErrorHandling.ps1
Write-Host "Import completed." -ForegroundColor Yellow

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

# Test bandwidth calculation
Write-Host "Testing bandwidth calculation..." -ForegroundColor Cyan

# Test bandwidth calculation with identical data points
try {
    $bandwidth = Get-SilvermanBandwidth -Data @(5, 5, 5, 5, 5)

    # Check if the bandwidth is the minimum bandwidth
    if ($bandwidth -eq 1e-10) {
        Write-Host "PASSED: Bandwidth calculation with identical data points" -ForegroundColor Green
        Write-Host "  Bandwidth: $bandwidth" -ForegroundColor Green
        $test1 = $true
    } else {
        Write-Host "FAILED: Bandwidth calculation with identical data points - Wrong bandwidth" -ForegroundColor Red
        Write-Host "  Expected: 1e-10" -ForegroundColor Red
        Write-Host "  Actual: $bandwidth" -ForegroundColor Red
        $test1 = $false
    }
} catch {
    Write-Host "FAILED: Bandwidth calculation with identical data points - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test1 = $false
}

# Test bandwidth calculation with very small variance
try {
    $bandwidth = Get-SilvermanBandwidth -Data @(1, 1.0000001, 1.0000002, 1.0000003)
    Write-Host "PASSED: Bandwidth calculation with very small variance" -ForegroundColor Green
    Write-Host "  Bandwidth: $bandwidth" -ForegroundColor Green
    $test2 = $true
} catch {
    Write-Host "FAILED: Bandwidth calculation with very small variance - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test2 = $false
}

# Test bandwidth calculation with normal data
try {
    $bandwidth = Get-SilvermanBandwidth -Data @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    Write-Host "PASSED: Bandwidth calculation with normal data" -ForegroundColor Green
    Write-Host "  Bandwidth: $bandwidth" -ForegroundColor Green
    $test3 = $true
} catch {
    Write-Host "FAILED: Bandwidth calculation with normal data - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test3 = $false
}

# Test kernel calculation
Write-Host "`nTesting kernel calculation..." -ForegroundColor Cyan

# Test Gaussian kernel with normal input
try {
    $kernelValue = Get-KernelValue -X 0 -KernelType "Gaussian"
    if ([Math]::Abs($kernelValue - 0.3989) -lt 0.0001) {
        Write-Host "PASSED: Gaussian kernel with normal input" -ForegroundColor Green
        Write-Host "  Kernel value: $kernelValue" -ForegroundColor Green
        $test4 = $true
    } else {
        Write-Host "FAILED: Gaussian kernel with normal input - Wrong value" -ForegroundColor Red
        Write-Host "  Expected: 0.3989" -ForegroundColor Red
        Write-Host "  Actual: $kernelValue" -ForegroundColor Red
        $test4 = $false
    }
} catch {
    Write-Host "FAILED: Gaussian kernel with normal input - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test4 = $false
}

# Test Gaussian kernel with large input (potential overflow)
try {
    $kernelValue = Get-KernelValue -X 100 -KernelType "Gaussian"
    Write-Host "PASSED: Gaussian kernel with large input" -ForegroundColor Green
    Write-Host "  Kernel value: $kernelValue" -ForegroundColor Green
    $test5 = $true
} catch {
    Write-Host "FAILED: Gaussian kernel with large input - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test5 = $false
}

# Test invalid kernel type
$test6 = Test-ErrorHandling -TestName "Invalid kernel type" -TestBlock {
    Get-KernelValue -X 0 -KernelType "InvalidKernel"
} -ExpectedErrorCode $ErrorCodes.InvalidKernelType

# Test density estimation
Write-Host "`nTesting density estimation..." -ForegroundColor Cyan

# Test density estimation with normal data
try {
    $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    $evaluationPoints = @(0, 2.5, 5, 7.5, 10)
    $densityEstimates = Get-DensityEstimate -Data $data -EvaluationPoints $evaluationPoints -KernelType "Gaussian" -Bandwidth 2

    Write-Host "PASSED: Density estimation with normal data" -ForegroundColor Green
    Write-Host "  Density estimates: $($densityEstimates -join ', ')" -ForegroundColor Green
    $test7 = $true
} catch {
    Write-Host "FAILED: Density estimation with normal data - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test7 = $false
}

# Test density estimation with zero bandwidth
$test8 = Test-ErrorHandling -TestName "Density estimation with zero bandwidth" -TestBlock {
    $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    $evaluationPoints = @(0, 2.5, 5, 7.5, 10)
    Get-DensityEstimate -Data $data -EvaluationPoints $evaluationPoints -KernelType "Gaussian" -Bandwidth 0
} -ExpectedErrorCode $ErrorCodes.DensityContainsNaN

# Test density normalization with all zeros
$test9 = Test-ErrorHandling -TestName "Density normalization with all zeros" -TestBlock {
    # Create a scenario where all density estimates are zero
    # This can happen if all evaluation points are far from all data points
    $data = @(1, 2, 3)
    $evaluationPoints = @(1000, 2000, 3000)
    Get-DensityEstimate -Data $data -EvaluationPoints $evaluationPoints -KernelType "Uniform" -Bandwidth 1 -Normalize
} -ExpectedErrorCode $ErrorCodes.DensityNormalizationFailed

# Test evaluation points generation
Write-Host "`nTesting evaluation points generation..." -ForegroundColor Cyan

# Test evaluation points generation with normal data
try {
    $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    $evaluationPoints = Get-EvaluationPoints -Data $data -NumPoints 5

    Write-Host "PASSED: Evaluation points generation with normal data" -ForegroundColor Green
    Write-Host "  Evaluation points: $($evaluationPoints -join ', ')" -ForegroundColor Green
    $test10 = $true
} catch {
    Write-Host "FAILED: Evaluation points generation with normal data - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test10 = $false
}

# Test evaluation points generation with identical data points
try {
    $data = @(5, 5, 5, 5, 5)
    $evaluationPoints = Get-EvaluationPoints -Data $data -NumPoints 5

    Write-Host "PASSED: Evaluation points generation with identical data points" -ForegroundColor Green
    Write-Host "  Evaluation points: $($evaluationPoints -join ', ')" -ForegroundColor Green
    $test11 = $true
} catch {
    Write-Host "FAILED: Evaluation points generation with identical data points - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test11 = $false
}

# Test complete kernel density estimation
Write-Host "`nTesting complete kernel density estimation..." -ForegroundColor Cyan

# Test complete kernel density estimation with normal data
try {
    $data = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

    # Calculate bandwidth
    $bandwidth = Get-SilvermanBandwidth -Data $data

    # Generate evaluation points
    $evaluationPoints = Get-EvaluationPoints -Data $data -NumPoints 10

    # Calculate density estimates
    $densityEstimates = Get-DensityEstimate -Data $data -EvaluationPoints $evaluationPoints -KernelType "Gaussian" -Bandwidth $bandwidth

    Write-Host "PASSED: Complete kernel density estimation with normal data" -ForegroundColor Green
    Write-Host "  Bandwidth: $bandwidth" -ForegroundColor Green
    Write-Host "  Evaluation points: $($evaluationPoints -join ', ')" -ForegroundColor Green
    Write-Host "  Density estimates: $($densityEstimates -join ', ')" -ForegroundColor Green
    $test12 = $true
} catch {
    Write-Host "FAILED: Complete kernel density estimation with normal data - Exception was thrown" -ForegroundColor Red
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Red
    $test12 = $false
}

# Summary
$totalTests = 12
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9, $test10, $test11, $test12).Where({ $_ -eq $true }).Count

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
Write-Host "Passed tests: $passedTests" -ForegroundColor Cyan
Write-Host "Failed tests: $($totalTests - $passedTests)" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
}
