<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le système de cache prédictif.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le système de cache prédictif
    et génère un rapport de couverture de code.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -MinimumVersion 5.0

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Définir le répertoire des tests
$testDirectory = $PSScriptRoot
$moduleDirectory = Split-Path -Path $testDirectory -Parent

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testDirectory
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $moduleDirectory -ChildPath "*.psm1"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $testDirectory -ChildPath "coverage.xml"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.TestResult.OutputPath = Join-Path -Path $testDirectory -ChildPath "testResults.xml"

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin des rapports générés
Write-Host "`nRapports générés:" -ForegroundColor Cyan
Write-Host "Rapport de couverture: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
Write-Host "Rapport de tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White

# Retourner le code de sortie en fonction des résultats
exit $testResults.FailedCount
