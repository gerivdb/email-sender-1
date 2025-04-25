<#
.SYNOPSIS
    Tests unitaires pour le module de gestion d'erreurs.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement du module de gestion d'erreurs.
    Il utilise le framework Pester pour exécuter les tests.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
    Prérequis:      Pester 5.0 ou supérieur
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Définir le chemin du module à tester
$moduleRoot = Split-Path -Path $PSCommandPath -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorHandling.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
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

# Définir les tests Pester
Describe "Module de gestion d'erreurs" {
    BeforeAll {
        # Importer le module à tester
        Import-Module $modulePath -Force

        # Initialiser le module avec un répertoire de test
        $logPath = Join-Path -Path $testRoot -ChildPath "Logs"
        Initialize-ErrorHandling -LogPath $logPath
    }

    Context "Initialisation du module" {
        It "Devrait initialiser le module avec succès" {
            $result = Initialize-ErrorHandling -LogPath $testRoot
            $result | Should -Be $true
        }

        It "Devrait créer le répertoire de journaux" {
            Test-Path -Path $testRoot | Should -Be $true
        }
    }

    Context "Ajout de blocs try/catch" {
        It "Devrait ajouter des blocs try/catch à un script" {
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath -BackupFile
            $result | Should -Be $true

            # Vérifier que le fichier de sauvegarde a été créé
            Test-Path -Path "$testScriptPath.bak" | Should -Be $true

            # Vérifier que le script contient maintenant des blocs try/catch
            $modifiedContent = Get-Content -Path $testScriptPath -Raw
            $modifiedContent | Should -Match "try\s*\{"
            $modifiedContent | Should -Match "catch\s*\{"
        }

        It "Ne devrait pas ajouter de blocs try/catch si le script en contient déjà" {
            # Le script contient déjà des blocs try/catch après le test précédent
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath
            $result | Should -Be $false
        }

        It "Devrait ajouter des blocs try/catch même si le script en contient déjà avec -Force" {
            $result = Add-TryCatchBlock -ScriptPath $testScriptPath -Force
            $result | Should -Be $true
        }
    }

    Context "Journalisation des erreurs" {
        It "Devrait journaliser une erreur avec succès" {
            # Créer une erreur
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

            # Vérifier que le fichier de journal a été créé
            $logFile = Join-Path -Path $testRoot -ChildPath "error_log.json"
            Test-Path -Path $logFile | Should -Be $true

            # Vérifier que l'erreur a été journalisée
            $logContent = Get-Content -Path $logFile -Raw | ConvertFrom-Json
            $logContent | Should -Not -BeNullOrEmpty
            $logContent[0].FunctionName | Should -Be "Test-Function"
            $logContent[0].Category | Should -Be "FileSystem"
        }
    }

    Context "Système de journalisation centralisé" {
        It "Devrait créer un système de journalisation centralisé" {
            $result = New-CentralizedLoggingSystem -LogPath $testRoot -IncludeAnalytics
            $result | Should -Be $true

            # Vérifier que les répertoires ont été créés
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Errors") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Warnings") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Information") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Debug") | Should -Be $true

            # Vérifier que les scripts ont été créés
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "logging_config.json") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Rotate-Logs.ps1") | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "Analyze-Errors.ps1") | Should -Be $true
        }
    }

    Context "Ajout de solutions aux erreurs" {
        It "Devrait ajouter une solution à une erreur connue" {
            # Créer une erreur
            $errorRecord = $null
            try {
                Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
            }
            catch {
                $errorRecord = $_
            }

            # Journaliser l'erreur pour l'ajouter à la base de données
            Write-Log-Error -ErrorRecord $errorRecord -FunctionName "Test-Function" -Category "FileSystem"

            # Obtenir le hash de l'erreur
            $errorHash = Get-Hash-For-Error -ErrorRecord $errorRecord

            # Ajouter une solution
            $result = Add-ErrorSolution -ErrorHash $errorHash -Solution "Vérifier que le chemin existe avant d'appeler Get-Content" -DatabasePath "$testRoot\error_database.json"
            $result | Should -Be $true

            # Vérifier que la solution a été ajoutée
            $databasePath = Join-Path -Path $testRoot -ChildPath "error_database.json"
            Test-Path -Path $databasePath | Should -Be $true

            $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
            $database.$errorHash.Solutions | Should -Not -BeNullOrEmpty
            $database.$errorHash.Solutions[0].Solution | Should -Be "Vérifier que le chemin existe avant d'appeler Get-Content"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorHandling -Force -ErrorAction SilentlyContinue

        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Ne pas exécuter les tests automatiquement
# Invoke-Pester -Path $PSCommandPath -Output Detailed
