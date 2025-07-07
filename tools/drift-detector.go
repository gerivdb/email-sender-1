package tools

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"
)

// DriftDetector monitors for synchronization drift and performance issues
type DriftDetector struct {
	thresholds    map[string]float64
	alertManager  *AlertManager
	metrics       *PerformanceMetrics
	logger        *log.Logger
	ctx           context.Context
	cancel        context.CancelFunc
	mutex         sync.RWMutex
	running       bool
	checkInterval time.Duration
}

// DriftThresholds contains default threshold values
var DriftThresholds = map[string]float64{
	"sync_delay_minutes":   30.0,   // Alert if last sync > 30 minutes ago
	"error_rate_percent":   5.0,    // Alert if error rate > 5%
	"response_time_ms":     1000.0, // Alert if response time > 1s
	"memory_usage_percent": 80.0,   // Alert if memory usage > 80%
	"disk_space_percent":   90.0,   // Alert if disk usage > 90%
	"queue_size":           100.0,  // Alert if queue size > 100
	"consistency_score":    90.0,   // Alert if consistency score < 90%
}

// Alert represents a system alert
type Alert struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"`
	Severity   string                 `json:"severity"`
	Message    string                 `json:"message"`
	Details    map[string]interface{} `json:"details"`
	Timestamp  time.Time              `json:"timestamp"`
	Source     string                 `json:"source"`
	Resolved   bool                   `json:"resolved"`
	ResolvedAt *time.Time             `json:"resolved_at,omitempty"`
}

// NewDriftDetector creates a new drift detector
func NewDriftDetector(alertManager *AlertManager, metrics *PerformanceMetrics, logger *log.Logger) *DriftDetector {
	ctx, cancel := context.WithCancel(context.Background())

	return &DriftDetector{
		thresholds:    DriftThresholds,
		alertManager:  alertManager,
		metrics:       metrics,
		logger:        logger,
		ctx:           ctx,
		cancel:        cancel,
		checkInterval: 30 * time.Second,
	}
}

// Start begins drift monitoring
func (dd *DriftDetector) Start() error {
	dd.mutex.Lock()
	defer dd.mutex.Unlock()

	if dd.running {
		return fmt.Errorf("drift detector already running")
	}

	dd.running = true
	dd.logger.Printf("🔍 Starting drift detector with %d second interval", int(dd.checkInterval.Seconds()))

	go dd.monitorLoop()
	return nil
}

// Stop stops drift monitoring
func (dd *DriftDetector) Stop() error {
	dd.mutex.Lock()
	defer dd.mutex.Unlock()

	if !dd.running {
		return fmt.Errorf("drift detector not running")
	}

	dd.cancel()
	dd.running = false
	dd.logger.Println("🛑 Drift detector stopped")
	return nil
}

// monitorLoop is the main monitoring loop
func (dd *DriftDetector) monitorLoop() {
	ticker := time.NewTicker(dd.checkInterval)
	defer ticker.Stop()

	for {
		select {
		case <-dd.ctx.Done():
			dd.logger.Println("📊 Drift monitoring stopped")
			return
		case <-ticker.C:
			dd.performChecks()
		}
	}
}

// performChecks executes all drift detection checks
func (dd *DriftDetector) performChecks() {
	dd.logger.Println("🔍 Performing drift detection checks...")

	// Run checks in parallel for better performance
	var wg sync.WaitGroup

	checks := []func(){
		dd.checkSyncDrift,
		dd.checkPerformanceDrift,
		dd.checkConsistencyDrift,
		dd.checkResourceDrift,
		dd.checkQueueDrift,
	}

	for _, check := range checks {
		wg.Add(1)
		go func(checkFunc func()) {
			defer wg.Done()
			defer func() {
				if r := recover(); r != nil {
					dd.logger.Printf("❌ Check panic: %v", r)
				}
			}()
			checkFunc()
		}(check)
	}

	wg.Wait()
	dd.logger.Println("✅ Drift detection checks completed")
}

// checkSyncDrift checks for synchronization delays
func (dd *DriftDetector) checkSyncDrift() {
	lastSync := dd.metrics.GetLastSyncTime()
	threshold := dd.thresholds["sync_delay_minutes"]

	timeSinceSync := time.Since(lastSync)

	if timeSinceSync.Minutes() > threshold {
		alert := Alert{
			ID:       fmt.Sprintf("sync_drift_%d", time.Now().Unix()),
			Type:     "sync_drift",
			Severity: dd.determineSeverity(timeSinceSync.Minutes(), threshold),
			Message:  fmt.Sprintf("Synchronization delay detected: last sync was %.1f minutes ago", timeSinceSync.Minutes()),
			Details: map[string]interface{}{
				"last_sync_time":    lastSync.Format(time.RFC3339),
				"minutes_since":     timeSinceSync.Minutes(),
				"threshold_minutes": threshold,
				"active_syncs":      dd.metrics.GetActiveSyncCount(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Sync drift alert: %.1f minutes since last sync", timeSinceSync.Minutes())
	}
}

// checkPerformanceDrift checks for performance degradation
func (dd *DriftDetector) checkPerformanceDrift() {
	avgResponseTime := dd.metrics.GetAverageResponseTime()
	threshold := dd.thresholds["response_time_ms"]

	if avgResponseTime > threshold {
		errorRate := dd.metrics.GetErrorRate()
		throughput := dd.metrics.GetThroughput()

		alert := Alert{
			ID:       fmt.Sprintf("perf_drift_%d", time.Now().Unix()),
			Type:     "performance_drift",
			Severity: dd.determineSeverity(avgResponseTime, threshold),
			Message:  fmt.Sprintf("Performance degradation detected: average response time %.1fms", avgResponseTime),
			Details: map[string]interface{}{
				"avg_response_time_ms": avgResponseTime,
				"threshold_ms":         threshold,
				"error_rate_percent":   errorRate,
				"throughput":           throughput,
				"trend":                dd.metrics.GetPerformanceTrend(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Performance drift alert: %.1fms response time", avgResponseTime)
	}

	// Check error rate separately
	errorRate := dd.metrics.GetErrorRate()
	errorThreshold := dd.thresholds["error_rate_percent"]

	if errorRate > errorThreshold {
		alert := Alert{
			ID:       fmt.Sprintf("error_rate_%d", time.Now().Unix()),
			Type:     "error_rate_high",
			Severity: dd.determineSeverity(errorRate, errorThreshold),
			Message:  fmt.Sprintf("High error rate detected: %.1f%%", errorRate),
			Details: map[string]interface{}{
				"error_rate_percent": errorRate,
				"threshold_percent":  errorThreshold,
				"total_operations":   dd.metrics.GetTotalOperations(),
				"failed_operations":  dd.metrics.GetFailedOperations(),
				"recent_errors":      dd.metrics.GetRecentErrors(10),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Error rate alert: %.1f%% error rate", errorRate)
	}
}

// checkConsistencyDrift checks for data consistency issues
func (dd *DriftDetector) checkConsistencyDrift() {
	consistencyScore := dd.metrics.GetConsistencyScore()
	threshold := dd.thresholds["consistency_score"]

	if consistencyScore < threshold {
		inconsistencies := dd.metrics.GetInconsistencies()

		alert := Alert{
			ID:       fmt.Sprintf("consistency_drift_%d", time.Now().Unix()),
			Type:     "consistency_drift",
			Severity: dd.determineSeverity(threshold-consistencyScore, 10.0), // 10 point difference = critical
			Message:  fmt.Sprintf("Data consistency degradation: score %.1f%%", consistencyScore),
			Details: map[string]interface{}{
				"consistency_score": consistencyScore,
				"threshold_score":   threshold,
				"inconsistencies":   inconsistencies,
				"affected_plans":    dd.metrics.GetAffectedPlans(),
				"last_validation":   dd.metrics.GetLastValidationTime(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Consistency drift alert: %.1f%% score", consistencyScore)
	}
}

// checkResourceDrift checks for resource usage issues
func (dd *DriftDetector) checkResourceDrift() {
	memoryUsage := dd.metrics.GetMemoryUsagePercent()
	memThreshold := dd.thresholds["memory_usage_percent"]

	if memoryUsage > memThreshold {
		alert := Alert{
			ID:       fmt.Sprintf("memory_usage_%d", time.Now().Unix()),
			Type:     "resource_drift",
			Severity: dd.determineSeverity(memoryUsage, memThreshold),
			Message:  fmt.Sprintf("High memory usage: %.1f%%", memoryUsage),
			Details: map[string]interface{}{
				"memory_usage_percent": memoryUsage,
				"threshold_percent":    memThreshold,
				"available_memory_mb":  dd.metrics.GetAvailableMemoryMB(),
				"process_count":        dd.metrics.GetActiveProcessCount(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Memory usage alert: %.1f%%", memoryUsage)
	}

	diskUsage := dd.metrics.GetDiskUsagePercent()
	diskThreshold := dd.thresholds["disk_space_percent"]

	if diskUsage > diskThreshold {
		alert := Alert{
			ID:       fmt.Sprintf("disk_usage_%d", time.Now().Unix()),
			Type:     "resource_drift",
			Severity: dd.determineSeverity(diskUsage, diskThreshold),
			Message:  fmt.Sprintf("High disk usage: %.1f%%", diskUsage),
			Details: map[string]interface{}{
				"disk_usage_percent": diskUsage,
				"threshold_percent":  diskThreshold,
				"available_space_gb": dd.metrics.GetAvailableSpaceGB(),
				"log_files_size_mb":  dd.metrics.GetLogFilesSizeMB(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Disk usage alert: %.1f%%", diskUsage)
	}
}

// checkQueueDrift checks for queue backlog issues
func (dd *DriftDetector) checkQueueDrift() {
	queueSize := dd.metrics.GetQueueSize()
	threshold := dd.thresholds["queue_size"]

	if float64(queueSize) > threshold {
		alert := Alert{
			ID:       fmt.Sprintf("queue_drift_%d", time.Now().Unix()),
			Type:     "queue_drift",
			Severity: dd.determineSeverity(float64(queueSize), threshold),
			Message:  fmt.Sprintf("Queue backlog detected: %d items pending", queueSize),
			Details: map[string]interface{}{
				"queue_size":          queueSize,
				"threshold":           int(threshold),
				"processing_rate":     dd.metrics.GetProcessingRate(),
				"oldest_item_age_min": dd.metrics.GetOldestQueueItemAge().Minutes(),
				"queue_growth_trend":  dd.metrics.GetQueueGrowthTrend(),
			},
			Timestamp: time.Now(),
			Source:    "drift_detector",
		}

		dd.alertManager.SendAlert(alert)
		dd.logger.Printf("⚠️ Queue drift alert: %d items in queue", queueSize)
	}
}

// determineSeverity determines alert severity based on value vs threshold
func (dd *DriftDetector) determineSeverity(value, threshold float64) string {
	ratio := value / threshold

	switch {
	case ratio >= 2.0:
		return "critical"
	case ratio >= 1.5:
		return "high"
	case ratio >= 1.2:
		return "medium"
	default:
		return "low"
	}
}

// UpdateThreshold updates a specific threshold value
func (dd *DriftDetector) UpdateThreshold(key string, value float64) error {
	dd.mutex.Lock()
	defer dd.mutex.Unlock()

	if _, exists := dd.thresholds[key]; !exists {
		return fmt.Errorf("unknown threshold key: %s", key)
	}

	dd.thresholds[key] = value
	dd.logger.Printf("📊 Updated threshold %s to %.2f", key, value)
	return nil
}

// GetThresholds returns current threshold values
func (dd *DriftDetector) GetThresholds() map[string]float64 {
	dd.mutex.RLock()
	defer dd.mutex.RUnlock()

	result := make(map[string]float64)
	for k, v := range dd.thresholds {
		result[k] = v
	}
	return result
}

// SetCheckInterval updates the monitoring interval
func (dd *DriftDetector) SetCheckInterval(interval time.Duration) {
	dd.mutex.Lock()
	defer dd.mutex.Unlock()

	dd.checkInterval = interval
	dd.logger.Printf("📊 Updated check interval to %v", interval)
}

// GetStatus returns the current status of the drift detector
func (dd *DriftDetector) GetStatus() map[string]interface{} {
	dd.mutex.RLock()
	defer dd.mutex.RUnlock()

	return map[string]interface{}{
		"running":        dd.running,
		"check_interval": dd.checkInterval.String(),
		"thresholds":     dd.thresholds,
		"last_check":     time.Now().Format(time.RFC3339),
	}
}
