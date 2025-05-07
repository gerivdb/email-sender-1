# Test for the Get-KernelDensityEstimate function output structure

# Import the module
Import-Module .\development\scripts\statistics\KernelDensityEstimate.psm1 -Force

# Generate test data
$testData = 1..20 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

# Run the function
$result = Get-KernelDensityEstimate -Data $testData

# Test the basic structure
Write-Host "Testing basic structure..." -ForegroundColor Cyan
$expectedProperties = @("Data", "EvaluationPoints", "DensityEstimates", "Parameters", "Statistics", "Metadata")
$missingProperties = $expectedProperties | Where-Object { -not $result.PSObject.Properties.Name.Contains($_) }

if ($missingProperties.Count -eq 0) {
    Write-Host "  PASSED: All expected top-level properties are present" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Missing properties: $($missingProperties -join ', ')" -ForegroundColor Red
}

# Test Parameters structure
Write-Host "`nTesting Parameters structure..." -ForegroundColor Cyan
$expectedParameterProperties = @("KernelType", "Bandwidth", "Method", "Objective", "KFolds", "Normalize", "UseParallel", "MaxIterations")
$missingParameterProperties = $expectedParameterProperties | Where-Object { -not $result.Parameters.PSObject.Properties.Name.Contains($_) }

if ($missingParameterProperties.Count -eq 0) {
    Write-Host "  PASSED: All expected parameter properties are present" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Missing parameter properties: $($missingParameterProperties -join ', ')" -ForegroundColor Red
}

# Test Statistics structure
Write-Host "`nTesting Statistics structure..." -ForegroundColor Cyan
$expectedStatisticsProperties = @("DataCount", "DataMin", "DataMax", "DataRange", "DataMean", "DataMedian", "DataStdDev", "ExecutionTime", "MemoryUsed", "Timestamp")
$missingStatisticsProperties = $expectedStatisticsProperties | Where-Object { -not $result.Statistics.PSObject.Properties.Name.Contains($_) }

if ($missingStatisticsProperties.Count -eq 0) {
    Write-Host "  PASSED: All expected statistics properties are present" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Missing statistics properties: $($missingStatisticsProperties -join ', ')" -ForegroundColor Red
}

# Test Metadata structure
Write-Host "`nTesting Metadata structure..." -ForegroundColor Cyan
$expectedMetadataProperties = @("Title", "Description", "CreatedBy", "CreatedOn", "Version")
$missingMetadataProperties = $expectedMetadataProperties | Where-Object { -not $result.Metadata.PSObject.Properties.Name.Contains($_) }

if ($missingMetadataProperties.Count -eq 0) {
    Write-Host "  PASSED: All expected metadata properties are present" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Missing metadata properties: $($missingMetadataProperties -join ', ')" -ForegroundColor Red
}

# Test summary
Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
Write-Host "All output structure tests were executed." -ForegroundColor Green
