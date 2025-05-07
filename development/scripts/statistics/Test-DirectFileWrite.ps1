# Test-DirectFileWrite.ps1
# Simple script to test writing directly to a file

# Create a temporary log file
$tempLogFile = Join-Path -Path $env:TEMP -ChildPath "DirectFileWriteTest_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Using log file: $tempLogFile" -ForegroundColor Yellow

# Create the log file
New-Item -Path $tempLogFile -ItemType File -Force | Out-Null

# Write some messages directly to the file
Write-Host "`nWriting messages directly to the file..." -ForegroundColor Green
Add-Content -Path $tempLogFile -Value "This is a test message" -Encoding UTF8
Add-Content -Path $tempLogFile -Value "This is another test message" -Encoding UTF8
Add-Content -Path $tempLogFile -Value "This is a third test message" -Encoding UTF8

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
