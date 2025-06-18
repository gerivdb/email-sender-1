// interfaces/hybrid_metrics.go
package interfaces

import (
	"context"
	"time"
)

// HybridMetricsManager interface pour la gestion des métriques hybrides
type HybridMetricsManager interface {
	// Enregistrement des métriques
	RecordQuery(mode string, duration time.Duration, success bool, qualityScore float64)
	RecordModeSelection(selectedMode string, actualBest string, confidence float64)
	RecordError(mode string, err error)
	RecordCacheHit(mode string, hit bool)
	RecordMemoryUsage(mode string, bytes int64)

	// Récupération des statistiques
	GetStatistics() *HybridStatistics
	GetMetricsSummary() map[string]interface{}

	// Contrôle du cycle de vie
	StartPeriodicReporting(ctx context.Context)
	Stop()
	Reset()
}

// HybridStatistics structure contenant toutes les métriques
type HybridStatistics struct {
	// Compteurs de requêtes
	TotalQueries    int64 `json:"total_queries"`
	ASTQueries      int64 `json:"ast_queries"`
	RAGQueries      int64 `json:"rag_queries"`
	HybridQueries   int64 `json:"hybrid_queries"`
	ParallelQueries int64 `json:"parallel_queries"`

	// Métriques de performance
	AverageLatency map[string]time.Duration `json:"average_latency"`
	SuccessRates   map[string]float64       `json:"success_rates"`
	QualityScores  map[string]float64       `json:"quality_scores"`

	// Cache et optimisations
	CacheHitRates map[string]float64 `json:"cache_hit_rates"`
	MemoryUsage   map[string]int64   `json:"memory_usage"`

	// Erreurs et problèmes
	ErrorCounts map[string]int64    `json:"error_counts"`
	LastErrors  []HybridErrorInfo   `json:"last_errors"`

	// Adaptation du mode
	ModeSelections map[string]int64   `json:"mode_selections"`
	ModeAccuracy   map[string]float64 `json:"mode_accuracy"`

	LastUpdated time.Time `json:"last_updated"`
}

// HybridErrorInfo informations sur une erreur
type HybridErrorInfo struct {
	Mode      string    `json:"mode"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
}

// MetricsAlert structure pour les alertes basées sur les métriques
type MetricsAlert struct {
	Type        string                 `json:"type"`
	Severity    string                 `json:"severity"`
	Message     string                 `json:"message"`
	Metrics     map[string]interface{} `json:"metrics"`
	Timestamp   time.Time              `json:"timestamp"`
	Threshold   float64                `json:"threshold"`
	ActualValue float64                `json:"actual_value"`
}

// PerformanceThresholds seuils de performance pour les alertes
type PerformanceThresholds struct {
	MaxLatency       time.Duration `json:"max_latency"`
	MinSuccessRate   float64       `json:"min_success_rate"`
	MinQualityScore  float64       `json:"min_quality_score"`
	MinCacheHitRate  float64       `json:"min_cache_hit_rate"`
	MaxErrorRate     float64       `json:"max_error_rate"`
	MaxMemoryUsage   int64         `json:"max_memory_usage"`
}

// HybridMetricsConfig configuration pour le système de métriques
type HybridMetricsConfig struct {
	EnablePeriodicReporting bool                  `json:"enable_periodic_reporting"`
	ReportingInterval       time.Duration         `json:"reporting_interval"`
	MaxErrorHistory         int                   `json:"max_error_history"`
	PerformanceThresholds   PerformanceThresholds `json:"performance_thresholds"`
	AlertWebhookURL         string                `json:"alert_webhook_url"`
	EnableAlerts           bool                  `json:"enable_alerts"`
}
