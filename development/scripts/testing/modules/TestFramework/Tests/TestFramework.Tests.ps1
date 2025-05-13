#Requires -Modules Pester
<#
.SYNOPSIS
    Tests pour le module TestFramework.
.DESCRIPTION
    Ce script contient des tests Pester pour le module TestFramework.
.EXAMPLE
    Invoke-Pester -Path ".\TestFramework.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

BeforeAll {
    # Importer le module à tester
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleName = Split-Path -Leaf $ModuleRoot
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath "$ModuleName.psm1"

    # Importer le module avec force pour s'assurer d'avoir la dernière version
    Import-Module -Name $ModulePath -Force
}

Describe "TestFramework Module Tests" {
    Context "Module Loading" {
        It "Should import the module without errors" {
            { Import-Module -Name $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should have exported functions" {
            $ExportedFunctions = Get-Command -Module TestFramework -CommandType Function
            $ExportedFunctions | Should -Not -BeNullOrEmpty
        }

        It "Should export the Invoke-TestSetup function" {
            Get-Command -Name Invoke-TestSetup -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export the New-TestEnvironment function" {
            Get-Command -Name New-TestEnvironment -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export the Invoke-TestCleanup function" {
            Get-Command -Name Invoke-TestCleanup -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export the New-TestMock function" {
            Get-Command -Name New-TestMock -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export the New-TestData function" {
            Get-Command -Name New-TestData -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should export the Test-FunctionAvailability function" {
            Get-Command -Name Test-FunctionAvailability -Module TestFramework -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Invoke-TestSetup Tests" {
        It "Should return an object with module information" {
            # Créer un module temporaire pour les tests
            $tempModulePath = Join-Path -Path $TestDrive -ChildPath "TestModule.psm1"
            "function Test-Function { return 'Test' }" | Out-File -FilePath $tempModulePath -Encoding utf8

            # Tester la fonction
            $result = Invoke-TestSetup -ModuleName "TestModule" -ModulePath $tempModulePath
            $result | Should -Not -BeNullOrEmpty
            $result.ModuleName | Should -Be "TestModule"
            $result.ModulePath | Should -Be $tempModulePath
            $result.Imported | Should -Be $true
        }
    }

    Context "New-TestEnvironment Tests" {
        It "Should create a test environment with files and folders" {
            # Tester la fonction
            $env = New-TestEnvironment -TestName "TestEnv" -Files @{
                "test.txt" = "Test content"
                "subfolder/test.json" = '{"test": "value"}'
            } -Folders @("folder1", "folder2")

            # Vérifier que l'environnement a été créé
            $env | Should -Not -BeNullOrEmpty
            $env.Path | Should -Not -BeNullOrEmpty
            Test-Path -Path $env.Path | Should -Be $true

            # Vérifier que les fichiers ont été créés
            $testFilePath = Join-Path -Path $env.Path -ChildPath "test.txt"
            Test-Path -Path $testFilePath | Should -Be $true
            Get-Content -Path $testFilePath | Should -Be "Test content"

            $jsonFilePath = Join-Path -Path $env.Path -ChildPath "subfolder/test.json"
            Test-Path -Path $jsonFilePath | Should -Be $true
            Get-Content -Path $jsonFilePath | Should -Be '{"test": "value"}'

            # Vérifier que les dossiers ont été créés
            $folder1Path = Join-Path -Path $env.Path -ChildPath "folder1"
            Test-Path -Path $folder1Path | Should -Be $true

            $folder2Path = Join-Path -Path $env.Path -ChildPath "folder2"
            Test-Path -Path $folder2Path | Should -Be $true

            # Nettoyer l'environnement
            & $env.Cleanup
            Test-Path -Path $env.Path | Should -Be $false
        }
    }

    Context "New-TestData Tests" {
        It "Should generate a string of the specified length" {
            $result = New-TestData -Type String -Length 10
            $result | Should -BeOfType [string]
            $result.Length | Should -Be 10
        }

        It "Should generate a number in the specified range" {
            $result = New-TestData -Type Number -Min 1 -Max 10
            $result | Should -BeOfType [int]
            $result | Should -BeGreaterOrEqual 1
            $result | Should -BeLessOrEqual 10
        }

        It "Should generate a boolean value" {
            $result = New-TestData -Type Boolean
            $result | Should -BeOfType [bool]
        }

        It "Should generate an array of the specified count" {
            $result = New-TestData -Type Array -Count 5
            $result | Should -BeOfType [array]
            $result.Count | Should -Be 5
        }

        It "Should generate an object with the specified properties" {
            $result = New-TestData -Type Object -Properties @{
                Id = { 1 }
                Name = { "Test" }
            }
            $result | Should -BeOfType [PSCustomObject]
            $result.Id | Should -Be 1
            $result.Name | Should -Be "Test"
        }

        It "Should generate JSON data" {
            $result = New-TestData -Type Json
            $result | Should -BeOfType [string]
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Should generate XML data" {
            $result = New-TestData -Type Xml
            $result | Should -BeOfType [string]
            $result | Should -Match "<\?xml"
        }

        It "Should generate CSV data" {
            $result = New-TestData -Type Csv
            $result | Should -BeOfType [string]
            $result | Should -Match "Id,Name,Value"
        }

        It "Should use a custom generator if provided" {
            $result = New-TestData -Type String -CustomGenerator { "CustomValue" }
            $result | Should -Be "CustomValue"
        }
    }

    Context "Test-FunctionAvailability Tests" {
        It "Should return true for available functions" {
            $result = Test-FunctionAvailability -FunctionName "Get-Command"
            $result["Get-Command"].Available | Should -Be $true
            $result["Get-Command"].Error | Should -BeNullOrEmpty
        }

        It "Should return false for unavailable functions" {
            $result = Test-FunctionAvailability -FunctionName "Get-NonExistentFunction"
            $result["Get-NonExistentFunction"].Available | Should -Be $false
            $result["Get-NonExistentFunction"].Error | Should -Not -BeNullOrEmpty
        }

        It "Should check multiple functions" {
            $result = Test-FunctionAvailability -FunctionName "Get-Command", "Get-NonExistentFunction"
            $result["Get-Command"].Available | Should -Be $true
            $result["Get-NonExistentFunction"].Available | Should -Be $false
        }

        It "Should throw an error when ThrowOnError is specified" {
            { Test-FunctionAvailability -FunctionName "Get-NonExistentFunction" -ThrowOnError } | Should -Throw
        }
    }

    Context "New-TestMock Tests" {
        It "Should create a mock for a command" {
            # Créer un mock
            $mock = New-TestMock -CommandName "Get-Content" -MockScript { "Mocked content" }
            
            # Vérifier que le mock a été créé
            $mock | Should -Not -BeNullOrEmpty
            $mock.CommandName | Should -Be "Get-Content"
            
            # Vérifier que le mock fonctionne
            $result = Get-Content -Path "non-existent-file.txt"
            $result | Should -Be "Mocked content"
        }

        It "Should create a mock with a parameter filter" {
            # Créer un mock avec un filtre
            $mock = New-TestMock -CommandName "Get-Content" -ParameterFilter { $Path -eq "test.txt" } -MockScript { "Mocked test.txt" }
            
            # Vérifier que le mock a été créé
            $mock | Should -Not -BeNullOrEmpty
            $mock.CommandName | Should -Be "Get-Content"
            
            # Vérifier que le mock fonctionne avec le filtre
            $result = Get-Content -Path "test.txt"
            $result | Should -Be "Mocked test.txt"
            
            # Vérifier que le mock précédent fonctionne toujours pour les autres chemins
            $result = Get-Content -Path "other-file.txt"
            $result | Should -Be "Mocked content"
        }
    }
}

AfterAll {
    # Nettoyer après les tests
    Remove-Module -Name TestFramework -ErrorAction SilentlyContinue
}
