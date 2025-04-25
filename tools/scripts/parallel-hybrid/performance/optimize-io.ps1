#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise les opérations d'E/S dans le traitement parallèle.
.DESCRIPTION
    Ce script implémente des techniques pour réduire les opérations d'E/S redondantes
    et améliorer les performances des opérations d'E/S.
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

# Fonction pour mesurer les performances des opérations d'E/S
function Measure-IOPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TestFilesPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 3
    )
    
    Write-Host "`n=== Mesure des performances d'E/S ===" -ForegroundColor Cyan
    
    # Créer un répertoire pour les résultats
    $resultsPath = Join-Path -Path $OutputPath -ChildPath "io_optimization"
    if (-not (Test-Path -Path $resultsPath)) {
        New-Item -Path $resultsPath -ItemType Directory -Force | Out-Null
    }
    
    # Techniques d'optimisation d'E/S
    $ioTechniques = @(
        @{
            Name = "Standard (sans optimisation)"
            ScriptBlock = {
                param($TestFilesPath, $OutputPath)
                
                $files = Get-ChildItem -Path $TestFilesPath -Filter "*.ps1" -Recurse
                $results = @()
                
                foreach ($file in $files) {
                    $content = Get-Content -Path $file.FullName -Raw
                    $lineCount = ($content -split "`n").Count
                    
                    $results += [PSCustomObject]@{
                        FileName = $file.Name
                        FilePath = $file.FullName
                        LineCount = $lineCount
                        FileSize = $file.Length
                    }
                }
                
                $results | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "results.json") -Encoding utf8
                
                return $results
            }
        },
        @{
            Name = "Lecture asynchrone"
            ScriptBlock = {
                param($TestFilesPath, $OutputPath)
                
                $files = Get-ChildItem -Path $TestFilesPath -Filter "*.ps1" -Recurse
                $results = @()
                $jobs = @()
                
                # Démarrer les jobs de lecture asynchrone
                foreach ($file in $files) {
                    $jobs += Start-Job -ScriptBlock {
                        param($FilePath)
                        
                        $content = Get-Content -Path $FilePath -Raw
                        $lineCount = ($content -split "`n").Count
                        
                        return [PSCustomObject]@{
                            FileName = [System.IO.Path]::GetFileName($FilePath)
                            FilePath = $FilePath
                            LineCount = $lineCount
                            FileSize = (Get-Item -Path $FilePath).Length
                        }
                    } -ArgumentList $file.FullName
                }
                
                # Attendre que tous les jobs soient terminés
                $jobs | Wait-Job | Out-Null
                
                # Récupérer les résultats
                foreach ($job in $jobs) {
                    $results += Receive-Job -Job $job
                    Remove-Job -Job $job
                }
                
                $results | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "results.json") -Encoding utf8
                
                return $results
            }
        },
        @{
            Name = "Lecture par lots"
            ScriptBlock = {
                param($TestFilesPath, $OutputPath)
                
                $files = Get-ChildItem -Path $TestFilesPath -Filter "*.ps1" -Recurse
                $results = @()
                $batchSize = 10
                $batches = [Math]::Ceiling($files.Count / $batchSize)
                
                for ($i = 0; $i -lt $batches; $i++) {
                    $batchFiles = $files | Select-Object -Skip ($i * $batchSize) -First $batchSize
                    $batchResults = @()
                    
                    foreach ($file in $batchFiles) {
                        $content = Get-Content -Path $file.FullName -Raw
                        $lineCount = ($content -split "`n").Count
                        
                        $batchResults += [PSCustomObject]@{
                            FileName = $file.Name
                            FilePath = $file.FullName
                            LineCount = $lineCount
                            FileSize = $file.Length
                        }
                    }
                    
                    $results += $batchResults
                }
                
                $results | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "results.json") -Encoding utf8
                
                return $results
            }
        },
        @{
            Name = "Mise en cache des fichiers"
            ScriptBlock = {
                param($TestFilesPath, $OutputPath)
                
                $files = Get-ChildItem -Path $TestFilesPath -Filter "*.ps1" -Recurse
                $results = @()
                $fileCache = @{}
                
                foreach ($file in $files) {
                    # Vérifier si le fichier est déjà en cache
                    if (-not $fileCache.ContainsKey($file.FullName)) {
                        $content = Get-Content -Path $file.FullName -Raw
                        $fileCache[$file.FullName] = @{
                            Content = $content
                            LineCount = ($content -split "`n").Count
                            FileSize = $file.Length
                        }
                    }
                    
                    $cachedFile = $fileCache[$file.FullName]
                    
                    $results += [PSCustomObject]@{
                        FileName = $file.Name
                        FilePath = $file.FullName
                        LineCount = $cachedFile.LineCount
                        FileSize = $cachedFile.FileSize
                    }
                }
                
                $results | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "results.json") -Encoding utf8
                
                return $results
            }
        },
        @{
            Name = "Utilisation de streams"
            ScriptBlock = {
                param($TestFilesPath, $OutputPath)
                
                $files = Get-ChildItem -Path $TestFilesPath -Filter "*.ps1" -Recurse
                $results = @()
                
                foreach ($file in $files) {
                    $lineCount = 0
                    
                    # Utiliser un FileStream pour la lecture
                    $stream = [System.IO.File]::OpenRead($file.FullName)
                    $reader = New-Object System.IO.StreamReader($stream)
                    
                    while ($null -ne $reader.ReadLine()) {
                        $lineCount++
                    }
                    
                    $reader.Close()
                    $stream.Close()
                    
                    $results += [PSCustomObject]@{
                        FileName = $file.Name
                        FilePath = $file.FullName
                        LineCount = $lineCount
                        FileSize = $file.Length
                    }
                }
                
                $results | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "results.json") -Encoding utf8
                
                return $results
            }
        }
    )
    
    $results = @()
    
    foreach ($technique in $ioTechniques) {
        Write-Host "`nTest de la technique : $($technique.Name)" -ForegroundColor Yellow
        
        $techniqueResults = @()
        
        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Host "  Itération $i/$Iterations..." -ForegroundColor Yellow
            
            # Nettoyer la mémoire avant chaque test
            [System.GC]::Collect()
            
            # Mesurer le temps d'exécution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                # Exécuter le script
                $scriptResult = & $technique.ScriptBlock $TestFilesPath (Join-Path -Path $resultsPath -ChildPath $technique.Name.Replace(" ", "_"))
                $success = $true
                $fileCount = $scriptResult.Count
            }
            catch {
                Write-Error "Erreur lors de l'exécution de la technique '$($technique.Name)' : $_"
                $success = $false
                $fileCount = 0
            }
            
            $stopwatch.Stop()
            $executionTime = $stopwatch.Elapsed.TotalSeconds
            
            # Enregistrer les résultats
            $techniqueResults += [PSCustomObject]@{
                Iteration = $i
                ExecutionTime = $executionTime
                FileCount = $fileCount
                Success = $success
            }
            
            Write-Host "    Temps d'exécution : $executionTime secondes" -ForegroundColor Yellow
            Write-Host "    Nombre de fichiers traités : $fileCount" -ForegroundColor Yellow
            Write-Host "    Succès : $success" -ForegroundColor ($success ? "Green" : "Red")
        }
        
        # Calculer les statistiques
        $avgTime = ($techniqueResults | Measure-Object -Property ExecutionTime -Average).Average
        $minTime = ($techniqueResults | Measure-Object -Property ExecutionTime -Minimum).Minimum
        $maxTime = ($techniqueResults | Measure-Object -Property ExecutionTime -Maximum).Maximum
        $successRate = ($techniqueResults | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
        
        Write-Host "`n  Résultats pour '$($technique.Name)' :" -ForegroundColor Cyan
        Write-Host "    Temps moyen : $avgTime secondes" -ForegroundColor Green
        Write-Host "    Temps min/max : $minTime / $maxTime secondes" -ForegroundColor Green
        Write-Host "    Taux de succès : $successRate%" -ForegroundColor Green
        
        $results += [PSCustomObject]@{
            Technique = $technique.Name
            AverageTime = $avgTime
            MinTime = $minTime
            MaxTime = $maxTime
            SuccessRate = $successRate
            DetailedResults = $techniqueResults
        }
    }
    
    # Déterminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.SuccessRate -eq 100 } | 
        Sort-Object -Property AverageTime | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        Write-Host "`n=== Technique d'optimisation d'E/S optimale ===" -ForegroundColor Green
        Write-Host "  Technique : $($optimalTechnique.Technique)" -ForegroundColor Green
        Write-Host "  Temps moyen : $($optimalTechnique.AverageTime) secondes" -ForegroundColor Green
        Write-Host "  Temps min/max : $($optimalTechnique.MinTime) / $($optimalTechnique.MaxTime) secondes" -ForegroundColor Green
    }
    else {
        Write-Warning "Impossible de déterminer la technique optimale. Aucun test n'a réussi à 100%."
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
    
    $testFilesPath = New-TestFiles -OutputPath $OutputPath -SmallFiles 200 -MediumFiles 100 -LargeFiles 50
}
else {
    Write-Host "Utilisation des fichiers de test existants : $testFilesPath" -ForegroundColor Yellow
}

# Mesurer les performances d'E/S
$results = Measure-IOPerformance `
    -TestFilesPath $testFilesPath `
    -OutputPath $OutputPath

# Enregistrer les résultats
$resultsPath = Join-Path -Path $OutputPath -ChildPath "io_optimization_results.json"
$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsPath -Encoding utf8

Write-Host "`nRésultats enregistrés : $resultsPath" -ForegroundColor Green

# Générer un rapport HTML si demandé
if ($GenerateReport) {
    $reportPath = Join-Path -Path $OutputPath -ChildPath "io_optimization_report.html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation des E/S</title>
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
    <h1>Rapport d'optimisation des E/S</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre de techniques testées : $($results.Count)</p>
"@
    
    # Déterminer la technique optimale
    $optimalTechnique = $results | 
        Where-Object { $_.SuccessRate -eq 100 } | 
        Sort-Object -Property AverageTime | 
        Select-Object -First 1
    
    if ($optimalTechnique) {
        $htmlContent += @"
        <p><strong>Technique optimale : $($optimalTechnique.Technique)</strong></p>
        <p>Temps moyen : $([Math]::Round($optimalTechnique.AverageTime, 2)) secondes</p>
        <p>Temps min/max : $([Math]::Round($optimalTechnique.MinTime, 2)) / $([Math]::Round($optimalTechnique.MaxTime, 2)) secondes</p>
"@
    }
    else {
        $htmlContent += @"
        <p><strong>Impossible de déterminer la technique optimale. Aucun test n'a réussi à 100%.</strong></p>
"@
    }
    
    $htmlContent += @"
    </div>
    
    <h2>Résultats par technique</h2>
    <table>
        <thead>
            <tr>
                <th>Technique</th>
                <th>Temps moyen (s)</th>
                <th>Temps min (s)</th>
                <th>Temps max (s)</th>
                <th>Taux de succès (%)</th>
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
                <td>$([Math]::Round($result.AverageTime, 2))</td>
                <td>$([Math]::Round($result.MinTime, 2))</td>
                <td>$([Math]::Round($result.MaxTime, 2))</td>
                <td>$([Math]::Round($result.SuccessRate, 2))</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </tbody>
    </table>
    
    <h2>Graphiques</h2>
    
    <h3>Temps d'exécution moyen par technique</h3>
    <div class="chart-container">
        <canvas id="timeChart"></canvas>
    </div>
    
    <script>
        // Données pour les graphiques
        const techniques = [$(($results | ForEach-Object { "'$($_.Technique)'" }) -join ', ')];
        const avgTimes = [$(($results | ForEach-Object { [Math]::Round($_.AverageTime, 2) }) -join ', ')];
        const minTimes = [$(($results | ForEach-Object { [Math]::Round($_.MinTime, 2) }) -join ', ')];
        const maxTimes = [$(($results | ForEach-Object { [Math]::Round($_.MaxTime, 2) }) -join ', ')];
        
        // Graphique des temps d'exécution
        const timeCtx = document.getElementById('timeChart').getContext('2d');
        new Chart(timeCtx, {
            type: 'bar',
            data: {
                labels: techniques,
                datasets: [
                    {
                        label: 'Temps moyen (s)',
                        data: avgTimes,
                        backgroundColor: 'rgba(0, 120, 212, 0.7)',
                        borderColor: 'rgba(0, 120, 212, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Temps min (s)',
                        data: minTimes,
                        backgroundColor: 'rgba(0, 183, 74, 0.7)',
                        borderColor: 'rgba(0, 183, 74, 1)',
                        borderWidth: 1
                    },
                    {
                        label: 'Temps max (s)',
                        data: maxTimes,
                        backgroundColor: 'rgba(209, 52, 56, 0.7)',
                        borderColor: 'rgba(209, 52, 56, 1)',
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
