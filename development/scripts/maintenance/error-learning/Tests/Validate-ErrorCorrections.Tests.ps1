<#
.SYNOPSIS
    Tests unitaires pour le script Validate-ErrorCorrections.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Validate-ErrorCorrections
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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Validate-ErrorCorrections.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ValidateErrorCorrectionsTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# DÃ©finir les tests Pester
Describe "Script Validate-ErrorCorrections" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-ErrorLearningSystem

        # CrÃ©er des scripts de test
        $validScript = @{
            Path = Join-Path -Path $testRoot -ChildPath "ValidScript.ps1"
            Content = @"
# Script valide
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )

    try {
        `$content = Get-Content -Path `$Path -ErrorAction Stop
        return `$content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: `$_"
        return `$null
    }
}

# Appeler la fonction
`$data = Get-TestData -Path "`$PSScriptRoot\data.txt"
Write-Output "DonnÃ©es chargÃ©es: `$(`$data.Count) lignes"
"@
        }

        $invalidScript = @{
            Path = Join-Path -Path $testRoot -ChildPath "InvalidScript.ps1"
            Content = @"
# Script invalide avec une erreur de syntaxe
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )

    try {
        `$content = Get-Content -Path `$Path -ErrorAction Stop
        return `$content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: `$_"
        return `$null
    }
# Accolade fermante manquante

# Appeler la fonction
`$data = Get-TestData -Path "`$PSScriptRoot\data.txt"
Write-Output "DonnÃ©es chargÃ©es: `$(`$data.Count) lignes"
"@
        }

        # CrÃ©er les fichiers de test
        Set-Content -Path $validScript.Path -Value $validScript.Content -Force
        Set-Content -Path $invalidScript.Path -Value $invalidScript.Content -Force

        # CrÃ©er un rÃ©pertoire pour les tests
        $testDir = Join-Path -Path $testRoot -ChildPath "Tests"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }

    Context "Validation de la syntaxe" {
        It "Devrait valider un script avec une syntaxe valide" {
            # ExÃ©cuter le script de validation
            $output = & $scriptPath -ScriptPath $validScript.Path -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que la syntaxe est validÃ©e
            $output | Should -Match "La syntaxe du script est valide"
        }

        It "Devrait dÃ©tecter un script avec une syntaxe invalide" {
            # ExÃ©cuter le script de validation
            $output = & $scriptPath -ScriptPath $invalidScript.Path -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que la syntaxe est invalidÃ©e
            $output | Should -Match "La syntaxe du script est invalide"
            $output | Should -Match "Erreurs de syntaxe dÃ©tectÃ©es"
        }
    }

    Context "GÃ©nÃ©ration de script de test" {
        It "Devrait gÃ©nÃ©rer un script de test unitaire" {
            # DÃ©finir le chemin du script de test
            $testPath = Join-Path -Path $testDir -ChildPath "ValidScript.Tests.ps1"

            # ExÃ©cuter le script de validation avec gÃ©nÃ©ration de test
            & $scriptPath -ScriptPath $validScript.Path -GenerateTestScript -TestPath $testPath -ErrorAction SilentlyContinue

            # VÃ©rifier que le script de test est gÃ©nÃ©rÃ©
            Test-Path -Path $testPath | Should -BeTrue

            # VÃ©rifier le contenu du script de test
            $testContent = Get-Content -Path $testPath -Raw
            $testContent | Should -Match "Tests unitaires pour le script ValidScript"
            $testContent | Should -Match "Describe"
            $testContent | Should -Match "Context"
            $testContent | Should -Match "It"
            $testContent | Should -Match "Get-TestData"
        }
    }

    Context "Validation des corrections" {
        It "Devrait valider les corrections d'un script valide" {
            # Copier le script valide
            $scriptToCopy = $validScript.Path
            $scriptToValidate = Join-Path -Path $testRoot -ChildPath "ValidScript_ToValidate.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToValidate -Force

            # CrÃ©er une sauvegarde factice
            $backupPath = "$scriptToValidate.bak"
            Copy-Item -Path $scriptToCopy -Destination $backupPath -Force

            # ExÃ©cuter le script de validation
            $output = & $scriptPath -ScriptPath $scriptToValidate -ErrorAction SilentlyContinue 6>&1

            # VÃ©rifier que les corrections sont validÃ©es
            $output | Should -Match "La syntaxe du script est valide"
            $output | Should -Match "Validation rÃ©ussie"

            # VÃ©rifier que la sauvegarde est supprimÃ©e
            Test-Path -Path $backupPath | Should -BeFalse
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



