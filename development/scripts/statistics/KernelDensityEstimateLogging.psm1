# KernelDensityEstimateLogging.psm1
# Module for logging and debugging in kernel density estimation

# Define verbosity levels as constants
# Using constants instead of an enumeration for better compatibility
New-Variable -Name KDELogLevelNone -Value 0 -Option Constant -Scope Script
New-Variable -Name KDELogLevelError -Value 1 -Option Constant -Scope Script
New-Variable -Name KDELogLevelWarning -Value 2 -Option Constant -Scope Script
New-Variable -Name KDELogLevelInfo -Value 3 -Option Constant -Scope Script
New-Variable -Name KDELogLevelDebug -Value 4 -Option Constant -Scope Script
New-Variable -Name KDELogLevelVerbose -Value 5 -Option Constant -Scope Script

# Create a hashtable for log level names
$script:LogLevelNames = @{
    $KDELogLevelNone    = "None"      # No logging
    $KDELogLevelError   = "Error"    # Critical errors that prevent execution
    $KDELogLevelWarning = "Warning" # Non-critical issues that might affect results
    $KDELogLevelInfo    = "Info"      # General information about execution
    $KDELogLevelDebug   = "Debug"    # Detailed information for debugging
    $KDELogLevelVerbose = "Verbose" # Very detailed information for tracing execution
}

# Default log level
$script:LogLevel = $KDELogLevelInfo

# Default log file path
$script:LogFilePath = $null

# Default log to console setting
$script:LogToConsole = $true

# Default log to file setting
$script:LogToFile = $false

# Default include timestamp setting
$script:IncludeTimestamp = $true

# Default include log level setting
$script:IncludeLogLevel = $true

# Default include caller info setting
$script:IncludeCallerInfo = $false

# Default log file append setting
$script:AppendToLogFile = $true

# Default log file max size (in MB)
$script:LogFileMaxSizeMB = 10

# Default log file rotation count
$script:LogFileRotationCount = 3

# Function to set the log level
function Set-KDELogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level
    )

    $script:LogLevel = $Level
    $levelName = $script:LogLevelNames[$Level]
    Write-Verbose "Log level set to $levelName ($Level)"
}

# Function to get the current log level
function Get-KDELogLevel {
    [CmdletBinding()]
    [OutputType([int])]
    param ()

    return $script:LogLevel
}

# Function to set the log file path
function Set-KDELogFilePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Append = $script:AppendToLogFile,

        [Parameter(Mandatory = $false)]
        [double]$MaxSizeMB = $script:LogFileMaxSizeMB,

        [Parameter(Mandatory = $false)]
        [int]$RotationCount = $script:LogFileRotationCount
    )

    $script:LogFilePath = $Path
    $script:AppendToLogFile = $Append
    $script:LogFileMaxSizeMB = $MaxSizeMB
    $script:LogFileRotationCount = $RotationCount

    # Create the log file directory if it doesn't exist
    $logDir = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Create the log file if it doesn't exist
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }

    # Check if the log file needs to be rotated
    if ($Append -and (Test-Path -Path $Path)) {
        $logFile = Get-Item -Path $Path
        if ($logFile.Length -gt ($MaxSizeMB * 1MB)) {
            # Rotate log files
            for ($i = $RotationCount; $i -gt 0; $i--) {
                $oldPath = "$Path.$i"
                $newPath = "$Path.$($i + 1)"

                if ($i -eq $RotationCount) {
                    # Remove the oldest log file
                    if (Test-Path -Path $oldPath) {
                        Remove-Item -Path $oldPath -Force
                    }
                } else {
                    # Rename the log file
                    if (Test-Path -Path $oldPath) {
                        if (Test-Path -Path $newPath) {
                            Remove-Item -Path $newPath -Force
                        }
                        Rename-Item -Path $oldPath -NewName $newPath
                    }
                }
            }

            # Rename the current log file
            Rename-Item -Path $Path -NewName "$Path.1"

            # Create a new log file
            New-Item -Path $Path -ItemType File -Force | Out-Null
        }
    } elseif (-not $Append -and (Test-Path -Path $Path)) {
        # Clear the log file
        Clear-Content -Path $Path
    }

    Write-Verbose "Log file path set to $Path"
}

# Function to enable or disable logging to console
function Set-KDELogToConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )

    $script:LogToConsole = $Enabled
    Write-Verbose "Logging to console set to $Enabled"
}

# Function to enable or disable logging to file
function Set-KDELogToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )

    $script:LogToFile = $Enabled
    Write-Verbose "Logging to file set to $Enabled"
}

# Function to enable or disable including timestamp in log messages
function Set-KDELogIncludeTimestamp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )

    $script:IncludeTimestamp = $Enabled
    Write-Verbose "Including timestamp in log messages set to $Enabled"
}

# Function to enable or disable including log level in log messages
function Set-KDELogIncludeLogLevel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )

    $script:IncludeLogLevel = $Enabled
    Write-Verbose "Including log level in log messages set to $Enabled"
}

# Function to enable or disable including caller info in log messages
function Set-KDELogIncludeCallerInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )

    $script:IncludeCallerInfo = $Enabled
    Write-Verbose "Including caller info in log messages set to $Enabled"
}

# Function to get the caller information
function Get-CallerInfo {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $callStack = Get-PSCallStack
    $caller = $callStack[1]

    return "$($caller.Command):$($caller.Location)"
}

# Function to format a log message
function Format-LogMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level
    )

    $formattedMessage = ""

    # Add timestamp if enabled
    if ($script:IncludeTimestamp) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $formattedMessage += "[$timestamp] "
    }

    # Add log level if enabled
    if ($script:IncludeLogLevel) {
        $levelName = $script:LogLevelNames[$Level]
        $formattedMessage += "[$levelName] "
    }

    # Add caller info if enabled
    if ($script:IncludeCallerInfo) {
        $callerInfo = Get-CallerInfo
        $formattedMessage += "[$callerInfo] "
    }

    # Add the message
    $formattedMessage += $Message

    return $formattedMessage
}

# Function to write a log message
function Write-KDELog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level = $KDELogLevelInfo
    )

    # Check if the log level is enabled
    if ($Level -gt $script:LogLevel) {
        return
    }

    # Format the log message
    $formattedMessage = Format-LogMessage -Message $Message -Level $Level

    # Write to console if enabled
    if ($script:LogToConsole) {
        switch ($Level) {
            $KDELogLevelError {
                Write-Error $formattedMessage
            }
            $KDELogLevelWarning {
                Write-Warning $formattedMessage
            }
            $KDELogLevelInfo {
                Write-Information $formattedMessage -InformationAction Continue
            }
            $KDELogLevelDebug {
                Write-Debug $formattedMessage
            }
            $KDELogLevelVerbose {
                Write-Verbose $formattedMessage
            }
            default {
                Write-Output $formattedMessage
            }
        }
    }

    # Write to file if enabled and log file path is set
    if ($script:LogToFile -and $script:LogFilePath) {
        try {
            # Ensure the log file exists
            if (-not (Test-Path -Path $script:LogFilePath)) {
                New-Item -Path $script:LogFilePath -ItemType File -Force | Out-Null
            }

            # Write to the log file
            Add-Content -Path $script:LogFilePath -Value $formattedMessage -Encoding UTF8
        } catch {
            Write-Error "Failed to write to log file: $($_.Exception.Message)"
        }
    }
}

# Convenience functions for different log levels
function Write-KDEError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    Write-KDELog -Message $Message -Level $KDELogLevelError
}

function Write-KDEWarning {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    Write-KDELog -Message $Message -Level $KDELogLevelWarning
}

function Write-KDEInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    Write-KDELog -Message $Message -Level $KDELogLevelInfo
}

function Write-KDEDebug {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    Write-KDELog -Message $Message -Level $KDELogLevelDebug
}

function Write-KDEVerbose {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )

    Write-KDELog -Message $Message -Level $KDELogLevelVerbose
}

# Function to initialize logging with default settings
function Initialize-KDELogging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level = $KDELogLevelInfo,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $null,

        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole = $true,

        [Parameter(Mandatory = $false)]
        [bool]$LogToFile = $false,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeTimestamp = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeLogLevel = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeCallerInfo = $false,

        [Parameter(Mandatory = $false)]
        [bool]$AppendToLogFile = $true,

        [Parameter(Mandatory = $false)]
        [double]$LogFileMaxSizeMB = 10,

        [Parameter(Mandatory = $false)]
        [int]$LogFileRotationCount = 3
    )

    # Set log level
    Set-KDELogLevel -Level $Level

    # Set log to console
    Set-KDELogToConsole -Enabled $LogToConsole

    # Set log to file
    Set-KDELogToFile -Enabled $LogToFile

    # Set include timestamp
    Set-KDELogIncludeTimestamp -Enabled $IncludeTimestamp

    # Set include log level
    Set-KDELogIncludeLogLevel -Enabled $IncludeLogLevel

    # Set include caller info
    Set-KDELogIncludeCallerInfo -Enabled $IncludeCallerInfo

    # Set log file path if provided
    if ($LogFilePath) {
        $script:AppendToLogFile = $AppendToLogFile
        $script:LogFileMaxSizeMB = $LogFileMaxSizeMB
        $script:LogFileRotationCount = $LogFileRotationCount

        Set-KDELogFilePath -Path $LogFilePath -Append:$AppendToLogFile -MaxSizeMB $LogFileMaxSizeMB -RotationCount $LogFileRotationCount
    }

    $levelName = $script:LogLevelNames[$Level]

    # Write a test message to the log file to verify it's working
    if ($LogToFile -and $LogFilePath) {
        $testMessage = "Logging initialized with level $levelName ($Level) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')"
        try {
            # Ensure the log file exists
            if (-not (Test-Path -Path $LogFilePath)) {
                New-Item -Path $LogFilePath -ItemType File -Force | Out-Null
            }

            # Write directly to the log file
            Add-Content -Path $LogFilePath -Value $testMessage -Encoding UTF8
        } catch {
            Write-Error "Failed to write to log file: $($_.Exception.Message)"
        }
    }

    Write-KDEInfo "Logging initialized with level $levelName ($Level)"
}

# Export functions
Export-ModuleMember -Function Set-KDELogLevel, Get-KDELogLevel, Set-KDELogFilePath, Set-KDELogToConsole, Set-KDELogToFile
Export-ModuleMember -Function Set-KDELogIncludeTimestamp, Set-KDELogIncludeLogLevel, Set-KDELogIncludeCallerInfo
Export-ModuleMember -Function Write-KDELog, Write-KDEError, Write-KDEWarning, Write-KDEInfo, Write-KDEDebug, Write-KDEVerbose
Export-ModuleMember -Function Initialize-KDELogging

# Export variables
Export-ModuleMember -Variable KDELogLevelNone, KDELogLevelError, KDELogLevelWarning, KDELogLevelInfo, KDELogLevelDebug, KDELogLevelVerbose
