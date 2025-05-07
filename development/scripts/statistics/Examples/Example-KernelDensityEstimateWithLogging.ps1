# Example-KernelDensityEstimateWithLogging.ps1
# Example of using logging with kernel density estimation

# Import the required modules
Import-Module ..\KernelDensityEstimateLogging.psm1 -Force

# Function to demonstrate logging in kernel density estimation
function Get-KernelDensityEstimateWithLogging {
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
        [double]$Bandwidth = 0,
        
        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "The log level to use for logging.")]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$LogLevel = $KDELogLevelInfo,
        
        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = "The log file path to use for logging.")]
        [string]$LogFilePath = $null,
        
        [Parameter(Mandatory = $false,
            Position = 6,
            HelpMessage = "Whether to log to a file.")]
        [switch]$LogToFile = $false
    )
    
    try {
        # Initialize logging
        Write-Verbose "Initializing logging..."
        Initialize-KDELogging -Level $LogLevel -LogFilePath $LogFilePath -LogToFile:$LogToFile
        
        # Log function entry
        Write-KDEInfo "Entering Get-KernelDensityEstimateWithLogging function"
        Write-KDEDebug "Parameters: Data.Count=$($Data.Count), EvaluationPoints.Count=$($EvaluationPoints.Count), KernelType=$KernelType, Bandwidth=$Bandwidth"
        
        # Validate input data
        Write-KDEDebug "Validating input data..."
        if ($null -eq $Data -or $Data.Count -eq 0) {
            $errorMessage = "The input data is null or empty."
            Write-KDEError $errorMessage
            throw $errorMessage
        }
        
        if ($Data.Count -lt 2) {
            $errorMessage = "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
            Write-KDEError $errorMessage
            throw $errorMessage
        }
        
        # Check if data contains NaN or infinity values
        Write-KDEDebug "Checking if data contains NaN or infinity values..."
        foreach ($value in $Data) {
            if ($value -isnot [ValueType] -and $value -isnot [string]) {
                $errorMessage = "The input data contains non-numeric values."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            if ($value -is [string]) {
                # Try to convert string to double
                try {
                    $doubleValue = [double]$value
                } catch {
                    $errorMessage = "The input data contains non-numeric values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                if ([double]::IsNaN($doubleValue)) {
                    $errorMessage = "The input data contains NaN values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                if ([double]::IsInfinity($doubleValue)) {
                    $errorMessage = "The input data contains infinity values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
            } else {
                # Check if value is NaN or infinity
                if ([double]::IsNaN($value)) {
                    $errorMessage = "The input data contains NaN values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                if ([double]::IsInfinity($value)) {
                    $errorMessage = "The input data contains infinity values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
            }
        }
        
        # Convert data to double array
        Write-KDEDebug "Converting data to double array..."
        $Data = $Data | ForEach-Object { [double]$_ }
        
        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            Write-KDEDebug "Validating evaluation points..."
            if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                $errorMessage = "The evaluation points are null or empty."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            # Check if evaluation points contain NaN or infinity values
            Write-KDEDebug "Checking if evaluation points contain NaN or infinity values..."
            foreach ($value in $EvaluationPoints) {
                if ($value -isnot [ValueType] -and $value -isnot [string]) {
                    $errorMessage = "The evaluation points contain non-numeric values."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                if ($value -is [string]) {
                    # Try to convert string to double
                    try {
                        $doubleValue = [double]$value
                    } catch {
                        $errorMessage = "The evaluation points contain non-numeric values."
                        Write-KDEError $errorMessage
                        throw $errorMessage
                    }
                    
                    if ([double]::IsNaN($doubleValue)) {
                        $errorMessage = "The evaluation points contain NaN values."
                        Write-KDEError $errorMessage
                        throw $errorMessage
                    }
                    
                    if ([double]::IsInfinity($doubleValue)) {
                        $errorMessage = "The evaluation points contain infinity values."
                        Write-KDEError $errorMessage
                        throw $errorMessage
                    }
                } else {
                    # Check if value is NaN or infinity
                    if ([double]::IsNaN($value)) {
                        $errorMessage = "The evaluation points contain NaN values."
                        Write-KDEError $errorMessage
                        throw $errorMessage
                    }
                    
                    if ([double]::IsInfinity($value)) {
                        $errorMessage = "The evaluation points contain infinity values."
                        Write-KDEError $errorMessage
                        throw $errorMessage
                    }
                }
            }
            
            # Convert evaluation points to double array
            Write-KDEDebug "Converting evaluation points to double array..."
            $EvaluationPoints = $EvaluationPoints | ForEach-Object { [double]$_ }
        } else {
            # Generate evaluation points automatically
            Write-KDEDebug "Generating evaluation points automatically..."
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
            
            Write-KDEDebug "Generated $numPoints evaluation points from $min to $max"
        }
        
        # Validate bandwidth
        Write-KDEDebug "Validating bandwidth..."
        if ($Bandwidth -lt 0) {
            $errorMessage = "The bandwidth is negative: $Bandwidth."
            Write-KDEError $errorMessage
            throw $errorMessage
        }
        
        # Calculate bandwidth if not provided
        if ($Bandwidth -eq 0) {
            Write-KDEDebug "Calculating bandwidth automatically..."
            
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
            
            Write-KDEDebug "Calculated bandwidth: $Bandwidth (stdDev=$stdDev, iqr=$iqr, n=$n)"
            
            # Check if bandwidth calculation failed
            if ($Bandwidth -eq 0) {
                $errorMessage = "Bandwidth calculation resulted in zero. This may be due to all data points being identical."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            if ([double]::IsNaN($Bandwidth)) {
                $errorMessage = "Bandwidth calculation resulted in NaN."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            if ([double]::IsInfinity($Bandwidth)) {
                $errorMessage = "Bandwidth calculation resulted in infinity."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
        }
        
        # Initialize the density estimates
        Write-KDEDebug "Initializing density estimates array with $($EvaluationPoints.Count) elements..."
        $densityEstimates = New-Object double[] $EvaluationPoints.Count
        
        # Calculate the density estimates
        Write-KDEDebug "Calculating density estimates using $KernelType kernel with bandwidth $Bandwidth..."
        $startTime = Get-Date
        
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
                
                # Check if kernel calculation failed
                if ([double]::IsNaN($kernelValue)) {
                    $errorMessage = "Kernel calculation resulted in NaN for x = $x."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                if ([double]::IsInfinity($kernelValue)) {
                    $errorMessage = "Kernel calculation resulted in infinity for x = $x."
                    Write-KDEError $errorMessage
                    throw $errorMessage
                }
                
                $density += $kernelValue
            }
            
            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
            
            # Check if density estimation failed
            if ([double]::IsNaN($densityEstimates[$i])) {
                $errorMessage = "Density estimation resulted in NaN."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            if ([double]::IsInfinity($densityEstimates[$i])) {
                $errorMessage = "Density estimation resulted in infinity."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            if ($densityEstimates[$i] -lt 0) {
                $errorMessage = "Density estimation resulted in a negative value."
                Write-KDEError $errorMessage
                throw $errorMessage
            }
            
            # Log progress for every 10% of completion
            if ($i % [Math]::Max(1, [Math]::Floor($EvaluationPoints.Count / 10)) -eq 0) {
                $percentComplete = [Math]::Floor(($i / $EvaluationPoints.Count) * 100)
                Write-KDEVerbose "Density estimation progress: $percentComplete% complete"
            }
        }
        
        $endTime = Get-Date
        $elapsedTime = $endTime - $startTime
        Write-KDEInfo "Density estimation completed in $($elapsedTime.TotalSeconds) seconds"
        
        # Create the output object
        Write-KDEDebug "Creating output object..."
        $result = [PSCustomObject]@{
            Data = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            KernelType = $KernelType
            Bandwidth = $Bandwidth
            ElapsedTime = $elapsedTime
        }
        
        # Log function exit
        Write-KDEInfo "Exiting Get-KernelDensityEstimateWithLogging function"
        
        return $result
    } catch {
        # Log the error
        Write-KDEError "Error in Get-KernelDensityEstimateWithLogging: $($_.Exception.Message)"
        
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
    
    # Set the log level to Info
    $result = Get-KernelDensityEstimateWithLogging -Data $data -LogLevel $KDELogLevelInfo
    
    Write-Host "Kernel density estimation successful!" -ForegroundColor Green
    Write-Host "  Data: $($result.Data -join ', ')" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Bandwidth)" -ForegroundColor Green
    Write-Host "  Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Elapsed time: $($result.ElapsedTime.TotalSeconds) seconds" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Example 2: With debug logging
Write-Host "`nExample 2: With debug logging" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    # Create some sample data
    $data = 1..10 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    
    # Create a temporary log file
    $tempLogFile = [System.IO.Path]::GetTempFileName()
    
    # Set the log level to Debug and log to file
    $result = Get-KernelDensityEstimateWithLogging -Data $data -LogLevel $KDELogLevelDebug -LogFilePath $tempLogFile -LogToFile
    
    Write-Host "Kernel density estimation successful!" -ForegroundColor Green
    Write-Host "  Data: $($result.Data -join ', ')" -ForegroundColor Green
    Write-Host "  Kernel type: $($result.KernelType)" -ForegroundColor Green
    Write-Host "  Bandwidth: $($result.Bandwidth)" -ForegroundColor Green
    Write-Host "  Number of evaluation points: $($result.EvaluationPoints.Count)" -ForegroundColor Green
    Write-Host "  Number of density estimates: $($result.DensityEstimates.Count)" -ForegroundColor Green
    Write-Host "  Elapsed time: $($result.ElapsedTime.TotalSeconds) seconds" -ForegroundColor Green
    
    # Display the log file
    Write-Host "`nLog file content:" -ForegroundColor Yellow
    Get-Content -Path $tempLogFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    # Clean up
    Remove-Item -Path $tempLogFile -Force
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
