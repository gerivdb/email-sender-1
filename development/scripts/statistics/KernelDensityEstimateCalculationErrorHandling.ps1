# KernelDensityEstimateCalculationErrorHandling.ps1
# Script implementing calculation error handling functions for kernel density estimation

# Import the validation functions and error types
. "$PSScriptRoot\KernelDensityEstimateValidation.ps1"

# Add calculation error codes to the ErrorCodes hashtable if they don't exist
if (-not $ErrorCodes.ContainsKey("BandwidthCalculationFailed")) {
    # Bandwidth calculation errors
    $ErrorCodes.BandwidthCalculationFailed = "C001"
    $ErrorCodes.BandwidthTooSmall = "C002"
    $ErrorCodes.BandwidthTooLarge = "C003"
    $ErrorCodes.BandwidthOptimizationFailed = "C004"
    
    # Kernel calculation errors
    $ErrorCodes.KernelCalculationFailed = "C101"
    $ErrorCodes.KernelNormalizationFailed = "C102"
    $ErrorCodes.KernelIntegrationFailed = "C103"
    
    # Density estimation errors
    $ErrorCodes.DensityEstimationFailed = "C201"
    $ErrorCodes.DensityNormalizationFailed = "C202"
    $ErrorCodes.DensityContainsNaN = "C203"
    $ErrorCodes.DensityContainsInfinity = "C204"
    $ErrorCodes.DensityNegative = "C205"
}

# Add calculation error messages to the ErrorMessages hashtable if they don't exist
if (-not $ErrorMessages.ContainsKey($ErrorCodes.BandwidthCalculationFailed)) {
    # Bandwidth calculation errors
    $ErrorMessages[$ErrorCodes.BandwidthCalculationFailed] = "The bandwidth calculation failed. {0}"
    $ErrorMessages[$ErrorCodes.BandwidthTooSmall] = "The calculated bandwidth ({0}) is too small. Minimum allowed: {1}."
    $ErrorMessages[$ErrorCodes.BandwidthTooLarge] = "The calculated bandwidth ({0}) is too large. Maximum allowed: {1}."
    $ErrorMessages[$ErrorCodes.BandwidthOptimizationFailed] = "The bandwidth optimization failed to converge. {0}"
    
    # Kernel calculation errors
    $ErrorMessages[$ErrorCodes.KernelCalculationFailed] = "The kernel calculation failed. {0}"
    $ErrorMessages[$ErrorCodes.KernelNormalizationFailed] = "The kernel normalization failed because all kernel values are zero."
    $ErrorMessages[$ErrorCodes.KernelIntegrationFailed] = "The kernel integration failed. {0}"
    
    # Density estimation errors
    $ErrorMessages[$ErrorCodes.DensityEstimationFailed] = "The density estimation failed. {0}"
    $ErrorMessages[$ErrorCodes.DensityNormalizationFailed] = "The density normalization failed because all density estimates are zero."
    $ErrorMessages[$ErrorCodes.DensityContainsNaN] = "The density estimates contain NaN values."
    $ErrorMessages[$ErrorCodes.DensityContainsInfinity] = "The density estimates contain infinity values."
    $ErrorMessages[$ErrorCodes.DensityNegative] = "The density estimates contain negative values."
}

# Function to safely calculate the bandwidth using Silverman's rule of thumb
function Get-SilvermanBandwidth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [double]$MinBandwidth = 1e-10,
        
        [Parameter(Mandatory = $false)]
        [double]$MaxBandwidthFactor = 1.0
    )
    
    try {
        # Check if all data points are identical
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        
        if ($min -eq $max) {
            # All data points are identical, use a small bandwidth
            $bandwidth = $MinBandwidth
            Write-Verbose "All data points are identical, using minimum bandwidth: $bandwidth"
            return $bandwidth
        }
        
        # Calculate the standard deviation of the data
        $mean = ($Data | Measure-Object -Average).Average
        $sumSquaredDiff = 0
        
        foreach ($value in $Data) {
            $diff = $value - $mean
            $sumSquaredDiff += $diff * $diff
        }
        
        $variance = $sumSquaredDiff / $Data.Count
        $stdDev = [Math]::Sqrt($variance)
        
        # Check if standard deviation is zero or very small
        if ($stdDev -lt $MinBandwidth) {
            $bandwidth = $MinBandwidth
            Write-Verbose "Standard deviation is very small, using minimum bandwidth: $bandwidth"
            return $bandwidth
        }
        
        # Calculate the interquartile range
        $sortedData = $Data | Sort-Object
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]
        
        # Check if IQR is zero or very small
        if ($iqr -lt $MinBandwidth) {
            $bandwidth = $MinBandwidth
            Write-Verbose "Interquartile range is very small, using minimum bandwidth: $bandwidth"
            return $bandwidth
        }
        
        # Calculate the bandwidth using Silverman's rule
        $n = $Data.Count
        $bandwidth = 0.9 * [Math]::Min($stdDev, $iqr / 1.34) * [Math]::Pow($n, -0.2)
        
        # Check if bandwidth is too small
        if ($bandwidth -lt $MinBandwidth) {
            $bandwidth = $MinBandwidth
            Write-Verbose "Calculated bandwidth is too small, using minimum bandwidth: $bandwidth"
        }
        
        # Check if bandwidth is too large
        $maxBandwidth = ($max - $min) * $MaxBandwidthFactor
        if ($bandwidth -gt $maxBandwidth) {
            $bandwidth = $maxBandwidth
            Write-Verbose "Calculated bandwidth is too large, using maximum bandwidth: $bandwidth"
        }
        
        Write-Verbose "Bandwidth calculated using Silverman's rule: $bandwidth"
        return $bandwidth
    } catch {
        # Handle any unexpected errors
        $errorMessage = "Failed to calculate bandwidth: $($_.Exception.Message)"
        Write-Verbose $errorMessage
        Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthCalculationFailed -Args @($errorMessage)
    }
}

# Function to safely calculate the kernel value
function Get-KernelValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,
        
        [Parameter(Mandatory = $true)]
        [string]$KernelType
    )
    
    try {
        switch ($KernelType) {
            "Gaussian" {
                # Check for potential overflow in the exponential calculation
                if ([Math]::Abs($X) -gt 37) {
                    # exp(-x^2/2) is effectively zero for |x| > 37
                    return 0
                }
                
                $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $X * $X)
            }
            "Epanechnikov" {
                if ([Math]::Abs($X) -le 1) {
                    $kernelValue = 0.75 * (1 - $X * $X)
                } else {
                    $kernelValue = 0
                }
            }
            "Triangular" {
                if ([Math]::Abs($X) -le 1) {
                    $kernelValue = 1 - [Math]::Abs($X)
                } else {
                    $kernelValue = 0
                }
            }
            "Uniform" {
                if ([Math]::Abs($X) -le 1) {
                    $kernelValue = 0.5
                } else {
                    $kernelValue = 0
                }
            }
            default {
                Throw-ValidationError -ErrorCode $ErrorCodes.InvalidKernelType -Args @($KernelType, "Gaussian, Epanechnikov, Triangular, Uniform")
            }
        }
        
        # Check for NaN or infinity
        if ([double]::IsNaN($kernelValue)) {
            Throw-ValidationError -ErrorCode $ErrorCodes.KernelCalculationFailed -Args @("Kernel calculation resulted in NaN for x = $X.")
        }
        
        if ([double]::IsInfinity($kernelValue)) {
            Throw-ValidationError -ErrorCode $ErrorCodes.KernelCalculationFailed -Args @("Kernel calculation resulted in infinity for x = $X.")
        }
        
        return $kernelValue
    } catch [System.Exception] {
        if ($_.Exception.ErrorCode) {
            # Re-throw validation errors
            throw $_.Exception
        } else {
            # Wrap other exceptions
            $errorMessage = "Failed to calculate kernel value: $($_.Exception.Message)"
            Write-Verbose $errorMessage
            Throw-ValidationError -ErrorCode $ErrorCodes.KernelCalculationFailed -Args @($errorMessage)
        }
    }
}

# Function to safely calculate the density estimate
function Get-DensityEstimate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $true)]
        [double[]]$EvaluationPoints,
        
        [Parameter(Mandatory = $true)]
        [string]$KernelType,
        
        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,
        
        [Parameter(Mandatory = $false)]
        [switch]$Normalize
    )
    
    try {
        # Initialize the density estimates
        $densityEstimates = New-Object double[] $EvaluationPoints.Count
        
        # Calculate the density estimates
        for ($i = 0; $i -lt $EvaluationPoints.Count; $i++) {
            $point = $EvaluationPoints[$i]
            $density = 0
            
            foreach ($dataPoint in $Data) {
                $x = ($point - $dataPoint) / $Bandwidth
                
                # Calculate the kernel value
                $kernelValue = Get-KernelValue -X $x -KernelType $KernelType
                
                $density += $kernelValue
            }
            
            # Normalize by bandwidth and sample size
            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)
            
            # Check for NaN or infinity
            if ([double]::IsNaN($densityEstimates[$i])) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityContainsNaN
            }
            
            if ([double]::IsInfinity($densityEstimates[$i])) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityContainsInfinity
            }
            
            # Check for negative values (should not happen with proper kernels)
            if ($densityEstimates[$i] -lt 0) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityNegative
            }
        }
        
        # Normalize the density estimates if requested
        if ($Normalize) {
            $sum = 0
            foreach ($value in $densityEstimates) {
                $sum += $value
            }
            
            # Check if sum is zero
            if ($sum -eq 0) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityNormalizationFailed
            }
            
            # Normalize
            for ($i = 0; $i -lt $densityEstimates.Count; $i++) {
                $densityEstimates[$i] = $densityEstimates[$i] / $sum
            }
        }
        
        return $densityEstimates
    } catch [System.Exception] {
        if ($_.Exception.ErrorCode) {
            # Re-throw validation errors
            throw $_.Exception
        } else {
            # Wrap other exceptions
            $errorMessage = "Failed to calculate density estimate: $($_.Exception.Message)"
            Write-Verbose $errorMessage
            Throw-ValidationError -ErrorCode $ErrorCodes.DensityEstimationFailed -Args @($errorMessage)
        }
    }
}

# Function to safely generate evaluation points
function Get-EvaluationPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,
        
        [Parameter(Mandatory = $false)]
        [double]$MarginFactor = 0.1
    )
    
    try {
        # Calculate basic statistics of the data
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        $range = $max - $min
        
        # Check if all data points are identical
        if ($range -eq 0) {
            # Use a small range around the single value
            $min = $min - 0.1
            $max = $max + 0.1
            $range = 0.2
        }
        
        # Add a margin to avoid edge effects
        $min = $min - $MarginFactor * $range
        $max = $max + $MarginFactor * $range
        
        # Generate a grid of evaluation points
        $step = ($max - $min) / ($NumPoints - 1)
        $evaluationPoints = New-Object double[] $NumPoints
        
        for ($i = 0; $i -lt $NumPoints; $i++) {
            $evaluationPoints[$i] = $min + $i * $step
        }
        
        return $evaluationPoints
    } catch {
        # Handle any unexpected errors
        $errorMessage = "Failed to generate evaluation points: $($_.Exception.Message)"
        Write-Verbose $errorMessage
        Throw-ValidationError -ErrorCode $ErrorCodes.DensityEstimationFailed -Args @($errorMessage)
    }
}

# Export the functions
Export-ModuleMember -Function Get-SilvermanBandwidth, Get-KernelValue, Get-DensityEstimate, Get-EvaluationPoints
