#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise l'utilisation de la mÃ©moire dans le traitement parallÃ¨le.
.DESCRIPTION
    Ce script implÃ©mente des techniques pour rÃ©duire l'empreinte mÃ©moire
    des opÃ©rations parallÃ¨les et amÃ©liorer la gestion de la mÃ©moire.
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
    [switch]$GenerateReport
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour surveiller l'utilisation de la mÃ©moire
function Start-MemoryMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$IntervalSeconds = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 60
    )
    
    $process = Get-Process -Id $PID
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    
    $memoryUsage = @()
    
    Write-Host "DÃ©marrage de la surveillance de la mÃ©moire..." -ForegroundColor Yellow
    Write-Host "  Processus : $($process.Name) (PID: $PID)" -ForegroundColor Yellow
    Write-Host "  Intervalle : $IntervalSeconds secondes" -ForegroundColor Yellow
    Write-Host "  DurÃ©e : $DurationSeconds secondes" -ForegroundColor Yellow
    
    while ((Get-Date) -lt $endTime) {
        # Mettre Ã  jour les informations du processus
        $process = Get-Process -Id $PID
        
        # Enregistrer l'utilisation de la mÃ©moire
        $memoryUsage += [PSCustomObject]@{
            Timestamp = Get-Date
            WorkingSetMB = $process.WorkingSet64 / 1MB
            PrivateMemoryMB = $process.PrivateMemorySize64 / 1MB
            VirtualMemoryMB = $process.VirtualMemorySize64 / 1MB
        }
        
        # Attendre l'intervalle spÃ©cifiÃ©
        Start-Sleep -Seconds $IntervalSeconds
    }
    
    Write-Host "Surveillance de la mÃ©moire terminÃ©e." -ForegroundColor Green
    
    return $memoryUsage
}

# Fonction pour optimiser l'utilisation de la mÃ©moire
function Optimize-MemoryUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestFilesPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-Host "`n=== Optimisation de l'utilisation de la mÃ©moire ===" -ForegroundColor Cyan
    
    # CrÃ©er un rÃ©pertoire pour les rÃ©sultats
    $resultsPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization"
    if (-not (Test-Path -Path $resultsPath)) {
        New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null
    }
    
    # Techniques d'optimisation de la mÃ©moire
    $optimizationTechniques = @(
        @{
            Name = "Standard (sans optimisation)"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "standard")
            }
        },
        @{
            Name = "Traitement par lots avec libÃ©ration de mÃ©moire"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "batch_with_gc")
                BatchSize = 10
                ForceGC = $true
            }
        },
        @{
            Name = "Streaming de donnÃ©es"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "streaming")
                UseStreaming = $true
            }
        },
        @{
            Name = "Limitation du nombre de processus parallÃ¨les"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "limited_processes")
                MaxProcesses = 2
            }
        }
    )
    
    $results = @()
    
    foreach ($technique in $optimizationTechniques) {
        Write-Host "`nTest de la technique : $($technique.Name)" -ForegroundColor Yellow
        
        # DÃ©marrer la surveillance de la mÃ©moire
        $monitoringJob = Start-Job -ScriptBlock {
            param($PID, $IntervalSeconds, $DurationSeconds)
            
            $memoryUsage = @()
            $startTime = Get-Date
            $endTime = $startTime.AddSeconds($DurationSeconds)
            
            while ((Get-Date) -lt $endTime) {
                try {
                    $process = Get-Process -Id $PID -ErrorAction Stop
                    
                    $memoryUsage += [PSCustomObject]@{
                        Timestamp = Get-Date
                        WorkingSetMB = $process.WorkingSet64 / 1MB
                        PrivateMemoryMB = $process.PrivateMemorySize64 / 1MB
                        VirtualMemoryMB = $process.VirtualMemorySize64 / 1MB
                    }
                }
                catch {
                    # Le processus n'existe plus
                    break
                }
                
                Start-Sleep -Seconds $IntervalSeconds
            }
            
            return $memoryUsage
        } -ArgumentList $PID, 1, 120
        
        # ExÃ©cuter le script avec les paramÃ¨tres spÃ©cifiÃ©s
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # ExÃ©cuter le script
            $scriptResult = & $ScriptPath @($technique.Parameters)
            $success = $true
        }
        catch {
            Write-Error "Erreur lors de l'exÃ©cution du script avec la technique '$($technique.Name)' : $_"
            $success = $false
            $scriptResult = $null
        }
        
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed.TotalSeconds
        
        # ArrÃªter la surveillance de la mÃ©moire
        $memoryUsage = Receive-Job -Job $monitoringJob
        Remove-Job -Job $monitoringJob -Force
        
        # Calculer les statistiques d'utilisation de la mÃ©moire
        if ($memoryUsage -and $memoryUsage.Count -gt 0) {
            $avgWorkingSet = ($memoryUsage | Measure-Object -Property WorkingSetMB -Average).Average
            $maxWorkingSet = ($memoryUsage | Measure-Object -Property WorkingSetMB -Maximum).Maximum
            $avgPrivateMemory = ($memoryUsage | Measure-Object -Property PrivateMemoryMB -Average).Average
            $maxPrivateMemory = ($memoryUsage | Measure-Object -Property PrivateMemoryMB -Maximum).Maximum
        }
        else {
            $avgWorkingSet = 0
            $maxWorkingSet = 0
            $avgPrivateMemory = 0
            $maxPrivateMemory = 0
        }
        
        # Enregistrer les rÃ©sultats
        $result = [PSCustomObject]@{
            Technique = $technique.Name
            ExecutionTime = $executionTime
            AverageWorkingSetMB = $avgWorkingSet
            MaxWorkingSetMB = $maxWorkingSet
            AveragePrivateMemoryMB = $avgPrivateMemory
            MaxPrivateMemoryMB = $maxPrivateMemory
            Success = $success
            MemoryUsage = $memoryUsage
        }
        
        $results += $result
        
        Write-Host "  Temps d'exÃ©cution : $executionTime secondes" -ForegroundColor Yellow
        Write-Host "  Working Set moyen : $avgWorkingSet MB" -ForegroundColor Yellow
        Write-Host "  Working Set max : $maxWorkingSet MB" -ForegroundColor Yellow
        Write-Host "  MÃ©moire privÃ©e moyenne : $avgPrivateMemory MB" -ForegroundColor Yellow
        Write-Host "  MÃ©moire privÃ©e max : $maxPrivateMemory MB" -ForegroundColor Yellow
        Write-Host "  SuccÃ¨s : $success" -ForegroundColor ($success ? "Green" : "Red")
    }
    
    # DÃ©terminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.Success } | 
        Sort-Object -Property MaxWorkingSetMB | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        Write-Host "`n=== Technique d'optimisation de la mÃ©moire optimale ===" -ForegroundColor Green
        Write-Host "  Technique : $($optimalTechnique.Technique)" -ForegroundColor Green
        Write-Host "  Temps d'exÃ©cution : $($optimalTechnique.ExecutionTime) secondes" -ForegroundColor Green
        Write-Host "  Working Set max : $($optimalTechnique.MaxWorkingSetMB) MB" -ForegroundColor Green
        Write-Host "  MÃ©moire privÃ©e max : $($optimalTechnique.MaxPrivateMemoryMB) MB" -ForegroundColor Green
    }
    else {
        Write-Warning "Impossible de dÃ©terminer la technique optimale. Aucun test n'a rÃ©ussi."
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
    
    $testFilesPath = New-TestFiles -OutputPath $OutputPath -SmallFiles 100 -MediumFiles 50 -LargeFiles 20
}
else {
    Write-Host "Utilisation des fichiers de test existants : $testFilesPath" -ForegroundColor Yellow
}

# Chemin vers le script d'analyse
$analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"

# Optimiser l'utilisation de la mÃ©moire
$results = Optimize-MemoryUsage `
    -ScriptPath $analyzerPath `
    -TestFilesPath $testFilesPath `
    -OutputPath $OutputPath

# Enregistrer les rÃ©sultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization_results.json"
$results | Select-Object -Property Technique, ExecutionTime, AverageWorkingSetMB, MaxWorkingSetMB, AveragePrivateMemoryMB, MaxPrivateMemoryMB, Success | 
    ConvertTo-Json -Depth 5 | 
    Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRÃ©sultats enregistrÃ©s : $resultsPath" -ForegroundColor Green

# Enregistrer les donnÃ©es d'utilisation de la mÃ©moire pour chaque technique
foreach ($result in $results) {
    $techniqueName = $result.Technique -replace '[^a-zA-Z0-9]', '_'
    $memoryUsagePath = Join-Path -Path $OutputPath -ChildPath "memory_usage_$techniqueName.json"
    
    $result.MemoryUsage | Select-Object -Property Timestamp, WorkingSetMB, PrivateMemoryMB, VirtualMemoryMB | 
        ConvertTo-Json -Depth 5 | 
        Out-File -FilePath $memoryUsagePath -Encoding utf8
    
    Write-Host "DonnÃ©es d'utilisation de la mÃ©moire enregistrÃ©es : $memoryUsagePath" -ForegroundColor Green
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation de la mÃ©moire</title>
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
    <h1>Rapport d'optimisation de la mÃ©moire</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre de techniques testÃ©es : $($results.Count)</p>
"@
    
    # DÃ©terminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.Success } | 
        Sort-Object -Property MaxWorkingSetMB | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        $htmlContent += @"
        <p><strong>Technique optimale : $($optimalTechnique.Technique)</strong></p>
        <p>Temps d'exÃ©cution : $([Math]::Round($optimalTechnique.ExecutionTime, 2)) secondes</p>
        <p>Working Set max : $([Math]::Round($optimalTechnique.MaxWorkingSetMB, 2)) MB</p>
        <p>MÃ©moire privÃ©e max : $([Math]::Round($optimalTechnique.MaxPrivateMemoryMB, 2)) MB</p>
"@
    }
    else {
        $htmlContent += @"
        <p><strong>Impossible de dÃ©terminer la technique optimale. Aucun test n'a rÃ©ussi.</strong></p>
"@
    }
    
    $htmlContent += @"
    </div>
    
    <h2>RÃ©sultats par technique</h2>
    <table>
        <thead>
            <tr>
                <th>Technique</th>
                <th>Temps d'exÃ©cution (s)</th>
                <th>Working Set moyen (MB)</th>
                <th>Working Set max (MB)</th>
                <th>MÃ©moire privÃ©e moyenne (MB)</th>
                <th>MÃ©moire privÃ©e max (MB)</th>
                <th>SuccÃ¨s</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($result in $results) {
        $isOptimal = $optimalTechnique -and $result.Technique -eq $optimalTechnique.Technique
        $rowClass = $isOptimal ? "optimal" : ""
        
        $htmlContent += @"
            <tr class="$rowClass">
                <td>$($result.Technique)</td>
                <td>$([Math]::Round($result.ExecutionTime, 2))</td>
                <td>$([Math]::Round($result.AverageWorkingSetMB, 2))</td>
                <td>$([Math]::Round($result.MaxWorkingSetMB, 2))</td>
                <td>$([Math]::Round($result.AveragePrivateMemoryMB, 2))</td>
                <td>$([Math]::Round($result.MaxPrivateMemoryMB, 2))</td>
                <td>$($result.Success)</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </tbody>
    </table>
    
    <h2>Graphiques</h2>
    
    <h3>Utilisation de la mÃ©moire (Working Set)</h3>
    <div class="chart-container">
        <canvas id="workingSetChart"></canvas>
    </div>
    
    <h3>Utilisation de la mÃ©moire (MÃ©moire privÃ©e)</h3>
    <div class="chart-container">
        <canvas id="privateMemoryChart"></canvas>
    </div>
    
    <h3>Temps d'exÃ©cution</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const techniques = [$(($results | ForEach-Object { "'$($_.Technique)'" }) -join ', ')];
        const avgWorkingSet = [$(($results | ForEach-Object { [Math]::Round($_.AverageWorkingSetMB, 2) }) -join ', ')];
        const maxWorkingSet = [$(($results | ForEach-Object { [Math]::Round($_.MaxWorkingSetMB, 2) }) -join ', ')];
        const avgPrivateMemory = [$(($results | ForEach-Object { [Math]::Round($_.AveragePrivateMemoryMB, 2) }) -join ', ')];
        const maxPrivateMemory = [$(($results | ForEach-Object { [Math]::Round($_.MaxPrivateMemoryMB, 2) }) -join ', ')];
        const executionTimes = [$(($results | ForEach-Object { [Math]::Round($_.ExecutionTime, 2) }) -join ', ')];
        
        // Graphique Working Set
        const wsCtx = document.getElementById('workingSetChart').getContext('2d');
        new Chart(wsCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [
                    {
                        label: 'Working Set moyen (MB)',
                        data: avgWorkingSet,
                        backgroundColor: 'rgba(0, 120, 212, 0.7)',
                        borderColor: 'rgba(0, 120, 212, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Working Set max (MB)',
                        data: maxWorkingSet,
                        backgroundColor: 'rgba(0, 183, 74, 0.7)',
                        borderColor: 'rgba(0, 183, 74, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                scales: {
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
        
        // Graphique MÃ©moire privÃ©e
        const pmCtx = document.getElementById('privateMemoryChart').getContext('2d');
        new Chart(pmCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [
                    {
                        label: 'MÃ©moire privÃ©e moyenne (MB)',
                        data: avgPrivateMemory,
                        backgroundColor: 'rgba(0, 120, 212, 0.7)',
                        borderColor: 'rgba(0, 120, 212, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'MÃ©moire privÃ©e max (MB)',
                        data: maxPrivateMemory,
                        backgroundColor: 'rgba(0, 183, 74, 0.7)',
                        borderColor: 'rgba(0, 183, 74, 1)',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                scales: {
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
        
        // Graphique Temps d'exÃ©cution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [{
                    label: 'Temps d\'exÃ©cution (s)',
                    data: executionTimes,
                    backgroundColor: 'rgba(209, 52, 56, 0.7)',
                    borderColor: 'rgba(209, 52, 56, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
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
