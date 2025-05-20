# Script pour exécuter les tests de timeout pour Wait-ForCompletedRunspace

# Vérifier que Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Chemin vers le fichier de test
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Wait-ForCompletedRunspace.Timeout.Tests.ps1"

# Vérifier que le fichier de test existe
if (-not (Test-Path -Path $testScriptPath)) {
    Write-Error "Le fichier de test n'existe pas: $testScriptPath"
    exit 1
}

# Exécuter les tests
Write-Host "Exécution des tests de timeout pour Wait-ForCompletedRunspace..." -ForegroundColor Cyan

# Configurer les options de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testScriptPath
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "TimeoutTestResults.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "TimeoutCoverage.xml"

# Exécuter les tests avec la configuration spécifiée
Invoke-Pester -Configuration $pesterConfig
