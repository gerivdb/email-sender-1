<#
.SYNOPSIS
    ExÃ©cute TestOmnibus avec des paramÃ¨tres optimisÃ©s en fonction des donnÃ©es d'utilisation.
.DESCRIPTION
    Ce script utilise les donnÃ©es d'utilisation collectÃ©es par le systÃ¨me d'optimisation proactive
    pour exÃ©cuter TestOmnibus avec des paramÃ¨tres optimisÃ©s, comme le nombre de threads,
    l'ordre d'exÃ©cution des tests, etc.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER UsageDataPath
    Chemin vers le fichier de donnÃ©es d'utilisation.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats des tests.
.PARAMETER ConfigPath
    Chemin vers un fichier de configuration personnalisÃ©.
.PARAMETER GenerateDetailedReport
    GÃ©nÃ¨re un rapport dÃ©taillÃ© des rÃ©sultats des tests.
.EXAMPLE
    .\Invoke-OptimizedTestOmnibus.ps1 -TestPath "D:\Tests" -UsageDataPath "D:\UsageData\usage_data.xml" -OutputPath "D:\TestResults"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $false)]
    [string]$UsageDataPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"),
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateDetailedReport
)

# VÃ©rifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Chemin vers l'optimiseur
$optimizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimizers\UsageBasedOptimizer.ps1"

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

# VÃ©rifier que les scripts existent
if (-not (Test-Path -Path $optimizerPath)) {
    Write-Error "L'optimiseur n'existe pas: $optimizerPath"
    return 1
}

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
    return 1
}

# ExÃ©cuter l'optimiseur pour obtenir une configuration optimisÃ©e
Write-Host "Optimisation de l'exÃ©cution des tests..." -ForegroundColor Cyan
$optimizedConfig = & $optimizerPath -UsageDataPath $UsageDataPath -OutputPath $OutputPath

# CrÃ©er un fichier de configuration temporaire
$tempConfigPath = Join-Path -Path $OutputPath -ChildPath "optimized_config.json"
$optimizedConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempConfigPath -Encoding utf8 -Force

# Utiliser la configuration personnalisÃ©e si spÃ©cifiÃ©e
$configToUse = if ($ConfigPath -and (Test-Path -Path $ConfigPath)) { $ConfigPath } else { $tempConfigPath }

# ExÃ©cuter TestOmnibus avec la configuration optimisÃ©e
Write-Host "ExÃ©cution de TestOmnibus avec la configuration optimisÃ©e..." -ForegroundColor Cyan
Write-Host "Nombre de threads: $($optimizedConfig.MaxThreads)" -ForegroundColor Cyan
Write-Host "RÃ©pertoire de sortie: $($optimizedConfig.OutputPath)" -ForegroundColor Cyan

# Construire les paramÃ¨tres pour TestOmnibus
$testOmnibusParams = @{
    Path = $TestPath
    ConfigPath = $configToUse
}

# ExÃ©cuter TestOmnibus
$result = & $testOmnibusPath @testOmnibusParams

# GÃ©nÃ©rer un rapport dÃ©taillÃ© si demandÃ©
if ($GenerateDetailedReport) {
    Write-Host "GÃ©nÃ©ration d'un rapport dÃ©taillÃ©..." -ForegroundColor Cyan
    
    # Chemin vers le rapport dÃ©taillÃ©
    $detailedReportPath = Join-Path -Path $OutputPath -ChildPath "detailed_report.html"
    
    # RÃ©cupÃ©rer les rÃ©sultats des tests
    $testResults = Import-Clixml -Path (Join-Path -Path $optimizedConfig.OutputPath -ChildPath "results.xml")
    
    # GÃ©nÃ©rer le rapport dÃ©taillÃ©
    $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport dÃ©taillÃ© des tests</title>
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
        .optimization-info {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport dÃ©taillÃ© des tests</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
        
        <div class="optimization-info">
            <h2>Informations d'optimisation</h2>
            <p>
                <strong>Nombre de threads:</strong> $($optimizedConfig.MaxThreads)<br>
                <strong>RÃ©pertoire de sortie:</strong> $($optimizedConfig.OutputPath)<br>
                <strong>GÃ©nÃ©ration de rapport HTML:</strong> $($optimizedConfig.GenerateHtmlReport)<br>
                <strong>Collecte de donnÃ©es de performance:</strong> $($optimizedConfig.CollectPerformanceData)
            </p>
        </div>
        
        <h2>RÃ©sumÃ© des tests</h2>
        <p>
            <strong>Tests exÃ©cutÃ©s:</strong> $($testResults.Count)<br>
            <strong>Tests rÃ©ussis:</strong> $(($testResults | Where-Object { $_.Success }).Count)<br>
            <strong>Tests Ã©chouÃ©s:</strong> $(($testResults | Where-Object { -not $_.Success }).Count)<br>
            <strong>DurÃ©e totale:</strong> $([math]::Round(($testResults | Measure-Object -Property Duration -Sum).Sum, 2)) ms
        </p>
        
        <div class="chart-container">
            <canvas id="testResultsChart"></canvas>
        </div>
        
        <h2>RÃ©sultats dÃ©taillÃ©s</h2>
        <table>
            <tr>
                <th>Test</th>
                <th>RÃ©sultat</th>
                <th>DurÃ©e (ms)</th>
                <th>DÃ©tails</th>
            </tr>
"@

    foreach ($result in $testResults) {
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        $statusText = if ($result.Success) { "SuccÃ¨s" } else { "Ã‰chec" }
        
        if ($result.Success -and $result.Duration -gt 1000) {
            $statusClass = "slow"
            $statusText = "SuccÃ¨s (lent)"
        }
        
        $htmlReport += @"
            <tr>
                <td>$($result.Name)</td>
                <td class="$statusClass">$statusText</td>
                <td>$([math]::Round($result.Duration, 2))</td>
                <td>$($result.ErrorMessage)</td>
            </tr>
"@
    }

    $htmlReport += @"
        </table>
        
        <script>
            // CrÃ©er un graphique des rÃ©sultats des tests
            const ctx = document.getElementById('testResultsChart').getContext('2d');
            const testResultsChart = new Chart(ctx, {
                type: 'pie',
                data: {
                    labels: ['RÃ©ussis', 'Ã‰chouÃ©s'],
                    datasets: [{
                        label: 'RÃ©sultats des tests',
                        data: [$(($testResults | Where-Object { $_.Success }).Count), $(($testResults | Where-Object { -not $_.Success }).Count)],
                        backgroundColor: [
                            '#2ecc71',
                            '#e74c3c'
                        ],
                        borderColor: [
                            '#27ae60',
                            '#c0392b'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            position: 'top',
                        },
                        title: {
                            display: true,
                            text: 'RÃ©sultats des tests'
                        }
                    }
                }
            });
        </script>
        
        <div class="footer">
            <p>GÃ©nÃ©rÃ© par TestOmnibus Optimizer</p>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport dÃ©taillÃ©
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($detailedReportPath, $htmlReport, $utf8WithBom)
    
    Write-Host "Rapport dÃ©taillÃ© gÃ©nÃ©rÃ©: $detailedReportPath" -ForegroundColor Green
}

# Retourner le rÃ©sultat
return $result
