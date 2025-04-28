<#
.SYNOPSIS
    Tests unitaires pour le module de gestion d'erreurs.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement du module de gestion d'erreurs.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      Pester 5.0 ou supÃ©rieur
#>

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# DÃ©finir le chemin du module Ã  tester
$moduleRoot = Split-Path -Path $PSCommandPath -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorHandling.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$testScriptPath = Join-Path -Path $testRoot -ChildPath "TestScript.ps1"
$testScriptContent = @"
# Script de test sans gestion d'erreurs
function Test-Function {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )

    Get-Content -Path `$Path
}

# Appeler la fonction avec un chemin invalide
Test-Function -Path "C:\chemin\invalide.txt"
"@
Set-Content -Path $testScriptPath -Value $testScriptContent -Force

# DÃ©finir les tests Pester
Describe "Module de gestion d'erreurs" {
    BeforeAll {
        # Importer le module Ã  tester
        Import-Module $modulePath -Force

        # Initialiser le module avec un rÃ©pertoire de test
        $logPath = Join-Path -Path $testRoot -ChildPath "Logs"
        Initialize-ErrorHandling -LogPath $logPath
    }

    Context "Initialisation du module" {
        It "Devrait initialiser le module avec succÃ¨s" {
            $result = Initialize-ErrorHandling -LogPath $testRoot
            $result | Should -Be $true
        }

        It "Devrait crÃ©er le rÃ©pertoire de journaux" {
            Test-Path -Path $testRoot | Should -Be $true
        }
    }

    Context "Ajout de blocs try/catch" {
        It "Devrait ajouter des blocs try/catch Ã  un script" {
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath -BackupFile
            $result | Should -Be $true

            # VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã©
            Test-Path -Path "$testScriptPath.bak" | Should -Be $true

            # VÃ©rifier que le script contient maintenant des blocs try/catch
            $modifiedContent = Get-Content -Path $testScriptPath -Raw
            $modifiedContent | Should -Match "try\s*\{"
            $modifiedContent | Should -Match "catch\s*\{"
        }

        It "Ne devrait pas ajouter de blocs try/catch si le script en contient dÃ©jÃ " {
            # Le script contient dÃ©jÃ  des blocs try/catch aprÃ¨s le test prÃ©cÃ©dent
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath
            $result | Should -Be $false
        }

        It "Devrait ajouter des blocs try/catch mÃªme si le script en contient dÃ©jÃ  avec -Force" {
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath -Force
            $result | Should -Be $true
        }
    }

    Context "Journalisation des erreurs" {
        It "Devrait journaliser une erreur avec succÃ¨s" {
            # CrÃ©er une erreur
            $errorRecord = $null
            try {
                Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
            }
            catch {
                $errorRecord = $_
            }

            $errorRecord | Should -Not -BeNullOrEmpty

            # Journaliser l'erreur
            $result = Write-Log-Error -ErrorRecord $errorRecord -FunctionName "Test-Function" -Category "FileSystem"
            $result | Should -Be $true

            # VÃ©rifier que le fichier de journal a Ã©tÃ© crÃ©Ã©
            $logFile = Join-Path -Path $testRoot -ChildPath "error_log.json"
            Test-Path -Path $logFile | Should -Be $true

            # VÃ©rifier que l'erreur a Ã©tÃ© journalisÃ©e
            $logContent = Get-Content -Path $logFile -Raw | ConvertFrom-Json
            $logContent | Should -Not -BeNullOrEmpty
            $logContent[0].FunctionName | Should -Be "Test-Function"
            $logContent[0].Category | Should -Be "FileSystem"
        }
    }

    Context "SystÃ¨me de journalisation centralisÃ©" {
        It "Devrait crÃ©er un systÃ¨me de journalisation centralisÃ©" {
            $result = New-CentralizedLoggingSystem -LogPath $testRoot -IncludeAnalytics
            $result | Should -Be $true

            # VÃ©rifier que les rÃ©pertoires ont Ã©tÃ© crÃ©Ã©s
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Errors") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Warnings") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Information") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Debug") | Should -Be $true

            # VÃ©rifier que les scripts ont Ã©tÃ© crÃ©Ã©s
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "logging_config.json") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Rotate-Logs.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Analyze-Errors.ps1") | Should -Be $true
        }
    }

    Context "Ajout de solutions aux erreurs" {
        It "Devrait ajouter une solution Ã  une erreur connue" {
            # CrÃ©er une erreur
            $errorRecord = $null
            try {
                Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
            }
            catch {
                $errorRecord = $_
            }

            # Journaliser l'erreur pour l'ajouter Ã  la base de donnÃ©es
            Write-Log-Error -ErrorRecord $errorRecord -FunctionName "Test-Function" -Category "FileSystem"

            # Obtenir le hash de l'erreur
            $errorHash = Get-Hash-For-Error -ErrorRecord $errorRecord

            # Ajouter une solution
            $result = Add-ErrorSolution -ErrorHash $errorHash -Solution "VÃ©rifier que le chemin existe avant d'appeler Get-Content" -DatabasePath "$testRoot\error_database.json"
            $result | Should -Be $true

            # VÃ©rifier que la solution a Ã©tÃ© ajoutÃ©e
            $databasePath = Join-Path -Path $testRoot -ChildPath "error_database.json"
            Test-Path -Path $databasePath | Should -Be $true

            $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
            $database.$errorHash.Solutions | Should -Not -BeNullOrEmpty
            $database.$errorHash.Solutions[0].Solution | Should -Be "VÃ©rifier que le chemin existe avant d'appeler Get-Content"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorHandling -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Ne pas exÃ©cuter les tests automatiquement
# Invoke-Pester -Path $PSCommandPath -Output Detailed
