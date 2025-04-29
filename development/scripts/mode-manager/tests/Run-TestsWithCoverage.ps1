# Script pour exÃ©cuter les tests et gÃ©nÃ©rer un rapport de couverture de code en une seule commande

# DÃ©finir les paramÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Performance", "Workflow", "Error", "Config", "Simple", "PerformanceAdvanced", "WorkflowAdvanced", "UI", "Security", "Documentation", "Installation", "Regression", "Load", "IntegrationRoadmapParser", "Compatibility", "Localization", "LongTermPerformance", "IntegrationReporting")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML = $true,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests = $false,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateBadge = $true
)

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir les chemins des fichiers Ã  tester
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\\scripts\\mode-manager\mode-manager.ps1"
$modeManagerDir = Join-Path -Path $projectRoot -ChildPath "development\\scripts\\mode-manager"
$testsDir = Join-Path -Path $modeManagerDir -ChildPath "tests"

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"
$coverageOutputPath = Join-Path -Path $OutputPath -ChildPath "coverage"

# Afficher les informations
Write-Host "ExÃ©cution des tests du mode MANAGER avec couverture de code" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan

# ExÃ©cuter les tests
$testScript = Join-Path -Path $testsDir -ChildPath "Run-AllTestsWithCoverage.ps1"
$testResult = & $testScript -TestType $TestType -OutputPath $OutputPath -GenerateHTML:$GenerateHTML -SkipPerformanceTests:$SkipPerformanceTests -OpenReport:$OpenReport

# VÃ©rifier le rÃ©sultat
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Les tests ont Ã©chouÃ©."
}

# GÃ©nÃ©rer un rapport de couverture dÃ©taillÃ©
if ($GenerateHTML) {
    $coverageReportScript = Join-Path -Path $testsDir -ChildPath "Generate-CoverageReport.ps1"
    & $coverageReportScript -CoverageReportPath $coverageReportPath -OutputPath $coverageOutputPath
}

# GÃ©nÃ©rer un badge de couverture
if ($GenerateBadge) {
    $badgeScript = Join-Path -Path $testsDir -ChildPath "Generate-CoverageBadge.ps1"
    & $badgeScript -CoverageReportPath $coverageReportPath
}

# Retourner le code de sortie
exit $LASTEXITCODE

