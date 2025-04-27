<#
.SYNOPSIS
    Tests unitaires pour les scripts d'apprentissage adaptatif et de validation des corrections.
.DESCRIPTION
    Ce script contient des tests unitaires pour les scripts d'apprentissage adaptatif et de validation des corrections.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests des scripts d'apprentissage adaptatif et de validation des corrections" {
    BeforeAll {
        # DÃ©finir le chemin des scripts Ã  tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:adaptiveScriptPath = Join-Path -Path $script:moduleRoot -ChildPath "Adaptive-ErrorCorrection.Simplified.ps1"
        $script:validateScriptPath = Join-Path -Path $script:moduleRoot -ChildPath "Validate-ErrorCorrections.Simplified.ps1"

        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "AdaptiveCorrectionTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # CrÃ©er un script de test valide
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

# CrÃ©er le rÃ©pertoire de logs s'il n'existe pas
if (-not (Test-Path -Path (Split-Path -Path `$logPath -Parent))) {
    New-Item -Path (Split-Path -Path `$logPath -Parent) -ItemType Directory -Force | Out-Null
}

# Lire le contenu du fichier d'entrÃ©e
try {
    `$content = Get-Content -Path `$InputPath -Raw -ErrorAction Stop
}
catch {
    Write-Error "Impossible de lire le fichier d'entrÃ©e : `$_"
    exit 1
}

# Traiter le contenu
`$processedContent = `$content.ToUpper()

# DÃ©finir le chemin de sortie s'il n'est pas spÃ©cifiÃ©
if (-not `$OutputPath) {
    `$OutputPath = Join-Path -Path `$scriptRoot -ChildPath "output\processed.txt"
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path (Split-Path -Path `$OutputPath -Parent))) {
    New-Item -Path (Split-Path -Path `$OutputPath -Parent) -ItemType Directory -Force | Out-Null
}

# Enregistrer le contenu traitÃ©
try {
    Set-Content -Path `$OutputPath -Value `$processedContent -ErrorAction Stop
    Write-Output "Traitement terminÃ©. Fichier enregistrÃ© : `$OutputPath"
}
catch {
    Write-Error "Impossible d'enregistrer le fichier de sortie : `$_"
    exit 1
}
"@
        Set-Content -Path $script:validScriptPath -Value $validScriptContent -Force

        # CrÃ©er un script de test avec des erreurs
        $script:invalidScriptPath = Join-Path -Path $script:testRoot -ChildPath "InvalidScript.ps1"
        $invalidScriptContent = @"
# Script de test avec des erreurs
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolÃ¨te
`$processes = Get-WmiObject -Class Win32_Process

# Erreur de syntaxe
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
        Set-Content -Path $script:invalidScriptPath -Value $invalidScriptContent -Force

        # CrÃ©er un rÃ©pertoire pour le modÃ¨le
        $script:modelDir = Join-Path -Path $script:testRoot -ChildPath "Models"
        New-Item -Path $script:modelDir -ItemType Directory -Force | Out-Null

        # DÃ©finir le chemin du modÃ¨le
        $script:modelPath = Join-Path -Path $script:modelDir -ChildPath "correction-model.json"
    }

    Context "Apprentissage adaptatif" {
        It "Devrait gÃ©nÃ©rer un modÃ¨le de correction" {
            # ExÃ©cuter le script d'apprentissage adaptatif en mode d'apprentissage
            $output = & $script:adaptiveScriptPath -TrainingMode -ModelPath $script:modelPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # VÃ©rifier que le modÃ¨le est gÃ©nÃ©rÃ©
            $outputString | Should -Match "Mode d'apprentissage"
            $outputString | Should -Match "ModÃ¨le gÃ©nÃ©rÃ©"

            # VÃ©rifier que le fichier du modÃ¨le existe
            Test-Path -Path $script:modelPath | Should -Be $true

            # VÃ©rifier le contenu du modÃ¨le
            $modelContent = Get-Content -Path $script:modelPath -Raw | ConvertFrom-Json
            $modelContent.Metadata | Should -Not -BeNullOrEmpty
            $modelContent.Patterns | Should -Not -BeNullOrEmpty
            $modelContent.Patterns.Count | Should -BeGreaterThan 0
        }
    }

    Context "Validation des corrections" {
        It "Devrait valider la syntaxe d'un script correct" {
            # ExÃ©cuter le script de validation sur un script valide
            $output = & $script:validateScriptPath -ScriptPath $script:validScriptPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # VÃ©rifier que la syntaxe du script est validÃ©e
            $outputString | Should -Match "La syntaxe du script est valide"
        }

        It "Devrait dÃ©tecter les problÃ¨mes dans un script incorrect" {
            # ExÃ©cuter le script de validation sur un script invalide
            $output = & $script:validateScriptPath -ScriptPath $script:invalidScriptPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # VÃ©rifier que les problÃ¨mes sont dÃ©tectÃ©s
            $outputString | Should -Match "Erreurs de syntaxe dÃ©tectÃ©es"
            $outputString | Should -Match "ProblÃ¨mes de bonnes pratiques dÃ©tectÃ©s"
            $outputString | Should -Match "Le script prÃ©sente des problÃ¨mes"
        }
    }

    AfterAll {
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}
