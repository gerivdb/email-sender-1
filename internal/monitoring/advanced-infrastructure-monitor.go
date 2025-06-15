package monitoring

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"
	_ "github.com/lib/pq"
)

// AutonomyMetric représente les métriques d'autonomie d'un service
type AutonomyMetric struct {
	ServiceName       string    `json:"service_name"`
	AutonomyLevel     float64   `json:"autonomy_level"`
	SelfHealingCount  int       `json:"self_healing_count"`
	LastIntervention  time.Time `json:"last_intervention"`
	DecisionQuality   float64   `json:"decision_quality"`
	LastUpdated       time.Time `json:"last_updated"`
}

// AutonomyDecision représente une décision prise par le système d'autonomie
type AutonomyDecision struct {
	Timestamp     time.Time                `json:"timestamp"`
	ServiceName   string                   `json:"service_name"`
	DecisionType  string                   `json:"decision_type"`
	Context       map[string]interface{}   `json:"context"`
	Success       bool                     `json:"success"`
	Duration      time.Duration            `json:"duration"`
	Confidence    float64                  `json:"confidence"`
}

// MonitoringStatus représente l'état du système de monitoring
type MonitoringStatus struct {
	Active             bool      `json:"active"`
	AutoHealingEnabled bool      `json:"auto_healing_enabled"`
	StartTime          time.Time `json:"start_time"`
	ServicesMonitored  int       `json:"services_monitored"`
}

// ServiceHealthStatus représente l'état de santé d'un service
type ServiceHealthStatus struct {
	ServiceName  string                 `json:"service_name"`
	Status       string                 `json:"status"`
	Healthy      bool                   `json:"healthy"`
	ResponseTime time.Duration          `json:"response_time"`
	LastCheck    time.Time              `json:"last_check"`
	Checks       map[string]CheckResult `json:"checks"`
	Uptime       time.Duration          `json:"uptime"`
	Dependencies []DependencyStatus     `json:"dependencies"`
	Metrics      map[string]interface{} `json:"metrics,omitempty"`
	Timestamp    time.Time              `json:"timestamp"`
}

// CheckResult représente le résultat d'un health check
type CheckResult struct {
	Type      string        `json:"type"`
	Success   bool          `json:"success"`
	Message   string        `json:"message"`
	Duration  time.Duration `json:"duration"`
	Timestamp time.Time     `json:"timestamp"`
}

// DependencyStatus représente l'état d'une dépendance
type DependencyStatus struct {
	Name    string `json:"name"`
	Status  bool   `json:"status"`
	Message string `json:"message"`
}

// AdvancedInfrastructureMonitor étend le monitoring existant
type AdvancedInfrastructureMonitor struct {
	serviceHealthGauge    *prometheus.GaugeVec
	serviceResponseGauge  *prometheus.GaugeVec
	autoHealingCounter    *prometheus.CounterVec
	healthCheckCounter    *prometheus.CounterVec
	
	redisClient *redis.Client
	httpClient  *http.Client
	dbPool      map[string]*sql.DB
}

// NewAdvancedInfrastructureMonitor crée une nouvelle instance
func NewAdvancedInfrastructureMonitor() *AdvancedInfrastructureMonitor {
	monitor := &AdvancedInfrastructureMonitor{
		httpClient: &http.Client{Timeout: 10 * time.Second},
		dbPool:     make(map[string]*sql.DB),
	}

	monitor.serviceHealthGauge = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "service",
			Name:      "health_status",
			Help:      "Health status of infrastructure services",
		},
		[]string{"service", "check_type"},
	)

	monitor.serviceResponseGauge = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Namespace: "smart_infrastructure", 
			Subsystem: "service",
			Name:      "response_time_seconds",
			Help:      "Response time of services in seconds",
		},
		[]string{"service"},
	)

	monitor.autoHealingCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "auto_healing",
			Name:      "attempts_total", 
			Help:      "Total auto-healing attempts",
		},
		[]string{"service", "result"},
	)

	monitor.healthCheckCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "smart_infrastructure",
			Subsystem: "health_check",
			Name:      "total",
			Help:      "Total health checks performed",
		},
		[]string{"service", "result"},
	)

	return monitor
}

// Start démarre le monitoring avancé
func (aim *AdvancedInfrastructureMonitor) Start(ctx context.Context) error {
	log.Println("🚀 Starting Advanced Infrastructure Monitor...")
	
	go aim.startMetricsCollection(ctx)
	
	log.Println("✅ Advanced Infrastructure Monitor started")
	return nil
}

// Stop arrête le monitoring avancé
func (aim *AdvancedInfrastructureMonitor) Stop() {
	log.Println("🛑 Stopping Advanced Infrastructure Monitor...")
	
	for _, db := range aim.dbPool {
		if db != nil {
			db.Close()
		}
	}
	
	log.Println("✅ Advanced Infrastructure Monitor stopped")
}

// GetHealthStatus retourne le statut de santé de tous les services
func (aim *AdvancedInfrastructureMonitor) GetHealthStatus(ctx context.Context) (map[string]ServiceHealthStatus, error) {
	healthStatus := make(map[string]ServiceHealthStatus)
	
	services := []string{"qdrant", "redis", "prometheus", "grafana", "rag_server"}
	
	for _, service := range services {
		status := aim.checkSingleService(ctx, service)
		healthStatus[service] = status
	}
	
	return healthStatus, nil
}

// checkSingleService vérifie la santé d'un service spécifique
func (aim *AdvancedInfrastructureMonitor) checkSingleService(ctx context.Context, service string) ServiceHealthStatus {
	status := ServiceHealthStatus{
		ServiceName: service,
		Status:      "unknown",
		Healthy:     false,
		LastCheck:   time.Now(),
		Checks:      make(map[string]CheckResult),
		Dependencies: []DependencyStatus{},
		Timestamp:   time.Now(),
	}

	switch service {
	case "qdrant":
		status = aim.checkQdrantHealth(ctx, status)
	case "redis":
		status = aim.checkRedisHealth(ctx, status)
	case "prometheus":
		status = aim.checkPrometheusHealth(ctx, status)
	case "grafana":
		status = aim.checkGrafanaHealth(ctx, status)
	case "rag_server":
		status = aim.checkRAGServerHealth(ctx, status)
	}

	// Déterminer le statut global
	healthy := true
	for _, check := range status.Checks {
		if !check.Success {
			healthy = false
			break
		}
	}
	
	status.Healthy = healthy
	status.Status = map[bool]string{true: "healthy", false: "unhealthy"}[healthy]

	// Mettre à jour les métriques Prometheus
	healthValue := map[bool]float64{true: 1, false: 0}[healthy]
	aim.serviceHealthGauge.WithLabelValues(service, "overall").Set(healthValue)
	aim.healthCheckCounter.WithLabelValues(service, status.Status).Inc()

	return status
}

// checkQdrantHealth vérifie la santé de QDrant
func (aim *AdvancedInfrastructureMonitor) checkQdrantHealth(ctx context.Context, status ServiceHealthStatus) ServiceHealthStatus {
	healthCheck := aim.performHTTPCheck(ctx, "http://localhost:6333/", "qdrant_health")
	status.Checks["health"] = healthCheck

	collectionsCheck := aim.performHTTPCheck(ctx, "http://localhost:6333/collections", "qdrant_collections")
	status.Checks["collections"] = collectionsCheck

	return status
}

// checkRedisHealth vérifie la santé de Redis  
func (aim *AdvancedInfrastructureMonitor) checkRedisHealth(ctx context.Context, status ServiceHealthStatus) ServiceHealthStatus {
	if aim.redisClient == nil {
		aim.redisClient = redis.NewClient(&redis.Options{
			Addr: "localhost:6379",
		})
	}

	start := time.Now()
	err := aim.redisClient.Ping(ctx).Err()
	duration := time.Since(start)

	pingCheck := CheckResult{
		Type:      "ping",
		Success:   err == nil,
		Message:   "Redis ping check",
		Duration:  duration,
		Timestamp: time.Now(),
	}
	if err != nil {
		pingCheck.Message = fmt.Sprintf("Redis ping failed: %v", err)
	}

	status.Checks["ping"] = pingCheck
	status.ResponseTime = duration

	return status
}

// checkPrometheusHealth vérifie la santé de Prometheus
func (aim *AdvancedInfrastructureMonitor) checkPrometheusHealth(ctx context.Context, status ServiceHealthStatus) ServiceHealthStatus {
	healthCheck := aim.performHTTPCheck(ctx, "http://localhost:9090/-/healthy", "prometheus_health")
	status.Checks["health"] = healthCheck

	metricsCheck := aim.performHTTPCheck(ctx, "http://localhost:9090/api/v1/query?query=up", "prometheus_metrics")
	status.Checks["metrics"] = metricsCheck

	return status
}

// checkGrafanaHealth vérifie la santé de Grafana
func (aim *AdvancedInfrastructureMonitor) checkGrafanaHealth(ctx context.Context, status ServiceHealthStatus) ServiceHealthStatus {
	healthCheck := aim.performHTTPCheck(ctx, "http://localhost:3000/api/health", "grafana_health")
	status.Checks["health"] = healthCheck

	return status
}

// checkRAGServerHealth vérifie la santé du serveur RAG
func (aim *AdvancedInfrastructureMonitor) checkRAGServerHealth(ctx context.Context, status ServiceHealthStatus) ServiceHealthStatus {
	healthCheck := aim.performHTTPCheck(ctx, "http://localhost:8080/health", "rag_server_health")
	status.Checks["health"] = healthCheck

	return status
}

// performHTTPCheck effectue un health check HTTP
func (aim *AdvancedInfrastructureMonitor) performHTTPCheck(ctx context.Context, url, checkType string) CheckResult {
	start := time.Now()
	
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return CheckResult{
			Type:      checkType,
			Success:   false,
			Message:   fmt.Sprintf("Failed to create request: %v", err),
			Duration:  time.Since(start),
			Timestamp: time.Now(),
		}
	}

	resp, err := aim.httpClient.Do(req)
	duration := time.Since(start)
	
	if err != nil {
		return CheckResult{
			Type:      checkType,
			Success:   false,
			Message:   fmt.Sprintf("HTTP request failed: %v", err),
			Duration:  duration,
			Timestamp: time.Now(),
		}
	}
	defer resp.Body.Close()

	success := resp.StatusCode >= 200 && resp.StatusCode < 300
	message := fmt.Sprintf("HTTP %d", resp.StatusCode)
	
	return CheckResult{
		Type:      checkType,
		Success:   success,
		Message:   message,
		Duration:  duration,
		Timestamp: time.Now(),
	}
}

// startMetricsCollection démarre la collecte périodique des métriques
func (aim *AdvancedInfrastructureMonitor) startMetricsCollection(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			services := []string{"qdrant", "redis", "prometheus", "grafana", "rag_server"}
			for _, service := range services {
				status := aim.checkSingleService(ctx, service)
				log.Printf("Health check for %s: %s", service, status.Status)
			}
		}
	}
}
