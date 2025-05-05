<#
.SYNOPSIS
    Tests de format des fichiers pour le systÃ¨me de feedback.

.DESCRIPTION
    Ce script vÃ©rifie que les fichiers du systÃ¨me de feedback sont correctement formatÃ©s.

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
Describe "SystÃ¨me de feedback - Tests de format des fichiers" {
    BeforeAll {
        # DÃ©finir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Format des fichiers PowerShell" {
        It "Le fichier FeedbackManager.psm1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackCollector.psm1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackExporter.psm1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }
    }

    Context "Format des fichiers de manifeste PowerShell" {
        It "Le fichier FeedbackManager.psd1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackCollector.psd1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackExporter.psd1 doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
        }
    }

    Context "Format des fichiers JSON" {
        It "Le fichier FeedbackManager.manifest.json doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackCollector.manifest.json doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
        }

        It "Le fichier FeedbackExporter.manifest.json doit contenir du contenu" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
        }
    }
}
