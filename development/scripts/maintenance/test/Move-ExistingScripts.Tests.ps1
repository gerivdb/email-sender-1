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
    Date de création: 2023-06-10
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\organize\Move-ExistingScripts.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Move-ExistingScripts.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Move-ExistingScripts.ps1" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "MoveExistingScriptsTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer une structure de dossiers pour les tests
        $maintenanceDir = Join-Path -Path $testDir -ChildPath "maintenance"
        New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

        # Créer quelques sous-dossiers
        $categories = @('api', 'cleanup', 'paths', 'test', 'utils', 'roadmap', 'modes', 'vscode', 'backups')
        foreach ($category in $categories) {
            New-Item -Path (Join-Path -Path $maintenanceDir -ChildPath $category) -ItemType Directory -Force | Out-Null
        }

        # Créer quelques fichiers de test à la racine
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
        # Nettoyer après les tests
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force
        }
    }

    Context "Tests de fonctionnalité" {
        It "Le script devrait exister" {
            Test-Path -Path $scriptPath | Should -Be $true
        }

        It "Le script devrait être un fichier PowerShell valide" {
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

    Context "Tests d'intégration" {
        It "Devrait déplacer les fichiers dans les bons sous-dossiers selon la classification prédéfinie" {
            # Exécuter le script avec les paramètres de test
            & $scriptPath -Force -CreateBackups:$false

            # Vérifier que les fichiers ont été déplacés dans les bons sous-dossiers
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

        It "Ne devrait plus y avoir de fichiers à la racine du dossier maintenance" {
            $rootFiles = Get-ChildItem -Path $script:maintenanceDir -File
            $rootFiles.Count | Should -Be 0
        }
    }
}
