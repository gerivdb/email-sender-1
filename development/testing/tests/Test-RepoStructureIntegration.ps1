#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intÃ©gration pour les scripts de rÃ©organisation et standardisation du dÃ©pÃ´t
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les scripts de rÃ©organisation
    et standardisation du dÃ©pÃ´t, gÃ©nÃ¨re un rapport de couverture et vÃ©rifie
    l'intÃ©gration entre les diffÃ©rents composants.
.PARAMETER OutputFormat
    Format de sortie du rapport (NUnitXml, JUnitXml, HTML)
.PARAMETER CoverageReport
    Indique s'il faut gÃ©nÃ©rer un rapport de couverture
.EXAMPLE
    .\Test-RepoStructureIntegration.ps1 -OutputFormat HTML -CoverageReport
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("NUnitXml", "JUnitXml", "HTML")]
    [string]$OutputFormat = "HTML",
    
    [Parameter(Mandatory = $false)]
    [switch]$CoverageReport
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# DÃ©finir les chemins des scripts Ã  tester
$scriptsToTest = @(
    "scripts\maintenance\repo\Test-RepoStructure.ps1",
    "scripts\maintenance\repo\Reorganize-Repository.ps1",
    "scripts\maintenance\repo\Clean-Repository.ps1"
)

# DÃ©finir les chemins des tests unitaires
$unitTests = @(
    "tests\unit\Test-RepoStructureUnit.ps1",
    "tests\unit\Test-RepositoryMigration.ps1",
    "tests\unit\Test-RepositoryCleaning.ps1"
)

# VÃ©rifier que tous les scripts Ã  tester existent
$missingScripts = $scriptsToTest | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
if ($missingScripts.Count -gt 0) {
    Write-Host "Les scripts suivants sont manquants:" -ForegroundColor Red
    $missingScripts | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

# VÃ©rifier que tous les tests unitaires existent
$missingTests = $unitTests | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
if ($missingTests.Count -gt 0) {
    Write-Host "Les tests unitaires suivants sont manquants:" -ForegroundColor Red
    $missingTests | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

# CrÃ©er les dossiers pour les rapports
$reportsDir = "reports\tests"
if (-not (Test-Path -Path $reportsDir -PathType Container)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins des rapports
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$testResultsPath = Join-Path -Path $reportsDir -ChildPath "TestResults-$timestamp.$($OutputFormat.ToLower())"
$coverageReportPath = Join-Path -Path $reportsDir -ChildPath "CoverageReport-$timestamp.xml"

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $unitTests
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = $OutputFormat
$pesterConfig.TestResult.OutputPath = $testResultsPath

if ($CoverageReport) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $scriptsToTest
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
    $pesterConfig.CodeCoverage.OutputPath = $coverageReportPath
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "- Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "- Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "- Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "- Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "- DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin du rapport de rÃ©sultats
Write-Host "`nRapport de rÃ©sultats gÃ©nÃ©rÃ©: $testResultsPath" -ForegroundColor Cyan

# Afficher le chemin du rapport de couverture si gÃ©nÃ©rÃ©
if ($CoverageReport) {
    Write-Host "Rapport de couverture gÃ©nÃ©rÃ©: $coverageReportPath" -ForegroundColor Cyan
    
    # Calculer le pourcentage de couverture
    $coverageXml = [xml](Get-Content -Path $coverageReportPath)
    $totalLines = [int]$coverageXml.report.counter | Where-Object { $_.type -eq "LINE" } | Select-Object -ExpandProperty missed
    $coveredLines = [int]$coverageXml.report.counter | Where-Object { $_.type -eq "LINE" } | Select-Object -ExpandProperty covered
    $totalLinesCount = $totalLines + $coveredLines
    
    if ($totalLinesCount -gt 0) {
        $coveragePercentage = [Math]::Round(($coveredLines / $totalLinesCount) * 100, 2)
        Write-Host "Couverture de code: $coveragePercentage%" -ForegroundColor $(if ($coveragePercentage -ge 80) { "Green" } elseif ($coveragePercentage -ge 60) { "Yellow" } else { "Red" })
    }
}

# VÃ©rifier si tous les tests ont rÃ©ussi
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nCertains tests ont Ã©chouÃ©. Veuillez consulter le rapport pour plus de dÃ©tails." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}
