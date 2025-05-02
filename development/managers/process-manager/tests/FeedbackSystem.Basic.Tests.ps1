<#
.SYNOPSIS
    Tests de base pour le système de feedback.

.DESCRIPTION
    Ce script vérifie simplement que les répertoires du système de feedback existent.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de création: 2025-05-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Système de feedback - Tests de base" {
    BeforeAll {
        # Définir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Existence des répertoires" {
        It "Le répertoire des modules doit exister" {
            Test-Path -Path $script:ModulesPath -PathType Container | Should -Be $true
        }

        It "Le répertoire FeedbackManager doit exister" {
            Test-Path -Path $script:FeedbackManagerPath -PathType Container | Should -Be $true
        }

        It "Le répertoire FeedbackCollector doit exister" {
            Test-Path -Path $script:FeedbackCollectorPath -PathType Container | Should -Be $true
        }

        It "Le répertoire FeedbackExporter doit exister" {
            Test-Path -Path $script:FeedbackExporterPath -PathType Container | Should -Be $true
        }
    }
}
