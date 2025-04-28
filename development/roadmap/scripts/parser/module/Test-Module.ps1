#
# Test-Module.ps1
#
# Script to test the RoadmapParser module
#

# Get the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import the module
Import-Module -Name $scriptPath\RoadmapParser.psd1 -Force -Verbose

# Get the exported commands
$exportedCommands = Get-Command -Module RoadmapParser

# Display the exported commands
Write-Host "Exported commands:" -ForegroundColor Cyan
$exportedCommands | Format-Table -Property Name, CommandType, Version

# Test if the module is loaded
if (Get-Module -Name RoadmapParser) {
    Write-Host "Module 'RoadmapParser' is loaded" -ForegroundColor Green
} else {
    Write-Host "Module 'RoadmapParser' is not loaded" -ForegroundColor Red
}

# Remove the module
Remove-Module -Name RoadmapParser -Force

# Test if the module is removed
if (-not (Get-Module -Name RoadmapParser)) {
    Write-Host "Module 'RoadmapParser' is removed" -ForegroundColor Green
} else {
    Write-Host "Module 'RoadmapParser' is not removed" -ForegroundColor Red
}
