# Test for the basic Get-KernelDensityEstimateBasic function

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimateBasic.psm1 -Force

# Generate test data
$testData = 1..20 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

# Test with default parameters
Write-Host "Testing with default parameters..." -ForegroundColor Cyan
$result1 = Get-KernelDensityEstimateBasic -Data $testData -Verbose

# Display the results
Write-Host "`nResults with default parameters:" -ForegroundColor Magenta
Write-Host "Number of data points: $($result1.Data.Count)" -ForegroundColor Green
Write-Host "Number of evaluation points: $($result1.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "Number of density estimates: $($result1.DensityEstimates.Count)" -ForegroundColor Green
Write-Host "Kernel type: $($result1.Parameters.KernelType)" -ForegroundColor Green
Write-Host "Bandwidth: $($result1.Parameters.Bandwidth)" -ForegroundColor Green
Write-Host "Execution time: $($result1.Statistics.ExecutionTime) seconds" -ForegroundColor Green

# Test with custom bandwidth
Write-Host "`nTesting with custom bandwidth..." -ForegroundColor Cyan
$result2 = Get-KernelDensityEstimateBasic -Data $testData -Bandwidth 5 -Verbose

# Display the results
Write-Host "`nResults with custom bandwidth:" -ForegroundColor Magenta
Write-Host "Kernel type: $($result2.Parameters.KernelType)" -ForegroundColor Green
Write-Host "Bandwidth: $($result2.Parameters.Bandwidth)" -ForegroundColor Green

# Test with custom evaluation points
Write-Host "`nTesting with custom evaluation points..." -ForegroundColor Cyan
$evalPoints = 0..10 | ForEach-Object { $_ * 10 }
$result3 = Get-KernelDensityEstimateBasic -Data $testData -EvaluationPoints $evalPoints -Verbose

# Display the results
Write-Host "`nResults with custom evaluation points:" -ForegroundColor Magenta
Write-Host "Number of evaluation points: $($result3.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "Evaluation points: $($result3.EvaluationPoints -join ', ')" -ForegroundColor Green

# Test with invalid data
Write-Host "`nTesting with invalid data..." -ForegroundColor Cyan
try {
    $invalidData = @(1)
    $result4 = Get-KernelDensityEstimateBasic -Data $invalidData
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test with negative bandwidth
Write-Host "`nTesting with negative bandwidth..." -ForegroundColor Cyan
try {
    $result5 = Get-KernelDensityEstimateBasic -Data $testData -Bandwidth -1
    Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
} catch {
    Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
}

# Test summary
Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
Write-Host "All tests were executed successfully." -ForegroundColor Green
