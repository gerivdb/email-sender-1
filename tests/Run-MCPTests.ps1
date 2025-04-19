#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests pour le module MCPClient et génère un rapport.
.DESCRIPTION
    Ce script exécute les tests unitaires, d'intégration et de performance
    pour le module MCPClient, puis génère un rapport détaillé.
.PARAMETER SkipUnitTests
    Indique s'il faut ignorer les tests unitaires.
.PARAMETER SkipIntegrationTests
    Indique s'il faut ignorer les tests d'intégration.
.PARAMETER SkipPerformanceTests
    Indique s'il faut ignorer les tests de performance.
.PARAMETER SkipReport
    Indique s'il faut ignorer la génération du rapport.
.EXAMPLE
    .\Run-MCPTests.ps1
    Exécute tous les tests et génère un rapport.
.EXAMPLE
    .\Run-MCPTests.ps1 -SkipPerformanceTests
    Exécute les tests unitaires et d'intégration, puis génère un rapport.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-21
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipUnitTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipIntegrationTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipReport
)

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Créer le répertoire des rapports s'il n'existe pas
$reportsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\docs\test_reports"
if (-not (Test-Path -Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Exécuter les tests unitaires
if (-not $SkipUnitTests) {
    Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
    
    $unitTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "unit\MCPClient.Tests.ps1"
    
    if (Test-Path -Path $unitTestsPath) {
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $unitTestsPath
        $pesterConfig.Output.Verbosity = 'Detailed'
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportsDir -ChildPath "MCPClient.Tests.xml"
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        
        $unitTestResults = Invoke-Pester -Configuration $pesterConfig -PassThru
        
        Write-Host "Tests unitaires terminés avec $($unitTestResults.PassedCount) tests réussis sur $($unitTestResults.TotalCount)" -ForegroundColor $(if ($unitTestResults.FailedCount -eq 0) { "Green" } else { "Red" })
    } else {
        Write-Warning "Fichier de tests unitaires introuvable: $unitTestsPath"
    }
}

# Exécuter les tests d'intégration
if (-not $SkipIntegrationTests) {
    Write-Host "Exécution des tests d'intégration..." -ForegroundColor Cyan
    
    $integrationTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "integration\MCPClient.Integration.Tests.ps1"
    
    if (Test-Path -Path $integrationTestsPath) {
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $integrationTestsPath
        $pesterConfig.Output.Verbosity = 'Detailed'
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path -Path $reportsDir -ChildPath "MCPClient.Integration.Tests.xml"
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPClient.psm1"
        $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $reportsDir -ChildPath "MCPClient.Integration.Coverage.xml"
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        
        $integrationTestResults = Invoke-Pester -Configuration $pesterConfig -PassThru
        
        Write-Host "Tests d'intégration terminés avec $($integrationTestResults.PassedCount) tests réussis sur $($integrationTestResults.TotalCount)" -ForegroundColor $(if ($integrationTestResults.FailedCount -eq 0) { "Green" } else { "Red" })
    } else {
        Write-Warning "Fichier de tests d'intégration introuvable: $integrationTestsPath"
    }
}

# Exécuter les tests de performance
if (-not $SkipPerformanceTests) {
    Write-Host "Exécution des tests de performance..." -ForegroundColor Cyan
    
    $performanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "performance\MCPClient.Performance.Tests.ps1"
    
    if (Test-Path -Path $performanceTestsPath) {
        & $performanceTestsPath
    } else {
        Write-Warning "Fichier de tests de performance introuvable: $performanceTestsPath"
    }
}

# Générer le rapport
if (-not $SkipReport) {
    Write-Host "Génération du rapport de tests..." -ForegroundColor Cyan
    
    $reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-TestReport.ps1"
    
    if (Test-Path -Path $reportScriptPath) {
        $reportPath = Join-Path -Path $reportsDir -ChildPath "MCP_TestReport.md"
        $jsonReportPath = Join-Path -Path $reportsDir -ChildPath "MCP_TestReport.json"
        
        & $reportScriptPath -OutputPath $reportPath -JsonOutputPath $jsonReportPath
    } else {
        Write-Warning "Script de génération de rapport introuvable: $reportScriptPath"
    }
}

Write-Host "Tous les tests sont terminés." -ForegroundColor Green
