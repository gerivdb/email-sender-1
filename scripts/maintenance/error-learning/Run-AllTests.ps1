<#
.SYNOPSIS
    Script pour exécuter tous les tests unitaires et d'intégration du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration du système d'apprentissage des erreurs
    et génère un rapport des résultats.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des tests. Par défaut, utilise le répertoire courant.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats des tests.
.PARAMETER TestType
    Type de tests à exécuter. Valeurs possibles : 'All', 'Unit', 'Integration'. Par défaut, 'All'.
.EXAMPLE
    .\Run-AllTests.ps1 -GenerateReport
    Exécute tous les tests unitaires et d'intégration et génère un rapport HTML des résultats.
.EXAMPLE
    .\Run-AllTests.ps1 -TestType Unit
    Exécute uniquement les tests unitaires.
.EXAMPLE
    .\Run-AllTests.ps1 -TestType Integration
    Exécute uniquement les tests d'intégration.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Unit', 'Integration')]
    [string]$TestType = 'All'
)

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin des tests
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"

# Filtrer les tests en fonction du type de test demandé
if ($TestType -eq 'Unit') {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse | Where-Object { $_.Name -notmatch '\.Integration\.Tests\.ps1$' }
    Write-Host "Tests unitaires trouvés :" -ForegroundColor Cyan
}
elseif ($TestType -eq 'Integration') {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Integration.Tests.ps1" -Recurse
    Write-Host "Tests d'intégration trouvés :" -ForegroundColor Cyan
}
else {
    $testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse
    Write-Host "Tous les tests trouvés :" -ForegroundColor Cyan
}

# Afficher les tests trouvés
foreach ($testFile in $testFiles) {
    Write-Host "  $($testFile.Name)" -ForegroundColor Yellow
}

# Définir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "TestResults"
    if (-not (Test-Path -Path $reportPath)) {
        New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
    }

    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"

    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @(
        (Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Auto-CorrectErrors.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"),
        (Join-Path -Path $PSScriptRoot -ChildPath "Validate-ErrorCorrections.ps1")
    )
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# Exécuter les tests
Write-Host "`nExécution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Yellow

    # Vérifier si ReportUnit est installé
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"

    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Host "Téléchargement de ReportUnit..." -ForegroundColor Yellow
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }

    # Générer le rapport HTML
    $reportXmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $reportHtmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.html"

    if (Test-Path -Path $reportXmlPath) {
        & $reportUnitPath $reportXmlPath $reportPath

        if (Test-Path -Path $reportHtmlPath) {
            Write-Host "Rapport HTML généré: $reportHtmlPath" -ForegroundColor Green
            Start-Process $reportHtmlPath
        }
        else {
            Write-Warning "Échec de la génération du rapport HTML."
        }
    }
    else {
        Write-Warning "Fichier de résultats XML non trouvé: $reportXmlPath"
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow

# Afficher le type de tests exécutés
Write-Host "`nType de tests exécutés: $TestType" -ForegroundColor Cyan
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $testResults.FailedCount
