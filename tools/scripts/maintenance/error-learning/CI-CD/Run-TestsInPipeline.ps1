<#
.SYNOPSIS
    Script pour exécuter les tests dans un pipeline CI/CD.
.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration du système d'apprentissage des erreurs
    dans un pipeline CI/CD et génère un rapport des résultats.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des tests. Par défaut, utilise le répertoire courant.
.EXAMPLE
    .\Run-TestsInPipeline.ps1
    Exécute tous les tests unitaires et d'intégration et génère un rapport XML des résultats.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestResults")
)

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin des tests
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$testRoot = Join-Path -Path $scriptRoot -ChildPath "Tests"
$testFiles = Get-ChildItem -Path $testRoot -Filter "*.Tests.ps1" -Recurse

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    (Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"),
    (Join-Path -Path $scriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Auto-CorrectErrors.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Adaptive-ErrorCorrection.ps1"),
    (Join-Path -Path $scriptRoot -ChildPath "Validate-ErrorCorrections.ps1")
)
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Afficher le chemin des résultats
Write-Host "Résultats des tests enregistrés dans: $OutputPath" -ForegroundColor Cyan
Write-Host "  Résultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Yellow
Write-Host "  Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basé sur les résultats des tests
exit $testResults.FailedCount
