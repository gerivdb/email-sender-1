<#
.SYNOPSIS
    Tests unitaires pour le module ErrorLearningSystem.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module ErrorLearningSystem
    en utilisant le framework Pester.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du module Ã  tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorLearningSystem.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# DÃ©finir les tests Pester
Describe "Module ErrorLearningSystem" {
    BeforeAll {
        # Importer le module Ã  tester
        Import-Module $modulePath -Force

        # Initialiser le module avec un chemin personnalisÃ© pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $testRoot -ChildPath "patterns"

        # Initialiser le systÃ¨me
        Initialize-ErrorLearningSystem -Force
    }

    Context "Initialisation du module" {
        It "Devrait initialiser le module avec succÃ¨s" {
            $result = Initialize-ErrorLearningSystem -Force
            $result | Should -BeNullOrEmpty
        }

        It "Devrait crÃ©er les dossiers nÃ©cessaires" {
            Test-Path -Path $script:ErrorLogsPath | Should -BeTrue
            Test-Path -Path $script:ErrorPatternsPath | Should -BeTrue
        }

        It "Devrait crÃ©er la base de donnÃ©es des erreurs" {
            Test-Path -Path $script:ErrorDatabasePath | Should -BeTrue
        }
    }

    Context "Enregistrement des erreurs" {
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
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory"

            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty
        }

        It "Devrait enregistrer une erreur avec des informations supplÃ©mentaires" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test avec infos")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithInfo",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Informations supplÃ©mentaires
            $additionalInfo = @{
                TestKey = "TestValue"
                TestNumber = 123
            }

            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory" -AdditionalInfo $additionalInfo

            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty
        }

        It "Devrait enregistrer une erreur avec une solution" {
            # CrÃ©er une erreur factice
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Enregistrer l'erreur avec une solution
            $solution = "Voici la solution Ã  l'erreur de test"
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory" -Solution $solution

            # VÃ©rifier que l'erreur a Ã©tÃ© enregistrÃ©e
            $errorId | Should -Not -BeNullOrEmpty
        }
    }

    Context "Analyse des erreurs" {
        It "Devrait analyser les erreurs avec succÃ¨s" {
            # Analyser les erreurs
            $result = Get-PowerShellErrorAnalysis

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 3
        }

        It "Devrait filtrer les erreurs par catÃ©gorie" {
            # Analyser les erreurs filtrÃ©es par catÃ©gorie
            $result = Get-PowerShellErrorAnalysis -Category "TestCategory"

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 3
            $result.Errors | ForEach-Object { $_.Category | Should -Be "TestCategory" }
        }

        It "Devrait limiter le nombre de rÃ©sultats" {
            # Analyser les erreurs avec une limite
            $result = Get-PowerShellErrorAnalysis -MaxResults 2

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeLessOrEqual 2
        }

        It "Devrait inclure les statistiques si demandÃ©" {
            # Analyser les erreurs avec les statistiques
            $result = Get-PowerShellErrorAnalysis -IncludeStatistics

            # VÃ©rifier le rÃ©sultat
            $result | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            $result.Statistics.TotalErrors | Should -BeGreaterOrEqual 3
            $result.Statistics.CategorizedErrors | Should -Not -BeNullOrEmpty
            $result.Statistics.CategorizedErrors.TestCategory | Should -BeGreaterOrEqual 3
        }
    }

    Context "Suggestions d'erreurs" {
        It "Devrait obtenir des suggestions pour une erreur connue" {
            # CrÃ©er une erreur factice similaire Ã  une erreur enregistrÃ©e
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $errorRecord

            # VÃ©rifier le rÃ©sultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeTrue
            $suggestions.Suggestions | Should -Not -BeNullOrEmpty
        }

        It "Devrait retourner un message appropriÃ© pour une erreur inconnue" {
            # CrÃ©er une erreur factice inconnue
            $exception = New-Object System.Exception("Erreur inconnue")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "UnknownError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )

            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $errorRecord

            # VÃ©rifier le rÃ©sultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeFalse
            $suggestions.Message | Should -Be "Aucune suggestion trouvÃ©e pour cette erreur."
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Ne pas exÃ©cuter les tests automatiquement pour Ã©viter la rÃ©cursion infinie
# # # # # Invoke-Pester -Path $PSCommandPath -Output Detailed # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie



