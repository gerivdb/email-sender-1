<#
.SYNOPSIS
    Tests unitaires pour les scripts d'apprentissage adaptatif et de validation des corrections.
.DESCRIPTION
    Ce script contient des tests unitaires pour les scripts d'apprentissage adaptatif et de validation des corrections.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests des scripts d'apprentissage adaptatif et de validation des corrections" {
    BeforeAll {
        # Définir le chemin des scripts à tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:adaptiveScriptPath = Join-Path -Path $script:moduleRoot -ChildPath "Adaptive-ErrorCorrection.Simplified.ps1"
        $script:validateScriptPath = Join-Path -Path $script:moduleRoot -ChildPath "Validate-ErrorCorrections.Simplified.ps1"

        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "AdaptiveCorrectionTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # Créer un script de test valide
        $script:validScriptPath = Join-Path -Path $script:testRoot -ChildPath "ValidScript.ps1"
        $validScriptContent = @"
# Script de test valide
[CmdletBinding()]
param (
    [Parameter(Mandatory = `$true)]
    [string]`$InputPath,

    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = ""
)

# Initialiser les variables
`$scriptRoot = `$PSScriptRoot
`$logPath = Join-Path -Path `$scriptRoot -ChildPath "logs\script.log"

# Créer le répertoire de logs s'il n'existe pas
if (-not (Test-Path -Path (Split-Path -Path `$logPath -Parent))) {
    New-Item -Path (Split-Path -Path `$logPath -Parent) -ItemType Directory -Force | Out-Null
}

# Lire le contenu du fichier d'entrée
try {
    `$content = Get-Content -Path `$InputPath -Raw -ErrorAction Stop
}
catch {
    Write-Error "Impossible de lire le fichier d'entrée : `$_"
    exit 1
}

# Traiter le contenu
`$processedContent = `$content.ToUpper()

# Définir le chemin de sortie s'il n'est pas spécifié
if (-not `$OutputPath) {
    `$OutputPath = Join-Path -Path `$scriptRoot -ChildPath "output\processed.txt"
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path (Split-Path -Path `$OutputPath -Parent))) {
    New-Item -Path (Split-Path -Path `$OutputPath -Parent) -ItemType Directory -Force | Out-Null
}

# Enregistrer le contenu traité
try {
    Set-Content -Path `$OutputPath -Value `$processedContent -ErrorAction Stop
    Write-Output "Traitement terminé. Fichier enregistré : `$OutputPath"
}
catch {
    Write-Error "Impossible d'enregistrer le fichier de sortie : `$_"
    exit 1
}
"@
        Set-Content -Path $script:validScriptPath -Value $validScriptContent -Force

        # Créer un script de test avec des erreurs
        $script:invalidScriptPath = Join-Path -Path $script:testRoot -ChildPath "InvalidScript.ps1"
        $invalidScriptContent = @"
# Script de test avec des erreurs
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process

# Erreur de syntaxe
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
        Set-Content -Path $script:invalidScriptPath -Value $invalidScriptContent -Force

        # Créer un répertoire pour le modèle
        $script:modelDir = Join-Path -Path $script:testRoot -ChildPath "Models"
        New-Item -Path $script:modelDir -ItemType Directory -Force | Out-Null

        # Définir le chemin du modèle
        $script:modelPath = Join-Path -Path $script:modelDir -ChildPath "correction-model.json"
    }

    Context "Apprentissage adaptatif" {
        It "Devrait générer un modèle de correction" {
            # Exécuter le script d'apprentissage adaptatif en mode d'apprentissage
            $output = & $script:adaptiveScriptPath -TrainingMode -ModelPath $script:modelPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # Vérifier que le modèle est généré
            $outputString | Should -Match "Mode d'apprentissage"
            $outputString | Should -Match "Modèle généré"

            # Vérifier que le fichier du modèle existe
            Test-Path -Path $script:modelPath | Should -Be $true

            # Vérifier le contenu du modèle
            $modelContent = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            $modelContent.Metadata | Should -Not -BeNullOrEmpty
            $modelContent.Patterns | Should -Not -BeNullOrEmpty
            $modelContent.Patterns.Count | Should -BeGreaterThan 0
        }
    }

    Context "Validation des corrections" {
        It "Devrait valider la syntaxe d'un script correct" {
            # Exécuter le script de validation sur un script valide
            $output = & $script:validateScriptPath -ScriptPath $script:validScriptPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # Vérifier que la syntaxe du script est validée
            $outputString | Should -Match "La syntaxe du script est valide"
        }

        It "Devrait détecter les problèmes dans un script incorrect" {
            # Exécuter le script de validation sur un script invalide
            $output = & $script:validateScriptPath -ScriptPath $script:invalidScriptPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # Vérifier que les problèmes sont détectés
            $outputString | Should -Match "Erreurs de syntaxe détectées"
            $outputString | Should -Match "Problèmes de bonnes pratiques détectés"
            $outputString | Should -Match "Le script présente des problèmes"
        }
    }

    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
