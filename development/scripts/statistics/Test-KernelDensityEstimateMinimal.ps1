# Test-KernelDensityEstimateMinimal.ps1
# Minimal test for kernel density estimation

# Function to perform kernel density estimation
function Get-KernelDensityEstimate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [double[]]$EvaluationPoints,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform")]
        [string]$KernelType = "Gaussian",
        
        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )
    
    # Validate input data
    if ($null -eq $Data -or $Data.Count -eq 0) {
        throw "The input data is null or empty."
    }
    
    if ($Data.Count -lt 2) {
        throw "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
    }
    
    # Generate evaluation points if not provided
    if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        $range = $max - $min
        
        # Add a margin to avoid edge effects
        $min = $min - 0.1 * $range
        $max = $max + 0.1 * $range
        
        # Generate a grid of evaluation points
        $numPoints = 100
        $step = ($max - $min) / ($numPoints - 1)
        $EvaluationPoints = 0..($numPoints - 1) | ForEach-Object { $min + $_ * $step }
    }
    
    # Validate bandwidth
    if ($Bandwidth -lt 0) {
        throw "The bandwidth is negative: $Bandwidth."
    }
    
    # Calculate bandwidth if not provided
    if ($Bandwidth -eq 0) {
        # Calculate the standard deviation of the data
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
        
        # Calculate the interquartile range
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]
        
        # Calculate the bandwidth using Silverman's rule
        $n = $Data.Count
        $minValue = [Math]::Min($stdDev, $iqr / 1.34)
        
        # Handle the case where both stdDev and iqr are 0
        if ($minValue -eq 0) {
            $range = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
            if ($range -eq 0) {
                $Bandwidth = [Math]::Max(0.1, [Math]::Abs($Data[0]) * 0.1)
            } else {
                $Bandwidth = $range * 0.1
            }
        } else {
            $Bandwidth = 0.9 * $minValue * [Math]::Pow($n, -0.2)
        }
    }
    
    # Initialize the density estimates
    $densityEstimates = New-Object double[] $EvaluationPoints.Count
    
    # Calculate the density estimates
    for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
        $point = $EvaluationPoints[$i]
        $density = 0
        
        foreach ($dataPoint in $Data) {
            $x = ($point - $dataPoint) / $Bandwidth
            
            # Apply the kernel function
            switch ($KernelType) {
                "Gaussian" {
                    $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                }
                "Epanechnikov" {
                    if ([Math]::Abs($x) -le 1) {
                        $kernelValue = 0.75 * (1 - $x * $x)
                    } else {
                        $kernelValue = 0
                    }
                }
                "Triangular" {
                    if ([Math]::Abs($x) -le 1) {
                        $kernelValue = 1 - [Math]::Abs($x)
                    } else {
                        $kernelValue = 0
                    }
                }
                "Uniform" {
                    if ([Math]::Abs($x) -le 1) {
                        $kernelValue = 0.5
                    } else {
                        $kernelValue = 0
                    }
                }
            }
            
            $density += $kernelValue
        }
        
        $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
    }
    
    # Create the output object
    $result = [PSCustomObject]@{
        Data = $Data
        EvaluationPoints = $EvaluationPoints
        DensityEstimates = $densityEstimates
        KernelType = $KernelType
        Bandwidth = $Bandwidth
    }
    
    return $result
}

# Function to run a minimal test for kernel density estimation
function Test-KernelDensityEstimateMinimal {
    [CmdletBinding()]
    param ()
    
    # Initialize test results
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    # Function to run a test
    function Test-Condition {
        param (
            [string]$Name,
            [scriptblock]$Condition
        )
        
        $script:totalTests++
        
        try {
            $result = & $Condition
            if ($result) {
                $script:passedTests++
                Write-Host "  PASSED: $Name" -ForegroundColor Green
            } else {
                $script:failedTests++
                Write-Host "  FAILED: $Name" -ForegroundColor Red
            }
        } catch {
            $script:failedTests++
            Write-Host "  FAILED: $Name - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Generate test data
    $testData = @(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0)
    
    # Test basic functionality
    Write-Host "Testing basic functionality..." -ForegroundColor Cyan
    
    Test-Condition -Name "Should return a result with default parameters" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $null -ne $result
    }
    
    Test-Condition -Name "Should return the correct data" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $result.Data.Count -eq $testData.Count
    }
    
    Test-Condition -Name "Should generate evaluation points" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $result.EvaluationPoints.Count -eq 100
    }
    
    Test-Condition -Name "Should calculate density estimates" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $result.DensityEstimates.Count -eq 100
    }
    
    Test-Condition -Name "Should use Gaussian kernel by default" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $result.KernelType -eq "Gaussian"
    }
    
    Test-Condition -Name "Should calculate bandwidth automatically" {
        $result = Get-KernelDensityEstimate -Data $testData
        return $result.Bandwidth -gt 0
    }
    
    # Test kernel types
    Write-Host "`nTesting kernel types..." -ForegroundColor Cyan
    
    Test-Condition -Name "Should work with Gaussian kernel" {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Gaussian
        return $result.KernelType -eq "Gaussian"
    }
    
    Test-Condition -Name "Should work with Epanechnikov kernel" {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Epanechnikov
        return $result.KernelType -eq "Epanechnikov"
    }
    
    Test-Condition -Name "Should work with Triangular kernel" {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Triangular
        return $result.KernelType -eq "Triangular"
    }
    
    Test-Condition -Name "Should work with Uniform kernel" {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Uniform
        return $result.KernelType -eq "Uniform"
    }
    
    # Test bandwidth selection
    Write-Host "`nTesting bandwidth selection..." -ForegroundColor Cyan
    
    Test-Condition -Name "Should use the provided bandwidth" {
        $bandwidth = 5
        $result = Get-KernelDensityEstimate -Data $testData -Bandwidth $bandwidth
        return $result.Bandwidth -eq $bandwidth
    }
    
    Test-Condition -Name "Should handle identical data points" {
        $identicalData = @(5.0, 5.0, 5.0, 5.0, 5.0)
        $result = Get-KernelDensityEstimate -Data $identicalData
        return $result.Bandwidth -gt 0
    }
    
    # Test evaluation points
    Write-Host "`nTesting evaluation points..." -ForegroundColor Cyan
    
    Test-Condition -Name "Should use the provided evaluation points" {
        $evalPoints = @(0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0)
        $result = Get-KernelDensityEstimate -Data $testData -EvaluationPoints $evalPoints
        return $result.EvaluationPoints.Count -eq $evalPoints.Count
    }
    
    # Test density estimation
    Write-Host "`nTesting density estimation..." -ForegroundColor Cyan
    
    Test-Condition -Name "Should produce non-negative density estimates" {
        $result = Get-KernelDensityEstimate -Data $testData
        $allNonNegative = $true
        foreach ($density in $result.DensityEstimates) {
            if ($density -lt 0) {
                $allNonNegative = $false
                break
            }
        }
        return $allNonNegative
    }
    
    # Display test results
    Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
    Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
    Write-Host "Passed tests: $passedTests" -ForegroundColor Green
    Write-Host "Failed tests: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
    
    # Return test results
    return [PSCustomObject]@{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Success = $failedTests -eq 0
    }
}

# Run the minimal test if the script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-KernelDensityEstimateMinimal
}
