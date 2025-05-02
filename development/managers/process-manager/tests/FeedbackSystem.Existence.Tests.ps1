<#
.SYNOPSIS
    Tests d'existence pour le système de feedback.

.DESCRIPTION
    Ce script vérifie simplement que les fichiers du système de feedback existent et sont correctement formatés.

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
Describe "Système de feedback - Tests d'existence" {
    BeforeAll {
        # Définir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Existence des fichiers" {
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

        It "Le fichier FeedbackManager.psm1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psm1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackManager.psd1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackManager.manifest.json doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.manifest.json") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackCollector.psm1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psm1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackCollector.psd1 doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") -PathType Leaf | Should -Be $true
        }

        It "Le fichier FeedbackCollector.manifest.json doit exister" {
            Test-Path -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.manifest.json") -PathType Leaf | Should -Be $true
        }

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

    Context "Format des fichiers" {
        It "Le fichier FeedbackManager.psm1 doit être un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.psm1 doit être un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.psm1 doit être un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackManager.psd1 doit être un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.psd1 doit être un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.psd1 doit être un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackManager.manifest.json doit être un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.manifest.json doit être un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.manifest.json doit être un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }
    }
}
