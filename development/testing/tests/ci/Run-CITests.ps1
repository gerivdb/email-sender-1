#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour le pipeline CI/CD.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour le pipeline CI/CD et gÃ©nÃ¨re des rapports.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$TestsPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\unit"),
    
    [Parameter(Mandatory = $false)]
    [string]$ReportsPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\reports"),
    
    [Parameter(Mandatory = $false)]
    [string]$ModulesPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"),
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# CrÃ©er le rÃ©pertoire de rapports s'il n'existe pas
if (-not (Test-Path -Path $ReportsPath)) {
    New-Item -Path $ReportsPath -ItemType Directory -Force | Out-Null
}

# Configuration Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $TestsPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $ReportsPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $ModulesPath
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $ReportsPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires..."
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :"
Write-Host "Total des tests : $($testResults.TotalCount)"
Write-Host "Tests rÃ©ussis : $($testResults.PassedCount)"
Write-Host "Tests Ã©chouÃ©s : $($testResults.FailedCount)"
Write-Host "Tests ignorÃ©s : $($testResults.SkippedCount)"
Write-Host "DurÃ©e totale : $($testResults.Duration.TotalSeconds) secondes"

# Afficher les tests Ã©chouÃ©s
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s :"
    foreach ($testResult in $testResults.Failed) {
        Write-Host "- $($testResult.Name) : $($testResult.ErrorRecord.Exception.Message)"
    }
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlReportPath = Join-Path -Path $ReportsPath -ChildPath "TestResults.html"
    
    # VÃ©rifier si ReportUnit est installÃ©
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"
    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Host "TÃ©lÃ©chargement de ReportUnit..."
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }
    
    # GÃ©nÃ©rer le rapport HTML
    Write-Host "GÃ©nÃ©ration du rapport HTML..."
    & $reportUnitPath $pesterConfig.TestResult.OutputPath $htmlReportPath
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlReportPath"
}

# ExÃ©cuter les tests de performance si demandÃ©
if (-not $SkipPerformanceTests) {
    Write-Host "`nExÃ©cution des tests de performance..."
    $performanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "Run-PerformanceTests.ps1"
    if (Test-Path -Path $performanceTestsPath) {
        & $performanceTestsPath -ReportsPath $ReportsPath
    } else {
        Write-Warning "Le script de tests de performance n'a pas Ã©tÃ© trouvÃ© : $performanceTestsPath"
    }
}

# Afficher le chemin des rapports
Write-Host "`nRapports gÃ©nÃ©rÃ©s :"
Write-Host "- RÃ©sultats des tests : $($pesterConfig.TestResult.OutputPath)"
Write-Host "- Couverture de code : $($pesterConfig.CodeCoverage.OutputPath)"

# Retourner le nombre de tests Ã©chouÃ©s
return $testResults.FailedCount
