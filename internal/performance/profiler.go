package performance

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// ProfilerMetrics contient les métriques de profiling
type ProfilerMetrics struct {
	memoryUsage      prometheus.Gauge
	goroutineCount   prometheus.Gauge
	gcPauses         prometheus.Histogram
	cpuUtilization   prometheus.Gauge
	operationLatency prometheus.Histogram
}

// PerformanceProfiler surveille et optimise les performances
type PerformanceProfiler struct {
	metrics     *ProfilerMetrics
	mu          sync.RWMutex
	ctx         context.Context
	cancel      context.CancelFunc
	config      *ProfilerConfig
	lastGCStats runtime.GCStats
}

// ProfilerConfig contient la configuration du profiler
type ProfilerConfig struct {
	MonitoringInterval time.Duration
	MemoryThreshold    int64 // en bytes
	GoroutineThreshold int
	EnableAutoGC       bool
	LogMetrics         bool
}

// NewPerformanceProfiler crée un nouveau profiler
func NewPerformanceProfiler(config *ProfilerConfig) *PerformanceProfiler {
	ctx, cancel := context.WithCancel(context.Background())

	metrics := &ProfilerMetrics{
		memoryUsage: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "vectorization_memory_usage_bytes",
			Help: "Utilisation mémoire actuelle",
		}),
		goroutineCount: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "vectorization_goroutine_count",
			Help: "Nombre de goroutines actives",
		}),
		gcPauses: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "vectorization_gc_pause_duration_seconds",
			Help:    "Durée des pauses GC",
			Buckets: []float64{0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0},
		}),
		cpuUtilization: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "vectorization_cpu_utilization_percent",
			Help: "Utilisation CPU en pourcentage",
		}),
		operationLatency: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "vectorization_operation_latency_seconds",
			Help:    "Latence des opérations de vectorisation",
			Buckets: prometheus.DefBuckets,
		}),
	}

	profiler := &PerformanceProfiler{
		metrics: metrics,
		ctx:     ctx,
		cancel:  cancel,
		config:  config,
	}

	// Démarrer le monitoring
	go profiler.startMonitoring()

	return profiler
}

// startMonitoring démarre la surveillance des performances
func (pp *PerformanceProfiler) startMonitoring() {
	ticker := time.NewTicker(pp.config.MonitoringInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			pp.collectMetrics()
		case <-pp.ctx.Done():
			return
		}
	}
}

// collectMetrics collecte les métriques système
func (pp *PerformanceProfiler) collectMetrics() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	// Métriques mémoire
	pp.metrics.memoryUsage.Set(float64(m.Alloc))

	// Nombre de goroutines
	pp.metrics.goroutineCount.Set(float64(runtime.NumGoroutine()))

	// Statistiques GC
	var gcStats runtime.GCStats
	runtime.ReadGCStats(&gcStats)

	if len(gcStats.Pause) > len(pp.lastGCStats.Pause) {
		// Nouvelle pause GC
		newPauses := gcStats.Pause[len(pp.lastGCStats.Pause):]
		for _, pause := range newPauses {
			if pause > 0 {
				pp.metrics.gcPauses.Observe(pause.Seconds())
			}
		}
	}
	pp.lastGCStats = gcStats

	// Vérifier les seuils et déclencher des optimisations si nécessaire
	pp.checkThresholds(m)

	if pp.config.LogMetrics {
		pp.logCurrentMetrics(m)
	}
}

// checkThresholds vérifie les seuils et déclenche des actions
func (pp *PerformanceProfiler) checkThresholds(m runtime.MemStats) {
	// Vérifier le seuil mémoire
	if int64(m.Alloc) > pp.config.MemoryThreshold {
		if pp.config.EnableAutoGC {
			runtime.GC()
			fmt.Printf("GC déclenché automatiquement - mémoire: %d MB\n", m.Alloc/1024/1024)
		}
	}

	// Vérifier le seuil de goroutines
	goroutineCount := runtime.NumGoroutine()
	if goroutineCount > pp.config.GoroutineThreshold {
		fmt.Printf("Attention: nombre élevé de goroutines: %d\n", goroutineCount)
	}
}

// logCurrentMetrics affiche les métriques actuelles
func (pp *PerformanceProfiler) logCurrentMetrics(m runtime.MemStats) {
	fmt.Printf("Métriques Performance - Mémoire: %d MB, Goroutines: %d, GC: %d\n",
		m.Alloc/1024/1024,
		runtime.NumGoroutine(),
		m.NumGC)
}

// TrackOperation suit la performance d'une opération
func (pp *PerformanceProfiler) TrackOperation(name string, operation func() error) error {
	start := time.Now()
	defer func() {
		duration := time.Since(start)
		pp.metrics.operationLatency.Observe(duration.Seconds())
	}()

	return operation()
}

// GetOptimalProfilerConfig retourne une configuration optimale
func GetOptimalProfilerConfig() *ProfilerConfig {
	return &ProfilerConfig{
		MonitoringInterval: 10 * time.Second,
		MemoryThreshold:    500 * 1024 * 1024, // 500 MB
		GoroutineThreshold: 1000,
		EnableAutoGC:       true,
		LogMetrics:         false,
	}
}

// Shutdown arrête le profiler
func (pp *PerformanceProfiler) Shutdown() {
	pp.cancel()
}

// GetPerformanceReport génère un rapport de performance
func (pp *PerformanceProfiler) GetPerformanceReport() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"memory": map[string]interface{}{
			"alloc_mb":        m.Alloc / 1024 / 1024,
			"total_alloc_mb":  m.TotalAlloc / 1024 / 1024,
			"sys_mb":          m.Sys / 1024 / 1024,
			"num_gc":          m.NumGC,
			"gc_cpu_fraction": m.GCCPUFraction,
		},
		"goroutines": runtime.NumGoroutine(),
		"cpu_count":  runtime.NumCPU(),
		"go_version": runtime.Version(),
	}
}

// OptimizeForVectorization applique des optimisations spécifiques à la vectorisation
func (pp *PerformanceProfiler) OptimizeForVectorization() {
	// Augmenter GOMAXPROCS si nécessaire
	maxProcs := runtime.GOMAXPROCS(0)
	cpuCount := runtime.NumCPU()

	if maxProcs < cpuCount {
		runtime.GOMAXPROCS(cpuCount)
		fmt.Printf("GOMAXPROCS ajusté de %d à %d\n", maxProcs, cpuCount)
	}

	// Ajuster le pourcentage GC pour les workloads de vectorisation
	// (plus agressif pour libérer rapidement la mémoire des embeddings)
	runtime.SetGCPercent(75) // Plus agressif que les 100% par défaut

	fmt.Println("Optimisations pour vectorisation appliquées")
}
