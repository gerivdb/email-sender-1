#Requires -Version 5.1
<#
.SYNOPSIS
    Test unitaire simplifiÃ©.
.DESCRIPTION
    Ce script exÃ©cute un test unitaire simplifiÃ© pour vÃ©rifier que l'environnement de test fonctionne.
#>

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# ExÃ©cuter un test simple
Describe "Test simple" {
    It "Devrait toujours rÃ©ussir" {
        $true | Should -Be $true
    }
    
    It "Devrait pouvoir accÃ©der au systÃ¨me de fichiers" {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        Test-Path -Path $scriptPath | Should -Be $true
    }
}
