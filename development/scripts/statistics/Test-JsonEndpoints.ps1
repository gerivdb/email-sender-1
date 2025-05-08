# Test-JsonEndpoints.ps1
# Ce script teste le module JsonEndpoints

# Importer le module JsonEndpoints
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "JsonEndpoints.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module JsonEndpoints.psm1 n'a pas été trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir les chemins des fichiers
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
$clientsFolder = Join-Path -Path $PSScriptRoot -ChildPath "clients"

# Créer le dossier clients s'il n'existe pas
if (-not (Test-Path -Path $clientsFolder)) {
    New-Item -Path $clientsFolder -ItemType Directory | Out-Null
}

# Vérifier que le dossier de rapports existe et contient des fichiers JSON
if (-not (Test-Path -Path $reportsFolder)) {
    Write-Error "Le dossier de rapports n'existe pas: $reportsFolder"
    exit 1
}

$jsonFiles = Get-ChildItem -Path $reportsFolder -Filter "*.json"
if ($jsonFiles.Count -eq 0) {
    Write-Error "Aucun fichier JSON trouvé dans le dossier de rapports: $reportsFolder"
    exit 1
}

# Test 1: Génération du client JavaScript
Write-Host "`n=== Test 1: Génération du client JavaScript ===" -ForegroundColor Magenta
$clientPath = Join-Path -Path $clientsFolder -ChildPath "asymmetry-json-client.js"
$jsClient = New-JsonEndpointClient -OutputPath $clientPath -ServerUrl "http://localhost:8080"
if (Test-Path -Path $clientPath) {
    Write-Host "Client JavaScript généré avec succès: $clientPath" -ForegroundColor Green
    Write-Host "Taille du client: $((Get-Item -Path $clientPath).Length) octets" -ForegroundColor White
} else {
    Write-Host "Échec de la génération du client JavaScript." -ForegroundColor Red
    exit 1
}

# Test 2: Création d'une page HTML de démonstration
Write-Host "`n=== Test 2: Création d'une page HTML de démonstration ===" -ForegroundColor Magenta
$demoHtmlPath = Join-Path -Path $clientsFolder -ChildPath "asymmetry-demo.html"
$demoHtml = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Démo du client JSON d'asymétrie</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .reports-list {
            flex: 1;
            min-width: 300px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .report-view {
            flex: 2;
            min-width: 500px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .report-table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        .report-table th, .report-table td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .report-table th {
            background-color: #f2f2f2;
        }
        .report-item {
            cursor: pointer;
            padding: 8px;
            margin-bottom: 5px;
            background-color: #fff;
            border-radius: 4px;
            transition: background-color 0.2s;
        }
        .report-item:hover {
            background-color: #e9ecef;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin: 20px 0;
        }
        .status {
            padding: 10px;
            margin-top: 20px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .error {
            color: #e74c3c;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="asymmetry-json-client.js"></script>
</head>
<body>
    <h1>Démo du client JSON d'asymétrie</h1>
    <p>Cette page démontre l'utilisation du client JavaScript pour accéder aux endpoints JSON d'asymétrie.</p>
    
    <div class="container">
        <div class="reports-list">
            <h2>Rapports disponibles</h2>
            <div id="reports-container"></div>
        </div>
        
        <div class="report-view">
            <h2>Détails du rapport</h2>
            <div id="report-details"></div>
            <div class="chart-container">
                <canvas id="histogram-chart"></canvas>
            </div>
        </div>
    </div>
    
    <div class="status" id="status"></div>
    
    <script>
        // Initialiser le client
        const client = new AsymmetryJsonClient();
        
        // Fonction pour afficher la liste des rapports
        async function loadReportsList() {
            try {
                const status = document.getElementById('status');
                status.textContent = 'Chargement de la liste des rapports...';
                status.className = 'status';
                
                const reportsList = await client.getReportsList();
                const reportsContainer = document.getElementById('reports-container');
                
                if (reportsList.reports.length === 0) {
                    reportsContainer.innerHTML = '<p>Aucun rapport disponible</p>';
                    return;
                }
                
                let html = '';
                reportsList.reports.forEach(report => {
                    const date = new Date(report.lastModified);
                    html += `<div class="report-item" onclick="loadReport('\${report.name}')">`;
                    html += `<strong>\${report.name}</strong><br>`;
                    html += `<small>Modifié le \${date.toLocaleString()}</small><br>`;
                    html += `<small>Taille: \${report.size} octets</small>`;
                    html += `</div>`;
                });
                
                reportsContainer.innerHTML = html;
                status.textContent = `\${reportsList.reports.length} rapports chargés.`;
            } catch (error) {
                const status = document.getElementById('status');
                status.textContent = `Erreur: \${error.message}`;
                status.className = 'status error';
                console.error(error);
            }
        }
        
        // Fonction pour charger un rapport spécifique
        async function loadReport(reportName) {
            try {
                const status = document.getElementById('status');
                status.textContent = `Chargement du rapport \${reportName}...`;
                status.className = 'status';
                
                const report = await client.getReport(reportName);
                const reportDetails = document.getElementById('report-details');
                
                // Afficher les détails du rapport
                reportDetails.innerHTML = client.createReportTable(report);
                
                // Créer le graphique d'histogramme si les données sont disponibles
                if (report.data && report.data.histogram) {
                    client.createHistogramChart(report, 'histogram-chart');
                } else {
                    const ctx = document.getElementById('histogram-chart').getContext('2d');
                    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
                    ctx.font = '14px Arial';
                    ctx.fillText('Données d\'histogramme non disponibles', 10, 50);
                }
                
                status.textContent = `Rapport \${reportName} chargé.`;
            } catch (error) {
                const status = document.getElementById('status');
                status.textContent = `Erreur: \${error.message}`;
                status.className = 'status error';
                console.error(error);
            }
        }
        
        // Charger la liste des rapports au chargement de la page
        window.onload = loadReportsList;
    </script>
</body>
</html>
"@

$demoHtml | Out-File -FilePath $demoHtmlPath -Encoding UTF8
if (Test-Path -Path $demoHtmlPath) {
    Write-Host "Page HTML de démonstration générée avec succès: $demoHtmlPath" -ForegroundColor Green
    Write-Host "Taille de la page: $((Get-Item -Path $demoHtmlPath).Length) octets" -ForegroundColor White
} else {
    Write-Host "Échec de la génération de la page HTML de démonstration." -ForegroundColor Red
    exit 1
}

# Test 3: Démarrage du serveur JSON
Write-Host "`n=== Test 3: Démarrage du serveur JSON ===" -ForegroundColor Magenta
Write-Host "Le serveur JSON va démarrer sur http://localhost:8080/" -ForegroundColor Yellow
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur..." -ForegroundColor Yellow
Write-Host "Ouvrez la page de démonstration dans votre navigateur: $demoHtmlPath" -ForegroundColor Yellow

# Ouvrir la page de démonstration dans le navigateur par défaut
Start-Process $demoHtmlPath

# Démarrer le serveur JSON
Start-JsonEndpointServer -Port 8080 -ReportsFolder $reportsFolder -CacheEnabled $true -CacheExpirationMinutes 5
