package monitoring

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// MetricsRegistry centralise les métriques Prometheus
type MetricsRegistry struct {
	JobQueued     prometheus.Counter
	JobCompleted  prometheus.Counter
	JobFailed     prometheus.Counter
	JobLatency    prometheus.Histogram
	ActiveWorkers prometheus.Gauge
	QueueSize     prometheus.Gauge
}

// NewMetricsRegistry initialise les métriques
func NewMetricsRegistry() *MetricsRegistry {
	mr := &MetricsRegistry{
		JobQueued: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "go_queue_jobs_queued_total",
			Help: "Total jobs queued",
		}),
		JobCompleted: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "go_queue_jobs_completed_total",
			Help: "Total jobs completed",
		}),
		JobFailed: prometheus.NewCounter(prometheus.CounterOpts{
			Name: "go_queue_jobs_failed_total",
			Help: "Total jobs failed",
		}),
		JobLatency: prometheus.NewHistogram(prometheus.HistogramOpts{
			Name:    "go_queue_job_latency_seconds",
			Help:    "Job execution latency (seconds)",
			Buckets: prometheus.LinearBuckets(0.01, 0.05, 20),
		}),
		ActiveWorkers: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "go_queue_active_workers",
			Help: "Number of active workers",
		}),
		QueueSize: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "go_queue_size",
			Help: "Current queue size",
		}),
	}
	prometheus.MustRegister(
		mr.JobQueued,
		mr.JobCompleted,
		mr.JobFailed,
		mr.JobLatency,
		mr.ActiveWorkers,
		mr.QueueSize,
	)
	return mr
}

// ExposeMetricsHandler expose /metrics pour Prometheus
func ExposeMetricsHandler() {
	http.Handle("/metrics", promhttp.Handler())
}
