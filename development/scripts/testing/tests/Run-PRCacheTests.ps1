#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le systÃ¨me de cache d'analyse des pull requests.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le systÃ¨me de cache d'analyse des pull requests,
    y compris les tests pour le module PRAnalysisCache.psm1 et les scripts associÃ©s.
.PARAMETER OutputFormat
    Le format de sortie des rÃ©sultats des tests.
    Valeurs possibles: "Normal", "Detailed", "Diagnostic", "Minimal", "NUnitXml", "JUnitXml"
    Par dÃ©faut: "Detailed"
.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats des tests si un format XML est spÃ©cifiÃ©.
    Par dÃ©faut: "reports\pr-testing\cache_tests_results.xml"
.EXAMPLE
    .\Run-PRCacheTests.ps1
    ExÃ©cute tous les tests avec le format de sortie dÃ©taillÃ©.
.EXAMPLE
    .\Run-PRCacheTests.ps1 -OutputFormat "NUnitXml" -OutputPath "reports\cache_tests.xml"
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport NUnit XML.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Normal", "Detailed", "Diagnostic", "Minimal", "NUnitXml", "JUnitXml")]
    [string]$OutputFormat = "Detailed",

    [Parameter()]
    [string]$OutputPath = "reports\pr-testing\cache_tests_results.xml"
)

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Chemin des tests
$testsPath = $PSScriptRoot

# VÃ©rifier que le rÃ©pertoire des tests existe
if (-not (Test-Path -Path $testsPath)) {
    throw "RÃ©pertoire de tests non trouvÃ©: $testsPath"
}

# CrÃ©er le rÃ©pertoire de rapports si nÃ©cessaire
if ($OutputFormat -in @("NUnitXml", "JUnitXml")) {
    $reportDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrEmpty($reportDir) -and -not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
}

# Configuration de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = $OutputFormat

if ($OutputFormat -in @("NUnitXml", "JUnitXml")) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $OutputPath
    $pesterConfig.TestResult.OutputFormat = $OutputFormat
}

# Afficher les informations sur les tests
Write-Host "ExÃ©cution des tests unitaires pour le systÃ¨me de cache d'analyse des pull requests" -ForegroundColor Cyan
Write-Host "RÃ©pertoire des tests: $testsPath" -ForegroundColor White
Write-Host "Format de sortie: $OutputFormat" -ForegroundColor White

if ($OutputFormat -in @("NUnitXml", "JUnitXml")) {
    Write-Host "Chemin du rapport: $OutputPath" -ForegroundColor White
}

Write-Host "`nDÃ©marrage des tests..." -ForegroundColor Green

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s: $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les tests Ã©chouÃ©s
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s:" -ForegroundColor Red
    foreach ($failure in $testResults.Failed) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Retourner les rÃ©sultats
return $testResults
