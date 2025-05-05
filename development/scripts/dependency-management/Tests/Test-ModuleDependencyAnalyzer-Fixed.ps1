#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyAnalyzer-Fixed.

.DESCRIPTION
    Ce script contient des tests unitaires pour le module ModuleDependencyAnalyzer-Fixed,
    en utilisant le framework Pester.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
$moduleName = "ModuleDependencyAnalyzer-Fixed"
$moduleFile = Join-Path -Path $modulePath -ChildPath "$moduleName.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyAnalyzerTests"
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
        },
        @{
            ModuleName = 'Module3'
            RequiredVersion = '3.0.0'
            GUID = 'aaaaaaaa-bbbb-cccc-dddd-ffffffffffff'
        }
    )
    NestedModules = @(
        'NestedModule1.psm1',
        @{
            ModuleName = 'NestedModule2'
            ModuleVersion = '2.0.0'
        }
    )
}
"@

$scriptContent = @"
# Import modules
Import-Module Module1
Import-Module -Name Module2
Import-Module -Name "Module3"
Import-Module -Name 'Module4'
Import-Module -Path "C:\Path\To\Module5.psd1"

# Using module
using module Module6
using module "C:\Path\To\Module7.psm1"
"@

$manifestPath = Join-Path -Path $testDir -ChildPath "TestModule.psd1"
$scriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"

Set-Content -Path $manifestPath -Value $manifestContent
Set-Content -Path $scriptPath -Value $scriptContent

# DÃ©finir les tests Pester
Describe "ModuleDependencyAnalyzer-Fixed Tests" {
    BeforeAll {
        # Importer le module Ã  tester
        Import-Module -Name $moduleFile -Force
    }

    Context "Test-SystemModule" {
        It "Should identify system modules" {
            Test-SystemModule -ModuleName "Microsoft.PowerShell.Core" | Should -Be $true
            Test-SystemModule -ModuleName "Microsoft.PowerShell.Management" | Should -Be $true
            Test-SystemModule -ModuleName "CustomModule" | Should -Be $false
        }
    }

    Context "Get-PowerShellManifestStructure" {
        It "Should return a valid manifest structure" {
            $result = Get-PowerShellManifestStructure -ManifestPath $manifestPath
            $result | Should -Not -BeNullOrEmpty
            $result.ModuleName | Should -Be "TestModule"
            $result.RequiredModules.Count | Should -Be 3
            $result.NestedModules.Count | Should -Be 2
        }

        It "Should handle non-existent files" {
            $result = Get-PowerShellManifestStructure -ManifestPath "NonExistentFile.psd1" -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Get-ModuleDependenciesFromManifest" {
        It "Should extract dependencies from a manifest" {
            $result = Get-ModuleDependenciesFromManifest -ManifestPath $manifestPath
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Where-Object { $_.Name -eq "Module1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module3" } | Should -Not -BeNullOrEmpty
        }

        It "Should handle non-existent files" {
            $result = Get-ModuleDependenciesFromManifest -ManifestPath "NonExistentFile.psd1"
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
    }

    Context "Get-ModuleDependenciesFromCode" {
        It "Should extract dependencies from code" {
            $result = Get-ModuleDependenciesFromCode -ModulePath $scriptPath
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result | Where-Object { $_.Name -eq "Module1" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module2" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module3" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module4" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module5" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module6" } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Name -eq "Module7" } | Should -Not -BeNullOrEmpty
        }

        It "Should handle non-existent files" {
            $result = Get-ModuleDependenciesFromCode -ModulePath "NonExistentFile.ps1"
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
