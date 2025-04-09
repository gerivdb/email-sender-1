<#
.SYNOPSIS
    Tests unitaires pour le script Validate-ErrorCorrections.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Validate-ErrorCorrections
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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Validate-ErrorCorrections.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ValidateErrorCorrectionsTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Script Validate-ErrorCorrections" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-ErrorLearningSystem

        # Créer des scripts de test
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
Write-Output "Données chargées: `$(`$data.Count) lignes"
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
Write-Output "Données chargées: `$(`$data.Count) lignes"
"@
        }

        # Créer les fichiers de test
        Set-Content -Path $validScript.Path -Value $validScript.Content -Force
        Set-Content -Path $invalidScript.Path -Value $invalidScript.Content -Force

        # Créer un répertoire pour les tests
        $testDir = Join-Path -Path $testRoot -ChildPath "Tests"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }

    Context "Validation de la syntaxe" {
        It "Devrait valider un script avec une syntaxe valide" {
            # Exécuter le script de validation
            $output = & $scriptPath -ScriptPath $validScript.Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que la syntaxe est validée
            $output | Should -Match "La syntaxe du script est valide"
        }

        It "Devrait détecter un script avec une syntaxe invalide" {
            # Exécuter le script de validation
            $output = & $scriptPath -ScriptPath $invalidScript.Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que la syntaxe est invalidée
            $output | Should -Match "La syntaxe du script est invalide"
            $output | Should -Match "Erreurs de syntaxe détectées"
        }
    }

    Context "Génération de script de test" {
        It "Devrait générer un script de test unitaire" {
            # Définir le chemin du script de test
            $testPath = Join-Path -Path $testDir -ChildPath "ValidScript.Tests.ps1"

            # Exécuter le script de validation avec génération de test
            & $scriptPath -ScriptPath $validScript.Path -GenerateTestScript -TestPath $testPath -ErrorAction SilentlyContinue

            # Vérifier que le script de test est généré
            Test-Path -Path $testPath | Should -BeTrue

            # Vérifier le contenu du script de test
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

            # Créer une sauvegarde factice
            $backupPath = "$scriptToValidate.bak"
            Copy-Item -Path $scriptToCopy -Destination $backupPath -Force

            # Exécuter le script de validation
            $output = & $scriptPath -ScriptPath $scriptToValidate -ErrorAction SilentlyContinue 6>&1

            # Vérifier que les corrections sont validées
            $output | Should -Match "La syntaxe du script est valide"
            $output | Should -Match "Validation réussie"

            # Vérifier que la sauvegarde est supprimée
            Test-Path -Path $backupPath | Should -BeFalse
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

# Ne pas exécuter les tests automatiquement pour éviter la récursion infinie
# # # # # Invoke-Pester -Path $PSCommandPath -Output Detailed # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie



