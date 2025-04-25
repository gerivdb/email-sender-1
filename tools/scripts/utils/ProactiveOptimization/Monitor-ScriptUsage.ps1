<#
.SYNOPSIS
    Système de monitoring et d'analyse comportementale des scripts.
.DESCRIPTION
    Ce script implémente un système avancé de monitoring qui:
    - Enregistre l'utilisation des scripts (fréquence, durée, succès/échec, ressources)
    - Analyse les logs pour identifier les scripts les plus utilisés, lents ou problématiques
    - Détecte les goulots d'étranglement dans les processus parallèles
.EXAMPLE
    .\Monitor-ScriptUsage.ps1 -EnableRealTimeMonitoring
.NOTES
    Version: 1.0
    Date: 15/05/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableRealTimeMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports\usage",
    
    [Parameter(Mandatory = $false)]
    [int]$AnalysisPeriodDays = 30
)

# Importer le module UsageMonitor existant
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\UsageMonitor\UsageMonitor.psm1"
if (Test-Path -Path $usageMonitorPath) {
    Import-Module $usageMonitorPath -Force
}
else {
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
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour analyser les logs d'utilisation
function Analyze-UsageLogs {
    [CmdletBinding()]
    param (
        [int]$PeriodDays = 30,
        [int]$TopCount = 10
    )
    
    Write-Log "Analyse des logs d'utilisation sur les $PeriodDays derniers jours..." -Level "TITLE"
    
    # Obtenir les statistiques d'utilisation
    $usageStats = Get-ScriptUsageStatistics -TopCount $TopCount
    
    # Afficher les scripts les plus utilisés
    Write-Log "Scripts les plus utilisés:" -Level "INFO"
    $usageStats.TopUsedScripts.GetEnumerator() | ForEach-Object {
        Write-Log "  - $($_.Key): $($_.Value) exécutions" -Level "INFO"
    }
    
    # Afficher les scripts les plus lents
    Write-Log "Scripts les plus lents:" -Level "INFO"
    $usageStats.SlowestScripts.GetEnumerator() | ForEach-Object {
        Write-Log "  - $($_.Key): $([math]::Round($_.Value, 2)) ms en moyenne" -Level "INFO"
    }
    
    # Afficher les scripts échouant le plus souvent
    Write-Log "Scripts échouant le plus souvent:" -Level "INFO"
    $usageStats.MostFailingScripts.GetEnumerator() | ForEach-Object {
        Write-Log "  - $($_.Key): $([math]::Round($_.Value, 2))% d'échecs" -Level "INFO"
    }
    
    # Afficher les scripts consommant le plus de ressources
    Write-Log "Scripts consommant le plus de ressources:" -Level "INFO"
    $usageStats.ResourceIntensiveScripts.GetEnumerator() | ForEach-Object {
        Write-Log "  - $($_.Key): Score d'utilisation des ressources: $([math]::Round($_.Value, 2))" -Level "INFO"
    }
    
    return $usageStats
}

# Fonction pour détecter les goulots d'étranglement dans les processus parallèles
function Detect-ParallelBottlenecks {
    [CmdletBinding()]
    param ()
    
    Write-Log "Détection des goulots d'étranglement dans les processus parallèles..." -Level "TITLE"
    
    # Utiliser la fonction existante pour trouver les goulots d'étranglement
    $bottlenecks = Find-ScriptBottlenecks
    
    if ($bottlenecks.Count -gt 0) {
        Write-Log "Goulots d'étranglement détectés:" -Level "WARNING"
        foreach ($bottleneck in $bottlenecks) {
            Write-Log "  - Script: $($bottleneck.ScriptName)" -Level "WARNING"
            Write-Log "    * Durée moyenne: $([math]::Round($bottleneck.AverageDuration, 2)) ms" -Level "INFO"
            Write-Log "    * Seuil de lenteur: $([math]::Round($bottleneck.SlowThreshold, 2)) ms" -Level "INFO"
            Write-Log "    * Exécutions lentes: $($bottleneck.SlowExecutionsCount)/$($bottleneck.TotalExecutionsCount) ($([math]::Round($bottleneck.SlowExecutionPercentage, 2))%)" -Level "INFO"
            
            # Analyser les exécutions lentes pour détecter des patterns
            if ($bottleneck.SlowExecutions.Count -gt 0) {
                $patterns = Analyze-SlowExecutionPatterns -SlowExecutions $bottleneck.SlowExecutions
                if ($patterns.Count -gt 0) {
                    Write-Log "    * Patterns détectés:" -Level "INFO"
                    foreach ($pattern in $patterns.GetEnumerator()) {
                        Write-Log "      - $($pattern.Key): $($pattern.Value)" -Level "INFO"
                    }
                }
            }
        }
    }
    else {
        Write-Log "Aucun goulot d'étranglement détecté." -Level "SUCCESS"
    }
    
    return $bottlenecks
}

# Fonction pour analyser les patterns dans les exécutions lentes
function Analyze-SlowExecutionPatterns {
    param (
        [array]$SlowExecutions
    )
    
    $patterns = @{}
    
    # Analyser les paramètres communs
    $parameterCounts = @{}
    foreach ($execution in $SlowExecutions) {
        if ($execution.Parameters) {
            foreach ($param in $execution.Parameters.GetEnumerator()) {
                $key = "$($param.Key)=$($param.Value)"
                if (-not $parameterCounts.ContainsKey($key)) {
                    $parameterCounts[$key] = 0
                }
                $parameterCounts[$key]++
            }
        }
    }
    
    # Identifier les paramètres qui apparaissent fréquemment
    $threshold = $SlowExecutions.Count * 0.5  # 50% des exécutions lentes
    foreach ($param in $parameterCounts.GetEnumerator()) {
        if ($param.Value -ge $threshold) {
            $patterns["Paramètre fréquent"] = $param.Key
        }
    }
    
    # Analyser les heures d'exécution
    $hourCounts = @{}
    foreach ($execution in $SlowExecutions) {
        $hour = $execution.StartTime.Hour
        if (-not $hourCounts.ContainsKey($hour)) {
            $hourCounts[$hour] = 0
        }
        $hourCounts[$hour]++
    }
    
    # Identifier les heures problématiques
    $maxHourCount = 0
    $maxHour = 0
    foreach ($hour in $hourCounts.GetEnumerator()) {
        if ($hour.Value -gt $maxHourCount) {
            $maxHourCount = $hour.Value
            $maxHour = $hour.Key
        }
    }
    
    if ($maxHourCount -ge ($SlowExecutions.Count * 0.3)) {  # 30% des exécutions lentes
        $patterns["Heure problématique"] = "$maxHour:00 ($maxHourCount occurrences)"
    }
    
    # Analyser l'utilisation des ressources
    $highCpuCount = 0
    $highMemoryCount = 0
    foreach ($execution in $SlowExecutions) {
        if ($execution.ResourceUsage) {
            $cpuDiff = 0
            $memoryDiff = 0
            
            if ($execution.ResourceUsage.CpuUsageStart -and $execution.ResourceUsage.CpuUsageEnd) {
                $cpuDiff = $execution.ResourceUsage.CpuUsageEnd - $execution.ResourceUsage.CpuUsageStart
            }
            
            if ($execution.ResourceUsage.MemoryUsageStart -and $execution.ResourceUsage.MemoryUsageEnd) {
                $memoryDiff = $execution.ResourceUsage.MemoryUsageEnd - $execution.ResourceUsage.MemoryUsageStart
            }
            
            if ($cpuDiff -gt 50) {  # Augmentation de plus de 50% d'utilisation CPU
                $highCpuCount++
            }
            
            if ($memoryDiff -gt 100 * 1024 * 1024) {  # Augmentation de plus de 100 MB
                $highMemoryCount++
            }
        }
    }
    
    if ($highCpuCount -ge ($SlowExecutions.Count * 0.5)) {
        $patterns["Utilisation CPU élevée"] = "$highCpuCount occurrences"
    }
    
    if ($highMemoryCount -ge ($SlowExecutions.Count * 0.5)) {
        $patterns["Utilisation mémoire élevée"] = "$highMemoryCount occurrences"
    }
    
    return $patterns
}

# Fonction pour générer un rapport HTML
function Generate-UsageReport {
    param (
        [PSCustomObject]$UsageStats,
        [array]$Bottlenecks,
        [string]$OutputPath
    )
    
    Write-Log "Génération du rapport d'utilisation..." -Level "TITLE"
    
    # Créer le dossier de sortie s'il n'existe pas
    $reportDir = Join-Path -Path $PSScriptRoot -ChildPath $OutputPath
    if (-not (Test-Path -Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    $reportFile = Join-Path -Path $reportDir -ChildPath "usage_report_$(Get-Date -Format 'yyyy-MM-dd').html"
    
    # Générer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'utilisation des scripts</title>
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
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport d'utilisation des scripts</h1>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
        
        <h2>Résumé</h2>
        <p>Ce rapport présente l'analyse de l'utilisation des scripts sur les $AnalysisPeriodDays derniers jours.</p>
        
        <h2>Scripts les plus utilisés</h2>
        <div class="chart-container">
            <canvas id="usageChart"></canvas>
        </div>
        <table>
            <tr>
                <th>Script</th>
                <th>Nombre d'exécutions</th>
            </tr>
"@

    # Ajouter les scripts les plus utilisés
    foreach ($script in $UsageStats.TopUsedScripts.GetEnumerator()) {
        $scriptName = Split-Path -Path $script.Key -Leaf
        $htmlContent += @"
            <tr>
                <td>$scriptName</td>
                <td>$($script.Value)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h2>Scripts les plus lents</h2>
        <div class="chart-container">
            <canvas id="durationChart"></canvas>
        </div>
        <table>
            <tr>
                <th>Script</th>
                <th>Durée moyenne (ms)</th>
            </tr>
"@

    # Ajouter les scripts les plus lents
    foreach ($script in $UsageStats.SlowestScripts.GetEnumerator()) {
        $scriptName = Split-Path -Path $script.Key -Leaf
        $duration = [math]::Round($script.Value, 2)
        $htmlContent += @"
            <tr>
                <td>$scriptName</td>
                <td>$duration</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h2>Scripts échouant le plus souvent</h2>
        <div class="chart-container">
            <canvas id="failureChart"></canvas>
        </div>
        <table>
            <tr>
                <th>Script</th>
                <th>Taux d'échec (%)</th>
            </tr>
"@

    # Ajouter les scripts échouant le plus souvent
    foreach ($script in $UsageStats.MostFailingScripts.GetEnumerator()) {
        $scriptName = Split-Path -Path $script.Key -Leaf
        $failureRate = [math]::Round($script.Value, 2)
        $cssClass = if ($failureRate -gt 20) { "error" } elseif ($failureRate -gt 10) { "warning" } else { "" }
        $htmlContent += @"
            <tr>
                <td>$scriptName</td>
                <td class="$cssClass">$failureRate</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h2>Goulots d'étranglement détectés</h2>
"@

    if ($Bottlenecks.Count -gt 0) {
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
    }
    else {
        $htmlContent += "<p class='success'>Aucun goulot d'étranglement détecté.</p>"
    }

    # Ajouter les scripts JavaScript pour les graphiques
    $htmlContent += @"
        <script>
            // Données pour les graphiques
            const usageData = {
                labels: [$(($UsageStats.TopUsedScripts.GetEnumerator() | ForEach-Object { "'$(Split-Path -Path $_.Key -Leaf)'" }) -join ', ')],
                datasets: [{
                    label: 'Nombre d\'exécutions',
                    data: [$(($UsageStats.TopUsedScripts.GetEnumerator() | ForEach-Object { $_.Value }) -join ', ')],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            };
            
            const durationData = {
                labels: [$(($UsageStats.SlowestScripts.GetEnumerator() | ForEach-Object { "'$(Split-Path -Path $_.Key -Leaf)'" }) -join ', ')],
                datasets: [{
                    label: 'Durée moyenne (ms)',
                    data: [$(($UsageStats.SlowestScripts.GetEnumerator() | ForEach-Object { [math]::Round($_.Value, 2) }) -join ', ')],
                    backgroundColor: 'rgba(255, 159, 64, 0.5)',
                    borderColor: 'rgba(255, 159, 64, 1)',
                    borderWidth: 1
                }]
            };
            
            const failureData = {
                labels: [$(($UsageStats.MostFailingScripts.GetEnumerator() | ForEach-Object { "'$(Split-Path -Path $_.Key -Leaf)'" }) -join ', ')],
                datasets: [{
                    label: 'Taux d\'échec (%)',
                    data: [$(($UsageStats.MostFailingScripts.GetEnumerator() | ForEach-Object { [math]::Round($_.Value, 2) }) -join ', ')],
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }]
            };
            
            // Créer les graphiques
            window.onload = function() {
                const usageCtx = document.getElementById('usageChart').getContext('2d');
                new Chart(usageCtx, {
                    type: 'bar',
                    data: usageData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });
                
                const durationCtx = document.getElementById('durationChart').getContext('2d');
                new Chart(durationCtx, {
                    type: 'bar',
                    data: durationData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });
                
                const failureCtx = document.getElementById('failureChart').getContext('2d');
                new Chart(failureCtx, {
                    type: 'bar',
                    data: failureData,
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: 100
                            }
                        }
                    }
                });
            };
        </script>
        
        <div class="footer">
            <p>Rapport généré par le système de monitoring et d'analyse comportementale</p>
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

# Fonction pour démarrer le monitoring en temps réel
function Start-RealTimeMonitoring {
    [CmdletBinding()]
    param (
        [int]$RefreshIntervalSeconds = 60
    )
    
    Write-Log "Démarrage du monitoring en temps réel (intervalle: $RefreshIntervalSeconds secondes)..." -Level "TITLE"
    
    try {
        while ($true) {
            Clear-Host
            Write-Log "=== Monitoring en temps réel (Ctrl+C pour arrêter) ===" -Level "TITLE"
            Write-Log "Dernière mise à jour: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level "INFO"
            
            # Analyser les logs d'utilisation
            $usageStats = Get-ScriptUsageStatistics -TopCount 5
            
            # Afficher les scripts les plus utilisés
            Write-Log "Top 5 des scripts les plus utilisés:" -Level "INFO"
            $usageStats.TopUsedScripts.GetEnumerator() | ForEach-Object {
                Write-Log "  - $($_.Key): $($_.Value) exécutions" -Level "INFO"
            }
            
            # Afficher les scripts les plus lents
            Write-Log "Top 5 des scripts les plus lents:" -Level "INFO"
            $usageStats.SlowestScripts.GetEnumerator() | ForEach-Object {
                Write-Log "  - $($_.Key): $([math]::Round($_.Value, 2)) ms en moyenne" -Level "INFO"
            }
            
            # Afficher les scripts échouant le plus souvent
            Write-Log "Top 5 des scripts échouant le plus souvent:" -Level "INFO"
            $usageStats.MostFailingScripts.GetEnumerator() | ForEach-Object {
                Write-Log "  - $($_.Key): $([math]::Round($_.Value, 2))% d'échecs" -Level "INFO"
            }
            
            # Détecter les goulots d'étranglement
            $bottlenecks = Find-ScriptBottlenecks
            
            if ($bottlenecks.Count -gt 0) {
                Write-Log "Goulots d'étranglement détectés:" -Level "WARNING"
                foreach ($bottleneck in $bottlenecks) {
                    Write-Log "  - Script: $($bottleneck.ScriptName)" -Level "WARNING"
                    Write-Log "    * Durée moyenne: $([math]::Round($bottleneck.AverageDuration, 2)) ms" -Level "INFO"
                    Write-Log "    * Exécutions lentes: $($bottleneck.SlowExecutionsCount)/$($bottleneck.TotalExecutionsCount) ($([math]::Round($bottleneck.SlowExecutionPercentage, 2))%)" -Level "INFO"
                }
            }
            else {
                Write-Log "Aucun goulot d'étranglement détecté." -Level "SUCCESS"
            }
            
            # Attendre avant la prochaine mise à jour
            Write-Log "Prochaine mise à jour dans $RefreshIntervalSeconds secondes..." -Level "INFO"
            Start-Sleep -Seconds $RefreshIntervalSeconds
        }
    }
    catch {
        Write-Log "Monitoring en temps réel arrêté: $_" -Level "WARNING"
    }
}

# Point d'entrée principal
try {
    # Initialiser le moniteur d'utilisation
    if ([string]::IsNullOrEmpty($DatabasePath)) {
        $DatabasePath = Join-Path -Path $PSScriptRoot -ChildPath "usage_data.xml"
    }
    
    Initialize-UsageMonitor -DatabasePath $DatabasePath
    Write-Log "Moniteur d'utilisation initialisé avec la base de données: $DatabasePath" -Level "SUCCESS"
    
    # Analyser les logs d'utilisation
    $usageStats = Analyze-UsageLogs -PeriodDays $AnalysisPeriodDays
    
    # Détecter les goulots d'étranglement
    $bottlenecks = Detect-ParallelBottlenecks
    
    # Générer un rapport si demandé
    if ($GenerateReport) {
        $reportFile = Generate-UsageReport -UsageStats $usageStats -Bottlenecks $bottlenecks -OutputPath $ReportPath
        
        # Ouvrir le rapport dans le navigateur par défaut
        if (Test-Path -Path $reportFile) {
            Start-Process $reportFile
        }
    }
    
    # Démarrer le monitoring en temps réel si demandé
    if ($EnableRealTimeMonitoring) {
        Start-RealTimeMonitoring
    }
}
catch {
    Write-Log "Erreur lors de l'exécution du script: $_" -Level "ERROR"
    exit 1
}
