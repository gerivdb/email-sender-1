package indexing

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// EmbeddingQualityMetrics tracks metrics related to embedding quality
type EmbeddingQualityMetrics struct {
	// Embedding quality metrics
	VectorNorm     prometheus.Histogram
	VectorSparsity prometheus.Histogram
	Dimensionality prometheus.Gauge
	ClusterDensity prometheus.Histogram
	OutlierScore   prometheus.Histogram

	// Semantic similarity metrics
	SimilarityScore prometheus.Histogram
	QueryRelevance  prometheus.Histogram
	RecallScore     prometheus.Histogram

	// Cache effectiveness
	CacheHitRatio  prometheus.Gauge
	CacheFreshness prometheus.Histogram
	CacheSize      prometheus.Gauge

	// System health metrics
	CPUUsage       prometheus.Gauge
	MemoryUsage    prometheus.Gauge
	DiskUsage      prometheus.Gauge
	GoroutineCount prometheus.Gauge
	ErrorRate      prometheus.Gauge
	LatencyP95     prometheus.Gauge
	LatencyP99     prometheus.Gauge

	// QPS and throughput
	QueriesPerSecond prometheus.Counter
	BytesProcessed   prometheus.Counter
	VectorsIndexed   prometheus.Counter
}

// NewEmbeddingQualityMetrics creates new metrics for embedding quality monitoring
func NewEmbeddingQualityMetrics(namespace string) *EmbeddingQualityMetrics {
	return &EmbeddingQualityMetrics{
		VectorNorm: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "embedding_vector_norm",
			Help:      "L2 norm distribution of embedding vectors",
			Buckets:   prometheus.LinearBuckets(0, 0.1, 20),
		}),

		VectorSparsity: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "embedding_vector_sparsity",
			Help:      "Percentage of near-zero values in embedding vectors",
			Buckets:   prometheus.LinearBuckets(0, 0.05, 20),
		}),

		Dimensionality: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "embedding_dimensionality",
			Help:      "Dimensionality of the embedding vectors",
		}),

		ClusterDensity: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "embedding_cluster_density",
			Help:      "Density of vector clusters in embedding space",
			Buckets:   prometheus.ExponentialBuckets(1, 2, 10),
		}),

		OutlierScore: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "embedding_outlier_score",
			Help:      "Distribution of outlier scores for vectors",
			Buckets:   prometheus.LinearBuckets(0, 0.1, 10),
		}),

		SimilarityScore: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "semantic_similarity_score",
			Help:      "Distribution of semantic similarity scores",
			Buckets:   prometheus.LinearBuckets(0, 0.1, 10),
		}),

		QueryRelevance: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "query_relevance_score",
			Help:      "Distribution of query relevance scores",
			Buckets:   prometheus.LinearBuckets(0, 0.1, 10),
		}),

		RecallScore: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "recall_score",
			Help:      "Distribution of recall scores",
			Buckets:   prometheus.LinearBuckets(0, 0.1, 10),
		}),

		CacheHitRatio: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "cache_hit_ratio",
			Help:      "Ratio of cache hits to total requests",
		}),

		CacheFreshness: promauto.NewHistogram(prometheus.HistogramOpts{
			Namespace: namespace,
			Name:      "cache_freshness_seconds",
			Help:      "Age distribution of cache entries",
			Buckets:   prometheus.ExponentialBuckets(60, 2, 10),
		}),

		CacheSize: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "cache_size_bytes",
			Help:      "Total size of the embedding cache in bytes",
		}),

		CPUUsage: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "cpu_usage_percent",
			Help:      "CPU usage percentage",
		}),

		MemoryUsage: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "memory_usage_bytes",
			Help:      "Memory usage in bytes",
		}),

		DiskUsage: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "disk_usage_bytes",
			Help:      "Disk usage in bytes",
		}),

		GoroutineCount: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "goroutine_count",
			Help:      "Number of running goroutines",
		}),

		ErrorRate: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "error_rate",
			Help:      "Rate of errors per second",
		}),

		LatencyP95: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "latency_p95_seconds",
			Help:      "95th percentile latency",
		}),

		LatencyP99: promauto.NewGauge(prometheus.GaugeOpts{
			Namespace: namespace,
			Name:      "latency_p99_seconds",
			Help:      "99th percentile latency",
		}),

		QueriesPerSecond: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "queries_per_second",
			Help:      "Number of queries processed per second",
		}),

		BytesProcessed: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "bytes_processed_total",
			Help:      "Total number of bytes processed",
		}),

		VectorsIndexed: promauto.NewCounter(prometheus.CounterOpts{
			Namespace: namespace,
			Name:      "vectors_indexed_total",
			Help:      "Total number of vectors indexed",
		}),
	}
}

// RecordEmbeddingQuality records quality metrics for an embedding vector
func (m *EmbeddingQualityMetrics) RecordEmbeddingQuality(vector []float32) {
	norm := calculateL2Norm(vector)
	sparsity := calculateSparsity(vector)
	m.VectorNorm.Observe(float64(norm))
	m.VectorSparsity.Observe(sparsity)
}

// RecordClusterMetrics records metrics about vector clustering
func (m *EmbeddingQualityMetrics) RecordClusterMetrics(density float64, outlierScore float64) {
	m.ClusterDensity.Observe(density)
	m.OutlierScore.Observe(outlierScore)
}

// RecordQueryMetrics records metrics about query performance
func (m *EmbeddingQualityMetrics) RecordQueryMetrics(similarityScore, relevance, recall float64) {
	m.SimilarityScore.Observe(similarityScore)
	m.QueryRelevance.Observe(relevance)
	m.RecallScore.Observe(recall)
}

// RecordSystemHealth records system health metrics
func (m *EmbeddingQualityMetrics) RecordSystemHealth(cpuUsage, memoryUsage, diskUsage float64, goroutines int) {
	m.CPUUsage.Set(cpuUsage)
	m.MemoryUsage.Set(memoryUsage)
	m.DiskUsage.Set(diskUsage)
	m.GoroutineCount.Set(float64(goroutines))
}

// RecordLatency records latency metrics
func (m *EmbeddingQualityMetrics) RecordLatency(p95, p99 float64) {
	m.LatencyP95.Set(p95)
	m.LatencyP99.Set(p99)
}

// Helper functions

func calculateL2Norm(vector []float32) float32 {
	var sum float32
	for _, v := range vector {
		sum += v * v
	}
	return float32(sum)
}

func calculateSparsity(vector []float32) float64 {
	var zeroCount int
	threshold := float32(1e-6)
	for _, v := range vector {
		if abs(v) < threshold {
			zeroCount++
		}
	}
	return float64(zeroCount) / float64(len(vector))
}

func abs(x float32) float32 {
	if x < 0 {
		return -x
	}
	return x
}
