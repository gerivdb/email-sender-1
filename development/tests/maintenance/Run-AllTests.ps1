# Run-AllTests.ps1
# Script pour exÃ©cuter tous les tests unitaires du systÃ¨me de gestion de roadmap

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "development\tests\maintenance\results"
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Le module Pester n'est pas installÃ©. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Chemins des fichiers de test
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "*.Tests.ps1"
$testFiles = Get-ChildItem -Path $testPath

# CrÃ©er le dossier de sortie si nÃ©cessaire
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
Write-Host "ExÃ©cution des tests unitaires pour le systÃ¨me de gestion de roadmap" -ForegroundColor Cyan
Write-Host "Fichiers de test trouvÃ©s: $($testFiles.Count)" -ForegroundColor Cyan
foreach ($file in $testFiles) {
    Write-Host "  - $($file.Name)" -ForegroundColor Gray
}
Write-Host ""

# Initialiser les donnÃ©es de test
Write-Host "Initialisation des donnÃ©es de test..." -ForegroundColor Cyan
$initializeTestDataScript = Join-Path -Path $PSScriptRoot -ChildPath "Initialize-TestData.ps1"
if (Test-Path -Path $initializeTestDataScript) {
    & $initializeTestDataScript
} else {
    Write-Host "Le script d'initialisation des donnÃ©es de test n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement: $initializeTestDataScript" -ForegroundColor Red
    return
}

# ExÃ©cuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "RÃ©sumÃ© des rÃ©sultats:" -ForegroundColor Cyan
Write-Host "  - Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor Gray
Write-Host "  - Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  - Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  - Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($GenerateReport) {
    Write-Host "Rapports gÃ©nÃ©rÃ©s:" -ForegroundColor Cyan
    Write-Host "  - RÃ©sultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor Gray
    Write-Host "  - Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Gray
}

# Retourner un code d'erreur si des tests ont Ã©chouÃ©
if ($results.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
