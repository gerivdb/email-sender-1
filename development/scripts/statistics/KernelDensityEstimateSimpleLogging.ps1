# KernelDensityEstimateSimpleLogging.ps1
# Simple logging functions for kernel density estimation

# Define verbosity levels as constants
$script:LogLevelNone = 0    # No logging
$script:LogLevelError = 1   # Critical errors that prevent execution
$script:LogLevelWarning = 2 # Non-critical issues that might affect results
$script:LogLevelInfo = 3    # General information about execution
$script:LogLevelDebug = 4   # Detailed information for debugging
$script:LogLevelVerbose = 5 # Very detailed information for tracing execution

# Create a hashtable for log level names
$script:LogLevelNames = @{
    $script:LogLevelNone = "None"
    $script:LogLevelError = "Error"
    $script:LogLevelWarning = "Warning"
    $script:LogLevelInfo = "Info"
    $script:LogLevelDebug = "Debug"
    $script:LogLevelVerbose = "Verbose"
}

# Default log level
$script:LogLevel = $script:LogLevelInfo

# Default log file path
$script:LogFilePath = $null

# Default log to console setting
$script:LogToConsole = $true

# Default log to file setting
$script:LogToFile = $false

# Function to set the log level
function Set-LogLevel {
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

# Function to set the log file path
function Set-LogFilePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )
    
    $script:LogFilePath = $Path
    
    # Create the log file directory if it doesn't exist
    $logDir = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrEmpty($logDir) -and -not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Create the log file if it doesn't exist
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType File -Force | Out-Null
    }
    
    Write-Verbose "Log file path set to $Path"
}

# Function to enable or disable logging to console
function Set-LogToConsole {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )
    
    $script:LogToConsole = $Enabled
    Write-Verbose "Logging to console set to $Enabled"
}

# Function to enable or disable logging to file
function Set-LogToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [bool]$Enabled
    )
    
    $script:LogToFile = $Enabled
    Write-Verbose "Logging to file set to $Enabled"
}

# Function to write a log message
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level = $script:LogLevelInfo
    )
    
    # Check if the log level is enabled
    if ($Level -gt $script:LogLevel) {
        return
    }
    
    # Format the log message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $levelName = $script:LogLevelNames[$Level]
    $formattedMessage = "[$timestamp] [$levelName] $Message"
    
    # Write to console if enabled
    if ($script:LogToConsole) {
        switch ($Level) {
            $script:LogLevelError {
                Write-Error $formattedMessage
            }
            $script:LogLevelWarning {
                Write-Warning $formattedMessage
            }
            $script:LogLevelInfo {
                Write-Host $formattedMessage
            }
            $script:LogLevelDebug {
                Write-Host $formattedMessage -ForegroundColor Cyan
            }
            $script:LogLevelVerbose {
                Write-Host $formattedMessage -ForegroundColor Gray
            }
            default {
                Write-Host $formattedMessage
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
function Write-ErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    Write-Log -Message $Message -Level $script:LogLevelError
}

function Write-WarningLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    Write-Log -Message $Message -Level $script:LogLevelWarning
}

function Write-InfoLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    Write-Log -Message $Message -Level $script:LogLevelInfo
}

function Write-DebugLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    Write-Log -Message $Message -Level $script:LogLevelDebug
}

function Write-VerboseLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message
    )
    
    Write-Log -Message $Message -Level $script:LogLevelVerbose
}

# Function to initialize logging with default settings
function Initialize-Logging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$Level = $script:LogLevelInfo,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = $null,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToConsole = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$LogToFile = $false
    )
    
    # Set log level
    Set-LogLevel -Level $Level
    
    # Set log to console
    Set-LogToConsole -Enabled $LogToConsole
    
    # Set log to file
    Set-LogToFile -Enabled $LogToFile
    
    # Set log file path if provided
    if ($LogFilePath) {
        Set-LogFilePath -Path $LogFilePath
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
    
    Write-InfoLog "Logging initialized with level $levelName ($Level)"
}
