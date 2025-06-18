package monitoring

import (
	"context"
	"log"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// VectorizationMetrics contient toutes les métriques de vectorisation
type VectorizationMetrics struct {
	// Compteurs d'opérations
	VectorizationRequests *prometheus.CounterVec
	VectorizationErrors   *prometheus.CounterVec
	QdrantOperations      *prometheus.CounterVec
	QdrantErrors          *prometheus.CounterVec

	// Latences
	VectorizationDuration *prometheus.HistogramVec
	QdrantQueryDuration   *prometheus.HistogramVec
	EmbeddingDuration     *prometheus.HistogramVec

	// Métriques de qualité
	EmbeddingQualityScore *prometheus.GaugeVec
	SimilarityScores      *prometheus.HistogramVec

	// Métriques d'état
	ActiveWorkers     prometheus.Gauge
	QueueSize         prometheus.Gauge
	QdrantConnections prometheus.Gauge
	MemoryUsage       prometheus.Gauge

	// Métriques de santé
	HealthStatus      *prometheus.GaugeVec
	LastSuccessfulOp  prometheus.Gauge
	ConsecutiveErrors *prometheus.CounterVec

	mu sync.RWMutex
}

// NewVectorizationMetrics crée une nouvelle instance des métriques
func NewVectorizationMetrics() *VectorizationMetrics {
	return &VectorizationMetrics{
		// Compteurs d'opérations
		VectorizationRequests: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "vectorization_requests_total",
				Help: "Nombre total de requêtes de vectorisation",
			},
			[]string{"operation", "manager", "status"},
		),

		VectorizationErrors: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "vectorization_errors_total",
				Help: "Nombre total d'erreurs de vectorisation",
			},
			[]string{"operation", "manager", "error_type"},
		),

		QdrantOperations: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "qdrant_operations_total",
				Help: "Nombre total d'opérations Qdrant",
			},
			[]string{"operation", "collection", "status"},
		),

		QdrantErrors: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "qdrant_errors_total",
				Help: "Nombre total d'erreurs Qdrant",
			},
			[]string{"operation", "collection", "error_type"},
		),

		// Latences
		VectorizationDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "vectorization_duration_seconds",
				Help:    "Durée des opérations de vectorisation en secondes",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"operation", "manager"},
		),

		QdrantQueryDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "qdrant_query_duration_seconds",
				Help:    "Durée des requêtes Qdrant en secondes",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"operation", "collection"},
		),

		EmbeddingDuration: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "embedding_generation_duration_seconds",
				Help:    "Durée de génération des embeddings en secondes",
				Buckets: prometheus.DefBuckets,
			},
			[]string{"model", "text_length_bucket"},
		),

		// Métriques de qualité
		EmbeddingQualityScore: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "embedding_quality_score",
				Help: "Score de qualité des embeddings (0-1)",
			},
			[]string{"model", "validation_type"},
		),

		SimilarityScores: promauto.NewHistogramVec(
			prometheus.HistogramOpts{
				Name:    "similarity_scores",
				Help:    "Distribution des scores de similarité",
				Buckets: []float64{0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0},
			},
			[]string{"operation", "threshold"},
		),

		// Métriques d'état
		ActiveWorkers: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "vectorization_active_workers",
				Help: "Nombre de workers de vectorisation actifs",
			},
		),

		QueueSize: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "vectorization_queue_size",
				Help: "Taille actuelle de la queue de vectorisation",
			},
		),

		QdrantConnections: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "qdrant_active_connections",
				Help: "Nombre de connexions Qdrant actives",
			},
		),

		MemoryUsage: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "vectorization_memory_usage_bytes",
				Help: "Utilisation mémoire du système de vectorisation en bytes",
			},
		),

		// Métriques de santé
		HealthStatus: promauto.NewGaugeVec(
			prometheus.GaugeOpts{
				Name: "vectorization_health_status",
				Help: "Statut de santé des composants (0=DOWN, 1=UP)",
			},
			[]string{"component", "instance"},
		),

		LastSuccessfulOp: promauto.NewGauge(
			prometheus.GaugeOpts{
				Name: "vectorization_last_successful_operation_timestamp",
				Help: "Timestamp de la dernière opération réussie",
			},
		),

		ConsecutiveErrors: promauto.NewCounterVec(
			prometheus.CounterOpts{
				Name: "vectorization_consecutive_errors",
				Help: "Nombre d'erreurs consécutives par composant",
			},
			[]string{"component", "manager"},
		),
	}
}

// RecordVectorizationRequest enregistre une requête de vectorisation
func (m *VectorizationMetrics) RecordVectorizationRequest(operation, manager, status string) {
	m.VectorizationRequests.WithLabelValues(operation, manager, status).Inc()
}

// RecordVectorizationError enregistre une erreur de vectorisation
func (m *VectorizationMetrics) RecordVectorizationError(operation, manager, errorType string) {
	m.VectorizationErrors.WithLabelValues(operation, manager, errorType).Inc()
	m.ConsecutiveErrors.WithLabelValues("vectorization", manager).Inc()
}

// RecordVectorizationDuration enregistre la durée d'une opération de vectorisation
func (m *VectorizationMetrics) RecordVectorizationDuration(operation, manager string, duration time.Duration) {
	m.VectorizationDuration.WithLabelValues(operation, manager).Observe(duration.Seconds())
}

// RecordQdrantOperation enregistre une opération Qdrant
func (m *VectorizationMetrics) RecordQdrantOperation(operation, collection, status string) {
	m.QdrantOperations.WithLabelValues(operation, collection, status).Inc()
}

// RecordQdrantError enregistre une erreur Qdrant
func (m *VectorizationMetrics) RecordQdrantError(operation, collection, errorType string) {
	m.QdrantErrors.WithLabelValues(operation, collection, errorType).Inc()
	m.ConsecutiveErrors.WithLabelValues("qdrant", collection).Inc()
}

// RecordQdrantQueryDuration enregistre la durée d'une requête Qdrant
func (m *VectorizationMetrics) RecordQdrantQueryDuration(operation, collection string, duration time.Duration) {
	m.QdrantQueryDuration.WithLabelValues(operation, collection).Observe(duration.Seconds())
}

// RecordEmbeddingDuration enregistre la durée de génération d'embeddings
func (m *VectorizationMetrics) RecordEmbeddingDuration(model, textLengthBucket string, duration time.Duration) {
	m.EmbeddingDuration.WithLabelValues(model, textLengthBucket).Observe(duration.Seconds())
}

// UpdateEmbeddingQuality met à jour le score de qualité des embeddings
func (m *VectorizationMetrics) UpdateEmbeddingQuality(model, validationType string, score float64) {
	m.EmbeddingQualityScore.WithLabelValues(model, validationType).Set(score)
}

// RecordSimilarityScore enregistre un score de similarité
func (m *VectorizationMetrics) RecordSimilarityScore(operation, threshold string, score float64) {
	m.SimilarityScores.WithLabelValues(operation, threshold).Observe(score)
}

// UpdateActiveWorkers met à jour le nombre de workers actifs
func (m *VectorizationMetrics) UpdateActiveWorkers(count int) {
	m.ActiveWorkers.Set(float64(count))
}

// UpdateQueueSize met à jour la taille de la queue
func (m *VectorizationMetrics) UpdateQueueSize(size int) {
	m.QueueSize.Set(float64(size))
}

// UpdateQdrantConnections met à jour le nombre de connexions Qdrant
func (m *VectorizationMetrics) UpdateQdrantConnections(count int) {
	m.QdrantConnections.Set(float64(count))
}

// UpdateMemoryUsage met à jour l'utilisation mémoire
func (m *VectorizationMetrics) UpdateMemoryUsage(bytes int64) {
	m.MemoryUsage.Set(float64(bytes))
}

// UpdateHealthStatus met à jour le statut de santé d'un composant
func (m *VectorizationMetrics) UpdateHealthStatus(component, instance string, healthy bool) {
	value := 0.0
	if healthy {
		value = 1.0
	}
	m.HealthStatus.WithLabelValues(component, instance).Set(value)
}

// RecordSuccessfulOperation enregistre une opération réussie
func (m *VectorizationMetrics) RecordSuccessfulOperation() {
	m.LastSuccessfulOp.Set(float64(time.Now().Unix()))
	// Reset des erreurs consécutives sur succès
	m.resetConsecutiveErrors()
}

// resetConsecutiveErrors remet à zéro les compteurs d'erreurs consécutives
func (m *VectorizationMetrics) resetConsecutiveErrors() {
	// Note: Prometheus ne permet pas de reset les compteurs directement
	// Dans un vrai système, on utiliserait des gauges ou une approche différente
	log.Println("Operation successful - consecutive errors conceptually reset")
}

// GetTextLengthBucket retourne le bucket de longueur de texte approprié
func GetTextLengthBucket(textLength int) string {
	switch {
	case textLength < 100:
		return "small"
	case textLength < 500:
		return "medium"
	case textLength < 2000:
		return "large"
	default:
		return "xlarge"
	}
}

// MetricsCollector interface pour collecter des métriques personnalisées
type MetricsCollector interface {
	Collect(ctx context.Context, metrics *VectorizationMetrics) error
}

// StartMetricsCollection démarre la collecte périodique de métriques
func (m *VectorizationMetrics) StartMetricsCollection(ctx context.Context, collectors []MetricsCollector, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				for _, collector := range collectors {
					if err := collector.Collect(ctx, m); err != nil {
						log.Printf("Erreur lors de la collecte de métriques: %v", err)
					}
				}
			}
		}
	}()
}
