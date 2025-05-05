<#
.SYNOPSIS
    Tests d'existence pour le systÃ¨me de feedback.

.DESCRIPTION
    Ce script vÃ©rifie simplement que les fichiers du systÃ¨me de feedback existent et sont correctement formatÃ©s.

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
Describe "SystÃ¨me de feedback - Tests d'existence" {
    BeforeAll {
        # DÃ©finir les chemins des modules
        $script:ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
        $script:FeedbackManagerPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackManager"
        $script:FeedbackCollectorPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackCollector"
        $script:FeedbackExporterPath = Join-Path -Path $script:ModulesPath -ChildPath "FeedbackExporter"
    }

    Context "Existence des fichiers" {
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
        It "Le fichier FeedbackManager.psm1 doit Ãªtre un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.psm1 doit Ãªtre un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.psm1 doit Ãªtre un fichier PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psm1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null) } | Should -Not -Throw
        }

        It "Le fichier FeedbackManager.psd1 doit Ãªtre un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.psd1 doit Ãªtre un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.psd1 doit Ãªtre un fichier de manifeste PowerShell valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") -Raw
            $content | Should -Not -BeNullOrEmpty
            { Import-PowerShellDataFile -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.psd1") } | Should -Not -Throw
        }

        It "Le fichier FeedbackManager.manifest.json doit Ãªtre un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackManagerPath -ChildPath "FeedbackManager.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }

        It "Le fichier FeedbackCollector.manifest.json doit Ãªtre un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackCollectorPath -ChildPath "FeedbackCollector.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }

        It "Le fichier FeedbackExporter.manifest.json doit Ãªtre un fichier JSON valide" {
            $content = Get-Content -Path (Join-Path -Path $script:FeedbackExporterPath -ChildPath "FeedbackExporter.manifest.json") -Raw
            $content | Should -Not -BeNullOrEmpty
            { ConvertFrom-Json -InputObject $content } | Should -Not -Throw
        }
    }
}
