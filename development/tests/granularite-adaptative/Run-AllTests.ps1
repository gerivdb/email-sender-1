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
$testsPath = Join-Path -Path $projectRoot -ChildPath "development\tests\granularite-adaptative"

# Définir le chemin de sortie des rapports
$reportPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

# Exécuter les tests manuellement un par un
$testFiles = Get-ChildItem -Path $testsPath -Filter "Test-*.ps1"
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0
$totalDuration = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $testFiles) {
    Write-Host "`nExécution des tests dans $($file.Name)..." -ForegroundColor Cyan

    # Exécuter le test
    $fileResults = & $file.FullName

    # Compter les résultats
    $totalTests += $fileResults.TotalCount
    $passedTests += $fileResults.PassedCount
    $failedTests += $fileResults.FailedCount
    $skippedTests += $fileResults.SkippedCount

    # Afficher un résumé pour ce fichier
    Write-Host "Tests exécutés : $($fileResults.TotalCount)" -ForegroundColor White
    Write-Host "Tests réussis  : $($fileResults.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués  : $($fileResults.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés  : $($fileResults.SkippedCount)" -ForegroundColor Yellow
}

$totalDuration.Stop()

# Simuler un objet de résultats Pester
$testResults = [PSCustomObject]@{
    TotalCount   = $totalTests
    PassedCount  = $passedTests
    FailedCount  = $failedTests
    SkippedCount = $skippedTests
    Duration     = [TimeSpan]::FromSeconds($totalDuration.Elapsed.TotalSeconds)
}

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
