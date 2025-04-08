# Module de tableau de bord de santé pour le Script Manager
# Ce module génère un tableau de bord de santé des scripts
# Author: Script Manager
# Version: 1.0
# Tags: monitoring, health, dashboard

function Initialize-HealthDashboard {
    <#
    .SYNOPSIS
        Initialise le tableau de bord de santé
    .DESCRIPTION
        Configure le tableau de bord de santé pour les scripts
    .PARAMETER Inventory
        Objet d'inventaire des scripts
    .PARAMETER OutputPath
        Chemin où enregistrer le tableau de bord
    .EXAMPLE
        Initialize-HealthDashboard -Inventory $inventory -OutputPath "monitoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Inventory,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier du tableau de bord
    $DashboardPath = Join-Path -Path $OutputPath -ChildPath "dashboard"
    if (-not (Test-Path -Path $DashboardPath)) {
        New-Item -ItemType Directory -Path $DashboardPath -Force | Out-Null
    }
    
    Write-Host "Initialisation du tableau de bord de santé..." -ForegroundColor Cyan
    
    # Créer le fichier de données du tableau de bord
    $DashboardDataPath = Join-Path -Path $DashboardPath -ChildPath "dashboard_data.json"
    
    # Générer les données initiales du tableau de bord
    $DashboardData = @{
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Inventory.TotalScripts
        ScriptsByType = $Inventory.ScriptsByType
        HealthStatus = @{
            Healthy = 0
            Warning = 0
            Critical = 0
            Unknown = $Inventory.TotalScripts
        }
        Scripts = @()
    }
    
    # Enregistrer les données du tableau de bord
    $DashboardData | ConvertTo-Json -Depth 10 | Set-Content -Path $DashboardDataPath
    
    Write-Host "  Données du tableau de bord initialisées: $DashboardDataPath" -ForegroundColor Green
    
    # Créer le fichier HTML du tableau de bord
    $DashboardHtmlPath = Join-Path -Path $DashboardPath -ChildPath "dashboard.html"
    $DashboardHtmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de bord de santé des scripts</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .last-update {
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .stats {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            flex: 1;
            min-width: 200px;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .stat-card h3 {
            margin-top: 0;
            font-size: 1.2em;
        }
        .stat-card .value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .healthy {
            background-color: #e8f5e9;
            color: #2e7d32;
        }
        .warning {
            background-color: #fff8e1;
            color: #f57f17;
        }
        .critical {
            background-color: #ffebee;
            color: #c62828;
        }
        .unknown {
            background-color: #e3f2fd;
            color: #1565c0;
        }
        .chart-container {
            display: flex;
            gap: 20px;
            margin-bottom: 30px;
        }
        .chart {
            flex: 1;
            min-width: 300px;
            height: 300px;
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            padding: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 600;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 600;
        }
        .filters {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }
        .filter {
            padding: 8px 15px;
            border: 1px solid #ddd;
            border-radius: 20px;
            background-color: #fff;
            cursor: pointer;
            transition: all 0.2s;
        }
        .filter:hover, .filter.active {
            background-color: #2c3e50;
            color: #fff;
            border-color: #2c3e50;
        }
        .search {
            margin-bottom: 20px;
        }
        .search input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 1em;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.9em;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Tableau de bord de santé des scripts</h1>
            <div class="last-update">Dernière mise à jour: <span id="lastUpdate">Chargement...</span></div>
        </div>
        
        <div class="stats">
            <div class="stat-card healthy">
                <h3>Scripts sains</h3>
                <div class="value" id="healthyCount">0</div>
                <div class="description">Scripts fonctionnant correctement</div>
            </div>
            <div class="stat-card warning">
                <h3>Avertissements</h3>
                <div class="value" id="warningCount">0</div>
                <div class="description">Scripts avec problèmes mineurs</div>
            </div>
            <div class="stat-card critical">
                <h3>Critiques</h3>
                <div class="value" id="criticalCount">0</div>
                <div class="description">Scripts avec problèmes majeurs</div>
            </div>
            <div class="stat-card unknown">
                <h3>Non vérifiés</h3>
                <div class="value" id="unknownCount">0</div>
                <div class="description">Scripts non encore vérifiés</div>
            </div>
        </div>
        
        <div class="chart-container">
            <div class="chart">
                <h3>Répartition par état</h3>
                <canvas id="healthChart"></canvas>
            </div>
            <div class="chart">
                <h3>Répartition par type</h3>
                <canvas id="typeChart"></canvas>
            </div>
        </div>
        
        <h2>Liste des scripts</h2>
        
        <div class="search">
            <input type="text" id="searchInput" placeholder="Rechercher un script...">
        </div>
        
        <div class="filters">
            <div class="filter active" data-filter="all">Tous</div>
            <div class="filter" data-filter="healthy">Sains</div>
            <div class="filter" data-filter="warning">Avertissements</div>
            <div class="filter" data-filter="critical">Critiques</div>
            <div class="filter" data-filter="unknown">Non vérifiés</div>
        </div>
        
        <table id="scriptsTable">
            <thead>
                <tr>
                    <th>Nom</th>
                    <th>Type</th>
                    <th>Chemin</th>
                    <th>État</th>
                    <th>Dernière vérification</th>
                </tr>
            </thead>
            <tbody id="scriptsTableBody">
                <tr>
                    <td colspan="5" style="text-align: center;">Chargement des données...</td>
                </tr>
            </tbody>
        </table>
        
        <div class="footer">
            <p>Généré par le Script Manager</p>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        // Fonction pour charger les données du tableau de bord
        async function loadDashboardData() {
            try {
                const response = await fetch('dashboard_data.json');
                const data = await response.json();
                updateDashboard(data);
            } catch (error) {
                console.error('Erreur lors du chargement des données:', error);
                document.getElementById('scriptsTableBody').innerHTML = '<tr><td colspan="5" style="text-align: center;">Erreur lors du chargement des données</td></tr>';
            }
        }
        
        // Fonction pour mettre à jour le tableau de bord
        function updateDashboard(data) {
            // Mettre à jour la dernière mise à jour
            document.getElementById('lastUpdate').textContent = data.LastUpdate;
            
            // Mettre à jour les compteurs
            document.getElementById('healthyCount').textContent = data.HealthStatus.Healthy;
            document.getElementById('warningCount').textContent = data.HealthStatus.Warning;
            document.getElementById('criticalCount').textContent = data.HealthStatus.Critical;
            document.getElementById('unknownCount').textContent = data.HealthStatus.Unknown;
            
            // Mettre à jour les graphiques
            updateHealthChart(data.HealthStatus);
            updateTypeChart(data.ScriptsByType);
            
            // Mettre à jour la table des scripts
            updateScriptsTable(data.Scripts);
        }
        
        // Fonction pour mettre à jour le graphique de santé
        function updateHealthChart(healthStatus) {
            const ctx = document.getElementById('healthChart').getContext('2d');
            
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Sains', 'Avertissements', 'Critiques', 'Non vérifiés'],
                    datasets: [{
                        data: [
                            healthStatus.Healthy,
                            healthStatus.Warning,
                            healthStatus.Critical,
                            healthStatus.Unknown
                        ],
                        backgroundColor: [
                            '#2e7d32',
                            '#f57f17',
                            '#c62828',
                            '#1565c0'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        }
        
        // Fonction pour mettre à jour le graphique de types
        function updateTypeChart(scriptsByType) {
            const ctx = document.getElementById('typeChart').getContext('2d');
            
            const labels = scriptsByType.map(type => type.Type);
            const data = scriptsByType.map(type => type.Count);
            
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Nombre de scripts',
                        data: data,
                        backgroundColor: '#3498db'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
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
        }
        
        // Fonction pour mettre à jour la table des scripts
        function updateScriptsTable(scripts) {
            const tableBody = document.getElementById('scriptsTableBody');
            
            if (scripts.length === 0) {
                tableBody.innerHTML = '<tr><td colspan="5" style="text-align: center;">Aucun script trouvé</td></tr>';
                return;
            }
            
            tableBody.innerHTML = '';
            
            scripts.forEach(script => {
                const row = document.createElement('tr');
                row.dataset.status = script.Status || 'unknown';
                
                row.innerHTML = `
                    <td>${script.Name}</td>
                    <td>${script.Type}</td>
                    <td>${script.Path}</td>
                    <td>
                        <span class="status-badge ${script.Status || 'unknown'}">
                            ${getStatusText(script.Status)}
                        </span>
                    </td>
                    <td>${script.LastCheck || 'Jamais'}</td>
                `;
                
                tableBody.appendChild(row);
            });
            
            // Initialiser les filtres et la recherche
            initializeFilters();
            initializeSearch();
        }
        
        // Fonction pour obtenir le texte du statut
        function getStatusText(status) {
            switch (status) {
                case 'healthy': return 'Sain';
                case 'warning': return 'Avertissement';
                case 'critical': return 'Critique';
                default: return 'Non vérifié';
            }
        }
        
        // Fonction pour initialiser les filtres
        function initializeFilters() {
            const filters = document.querySelectorAll('.filter');
            const rows = document.querySelectorAll('#scriptsTableBody tr');
            
            filters.forEach(filter => {
                filter.addEventListener('click', () => {
                    // Mettre à jour la classe active
                    filters.forEach(f => f.classList.remove('active'));
                    filter.classList.add('active');
                    
                    // Filtrer les lignes
                    const filterValue = filter.dataset.filter;
                    
                    rows.forEach(row => {
                        if (filterValue === 'all' || row.dataset.status === filterValue) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                });
            });
        }
        
        // Fonction pour initialiser la recherche
        function initializeSearch() {
            const searchInput = document.getElementById('searchInput');
            const rows = document.querySelectorAll('#scriptsTableBody tr');
            
            searchInput.addEventListener('input', () => {
                const searchValue = searchInput.value.toLowerCase();
                
                rows.forEach(row => {
                    const text = row.textContent.toLowerCase();
                    
                    if (text.includes(searchValue)) {
                        row.style.display = '';
                    } else {
                        row.style.display = 'none';
                    }
                });
            });
        }
        
        // Charger les données au chargement de la page
        document.addEventListener('DOMContentLoaded', loadDashboardData);
        
        // Recharger les données toutes les 5 minutes
        setInterval(loadDashboardData, 5 * 60 * 1000);
    </script>
</body>
</html>
"@
    
    Set-Content -Path $DashboardHtmlPath -Value $DashboardHtmlContent
    
    Write-Host "  Tableau de bord HTML créé: $DashboardHtmlPath" -ForegroundColor Green
    
    # Créer le script de mise à jour du tableau de bord
    $UpdateScriptPath = Join-Path -Path $DashboardPath -ChildPath "Update-Dashboard.ps1"
    $UpdateScriptContent = @"
<#
.SYNOPSIS
    Met à jour le tableau de bord de santé des scripts
.DESCRIPTION
    Analyse les scripts et met à jour le tableau de bord de santé
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire
.PARAMETER DashboardDataPath
    Chemin vers le fichier de données du tableau de bord
.EXAMPLE
    .\Update-Dashboard.ps1 -InventoryPath "data\inventory.json" -DashboardDataPath "monitoring\dashboard\dashboard_data.json"
#>

param (
    [Parameter(Mandatory=`$true)]
    [string]`$InventoryPath,
    
    [Parameter(Mandatory=`$true)]
    [string]`$DashboardDataPath
)

# Vérifier si les fichiers existent
if (-not (Test-Path -Path `$InventoryPath)) {
    Write-Error "Fichier d'inventaire non trouvé: `$InventoryPath"
    exit 1
}

if (-not (Test-Path -Path `$DashboardDataPath)) {
    Write-Error "Fichier de données du tableau de bord non trouvé: `$DashboardDataPath"
    exit 1
}

# Charger l'inventaire et les données du tableau de bord
try {
    `$Inventory = Get-Content -Path `$InventoryPath -Raw | ConvertFrom-Json
    `$DashboardData = Get-Content -Path `$DashboardDataPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des fichiers: `$_"
    exit 1
}

# Mettre à jour les données du tableau de bord
`$DashboardData.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
`$DashboardData.TotalScripts = `$Inventory.TotalScripts
`$DashboardData.ScriptsByType = `$Inventory.ScriptsByType

# Réinitialiser les compteurs de santé
`$DashboardData.HealthStatus.Healthy = 0
`$DashboardData.HealthStatus.Warning = 0
`$DashboardData.HealthStatus.Critical = 0
`$DashboardData.HealthStatus.Unknown = 0

# Mettre à jour la liste des scripts
`$DashboardData.Scripts = @()

foreach (`$Script in `$Inventory.Scripts) {
    # Vérifier l'état du script
    `$Status = Get-ScriptHealth -ScriptPath `$Script.Path
    
    # Incrémenter le compteur correspondant
    `$DashboardData.HealthStatus.(`$Status) += 1
    
    # Ajouter le script à la liste
    `$DashboardData.Scripts += [PSCustomObject]@{
        Name = `$Script.Name
        Type = `$Script.Type
        Path = `$Script.Path
        Status = `$Status.ToLower()
        LastCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Enregistrer les données mises à jour
`$DashboardData | ConvertTo-Json -Depth 10 | Set-Content -Path `$DashboardDataPath

Write-Host "Tableau de bord mis à jour: `$DashboardDataPath" -ForegroundColor Green

function Get-ScriptHealth {
    <#
    .SYNOPSIS
        Vérifie l'état de santé d'un script
    .DESCRIPTION
        Analyse un script pour déterminer son état de santé
    .PARAMETER ScriptPath
        Chemin vers le script à vérifier
    .EXAMPLE
        Get-ScriptHealth -ScriptPath "scripts\myscript.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=`$true)]
        [string]`$ScriptPath
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path `$ScriptPath)) {
        return "Critical"
    }
    
    # Obtenir l'extension du fichier
    `$Extension = [System.IO.Path]::GetExtension(`$ScriptPath).ToLower()
    
    # Vérifier le script selon son type
    switch (`$Extension) {
        ".ps1" {
            # Vérifier la syntaxe PowerShell
            try {
                `$Errors = `$null
                [void][System.Management.Automation.PSParser]::Tokenize((Get-Content -Path `$ScriptPath -Raw), [ref]`$Errors)
                
                if (`$Errors.Count -gt 0) {
                    # Erreurs de syntaxe
                    return "Critical"
                }
                
                # Vérifier les problèmes courants
                `$Content = Get-Content -Path `$ScriptPath -Raw
                
                # Vérifier l'utilisation de chemins absolus
                if (`$Content -match "[A-Z]:\\") {
                    return "Warning"
                }
                
                # Vérifier l'utilisation de $null à droite des comparaisons
                if (`$Content -match "\`$\w+\s*-eq\s*\`$null") {
                    return "Warning"
                }
                
                return "Healthy"
            } catch {
                # Erreur lors de la vérification
                return "Critical"
            }
        }
        ".py" {
            # Pour les scripts Python, vérifier simplement s'ils peuvent être lus
            try {
                `$Content = Get-Content -Path `$ScriptPath -Raw
                
                # Vérifier les problèmes courants
                if (`$Content -match "print\s*\(" -and -not (`$Content -match "import\s+logging")) {
                    return "Warning"
                }
                
                if (`$Content -match "except\s*:") {
                    return "Warning"
                }
                
                return "Healthy"
            } catch {
                return "Critical"
            }
        }
        ".cmd" {
            # Pour les scripts Batch, vérifier simplement s'ils peuvent être lus
            try {
                `$Content = Get-Content -Path `$ScriptPath -Raw
                
                # Vérifier les problèmes courants
                if (-not (`$Content -match "@ECHO OFF")) {
                    return "Warning"
                }
                
                return "Healthy"
            } catch {
                return "Critical"
            }
        }
        ".bat" {
            # Pour les scripts Batch, vérifier simplement s'ils peuvent être lus
            try {
                `$Content = Get-Content -Path `$ScriptPath -Raw
                
                # Vérifier les problèmes courants
                if (-not (`$Content -match "@ECHO OFF")) {
                    return "Warning"
                }
                
                return "Healthy"
            } catch {
                return "Critical"
            }
        }
        ".sh" {
            # Pour les scripts Shell, vérifier simplement s'ils peuvent être lus
            try {
                `$Content = Get-Content -Path `$ScriptPath -Raw
                
                # Vérifier les problèmes courants
                if (-not (`$Content -match "^#!/bin/(bash|sh)")) {
                    return "Warning"
                }
                
                return "Healthy"
            } catch {
                return "Critical"
            }
        }
        default {
            # Type de script inconnu
            return "Unknown"
        }
    }
}
"@
    
    Set-Content -Path $UpdateScriptPath -Value $UpdateScriptContent
    
    Write-Host "  Script de mise à jour créé: $UpdateScriptPath" -ForegroundColor Green
    
    return [PSCustomObject]@{
        DashboardPath = $DashboardPath
        DashboardDataPath = $DashboardDataPath
        DashboardHtmlPath = $DashboardHtmlPath
        UpdateScriptPath = $UpdateScriptPath
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-HealthDashboard
