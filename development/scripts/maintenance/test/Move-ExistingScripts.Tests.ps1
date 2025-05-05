#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Move-ExistingScripts.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Move-ExistingScripts.ps1,
    en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\Move-ExistingScripts.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\organize\Move-ExistingScripts.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Move-ExistingScripts.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Move-ExistingScripts.ps1" {
    BeforeAll {
        # CrÃ©er un dossier temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "MoveExistingScriptsTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er une structure de dossiers pour les tests
        $maintenanceDir = Join-Path -Path $testDir -ChildPath "maintenance"
        New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

        # CrÃ©er quelques sous-dossiers
        $categories = @('api', 'cleanup', 'paths', 'test', 'utils', 'roadmap', 'modes', 'vscode', 'backups')
        foreach ($category in $categories) {
            New-Item -Path (Join-Path -Path $maintenanceDir -ChildPath $category) -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er quelques fichiers de test Ã  la racine
        $testFiles = @(
            "Analyze-Feedback.ps1",
            "autoprefixer.ps1",
            "Consolidate-AnalysisDirectories-Final.ps1",
            "Consolidate-AnalysisDirectories.ps1",
            "create-checkbox-symlinks.ps1",
            "create-checkbox-symlinks.ps1.bak",
            "Fix-RoadmapScripts.ps1",
            "init-maintenance.ps1",
            "install-check-enhanced.ps1",
            "normalize-project-paths.ps1",
            "normalize-project-paths.ps1.bak",
            "Test-ConsolidateAnalysisDirectories-Final.ps1",
            "test-script-at-root.ps1",
            "test-script-at-root2.ps1",
            "update-checkbox-function.ps1",
            "update-checkbox-function.ps1.bak",
            "update-project-paths.ps1",
            "Update-Roadmap.ps1",
            "update-vscode-cache.ps1"
        )

        foreach ($fileName in $testFiles) {
            $filePath = Join-Path -Path $maintenanceDir -ChildPath $fileName
            Set-Content -Path $filePath -Value "# Test content for $fileName" -Encoding UTF8
        }

        # Sauvegarder les chemins pour les tests
        $script:testDir = $testDir
        $script:maintenanceDir = $maintenanceDir
        $script:testFiles = $testFiles
    }

    AfterAll {
        # Nettoyer aprÃ¨s les tests
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context "Tests de fonctionnalitÃ©" {
        It "Le script devrait exister" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "Le script devrait Ãªtre un fichier PowerShell valide" {
            { . $scriptPath } | Should -Not -Throw
        }

        It "Le script devrait contenir la variable scriptClassification" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "scriptClassification"
        }

        It "Le script devrait contenir la fonction Move-ScriptToCategory" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Move-ScriptToCategory"
        }
    }

    Context "Tests d'intÃ©gration" {
        It "Devrait dÃ©placer les fichiers dans les bons sous-dossiers selon la classification prÃ©dÃ©finie" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            & $scriptPath -Force -CreateBackups:$false

            # VÃ©rifier que les fichiers ont Ã©tÃ© dÃ©placÃ©s dans les bons sous-dossiers
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "api\Analyze-Feedback.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "utils\autoprefixer.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "cleanup\Consolidate-AnalysisDirectories-Final.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "cleanup\Consolidate-AnalysisDirectories.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "modes\create-checkbox-symlinks.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "backups\create-checkbox-symlinks.ps1.bak") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "roadmap\Fix-RoadmapScripts.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "environment-compatibility\init-maintenance.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "modes\install-check-enhanced.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "paths\normalize-project-paths.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "backups\normalize-project-paths.ps1.bak") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "test\Test-ConsolidateAnalysisDirectories-Final.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "test\test-script-at-root.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "test\test-script-at-root2.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "modes\update-checkbox-function.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "backups\update-checkbox-function.ps1.bak") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "paths\update-project-paths.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "roadmap\Update-Roadmap.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "vscode\update-vscode-cache.ps1") | Should -Be $true
        }

        It "Ne devrait plus y avoir de fichiers Ã  la racine du dossier maintenance" {
            $rootFiles = Get-ChildItem -Path $script:maintenanceDir -File
            $rootFiles.Count | Should -Be 0
        }
    }
}
