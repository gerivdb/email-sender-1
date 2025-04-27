<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-PowerShellErrorAnalysis.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-PowerShellErrorAnalysis.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Importer le module Ã  tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorLearningSystem.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests"
if (Test-Path -Path $script:testRoot) {
    Remove-Item -Path $script:testRoot -Recurse -Force
}
New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

# DÃ©finir les tests Pester
Describe "Tests de Get-PowerShellErrorAnalysis" {
    BeforeAll {
        # Importer le module Ã  tester
        Import-Module $modulePath -Force
        
        # Initialiser le module avec un chemin personnalisÃ© pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $script:testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $script:testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $script:testRoot -ChildPath "patterns"
        
        # Initialiser le systÃ¨me
        Initialize-ErrorLearningSystem -Force
        
        # CrÃ©er quelques erreurs de test
        $exception1 = New-Object System.Exception("Erreur de test 1")
        $errorRecord1 = New-Object System.Management.Automation.ErrorRecord(
            $exception1,
            "TestError1",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        $exception2 = New-Object System.Exception("Erreur de test 2")
        $errorRecord2 = New-Object System.Management.Automation.ErrorRecord(
            $exception2,
            "TestError2",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Enregistrer les erreurs
        Register-PowerShellError -ErrorRecord $errorRecord1 -Source "TestSource1" -Category "TestCategory1"
        Register-PowerShellError -ErrorRecord $errorRecord2 -Source "TestSource2" -Category "TestCategory2"
    }
    
    Context "FonctionnalitÃ©s de base" {
        It "Devrait retourner un objet d'analyse" {
            $result = Get-PowerShellErrorAnalysis
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait contenir une liste d'erreurs" {
            $result = Get-PowerShellErrorAnalysis
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 2
        }
        
        It "Devrait contenir les erreurs enregistrÃ©es" {
            $result = Get-PowerShellErrorAnalysis
            $result.Errors | Where-Object { $_.ErrorId -eq "TestError1" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.ErrorId -eq "TestError2" } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "ParamÃ¨tres optionnels" {
        It "Devrait filtrer par catÃ©gorie" {
            $result = Get-PowerShellErrorAnalysis -Category "TestCategory1"
            $result.Errors | Where-Object { $_.Category -eq "TestCategory1" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.Category -eq "TestCategory2" } | Should -BeNullOrEmpty
        }
        
        It "Devrait filtrer par source" {
            $result = Get-PowerShellErrorAnalysis -Source "TestSource2"
            $result.Errors | Where-Object { $_.Source -eq "TestSource2" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.Source -eq "TestSource1" } | Should -BeNullOrEmpty
        }
        
        It "Devrait inclure des statistiques si demandÃ©" {
            $result = Get-PowerShellErrorAnalysis -IncludeStatistics
            $result.Statistics | Should -Not -BeNullOrEmpty
            $result.Statistics.TotalErrors | Should -BeGreaterOrEqual 2
        }
    }
    
    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue
        
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
