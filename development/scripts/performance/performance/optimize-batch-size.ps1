#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise la taille des lots pour le traitement parallÃ¨le.
.DESCRIPTION
    Ce script dÃ©termine la taille de lot optimale pour le traitement parallÃ¨le
    en exÃ©cutant des tests avec diffÃ©rentes tailles de lots.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "results"),
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 3,
    
    [Parameter(Mandatory = $false)]
    [int[]]$BatchSizes = @(5, 10, 20, 50, 100),
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour mesurer les performances avec diffÃ©rentes tailles de lots
function Measure-BatchSizePerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestFilesPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [int[]]$BatchSizes,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )
    
    Write-Host "`n=== Optimisation de la taille des lots ===" -ForegroundColor Cyan
    
    $results = @()
    
    foreach ($batchSize in $BatchSizes) {
        Write-Host "`nTest avec taille de lot : $batchSize" -ForegroundColor Yellow
        
        $batchResults = @()
        
        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Host "  ItÃ©ration $i/$Iterations..." -ForegroundColor Yellow
            
            # Nettoyer la mÃ©moire avant chaque test
            [System.GC]::Collect()
            
            # Mesurer l'utilisation de la mÃ©moire avant
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            # Mesurer le temps d'exÃ©cution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                # ExÃ©cuter l'analyseur avec la taille de lot spÃ©cifiÃ©e
                $analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"
                $result = & $analyzerPath -ScriptsPath $TestFilesPath -OutputPath (Join-Path -Path $OutputPath -ChildPath "batch_$batchSize") -BatchSize $batchSize
                
                $success = $true
            }
            catch {
                Write-Error "Erreur lors du test avec taille de lot $batchSize : $_"
                $success = $false
                $result = $null
            }
            
            $stopwatch.Stop()
            $executionTime = $stopwatch.Elapsed.TotalSeconds
            
            # Mesurer l'utilisation de la mÃ©moire aprÃ¨s
            $memoryAfter = [System.GC]::GetTotalMemory($true)
            $memoryUsage = ($memoryAfter - $memoryBefore) / 1MB
            
            # Enregistrer les rÃ©sultats
            $batchResults += [PSCustomObject]@{
                Iteration = $i
                BatchSize = $batchSize
                ExecutionTime = $executionTime
                MemoryUsageMB = $memoryUsage
                Success = $success
                ResultCount = if ($result) { $result.Count } else { 0 }
            }
            
            Write-Host "    Temps d'exÃ©cution : $executionTime secondes" -ForegroundColor Yellow
            Write-Host "    Utilisation mÃ©moire : $memoryUsage MB" -ForegroundColor Yellow
            Write-Host "    SuccÃ¨s : $success" -ForegroundColor ($success ? "Green" : "Red")
        }
        
        # Calculer les statistiques pour cette taille de lot
        $avgTime = ($batchResults | Measure-Object -Property ExecutionTime -Average).Average
        $minTime = ($batchResults | Measure-Object -Property ExecutionTime -Minimum).Minimum
        $maxTime = ($batchResults | Measure-Object -Property ExecutionTime -Maximum).Maximum
        $avgMemory = ($batchResults | Measure-Object -Property MemoryUsageMB -Average).Average
        $successRate = ($batchResults | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
        
        Write-Host "`n  RÃ©sultats pour taille de lot $batchSize :" -ForegroundColor Cyan
        Write-Host "    Temps moyen : $avgTime secondes" -ForegroundColor Green
        Write-Host "    Temps min/max : $minTime / $maxTime secondes" -ForegroundColor Green
        Write-Host "    MÃ©moire moyenne : $avgMemory MB" -ForegroundColor Green
        Write-Host "    Taux de succÃ¨s : $successRate%" -ForegroundColor Green
        
        $results += [PSCustomObject]@{
            BatchSize = $batchSize
            AverageTime = $avgTime
            MinTime = $minTime
            MaxTime = $maxTime
            AverageMemoryMB = $avgMemory
            SuccessRate = $successRate
            DetailedResults = $batchResults
        }
    }
    
    # DÃ©terminer la taille de lot optimale
    $optimalBatchSize = $results | 
        Where-Object { $_.SuccessRate -eq 100 } | 
        Sort-Object -Property AverageTime | 
        Select-Object -First 1
    
    if ($optimalBatchSize) {
        Write-Host "`n=== Taille de lot optimale ===" -ForegroundColor Green
        Write-Host "  Taille de lot : $($optimalBatchSize.BatchSize)" -ForegroundColor Green
        Write-Host "  Temps moyen : $($optimalBatchSize.AverageTime) secondes" -ForegroundColor Green
        Write-Host "  MÃ©moire moyenne : $($optimalBatchSize.AverageMemoryMB) MB" -ForegroundColor Green
    }
    else {
        Write-Warning "Impossible de dÃ©terminer la taille de lot optimale. Aucun test n'a rÃ©ussi Ã  100%."
    }
    
    return $results
}

# CrÃ©er des fichiers de test si nÃ©cessaire
$testFilesPath = Join-Path -Path $OutputPath -ChildPath "test_files"
if (-not (Test-Path -Path $testFilesPath)) {
    Write-Host "CrÃ©ation des fichiers de test..." -ForegroundColor Yellow
    
    # Importer le script de benchmark pour utiliser sa fonction de crÃ©ation de fichiers de test
    $benchmarkPath = Join-Path -Path $PSScriptRoot -ChildPath "benchmark.ps1"
    . $benchmarkPath
    
    $testFilesPath = New-TestFiles -OutputPath $OutputPath
}
else {
    Write-Host "Utilisation des fichiers de test existants : $testFilesPath" -ForegroundColor Yellow
}

# ExÃ©cuter les tests de performance avec diffÃ©rentes tailles de lots
$results = Measure-BatchSizePerformance `
    -TestFilesPath $testFilesPath `
    -OutputPath $OutputPath `
    -BatchSizes $BatchSizes `
    -Iterations $Iterations

# Enregistrer les rÃ©sultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "batch_size_results.json"
$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRÃ©sultats enregistrÃ©s : $resultsPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "batch_size_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation de la taille des lots</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
        .optimal {
            background-color: #DFF6DD;
            font-weight: bold;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport d'optimisation de la taille des lots</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre de tailles de lots testÃ©es : $($results.Count)</p>
        <p>Nombre d'itÃ©rations par taille : $Iterations</p>
"@
    
    # DÃ©terminer la taille de lot optimale
    $optimalBatchSize = $results | 
        Where-Object { $_.SuccessRate -eq 100 } | 
        Sort-Object -Property AverageTime | 
        Select-Object -First 1
    
    if ($optimalBatchSize) {
        $htmlContent += @"
        <p><strong>Taille de lot optimale : $($optimalBatchSize.BatchSize)</strong></p>
        <p>Temps moyen : $([Math]::Round($optimalBatchSize.AverageTime, 2)) secondes</p>
        <p>MÃ©moire moyenne : $([Math]::Round($optimalBatchSize.AverageMemoryMB, 2)) MB</p>
"@
    }
    else {
        $htmlContent += @"
        <p><strong>Impossible de dÃ©terminer la taille de lot optimale. Aucun test n'a rÃ©ussi Ã  100%.</strong></p>
"@
    }
    
    $htmlContent += @"
    </div>
    
    <h2>RÃ©sultats par taille de lot</h2>
    <table>
        <thead>
            <tr>
                <th>Taille de lot</th>
                <th>Temps moyen (s)</th>
                <th>Temps min (s)</th>
                <th>Temps max (s)</th>
                <th>MÃ©moire moyenne (MB)</th>
                <th>Taux de succÃ¨s (%)</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($result in $results) {
        $isOptimal = $optimalBatchSize -and $result.BatchSize -eq $optimalBatchSize.BatchSize
        $rowClass = $isOptimal ? "optimal" : ""
        
        $htmlContent += @"
            <tr class="$rowClass">
                <td>$($result.BatchSize)</td>
                <td>$([Math]::Round($result.AverageTime, 2))</td>
                <td>$([Math]::Round($result.MinTime, 2))</td>
                <td>$([Math]::Round($result.MaxTime, 2))</td>
                <td>$([Math]::Round($result.AverageMemoryMB, 2))</td>
                <td>$([Math]::Round($result.SuccessRate, 2))</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </tbody>
    </table>
    
    <h2>Graphiques</h2>
    
    <h3>Temps d'exÃ©cution moyen par taille de lot</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <h3>Utilisation mÃ©moire moyenne par taille de lot</h3>
    <div class="chart-container">
        <canvas id="memoryChart"></canvas>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const batchSizes = [$(($results | ForEach-Object { $_.BatchSize }) -join ', ')];
        const avgTimes = [$(($results | ForEach-Object { [Math]::Round($_.AverageTime, 2) }) -join ', ')];
        const avgMemory = [$(($results | ForEach-Object { [Math]::Round($_.AverageMemoryMB, 2) }) -join ', ')];
        
        // Graphique des temps d'exÃ©cution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'line',
            data: {
                labels: batchSizes,
                datasets: [{
                    label: 'Temps d\'exÃ©cution moyen (s)',
                    data: avgTimes,
                    backgroundColor: 'rgba(0, 120, 212, 0.2)',
                    borderColor: 'rgba(0, 120, 212, 1)',
                    borderWidth: 2,
                    tension: 0.1,
                    pointRadius: 5,
                    pointBackgroundColor: 'rgba(0, 120, 212, 1)'
                }]
            },
            options: {
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: 'Taille de lot'
                        }
                    },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Secondes'
                        }
                    }
                }
            }
        });
        
        // Graphique de l'utilisation mÃ©moire
        const memoryCtx = document.getElementById('memoryChart').getContext('2d');
        new Chart(memoryCtx, {
            type: 'line',
            data: {
                labels: batchSizes,
                datasets: [{
                    label: 'Utilisation mÃ©moire moyenne (MB)',
                    data: avgMemory,
                    backgroundColor: 'rgba(0, 183, 74, 0.2)',
                    borderColor: 'rgba(0, 183, 74, 1)',
                    borderWidth: 2,
                    tension: 0.1,
                    pointRadius: 5,
                    pointBackgroundColor: 'rgba(0, 183, 74, 1)'
                }]
            },
            options: {
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: 'Taille de lot'
                        }
                    },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'MB'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $reportPath -Encoding utf8
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
    
    # Ouvrir le rapport dans le navigateur par dÃ©faut
    Start-Process $reportPath
}

# Retourner les rÃ©sultats
return $results
