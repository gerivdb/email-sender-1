#
# Install-Module.ps1
#
# Script to install the RoadmapParser module
#

# Get the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the module name
$moduleName = "RoadmapParser"

# Get the module path
$modulePath = $scriptPath

# Get the user's modules directory
$userModulesPath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "WindowsPowerShell\Modules"

# Create the user's modules directory if it doesn't exist
if (-not (Test-Path -Path $userModulesPath)) {
    New-Item -Path $userModulesPath -ItemType Directory -Force | Out-Null
}

# Create the module directory in the user's modules directory
$moduleInstallPath = Join-Path -Path $userModulesPath -ChildPath $moduleName
if (-not (Test-Path -Path $moduleInstallPath)) {
    New-Item -Path $moduleInstallPath -ItemType Directory -Force | Out-Null
}

# Copy the module files to the user's modules directory
Copy-Item -Path "$modulePath\*" -Destination $moduleInstallPath -Recurse -Force

# Import the module
Import-Module -Name $moduleInstallPath\$moduleName.psd1 -Force

# Get the exported commands
$exportedCommands = Get-Command -Module $moduleName

# Display the exported commands
Write-Host "Exported commands:" -ForegroundColor Cyan
$exportedCommands | Format-Table -Property Name, CommandType, Version

# Test if the module is loaded
if (Get-Module -Name $moduleName) {
    Write-Host "Module '$moduleName' is installed and loaded" -ForegroundColor Green
} else {
    Write-Host "Module '$moduleName' is not loaded" -ForegroundColor Red
}

Write-Host "Module '$moduleName' is installed at: $moduleInstallPath" -ForegroundColor Green
