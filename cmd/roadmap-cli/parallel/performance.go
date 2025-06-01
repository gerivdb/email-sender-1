// Package parallel provides performance monitoring and resource management
package parallel

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"time"
)

// PerformanceMonitor tracks system performance during parallel processing
type PerformanceMonitor struct {
	startTime         time.Time
	samples           []PerformanceSample
	mu                sync.RWMutex
	stopChan          chan struct{}
	sampleInterval    time.Duration
	maxSamples        int
	activeGoroutines  int
	peakMemoryUsage   uint64
	totalGCPauses     time.Duration
	lastGCStats       runtime.MemStats
}

// PerformanceSample represents a point-in-time performance measurement
type PerformanceSample struct {
	Timestamp    time.Time `json:"timestamp"`
	Goroutines   int       `json:"goroutines"`
	MemoryMB     uint64    `json:"memory_mb"`
	GCPauseMS    float64   `json:"gc_pause_ms"`
	CPUUsage     float64   `json:"cpu_usage"`
	AllocRate    uint64    `json:"alloc_rate_mb_per_sec"`
}

// PerformanceReport provides a comprehensive performance summary
type PerformanceReport struct {
	Duration            time.Duration         `json:"duration"`
	Samples             []PerformanceSample   `json:"samples"`
	PeakMemoryMB        uint64                `json:"peak_memory_mb"`
	AverageMemoryMB     uint64                `json:"average_memory_mb"`
	PeakGoroutines      int                   `json:"peak_goroutines"`
	TotalGCPauses       time.Duration         `json:"total_gc_pauses"`
	AverageGCPauseMS    float64               `json:"average_gc_pause_ms"`
	MemoryGrowthRate    float64               `json:"memory_growth_rate_mb_per_sec"`
	Recommendations     []string              `json:"recommendations"`
}

// NewPerformanceMonitor creates a new performance monitor
func NewPerformanceMonitor(sampleInterval time.Duration, maxSamples int) *PerformanceMonitor {
	pm := &PerformanceMonitor{
		startTime:      time.Now(),
		stopChan:       make(chan struct{}),
		sampleInterval: sampleInterval,
		maxSamples:     maxSamples,
		samples:        make([]PerformanceSample, 0, maxSamples),
	}

	// Initialize baseline GC stats
	runtime.ReadMemStats(&pm.lastGCStats)

	return pm
}

// Start begins performance monitoring in a background goroutine
func (pm *PerformanceMonitor) Start(ctx context.Context) {
	go pm.monitorLoop(ctx)
}

// Stop stops performance monitoring and returns a report
func (pm *PerformanceMonitor) Stop() PerformanceReport {
	close(pm.stopChan)
	return pm.generateReport()
}

// GetCurrentSample returns the most recent performance sample
func (pm *PerformanceMonitor) GetCurrentSample() PerformanceSample {
	pm.mu.RLock()
	defer pm.mu.RUnlock()
	
	if len(pm.samples) == 0 {
		return PerformanceSample{}
	}
	
	return pm.samples[len(pm.samples)-1]
}

// monitorLoop runs the monitoring loop
func (pm *PerformanceMonitor) monitorLoop(ctx context.Context) {
	ticker := time.NewTicker(pm.sampleInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			pm.takeSample()
		case <-pm.stopChan:
			return
		case <-ctx.Done():
			return
		}
	}
}

// takeSample captures current performance metrics
func (pm *PerformanceMonitor) takeSample() {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	sample := PerformanceSample{
		Timestamp:  time.Now(),
		Goroutines: runtime.NumGoroutine(),
		MemoryMB:   memStats.Alloc / 1024 / 1024,
	}

	// Calculate GC pause since last sample
	if pm.lastGCStats.NumGC < memStats.NumGC {
		// New GC cycles occurred
		gcPauses := time.Duration(0)
		for i := pm.lastGCStats.NumGC; i < memStats.NumGC; i++ {
			gcPauses += time.Duration(memStats.PauseNs[i%256])
		}
		sample.GCPauseMS = float64(gcPauses.Nanoseconds()) / 1e6
	}

	// Calculate allocation rate (MB/sec since last sample)
	if len(pm.samples) > 0 {
		lastSample := pm.samples[len(pm.samples)-1]
		timeDiff := sample.Timestamp.Sub(lastSample.Timestamp).Seconds()
		allocDiff := memStats.TotalAlloc - pm.lastGCStats.TotalAlloc
		sample.AllocRate = uint64(float64(allocDiff) / 1024 / 1024 / timeDiff)
	}

	pm.mu.Lock()
	defer pm.mu.Unlock()

	// Update peak values
	if sample.MemoryMB > pm.peakMemoryUsage {
		pm.peakMemoryUsage = sample.MemoryMB
	}

	if sample.Goroutines > pm.activeGoroutines {
		pm.activeGoroutines = sample.Goroutines
	}

	// Add sample to collection
	pm.samples = append(pm.samples, sample)

	// Maintain max samples limit
	if len(pm.samples) > pm.maxSamples {
		// Remove oldest sample
		copy(pm.samples, pm.samples[1:])
		pm.samples = pm.samples[:len(pm.samples)-1]
	}

	// Update last GC stats
	pm.lastGCStats = memStats

	// Print periodic status
	if len(pm.samples)%10 == 0 { // Every 10 samples
		fmt.Printf("📊 Performance: %d goroutines, %d MB memory, %.1f ms GC pause\n",
			sample.Goroutines, sample.MemoryMB, sample.GCPauseMS)
	}
}

// generateReport creates a comprehensive performance report
func (pm *PerformanceMonitor) generateReport() PerformanceReport {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	duration := time.Since(pm.startTime)
	
	report := PerformanceReport{
		Duration:       duration,
		Samples:        make([]PerformanceSample, len(pm.samples)),
		PeakMemoryMB:   pm.peakMemoryUsage,
		PeakGoroutines: pm.activeGoroutines,
	}

	// Copy samples
	copy(report.Samples, pm.samples)

	if len(pm.samples) == 0 {
		return report
	}

	// Calculate averages
	var totalMemory uint64
	var totalGCPause float64
	var memoryStart, memoryEnd uint64

	memoryStart = pm.samples[0].MemoryMB
	memoryEnd = pm.samples[len(pm.samples)-1].MemoryMB

	for _, sample := range pm.samples {
		totalMemory += sample.MemoryMB
		totalGCPause += sample.GCPauseMS
	}

	report.AverageMemoryMB = totalMemory / uint64(len(pm.samples))
	report.AverageGCPauseMS = totalGCPause / float64(len(pm.samples))

	// Calculate memory growth rate (MB/sec)
	if duration.Seconds() > 0 {
		report.MemoryGrowthRate = float64(memoryEnd-memoryStart) / duration.Seconds()
	}

	// Generate recommendations
	report.Recommendations = pm.generateRecommendations(report)

	return report
}

// generateRecommendations provides performance optimization suggestions
func (pm *PerformanceMonitor) generateRecommendations(report PerformanceReport) []string {
	var recommendations []string

	// Memory recommendations
	if report.PeakMemoryMB > 1000 { // 1GB
		recommendations = append(recommendations, 
			"High memory usage detected. Consider reducing batch sizes or worker count.")
	}

	if report.MemoryGrowthRate > 50 { // 50MB/sec growth
		recommendations = append(recommendations, 
			"Rapid memory growth detected. Check for memory leaks or increase GC frequency.")
	}

	// GC recommendations
	if report.AverageGCPauseMS > 10 {
		recommendations = append(recommendations, 
			"High GC pause times. Consider tuning GOGC environment variable or reducing allocation rate.")
	}

	// Goroutine recommendations
	if report.PeakGoroutines > runtime.NumCPU()*10 {
		recommendations = append(recommendations, 
			"High goroutine count. Consider reducing worker pool size to prevent resource contention.")
	}

	// Duration recommendations
	if len(report.Samples) > 0 {
		lastSample := report.Samples[len(report.Samples)-1]
		if lastSample.AllocRate > 100 { // 100MB/sec allocation
			recommendations = append(recommendations, 
				"High allocation rate. Consider object pooling or reducing temporary object creation.")
		}
	}

	if len(recommendations) == 0 {
		recommendations = append(recommendations, "Performance looks good! No specific optimizations needed.")
	}

	return recommendations
}

// ResourceManager provides dynamic resource management during processing
type ResourceManager struct {
	maxWorkers     int
	maxMemoryMB    uint64
	currentWorkers int
	monitor        *PerformanceMonitor
	mu             sync.Mutex
}

// NewResourceManager creates a new resource manager
func NewResourceManager(maxWorkers int, maxMemoryMB uint64, monitor *PerformanceMonitor) *ResourceManager {
	return &ResourceManager{
		maxWorkers:     maxWorkers,
		maxMemoryMB:    maxMemoryMB,
		currentWorkers: maxWorkers,
		monitor:        monitor,
	}
}

// ShouldReduceWorkers checks if worker count should be reduced due to resource pressure
func (rm *ResourceManager) ShouldReduceWorkers() bool {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	if rm.monitor == nil {
		return false
	}

	sample := rm.monitor.GetCurrentSample()
	
	// Reduce workers if memory usage is too high
	if sample.MemoryMB > rm.maxMemoryMB {
		return true
	}

	// Reduce workers if GC pressure is too high
	if sample.GCPauseMS > 20 { // 20ms pause threshold
		return true
	}

	return false
}

// GetOptimalWorkerCount returns the recommended number of workers
func (rm *ResourceManager) GetOptimalWorkerCount() int {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	if rm.ShouldReduceWorkers() && rm.currentWorkers > 1 {
		rm.currentWorkers = rm.currentWorkers / 2
		fmt.Printf("🔽 Reducing workers to %d due to resource pressure\n", rm.currentWorkers)
	}

	return rm.currentWorkers
}

// SetWorkerCount updates the current worker count
func (rm *ResourceManager) SetWorkerCount(count int) {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	if count > 0 && count <= rm.maxWorkers {
		rm.currentWorkers = count
	}
}
