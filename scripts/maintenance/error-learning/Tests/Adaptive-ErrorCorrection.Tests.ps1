<#
.SYNOPSIS
    Tests unitaires pour le script Adaptive-ErrorCorrection.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Adaptive-ErrorCorrection
    en utilisant le framework Pester.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du script à tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "AdaptiveErrorCorrectionTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Variable globale pour le chemin du modèle (accessible dans tous les tests)
$Global:TestModelPath = Join-Path -Path $env:TEMP -ChildPath "correction-model.json"

# Définir les tests Pester
Describe "Script Adaptive-ErrorCorrection" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-ErrorLearningSystem

        # Créer des erreurs dans la base de données pour les tests
        # Erreur de syntaxe avec solution
        $exception = New-Object System.Exception("Erreur de syntaxe : accolade fermante manquante")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "SyntaxError",
            [System.Management.Automation.ErrorCategory]::SyntaxError,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "SyntaxError" -Solution "Remplacer `"if (true) {`" par `"if (true) { }`""

        # Chemin codé en dur avec solution
        $exception = New-Object System.Exception("Chemin codé en dur détecté : D:\Logs\app.log")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "HardcodedPath",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "HardcodedPath" -Solution "Remplacer `"D:\Logs\app.log`" par `"(Join-Path -Path `$PSScriptRoot -ChildPath `"logs\app.log`")`""

        # Variable non déclarée avec solution
        $exception = New-Object System.Exception("Variable non déclarée : $undeclaredVar")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "UndeclaredVariable",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "UndeclaredVariable" -Solution "Remplacer `"`$undeclaredVar = `"Test`"`" par `"[string]`$undeclaredVar = `"Test`"`""

        # Créer un script de test avec des erreurs
        $testScript = @{
            Path = Join-Path -Path $testRoot -ChildPath "TestScript.ps1"
            Content = @"
# Script avec plusieurs problèmes
`$logPath = "D:\Logs\app.log"
`$undeclaredVar = "Test"
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
        }

        # Créer le fichier de test
        Set-Content -Path $testScript.Path -Value $testScript.Content -Force
    }

    Context "Analyse de l'historique des corrections" {
        It "Devrait analyser l'historique des corrections avec succès" {
            # Exécuter le script en mode d'entraînement
            $output = & $scriptPath -TrainingMode -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # Vérifier que l'historique est analysé
            $output | Should -Match "Analyse de .* erreurs avec des solutions"
            $output | Should -Match "Modèle de correction généré"
        }

        It "Devrait générer un modèle de correction" {
            # Vérifier que le modèle est généré
            Test-Path -Path $Global:TestModelPath | Should -BeTrue

            # Vérifier le contenu du modèle
            $modelContent = Get-Content -Path $Global:TestModelPath -Raw | ConvertFrom-Json
            $modelContent.Metadata | Should -Not -BeNullOrEmpty
            $modelContent.Patterns | Should -Not -BeNullOrEmpty
        }
    }

    Context "Chargement du modèle" {
        It "Devrait charger un modèle existant" {
            # Exécuter le script en mode par défaut
            $output = & $scriptPath -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # Vérifier que le modèle est chargé
            $output | Should -Match "Modèle de correction chargé"
            $output | Should -Match "Date de création"
            $output | Should -Match "Version"
        }
    }

    Context "Application du modèle" {
        It "Devrait tester le modèle sur un script" {
            # Copier le script de test
            $scriptToCopy = $testScript.Path
            $scriptToTest = Join-Path -Path $testRoot -ChildPath "TestScript_ToTest.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToTest -Force

            # Exécuter le script en mode de test
            $output = & $scriptPath -TestScript $scriptToTest -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # Vérifier que le modèle est testé
            $output | Should -Match "Test du modèle de correction"
            $output | Should -Match "Modèle de correction chargé"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue

        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
