<#
.SYNOPSIS
    Détecte les goulots d'étranglement dans les processus parallèles.
.DESCRIPTION
    Ce script analyse les données d'utilisation pour détecter les goulots d'étranglement
    dans les processus parallèles, en se concentrant sur:
    - Les scripts qui ralentissent fréquemment
    - Les contentions de ressources
    - Les problèmes de synchronisation
.EXAMPLE
    .\Detect-Bottlenecks.ps1 -DetailedAnalysis
.NOTES
    Version: 1.0
    Date: 15/05/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = "",

    [Parameter(Mandatory = $false)]
    [switch]$DetailedAnalysis,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports\bottlenecks"
)

# Importer le module UsageMonitor existant
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\UsageMonitor\UsageMonitor.psm1"
if (Test-Path -Path $usageMonitorPath) {
    Import-Module $usageMonitorPath -Force
} else {
    Write-Error "Module UsageMonitor non trouvé: $usageMonitorPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
        "TITLE"   = "Cyan"
    }

    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"

    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour vérifier si un script utilise la parallélisation
function Test-ScriptUsesParallelization {
    param (
        [string]$ScriptPath
    )

    if (-not (Test-Path -Path $ScriptPath)) {
        return $false
    }

    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop

        # Vérifier les patterns de parallélisation courants
        $parallelPatterns = @(
            'Invoke-Parallel',
            'Start-ThreadJob',
            'ForEach-Object -Parallel',
            'Invoke-OptimizedParallel',
            'RunspacePool',
            'System.Threading',
            'Parallel\s+processing',
            'MaxThreads',
            'MaxConcurrency',
            'ThreadPool',
            'Runspace',
            'BeginInvoke',
            'WaitHandle'
        )

        foreach ($pattern in $parallelPatterns) {
            if ($content -match $pattern) {
                return $true
            }
        }

        return $false
    } catch {
        Write-Warning "Erreur lors de la vérification de la parallélisation pour $ScriptPath : $_"
        return $false
    }
}

# Fonction pour analyser en détail un goulot d'étranglement parallèle
function Analyze-ParallelBottleneck {
    param (
        [string]$ScriptPath,
        [PSCustomObject]$Bottleneck
    )

    $analysis = @{
        ParallelizationType = "Inconnue"
        ProbableCause       = "Indéterminé"
        Recommendation      = "Analyse manuelle requise"
    }

    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop

        # Déterminer le type de parallélisation
        if ($content -match 'ForEach-Object\s+-Parallel') {
            $analysis.ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
        } elseif ($content -match 'RunspacePool') {
            $analysis.ParallelizationType = "RunspacePool"
        } elseif ($content -match 'Start-ThreadJob') {
            $analysis.ParallelizationType = "ThreadJob"
        } elseif ($content -match 'Invoke-Parallel') {
            $analysis.ParallelizationType = "Invoke-Parallel (Module PoshRSJob)"
        } elseif ($content -match 'Invoke-OptimizedParallel') {
            $analysis.ParallelizationType = "Invoke-OptimizedParallel (Module personnalisé)"
        }

        # Analyser les exécutions lentes pour détecter des patterns
        $slowExecutions = $Bottleneck.SlowExecutions

        if ($slowExecutions.Count -gt 0) {
            # Vérifier si les ralentissements sont liés à la taille des données
            $largeDataCount = 0
            foreach ($execution in $slowExecutions) {
                if ($execution.Parameters -and ($execution.Parameters.Count -gt 0)) {
                    foreach ($param in $execution.Parameters.GetEnumerator()) {
                        if ($param.Value -is [array] -and $param.Value.Count -gt 1000) {
                            $largeDataCount++
                            break
                        }
                    }
                }
            }

            if ($largeDataCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Traitement de grands volumes de données"
                $analysis.Recommendation = "Optimiser la taille des lots (batch size) et implémenter un partitionnement plus efficace"
            }

            # Vérifier si les ralentissements sont liés à la contention des ressources
            $highCpuCount = 0
            $highMemoryCount = 0

            foreach ($execution in $slowExecutions) {
                if ($execution.ResourceUsage) {
                    if ($execution.ResourceUsage.CpuUsageEnd -gt 90) {
                        $highCpuCount++
                    }

                    if ($execution.ResourceUsage.MemoryUsageEnd -gt 1024 * 1024 * 1024) {
                        # > 1 GB
                        $highMemoryCount++
                    }
                }
            }

            if ($highCpuCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Saturation du CPU"
                $analysis.Recommendation = "Réduire le nombre de threads parallèles et optimiser les opérations intensives en CPU"
            } elseif ($highMemoryCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Consommation excessive de mémoire"
                $analysis.Recommendation = "Optimiser l'utilisation de la mémoire, libérer les ressources non utilisées et traiter les données par lots plus petits"
            }

            # Vérifier si les ralentissements sont liés à des opérations d'E/S
            if ($content -match '(Get-Content|Set-Content|Add-Content|Out-File|Import-Csv|Export-Csv|Copy-Item|Move-Item)') {
                $analysis.ProbableCause = "Opérations d'E/S intensives"
                $analysis.Recommendation = "Optimiser les opérations de fichier, utiliser des buffers plus grands, et considérer des techniques comme la mise en cache ou la lecture/écriture asynchrone"
            }

            # Vérifier si les ralentissements sont liés à des problèmes de synchronisation
            if ($content -match '(lock|Mutex|Semaphore|Monitor|SyncRoot|SemaphoreSlim|ReaderWriterLockSlim)') {
                $analysis.ProbableCause = "Contention de synchronisation"
                $analysis.Recommendation = "Réduire la granularité des verrous, utiliser des structures de données thread-safe, et minimiser les sections critiques"
            }
        }
    } catch {
        Write-Warning "Erreur lors de l'analyse détaillée pour $ScriptPath : $_"
    }

    return $analysis
}

# Fonction pour détecter les goulots d'étranglement dans les processus parallèles
function Find-ParallelProcessBottlenecks {
    [CmdletBinding()]
    param (
        [switch]$DetailedAnalysis
    )

    Write-Log "Détection des goulots d'étranglement dans les processus parallèles..." -Level "TITLE"

    # Utiliser la fonction existante pour trouver les goulots d'étranglement
    $bottlenecks = Find-ScriptBottlenecks

    # Filtrer pour ne garder que les scripts qui utilisent la parallélisation
    $parallelBottlenecks = @()

    foreach ($bottleneck in $bottlenecks) {
        $scriptPath = $bottleneck.ScriptPath

        # Vérifier si le script utilise des fonctionnalités de parallélisation
        $isParallel = Test-ScriptUsesParallelization -ScriptPath $scriptPath

        if ($isParallel) {
            $bottleneck | Add-Member -MemberType NoteProperty -Name "IsParallel" -Value $true
            $parallelBottlenecks += $bottleneck

            # Analyse détaillée si demandée
            if ($DetailedAnalysis) {
                $detailedInfo = Get-ParallelBottleneckAnalysis -ScriptPath $scriptPath -Bottleneck $bottleneck
                $bottleneck | Add-Member -MemberType NoteProperty -Name "DetailedAnalysis" -Value $detailedInfo
            }
        }
    }

    if ($parallelBottlenecks.Count -gt 0) {
        Write-Log "Goulots d'étranglement détectés dans les processus parallèles:" -Level "WARNING"
        foreach ($bottleneck in $parallelBottlenecks) {
            Write-Log "  - Script: $($bottleneck.ScriptName)" -Level "WARNING"
            Write-Log "    * Durée moyenne: $([math]::Round($bottleneck.AverageDuration, 2)) ms" -Level "INFO"
            Write-Log "    * Seuil de lenteur: $([math]::Round($bottleneck.SlowThreshold, 2)) ms" -Level "INFO"
            Write-Log "    * Exécutions lentes: $($bottleneck.SlowExecutionsCount)/$($bottleneck.TotalExecutionsCount) ($([math]::Round($bottleneck.SlowExecutionPercentage, 2))%)" -Level "INFO"

            if ($DetailedAnalysis -and $bottleneck.DetailedAnalysis) {
                Write-Log "    * Analyse détaillée:" -Level "INFO"
                Write-Log "      - Type de parallélisation: $($bottleneck.DetailedAnalysis.ParallelizationType)" -Level "INFO"
                Write-Log "      - Problème probable: $($bottleneck.DetailedAnalysis.ProbableCause)" -Level "INFO"
                Write-Log "      - Recommandation: $($bottleneck.DetailedAnalysis.Recommendation)" -Level "INFO"
            }
        }
    } else {
        Write-Log "Aucun goulot d'étranglement détecté dans les processus parallèles." -Level "SUCCESS"
    }

    return $parallelBottlenecks
}



# Fonction pour analyser en détail un goulot d'étranglement parallèle
function Get-ParallelBottleneckAnalysis {
    param (
        [string]$ScriptPath,
        [PSCustomObject]$Bottleneck
    )

    $analysis = @{
        ParallelizationType = "Inconnue"
        ProbableCause       = "Indéterminé"
        Recommendation      = "Analyse manuelle requise"
    }

    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop

        # Déterminer le type de parallélisation
        if ($content -match 'ForEach-Object\s+-Parallel') {
            $analysis.ParallelizationType = "ForEach-Object -Parallel (PowerShell 7+)"
        } elseif ($content -match 'RunspacePool') {
            $analysis.ParallelizationType = "RunspacePool"
        } elseif ($content -match 'Start-ThreadJob') {
            $analysis.ParallelizationType = "ThreadJob"
        } elseif ($content -match 'Invoke-Parallel') {
            $analysis.ParallelizationType = "Invoke-Parallel (Module PoshRSJob)"
        } elseif ($content -match 'Invoke-OptimizedParallel') {
            $analysis.ParallelizationType = "Invoke-OptimizedParallel (Module personnalisé)"
        }

        # Analyser les exécutions lentes pour détecter des patterns
        $slowExecutions = $Bottleneck.SlowExecutions

        if ($slowExecutions.Count -gt 0) {
            # Vérifier si les ralentissements sont liés à la taille des données
            $largeDataCount = 0
            foreach ($execution in $slowExecutions) {
                if ($execution.Parameters -and ($execution.Parameters.Count -gt 0)) {
                    foreach ($param in $execution.Parameters.GetEnumerator()) {
                        if ($param.Value -is [array] -and $param.Value.Count -gt 1000) {
                            $largeDataCount++
                            break
                        }
                    }
                }
            }

            if ($largeDataCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Traitement de grands volumes de données"
                $analysis.Recommendation = "Optimiser la taille des lots (batch size) et implémenter un partitionnement plus efficace"
            }

            # Vérifier si les ralentissements sont liés à la contention des ressources
            $highCpuCount = 0
            $highMemoryCount = 0

            foreach ($execution in $slowExecutions) {
                if ($execution.ResourceUsage) {
                    if ($execution.ResourceUsage.CpuUsageEnd -gt 90) {
                        $highCpuCount++
                    }

                    if ($execution.ResourceUsage.MemoryUsageEnd -gt 1024 * 1024 * 1024) {
                        # > 1 GB
                        $highMemoryCount++
                    }
                }
            }

            if ($highCpuCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Saturation du CPU"
                $analysis.Recommendation = "Réduire le nombre de threads parallèles et optimiser les opérations intensives en CPU"
            } elseif ($highMemoryCount -gt ($slowExecutions.Count * 0.5)) {
                $analysis.ProbableCause = "Consommation excessive de mémoire"
                $analysis.Recommendation = "Optimiser l'utilisation de la mémoire, libérer les ressources non utilisées et traiter les données par lots plus petits"
            }

            # Vérifier si les ralentissements sont liés à des opérations d'E/S
            if ($content -match '(Get-Content|Set-Content|Add-Content|Out-File|Import-Csv|Export-Csv|Copy-Item|Move-Item)') {
                $analysis.ProbableCause = "Opérations d'E/S intensives"
                $analysis.Recommendation = "Optimiser les opérations de fichier, utiliser des buffers plus grands, et considérer des techniques comme la mise en cache ou la lecture/écriture asynchrone"
            }

            # Vérifier si les ralentissements sont liés à des problèmes de synchronisation
            if ($content -match '(lock|Mutex|Semaphore|Monitor|SyncRoot|SemaphoreSlim|ReaderWriterLockSlim)') {
                $analysis.ProbableCause = "Contention de synchronisation"
                $analysis.Recommendation = "Réduire la granularité des verrous, utiliser des structures de données thread-safe, et minimiser les sections critiques"
            }
        }
    } catch {
        Write-Warning "Erreur lors de l'analyse détaillée pour $ScriptPath : $_"
    }

    return $analysis
}

# Fonction pour générer un rapport HTML
function New-BottleneckReport {
    param (
        [array]$Bottlenecks,
        [string]$OutputPath
    )

    Write-Log "Génération du rapport de goulots d'étranglement..." -Level "TITLE"

    # Créer le dossier de sortie s'il n'existe pas
    $reportDir = Join-Path -Path $PSScriptRoot -ChildPath $OutputPath
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $reportFile = Join-Path -Path $reportDir -ChildPath "bottleneck_report_$(Get-Date -Format 'yyyy-MM-dd').html"

    # Générer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des goulots d'étranglement dans les processus parallèles</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .warning {
            color: #e67e22;
        }
        .error {
            color: #e74c3c;
        }
        .success {
            color: #2ecc71;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .details {
            background-color: #f9f9f9;
            padding: 15px;
            border-left: 4px solid #3498db;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport des goulots d'étranglement dans les processus parallèles</h1>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>

        <h2>Résumé</h2>
"@

    if ($Bottlenecks.Count -gt 0) {
        $htmlContent += "<p>$($Bottlenecks.Count) goulots d'étranglement détectés dans les processus parallèles.</p>"

        $htmlContent += @"
        <table>
            <tr>
                <th>Script</th>
                <th>Durée moyenne (ms)</th>
                <th>Seuil de lenteur (ms)</th>
                <th>Exécutions lentes</th>
                <th>Pourcentage</th>
            </tr>
"@

        foreach ($bottleneck in $Bottlenecks) {
            $scriptName = $bottleneck.ScriptName
            $avgDuration = [math]::Round($bottleneck.AverageDuration, 2)
            $threshold = [math]::Round($bottleneck.SlowThreshold, 2)
            $slowCount = "$($bottleneck.SlowExecutionsCount)/$($bottleneck.TotalExecutionsCount)"
            $percentage = [math]::Round($bottleneck.SlowExecutionPercentage, 2)
            $cssClass = if ($percentage -gt 50) { "error" } elseif ($percentage -gt 25) { "warning" } else { "" }

            $htmlContent += @"
            <tr>
                <td>$scriptName</td>
                <td>$avgDuration</td>
                <td>$threshold</td>
                <td>$slowCount</td>
                <td class="$cssClass">$percentage%</td>
            </tr>
"@
        }

        $htmlContent += "</table>"

        $htmlContent += "<h2>Analyse détaillée</h2>"

        foreach ($bottleneck in $Bottlenecks) {
            $scriptName = $bottleneck.ScriptName
            $scriptPath = $bottleneck.ScriptPath

            $htmlContent += @"
            <h3>$scriptName</h3>
            <p>Chemin: $scriptPath</p>
"@

            if ($bottleneck.DetailedAnalysis) {
                $htmlContent += @"
                <div class="details">
                    <p><strong>Type de parallélisation:</strong> $($bottleneck.DetailedAnalysis.ParallelizationType)</p>
                    <p><strong>Problème probable:</strong> $($bottleneck.DetailedAnalysis.ProbableCause)</p>
                    <p><strong>Recommandation:</strong> $($bottleneck.DetailedAnalysis.Recommendation)</p>
                </div>
"@
            }

            $htmlContent += "<h4>Exécutions lentes</h4>"

            if ($bottleneck.SlowExecutions.Count -gt 0) {
                $htmlContent += @"
                <table>
                    <tr>
                        <th>Date</th>
                        <th>Durée (ms)</th>
                        <th>Paramètres</th>
                        <th>CPU (%)</th>
                        <th>Mémoire (MB)</th>
                    </tr>
"@

                foreach ($execution in $bottleneck.SlowExecutions | Select-Object -First 10) {
                    $date = $execution.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                    $duration = [math]::Round($execution.Duration.TotalMilliseconds, 2)

                    $parameters = "N/A"
                    if ($execution.Parameters -and ($execution.Parameters.Count -gt 0)) {
                        $parameters = ($execution.Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
                    }

                    $cpuUsage = "N/A"
                    $memoryUsage = "N/A"

                    if ($execution.ResourceUsage) {
                        if ($execution.ResourceUsage.CpuUsageStart -and $execution.ResourceUsage.CpuUsageEnd) {
                            $cpuDiff = $execution.ResourceUsage.CpuUsageEnd - $execution.ResourceUsage.CpuUsageStart
                            $cpuUsage = [math]::Round($cpuDiff, 2)
                        }

                        if ($execution.ResourceUsage.MemoryUsageStart -and $execution.ResourceUsage.MemoryUsageEnd) {
                            $memoryDiff = ($execution.ResourceUsage.MemoryUsageEnd - $execution.ResourceUsage.MemoryUsageStart) / 1MB
                            $memoryUsage = [math]::Round($memoryDiff, 2)
                        }
                    }

                    $htmlContent += @"
                    <tr>
                        <td>$date</td>
                        <td>$duration</td>
                        <td>$parameters</td>
                        <td>$cpuUsage</td>
                        <td>$memoryUsage</td>
                    </tr>
"@
                }

                $htmlContent += "</table>"

                if ($bottleneck.SlowExecutions.Count -gt 10) {
                    $htmlContent += "<p><em>Affichage limité aux 10 premières exécutions lentes sur un total de $($bottleneck.SlowExecutions.Count).</em></p>"
                }
            } else {
                $htmlContent += "<p>Aucune information détaillée disponible sur les exécutions lentes.</p>"
            }
        }
    } else {
        $htmlContent += "<p class='success'>Aucun goulot d'étranglement détecté dans les processus parallèles.</p>"
    }

    $htmlContent += @"
        <div class="footer">
            <p>Rapport généré par le système de détection des goulots d'étranglement</p>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $reportFile -Encoding utf8 -Force

    Write-Log "Rapport généré avec succès: $reportFile" -Level "SUCCESS"

    return $reportFile
}

# Point d'entrée principal
try {
    # Initialiser le moniteur d'utilisation
    if ([string]::IsNullOrEmpty($DatabasePath)) {
        $DatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "usage_data.xml"
    }

    Initialize-UsageMonitor -DatabasePath $DatabasePath
    Write-Log "Moniteur d'utilisation initialisé avec la base de données: $DatabasePath" -Level "SUCCESS"

    # Détecter les goulots d'étranglement dans les processus parallèles
    $bottlenecks = Find-ParallelProcessBottlenecks -DetailedAnalysis:$DetailedAnalysis

    # Générer un rapport si demandé
    if ($GenerateReport) {
        $reportFile = New-BottleneckReport -Bottlenecks $bottlenecks -OutputPath $ReportPath

        # Ouvrir le rapport dans le navigateur par défaut
        if (Test-Path -Path $reportFile) {
            Start-Process $reportFile
        }
    }
} catch {
    Write-Log "Erreur lors de l'exécution du script: $_" -Level "ERROR"
    exit 1
}
