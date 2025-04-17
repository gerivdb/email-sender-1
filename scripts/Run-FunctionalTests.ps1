<#
.SYNOPSIS
    Script d'exÃ©cution des tests fonctionnels pour le cache prÃ©dictif.
.DESCRIPTION
    Ce script exÃ©cute les tests fonctionnels du cache prÃ©dictif
    et gÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# DÃ©finir les chemins
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
$reportDir = Join-Path -Path $testDir -ChildPath "Reports"

# CrÃ©er les rÃ©pertoires nÃ©cessaires
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

# Fonction pour exÃ©cuter un test et gÃ©nÃ©rer un rapport
function Invoke-TestWithReport {
    param(
        [string]$TestName,
        [string]$TestPath,
        [string]$ReportPath
    )
    
    Write-Host "ExÃ©cution du test : $TestName" -ForegroundColor Yellow
    
    $startTime = Get-Date
    $output = & $TestPath
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Analyser la sortie pour dÃ©terminer le rÃ©sultat
    $success = $output -match "Tous les tests ont rÃ©ussi!"
    $totalTests = ($output | Select-String -Pattern "Tests exÃ©cutÃ©s: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $passedTests = ($output | Select-String -Pattern "Tests rÃ©ussis: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $failedTests = ($output | Select-String -Pattern "Tests Ã©chouÃ©s: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [int]
    $successRate = ($output | Select-String -Pattern "Taux de rÃ©ussite: ([\d\.]+)%" | ForEach-Object { $_.Matches.Groups[1].Value }) -as [double]
    
    # CrÃ©er un rapport HTML
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
            <h2>RÃ©sumÃ©</h2>
            <p>Date d'exÃ©cution : $startTime</p>
            <p>DurÃ©e : $duration secondes</p>
            <p>Tests exÃ©cutÃ©s : $totalTests</p>
            <p>Tests rÃ©ussis : <span class="success">$passedTests</span></p>
            <p>Tests Ã©chouÃ©s : <span class="failure">$failedTests</span></p>
            
            <div class="progress-bar">
                <div class="progress" style="width: $successRate%">$successRate%</div>
            </div>
            
            <p>RÃ©sultat global : 
                $(if ($success) {
                    '<span class="success">SUCCÃˆS</span>'
                } else {
                    '<span class="failure">Ã‰CHEC</span>'
                })
            </p>
        </div>
        
        <div class="details">
            <h2>DÃ©tails</h2>
            <pre>$($output -join "`n")</pre>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $ReportPath -Encoding UTF8
    
    # Retourner un objet avec les rÃ©sultats
    return [PSCustomObject]@{
        TestName = $TestName
        Success = $success
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SuccessRate = $successRate
        Duration = $duration
        ReportPath = $ReportPath
    }
}

# Fonction pour gÃ©nÃ©rer un rapport global
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
        $statusText = if ($_.Success) { "SUCCÃˆS" } else { "Ã‰CHEC" }
        
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
    <title>Rapport global des tests du cache prÃ©dictif</title>
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
        <h1>Rapport global des tests du cache prÃ©dictif</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p>Date d'exÃ©cution : $(Get-Date)</p>
            <p>DurÃ©e totale : $totalDuration secondes</p>
            <p>Tests exÃ©cutÃ©s : $totalTests</p>
            <p>Tests rÃ©ussis : <span class="success">$passedTests</span></p>
            <p>Tests Ã©chouÃ©s : <span class="failure">$failedTests</span></p>
            
            <div class="progress-bar">
                <div class="progress" style="width: $successRate%">$successRate%</div>
            </div>
            
            <p>RÃ©sultat global : 
                $(if ($allSuccess) {
                    '<span class="success">SUCCÃˆS</span>'
                } else {
                    '<span class="failure">Ã‰CHEC</span>'
                })
            </p>
        </div>
        
        <h2>DÃ©tails des tests</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>Total</th>
                <th>RÃ©ussis</th>
                <th>Ã‰chouÃ©s</th>
                <th>Taux</th>
                <th>DurÃ©e</th>
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

# ExÃ©cuter les tests
Show-SectionTitle "ExÃ©cution des tests fonctionnels du cache prÃ©dictif"

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

# GÃ©nÃ©rer le rapport global
Show-SectionTitle "GÃ©nÃ©ration du rapport global"

$globalReportPath = Join-Path -Path $reportDir -ChildPath "Global-Report.html"
New-GlobalReport -TestResults $testResults -ReportPath $globalReportPath

Write-Host "Rapport global gÃ©nÃ©rÃ© : $globalReportPath" -ForegroundColor Green

# Afficher le rÃ©sumÃ©
Show-SectionTitle "RÃ©sumÃ© des tests"

$totalTests = ($testResults | Measure-Object -Property TotalTests -Sum).Sum
$passedTests = ($testResults | Measure-Object -Property PassedTests -Sum).Sum
$failedTests = ($testResults | Measure-Object -Property FailedTests -Sum).Sum
$successRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Tests exÃ©cutÃ©s : $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis : $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $failedTests" -ForegroundColor Red
Write-Host "Taux de rÃ©ussite : $successRate%" -ForegroundColor Cyan

# Ouvrir le rapport global
$openReport = Read-Host "Voulez-vous ouvrir le rapport global dans votre navigateur ? (O/N)"
if ($openReport -eq "O" -or $openReport -eq "o") {
    Open-Report -ReportPath $globalReportPath
}

# RÃ©sultat final
if ($failedTests -eq 0) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
