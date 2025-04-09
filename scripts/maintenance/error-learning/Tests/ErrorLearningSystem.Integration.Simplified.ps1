<#
.SYNOPSIS
    Tests d'intégration simplifiés pour le système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests d'intégration simplifiés pour le système d'apprentissage des erreurs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests d'intégration simplifiés du système d'apprentissage des erreurs" {
    BeforeAll {
        # Définir le chemin du module à tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:modulePath = Join-Path -Path $script:moduleRoot -ChildPath "ErrorLearningSystem.psm1"

        # Créer un répertoire temporaire pour les tests avec un identifiant unique
        $script:testId = [guid]::NewGuid().ToString().Substring(0, 8)
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests_$script:testId"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # Importer le module à tester
        Import-Module $script:modulePath -Force
    }

    Context "Enregistrement et analyse des erreurs" {
        It "Devrait enregistrer une erreur avec succès" {
            # Définir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test1-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test1-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test1-patterns"

            # Définir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le système pour ce test
            Initialize-ErrorLearningSystem -Force

            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory"

            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty

            # Analyser les erreurs
            $analysisResult = Get-PowerShellErrorAnalysis -IncludeStatistics

            # Vérifier le résultat
            $analysisResult | Should -Not -BeNullOrEmpty
            $analysisResult.Errors | Should -Not -BeNullOrEmpty
            $analysisResult.Errors.Count | Should -BeGreaterOrEqual 1
            $analysisResult.Statistics | Should -Not -BeNullOrEmpty
            $analysisResult.Statistics.TotalErrors | Should -BeGreaterOrEqual 1
        }

        It "Devrait filtrer les erreurs par catégorie" {
            # Définir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test2-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test2-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test2-patterns"

            # Définir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le système pour ce test
            Initialize-ErrorLearningSystem -Force

            # Créer une erreur factice avec une catégorie spécifique
            $exception = New-Object System.Exception("Erreur de test 2")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError2",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory2"

            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty

            # Analyser les erreurs filtrées par catégorie
            $analysisResult = Get-PowerShellErrorAnalysis -Category "TestCategory2" -IncludeStatistics

            # Vérifier le résultat
            $analysisResult | Should -Not -BeNullOrEmpty
            $analysisResult.Errors | Should -Not -BeNullOrEmpty
            $analysisResult.Errors.Count | Should -BeGreaterOrEqual 1
            $analysisResult.Errors[0].Category | Should -Be "TestCategory2"
        }

        It "Devrait obtenir des suggestions pour une erreur" {
            # Définir des chemins uniques pour ce test
            $testDbPath = Join-Path -Path $script:testRoot -ChildPath "test3-database.json"
            $testLogsPath = Join-Path -Path $script:testRoot -ChildPath "test3-logs"
            $testPatternsPath = Join-Path -Path $script:testRoot -ChildPath "test3-patterns"

            # Définir les variables globales du module pour ce test
            Set-Variable -Name ErrorDatabasePath -Value $testDbPath -Scope Script
            Set-Variable -Name ErrorLogsPath -Value $testLogsPath -Scope Script
            Set-Variable -Name ErrorPatternsPath -Value $testPatternsPath -Scope Script

            # Initialiser le système pour ce test
            Initialize-ErrorLearningSystem -Force

            # Créer une erreur factice avec une solution
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur avec une solution
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory" -Solution "Voici la solution à l'erreur."

            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty

            # Créer une erreur similaire pour obtenir des suggestions
            $similarException = New-Object System.Exception("Erreur de test avec solution")
            $similarErrorRecord = New-Object System.Management.Automation.ErrorRecord(
                $similarException,
                "SimilarTestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $similarErrorRecord

            # Vérifier le résultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeTrue
            $suggestions.Suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Suggestions.Count | Should -BeGreaterOrEqual 1
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue

        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
