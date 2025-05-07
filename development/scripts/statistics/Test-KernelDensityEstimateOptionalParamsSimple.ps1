# Simple test for the Get-KernelDensityEstimate function with optional parameters

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimate.psm1 -Force

# Generate simple test data
$simpleData = 1..10

# Test with custom parameters
Write-Host "Test with custom parameters" -ForegroundColor Cyan
$result = Get-KernelDensityEstimate -Data $simpleData -KernelType Epanechnikov -Method Silverman -Bandwidth 1.5 -Normalize -MaxIterations 75

# Display the results
Write-Host "`nResults:" -ForegroundColor Magenta
Write-Host "KernelType: $($result.Parameters.KernelType)" -ForegroundColor Green
Write-Host "Method: $($result.Parameters.Method)" -ForegroundColor Green
Write-Host "Bandwidth: $($result.Parameters.Bandwidth)" -ForegroundColor Green
Write-Host "Normalize: $($result.Parameters.Normalize)" -ForegroundColor Green
Write-Host "MaxIterations: $($result.Parameters.MaxIterations)" -ForegroundColor Green

# Display statistics
Write-Host "`nStatistics:" -ForegroundColor Magenta
Write-Host "DataCount: $($result.Statistics.DataCount)" -ForegroundColor Green
Write-Host "DataMin: $($result.Statistics.DataMin)" -ForegroundColor Green
Write-Host "DataMax: $($result.Statistics.DataMax)" -ForegroundColor Green
Write-Host "DataMean: $($result.Statistics.DataMean)" -ForegroundColor Green
Write-Host "DataStdDev: $($result.Statistics.DataStdDev)" -ForegroundColor Green

# Test summary
Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
Write-Host "Test completed successfully." -ForegroundColor Green
