#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'organisation des scripts.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'organisation
    des scripts de maintenance, en utilisant le framework Pester.
.EXAMPLE
    Invoke-Pester -Path ".\OrganizationFunctions.Tests.ps1"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Fonctions à tester
function Get-ScriptCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        
        [Parameter(Mandatory = $false)]
        [string]$Content = ""
    )
    
    $lowerName = $FileName.ToLower()
    
    # Catégorisation basée sur des mots-clés dans le nom du fichier
    if ($lowerName -match 'roadmap') { return 'roadmap' }
    if ($lowerName -match 'path') { return 'paths' }
    if ($lowerName -match 'checkbox') { return 'modes' }
    if ($lowerName -match 'analyze|analysis|feedback') { return 'api' }
    if ($lowerName -match 'test') { return 'test' }
    if ($lowerName -match 'vscode') { return 'vscode' }
    if ($lowerName -match 'git') { return 'git' }
    if ($lowerName -match 'clean|fix|repair|consolidate') { return 'cleanup' }
    if ($lowerName -match 'mode|check') { return 'modes' }
    if ($lowerName -match 'encoding') { return 'encoding' }
    if ($lowerName -match 'log') { return 'logs' }
    if ($lowerName -match 'performance|perf') { return 'performance' }
    if ($lowerName -match 'backup') { return 'backups' }
    if ($lowerName -match 'init|install') { return 'environment-compatibility' }
    if ($lowerName -match 'update') { 
        if ($lowerName -match 'vscode') { return 'vscode' }
        if ($lowerName -match 'roadmap') { return 'roadmap' }
        if ($lowerName -match 'path') { return 'paths' }
        if ($lowerName -match 'checkbox') { return 'modes' }
        return 'utils' 
    }
    
    # Analyse du contenu si disponible
    if ($Content) {
        if ($Content -match 'roadmap|plan') { return 'roadmap' }
        if ($Content -match 'path|chemin') { return 'paths' }
        if ($Content -match 'checkbox|case à cocher') { return 'modes' }
        if ($Content -match 'analyze|analyse|feedback') { return 'api' }
        if ($Content -match 'test|pester') { return 'test' }
        if ($Content -match 'vscode|vs code') { return 'vscode' }
        if ($Content -match 'git|commit|push') { return 'git' }
        if ($Content -match 'clean|fix|repair|nettoyer|réparer') { return 'cleanup' }
        if ($Content -match 'mode|check|vérifier') { return 'modes' }
        if ($Content -match 'encoding|encodage|utf') { return 'encoding' }
        if ($Content -match 'log|journal') { return 'logs' }
        if ($Content -match 'performance|perf|mesure') { return 'performance' }
        if ($Content -match 'backup|sauvegarde') { return 'backups' }
    }
    
    # Par défaut, retourner 'utils'
    return 'utils'
}

# Tests Pester
Describe "Tests des fonctions d'organisation des scripts" {
    Context "Tests de la fonction Get-ScriptCategory" {
        It "Devrait retourner 'roadmap' pour un fichier contenant 'roadmap' dans son nom" {
            Get-ScriptCategory -FileName "Update-Roadmap.ps1" | Should -Be "roadmap"
        }

        It "Devrait retourner 'paths' pour un fichier contenant 'path' dans son nom" {
            Get-ScriptCategory -FileName "normalize-project-paths.ps1" | Should -Be "paths"
        }

        It "Devrait retourner 'modes' pour un fichier contenant 'checkbox' dans son nom" {
            Get-ScriptCategory -FileName "update-checkbox-function.ps1" | Should -Be "modes"
        }

        It "Devrait retourner 'api' pour un fichier contenant 'analyze' dans son nom" {
            Get-ScriptCategory -FileName "Analyze-Feedback.ps1" | Should -Be "api"
        }

        It "Devrait retourner 'test' pour un fichier contenant 'test' dans son nom" {
            Get-ScriptCategory -FileName "test-script-at-root.ps1" | Should -Be "test"
        }

        It "Devrait retourner 'vscode' pour un fichier contenant 'vscode' dans son nom" {
            Get-ScriptCategory -FileName "update-vscode-cache.ps1" | Should -Be "vscode"
        }

        It "Devrait retourner 'git' pour un fichier contenant 'git' dans son nom" {
            Get-ScriptCategory -FileName "update-git-hooks.ps1" | Should -Be "git"
        }

        It "Devrait retourner 'cleanup' pour un fichier contenant 'fix' dans son nom" {
            Get-ScriptCategory -FileName "Fix-RoadmapScripts.ps1" | Should -Be "cleanup"
        }

        It "Devrait retourner 'modes' pour un fichier contenant 'mode' dans son nom" {
            Get-ScriptCategory -FileName "debug-mode.ps1" | Should -Be "modes"
        }

        It "Devrait retourner 'encoding' pour un fichier contenant 'encoding' dans son nom" {
            Get-ScriptCategory -FileName "fix-encoding-issues.ps1" | Should -Be "encoding"
        }

        It "Devrait retourner 'logs' pour un fichier contenant 'log' dans son nom" {
            Get-ScriptCategory -FileName "clean-log-files.ps1" | Should -Be "logs"
        }

        It "Devrait retourner 'performance' pour un fichier contenant 'performance' dans son nom" {
            Get-ScriptCategory -FileName "measure-performance.ps1" | Should -Be "performance"
        }

        It "Devrait retourner 'backups' pour un fichier contenant 'backup' dans son nom" {
            Get-ScriptCategory -FileName "create-backup.ps1" | Should -Be "backups"
        }

        It "Devrait retourner 'environment-compatibility' pour un fichier contenant 'init' dans son nom" {
            Get-ScriptCategory -FileName "init-maintenance.ps1" | Should -Be "environment-compatibility"
        }

        It "Devrait retourner 'utils' pour un fichier sans mot-clé reconnu" {
            Get-ScriptCategory -FileName "random-script.ps1" | Should -Be "utils"
        }

        It "Devrait analyser le contenu si le nom ne contient pas de mot-clé reconnu" {
            $content = "# Script pour tester les performances du système"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "performance"
        }

        It "Devrait retourner 'utils' si ni le nom ni le contenu ne contiennent de mot-clé reconnu" {
            $content = "# Script sans mot-clé reconnu"
            Get-ScriptCategory -FileName "random-script.ps1" -Content $content | Should -Be "utils"
        }
    }
}
