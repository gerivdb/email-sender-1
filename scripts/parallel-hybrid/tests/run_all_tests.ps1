#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour vérifier le bon fonctionnement
    de l'architecture hybride PowerShell-Python et des cas d'usage implémentés.
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
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Installer les dépendances Python si nécessaire
$installDependenciesPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "install_dependencies.ps1"
if (Test-Path -Path $installDependenciesPath) {
    Write-Host "Installation des dépendances Python..." -ForegroundColor Yellow
    & $installDependenciesPath
}

# Créer un répertoire pour les rapports de tests
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

# Exécuter les tests
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :" -ForegroundColor Yellow
Write-Host "  Tests exécutés : $($testResults.TotalCount)" -ForegroundColor Yellow
Write-Host "  Tests réussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués : $($testResults.FailedCount)" -ForegroundColor ($testResults.FailedCount -gt 0 ? "Red" : "Green")
Write-Host "  Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés : $($testResults.NotRunCount)" -ForegroundColor Yellow
Write-Host "  Durée totale : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Yellow

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Cyan
    
    # Créer un rapport HTML simple
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
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <div class="summary-grid">
            <div class="summary-item">
                <h3>Tests exécutés</h3>
                <p>$($testResults.TotalCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests réussis</h3>
                <p class="success">$($testResults.PassedCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests échoués</h3>
                <p class="failure">$($testResults.FailedCount)</p>
            </div>
            <div class="summary-item">
                <h3>Tests ignorés</h3>
                <p>$($testResults.SkippedCount)</p>
            </div>
            <div class="summary-item">
                <h3>Durée totale</h3>
                <p>$([Math]::Round($testResults.Duration.TotalSeconds, 2)) secondes</p>
            </div>
        </div>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <thead>
            <tr>
                <th>Nom du test</th>
                <th>Résultat</th>
                <th>Durée (s)</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($container in $testResults.Containers) {
        foreach ($block in $container.Blocks) {
            foreach ($test in $block.Tests) {
                $testClass = $test.Result -eq "Passed" ? "test-passed" : "test-failed"
                $testResult = $test.Result -eq "Passed" ? "Succès" : "Échec"
                
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
    
    Write-Host "Rapport HTML généré : $htmlReportPath" -ForegroundColor Green
    
    if ($OpenReport) {
        Start-Process $htmlReportPath
    }
}

# Retourner les résultats des tests
return $testResults
