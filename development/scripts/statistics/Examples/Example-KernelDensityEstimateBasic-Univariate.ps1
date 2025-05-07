# Example-KernelDensityEstimateBasic-Univariate.ps1
# Examples of using Get-KernelDensityEstimateBasic with univariate data

# Import the module
Import-Module ..\KernelDensityEstimateBasic.psm1 -Force

# Example 1: Basic usage with random data
Write-Host "Example 1: Basic usage with random data" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Generate some random data
$randomData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

# Estimate the density using default parameters
$density1 = Get-KernelDensityEstimateBasic -Data $randomData

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density1.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Min: $($density1.Statistics.DataMin)" -ForegroundColor Green
Write-Host "  Max: $($density1.Statistics.DataMax)" -ForegroundColor Green
Write-Host "  Mean: $($density1.Statistics.DataMean)" -ForegroundColor Green
Write-Host "  Median: $($density1.Statistics.DataMedian)" -ForegroundColor Green
Write-Host "  StdDev: $($density1.Statistics.DataStdDev)" -ForegroundColor Green

Write-Host "`nParameters:" -ForegroundColor Green
Write-Host "  Kernel type: $($density1.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Bandwidth: $($density1.Parameters.Bandwidth)" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Green
Write-Host "  Number of evaluation points: $($density1.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "  First 5 evaluation points: $($density1.EvaluationPoints[0..4] -join ', ')" -ForegroundColor Green
Write-Host "  First 5 density estimates: $($density1.DensityEstimates[0..4] -join ', ')" -ForegroundColor Green

# Example 2: Normal distribution
Write-Host "`n`nExample 2: Normal distribution" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

# Generate data from a normal distribution
$mean = 50
$stdDev = 10
$normalData = 1..1000 | ForEach-Object { 
    $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $mean + $stdDev * $z
}

# Estimate the density
$density2 = Get-KernelDensityEstimateBasic -Data $normalData

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density2.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Min: $($density2.Statistics.DataMin)" -ForegroundColor Green
Write-Host "  Max: $($density2.Statistics.DataMax)" -ForegroundColor Green
Write-Host "  Mean: $($density2.Statistics.DataMean)" -ForegroundColor Green
Write-Host "  Median: $($density2.Statistics.DataMedian)" -ForegroundColor Green
Write-Host "  StdDev: $($density2.Statistics.DataStdDev)" -ForegroundColor Green

Write-Host "`nParameters:" -ForegroundColor Green
Write-Host "  Kernel type: $($density2.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Bandwidth: $($density2.Parameters.Bandwidth)" -ForegroundColor Green

# Example 3: Bimodal distribution
Write-Host "`n`nExample 3: Bimodal distribution" -ForegroundColor Cyan
Write-Host "------------------------------" -ForegroundColor Cyan

# Generate data from a bimodal distribution (mixture of two normal distributions)
$mean1 = 30
$stdDev1 = 5
$mean2 = 70
$stdDev2 = 8
$bimodalData = 1..1000 | ForEach-Object { 
    if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt 0.6) {
        # First mode (60% of the data)
        $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
        $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $mean1 + $stdDev1 * $z
    } else {
        # Second mode (40% of the data)
        $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
        $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $mean2 + $stdDev2 * $z
    }
}

# Estimate the density with different bandwidths
$density3a = Get-KernelDensityEstimateBasic -Data $bimodalData  # Automatic bandwidth
$density3b = Get-KernelDensityEstimateBasic -Data $bimodalData -Bandwidth 2  # Small bandwidth
$density3c = Get-KernelDensityEstimateBasic -Data $bimodalData -Bandwidth 10  # Large bandwidth

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density3a.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Min: $($density3a.Statistics.DataMin)" -ForegroundColor Green
Write-Host "  Max: $($density3a.Statistics.DataMax)" -ForegroundColor Green
Write-Host "  Mean: $($density3a.Statistics.DataMean)" -ForegroundColor Green
Write-Host "  Median: $($density3a.Statistics.DataMedian)" -ForegroundColor Green
Write-Host "  StdDev: $($density3a.Statistics.DataStdDev)" -ForegroundColor Green

Write-Host "`nBandwidth comparison:" -ForegroundColor Green
Write-Host "  Automatic bandwidth: $($density3a.Parameters.Bandwidth)" -ForegroundColor Green
Write-Host "  Small bandwidth: $($density3b.Parameters.Bandwidth)" -ForegroundColor Green
Write-Host "  Large bandwidth: $($density3c.Parameters.Bandwidth)" -ForegroundColor Green

# Example 4: Custom evaluation points
Write-Host "`n`nExample 4: Custom evaluation points" -ForegroundColor Cyan
Write-Host "---------------------------------" -ForegroundColor Cyan

# Generate some random data
$customData = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }

# Define custom evaluation points
$evalPoints = 0..10 | ForEach-Object { $_ * 10 }  # 0, 10, 20, ..., 100

# Estimate the density at the custom evaluation points
$density4 = Get-KernelDensityEstimateBasic -Data $customData -EvaluationPoints $evalPoints

# Display the results
Write-Host "Custom evaluation points:" -ForegroundColor Green
Write-Host "  $($density4.EvaluationPoints -join ', ')" -ForegroundColor Green

Write-Host "`nDensity estimates at these points:" -ForegroundColor Green
for ($i = 0; $i -lt $density4.EvaluationPoints.Count; $i++) {
    Write-Host "  At $($density4.EvaluationPoints[$i]): $($density4.DensityEstimates[$i])" -ForegroundColor Green
}

# Example 5: Finding the mode (peak) of the distribution
Write-Host "`n`nExample 5: Finding the mode (peak) of the distribution" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan

# Generate data from a normal distribution
$mean = 60
$stdDev = 15
$modeData = 1..500 | ForEach-Object { 
    $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $mean + $stdDev * $z
}

# Estimate the density
$density5 = Get-KernelDensityEstimateBasic -Data $modeData

# Find the mode (the point with the highest density)
$maxDensityIndex = 0
$maxDensity = $density5.DensityEstimates[0]

for ($i = 1; $i -lt $density5.DensityEstimates.Count; $i++) {
    if ($density5.DensityEstimates[$i] -gt $maxDensity) {
        $maxDensity = $density5.DensityEstimates[$i]
        $maxDensityIndex = $i
    }
}

$mode = $density5.EvaluationPoints[$maxDensityIndex]

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density5.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Min: $($density5.Statistics.DataMin)" -ForegroundColor Green
Write-Host "  Max: $($density5.Statistics.DataMax)" -ForegroundColor Green
Write-Host "  Mean: $($density5.Statistics.DataMean)" -ForegroundColor Green
Write-Host "  Median: $($density5.Statistics.DataMedian)" -ForegroundColor Green
Write-Host "  StdDev: $($density5.Statistics.DataStdDev)" -ForegroundColor Green

Write-Host "`nMode (peak of the distribution): $mode" -ForegroundColor Green
Write-Host "Density at the mode: $maxDensity" -ForegroundColor Green
Write-Host "True mean (for comparison): $mean" -ForegroundColor Green
