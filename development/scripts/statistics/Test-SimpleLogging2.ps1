# Test-SimpleLogging2.ps1
# Simple script to test the simple logging module

# Import the logging module
. .\KernelDensityEstimateSimpleLogging.ps1

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "SimpleLoggingTest2_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Initialize logging
Initialize-Logging -Level $script:LogLevelVerbose -LogFilePath $tempLogFile -LogToFile $true -LogToConsole $true

# Write some log messages
Write-Host "`nWriting log messages..." -ForegroundColor Green
Write-ErrorLog "This is an error message"
Write-WarningLog "This is a warning message"
Write-InfoLog "This is an info message"
Write-DebugLog "This is a debug message"
Write-VerboseLog "This is a verbose message"

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
