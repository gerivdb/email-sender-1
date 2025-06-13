package integration

import (
	"context"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	"./interfaces"
)

// DefaultHealthChecker provides a concrete implementation of HealthChecker
type DefaultHealthChecker struct {
	name            string
	manager         interfaces.BaseManager
	logger          *logrus.Logger
	mutex           sync.RWMutex
	
	// Health tracking
	lastCheck       time.Time
	healthHistory   []HealthStatus
	maxHistorySize  int
	checkInterval   time.Duration
	
	// Status tracking
	consecutiveFailures int
	isHealthy          bool
	lastHealthy        time.Time
	lastUnhealthy      time.Time
	
	// Background monitoring
	stopCh          chan struct{}
	running         bool
	backgroundChecks bool
}

// NewDefaultHealthChecker creates a new health checker for a manager
func NewDefaultHealthChecker(name string, manager interfaces.BaseManager, logger *logrus.Logger) *DefaultHealthChecker {
	return &DefaultHealthChecker{
		name:            name,
		manager:         manager,
		logger:          logger,
		maxHistorySize:  100, // Keep last 100 health checks
		checkInterval:   30 * time.Second,
		healthHistory:   make([]HealthStatus, 0),
		isHealthy:       true, // Start optimistic
		stopCh:          make(chan struct{}),
		backgroundChecks: false,
	}
}

// CheckHealth performs an immediate health check
func (dhc *DefaultHealthChecker) CheckHealth(ctx context.Context) HealthStatus {
	startTime := time.Now()
	
	dhc.logger.WithFields(logrus.Fields{
		"manager": dhc.name,
		"check_time": startTime,
	}).Debug("Performing health check")
	
	status := HealthStatus{
		CheckTime:    startTime,
		ResponseTime: 0,
		Issues:       []HealthIssue{},
		Metrics:      make(map[string]float64),
		IsHealthy:    true,
	}
	
	// Perform the actual health check
	var err error
	if dhc.manager != nil {
		err = dhc.manager.HealthCheck(ctx)
	}
	
	status.ResponseTime = time.Since(startTime)
	
	if err != nil {
		status.IsHealthy = false
		status.Issues = append(status.Issues, HealthIssue{
			Severity:    "error",
			Component:   dhc.name,
			Description: err.Error(),
			Timestamp:   time.Now(),
		})
		
		dhc.logger.WithFields(logrus.Fields{
			"manager": dhc.name,
			"error": err.Error(),
			"response_time": status.ResponseTime,
		}).Warn("Health check failed")
		
		dhc.updateHealthStatus(false)
	} else {
		dhc.logger.WithFields(logrus.Fields{
			"manager": dhc.name,
			"response_time": status.ResponseTime,
		}).Debug("Health check passed")
		
		dhc.updateHealthStatus(true)
	}
	
	// Add performance metrics
	status.Metrics["response_time_ms"] = float64(status.ResponseTime.Milliseconds())
	status.Metrics["consecutive_failures"] = float64(dhc.consecutiveFailures)
	
	// Collect additional metrics if manager supports monitoring
	if monitoringMgr, ok := dhc.manager.(interfaces.MonitoringManager); ok {
		if metrics, err := monitoringMgr.CollectMetrics(ctx); err == nil {
			status.Metrics["cpu_usage"] = metrics.CPUUsage
			status.Metrics["memory_usage"] = metrics.MemoryUsage
			status.Metrics["error_count"] = float64(metrics.ErrorCount)
		}
	}
	
	// Update tracking
	dhc.mutex.Lock()
	dhc.lastCheck = startTime
	dhc.addToHistory(status)
	dhc.mutex.Unlock()
	
	return status
}

// GetLastHealthCheck returns the timestamp of the last health check
func (dhc *DefaultHealthChecker) GetLastHealthCheck() time.Time {
	dhc.mutex.RLock()
	defer dhc.mutex.RUnlock()
	return dhc.lastCheck
}

// GetHealthHistory returns the health check history
func (dhc *DefaultHealthChecker) GetHealthHistory() []HealthStatus {
	dhc.mutex.RLock()
	defer dhc.mutex.RUnlock()
	
	// Return a copy to prevent race conditions
	history := make([]HealthStatus, len(dhc.healthHistory))
	copy(history, dhc.healthHistory)
	return history
}

// IsCurrentlyHealthy returns the current health status
func (dhc *DefaultHealthChecker) IsCurrentlyHealthy() bool {
	dhc.mutex.RLock()
	defer dhc.mutex.RUnlock()
	return dhc.isHealthy
}

// GetHealthMetrics returns current health metrics
func (dhc *DefaultHealthChecker) GetHealthMetrics() map[string]interface{} {
	dhc.mutex.RLock()
	defer dhc.mutex.RUnlock()
	
	return map[string]interface{}{
		"is_healthy":           dhc.isHealthy,
		"last_check":          dhc.lastCheck,
		"consecutive_failures": dhc.consecutiveFailures,
		"last_healthy":        dhc.lastHealthy,
		"last_unhealthy":      dhc.lastUnhealthy,
		"check_count":         len(dhc.healthHistory),
	}
}

// StartBackgroundChecks starts periodic health checks
func (dhc *DefaultHealthChecker) StartBackgroundChecks() {
	dhc.mutex.Lock()
	if dhc.running {
		dhc.mutex.Unlock()
		return
	}
	dhc.running = true
	dhc.backgroundChecks = true
	dhc.mutex.Unlock()
	
	go dhc.backgroundCheckLoop()
	
	dhc.logger.WithFields(logrus.Fields{
		"manager": dhc.name,
		"interval": dhc.checkInterval,
	}).Info("Started background health checks")
}

// StopBackgroundChecks stops periodic health checks
func (dhc *DefaultHealthChecker) StopBackgroundChecks() {
	dhc.mutex.Lock()
	if !dhc.running {
		dhc.mutex.Unlock()
		return
	}
	dhc.running = false
	dhc.backgroundChecks = false
	dhc.mutex.Unlock()
	
	close(dhc.stopCh)
	
	dhc.logger.WithFields(logrus.Fields{
		"manager": dhc.name,
	}).Info("Stopped background health checks")
}

// SetCheckInterval updates the check interval
func (dhc *DefaultHealthChecker) SetCheckInterval(interval time.Duration) {
	dhc.mutex.Lock()
	defer dhc.mutex.Unlock()
	dhc.checkInterval = interval
}

// GetHealthSummary returns a summary of health status
func (dhc *DefaultHealthChecker) GetHealthSummary() map[string]interface{} {
	dhc.mutex.RLock()
	defer dhc.mutex.RUnlock()
	
	healthyCount := 0
	unhealthyCount := 0
	totalResponseTime := time.Duration(0)
	
	for _, status := range dhc.healthHistory {
		if status.IsHealthy {
			healthyCount++
		} else {
			unhealthyCount++
		}
		totalResponseTime += status.ResponseTime
	}
	
	var avgResponseTime time.Duration
	if len(dhc.healthHistory) > 0 {
		avgResponseTime = totalResponseTime / time.Duration(len(dhc.healthHistory))
	}
	
	return map[string]interface{}{
		"manager":              dhc.name,
		"current_status":       dhc.isHealthy,
		"total_checks":         len(dhc.healthHistory),
		"healthy_checks":       healthyCount,
		"unhealthy_checks":     unhealthyCount,
		"consecutive_failures": dhc.consecutiveFailures,
		"avg_response_time":    avgResponseTime,
		"last_check":          dhc.lastCheck,
		"uptime_percentage":   dhc.calculateUptime(),
	}
}

// Private methods

func (dhc *DefaultHealthChecker) updateHealthStatus(healthy bool) {
	dhc.mutex.Lock()
	defer dhc.mutex.Unlock()
	
	wasHealthy := dhc.isHealthy
	dhc.isHealthy = healthy
	
	now := time.Now()
	if healthy {
		dhc.consecutiveFailures = 0
		dhc.lastHealthy = now
		
		// Log recovery if we were previously unhealthy
		if !wasHealthy {
			dhc.logger.WithFields(logrus.Fields{
				"manager": dhc.name,
			}).Info("Manager recovered and is now healthy")
		}
	} else {
		dhc.consecutiveFailures++
		dhc.lastUnhealthy = now
		
		// Log degradation if we were previously healthy
		if wasHealthy {
			dhc.logger.WithFields(logrus.Fields{
				"manager": dhc.name,
			}).Warn("Manager became unhealthy")
		}
	}
}

func (dhc *DefaultHealthChecker) addToHistory(status HealthStatus) {
	dhc.healthHistory = append(dhc.healthHistory, status)
	
	// Keep only the most recent checks
	if len(dhc.healthHistory) > dhc.maxHistorySize {
		dhc.healthHistory = dhc.healthHistory[1:]
	}
}

func (dhc *DefaultHealthChecker) backgroundCheckLoop() {
	ticker := time.NewTicker(dhc.checkInterval)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			if dhc.backgroundChecks {
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				dhc.CheckHealth(ctx)
				cancel()
			}
		case <-dhc.stopCh:
			return
		}
	}
}

func (dhc *DefaultHealthChecker) calculateUptime() float64 {
	if len(dhc.healthHistory) == 0 {
		return 100.0
	}
	
	healthyCount := 0
	for _, status := range dhc.healthHistory {
		if status.IsHealthy {
			healthyCount++
		}
	}
	
	return (float64(healthyCount) / float64(len(dhc.healthHistory))) * 100.0
}

// ComprehensiveHealthChecker performs deeper health analysis
type ComprehensiveHealthChecker struct {
	*DefaultHealthChecker
	performanceThresholds map[string]float64
	criticalIssues       []HealthIssue
}

// NewComprehensiveHealthChecker creates an enhanced health checker
func NewComprehensiveHealthChecker(name string, manager interfaces.BaseManager, logger *logrus.Logger) *ComprehensiveHealthChecker {
	base := NewDefaultHealthChecker(name, manager, logger)
	
	return &ComprehensiveHealthChecker{
		DefaultHealthChecker: base,
		performanceThresholds: map[string]float64{
			"response_time_ms": 1000, // 1 second
			"cpu_usage":       80.0,  // 80%
			"memory_usage":    1000,  // 1GB
			"error_rate":      5.0,   // 5%
		},
		criticalIssues: make([]HealthIssue, 0),
	}
}

// CheckHealth performs comprehensive health analysis
func (chc *ComprehensiveHealthChecker) CheckHealth(ctx context.Context) HealthStatus {
	status := chc.DefaultHealthChecker.CheckHealth(ctx)
	
	// Perform additional analysis
	chc.analyzePerformance(&status)
	chc.checkCriticalIssues(&status)
	
	return status
}

func (chc *ComprehensiveHealthChecker) analyzePerformance(status *HealthStatus) {
	for metric, value := range status.Metrics {
		if threshold, exists := chc.performanceThresholds[metric]; exists {
			if value > threshold {
				issue := HealthIssue{
					Severity:    "warning",
					Component:   metric,
					Description: fmt.Sprintf("%s exceeded threshold: %.2f > %.2f", metric, value, threshold),
					Timestamp:   time.Now(),
				}
				status.Issues = append(status.Issues, issue)
				
				// If it's a critical metric, mark as unhealthy
				if metric == "response_time_ms" && value > threshold*2 {
					status.IsHealthy = false
				}
			}
		}
	}
}

func (chc *ComprehensiveHealthChecker) checkCriticalIssues(status *HealthStatus) {
	// Check for consecutive failures
	if chc.consecutiveFailures >= 3 {
		issue := HealthIssue{
			Severity:    "critical",
			Component:   "health_checker",
			Description: fmt.Sprintf("Manager has failed %d consecutive health checks", chc.consecutiveFailures),
			Timestamp:   time.Now(),
		}
		status.Issues = append(status.Issues, issue)
		status.IsHealthy = false
	}
	
	// Check response time trends
	if len(chc.healthHistory) >= 5 {
		recentChecks := chc.healthHistory[len(chc.healthHistory)-5:]
		avgResponseTime := time.Duration(0)
		for _, check := range recentChecks {
			avgResponseTime += check.ResponseTime
		}
		avgResponseTime /= 5
		
		if avgResponseTime > 5*time.Second {
			issue := HealthIssue{
				Severity:    "warning",
				Component:   "performance",
				Description: fmt.Sprintf("Average response time degraded: %v", avgResponseTime),
				Timestamp:   time.Now(),
			}
			status.Issues = append(status.Issues, issue)
		}
	}
}
