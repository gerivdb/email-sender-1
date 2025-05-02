# Run-AllTests.ps1
# Script pour exécuter tous les tests unitaires du système de gestion de roadmap

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "development\tests\maintenance\results"
)

# Vérifier que Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Chemins des fichiers de test
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "*.Tests.ps1"
$testFiles = Get-ChildItem -Path $testPath

# Créer le dossier de sortie si nécessaire
if ($GenerateReport -and -not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testPath
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
}

# Afficher les informations sur les tests
Write-Host "Exécution des tests unitaires pour le système de gestion de roadmap" -ForegroundColor Cyan
Write-Host "Fichiers de test trouvés: $($testFiles.Count)" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "  - $($file.Name)" -ForegroundColor Gray
}
Write-Host ""

# Initialiser les données de test
Write-Host "Initialisation des données de test..." -ForegroundColor Cyan
$initializeTestDataScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-TestData.ps1"
if (Test-Path -Path $initializeTestDataScript) {
    & $initializeTestDataScript
} else {
    Write-Host "Le script d'initialisation des données de test n'a pas été trouvé à l'emplacement: $initializeTestDataScript" -ForegroundColor Red
    return
}

# Exécuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "Résumé des résultats:" -ForegroundColor Cyan
Write-Host "  - Tests exécutés: $($results.TotalCount)" -ForegroundColor Gray
Write-Host "  - Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  - Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  - Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($GenerateReport) {
    Write-Host "Rapports générés:" -ForegroundColor Cyan
    Write-Host "  - Résultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Gray
    Write-Host "  - Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Gray
}

# Retourner un code d'erreur si des tests ont échoué
if ($results.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
