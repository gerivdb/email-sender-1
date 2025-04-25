<#
.SYNOPSIS
    Exécute tous les tests pour les modes et génère un rapport de couverture.

.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration pour les différents modes
    et génère un rapport de couverture global. Il permet de s'assurer que tous les modes
    fonctionnent correctement individuellement et ensemble.

.PARAMETER OutputPath
    Chemin où seront générés les rapports de test et de couverture.

.PARAMETER ShowResults
    Indique si les résultats des tests doivent être affichés dans la console.

.PARAMETER GenerateReport
    Indique si un rapport HTML doit être généré.

.EXAMPLE
    .\Invoke-AllTests.ps1 -OutputPath "test-reports" -ShowResults $true -GenerateReport $true

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "test-reports",
    
    [Parameter(Mandatory = $false)]
    [bool]$ShowResults = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$GenerateReport = $true
)

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
        Import-Module Pester
        Write-Host "Module Pester installé avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
} else {
    Import-Module Pester
    Write-Host "Module Pester déjà installé." -ForegroundColor Green
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputPath" -ForegroundColor Green
}

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = Get-ChildItem -Path $scriptPath -Filter "Test-*.ps1" | Where-Object { $_.Name -ne "Test-Template.ps1" }

Write-Host "Tests trouvés : $($testFiles.Count)" -ForegroundColor Green
foreach ($testFile in $testFiles) {
    Write-Host "  - $($testFile.Name)" -ForegroundColor Gray
}

# Configuration des tests
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $scriptPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = Join-Path -Path $scriptPath -ChildPath "..\Functions\Public\*.ps1"
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "test-results.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Yellow
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les résultats
if ($ShowResults) {
    Write-Host "`nRésultats des tests :" -ForegroundColor Yellow
    Write-Host "  - Tests exécutés : $($testResults.TotalCount)" -ForegroundColor $(if ($testResults.TotalCount -gt 0) { "Green" } else { "Red" })
    Write-Host "  - Tests réussis : $($testResults.PassedCount)" -ForegroundColor $(if ($testResults.PassedCount -eq $testResults.TotalCount) { "Green" } else { "Yellow" })
    Write-Host "  - Tests échoués : $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { "Green" } else { "Red" })
    Write-Host "  - Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor $(if ($testResults.SkippedCount -eq 0) { "Green" } else { "Yellow" })
    Write-Host "  - Durée totale : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Gray
    
    if ($testResults.FailedCount -gt 0) {
        Write-Host "`nTests échoués :" -ForegroundColor Red
        foreach ($failedTest in $testResults.Failed) {
            Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
            Write-Host "    $($failedTest.ErrorRecord)" -ForegroundColor Gray
        }
    }
}

# Générer un rapport HTML
if ($GenerateReport) {
    Write-Host "`nGénération du rapport HTML..." -ForegroundColor Yellow
    
    # Créer le rapport HTML
    $reportPath = Join-Path -Path $OutputPath -ChildPath "test-report.html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - Modes RoadmapParser</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-container {
            width: 100%;
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests - Modes RoadmapParser</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Date d'exécution : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <div class="progress-container">
            <div class="progress-bar" style="width: $([Math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100))%">
                $([Math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100))%
            </div>
        </div>
        <p>Tests exécutés : <strong>$($testResults.TotalCount)</strong></p>
        <p>Tests réussis : <span class="success"><strong>$($testResults.PassedCount)</strong></span></p>
        <p>Tests échoués : <span class="danger"><strong>$($testResults.FailedCount)</strong></span></p>
        <p>Tests ignorés : <span class="warning"><strong>$($testResults.SkippedCount)</strong></span></p>
        <p>Durée totale : <strong>$($testResults.Duration.TotalSeconds) secondes</strong></p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
        </tr>
"@

    foreach ($test in $testResults.Tests) {
        $resultClass = switch ($test.Result) {
            "Passed" { "success" }
            "Failed" { "danger" }
            "Skipped" { "warning" }
            default { "" }
        }
        
        $htmlReport += @"
        <tr>
            <td>$($test.Name)</td>
            <td class="$resultClass">$($test.Result)</td>
            <td>$($test.Duration.TotalMilliseconds)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Tests échoués</h2>
"@

    if ($testResults.FailedCount -gt 0) {
        $htmlReport += @"
    <table>
        <tr>
            <th>Nom</th>
            <th>Message d'erreur</th>
        </tr>
"@

        foreach ($failedTest in $testResults.Failed) {
            $htmlReport += @"
        <tr>
            <td>$($failedTest.Name)</td>
            <td>$($failedTest.ErrorRecord)</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>
"@
    } else {
        $htmlReport += @"
    <p class="success">Aucun test n'a échoué.</p>
"@
    }

    $htmlReport += @"
</body>
</html>
"@

    $htmlReport | Set-Content -Path $reportPath -Encoding UTF8
    Write-Host "Rapport HTML généré : $reportPath" -ForegroundColor Green
}

# Afficher le chemin des rapports
Write-Host "`nRapports générés :" -ForegroundColor Yellow
Write-Host "  - Rapport de tests : $(Join-Path -Path $OutputPath -ChildPath "test-results.xml")" -ForegroundColor Gray
Write-Host "  - Rapport de couverture : $(Join-Path -Path $OutputPath -ChildPath "coverage.xml")" -ForegroundColor Gray
if ($GenerateReport) {
    Write-Host "  - Rapport HTML : $(Join-Path -Path $OutputPath -ChildPath "test-report.html")" -ForegroundColor Gray
}

# Retourner les résultats
return $testResults
