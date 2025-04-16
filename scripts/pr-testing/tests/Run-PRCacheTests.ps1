#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le système de cache d'analyse des pull requests.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le système de cache d'analyse des pull requests,
    y compris les tests pour le module PRAnalysisCache.psm1 et les scripts associés.
.PARAMETER OutputFormat
    Le format de sortie des résultats des tests.
    Valeurs possibles: "Normal", "Detailed", "Diagnostic", "Minimal", "NUnitXml", "JUnitXml"
    Par défaut: "Detailed"
.PARAMETER OutputPath
    Le chemin où enregistrer les résultats des tests si un format XML est spécifié.
    Par défaut: "reports\pr-testing\cache_tests_results.xml"
.EXAMPLE
    .\Run-PRCacheTests.ps1
    Exécute tous les tests avec le format de sortie détaillé.
.EXAMPLE
    .\Run-PRCacheTests.ps1 -OutputFormat "NUnitXml" -OutputPath "reports\cache_tests.xml"
    Exécute tous les tests et génère un rapport NUnit XML.
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

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Chemin des tests
$testsPath = $PSScriptRoot

# Vérifier que le répertoire des tests existe
if (-not (Test-Path -Path $testsPath)) {
    throw "Répertoire de tests non trouvé: $testsPath"
}

# Créer le répertoire de rapports si nécessaire
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
Write-Host "Exécution des tests unitaires pour le système de cache d'analyse des pull requests" -ForegroundColor Cyan
Write-Host "Répertoire des tests: $testsPath" -ForegroundColor White
Write-Host "Format de sortie: $OutputFormat" -ForegroundColor White

if ($OutputFormat -in @("NUnitXml", "JUnitXml")) {
    Write-Host "Chemin du rapport: $OutputPath" -ForegroundColor White
}

Write-Host "`nDémarrage des tests..." -ForegroundColor Green

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés: $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les tests échoués
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests échoués:" -ForegroundColor Red
    foreach ($failure in $testResults.Failed) {
        Write-Host "  - $($failure.Name)" -ForegroundColor Red
        Write-Host "    $($failure.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Retourner les résultats
return $testResults
