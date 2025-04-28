<#
.SYNOPSIS
    Version simplifiÃ©e de TestOmnibus pour tester l'intÃ©gration.
.DESCRIPTION
    Ce script est une version simplifiÃ©e de TestOmnibus qui permet de tester
    l'intÃ©gration avec le SystÃ¨me d'Optimisation Proactive.
.PARAMETER Path
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration.
.EXAMPLE
    .\Invoke-TestOmnibus.ps1 -Path "C:\Tests"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# DÃ©finir l'encodage de la console en UTF-8
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Charger la configuration
$config = @{
    MaxThreads             = 4
    OutputPath             = Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"
    GenerateHtmlReport     = $true
    CollectPerformanceData = $true
}

if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
    try {
        $configFromFile = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        if ($configFromFile.MaxThreads) {
            $config.MaxThreads = $configFromFile.MaxThreads
        }

        if ($configFromFile.OutputPath) {
            $config.OutputPath = $configFromFile.OutputPath
        }

        if ($null -ne $configFromFile.GenerateHtmlReport) {
            $config.GenerateHtmlReport = $configFromFile.GenerateHtmlReport
        }

        if ($null -ne $configFromFile.CollectPerformanceData) {
            $config.CollectPerformanceData = $configFromFile.CollectPerformanceData
        }

        if ($configFromFile.PriorityScripts) {
            $config.PriorityScripts = $configFromFile.PriorityScripts
        }
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration: $_"
    }
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $config.OutputPath)) {
    New-Item -Path $config.OutputPath -ItemType Directory -Force | Out-Null
}

# Rechercher les tests
$testFiles = Get-ChildItem -Path $Path -Filter "*.Tests.ps1" -Recurse

if ($testFiles.Count -eq 0) {
    Write-Warning "Aucun fichier de test trouvÃ© dans: $Path"
    return
}

Write-Host "ExÃ©cution de $($testFiles.Count) tests avec $($config.MaxThreads) threads..." -ForegroundColor Cyan

# PrÃ©parer les rÃ©sultats
$results = @()

# ExÃ©cuter les tests
foreach ($testFile in $testFiles) {
    Write-Host "ExÃ©cution du test: $($testFile.Name)" -ForegroundColor Yellow

    $startTime = Get-Date
    $success = $true
    $errorMessage = ""

    try {
        # Simuler l'exÃ©cution du test
        if ($testFile.Name -match "Failing") {
            # Simuler un Ã©chec
            $success = $false
            $errorMessage = "Test Ã©chouÃ©"
            Write-Host "  - Ã‰chec" -ForegroundColor Red
        } elseif ($testFile.Name -match "Slow") {
            # Simuler un test lent
            Start-Sleep -Seconds 2
            Write-Host "  - SuccÃ¨s (lent)" -ForegroundColor Green
        } else {
            # Simuler un succÃ¨s
            Start-Sleep -Milliseconds 100
            Write-Host "  - SuccÃ¨s" -ForegroundColor Green
        }
    } catch {
        $success = $false
        $errorMessage = $_.Exception.Message
        Write-Host "  - Erreur: $errorMessage" -ForegroundColor Red
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    # Ajouter le rÃ©sultat
    $result = [PSCustomObject]@{
        Name         = $testFile.Name -replace "\.Tests\.ps1", ""
        Path         = $testFile.FullName
        Success      = $success
        ErrorMessage = $errorMessage
        Duration     = $duration
        StartTime    = $startTime
        EndTime      = $endTime
    }

    $results += $result
}

# GÃ©nÃ©rer un rapport XML
$resultsPath = Join-Path -Path $config.OutputPath -ChildPath "results.xml"
$results | Export-Clixml -Path $resultsPath -Force

Write-Host "RÃ©sultats des tests sauvegardÃ©s: $resultsPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($config.GenerateHtmlReport) {
    $reportPath = Join-Path -Path $config.OutputPath -ChildPath "report.html"

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests</title>
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
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
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
        .success {
            color: #2ecc71;
        }
        .failure {
            color: #e74c3c;
        }
        .slow {
            color: #f39c12;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Tests</h1>
        <p>G&eacute;n&eacute;r&eacute; le $(Get-Date -Format "dd/MM/yyyy \&agrave; HH:mm:ss")</p>

        <h2>R&eacute;sum&eacute;</h2>
        <p>
            <strong>Tests ex&eacute;cut&eacute;s:</strong> $($results.Count)<br>
            <strong>Tests r&eacute;ussis:</strong> $(($results | Where-Object { $_.Success }).Count)<br>
            <strong>Tests &eacute;chou&eacute;s:</strong> $(($results | Where-Object { -not $_.Success }).Count)<br>
            <strong>Dur&eacute;e totale:</strong> $([math]::Round(($results | Measure-Object -Property Duration -Sum).Sum, 2)) ms<br>
            <strong>Threads utilis&eacute;s:</strong> $($config.MaxThreads)
        </p>

        <h2>R&eacute;sultats d&eacute;taill&eacute;s</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>R&eacute;sultat</th>
                <th>Dur&eacute;e (ms)</th>
                <th>D&eacute;tails</th>
            </tr>
"@

    foreach ($result in $results) {
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        $statusText = if ($result.Success) { "Succ&egrave;s" } else { "&Eacute;chec" }

        if ($result.Success -and $result.Duration -gt 1000) {
            $statusClass = "slow"
            $statusText = "Succ&egrave;s (lent)"
        }

        $html += @"
            <tr>
                <td>$($result.Name)</td>
                <td class="$statusClass">$statusText</td>
                <td>$([math]::Round($result.Duration, 2))</td>
                <td>$($result.ErrorMessage)</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <div class="footer">
            <p>G&eacute;n&eacute;r&eacute; par TestOmnibus</p>
        </div>
    </div>
</body>
</html>
"@

    # Utiliser UTF-8 avec BOM pour Ã©viter les problÃ¨mes d'encodage
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($reportPath, $html, $utf8WithBom)

    Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
}

# Afficher un rÃ©sumÃ©
$successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
$totalDuration = ($results | Measure-Object -Property Duration -Sum).Sum

Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  - Tests exÃ©cutÃ©s: $($results.Count)" -ForegroundColor White
Write-Host "  - Tests rÃ©ussis: $successCount" -ForegroundColor Green
Write-Host "  - Tests Ã©chouÃ©s: $failureCount" -ForegroundColor Red
Write-Host "  - DurÃ©e totale: $([math]::Round($totalDuration, 2)) ms" -ForegroundColor White
Write-Host "  - Threads utilisÃ©s: $($config.MaxThreads)" -ForegroundColor White

# Retourner les rÃ©sultats
return $results
