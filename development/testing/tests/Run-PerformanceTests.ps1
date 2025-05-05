#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests de performance pour le projet.
.DESCRIPTION
    Ce script exÃ©cute les tests de performance pour le projet et gÃ©nÃ¨re un rapport de rÃ©sultats.
.PARAMETER OutputPath
    Chemin du rÃ©pertoire de sortie pour les rapports. Par dÃ©faut: "./reports/performance".
.PARAMETER GenerateCharts
    GÃ©nÃ¨re des graphiques pour les rapports de performance.
.EXAMPLE
    .\Run-PerformanceTests.ps1 -GenerateCharts
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
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# CrÃ©er le rÃ©pertoire de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "RÃ©pertoire de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# DÃ©finir le chemin des tests de performance
$performanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "performance"

# VÃ©rifier que le rÃ©pertoire des tests de performance existe
if (-not (Test-Path -Path $performanceTestsPath)) {
    Write-Log "Le rÃ©pertoire des tests de performance n'existe pas: $performanceTestsPath" -Level "ERROR"
    exit 1
}

# Obtenir tous les fichiers de test de performance
$performanceTestFiles = Get-ChildItem -Path $performanceTestsPath -Filter "*.ps1" -Recurse

if ($performanceTestFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test de performance trouvÃ© dans: $performanceTestsPath" -Level "WARNING"
    exit 0
}

Write-Log "Nombre de fichiers de test de performance trouvÃ©s: $($performanceTestFiles.Count)" -Level "INFO"

# ExÃ©cuter les tests de performance
$results = @()

foreach ($testFile in $performanceTestFiles) {
    Write-Log "ExÃ©cution du test de performance: $($testFile.Name)" -Level "INFO"
    
    try {
        # CrÃ©er un rÃ©pertoire temporaire pour les rÃ©sultats
        $tempDir = Join-Path -Path $env:TEMP -ChildPath "PerfTest_$([Guid]::NewGuid().ToString())"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        # ExÃ©cuter le test de performance
        $scriptParams = @{
            OutputPath = $tempDir
        }
        
        & $testFile.FullName @scriptParams
        
        # VÃ©rifier si le test a gÃ©nÃ©rÃ© un fichier CSV
        $csvFiles = Get-ChildItem -Path $tempDir -Filter "*.csv" -Recurse
        
        if ($csvFiles.Count -gt 0) {
            foreach ($csvFile in $csvFiles) {
                # Copier le fichier CSV dans le rÃ©pertoire de sortie
                $destPath = Join-Path -Path $OutputPath -ChildPath "$($testFile.BaseName)_$($csvFile.Name)"
                Copy-Item -Path $csvFile.FullName -Destination $destPath -Force
                
                Write-Log "Fichier CSV gÃ©nÃ©rÃ©: $destPath" -Level "SUCCESS"
                
                # Lire les rÃ©sultats du fichier CSV
                $testResults = Import-Csv -Path $destPath
                $results += $testResults
            }
        } else {
            Write-Log "Aucun fichier CSV gÃ©nÃ©rÃ© pour le test: $($testFile.Name)" -Level "WARNING"
        }
        
        # Nettoyer le rÃ©pertoire temporaire
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
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
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de performance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .chart {
            margin: 20px 0;
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
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
        <p>Nombre de tests exÃ©cutÃ©s: $($performanceTestFiles.Count)</p>
        <p>Date d'exÃ©cution: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <h2>RÃ©sultats des tests</h2>
"@

# Regrouper les rÃ©sultats par test
$groupedResults = $results | Group-Object -Property TestName

foreach ($group in $groupedResults) {
    $htmlReport += @"
    <h3>$($group.Name)</h3>
    <table>
        <tr>
            <th>DurÃ©e moyenne (ms)</th>
            <th>DurÃ©e minimale (ms)</th>
            <th>DurÃ©e maximale (ms)</th>
            <th>Ã‰cart type</th>
            <th>ItÃ©rations</th>
        </tr>
"@

    foreach ($result in $group.Group) {
        $htmlReport += @"
        <tr>
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
        $chartId = "chart_$($group.Name -replace '[^a-zA-Z0-9]', '_')"
        
        $htmlReport += @"
    <div class="chart">
        <canvas id="$chartId"></canvas>
    </div>
    
    <script>
        // DonnÃ©es pour le graphique
        const ctx_$chartId = document.getElementById('$chartId').getContext('2d');
        const chart_$chartId = new Chart(ctx_$chartId, {
            type: 'bar',
            data: {
                labels: [$(($group.Group | ForEach-Object { "'$($_.TestName)'" }) -join ", ")],
                datasets: [
                    {
                        label: 'DurÃ©e moyenne (ms)',
                        data: [$(($group.Group | ForEach-Object { $_.AverageDuration }) -join ", ")],
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'DurÃ©e minimale (ms)',
                        data: [$(($group.Group | ForEach-Object { $_.MinDuration }) -join ", ")],
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'DurÃ©e maximale (ms)',
                        data: [$(($group.Group | ForEach-Object { $_.MaxDuration }) -join ", ")],
                        backgroundColor: 'rgba(255, 99, 132, 0.5)',
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: '$($group.Name)'
                    },
                },
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
}

$htmlReport += @"
    <p class="timestamp">Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $reportPath -Encoding utf8

Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -Level "SUCCESS"

# Ouvrir le rapport HTML
if (Test-Path -Path $reportPath) {
    Write-Log "Ouverture du rapport HTML..." -Level "INFO"
    Start-Process $reportPath
}

Write-Log "Tous les tests de performance ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s!" -Level "SUCCESS"
