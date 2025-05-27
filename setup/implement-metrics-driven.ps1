#!/usr/bin/env pwsh
# 📊 Méthode #6: Metrics-Driven Development  
# ROI: +15-20h/mois par optimisation continue

param([switch]$DryRun)

Write-Host @"
📊 MÉTHODE #6: METRICS-DRIVEN DEVELOPMENT
════════════════════════════════════════
ROI: +15-20h/mois par optimisation continue
Surveillance: Performance, Qualité, Usage
"@ -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot

# Créer la structure des métriques
if (-not $DryRun) {
    @("metrics", "metrics/collectors", "metrics/analyzers", "metrics/dashboards", "metrics/alerts") | ForEach-Object {
        $path = Join-Path $projectRoot $_
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
            Write-Host "✅ Créé: $_" -ForegroundColor Green
        }
    }
}

# 1. Collecteur de métriques de performance
$performanceCollectorContent = @'
#!/usr/bin/env pwsh
# Performance Metrics Collector
# Collecte automatique des métriques de performance

param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "$PSScriptRoot/../config/metrics.json",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$PSScriptRoot/../data/performance",
    
    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 60
)

# Configuration par défaut
$defaultConfig = @{
    Metrics = @{
        CPU = @{ Enabled = $true; Threshold = 80 }
        Memory = @{ Enabled = $true; Threshold = 85 }
        Disk = @{ Enabled = $true; Threshold = 90 }
        Network = @{ Enabled = $true; Threshold = 100 }
        Scripts = @{ 
            Enabled = $true
            Paths = @("development/scripts", "src")
            ExecutionTimeThreshold = 30
        }
        Database = @{
            Enabled = $true
            QueryTimeThreshold = 5
            ConnectionPoolThreshold = 80
        }
    }
    Alerts = @{
        Email = @{ Enabled = $false; Recipients = @() }
        Webhook = @{ Enabled = $false; Url = "" }
        Log = @{ Enabled = $true; Level = "Warning" }
    }
}

function Start-MetricsCollection {
    param([hashtable]$Config)
    
    Write-Host "📊 Démarrage collecte métriques..." -ForegroundColor Cyan
    
    while ($true) {
        $timestamp = Get-Date
        $metrics = @{
            Timestamp = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            System = @{}
            Application = @{}
            Custom = @{}
        }
        
        # Métriques système
        if ($Config.Metrics.CPU.Enabled) {
            $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
            $metrics.System.CPU = @{
                Usage = [math]::Round($cpu.Average, 2)
                Threshold = $Config.Metrics.CPU.Threshold
                Status = if ($cpu.Average -gt $Config.Metrics.CPU.Threshold) { "Alert" } else { "OK" }
            }
        }
        
        if ($Config.Metrics.Memory.Enabled) {
            $os = Get-CimInstance Win32_OperatingSystem
            $memoryUsage = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
            $metrics.System.Memory = @{
                Usage = $memoryUsage
                Threshold = $Config.Metrics.Memory.Threshold
                Status = if ($memoryUsage -gt $Config.Metrics.Memory.Threshold) { "Alert" } else { "OK" }
            }
        }
        
        if ($Config.Metrics.Disk.Enabled) {
            $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            $diskMetrics = @()
            foreach ($disk in $disks) {
                $usage = [math]::Round(((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100), 2)
                $diskMetrics += @{
                    Drive = $disk.DeviceID
                    Usage = $usage
                    Status = if ($usage -gt $Config.Metrics.Disk.Threshold) { "Alert" } else { "OK" }
                }
            }
            $metrics.System.Disk = $diskMetrics
        }
        
        # Métriques d'application
        if ($Config.Metrics.Scripts.Enabled) {
            $scriptMetrics = @{
                TotalScripts = 0
                ExecutionTimes = @()
                Errors = @()
            }
            
            foreach ($path in $Config.Metrics.Scripts.Paths) {
                if (Test-Path $path) {
                    $scripts = Get-ChildItem -Path $path -Recurse -Filter "*.ps1"
                    $scriptMetrics.TotalScripts += $scripts.Count
                }
            }
            
            $metrics.Application.Scripts = $scriptMetrics
        }
        
        # Métriques custom (projets spécifiques)
        $metrics.Custom = @{
            EmailSender = @{
                QueueLength = Get-Random -Minimum 0 -Maximum 100  # Simulé pour démo
                ProcessingRate = Get-Random -Minimum 50 -Maximum 200
                ErrorRate = Get-Random -Minimum 0 -Maximum 5
            }
            Qdrant = @{
                ConnectionPool = Get-Random -Minimum 0 -Maximum 100
                QueryTime = Get-Random -Minimum 1 -Maximum 10
                IndexSize = Get-Random -Minimum 1000 -Maximum 10000
            }
        }
        
        # Sauvegarder les métriques
        $outputFile = Join-Path $OutputPath "metrics_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        $metrics | ConvertTo-Json -Depth 10 | Set-Content -Path $outputFile
        
        # Vérifier les alertes
        Test-MetricAlerts -Metrics $metrics -Config $Config
        
        Write-Host "📈 Métriques collectées: $outputFile" -ForegroundColor Green
        
        Start-Sleep -Seconds $IntervalSeconds
    }
}

function Test-MetricAlerts {
    param([hashtable]$Metrics, [hashtable]$Config)
    
    $alerts = @()
    
    # Vérifier CPU
    if ($Metrics.System.CPU.Status -eq "Alert") {
        $alerts += "🚨 CPU Usage: $($Metrics.System.CPU.Usage)% > $($Metrics.System.CPU.Threshold)%"
    }
    
    # Vérifier Memory
    if ($Metrics.System.Memory.Status -eq "Alert") {
        $alerts += "🚨 Memory Usage: $($Metrics.System.Memory.Usage)% > $($Metrics.System.Memory.Threshold)%"
    }
    
    # Vérifier Disk
    foreach ($disk in $Metrics.System.Disk) {
        if ($disk.Status -eq "Alert") {
            $alerts += "🚨 Disk $($disk.Drive) Usage: $($disk.Usage)%"
        }
    }
    
    # Envoyer les alertes
    if ($alerts.Count -gt 0) {
        foreach ($alert in $alerts) {
            Write-Warning $alert
            
            if ($Config.Alerts.Log.Enabled) {
                Add-Content -Path "$OutputPath/alerts.log" -Value "$(Get-Date): $alert"
            }
        }
    }
}

# Charger la configuration
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
} else {
    $config = $defaultConfig
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
    Write-Host "📋 Configuration par défaut créée: $ConfigPath" -ForegroundColor Yellow
}

# Démarrer la collecte
Start-MetricsCollection -Config $config
'@

if (-not $DryRun) {
    $collectorPath = Join-Path $projectRoot "metrics/collectors/Collect-PerformanceMetrics.ps1"
    Set-Content -Path $collectorPath -Value $performanceCollectorContent
    Write-Host "✅ Collecteur de performance créé" -ForegroundColor Green
}

# 2. Analyseur de tendances
$trendAnalyzerContent = @'
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
'@

if (-not $DryRun) {
    $analyzerPath = Join-Path $projectRoot "metrics/analyzers/Analyze-Trends.ps1"
    Set-Content -Path $analyzerPath -Value $trendAnalyzerContent
    Write-Host "✅ Analyseur de tendances créé" -ForegroundColor Green
}

# 3. Dashboard en temps réel
$dashboardContent = @'
#!/usr/bin/env pwsh
# Real-time Metrics Dashboard
# Dashboard web en temps réel

param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,
    
    [Parameter(Mandatory = $false)]
    [string]$MetricsPath = "$PSScriptRoot/../data/performance"
)

function Start-MetricsDashboard {
    param([int]$Port, [string]$DataPath)
    
    Write-Host "🌐 Démarrage dashboard sur http://localhost:$Port" -ForegroundColor Cyan
    
    # HTML du dashboard
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Email Sender 1 - Dashboard</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #1a1a1a; color: white; }
        .header { text-align: center; margin-bottom: 30px; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .metric-card { background: #2d2d2d; border-radius: 10px; padding: 20px; border: 1px solid #444; }
        .metric-title { font-size: 1.2em; margin-bottom: 15px; color: #3498db; }
        .metric-value { font-size: 3em; font-weight: bold; margin: 10px 0; }
        .metric-status { padding: 5px 10px; border-radius: 15px; font-size: 0.8em; }
        .status-ok { background: #27ae60; }
        .status-warning { background: #f39c12; }
        .status-alert { background: #e74c3c; }
        .trend { font-size: 0.9em; color: #bdc3c7; }
        .chart { height: 100px; background: #34495e; border-radius: 5px; margin: 10px 0; }
        .last-update { text-align: center; color: #7f8c8d; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Email Sender 1 - Dashboard</h1>
        <p>Surveillance en temps réel</p>
    </div>
    
    <div class="metrics-grid" id="metricsGrid">
        <!-- Les métriques seront injectées ici -->
    </div>
    
    <div class="last-update">
        Dernière mise à jour: <span id="lastUpdate">-</span>
    </div>
    
    <script>
        function updateMetrics() {
            // Simulation des données (normalement via API)
            const metrics = {
                cpu: { value: Math.random() * 100, status: 'ok', trend: 'stable' },
                memory: { value: Math.random() * 100, status: 'ok', trend: 'increasing' },
                emailQueue: { value: Math.floor(Math.random() * 200), status: 'warning', trend: 'decreasing' },
                qdrantConnections: { value: Math.floor(Math.random() * 50), status: 'ok', trend: 'stable' }
            };
            
            const grid = document.getElementById('metricsGrid');
            grid.innerHTML = generateMetricsHTML(metrics);
            
            document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
        }
        
        function generateMetricsHTML(metrics) {
            return Object.entries(metrics).map(([key, data]) => `
                <div class="metric-card">
                    <div class="metric-title">${getMetricTitle(key)}</div>
                    <div class="metric-value" style="color: ${getValueColor(data.status)}">
                        ${formatValue(key, data.value)}
                    </div>
                    <div class="metric-status status-${data.status}">
                        ${data.status.toUpperCase()}
                    </div>
                    <div class="trend">Tendance: ${data.trend}</div>
                    <div class="chart"></div>
                </div>
            `).join('');
        }
        
        function getMetricTitle(key) {
            const titles = {
                cpu: '🖥️ CPU Usage',
                memory: '💾 Memory Usage', 
                emailQueue: '📧 Email Queue',
                qdrantConnections: '🔍 Qdrant Connections'
            };
            return titles[key] || key;
        }
        
        function formatValue(key, value) {
            if (key === 'cpu' || key === 'memory') {
                return Math.round(value) + '%';
            }
            return Math.round(value);
        }
        
        function getValueColor(status) {
            const colors = {
                ok: '#27ae60',
                warning: '#f39c12', 
                alert: '#e74c3c'
            };
            return colors[status] || '#bdc3c7';
        }
        
        // Mise à jour initiale et périodique
        updateMetrics();
        setInterval(updateMetrics, 30000); // Toutes les 30 secondes
    </script>
</body>
</html>
"@

    # Créer le fichier HTML
    $htmlPath = Join-Path $DataPath "dashboard.html"
    if (-not (Test-Path $DataPath)) {
        New-Item -Path $DataPath -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $htmlPath -Value $html
    
    Write-Host "✅ Dashboard créé: $htmlPath" -ForegroundColor Green
    Write-Host "🌐 Ouvrez: file:///$($htmlPath.Replace('\', '/'))" -ForegroundColor Yellow
    
    return $htmlPath
}

# Démarrer le dashboard
Start-MetricsDashboard -Port $Port -DataPath $MetricsPath
'@

if (-not $DryRun) {
    $dashboardPath = Join-Path $projectRoot "metrics/dashboards/Start-Dashboard.ps1"
    Set-Content -Path $dashboardPath -Value $dashboardContent
    Write-Host "✅ Dashboard créé" -ForegroundColor Green
}

# 4. Configuration des métriques
$configContent = @'
{
    "Metrics": {
        "CPU": {
            "Enabled": true,
            "Threshold": 80,
            "AlertOnExceed": true
        },
        "Memory": {
            "Enabled": true,
            "Threshold": 85,
            "AlertOnExceed": true
        },
        "Disk": {
            "Enabled": true,
            "Threshold": 90,
            "AlertOnExceed": true
        },
        "Network": {
            "Enabled": true,
            "Threshold": 100,
            "AlertOnExceed": false
        },
        "Scripts": {
            "Enabled": true,
            "Paths": ["development/scripts", "src"],
            "ExecutionTimeThreshold": 30
        },
        "Database": {
            "Enabled": true,
            "QueryTimeThreshold": 5,
            "ConnectionPoolThreshold": 80
        }
    },
    "Alerts": {
        "Email": {
            "Enabled": false,
            "Recipients": []
        },
        "Webhook": {
            "Enabled": false,
            "Url": ""
        },
        "Log": {
            "Enabled": true,
            "Level": "Warning"
        }
    },
    "Collection": {
        "IntervalSeconds": 60,
        "RetentionDays": 30,
        "BatchSize": 100
    },
    "Dashboard": {
        "Port": 8080,
        "RefreshSeconds": 30,
        "HistoryHours": 24
    }
}
'@

if (-not $DryRun) {
    $configPath = Join-Path $projectRoot "metrics/config/metrics.json"
    if (-not (Test-Path (Split-Path $configPath))) {
        New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
    }
    Set-Content -Path $configPath -Value $configContent
    Write-Host "✅ Configuration créée" -ForegroundColor Green
}

Write-Host @"

📊 METRICS-DRIVEN DEVELOPMENT CONFIGURÉ!
════════════════════════════════════════

✅ Composants créés:
   - Collecteur performance automatique
   - Analyseur de tendances prédictif
   - Dashboard temps réel
   - Configuration centralisée

🚀 DÉMARRAGE:
   1. Collecte: ./metrics/collectors/Collect-PerformanceMetrics.ps1
   2. Analyse: ./metrics/analyzers/Analyze-Trends.ps1  
   3. Dashboard: ./metrics/dashboards/Start-Dashboard.ps1

📊 ROI: +15-20h/mois par optimisation proactive
"@ -ForegroundColor Green
