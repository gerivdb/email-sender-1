<#
.SYNOPSIS
    Script de génération de tableaux de bord pour les données de performance.
.DESCRIPTION
    Ce script génère des tableaux de bord pour visualiser les données de performance
    du système, des applications et des métriques métier.
.PARAMETER DataPath
    Chemin vers les données de performance.
.PARAMETER OutputPath
    Chemin où les tableaux de bord seront sauvegardés.
.PARAMETER TemplatesPath
    Chemin vers les templates de tableaux de bord.
.PARAMETER DashboardType
    Type de tableau de bord à générer (system, application, business).
.PARAMETER TimeRange
    Plage de temps pour les données à visualiser.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "output/dashboards",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplatesPath = "templates/dashboards/dashboard_templates.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("system", "application", "business", "all")]
    [string]$DashboardType = "all",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("last_hour", "last_day", "last_week", "last_month")]
    [string]$TimeRange = "last_day"
)

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Verbose", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Verbose" { Write-Verbose $LogMessage }
        "Info" { Write-Host $LogMessage -ForegroundColor Cyan }
        "Warning" { Write-Host $LogMessage -ForegroundColor Yellow }
        "Error" { Write-Host $LogMessage -ForegroundColor Red }
    }
}

# Fonction pour charger les templates de tableaux de bord
function Import-DashboardTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplatesPath
    )
    
    Write-Log -Message "Chargement des templates de tableaux de bord depuis $TemplatesPath" -Level "Info"
    
    try {
        if (Test-Path -Path $TemplatesPath) {
            $Templates = Get-Content -Path $TemplatesPath -Raw | ConvertFrom-Json
            Write-Log -Message "Templates chargés avec succès: $($Templates.templates.Count) templates disponibles" -Level "Info"
            return $Templates.templates
        } else {
            Write-Log -Message "Fichier de templates non trouvé: $TemplatesPath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des templates: $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger les données de performance
function Import-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$MetricType,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeRange
    )
    
    Write-Log -Message "Chargement des données de performance de type $MetricType" -Level "Info"
    
    try {
        $DataFile = Join-Path -Path $DataPath -ChildPath "$($MetricType)_metrics.csv"
        
        if (Test-Path -Path $DataFile) {
            $Data = Import-Csv -Path $DataFile
            
            # Convertir les timestamps en objets DateTime
            $Data = $Data | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "DateTime" -Value ([DateTime]::Parse($_.Timestamp)) -Force
                $_
            }
            
            # Filtrer par plage de temps
            $EndDate = Get-Date
            $StartDate = switch ($TimeRange) {
                "last_hour" { $EndDate.AddHours(-1) }
                "last_day" { $EndDate.AddDays(-1) }
                "last_week" { $EndDate.AddDays(-7) }
                "last_month" { $EndDate.AddDays(-30) }
                default { $EndDate.AddDays(-1) }
            }
            
            $FilteredData = $Data | Where-Object { $_.DateTime -ge $StartDate -and $_.DateTime -le $EndDate }
            
            Write-Log -Message "Données chargées avec succès: $($FilteredData.Count) entrées" -Level "Info"
            return $FilteredData
        } else {
            Write-Log -Message "Fichier de données non trouvé: $DataFile" -Level "Warning"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des données: $_" -Level "Error"
        return $null
    }
}

# Fonction pour générer un panneau de tableau de bord
function New-DashboardPanel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Panel,
        
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalOptions = @{}
    )
    
    Write-Log -Message "Génération du panneau: $($Panel.id)" -Level "Verbose"
    
    try {
        # Filtrer les données pour la métrique spécifiée
        $MetricData = if ($Panel.PSObject.Properties.Name -contains "metrics") {
            # Plusieurs métriques
            $Panel.metrics | ForEach-Object {
                $Metric = $_
                $Data | Where-Object { $_.Metric -eq $Metric }
            }
        } else {
            # Une seule métrique
            $Data | Where-Object { $_.Metric -eq $Panel.metric }
        }
        
        if (-not $MetricData -or $MetricData.Count -eq 0) {
            Write-Log -Message "Aucune donnée trouvée pour le panneau: $($Panel.id)" -Level "Warning"
            return $null
        }
        
        # Créer le panneau selon son type
        $PanelConfig = switch ($Panel.type) {
            "gauge" {
                # Calculer la dernière valeur
                $LastValue = ($MetricData | Sort-Object -Property DateTime | Select-Object -Last 1).Value
                
                @{
                    id = $Panel.id
                    title = $Panel.title
                    type = "gauge"
                    value = [double]$LastValue
                    min = $Panel.options.min
                    max = $Panel.options.max
                    unit = $Panel.options.unit
                    thresholds = $Panel.options.thresholds
                }
            }
            "line" {
                # Préparer les données pour le graphique
                $Series = if ($Panel.PSObject.Properties.Name -contains "metrics") {
                    # Plusieurs métriques
                    $Panel.metrics | ForEach-Object {
                        $Metric = $_
                        $MetricValues = $Data | Where-Object { $_.Metric -eq $Metric } | Sort-Object -Property DateTime
                        
                        @{
                            name = $Metric
                            data = @($MetricValues | ForEach-Object {
                                @{
                                    x = $_.DateTime.ToString("yyyy-MM-dd HH:mm:ss")
                                    y = [double]$_.Value
                                }
                            })
                        }
                    }
                } else {
                    # Une seule métrique
                    @(
                        @{
                            name = $Panel.metric
                            data = @($MetricData | Sort-Object -Property DateTime | ForEach-Object {
                                @{
                                    x = $_.DateTime.ToString("yyyy-MM-dd HH:mm:ss")
                                    y = [double]$_.Value
                                }
                            })
                        }
                    )
                }
                
                @{
                    id = $Panel.id
                    title = $Panel.title
                    type = "line"
                    series = $Series
                    options = @{
                        legend = $Panel.options.legend
                        tooltip = $Panel.options.tooltip
                        xAxis = @{
                            type = "time"
                            title = "Temps"
                        }
                        yAxis = @{
                            title = "Valeur"
                        }
                    }
                }
            }
            default {
                Write-Log -Message "Type de panneau non pris en charge: $($Panel.type)" -Level "Warning"
                return $null
            }
        }
        
        # Ajouter les options supplémentaires
        foreach ($Key in $AdditionalOptions.Keys) {
            $PanelConfig[$Key] = $AdditionalOptions[$Key]
        }
        
        return $PanelConfig
    } catch {
        Write-Log -Message "Erreur lors de la génération du panneau: $_" -Level "Error"
        return $null
    }
}

# Fonction pour générer un tableau de bord
function New-Dashboard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Template,
        
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalOptions = @{}
    )
    
    Write-Log -Message "Génération du tableau de bord: $($Template.name)" -Level "Info"
    
    try {
        # Créer le répertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Préparer la structure du tableau de bord
        $Dashboard = @{
            id = $Template.id
            name = $Template.name
            description = $Template.description
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            layout = @{
                rows = $Template.layout.rows
                columns = $Template.layout.columns
            }
            panels = @()
        }
        
        # Générer chaque panneau
        foreach ($Panel in $Template.layout.panels) {
            $PanelConfig = New-DashboardPanel -Panel $Panel -Data $Data -AdditionalOptions $AdditionalOptions
            
            if ($PanelConfig) {
                $PanelConfig.position = $Panel.position
                $Dashboard.panels += $PanelConfig
            }
        }
        
        # Convertir en JSON
        $DashboardJson = $Dashboard | ConvertTo-Json -Depth 10
        
        # Sauvegarder le fichier de configuration du tableau de bord
        $DashboardJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Tableau de bord généré avec succès: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération du tableau de bord: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer un fichier HTML pour le tableau de bord
function New-DashboardHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DashboardConfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Title = "Tableau de bord"
    )
    
    Write-Log -Message "Génération du fichier HTML pour le tableau de bord: $OutputPath" -Level "Info"
    
    try {
        # Lire la configuration du tableau de bord
        $DashboardConfig = Get-Content -Path $DashboardConfigPath -Raw | ConvertFrom-Json
        
        # Créer le contenu HTML
        $HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/moment@2.29.1/moment.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-moment@1.0.0/dist/chartjs-adapter-moment.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .dashboard-header {
            margin-bottom: 20px;
        }
        .dashboard-title {
            font-size: 24px;
            margin: 0;
        }
        .dashboard-description {
            color: #666;
            margin: 5px 0 0 0;
        }
        .dashboard-timestamp {
            color: #999;
            font-size: 12px;
            margin: 5px 0 0 0;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat($($DashboardConfig.layout.columns), 1fr);
            grid-auto-rows: minmax(200px, auto);
            gap: 20px;
        }
        .panel {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
            padding: 15px;
            display: flex;
            flex-direction: column;
        }
        .panel-header {
            margin-bottom: 10px;
        }
        .panel-title {
            font-size: 16px;
            margin: 0;
        }
        .panel-content {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .gauge-container {
            position: relative;
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }
        .gauge-value {
            font-size: 24px;
            font-weight: bold;
        }
        .gauge-label {
            font-size: 12px;
            color: #666;
        }
        canvas {
            width: 100% !important;
            height: 100% !important;
        }
    </style>
</head>
<body>
    <div class="dashboard-header">
        <h1 class="dashboard-title">$($DashboardConfig.name)</h1>
        <p class="dashboard-description">$($DashboardConfig.description)</p>
        <p class="dashboard-timestamp">Dernière mise à jour: $($DashboardConfig.timestamp)</p>
    </div>
    
    <div class="dashboard-grid">
"@
        
        # Ajouter chaque panneau
        foreach ($Panel in $DashboardConfig.panels) {
            $GridColumn = "grid-column: $($Panel.position.col + 1) / span $($Panel.position.width);"
            $GridRow = "grid-row: $($Panel.position.row + 1) / span $($Panel.position.height);"
            
            $HtmlContent += @"
        <div class="panel" style="$GridColumn $GridRow">
            <div class="panel-header">
                <h2 class="panel-title">$($Panel.title)</h2>
            </div>
            <div class="panel-content">
"@
            
            # Contenu spécifique au type de panneau
            switch ($Panel.type) {
                "gauge" {
                    $HtmlContent += @"
                <div class="gauge-container">
                    <div class="gauge-value">$([Math]::Round($Panel.value, 2))$($Panel.unit)</div>
                    <div class="gauge-label">Min: $($Panel.min)$($Panel.unit) | Max: $($Panel.max)$($Panel.unit)</div>
                    <canvas id="gauge-$($Panel.id)"></canvas>
                </div>
"@
                }
                "line" {
                    $HtmlContent += @"
                <canvas id="chart-$($Panel.id)"></canvas>
"@
                }
            }
            
            $HtmlContent += @"
            </div>
        </div>
"@
        }
        
        $HtmlContent += @"
    </div>
    
    <script>
        // Configuration des graphiques
        const dashboardConfig = $($DashboardConfig | ConvertTo-Json -Depth 10);
        
        // Initialiser les graphiques
        document.addEventListener('DOMContentLoaded', function() {
            // Créer chaque graphique
            dashboardConfig.panels.forEach(panel => {
                switch (panel.type) {
                    case 'gauge':
                        createGauge(panel);
                        break;
                    case 'line':
                        createLineChart(panel);
                        break;
                }
            });
        });
        
        // Fonction pour créer un gauge
        function createGauge(panel) {
            const canvas = document.getElementById(`gauge-\${panel.id}`);
            if (!canvas) return;
            
            const ctx = canvas.getContext('2d');
            
            // Trouver la couleur correspondant à la valeur
            let color = '#73BF69'; // Couleur par défaut (vert)
            for (let i = panel.thresholds.length - 1; i >= 0; i--) {
                if (panel.value >= panel.thresholds[i].value) {
                    color = panel.thresholds[i].color;
                    break;
                }
            }
            
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    datasets: [{
                        data: [panel.value, panel.max - panel.value],
                        backgroundColor: [color, '#eee'],
                        borderWidth: 0
                    }]
                },
                options: {
                    circumference: 180,
                    rotation: -90,
                    cutout: '80%',
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            enabled: false
                        }
                    },
                    animation: {
                        animateRotate: true,
                        animateScale: false
                    }
                }
            });
        }
        
        // Fonction pour créer un graphique linéaire
        function createLineChart(panel) {
            const canvas = document.getElementById(`chart-\${panel.id}`);
            if (!canvas) return;
            
            const ctx = canvas.getContext('2d');
            
            const datasets = panel.series.map((series, index) => {
                return {
                    label: series.name,
                    data: series.data,
                    borderColor: getColor(index),
                    backgroundColor: getColor(index, 0.1),
                    tension: 0.4,
                    fill: false
                };
            });
            
            new Chart(ctx, {
                type: 'line',
                data: {
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            type: 'time',
                            time: {
                                unit: 'hour',
                                displayFormats: {
                                    hour: 'HH:mm'
                                }
                            },
                            title: {
                                display: true,
                                text: panel.options.xAxis.title
                            }
                        },
                        y: {
                            title: {
                                display: true,
                                text: panel.options.yAxis.title
                            },
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            display: panel.options.legend
                        },
                        tooltip: {
                            enabled: panel.options.tooltip
                        }
                    }
                }
            });
        }
        
        // Fonction pour obtenir une couleur
        function getColor(index, alpha = 1) {
            const colors = [
                `rgba(31, 119, 180, \${alpha})`,
                `rgba(255, 127, 14, \${alpha})`,
                `rgba(44, 160, 44, \${alpha})`,
                `rgba(214, 39, 40, \${alpha})`,
                `rgba(148, 103, 189, \${alpha})`,
                `rgba(140, 86, 75, \${alpha})`,
                `rgba(227, 119, 194, \${alpha})`,
                `rgba(127, 127, 127, \${alpha})`,
                `rgba(188, 189, 34, \${alpha})`,
                `rgba(23, 190, 207, \${alpha})`
            ];
            return colors[index % colors.length];
        }
    </script>
</body>
</html>
"@
        
        # Sauvegarder le fichier HTML
        $HtmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Fichier HTML généré avec succès: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération du fichier HTML: $_" -Level "Error"
        return $false
    }
}

# Fonction principale pour générer les tableaux de bord
function Start-DashboardGeneration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [object[]]$Templates,
        
        [Parameter(Mandatory=$true)]
        [string]$DashboardType,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeRange
    )
    
    Write-Log -Message "Début de la génération des tableaux de bord" -Level "Info"
    
    # Déterminer les types de tableaux de bord à générer
    $DashboardTypes = @()
    if ($DashboardType -eq "all") {
        $DashboardTypes = @("system", "application", "business")
    } else {
        $DashboardTypes = @($DashboardType)
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Générer les tableaux de bord pour chaque type
    foreach ($Type in $DashboardTypes) {
        Write-Log -Message "Génération du tableau de bord de type: $Type" -Level "Info"
        
        # Trouver le template correspondant
        $Template = $Templates | Where-Object { $_.id -eq "${Type}_dashboard" } | Select-Object -First 1
        
        if ($null -eq $Template) {
            Write-Log -Message "Aucun template trouvé pour le type: $Type" -Level "Warning"
            continue
        }
        
        # Charger les données
        $Data = Import-PerformanceData -DataPath $DataPath -MetricType $Type -TimeRange $TimeRange
        
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée disponible pour le type: $Type" -Level "Warning"
            continue
        }
        
        # Générer le tableau de bord
        $DashboardOutputPath = Join-Path -Path $OutputPath -ChildPath "${Type}_dashboard.json"
        $Success = New-Dashboard -Template $Template -Data $Data -OutputPath $DashboardOutputPath
        
        if ($Success) {
            # Générer le fichier HTML
            $HtmlOutputPath = Join-Path -Path $OutputPath -ChildPath "${Type}_dashboard.html"
            New-DashboardHtml -DashboardConfigPath $DashboardOutputPath -OutputPath $HtmlOutputPath -Title $Template.name
        }
    }
    
    Write-Log -Message "Génération des tableaux de bord terminée" -Level "Info"
    return $true
}

# Point d'entrée principal
try {
    # Charger les templates de tableaux de bord
    $Templates = Import-DashboardTemplates -TemplatesPath $TemplatesPath
    
    if ($null -eq $Templates) {
        Write-Log -Message "Impossible de continuer sans templates de tableaux de bord" -Level "Error"
        exit 1
    }
    
    # Générer les tableaux de bord
    $Result = Start-DashboardGeneration -DataPath $DataPath -OutputPath $OutputPath -Templates $Templates -DashboardType $DashboardType -TimeRange $TimeRange
    
    if ($Result) {
        Write-Log -Message "Génération des tableaux de bord réussie" -Level "Info"
        exit 0
    } else {
        Write-Log -Message "Échec de la génération des tableaux de bord" -Level "Error"
        exit 1
    }
} catch {
    Write-Log -Message "Erreur non gérée: $_" -Level "Error"
    exit 1
}
