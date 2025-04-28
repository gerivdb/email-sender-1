#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour Repair-PSScriptAnalyzerIssues.ps1.
.DESCRIPTION
    Ce script importe correctement le script principal et exÃ©cute les tests unitaires.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Repair-PSScriptAnalyzerIssues.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Ã  tester n'existe pas: $scriptPath"
}

# Importer les fonctions du script Ã  tester
. $scriptPath

# ExÃ©cuter les tests
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "Repair-PSScriptAnalyzerIssues.Tests.ps1"
Invoke-Pester -Path $testPath -Output Detailed
