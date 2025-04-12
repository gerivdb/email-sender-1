#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour Inspect-ScriptPreventively.ps1.
.DESCRIPTION
    Ce script exécute les tests unitaires pour vérifier le bon fonctionnement
    du script Inspect-ScriptPreventively.ps1.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour Inspect-ScriptPreventively.ps1..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow

# Afficher le chemin du rapport
Write-Host "`nRapport généré: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White

# Retourner les résultats
return $testResults
