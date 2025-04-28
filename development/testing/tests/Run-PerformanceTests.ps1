#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests de performance pour le projet.
.DESCRIPTION
    Ce script exécute les tests de performance pour le projet et génère un rapport de résultats.
.PARAMETER OutputPath
    Chemin du répertoire de sortie pour les rapports. Par défaut: "./reports/performance".
.PARAMETER GenerateCharts
    Génère des graphiques pour les rapports de performance.
.EXAMPLE
    .\Run-PerformanceTests.ps1 -GenerateCharts
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./reports/performance",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCharts
)

# Fonction pour écrire des messages de log
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

# Créer le répertoire de sortie
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Définir le chemin des tests de performance
$performanceTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "performance"

# Vérifier que le répertoire des tests de performance existe
if (-not (Test-Path -Path $performanceTestsPath)) {
    Write-Log "Le répertoire des tests de performance n'existe pas: $performanceTestsPath" -Level "ERROR"
    exit 1
}

# Obtenir tous les fichiers de test de performance
$performanceTestFiles = Get-ChildItem -Path $performanceTestsPath -Filter "*.ps1" -Recurse

if ($performanceTestFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test de performance trouvé dans: $performanceTestsPath" -Level "WARNING"
    exit 0
}

Write-Log "Nombre de fichiers de test de performance trouvés: $($performanceTestFiles.Count)" -Level "INFO"

# Exécuter les tests de performance
$results = @()

foreach ($testFile in $performanceTestFiles) {
    Write-Log "Exécution du test de performance: $($testFile.Name)" -Level "INFO"
    
    try {
        # Créer un répertoire temporaire pour les résultats
        $tempDir = Join-Path -Path $env:TEMP -ChildPath "PerfTest_$([Guid]::NewGuid().ToString())"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        # Exécuter le test de performance
        $scriptParams = @{
            OutputPath = $tempDir
        }
        
        & $testFile.FullName @scriptParams
        
        # Vérifier si le test a généré un fichier CSV
        $csvFiles = Get-ChildItem -Path $tempDir -Filter "*.csv" -Recurse
        
        if ($csvFiles.Count -gt 0) {
            foreach ($csvFile in $csvFiles) {
                # Copier le fichier CSV dans le répertoire de sortie
                $destPath = Join-Path -Path $OutputPath -ChildPath "$($testFile.BaseName)_$($csvFile.Name)"
                Copy-Item -Path $csvFile.FullName -Destination $destPath -Force
                
                Write-Log "Fichier CSV généré: $destPath" -Level "SUCCESS"
                
                # Lire les résultats du fichier CSV
                $testResults = Import-Csv -Path $destPath
                $results += $testResults
            }
        } else {
            Write-Log "Aucun fichier CSV généré pour le test: $($testFile.Name)" -Level "WARNING"
        }
        
        # Nettoyer le répertoire temporaire
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Log "Erreur lors de l'exécution du test de performance: $($testFile.Name)" -Level "ERROR"
        Write-Log "Message d'erreur: $_" -Level "ERROR"
    }
}

# Générer un rapport de performance global
$reportPath = Join-Path -Path $OutputPath -ChildPath "performance-report.html"

# Créer le rapport HTML
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
        <h2>Résumé</h2>
        <p>Nombre de tests exécutés: $($performanceTestFiles.Count)</p>
        <p>Date d'exécution: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <h2>Résultats des tests</h2>
"@

# Regrouper les résultats par test
$groupedResults = $results | Group-Object -Property TestName

foreach ($group in $groupedResults) {
    $htmlReport += @"
    <h3>$($group.Name)</h3>
    <table>
        <tr>
            <th>Durée moyenne (ms)</th>
            <th>Durée minimale (ms)</th>
            <th>Durée maximale (ms)</th>
            <th>Écart type</th>
            <th>Itérations</th>
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
        // Données pour le graphique
        const ctx_$chartId = document.getElementById('$chartId').getContext('2d');
        const chart_$chartId = new Chart(ctx_$chartId, {
            type: 'bar',
            data: {
                labels: [$(($group.Group | ForEach-Object { "'$($_.TestName)'" }) -join ", ")],
                datasets: [
                    {
                        label: 'Durée moyenne (ms)',
                        data: [$(($group.Group | ForEach-Object { $_.AverageDuration }) -join ", ")],
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Durée minimale (ms)',
                        data: [$(($group.Group | ForEach-Object { $_.MinDuration }) -join ", ")],
                        backgroundColor: 'rgba(75, 192, 192, 0.5)',
                        borderColor: 'rgba(75, 192, 192, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Durée maximale (ms)',
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
    <p class="timestamp">Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $reportPath -Encoding utf8

Write-Log "Rapport HTML généré: $reportPath" -Level "SUCCESS"

# Ouvrir le rapport HTML
if (Test-Path -Path $reportPath) {
    Write-Log "Ouverture du rapport HTML..." -Level "INFO"
    Start-Process $reportPath
}

Write-Log "Tous les tests de performance ont été exécutés avec succès!" -Level "SUCCESS"
