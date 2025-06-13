package monitoring

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
	baseInterfaces "./interfaces"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// monitoringManagerImpl implÃ©mente les mÃ©triques et monitoring
type monitoringManagerImpl struct {
	storageManager baseInterfaces.StorageManager
	configManager  baseInterfaces.ConfigManager
	errorManager   baseInterfaces.ErrorManager
	
	initialized bool
	mu          sync.RWMutex
	
	// MÃ©triques Prometheus
	actionsCaptured   prometheus.Counter
	searchDuration    prometheus.Histogram
	cacheHitRatio     prometheus.Gauge
	activeSessions    prometheus.Gauge
	embeddingLatency  prometheus.Histogram
	mcpNotifications  prometheus.Counter
	
	// Ãtats internes
	stats *ContextualMemoryStats
}

// ContextualMemoryStats reprÃ©sente les statistiques du systÃ¨me
type ContextualMemoryStats struct {
	TotalActions         int64     `json:"total_actions"`
	TotalSearches        int64     `json:"total_searches"`
	CacheHitRatio        float64   `json:"cache_hit_ratio"`
	AvgSearchLatency     float64   `json:"avg_search_latency_ms"`
	AvgEmbeddingLatency  float64   `json:"avg_embedding_latency_ms"`
	ActiveSessions       int64     `json:"active_sessions"`
	LastActivity         time.Time `json:"last_activity"`
	SystemHealth         string    `json:"system_health"`
}

// NewMonitoringManager crÃ©e une nouvelle instance de MonitoringManager
func NewMonitoringManager(
	storageManager baseInterfaces.StorageManager,
	errorManager baseInterfaces.ErrorManager,
	configManager baseInterfaces.ConfigManager,
) (*monitoringManagerImpl, error) {
	return &monitoringManagerImpl{
		storageManager: storageManager,
		configManager:  configManager,
		errorManager:   errorManager,
		stats: &ContextualMemoryStats{
			SystemHealth: "unknown",
		},
	}, nil
		configManager: configManager,
		errorManager:  errorManager,
		stats: &ContextualMemoryStats{
			SystemHealth: "unknown",
		},
	}
}

// Initialize implÃ©mente BaseManager.Initialize
func (mm *monitoringManagerImpl) Initialize(ctx context.Context) error {
	if mm.initialized {
		return nil
	}

	// Initialiser les mÃ©triques Prometheus
	mm.initializeMetrics()
	
	// DÃ©marrer la collecte pÃ©riodique de mÃ©triques
	go mm.startMetricsCollection(ctx)

	mm.initialized = true
	return nil
}

// RecordAction enregistre une action capturÃ©e
func (mm *monitoringManagerImpl) RecordAction(actionType string) {
	if !mm.initialized {
		return
	}

	mm.actionsCaptured.Inc()
	
	mm.mu.Lock()
	mm.stats.TotalActions++
	mm.stats.LastActivity = time.Now()
	mm.mu.Unlock()
}

// RecordSearch enregistre une recherche avec sa latence
func (mm *monitoringManagerImpl) RecordSearch(duration time.Duration, resultsCount int) {
	if !mm.initialized {
		return
	}

	mm.searchDuration.Observe(duration.Seconds())
	
	mm.mu.Lock()
	mm.stats.TotalSearches++
	// Calcul de la moyenne mobile simple
	if mm.stats.TotalSearches == 1 {
		mm.stats.AvgSearchLatency = float64(duration.Milliseconds())
	} else {
		mm.stats.AvgSearchLatency = (mm.stats.AvgSearchLatency*0.9) + (float64(duration.Milliseconds())*0.1)
	}
	mm.mu.Unlock()
}

// RecordEmbeddingLatency enregistre la latence de gÃ©nÃ©ration d'embedding
func (mm *monitoringManagerImpl) RecordEmbeddingLatency(duration time.Duration) {
	if !mm.initialized {
		return
	}

	mm.embeddingLatency.Observe(duration.Seconds())
	
	mm.mu.Lock()
	// Calcul de la moyenne mobile
	if mm.stats.AvgEmbeddingLatency == 0 {
		mm.stats.AvgEmbeddingLatency = float64(duration.Milliseconds())
	} else {
		mm.stats.AvgEmbeddingLatency = (mm.stats.AvgEmbeddingLatency*0.9) + (float64(duration.Milliseconds())*0.1)
	}
	mm.mu.Unlock()
}

// UpdateCacheHitRatio met Ã  jour le ratio de cache hits
func (mm *monitoringManagerImpl) UpdateCacheHitRatio(ratio float64) {
	if !mm.initialized {
		return
	}

	mm.cacheHitRatio.Set(ratio)
	
	mm.mu.Lock()
	mm.stats.CacheHitRatio = ratio
	mm.mu.Unlock()
}

// UpdateActiveSessions met Ã  jour le nombre de sessions actives
func (mm *monitoringManagerImpl) UpdateActiveSessions(count int64) {
	if !mm.initialized {
		return
	}

	mm.activeSessions.Set(float64(count))
	
	mm.mu.Lock()
	mm.stats.ActiveSessions = count
	mm.mu.Unlock()
}

// RecordMCPNotification enregistre une notification MCP
func (mm *monitoringManagerImpl) RecordMCPNotification(success bool) {
	if !mm.initialized {
		return
	}

	labels := prometheus.Labels{"status": "failure"}
	if success {
		labels["status"] = "success"
	}
	
	mm.mcpNotifications.With(labels).Inc()
}

// RecordOperation enregistre une opÃ©ration avec sa durÃ©e et status d'erreur
func (mm *monitoringManagerImpl) RecordOperation(ctx context.Context, operation string, duration time.Duration, err error) error {
	if !mm.initialized {
		return fmt.Errorf("monitoring manager not initialized")
	}

	// Enregistrer la latence
	mm.searchLatency.WithLabelValues(operation).Observe(duration.Seconds())
	
	// Enregistrer l'opÃ©ration
	if err != nil {
		mm.operationsTotal.WithLabelValues(operation, "error").Inc()
	} else {
		mm.operationsTotal.WithLabelValues(operation, "success").Inc()
	}

	mm.mu.Lock()
	mm.stats.LastActivity = time.Now()
	if err != nil {
		mm.stats.ErrorCount++
	}
	mm.mu.Unlock()

	return nil
}

// GetMetrics retourne les mÃ©triques actuelles du systÃ¨me
func (mm *monitoringManagerImpl) GetMetrics(ctx context.Context) (interfaces.ManagerMetrics, error) {
	if !mm.initialized {
		return interfaces.ManagerMetrics{}, fmt.Errorf("monitoring manager not initialized")
	}

	mm.mu.RLock()
	defer mm.mu.RUnlock()

	// Calculer le ratio de cache hits (simulation)
	cacheHitRatio := 0.85 // Dans un vrai systÃ¨me, cela viendrait du cache manager

	return interfaces.ManagerMetrics{
		TotalActions:      mm.stats.TotalActions,
		CacheHitRatio:     cacheHitRatio,
		AverageLatency:    time.Duration(mm.stats.AvgSearchLatency) * time.Millisecond,
		ActiveSessions:    mm.stats.ActiveSessions,
		MCPNotifications:  mm.stats.MCPNotifications,
		LastOperationTime: mm.stats.LastActivity,
		ErrorCount:        mm.stats.ErrorCount,
		ComponentStatus: map[string]string{
			"monitoring": mm.stats.SystemHealth,
			"storage":    "healthy",
			"indexing":   "healthy",
			"retrieval":  "healthy",
		},
	}, nil
}

// RecordCacheHit enregistre un hit/miss de cache
func (mm *monitoringManagerImpl) RecordCacheHit(ctx context.Context, hit bool) error {
	if !mm.initialized {
		return fmt.Errorf("monitoring manager not initialized")
	}

	if hit {
		mm.cacheHits.Inc()
	} else {
		mm.cacheMisses.Inc()
	}

	// Calculer et mettre Ã  jour le ratio
	hits := mm.cacheHits.Get()
	misses := mm.cacheMisses.Get()
	total := hits + misses
	
	if total > 0 {
		ratio := hits / total
		mm.cacheHitRatio.Set(ratio)
	}

	return nil
}

// IncrementActiveSession incrÃ©mente le compteur de sessions actives
func (mm *monitoringManagerImpl) IncrementActiveSession(ctx context.Context) error {
	if !mm.initialized {
		return fmt.Errorf("monitoring manager not initialized")
	}

	mm.activeSessions.Inc()
	
	mm.mu.Lock()
	mm.stats.ActiveSessions++
	mm.mu.Unlock()

	return nil
}

// DecrementActiveSession dÃ©crÃ©mente le compteur de sessions actives
func (mm *monitoringManagerImpl) DecrementActiveSession(ctx context.Context) error {
	if !mm.initialized {
		return fmt.Errorf("monitoring manager not initialized")
	}

	mm.activeSessions.Dec()
	
	mm.mu.Lock()
	if mm.stats.ActiveSessions > 0 {
		mm.stats.ActiveSessions--
	}
	mm.mu.Unlock()

	return nil
}

// GetStats retourne les statistiques actuelles
func (mm *monitoringManagerImpl) GetStats() *ContextualMemoryStats {
	mm.mu.RLock()
	defer mm.mu.RUnlock()
	
	// CrÃ©er une copie pour Ã©viter les races
	statsCopy := *mm.stats
	return &statsCopy
}

// UpdateSystemHealth met Ã  jour l'Ã©tat de santÃ© du systÃ¨me
func (mm *monitoringManagerImpl) UpdateSystemHealth(health string) {
	mm.mu.Lock()
	mm.stats.SystemHealth = health
	mm.mu.Unlock()
}

// GetHealthStatus retourne l'Ã©tat de santÃ© du systÃ¨me
func (mm *monitoringManagerImpl) GetHealthStatus(ctx context.Context) map[string]interface{} {
	mm.mu.RLock()
	defer mm.mu.RUnlock()
	
	return map[string]interface{}{
		"status":           mm.stats.SystemHealth,
		"total_actions":    mm.stats.TotalActions,
		"total_searches":   mm.stats.TotalSearches,
		"cache_hit_ratio":  mm.stats.CacheHitRatio,
		"active_sessions":  mm.stats.ActiveSessions,
		"last_activity":    mm.stats.LastActivity,
		"avg_search_latency_ms": mm.stats.AvgSearchLatency,
		"avg_embedding_latency_ms": mm.stats.AvgEmbeddingLatency,
		"uptime_seconds":   time.Since(mm.stats.LastActivity).Seconds(),
	}
}

// Cleanup implÃ©mente BaseManager.Cleanup
func (mm *monitoringManagerImpl) Cleanup() error {
	// Rien Ã  nettoyer spÃ©cifiquement
	return nil
}

// HealthCheck implÃ©mente BaseManager.HealthCheck
func (mm *monitoringManagerImpl) HealthCheck(ctx context.Context) error {
	if !mm.initialized {
		return fmt.Errorf("MonitoringManager not initialized")
	}

	// VÃ©rifier que les mÃ©triques sont fonctionnelles
	mm.mu.RLock()
	lastActivity := mm.stats.LastActivity
	mm.mu.RUnlock()

	// Si aucune activitÃ© depuis plus de 5 minutes, considÃ©rer comme dÃ©gradÃ©
	if time.Since(lastActivity) > 5*time.Minute {
		mm.UpdateSystemHealth("degraded")
		return fmt.Errorf("no recent activity detected")
	}

	mm.UpdateSystemHealth("healthy")
	return nil
}

// MÃ©thodes privÃ©es

func (mm *monitoringManagerImpl) initializeMetrics() {
	// Compteur d'actions capturÃ©es
	mm.actionsCaptured = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contextual_memory_actions_total",
		Help: "The total number of actions captured",
	})

	// Histogramme de durÃ©e de recherche
	mm.searchDuration = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "contextual_memory_search_duration_seconds",
		Help:    "The duration of context searches",
		Buckets: prometheus.DefBuckets,
	})

	// Gauge de ratio de cache hits
	mm.cacheHitRatio = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "contextual_memory_cache_hit_ratio",
		Help: "The cache hit ratio for embeddings",
	})

	// Gauge de sessions actives
	mm.activeSessions = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "contextual_memory_active_sessions",
		Help: "The number of active user sessions",
	})

	// Histogramme de latence d'embedding
	mm.embeddingLatency = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "contextual_memory_embedding_latency_seconds",
		Help:    "The latency of embedding generation",
		Buckets: []float64{0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
	})

	// Compteur de notifications MCP
	mm.mcpNotifications = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "contextual_memory_mcp_notifications_total",
			Help: "The total number of MCP notifications sent",
		},
		[]string{"status"},
	)
}

func (mm *monitoringManagerImpl) startMetricsCollection(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			mm.collectMetrics()
		}
	}
}

func (mm *monitoringManagerImpl) collectMetrics() {
	// Simulation de collecte de mÃ©triques systÃ¨me
	// Dans un vrai systÃ¨me, ces valeurs viendraient des autres managers
	
	mm.mu.Lock()
	defer mm.mu.Unlock()
	
	// Simuler des mises Ã  jour pÃ©riodiques
	if time.Since(mm.stats.LastActivity) < time.Minute {
		mm.stats.SystemHealth = "healthy"
	} else if time.Since(mm.stats.LastActivity) < 5*time.Minute {
		mm.stats.SystemHealth = "degraded"
	} else {
		mm.stats.SystemHealth = "unhealthy"
	}
}
