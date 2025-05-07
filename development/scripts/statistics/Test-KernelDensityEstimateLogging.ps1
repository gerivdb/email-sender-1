# Test-KernelDensityEstimateLogging.ps1
# Script to test the logging module for kernel density estimation

# Import the logging module
Import-Module .\KernelDensityEstimateLogging.psm1 -Force

# Create a temporary log file
$tempLogFile = [System.IO.Path]::GetTempFileName()

# Function to test logging at different levels
function Test-LoggingLevels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(0, 1, 2, 3, 4, 5)]
        [int]$CurrentLogLevel
    )

    $levelName = switch ($CurrentLogLevel) {
        $KDELogLevelNone { "None" }
        $KDELogLevelError { "Error" }
        $KDELogLevelWarning { "Warning" }
        $KDELogLevelInfo { "Info" }
        $KDELogLevelDebug { "Debug" }
        $KDELogLevelVerbose { "Verbose" }
        default { "Unknown" }
    }

    Write-Host "Testing logging with log level set to $levelName ($CurrentLogLevel)" -ForegroundColor Cyan

    # Set the log level
    Set-KDELogLevel -Level $CurrentLogLevel

    # Test logging at each level
    Write-KDEError "This is an error message"
    Write-KDEWarning "This is a warning message"
    Write-KDEInfo "This is an info message"
    Write-KDEDebug "This is a debug message"
    Write-KDEVerbose "This is a verbose message"

    # Check the log file
    if (Test-Path -Path $tempLogFile) {
        $logContent = Get-Content -Path $tempLogFile
        Write-Host "Log file content:" -ForegroundColor Yellow
        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }

    # Clear the log file
    Clear-Content -Path $tempLogFile
}

# Function to test log message formatting
function Test-LogMessageFormatting {
    [CmdletBinding()]
    param ()

    Write-Host "Testing log message formatting" -ForegroundColor Cyan

    # Test with default settings
    Write-Host "Testing with default settings" -ForegroundColor Yellow
    Initialize-KDELogging -Level $KDELogLevelVerbose -LogFilePath $tempLogFile -LogToFile $true
    Write-KDEInfo "This is a test message with default formatting"

    # Test without timestamp
    Write-Host "Testing without timestamp" -ForegroundColor Yellow
    Set-KDELogIncludeTimestamp -Enabled $false
    Write-KDEInfo "This is a test message without timestamp"

    # Test without log level
    Write-Host "Testing without log level" -ForegroundColor Yellow
    Set-KDELogIncludeTimestamp -Enabled $true
    Set-KDELogIncludeLogLevel -Enabled $false
    Write-KDEInfo "This is a test message without log level"

    # Test with caller info
    Write-Host "Testing with caller info" -ForegroundColor Yellow
    Set-KDELogIncludeLogLevel -Enabled $true
    Set-KDELogIncludeCallerInfo -Enabled $true
    Write-KDEInfo "This is a test message with caller info"

    # Check the log file
    if (Test-Path -Path $tempLogFile) {
        $logContent = Get-Content -Path $tempLogFile
        Write-Host "Log file content:" -ForegroundColor Yellow
        $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }

    # Clear the log file
    Clear-Content -Path $tempLogFile
}

# Function to test log file rotation
function Test-LogFileRotation {
    [CmdletBinding()]
    param ()

    Write-Host "Testing log file rotation" -ForegroundColor Cyan

    # Create a small log file with a low max size
    $rotationLogFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "kde_log_rotation_test.log")

    # Initialize logging with a small max size
    Initialize-KDELogging -Level $KDELogLevelInfo -LogFilePath $rotationLogFile -LogToFile $true -LogFileMaxSizeMB 0.001 -LogFileRotationCount 3

    # Write enough data to trigger rotation
    for ($i = 0; $i -lt 100; $i++) {
        Write-KDEInfo "This is log message $i to test log file rotation"
    }

    # Check if rotation files were created
    $rotationFiles = Get-ChildItem -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "kde_log_rotation_test.log*"))

    Write-Host "Rotation files:" -ForegroundColor Yellow
    $rotationFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }

    # Clean up rotation files
    $rotationFiles | Remove-Item -Force
}

# Main test script
try {
    Write-Host "Starting logging tests..." -ForegroundColor Green

    # Initialize logging
    Initialize-KDELogging -Level $KDELogLevelInfo -LogFilePath $tempLogFile -LogToFile $true

    # Test logging at different levels
    Write-Host "`nTesting logging at different levels..." -ForegroundColor Green

    # Test with Error level
    Test-LoggingLevels -CurrentLogLevel $KDELogLevelError

    # Test with Warning level
    Test-LoggingLevels -CurrentLogLevel $KDELogLevelWarning

    # Test with Info level
    Test-LoggingLevels -CurrentLogLevel $KDELogLevelInfo

    # Test with Debug level
    Test-LoggingLevels -CurrentLogLevel $KDELogLevelDebug

    # Test with Verbose level
    Test-LoggingLevels -CurrentLogLevel $KDELogLevelVerbose

    # Test log message formatting
    Write-Host "`nTesting log message formatting..." -ForegroundColor Green
    Test-LogMessageFormatting

    # Test log file rotation
    Write-Host "`nTesting log file rotation..." -ForegroundColor Green
    Test-LogFileRotation

    Write-Host "`nAll tests completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error during testing: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up
    if (Test-Path -Path $tempLogFile) {
        Remove-Item -Path $tempLogFile -Force
    }
}
