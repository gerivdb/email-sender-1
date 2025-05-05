<#
.SYNOPSIS
    Tests de base pour le systÃ¨me de feedback.

.DESCRIPTION
    Ce script vÃ©rifie simplement que les rÃ©pertoires du systÃ¨me de feedback existent.

.NOTES
    Version: 1.0.0
    Auteur: Process Manager Team
    Date de crÃ©ation: 2025-05-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "SystÃ¨me de feedback - Tests de base" {
    BeforeAll {
        # DÃ©finir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Existence des rÃ©pertoires" {
        It "Le rÃ©pertoire des modules doit exister" {
            Test-Path -Path $script:ModulesPath -PathType Container | Should -Be $true
        }

        It "Le rÃ©pertoire FeedbackManager doit exister" {
            Test-Path -Path $script:FeedbackManagerPath -PathType Container | Should -Be $true
        }

        It "Le rÃ©pertoire FeedbackCollector doit exister" {
            Test-Path -Path $script:FeedbackCollectorPath -PathType Container | Should -Be $true
        }

        It "Le rÃ©pertoire FeedbackExporter doit exister" {
            Test-Path -Path $script:FeedbackExporterPath -PathType Container | Should -Be $true
        }
    }
}
