// internal/monitoring/realtime_dashboard.go
package monitoring

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/contextual-memory-manager/interfaces"
	"go.uber.org/zap"
)

// RealTimeDashboard fournit un dashboard web temps réel pour les métriques
type RealTimeDashboard struct {
	metricsCollector interfaces.HybridMetricsManager
	server          *http.Server
	logger          *zap.Logger
	clients         map[string]chan []byte
	clientsMu       sync.RWMutex
	updateInterval  time.Duration
	stopChan        chan struct{}
}

// NewRealTimeDashboard crée une nouvelle instance du dashboard
func NewRealTimeDashboard(
	metricsCollector interfaces.HybridMetricsManager,
	logger *zap.Logger,
	port int,
) *RealTimeDashboard {
	dashboard := &RealTimeDashboard{
		metricsCollector: metricsCollector,
		logger:          logger,
		clients:         make(map[string]chan []byte),
		updateInterval:  time.Second * 2, // Mise à jour toutes les 2 secondes
		stopChan:        make(chan struct{}),
	}

	// Configuration du serveur HTTP
	mux := http.NewServeMux()
	mux.HandleFunc("/", dashboard.handleDashboard)
	mux.HandleFunc("/api/metrics", dashboard.handleMetricsAPI)
	mux.HandleFunc("/api/stream", dashboard.handleMetricsStream)
	mux.HandleFunc("/health", dashboard.handleHealth)

	dashboard.server = &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: mux,
	}

	return dashboard
}

// Start démarre le dashboard
func (rtd *RealTimeDashboard) Start(ctx context.Context) error {
	// Démarrer le serveur HTTP
	go func() {
		rtd.logger.Info("Starting real-time dashboard", zap.String("addr", rtd.server.Addr))
		if err := rtd.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			rtd.logger.Error("Dashboard server error", zap.Error(err))
		}
	}()

	// Démarrer le streaming des métriques
	go rtd.startMetricsStreaming(ctx)

	return nil
}

// Stop arrête le dashboard
func (rtd *RealTimeDashboard) Stop() error {
	close(rtd.stopChan)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return rtd.server.Shutdown(ctx)
}

// handleDashboard sert la page HTML du dashboard
func (rtd *RealTimeDashboard) handleDashboard(w http.ResponseWriter, r *http.Request) {
	html := rtd.generateDashboardHTML()
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))
}

// handleMetricsAPI fournit les métriques en JSON
func (rtd *RealTimeDashboard) handleMetricsAPI(w http.ResponseWriter, r *http.Request) {
	stats := rtd.metricsCollector.GetStatistics()
	summary := rtd.metricsCollector.GetMetricsSummary()

	response := map[string]interface{}{
		"statistics": stats,
		"summary":    summary,
		"timestamp":  time.Now().Unix(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleMetricsStream gère le streaming temps réel via Server-Sent Events
func (rtd *RealTimeDashboard) handleMetricsStream(w http.ResponseWriter, r *http.Request) {
	// Configuration pour Server-Sent Events
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// Créer un canal pour ce client
	clientID := fmt.Sprintf("client_%d", time.Now().UnixNano())
	clientChan := make(chan []byte, 10)

	rtd.clientsMu.Lock()
	rtd.clients[clientID] = clientChan
	rtd.clientsMu.Unlock()

	// Nettoyer à la fermeture de la connexion
	defer func() {
		rtd.clientsMu.Lock()
		delete(rtd.clients, clientID)
		close(clientChan)
		rtd.clientsMu.Unlock()
	}()

	// Envoyer les données au client
	for {
		select {
		case data := <-clientChan:
			fmt.Fprintf(w, "data: %s\n\n", data)
			if flusher, ok := w.(http.Flusher); ok {
				flusher.Flush()
			}
		case <-r.Context().Done():
			return
		}
	}
}

// handleHealth endpoint de santé
func (rtd *RealTimeDashboard) handleHealth(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"clients":   len(rtd.clients),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// startMetricsStreaming démarre le streaming des métriques
func (rtd *RealTimeDashboard) startMetricsStreaming(ctx context.Context) {
	ticker := time.NewTicker(rtd.updateInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			rtd.broadcastMetrics()
		case <-rtd.stopChan:
			return
		case <-ctx.Done():
			return
		}
	}
}

// broadcastMetrics diffuse les métriques à tous les clients connectés
func (rtd *RealTimeDashboard) broadcastMetrics() {
	stats := rtd.metricsCollector.GetStatistics()
	summary := rtd.metricsCollector.GetMetricsSummary()

	data := map[string]interface{}{
		"statistics": stats,
		"summary":    summary,
		"timestamp":  time.Now().Unix(),
	}

	jsonData, err := json.Marshal(data)
	if err != nil {
		rtd.logger.Error("Failed to marshal metrics data", zap.Error(err))
		return
	}

	rtd.clientsMu.RLock()
	defer rtd.clientsMu.RUnlock()

	for _, clientChan := range rtd.clients {
		select {
		case clientChan <- jsonData:
		default:
			// Canal plein, ignorer cette mise à jour pour ce client
		}
	}
}

// generateDashboardHTML génère le HTML du dashboard
func (rtd *RealTimeDashboard) generateDashboardHTML() string {
	return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hybrid Memory Manager - Dashboard Temps Réel</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .dashboard {
            max-width: 1400px;
            margin: 0 auto;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .metric-card h3 {
            margin: 0 0 15px 0;
            font-size: 1.2em;
            color: #fff;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
        .metric-label {
            font-size: 0.9em;
            opacity: 0.8;
        }
        .chart-container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            margin-bottom: 20px;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        .status-good { background-color: #4CAF50; }
        .status-warning { background-color: #FF9800; }
        .status-error { background-color: #F44336; }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            overflow: hidden;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
            transition: width 0.3s ease;
        }
        .error-log {
            max-height: 200px;
            overflow-y: auto;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 5px;
            padding: 10px;
            font-family: monospace;
            font-size: 0.8em;
        }
        .timestamp {
            opacity: 0.7;
            font-size: 0.8em;
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>🧠 Hybrid Memory Manager Dashboard</h1>
            <div class="timestamp">Dernière mise à jour: <span id="lastUpdate">-</span></div>
        </div>

        <div class="metrics-grid">
            <div class="metric-card">
                <h3>📊 Requêtes Totales</h3>
                <div class="metric-value" id="totalQueries">0</div>
                <div class="metric-label">Total des requêtes traitées</div>
            </div>

            <div class="metric-card">
                <h3>⚡ Latence Moyenne</h3>
                <div class="metric-value" id="avgLatency">0ms</div>
                <div class="metric-label">Temps de réponse moyen</div>
            </div>

            <div class="metric-card">
                <h3>✅ Taux de Succès</h3>
                <div class="metric-value" id="successRate">0%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="successProgress" style="width: 0%"></div>
                </div>
            </div>

            <div class="metric-card">
                <h3>🎯 Score de Qualité</h3>
                <div class="metric-value" id="qualityScore">0.0</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="qualityProgress" style="width: 0%"></div>
                </div>
            </div>
        </div>

        <div class="chart-container">
            <h3>🔄 Distribution des Modes de Recherche</h3>
            <div id="modeDistribution">
                <div>AST: <span id="astQueries">0</span> requêtes</div>
                <div>RAG: <span id="ragQueries">0</span> requêtes</div>
                <div>Hybride: <span id="hybridQueries">0</span> requêtes</div>
                <div>Parallèle: <span id="parallelQueries">0</span> requêtes</div>
            </div>
        </div>

        <div class="chart-container">
            <h3>🎯 Performance par Mode</h3>
            <div id="modePerformance"></div>
        </div>

        <div class="chart-container">
            <h3>🚨 Erreurs Récentes</h3>
            <div class="error-log" id="errorLog">Aucune erreur récente</div>
        </div>
    </div>

    <script>
        // Connexion au stream de métriques
        const eventSource = new EventSource('/api/stream');
        
        eventSource.onmessage = function(event) {
            const data = JSON.parse(event.data);
            updateDashboard(data);
        };

        function updateDashboard(data) {
            const stats = data.statistics;
            const summary = data.summary;

            // Mise à jour des métriques principales
            document.getElementById('totalQueries').textContent = stats.total_queries;
            document.getElementById('lastUpdate').textContent = new Date().toLocaleTimeString();

            // Latence moyenne
            const avgLatency = calculateAverageLatency(stats.average_latency);
            document.getElementById('avgLatency').textContent = avgLatency + 'ms';

            // Taux de succès global
            const avgSuccessRate = calculateAverageSuccessRate(stats.success_rates);
            document.getElementById('successRate').textContent = (avgSuccessRate * 100).toFixed(1) + '%';
            document.getElementById('successProgress').style.width = (avgSuccessRate * 100) + '%';

            // Score de qualité global
            const avgQualityScore = calculateAverageQualityScore(stats.quality_scores);
            document.getElementById('qualityScore').textContent = avgQualityScore.toFixed(2);
            document.getElementById('qualityProgress').style.width = (avgQualityScore * 100) + '%';

            // Distribution des modes
            document.getElementById('astQueries').textContent = stats.ast_queries;
            document.getElementById('ragQueries').textContent = stats.rag_queries;
            document.getElementById('hybridQueries').textContent = stats.hybrid_queries;
            document.getElementById('parallelQueries').textContent = stats.parallel_queries;

            // Performance par mode
            updateModePerformance(stats);

            // Erreurs récentes
            updateErrorLog(stats.last_errors);
        }

        function calculateAverageLatency(latencies) {
            const values = Object.values(latencies);
            if (values.length === 0) return 0;
            
            const totalMs = values.reduce((sum, duration) => {
                // Convertir duration (nanosecondes) en millisecondes
                return sum + (duration / 1000000);
            }, 0);
            
            return Math.round(totalMs / values.length);
        }

        function calculateAverageSuccessRate(rates) {
            const values = Object.values(rates);
            if (values.length === 0) return 0;
            
            return values.reduce((sum, rate) => sum + rate, 0) / values.length;
        }

        function calculateAverageQualityScore(scores) {
            const values = Object.values(scores);
            if (values.length === 0) return 0;
            
            return values.reduce((sum, score) => sum + score, 0) / values.length;
        }

        function updateModePerformance(stats) {
            const container = document.getElementById('modePerformance');
            let html = '';

            const modes = ['ast', 'rag', 'hybrid', 'parallel'];
            
            modes.forEach(mode => {
                const latency = stats.average_latency[mode] || 0;
                const successRate = stats.success_rates[mode] || 0;
                const qualityScore = stats.quality_scores[mode] || 0;
                
                const latencyMs = Math.round(latency / 1000000);
                const statusClass = successRate > 0.9 ? 'status-good' : 
                                  successRate > 0.7 ? 'status-warning' : 'status-error';

                html += \`
                    <div style="margin: 10px 0; padding: 10px; background: rgba(255,255,255,0.05); border-radius: 8px;">
                        <div><span class="status-indicator \${statusClass}"></span><strong>\${mode.toUpperCase()}</strong></div>
                        <div>Latence: \${latencyMs}ms | Succès: \${(successRate * 100).toFixed(1)}% | Qualité: \${qualityScore.toFixed(2)}</div>
                    </div>
                \`;
            });

            container.innerHTML = html;
        }

        function updateErrorLog(errors) {
            const container = document.getElementById('errorLog');
            
            if (!errors || errors.length === 0) {
                container.innerHTML = 'Aucune erreur récente';
                return;
            }

            let html = '';
            errors.slice(-10).reverse().forEach(error => {
                const timestamp = new Date(error.timestamp).toLocaleTimeString();
                html += \`<div>[\${timestamp}] \${error.mode}: \${error.message}</div>\`;
            });

            container.innerHTML = html;
        }

        // Gestion des erreurs de connexion
        eventSource.onerror = function(event) {
            console.error('Erreur de connexion au stream:', event);
            document.getElementById('lastUpdate').textContent = 'Connexion perdue - Tentative de reconnexion...';
        };
    </script>
</body>
</html>
`
}
