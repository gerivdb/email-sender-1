#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise l'utilisation de la mémoire dans le traitement parallèle.
.DESCRIPTION
    Ce script implémente des techniques pour réduire l'empreinte mémoire
    des opérations parallèles et améliorer la gestion de la mémoire.
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

# Importer les modules nécessaires
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ParallelHybrid.psm1"
Import-Module $modulePath -Force

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Fonction pour surveiller l'utilisation de la mémoire
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
    
    Write-Host "Démarrage de la surveillance de la mémoire..." -ForegroundColor Yellow
    Write-Host "  Processus : $($process.Name) (PID: $PID)" -ForegroundColor Yellow
    Write-Host "  Intervalle : $IntervalSeconds secondes" -ForegroundColor Yellow
    Write-Host "  Durée : $DurationSeconds secondes" -ForegroundColor Yellow
    
    while ((Get-Date) -lt $endTime) {
        # Mettre à jour les informations du processus
        $process = Get-Process -Id $PID
        
        # Enregistrer l'utilisation de la mémoire
        $memoryUsage += [PSCustomObject]@{
            Timestamp = Get-Date
            WorkingSetMB = $process.WorkingSet64 / 1MB
            PrivateMemoryMB = $process.PrivateMemorySize64 / 1MB
            VirtualMemoryMB = $process.VirtualMemorySize64 / 1MB
        }
        
        # Attendre l'intervalle spécifié
        Start-Sleep -Seconds $IntervalSeconds
    }
    
    Write-Host "Surveillance de la mémoire terminée." -ForegroundColor Green
    
    return $memoryUsage
}

# Fonction pour optimiser l'utilisation de la mémoire
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
    
    Write-Host "`n=== Optimisation de l'utilisation de la mémoire ===" -ForegroundColor Cyan
    
    # Créer un répertoire pour les résultats
    $resultsPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization"
    if (-not (Test-Path -Path $resultsPath)) {
        New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null
    }
    
    # Techniques d'optimisation de la mémoire
    $optimizationTechniques = @(
        @{
            Name = "Standard (sans optimisation)"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "standard")
            }
        },
        @{
            Name = "Traitement par lots avec libération de mémoire"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "batch_with_gc")
                BatchSize = 10
                ForceGC = $true
            }
        },
        @{
            Name = "Streaming de données"
            Parameters = @{
                ScriptsPath = $TestFilesPath
                OutputPath = (Join-Path -Path $resultsPath -ChildPath "streaming")
                UseStreaming = $true
            }
        },
        @{
            Name = "Limitation du nombre de processus parallèles"
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
        
        # Démarrer la surveillance de la mémoire
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
        
        # Exécuter le script avec les paramètres spécifiés
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            # Exécuter le script
            $scriptResult = & $ScriptPath @($technique.Parameters)
            $success = $true
        }
        catch {
            Write-Error "Erreur lors de l'exécution du script avec la technique '$($technique.Name)' : $_"
            $success = $false
            $scriptResult = $null
        }
        
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed.TotalSeconds
        
        # Arrêter la surveillance de la mémoire
        $memoryUsage = Receive-Job -Job $monitoringJob
        Remove-Job -Job $monitoringJob -Force
        
        # Calculer les statistiques d'utilisation de la mémoire
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
        
        # Enregistrer les résultats
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
        
        Write-Host "  Temps d'exécution : $executionTime secondes" -ForegroundColor Yellow
        Write-Host "  Working Set moyen : $avgWorkingSet MB" -ForegroundColor Yellow
        Write-Host "  Working Set max : $maxWorkingSet MB" -ForegroundColor Yellow
        Write-Host "  Mémoire privée moyenne : $avgPrivateMemory MB" -ForegroundColor Yellow
        Write-Host "  Mémoire privée max : $maxPrivateMemory MB" -ForegroundColor Yellow
        Write-Host "  Succès : $success" -ForegroundColor ($success ? "Green" : "Red")
    }
    
    # Déterminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.Success } | 
        Sort-Object -Property MaxWorkingSetMB | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        Write-Host "`n=== Technique d'optimisation de la mémoire optimale ===" -ForegroundColor Green
        Write-Host "  Technique : $($optimalTechnique.Technique)" -ForegroundColor Green
        Write-Host "  Temps d'exécution : $($optimalTechnique.ExecutionTime) secondes" -ForegroundColor Green
        Write-Host "  Working Set max : $($optimalTechnique.MaxWorkingSetMB) MB" -ForegroundColor Green
        Write-Host "  Mémoire privée max : $($optimalTechnique.MaxPrivateMemoryMB) MB" -ForegroundColor Green
    }
    else {
        Write-Warning "Impossible de déterminer la technique optimale. Aucun test n'a réussi."
    }
    
    return $results
}

# Créer des fichiers de test si nécessaire
$testFilesPath = Join-Path -Path $OutputPath -ChildPath "test_files"
if (-not (Test-Path -Path $testFilesPath)) {
    Write-Host "Création des fichiers de test..." -ForegroundColor Yellow
    
    # Importer le script de benchmark pour utiliser sa fonction de création de fichiers de test
    $benchmarkPath = Join-Path -Path $PSScriptRoot -ChildPath "benchmark.ps1"
    . $benchmarkPath
    
    $testFilesPath = New-TestFiles -OutputPath $OutputPath -SmallFiles 100 -MediumFiles 50 -LargeFiles 20
}
else {
    Write-Host "Utilisation des fichiers de test existants : $testFilesPath" -ForegroundColor Yellow
}

# Chemin vers le script d'analyse
$analyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "examples\script-analyzer-simple.ps1"

# Optimiser l'utilisation de la mémoire
$results = Optimize-MemoryUsage `
    -ScriptPath $analyzerPath `
    -TestFilesPath $testFilesPath `
    -OutputPath $OutputPath

# Enregistrer les résultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization_results.json"
$results | Select-Object -Property Technique, ExecutionTime, AverageWorkingSetMB, MaxWorkingSetMB, AveragePrivateMemoryMB, MaxPrivateMemoryMB, Success | 
    ConvertTo-Json -Depth 5 | 
    Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRésultats enregistrés : $resultsPath" -ForegroundColor Green

# Enregistrer les données d'utilisation de la mémoire pour chaque technique
foreach ($result in $results) {
    $techniqueName = $result.Technique -replace '[^a-zA-Z0-9]', '_'
    $memoryUsagePath = Join-Path -Path $OutputPath -ChildPath "memory_usage_$techniqueName.json"
    
    $result.MemoryUsage | Select-Object -Property Timestamp, WorkingSetMB, PrivateMemoryMB, VirtualMemoryMB | 
        ConvertTo-Json -Depth 5 | 
        Out-File -FilePath $memoryUsagePath -Encoding utf8
    
    Write-Host "Données d'utilisation de la mémoire enregistrées : $memoryUsagePath" -ForegroundColor Green
}

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "memory_optimization_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation de la mémoire</title>
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
    <h1>Rapport d'optimisation de la mémoire</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de techniques testées : $($results.Count)</p>
"@
    
    # Déterminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.Success } | 
        Sort-Object -Property MaxWorkingSetMB | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        $htmlContent += @"
        <p><strong>Technique optimale : $($optimalTechnique.Technique)</strong></p>
        <p>Temps d'exécution : $([Math]::Round($optimalTechnique.ExecutionTime, 2)) secondes</p>
        <p>Working Set max : $([Math]::Round($optimalTechnique.MaxWorkingSetMB, 2)) MB</p>
        <p>Mémoire privée max : $([Math]::Round($optimalTechnique.MaxPrivateMemoryMB, 2)) MB</p>
"@
    }
    else {
        $htmlContent += @"
        <p><strong>Impossible de déterminer la technique optimale. Aucun test n'a réussi.</strong></p>
"@
    }
    
    $htmlContent += @"
    </div>
    
    <h2>Résultats par technique</h2>
    <table>
        <thead>
            <tr>
                <th>Technique</th>
                <th>Temps d'exécution (s)</th>
                <th>Working Set moyen (MB)</th>
                <th>Working Set max (MB)</th>
                <th>Mémoire privée moyenne (MB)</th>
                <th>Mémoire privée max (MB)</th>
                <th>Succès</th>
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
    
    <h3>Utilisation de la mémoire (Working Set)</h3>
    <div class="chart-container">
        <canvas id="workingSetChart"></canvas>
    </div>
    
    <h3>Utilisation de la mémoire (Mémoire privée)</h3>
    <div class="chart-container">
        <canvas id="privateMemoryChart"></canvas>
    </div>
    
    <h3>Temps d'exécution</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <script>
        // Données pour les graphiques
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
        
        // Graphique Mémoire privée
        const pmCtx = document.getElementById('privateMemoryChart').getContext('2d');
        new Chart(pmCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [
                    {
                        label: 'Mémoire privée moyenne (MB)',
                        data: avgPrivateMemory,
                        backgroundColor: 'rgba(0, 120, 212, 0.7)',
                        borderColor: 'rgba(0, 120, 212, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Mémoire privée max (MB)',
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
        
        // Graphique Temps d'exécution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [{
                    label: 'Temps d\'exécution (s)',
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
    
    Write-Host "Rapport HTML généré : $reportPath" -ForegroundColor Green
    
    # Ouvrir le rapport dans le navigateur par défaut
    Start-Process $reportPath
}

# Retourner les résultats
return $results
