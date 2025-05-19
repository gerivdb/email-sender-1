﻿#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Exécute tous les tests pour les fonctionnalités de collection.

.DESCRIPTION
    Ce script exécute tous les tests unitaires et de performance pour les fonctionnalités de collection.
    Il génère des rapports de couverture de code et des résultats de test.

.PARAMETER UnitTestsOnly
    Exécute uniquement les tests unitaires, pas les tests de performance.

.PARAMETER PerformanceTestsOnly
    Exécute uniquement les tests de performance, pas les tests unitaires.

.PARAMETER CodeCoverage
    Génère un rapport de couverture de code.

.PARAMETER OutputPath
    Chemin de sortie pour les rapports de test. Par défaut, "TestResults".

.EXAMPLE
    .\Run-AllCollectionTests.ps1
    Exécute tous les tests unitaires et de performance.

.EXAMPLE
    .\Run-AllCollectionTests.ps1 -UnitTestsOnly
    Exécute uniquement les tests unitaires.

.EXAMPLE
    .\Run-AllCollectionTests.ps1 -PerformanceTestsOnly
    Exécute uniquement les tests de performance.

.EXAMPLE
    .\Run-AllCollectionTests.ps1 -CodeCoverage
    Exécute tous les tests et génère un rapport de couverture de code.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-20
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$UnitTestsOnly,

    [Parameter(Mandatory = $false)]
    [switch]$PerformanceTestsOnly,

    [Parameter(Mandatory = $false)]
    [switch]$CodeCoverage,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "TestResults"
)

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Error "Pester n'est pas installé. Veuillez installer Pester 5.0.0 ou supérieur."
    return
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0.0 -Force

# Définir les chemins
$scriptRoot = $PSScriptRoot
$projectRoot = (Get-Item $scriptRoot).Parent.FullName
$testResultsPath = Join-Path -Path $projectRoot -ChildPath $OutputPath

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $testResultsPath)) {
    New-Item -Path $testResultsPath -ItemType Directory -Force | Out-Null
}

# Définir les fichiers à tester
$filesToTest = @(
    (Join-Path -Path $projectRoot -ChildPath "CollectionWrapper.ps1"),
    (Join-Path -Path $projectRoot -ChildPath "CollectionExtensions.ps1")
)

# Définir les tests unitaires
$unitTests = @(
    (Join-Path -Path $scriptRoot -ChildPath "Pester\CollectionWrapper.Tests.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Pester\CollectionExtensions.Tests.ps1")
)

# Définir les tests de performance
$performanceTests = @(
    (Join-Path -Path $scriptRoot -ChildPath "Performance\CollectionPerformance.Tests.ps1")
)

# Fonction pour exécuter les tests
function Invoke-Tests {
    param(
        [string[]]$TestFiles,
        [string]$OutputFile,
        [switch]$WithCoverage,
        [string[]]$CoverageFiles
    )

    $configuration = [PesterConfiguration]::Default
    $configuration.Run.Path = $TestFiles
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = "Detailed"
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = $OutputFile

    if ($WithCoverage) {
        $configuration.CodeCoverage.Enabled = $true
        $configuration.CodeCoverage.Path = $CoverageFiles
        $configuration.CodeCoverage.OutputPath = [System.IO.Path]::ChangeExtension($OutputFile, "coverage.xml")
    }

    $results = Invoke-Pester -Configuration $configuration

    return $results
}

# Exécuter les tests unitaires
if (-not $PerformanceTestsOnly) {
    Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
    $unitTestsOutputFile = Join-Path -Path $testResultsPath -ChildPath "UnitTests.xml"
    $unitTestsResults = Invoke-Tests -TestFiles $unitTests -OutputFile $unitTestsOutputFile -WithCoverage:$CodeCoverage -CoverageFiles $filesToTest

    Write-Host "Résultats des tests unitaires :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : $($unitTestsResults.TotalCount)" -ForegroundColor White
    Write-Host "Tests réussis : $($unitTestsResults.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : $($unitTestsResults.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés : $($unitTestsResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Durée totale : $($unitTestsResults.Duration.TotalSeconds) secondes" -ForegroundColor White

    if ($CodeCoverage) {
        Write-Host "Couverture de code : $($unitTestsResults.CodeCoverage.CoveragePercent)%" -ForegroundColor White
    }

    Write-Host ""
}

# Exécuter les tests de performance
if (-not $UnitTestsOnly) {
    Write-Host "Exécution des tests de performance..." -ForegroundColor Cyan
    $performanceTestsOutputFile = Join-Path -Path $testResultsPath -ChildPath "PerformanceTests.xml"
    $performanceTestsResults = Invoke-Tests -TestFiles $performanceTests -OutputFile $performanceTestsOutputFile

    Write-Host "Résultats des tests de performance :" -ForegroundColor Cyan
    Write-Host "Tests exécutés : $($performanceTestsResults.TotalCount)" -ForegroundColor White
    Write-Host "Tests réussis : $($performanceTestsResults.PassedCount)" -ForegroundColor Green
    Write-Host "Tests échoués : $($performanceTestsResults.FailedCount)" -ForegroundColor Red
    Write-Host "Tests ignorés : $($performanceTestsResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Durée totale : $($performanceTestsResults.Duration.TotalSeconds) secondes" -ForegroundColor White
    Write-Host ""
}

# Afficher le chemin des rapports
Write-Host "Les rapports de test ont été générés dans : $testResultsPath" -ForegroundColor Cyan
