# Test-SimpleLogging.ps1
# Simple script to test the logging module

# Import the logging module
Import-Module .\KernelDensityEstimateLogging.psm1 -Force

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "SimpleLoggingTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Initialize logging
Initialize-KDELogging -Level $KDELogLevelVerbose -LogFilePath $tempLogFile -LogToFile $true -LogToConsole $true

# Write some log messages
Write-Host "`nWriting log messages..." -ForegroundColor Green
Write-KDEError "This is an error message"
Write-KDEWarning "This is a warning message"
Write-KDEInfo "This is an info message"
Write-KDEDebug "This is a debug message"
Write-KDEVerbose "This is a verbose message"

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
