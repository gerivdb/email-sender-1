# Example-KernelDensityEstimateMultivariate.ps1
# Examples of using Get-KernelDensityEstimateMultivariate with multivariate data

# Import the module
Import-Module ..\KernelDensityEstimateMultivariate.psm1 -Force

# Example 1: Bivariate data (2D)
Write-Host "Example 1: Bivariate data (2D)" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Generate some random bivariate data
$bivariate_data = 1..100 | ForEach-Object {
    [PSCustomObject]@{
        X = Get-Random -Minimum 0 -Maximum 100
        Y = Get-Random -Minimum 0 -Maximum 100
    }
}

# Estimate the density
$density1 = Get-KernelDensityEstimateMultivariate -Data $bivariate_data -Dimensions @("X", "Y") -Verbose

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density1.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Dimensions: $($density1.Dimensions -join ', ')" -ForegroundColor Green

Write-Host "`nDimension statistics:" -ForegroundColor Green
Write-Host "  X dimension:" -ForegroundColor Green
Write-Host "    Min: $($density1.Statistics.DimensionStats.X.Min)" -ForegroundColor Green
Write-Host "    Max: $($density1.Statistics.DimensionStats.X.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density1.Statistics.DimensionStats.X.Mean)" -ForegroundColor Green
Write-Host "    Median: $($density1.Statistics.DimensionStats.X.Median)" -ForegroundColor Green
Write-Host "    StdDev: $($density1.Statistics.DimensionStats.X.StdDev)" -ForegroundColor Green

Write-Host "  Y dimension:" -ForegroundColor Green
Write-Host "    Min: $($density1.Statistics.DimensionStats.Y.Min)" -ForegroundColor Green
Write-Host "    Max: $($density1.Statistics.DimensionStats.Y.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density1.Statistics.DimensionStats.Y.Mean)" -ForegroundColor Green
Write-Host "    Median: $($density1.Statistics.DimensionStats.Y.Median)" -ForegroundColor Green
Write-Host "    StdDev: $($density1.Statistics.DimensionStats.Y.StdDev)" -ForegroundColor Green

Write-Host "`nParameters:" -ForegroundColor Green
Write-Host "  Kernel type: $($density1.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Bandwidth X: $($density1.Parameters.Bandwidth.X)" -ForegroundColor Green
Write-Host "  Bandwidth Y: $($density1.Parameters.Bandwidth.Y)" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Green
Write-Host "  Number of evaluation points: $($density1.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "  First evaluation point: X=$($density1.EvaluationPoints[0].X), Y=$($density1.EvaluationPoints[0].Y)" -ForegroundColor Green
Write-Host "  Density at first point: $($density1.DensityEstimates[0])" -ForegroundColor Green

# Example 2: Bivariate normal distribution
Write-Host "`n`nExample 2: Bivariate normal distribution" -ForegroundColor Cyan
Write-Host "------------------------------------" -ForegroundColor Cyan

# Generate data from a bivariate normal distribution
$mean_x = 50
$mean_y = 50
$stddev_x = 10
$stddev_y = 15
$correlation = 0.7

$bivariate_normal_data = 1..200 | ForEach-Object {
    # Generate two independent standard normal random variables
    $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    $u3 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u4 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z2 = [Math]::Sqrt(-2 * [Math]::Log($u3)) * [Math]::Cos(2 * [Math]::PI * $u4)
    
    # Apply correlation
    $z2_correlated = $correlation * $z1 + [Math]::Sqrt(1 - $correlation * $correlation) * $z2
    
    # Transform to the desired mean and standard deviation
    $x = $mean_x + $stddev_x * $z1
    $y = $mean_y + $stddev_y * $z2_correlated
    
    [PSCustomObject]@{
        X = $x
        Y = $y
    }
}

# Estimate the density
$density2 = Get-KernelDensityEstimateMultivariate -Data $bivariate_normal_data -Dimensions @("X", "Y") -Verbose

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density2.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Dimensions: $($density2.Dimensions -join ', ')" -ForegroundColor Green

Write-Host "`nDimension statistics:" -ForegroundColor Green
Write-Host "  X dimension:" -ForegroundColor Green
Write-Host "    Min: $($density2.Statistics.DimensionStats.X.Min)" -ForegroundColor Green
Write-Host "    Max: $($density2.Statistics.DimensionStats.X.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density2.Statistics.DimensionStats.X.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density2.Statistics.DimensionStats.X.StdDev)" -ForegroundColor Green

Write-Host "  Y dimension:" -ForegroundColor Green
Write-Host "    Min: $($density2.Statistics.DimensionStats.Y.Min)" -ForegroundColor Green
Write-Host "    Max: $($density2.Statistics.DimensionStats.Y.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density2.Statistics.DimensionStats.Y.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density2.Statistics.DimensionStats.Y.StdDev)" -ForegroundColor Green

Write-Host "`nParameters:" -ForegroundColor Green
Write-Host "  Kernel type: $($density2.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Bandwidth X: $($density2.Parameters.Bandwidth.X)" -ForegroundColor Green
Write-Host "  Bandwidth Y: $($density2.Parameters.Bandwidth.Y)" -ForegroundColor Green

# Example 3: Trivariate data (3D)
Write-Host "`n`nExample 3: Trivariate data (3D)" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Generate some random trivariate data
$trivariate_data = 1..100 | ForEach-Object {
    [PSCustomObject]@{
        X = Get-Random -Minimum 0 -Maximum 100
        Y = Get-Random -Minimum 0 -Maximum 100
        Z = Get-Random -Minimum 0 -Maximum 100
    }
}

# Estimate the density
$density3 = Get-KernelDensityEstimateMultivariate -Data $trivariate_data -Dimensions @("X", "Y", "Z") -Verbose

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density3.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Dimensions: $($density3.Dimensions -join ', ')" -ForegroundColor Green

Write-Host "`nDimension statistics:" -ForegroundColor Green
Write-Host "  X dimension:" -ForegroundColor Green
Write-Host "    Min: $($density3.Statistics.DimensionStats.X.Min)" -ForegroundColor Green
Write-Host "    Max: $($density3.Statistics.DimensionStats.X.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density3.Statistics.DimensionStats.X.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density3.Statistics.DimensionStats.X.StdDev)" -ForegroundColor Green

Write-Host "  Y dimension:" -ForegroundColor Green
Write-Host "    Min: $($density3.Statistics.DimensionStats.Y.Min)" -ForegroundColor Green
Write-Host "    Max: $($density3.Statistics.DimensionStats.Y.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density3.Statistics.DimensionStats.Y.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density3.Statistics.DimensionStats.Y.StdDev)" -ForegroundColor Green

Write-Host "  Z dimension:" -ForegroundColor Green
Write-Host "    Min: $($density3.Statistics.DimensionStats.Z.Min)" -ForegroundColor Green
Write-Host "    Max: $($density3.Statistics.DimensionStats.Z.Max)" -ForegroundColor Green
Write-Host "    Mean: $($density3.Statistics.DimensionStats.Z.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density3.Statistics.DimensionStats.Z.StdDev)" -ForegroundColor Green

Write-Host "`nParameters:" -ForegroundColor Green
Write-Host "  Kernel type: $($density3.Parameters.KernelType)" -ForegroundColor Green
Write-Host "  Bandwidth X: $($density3.Parameters.Bandwidth.X)" -ForegroundColor Green
Write-Host "  Bandwidth Y: $($density3.Parameters.Bandwidth.Y)" -ForegroundColor Green
Write-Host "  Bandwidth Z: $($density3.Parameters.Bandwidth.Z)" -ForegroundColor Green

Write-Host "`nResults:" -ForegroundColor Green
Write-Host "  Number of evaluation points: $($density3.EvaluationPoints.Count)" -ForegroundColor Green
Write-Host "  First evaluation point: X=$($density3.EvaluationPoints[0].X), Y=$($density3.EvaluationPoints[0].Y), Z=$($density3.EvaluationPoints[0].Z)" -ForegroundColor Green
Write-Host "  Density at first point: $($density3.DensityEstimates[0])" -ForegroundColor Green

# Example 4: Finding the mode (peak) of a bivariate distribution
Write-Host "`n`nExample 4: Finding the mode (peak) of a bivariate distribution" -ForegroundColor Cyan
Write-Host "------------------------------------------------------" -ForegroundColor Cyan

# Generate data from a bivariate normal distribution with a single mode
$mean_x = 40
$mean_y = 60
$stddev_x = 8
$stddev_y = 12
$correlation = 0.5

$bimodal_data = 1..200 | ForEach-Object {
    # Generate two independent standard normal random variables
    $u1 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u2 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z1 = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    
    $u3 = Get-Random -Minimum 0.0 -Maximum 1.0
    $u4 = Get-Random -Minimum 0.0 -Maximum 1.0
    $z2 = [Math]::Sqrt(-2 * [Math]::Log($u3)) * [Math]::Cos(2 * [Math]::PI * $u4)
    
    # Apply correlation
    $z2_correlated = $correlation * $z1 + [Math]::Sqrt(1 - $correlation * $correlation) * $z2
    
    # Transform to the desired mean and standard deviation
    $x = $mean_x + $stddev_x * $z1
    $y = $mean_y + $stddev_y * $z2_correlated
    
    [PSCustomObject]@{
        X = $x
        Y = $y
    }
}

# Estimate the density
$density4 = Get-KernelDensityEstimateMultivariate -Data $bimodal_data -Dimensions @("X", "Y") -Verbose

# Find the mode (the point with the highest density)
$maxDensityIndex = 0
$maxDensity = $density4.DensityEstimates[0]

for ($i = 1; $i -lt $density4.DensityEstimates.Count; $i++) {
    if ($density4.DensityEstimates[$i] -gt $maxDensity) {
        $maxDensity = $density4.DensityEstimates[$i]
        $maxDensityIndex = $i
    }
}

$mode = $density4.EvaluationPoints[$maxDensityIndex]

# Display the results
Write-Host "Data summary:" -ForegroundColor Green
Write-Host "  Count: $($density4.Statistics.DataCount)" -ForegroundColor Green
Write-Host "  Dimensions: $($density4.Dimensions -join ', ')" -ForegroundColor Green

Write-Host "`nDimension statistics:" -ForegroundColor Green
Write-Host "  X dimension:" -ForegroundColor Green
Write-Host "    Mean: $($density4.Statistics.DimensionStats.X.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density4.Statistics.DimensionStats.X.StdDev)" -ForegroundColor Green

Write-Host "  Y dimension:" -ForegroundColor Green
Write-Host "    Mean: $($density4.Statistics.DimensionStats.Y.Mean)" -ForegroundColor Green
Write-Host "    StdDev: $($density4.Statistics.DimensionStats.Y.StdDev)" -ForegroundColor Green

Write-Host "`nMode (peak of the distribution):" -ForegroundColor Green
Write-Host "  X: $($mode.X)" -ForegroundColor Green
Write-Host "  Y: $($mode.Y)" -ForegroundColor Green
Write-Host "  Density at the mode: $maxDensity" -ForegroundColor Green
Write-Host "  True means (for comparison): X=$mean_x, Y=$mean_y" -ForegroundColor Green
