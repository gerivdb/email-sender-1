#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour vÃ©rifier le bon fonctionnement
    de l'architecture hybride PowerShell-Python et des cas d'usage implÃ©mentÃ©s.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenReport
)

# Importer le module Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Installer les dÃ©pendances Python si nÃ©cessaire
$installDependenciesPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "install_dependencies.ps1"
if (Test-Path -Path $installDependenciesPath) {
    Write-Host "Installation des dÃ©pendances Python..." -ForegroundColor Yellow
    & $installDependenciesPath
}

# CrÃ©er un rÃ©pertoire pour les rapports de tests
$testReportsPath = Join-Path -Path $scriptPath -ChildPath "test_reports"
if (-not (Test-Path -Path $testReportsPath)) {
    New-Item -Path $testReportsPath -ItemType Directory -Force | Out-Null
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $scriptPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path -Path $testReportsPath -ChildPath "test_results.xml"
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @(
        (Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ParallelHybrid.psm1"),
        (Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "TaskManager.psm1"),
        (Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "CacheAdapter.psm1")
    )
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $testReportsPath -ChildPath "coverage.xml"
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Yellow
Write-Host "  Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor Yellow
Write-Host "  Tests rÃ©ussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s : $($testResults.FailedCount)" -ForegroundColor ($testResults.FailedCount -gt 0 ? "Red" : "Green")
Write-Host "  Tests ignorÃ©s : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exÃ©cutÃ©s : $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Yellow

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    Write-Host "`nGÃ©nÃ©ration du rapport HTML..." -ForegroundColor Cyan
    
    # CrÃ©er un rapport HTML simple
    $htmlReportPath = Join-Path -Path $testReportsPath -ChildPath "test_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests unitaires</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 10px;
        }
        .summary-item {
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .summary-item h3 {
            margin-top: 0;
        }
        .success {
            color: #107C10;
        }
        .failure {
            color: #D83B01;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .test-passed {
            background-color: #DFF6DD;
        }
        .test-failed {
            background-color: #FED9CC;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests unitaires</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <div class="summary-grid">
            <div class="summary-item">
                <h3>Tests exÃ©cutÃ©s</h3>
                <p>$($testResults.TotalCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests rÃ©ussis</h3>
                <p class="success">$($testResults.PassedCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests Ã©chouÃ©s</h3>
                <p class="failure">$($testResults.FailedCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests ignorÃ©s</h3>
                <p>$($testResults.SkippedCount)</p>
            </div>
            <div class="summary-item">
                <h3>DurÃ©e totale</h3>
                <p>$([Math]::Round($testResults.Duration.TotalSeconds, 2)) secondes</p>
            </div>
        </div>
    </div>
    
    <h2>DÃ©tails des tests</h2>
    <table>
        <thead>
            <tr>
                <th>Nom du test</th>
                <th>RÃ©sultat</th>
                <th>DurÃ©e (s)</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($container in $testResults.Containers) {
        foreach ($block in $container.Blocks) {
            foreach ($test in $block.Tests) {
                $testClass = $test.Result -eq "Passed" ? "test-passed" : "test-failed"
                $testResult = $test.Result -eq "Passed" ? "SuccÃ¨s" : "Ã‰chec"
                
                $htmlContent += @"
            <tr class="$testClass">
                <td>$($test.Name)</td>
                <td>$testResult</td>
                <td>$([Math]::Round($test.Duration.TotalSeconds, 3))</td>
            </tr>
"@
            }
        }
    }
    
    $htmlContent += @"
        </tbody>
    </table>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlReportPath -Encoding utf8
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlReportPath" -ForegroundColor Green
    
    if ($OpenReport) {
        Start-Process $htmlReportPath
    }
}

# Retourner les rÃ©sultats des tests
return $testResults
