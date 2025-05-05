<#
.SYNOPSIS
    Tests d'existence des fichiers pour le systÃ¨me de feedback.

.DESCRIPTION
    Ce script vÃ©rifie simplement que les fichiers du systÃ¨me de feedback existent.

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
Describe "SystÃ¨me de feedback - Tests d'existence des fichiers" {
    BeforeAll {
        # DÃ©finir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Existence des fichiers FeedbackManager" {
        It "Le fichier FeedbackManager.psm1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psm1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackManager.psd1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackManager.manifest.json doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.manifest.json") -PathType Leaf | Should -Be $true
        }
    }

    Context "Existence des fichiers FeedbackCollector" {
        It "Le fichier FeedbackCollector.psm1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psm1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackCollector.psd1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackCollector.manifest.json doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.manifest.json") -PathType Leaf | Should -Be $true
        }
    }

    Context "Existence des fichiers FeedbackExporter" {
        It "Le fichier FeedbackExporter.psm1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psm1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackExporter.psd1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackExporter.manifest.json doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.manifest.json") -PathType Leaf | Should -Be $true
        }
    }
}
