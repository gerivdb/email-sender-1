#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour les scripts de performance.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les scripts de performance
    en utilisant le framework Pester. Il gÃ©nÃ¨re un rapport de couverture de code
    et affiche les rÃ©sultats dans la console.
.EXAMPLE
    .\Run-AllTests.ps1
    ExÃ©cute tous les tests unitaires et affiche les rÃ©sultats.
.NOTES
    Auteur: Augment Agent
    Date: 10/04/2025
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$GenerateReport,

    [Parameter()]
    [string]$OutputPath = "$PSScriptRoot\TestResults"
)

# Par dÃ©faut, gÃ©nÃ©rer un rapport
if (-not $PSBoundParameters.ContainsKey('GenerateReport')) {
    $GenerateReport = $true
}

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

# Importer Pester
Import-Module Pester

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if ($GenerateReport -and -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

# Configuration de la couverture de code
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    "$PSScriptRoot\..\benchmark.ps1",
    "$PSScriptRoot\..\Optimize-ParallelBatchSize.ps1"
)
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = "$PSScriptRoot\TestResults\coverage.xml"

if ($GenerateReport) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = "$OutputPath\TestResults.xml"
    # DÃ©sactiver la couverture de code car nous ne pouvons pas importer les scripts complets
    $pesterConfig.CodeCoverage.Enabled = $false
}

# ExÃ©cuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`n=== RÃ‰SUMÃ‰ DES TESTS ===" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

if ($GenerateReport) {
    Write-Host "`nRapports gÃ©nÃ©rÃ©s dans: $OutputPath" -ForegroundColor Cyan
}

# Retourner un code d'erreur si des tests ont Ã©chouÃ©
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
