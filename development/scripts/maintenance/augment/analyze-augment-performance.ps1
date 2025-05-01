<#
.SYNOPSIS
    Script d'analyse des performances d'Augment Code.

.DESCRIPTION
    Ce script analyse les performances d'Augment Code en mesurant les temps de réponse,
    la taille des inputs/outputs et d'autres métriques pertinentes.

.PARAMETER LogPath
    Chemin vers le fichier de log à analyser. Par défaut : "logs\augment\augment.log".

.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour le rapport. Par défaut : "reports\augment\performance.html".

.EXAMPLE
    .\analyze-augment-performance.ps1
    # Analyse les performances d'Augment Code avec les paramètres par défaut

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$LogPath = "logs\augment\augment.log",

    [Parameter()]
    [string]$OutputPath = "reports\augment\performance.html"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Vérifier si le fichier de log existe
$logPath = Join-Path -Path $projectRoot -ChildPath $LogPath
if (-not (Test-Path -Path $logPath)) {
    Write-Warning "Fichier de log introuvable : $logPath"
    
    # Créer un fichier de log de démonstration
    $demoLogContent = @"
2025-06-01T10:00:00.000Z|REQUEST|{"input":"Analyse le fichier gran-mode.ps1","input_size":35,"mode":"GRAN"}
2025-06-01T10:00:05.123Z|RESPONSE|{"output":"Analyse du fichier gran-mode.ps1...","output_size":120,"time_ms":5123}
2025-06-01T10:10:00.000Z|REQUEST|{"input":"Implémente une fonction pour détecter la complexité","input_size":52,"mode":"DEV-R"}
2025-06-01T10:10:08.456Z|RESPONSE|{"output":"Voici l'implémentation de la fonction...","output_size":2500,"time_ms":8456}
2025-06-01T10:20:00.000Z|REQUEST|{"input":"Vérifie si la tâche 1.2.3 est terminée","input_size":40,"mode":"CHECK"}
2025-06-01T10:20:03.789Z|RESPONSE|{"output":"La tâche 1.2.3 est terminée à 80%...","output_size":800,"time_ms":3789}
2025-06-01T10:30:00.000Z|REQUEST|{"input":"Optimise cette fonction pour réduire la complexité","input_size":48,"mode":"OPTI"}
2025-06-01T10:30:10.234Z|RESPONSE|{"output":"Voici la version optimisée de la fonction...","output_size":1800,"time_ms":10234}
2025-06-01T10:40:00.000Z|REQUEST|{"input":"Crée un diagramme d'architecture pour le module de gestion des modes","input_size":65,"mode":"ARCHI"}
2025-06-01T10:40:15.678Z|RESPONSE|{"output":"Voici le diagramme d'architecture...","output_size":3200,"time_ms":15678}
"@
    
    # Créer le répertoire des logs s'il n'existe pas
    $logDir = Split-Path -Path $logPath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le fichier de log de démonstration
    $demoLogContent | Out-File -FilePath $logPath -Encoding UTF8
    Write-Host "Fichier de log de démonstration créé : $logPath" -ForegroundColor Yellow
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $outputDir -PathType Container)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour analyser le fichier de log
function Analyze-AugmentLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    # Lire le fichier de log
    $logContent = Get-Content -Path $LogPath -Encoding UTF8

    # Initialiser les variables d'analyse
    $requests = @()
    $responses = @()
    $metrics = @{
        TotalRequests = 0
        TotalResponses = 0
        AverageResponseTime = 0
        MaxResponseTime = 0
        MinResponseTime = [int]::MaxValue
        AverageInputSize = 0
        AverageOutputSize = 0
        MaxInputSize = 0
        MaxOutputSize = 0
        RequestsByMode = @{}
        ResponseTimesByMode = @{}
    }

    # Analyser chaque ligne du log
    foreach ($line in $logContent) {
        if ($line -match "^(.*?)\|REQUEST\|(.*?)$") {
            $timestamp = $matches[1]
            $requestData = $matches[2] | ConvertFrom-Json
            
            $request = @{
                Timestamp = $timestamp
                Input = $requestData.input
                InputSize = $requestData.input_size
                Mode = $requestData.mode
            }
            
            $requests += $request
            $metrics.TotalRequests++
            
            if ($requestData.input_size -gt $metrics.MaxInputSize) {
                $metrics.MaxInputSize = $requestData.input_size
            }
            
            if (-not $metrics.RequestsByMode.ContainsKey($requestData.mode)) {
                $metrics.RequestsByMode[$requestData.mode] = 0
                $metrics.ResponseTimesByMode[$requestData.mode] = @()
            }
            
            $metrics.RequestsByMode[$requestData.mode]++
        }
        elseif ($line -match "^(.*?)\|RESPONSE\|(.*?)$") {
            $timestamp = $matches[1]
            $responseData = $matches[2] | ConvertFrom-Json
            
            $response = @{
                Timestamp = $timestamp
                Output = $responseData.output
                OutputSize = $responseData.output_size
                TimeMs = $responseData.time_ms
            }
            
            $responses += $response
            $metrics.TotalResponses++
            
            if ($responseData.output_size -gt $metrics.MaxOutputSize) {
                $metrics.MaxOutputSize = $responseData.output_size
            }
            
            if ($responseData.time_ms -gt $metrics.MaxResponseTime) {
                $metrics.MaxResponseTime = $responseData.time_ms
            }
            
            if ($responseData.time_ms -lt $metrics.MinResponseTime) {
                $metrics.MinResponseTime = $responseData.time_ms
            }
            
            # Associer la réponse à la requête correspondante
            if ($requests.Count -ge $responses.Count) {
                $request = $requests[$responses.Count - 1]
                if ($request.Mode) {
                    $metrics.ResponseTimesByMode[$request.Mode] += $responseData.time_ms
                }
            }
        }
    }

    # Calculer les moyennes
    if ($metrics.TotalRequests -gt 0) {
        $metrics.AverageInputSize = ($requests | Measure-Object -Property InputSize -Average).Average
    }
    
    if ($metrics.TotalResponses -gt 0) {
        $metrics.AverageOutputSize = ($responses | Measure-Object -Property OutputSize -Average).Average
        $metrics.AverageResponseTime = ($responses | Measure-Object -Property TimeMs -Average).Average
    }
    
    # Calculer les temps de réponse moyens par mode
    foreach ($mode in $metrics.ResponseTimesByMode.Keys) {
        $times = $metrics.ResponseTimesByMode[$mode]
        if ($times.Count -gt 0) {
            $metrics.ResponseTimesByMode[$mode] = ($times | Measure-Object -Average).Average
        }
        else {
            $metrics.ResponseTimesByMode[$mode] = 0
        }
    }
    
    # Si aucune réponse n'a été trouvée, définir MinResponseTime à 0
    if ($metrics.MinResponseTime -eq [int]::MaxValue) {
        $metrics.MinResponseTime = 0
    }

    return @{
        Requests = $requests
        Responses = $responses
        Metrics = $metrics
    }
}

# Fonction pour générer un rapport HTML
function Generate-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResults,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $metrics = $AnalysisResults.Metrics
    $requests = $AnalysisResults.Requests
    $responses = $AnalysisResults.Responses

    # Créer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de performances d'Augment Code</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .card {
            background-color: #fff;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .metric-name {
            font-weight: bold;
        }
        .metric-value {
            color: #3498db;
        }
        .chart-container {
            height: 300px;
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
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
            background-color: #f5f5f5;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport de performances d'Augment Code</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="card">
            <h2>Métriques globales</h2>
            <div class="metric">
                <span class="metric-name">Nombre total de requêtes</span>
                <span class="metric-value">$($metrics.TotalRequests)</span>
            </div>
            <div class="metric">
                <span class="metric-name">Nombre total de réponses</span>
                <span class="metric-value">$($metrics.TotalResponses)</span>
            </div>
            <div class="metric">
                <span class="metric-name">Temps de réponse moyen</span>
                <span class="metric-value">$([math]::Round($metrics.AverageResponseTime, 2)) ms</span>
            </div>
            <div class="metric">
                <span class="metric-name">Temps de réponse maximum</span>
                <span class="metric-value">$($metrics.MaxResponseTime) ms</span>
            </div>
            <div class="metric">
                <span class="metric-name">Temps de réponse minimum</span>
                <span class="metric-value">$($metrics.MinResponseTime) ms</span>
            </div>
            <div class="metric">
                <span class="metric-name">Taille moyenne des inputs</span>
                <span class="metric-value">$([math]::Round($metrics.AverageInputSize, 2)) caractères</span>
            </div>
            <div class="metric">
                <span class="metric-name">Taille moyenne des outputs</span>
                <span class="metric-value">$([math]::Round($metrics.AverageOutputSize, 2)) caractères</span>
            </div>
            <div class="metric">
                <span class="metric-name">Taille maximum des inputs</span>
                <span class="metric-value">$($metrics.MaxInputSize) caractères</span>
            </div>
            <div class="metric">
                <span class="metric-name">Taille maximum des outputs</span>
                <span class="metric-value">$($metrics.MaxOutputSize) caractères</span>
            </div>
        </div>
        
        <div class="card">
            <h2>Répartition par mode</h2>
            <div class="chart-container">
                <canvas id="requestsByModeChart"></canvas>
            </div>
            <div class="chart-container">
                <canvas id="responseTimesByModeChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>Détail des requêtes</h2>
            <table>
                <thead>
                    <tr>
                        <th>Horodatage</th>
                        <th>Mode</th>
                        <th>Input</th>
                        <th>Taille</th>
                    </tr>
                </thead>
                <tbody>
"@

    # Ajouter les détails des requêtes
    foreach ($request in $requests) {
        $htmlContent += @"
                    <tr>
                        <td>$($request.Timestamp)</td>
                        <td>$($request.Mode)</td>
                        <td>$($request.Input)</td>
                        <td>$($request.InputSize)</td>
                    </tr>
"@
    }

    $htmlContent += @"
                </tbody>
            </table>
        </div>
        
        <div class="card">
            <h2>Détail des réponses</h2>
            <table>
                <thead>
                    <tr>
                        <th>Horodatage</th>
                        <th>Temps (ms)</th>
                        <th>Taille</th>
                    </tr>
                </thead>
                <tbody>
"@

    # Ajouter les détails des réponses
    foreach ($response in $responses) {
        $htmlContent += @"
                    <tr>
                        <td>$($response.Timestamp)</td>
                        <td>$($response.TimeMs)</td>
                        <td>$($response.OutputSize)</td>
                    </tr>
"@
    }

    # Préparer les données pour les graphiques
    $modesJson = $metrics.RequestsByMode.Keys | ConvertTo-Json
    $requestsByModeJson = $metrics.RequestsByMode.Values | ConvertTo-Json
    $responseTimesByModeJson = $metrics.ResponseTimesByMode.Values | ConvertTo-Json

    $htmlContent += @"
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        // Graphique de répartition des requêtes par mode
        const requestsByModeCtx = document.getElementById('requestsByModeChart').getContext('2d');
        const requestsByModeChart = new Chart(requestsByModeCtx, {
            type: 'bar',
            data: {
                labels: $modesJson,
                datasets: [{
                    label: 'Nombre de requêtes',
                    data: $requestsByModeJson,
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Nombre de requêtes'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Mode'
                        }
                    }
                }
            }
        });
        
        // Graphique des temps de réponse par mode
        const responseTimesByModeCtx = document.getElementById('responseTimesByModeChart').getContext('2d');
        const responseTimesByModeChart = new Chart(responseTimesByModeCtx, {
            type: 'bar',
            data: {
                labels: $modesJson,
                datasets: [{
                    label: 'Temps de réponse moyen (ms)',
                    data: $responseTimesByModeJson,
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Temps de réponse (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Mode'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
}

# Analyser le fichier de log
Write-Host "Analyse du fichier de log : $logPath" -ForegroundColor Cyan
$analysisResults = Analyze-AugmentLog -LogPath $logPath

# Générer le rapport HTML
Write-Host "Génération du rapport HTML : $outputPath" -ForegroundColor Cyan
Generate-HtmlReport -AnalysisResults $analysisResults -OutputPath $outputPath

# Afficher un résumé
Write-Host "`nRésumé des performances d'Augment Code :" -ForegroundColor Green
Write-Host "Nombre total de requêtes : $($analysisResults.Metrics.TotalRequests)" -ForegroundColor Gray
Write-Host "Temps de réponse moyen : $([math]::Round($analysisResults.Metrics.AverageResponseTime, 2)) ms" -ForegroundColor Gray
Write-Host "Taille moyenne des inputs : $([math]::Round($analysisResults.Metrics.AverageInputSize, 2)) caractères" -ForegroundColor Gray
Write-Host "Taille moyenne des outputs : $([math]::Round($analysisResults.Metrics.AverageOutputSize, 2)) caractères" -ForegroundColor Gray

Write-Host "`nRépartition par mode :" -ForegroundColor Green
foreach ($mode in $analysisResults.Metrics.RequestsByMode.Keys) {
    $count = $analysisResults.Metrics.RequestsByMode[$mode]
    $time = [math]::Round($analysisResults.Metrics.ResponseTimesByMode[$mode], 2)
    Write-Host "$mode : $count requêtes, temps moyen : $time ms" -ForegroundColor Gray
}

Write-Host "`nRapport HTML généré : $outputPath" -ForegroundColor Green
Write-Host "Pour visualiser le rapport, ouvrez le fichier dans un navigateur web." -ForegroundColor Yellow
