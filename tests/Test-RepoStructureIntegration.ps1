#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour les scripts de réorganisation et standardisation du dépôt
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les scripts de réorganisation
    et standardisation du dépôt, génère un rapport de couverture et vérifie
    l'intégration entre les différents composants.
.PARAMETER OutputFormat
    Format de sortie du rapport (NUnitXml, JUnitXml, HTML)
.PARAMETER CoverageReport
    Indique s'il faut générer un rapport de couverture
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

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Définir les chemins des scripts à tester
$scriptsToTest = @(
    "scripts\maintenance\repo\Test-RepoStructure.ps1",
    "scripts\maintenance\repo\Reorganize-Repository.ps1",
    "scripts\maintenance\repo\Clean-Repository.ps1"
)

# Définir les chemins des tests unitaires
$unitTests = @(
    "tests\unit\Test-RepoStructureUnit.ps1",
    "tests\unit\Test-RepositoryMigration.ps1",
    "tests\unit\Test-RepositoryCleaning.ps1"
)

# Vérifier que tous les scripts à tester existent
$missingScripts = $scriptsToTest | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
if ($missingScripts.Count -gt 0) {
    Write-Host "Les scripts suivants sont manquants:" -ForegroundColor Red
    $missingScripts | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

# Vérifier que tous les tests unitaires existent
$missingTests = $unitTests | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
if ($missingTests.Count -gt 0) {
    Write-Host "Les tests unitaires suivants sont manquants:" -ForegroundColor Red
    $missingTests | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

# Créer les dossiers pour les rapports
$reportsDir = "reports\tests"
if (-not (Test-Path -Path $reportsDir -PathType Container)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Définir les chemins des rapports
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

# Exécuter les tests
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "- Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "- Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "- Tests échoués: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host "- Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "- Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin du rapport de résultats
Write-Host "`nRapport de résultats généré: $testResultsPath" -ForegroundColor Cyan

# Afficher le chemin du rapport de couverture si généré
if ($CoverageReport) {
    Write-Host "Rapport de couverture généré: $coverageReportPath" -ForegroundColor Cyan
    
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

# Vérifier si tous les tests ont réussi
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nCertains tests ont échoué. Veuillez consulter le rapport pour plus de détails." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
