<#
.SYNOPSIS
    Tests unitaires pour le module ErrorLearningSystem.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module ErrorLearningSystem
    en utilisant le framework Pester.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du module à tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Module ErrorLearningSystem" {
    BeforeAll {
        # Importer le module à tester
        Import-Module $modulePath -Force
        
        # Initialiser le module avec un chemin personnalisé pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $testRoot -ChildPath "patterns"
        
        # Initialiser le système
        Initialize-ErrorLearningSystem -Force
    }
    
    Context "Initialisation du module" {
        It "Devrait initialiser le module avec succès" {
            $result = Initialize-ErrorLearningSystem -Force
            $result | Should -BeNullOrEmpty
        }
        
        It "Devrait créer les dossiers nécessaires" {
            Test-Path -Path $script:ErrorLogsPath | Should -BeTrue
            Test-Path -Path $script:ErrorPatternsPath | Should -BeTrue
        }
        
        It "Devrait créer la base de données des erreurs" {
            Test-Path -Path $script:ErrorDatabasePath | Should -BeTrue
        }
    }
    
    Context "Enregistrement des erreurs" {
        It "Devrait enregistrer une erreur avec succès" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory"
            
            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait enregistrer une erreur avec des informations supplémentaires" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test avec infos")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithInfo",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Informations supplémentaires
            $additionalInfo = @{
                TestKey = "TestValue"
                TestNumber = 123
            }
            
            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory" -AdditionalInfo $additionalInfo
            
            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait enregistrer une erreur avec une solution" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Enregistrer l'erreur avec une solution
            $solution = "Voici la solution à l'erreur de test"
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "TestCategory" -Solution $solution
            
            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Analyse des erreurs" {
        It "Devrait analyser les erreurs avec succès" {
            # Analyser les erreurs
            $result = Analyze-PowerShellErrors
            
            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 3
        }
        
        It "Devrait filtrer les erreurs par catégorie" {
            # Analyser les erreurs filtrées par catégorie
            $result = Analyze-PowerShellErrors -Category "TestCategory"
            
            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 3
            $result.Errors | ForEach-Object { $_.Category | Should -Be "TestCategory" }
        }
        
        It "Devrait limiter le nombre de résultats" {
            # Analyser les erreurs avec une limite
            $result = Analyze-PowerShellErrors -MaxResults 2
            
            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeLessOrEqual 2
        }
        
        It "Devrait inclure les statistiques si demandé" {
            # Analyser les erreurs avec les statistiques
            $result = Analyze-PowerShellErrors -IncludeStatistics
            
            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Statistics | Should -Not -BeNullOrEmpty
            $result.Statistics.TotalErrors | Should -BeGreaterOrEqual 3
            $result.Statistics.CategorizedErrors | Should -Not -BeNullOrEmpty
            $result.Statistics.CategorizedErrors.TestCategory | Should -BeGreaterOrEqual 3
        }
    }
    
    Context "Suggestions d'erreurs" {
        It "Devrait obtenir des suggestions pour une erreur connue" {
            # Créer une erreur factice similaire à une erreur enregistrée
            $exception = New-Object System.Exception("Erreur de test avec solution")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestErrorWithSolution",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $errorRecord
            
            # Vérifier le résultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeTrue
            $suggestions.Suggestions | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait retourner un message approprié pour une erreur inconnue" {
            # Créer une erreur factice inconnue
            $exception = New-Object System.Exception("Erreur inconnue")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "UnknownError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Obtenir des suggestions
            $suggestions = Get-ErrorSuggestions -ErrorRecord $errorRecord
            
            # Vérifier le résultat
            $suggestions | Should -Not -BeNullOrEmpty
            $suggestions.Found | Should -BeFalse
            $suggestions.Message | Should -Be "Aucune suggestion trouvée pour cette erreur."
        }
    }
    
    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue
        
        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
