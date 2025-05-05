#Requires -Version 5.1

<#
.SYNOPSIS
    Tests unitaires pour le module FunctionDependencyAnalyzer.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module FunctionDependencyAnalyzer.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer les modules Ã  tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath "FunctionCallParser.psm1"
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath "ImportedFunctionDetector.psm1"
$functionDependencyAnalyzerPath = Join-Path -Path $moduleRoot -ChildPath "FunctionDependencyAnalyzer.psm1"

if (-not (Test-Path -Path $functionCallParserPath)) {
    throw "Le module FunctionCallParser.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $functionCallParserPath"
}

if (-not (Test-Path -Path $importedFunctionDetectorPath)) {
    throw "Le module ImportedFunctionDetector.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $importedFunctionDetectorPath"
}

if (-not (Test-Path -Path $functionDependencyAnalyzerPath)) {
    throw "Le module FunctionDependencyAnalyzer.psm1 n'existe pas dans le chemin spÃ©cifiÃ©: $functionDependencyAnalyzerPath"
}

Import-Module -Name $functionCallParserPath -Force
Import-Module -Name $importedFunctionDetectorPath -Force
Import-Module -Name $functionDependencyAnalyzerPath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "FunctionDependencyAnalyzerTests"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$testScript1 = @'
#Requires -Modules Microsoft.PowerShell.Management

<#
.SYNOPSIS
    Script de test 1.
#>

# Importer les modules requis
Import-Module -Name Microsoft.PowerShell.Utility

# DÃ©finir une fonction locale
function Get-LocalData {
    [CmdletBinding()]
    param()

    Write-Output "Local Data"
}

# Appeler des fonctions importÃ©es
Get-Process
Write-Host "Hello, World!"

# Appeler une fonction locale
Get-LocalData

# Appeler une fonction non importÃ©e
Get-Service
'@

$testScript2 = @'
<#
.SYNOPSIS
    Script de test 2.
#>

# DÃ©finir une fonction locale
function Get-CustomData {
    [CmdletBinding()]
    param()

    # Appeler une fonction non importÃ©e
    Get-Date

    # Appeler une autre fonction non importÃ©e
    Get-Random -Minimum 1 -Maximum 100

    Write-Output "Custom Data"
}

# Appeler une fonction locale
Get-CustomData

# Appeler des fonctions non importÃ©es
Get-ChildItem -Path C:\
Test-Path -Path C:\Windows
'@

$testScript3 = @'
<#
.SYNOPSIS
    Script de test 3 avec des cas particuliers.
#>

# Utiliser des alias
gps # Alias de Get-Process
dir # Alias de Get-ChildItem

# Utiliser des appels dynamiques
$command = "Get-Process"
& $command

# Utiliser des appels avec namespace
Microsoft.PowerShell.Management\Get-Process

# Utiliser des mÃ©thodes statiques
[System.IO.Path]::Combine("C:\", "Windows")
[System.Math]::Max(10, 20)

# Utiliser des mÃ©thodes d'instance
$string = "Hello, World"
$string.ToUpper()

# Utiliser des appels via pipeline
Get-Process | Where-Object { $_.CPU -gt 10 }

# Utiliser des appels via script block
& { Get-Process }
'@

# Ã‰crire les fichiers de test
$testScript1Path = Join-Path -Path $testDir -ChildPath "TestScript1.ps1"
$testScript2Path = Join-Path -Path $testDir -ChildPath "TestScript2.ps1"
$testScript3Path = Join-Path -Path $testDir -ChildPath "TestScript3.ps1"

$testScript1 | Out-File -FilePath $testScript1Path -Encoding UTF8
$testScript2 | Out-File -FilePath $testScript2Path -Encoding UTF8
$testScript3 | Out-File -FilePath $testScript3Path -Encoding UTF8

# ExÃ©cuter les tests
Describe "FunctionDependencyAnalyzer" {
    Context "Get-FunctionCalls" {
        It "DÃ©tecte les appels de fonctions dans un script" {
            $functionCalls = Get-FunctionCalls -ScriptPath $testScript1Path
            $functionCalls | Should -Not -BeNullOrEmpty
            $functionCalls.Count | Should -BeGreaterThan 0
            $functionCalls.Name | Should -Contain "Get-Process"
            $functionCalls.Name | Should -Contain "Write-Host"
            $functionCalls.Name | Should -Contain "Get-LocalData"
            $functionCalls.Name | Should -Contain "Get-Service"
        }

        It "DÃ©tecte les appels de fonctions avec des paramÃ¨tres" {
            $functionCalls = Get-FunctionCalls -ScriptPath $testScript2Path
            $functionCalls | Should -Not -BeNullOrEmpty
            $functionCalls.Count | Should -BeGreaterThan 0
            $functionCalls.Name | Should -Contain "Get-Random"
            $functionCalls | Where-Object { $_.Name -eq "Get-Random" } | ForEach-Object {
                $_.Parameters | Should -Not -BeNullOrEmpty
                $_.Parameters.Count | Should -BeGreaterThan 0
                $_.Parameters.Name | Should -Contain "Minimum"
                $_.Parameters.Name | Should -Contain "Maximum"
            }
        }

        It "DÃ©tecte les appels de mÃ©thodes si demandÃ©" {
            $functionCalls = Get-FunctionCalls -ScriptPath $testScript3Path -IncludeMethodCalls
            $functionCalls | Should -Not -BeNullOrEmpty
            $functionCalls.Count | Should -BeGreaterThan 0
            $functionCalls.Type | Should -Contain "Method"
            $functionCalls | Where-Object { $_.Type -eq "Method" } | ForEach-Object {
                $_.Name | Should -Be "ToUpper"
            }
        }

        It "DÃ©tecte les appels de mÃ©thodes statiques si demandÃ©" {
            $functionCalls = Get-FunctionCalls -ScriptPath $testScript3Path -IncludeStaticMethodCalls
            $functionCalls | Should -Not -BeNullOrEmpty
            $functionCalls.Count | Should -BeGreaterThan 0
            $functionCalls.Type | Should -Contain "StaticMethod"
            $functionCalls | Where-Object { $_.Type -eq "StaticMethod" } | ForEach-Object {
                $_.Name | Should -BeIn @("Combine", "Max")
            }
        }
    }

    Context "Get-LocalFunctions" {
        It "DÃ©tecte les fonctions dÃ©finies localement" {
            $localFunctions = Get-LocalFunctions -ScriptPath $testScript1Path
            $localFunctions | Should -Not -BeNullOrEmpty
            $localFunctions.Count | Should -Be 1
            $localFunctions.Name | Should -Contain "Get-LocalData"
        }

        It "DÃ©tecte les fonctions dÃ©finies localement avec des paramÃ¨tres" {
            $localFunctions = Get-LocalFunctions -ScriptContent $testScript2
            $localFunctions | Should -Not -BeNullOrEmpty
            $localFunctions.Count | Should -Be 1
            $localFunctions.Name | Should -Contain "Get-CustomData"
        }
    }

    Context "Get-ImportedModules" {
        It "DÃ©tecte les modules importÃ©s via Import-Module" {
            $importedModules = Get-ImportedModules -ScriptPath $testScript1Path
            $importedModules | Should -Not -BeNullOrEmpty
            $importedModules.Count | Should -Be 1
            $importedModules.Name | Should -Contain "Microsoft.PowerShell.Utility"
        }

        It "DÃ©tecte les modules importÃ©s via #Requires -Modules" {
            $importedModules = Get-ImportedModules -ScriptPath $testScript1Path -IncludeRequiresDirectives
            $importedModules | Should -Not -BeNullOrEmpty
            $importedModules.Count | Should -Be 2
            $importedModules.Name | Should -Contain "Microsoft.PowerShell.Utility"
            $importedModules.Name | Should -Contain "Microsoft.PowerShell.Management"
        }
    }

    Context "Get-NonImportedFunctionCalls" {
        It "DÃ©tecte les appels de fonctions non importÃ©es" {
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptPath $testScript1Path
            $nonImportedFunctionCalls | Should -Not -BeNullOrEmpty
            $nonImportedFunctionCalls.Count | Should -Be 1
            $nonImportedFunctionCalls.Name | Should -Contain "Get-Service"
        }

        It "Ne dÃ©tecte pas les fonctions dÃ©finies localement comme non importÃ©es" {
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptPath $testScript1Path
            $nonImportedFunctionCalls.Name | Should -Not -Contain "Get-LocalData"
        }

        It "Ne dÃ©tecte pas les fonctions importÃ©es comme non importÃ©es" {
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptPath $testScript1Path
            $nonImportedFunctionCalls.Name | Should -Not -Contain "Get-Process"
            $nonImportedFunctionCalls.Name | Should -Not -Contain "Write-Host"
        }

        It "DÃ©tecte plusieurs appels de fonctions non importÃ©es" {
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptPath $testScript2Path
            $nonImportedFunctionCalls | Should -Not -BeNullOrEmpty
            $nonImportedFunctionCalls.Count | Should -BeGreaterThan 1
            $nonImportedFunctionCalls.Name | Should -Contain "Get-Date"
            $nonImportedFunctionCalls.Name | Should -Contain "Get-Random"
            $nonImportedFunctionCalls.Name | Should -Contain "Get-ChildItem"
            $nonImportedFunctionCalls.Name | Should -Contain "Test-Path"
        }
    }

    Context "Resolve-ModulesForFunctions" {
        It "RÃ©sout les modules pour les fonctions" {
            $resolvedModules = Resolve-ModulesForFunctions -FunctionNames @("Get-Process", "Get-Service")
            $resolvedModules | Should -Not -BeNullOrEmpty
            $resolvedModules.Count | Should -BeGreaterThan 0
            $resolvedModules.FunctionName | Should -Contain "Get-Process"
            $resolvedModules.FunctionName | Should -Contain "Get-Service"
            $resolvedModules.ModuleName | Should -Contain "Microsoft.PowerShell.Management"
        }

        It "RÃ©sout les modules pour les fonctions non importÃ©es" {
            $nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptPath $testScript2Path
            $resolvedModules = Resolve-ModulesForFunctions -FunctionNames $nonImportedFunctionCalls.Name
            $resolvedModules | Should -Not -BeNullOrEmpty
            $resolvedModules.Count | Should -BeGreaterThan 0
            $resolvedModules.FunctionName | Should -Contain "Get-Date"
            $resolvedModules.FunctionName | Should -Contain "Get-Random"
            $resolvedModules.FunctionName | Should -Contain "Get-ChildItem"
            $resolvedModules.FunctionName | Should -Contain "Test-Path"
            $resolvedModules.ModuleName | Should -Contain "Microsoft.PowerShell.Utility"
            $resolvedModules.ModuleName | Should -Contain "Microsoft.PowerShell.Management"
        }
    }

    Context "Get-FunctionDependencies" {
        It "Analyse les dÃ©pendances de fonctions" {
            $dependencies = Get-FunctionDependencies -ScriptPath $testScript1Path -ResolveModules
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.ImportedModules | Should -Not -BeNullOrEmpty
            $dependencies.ImportedModules.Count | Should -BeGreaterThan 0
            $dependencies.NonImportedFunctionCalls | Should -Not -BeNullOrEmpty
            $dependencies.NonImportedFunctionCalls.Count | Should -BeGreaterThan 0
            $dependencies.ResolvedModules | Should -Not -BeNullOrEmpty
            $dependencies.ResolvedModules.Count | Should -BeGreaterThan 0
            $dependencies.MissingModules | Should -Not -BeNullOrEmpty
            $dependencies.MissingModules.Count | Should -BeGreaterThan 0
            $dependencies.MissingModules.FunctionName | Should -Contain "Get-Service"
            $dependencies.MissingModules.ResolvedModules | Should -Not -BeNullOrEmpty
            $dependencies.MissingModules.ResolvedModules.ModuleName | Should -Contain "Microsoft.PowerShell.Management"
        }

        It "Analyse les dÃ©pendances de fonctions avec des cas particuliers" {
            $dependencies = Get-FunctionDependencies -ScriptPath $testScript3Path -ResolveModules -IncludeMethodCalls -IncludeStaticMethodCalls
            $dependencies | Should -Not -BeNullOrEmpty
            $dependencies.NonImportedFunctionCalls | Should -Not -BeNullOrEmpty
            $dependencies.NonImportedFunctionCalls.Count | Should -BeGreaterThan 0
            $dependencies.NonImportedFunctionCalls.Name | Should -Contain "Get-Process"
            $dependencies.NonImportedFunctionCalls.Name | Should -Contain "Where-Object"
        }
    }
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force
