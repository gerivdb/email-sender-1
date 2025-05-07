# Example-KernelDensityEstimateWithEnhancedErrors.ps1
# Example of using enhanced error messages with kernel density estimation

# Import the required modules
Write-Host "Importing modules..." -ForegroundColor Yellow
. ..\KernelDensityEstimateValidation.ps1
Write-Host "Validation module imported." -ForegroundColor Yellow

# Define enhanced error messages directly in this script for simplicity
$EnhancedErrorMessages = @{}

# Data validation error messages
$EnhancedErrorMessages[$ErrorCodes.DataNullOrEmpty] = @{
    Message    = "The input data is null or empty."
    Context    = "Kernel density estimation requires a non-empty dataset to function."
    Resolution = "Please provide a valid dataset with at least 2 data points."
    Example    = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"
}

$EnhancedErrorMessages[$ErrorCodes.DataTooSmall] = @{
    Message    = "The input data has too few points. Minimum required: 2, Actual: {0}."
    Context    = "Kernel density estimation requires at least 2 data points to calculate a meaningful density estimate."
    Resolution = "Please provide a dataset with at least 2 data points."
    Example    = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"
}

$EnhancedErrorMessages[$ErrorCodes.InvalidKernelType] = @{
    Message    = "The kernel type '{0}' is not valid. Valid kernel types are: {1}."
    Context    = "The kernel type determines the shape of the kernel function used for density estimation."
    Resolution = "Please use one of the valid kernel types listed in the error message."
    Example    = "Get-KernelDensityEstimate -Data $data -KernelType 'Gaussian'"
}

$EnhancedErrorMessages[$ErrorCodes.BandwidthNegative] = @{
    Message    = "The bandwidth is negative: {0}."
    Context    = "Bandwidth must be a positive value as it represents the smoothing parameter for kernel density estimation."
    Resolution = "Please provide a positive bandwidth value or use 0 for automatic bandwidth selection."
    Example    = "Get-KernelDensityEstimate -Data $data -Bandwidth 1.5"
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
            Message    = "Unknown error code: $ErrorCode"
            Context    = "No additional context available for this error code."
            Resolution = "Please check the documentation for more information."
            Example    = "N/A"
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
        Message    = $formattedMessage
        Context    = $enhancedMessage.Context
        Resolution = $enhancedMessage.Resolution
        Example    = $enhancedMessage.Example
    }

    return $result
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

Write-Host "Helper functions defined." -ForegroundColor Yellow

# Function to demonstrate enhanced error handling
function Get-KernelDensityEstimateWithEnhancedErrors {
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
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = "The bandwidth to use for density estimation. If not specified, it will be automatically determined.")]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = "Whether to include help information in error messages.")]
        [switch]$IncludeHelpInErrors
    )

    try {
        # Validate input data
        if ($null -eq $Data -or $Data.Count -eq 0) {
            # Create a custom error message
            $errorMessage = "The input data is null or empty."
            $errorContext = "Kernel density estimation requires a non-empty dataset to function."
            $errorResolution = "Please provide a valid dataset with at least 2 data points."
            $errorExample = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"

            # Write the error message
            Write-Error "Error: $errorMessage`n`nContext: $errorContext`n`nResolution: $errorResolution`n`nExample: $errorExample"

            # Throw a standard exception
            throw "The input data is null or empty."
        }

        if ($Data.Count -lt 2) {
            # Create a custom error message
            $errorMessage = "The input data has too few points. Minimum required: 2, Actual: $($Data.Count)."
            $errorContext = "Kernel density estimation requires at least 2 data points to calculate a meaningful density estimate."
            $errorResolution = "Please provide a dataset with at least 2 data points."
            $errorExample = "Get-KernelDensityEstimate -Data @(1, 2, 3, 4, 5)"

            # Write the error message
            Write-Error "Error: $errorMessage`n`nContext: $errorContext`n`nResolution: $errorResolution`n`nExample: $errorExample"

            # Throw a standard exception
            throw $errorMessage
        }

        # Check if data contains NaN or infinity values
        foreach ($value in $Data) {
            if ($value -isnot [ValueType] -and $value -isnot [string]) {
                $errorMessage = "The input data contains non-numeric values."
                Write-Error $errorMessage
                throw $errorMessage
            }

            if ($value -is [string]) {
                # Try to convert string to double
                try {
                    $doubleValue = [double]$value
                } catch {
                    $errorMessage = "The input data contains non-numeric values."
                    Write-Error $errorMessage
                    throw $errorMessage
                }

                if ([double]::IsNaN($doubleValue)) {
                    $errorMessage = "The input data contains NaN values."
                    Write-Error $errorMessage
                    throw $errorMessage
                }

                if ([double]::IsInfinity($doubleValue)) {
                    $errorMessage = "The input data contains infinity values."
                    Write-Error $errorMessage
                    throw $errorMessage
                }
            } else {
                # Check if value is NaN or infinity
                if ([double]::IsNaN($value)) {
                    $errorMessage = "The input data contains NaN values."
                    Write-Error $errorMessage
                    throw $errorMessage
                }

                if ([double]::IsInfinity($value)) {
                    $errorMessage = "The input data contains infinity values."
                    Write-Error $errorMessage
                    throw $errorMessage
                }
            }
        }

        # Convert data to double array
        $Data = $Data | ForEach-Object { [double]$_ }

        # Validate evaluation points if provided
        if ($PSBoundParameters.ContainsKey('EvaluationPoints')) {
            if ($null -eq $EvaluationPoints -or $EvaluationPoints.Count -eq 0) {
                Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsEmpty
            }

            # Check if evaluation points contain NaN or infinity values
            foreach ($value in $EvaluationPoints) {
                if ($value -isnot [ValueType] -and $value -isnot [string]) {
                    Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsNotNumeric
                }

                if ($value -is [string]) {
                    # Try to convert string to double
                    try {
                        $doubleValue = [double]$value
                    } catch {
                        Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsNotNumeric
                    }

                    if ([double]::IsNaN($doubleValue)) {
                        Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsContainsNaN
                    }

                    if ([double]::IsInfinity($doubleValue)) {
                        Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsContainsInfinity
                    }
                } else {
                    # Check if value is NaN or infinity
                    if ([double]::IsNaN($value)) {
                        Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsContainsNaN
                    }

                    if ([double]::IsInfinity($value)) {
                        Throw-ValidationError -ErrorCode $ErrorCodes.EvalPointsContainsInfinity
                    }
                }
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
            $errorContext = "Bandwidth must be a positive value as it represents the smoothing parameter for kernel density estimation."
            $errorResolution = "Please provide a positive bandwidth value or use 0 for automatic bandwidth selection."
            $errorExample = "Get-KernelDensityEstimate -Data `$data -Bandwidth 1.5"

            # Write the error message
            Write-Error "Error: $errorMessage`n`nContext: $errorContext`n`nResolution: $errorResolution`n`nExample: $errorExample"

            # Throw a standard exception
            throw $errorMessage
        }

        if ($Bandwidth -eq 0 -and $PSBoundParameters.ContainsKey('Bandwidth')) {
            $errorMessage = "The bandwidth is zero. This is only allowed when automatic bandwidth selection is enabled."
            $errorContext = "A zero bandwidth would result in division by zero during density estimation calculations."
            $errorResolution = "Please provide a positive bandwidth value or use automatic bandwidth selection by omitting the Bandwidth parameter."
            $errorExample = "Get-KernelDensityEstimate -Data `$data -Bandwidth 1.5"

            # Write the error message
            Write-Error "Error: $errorMessage`n`nContext: $errorContext`n`nResolution: $errorResolution`n`nExample: $errorExample"

            # Throw a standard exception
            throw $errorMessage
        }

        if ([double]::IsNaN($Bandwidth)) {
            $errorMessage = "The bandwidth contains NaN values."
            Write-Error $errorMessage
            throw $errorMessage
        }

        if ([double]::IsInfinity($Bandwidth)) {
            $errorMessage = "The bandwidth contains infinity values."
            Write-Error $errorMessage
            throw $errorMessage
        }

        # Validate kernel type
        $validKernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform")
        if ($KernelType -notin $validKernelTypes) {
            $errorMessage = "The kernel type '$KernelType' is not valid. Valid kernel types are: $($validKernelTypes -join ", ")."
            $errorContext = "The kernel type determines the shape of the kernel function used for density estimation."
            $errorResolution = "Please use one of the valid kernel types listed in the error message."
            $errorExample = "Get-KernelDensityEstimate -Data `$data -KernelType 'Gaussian'"

            # Write the error message
            Write-Error "Error: $errorMessage`n`nContext: $errorContext`n`nResolution: $errorResolution`n`nExample: $errorExample"

            # Throw a standard exception
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

            # Check if bandwidth calculation failed
            if ($Bandwidth -eq 0) {
                Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthCalculationFailed -Args @("Bandwidth calculation resulted in zero. This may be due to all data points being identical.")
            }

            if ([double]::IsNaN($Bandwidth)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthCalculationFailed -Args @("Bandwidth calculation resulted in NaN.")
            }

            if ([double]::IsInfinity($Bandwidth)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthCalculationFailed -Args @("Bandwidth calculation resulted in infinity.")
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

                # Check if kernel calculation failed
                if ([double]::IsNaN($kernelValue)) {
                    Throw-ValidationError -ErrorCode $ErrorCodes.KernelCalculationFailed -Args @("Kernel calculation resulted in NaN for x = $x.")
                }

                if ([double]::IsInfinity($kernelValue)) {
                    Throw-ValidationError -ErrorCode $ErrorCodes.KernelCalculationFailed -Args @("Kernel calculation resulted in infinity for x = $x.")
                }

                $density += $kernelValue
            }

            $densityEstimates[$i] = $density / ($Bandwidth * $Data.Count)

            # Check if density estimation failed
            if ([double]::IsNaN($densityEstimates[$i])) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityContainsNaN
            }

            if ([double]::IsInfinity($densityEstimates[$i])) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityContainsInfinity
            }

            if ($densityEstimates[$i] -lt 0) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DensityNegative
            }
        }

        # Create the output object
        $result = [PSCustomObject]@{
            Data             = $Data
            EvaluationPoints = $EvaluationPoints
            DensityEstimates = $densityEstimates
            KernelType       = $KernelType
            Bandwidth        = $Bandwidth
        }

        return $result
    } catch {
        # Write the error message
        Write-Error $_.Exception.Message

        # Re-throw the exception
        throw
    }
}

# Example 1: Empty data
Write-Host "`nExample 1: Empty data" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    $emptyData = @()
    $result = Get-KernelDensityEstimateWithEnhancedErrors -Data $emptyData

    Write-Host "This should not be reached" -ForegroundColor Red
} catch {
    Write-Host "Error caught as expected!" -ForegroundColor Green
    $errorMessage = Format-ErrorMessage -Exception $_.Exception -IncludeHelp
    Write-Host $errorMessage -ForegroundColor Yellow
}

# Example 2: Data with too few points
Write-Host "`nExample 2: Data with too few points" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    $smallData = @(1)
    $result = Get-KernelDensityEstimateWithEnhancedErrors -Data $smallData

    Write-Host "This should not be reached" -ForegroundColor Red
} catch {
    Write-Host "Error caught as expected!" -ForegroundColor Green
    $errorMessage = Format-ErrorMessage -Exception $_.Exception -IncludeHelp
    Write-Host $errorMessage -ForegroundColor Yellow
}

# Example 3: Invalid kernel type
Write-Host "`nExample 3: Invalid kernel type" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    $data = 1..10
    $result = Get-KernelDensityEstimateWithEnhancedErrors -Data $data -KernelType "InvalidKernel"

    Write-Host "This should not be reached" -ForegroundColor Red
} catch {
    Write-Host "Error caught as expected!" -ForegroundColor Green
    $errorMessage = Format-ErrorMessage -Exception $_.Exception -IncludeHelp
    Write-Host $errorMessage -ForegroundColor Yellow
}

# Example 4: Negative bandwidth
Write-Host "`nExample 4: Negative bandwidth" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan

try {
    $data = 1..10
    $result = Get-KernelDensityEstimateWithEnhancedErrors -Data $data -Bandwidth -1

    Write-Host "This should not be reached" -ForegroundColor Red
} catch {
    Write-Host "Error caught as expected!" -ForegroundColor Green
    $errorMessage = Format-ErrorMessage -Exception $_.Exception -IncludeHelp
    Write-Host $errorMessage -ForegroundColor Yellow
}
