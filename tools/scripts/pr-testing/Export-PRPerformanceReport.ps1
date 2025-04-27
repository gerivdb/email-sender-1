#Requires -Version 5.1
<#
.SYNOPSIS
    Exporte un rapport de performance dÃ©taillÃ© pour l'analyse des pull requests.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport HTML dÃ©taillÃ© Ã  partir des donnÃ©es de traÃ§age
    collectÃ©es par le module PRPerformanceTracer.

.PARAMETER Tracer
    L'objet traceur contenant les donnÃ©es de traÃ§age.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le rapport.
    Par dÃ©faut: "reports\pr-analysis\profiling\performance_report.html"

.PARAMETER PullRequestInfo
    Informations sur la pull request analysÃ©e.

.EXAMPLE
    Export-PRPerformanceReport -Tracer $tracer -OutputPath "reports\performance_report_pr42.html" -PullRequestInfo $prInfo
    GÃ©nÃ¨re un rapport de performance Ã  partir des donnÃ©es du traceur et l'enregistre dans le fichier spÃ©cifiÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [object]$Tracer,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\profiling\performance_report.html",

    [Parameter()]
    [PSCustomObject]$PullRequestInfo = $null
)

# Fonction pour gÃ©nÃ©rer le HTML du rapport
function New-PerformanceReportHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TracingData,

        [Parameter()]
        [PSCustomObject]$PRInfo = $null
    )

    # Convertir les donnÃ©es en JSON pour les graphiques
    $operationsJson = $TracingData.Operations | ConvertTo-Json -Depth 10
    $resourceSnapshotsJson = $TracingData.ResourceSnapshots | ConvertTo-Json -Depth 10

    # CrÃ©er le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Performance - Analyse PR</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            position: relative;
            height: 300px;
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .section {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .card {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 15px;
            margin-bottom: 20px;
        }
        .metric {
            display: inline-block;
            width: 23%;
            margin: 1%;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            text-align: center;
            box-sizing: border-box;
        }
        .metric h3 {
            margin-top: 0;
            font-size: 16px;
            color: #6c757d;
        }
        .metric p {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0 0 0;
            color: #343a40;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Performance - Analyse de Pull Request</h1>
        
        <!-- RÃ©sumÃ© -->
        <div class="section">
            <h2>RÃ©sumÃ©</h2>
            <div class="summary">
"@

    # Ajouter les informations sur la PR si disponibles
    if ($null -ne $PRInfo) {
        $html += @"
                <h3>Informations sur la Pull Request</h3>
                <p><strong>NumÃ©ro:</strong> #$($PRInfo.Number)</p>
                <p><strong>Titre:</strong> $($PRInfo.Title)</p>
                <p><strong>Branche source:</strong> $($PRInfo.HeadBranch)</p>
                <p><strong>Branche cible:</strong> $($PRInfo.BaseBranch)</p>
                <p><strong>Fichiers modifiÃ©s:</strong> $($PRInfo.FileCount)</p>
                <p><strong>Ajouts:</strong> $($PRInfo.Additions)</p>
                <p><strong>Suppressions:</strong> $($PRInfo.Deletions)</p>
                <p><strong>Modifications totales:</strong> $($PRInfo.Changes)</p>
"@
    }

    $html += @"
                <h3>MÃ©triques de Performance</h3>
                <div class="metrics">
                    <div class="metric">
                        <h3>DurÃ©e Totale</h3>
                        <p>$([Math]::Round($TracingData.Duration.TotalSeconds, 2)) s</p>
                    </div>
                    <div class="metric">
                        <h3>OpÃ©rations</h3>
                        <p>$($TracingData.Operations.Count)</p>
                    </div>
                    <div class="metric">
                        <h3>MÃ©moire Max</h3>
                        <p>$([Math]::Round(($TracingData.ResourceSnapshots | Measure-Object -Property WorkingSet -Maximum).Maximum / 1MB, 2)) MB</p>
                    </div>
                    <div class="metric">
                        <h3>CPU</h3>
                        <p>$([Math]::Round(($TracingData.ResourceSnapshots | Measure-Object -Property CPU -Maximum).Maximum, 2))</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Graphiques d'utilisation des ressources -->
        <div class="section">
            <h2>Utilisation des Ressources</h2>
            
            <div class="chart-container">
                <canvas id="memoryChart"></canvas>
            </div>
            
            <div class="chart-container">
                <canvas id="cpuChart"></canvas>
            </div>
        </div>
        
        <!-- OpÃ©rations -->
        <div class="section">
            <h2>OpÃ©rations</h2>
            
            <div class="chart-container">
                <canvas id="operationsChart"></canvas>
            </div>
            
            <h3>DÃ©tails des OpÃ©rations</h3>
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Description</th>
                        <th>DurÃ©e (ms)</th>
                        <th>MÃ©moire (MB)</th>
                        <th>CPU</th>
                    </tr>
                </thead>
                <tbody>
"@

    # Ajouter les dÃ©tails des opÃ©rations
    foreach ($operation in $TracingData.Operations) {
        $memoryDelta = 0
        $cpuDelta = 0
        
        if ($null -ne $operation.ResourceUsage -and $null -ne $operation.ResourceUsage.Delta) {
            $memoryDelta = [Math]::Round($operation.ResourceUsage.Delta.WorkingSet / 1MB, 2)
            $cpuDelta = [Math]::Round($operation.ResourceUsage.Delta.CPU, 2)
        }
        
        $html += @"
                    <tr>
                        <td>$($operation.Name)</td>
                        <td>$($operation.Description)</td>
                        <td>$([Math]::Round($operation.Duration.TotalMilliseconds, 2))</td>
                        <td>$memoryDelta</td>
                        <td>$cpuDelta</td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
        
        <!-- Recommandations -->
        <div class="section">
            <h2>Recommandations</h2>
            <div class="card">
                <ul>
"@

    # Ajouter des recommandations basÃ©es sur l'analyse
    $avgOperationTime = ($TracingData.Operations | Measure-Object -Property { $_.Duration.TotalMilliseconds } -Average).Average
    $maxOperationTime = ($TracingData.Operations | Measure-Object -Property { $_.Duration.TotalMilliseconds } -Maximum).Maximum
    $maxMemoryOperation = $TracingData.Operations | Sort-Object -Property { if ($null -ne $_.ResourceUsage -and $null -ne $_.ResourceUsage.Delta) { $_.ResourceUsage.Delta.WorkingSet } else { 0 } } -Descending | Select-Object -First 1

    if ($avgOperationTime -gt 500) {
        $html += @"
                    <li><strong>Optimisation des performances gÃ©nÃ©rales:</strong> Le temps moyen d'opÃ©ration est Ã©levÃ© ($([Math]::Round($avgOperationTime, 2)) ms). Envisagez d'optimiser les opÃ©rations les plus courantes.</li>
"@
    }

    if ($maxOperationTime -gt 1000) {
        $slowestOp = $TracingData.Operations | Sort-Object -Property { $_.Duration.TotalMilliseconds } -Descending | Select-Object -First 1
        $html += @"
                    <li><strong>Optimisation des opÃ©rations lentes:</strong> L'opÃ©ration '$($slowestOp.Name)' est particuliÃ¨rement lente ($([Math]::Round($slowestOp.Duration.TotalMilliseconds, 2)) ms). Envisagez de l'optimiser en prioritÃ©.</li>
"@
    }

    if ($null -ne $maxMemoryOperation -and $null -ne $maxMemoryOperation.ResourceUsage -and $null -ne $maxMemoryOperation.ResourceUsage.Delta -and $maxMemoryOperation.ResourceUsage.Delta.WorkingSet / 1MB -gt 50) {
        $html += @"
                    <li><strong>Optimisation de la mÃ©moire:</strong> L'opÃ©ration '$($maxMemoryOperation.Name)' consomme beaucoup de mÃ©moire ($([Math]::Round($maxMemoryOperation.ResourceUsage.Delta.WorkingSet / 1MB, 2)) MB). Envisagez d'optimiser son utilisation de la mÃ©moire.</li>
"@
    }

    $html += @"
                    <li><strong>Mise en cache:</strong> Envisagez d'implÃ©menter un systÃ¨me de cache pour les opÃ©rations frÃ©quentes et coÃ»teuses.</li>
                    <li><strong>ParallÃ©lisation:</strong> Certaines opÃ©rations pourraient bÃ©nÃ©ficier d'une exÃ©cution parallÃ¨le pour amÃ©liorer les performances globales.</li>
                </ul>
            </div>
        </div>
    </div>

    <script>
        // DonnÃ©es pour les graphiques
        const operations = $operationsJson;
        const resourceSnapshots = $resourceSnapshotsJson;
        
        // PrÃ©parer les donnÃ©es pour les graphiques
        const timestamps = resourceSnapshots.map(snapshot => new Date(snapshot.Timestamp).toLocaleTimeString());
        const memoryData = resourceSnapshots.map(snapshot => snapshot.WorkingSet / (1024 * 1024)); // Convertir en MB
        const cpuData = resourceSnapshots.map(snapshot => snapshot.CPU);
        
        // Graphique de mÃ©moire
        const memoryCtx = document.getElementById('memoryChart').getContext('2d');
        new Chart(memoryCtx, {
            type: 'line',
            data: {
                labels: timestamps,
                datasets: [{
                    label: 'Utilisation MÃ©moire (MB)',
                    data: memoryData,
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'MÃ©moire (MB)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Temps'
                        }
                    }
                }
            }
        });
        
        // Graphique CPU
        const cpuCtx = document.getElementById('cpuChart').getContext('2d');
        new Chart(cpuCtx, {
            type: 'line',
            data: {
                labels: timestamps,
                datasets: [{
                    label: 'Utilisation CPU',
                    data: cpuData,
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'CPU'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Temps'
                        }
                    }
                }
            }
        });
        
        // Graphique des opÃ©rations
        const operationsCtx = document.getElementById('operationsChart').getContext('2d');
        const operationNames = operations.map(op => op.Name);
        const operationDurations = operations.map(op => op.Duration.TotalMilliseconds);
        
        new Chart(operationsCtx, {
            type: 'bar',
            data: {
                labels: operationNames,
                datasets: [{
                    label: 'DurÃ©e (ms)',
                    data: operationDurations,
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'DurÃ©e (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'OpÃ©ration'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    return $html
}

# Point d'entrÃ©e principal
try {
    # VÃ©rifier que le traceur est valide
    if ($null -eq $Tracer) {
        throw "L'objet traceur est null."
    }

    # Obtenir les donnÃ©es de traÃ§age
    $tracingData = $Tracer.GetTracingData()
    if ($null -eq $tracingData) {
        throw "Impossible d'obtenir les donnÃ©es de traÃ§age."
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # GÃ©nÃ©rer le HTML du rapport
    $html = New-PerformanceReportHtml -TracingData $tracingData -PRInfo $PullRequestInfo

    # Enregistrer le fichier HTML
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8

    Write-Host "Rapport de performance gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -ForegroundColor Green
    return $OutputPath
} catch {
    Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de performance: $_"
    return $null
}
