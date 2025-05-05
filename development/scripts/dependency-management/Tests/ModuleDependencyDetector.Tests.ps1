#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module ModuleDependencyDetector.

.DESCRIPTION
    Ce script contient les tests unitaires pour le module ModuleDependencyDetector,
    vÃ©rifiant la dÃ©tection des instructions Import-Module et using module dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-16
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ModuleDependencyDetectorTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Describe "ModuleDependencyDetector" {
    BeforeEach {
        # CrÃ©er des fichiers de test
        $testScriptPath1 = Join-Path -Path $testDir -ChildPath "TestImportModule.ps1"
        $testScriptContent1 = @'
# Test d'importation de modules avec Import-Module
Import-Module PSScriptAnalyzer
Import-Module -Name Pester
Import-Module ..\Modules\MyModule.psm1
Import-Module C:\Modules\AnotherModule.psm1
Import-Module PSScriptAnalyzer -RequiredVersion 1.18.0
Import-Module PSScriptAnalyzer -MinimumVersion 1.18.0 -MaximumVersion 2.0.0
Import-Module PSScriptAnalyzer -Global -Force -Prefix "PSA"
$moduleName = "PSScriptAnalyzer"
Import-Module $moduleName
if ($true) {
    Import-Module PSScriptAnalyzer
}
function Test-Function {
    Import-Module PSScriptAnalyzer
}
'@
        Set-Content -Path $testScriptPath1 -Value $testScriptContent1

        $testScriptPath2 = Join-Path -Path $testDir -ChildPath "TestUsingModule.ps1"
        $testScriptContent2 = @'
# Test d'importation de modules avec using module
using module PSScriptAnalyzer
using module ..\Modules\MyModule.psm1
using module C:\Modules\AnotherModule.psm1

# MÃ©lange avec Import-Module
Import-Module Pester
'@
        Set-Content -Path $testScriptPath2 -Value $testScriptContent2

        $testScriptPath3 = Join-Path -Path $testDir -ChildPath "TestMixed.ps1"
        $testScriptContent3 = @'
# Test d'importation de modules avec using module et Import-Module
using module PSScriptAnalyzer
using module ..\Modules\MyModule.psm1

# Import-Module
Import-Module Pester
Import-Module ..\Modules\AnotherModule.psm1
'@
        Set-Content -Path $testScriptPath3 -Value $testScriptContent3

        # CrÃ©er un module de test
        $testModulePath = Join-Path -Path $testDir -ChildPath "Modules"
        if (-not (Test-Path -Path $testModulePath)) {
            New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
        }
        $testModuleFile = Join-Path -Path $testModulePath -ChildPath "TestModule.psm1"
        $testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
        Set-Content -Path $testModuleFile -Value $testModuleContent
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Find-ImportModuleInstruction" {
        It "DÃ©tecte les instructions Import-Module dans un fichier" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath1
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result[0].Name | Should -Be "PSScriptAnalyzer"
        }

        It "DÃ©tecte les instructions using module dans un fichier" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath2
            $result | Should -Not -BeNullOrEmpty
            $usingModules = @($result | Where-Object { $_.ImportType -eq "using module" })
            $usingModules | Should -Not -BeNullOrEmpty
            $usingModules[0].Name | Should -Be "PSScriptAnalyzer"
        }

        It "DÃ©tecte les instructions Import-Module et using module dans un fichier" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath3
            $result | Should -Not -BeNullOrEmpty
            $importModules = @($result | Where-Object { $_.ImportType -eq "Import-Module" })
            $usingModules = @($result | Where-Object { $_.ImportType -eq "using module" })
            $importModules | Should -Not -BeNullOrEmpty
            $usingModules | Should -Not -BeNullOrEmpty
        }

        It "DÃ©tecte les instructions Import-Module avec paramÃ¨tres nommÃ©s" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath1
            $namedModule = $result | Where-Object { $_.ArgumentType -eq "Named" }
            $namedModule | Should -Not -BeNullOrEmpty
            $namedModule[0].Name | Should -Be "Pester"
        }

        It "DÃ©tecte les instructions Import-Module avec chemins relatifs" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath1
            $pathModule = $result | Where-Object { $_.Path -like "*MyModule.psm1" }
            $pathModule | Should -Not -BeNullOrEmpty
            $pathModule[0].Name | Should -Be "MyModule"
        }

        It "DÃ©tecte les instructions Import-Module avec versions" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath1
            $versionModule = $result | Where-Object { $_.Version -ne $null }
            $versionModule | Should -Not -BeNullOrEmpty
            $versionModule[0].Name | Should -Be "PSScriptAnalyzer"
        }

        It "DÃ©tecte les instructions Import-Module avec paramÃ¨tres supplÃ©mentaires" {
            $result = Find-ImportModuleInstruction -FilePath $testScriptPath1
            $globalModule = $result | Where-Object { $_.Global -eq $true -and $_.ImportType -eq "Import-Module" }
            $globalModule | Should -Not -BeNullOrEmpty
            $globalModule[0].Name | Should -Be "PSScriptAnalyzer"
        }

        It "GÃ¨re correctement un contenu de script" {
            $scriptContent = @'
# Test d'importation de modules
Import-Module PSScriptAnalyzer
using module Pester
'@
            $result = Find-ImportModuleInstruction -ScriptContent $scriptContent
            $result | Should -Not -BeNullOrEmpty
            $importModules = @($result | Where-Object { $_.ImportType -eq "Import-Module" })
            $usingModules = @($result | Where-Object { $_.ImportType -eq "using module" })
            $importModules | Should -Not -BeNullOrEmpty
            $usingModules | Should -Not -BeNullOrEmpty
            $importModules[0].Name | Should -Be "PSScriptAnalyzer"
            $usingModules[0].Name | Should -Be "Pester"
        }
    }

    Context "Resolve-ModulePath" {
        It "RÃ©sout le chemin d'un module par nom" {
            # CrÃ©er un module de test
            $testModulePath = Join-Path -Path $testDir -ChildPath "TestResolveModule.psm1"
            $testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
            Set-Content -Path $testModulePath -Value $testModuleContent

            # Tester la rÃ©solution
            $result = Resolve-ModulePath -Name "TestResolveModule" -BaseDirectory $testDir
            $result | Should -Not -BeNullOrEmpty
        }

        It "RÃ©sout le chemin d'un module par chemin relatif" {
            # CrÃ©er un module de test dans un sous-rÃ©pertoire
            $testSubDir = Join-Path -Path $testDir -ChildPath "SubDir"
            if (-not (Test-Path -Path $testSubDir)) {
                New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
            }
            $testModulePath = Join-Path -Path $testSubDir -ChildPath "TestRelativeModule.psm1"
            $testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
            Set-Content -Path $testModulePath -Value $testModuleContent

            # Tester la rÃ©solution
            $relativePath = "SubDir\TestRelativeModule.psm1"
            $result = Resolve-ModulePath -Path $relativePath -BaseDirectory $testDir
            $result | Should -Not -BeNullOrEmpty
        }

        It "RÃ©sout le chemin d'un module par chemin absolu" {
            # CrÃ©er un module de test
            $testModulePath = Join-Path -Path $testDir -ChildPath "TestAbsoluteModule.psm1"
            $testModuleContent = @'
function Test-Function {
    [CmdletBinding()]
    param()

    Write-Output "Test function"
}

Export-ModuleMember -Function Test-Function
'@
            Set-Content -Path $testModulePath -Value $testModuleContent

            # Tester la rÃ©solution
            $result = Resolve-ModulePath -Path $testModulePath -BaseDirectory $testDir
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
