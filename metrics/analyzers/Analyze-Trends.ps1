#!/usr/bin/env pwsh
# Metrics Trend Analyzer
# Analyse les tendances et prédit les problèmes

param(
    [Parameter(Mandatory = $false)]
    [string]$MetricsPath = "$PSScriptRoot/../data/performance",
    
    [Parameter(Mandatory = $false)]
    [int]$DaysToAnalyze = 7,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "$PSScriptRoot/../dashboards/trend-analysis.html"
)

function Analyze-MetricsTrends {
    param([string]$Path, [int]$Days)
    
    Write-Host "📈 Analyse des tendances sur $Days jours..." -ForegroundColor Cyan
    
    # Récupérer les fichiers de métriques
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $metricFiles = Get-ChildItem -Path $Path -Filter "metrics_*.json" | 
                   Where-Object { $_.CreationTime -gt $cutoffDate } |
                   Sort-Object CreationTime
    
    if ($metricFiles.Count -eq 0) {
        Write-Warning "Aucun fichier de métriques trouvé"
        return
    }
    
    # Analyser les données
    $analysis = @{
        Period = "$Days jours"
        TotalSamples = $metricFiles.Count
        Trends = @{}
        Predictions = @{}
        Recommendations = @()
    }
    
    $allMetrics = @()
    foreach ($file in $metricFiles) {
        try {
            $content = Get-Content $file.FullName | ConvertFrom-Json
            $allMetrics += $content
        } catch {
            Write-Warning "Erreur lecture fichier: $($file.Name)"
        }
    }
    
    if ($allMetrics.Count -eq 0) {
        Write-Warning "Aucune métrique valide trouvée"
        return
    }
    
    # Analyser CPU
    $cpuValues = $allMetrics | Where-Object { $_.System.CPU } | ForEach-Object { $_.System.CPU.Usage }
    if ($cpuValues.Count -gt 0) {
        $analysis.Trends.CPU = @{
            Average = [math]::Round(($cpuValues | Measure-Object -Average).Average, 2)
            Max = ($cpuValues | Measure-Object -Maximum).Maximum
            Min = ($cpuValues | Measure-Object -Minimum).Minimum
            Trend = if ($cpuValues[-1] -gt $cpuValues[0]) { "Increasing" } else { "Decreasing" }
        }
        
        # Prédiction simple (tendance linéaire)
        if ($cpuValues.Count -gt 5) {
            $trend = Calculate-LinearTrend -Values $cpuValues
            $predicted = $cpuValues[-1] + ($trend * 24)  # Prédiction 24h
            $analysis.Predictions.CPU = @{
                Next24h = [math]::Round($predicted, 2)
                Confidence = if ($trend -gt 5) { "Faible" } elseif ($trend -gt 2) { "Moyenne" } else { "Élevée" }
            }
            
            if ($predicted -gt 80) {
                $analysis.Recommendations += "🚨 CPU risque de dépasser 80% dans 24h - Optimiser les processus"
            }
        }
    }
    
    # Analyser Memory
    $memValues = $allMetrics | Where-Object { $_.System.Memory } | ForEach-Object { $_.System.Memory.Usage }
    if ($memValues.Count -gt 0) {
        $analysis.Trends.Memory = @{
            Average = [math]::Round(($memValues | Measure-Object -Average).Average, 2)
            Max = ($memValues | Measure-Object -Maximum).Maximum
            Min = ($memValues | Measure-Object -Minimum).Minimum
            Trend = if ($memValues[-1] -gt $memValues[0]) { "Increasing" } else { "Decreasing" }
        }
    }
    
    # Analyser métriques custom
    $queueLengths = $allMetrics | Where-Object { $_.Custom.EmailSender } | ForEach-Object { $_.Custom.EmailSender.QueueLength }
    if ($queueLengths.Count -gt 0) {
        $analysis.Trends.EmailQueue = @{
            Average = [math]::Round(($queueLengths | Measure-Object -Average).Average, 2)
            Max = ($queueLengths | Measure-Object -Maximum).Maximum
            Trend = if ($queueLengths[-1] -gt $queueLengths[0]) { "Increasing" } else { "Decreasing" }
        }
        
        if ($analysis.Trends.EmailQueue.Average -gt 50) {
            $analysis.Recommendations += "📧 Queue d'emails élevée - Augmenter la capacité de traitement"
        }
    }
    
    return $analysis
}

function Calculate-LinearTrend {
    param([array]$Values)
    
    if ($Values.Count -lt 2) { return 0 }
    
    $n = $Values.Count
    $sumX = ($n * ($n + 1)) / 2
    $sumY = ($Values | Measure-Object -Sum).Sum
    $sumXY = 0
    $sumX2 = 0
    
    for ($i = 0; $i -lt $n; $i++) {
        $x = $i + 1
        $y = $Values[$i]
        $sumXY += $x * $y
        $sumX2 += $x * $x
    }
    
    $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - $sumX * $sumX)
    return $slope
}

function New-TrendReport {
    param([hashtable]$Analysis, [string]$OutputPath)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Analyse des Tendances - Email Sender 1</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
        h1 { color: #2c3e50; text-align: center; }
        .metric-card { background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .trend-up { color: #e74c3c; }
        .trend-down { color: #27ae60; }
        .recommendation { background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; margin: 5px 0; border-radius: 5px; }
        .stats { display: flex; gap: 20px; }
        .stat { flex: 1; text-align: center; }
        .stat-value { font-size: 2em; font-weight: bold; color: #3498db; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📈 Analyse des Tendances</h1>
        <p><strong>Période:</strong> $($Analysis.Period)</p>
        <p><strong>Échantillons:</strong> $($Analysis.TotalSamples)</p>
        <p><strong>Généré le:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <h2>🖥️ Métriques Système</h2>
"@

    if ($Analysis.Trends.CPU) {
        $trendClass = if ($Analysis.Trends.CPU.Trend -eq "Increasing") { "trend-up" } else { "trend-down" }
        $html += @"
        <div class="metric-card">
            <h3>CPU Usage</h3>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.CPU.Average)%</div>
                    <div>Moyenne</div>
                </div>
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.CPU.Max)%</div>
                    <div>Maximum</div>
                </div>
                <div class="stat">
                    <div class="stat-value $trendClass">$($Analysis.Trends.CPU.Trend)</div>
                    <div>Tendance</div>
                </div>
            </div>
        </div>
"@
    }

    if ($Analysis.Trends.Memory) {
        $trendClass = if ($Analysis.Trends.Memory.Trend -eq "Increasing") { "trend-up" } else { "trend-down" }
        $html += @"
        <div class="metric-card">
            <h3>Memory Usage</h3>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.Memory.Average)%</div>
                    <div>Moyenne</div>
                </div>
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.Memory.Max)%</div>
                    <div>Maximum</div>
                </div>
                <div class="stat">
                    <div class="stat-value $trendClass">$($Analysis.Trends.Memory.Trend)</div>
                    <div>Tendance</div>
                </div>
            </div>
        </div>
"@
    }

    $html += @"
        <h2>📧 Métriques Application</h2>
"@

    if ($Analysis.Trends.EmailQueue) {
        $trendClass = if ($Analysis.Trends.EmailQueue.Trend -eq "Increasing") { "trend-up" } else { "trend-down" }
        $html += @"
        <div class="metric-card">
            <h3>Email Queue</h3>
            <div class="stats">
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.EmailQueue.Average)</div>
                    <div>Moyenne</div>
                </div>
                <div class="stat">
                    <div class="stat-value">$($Analysis.Trends.EmailQueue.Max)</div>
                    <div>Maximum</div>
                </div>
                <div class="stat">
                    <div class="stat-value $trendClass">$($Analysis.Trends.EmailQueue.Trend)</div>
                    <div>Tendance</div>
                </div>
            </div>
        </div>
"@
    }

    if ($Analysis.Predictions.CPU) {
        $html += @"
        <h2>🔮 Prédictions</h2>
        <div class="metric-card">
            <h3>CPU dans 24h</h3>
            <p><strong>Prédiction:</strong> $($Analysis.Predictions.CPU.Next24h)%</p>
            <p><strong>Confiance:</strong> $($Analysis.Predictions.CPU.Confidence)</p>
        </div>
"@
    }

    if ($Analysis.Recommendations.Count -gt 0) {
        $html += @"
        <h2>💡 Recommandations</h2>
"@
        foreach ($rec in $Analysis.Recommendations) {
            $html += @"
        <div class="recommendation">$rec</div>
"@
        }
    }

    $html += @"
    </div>
</body>
</html>
"@

    if (-not (Test-Path (Split-Path $OutputPath))) {
        New-Item -Path (Split-Path $OutputPath) -ItemType Directory -Force | Out-Null
    }
    
    Set-Content -Path $OutputPath -Value $html
    Write-Host "📊 Rapport généré: $OutputPath" -ForegroundColor Green
}

# Exécution principale
$analysis = Analyze-MetricsTrends -Path $MetricsPath -Days $DaysToAnalyze
if ($analysis) {
    New-TrendReport -Analysis $analysis -OutputPath $ReportPath
    Write-Host "✅ Analyse terminée" -ForegroundColor Green
}
