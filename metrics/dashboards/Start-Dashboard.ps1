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
