<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le module de compatibilitÃ© entre environnements.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le module de compatibilitÃ© entre environnements
    en utilisant le framework Pester.

.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER GenerateReport
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.

.EXAMPLE
    .\Run-Tests.ps1 -GenerateReport
    ExÃ©cute les tests unitaires et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
    PrÃ©requis:      Pester 5.0 ou supÃ©rieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin des tests
$testRoot = $PSScriptRoot
$testFiles = @(
    (Join-Path -Path $testRoot -ChildPath "EnvironmentManager.Tests.ps1"),
    (Join-Path -Path $testRoot -ChildPath "Improve-ScriptCompatibility.Tests.ps1")
)

# DÃ©finir la configuration Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "TestResults"
    if (-not (Test-Path -Path $reportPath)) {
        New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
    }
    
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = Join-Path -Path $testRoot -ChildPath "EnvironmentManager.psm1"
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportPath -ChildPath "CodeCoverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    Write-Host "GÃ©nÃ©ration du rapport HTML..." -ForegroundColor Yellow
    
    # VÃ©rifier si ReportUnit est installÃ©
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"
    
    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Host "TÃ©lÃ©chargement de ReportUnit..." -ForegroundColor Yellow
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }
    
    # GÃ©nÃ©rer le rapport HTML
    $reportXmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.xml"
    $reportHtmlPath = Join-Path -Path $reportPath -ChildPath "TestResults.html"
    
    if (Test-Path -Path $reportXmlPath) {
        & $reportUnitPath $reportXmlPath $reportPath
        
        if (Test-Path -Path $reportHtmlPath) {
            Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportHtmlPath" -ForegroundColor Green
            Start-Process $reportHtmlPath
        }
        else {
            Write-Warning "Ã‰chec de la gÃ©nÃ©ration du rapport HTML."
        }
    }
    else {
        Write-Warning "Fichier de rÃ©sultats XML non trouvÃ©: $reportXmlPath"
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host
Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)"
Write-Host "  Tests rÃ©ussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $testResults.FailedCount
