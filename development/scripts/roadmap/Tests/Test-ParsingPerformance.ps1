# Test-ParsingPerformance.ps1
# Script de test pour évaluer les performances des différentes méthodes de parsing
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Évalue les performances des différentes méthodes de parsing pour les roadmaps volumineuses.

.DESCRIPTION
    Ce script évalue les performances des différentes méthodes de parsing pour les roadmaps volumineuses,
    notamment le parsing incrémental, le parsing par flux (streaming) et le parsing parallèle.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$performancePath = Join-Path -Path $parentPath -ChildPath "performance"
$optimizeRoadmapParsingPath = Join-Path -Path $performancePath -ChildPath "Optimize-RoadmapParsing.ps1"
$optimizeRoadmapPerformancePath = Join-Path -Path $performancePath -ChildPath "Optimize-RoadmapPerformance.ps1"

if (Test-Path $optimizeRoadmapParsingPath) {
    . $optimizeRoadmapParsingPath
    Write-Host "Module Optimize-RoadmapParsing.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Optimize-RoadmapParsing.ps1 introuvable à l'emplacement: $optimizeRoadmapParsingPath"
    exit
}

if (Test-Path $optimizeRoadmapPerformancePath) {
    . $optimizeRoadmapPerformancePath
    Write-Host "Module Optimize-RoadmapPerformance.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Optimize-RoadmapPerformance.ps1 introuvable à l'emplacement: $optimizeRoadmapPerformancePath"
    exit
}

# Fonction pour générer un fichier de roadmap de test
function New-TestRoadmap {
    <#
    .SYNOPSIS
        Génère un fichier de roadmap de test.

    .DESCRIPTION
        Cette fonction génère un fichier de roadmap de test avec un nombre spécifié de tâches.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier de roadmap.

    .PARAMETER TaskCount
        Le nombre de tâches à générer.
        Par défaut, 1000 tâches.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie des tâches.
        Par défaut, 5 niveaux.

    .PARAMETER TasksPerLevel
        Le nombre de tâches par niveau.
        Par défaut, 5 tâches par niveau.

    .EXAMPLE
        New-TestRoadmap -OutputPath "C:\Temp\test-roadmap.md" -TaskCount 5000 -MaxDepth 6 -TasksPerLevel 8
        Génère un fichier de roadmap de test avec 5000 tâches, une profondeur maximale de 6 niveaux et 8 tâches par niveau.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 1000,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 5,

        [Parameter(Mandatory = $false)]
        [int]$TasksPerLevel = 5
    )

    try {
        # Créer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Générer le contenu de la roadmap
        $content = @()
        $content += "# Roadmap de test"
        $content += ""
        $content += "Cette roadmap est générée automatiquement pour les tests de performance."
        $content += ""
        
        # Générer les tâches
        $taskNumber = 0
        $statusOptions = @("[ ]", "[x]")
        $priorityOptions = @("high", "medium", "low")
        $domainOptions = @("frontend", "backend", "database", "security", "performance")
        
        function Add-Tasks {
            param (
                [int]$Level,
                [string]$Prefix
            )
            
            $indent = "  " * ($Level - 1)
            $taskCount = Get-Random -Minimum 1 -Maximum $TasksPerLevel
            
            for ($i = 1; $i -le $taskCount; $i++) {
                $taskId = if ([string]::IsNullOrEmpty($Prefix)) { "$i" } else { "$Prefix.$i" }
                $status = $statusOptions[(Get-Random -Minimum 0 -Maximum 2)]
                $priority = $priorityOptions[(Get-Random -Minimum 0 -Maximum 3)]
                $domain = $domainOptions[(Get-Random -Minimum 0 -Maximum 5)]
                
                $content += "$indent- $status **$taskId** Tâche de test $taskId (#priority:$priority #domain:$domain)"
                $taskNumber++
                
                if ($taskNumber -ge $TaskCount) {
                    return $content
                }
                
                if ($Level -lt $MaxDepth) {
                    $content = Add-Tasks -Level ($Level + 1) -Prefix $taskId
                }
            }
            
            return $content
        }
        
        $content = Add-Tasks -Level 1 -Prefix ""
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding UTF8
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            OutputPath = $OutputPath
            TaskCount = $taskNumber
            MaxDepth = $MaxDepth
            TasksPerLevel = $TasksPerLevel
            FileSize = (Get-Item -Path $OutputPath).Length
            FileSizeMB = (Get-Item -Path $OutputPath).Length / 1MB
        }
        
        return $result
    } catch {
        Write-Error "Échec de la génération du fichier de roadmap de test: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour exécuter les tests de performance
function Invoke-ParsingPerformanceTest {
    <#
    .SYNOPSIS
        Exécute les tests de performance pour les différentes méthodes de parsing.

    .DESCRIPTION
        Cette fonction exécute les tests de performance pour les différentes méthodes de parsing,
        notamment le parsing incrémental, le parsing par flux (streaming) et le parsing parallèle.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à tester.
        Si non spécifié, un fichier de test est généré.

    .PARAMETER TaskCount
        Le nombre de tâches à générer pour le fichier de test.
        Par défaut, 10000 tâches.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats des tests.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER RunCount
        Le nombre d'exécutions pour chaque méthode de parsing.
        Par défaut, 3 exécutions.

    .EXAMPLE
        Invoke-ParsingPerformanceTest -TaskCount 20000 -RunCount 5
        Exécute les tests de performance avec un fichier de test de 20000 tâches et 5 exécutions pour chaque méthode.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath = "",

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 10000,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$RunCount = 3
    )

    try {
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "ParsingPerformanceTests"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Générer un fichier de test si nécessaire
        if ([string]::IsNullOrEmpty($RoadmapPath)) {
            $testRoadmapPath = Join-Path -Path $OutputPath -ChildPath "test-roadmap-$TaskCount.md"
            Write-Host "Génération du fichier de test avec $TaskCount tâches..." -ForegroundColor Cyan
            $roadmap = New-TestRoadmap -OutputPath $testRoadmapPath -TaskCount $TaskCount
            $RoadmapPath = $roadmap.OutputPath
            
            Write-Host "Fichier de test généré: $RoadmapPath" -ForegroundColor Green
            Write-Host "Taille du fichier: $([Math]::Round($roadmap.FileSizeMB, 2)) Mo" -ForegroundColor Green
        }
        
        # Vérifier que le fichier existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Créer le dossier de résultats
        $resultPath = Join-Path -Path $OutputPath -ChildPath "results"
        if (-not (Test-Path $resultPath)) {
            New-Item -Path $resultPath -ItemType Directory -Force | Out-Null
        }
        
        # Exécuter les tests pour chaque mode de parsing
        $modes = @("Incremental", "Streaming", "Parallel")
        $results = @()
        
        foreach ($mode in $modes) {
            Write-Host "Exécution des tests pour le mode $mode..." -ForegroundColor Cyan
            
            $modeResults = @()
            
            for ($i = 1; $i -le $RunCount; $i++) {
                Write-Host "  Exécution $i/$RunCount..." -ForegroundColor Yellow
                
                # Mesurer les performances
                $startTime = Get-Date
                $memoryBefore = [System.GC]::GetTotalMemory($true)
                
                $result = Optimize-RoadmapParsing -RoadmapPath $RoadmapPath -ParsingMode $mode -OutputPath (Join-Path -Path $resultPath -ChildPath $mode)
                
                $endTime = Get-Date
                $memoryAfter = [System.GC]::GetTotalMemory($true)
                
                $duration = $endTime - $startTime
                $memoryUsage = ($memoryAfter - $memoryBefore) / 1MB
                
                $modeResults += [PSCustomObject]@{
                    Mode = $mode
                    Run = $i
                    DurationSeconds = $duration.TotalSeconds
                    MemoryUsageMB = $memoryUsage
                    TaskCount = $result.TotalTasks
                    ProcessingSpeedMBPerSecond = $result.ProcessingSpeedMBPerSecond
                }
                
                Write-Host "    Durée: $([Math]::Round($duration.TotalSeconds, 2)) secondes" -ForegroundColor Green
                Write-Host "    Utilisation mémoire: $([Math]::Round($memoryUsage, 2)) Mo" -ForegroundColor Green
                Write-Host "    Vitesse de traitement: $([Math]::Round($result.ProcessingSpeedMBPerSecond, 2)) Mo/s" -ForegroundColor Green
                
                # Libérer la mémoire
                [System.GC]::Collect()
                Start-Sleep -Seconds 2
            }
            
            # Calculer les moyennes
            $avgDuration = ($modeResults | Measure-Object -Property DurationSeconds -Average).Average
            $avgMemoryUsage = ($modeResults | Measure-Object -Property MemoryUsageMB -Average).Average
            $avgProcessingSpeed = ($modeResults | Measure-Object -Property ProcessingSpeedMBPerSecond -Average).Average
            
            $results += [PSCustomObject]@{
                Mode = $mode
                AverageDurationSeconds = $avgDuration
                AverageMemoryUsageMB = $avgMemoryUsage
                AverageProcessingSpeedMBPerSecond = $avgProcessingSpeed
                Runs = $modeResults
            }
            
            Write-Host "  Moyenne sur $RunCount exécutions:" -ForegroundColor Cyan
            Write-Host "    Durée: $([Math]::Round($avgDuration, 2)) secondes" -ForegroundColor Green
            Write-Host "    Utilisation mémoire: $([Math]::Round($avgMemoryUsage, 2)) Mo" -ForegroundColor Green
            Write-Host "    Vitesse de traitement: $([Math]::Round($avgProcessingSpeed, 2)) Mo/s" -ForegroundColor Green
        }
        
        # Créer l'objet de résultat
        $finalResult = [PSCustomObject]@{
            RoadmapPath = $RoadmapPath
            FileSize = (Get-Item -Path $RoadmapPath).Length
            FileSizeMB = (Get-Item -Path $RoadmapPath).Length / 1MB
            RunCount = $RunCount
            Results = $results
            BestMode = ($results | Sort-Object -Property AverageDurationSeconds | Select-Object -First 1).Mode
            TestDate = Get-Date
        }
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $resultPath -ChildPath "performance-results.json"
        $finalResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        # Générer un rapport HTML
        $htmlReportPath = Join-Path -Path $resultPath -ChildPath "performance-report.html"
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performance de parsing</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .best { background-color: #d4edda; }
        .chart { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de performance de parsing</h1>
    <p><strong>Fichier:</strong> $($finalResult.RoadmapPath)</p>
    <p><strong>Taille:</strong> $([Math]::Round($finalResult.FileSizeMB, 2)) Mo</p>
    <p><strong>Date du test:</strong> $($finalResult.TestDate)</p>
    <p><strong>Nombre d'exécutions:</strong> $($finalResult.RunCount)</p>
    <p><strong>Meilleur mode:</strong> $($finalResult.BestMode)</p>
    
    <h2>Résultats par mode</h2>
    <div class="chart">
        <canvas id="durationChart"></canvas>
    </div>
    <div class="chart">
        <canvas id="memoryChart"></canvas>
    </div>
    <div class="chart">
        <canvas id="speedChart"></canvas>
    </div>
    
    <table>
        <tr>
            <th>Mode</th>
            <th>Durée moyenne (s)</th>
            <th>Utilisation mémoire moyenne (Mo)</th>
            <th>Vitesse de traitement moyenne (Mo/s)</th>
        </tr>
"@
        
        foreach ($result in $results) {
            $bestClass = if ($result.Mode -eq $finalResult.BestMode) { "best" } else { "" }
            $htmlContent += @"
        <tr class="$bestClass">
            <td>$($result.Mode)</td>
            <td>$([Math]::Round($result.AverageDurationSeconds, 2))</td>
            <td>$([Math]::Round($result.AverageMemoryUsageMB, 2))</td>
            <td>$([Math]::Round($result.AverageProcessingSpeedMBPerSecond, 2))</td>
        </tr>
"@
        }
        
        $htmlContent += @"
    </table>
    
    <h2>Détails des exécutions</h2>
"@
        
        foreach ($result in $results) {
            $htmlContent += @"
    <h3>Mode: $($result.Mode)</h3>
    <table>
        <tr>
            <th>Exécution</th>
            <th>Durée (s)</th>
            <th>Utilisation mémoire (Mo)</th>
            <th>Vitesse de traitement (Mo/s)</th>
        </tr>
"@
            
            foreach ($run in $result.Runs) {
                $htmlContent += @"
        <tr>
            <td>$($run.Run)</td>
            <td>$([Math]::Round($run.DurationSeconds, 2))</td>
            <td>$([Math]::Round($run.MemoryUsageMB, 2))</td>
            <td>$([Math]::Round($run.ProcessingSpeedMBPerSecond, 2))</td>
        </tr>
"@
            }
            
            $htmlContent += @"
    </table>
"@
        }
        
        $htmlContent += @"
    <script>
        // Graphique de durée
        var durationCtx = document.getElementById('durationChart').getContext('2d');
        var durationChart = new Chart(durationCtx, {
            type: 'bar',
            data: {
                labels: [$(($results | ForEach-Object { "'$($_.Mode)'" }) -join ", ")],
                datasets: [{
                    label: 'Durée moyenne (s)',
                    data: [$(($results | ForEach-Object { [Math]::Round($_.AverageDurationSeconds, 2) }) -join ", ")],
                    backgroundColor: [$(($results | ForEach-Object { if ($_.Mode -eq $finalResult.BestMode) { "'rgba(75, 192, 192, 0.2)'" } else { "'rgba(54, 162, 235, 0.2)'" } }) -join ", ")],
                    borderColor: [$(($results | ForEach-Object { if ($_.Mode -eq $finalResult.BestMode) { "'rgba(75, 192, 192, 1)'" } else { "'rgba(54, 162, 235, 1)'" } }) -join ", ")],
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
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Durée moyenne par mode'
                    }
                }
            }
        });
        
        // Graphique d'utilisation mémoire
        var memoryCtx = document.getElementById('memoryChart').getContext('2d');
        var memoryChart = new Chart(memoryCtx, {
            type: 'bar',
            data: {
                labels: [$(($results | ForEach-Object { "'$($_.Mode)'" }) -join ", ")],
                datasets: [{
                    label: 'Utilisation mémoire moyenne (Mo)',
                    data: [$(($results | ForEach-Object { [Math]::Round($_.AverageMemoryUsageMB, 2) }) -join ", ")],
                    backgroundColor: ['rgba(255, 99, 132, 0.2)', 'rgba(255, 159, 64, 0.2)', 'rgba(255, 205, 86, 0.2)'],
                    borderColor: ['rgba(255, 99, 132, 1)', 'rgba(255, 159, 64, 1)', 'rgba(255, 205, 86, 1)'],
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Mégaoctets'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Utilisation mémoire moyenne par mode'
                    }
                }
            }
        });
        
        // Graphique de vitesse de traitement
        var speedCtx = document.getElementById('speedChart').getContext('2d');
        var speedChart = new Chart(speedCtx, {
            type: 'bar',
            data: {
                labels: [$(($results | ForEach-Object { "'$($_.Mode)'" }) -join ", ")],
                datasets: [{
                    label: 'Vitesse de traitement moyenne (Mo/s)',
                    data: [$(($results | ForEach-Object { [Math]::Round($_.AverageProcessingSpeedMBPerSecond, 2) }) -join ", ")],
                    backgroundColor: ['rgba(153, 102, 255, 0.2)', 'rgba(201, 203, 207, 0.2)', 'rgba(255, 99, 132, 0.2)'],
                    borderColor: ['rgba(153, 102, 255, 1)', 'rgba(201, 203, 207, 1)', 'rgba(255, 99, 132, 1)'],
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Mo/s'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Vitesse de traitement moyenne par mode'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
        
        $htmlContent | Out-File -FilePath $htmlReportPath -Encoding UTF8
        
        Write-Host "Rapport HTML généré: $htmlReportPath" -ForegroundColor Green
        
        return $finalResult
    } catch {
        Write-Error "Échec des tests de performance: $($_.Exception.Message)"
        return $null
    }
}

# Exécuter les tests de performance
Invoke-ParsingPerformanceTest -TaskCount 5000 -RunCount 2
