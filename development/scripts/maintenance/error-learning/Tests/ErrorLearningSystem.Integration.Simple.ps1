<#
.SYNOPSIS
    Tests d'intÃ©gration simplifiÃ©s pour le systÃ¨me d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests d'intÃ©gration simplifiÃ©s pour le systÃ¨me d'apprentissage des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests d'intÃ©gration simplifiÃ©s du systÃ¨me d'apprentissage des erreurs" {
    BeforeAll {
        # DÃ©finir le chemin du module Ã  tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:modulePath = Join-Path -Path $script:moduleRoot -ChildPath "ErrorLearningSystem.psm1"
        
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemSimpleTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Importer le module Ã  tester
        Import-Module $script:modulePath -Force
        
        # Initialiser le module avec un chemin personnalisÃ© pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $script:testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $script:testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $script:testRoot -ChildPath "patterns"
        
        # Initialiser le systÃ¨me
        Initialize-ErrorLearningSystem -Force
    }
    
    Context "Enregistrement et analyse des erreurs" {
        It "Devrait enregistrer une erreur avec succÃ¨s" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory"
            
            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty
            
            # Analyser les erreurs
            $analysisResult = Get-PowerShellErrorAnalysis -IncludeStatistics
            
            # VÃ©rifier le rÃ©sultat
            $analysisResult | Should -Not -BeNullOrEmpty
            $analysisResult.Errors | Should -Not -BeNullOrEmpty
            $analysisResult.Errors.Count | Should -BeGreaterOrEqual 1
            $analysisResult.Statistics | Should -Not -BeNullOrEmpty
            $analysisResult.Statistics.TotalErrors | Should -BeGreaterOrEqual 1
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
