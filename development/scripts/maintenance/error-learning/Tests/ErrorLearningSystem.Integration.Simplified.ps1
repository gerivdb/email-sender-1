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

        # CrÃ©er un rÃ©pertoire temporaire pour les tests avec un identifiant unique
        $script:testId = [guid]::NewGuid().ToString().Substring(0, 8)
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests_$script:testId"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # Importer le module Ã  tester
        Import-Module $script:modulePath -Force
    }

    Context "Enregistrement et analyse des erreurs" {
        It "Devrait enregistrer une erreur avec succÃ¨s" {
            # DÃ©finir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test1-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test1-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test1-patterns"

            # DÃ©finir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le systÃ¨me pour ce test
            Initialize-ErrorLearningSystem -Force

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

        It "Devrait filtrer les erreurs par catÃ©gorie" {
            # DÃ©finir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test2-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test2-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test2-patterns"

            # DÃ©finir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le systÃ¨me pour ce test
            Initialize-ErrorLearningSystem -Force

            # CrÃ©er une erreur factice avec une catÃ©gorie spÃ©cifique
            $exception = New-Object System.Exception("Erreur de test 2")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError2",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory2"

            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty

            # Analyser les erreurs filtrÃ©es par catÃ©gorie
            $analysisResult = Get-PowerShellErrorAnalysis -Category "TestCategory2" -IncludeStatistics

            # VÃ©rifier le rÃ©sultat
            $analysisResult | Should -Not -BeNullOrEmpty
            $analysisResult.Errors | Should -Not -BeNullOrEmpty
            $analysisResult.Errors.Count | Should -BeGreaterOrEqual 1
            $analysisResult.Errors[0].Category | Should -Be "TestCategory2"
        }

        It "Devrait obtenir des suggestions pour une erreur" {
            # DÃ©finir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test3-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test3-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test3-patterns"

            # DÃ©finir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le systÃ¨me pour ce test
            Initialize-ErrorLearningSystem -Force

            # CrÃ©er une erreur factice avec une solution
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur avec une solution
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory" -Solution "Voici la solution Ã  l'erreur."

            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty

            # CrÃ©er une erreur similaire pour obtenir des suggestions
            $similarException = New-Object System.Exception("Erreur de test avec solution")
            $similarErrorRecord = New-Object System.Management.Automation.ErrorRecord(
                $similarException,
                "SimilarTestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $similarErrorRecord

            # VÃ©rifier le rÃ©sultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeTrue
            $suggestions.Suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Suggestions.Count | Should -BeGreaterOrEqual 1
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
