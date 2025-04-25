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
        
        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemSimpleTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Importer le module à tester
        Import-Module $script:modulePath -Force
        
        # Initialiser le module avec un chemin personnalisé pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $script:testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $script:testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $script:testRoot -ChildPath "patterns"
        
        # Initialiser le système
        Initialize-ErrorLearningSystem -Force
    }
    
    Context "Enregistrement et analyse des erreurs" {
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
