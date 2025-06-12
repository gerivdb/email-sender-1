package tools

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// RealtimeDashboard provides real-time metrics dashboard functionality
type RealtimeDashboard struct {
	performanceMetrics *PerformanceMetrics
	driftDetector      *DriftDetector
	alertManager       *AlertManager
	logger             *log.Logger
	
	// WebSocket connections
	upgrader      websocket.Upgrader
	connections   map[string]*websocket.Conn
	connMutex     sync.RWMutex
	
	// Dashboard state
	lastUpdate    time.Time
	updateTicker  *time.Ticker
	httpServer    *http.Server
}

// DashboardData represents real-time dashboard data
type DashboardData struct {
	Timestamp         time.Time              `json:"timestamp"`
	SystemHealth      string                 `json:"system_health"`
	PerformanceMetrics map[string]interface{} `json:"performance_metrics"`
	BusinessMetrics   *BusinessMetrics       `json:"business_metrics"`
	RecentAlerts      []Alert                `json:"recent_alerts"`
	TrendAnalysis     *TrendAnalysis         `json:"trend_analysis"`
	SystemStatus      *SystemStatus          `json:"system_status"`
}

// SystemStatus represents current system status
type SystemStatus struct {
	CPUUsage         float64 `json:"cpu_usage"`
	MemoryUsage      uint64  `json:"memory_usage"`
	DiskUsage        float64 `json:"disk_usage"`
	ActiveConnections int     `json:"active_connections"`
	QueueSize        int     `json:"queue_size"`
	LastSyncTime     time.Time `json:"last_sync_time"`
	SyncStatus       string  `json:"sync_status"`
	ErrorCount       int     `json:"error_count"`
}

// NewRealtimeDashboard creates a new real-time dashboard
func NewRealtimeDashboard(
	performanceMetrics *PerformanceMetrics,
	driftDetector *DriftDetector,
	alertManager *AlertManager,
	logger *log.Logger,
) *RealtimeDashboard {
	
	return &RealtimeDashboard{
		performanceMetrics: performanceMetrics,
		driftDetector:      driftDetector,
		alertManager:       alertManager,
		logger:             logger,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for demo
			},
		},
		connections: make(map[string]*websocket.Conn),
		lastUpdate:  time.Now(),
	}
}

// StartDashboard starts the real-time dashboard server
func (rd *RealtimeDashboard) StartDashboard(port int) error {
	rd.logger.Printf("Starting real-time dashboard on port %d", port)

	// Setup HTTP routes
	http.HandleFunc("/", rd.handleDashboardPage)
	http.HandleFunc("/api/metrics", rd.handleMetricsAPI)
	http.HandleFunc("/api/health", rd.handleHealthAPI)
	http.HandleFunc("/api/alerts", rd.handleAlertsAPI)
	http.HandleFunc("/ws", rd.handleWebSocket)
	http.HandleFunc("/static/", rd.handleStatic)

	// Start update ticker for real-time data
	rd.updateTicker = time.NewTicker(5 * time.Second)
	go rd.broadcastUpdates()

	// Start HTTP server
	rd.httpServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: nil,
	}

	rd.logger.Printf("Dashboard available at http://localhost:%d", port)
	return rd.httpServer.ListenAndServe()
}

// Stop stops the dashboard server
func (rd *RealtimeDashboard) Stop() error {
	if rd.updateTicker != nil {
		rd.updateTicker.Stop()
	}
	
	if rd.httpServer != nil {
		return rd.httpServer.Close()
	}
	
	return nil
}

// handleDashboardPage serves the main dashboard HTML page
func (rd *RealtimeDashboard) handleDashboardPage(w http.ResponseWriter, r *http.Request) {
	html := `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Planning Ecosystem Sync - Real-time Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            min-height: 100vh;
        }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .subtitle { opacity: 0.8; font-size: 1.1em; }
        
        .metrics-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); 
            gap: 20px; 
            margin-bottom: 30px;
        }
        
        .metric-card { 
            background: rgba(255,255,255,0.1); 
            border-radius: 15px; 
            padding: 25px; 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            transition: transform 0.3s ease;
        }
        .metric-card:hover { transform: translateY(-5px); }
        
        .metric-header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            margin-bottom: 15px;
        }
        .metric-title { font-size: 1.1em; font-weight: 600; }
        .metric-status { 
            padding: 5px 12px; 
            border-radius: 20px; 
            font-size: 0.8em; 
            font-weight: bold;
        }
        .status-healthy { background: #2ecc71; }
        .status-warning { background: #f39c12; }
        .status-critical { background: #e74c3c; }
        
        .metric-value { 
            font-size: 2.5em; 
            font-weight: bold; 
            margin-bottom: 10px;
            text-align: center;
        }
        .metric-subtitle { 
            text-align: center; 
            opacity: 0.8; 
            font-size: 0.9em;
        }
        
        .alerts-panel { 
            background: rgba(255,255,255,0.1); 
            border-radius: 15px; 
            padding: 25px; 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            margin-bottom: 20px;
        }
        
        .alert-item { 
            background: rgba(231,76,60,0.2); 
            border-radius: 8px; 
            padding: 15px; 
            margin-bottom: 10px;
            border-left: 4px solid #e74c3c;
        }
        .alert-warning { border-left-color: #f39c12; background: rgba(243,156,18,0.2); }
        .alert-info { border-left-color: #3498db; background: rgba(52,152,219,0.2); }
        
        .trend-indicator { 
            display: inline-block; 
            margin-left: 10px; 
            font-size: 1.2em;
        }
        .trend-up { color: #2ecc71; }
        .trend-down { color: #e74c3c; }
        .trend-stable { color: #95a5a6; }
        
        .last-updated { 
            text-align: center; 
            margin-top: 20px; 
            opacity: 0.7; 
            font-size: 0.9em;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        .updating { animation: pulse 1s infinite; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 Planning Ecosystem Sync</h1>
            <div class="subtitle">Real-time Performance Dashboard</div>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">📊 Sync Performance</div>
                    <div class="metric-status status-healthy" id="sync-status">Healthy</div>
                </div>
                <div class="metric-value" id="avg-sync-time">--</div>
                <div class="metric-subtitle">Average Sync Time (ms)</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">⚡ Throughput</div>
                    <div class="metric-status status-healthy" id="throughput-status">Optimal</div>
                </div>
                <div class="metric-value" id="throughput-value">--</div>
                <div class="metric-subtitle">Tasks/second</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">🚨 Error Rate</div>
                    <div class="metric-status status-healthy" id="error-status">Low</div>
                </div>
                <div class="metric-value" id="error-rate">--</div>
                <div class="metric-subtitle">Errors (%)</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">💾 Memory Usage</div>
                    <div class="metric-status status-healthy" id="memory-status">Normal</div>
                </div>
                <div class="metric-value" id="memory-value">--</div>
                <div class="metric-subtitle">MB Used</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">📈 System Health</div>
                    <div class="metric-status status-healthy" id="health-status">Excellent</div>
                </div>
                <div class="metric-value" id="health-score">--</div>
                <div class="metric-subtitle">Health Score</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-title">🔄 Active Syncs</div>
                    <div class="metric-status status-healthy" id="active-status">Running</div>
                </div>
                <div class="metric-value" id="active-syncs">--</div>
                <div class="metric-subtitle">Operations in Progress</div>
            </div>
        </div>
        
        <div class="alerts-panel">
            <h3>🚨 Recent Alerts</h3>
            <div id="alerts-container">
                <div class="alert-item alert-info">
                    <strong>System Started</strong> - Dashboard monitoring initialized successfully
                </div>
            </div>
        </div>
        
        <div class="last-updated">
            Last updated: <span id="last-updated">--</span>
        </div>
    </div>
    
    <script>
        let ws;
        let connectionAttempts = 0;
        const maxReconnectAttempts = 5;
        
        function connectWebSocket() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = protocol + '//' + window.location.host + '/ws';
            
            ws = new WebSocket(wsUrl);
            
            ws.onopen = function() {
                console.log('WebSocket connected');
                connectionAttempts = 0;
                document.body.style.opacity = '1';
            };
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                updateDashboard(data);
            };
            
            ws.onclose = function() {
                console.log('WebSocket connection closed');
                if (connectionAttempts < maxReconnectAttempts) {
                    connectionAttempts++;
                    setTimeout(connectWebSocket, 2000 * connectionAttempts);
                }
            };
            
            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
            };
        }
        
        function updateDashboard(data) {
            // Update sync performance
            if (data.performance_metrics) {
                const metrics = data.performance_metrics;
                
                updateElement('avg-sync-time', metrics.avg_sync_duration || '--');
                updateElement('throughput-value', Math.round(metrics.avg_throughput || 0));
                updateElement('error-rate', (metrics.avg_error_rate || 0).toFixed(2));
                updateElement('memory-value', Math.round(metrics.current_memory_mb || 0));
                updateElement('health-score', metrics.health_status || 'Unknown');
                updateElement('active-syncs', metrics.total_samples || 0);
            }
            
            // Update alerts
            if (data.recent_alerts) {
                updateAlerts(data.recent_alerts);
            }
            
            // Update last updated time
            updateElement('last-updated', new Date().toLocaleTimeString());
            
            // Update status indicators
            updateStatusIndicators(data);
        }
        
        function updateElement(id, value) {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = value;
                element.classList.add('updating');
                setTimeout(() => element.classList.remove('updating'), 500);
            }
        }
        
        function updateStatusIndicators(data) {
            const healthStatus = data.system_health || 'unknown';
            
            // Update status badges based on metrics
            updateStatusBadge('sync-status', healthStatus);
            updateStatusBadge('throughput-status', healthStatus);
            updateStatusBadge('error-status', healthStatus);
            updateStatusBadge('memory-status', healthStatus);
            updateStatusBadge('health-status', healthStatus);
            updateStatusBadge('active-status', 'healthy');
        }
        
        function updateStatusBadge(id, status) {
            const element = document.getElementById(id);
            if (!element) return;
            
            element.className = 'metric-status';
            
            switch(status) {
                case 'healthy':
                    element.classList.add('status-healthy');
                    element.textContent = 'Healthy';
                    break;
                case 'warning':
                    element.classList.add('status-warning');
                    element.textContent = 'Warning';
                    break;
                case 'critical':
                    element.classList.add('status-critical');
                    element.textContent = 'Critical';
                    break;
                default:
                    element.classList.add('status-healthy');
                    element.textContent = 'Unknown';
            }
        }
        
        function updateAlerts(alerts) {
            const container = document.getElementById('alerts-container');
            if (!container || !alerts || alerts.length === 0) return;
            
            // Clear existing alerts except the first one (system started)
            const systemAlert = container.firstElementChild;
            container.innerHTML = '';
            container.appendChild(systemAlert);
            
            // Add new alerts (max 5)
            alerts.slice(0, 5).forEach(alert => {
                const alertDiv = document.createElement('div');
                alertDiv.className = 'alert-item';
                
                switch(alert.severity) {
                    case 'warning':
                        alertDiv.classList.add('alert-warning');
                        break;
                    case 'critical':
                        alertDiv.classList.add('alert-critical');
                        break;
                    default:
                        alertDiv.classList.add('alert-info');
                }
                
                alertDiv.innerHTML = 
                    '<strong>' + alert.type.replace('_', ' ').toUpperCase() + '</strong> - ' + 
                    alert.message + 
                    ' <small>(' + new Date(alert.timestamp).toLocaleTimeString() + ')</small>';
                
                container.appendChild(alertDiv);
            });
        }
        
        // Fallback API polling if WebSocket fails
        function pollMetrics() {
            fetch('/api/metrics')
                .then(response => response.json())
                .then(data => updateDashboard(data))
                .catch(error => console.error('Failed to fetch metrics:', error));
        }
        
        // Initialize
        connectWebSocket();
        
        // Fallback polling every 10 seconds
        setInterval(pollMetrics, 10000);
        
        // Initial data load
        pollMetrics();
    </script>
</body>
</html>`

	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))
}

// handleMetricsAPI serves metrics data via REST API
func (rd *RealtimeDashboard) handleMetricsAPI(w http.ResponseWriter, r *http.Request) {
	data := rd.collectDashboardData()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// handleHealthAPI serves health check endpoint
func (rd *RealtimeDashboard) handleHealthAPI(w http.ResponseWriter, r *http.Request) {
	health := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now(),
		"uptime":    time.Since(rd.lastUpdate).Seconds(),
		"version":   "1.0.0",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(health)
}

// handleAlertsAPI serves recent alerts
func (rd *RealtimeDashboard) handleAlertsAPI(w http.ResponseWriter, r *http.Request) {
	alerts := rd.alertManager.GetRecentAlerts(10)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"alerts": alerts,
		"count":  len(alerts),
	})
}

// handleWebSocket handles WebSocket connections for real-time updates
func (rd *RealtimeDashboard) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := rd.upgrader.Upgrade(w, r, nil)
	if err != nil {
		rd.logger.Printf("WebSocket upgrade failed: %v", err)
		return
	}
	
	// Generate connection ID
	connID := fmt.Sprintf("conn_%d", time.Now().UnixNano())
	
	rd.connMutex.Lock()
	rd.connections[connID] = conn
	rd.connMutex.Unlock()
	
	rd.logger.Printf("New WebSocket connection: %s", connID)
	
	// Send initial data
	data := rd.collectDashboardData()
	conn.WriteJSON(data)
	
	// Handle connection close
	go func() {
		defer func() {
			rd.connMutex.Lock()
			delete(rd.connections, connID)
			rd.connMutex.Unlock()
			conn.Close()
			rd.logger.Printf("WebSocket connection closed: %s", connID)
		}()
		
		// Keep connection alive and handle incoming messages
		for {
			_, _, err := conn.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
					rd.logger.Printf("WebSocket error: %v", err)
				}
				break
			}
		}
	}()
}

// handleStatic serves static files (placeholder)
func (rd *RealtimeDashboard) handleStatic(w http.ResponseWriter, r *http.Request) {
	http.NotFound(w, r)
}

// broadcastUpdates sends periodic updates to all connected WebSocket clients
func (rd *RealtimeDashboard) broadcastUpdates() {
	for range rd.updateTicker.C {
		data := rd.collectDashboardData()
		rd.broadcastToWebSockets(data)
		rd.lastUpdate = time.Now()
	}
}

// broadcastToWebSockets sends data to all connected WebSocket clients
func (rd *RealtimeDashboard) broadcastToWebSockets(data *DashboardData) {
	rd.connMutex.RLock()
	defer rd.connMutex.RUnlock()
	
	for connID, conn := range rd.connections {
		err := conn.WriteJSON(data)
		if err != nil {
			rd.logger.Printf("Failed to send WebSocket message to %s: %v", connID, err)
			// Connection will be cleaned up by the read goroutine
		}
	}
}

// collectDashboardData gathers all dashboard data from various sources
func (rd *RealtimeDashboard) collectDashboardData() *DashboardData {
	data := &DashboardData{
		Timestamp: time.Now(),
	}
	
	// Collect performance metrics
	if rd.performanceMetrics != nil {
		data.PerformanceMetrics = rd.performanceMetrics.GetRealtimeDashboardData()
		data.SystemHealth = fmt.Sprintf("%v", data.PerformanceMetrics["health_status"])
		
		// Generate performance report for trend analysis
		report := rd.performanceMetrics.GetPerformanceReport()
		data.TrendAnalysis = report.TrendAnalysis
		
		// Collect business metrics
		businessMetrics, err := rd.performanceMetrics.CollectBusinessMetrics()
		if err == nil {
			data.BusinessMetrics = businessMetrics
		}
	}
	
	// Collect recent alerts
	if rd.alertManager != nil {
		data.RecentAlerts = rd.alertManager.GetRecentAlerts(5)
	}
	
	// Collect system status
	data.SystemStatus = rd.collectSystemStatus()
	
	return data
}

// collectSystemStatus gathers current system status information
func (rd *RealtimeDashboard) collectSystemStatus() *SystemStatus {
	status := &SystemStatus{
		CPUUsage:         65.2,  // Mock values - would be collected from system
		MemoryUsage:      512 * 1024 * 1024, // 512MB
		DiskUsage:        42.8,
		ActiveConnections: len(rd.connections),
		QueueSize:        0,
		LastSyncTime:     time.Now().Add(-2 * time.Minute),
		SyncStatus:       "active",
		ErrorCount:       0,
	}
	
	return status
}

// GetConnectionCount returns the number of active WebSocket connections
func (rd *RealtimeDashboard) GetConnectionCount() int {
	rd.connMutex.RLock()
	defer rd.connMutex.RUnlock()
	return len(rd.connections)
}
