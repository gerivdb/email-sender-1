#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Organize-MaintenanceScripts.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Organize-MaintenanceScripts.ps1,
    en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\Organize-MaintenanceScripts.Tests.ps1"
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\organize\Organize-MaintenanceScripts.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Organize-MaintenanceScripts.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Organize-MaintenanceScripts.ps1" {
    BeforeAll {
        # CrÃ©er un dossier temporaire pour les tests
        $testDir = Join-Path -Path $env:TEMP -ChildPath "MaintenanceScriptsTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er une structure de dossiers pour les tests
        $maintenanceDir = Join-Path -Path $testDir -ChildPath "maintenance"
        New-Item -Path $maintenanceDir -ItemType Directory -Force | Out-Null

        # CrÃ©er quelques sous-dossiers
        $categories = @('api', 'cleanup', 'paths', 'test', 'utils')
        foreach ($category in $categories) {
            New-Item -Path (Join-Path -Path $maintenanceDir -ChildPath $category) -ItemType Directory -Force | Out-Null
        }

        # CrÃ©er quelques fichiers de test Ã  la racine
        $testFiles = @(
            @{Name = "test-script.ps1"; Content = "# Test script" },
            @{Name = "update-paths.ps1"; Content = "# Update paths script" },
            @{Name = "analyze-data.ps1"; Content = "# Analyze data script" },
            @{Name = "fix-issues.ps1"; Content = "# Fix issues script" },
            @{Name = "random-script.ps1"; Content = "# Random script" }
        )

        foreach ($file in $testFiles) {
            $filePath = Join-Path -Path $maintenanceDir -ChildPath $file.Name
            Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
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

        It "Le script devrait contenir la fonction Get-ScriptCategory" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Get-ScriptCategory"
        }

        It "Le script devrait contenir la fonction Move-ScriptToCategory" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Move-ScriptToCategory"
        }
    }

    Context "Tests d'intÃ©gration" {
        It "Devrait dÃ©placer les fichiers dans les bons sous-dossiers" {
            # ExÃ©cuter le script avec les paramÃ¨tres de test
            & $scriptPath -Force -CreateBackups:$false

            # VÃ©rifier que les fichiers ont Ã©tÃ© dÃ©placÃ©s dans les bons sous-dossiers
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "test\test-script.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "paths\update-paths.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "api\analyze-data.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "cleanup\fix-issues.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $script:maintenanceDir -ChildPath "utils\random-script.ps1") | Should -Be $true
        }

        It "Ne devrait plus y avoir de fichiers Ã  la racine du dossier maintenance" {
            $rootFiles = Get-ChildItem -Path $script:maintenanceDir -File
            $rootFiles.Count | Should -Be 0
        }
    }
}
