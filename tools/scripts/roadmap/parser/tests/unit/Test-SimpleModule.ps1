# Test-SimpleModule.ps1
# Script pour tester l'importation d'un module simple

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleModule.psm1"
Write-Host "Module path: $modulePath"
Write-Host "Module exists: $(Test-Path -Path $modulePath)"

try {
    Import-Module $modulePath -Force -Verbose
    Write-Host "Module imported successfully."
    
    Test-SimpleFunction
}
catch {
    Write-Host "Error importing module: $_"
    Write-Host $_.ScriptStackTrace
}
