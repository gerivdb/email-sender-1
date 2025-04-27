#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour l'optimisation dynamique de la parallÃ©lisation.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les modules liÃ©s Ã  l'optimisation
    dynamique de la parallÃ©lisation et gÃ©nÃ¨re un rapport de couverture.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rapports de test. Par dÃ©faut, utilise le rÃ©pertoire "TestResults"
    dans le rÃ©pertoire courant.
.EXAMPLE
    .\Run-ParallelizationTests.ps1
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport dans le rÃ©pertoire par dÃ©faut.
.EXAMPLE
    .\Run-ParallelizationTests.ps1 -OutputPath "C:\Reports"
    ExÃ©cute tous les tests et gÃ©nÃ¨re un rapport dans le rÃ©pertoire spÃ©cifiÃ©.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "TestResults")
)

# VÃ©rifier si le rÃ©pertoire de sortie existe, sinon le crÃ©er
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module Pester
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
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.Path = @(
    (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Dynamic-ThreadManager.psm1"),
    (Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "TaskPriorityQueue.psm1")
)

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour l'optimisation dynamique de la parallÃ©lisation..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s: $($testResults.NotRunCount)" -ForegroundColor Gray

# Afficher le chemin des rapports
Write-Host "`nRapports gÃ©nÃ©rÃ©s:" -ForegroundColor Cyan
Write-Host "  RÃ©sultats des tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
Write-Host "  Couverture de code: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White

# Retourner les rÃ©sultats
return $testResults
