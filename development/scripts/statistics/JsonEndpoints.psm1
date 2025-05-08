# JsonEndpoints.psm1
# Module pour l'exposition des rapports JSON via des endpoints HTTP

<#
.SYNOPSIS
    Démarre un serveur HTTP simple pour exposer les rapports JSON.

.DESCRIPTION
    Cette fonction démarre un serveur HTTP simple qui expose les rapports JSON
    via des endpoints REST. Le serveur utilise le module HttpListener de .NET.

.PARAMETER Port
    Le port sur lequel le serveur doit écouter (par défaut 8080).

.PARAMETER ReportsFolder
    Le dossier contenant les rapports JSON (par défaut "reports").

.PARAMETER CacheEnabled
    Indique si la mise en cache des rapports doit être activée (par défaut $true).

.PARAMETER CacheExpirationMinutes
    La durée de validité du cache en minutes (par défaut 5).

.EXAMPLE
    Start-JsonEndpointServer -Port 8080 -ReportsFolder "C:\Reports"
    Démarre un serveur HTTP sur le port 8080 qui expose les rapports JSON du dossier "C:\Reports".

.OUTPUTS
    System.Object
#>
function Start-JsonEndpointServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 8080,

        [Parameter(Mandatory = $false)]
        [string]$ReportsFolder = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),

        [Parameter(Mandatory = $false)]
        [bool]$CacheEnabled = $true,

        [Parameter(Mandatory = $false)]
        [int]$CacheExpirationMinutes = 5
    )

    # Vérifier que le dossier de rapports existe
    if (-not (Test-Path -Path $ReportsFolder)) {
        Write-Error "Le dossier de rapports n'existe pas: $ReportsFolder"
        return $null
    }

    # Créer un cache pour les rapports
    $cache = @{}
    $cacheTimestamps = @{}

    # Fonction pour vérifier si un rapport est en cache et valide
    function IsCacheValid {
        param (
            [string]$Key
        )

        if (-not $CacheEnabled) {
            return $false
        }

        if (-not $cache.ContainsKey($Key)) {
            return $false
        }

        $timestamp = $cacheTimestamps[$Key]
        $expirationTime = $timestamp.AddMinutes($CacheExpirationMinutes)
        return (Get-Date) -lt $expirationTime
    }

    # Fonction pour ajouter un rapport au cache
    function AddToCache {
        param (
            [string]$Key,
            [string]$Value
        )

        if (-not $CacheEnabled) {
            return
        }

        $cache[$Key] = $Value
        $cacheTimestamps[$Key] = Get-Date
    }

    # Fonction pour obtenir un rapport du cache
    function GetFromCache {
        param (
            [string]$Key
        )

        return $cache[$Key]
    }

    # Fonction pour gérer les requêtes HTTP
    function HandleRequest {
        param (
            [System.Net.HttpListenerContext]$Context
        )

        $request = $Context.Request
        $response = $Context.Response

        # Définir les en-têtes CORS
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        # Gérer les requêtes OPTIONS (CORS preflight)
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            return
        }

        # Gérer uniquement les requêtes GET
        if ($request.HttpMethod -ne "GET") {
            $response.StatusCode = 405 # Method Not Allowed
            $response.Close()
            return
        }

        # Analyser l'URL de la requête
        $url = $request.Url.LocalPath
        $segments = $url.Split("/", [System.StringSplitOptions]::RemoveEmptyEntries)

        # Endpoint racine : liste des rapports disponibles
        if ($segments.Count -eq 0 -or ($segments.Count -eq 1 -and $segments[0] -eq "reports")) {
            $reportFiles = Get-ChildItem -Path $ReportsFolder -Filter "*.json" | Select-Object Name, LastWriteTime, Length
            $reportsList = @{
                reports = @($reportFiles | ForEach-Object {
                    @{
                        name = $_.Name
                        lastModified = $_.LastWriteTime.ToString("o")
                        size = $_.Length
                        url = "http://localhost:$Port/reports/$($_.Name)"
                    }
                })
                count = $reportFiles.Count
                baseUrl = "http://localhost:$Port/reports"
            }

            $jsonResponse = $reportsList | ConvertTo-Json -Depth 3
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            return
        }

        # Endpoint pour un rapport spécifique
        if ($segments.Count -eq 2 -and $segments[0] -eq "reports") {
            $reportName = $segments[1]
            $reportPath = Join-Path -Path $ReportsFolder -ChildPath $reportName

            # Vérifier si le rapport existe
            if (-not (Test-Path -Path $reportPath)) {
                $response.StatusCode = 404 # Not Found
                $response.Close()
                return
            }

            # Vérifier si le rapport est en cache
            if (IsCacheValid -Key $reportName) {
                $jsonResponse = GetFromCache -Key $reportName
            } else {
                # Lire le rapport depuis le fichier
                $jsonResponse = Get-Content -Path $reportPath -Raw -Encoding UTF8
                # Ajouter le rapport au cache
                AddToCache -Key $reportName -Value $jsonResponse
            }

            $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            return
        }

        # Endpoint pour les statistiques du cache
        if ($segments.Count -eq 1 -and $segments[0] -eq "cache") {
            $cacheStats = @{
                enabled = $CacheEnabled
                expirationMinutes = $CacheExpirationMinutes
                itemCount = $cache.Count
                items = @($cache.Keys | ForEach-Object {
                    @{
                        key = $_
                        timestamp = $cacheTimestamps[$_].ToString("o")
                        expiresAt = $cacheTimestamps[$_].AddMinutes($CacheExpirationMinutes).ToString("o")
                        isValid = IsCacheValid -Key $_
                    }
                })
            }

            $jsonResponse = $cacheStats | ConvertTo-Json -Depth 3
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            return
        }

        # Endpoint non trouvé
        $response.StatusCode = 404 # Not Found
        $response.Close()
    }

    # Créer et démarrer le serveur HTTP
    try {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$Port/")
        $listener.Start()

        Write-Host "Serveur JSON démarré sur http://localhost:$Port/" -ForegroundColor Green
        Write-Host "Dossier de rapports: $ReportsFolder" -ForegroundColor Green
        Write-Host "Cache activé: $CacheEnabled" -ForegroundColor Green
        if ($CacheEnabled) {
            Write-Host "Expiration du cache: $CacheExpirationMinutes minutes" -ForegroundColor Green
        }
        Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur..." -ForegroundColor Yellow

        # Boucle principale du serveur
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            HandleRequest -Context $context
        }
    } catch {
        Write-Error "Erreur lors du démarrage du serveur HTTP: $_"
    } finally {
        if ($listener -ne $null) {
            $listener.Stop()
            $listener.Close()
        }
    }
}

<#
.SYNOPSIS
    Génère un client JavaScript pour accéder aux endpoints JSON.

.DESCRIPTION
    Cette fonction génère un client JavaScript qui peut être utilisé pour accéder
    aux endpoints JSON exposés par le serveur HTTP.

.PARAMETER OutputPath
    Le chemin du fichier de sortie JavaScript.

.PARAMETER ServerUrl
    L'URL du serveur JSON (par défaut "http://localhost:8080").

.EXAMPLE
    New-JsonEndpointClient -OutputPath "client.js" -ServerUrl "http://localhost:8080"
    Génère un client JavaScript pour accéder aux endpoints JSON du serveur sur "http://localhost:8080".

.OUTPUTS
    System.String
#>
function New-JsonEndpointClient {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:8080"
    )

    # Générer le code JavaScript du client
    $jsClient = @"
/**
 * Client JavaScript pour accéder aux endpoints JSON d'asymétrie
 * Généré automatiquement par New-JsonEndpointClient
 * URL du serveur: $ServerUrl
 */

class AsymmetryJsonClient {
    /**
     * Constructeur du client
     * @param {string} serverUrl - URL du serveur JSON
     */
    constructor(serverUrl = '$ServerUrl') {
        this.serverUrl = serverUrl;
    }

    /**
     * Récupère la liste des rapports disponibles
     * @returns {Promise<Object>} - Liste des rapports
     */
    async getReportsList() {
        try {
            const response = await fetch(`\${this.serverUrl}/reports`);
            if (!response.ok) {
                throw new Error(`Erreur HTTP: \${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('Erreur lors de la récupération de la liste des rapports:', error);
            throw error;
        }
    }

    /**
     * Récupère un rapport spécifique
     * @param {string} reportName - Nom du rapport
     * @returns {Promise<Object>} - Contenu du rapport
     */
    async getReport(reportName) {
        try {
            const response = await fetch(`\${this.serverUrl}/reports/\${reportName}`);
            if (!response.ok) {
                throw new Error(`Erreur HTTP: \${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error(`Erreur lors de la récupération du rapport \${reportName}:`, error);
            throw error;
        }
    }

    /**
     * Récupère les statistiques du cache
     * @returns {Promise<Object>} - Statistiques du cache
     */
    async getCacheStats() {
        try {
            const response = await fetch(`\${this.serverUrl}/cache`);
            if (!response.ok) {
                throw new Error(`Erreur HTTP: \${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('Erreur lors de la récupération des statistiques du cache:', error);
            throw error;
        }
    }

    /**
     * Crée un tableau HTML à partir d'un rapport
     * @param {Object} report - Rapport JSON
     * @returns {string} - Tableau HTML
     */
    createReportTable(report) {
        if (!report) {
            return '<p>Aucun rapport disponible</p>';
        }

        let html = '<table class="report-table">';
        
        // En-tête
        html += '<thead><tr><th colspan="2">Rapport d\'asymétrie</th></tr></thead>';
        
        // Métadonnées
        html += '<tbody>';
        html += `<tr><td>Titre</td><td>\${report.metadata.title}</td></tr>`;
        html += `<tr><td>Date de génération</td><td>\${report.metadata.generationDate}</td></tr>`;
        html += `<tr><td>Taille d'échantillon</td><td>\${report.metadata.sampleSize}</td></tr>`;
        
        // Résumé
        html += `<tr><th colspan="2">Résumé</th></tr>`;
        html += `<tr><td>Direction d'asymétrie</td><td>\${report.summary.asymmetryDirection}</td></tr>`;
        html += `<tr><td>Intensité d'asymétrie</td><td>\${report.summary.asymmetryIntensity}</td></tr>`;
        html += `<tr><td>Score composite</td><td>\${report.summary.compositeScore}</td></tr>`;
        html += `<tr><td>Méthode recommandée</td><td>\${report.summary.recommendedMethod}</td></tr>`;
        
        // Statistiques
        html += `<tr><th colspan="2">Statistiques</th></tr>`;
        html += `<tr><td>Minimum</td><td>\${report.statistics.min}</td></tr>`;
        html += `<tr><td>Maximum</td><td>\${report.statistics.max}</td></tr>`;
        html += `<tr><td>Moyenne</td><td>\${report.statistics.mean}</td></tr>`;
        html += `<tr><td>Médiane</td><td>\${report.statistics.median}</td></tr>`;
        html += `<tr><td>Écart-type</td><td>\${report.statistics.stdDev}</td></tr>`;
        html += `<tr><td>Coefficient d'asymétrie</td><td>\${report.statistics.skewness}</td></tr>`;
        
        html += '</tbody></table>';
        
        return html;
    }

    /**
     * Crée un graphique d'histogramme à partir d'un rapport
     * @param {Object} report - Rapport JSON
     * @param {string} canvasId - ID du canvas pour le graphique
     */
    createHistogramChart(report, canvasId) {
        if (!report || !report.data || !report.data.histogram) {
            console.error('Données d\'histogramme non disponibles dans le rapport');
            return;
        }

        const ctx = document.getElementById(canvasId).getContext('2d');
        
        const histogramData = {
            labels: [],
            datasets: [{
                label: 'Fréquence',
                data: report.data.histogram.frequencies,
                backgroundColor: 'rgba(52, 152, 219, 0.5)',
                borderColor: 'rgba(52, 152, 219, 1)',
                borderWidth: 1
            }]
        };
        
        // Créer les étiquettes des classes
        const bins = report.data.histogram.bins;
        for (let i = 0; i < bins.length - 1; i++) {
            histogramData.labels.push(`[\${bins[i]}, \${bins[i+1]})`);
        }
        
        new Chart(ctx, {
            type: 'bar',
            data: histogramData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    title: {
                        display: true,
                        text: 'Distribution des données'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Fréquence'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Valeurs'
                        }
                    }
                }
            }
        });
    }
}

// Exporter le client
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AsymmetryJsonClient;
}
"@

    # Écrire le code JavaScript dans un fichier si un chemin est spécifié
    if ($OutputPath -ne "") {
        try {
            $jsClient | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Verbose "Client JavaScript écrit dans le fichier: $OutputPath"
        } catch {
            Write-Error "Erreur lors de l'écriture du client JavaScript dans le fichier: $_"
        }
    }

    return $jsClient
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Start-JsonEndpointServer, New-JsonEndpointClient
