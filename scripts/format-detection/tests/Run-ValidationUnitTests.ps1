#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les scripts de validation de détection de format.

.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les scripts de validation de détection de format
    développés dans le cadre de la section 2.1.5 de la roadmap. Il utilise le framework Pester
    pour exécuter les tests et génère des rapports de test.

.PARAMETER OutputDirectory
    Le répertoire où les rapports de test seront enregistrés.
    Par défaut, utilise le répertoire 'test_reports' dans le répertoire du script.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré.
    Par défaut, cette option est activée.

.EXAMPLE
    .\Run-ValidationUnitTests.ps1 -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "test_reports"),
    
    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Vérifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1).Version
Write-Host "Version de Pester détectée : $pesterVersion" -ForegroundColor Cyan

# Fonction pour créer un répertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire créé : $Path"
    }
}

# Créer le répertoire de sortie
New-DirectoryIfNotExists -Path $OutputDirectory

# Chemins des fichiers de test
$testFiles = @(
    "$PSScriptRoot\MalformedSamples.Tests.ps1",
    "$PSScriptRoot\DetectionAccuracy.Tests.ps1",
    "$PSScriptRoot\OptimizeAlgorithms.Tests.ps1"
)

# Vérifier si les fichiers de test existent
$missingTests = $testFiles | Where-Object { -not (Test-Path -Path $_) }

if ($missingTests.Count -gt 0) {
    Write-Warning "Les fichiers de test suivants sont manquants :`n$($missingTests -join "`n")"
}

$existingTests = $testFiles | Where-Object { Test-Path -Path $_ }

if ($existingTests.Count -eq 0) {
    Write-Error "Aucun fichier de test n'a été trouvé."
    exit 1
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $existingTests
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputDirectory -ChildPath "ValidationUnitTestResults.xml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputDirectory -ChildPath "ValidationUnitTestCoverage.xml"
$pesterConfig.CodeCoverage.Path = @(
    "$PSScriptRoot\Generate-MalformedSamples.ps1",
    "$PSScriptRoot\Measure-DetectionAccuracy.ps1",
    "$PSScriptRoot\Optimize-DetectionAlgorithms.ps1"
)

# Exécuter les tests
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des résultats de test :" -ForegroundColor Yellow
Write-Host "Tests exécutés : $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis : $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Générer un rapport HTML si demandé
if ($GenerateHtmlReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Cyan
    
    $htmlReportPath = Join-Path -Path $OutputDirectory -ChildPath "ValidationUnitTestReport.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests unitaires - Validation de détection de format</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .metrics {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        .metric-card {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .metric-card h3 {
            margin-top: 0;
            color: #3498db;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
        }
        .success {
            color: #27ae60;
        }
        .failure {
            color: #e74c3c;
        }
        .warning {
            color: #f39c12;
        }
        .neutral {
            color: #2c3e50;
        }
        .test-results {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .test-results th, .test-results td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .test-results th {
            background-color: #3498db;
            color: white;
        }
        .test-results tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .test-results tr:hover {
            background-color: #e9e9e9;
        }
        .test-file {
            margin-bottom: 30px;
        }
        .test-file h3 {
            margin-top: 0;
            color: #3498db;
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests unitaires - Validation de détection de format</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Date d'exécution:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Version de Pester:</strong> $pesterVersion</p>
        </div>
        
        <div class="metrics">
            <div class="metric-card">
                <h3>Tests exécutés</h3>
                <div class="metric-value neutral">$($testResults.TotalCount)</div>
            </div>
            <div class="metric-card">
                <h3>Tests réussis</h3>
                <div class="metric-value success">$($testResults.PassedCount)</div>
            </div>
            <div class="metric-card">
                <h3>Tests échoués</h3>
                <div class="metric-value failure">$($testResults.FailedCount)</div>
            </div>
            <div class="metric-card">
                <h3>Tests ignorés</h3>
                <div class="metric-value warning">$($testResults.SkippedCount)</div>
            </div>
            <div class="metric-card">
                <h3>Durée totale</h3>
                <div class="metric-value neutral">$([Math]::Round($testResults.Duration.TotalSeconds, 2)) s</div>
            </div>
        </div>
        
        <h2>Résultats détaillés</h2>
"@

    # Ajouter les résultats détaillés pour chaque fichier de test
    foreach ($testFile in $existingTests) {
        $fileName = [System.IO.Path]::GetFileName($testFile)
        $fileTests = $testResults.Tests | Where-Object { $_.Path -like "*$fileName*" }
        
        $html += @"
        <div class="test-file">
            <h3>$fileName</h3>
            <table class="test-results">
                <thead>
                    <tr>
                        <th>Nom du test</th>
                        <th>Résultat</th>
                        <th>Durée</th>
                    </tr>
                </thead>
                <tbody>
"@
        
        foreach ($test in $fileTests) {
            $resultClass = switch ($test.Result) {
                "Passed" { "success" }
                "Failed" { "failure" }
                "Skipped" { "warning" }
                default { "neutral" }
            }
            
            $testName = $test.Name -replace '^[^.]+\.', ''
            $duration = [Math]::Round($test.Duration.TotalMilliseconds, 2)
            
            $html += @"
                    <tr>
                        <td>$testName</td>
                        <td class="$resultClass">$($test.Result)</td>
                        <td>$duration ms</td>
                    </tr>
"@
        }
        
        $html += @"
                </tbody>
            </table>
        </div>
"@
    }
    
    $html += @"
    </div>
</body>
</html>
"@
    
    $html | Set-Content -Path $htmlReportPath -Encoding UTF8
    Write-Host "Rapport HTML généré : $htmlReportPath" -ForegroundColor Green
}

# Retourner les résultats
return $testResults
