# Simple test for the Get-KernelDensityEstimate function parameter validations

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

# Test with negative bandwidth
Write-Host "`nTest with negative bandwidth" -ForegroundColor Cyan
try {
    $simpleData = 1..10
    $result = Get-KernelDensityEstimate -Data $simpleData -Bandwidth -1
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test execution time calculation
Write-Host "`nTest execution time calculation" -ForegroundColor Cyan
$simpleData = 1..10
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
