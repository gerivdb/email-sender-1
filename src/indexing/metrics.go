package indexing

import (
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Metrics holds all Prometheus metrics for the indexing system
type Metrics struct {
	// Document processing metrics
	DocumentsProcessed prometheus.Counter
	DocumentErrors     prometheus.Counter
	ProcessingDuration prometheus.Histogram
	DocumentSize       prometheus.Histogram

	// Chunking metrics
	ChunksCreated    prometheus.Counter
	ChunkSize        prometheus.Histogram
	ChunkingDuration prometheus.Histogram

	// Embedding metrics
	EmbeddingsGenerated prometheus.Counter
	EmbeddingErrors     prometheus.Counter
	EmbeddingDuration   prometheus.Histogram
	EmbeddingCacheHits  prometheus.Counter
	EmbeddingCacheMiss  prometheus.Counter

	// Qdrant metrics
	QdrantUpserts   prometheus.Counter
	QdrantErrors    prometheus.Counter
	QdrantLatency   prometheus.Histogram
	QdrantBatchSize prometheus.Histogram

	// Vector quality metrics
	IntraClusterDistance prometheus.Gauge
	InterClusterDistance prometheus.Gauge
	SilhouetteScore      prometheus.Gauge
	TotalVectors         prometheus.Gauge

	// File type metrics
	FileTypeProcessed *prometheus.CounterVec
}

// NewMetrics creates and registers all metrics
func NewMetrics(namespace string) *Metrics {
	return &Metrics{
		DocumentsProcessed: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "documents_processed_total",
			Help:      "The total number of documents processed",
		}),

		DocumentErrors: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "document_errors_total",
			Help:      "The total number of document processing errors",
		}),

		ProcessingDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "document_processing_duration_seconds",
			Help:      "Time spent processing documents",
			Buckets:   prometheus.ExponentialBuckets(0.1, 2.0, 10),
		}),

		DocumentSize: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "document_size_bytes",
			Help:      "Size of processed documents in bytes",
			Buckets:   prometheus.ExponentialBuckets(1000, 10, 6),
		}),

		ChunksCreated: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "chunks_created_total",
			Help:      "The total number of chunks created",
		}),

		ChunkSize: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "chunk_size_chars",
			Help:      "Size of chunks in characters",
			Buckets:   prometheus.LinearBuckets(100, 100, 10),
		}),

		ChunkingDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "chunking_duration_seconds",
			Help:      "Time spent chunking documents",
			Buckets:   prometheus.ExponentialBuckets(0.001, 2.0, 10),
		}),

		EmbeddingsGenerated: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "embeddings_generated_total",
			Help:      "The total number of embeddings generated",
		}),

		EmbeddingErrors: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "embedding_errors_total",
			Help:      "The total number of embedding generation errors",
		}),

		EmbeddingDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "embedding_generation_duration_seconds",
			Help:      "Time spent generating embeddings",
			Buckets:   prometheus.ExponentialBuckets(0.01, 2.0, 10),
		}),

		EmbeddingCacheHits: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "embedding_cache_hits_total",
			Help:      "The total number of embedding cache hits",
		}),

		EmbeddingCacheMiss: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "embedding_cache_misses_total",
			Help:      "The total number of embedding cache misses",
		}),

		QdrantUpserts: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "qdrant_upserts_total",
			Help:      "The total number of points upserted to Qdrant",
		}),

		QdrantErrors: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "qdrant_errors_total",
			Help:      "The total number of Qdrant operation errors",
		}),

		QdrantLatency: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "qdrant_operation_duration_seconds",
			Help:      "Time spent on Qdrant operations",
			Buckets:   prometheus.ExponentialBuckets(0.01, 2.0, 10),
		}),

		QdrantBatchSize: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "qdrant_batch_size",
			Help:      "Size of batches sent to Qdrant",
			Buckets:   prometheus.LinearBuckets(10, 10, 10),
		}),

		IntraClusterDistance: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "intra_cluster_distance",
			Help:      "Intra-cluster distance for vector quality",
		}),

		InterClusterDistance: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "inter_cluster_distance",
			Help:      "Inter-cluster distance for vector quality",
		}),

		SilhouetteScore: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "silhouette_score",
			Help:      "Silhouette score for vector quality",
		}),

		TotalVectors: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "total_vectors",
			Help:      "Total number of vectors",
		}),

		FileTypeProcessed: promauto.NewCounterVec(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "files_processed_by_type_total",
			Help:      "The total number of files processed by type",
		}, []string{"file_type"}),
	}
}

// RecordDocumentProcessing records metrics for document processing
func (m *Metrics) RecordDocumentProcessing(fileType string, size int, duration time.Duration, err error) {
	m.DocumentsProcessed.Inc()
	if err != nil {
		m.DocumentErrors.Inc()
	}
	m.ProcessingDuration.Observe(duration.Seconds())
	m.DocumentSize.Observe(float64(size))
	m.FileTypeProcessed.WithLabelValues(fileType).Inc()
}

// RecordChunking records metrics for document chunking
func (m *Metrics) RecordChunking(chunks []string, duration time.Duration) {
	m.ChunksCreated.Add(float64(len(chunks)))
	m.ChunkingDuration.Observe(duration.Seconds())
	for _, chunk := range chunks {
		m.ChunkSize.Observe(float64(len(chunk)))
	}
}

// RecordEmbeddingGeneration records metrics for embedding generation
func (m *Metrics) RecordEmbeddingGeneration(numEmbeddings int, cached int, duration time.Duration, err error) {
	m.EmbeddingsGenerated.Add(float64(numEmbeddings))
	if err != nil {
		m.EmbeddingErrors.Inc()
	}
	m.EmbeddingDuration.Observe(duration.Seconds())
	m.EmbeddingCacheHits.Add(float64(cached))
	m.EmbeddingCacheMiss.Add(float64(numEmbeddings - cached))
}

// RecordQdrantOperation records metrics for Qdrant operations
func (m *Metrics) RecordQdrantOperation(batchSize int, duration time.Duration, err error) {
	m.QdrantUpserts.Add(float64(batchSize))
	if err != nil {
		m.QdrantErrors.Inc()
	}
	m.QdrantLatency.Observe(duration.Seconds())
	m.QdrantBatchSize.Observe(float64(batchSize))
}

// RecordIndexingTime records the time taken for indexing
func (m *Metrics) RecordIndexingTime(duration time.Duration) {
	m.ProcessingDuration.Observe(duration.Seconds())
}

// RecordVectorQualityStats records vector quality metrics
func (m *Metrics) RecordVectorQualityStats(stats VectorQualityStats) {
	m.IntraClusterDistance.Set(stats.IntraClusterDistance)
	m.InterClusterDistance.Set(stats.InterClusterDistance)
	m.SilhouetteScore.Set(stats.SilhouetteScore)
	m.TotalVectors.Set(float64(stats.TotalVectors))
}

// VectorQualityStats contains quality metrics for vectors
type VectorQualityStats struct {
	IntraClusterDistance float64
	InterClusterDistance float64
	SilhouetteScore      float64
	TotalVectors         int
}
