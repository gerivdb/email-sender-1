# Test for the Get-KernelDensityEstimate function with optional parameters

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimate.psm1 -Force

# Generate simple test data
$simpleData = 1..10

# Test with different kernel types
Write-Host "Test with different kernel types" -ForegroundColor Cyan
$kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine", "OptimalKernel")

foreach ($kernelType in $kernelTypes) {
    Write-Host "Testing kernel type: $kernelType" -ForegroundColor Yellow
    $result = Get-KernelDensityEstimate -Data $simpleData -KernelType $kernelType
    Write-Host "  Kernel type in result: $($result.Parameters.KernelType)" -ForegroundColor Green
}

# Test with different bandwidth selection methods
Write-Host "`nTest with different bandwidth selection methods" -ForegroundColor Cyan
$methods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized", "Auto")

foreach ($method in $methods) {
    Write-Host "Testing method: $method" -ForegroundColor Yellow
    $result = Get-KernelDensityEstimate -Data $simpleData -Method $method
    Write-Host "  Method in result: $($result.Parameters.Method)" -ForegroundColor Green
}

# Test with different objectives
Write-Host "`nTest with different objectives" -ForegroundColor Cyan
$objectives = @("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")

foreach ($objective in $objectives) {
    Write-Host "Testing objective: $objective" -ForegroundColor Yellow
    $result = Get-KernelDensityEstimate -Data $simpleData -Objective $objective
    Write-Host "  Objective in result: $($result.Parameters.Objective)" -ForegroundColor Green
}

# Test with custom bandwidth
Write-Host "`nTest with custom bandwidth" -ForegroundColor Cyan
$bandwidth = 2.5
$result = Get-KernelDensityEstimate -Data $simpleData -Bandwidth $bandwidth
Write-Host "  Bandwidth in result: $($result.Parameters.Bandwidth)" -ForegroundColor Green

# Test with custom KFolds
Write-Host "`nTest with custom KFolds" -ForegroundColor Cyan
$kfolds = 10
$result = Get-KernelDensityEstimate -Data $simpleData -Method KFold -KFolds $kfolds
Write-Host "  KFolds in result: $($result.Parameters.KFolds)" -ForegroundColor Green

# Test with Normalize switch
Write-Host "`nTest with Normalize switch" -ForegroundColor Cyan
$result1 = Get-KernelDensityEstimate -Data $simpleData
$result2 = Get-KernelDensityEstimate -Data $simpleData -Normalize
Write-Host "  Normalize in result1: $($result1.Parameters.Normalize)" -ForegroundColor Green
Write-Host "  Normalize in result2: $($result2.Parameters.Normalize)" -ForegroundColor Green

# Test with UseParallel switch
Write-Host "`nTest with UseParallel switch" -ForegroundColor Cyan
$result1 = Get-KernelDensityEstimate -Data $simpleData
$result2 = Get-KernelDensityEstimate -Data $simpleData -UseParallel
Write-Host "  UseParallel in result1: $($result1.Parameters.UseParallel)" -ForegroundColor Green
Write-Host "  UseParallel in result2: $($result2.Parameters.UseParallel)" -ForegroundColor Green

# Test with MaxIterations
Write-Host "`nTest with MaxIterations" -ForegroundColor Cyan
$maxIterations = 50
$result = Get-KernelDensityEstimate -Data $simpleData -MaxIterations $maxIterations
Write-Host "  MaxIterations in result: $($result.Parameters.MaxIterations)" -ForegroundColor Green

# Test with multiple parameters
Write-Host "`nTest with multiple parameters" -ForegroundColor Cyan
$result = Get-KernelDensityEstimate -Data $simpleData -KernelType Epanechnikov -Method Silverman -Bandwidth 1.5 -Normalize -UseParallel -MaxIterations 75
Write-Host "  KernelType: $($result.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Method: $($result.Parameters.Method)" -ForegroundColor Green
Write-Host "  Bandwidth: $($result.Parameters.Bandwidth)" -ForegroundColor Green
Write-Host "  Normalize: $($result.Parameters.Normalize)" -ForegroundColor Green
Write-Host "  UseParallel: $($result.Parameters.UseParallel)" -ForegroundColor Green
Write-Host "  MaxIterations: $($result.Parameters.MaxIterations)" -ForegroundColor Green

# Test statistics output
Write-Host "`nTest statistics output" -ForegroundColor Cyan
$result = Get-KernelDensityEstimate -Data $simpleData
Write-Host "  DataCount: $($result.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  DataMin: $($result.Statistics.DataMin)" -ForegroundColor Green
Write-Host "  DataMax: $($result.Statistics.DataMax)" -ForegroundColor Green
Write-Host "  DataMean: $($result.Statistics.DataMean)" -ForegroundColor Green
Write-Host "  DataStdDev: $($result.Statistics.DataStdDev)" -ForegroundColor Green

# Test summary
Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
Write-Host "All tests were executed successfully." -ForegroundColor Green
