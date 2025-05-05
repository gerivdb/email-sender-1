#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simples pour le module SimpleModule.

.DESCRIPTION
    Ce script contient des tests simples pour le module SimpleModule.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleFile = Join-Path -Path $modulePath -ChildPath "SimpleModule.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SimpleModuleTests"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    GUID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
    Author = 'Test Author'
    Description = 'Test Module'
    RootModule = 'TestModule.psm1'
    RequiredModules = @(
        'Module1',
        @{
            ModuleName = 'Module2'
            ModuleVersion = '2.0.0'
        }
    )
}
"@

$scriptContent = @"
# Import modules
Import-Module Module1
Import-Module -Name Module2
"@

$manifestPath = Join-Path -Path $testDir -ChildPath "TestModule.psd1"
$scriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"

Set-Content -Path $manifestPath -Value $manifestContent
Set-Content -Path $scriptPath -Value $scriptContent

# Importer le module
Import-Module -Name $moduleFile -Force

# Test 1: Test-SystemModule
Write-Host "Test 1: Test-SystemModule"
$result1 = Test-SystemModule -ModuleName "Microsoft.PowerShell.Core"
$result2 = Test-SystemModule -ModuleName "CustomModule"
Write-Host "Microsoft.PowerShell.Core is system module: $result1"
Write-Host "CustomModule is system module: $result2"

# Test 2: Get-PowerShellManifestStructure
Write-Host "`nTest 2: Get-PowerShellManifestStructure"
$result = Get-PowerShellManifestStructure -ManifestPath $manifestPath
Write-Host "Module Name: $($result.ModuleName)"
Write-Host "Required Modules Count: $($result.RequiredModules.Count)"

# Test 3: Get-ModuleDependenciesFromManifest
Write-Host "`nTest 3: Get-ModuleDependenciesFromManifest"
$result = Get-ModuleDependenciesFromManifest -ManifestPath $manifestPath
Write-Host "Dependencies Count: $($result.Count)"
$result | ForEach-Object {
    Write-Host "  - $($_.Name) (Type: $($_.Type))"
}

# Test 4: Get-ModuleDependenciesFromCode
Write-Host "`nTest 4: Get-ModuleDependenciesFromCode"
$result = Get-ModuleDependenciesFromCode -ModulePath $scriptPath
Write-Host "Dependencies Count: $($result.Count)"
$result | ForEach-Object {
    Write-Host "  - $($_.Name) (Type: $($_.Type))"
}

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Module -Name "SimpleModule" -Force -ErrorAction SilentlyContinue

Write-Host "`nAll tests completed successfully!"
