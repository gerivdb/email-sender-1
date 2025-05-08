# Script pour exécuter tous les tests unitaires de granularité adaptative
# Auteur: Augment AI
# Date: 2025-06-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "TestResults"
)

# Vérifier que Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while ($projectRoot -and -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = Split-Path -Parent $projectRoot
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Définir le chemin des tests
$testsPath = Join-Path -Path $projectRoot -ChildPath "development\tests\granularite-adaptative\Test-Simple.ps1"

# Définir le chemin de sortie des rapports
$reportPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.Path = @(
        Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode-unified.ps1"
        Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode-recursive-unified.ps1"
    )
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires de granularité adaptative..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis  : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués  : $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés  : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale   : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Vérifier si tous les tests ont réussi
if ($testResults.FailedCount -eq 0) {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    
    if ($GenerateReport) {
        Write-Host "`nRapports générés :" -ForegroundColor Cyan
        Write-Host "Résultats des tests : $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
        Write-Host "Couverture de code  : $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
    }
    
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué. Veuillez corriger les erreurs et réexécuter les tests." -ForegroundColor Red
    exit 1
}
