#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour les scripts d'analyse de code.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour les scripts d'analyse de code
    et gÃ©nÃ¨re un rapport de couverture de code.
.PARAMETER OutputPath
    Chemin du rÃ©pertoire oÃ¹ les rapports de tests seront gÃ©nÃ©rÃ©s.
.PARAMETER ShowCoverage
    Indique si le rapport de couverture de code doit Ãªtre affichÃ©.
.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath ".\results" -ShowCoverage
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$ShowCoverage
)

# VÃ©rifier si Pester est disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer Pester
Import-Module -Name Pester -Force

# DÃ©finir le rÃ©pertoire des tests
$testsDir = $PSScriptRoot
$scriptsDir = Split-Path -Path $testsDir -Parent

# DÃ©finir le rÃ©pertoire de sortie par dÃ©faut si non spÃ©cifiÃ©
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $testsDir -ChildPath "results"
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath -PathType Container)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir les fichiers de test Ã  exÃ©cuter
$testFiles = Get-ChildItem -Path $testsDir -Filter "*.Tests.ps1" -File

# Copier le module TestHelpers.psm1 dans le rÃ©pertoire temporaire de Pester
$testHelpersPath = Join-Path -Path $testsDir -ChildPath "TestHelpers.psm1"
if (Test-Path -Path $testHelpersPath) {
    $pesterTempDir = Join-Path -Path $env:TEMP -ChildPath "Pester"
    if (-not (Test-Path -Path $pesterTempDir -PathType Container)) {
        New-Item -Path $pesterTempDir -ItemType Directory -Force | Out-Null
    }
    Copy-Item -Path $testHelpersPath -Destination $pesterTempDir -Force
}

# Configurer les options de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Configurer la couverture de code si demandÃ©
if ($ShowCoverage) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @(
        Join-Path -Path $scriptsDir -ChildPath "Start-CodeAnalysis.ps1"
        Join-Path -Path $scriptsDir -ChildPath "Fix-HtmlReportEncoding.ps1"
        Join-Path -Path $scriptsDir -ChildPath "Integrate-ThirdPartyTools.ps1"
        Join-Path -Path $scriptsDir -ChildPath "modules\UnifiedResultsFormat.psm1"
    )
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats:" -ForegroundColor Cyan
Write-Host "  - Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  - Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor $(if ($results.PassedCount -eq $results.TotalCount) { "Green" } else { "White" })
Write-Host "  - Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  - Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor $(if ($results.SkippedCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Tests non exÃ©cutÃ©s: $($results.NotRunCount)" -ForegroundColor $(if ($results.NotRunCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - DurÃ©e: $($results.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher le chemin des rapports gÃ©nÃ©rÃ©s
Write-Host "`nRapports gÃ©nÃ©rÃ©s:" -ForegroundColor Cyan
Write-Host "  - Rapport de tests: $($pesterConfig.TestResult.OutputPath)" -ForegroundColor White
if ($ShowCoverage) {
    Write-Host "  - Rapport de couverture: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor White
}

# Retourner les rÃ©sultats
return $results
