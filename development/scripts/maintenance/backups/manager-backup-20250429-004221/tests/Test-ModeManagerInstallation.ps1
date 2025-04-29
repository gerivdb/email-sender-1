<#
.SYNOPSIS
    Tests pour vérifier l'installation du mode MANAGER.

.DESCRIPTION
    Ce script vérifie que le mode MANAGER est correctement installé et configuré.
    Il vérifie la présence des fichiers nécessaires, la configuration et les liens symboliques.

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir les chemins des fichiers à vérifier
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$modeManagerDoc = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\methodologies\mode_manager.md"
$modesConfigJson = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\modes-config.json"
$installScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\install-mode-manager.ps1"

# Chemins des fichiers de configuration
$configPaths = @(
    (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\config.json"),
    (Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\config\config.json")
)

# Chemins des liens symboliques
$linkPaths = @(
    (Join-Path -Path $projectRoot -ChildPath "tools\scripts\mode-manager.ps1"),
    (Join-Path -Path $projectRoot -ChildPath "scripts\mode-manager.ps1")
)

# Définir les tests
Describe "Mode Manager Installation Tests" {
    Context "Fichiers principaux" {
        It "Le script mode-manager.ps1 devrait exister" {
            Test-Path -Path $modeManagerScript | Should -Be $true
        }

        It "La documentation du mode MANAGER devrait exister" {
            Test-Path -Path $modeManagerDoc | Should -Be $true
        }

        It "Le fichier de configuration des modes devrait exister" {
            Test-Path -Path $modesConfigJson | Should -Be $true
        }

        It "Le script d'installation devrait exister" {
            Test-Path -Path $installScript | Should -Be $true
        }
    }

    Context "Configuration" {
        It "Au moins un fichier de configuration devrait exister" {
            $configExists = $false
            foreach ($configPath in $configPaths) {
                if (Test-Path -Path $configPath) {
                    $configExists = $true
                    break
                }
            }
            $configExists | Should -Be $true
        }

        It "Le mode MANAGER devrait être configuré dans au moins un fichier de configuration" {
            $managerConfigured = $false
            foreach ($configPath in $configPaths) {
                if (Test-Path -Path $configPath) {
                    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                    if ($config.Modes -and ($config.Modes.PSObject.Properties.Name -contains "Manager" -or $config.Modes.PSObject.Properties.Name -contains "manager")) {
                        $managerConfigured = $true
                        break
                    }
                }
            }
            $managerConfigured | Should -Be $true
        }
    }

    Context "Liens symboliques" {
        It "Au moins un lien symbolique devrait exister" {
            $linkExists = $false
            foreach ($linkPath in $linkPaths) {
                if (Test-Path -Path $linkPath) {
                    $linkExists = $true
                    break
                }
            }
            $linkExists | Should -Be $true
        }
    }

    Context "Fonctionnalité" {
        It "Le script mode-manager.ps1 devrait s'exécuter sans erreur avec -ListModes" {
            $scriptPath = $modeManagerScript
            if (-not (Test-Path -Path $scriptPath)) {
                foreach ($linkPath in $linkPaths) {
                    if (Test-Path -Path $linkPath) {
                        $scriptPath = $linkPath
                        break
                    }
                }
            }

            { & $scriptPath -ListModes } | Should -Not -Throw
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot
