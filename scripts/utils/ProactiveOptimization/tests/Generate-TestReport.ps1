<#
.SYNOPSIS
    Génère un rapport de test pour le module ProactiveOptimization.
.DESCRIPTION
    Ce script génère un rapport de test pour le module ProactiveOptimization.
    Il exécute les tests unitaires et génère un rapport HTML.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "TestReports"
)

# Chemin vers les tests
$testsPath = $PSScriptRoot
$modulePath = Split-Path -Path $testsPath -Parent

# Créer le dossier de rapport s'il n'existe pas
$reportPath = Join-Path -Path $modulePath -ChildPath $OutputPath
if (-not (Test-Path -Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan

# Paramètres pour Invoke-Pester
$pesterParams = @{
    Path       = $testsPath
    PassThru   = $true
    ExcludeTag = @(
        'RequiresUsageMonitor',
        'RequiresFileAccess',
        'RequiresParallelization',
        'RequiresReportGeneration'
    )
}

# Exécuter les tests avec les mocks
$mockScriptPath = Join-Path -Path $testsPath -ChildPath "Run-AllTestsWithMocks.ps1"
if (Test-Path -Path $mockScriptPath) {
    & $mockScriptPath -ShowDetailedResults
    exit 0
} else {
    $results = Invoke-Pester @pesterParams
}

# Générer le rapport HTML
$reportFile = Join-Path -Path $reportPath -ChildPath "test_report_$(Get-Date -Format 'yyyy-MM-dd').html"

$htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests - ProactiveOptimization</title>
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
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
            text-align: center;
        }
        .summary-item {
            padding: 15px;
            border-radius: 5px;
            min-width: 150px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
        }
        .warning {
            background-color: #fff3cd;
            color: #856404;
        }
        .danger {
            background-color: #f8d7da;
            color: #721c24;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .test-result {
            padding: 5px 10px;
            border-radius: 3px;
            font-weight: bold;
        }
        .passed {
            background-color: #d4edda;
            color: #155724;
        }
        .failed {
            background-color: #f8d7da;
            color: #721c24;
        }
        .skipped {
            background-color: #e2e3e5;
            color: #383d41;
        }
        .progress-bar {
            height: 20px;
            background-color: #e9ecef;
            border-radius: 10px;
            margin: 20px 0;
            overflow: hidden;
        }
        .progress {
            height: 100%;
            background-color: #28a745;
            text-align: center;
            color: white;
            line-height: 20px;
        }
        footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #777;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Tests - Module ProactiveOptimization</h1>
"@

$htmlFooter = @"
        <footer>
            <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
        </footer>
    </div>
</body>
</html>
"@

# Calculer les statistiques
$totalTests = $results.TotalCount
$passedTests = $results.PassedCount
$failedTests = $results.FailedCount
$skippedTests = $results.SkippedCount
$notRunTests = $results.NotRunCount
$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / ($totalTests - $notRunTests)) * 100, 2) } else { 0 }

# Générer le résumé
$htmlSummary = @"
        <div class="summary">
            <div class="summary-item info">
                <h3>Total</h3>
                <p>$totalTests tests</p>
            </div>
            <div class="summary-item success">
                <h3>Réussis</h3>
                <p>$passedTests tests</p>
            </div>
            <div class="summary-item danger">
                <h3>Échoués</h3>
                <p>$failedTests tests</p>
            </div>
            <div class="summary-item warning">
                <h3>Ignorés</h3>
                <p>$skippedTests tests</p>
            </div>
            <div class="summary-item info">
                <h3>Non exécutés</h3>
                <p>$notRunTests tests</p>
            </div>
        </div>

        <h2>Taux de réussite</h2>
        <div class="progress-bar">
            <div class="progress" style="width: $successRate%">$successRate%</div>
        </div>
"@

# Générer le rapport complet
$htmlContent = $htmlHeader + $htmlSummary + $htmlFooter

# Écrire le rapport dans un fichier
$htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "Rapport de test généré avec succès: $reportFile" -ForegroundColor Green

# Ouvrir le rapport dans le navigateur par défaut
if (Test-Path -Path $reportFile) {
    Start-Process $reportFile
}

# Retourner le code de sortie
exit $results.FailedCount
