# Script pour gÃ©nÃ©rer un tableau de bord de suivi des erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration du tableau de bord
$DashboardConfig = @{
    # Dossier de sortie du tableau de bord
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorDashboard"
    
    # Nom du fichier HTML
    HtmlFile = "index.html"
    
    # Titre du tableau de bord
    Title = "Tableau de bord de suivi des erreurs"
    
    # PÃ©riode par dÃ©faut (en jours)
    DefaultPeriod = 30
    
    # Actualisation automatique (en secondes, 0 pour dÃ©sactiver)
    AutoRefresh = 300
    
    # ThÃ¨me (light ou dark)
    Theme = "dark"
}

# Fonction pour initialiser le tableau de bord

# Script pour gÃ©nÃ©rer un tableau de bord de suivi des erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration du tableau de bord
$DashboardConfig = @{
    # Dossier de sortie du tableau de bord
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorDashboard"
    
    # Nom du fichier HTML
    HtmlFile = "index.html"
    
    # Titre du tableau de bord
    Title = "Tableau de bord de suivi des erreurs"
    
    # PÃ©riode par dÃ©faut (en jours)
    DefaultPeriod = 30
    
    # Actualisation automatique (en secondes, 0 pour dÃ©sactiver)
    AutoRefresh = 300
    
    # ThÃ¨me (light ou dark)
    Theme = "dark"
}

# Fonction pour initialiser le tableau de bord
function Initialize-ErrorDashboard {
    param (
        [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "",
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultPeriod = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$AutoRefresh = 300,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("light", "dark")]
        [string]$Theme = "dark"
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $DashboardConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($Title)) {
        $DashboardConfig.Title = $Title
    }
    
    if ($DefaultPeriod -gt 0) {
        $DashboardConfig.DefaultPeriod = $DefaultPeriod
    }
    
    $DashboardConfig.AutoRefresh = $AutoRefresh
    $DashboardConfig.Theme = $Theme
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $DashboardConfig.OutputFolder)) {
        New-Item -Path $DashboardConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le collecteur de donnÃ©es
    Initialize-ErrorDataCollector
    
    return $DashboardConfig
}

# Fonction pour gÃ©nÃ©rer le tableau de bord HTML
function New-ErrorDashboard {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser
    )
    
    # Utiliser la pÃ©riode par dÃ©faut si non spÃ©cifiÃ©e
    if ($Days -le 0) {
        $Days = $DashboardConfig.DefaultPeriod
    }
    
    # Obtenir les donnÃ©es
    $errors = Get-ErrorData -Days $Days
    $stats = Get-ErrorStatistics
    
    # PrÃ©parer les donnÃ©es pour les graphiques
    $dailyErrorsData = @()
    $daysToShow = [Math]::Min($Days, 30)  # Limiter Ã  30 jours pour le graphique
    
    for ($i = $daysToShow - 1; $i -ge 0; $i--) {
        $day = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
        $count = if ($stats.DailyErrors.$day) { $stats.DailyErrors.$day } else { 0 }
        
        $dailyErrorsData += @{
            day = $day
            count = $count
        }
    }
    
    # PrÃ©parer les donnÃ©es pour les graphiques circulaires
    $categoryData = @()
    foreach ($category in $stats.ErrorsByCategory.PSObject.Properties) {
        $categoryData += @{
            name = $category.Name
            value = $category.Value
        }
    }
    
    $severityData = @()
    foreach ($severity in $stats.ErrorsBySeverity.PSObject.Properties) {
        $severityData += @{
            name = $severity.Name
            value = $severity.Value
        }
    }
    
    $sourceData = @()
    foreach ($source in $stats.ErrorsBySource.PSObject.Properties) {
        $sourceData += @{
            name = $source.Name
            value = $source.Value
        }
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($DashboardConfig.Title)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/moment"></script>
    <style>
        :root {
            --bg-color: $(if ($DashboardConfig.Theme -eq "dark") { "#1e1e1e" } else { "#ffffff" });
            --text-color: $(if ($DashboardConfig.Theme -eq "dark") { "#ffffff" } else { "#333333" });
            --card-bg: $(if ($DashboardConfig.Theme -eq "dark") { "#2d2d2d" } else { "#f5f5f5" });
            --border-color: $(if ($DashboardConfig.Theme -eq "dark") { "#444444" } else { "#dddddd" });
            --highlight-color: #4caf50;
            --error-color: #f44336;
            --warning-color: #ff9800;
            --info-color: #2196f3;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            margin: 0;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .header h1 {
            margin: 0;
        }
        
        .stats-summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .stat-card {
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .stat-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
            color: var(--text-color);
        }
        
        .stat-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        .charts-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .chart-card {
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .chart-card h3 {
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        .errors-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background-color: var(--card-bg);
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .errors-table th, .errors-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        
        .errors-table th {
            background-color: var(--highlight-color);
            color: white;
        }
        
        .errors-table tr:last-child td {
            border-bottom: none;
        }
        
        .errors-table tr:hover {
            background-color: rgba(0, 0, 0, 0.05);
        }
        
        .severity-error {
            color: var(--error-color);
            font-weight: bold;
        }
        
        .severity-warning {
            color: var(--warning-color);
            font-weight: bold;
        }
        
        .severity-info {
            color: var(--info-color);
        }
        
        .filters {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        
        .filter-group {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .filter-group label {
            font-weight: bold;
        }
        
        select, button {
            padding: 8px 12px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
            background-color: var(--card-bg);
            color: var(--text-color);
        }
        
        button {
            cursor: pointer;
            background-color: var(--highlight-color);
            color: white;
            border: none;
        }
        
        button:hover {
            opacity: 0.9;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
    $(if ($DashboardConfig.AutoRefresh -gt 0) {
        "<meta http-equiv='refresh' content='$($DashboardConfig.AutoRefresh)'>"
    })
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$($DashboardConfig.Title)</h1>
            <div>
                <span>DerniÃ¨re mise Ã  jour: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="filters">
            <div class="filter-group">
                <label for="period">PÃ©riode:</label>
                <select id="period">
                    <option value="7" $(if ($Days -eq 7) { "selected" } else { "" })>7 jours</option>
                    <option value="14" $(if ($Days -eq 14) { "selected" } else { "" })>14 jours</option>
                    <option value="30" $(if ($Days -eq 30) { "selected" } else { "" })>30 jours</option>
                    <option value="90" $(if ($Days -eq 90) { "selected" } else { "" })>90 jours</option>
                </select>
            </div>
            
            <div class="filter-group">
                <label for="severity">SÃ©vÃ©ritÃ©:</label>
                <select id="severity">
                    <option value="">Toutes</option>
                    <option value="Error">Erreur</option>
                    <option value="Warning">Avertissement</option>
                    <option value="Info">Information</option>
                </select>
            </div>
            
            <div class="filter-group">
                <label for="category">CatÃ©gorie:</label>
                <select id="category">
                    <option value="">Toutes</option>
                    $(foreach ($category in $stats.ErrorsByCategory.PSObject.Properties) {
                        "<option value='$($category.Name)'>$($category.Name)</option>"
                    })
                </select>
            </div>
            
            <button id="apply-filters">Appliquer les filtres</button>
        </div>
        
        <div class="stats-summary">
            <div class="stat-card">
                <h3>Total des erreurs</h3>
                <div class="stat-value">$($stats.TotalErrors)</div>
            </div>
            
            <div class="stat-card">
                <h3>Erreurs (SÃ©vÃ©ritÃ©)</h3>
                <div class="stat-value">$($stats.ErrorsBySeverity.Error)</div>
            </div>
            
            <div class="stat-card">
                <h3>Avertissements</h3>
                <div class="stat-value">$($stats.ErrorsBySeverity.Warning)</div>
            </div>
            
            <div class="stat-card">
                <h3>Erreurs aujourd'hui</h3>
                <div class="stat-value">$($stats.DailyErrors.((Get-Date).ToString("yyyy-MM-dd")))</div>
            </div>
        </div>
        
        <div class="charts-container">
            <div class="chart-card">
                <h3>Erreurs par jour</h3>
                <canvas id="daily-errors-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Erreurs par catÃ©gorie</h3>
                <canvas id="category-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Erreurs par sÃ©vÃ©ritÃ©</h3>
                <canvas id="severity-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Erreurs par source</h3>
                <canvas id="source-chart"></canvas>
            </div>
        </div>
        
        <h2>DerniÃ¨res erreurs</h2>
        <table class="errors-table">
            <thead>
                <tr>
                    <th>Date</th>
                    <th>SÃ©vÃ©ritÃ©</th>
                    <th>CatÃ©gorie</th>
                    <th>Source</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($error in ($errors | Sort-Object -Property Timestamp -Descending | Select-Object -First 20)) {
                    $severityClass = switch ($error.Severity) {
                        "Error" { "severity-error" }
                        "Warning" { "severity-warning" }
                        "Info" { "severity-info" }
                        default { "" }
                    }
                    
                    $timestamp = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                    
                    "<tr>
                        <td>$timestamp</td>
                        <td class='$severityClass'>$($error.Severity)</td>
                        <td>$($error.Category)</td>
                        <td>$($error.Source)</td>
                        <td>$($error.Message)</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | PÃ©riode: $Days jours</p>
        </div>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const dailyErrorsData = $(ConvertTo-Json -InputObject $dailyErrorsData);
        const categoryData = $(ConvertTo-Json -InputObject $categoryData);
        const severityData = $(ConvertTo-Json -InputObject $severityData);
        const sourceData = $(ConvertTo-Json -InputObject $sourceData);
        
        // Couleurs
        const colors = {
            Error: '#f44336',
            Warning: '#ff9800',
            Info: '#2196f3',
            Default: [
                '#4caf50', '#2196f3', '#9c27b0', '#ff9800', '#e91e63',
                '#00bcd4', '#673ab7', '#ffeb3b', '#3f51b5', '#8bc34a'
            ]
        };
        
        // Graphique des erreurs par jour
        const dailyErrorsCtx = document.getElementById('daily-errors-chart').getContext('2d');
        new Chart(dailyErrorsCtx, {
            type: 'line',
            data: {
                labels: dailyErrorsData.map(d => d.day),
                datasets: [{
                    label: 'Erreurs',
                    data: dailyErrorsData.map(d => d.count),
                    borderColor: '#4caf50',
                    backgroundColor: 'rgba(76, 175, 80, 0.1)',
                    tension: 0.1,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                }
            }
        });
        
        // Graphique des erreurs par catÃ©gorie
        const categoryCtx = document.getElementById('category-chart').getContext('2d');
        new Chart(categoryCtx, {
            type: 'pie',
            data: {
                labels: categoryData.map(d => d.name),
                datasets: [{
                    data: categoryData.map(d => d.value),
                    backgroundColor: colors.Default
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    }
                }
            }
        });
        
        // Graphique des erreurs par sÃ©vÃ©ritÃ©
        const severityCtx = document.getElementById('severity-chart').getContext('2d');
        new Chart(severityCtx, {
            type: 'pie',
            data: {
                labels: severityData.map(d => d.name),
                datasets: [{
                    data: severityData.map(d => d.value),
                    backgroundColor: severityData.map(d => colors[d.name] || colors.Default[0])
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    }
                }
            }
        });
        
        // Graphique des erreurs par source
        const sourceCtx = document.getElementById('source-chart').getContext('2d');
        new Chart(sourceCtx, {
            type: 'pie',
            data: {
                labels: sourceData.map(d => d.name),
                datasets: [{
                    data: sourceData.map(d => d.value),
                    backgroundColor: colors.Default
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    }
                }
            }
        });
        
        // Gestion des filtres
        document.getElementById('apply-filters').addEventListener('click', function() {
            const period = document.getElementById('period').value;
            const severity = document.getElementById('severity').value;
            const category = document.getElementById('category').value;
            
            let url = window.location.pathname + '?days=' + period;
            
            if (severity) {
                url += '&severity=' + encodeURIComponent(severity);
            }
            
            if (category) {
                url += '&category=' + encodeURIComponent(category);
            }
            
            window.location.href = url;
        });
    </script>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $outputPath = Join-Path -Path $DashboardConfig.OutputFolder -ChildPath $DashboardConfig.HtmlFile
    $html | Set-Content -Path $outputPath -Encoding UTF8
    
    # Ouvrir dans le navigateur si demandÃ©
    if ($OpenInBrowser) {
        Start-Process $outputPath
    }
    
    return $outputPath
}

# Fonction pour dÃ©marrer un serveur web simple pour le tableau de bord
function Start-ErrorDashboardServer {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 8080,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser
    )
    
    # GÃ©nÃ©rer le tableau de bord
    $dashboardPath = New-ErrorDashboard
    
    # DÃ©marrer le serveur HTTP
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    
    Write-Host "Serveur dÃ©marrÃ© sur http://localhost:$Port/"
    Write-Host "Appuyez sur Ctrl+C pour arrÃªter le serveur."
    
    if ($OpenInBrowser) {
        Start-Process "http://localhost:$Port/"
    }
    
    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $localPath = $request.Url.LocalPath
            $queryString = $request.Url.Query
            
            # Analyser les paramÃ¨tres de requÃªte
            $days = $DashboardConfig.DefaultPeriod
            $severity = ""
            $category = ""
            
            if ($queryString) {
                $params = [System.Web.HttpUtility]::ParseQueryString($queryString)
                
                if ($params["days"]) {
                    $days = [int]$params["days"]
                }
                
                if ($params["severity"]) {
                    $severity = $params["severity"]
                }
                
                if ($params["category"]) {
                    $category = $params["category"]
                }
            }
            
            # GÃ©nÃ©rer le tableau de bord avec les filtres
            $dashboardPath = New-ErrorDashboard -Days $days
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $dashboardPath -Raw
            
            # DÃ©finir les en-tÃªtes de rÃ©ponse
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "text/html; charset=UTF-8"
            
            # Envoyer la rÃ©ponse
            $output = $response.OutputStream
            $output.Write($buffer, 0, $buffer.Length)
            $output.Close()
        }
    }
    finally {
        $listener.Stop()
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorDashboard, New-ErrorDashboard, Start-ErrorDashboardServer

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
