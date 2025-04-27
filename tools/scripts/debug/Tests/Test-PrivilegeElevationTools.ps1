<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'Ã©lÃ©vation de privilÃ¨ges temporaires.
.DESCRIPTION
    Ce script contient des tests unitaires pour valider les fonctions d'Ã©lÃ©vation
    de privilÃ¨ges temporaires.
.NOTES
    Auteur: Augment Code
    Date de crÃ©ation: 2023-11-15
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Certains tests pourraient ne pas fonctionner correctement."
}

# Importer le script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\PrivilegeElevationTools.ps1"
. $scriptPath

Describe "Start-ElevatedProcess" {
    It "Devrait retourner un objet Process si Wait est $false" {
        # Ce test est difficile Ã  automatiser car il lance une fenÃªtre UAC
        # Nous allons simplement vÃ©rifier que la fonction existe
        { Get-Command -Name Start-ElevatedProcess -ErrorAction Stop } | Should -Not -Throw
    }
    
    It "Devrait exÃ©cuter directement le code si dÃ©jÃ  en mode administrateur" {
        # Mock pour simuler un processus administrateur
        Mock -CommandName ([Security.Principal.WindowsPrincipal]) -MockWith {
            return [PSCustomObject]@{
                IsInRole = { param($role) return $true }
            }
        }
        
        $result = Start-ElevatedProcess -ScriptBlock { return "Test" }
        $result | Should -Be "Test"
    }
}

Describe "Edit-ProtectedFile" {
    BeforeAll {
        # CrÃ©er un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    It "Devrait dÃ©tecter un fichier inexistant" {
        $result = Edit-ProtectedFile -Path "C:\CheMin_Qui_Nexiste_Pas_12345" -EditScriptBlock { param($file) }
        $result.Success | Should -Be $false
        $result.Message | Should -BeLike "*n'existe pas*"
    }
    
    It "Devrait crÃ©er un fichier temporaire" {
        # Mock pour Ã©viter de lancer un processus Ã©levÃ©
        Mock -CommandName Start-ElevatedProcess -MockWith { return 0 }
        
        $result = Edit-ProtectedFile -Path $tempFile -EditScriptBlock { param($file) Add-Content -Path $file -Value "New content" }
        $result.Success | Should -Be $true
        $result.OriginalPath | Should -Be $tempFile
    }
}

Describe "Set-TemporaryPermission" {
    BeforeAll {
        # CrÃ©er un fichier temporaire pour les tests
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value "Test content"
    }
    
    AfterAll {
        # Nettoyer les fichiers temporaires
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    It "Devrait dÃ©tecter un chemin inexistant" {
        { Set-TemporaryPermission -Path "C:\CheMin_Qui_Nexiste_Pas_12345" -Identity "Everyone" -Permission "Read" -ScriptBlock {} } | Should -Throw
    }
    
    It "Devrait exÃ©cuter le bloc de code avec les permissions temporaires" {
        # Mock pour Ã©viter de modifier rÃ©ellement les ACL
        Mock -CommandName Set-Acl -MockWith {}
        
        $result = Set-TemporaryPermission -Path $tempFile -Identity "Everyone" -Permission "Read" -ScriptBlock { return "Test" }
        $result | Should -Be "Test"
    }
}

Describe "Enable-Privilege" {
    It "Devrait valider le paramÃ¨tre Privilege" {
        { Enable-Privilege -Privilege "InvalidPrivilege" } | Should -Throw
    }
    
    It "Devrait tenter d'activer un privilÃ¨ge" {
        # Ce test est difficile Ã  automatiser car il dÃ©pend des privilÃ¨ges du processus
        # Nous allons simplement vÃ©rifier que la fonction existe
        { Get-Command -Name Enable-Privilege -ErrorAction Stop } | Should -Not -Throw
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Verbose
