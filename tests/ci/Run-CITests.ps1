#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour le pipeline CI/CD.
.DESCRIPTION
    Ce script exécute les tests unitaires pour le pipeline CI/CD et génère des rapports.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Créer le répertoire de rapports s'il n'existe pas
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

# Exécuter les tests
Write-Host "Exécution des tests unitaires..."
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :"
Write-Host "Total des tests : $($testResults.TotalCount)"
Write-Host "Tests réussis : $($testResults.PassedCount)"
Write-Host "Tests échoués : $($testResults.FailedCount)"
Write-Host "Tests ignorés : $($testResults.SkippedCount)"
Write-Host "Durée totale : $($testResults.Duration.TotalSeconds) secondes"

# Afficher les tests échoués
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests échoués :"
    foreach ($testResult in $testResults.Failed) {
        Write-Host "- $($testResult.Name) : $($testResult.ErrorRecord.Exception.Message)"
    }
}

# Générer un rapport HTML si demandé
if ($GenerateHtmlReport) {
    $htmlReportPath = Join-Path -Path $ReportsPath -ChildPath "TestResults.html"
    
    # Vérifier si ReportUnit est installé
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"
    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Host "Téléchargement de ReportUnit..."
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }
    
    # Générer le rapport HTML
    Write-Host "Génération du rapport HTML..."
    & $reportUnitPath $pesterConfig.TestResult.OutputPath $htmlReportPath
    
    Write-Host "Rapport HTML généré : $htmlReportPath"
}

# Exécuter les tests de performance si demandé
if (-not $SkipPerformanceTests) {
    Write-Host "`nExécution des tests de performance..."
    $performanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "Run-PerformanceTests.ps1"
    if (Test-Path -Path $performanceTestsPath) {
        & $performanceTestsPath -ReportsPath $ReportsPath
    } else {
        Write-Warning "Le script de tests de performance n'a pas été trouvé : $performanceTestsPath"
    }
}

# Afficher le chemin des rapports
Write-Host "`nRapports générés :"
Write-Host "- Résultats des tests : $($pesterConfig.TestResult.OutputPath)"
Write-Host "- Couverture de code : $($pesterConfig.CodeCoverage.OutputPath)"

# Retourner le nombre de tests échoués
return $testResults.FailedCount
