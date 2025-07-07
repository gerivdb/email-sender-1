// Package monitoring implements the Real-Time Monitoring Dashboard component
// of the AdvancedAutonomyManager - live surveillance and metrics dashboard
package monitoring

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/interfaces"
)

// MonitoringConfig configure le dashboard temps réel
type MonitoringConfig struct {
	DashboardPort    int                `yaml:"dashboard_port" json:"dashboard_port"`
	UpdateInterval   time.Duration      `yaml:"update_interval" json:"update_interval"`
	MetricsRetention time.Duration      `yaml:"metrics_retention" json:"metrics_retention"`
	AlertThresholds  map[string]float64 `yaml:"alert_thresholds" json:"alert_thresholds"`
	WebSocketEnabled bool               `yaml:"websocket_enabled" json:"websocket_enabled"`

	// Nouveaux champs pour RealTimeMonitoringDashboard
	HTTPSEnabled      bool          `yaml:"https_enabled" json:"https_enabled"`
	CertFile          string        `yaml:"cert_file" json:"cert_file"`
	KeyFile           string        `yaml:"key_file" json:"key_file"`
	AggregationWindow time.Duration `yaml:"aggregation_window" json:"aggregation_window"`
	TrendAnalysis     bool          `yaml:"trend_analysis" json:"trend_analysis"`
}

// AlertRule représente une règle d'alerte
type AlertRule struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Condition string  `json:"condition"`
	Threshold float64 `json:"threshold"`
	Severity  string  `json:"severity"`
	Enabled   bool    `json:"enabled"`
}

// NotificationChannel représente un canal de notification
type NotificationChannel struct {
	Type    string                 `json:"type"`
	Config  map[string]interface{} `json:"config"`
	Enabled bool                   `json:"enabled"`
}

// EscalationRule représente une règle d'escalade
type EscalationRule struct {
	Level   int           `json:"level"`
	Delay   time.Duration `json:"delay"`
	Actions []string      `json:"actions"`
}

// DashboardTemplate représente un template de dashboard
type DashboardTemplate struct {
	Name    string                 `json:"name"`
	Layout  map[string]interface{} `json:"layout"`
	Widgets []Widget               `json:"widgets"`
}

// MiddlewareFunc représente une fonction middleware
type MiddlewareFunc func(http.Handler) http.Handler

// Widget représente un widget du dashboard
type Widget struct {
	ID       string                 `json:"id"`
	Type     string                 `json:"type"`
	Title    string                 `json:"title"`
	Config   map[string]interface{} `json:"config"`
	Position Position               `json:"position"`
}

// Position représente la position d'un widget
type Position struct {
	X      int `json:"x"`
	Y      int `json:"y"`
	Width  int `json:"width"`
	Height int `json:"height"`
}

// RealTimeMonitoringDashboard est le tableau de bord de surveillance temps réel
// qui surveille en continu les 20 managers, collecte les métriques, génère des alertes
// et fournit une visualisation web temps réel avec WebSocket.
type RealTimeMonitoringDashboard struct {
	config *MonitoringConfig
	logger interfaces.Logger

	// Composants de surveillance
	metricsCollector *MetricsCollector
	alertingSystem   *AlertingSystem
	webDashboard     *WebDashboard
	websocketServer  *WebSocketServer
	dataAggregator   *DataAggregator

	// Stockage en temps réel
	liveMetrics  map[string]*LiveMetrics
	alertHistory []*Alert
	systemEvents []*SystemEvent

	// État et synchronisation
	mutex       sync.RWMutex
	initialized bool
	running     bool

	// Serveur web et connectivité
	httpServer    *http.Server
	wsConnections map[string]*WebSocketConnection
	connMutex     sync.RWMutex

	// Processus de surveillance
	collectionTicker  *time.Ticker
	aggregationTicker *time.Ticker
	cleanupTicker     *time.Ticker
}

// AlertSeverity niveau de sévérité d'alerte
type AlertSeverity int

const (
	AlertSeverityInfo AlertSeverity = iota
	AlertSeverityWarning
	AlertSeverityCritical
	AlertSeverityEmergency
)

// EventSeverity niveau de sévérité d'événement
type EventSeverity int

const (
	EventSeverityDebug EventSeverity = iota
	EventSeverityInfo
	EventSeverityWarning
	EventSeverityError
	EventSeverityCritical
)

// NewRealTimeMonitoringDashboard crée une nouvelle instance du dashboard
func NewRealTimeMonitoringDashboard(config *MonitoringConfig, logger interfaces.Logger) (*RealTimeMonitoringDashboard, error) {
	if config == nil {
		return nil, fmt.Errorf("monitoring config is required")
	}

	if logger == nil {
		return nil, fmt.Errorf("logger is required")
	}

	// Valider la configuration
	if err := validateMonitoringConfig(config); err != nil {
		return nil, fmt.Errorf("invalid monitoring config: %w", err)
	}

	dashboard := &RealTimeMonitoringDashboard{
		config:        config,
		logger:        logger,
		liveMetrics:   make(map[string]*LiveMetrics),
		alertHistory:  make([]*Alert, 0),
		systemEvents:  make([]*SystemEvent, 0),
		wsConnections: make(map[string]*WebSocketConnection),
	}

	// Initialiser les composants
	if err := dashboard.initializeComponents(); err != nil {
		return nil, fmt.Errorf("failed to initialize dashboard components: %w", err)
	}

	return dashboard, nil
}

// Initialize initialise le dashboard de surveillance
func (rtmd *RealTimeMonitoringDashboard) Initialize(ctx context.Context) error {
	rtmd.mutex.Lock()
	defer rtmd.mutex.Unlock()

	if rtmd.initialized {
		return fmt.Errorf("monitoring dashboard already initialized")
	}

	rtmd.logger.Info("Initializing Real-Time Monitoring Dashboard")

	// Initialiser les composants dans l'ordre
	components := []struct {
		name string
		init func(context.Context) error
	}{
		{"MetricsCollector", rtmd.metricsCollector.Initialize},
		{"DataAggregator", rtmd.dataAggregator.Initialize},
		{"AlertingSystem", rtmd.alertingSystem.Initialize},
		{"WebDashboard", rtmd.webDashboard.Initialize},
	}

	for _, component := range components {
		if err := component.init(ctx); err != nil {
			return fmt.Errorf("failed to initialize %s: %w", component.name, err)
		}
	}

	// Initialiser le serveur WebSocket si activé
	if rtmd.config.WebSocketEnabled {
		if err := rtmd.websocketServer.Initialize(ctx); err != nil {
			return fmt.Errorf("failed to initialize WebSocket server: %w", err)
		}
	}

	// Démarrer le serveur HTTP
	if err := rtmd.startHTTPServer(); err != nil {
		return fmt.Errorf("failed to start HTTP server: %w", err)
	}

	// Démarrer la collecte de métriques
	rtmd.startMetricsCollection()

	// Démarrer l'agrégation de données
	rtmd.startDataAggregation()

	// Démarrer le nettoyage automatique
	rtmd.startAutomaticCleanup()

	rtmd.initialized = true
	rtmd.running = true
	rtmd.logger.Info(fmt.Sprintf("Real-Time Monitoring Dashboard started on port %d", rtmd.config.DashboardPort))

	return nil
}

// HealthCheck vérifie la santé du dashboard
func (rtmd *RealTimeMonitoringDashboard) HealthCheck(ctx context.Context) error {
	rtmd.mutex.RLock()
	defer rtmd.mutex.RUnlock()

	if !rtmd.initialized {
		return fmt.Errorf("monitoring dashboard not initialized")
	}

	if !rtmd.running {
		return fmt.Errorf("monitoring dashboard not running")
	}

	// Vérifier tous les composants
	checks := []struct {
		name  string
		check func(context.Context) error
	}{
		{"MetricsCollector", rtmd.metricsCollector.HealthCheck},
		{"AlertingSystem", rtmd.alertingSystem.HealthCheck},
		{"WebDashboard", rtmd.webDashboard.HealthCheck},
		{"DataAggregator", rtmd.dataAggregator.HealthCheck},
	}

	for _, check := range checks {
		if err := check.check(ctx); err != nil {
			return fmt.Errorf("%s health check failed: %w", check.name, err)
		}
	}

	// Vérifier le serveur WebSocket si activé
	if rtmd.config.WebSocketEnabled {
		if err := rtmd.websocketServer.HealthCheck(ctx); err != nil {
			return fmt.Errorf("WebSocket server health check failed: %w", err)
		}
	}

	// Vérifier que nous collectons des métriques récentes
	rtmd.mutex.RLock()
	hasRecentMetrics := false
	cutoff := time.Now().Add(-2 * rtmd.config.UpdateInterval)
	for _, metrics := range rtmd.liveMetrics {
		if metrics.LastUpdate.After(cutoff) {
			hasRecentMetrics = true
			break
		}
	}
	rtmd.mutex.RUnlock()

	if !hasRecentMetrics {
		return fmt.Errorf("no recent metrics collected")
	}

	return nil
}

// Cleanup nettoie les ressources du dashboard
func (rtmd *RealTimeMonitoringDashboard) Cleanup() error {
	rtmd.mutex.Lock()
	defer rtmd.mutex.Unlock()

	rtmd.logger.Info("Cleaning up Real-Time Monitoring Dashboard")

	rtmd.running = false

	// Arrêter les tickers
	if rtmd.collectionTicker != nil {
		rtmd.collectionTicker.Stop()
	}
	if rtmd.aggregationTicker != nil {
		rtmd.aggregationTicker.Stop()
	}
	if rtmd.cleanupTicker != nil {
		rtmd.cleanupTicker.Stop()
	}

	// Arrêter le serveur HTTP
	if rtmd.httpServer != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := rtmd.httpServer.Shutdown(ctx); err != nil {
			rtmd.logger.WithError(err).Error("Failed to shutdown HTTP server gracefully")
		}
	}

	// Fermer toutes les connexions WebSocket
	rtmd.connMutex.Lock()
	for _, conn := range rtmd.wsConnections {
		if err := rtmd.closeWebSocketConnection(conn); err != nil {
			rtmd.logger.WithError(err).Warn(fmt.Sprintf("Failed to close WebSocket connection %s", conn.ID))
		}
	}
	rtmd.wsConnections = make(map[string]*WebSocketConnection)
	rtmd.connMutex.Unlock()

	// Nettoyer tous les composants
	var errors []error

	components := []struct {
		name    string
		cleanup func() error
	}{
		{"WebSocketServer", rtmd.websocketServer.Cleanup},
		{"WebDashboard", rtmd.webDashboard.Cleanup},
		{"AlertingSystem", rtmd.alertingSystem.Cleanup},
		{"DataAggregator", rtmd.dataAggregator.Cleanup},
		{"MetricsCollector", rtmd.metricsCollector.Cleanup},
	}

	for _, component := range components {
		if component.cleanup != nil {
			if err := component.cleanup(); err != nil {
				errors = append(errors, fmt.Errorf("%s cleanup failed: %w", component.name, err))
			}
		}
	}

	// Vider les données en mémoire
	rtmd.liveMetrics = make(map[string]*LiveMetrics)
	rtmd.alertHistory = make([]*Alert, 0)
	rtmd.systemEvents = make([]*SystemEvent, 0)

	rtmd.initialized = false

	if len(errors) > 0 {
		return fmt.Errorf("cleanup completed with errors: %v", errors)
	}

	rtmd.logger.Info("Real-Time Monitoring Dashboard cleanup completed successfully")
	return nil
}

// GenerateEcosystemHealthReport génère un rapport de santé de l'écosystème
func (rtmd *RealTimeMonitoringDashboard) GenerateEcosystemHealthReport(ctx context.Context, managerConnections map[string]interfaces.BaseManager) (*interfaces.EcosystemHealth, error) {
	rtmd.logger.Info("Generating ecosystem health report")

	// Mettre à jour les connexions des managers
	rtmd.metricsCollector.UpdateManagerConnections(managerConnections)

	// Collecter les métriques actuelles
	currentMetrics, err := rtmd.metricsCollector.CollectAllMetrics(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to collect current metrics: %w", err)
	}

	// Calculer la santé globale
	overallHealth := rtmd.calculateOverallHealth(currentMetrics)

	// Collecter les alertes actives
	activeAlerts := rtmd.alertingSystem.GetActiveAlerts()

	// Collecter les événements récents
	recentEvents := rtmd.getRecentEvents(1 * time.Hour)

	// Générer des insights prédictifs
	predictiveInsights, err := rtmd.dataAggregator.GeneratePredictiveInsights(ctx, currentMetrics)
	if err != nil {
		rtmd.logger.WithError(err).Warn("Failed to generate predictive insights")
		predictiveInsights = make([]*interfaces.PredictiveInsight, 0)
	}

	// Compiler le rapport de santé
	healthReport := &interfaces.EcosystemHealth{
		Timestamp:           time.Now(),
		OverallHealthScore:  overallHealth,
		ManagerStates:       rtmd.convertToManagerStates(currentMetrics),
		ActiveAlerts:        activeAlerts,
		RecentEvents:        recentEvents,
		PredictiveInsights:  predictiveInsights,
		PerformanceMetrics:  rtmd.aggregatePerformanceMetrics(currentMetrics),
		SystemStatus:        rtmd.determineSystemStatus(overallHealth, activeAlerts),
		ResourceUtilization: rtmd.aggregateResourceUtilization(currentMetrics),
	}

	return healthReport, nil
}

// ConnectWebSocket connecte un client WebSocket
func (rtmd *RealTimeMonitoringDashboard) ConnectWebSocket(userID string, subscriptions []string) (*WebSocketConnection, error) {
	if !rtmd.config.WebSocketEnabled {
		return nil, fmt.Errorf("WebSocket is disabled")
	}

	conn := &WebSocketConnection{
		ID:            fmt.Sprintf("ws-%d", time.Now().UnixNano()),
		UserID:        userID,
		ConnectedAt:   time.Now(),
		LastPing:      time.Now(),
		Subscriptions: subscriptions,
	}

	rtmd.connMutex.Lock()
	rtmd.wsConnections[conn.ID] = conn
	rtmd.connMutex.Unlock()

	rtmd.logger.Info(fmt.Sprintf("WebSocket client connected: %s (user: %s)", conn.ID, userID))

	return conn, nil
}

// BroadcastUpdate diffuse une mise à jour à tous les clients WebSocket
func (rtmd *RealTimeMonitoringDashboard) BroadcastUpdate(updateType string, data interface{}) error {
	if !rtmd.config.WebSocketEnabled {
		return nil
	}

	return rtmd.websocketServer.BroadcastMessage(updateType, data)
}

// GetLiveMetrics retourne les métriques actuelles
func (rtmd *RealTimeMonitoringDashboard) GetLiveMetrics() map[string]*LiveMetrics {
	rtmd.mutex.RLock()
	defer rtmd.mutex.RUnlock()

	// Copier les métriques pour éviter les races
	metrics := make(map[string]*LiveMetrics)
	for name, metric := range rtmd.liveMetrics {
		metricsCopy := *metric
		metrics[name] = &metricsCopy
	}

	return metrics
}

// GetHistoricalData retourne les données historiques
func (rtmd *RealTimeMonitoringDashboard) GetHistoricalData(managerName string, duration time.Duration) (*TimeSeries, error) {
	return rtmd.dataAggregator.GetHistoricalData(managerName, duration)
}

// Méthodes internes

func (rtmd *RealTimeMonitoringDashboard) initializeComponents() error {
	// Initialiser le collecteur de métriques
	metricsCollector, err := NewMetricsCollector(&CollectorConfig{}, rtmd.logger)
	if err != nil {
		return fmt.Errorf("failed to create metrics collector: %w", err)
	}
	rtmd.metricsCollector = metricsCollector

	// Initialiser le système d'alertes
	alertingSystem, err := NewAlertingSystem(&AlertConfig{}, rtmd.logger)
	if err != nil {
		return fmt.Errorf("failed to create alerting system: %w", err)
	}
	rtmd.alertingSystem = alertingSystem

	// Initialiser le dashboard web
	webDashboard, err := NewWebDashboard(&DashboardConfig{}, rtmd.logger)
	if err != nil {
		return fmt.Errorf("failed to create web dashboard: %w", err)
	}
	rtmd.webDashboard = webDashboard

	// Initialiser l'agrégateur de données
	dataAggregator, err := NewDataAggregator(&AggregatorConfig{}, rtmd.logger)
	if err != nil {
		return fmt.Errorf("failed to create data aggregator: %w", err)
	}
	rtmd.dataAggregator = dataAggregator

	// Initialiser le serveur WebSocket si activé
	if rtmd.config.WebSocketEnabled {
		websocketServer, err := NewWebSocketServer(&WebSocketConfig{}, rtmd.logger)
		if err != nil {
			return fmt.Errorf("failed to create WebSocket server: %w", err)
		}
		rtmd.websocketServer = websocketServer
	}

	return nil
}

func (rtmd *RealTimeMonitoringDashboard) startHTTPServer() error {
	mux := http.NewServeMux()

	// Routes de l'API
	mux.HandleFunc("/api/health", rtmd.handleHealthAPI)
	mux.HandleFunc("/api/metrics", rtmd.handleMetricsAPI)
	mux.HandleFunc("/api/alerts", rtmd.handleAlertsAPI)
	mux.HandleFunc("/api/events", rtmd.handleEventsAPI)
	mux.HandleFunc("/api/historical", rtmd.handleHistoricalAPI)

	// Route WebSocket
	if rtmd.config.WebSocketEnabled {
		mux.HandleFunc("/ws", rtmd.handleWebSocket)
	}

	// Routes statiques du dashboard
	mux.HandleFunc("/", rtmd.webDashboard.ServeHTTP)

	addr := fmt.Sprintf(":%d", rtmd.config.DashboardPort)
	rtmd.httpServer = &http.Server{
		Addr:    addr,
		Handler: mux,
	}

	// Démarrer le serveur dans une goroutine
	go func() {
		var err error
		if rtmd.config.HTTPSEnabled {
			err = rtmd.httpServer.ListenAndServeTLS(rtmd.config.CertFile, rtmd.config.KeyFile)
		} else {
			err = rtmd.httpServer.ListenAndServe()
		}

		if err != nil && err != http.ErrServerClosed {
			rtmd.logger.WithError(err).Error("HTTP server failed")
		}
	}()

	return nil
}

func (rtmd *RealTimeMonitoringDashboard) startMetricsCollection() {
	rtmd.collectionTicker = time.NewTicker(rtmd.config.UpdateInterval)

	go func() {
		for range rtmd.collectionTicker.C {
			if !rtmd.running {
				return
			}

			if err := rtmd.collectAndProcessMetrics(); err != nil {
				rtmd.logger.WithError(err).Error("Failed to collect and process metrics")
			}
		}
	}()
}

func (rtmd *RealTimeMonitoringDashboard) startDataAggregation() {
	rtmd.aggregationTicker = time.NewTicker(rtmd.config.AggregationWindow)

	go func() {
		for range rtmd.aggregationTicker.C {
			if !rtmd.running {
				return
			}

			if err := rtmd.aggregateAndAnalyzeData(); err != nil {
				rtmd.logger.WithError(err).Error("Failed to aggregate and analyze data")
			}
		}
	}()
}

func (rtmd *RealTimeMonitoringDashboard) startAutomaticCleanup() {
	rtmd.cleanupTicker = time.NewTicker(1 * time.Hour)

	go func() {
		for range rtmd.cleanupTicker.C {
			if !rtmd.running {
				return
			}

			rtmd.performAutomaticCleanup()
		}
	}()
}

func (rtmd *RealTimeMonitoringDashboard) collectAndProcessMetrics() error {
	ctx := context.Background()

	// Collecter les métriques de tous les managers
	newMetrics, err := rtmd.metricsCollector.CollectAllMetrics(ctx)
	if err != nil {
		return fmt.Errorf("failed to collect metrics: %w", err)
	}

	// Mettre à jour les métriques en mémoire
	rtmd.mutex.Lock()
	for name, metrics := range newMetrics {
		rtmd.liveMetrics[name] = metrics
	}
	rtmd.mutex.Unlock()

	// Vérifier les seuils d'alerte
	alerts, err := rtmd.alertingSystem.CheckThresholds(newMetrics)
	if err != nil {
		rtmd.logger.WithError(err).Warn("Failed to check alert thresholds")
	} else {
		rtmd.processNewAlerts(alerts)
	}

	// Diffuser les mises à jour via WebSocket
	if rtmd.config.WebSocketEnabled {
		if err := rtmd.BroadcastUpdate("metrics_update", newMetrics); err != nil {
			rtmd.logger.WithError(err).Warn("Failed to broadcast metrics update")
		}
	}

	return nil
}

func (rtmd *RealTimeMonitoringDashboard) aggregateAndAnalyzeData() error {
	// Agréger les données récentes
	if err := rtmd.dataAggregator.AggregateRecentData(); err != nil {
		return fmt.Errorf("failed to aggregate recent data: %w", err)
	}

	// Analyser les tendances
	if rtmd.config.TrendAnalysis {
		trends, err := rtmd.dataAggregator.AnalyzeTrends()
		if err != nil {
			rtmd.logger.WithError(err).Warn("Failed to analyze trends")
		} else {
			rtmd.processTrendAnalysis(trends)
		}
	}

	return nil
}

func (rtmd *RealTimeMonitoringDashboard) performAutomaticCleanup() {
	cutoff := time.Now().Add(-rtmd.config.MetricsRetention)

	// Nettoyer l'historique des alertes
	rtmd.mutex.Lock()
	filteredAlerts := make([]*Alert, 0)
	for _, alert := range rtmd.alertHistory {
		if alert.Timestamp.After(cutoff) {
			filteredAlerts = append(filteredAlerts, alert)
		}
	}
	rtmd.alertHistory = filteredAlerts

	// Nettoyer l'historique des événements
	filteredEvents := make([]*SystemEvent, 0)
	for _, event := range rtmd.systemEvents {
		if event.Timestamp.After(cutoff) {
			filteredEvents = append(filteredEvents, event)
		}
	}
	rtmd.systemEvents = filteredEvents
	rtmd.mutex.Unlock()

	// Nettoyer les données historiques dans l'agrégateur
	rtmd.dataAggregator.CleanupOldData(cutoff)

	rtmd.logger.Debug(fmt.Sprintf("Cleaned up data older than %v", rtmd.config.MetricsRetention))
}

func (rtmd *RealTimeMonitoringDashboard) processNewAlerts(alerts []*Alert) {
	for _, alert := range alerts {
		// Ajouter à l'historique
		rtmd.mutex.Lock()
		rtmd.alertHistory = append(rtmd.alertHistory, alert)
		rtmd.mutex.Unlock()

		// Créer un événement système
		event := &SystemEvent{
			ID:          fmt.Sprintf("event-%d", time.Now().UnixNano()),
			Type:        "alert_generated",
			Source:      alert.Source,
			Description: fmt.Sprintf("Alert generated: %s", alert.Title),
			Timestamp:   time.Now(),
			Severity:    EventSeverityWarning,
			Data: map[string]interface{}{
				"alert_id":   alert.ID,
				"alert_type": alert.Type,
				"value":      alert.Value,
				"threshold":  alert.Threshold,
			},
		}
		rtmd.addSystemEvent(event)

		// Diffuser l'alerte via WebSocket
		if rtmd.config.WebSocketEnabled {
			rtmd.BroadcastUpdate("alert", alert)
		}

		rtmd.logger.Info(fmt.Sprintf("Alert generated: %s (%s)", alert.Title, alert.Severity))
	}
}

func (rtmd *RealTimeMonitoringDashboard) processTrendAnalysis(trends map[string]*TrendAnalysis) {
	for manager, trend := range trends {
		if trend.IsSignificant() {
			event := &SystemEvent{
				ID:          fmt.Sprintf("trend-%d", time.Now().UnixNano()),
				Type:        "trend_detected",
				Source:      manager,
				Description: fmt.Sprintf("Significant trend detected: %s", trend.Description),
				Timestamp:   time.Now(),
				Severity:    EventSeverityInfo,
				Data: map[string]interface{}{
					"trend_type": trend.Type,
					"direction":  trend.Direction,
					"strength":   trend.Strength,
					"confidence": trend.Confidence,
				},
			}
			rtmd.addSystemEvent(event)
		}
	}
}

func (rtmd *RealTimeMonitoringDashboard) addSystemEvent(event *SystemEvent) {
	rtmd.mutex.Lock()
	rtmd.systemEvents = append(rtmd.systemEvents, event)
	rtmd.mutex.Unlock()

	// Diffuser l'événement via WebSocket
	if rtmd.config.WebSocketEnabled {
		rtmd.BroadcastUpdate("event", event)
	}
}

// Handlers HTTP API

func (rtmd *RealTimeMonitoringDashboard) handleHealthAPI(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()
	managerConnections := rtmd.metricsCollector.GetManagerConnections()

	healthReport, err := rtmd.GenerateEcosystemHealthReport(ctx, managerConnections)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate health report: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	// Ici on sérialiserait healthReport en JSON
	fmt.Fprintf(w, `{"status": "ok", "health_score": %.2f}`, healthReport.OverallHealthScore)
}

func (rtmd *RealTimeMonitoringDashboard) handleMetricsAPI(w http.ResponseWriter, r *http.Request) {
	metrics := rtmd.GetLiveMetrics()

	w.Header().Set("Content-Type", "application/json")
	// Ici on sérialiserait metrics en JSON
	fmt.Fprintf(w, `{"metrics_count": %d}`, len(metrics))
}

func (rtmd *RealTimeMonitoringDashboard) handleAlertsAPI(w http.ResponseWriter, r *http.Request) {
	activeAlerts := rtmd.alertingSystem.GetActiveAlerts()

	w.Header().Set("Content-Type", "application/json")
	// Ici on sérialiserait activeAlerts en JSON
	fmt.Fprintf(w, `{"active_alerts": %d}`, len(activeAlerts))
}

func (rtmd *RealTimeMonitoringDashboard) handleEventsAPI(w http.ResponseWriter, r *http.Request) {
	recentEvents := rtmd.getRecentEvents(24 * time.Hour)

	w.Header().Set("Content-Type", "application/json")
	// Ici on sérialiserait recentEvents en JSON
	fmt.Fprintf(w, `{"recent_events": %d}`, len(recentEvents))
}

func (rtmd *RealTimeMonitoringDashboard) handleHistoricalAPI(w http.ResponseWriter, r *http.Request) {
	manager := r.URL.Query().Get("manager")
	duration := r.URL.Query().Get("duration")

	if manager == "" || duration == "" {
		http.Error(w, "manager and duration parameters are required", http.StatusBadRequest)
		return
	}

	parsedDuration, err := time.ParseDuration(duration)
	if err != nil {
		http.Error(w, "invalid duration format", http.StatusBadRequest)
		return
	}

	data, err := rtmd.GetHistoricalData(manager, parsedDuration)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get historical data: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	// Ici on sérialiserait data en JSON
	fmt.Fprintf(w, `{"data_points": %d}`, len(data.DataPoints))
}

func (rtmd *RealTimeMonitoringDashboard) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Ici serait implémentée la logique de mise à niveau WebSocket
	rtmd.logger.Info("WebSocket connection attempted")
}

// Méthodes utilitaires

func (rtmd *RealTimeMonitoringDashboard) calculateOverallHealth(metrics map[string]*LiveMetrics) float64 {
	if len(metrics) == 0 {
		return 0.0
	}

	totalHealth := 0.0
	for _, metric := range metrics {
		totalHealth += metric.HealthScore
	}

	return totalHealth / float64(len(metrics))
}

func (rtmd *RealTimeMonitoringDashboard) convertToManagerStates(metrics map[string]*LiveMetrics) map[string]*interfaces.ManagerState {
	states := make(map[string]*interfaces.ManagerState)

	for name, metric := range metrics {
		state := &interfaces.ManagerState{
			Name:            name,
			Status:          metric.Status,
			HealthScore:     metric.HealthScore,
			LastHealthCheck: metric.LastUpdate,
			Metrics: map[string]interface{}{
				"response_time":  metric.ResponseTime,
				"throughput":     metric.ThroughputRPS,
				"error_rate":     metric.ErrorRate,
				"resource_usage": metric.ResourceUsage,
			},
		}
		states[name] = state
	}

	return states
}

func (rtmd *RealTimeMonitoringDashboard) aggregatePerformanceMetrics(metrics map[string]*LiveMetrics) map[string]float64 {
	aggregated := make(map[string]float64)

	totalResponseTime := 0.0
	totalThroughput := 0.0
	totalErrorRate := 0.0
	count := float64(len(metrics))

	for _, metric := range metrics {
		totalResponseTime += float64(metric.ResponseTime.Milliseconds())
		totalThroughput += metric.ThroughputRPS
		totalErrorRate += metric.ErrorRate
	}

	if count > 0 {
		aggregated["avg_response_time"] = totalResponseTime / count
		aggregated["total_throughput"] = totalThroughput
		aggregated["avg_error_rate"] = totalErrorRate / count
	}

	return aggregated
}

func (rtmd *RealTimeMonitoringDashboard) determineSystemStatus(healthScore float64, alerts []*Alert) string {
	if healthScore >= 0.9 && len(alerts) == 0 {
		return "healthy"
	} else if healthScore >= 0.7 && len(alerts) <= 2 {
		return "warning"
	} else if healthScore >= 0.5 {
		return "degraded"
	} else {
		return "critical"
	}
}

func (rtmd *RealTimeMonitoringDashboard) aggregateResourceUtilization(metrics map[string]*LiveMetrics) *interfaces.ResourceUtilization {
	totalCPU := 0.0
	totalMemory := 0.0
	totalDisk := 0.0
	count := float64(len(metrics))

	for _, metric := range metrics {
		if metric.ResourceUsage != nil {
			totalCPU += metric.ResourceUsage.CPUPercent
			totalMemory += metric.ResourceUsage.MemoryPercent
			totalDisk += metric.ResourceUsage.DiskPercent
		}
		}
	}

	if count == 0 {
		return &interfaces.ResourceUtilization{}
	}

	return &interfaces.ResourceUtilization{
		CPUPercent:    totalCPU / count,
		MemoryPercent: totalMemory / count,
		DiskPercent:   totalDisk / count,
	}
}

func (rtmd *RealTimeMonitoringDashboard) getRecentEvents(duration time.Duration) []*interfaces.Event {
	rtmd.mutex.RLock()
	defer rtmd.mutex.RUnlock()

	cutoff := time.Now().Add(-duration)
	events := make([]*interfaces.Event, 0)

	for _, event := range rtmd.systemEvents {
		if event.Timestamp.After(cutoff) {
			interfaceEvent := &interfaces.Event{
				ID:          event.ID,
				Type:        event.Type,
				Source:      event.Source,
				Description: event.Description,
				Timestamp:   event.Timestamp,
				Data:        event.Data,
			}
			events = append(events, interfaceEvent)
		}
	}

	return events
}

func (rtmd *RealTimeMonitoringDashboard) closeWebSocketConnection(conn *WebSocketConnection) error {
	// Ici serait implémentée la logique de fermeture de connexion WebSocket
	rtmd.logger.Info(fmt.Sprintf("Closing WebSocket connection %s", conn.ID))
	return nil
}

func validateMonitoringConfig(config *MonitoringConfig) error {
	if config.DashboardPort < 1 || config.DashboardPort > 65535 {
		return fmt.Errorf("dashboard port must be between 1 and 65535")
	}

	if config.UpdateInterval < time.Second || config.UpdateInterval > time.Hour {
		return fmt.Errorf("update interval must be between 1 second and 1 hour")
	}

	if config.MetricsRetention < time.Hour || config.MetricsRetention > 30*24*time.Hour {
		return fmt.Errorf("metrics retention must be between 1 hour and 30 days")
	}

	return nil
}
