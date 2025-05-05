# Test du module minimal
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "MinimalModule.psm1"
Write-Output "Module path: $modulePath"

Import-Module $modulePath -Force
Get-HelloWorld
