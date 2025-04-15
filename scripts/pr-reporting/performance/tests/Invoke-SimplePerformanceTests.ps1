#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests simplifiés pour les scripts de performance.
.DESCRIPTION
    Ce script exécute tous les tests simplifiés pour les scripts de performance
    en utilisant le framework Pester.
.PARAMETER TestName
    Nom du test à exécuter. Si non spécifié, tous les tests seront exécutés.
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

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
    exit 1
}

# Importer Pester
Import-Module Pester

# Définir les chemins des tests
$testsPath = $PSScriptRoot
$testFiles = @(
    "Simple-Invoke-PRPerformanceBenchmark.Tests.ps1",
    "Simple-Test-PRPerformanceRegression.Tests.ps1",
    "Simple-Start-PRLoadTest.Tests.ps1",
    "Simple-Compare-PRPerformanceResults.Tests.ps1",
    "Simple-Register-PRPerformanceTests.Tests.ps1",
    "Simple-Invoke-AllPerformanceTests.Tests.ps1"
)

# Filtrer les tests si un nom spécifique est demandé
if ($TestName) {
    $testFiles = $testFiles | Where-Object { $_ -like "*$TestName*.Tests.ps1" }
    
    if ($testFiles.Count -eq 0) {
        Write-Error "Aucun test trouvé pour le nom: $TestName"
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

# Spécifier les fichiers de test à exécuter
$pesterConfig.Run.Path = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }

# Exécuter les tests
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests simplifiés de performance:"
Write-Host "======================================="
Write-Host "Tests exécutés: $($results.TotalCount)"
Write-Host "Tests réussis: $($results.PassedCount)"
Write-Host "Tests échoués: $($results.FailedCount)"
Write-Host "Tests ignorés: $($results.SkippedCount)"
Write-Host "Durée totale: $($results.Duration.TotalSeconds) secondes"
Write-Host ""

# Retourner un code de sortie en fonction des résultats
if ($results.FailedCount -gt 0) {
    Write-Host "Des tests ont échoué!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
