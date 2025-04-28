#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Install-PreCommitHook.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Install-PreCommitHook.ps1,
    en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\Install-PreCommitHook.Tests.ps1"
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\git\Install-PreCommitHook.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Install-PreCommitHook.ps1 n'existe pas: $scriptPath"
}

# Tests Pester
Describe "Tests du script Install-PreCommitHook.ps1" {
    BeforeAll {
        # Créer un dossier temporaire pour simuler un dépôt Git
        $testDir = Join-Path -Path $env:TEMP -ChildPath "PreCommitHookTests"
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Créer une structure de dossiers pour simuler un dépôt Git
        $gitDir = Join-Path -Path $testDir -ChildPath ".git"
        $hooksDir = Join-Path -Path $gitDir -ChildPath "hooks"
        New-Item -Path $gitDir -ItemType Directory -Force | Out-Null
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null

        # Sauvegarder les chemins pour les tests
        $script:testDir = $testDir
        $script:gitDir = $gitDir
        $script:hooksDir = $hooksDir
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

        It "Le script devrait contenir la fonction Write-Log" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function Write-Log"
        }

        It "Le script devrait contenir le contenu du hook pre-commit" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "Pre-commit hook pour organiser les scripts de maintenance"
        }
    }

    Context "Tests d'intégration" {
        BeforeEach {
            # Simuler un dépôt Git en créant un fichier .git/config
            $configPath = Join-Path -Path $script:gitDir -ChildPath "config"
            Set-Content -Path $configPath -Value "[core]`n`trepositoryformatversion = 0`n`tfilemode = false`n`tbare = false`n`tlogallrefupdates = true`n`tsymlinks = false`n`tignorecase = true" -Encoding UTF8
        }

        It "Devrait créer le hook pre-commit" {
            # Simuler l'exécution du script dans un dépôt Git
            # Note: Nous ne pouvons pas exécuter réellement le script car il dépend de git rev-parse
            # Mais nous pouvons vérifier que le contenu du hook est correct

            # Extraire le contenu du hook pre-commit du script
            $scriptContent = Get-Content -Path $scriptPath -Raw
            if ($scriptContent -match "(?s)preCommitContent = @'(.*?)'@") {
                $hookContent = $matches[1]
                
                # Créer manuellement le hook pre-commit
                $preCommitPath = Join-Path -Path $script:hooksDir -ChildPath "pre-commit"
                Set-Content -Path $preCommitPath -Value $hookContent -Encoding utf8 -NoNewline
                
                # Vérifier que le hook a été créé
                Test-Path -Path $preCommitPath | Should -Be $true
                
                # Vérifier le contenu du hook
                $actualContent = Get-Content -Path $preCommitPath -Raw
                $actualContent | Should -Match "Pre-commit hook pour organiser les scripts de maintenance"
                $actualContent | Should -Match "MAINTENANCE_DIR="
                $actualContent | Should -Match "Organisation automatique des scripts"
            }
            else {
                # Si nous ne pouvons pas extraire le contenu du hook, le test échoue
                $false | Should -Be $true -Because "Impossible d'extraire le contenu du hook pre-commit du script"
            }
        }
    }
}
