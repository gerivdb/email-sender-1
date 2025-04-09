<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-PowerShellErrorAnalysis.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-PowerShellErrorAnalysis.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Importer le module à tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemTests"
if (Test-Path -Path $script:testRoot) {
    Remove-Item -Path $script:testRoot -Recurse -Force
}
New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Tests de Get-PowerShellErrorAnalysis" {
    BeforeAll {
        # Importer le module à tester
        Import-Module $modulePath -Force
        
        # Initialiser le module avec un chemin personnalisé pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $script:testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $script:testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $script:testRoot -ChildPath "patterns"
        
        # Initialiser le système
        Initialize-ErrorLearningSystem -Force
        
        # Créer quelques erreurs de test
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
    
    Context "Fonctionnalités de base" {
        It "Devrait retourner un objet d'analyse" {
            $result = Get-PowerShellErrorAnalysis
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait contenir une liste d'erreurs" {
            $result = Get-PowerShellErrorAnalysis
            $result.Errors | Should -Not -BeNullOrEmpty
            $result.Errors.Count | Should -BeGreaterOrEqual 2
        }
        
        It "Devrait contenir les erreurs enregistrées" {
            $result = Get-PowerShellErrorAnalysis
            $result.Errors | Where-Object { $_.ErrorId -eq "TestError1" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.ErrorId -eq "TestError2" } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Paramètres optionnels" {
        It "Devrait filtrer par catégorie" {
            $result = Get-PowerShellErrorAnalysis -Category "TestCategory1"
            $result.Errors | Where-Object { $_.Category -eq "TestCategory1" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.Category -eq "TestCategory2" } | Should -BeNullOrEmpty
        }
        
        It "Devrait filtrer par source" {
            $result = Get-PowerShellErrorAnalysis -Source "TestSource2"
            $result.Errors | Where-Object { $_.Source -eq "TestSource2" } | Should -Not -BeNullOrEmpty
            $result.Errors | Where-Object { $_.Source -eq "TestSource1" } | Should -BeNullOrEmpty
        }
        
        It "Devrait inclure des statistiques si demandé" {
            $result = Get-PowerShellErrorAnalysis -IncludeStatistics
            $result.Statistics | Should -Not -BeNullOrEmpty
            $result.Statistics.TotalErrors | Should -BeGreaterOrEqual 2
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
