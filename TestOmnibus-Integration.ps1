<#
.SYNOPSIS
    Script d'intégration avec TestOmnibus pour les tests du cache prédictif.
.DESCRIPTION
    Ce script intègre les tests du cache prédictif avec le système TestOmnibus
    pour une exécution centralisée et des rapports unifiés.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# Définir les chemins
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
$reportDir = Join-Path -Path $testDir -ChildPath "Reports"

# Créer les répertoires nécessaires
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour exécuter un test et générer un rapport
function Invoke-TestWithReport {
    param(
        [string]$TestName,
        [string]$TestPath,
        [string]$ReportPath
    )

    Write-Host "Exécution du test : $TestName" -ForegroundColor Yellow

    $startTime = Get-Date
    $output = & $TestPath
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    # Analyser la sortie pour déterminer le résultat
    $success = $output -match "Tous les tests ont réussi!"
    $totalTests = ($output | Select-String -Pattern "Tests exécutés: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $passedTests = ($output | Select-String -Pattern "Tests réussis: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $failedTests = ($output | Select-String -Pattern "Tests échoués: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $successRate = ($output | Select-String -Pattern "Taux de réussite: ([\d\.]+)%" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [double]

    # Créer un rapport HTML
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de test : $TestName</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
        }
        .summary {
            margin: 20px 0;
            padding: 15px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .failure {
            color: red;
            font-weight: bold;
        }
        .details {
            margin-top: 20px;
        }
        pre {
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .progress-bar {
            height: 20px;
            background-color: #e0e0e0;
            border-radius: 10px;
            margin: 10px 0;
        }
        .progress {
            height: 100%;
            background-color: #4CAF50;
            border-radius: 10px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de test : $TestName</h1>

        <div class="summary">
            <h2>Résumé</h2>
            <p>Date d'exécution : $startTime</p>
            <p>Durée : $duration secondes</p>
            <p>Tests exécutés : $totalTests</p>
            <p>Tests réussis : <span class="success">$passedTests</span></p>
            <p>Tests échoués : <span class="failure">$failedTests</span></p>

            <div class="progress-bar">
                <div class="progress" style="width: $successRate%">$successRate%</div>
            </div>

            <p>Résultat global :
                $(if ($success) {
                    '<span class="success">SUCCÈS</span>'
                } else {
                    '<span class="failure">ÉCHEC</span>'
                })
            </p>
        </div>

        <div class="details">
            <h2>Détails</h2>
            <pre>$($output -join "`n")</pre>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $ReportPath -Encoding UTF8

    # Retourner un objet avec les résultats
    return [PSCustomObject]@{
        TestName    = $TestName
        Success     = $success
        TotalTests  = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SuccessRate = $successRate
        Duration    = $duration
        ReportPath  = $ReportPath
    }
}

# Fonction pour générer un rapport global
function New-GlobalReport {
    param(
        [array]$TestResults,
        [string]$ReportPath
    )

    $totalTests = ($TestResults | Measure-Object -Property TotalTests -Sum).Sum
    $passedTests = ($TestResults | Measure-Object -Property PassedTests -Sum).Sum
    $failedTests = ($TestResults | Measure-Object -Property FailedTests -Sum).Sum
    $successRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    $totalDuration = ($TestResults | Measure-Object -Property Duration -Sum).Sum
    $allSuccess = ($TestResults | Where-Object { -not $_.Success }).Count -eq 0

    $testRows = $TestResults | ForEach-Object {
        $statusClass = if ($_.Success) { "success" } else { "failure" }
        $statusText = if ($_.Success) { "SUCCÈS" } else { "ÉCHEC" }

        @"
        <tr>
            <td>$($_.TestName)</td>
            <td>$($_.TotalTests)</td>
            <td>$($_.PassedTests)</td>
            <td>$($_.FailedTests)</td>
            <td>$($_.SuccessRate)%</td>
            <td>$($_.Duration) s</td>
            <td class="$statusClass">$statusText</td>
            <td><a href="$($_.ReportPath)" target="_blank">Voir le rapport</a></td>
        </tr>
"@
    }

    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport global des tests du cache prédictif</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333;
            border-bottom: 1px solid #ddd;
            padding-bottom: 10px;
        }
        .summary {
            margin: 20px 0;
            padding: 15px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .success {
            color: green;
            font-weight: bold;
        }
        .failure {
            color: red;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .progress-bar {
            height: 20px;
            background-color: #e0e0e0;
            border-radius: 10px;
            margin: 10px 0;
        }
        .progress {
            height: 100%;
            background-color: #4CAF50;
            border-radius: 10px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport global des tests du cache prédictif</h1>

        <div class="summary">
            <h2>Résumé</h2>
            <p>Date d'exécution : $(Get-Date)</p>
            <p>Durée totale : $totalDuration secondes</p>
            <p>Tests exécutés : $totalTests</p>
            <p>Tests réussis : <span class="success">$passedTests</span></p>
            <p>Tests échoués : <span class="failure">$failedTests</span></p>

            <div class="progress-bar">
                <div class="progress" style="width: $successRate%">$successRate%</div>
            </div>

            <p>Résultat global :
                $(if ($allSuccess) {
                    '<span class="success">SUCCÈS</span>'
                } else {
                    '<span class="failure">ÉCHEC</span>'
                })
            </p>
        </div>

        <h2>Détails des tests</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Total</th>
                <th>Réussis</th>
                <th>Échoués</th>
                <th>Taux</th>
                <th>Durée</th>
                <th>Statut</th>
                <th>Rapport</th>
            </tr>
            $testRows
        </table>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $ReportPath -Encoding UTF8

    return $ReportPath
}

# Fonction pour ouvrir un rapport dans le navigateur
function Open-Report {
    param([string]$ReportPath)

    if (Test-Path -Path $ReportPath) {
        Start-Process $ReportPath
    }
}

# Exécuter les tests
Show-SectionTitle "Exécution des tests du cache prédictif"

$testResults = @()

# Test de base
$basicTestPath = Join-Path -Path $scriptDir -ChildPath "Basic-Test.ps1"
$basicReportPath = Join-Path -Path $reportDir -ChildPath "Basic-Test-Report.html"
$basicResult = Invoke-TestWithReport -TestName "Test de base" -TestPath $basicTestPath -ReportPath $basicReportPath
$testResults += $basicResult

# Test complet
$completeTestPath = Join-Path -Path $scriptDir -ChildPath "Complete-Test.ps1"
$completeReportPath = Join-Path -Path $reportDir -ChildPath "Complete-Test-Report.html"
$completeResult = Invoke-TestWithReport -TestName "Test complet" -TestPath $completeTestPath -ReportPath $completeReportPath
$testResults += $completeResult

# Générer le rapport global
Show-SectionTitle "Génération du rapport global"

$globalReportPath = Join-Path -Path $reportDir -ChildPath "Global-Report.html"
New-GlobalReport -TestResults $testResults -ReportPath $globalReportPath

Write-Host "Rapport global généré : $globalReportPath" -ForegroundColor Green

# Afficher le résumé
Show-SectionTitle "Résumé des tests"

$totalTests = ($testResults | Measure-Object -Property TotalTests -Sum).Sum
$passedTests = ($testResults | Measure-Object -Property PassedTests -Sum).Sum
$failedTests = ($testResults | Measure-Object -Property FailedTests -Sum).Sum
$successRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Tests exécutés : $totalTests" -ForegroundColor White
Write-Host "Tests réussis : $passedTests" -ForegroundColor Green
Write-Host "Tests échoués : $failedTests" -ForegroundColor Red
Write-Host "Taux de réussite : $successRate%" -ForegroundColor Cyan

# Ouvrir le rapport global
$openReport = Read-Host "Voulez-vous ouvrir le rapport global dans votre navigateur ? (O/N)"
if ($openReport -eq "O" -or $openReport -eq "o") {
    Open-Report -ReportPath $globalReportPath
}

# Résultat final
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
