<#
.SYNOPSIS
    Tests simples pour le gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script contient des tests simples pour vÃ©rifier le bon fonctionnement du gestionnaire intÃ©grÃ©.
    Ces tests vÃ©rifient que le gestionnaire intÃ©grÃ© existe, qu'il peut Ãªtre exÃ©cutÃ© et qu'il peut afficher la liste des modes et des workflows.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# DÃ©finir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# DÃ©finir les tests
Describe "Tests simples pour le gestionnaire intÃ©grÃ©" {
    Context "VÃ©rification de l'existence du gestionnaire intÃ©grÃ©" {
        It "Le gestionnaire intÃ©grÃ© devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
    }
    
    Context "VÃ©rification de l'exÃ©cution du gestionnaire intÃ©grÃ©" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $integratedManagerPath -ListModes -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "VÃ©rification de l'affichage des modes" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir afficher la liste des modes" {
            $output = & $integratedManagerPath -ListModes
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "VÃ©rification de l'affichage des workflows" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir afficher la liste des workflows" {
            $output = & $integratedManagerPath -ListWorkflows
            $output | Should -Not -BeNullOrEmpty
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
