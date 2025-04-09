Write-Host "Test script executed successfully"
Write-Host "Current directory: $(Get-Location)"
Write-Host "Files in current directory:"
Get-ChildItem | Format-Table Name, Length
