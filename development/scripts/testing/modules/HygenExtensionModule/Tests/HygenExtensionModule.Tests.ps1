#Requires -Modules Pester
<#
.SYNOPSIS
    Tests pour le module HygenExtensionModule.
.DESCRIPTION
    Ce script contient des tests Pester pour le module HygenExtensionModule.
.EXAMPLE
    Invoke-Pester -Path ".\HygenExtensionModule.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-13
#>

BeforeAll {
    # Importer le module à tester
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleName = Split-Path -Leaf $ModuleRoot
    $ModulePath = Join-Path -Path $ModuleRoot -ChildPath "$ModuleName.psm1"

    # Importer le module avec force pour s'assurer d'avoir la dernière version
    Import-Module -Name $ModulePath -Force
}

Describe "HygenExtensionModule Module Tests" {
    Context "Module Loading" {
        It "Should import the module without errors" {
            { Import-Module -Name $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "Should have exported functions" {
            $ExportedFunctions = Get-Command -Module HygenExtensionModule -CommandType Function
            $ExportedFunctions | Should -Not -BeNullOrEmpty
        }
    }

    Context "Module Configuration" {
        It "Should have a valid configuration file" {
            $ConfigPath = Join-Path -Path $ModuleRoot -ChildPath "config\$ModuleName.config.json"
            Test-Path -Path $ConfigPath | Should -Be $true
            { Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context "Module Functions" {
        # Ajouter des tests pour chaque fonction publique du module
        # Exemple:
        # It "Get-Something should return expected results" {
        #     Get-Something -Parameter "Value" | Should -Be "ExpectedResult"
        # }
    }
}

AfterAll {
    # Nettoyer après les tests
    Remove-Module -Name HygenExtensionModule -ErrorAction SilentlyContinue
}

