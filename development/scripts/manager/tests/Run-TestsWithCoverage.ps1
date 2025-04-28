# Script pour exécuter les tests et générer un rapport de couverture de code en une seule commande

# Définir les paramètres
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

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir les chemins des fichiers à tester
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$modeManagerDir = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager"
$testsDir = Join-Path -Path $modeManagerDir -ChildPath "tests"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"
$coverageOutputPath = Join-Path -Path $OutputPath -ChildPath "coverage"

# Afficher les informations
Write-Host "Exécution des tests du mode MANAGER avec couverture de code" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan

# Exécuter les tests
$testScript = Join-Path -Path $testsDir -ChildPath "Run-AllTestsWithCoverage.ps1"
$testResult = & $testScript -TestType $TestType -OutputPath $OutputPath -GenerateHTML:$GenerateHTML -SkipPerformanceTests:$SkipPerformanceTests -OpenReport:$OpenReport

# Vérifier le résultat
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Les tests ont échoué."
}

# Générer un rapport de couverture détaillé
if ($GenerateHTML) {
    $coverageReportScript = Join-Path -Path $testsDir -ChildPath "Generate-CoverageReport.ps1"
    & $coverageReportScript -CoverageReportPath $coverageReportPath -OutputPath $coverageOutputPath
}

# Générer un badge de couverture
if ($GenerateBadge) {
    $badgeScript = Join-Path -Path $testsDir -ChildPath "Generate-CoverageBadge.ps1"
    & $badgeScript -CoverageReportPath $coverageReportPath
}

# Retourner le code de sortie
exit $LASTEXITCODE
