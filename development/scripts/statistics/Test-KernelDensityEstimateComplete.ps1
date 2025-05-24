# Test-KernelDensityEstimateComplete.ps1
# Complete test suite for kernel density estimation

# Function to perform kernel density estimation
function Get-KernelDensityEstimate {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "The input data for density estimation.")]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Data,

        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = "The points where the density will be evaluated.")]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$EvaluationPoints,
        
        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = "The type of kernel to use for density estimation.")]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform")]
        [string]$KernelType = "Gaussian",
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0
    )
    
    try {
        # Validate input data
        if ($null -eq $Data -or $Data.Count -eq 0) {
            $errorMessage = "The input data is null or empty."
            throw $errorMessage
        }
        
        if ($Data.Count -lt 2) {
            $errorMessage = "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
            throw $errorMessage
        }
        
        # Convert data to double array
        $Data = $Data | ForEach-Object { [double]$_ }
        
        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                $errorMessage = "The evaluation points are null or empty."
                throw $errorMessage
            }
            
            # Convert evaluation points to double array
            $EvaluationPoints = $EvaluationPoints | ForEach-Object { [double]$_ }
        } else {
            # Generate evaluation points automatically
            $min = ($Data | Measure-Object -Minimum).Minimum
            $max = ($Data | Measure-Object -Maximum).Maximum
            $range = $max - $min
            
            # Add a margin to avoid edge effects
            $min = $min - 0.1 * $range
            $max = $max + 0.1 * $range
            
            # Generate a grid of evaluation points (100 points by default)
            $numPoints = 100
            $step = ($max - $min) / ($numPoints - 1)
            $EvaluationPoints = 0..($numPoints - 1) | ForEach-Object { $min + $_ * $step }
        }
        
        # Validate bandwidth
        if ($Bandwidth -lt 0) {
            $errorMessage = "The bandwidth is negative: $Bandwidth."
            throw $errorMessage
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
            
            # Handle the case where both stdDev and iqr are 0 (all data points are identical)
            if ($minValue -eq 0) {
                # Use a small default bandwidth based on the range of the data
                $range = ($Data | Measure-Object -Maximum).Maximum - ($Data | Measure-Object -Minimum).Minimum
                if ($range -eq 0) {
                    # If all data points are identical, use a small value relative to the data
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
    } catch {
        # Re-throw the exception
        throw
    }
}

# Function to generate a normal distribution
function New-NormalDistribution {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,
        
        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,
        
        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$Seed = 0
    )
    
    # Set the random seed if provided
    if ($Seed -ne 0) {
        $random = New-Object System.Random($Seed)
    } else {
        $random = New-Object System.Random
    }
    
    # Generate the normal distribution
    $samples = New-Object double[] $SampleSize
    
    for ($i = 0; $i -lt $SampleSize; $i++) {
        # Box-Muller transform to generate normal distribution
        $u1 = $random.NextDouble()
        $u2 = $random.NextDouble()
        
        $z0 = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
        
        # Transform to desired mean and standard deviation
        $samples[$i] = $Mean + $StdDev * $z0
    }
    
    return $samples
}

# Function to run a complete test suite for kernel density estimation
function Test-KernelDensityEstimateComplete {
    [CmdletBinding()]
    param ()
    
    # Initialize test results
    $totalTests = 0
    $passedTests = 0
    $failedTests = @()
    
    # Function to run a test
    function Start-Test {
        param (
            [string]$Name,
            [scriptblock]$Test
        )
        
        $script:totalTests++
        
        try {
            & $Test
            $script:passedTests++
            Write-Host "  PASSED: $Name" -ForegroundColor Green
            return $true
        } catch {
            $script:failedTests += "$Name - $($_.Exception.Message)"
            Write-Host "  FAILED: $Name - $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    # Generate test data
    $testData = 1..20 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 -SetSeed 42 }
    $normalData = New-NormalDistribution -SampleSize 100 -Mean 0 -StdDev 1 -Seed 42
    $identicalData = @(5, 5, 5, 5, 5)
    
    # Test parameter validation
    Write-Host "Testing parameter validation..." -ForegroundColor Cyan
    
    Start-Test -Name "Should throw an error when data is null" -Test {
        try {
            Get-KernelDensityEstimate -Data $null
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The input data is null or empty.") {
                throw "Expected error message 'The input data is null or empty.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    Start-Test -Name "Should throw an error when data is empty" -Test {
        try {
            Get-KernelDensityEstimate -Data @()
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The input data is null or empty.") {
                throw "Expected error message 'The input data is null or empty.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    Start-Test -Name "Should throw an error when data has less than 2 points" -Test {
        try {
            Get-KernelDensityEstimate -Data @(1)
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The input data has too few points. Minimum required: 2, Actual: 1.") {
                throw "Expected error message 'The input data has too few points. Minimum required: 2, Actual: 1.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    Start-Test -Name "Should throw an error when evaluation points are null" -Test {
        try {
            Get-KernelDensityEstimate -Data $testData -EvaluationPoints $null
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The evaluation points are null or empty.") {
                throw "Expected error message 'The evaluation points are null or empty.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    Start-Test -Name "Should throw an error when evaluation points are empty" -Test {
        try {
            Get-KernelDensityEstimate -Data $testData -EvaluationPoints @()
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The evaluation points are null or empty.") {
                throw "Expected error message 'The evaluation points are null or empty.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    Start-Test -Name "Should throw an error when bandwidth is negative" -Test {
        try {
            Get-KernelDensityEstimate -Data $testData -Bandwidth -1
            throw "Test should have thrown an exception"
        } catch {
            if ($_.Exception.Message -ne "The bandwidth is negative: -1.") {
                throw "Expected error message 'The bandwidth is negative: -1.' but got '$($_.Exception.Message)'"
            }
        }
    }
    
    # Test default parameters
    Write-Host "`nTesting default parameters..." -ForegroundColor Cyan
    
    Start-Test -Name "Should return a result with default parameters" -Test {
        $result = Get-KernelDensityEstimate -Data $testData
        if ($null -eq $result) {
            throw "Result should not be null"
        }
        if ($result.Data.Count -ne $testData.Count) {
            throw "Expected data count $($testData.Count) but got $($result.Data.Count)"
        }
        if ($result.EvaluationPoints.Count -ne 100) {
            throw "Expected evaluation points count 100 but got $($result.EvaluationPoints.Count)"
        }
        if ($result.DensityEstimates.Count -ne 100) {
            throw "Expected density estimates count 100 but got $($result.DensityEstimates.Count)"
        }
        if ($result.KernelType -ne "Gaussian") {
            throw "Expected kernel type 'Gaussian' but got '$($result.KernelType)'"
        }
        if ($result.Bandwidth -le 0) {
            throw "Expected bandwidth > 0 but got $($result.Bandwidth)"
        }
    }
    
    # Test kernel types
    Write-Host "`nTesting kernel types..." -ForegroundColor Cyan
    
    Start-Test -Name "Should work with Gaussian kernel" -Test {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Gaussian
        if ($result.KernelType -ne "Gaussian") {
            throw "Expected kernel type 'Gaussian' but got '$($result.KernelType)'"
        }
    }
    
    Start-Test -Name "Should work with Epanechnikov kernel" -Test {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Epanechnikov
        if ($result.KernelType -ne "Epanechnikov") {
            throw "Expected kernel type 'Epanechnikov' but got '$($result.KernelType)'"
        }
    }
    
    Start-Test -Name "Should work with Triangular kernel" -Test {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Triangular
        if ($result.KernelType -ne "Triangular") {
            throw "Expected kernel type 'Triangular' but got '$($result.KernelType)'"
        }
    }
    
    Start-Test -Name "Should work with Uniform kernel" -Test {
        $result = Get-KernelDensityEstimate -Data $testData -KernelType Uniform
        if ($result.KernelType -ne "Uniform") {
            throw "Expected kernel type 'Uniform' but got '$($result.KernelType)'"
        }
    }
    
    # Test bandwidth selection
    Write-Host "`nTesting bandwidth selection..." -ForegroundColor Cyan
    
    Start-Test -Name "Should calculate bandwidth automatically when not provided" -Test {
        $result = Get-KernelDensityEstimate -Data $testData
        if ($result.Bandwidth -le 0) {
            throw "Expected bandwidth > 0 but got $($result.Bandwidth)"
        }
    }
    
    Start-Test -Name "Should use the provided bandwidth" -Test {
        $bandwidth = 5
        $result = Get-KernelDensityEstimate -Data $testData -Bandwidth $bandwidth
        if ($result.Bandwidth -ne $bandwidth) {
            throw "Expected bandwidth $bandwidth but got $($result.Bandwidth)"
        }
    }
    
    Start-Test -Name "Should handle identical data points" -Test {
        $result = Get-KernelDensityEstimate -Data $identicalData
        if ($result.Bandwidth -le 0) {
            throw "Expected bandwidth > 0 but got $($result.Bandwidth)"
        }
    }
    
    # Test evaluation points
    Write-Host "`nTesting evaluation points..." -ForegroundColor Cyan
    
    Start-Test -Name "Should generate evaluation points automatically when not provided" -Test {
        $result = Get-KernelDensityEstimate -Data $testData
        if ($result.EvaluationPoints.Count -ne 100) {
            throw "Expected evaluation points count 100 but got $($result.EvaluationPoints.Count)"
        }
    }
    
    Start-Test -Name "Should use the provided evaluation points" -Test {
        $evalPoints = 0..10 | ForEach-Object { $_ * 10 }
        $result = Get-KernelDensityEstimate -Data $testData -EvaluationPoints $evalPoints
        if ($result.EvaluationPoints.Count -ne $evalPoints.Count) {
            throw "Expected evaluation points count $($evalPoints.Count) but got $($result.EvaluationPoints.Count)"
        }
        for ($i = 0; $i -lt $evalPoints.Count; $i++) {
            if ($result.EvaluationPoints[$i] -ne $evalPoints[$i]) {
                throw "Expected evaluation point at index $i to be $($evalPoints[$i]) but got $($result.EvaluationPoints[$i])"
            }
        }
    }
    
    # Test density estimation
    Write-Host "`nTesting density estimation..." -ForegroundColor Cyan
    
    Start-Test -Name "Should produce non-negative density estimates" -Test {
        $result = Get-KernelDensityEstimate -Data $testData
        foreach ($density in $result.DensityEstimates) {
            if ($density -lt 0) {
                throw "Expected non-negative density but got $density"
            }
        }
    }
    
    Start-Test -Name "Should produce density estimates that integrate to approximately 1" -Test {
        $result = Get-KernelDensityEstimate -Data $normalData
        
        # Calculate the approximate integral of the density estimates
        $integral = 0
        for ($i = 1; $i -lt $result.EvaluationPoints.Count; $i++) {
            $width = $result.EvaluationPoints[$i] - $result.EvaluationPoints[$i - 1]
            $height = ($result.DensityEstimates[$i] + $result.DensityEstimates[$i - 1]) / 2
            $integral += $width * $height
        }
        
        # The integral should be approximately 1 (with some tolerance)
        if ($integral -lt 0.9 -or $integral -gt 1.1) {
            throw "Expected integral to be approximately 1 but got $integral"
        }
    }
    
    # Display test results
    Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
    Write-Host "Total tests: $totalTests" -ForegroundColor Cyan
    Write-Host "Passed tests: $passedTests" -ForegroundColor Green
    Write-Host "Failed tests: $($failedTests.Count)" -ForegroundColor $(if ($failedTests.Count -eq 0) { "Green" } else { "Red" })
    
    if ($failedTests.Count -gt 0) {
        Write-Host "`nFailed tests:" -ForegroundColor Red
        $failedTests | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    
    # Return test results
    return [PSCustomObject]@{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Success = $failedTests.Count -eq 0
    }
}

# Run the complete test suite if the script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-KernelDensityEstimateComplete
}

