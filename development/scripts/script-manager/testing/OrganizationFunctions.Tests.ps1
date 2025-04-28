#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'organisation des scripts du manager.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'organisation
    des scripts du manager, en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\OrganizationFunctions.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Charger les fonctions à tester
. "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"

# Tests Pester
Describe "Tests des fonctions d'organisation des scripts du manager" {
    Context "Tests de la fonction Get-ScriptCategory" {
        It "Devrait retourner 'analysis' pour un fichier contenant 'analyze' dans son nom" {
            Get-ScriptCategory -FileName "Analyze-Scripts.ps1" | Should -Be "analysis"
        }

        It "Devrait retourner 'organization' pour un fichier contenant 'organize' dans son nom" {
            Get-ScriptCategory -FileName "Organize-Scripts.ps1" | Should -Be "organization"
        }

        It "Devrait retourner 'inventory' pour un fichier contenant 'inventory' dans son nom" {
            Get-ScriptCategory -FileName "Show-ScriptInventory.ps1" | Should -Be "inventory"
        }

        It "Devrait retourner 'documentation' pour un fichier contenant 'document' dans son nom" {
            Get-ScriptCategory -FileName "Generate-Documentation.ps1" | Should -Be "documentation"
        }

        It "Devrait retourner 'monitoring' pour un fichier contenant 'monitor' dans son nom" {
            Get-ScriptCategory -FileName "Monitor-Scripts.ps1" | Should -Be "monitoring"
        }

        It "Devrait retourner 'optimization' pour un fichier contenant 'optimize' dans son nom" {
            Get-ScriptCategory -FileName "Optimize-Scripts.ps1" | Should -Be "optimization"
        }

        It "Devrait retourner 'testing' pour un fichier contenant 'test' dans son nom" {
            Get-ScriptCategory -FileName "Test-Scripts.ps1" | Should -Be "testing"
        }

        It "Devrait retourner 'configuration' pour un fichier contenant 'config' dans son nom" {
            Get-ScriptCategory -FileName "Update-Configuration.ps1" | Should -Be "configuration"
        }

        It "Devrait retourner 'generation' pour un fichier contenant 'generate' dans son nom" {
            Get-ScriptCategory -FileName "Generate-Script.ps1" | Should -Be "generation"
        }

        It "Devrait retourner 'integration' pour un fichier contenant 'integrate' dans son nom" {
            Get-ScriptCategory -FileName "Integrate-Tools.ps1" | Should -Be "integration"
        }

        It "Devrait retourner 'ui' pour un fichier contenant 'ui' dans son nom" {
            Get-ScriptCategory -FileName "Update-UI.ps1" | Should -Be "ui"
        }

        It "Devrait retourner 'core' pour un fichier sans mot-clé reconnu" {
            Get-ScriptCategory -FileName "ScriptManager.ps1" | Should -Be "core"
        }

        It "Devrait analyser le contenu si le nom ne contient pas de mot-clé reconnu" {
            $content = "# Script pour analyser les scripts"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "analysis"
        }

        It "Devrait retourner 'core' si ni le nom ni le contenu ne contiennent de mot-clé reconnu" {
            $content = "# Script sans mot-clé reconnu"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "core"
        }
    }

    Context "Tests de la fonction Backup-File" {
        BeforeAll {
            # Créer un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "BackupFileTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # Créer un fichier de test
            $testFilePath = Join-Path -Path $testDir -ChildPath "test-file.ps1"
            Set-Content -Path $testFilePath -Value "# Test file" -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:testFilePath = $testFilePath
        }

        AfterAll {
            # Nettoyer après les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait créer une sauvegarde du fichier" {
            $result = Backup-File -FilePath $script:testFilePath
            $result | Should -Be $true
            Test-Path -Path "$script:testFilePath.bak" | Should -Be $true
        }

        It "Le contenu de la sauvegarde devrait être identique à l'original" {
            $originalContent = Get-Content -Path $script:testFilePath -Raw
            $backupContent = Get-Content -Path "$script:testFilePath.bak" -Raw
            $backupContent | Should -Be $originalContent
        }
    }

    Context "Tests de la fonction Move-ScriptToCategory" {
        BeforeAll {
            # Créer un dossier temporaire pour les tests
            $testDir = Join-Path -Path $env:TEMP -ChildPath "MoveScriptToCategoryTests"
            if (Test-Path -Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null

            # Créer un dossier manager
            $managerDir = Join-Path -Path $testDir -ChildPath "manager"
            New-Item -Path $managerDir -ItemType Directory -Force | Out-Null

            # Créer un fichier de test
            $testFilePath = Join-Path -Path $managerDir -ChildPath "test-file.ps1"
            Set-Content -Path $testFilePath -Value "# Test file" -Encoding UTF8

            # Sauvegarder les chemins pour les tests
            $script:testDir = $testDir
            $script:managerDir = $managerDir
            $script:testFilePath = $testFilePath
        }

        AfterAll {
            # Nettoyer après les tests
            if (Test-Path -Path $script:testDir) {
                Remove-Item -Path $script:testDir -Recurse -Force
            }
        }

        It "Devrait déplacer le fichier dans le sous-dossier approprié" {
            $result = Move-ScriptToCategory -FilePath $script:testFilePath -Category "testing" -CreateBackup:$false
            $result | Should -Be $true
            Test-Path -Path "$script:managerDir/testing/test-file.ps1" | Should -Be $true
        }

        It "Le dossier cible devrait être créé s'il n'existe pas" {
            Test-Path -Path "$script:managerDir/testing" | Should -Be $true
        }

        It "Le fichier original ne devrait plus exister" {
            Test-Path -Path $script:testFilePath | Should -Be $false
        }
    }
}
