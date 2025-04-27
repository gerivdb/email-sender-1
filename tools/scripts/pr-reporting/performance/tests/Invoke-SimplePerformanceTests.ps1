#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests simplifiÃ©s pour les scripts de performance.
.DESCRIPTION
    Ce script exÃ©cute tous les tests simplifiÃ©s pour les scripts de performance
    en utilisant le framework Pester.
.PARAMETER TestName
    Nom du test Ã  exÃ©cuter. Si non spÃ©cifiÃ©, tous les tests seront exÃ©cutÃ©s.
.EXAMPLE
    .\Invoke-SimplePerformanceTests.ps1
.EXAMPLE
    .\Invoke-SimplePerformanceTests.ps1 -TestName "Invoke-PRPerformanceBenchmark"
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestName
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
    exit 1
}

# Importer Pester
Import-Module Pester

# DÃ©finir les chemins des tests
$testsPath = $PSScriptRoot
$testFiles = @(
    "Simple-Invoke-PRPerformanceBenchmark.Tests.ps1",
    "Simple-Test-PRPerformanceRegression.Tests.ps1",
    "Simple-Start-PRLoadTest.Tests.ps1",
    "Simple-Compare-PRPerformanceResults.Tests.ps1",
    "Simple-Register-PRPerformanceTests.Tests.ps1",
    "Simple-Invoke-AllPerformanceTests.Tests.ps1"
)

# Filtrer les tests si un nom spÃ©cifique est demandÃ©
if ($TestName) {
    $testFiles = $testFiles | Where-Object { $_ -like "*$TestName*.Tests.ps1" }
    
    if ($testFiles.Count -eq 0) {
        Write-Error "Aucun test trouvÃ© pour le nom: $TestName"
        exit 1
    }
}

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testsPath
$pesterConfig.Run.TestExtension = ".Tests.ps1"
$pesterConfig.Run.Exit = $true
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $testsPath -ChildPath "SimpleTestResults.xml"
$pesterConfig.Output.Verbosity = "Detailed"

# SpÃ©cifier les fichiers de test Ã  exÃ©cuter
$pesterConfig.Run.Path = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }

# ExÃ©cuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests simplifiÃ©s de performance:"
Write-Host "======================================="
Write-Host "Tests exÃ©cutÃ©s: $($results.TotalCount)"
Write-Host "Tests rÃ©ussis: $($results.PassedCount)"
Write-Host "Tests Ã©chouÃ©s: $($results.FailedCount)"
Write-Host "Tests ignorÃ©s: $($results.SkippedCount)"
Write-Host "DurÃ©e totale: $($results.Duration.TotalSeconds) secondes"
Write-Host ""

# Retourner un code de sortie en fonction des rÃ©sultats
if ($results.FailedCount -gt 0) {
    Write-Host "Des tests ont Ã©chouÃ©!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
}
