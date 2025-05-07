# Example-KernelDensityEstimateWithPerformanceLogging.ps1
# Example of using performance logging with kernel density estimation

# Import the required modules
. ..\KernelDensityEstimateSimpleLogging.ps1
. ..\KernelDensityEstimatePerformanceLogging.ps1

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "KDEPerformanceLoggingTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Initialize logging
Initialize-Logging -Level $script:LogLevelDebug -LogFilePath $tempLogFile -LogToFile $true -LogToConsole $true

# Function to perform kernel density estimation with performance logging
function Get-KernelDensityEstimateWithPerformanceLogging {
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
    
    # Start performance measurement
    $performanceMeasurement = Start-PerformanceMeasurement -OperationName "KernelDensityEstimation" -MeasureMemory
    
    try {
        # Log function entry
        Write-InfoLog "Entering Get-KernelDensityEstimateWithPerformanceLogging function"
        Write-DebugLog "Parameters: Data.Count=$($Data.Count), EvaluationPoints.Count=$($EvaluationPoints.Count), KernelType=$KernelType, Bandwidth=$Bandwidth"
        
        # Validate input data
        Write-DebugLog "Validating input data..."
        if ($null -eq $Data -or $Data.Count -eq 0) {
            $errorMessage = "The input data is null or empty."
            Write-ErrorLog $errorMessage
            throw $errorMessage
        }
        
        if ($Data.Count -lt 2) {
            $errorMessage = "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
            Write-ErrorLog $errorMessage
            throw $errorMessage
        }
        
        # Add a checkpoint for data validation
        Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "DataValidation"
        
        # Convert data to double array
        Write-DebugLog "Converting data to double array..."
        $Data = $Data | ForEach-Object { [double]$_ }
        
        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            Write-DebugLog "Validating evaluation points..."
            if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                $errorMessage = "The evaluation points are null or empty."
                Write-ErrorLog $errorMessage
                throw $errorMessage
            }
            
            # Convert evaluation points to double array
            Write-DebugLog "Converting evaluation points to double array..."
            $EvaluationPoints = $EvaluationPoints | ForEach-Object { [double]$_ }
        } else {
            # Generate evaluation points automatically
            Write-DebugLog "Generating evaluation points automatically..."
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
            
            Write-DebugLog "Generated $numPoints evaluation points from $min to $max"
        }
        
        # Add a checkpoint for evaluation points
        Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "EvaluationPoints"
        
        # Validate bandwidth
        Write-DebugLog "Validating bandwidth..."
        if ($Bandwidth -lt 0) {
            $errorMessage = "The bandwidth is negative: $Bandwidth."
            Write-ErrorLog $errorMessage
            throw $errorMessage
        }
        
        # Calculate bandwidth if not provided
        if ($Bandwidth -eq 0) {
            Write-DebugLog "Calculating bandwidth automatically..."
            
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
            
            Write-DebugLog "Calculated bandwidth: $Bandwidth (stdDev=$stdDev, iqr=$iqr, n=$n)"
        }
        
        # Add a checkpoint for bandwidth calculation
        Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "BandwidthCalculation"
        
        # Initialize the density estimates
        Write-DebugLog "Initializing density estimates array with $($EvaluationPoints.Count) elements..."
        $densityEstimates = New-Object double[] $EvaluationPoints.Count
        
        # Calculate the density estimates
        Write-DebugLog "Calculating density estimates using $KernelType kernel with bandwidth $Bandwidth..."
        $calculationStart = Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "CalculationStart"
        
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
            
            # Log progress for every 10% of completion
            if ($i % [Math]::Max(1, [Math]::Floor($EvaluationPoints.Count / 10)) -eq 0) {
                $percentComplete = [Math]::Floor(($i / $EvaluationPoints.Count) * 100)
                Write-VerboseLog "Density estimation progress: $percentComplete% complete"
            }
        }
        
        # Add a checkpoint for calculation completion
        Add-PerformanceCheckpoint -PerformanceMeasurement $performanceMeasurement -CheckpointName "CalculationComplete"
        
        # Create the output object
        Write-DebugLog "Creating output object..."
        $result = [PSCustomObject]@{
            Data = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            KernelType = $KernelType
            Bandwidth = $Bandwidth
            Performance = $null
        }
        
        # Log function exit
        Write-InfoLog "Exiting Get-KernelDensityEstimateWithPerformanceLogging function"
        
        # Stop performance measurement
        $performanceMeasurement = Stop-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement
        
        # Add the performance measurement to the result
        $result.Performance = $performanceMeasurement
        
        return $result
    } catch {
        # Log the error
        Write-ErrorLog "Error in Get-KernelDensityEstimateWithPerformanceLogging: $($_.Exception.Message)"
        
        # Stop performance measurement
        Stop-PerformanceMeasurement -PerformanceMeasurement $performanceMeasurement | Out-Null
        
        # Re-throw the exception
        throw
    }
}

# Example 1: Basic usage
Write-Host "Example 1: Basic usage" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    # Create some sample data
    $data = 1..10 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    
    # Perform kernel density estimation with performance logging
    $result = Get-KernelDensityEstimateWithPerformanceLogging -Data $data
    
    Write-Host "Kernel density estimation successful!" -ForegroundColor Green
    Write-Host "  Data: $($result.Data -join ', ')" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Bandwidth)" -ForegroundColor Green
    Write-Host "  Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green
    
    # Display the performance measurement
    Write-Host "`nPerformance measurement:" -ForegroundColor Yellow
    $performanceString = Format-PerformanceMeasurement -PerformanceMeasurement $result.Performance -IncludeCheckpoints
    Write-Host $performanceString -ForegroundColor Gray
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Example 2: Measure the performance of multiple kernel types
Write-Host "`nExample 2: Measure the performance of multiple kernel types" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    # Create some sample data
    $data = 1..100 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    
    # Create an array to store the performance measurements
    $performanceMeasurements = @()
    
    # Perform kernel density estimation with different kernel types
    foreach ($kernelType in @("Gaussian", "Epanechnikov", "Triangular", "Uniform")) {
        Write-Host "Testing kernel type: $kernelType" -ForegroundColor Yellow
        
        # Perform kernel density estimation with performance logging
        $result = Get-KernelDensityEstimateWithPerformanceLogging -Data $data -KernelType $kernelType
        
        # Add the performance measurement to the array
        $performanceMeasurements += $result.Performance
        
        Write-Host "  Elapsed time: $($result.Performance.ElapsedTime.TotalSeconds) seconds" -ForegroundColor Green
        Write-Host "  Memory used: $($result.Performance.MemoryUsed / 1MB) MB" -ForegroundColor Green
    }
    
    # Create a performance report
    $reportFilePath = Join-Path -Path $env:TEMP -ChildPath "KDEPerformanceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report = New-PerformanceReport -PerformanceMeasurements $performanceMeasurements -ReportName "Kernel Density Estimation Performance Report" -ReportFilePath $reportFilePath
    
    Write-Host "`nPerformance report written to: $reportFilePath" -ForegroundColor Yellow
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Clean up
Write-Host "`nCleaning up..." -ForegroundColor Green
Remove-Item -Path $tempLogFile -Force
