#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests de performance pour le projet.
.DESCRIPTION
    Ce script exÃ©cute tous les tests de performance pour le projet et gÃ©nÃ¨re des rapports de performance.
.PARAMETER OutputPath
    Chemin du rÃ©pertoire de sortie pour les rapports. Par dÃ©faut: "./reports/performance".
.PARAMETER GenerateCharts
    GÃ©nÃ¨re des graphiques pour les rapports de performance.
.EXAMPLE
    .\Run-AllPerformanceTests.ps1 -GenerateCharts
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports/performance",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCharts
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# CrÃ©er le rÃ©pertoire de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# DÃ©finir le chemin des tests de performance
$PerformanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "performance"

# Obtenir tous les fichiers de test de performance
$performanceTestFiles = Get-ChildItem -Path $PerformanceTestsPath -Filter "*.ps1" -Recurse

Write-Log "Nombre de fichiers de test de performance trouvÃ©s: $($performanceTestFiles.Count)" -Level "INFO"

# ExÃ©cuter les tests de performance
$results = @()

foreach ($testFile in $performanceTestFiles) {
    Write-Log "ExÃ©cution du test de performance: $($testFile.Name)" -Level "INFO"
    
    try {
        # ExÃ©cuter le test de performance
        & $testFile.FullName
        
        # VÃ©rifier si le test a gÃ©nÃ©rÃ© un fichier CSV
        $csvFileName = $testFile.BaseName + ".csv"
        $csvFilePath = Join-Path -Path $OutputPath -ChildPath $csvFileName
        
        if (Test-Path -Path $csvFilePath) {
            Write-Log "Fichier CSV gÃ©nÃ©rÃ©: $csvFilePath" -Level "SUCCESS"
            
            # Lire les rÃ©sultats du fichier CSV
            $testResults = Import-Csv -Path $csvFilePath
            $results += $testResults
        } else {
            Write-Log "Aucun fichier CSV gÃ©nÃ©rÃ© pour le test: $($testFile.Name)" -Level "WARNING"
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du test de performance: $($testFile.Name)" -Level "ERROR"
        Write-Log "Message d'erreur: $_" -Level "ERROR"
    }
}

# GÃ©nÃ©rer un rapport de performance global
$reportPath = Join-Path -Path $OutputPath -ChildPath "performance-report.html"

# CrÃ©er le rapport HTML
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .chart { margin: 20px 0; }
    </style>
"@

if ($GenerateCharts) {
    $htmlReport += @"
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
"@
}

$htmlReport += @"
</head>
<body>
    <h1>Rapport de performance</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre de tests exÃ©cutÃ©s: $($results.Count)</p>
        <p>Date d'exÃ©cution: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <h2>RÃ©sultats des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>DurÃ©e moyenne (ms)</th>
            <th>DurÃ©e minimale (ms)</th>
            <th>DurÃ©e maximale (ms)</th>
            <th>Ã‰cart type</th>
            <th>ItÃ©rations</th>
        </tr>
"@

foreach ($result in $results) {
    $htmlReport += @"
        <tr>
            <td>$($result.TestName)</td>
            <td>$($result.AverageDuration)</td>
            <td>$($result.MinDuration)</td>
            <td>$($result.MaxDuration)</td>
            <td>$($result.StdDeviation)</td>
            <td>$($result.Iterations)</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
"@

if ($GenerateCharts) {
    $htmlReport += @"
    <h2>Graphiques</h2>
    
    <div class="chart">
        <h3>DurÃ©e moyenne par test</h3>
        <canvas id="averageDurationChart"></canvas>
    </div>
    
    <script>
        // DonnÃ©es pour le graphique de durÃ©e moyenne
        const testNames = [$(($results | ForEach-Object { "'$($_.TestName)'" }) -join ", ")];
        const averageDurations = [$(($results | ForEach-Object { $_.AverageDuration }) -join ", ")];
        
        // CrÃ©er le graphique de durÃ©e moyenne
        const averageDurationCtx = document.getElementById('averageDurationChart').getContext('2d');
        const averageDurationChart = new Chart(averageDurationCtx, {
            type: 'bar',
            data: {
                labels: testNames,
                datasets: [{
                    label: 'DurÃ©e moyenne (ms)',
                    data: averageDurations,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
"@
}

$htmlReport += @"
</body>
</html>
"@

$htmlReport | Set-Content -Path $reportPath -Encoding UTF8

Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -Level "SUCCESS"

# Ouvrir le rapport HTML
if (Test-Path -Path $reportPath) {
    Write-Log "Ouverture du rapport HTML..." -Level "INFO"
    Start-Process $reportPath
}

Write-Log "Tous les tests de performance ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s!" -Level "SUCCESS"
