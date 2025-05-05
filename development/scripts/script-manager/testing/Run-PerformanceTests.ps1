#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute des tests de performance pour le script manager.
.DESCRIPTION
    Ce script exÃ©cute des tests de performance pour mesurer les performances
    des fonctions critiques du script manager.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER Iterations
    Nombre d'itÃ©rations pour chaque test de performance.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.EXAMPLE
    .\Run-PerformanceTests.ps1 -OutputPath ".\reports\performance" -Iterations 10 -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\performance",
    
    [Parameter(Mandatory = $false)]
    [int]$Iterations = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Fonction pour Ã©crire dans le journal
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
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# Fonction pour mesurer les performances d'une fonction
function Measure-FunctionPerformance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 5
    )
    
    Write-Log "Mesure des performances de la fonction '$Name'..." -Level "INFO"
    
    $results = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Log "  ItÃ©ration $i/$Iterations..." -Level "INFO"
        
        # Mesurer le temps d'exÃ©cution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # ExÃ©cuter la fonction
        try {
            & $ScriptBlock
            $success = $true
        }
        catch {
            Write-Log "Erreur lors de l'exÃ©cution de la fonction: $_" -Level "ERROR"
            $success = $false
        }
        
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed
        
        # Mesurer l'utilisation de la mÃ©moire
        $memoryBefore = [System.GC]::GetTotalMemory($true)
        & $ScriptBlock
        $memoryAfter = [System.GC]::GetTotalMemory($true)
        $memoryUsage = $memoryAfter - $memoryBefore
        
        # Ajouter les rÃ©sultats
        $results += [PSCustomObject]@{
            Iteration = $i
            ExecutionTime = $executionTime
            ExecutionTimeMs = $executionTime.TotalMilliseconds
            MemoryUsage = $memoryUsage
            MemoryUsageKB = [math]::Round($memoryUsage / 1KB, 2)
            Success = $success
        }
    }
    
    # Calculer les statistiques
    $stats = [PSCustomObject]@{
        Name = $Name
        Iterations = $Iterations
        AverageExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Average).Average
        MinExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Minimum).Minimum
        MaxExecutionTime = ($results | Measure-Object -Property ExecutionTimeMs -Maximum).Maximum
        AverageMemoryUsage = ($results | Measure-Object -Property MemoryUsageKB -Average).Average
        MinMemoryUsage = ($results | Measure-Object -Property MemoryUsageKB -Minimum).Minimum
        MaxMemoryUsage = ($results | Measure-Object -Property MemoryUsageKB -Maximum).Maximum
        SuccessRate = ($results | Where-Object { $_.Success } | Measure-Object).Count / $Iterations * 100
        Results = $results
    }
    
    return $stats
}

# Charger les fonctions Ã  tester
. "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1"

# DÃ©finir les tests de performance
$performanceTests = @(
    @{
        Name = "Get-ScriptCategory"
        ScriptBlock = {
            # Tester avec diffÃ©rents noms de fichiers
            $fileNames = @(
                "Analyze-Scripts.ps1",
                "Organize-Scripts.ps1",
                "Show-ScriptInventory.ps1",
                "Generate-Documentation.ps1",
                "Monitor-Scripts.ps1",
                "Optimize-Scripts.ps1",
                "Test-Scripts.ps1",
                "Update-Configuration.ps1",
                "Generate-Script.ps1",
                "Integrate-Tools.ps1",
                "Update-UI.ps1",
                "ScriptManager.ps1"
            )
            
            foreach ($fileName in $fileNames) {
                Get-ScriptCategory -FileName $fileName | Out-Null
            }
        }
    },
    @{
        Name = "Backup-File"
        ScriptBlock = {
            # CrÃ©er un fichier temporaire
            $tempFile = [System.IO.Path]::GetTempFileName()
            "Test content" | Out-File -FilePath $tempFile -Encoding utf8
            
            # CrÃ©er une sauvegarde
            Backup-File -FilePath $tempFile | Out-Null
            
            # Supprimer les fichiers
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$tempFile.bak" -Force -ErrorAction SilentlyContinue
        }
    }
)

# ExÃ©cuter les tests de performance
$performanceResults = @()
foreach ($test in $performanceTests) {
    $result = Measure-FunctionPerformance -Name $test.Name -ScriptBlock $test.ScriptBlock -Iterations $Iterations
    $performanceResults += $result
    
    Write-Log "RÃ©sultats pour la fonction '$($result.Name)':" -Level "INFO"
    Write-Log "  Temps d'exÃ©cution moyen: $([math]::Round($result.AverageExecutionTime, 2)) ms" -Level "INFO"
    Write-Log "  Utilisation mÃ©moire moyenne: $([math]::Round($result.AverageMemoryUsage, 2)) KB" -Level "INFO"
    Write-Log "  Taux de rÃ©ussite: $([math]::Round($result.SuccessRate, 2))%" -Level "INFO"
}

# Exporter les rÃ©sultats au format JSON
$jsonPath = Join-Path -Path $OutputPath -ChildPath "PerformanceResults.json"
$performanceResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
Write-Log "RÃ©sultats exportÃ©s au format JSON: $jsonPath" -Level "SUCCESS"

# Exporter les rÃ©sultats au format CSV
$csvPath = Join-Path -Path $OutputPath -ChildPath "PerformanceResults.csv"
$performanceResults | Select-Object Name, Iterations, AverageExecutionTime, MinExecutionTime, MaxExecutionTime, AverageMemoryUsage, MinMemoryUsage, MaxMemoryUsage, SuccessRate | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
Write-Log "RÃ©sultats exportÃ©s au format CSV: $csvPath" -Level "SUCCESS"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "PerformanceResults.html"
    
    # CrÃ©er un rapport HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performance du script manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .chart-container { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de performance du script manager</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <table>
            <tr>
                <th>Fonction</th>
                <th>ItÃ©rations</th>
                <th>Temps d'exÃ©cution moyen (ms)</th>
                <th>Utilisation mÃ©moire moyenne (KB)</th>
                <th>Taux de rÃ©ussite (%)</th>
            </tr>
"@

    foreach ($result in $performanceResults) {
        $htmlContent += @"
            <tr>
                <td>$($result.Name)</td>
                <td>$($result.Iterations)</td>
                <td>$([math]::Round($result.AverageExecutionTime, 2))</td>
                <td>$([math]::Round($result.AverageMemoryUsage, 2))</td>
                <td>$([math]::Round($result.SuccessRate, 2))</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <h2>Graphiques</h2>
    
    <div class="chart-container">
        <canvas id="executionTimeChart"></canvas>
    </div>
    
    <div class="chart-container">
        <canvas id="memoryUsageChart"></canvas>
    </div>
    
    <h2>DÃ©tails</h2>
"@

    foreach ($result in $performanceResults) {
        $htmlContent += @"
    <h3>$($result.Name)</h3>
    <table>
        <tr>
            <th>ItÃ©ration</th>
            <th>Temps d'exÃ©cution (ms)</th>
            <th>Utilisation mÃ©moire (KB)</th>
            <th>RÃ©ussite</th>
        </tr>
"@

        foreach ($iteration in $result.Results) {
            $htmlContent += @"
        <tr>
            <td>$($iteration.Iteration)</td>
            <td>$([math]::Round($iteration.ExecutionTimeMs, 2))</td>
            <td>$($iteration.MemoryUsageKB)</td>
            <td>$($iteration.Success)</td>
        </tr>
"@
        }

        $htmlContent += @"
    </table>
"@
    }

    $htmlContent += @"
    
    <script>
        // DonnÃ©es pour les graphiques
        const functions = [$(($performanceResults | ForEach-Object { "'$($_.Name)'" }) -join ", ")];
        const executionTimes = [$(($performanceResults | ForEach-Object { $_.AverageExecutionTime }) -join ", ")];
        const memoryUsages = [$(($performanceResults | ForEach-Object { $_.AverageMemoryUsage }) -join ", ")];
        
        // Graphique des temps d'exÃ©cution
        const executionTimeCtx = document.getElementById('executionTimeChart').getContext('2d');
        new Chart(executionTimeCtx, {
            type: 'bar',
            data: {
                labels: functions,
                datasets: [{
                    label: 'Temps d\'exÃ©cution moyen (ms)',
                    data: executionTimes,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Temps d\'exÃ©cution moyen par fonction'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Temps (ms)'
                        }
                    }
                }
            }
        });
        
        // Graphique de l'utilisation mÃ©moire
        const memoryUsageCtx = document.getElementById('memoryUsageChart').getContext('2d');
        new Chart(memoryUsageCtx, {
            type: 'bar',
            data: {
                labels: functions,
                datasets: [{
                    label: 'Utilisation mÃ©moire moyenne (KB)',
                    data: memoryUsages,
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Utilisation mÃ©moire moyenne par fonction'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'MÃ©moire (KB)'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

Write-Log "Tests de performance terminÃ©s." -Level "SUCCESS"
