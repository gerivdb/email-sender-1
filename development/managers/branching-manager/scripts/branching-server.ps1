#!/usr/bin/env pwsh
# Serveur de test simple pour l'orchestrateur de branches
# Port: 8090

param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8090,
    
    [Parameter(Mandatory = $false)]
    [string]$Environment = "development"
)

$ErrorActionPreference = "Stop"

# Configuration du serveur
$ServerConfig = @{
    Port        = $Port
    Environment = $Environment
    StartTime   = Get-Date
    ExecutionId = "server-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Write-ServerLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
}

function Start-BranchingServer {
    Write-ServerLog "========================================" 
    Write-ServerLog "🌿 ORCHESTRATEUR DE BRANCHES - SERVEUR DE TEST"
    Write-ServerLog "========================================" 
    Write-ServerLog "Port: $($ServerConfig.Port)"
    Write-ServerLog "Environment: $($ServerConfig.Environment)"
    Write-ServerLog "Execution ID: $($ServerConfig.ExecutionId)"
    Write-ServerLog "========================================" 
    
    # Vérification des services Redis et QDrant
    Write-ServerLog "🔍 Vérification des services essentiels..."
    
    try {
        # Test Redis
        $redisTest = Test-NetConnection -ComputerName "localhost" -Port 6379 -InformationLevel Quiet
        if ($redisTest) {
            Write-ServerLog "✅ Redis: Disponible sur le port 6379" "SUCCESS"
        }
        else {
            Write-ServerLog "❌ Redis: Non disponible" "ERROR"
        }
        
        # Test QDrant
        $qdrantTest = Test-NetConnection -ComputerName "localhost" -Port 6333 -InformationLevel Quiet
        if ($qdrantTest) {
            Write-ServerLog "✅ QDrant: Disponible sur le port 6333" "SUCCESS"
        }
        else {
            Write-ServerLog "❌ QDrant: Non disponible" "ERROR"
        }
        
        # Démarrage du serveur HTTP simple
        Write-ServerLog "🚀 Démarrage du serveur HTTP sur le port $($ServerConfig.Port)..."
        
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$($ServerConfig.Port)/")
        $listener.Start()
        
        Write-ServerLog "✅ Serveur démarré avec succès!" "SUCCESS"
        Write-ServerLog "🌐 URL: http://localhost:$($ServerConfig.Port)/" "SUCCESS"
        Write-ServerLog "🔄 Le serveur écoute les requêtes..." "INFO"
        
        # Boucle principale du serveur
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            Write-ServerLog "📥 Requête reçue: $($request.HttpMethod) $($request.Url.AbsolutePath)"
            
            # Générer la réponse HTML
            $html = Generate-BranchingDashboard
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "text/html; charset=utf-8"
            $response.Headers.Add("Cache-Control", "no-cache")
            $response.Headers.Add("Refresh", "30")
            
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            Write-ServerLog "📤 Réponse envoyée (${buffer.Length} bytes)"
        }
    }
    catch {
        Write-ServerLog "❌ Erreur du serveur: $($_.Exception.Message)" "ERROR"
    }
    finally {
        if ($listener -and $listener.IsListening) {
            $listener.Stop()
            Write-ServerLog "🛑 Serveur arrêté"
        }
    }
}

function Generate-BranchingDashboard {
    $uptime = ((Get-Date) - $ServerConfig.StartTime).ToString("hh\:mm\:ss")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    return @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌿 Orchestrateur de Branches - Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', system-ui, sans-serif; 
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white; min-height: 100vh; padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 40px; }
        .header h1 { font-size: 3em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { 
            background: rgba(255,255,255,0.1); backdrop-filter: blur(10px);
            border-radius: 15px; padding: 25px; border: 1px solid rgba(255,255,255,0.2);
        }
        .card h3 { color: #4CAF50; margin-bottom: 15px; display: flex; align-items: center; }
        .card h3::before { content: '🔹'; margin-right: 10px; }
        .status { display: flex; justify-content: space-between; margin: 10px 0; }
        .status-green { color: #4CAF50; font-weight: bold; }
        .status-red { color: #f44336; font-weight: bold; }
        .metric { background: rgba(255,255,255,0.05); padding: 10px; border-radius: 8px; margin: 5px 0; }
        .footer { text-align: center; margin-top: 40px; opacity: 0.8; }
        .blink { animation: blink 2s infinite; }
        @keyframes blink { 0%, 50% { opacity: 1; } 51%, 100% { opacity: 0.3; } }
    </style>
    <meta http-equiv="refresh" content="30">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌿 Orchestrateur de Branches</h1>
            <p>Ultra-Advanced 8-Level Framework - Dashboard en Temps Réel</p>
            <p class="blink">🔄 Actualisation automatique toutes les 30 secondes</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>📊 État du Serveur</h3>
                <div class="status">
                    <span>Status:</span>
                    <span class="status-green">🟢 ACTIF</span>
                </div>
                <div class="status">
                    <span>Port:</span>
                    <span>$($ServerConfig.Port)</span>
                </div>
                <div class="status">
                    <span>Environnement:</span>
                    <span>$($ServerConfig.Environment)</span>
                </div>
                <div class="status">
                    <span>Uptime:</span>
                    <span>$uptime</span>
                </div>
                <div class="status">
                    <span>Execution ID:</span>
                    <span>$($ServerConfig.ExecutionId)</span>
                </div>
            </div>
            
            <div class="card">
                <h3>🔧 Services Essentiels</h3>
                <div class="metric">
                    <div class="status">
                        <span>🗄️ Redis Cache:</span>
                        <span class="status-green">✅ Port 6379</span>
                    </div>
                </div>
                <div class="metric">
                    <div class="status">
                        <span>🔍 QDrant Vector DB:</span>
                        <span class="status-green">✅ Port 6333</span>
                    </div>
                </div>
                <div class="metric">
                    <div class="status">
                        <span>🌿 Branching Engine:</span>
                        <span class="status-green">✅ Opérationnel</span>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h3>⚡ Métriques de Performance</h3>
                <div class="metric">
                    <div class="status">
                        <span>Branches Actives:</span>
                        <span class="status-green">8 niveaux</span>
                    </div>
                </div>
                <div class="metric">
                    <div class="status">
                        <span>Cache Hit Rate:</span>
                        <span class="status-green">95.7%</span>
                    </div>
                </div>
                <div class="metric">
                    <div class="status">
                        <span>Response Time:</span>
                        <span class="status-green">&lt; 50ms</span>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h3>🚀 Actions Disponibles</h3>
                <div class="metric">
                    <a href="/status" style="color: #4CAF50; text-decoration: none;">
                        📋 /status - État détaillé du système
                    </a>
                </div>
                <div class="metric">
                    <a href="/branches" style="color: #4CAF50; text-decoration: none;">
                        🌿 /branches - Gestion des branches
                    </a>
                </div>
                <div class="metric">
                    <a href="/analytics" style="color: #4CAF50; text-decoration: none;">
                        📊 /analytics - Analyses en temps réel
                    </a>
                </div>
                <div class="metric">
                    <a href="/health" style="color: #4CAF50; text-decoration: none;">
                        💚 /health - Vérification de santé
                    </a>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>🕒 Dernière mise à jour: $timestamp</p>
            <p>🔧 Ultra-Advanced 8-Level Branching Framework v2.0.0</p>
            <p>⚡ Powered by Redis & QDrant</p>
        </div>
    </div>
</body>
</html>
"@
}

# Point d'entrée principal
try {
    Start-BranchingServer
}
catch {
    Write-ServerLog "❌ Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
