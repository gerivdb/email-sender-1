<#
.SYNOPSIS
    Tests unitaires pour le script Adaptive-ErrorCorrection.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Adaptive-ErrorCorrection
    en utilisant le framework Pester.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du script Ã  tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "AdaptiveErrorCorrectionTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Variable globale pour le chemin du modÃ¨le (accessible dans tous les tests)
$Global:TestModelPath = Join-Path -Path $env:TEMP -ChildPath "correction-model.json"

# DÃ©finir les tests Pester
Describe "Script Adaptive-ErrorCorrection" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-ErrorLearningSystem

        # CrÃ©er des erreurs dans la base de donnÃ©es pour les tests
        # Erreur de syntaxe avec solution
        $exception = New-Object System.Exception("Erreur de syntaxe : accolade fermante manquante")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "SyntaxError",
            [System.Management.Automation.ErrorCategory]::SyntaxError,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "SyntaxError" -Solution "Remplacer `"if (true) {`" par `"if (true) { }`""

        # Chemin codÃ© en dur avec solution
        $exception = New-Object System.Exception("Chemin codÃ© en dur dÃ©tectÃ© : D:\Logs\app.log")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "HardcodedPath",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "HardcodedPath" -Solution "Remplacer `"D:\Logs\app.log`" par `"(Join-Path -Path `$PSScriptRoot -ChildPath `"logs\app.log`")`""

        # Variable non dÃ©clarÃ©e avec solution
        $exception = New-Object System.Exception("Variable non dÃ©clarÃ©e : $undeclaredVar")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "UndeclaredVariable",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "UndeclaredVariable" -Solution "Remplacer `"`$undeclaredVar = `"Test`"`" par `"[string]`$undeclaredVar = `"Test`"`""

        # CrÃ©er un script de test avec des erreurs
        $testScript = @{
            Path = Join-Path -Path $testRoot -ChildPath "TestScript.ps1"
            Content = @"
# Script avec plusieurs problÃ¨mes
`$logPath = "D:\Logs\app.log"
`$undeclaredVar = "Test"
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
        }

        # CrÃ©er le fichier de test
        Set-Content -Path $testScript.Path -Value $testScript.Content -Force
    }

    Context "Analyse de l'historique des corrections" {
        It "Devrait analyser l'historique des corrections avec succÃ¨s" {
            # ExÃ©cuter le script en mode d'entraÃ®nement
            $output = & $scriptPath -TrainingMode -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que l'historique est analysÃ©
            $output | Should -Match "Analyse de .* erreurs avec des solutions"
            $output | Should -Match "ModÃ¨le de correction gÃ©nÃ©rÃ©"
        }

        It "Devrait gÃ©nÃ©rer un modÃ¨le de correction" {
            # VÃ©rifier que le modÃ¨le est gÃ©nÃ©rÃ©
            Test-Path -Path $Global:TestModelPath | Should -BeTrue

            # VÃ©rifier le contenu du modÃ¨le
            $modelContent = Get-Content -Path $Global:TestModelPath -Raw | ConvertFrom-Json
            $modelContent.Metadata | Should -Not -BeNullOrEmpty
            $modelContent.Patterns | Should -Not -BeNullOrEmpty
        }
    }

    Context "Chargement du modÃ¨le" {
        It "Devrait charger un modÃ¨le existant" {
            # ExÃ©cuter le script en mode par dÃ©faut
            $output = & $scriptPath -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que le modÃ¨le est chargÃ©
            $output | Should -Match "ModÃ¨le de correction chargÃ©"
            $output | Should -Match "Date de crÃ©ation"
            $output | Should -Match "Version"
        }
    }

    Context "Application du modÃ¨le" {
        It "Devrait tester le modÃ¨le sur un script" {
            # Copier le script de test
            $scriptToCopy = $testScript.Path
            $scriptToTest = Join-Path -Path $testRoot -ChildPath "TestScript_ToTest.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToTest -Force

            # ExÃ©cuter le script en mode de test
            $output = & $scriptPath -TestScript $scriptToTest -ModelPath $Global:TestModelPath -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que le modÃ¨le est testÃ©
            $output | Should -Match "Test du modÃ¨le de correction"
            $output | Should -Match "ModÃ¨le de correction chargÃ©"
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Ne pas exÃ©cuter les tests automatiquement pour Ã©viter la rÃ©cursion infinie
# # # # # Invoke-Pester -Path $PSCommandPath -Output Detailed # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie # CommentÃ© pour Ã©viter la rÃ©cursion infinie



