# Test-KernelDensityEstimateIntegration.ps1
# Integration tests for kernel density estimation

# Import the required modules
. .\KernelDensityEstimateTestData.ps1
. .\KernelDensityEstimateVisualization.ps1
. .\KernelDensityEstimateSimpleLogging.ps1

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
        # Log function entry
        Write-InfoLog "Entering Get-KernelDensityEstimate function"
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
        
        # Initialize the density estimates
        Write-DebugLog "Initializing density estimates array with $($EvaluationPoints.Count) elements..."
        $densityEstimates = New-Object double[] $EvaluationPoints.Count
        
        # Calculate the density estimates
        Write-DebugLog "Calculating density estimates using $KernelType kernel with bandwidth $Bandwidth..."
        
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
        Write-DebugLog "Creating output object..."
        $result = [PSCustomObject]@{
            Data = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            KernelType = $KernelType
            Bandwidth = $Bandwidth
        }
        
        # Log function exit
        Write-InfoLog "Exiting Get-KernelDensityEstimate function"
        
        return $result
    } catch {
        # Log the error
        Write-ErrorLog "Error in Get-KernelDensityEstimate: $($_.Exception.Message)"
        
        # Re-throw the exception
        throw
    }
}

# Function to run integration tests for kernel density estimation
function Test-KernelDensityEstimateIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleSize = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$Seed = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowPlots = $false,
        
        [Parameter(Mandatory = $false)]
        [switch]$Verbose = $false
    )
    
    # Initialize logging
    if ($Verbose) {
        Initialize-Logging -Level $script:LogLevelVerbose -LogToConsole $true -LogToFile $false
    } else {
        Initialize-Logging -Level $script:LogLevelInfo -LogToConsole $true -LogToFile $false
    }
    
    # Generate test datasets
    Write-InfoLog "Generating test datasets..."
    $datasets = New-TestDatasetCollection -SampleSize $SampleSize -Seed $Seed
    
    # Initialize the results
    $results = @()
    
    # Test each dataset with each kernel type
    $kernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform")
    
    foreach ($dataset in $datasets) {
        Write-InfoLog "Testing dataset: $($dataset.DistributionType)"
        
        foreach ($kernelType in $kernelTypes) {
            Write-InfoLog "  Testing kernel type: $kernelType"
            
            # Perform kernel density estimation
            $kde = Get-KernelDensityEstimate -Data $dataset.Samples -KernelType $kernelType
            
            # Compare the kernel density estimate with the theoretical distribution
            $comparison = Compare-KernelDensityEstimate -KernelDensityEstimate $kde -TheoreticalDistribution $dataset -ShowPlot:$ShowPlots
            
            # Create the result object
            $result = [PSCustomObject]@{
                DistributionType = $dataset.DistributionType
                KernelType = $kernelType
                MeanSquaredError = $comparison.MeanSquaredError
                MeanAbsoluteError = $comparison.MeanAbsoluteError
                MaximumAbsoluteError = $comparison.MaximumAbsoluteError
            }
            
            $results += $result
            
            # Display the result
            Write-InfoLog "    Mean Squared Error: $($comparison.MeanSquaredError)"
            Write-InfoLog "    Mean Absolute Error: $($comparison.MeanAbsoluteError)"
            Write-InfoLog "    Maximum Absolute Error: $($comparison.MaximumAbsoluteError)"
        }
    }
    
    # Display the summary
    Write-Host "`nSummary of Results:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    # Group the results by distribution type
    $groupedResults = $results | Group-Object -Property DistributionType
    
    foreach ($group in $groupedResults) {
        Write-Host "`nDistribution Type: $($group.Name)" -ForegroundColor Yellow
        
        # Find the best kernel type for this distribution
        $bestKernel = $group.Group | Sort-Object -Property MeanSquaredError | Select-Object -First 1
        
        # Display the results for each kernel type
        $group.Group | Sort-Object -Property KernelType | ForEach-Object {
            $color = if ($_.KernelType -eq $bestKernel.KernelType) { "Green" } else { "Gray" }
            Write-Host "  Kernel Type: $($_.KernelType)" -ForegroundColor $color
            Write-Host "    Mean Squared Error: $($_.MeanSquaredError)" -ForegroundColor $color
            Write-Host "    Mean Absolute Error: $($_.MeanAbsoluteError)" -ForegroundColor $color
            Write-Host "    Maximum Absolute Error: $($_.MaximumAbsoluteError)" -ForegroundColor $color
        }
        
        Write-Host "  Best Kernel Type: $($bestKernel.KernelType)" -ForegroundColor Green
    }
    
    # Find the overall best kernel type
    $overallBestKernel = $results | Group-Object -Property KernelType | ForEach-Object {
        $kernelType = $_.Name
        $avgMSE = ($_.Group | Measure-Object -Property MeanSquaredError -Average).Average
        
        [PSCustomObject]@{
            KernelType = $kernelType
            AverageMSE = $avgMSE
        }
    } | Sort-Object -Property AverageMSE | Select-Object -First 1
    
    Write-Host "`nOverall Best Kernel Type: $($overallBestKernel.KernelType) (Average MSE: $($overallBestKernel.AverageMSE))" -ForegroundColor Green
    
    return $results
}

# Run the integration tests if the script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-KernelDensityEstimateIntegration -SampleSize 100 -Seed 42 -ShowPlots:$false -Verbose:$false
}
