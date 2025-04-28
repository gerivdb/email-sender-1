#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour Inspect-ScriptPreventively.ps1.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour vÃ©rifier le bon fonctionnement
    du script Inspect-ScriptPreventively.ps1.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
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

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour Inspect-ScriptPreventively.ps1..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow

# Afficher le chemin du rapport
Write-Host "`nRapport gÃ©nÃ©rÃ©: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White

# Retourner les rÃ©sultats
return $testResults
