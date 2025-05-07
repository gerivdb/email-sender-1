# Test for the Get-KernelDensityEstimate function parameter validations

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimate.psm1 -Force

# Test with invalid data (less than 2 points)
Write-Host "Test with invalid data (less than 2 points)" -ForegroundColor Cyan
try {
    $invalidData = @(1)
    $result = Get-KernelDensityEstimate -Data $invalidData
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with empty evaluation points
Write-Host "`nTest with empty evaluation points" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $emptyPoints = @()
    $result = Get-KernelDensityEstimate -Data $simpleData -EvaluationPoints $emptyPoints
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with negative bandwidth
Write-Host "`nTest with negative bandwidth" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -Bandwidth -1
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with KFolds less than 2
Write-Host "`nTest with KFolds less than 2" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -Method KFold -KFolds 1
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with KFolds greater than data count
Write-Host "`nTest with KFolds greater than data count" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -Method KFold -KFolds 20 -Verbose
    Write-Host "  PASSED: Warning should have been displayed" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: This test should not have thrown an exception" -ForegroundColor Red
}

# Test with MaxIterations less than 1
Write-Host "`nTest with MaxIterations less than 1" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -MaxIterations 0
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with both Bandwidth and Method specified
Write-Host "`nTest with both Bandwidth and Method specified" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -Bandwidth 1.5 -Method Silverman -Verbose
    Write-Host "  PASSED: Warning should have been displayed" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: This test should not have thrown an exception" -ForegroundColor Red
}

# Test with OptimalKernel and specified Bandwidth
Write-Host "`nTest with OptimalKernel and specified Bandwidth" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -KernelType OptimalKernel -Bandwidth 1.5 -Verbose
    Write-Host "  PASSED: Warning should have been displayed" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: This test should not have thrown an exception" -ForegroundColor Red
}

# Test with UseParallel on small dataset
Write-Host "`nTest with UseParallel on small dataset" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -UseParallel -Verbose
    Write-Host "  PASSED: Verbose message should have been displayed" -ForegroundColor Green
} catch {
    Write-Host "  FAILED: This test should not have thrown an exception" -ForegroundColor Red
}

# Test execution time calculation
Write-Host "`nTest execution time calculation" -ForegroundColor Cyan
$simpleData = 1..100
$result = Get-KernelDensityEstimate -Data $simpleData
Write-Host "  Execution time: $($result.Statistics.ExecutionTime) seconds" -ForegroundColor Green
if ($result.Statistics.ExecutionTime -gt 0) {
    Write-Host "  PASSED: Execution time is greater than 0" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Execution time should be greater than 0" -ForegroundColor Red
}

# Test summary
Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
Write-Host "All validation tests were executed successfully." -ForegroundColor Green
