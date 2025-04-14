<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les hooks Git.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les hooks Git en utilisant Pester.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$ShowTestResults,
    
    [Parameter()]
    [switch]$GenerateReport
)

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Error "Le module Pester n'est pas installé. Veuillez l'installer avec la commande 'Install-Module -Name Pester -Force'."
    exit 1
}

# Importer le module Pester
Import-Module Pester -Force

# Définir les options de configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = Join-Path -Path $PSScriptRoot -ChildPath "tests"
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"

if ($GenerateReport) {
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "reports\test-report.xml"
    $reportDir = Split-Path -Path $reportPath -Parent
    
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $reportPath
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour les hooks Git..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Afficher les résultats
if ($ShowTestResults) {
    $results
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Tests non exécutés: $($results.NotRunCount)" -ForegroundColor Gray

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    $htmlReportPath = Join-Path -Path $PSScriptRoot -ChildPath "reports\test-report.html"
    
    # Créer un rapport HTML simple
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests unitaires - Hooks Git</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            color: #333;
        }
        .summary {
            margin: 20px 0;
            padding: 10px;
            background-color: #f5f5f5;
            border-radius: 5px;
        }
        .passed {
            color: green;
        }
        .failed {
            color: red;
        }
        .skipped {
            color: orange;
        }
        .not-run {
            color: gray;
        }
        table {
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests unitaires - Hooks Git</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés: $($results.TotalCount)</p>
        <p class="passed">Tests réussis: $($results.PassedCount)</p>
        <p class="failed">Tests échoués: $($results.FailedCount)</p>
        <p class="skipped">Tests ignorés: $($results.SkippedCount)</p>
        <p class="not-run">Tests non exécutés: $($results.NotRunCount)</p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom du test</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
        </tr>
"@

    foreach ($test in $results.Tests) {
        $resultClass = switch ($test.Result) {
            "Passed" { "passed" }
            "Failed" { "failed" }
            "Skipped" { "skipped" }
            default { "not-run" }
        }
        
        $htmlReport += @"
        <tr>
            <td>$($test.Name)</td>
            <td class="$resultClass">$($test.Result)</td>
            <td>$($test.Duration.TotalMilliseconds.ToString("F2"))</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Informations sur l'exécution</h2>
    <p>Date d'exécution: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    <p>Durée totale: $($results.Duration.TotalSeconds.ToString("F2")) secondes</p>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $htmlReportPath -Encoding utf8
    
    Write-Host "`nRapport HTML généré: $htmlReportPath" -ForegroundColor Cyan
}

# Retourner un code de sortie en fonction des résultats
if ($results.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
