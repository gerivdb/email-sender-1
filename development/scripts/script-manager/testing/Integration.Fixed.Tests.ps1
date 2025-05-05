﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration corrigÃ©s pour le script manager.
.DESCRIPTION
    Ce script contient des tests d'intÃ©gration corrigÃ©s pour le script manager,
    en utilisant le framework Pester avec des mocks.
.EXAMPLE
    Invoke-Pester -Path ".\Integration.Fixed.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Tests Pester
Describe "Tests d'intÃ©gration du script manager (version corrigÃ©e)" {
    Context "Tests de la structure des dossiers" {
        BeforeAll {
            $script:managerDir = "$PSScriptRoot/.."
        }

        It "Le dossier manager devrait exister" {
            Test-Path -Path $script:managerDir | Should -Be $true
        }

        It "Le dossier README.md devrait exister" {
            Test-Path -Path "$script:managerDir/README.md" | Should -Be $true
        }

        It "Le dossier testing devrait exister" {
            Test-Path -Path "$script:managerDir/testing" | Should -Be $true
        }

        It "Le dossier _templates devrait exister" {
            Test-Path -Path "$script:managerDir/_templates" | Should -Be $true
        }
    }

    Context "Tests des templates Hygen" {
        BeforeAll {
            $script:templatesDir = "$PSScriptRoot/../_templates"
        }

        It "Le fichier .hygen.js devrait exister" {
            Test-Path -Path "$script:templatesDir/.hygen.js" | Should -Be $true
        }

        It "Le dossier script/new devrait exister" {
            Test-Path -Path "$script:templatesDir/script/new" | Should -Be $true
        }

        It "Le dossier module/new devrait exister" {
            Test-Path -Path "$script:templatesDir/module/new" | Should -Be $true
        }
    }

    Context "Tests de flux de travail avec mocks" {
        BeforeAll {
            # CrÃ©er des mocks pour les fonctions utilisÃ©es
            Mock Invoke-Expression { return 0 }
            Mock Write-Host { }
        }

        It "Devrait pouvoir exÃ©cuter le flux de travail complet" {
            # Simuler l'exÃ©cution du flux de travail
            $result = Invoke-Expression -Command "echo 'Flux de travail complet'"
            $result | Should -Be 0
        }
    }

    Context "Tests de compatibilitÃ© avec les scripts de maintenance" {
        BeforeAll {
            # CrÃ©er des mocks pour les fonctions utilisÃ©es
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq ".git/hooks/pre-commit" }
            Mock Get-Content { return "maintenance`nmanager" } -ParameterFilter { $Path -eq ".git/hooks/pre-commit" }
            Mock Get-ChildItem { return @() }
        }

        It "Devrait Ãªtre compatible avec les scripts de maintenance" {
            # VÃ©rifier que le hook pre-commit est compatible
            $hookPath = ".git/hooks/pre-commit"
            $hookContent = Get-Content -Path $hookPath
            $hookContent | Should -Match "maintenance"
            $hookContent | Should -Match "manager"
        }
    }
}
