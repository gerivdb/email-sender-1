# Test-VerySimpleLogging.ps1
# Very simple script to test logging

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "VerySimpleLoggingTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Function to write a log message
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Level = "Info"
    )
    
    # Format the log message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console
    switch ($Level) {
        "Error" {
            Write-Host $formattedMessage -ForegroundColor Red
        }
        "Warning" {
            Write-Host $formattedMessage -ForegroundColor Yellow
        }
        "Info" {
            Write-Host $formattedMessage -ForegroundColor Green
        }
        "Debug" {
            Write-Host $formattedMessage -ForegroundColor Cyan
        }
        "Verbose" {
            Write-Host $formattedMessage -ForegroundColor Gray
        }
        default {
            Write-Host $formattedMessage
        }
    }
    
    # Write to file
    try {
        Add-Content -Path $tempLogFile -Value $formattedMessage -Encoding UTF8
    } catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Write some log messages
Write-Host "`nWriting log messages..." -ForegroundColor Green
Write-Log -Message "This is an error message" -Level "Error"
Write-Log -Message "This is a warning message" -Level "Warning"
Write-Log -Message "This is an info message" -Level "Info"
Write-Log -Message "This is a debug message" -Level "Debug"
Write-Log -Message "This is a verbose message" -Level "Verbose"

# Check the log file
Write-Host "`nChecking log file..." -ForegroundColor Green
if (Test-Path -Path $tempLogFile) {
    $logContent = Get-Content -Path $tempLogFile
    Write-Host "Log file content ($($logContent.Count) lines):" -ForegroundColor Yellow
    $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "Log file not found!" -ForegroundColor Red
}

# Clean up
Write-Host "`nCleaning up..." -ForegroundColor Green
Remove-Item -Path $tempLogFile -Force
