# KernelDensityEstimateValidation.ps1
# Script implementing validation functions for kernel density estimation

# Define error codes
$ErrorCodes = @{
    # Data validation errors
    DataNullOrEmpty             = "V001"
    DataTooSmall                = "V002"
    DataContainsNaN             = "V003"
    DataContainsInfinity        = "V004"
    DataNotNumeric              = "V005"
    DataDimensionMismatch       = "V006"

    # Evaluation points validation errors
    EvalPointsEmpty             = "V101"
    EvalPointsContainsNaN       = "V102"
    EvalPointsContainsInfinity  = "V103"
    EvalPointsNotNumeric        = "V104"
    EvalPointsDimensionMismatch = "V105"

    # Bandwidth validation errors
    BandwidthNegative           = "V201"
    BandwidthZero               = "V202"
    BandwidthContainsNaN        = "V203"
    BandwidthContainsInfinity   = "V204"
    BandwidthDimensionMismatch  = "V205"

    # Other parameter validation errors
    InvalidKernelType           = "V301"
    InvalidMethod               = "V302"
    InvalidObjective            = "V303"
    KFoldsTooSmall              = "V304"
    KFoldsTooLarge              = "V305"
    MaxIterationsTooSmall       = "V306"
    DimensionsNotSpecified      = "V307"
    DimensionsNotFound          = "V308"
}

# Define error messages
$ErrorMessages = @{
    # Data validation errors
    $ErrorCodes.DataNullOrEmpty             = "The input data is null or empty."
    $ErrorCodes.DataTooSmall                = "The input data has too few points. Minimum required: 2, Actual: {0}."
    $ErrorCodes.DataContainsNaN             = "The input data contains NaN values."
    $ErrorCodes.DataContainsInfinity        = "The input data contains infinity values."
    $ErrorCodes.DataNotNumeric              = "The input data contains non-numeric values."
    $ErrorCodes.DataDimensionMismatch       = "The input data points have inconsistent dimensions. {0}"

    # Evaluation points validation errors
    $ErrorCodes.EvalPointsEmpty             = "The evaluation points array is empty."
    $ErrorCodes.EvalPointsContainsNaN       = "The evaluation points contain NaN values."
    $ErrorCodes.EvalPointsContainsInfinity  = "The evaluation points contain infinity values."
    $ErrorCodes.EvalPointsNotNumeric        = "The evaluation points contain non-numeric values."
    $ErrorCodes.EvalPointsDimensionMismatch = "The evaluation points have inconsistent dimensions. {0}"

    # Bandwidth validation errors
    $ErrorCodes.BandwidthNegative           = "The bandwidth is negative: {0}."
    $ErrorCodes.BandwidthZero               = "The bandwidth is zero. This is only allowed when automatic bandwidth selection is enabled."
    $ErrorCodes.BandwidthContainsNaN        = "The bandwidth contains NaN values."
    $ErrorCodes.BandwidthContainsInfinity   = "The bandwidth contains infinity values."
    $ErrorCodes.BandwidthDimensionMismatch  = "The bandwidth dimensions do not match the data dimensions. {0}"

    # Other parameter validation errors
    $ErrorCodes.InvalidKernelType           = "The kernel type '{0}' is not valid. Valid kernel types are: {1}."
    $ErrorCodes.InvalidMethod               = "The bandwidth selection method '{0}' is not valid. Valid methods are: {1}."
    $ErrorCodes.InvalidObjective            = "The objective '{0}' is not valid. Valid objectives are: {1}."
    $ErrorCodes.KFoldsTooSmall              = "The number of folds ({0}) is too small. Minimum required: 2."
    $ErrorCodes.KFoldsTooLarge              = "The number of folds ({0}) is larger than the number of data points ({1})."
    $ErrorCodes.MaxIterationsTooSmall       = "The maximum number of iterations ({0}) is too small. Minimum required: 1."
    $ErrorCodes.DimensionsNotSpecified      = "The dimensions are not specified for multivariate data."
    $ErrorCodes.DimensionsNotFound          = "The specified dimension '{0}' is not found in the data. Available dimensions are: {1}."
}

# Function to throw a validation error
function Throw-ValidationError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorCode,

        [Parameter(Mandatory = $false)]
        [object[]]$Args = @()
    )

    # Get the error message template
    $messageTemplate = $ErrorMessages[$ErrorCode]

    # Format the message with the provided arguments
    $message = $messageTemplate
    if ($Args.Count -gt 0) {
        $message = $messageTemplate -f $Args
    }

    # Create a custom exception with the error code as a property
    $exception = New-Object System.Exception $message
    $exception | Add-Member -NotePropertyName ErrorCode -NotePropertyValue $ErrorCode -Force

    # Throw the exception
    throw $exception
}

# Function to validate data
function Test-KDEData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Data
    )

    # Check if data is null or empty
    if ($null -eq $Data -or $Data.Count -eq 0) {
        Throw-ValidationError -ErrorCode $ErrorCodes.DataNullOrEmpty
    }

    # Check if data has enough points
    if ($Data.Count -lt 2) {
        Throw-ValidationError -ErrorCode $ErrorCodes.DataTooSmall -Args @($Data.Count)
    }

    # Check if data contains NaN or infinity values
    foreach ($value in $Data) {
        if ($value -isnot [ValueType] -and $value -isnot [string]) {
            Throw-ValidationError -ErrorCode $ErrorCodes.DataNotNumeric
        }

        if ($value -is [string]) {
            # Try to convert string to double
            try {
                $doubleValue = [double]$value
            } catch {
                Throw-ValidationError -ErrorCode $ErrorCodes.DataNotNumeric
            }

            if ([double]::IsNaN($doubleValue)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DataContainsNaN
            }

            if ([double]::IsInfinity($doubleValue)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DataContainsInfinity
            }
        } else {
            # Check if value is NaN or infinity
            if ([double]::IsNaN($value)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DataContainsNaN
            }

            if ([double]::IsInfinity($value)) {
                Throw-ValidationError -ErrorCode $ErrorCodes.DataContainsInfinity
            }
        }
    }

    # Convert data to double array and return it
    $doubleArray = $Data | ForEach-Object { [double]$_ }
    return [double[]]$doubleArray
}

# Function to validate evaluation points
function Test-KDEEvaluationPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$EvaluationPoints
    )

    # Check if evaluation points is null or empty
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

    # Convert evaluation points to double array and return it
    $doubleArray = $EvaluationPoints | ForEach-Object { [double]$_ }
    return [double[]]$doubleArray
}

# Function to validate bandwidth
function Test-KDEBandwidth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,

        [Parameter(Mandatory = $false)]
        [switch]$AllowZero
    )

    # Check if bandwidth is NaN
    if ([double]::IsNaN($Bandwidth)) {
        Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthContainsNaN
    }

    # Check if bandwidth is infinity
    if ([double]::IsInfinity($Bandwidth)) {
        Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthContainsInfinity
    }

    # Check if bandwidth is negative
    if ($Bandwidth -lt 0) {
        Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthNegative -Args @($Bandwidth)
    }

    # Check if bandwidth is zero (when not allowed)
    if ($Bandwidth -eq 0 -and -not $AllowZero) {
        Throw-ValidationError -ErrorCode $ErrorCodes.BandwidthZero
    }

    return $Bandwidth
}

# Function to validate kernel type
function Test-KDEKernelType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$KernelType
    )

    $validKernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform")

    if ($KernelType -notin $validKernelTypes) {
        Throw-ValidationError -ErrorCode $ErrorCodes.InvalidKernelType -Args @($KernelType, ($validKernelTypes -join ", "))
    }

    return $KernelType
}

# Function to validate method
function Test-KDEMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Method
    )

    $validMethods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized", "Auto")

    if ($Method -notin $validMethods) {
        Throw-ValidationError -ErrorCode $ErrorCodes.InvalidMethod -Args @($Method, ($validMethods -join ", "))
    }

    return $Method
}

# Function to validate objective
function Test-KDEObjective {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Objective
    )

    $validObjectives = @("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")

    if ($Objective -notin $validObjectives) {
        Throw-ValidationError -ErrorCode $ErrorCodes.InvalidObjective -Args @($Objective, ($validObjectives -join ", "))
    }

    return $Objective
}

# Function to validate KFolds
function Test-KDEKFolds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$KFolds,

        [Parameter(Mandatory = $true)]
        [int]$DataCount
    )

    if ($KFolds -lt 2) {
        Throw-ValidationError -ErrorCode $ErrorCodes.KFoldsTooSmall -Args @($KFolds)
    }

    if ($KFolds -gt $DataCount) {
        Throw-ValidationError -ErrorCode $ErrorCodes.KFoldsTooLarge -Args @($KFolds, $DataCount)
    }

    return $KFolds
}

# Function to validate MaxIterations
function Test-KDEMaxIterations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$MaxIterations
    )

    if ($MaxIterations -lt 1) {
        Throw-ValidationError -ErrorCode $ErrorCodes.MaxIterationsTooSmall -Args @($MaxIterations)
    }

    return $MaxIterations
}

# Function to validate dimensions
function Test-KDEDimensions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $true)]
        [object]$DataPoint
    )

    if ($null -eq $Dimensions -or $Dimensions.Count -eq 0) {
        Throw-ValidationError -ErrorCode $ErrorCodes.DimensionsNotSpecified
    }

    $availableDimensions = $DataPoint.PSObject.Properties.Name

    foreach ($dimension in $Dimensions) {
        if ($dimension -notin $availableDimensions) {
            Throw-ValidationError -ErrorCode $ErrorCodes.DimensionsNotFound -Args @($dimension, ($availableDimensions -join ", "))
        }
    }

    return $Dimensions
}

# Export the functions
Export-ModuleMember -Function Test-KDEData, Test-KDEEvaluationPoints, Test-KDEBandwidth, Test-KDEKernelType, Test-KDEMethod, Test-KDEObjective, Test-KDEKFolds, Test-KDEMaxIterations, Test-KDEDimensions, Throw-ValidationError
Export-ModuleMember -Variable ErrorCodes, ErrorMessages
