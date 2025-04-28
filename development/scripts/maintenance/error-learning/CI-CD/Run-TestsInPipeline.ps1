<#
.SYNOPSIS
    Script pour exÃ©cuter les tests dans un pipeline CI/CD.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires et d'intÃ©gration du systÃ¨me d'apprentissage des erreurs
    dans un pipeline CI/CD et gÃ©nÃ¨re un rapport des rÃ©sultats.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut, utilise le rÃ©pertoire courant.
.EXAMPLE
    .\Run-TestsInPipeline.ps1
    ExÃ©cute tous les tests unitaires et d'intÃ©gration et gÃ©nÃ¨re un rapport XML des rÃ©sultats.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestResults")
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin des tests
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$testRoot = Join-Path -Path $scriptRoot -ChildPath "Tests"
$testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    (Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"),
    (Join-Path -Path $scriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Auto-CorrectErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Validate-ErrorCorrections.ps1")
)
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Afficher le chemin des rÃ©sultats
Write-Host "RÃ©sultats des tests enregistrÃ©s dans: $OutputPath" -ForegroundColor Cyan
Write-Host "  RÃ©sultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Yellow
Write-Host "  Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $testResults.FailedCount
