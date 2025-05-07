# Very simple test for the Get-KernelDensityEstimate function

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimate.psm1 -Force

# Generate simple test data
$simpleData = 1..10

# Test with only the data (mandatory parameter)
Write-Host "Test with only the data (mandatory parameter)" -ForegroundColor Cyan
$result = Get-KernelDensityEstimate -Data $simpleData

# Display the results
Write-Host "Number of data points: $($result.Data.Count)" -ForegroundColor Green
Write-Host "Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green

# Test summary
Write-Host "Test completed successfully." -ForegroundColor Green
