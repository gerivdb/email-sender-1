#
# Uninstall-Module.ps1
#
# Script to uninstall the RoadmapParser module
#

# Get the module name
$moduleName = "RoadmapParser"

# Get the user's modules directory
$userModulesPath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "WindowsPowerShell\Modules"

# Get the module directory in the user's modules directory
$moduleInstallPath = Join-Path -Path $userModulesPath -ChildPath $moduleName

# Remove the module from the current session
if (Get-Module -Name $moduleName) {
    Remove-Module -Name $moduleName -Force
    Write-Host "Module '$moduleName' removed from the current session" -ForegroundColor Green
}

# Remove the module directory from the user's modules directory
if (Test-Path -Path $moduleInstallPath) {
    Remove-Item -Path $moduleInstallPath -Recurse -Force
    Write-Host "Module '$moduleName' uninstalled from: $moduleInstallPath" -ForegroundColor Green
} else {
    Write-Host "Module '$moduleName' is not installed at: $moduleInstallPath" -ForegroundColor Yellow
}
