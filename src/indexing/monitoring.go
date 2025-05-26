package indexing

import (
	"runtime"
	"sync"
	"time"
)

// ResourceStats holds system resource usage statistics
type ResourceStats struct {
	CPUUsagePercent float64
	MemoryUsageMB   float64
	PeakMemoryMB    int64
	GoroutineCount  int
}

// ResourceMonitor monitors system resource usage
type ResourceMonitor struct {
	stats     ResourceStats
	stopChan  chan struct{}
	statMutex sync.RWMutex
}

// NewResourceMonitor creates a new ResourceMonitor instance
func NewResourceMonitor() *ResourceMonitor {
	return &ResourceMonitor{
		stopChan: make(chan struct{}),
	}
}

// Start begins monitoring system resources
func (m *ResourceMonitor) Start() {
	go func() {
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-m.stopChan:
				return
			case <-ticker.C:
				m.updateStats()
			}
		}
	}()
}

// Stop stops the resource monitoring
func (m *ResourceMonitor) Stop() {
	close(m.stopChan)
}

// GetStats returns the current resource statistics
func (m *ResourceMonitor) GetStats() ResourceStats {
	m.statMutex.RLock()
	defer m.statMutex.RUnlock()
	return m.stats
}

// updateStats updates the current resource statistics
func (m *ResourceMonitor) updateStats() {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	m.statMutex.Lock()
	defer m.statMutex.Unlock()

	m.stats.MemoryUsageMB = float64(memStats.Alloc) / (1024 * 1024)
	if int64(m.stats.MemoryUsageMB) > m.stats.PeakMemoryMB {
		m.stats.PeakMemoryMB = int64(m.stats.MemoryUsageMB)
	}
	m.stats.GoroutineCount = runtime.NumGoroutine()

	// CPU usage calculation would require OS-specific implementations
	// For now, we'll just use a placeholder
	m.stats.CPUUsagePercent = 0
}

// EmbeddingQualityMetrics holds metrics for monitoring embedding quality
type EmbeddingQualityMetrics struct {
	VectorNorm     float64
	VectorSparsity float64
}

// NewEmbeddingQualityMetrics creates new embedding quality metrics
func NewEmbeddingQualityMetrics(name string) *EmbeddingQualityMetrics {
	return &EmbeddingQualityMetrics{}
}

// RecordEmbeddingQuality records metrics for a single vector
func (m *EmbeddingQualityMetrics) RecordEmbeddingQuality(vector []float32) {
	// Calculate vector norm
	var norm float64
	var nonZero int
	for _, v := range vector {
		norm += float64(v * v)
		if v != 0 {
			nonZero++
		}
	}
	m.VectorNorm = norm

	// Calculate sparsity
	m.VectorSparsity = 1.0 - float64(nonZero)/float64(len(vector))
}
