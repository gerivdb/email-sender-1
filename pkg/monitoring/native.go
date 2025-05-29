package monitoring

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"runtime"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// NativeMonitor provides monitoring without external dependencies
type NativeMonitor struct {
	mu               sync.RWMutex
	startTime        time.Time
	metrics          *SystemMetrics
	httpServer       *http.Server
	collectionTicker *time.Ticker
	ctx              context.Context
	cancel           context.CancelFunc

	// Prometheus metrics
	requestDuration   *prometheus.HistogramVec
	requestCount      *prometheus.CounterVec
	activeConnections prometheus.Gauge
	systemCPU         prometheus.Gauge
	systemMemory      prometheus.Gauge
	cacheHitRate      prometheus.Gauge
}

// SystemMetrics holds system performance metrics
type SystemMetrics struct {
	Timestamp       time.Time `json:"timestamp"`
	Uptime          string    `json:"uptime"`
	CPUUsage        float64   `json:"cpu_usage_percent"`
	MemoryUsage     uint64    `json:"memory_usage_bytes"`
	MemoryPercent   float64   `json:"memory_usage_percent"`
	GoroutineCount  int       `json:"goroutine_count"`
	TotalRequests   uint64    `json:"total_requests"`
	ActiveRequests  int64     `json:"active_requests"`
	ErrorCount      uint64    `json:"error_count"`
	AvgResponseTime float64   `json:"avg_response_time_ms"`
	CacheHitRate    float64   `json:"cache_hit_rate_percent"`
	DiskUsage       uint64    `json:"disk_usage_bytes"`
	NetworkBytesIn  uint64    `json:"network_bytes_in"`
	NetworkBytesOut uint64    `json:"network_bytes_out"`
}

// NewNativeMonitor creates a new native monitoring instance
func NewNativeMonitor(port int, collectionInterval time.Duration) *NativeMonitor {
	ctx, cancel := context.WithCancel(context.Background())

	// Initialize Prometheus metrics
	requestDuration := prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name: "http_request_duration_seconds",
			Help: "HTTP request duration in seconds",
		},
		[]string{"method", "endpoint", "status"},
	)

	requestCount := prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	activeConnections := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "http_active_connections",
			Help: "Number of active HTTP connections",
		},
	)

	systemCPU := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "system_cpu_usage_percent",
			Help: "System CPU usage percentage",
		},
	)

	systemMemory := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "system_memory_usage_bytes",
			Help: "System memory usage in bytes",
		},
	)

	cacheHitRate := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "cache_hit_rate_percent",
			Help: "Cache hit rate percentage",
		},
	)

	// Register metrics
	prometheus.MustRegister(requestDuration, requestCount, activeConnections, systemCPU, systemMemory, cacheHitRate)

	monitor := &NativeMonitor{
		startTime:         time.Now(),
		metrics:           &SystemMetrics{},
		collectionTicker:  time.NewTicker(collectionInterval),
		ctx:               ctx,
		cancel:            cancel,
		requestDuration:   requestDuration,
		requestCount:      requestCount,
		activeConnections: activeConnections,
		systemCPU:         systemCPU,
		systemMemory:      systemMemory,
		cacheHitRate:      cacheHitRate,
	}

	// Setup HTTP server for metrics
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	mux.HandleFunc("/health", monitor.healthHandler)
	mux.HandleFunc("/metrics/json", monitor.jsonMetricsHandler)
	mux.HandleFunc("/", monitor.dashboardHandler)

	monitor.httpServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: mux,
	}

	return monitor
}

// Start begins monitoring collection and HTTP server
func (nm *NativeMonitor) Start() error {
	// Start metrics collection
	go nm.collectMetrics()

	// Start HTTP server
	log.Printf("Starting monitoring server on %s", nm.httpServer.Addr)
	go func() {
		if err := nm.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("Monitoring server error: %v", err)
		}
	}()

	return nil
}

// Stop stops the monitoring system
func (nm *NativeMonitor) Stop() error {
	nm.cancel()
	nm.collectionTicker.Stop()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	return nm.httpServer.Shutdown(ctx)
}

// collectMetrics collects system metrics periodically
func (nm *NativeMonitor) collectMetrics() {
	for {
		select {
		case <-nm.ctx.Done():
			return
		case <-nm.collectionTicker.C:
			nm.updateMetrics()
		}
	}
}

// updateMetrics updates current system metrics
func (nm *NativeMonitor) updateMetrics() {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	nm.metrics.Timestamp = time.Now()
	nm.metrics.Uptime = time.Since(nm.startTime).String()
	nm.metrics.MemoryUsage = m.Alloc
	nm.metrics.GoroutineCount = runtime.NumGoroutine()

	// Update Prometheus metrics
	nm.systemMemory.Set(float64(m.Alloc))

	// Calculate memory percentage (simplified)
	totalMemory := float64(m.Sys)
	if totalMemory > 0 {
		nm.metrics.MemoryPercent = (float64(m.Alloc) / totalMemory) * 100
	}

	// Note: CPU usage calculation would require more complex implementation
	// For production, consider using third-party libraries like gopsutil
	nm.metrics.CPUUsage = nm.estimateCPUUsage()
	nm.systemCPU.Set(nm.metrics.CPUUsage)
}

// estimateCPUUsage provides a simple CPU usage estimation
func (nm *NativeMonitor) estimateCPUUsage() float64 {
	// Simplified CPU estimation based on goroutine count and memory pressure
	// In production, use proper CPU monitoring libraries
	goroutines := float64(runtime.NumGoroutine())

	// Basic heuristic: more goroutines = higher CPU usage
	cpuEstimate := (goroutines / 100.0) * 10.0
	if cpuEstimate > 100.0 {
		cpuEstimate = 100.0
	}

	return cpuEstimate
}

// RecordRequest records HTTP request metrics
func (nm *NativeMonitor) RecordRequest(method, endpoint, status string, duration time.Duration) {
	nm.requestDuration.WithLabelValues(method, endpoint, status).Observe(duration.Seconds())
	nm.requestCount.WithLabelValues(method, endpoint, status).Inc()

	nm.mu.Lock()
	nm.metrics.TotalRequests++
	nm.metrics.AvgResponseTime = float64(duration.Milliseconds())
	nm.mu.Unlock()
}

// RecordError records an error occurrence
func (nm *NativeMonitor) RecordError() {
	nm.mu.Lock()
	nm.metrics.ErrorCount++
	nm.mu.Unlock()
}

// UpdateCacheHitRate updates cache hit rate metric
func (nm *NativeMonitor) UpdateCacheHitRate(hitRate float64) {
	nm.mu.Lock()
	nm.metrics.CacheHitRate = hitRate
	nm.mu.Unlock()

	nm.cacheHitRate.Set(hitRate)
}

// GetMetrics returns current metrics
func (nm *NativeMonitor) GetMetrics() *SystemMetrics {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	// Return a copy
	metricsCopy := *nm.metrics
	return &metricsCopy
}

// healthHandler provides health check endpoint
func (nm *NativeMonitor) healthHandler(w http.ResponseWriter, r *http.Request) {
	metrics := nm.GetMetrics()

	status := "healthy"
	httpStatus := http.StatusOK

	// Simple health checks
	if metrics.MemoryPercent > 90 {
		status = "unhealthy - high memory usage"
		httpStatus = http.StatusServiceUnavailable
	} else if metrics.CPUUsage > 90 {
		status = "unhealthy - high CPU usage"
		httpStatus = http.StatusServiceUnavailable
	} else if metrics.GoroutineCount > 10000 {
		status = "unhealthy - too many goroutines"
		httpStatus = http.StatusServiceUnavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpStatus)

	response := map[string]interface{}{
		"status":    status,
		"timestamp": time.Now(),
		"uptime":    metrics.Uptime,
		"metrics":   metrics,
	}

	json.NewEncoder(w).Encode(response)
}

// jsonMetricsHandler provides metrics in JSON format
func (nm *NativeMonitor) jsonMetricsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(nm.GetMetrics())
}

// dashboardHandler provides a simple HTML dashboard
func (nm *NativeMonitor) dashboardHandler(w http.ResponseWriter, r *http.Request) {
	metrics := nm.GetMetrics()

	html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <title>Email Sender Monitoring</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .metric-card { background: white; border-radius: 8px; padding: 20px; margin: 10px; 
                       box-shadow: 0 2px 4px rgba(0,0,0,0.1); display: inline-block; min-width: 200px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #333; }
        .metric-label { color: #666; font-size: 0.9em; }
        .status-healthy { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-danger { color: #dc3545; }
        .header { text-align: center; margin-bottom: 30px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Email Sender Monitoring Dashboard</h1>
            <p>Last updated: %s</p>
            <p>Uptime: %s</p>
        </div>
        
        <div class="grid">
            <div class="metric-card">
                <div class="metric-label">Memory Usage</div>
                <div class="metric-value %s">%.1f%%</div>
                <small>%s</small>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">CPU Usage</div>
                <div class="metric-value %s">%.1f%%</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">Goroutines</div>
                <div class="metric-value">%d</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">Total Requests</div>
                <div class="metric-value">%d</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">Error Count</div>
                <div class="metric-value %s">%d</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">Cache Hit Rate</div>
                <div class="metric-value %s">%.1f%%</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-label">Avg Response Time</div>
                <div class="metric-value">%.1f ms</div>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center;">
            <p><a href="/health">Health Check</a> | <a href="/metrics">Prometheus Metrics</a> | <a href="/metrics/json">JSON Metrics</a></p>
        </div>
    </div>
</body>
</html>`,
		metrics.Timestamp.Format("2006-01-02 15:04:05"),
		metrics.Uptime,
		getStatusClass(metrics.MemoryPercent, 80, 90),
		metrics.MemoryPercent,
		formatBytes(metrics.MemoryUsage),
		getStatusClass(metrics.CPUUsage, 70, 85),
		metrics.CPUUsage,
		metrics.GoroutineCount,
		metrics.TotalRequests,
		getErrorStatusClass(metrics.ErrorCount),
		metrics.ErrorCount,
		getCacheStatusClass(metrics.CacheHitRate),
		metrics.CacheHitRate,
		metrics.AvgResponseTime,
	)

	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))
}

// Helper functions
func getStatusClass(value, warning, danger float64) string {
	if value >= danger {
		return "status-danger"
	} else if value >= warning {
		return "status-warning"
	}
	return "status-healthy"
}

func getErrorStatusClass(errorCount uint64) string {
	if errorCount > 100 {
		return "status-danger"
	} else if errorCount > 10 {
		return "status-warning"
	}
	return "status-healthy"
}

func getCacheStatusClass(hitRate float64) string {
	if hitRate < 50 {
		return "status-danger"
	} else if hitRate < 70 {
		return "status-warning"
	}
	return "status-healthy"
}

func formatBytes(bytes uint64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}
