#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour le module ModuleDependencyDetector.

.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour le module ModuleDependencyDetector
    en utilisant Pester et gÃ©nÃ¨re un rapport de couverture de code.

.PARAMETER OutputPath
    Chemin du rÃ©pertoire de sortie pour les rapports de tests.
    Par dÃ©faut, utilise un sous-rÃ©pertoire "TestResults" dans le rÃ©pertoire courant.

.PARAMETER ShowCoverage
    Indique si la couverture de code doit Ãªtre affichÃ©e dans la console.

.EXAMPLE
    .\Run-Tests.ps1

.EXAMPLE
    .\Run-Tests.ps1 -OutputPath "C:\Reports" -ShowCoverage

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "TestResults"),

    [Parameter(Mandatory = $false)]
    [switch]$ShowCoverage
)

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory | Out-Null
}

# Configurer les options de Pester
$testResultsPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Path $PSScriptRoot -PassThru -OutputFormat NUnitXml -OutputFile $testResultsPath

# Afficher les rÃ©sultats
Write-Host "`nRÃ©sultats des tests :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s : $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s : $($testResults.SkippedCount)" -ForegroundColor Gray
Write-Host "  Tests non exÃ©cutÃ©s : $($testResults.NotRunCount)" -ForegroundColor Gray

# Afficher la couverture de code
if ($ShowCoverage) {
    Write-Host "`nCouverture de code :" -ForegroundColor Cyan
    Write-Host "  La couverture de code n'est pas disponible avec cette version de Pester." -ForegroundColor Yellow
}

# Afficher le chemin des rapports
Write-Host "`nRapports gÃ©nÃ©rÃ©s :" -ForegroundColor Cyan
Write-Host "  RÃ©sultats des tests : $testResultsPath" -ForegroundColor Gray

# Retourner le code de sortie
exit $testResults.FailedCount
