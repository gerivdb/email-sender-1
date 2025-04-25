#Requires -Version 5.1
<#
.SYNOPSIS
    Test unitaire simplifié.
.DESCRIPTION
    Ce script exécute un test unitaire simplifié pour vérifier que l'environnement de test fonctionne.
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Exécuter un test simple
Describe "Test simple" {
    It "Devrait toujours réussir" {
        $true | Should -Be $true
    }
    
    It "Devrait pouvoir accéder au système de fichiers" {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        Test-Path -Path $scriptPath | Should -Be $true
    }
}
