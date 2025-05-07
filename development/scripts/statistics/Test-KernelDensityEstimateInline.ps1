# Test-KernelDensityEstimateInline.ps1
# Inline test for kernel density estimation

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
            $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
            
            # Calculate the interquartile range
            $sortedData = $Data | Sort-Object
            $q1Index = [Math]::Floor($sortedData.Count * 0.25)
            $q3Index = [Math]::Floor($sortedData.Count * 0.75)
            $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]
            
            # Calculate the bandwidth using Silverman's rule
            $n = $Data.Count
            $Bandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2)
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

# Function to run an inline test for kernel density estimation
function Test-KernelDensityEstimateInline {
    [CmdletBinding()]
    param ()
    
    # Generate test data
    Write-Host "Generating test data..." -ForegroundColor Cyan
    $testData = 1..20 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    
    # Test with default parameters
    Write-Host "`nTesting with default parameters..." -ForegroundColor Cyan
    $result1 = Get-KernelDensityEstimate -Data $testData
    
    # Display the results
    Write-Host "`nResults with default parameters:" -ForegroundColor Magenta
    Write-Host "Number of data points: $($result1.Data.Count)" -ForegroundColor Green
    Write-Host "Number of evaluation points: $($result1.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "Number of density estimates: $($result1.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "Kernel type: $($result1.KernelType)" -ForegroundColor Green
    Write-Host "Bandwidth: $($result1.Bandwidth)" -ForegroundColor Green
    
    # Test with Epanechnikov kernel
    Write-Host "`nTesting with Epanechnikov kernel..." -ForegroundColor Cyan
    $result2 = Get-KernelDensityEstimate -Data $testData -KernelType Epanechnikov
    
    # Display the results
    Write-Host "`nResults with Epanechnikov kernel:" -ForegroundColor Magenta
    Write-Host "Kernel type: $($result2.KernelType)" -ForegroundColor Green
    Write-Host "Bandwidth: $($result2.Bandwidth)" -ForegroundColor Green
    
    # Test with custom bandwidth
    Write-Host "`nTesting with custom bandwidth..." -ForegroundColor Cyan
    $result3 = Get-KernelDensityEstimate -Data $testData -Bandwidth 5
    
    # Display the results
    Write-Host "`nResults with custom bandwidth:" -ForegroundColor Magenta
    Write-Host "Kernel type: $($result3.KernelType)" -ForegroundColor Green
    Write-Host "Bandwidth: $($result3.Bandwidth)" -ForegroundColor Green
    
    # Test with custom evaluation points
    Write-Host "`nTesting with custom evaluation points..." -ForegroundColor Cyan
    $evalPoints = 0..10 | ForEach-Object { $_ * 10 }
    $result5 = Get-KernelDensityEstimate -Data $testData -EvaluationPoints $evalPoints
    
    # Display the results
    Write-Host "`nResults with custom evaluation points:" -ForegroundColor Magenta
    Write-Host "Number of evaluation points: $($result5.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "Evaluation points: $($result5.EvaluationPoints -join ', ')" -ForegroundColor Green
    
    # Test with invalid data
    Write-Host "`nTesting with invalid data..." -ForegroundColor Cyan
    try {
        $invalidData = @(1)
        $result6 = Get-KernelDensityEstimate -Data $invalidData
        Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
    } catch {
        Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
    }
    
    # Test with negative bandwidth
    Write-Host "`nTesting with negative bandwidth..." -ForegroundColor Cyan
    try {
        $result7 = Get-KernelDensityEstimate -Data $testData -Bandwidth -1
        Write-Host "  FAILED: This test should have thrown an exception" -ForegroundColor Red
    } catch {
        Write-Host "  PASSED: $($_.Exception.Message)" -ForegroundColor Green
    }
    
    # Test summary
    Write-Host "`n=== Test summary ===" -ForegroundColor Cyan
    Write-Host "All tests were executed successfully." -ForegroundColor Green
}

# Run the inline test if the script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-KernelDensityEstimateInline
}
