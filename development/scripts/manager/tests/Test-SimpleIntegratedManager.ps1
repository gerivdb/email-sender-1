<#
.SYNOPSIS
    Tests simples pour le gestionnaire intégré.

.DESCRIPTION
    Ce script contient des tests simples pour vérifier le bon fonctionnement du gestionnaire intégré.
    Ces tests vérifient que le gestionnaire intégré existe, qu'il peut être exécuté et qu'il peut afficher la liste des modes et des workflows.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"

# Définir les tests
Describe "Tests simples pour le gestionnaire intégré" {
    Context "Vérification de l'existence du gestionnaire intégré" {
        It "Le gestionnaire intégré devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
    }
    
    Context "Vérification de l'exécution du gestionnaire intégré" {
        It "Le gestionnaire intégré devrait pouvoir être exécuté sans erreur" {
            { & $integratedManagerPath -ListModes -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Vérification de l'affichage des modes" {
        It "Le gestionnaire intégré devrait pouvoir afficher la liste des modes" {
            $output = & $integratedManagerPath -ListModes
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Vérification de l'affichage des workflows" {
        It "Le gestionnaire intégré devrait pouvoir afficher la liste des workflows" {
            $output = & $integratedManagerPath -ListWorkflows
            $output | Should -Not -BeNullOrEmpty
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
