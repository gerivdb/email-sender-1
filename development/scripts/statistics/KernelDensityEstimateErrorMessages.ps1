# KernelDensityEstimateErrorMessages.ps1
# Script implementing enhanced error messages for kernel density estimation

# Import the validation, calculation, and memory error handling functions
. "$PSScriptRoot\KernelDensityEstimateValidation.ps1"
. "$PSScriptRoot\KernelDensityEstimateCalculationErrorHandling.ps1"
. "$PSScriptRoot\KernelDensityEstimateMemoryErrorHandling.ps1"

# Define enhanced error messages with context and resolution suggestions
$EnhancedErrorMessages = @{}

# Data validation error messages
$EnhancedErrorMessages[$ErrorCodes.DataNullOrEmpty] = @{
    Message = "The input data is null or empty."
    Context = "Kernel density estimation requires a non-empty dataset to function."
    Resolution = "Please provide a valid dataset with at least 2 data points."
    Example = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"
}

$EnhancedErrorMessages[$ErrorCodes.DataTooSmall] = @{
    Message = "The input data has too few points. Minimum required: 2, Actual: {0}."
    Context = "Kernel density estimation requires at least 2 data points to calculate a meaningful density estimate."
    Resolution = "Please provide a dataset with at least 2 data points."
    Example = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"
}

$EnhancedErrorMessages[$ErrorCodes.DataContainsNaN] = @{
    Message = "The input data contains NaN (Not a Number) values."
    Context = "NaN values cannot be used in numerical calculations and will cause errors in the density estimation."
    Resolution = "Please remove or replace NaN values in your dataset before proceeding."
    Example = "# Filter out NaN values`n`$cleanData = `$data | Where-Object { -not [double]::IsNaN(`$_) }"
}

$EnhancedErrorMessages[$ErrorCodes.DataContainsInfinity] = @{
    Message = "The input data contains infinity values."
    Context = "Infinity values can cause numerical instability in the density estimation calculations."
    Resolution = "Please remove or replace infinity values in your dataset before proceeding."
    Example = "# Filter out infinity values`n`$cleanData = `$data | Where-Object { -not [double]::IsInfinity(`$_) }"
}

$EnhancedErrorMessages[$ErrorCodes.DataNotNumeric] = @{
    Message = "The input data contains non-numeric values."
    Context = "Kernel density estimation requires numeric data for all calculations."
    Resolution = "Please ensure all values in your dataset are numeric or can be converted to numeric values."
    Example = "# Convert all values to numeric (if possible)`n`$numericData = `$data | ForEach-Object { [double]`$_ }"
}

$EnhancedErrorMessages[$ErrorCodes.DataDimensionMismatch] = @{
    Message = "The input data points have inconsistent dimensions. {0}"
    Context = "For multivariate kernel density estimation, all data points must have the same dimensions."
    Resolution = "Please ensure all data points have the same dimensions or properties."
    Example = "# Example of consistent multivariate data`n`$data = @(`n  [PSCustomObject]@{ X = 1; Y = 2 },`n  [PSCustomObject]@{ X = 3; Y = 4 }`n)"
}

# Evaluation points error messages
$EnhancedErrorMessages[$ErrorCodes.EvalPointsEmpty] = @{
    Message = "The evaluation points array is empty."
    Context = "Kernel density estimation requires a non-empty array of evaluation points to calculate density estimates."
    Resolution = "Please provide a valid array of evaluation points or omit the parameter to use automatically generated points."
    Example = "# Let the function generate evaluation points automatically`nGet-KernelDensityEstimate -Data `$data`n`n# Or provide your own evaluation points`nGet-KernelDensityEstimate -Data `$data -EvaluationPoints @(1, 2, 3, 4, 5)"
}

$EnhancedErrorMessages[$ErrorCodes.EvalPointsContainsNaN] = @{
    Message = "The evaluation points contain NaN (Not a Number) values."
    Context = "NaN values cannot be used as evaluation points for density estimation."
    Resolution = "Please remove or replace NaN values in your evaluation points before proceeding."
    Example = "# Filter out NaN values`n`$cleanPoints = `$evaluationPoints | Where-Object { -not [double]::IsNaN(`$_) }"
}

$EnhancedErrorMessages[$ErrorCodes.EvalPointsContainsInfinity] = @{
    Message = "The evaluation points contain infinity values."
    Context = "Infinity values cannot be used as evaluation points for density estimation."
    Resolution = "Please remove or replace infinity values in your evaluation points before proceeding."
    Example = "# Filter out infinity values`n`$cleanPoints = `$evaluationPoints | Where-Object { -not [double]::IsInfinity(`$_) }"
}

$EnhancedErrorMessages[$ErrorCodes.EvalPointsNotNumeric] = @{
    Message = "The evaluation points contain non-numeric values."
    Context = "Kernel density estimation requires numeric evaluation points for all calculations."
    Resolution = "Please ensure all evaluation points are numeric or can be converted to numeric values."
    Example = "# Convert all values to numeric (if possible)`n`$numericPoints = `$evaluationPoints | ForEach-Object { [double]`$_ }"
}

$EnhancedErrorMessages[$ErrorCodes.EvalPointsDimensionMismatch] = @{
    Message = "The evaluation points have inconsistent dimensions. {0}"
    Context = "For multivariate kernel density estimation, all evaluation points must have the same dimensions as the data points."
    Resolution = "Please ensure all evaluation points have the same dimensions or properties as the data points."
    Example = "# Example of consistent multivariate evaluation points`n`$evalPoints = @(`n  [PSCustomObject]@{ X = 1; Y = 2 },`n  [PSCustomObject]@{ X = 3; Y = 4 }`n)"
}

# Bandwidth error messages
$EnhancedErrorMessages[$ErrorCodes.BandwidthNegative] = @{
    Message = "The bandwidth is negative: {0}."
    Context = "Bandwidth must be a positive value as it represents the smoothing parameter for kernel density estimation."
    Resolution = "Please provide a positive bandwidth value or use 0 for automatic bandwidth selection."
    Example = "# Use automatic bandwidth selection`nGet-KernelDensityEstimate -Data `$data -Bandwidth 0`n`n# Or provide a positive bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthZero] = @{
    Message = "The bandwidth is zero. This is only allowed when automatic bandwidth selection is enabled."
    Context = "A zero bandwidth would result in division by zero during density estimation calculations."
    Resolution = "Please provide a positive bandwidth value or use automatic bandwidth selection by omitting the Bandwidth parameter."
    Example = "# Use automatic bandwidth selection`nGet-KernelDensityEstimate -Data `$data`n`n# Or provide a positive bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthContainsNaN] = @{
    Message = "The bandwidth contains NaN (Not a Number) values."
    Context = "NaN values cannot be used as bandwidth for density estimation."
    Resolution = "Please provide a valid numeric bandwidth value."
    Example = "Get-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthContainsInfinity] = @{
    Message = "The bandwidth contains infinity values."
    Context = "Infinity values cannot be used as bandwidth for density estimation."
    Resolution = "Please provide a valid numeric bandwidth value."
    Example = "Get-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthDimensionMismatch] = @{
    Message = "The bandwidth dimensions do not match the data dimensions. {0}"
    Context = "For multivariate kernel density estimation, the bandwidth must have the same dimensions as the data points."
    Resolution = "Please ensure the bandwidth has the same dimensions or properties as the data points."
    Example = "# Example of consistent multivariate bandwidth`nGet-KernelDensityEstimateMultivariate -Data `$data -Bandwidth ([PSCustomObject]@{ X = 1.5; Y = 2.0 })"
}

# Other parameter error messages
$EnhancedErrorMessages[$ErrorCodes.InvalidKernelType] = @{
    Message = "The kernel type '{0}' is not valid. Valid kernel types are: {1}."
    Context = "The kernel type determines the shape of the kernel function used for density estimation."
    Resolution = "Please use one of the valid kernel types listed in the error message."
    Example = "# Use the Gaussian kernel (default)`nGet-KernelDensityEstimate -Data `$data -KernelType 'Gaussian'`n`n# Or use another valid kernel type`nGet-KernelDensityEstimate -Data `$data -KernelType 'Epanechnikov'"
}

$EnhancedErrorMessages[$ErrorCodes.InvalidMethod] = @{
    Message = "The bandwidth selection method '{0}' is not valid. Valid methods are: {1}."
    Context = "The bandwidth selection method determines how the optimal bandwidth is calculated."
    Resolution = "Please use one of the valid methods listed in the error message."
    Example = "# Use the Silverman method (default)`nGet-KernelDensityEstimate -Data `$data -Method 'Silverman'`n`n# Or use another valid method`nGet-KernelDensityEstimate -Data `$data -Method 'Scott'"
}

# Calculation error messages
$EnhancedErrorMessages[$ErrorCodes.BandwidthCalculationFailed] = @{
    Message = "The bandwidth calculation failed. {0}"
    Context = "The automatic bandwidth calculation encountered an error, possibly due to unusual data characteristics."
    Resolution = "Try providing a manual bandwidth value instead of relying on automatic calculation."
    Example = "# Provide a manual bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthTooSmall] = @{
    Message = "The calculated bandwidth ({0}) is too small. Minimum allowed: {1}."
    Context = "A very small bandwidth can cause numerical instability and produce unreliable density estimates."
    Resolution = "Try providing a larger manual bandwidth value or use a different bandwidth selection method."
    Example = "# Provide a larger manual bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthTooLarge] = @{
    Message = "The calculated bandwidth ({0}) is too large. Maximum allowed: {1}."
    Context = "A very large bandwidth can oversmooth the density estimate, hiding important features of the data."
    Resolution = "Try providing a smaller manual bandwidth value or use a different bandwidth selection method."
    Example = "# Provide a smaller manual bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 0.5"
}

$EnhancedErrorMessages[$ErrorCodes.DensityEstimationFailed] = @{
    Message = "The density estimation failed. {0}"
    Context = "The density estimation calculation encountered an error, possibly due to numerical issues."
    Resolution = "Try using a different kernel type, bandwidth, or preprocessing your data to remove outliers."
    Example = "# Try a different kernel type`nGet-KernelDensityEstimate -Data `$data -KernelType 'Epanechnikov'`n`n# Or try a different bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 1.5"
}

$EnhancedErrorMessages[$ErrorCodes.DensityNormalizationFailed] = @{
    Message = "The density normalization failed because all density estimates are zero."
    Context = "Normalization requires at least one non-zero density estimate."
    Resolution = "Try using a larger bandwidth, different evaluation points, or check if your data is valid."
    Example = "# Try a larger bandwidth`nGet-KernelDensityEstimate -Data `$data -Bandwidth 2.0`n`n# Or try different evaluation points`nGet-KernelDensityEstimate -Data `$data -EvaluationPoints `$customPoints"
}

# Memory error messages
$EnhancedErrorMessages[$ErrorCodes.MemoryAllocationFailed] = @{
    Message = "Failed to allocate memory. {0}"
    Context = "The operation requires more memory than is currently available."
    Resolution = "Try reducing the size of your dataset, using fewer evaluation points, or enabling chunking."
    Example = "# Use memory-optimized version with chunking`nGet-KernelDensityEstimateMemoryOptimized -Data `$data -ChunkSize 1000"
}

$EnhancedErrorMessages[$ErrorCodes.OutOfMemory] = @{
    Message = "The system is out of memory."
    Context = "The operation requires more memory than is available on your system."
    Resolution = "Try reducing the size of your dataset, using fewer evaluation points, enabling chunking, or closing other applications to free up memory."
    Example = "# Use memory-optimized version with smaller chunk size`nGet-KernelDensityEstimateMemoryOptimized -Data `$data -ChunkSize 500"
}

# Function to get an enhanced error message
function Get-EnhancedErrorMessage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorCode,
        
        [Parameter(Mandatory = $false)]
        [object[]]$Args = @()
    )
    
    # Check if the error code exists in the enhanced error messages
    if (-not $EnhancedErrorMessages.ContainsKey($ErrorCode)) {
        return [PSCustomObject]@{
            Message = "Unknown error code: $ErrorCode"
            Context = "No additional context available for this error code."
            Resolution = "Please check the documentation for more information."
            Example = "N/A"
        }
    }
    
    # Get the enhanced error message
    $enhancedMessage = $EnhancedErrorMessages[$ErrorCode]
    
    # Format the message with the provided arguments
    $formattedMessage = $enhancedMessage.Message
    if ($Args.Count -gt 0) {
        $formattedMessage = $formattedMessage -f $Args
    }
    
    # Create the result object
    $result = [PSCustomObject]@{
        Message = $formattedMessage
        Context = $enhancedMessage.Context
        Resolution = $enhancedMessage.Resolution
        Example = $enhancedMessage.Example
    }
    
    return $result
}

# Function to throw an enhanced error
function Throw-EnhancedError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorCode,
        
        [Parameter(Mandatory = $false)]
        [object[]]$Args = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeHelp
    )
    
    # Get the enhanced error message
    $enhancedMessage = Get-EnhancedErrorMessage -ErrorCode $ErrorCode -Args $Args
    
    # Create the error message
    $errorMessage = $enhancedMessage.Message
    
    # Include help information if requested
    if ($IncludeHelp) {
        $errorMessage += "`n`nContext: $($enhancedMessage.Context)`n"
        $errorMessage += "Resolution: $($enhancedMessage.Resolution)`n"
        $errorMessage += "Example: $($enhancedMessage.Example)"
    }
    
    # Throw the error
    Throw-ValidationError -ErrorCode $ErrorCode -Args $Args
}

# Function to format an error message with enhanced information
function Format-ErrorMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Exception]$Exception,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeHelp,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStackTrace
    )
    
    # Initialize the formatted message
    $formattedMessage = ""
    
    # Check if the exception has an error code
    if ($Exception.PSObject.Properties.Name -contains "ErrorCode") {
        # Get the enhanced error message
        $enhancedMessage = Get-EnhancedErrorMessage -ErrorCode $Exception.ErrorCode
        
        # Add the error message
        $formattedMessage += "Error: $($Exception.Message)`n"
        
        # Include help information if requested
        if ($IncludeHelp) {
            $formattedMessage += "`nContext: $($enhancedMessage.Context)`n"
            $formattedMessage += "Resolution: $($enhancedMessage.Resolution)`n"
            $formattedMessage += "Example: $($enhancedMessage.Example)`n"
        }
    } else {
        # Use the exception message as is
        $formattedMessage += "Error: $($Exception.Message)`n"
    }
    
    # Include stack trace if requested
    if ($IncludeStackTrace -and $Exception.StackTrace) {
        $formattedMessage += "`nStack Trace:`n$($Exception.StackTrace)`n"
    }
    
    return $formattedMessage
}

# Export the functions
Export-ModuleMember -Function Get-EnhancedErrorMessage, Throw-EnhancedError, Format-ErrorMessage
Export-ModuleMember -Variable EnhancedErrorMessages
