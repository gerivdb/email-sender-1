package tools

import (
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	_ "github.com/lib/pq"
)

// PerformanceMetrics collects and analyzes system performance data
type PerformanceMetrics struct {
	syncDuration []time.Duration
	throughput   []int
	errorRates   []float64
	memoryUsage  []uint64
	responseTime []time.Duration
	database     *sql.DB
	logger       *log.Logger
	mutex        sync.RWMutex
	config       *MetricsConfig

	// Additional tracking fields
	lastSyncTime     time.Time
	activeSyncCount  int
	totalOperations  int
	failedOperations int
	recentErrors     []string
}

// MetricsConfig configuration for performance metrics
type MetricsConfig struct {
	DatabaseURL     string             `json:"database_url"`
	RetentionDays   int                `json:"retention_days"`
	SampleInterval  time.Duration      `json:"sample_interval"`
	MaxSamples      int                `json:"max_samples"`
	AlertThresholds map[string]float64 `json:"alert_thresholds"`
}

// PerformanceReport contains analyzed performance data
type PerformanceReport struct {
	AvgSyncDuration     time.Duration      `json:"avg_sync_duration"`
	AvgThroughput       float64            `json:"avg_throughput"`
	AvgErrorRate        float64            `json:"avg_error_rate"`
	AvgResponseTime     time.Duration      `json:"avg_response_time"`
	PeakMemoryUsage     uint64             `json:"peak_memory_usage"`
	TrendAnalysis       *TrendAnalysis     `json:"trend_analysis"`
	Percentiles         map[string]float64 `json:"percentiles"`
	ReportTimestamp     time.Time          `json:"report_timestamp"`
	SampleCount         int                `json:"sample_count"`
	RecommendationsText []string           `json:"recommendations"`
}

// TrendAnalysis contains trend analysis data
type TrendAnalysis struct {
	SyncDurationTrend string  `json:"sync_duration_trend"`
	ThroughputTrend   string  `json:"throughput_trend"`
	ErrorRateTrend    string  `json:"error_rate_trend"`
	TrendSlope        float64 `json:"trend_slope"`
	ConfidenceLevel   float64 `json:"confidence_level"`
	PredictedValue    float64 `json:"predicted_value"`
}

// BusinessMetrics contains business-specific metrics
type BusinessMetrics struct {
	PlansSynchronized     int     `json:"plans_synchronized"`
	TasksProcessed        int     `json:"tasks_processed"`
	ConflictsResolved     int     `json:"conflicts_resolved"`
	ValidationErrors      int     `json:"validation_errors"`
	UserInteractions      int     `json:"user_interactions"`
	SystemUptime          float64 `json:"system_uptime"`
	DataConsistencyScore  float64 `json:"data_consistency_score"`
	UserSatisfactionScore float64 `json:"user_satisfaction_score"`
}

// NewPerformanceMetrics creates a new performance metrics collector
func NewPerformanceMetrics(config *MetricsConfig, logger *log.Logger) (*PerformanceMetrics, error) {
	pm := &PerformanceMetrics{
		syncDuration:     make([]time.Duration, 0, config.MaxSamples),
		throughput:       make([]int, 0, config.MaxSamples),
		errorRates:       make([]float64, 0, config.MaxSamples),
		memoryUsage:      make([]uint64, 0, config.MaxSamples),
		responseTime:     make([]time.Duration, 0, config.MaxSamples),
		logger:           logger,
		config:           config,
		lastSyncTime:     time.Now(),
		activeSyncCount:  0,
		totalOperations:  0,
		failedOperations: 0,
		recentErrors:     make([]string, 0, 100),
	}

	// Initialize database connection
	if config.DatabaseURL != "" {
		db, err := sql.Open("postgres", config.DatabaseURL)
		if err != nil {
			return nil, fmt.Errorf("failed to connect to database: %w", err)
		}
		pm.database = db

		// Create tables if they don't exist
		if err := pm.initializeTables(); err != nil {
			return nil, fmt.Errorf("failed to initialize tables: %w", err)
		}
	}

	return pm, nil
}

// RecordSyncOperation records a synchronization operation
func (pm *PerformanceMetrics) RecordSyncOperation(duration time.Duration, processed int, errors int) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()

	pm.syncDuration = append(pm.syncDuration, duration)
	pm.throughput = append(pm.throughput, processed)

	errorRate := float64(0)
	if processed > 0 {
		errorRate = float64(errors) / float64(processed) * 100
	}
	pm.errorRates = append(pm.errorRates, errorRate)

	// Trim to max samples if needed
	pm.trimSamples()

	// Store in database for historical analysis
	if pm.database != nil {
		go pm.storeMetrics(duration, processed, errorRate)
	}

	pm.logger.Printf("Recorded sync operation: duration=%v, processed=%d, errors=%d, error_rate=%.2f%%",
		duration, processed, errors, errorRate)
}

// RecordResponseTime records API response time
func (pm *PerformanceMetrics) RecordResponseTime(duration time.Duration) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()

	pm.responseTime = append(pm.responseTime, duration)
	pm.trimSamples()

	if pm.database != nil {
		go pm.storeResponseTime(duration)
	}
}

// RecordMemoryUsage records memory usage
func (pm *PerformanceMetrics) RecordMemoryUsage(usage uint64) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()

	pm.memoryUsage = append(pm.memoryUsage, usage)
	pm.trimSamples()

	if pm.database != nil {
		go pm.storeMemoryUsage(usage)
	}
}

// GetPerformanceReport generates a comprehensive performance report
func (pm *PerformanceMetrics) GetPerformanceReport() *PerformanceReport {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	report := &PerformanceReport{
		ReportTimestamp: time.Now(),
		SampleCount:     len(pm.syncDuration),
		Percentiles:     make(map[string]float64),
	}

	if len(pm.syncDuration) > 0 {
		report.AvgSyncDuration = pm.calculateDurationAverage(pm.syncDuration)
		report.Percentiles["sync_duration_p95"] = pm.calculateDurationPercentile(pm.syncDuration, 95)
		report.Percentiles["sync_duration_p99"] = pm.calculateDurationPercentile(pm.syncDuration, 99)
	}

	if len(pm.throughput) > 0 {
		report.AvgThroughput = pm.calculateIntAverage(pm.throughput)
		report.Percentiles["throughput_p95"] = float64(pm.calculateIntPercentile(pm.throughput, 95))
	}

	if len(pm.errorRates) > 0 {
		report.AvgErrorRate = pm.calculateFloatAverage(pm.errorRates)
		report.Percentiles["error_rate_p95"] = pm.calculateFloatPercentile(pm.errorRates, 95)
	}

	if len(pm.responseTime) > 0 {
		report.AvgResponseTime = pm.calculateDurationAverage(pm.responseTime)
		report.Percentiles["response_time_p95"] = pm.calculateDurationPercentile(pm.responseTime, 95)
	}

	if len(pm.memoryUsage) > 0 {
		report.PeakMemoryUsage = pm.calculateMaxUint64(pm.memoryUsage)
		report.Percentiles["memory_usage_p95"] = float64(pm.calculateUint64Percentile(pm.memoryUsage, 95))
	}

	// Generate trend analysis
	report.TrendAnalysis = pm.analyzeTrends()

	// Generate recommendations
	report.RecommendationsText = pm.generateRecommendations(report)

	return report
}

// CollectBusinessMetrics collects business-specific metrics
func (pm *PerformanceMetrics) CollectBusinessMetrics() (*BusinessMetrics, error) {
	if pm.database == nil {
		return nil, fmt.Errorf("database connection required for business metrics")
	}

	metrics := &BusinessMetrics{}

	// Query plans synchronized in last 24 hours
	err := pm.database.QueryRow(`
		SELECT COUNT(*) FROM sync_logs 
		WHERE event_type = 'sync_completed' 
		AND timestamp > NOW() - INTERVAL '24 hours'
	`).Scan(&metrics.PlansSynchronized)
	if err != nil {
		pm.logger.Printf("Error querying plans synchronized: %v", err)
	}

	// Query tasks processed
	err = pm.database.QueryRow(`
		SELECT COALESCE(SUM(processed_count), 0) FROM performance_metrics 
		WHERE timestamp > NOW() - INTERVAL '24 hours'
	`).Scan(&metrics.TasksProcessed)
	if err != nil {
		pm.logger.Printf("Error querying tasks processed: %v", err)
	}

	// Query conflicts resolved
	err = pm.database.QueryRow(`
		SELECT COUNT(*) FROM sync_logs 
		WHERE event_type = 'conflict_resolved' 
		AND timestamp > NOW() - INTERVAL '24 hours'
	`).Scan(&metrics.ConflictsResolved)
	if err != nil {
		pm.logger.Printf("Error querying conflicts resolved: %v", err)
	}

	// Calculate system uptime (mock calculation)
	metrics.SystemUptime = 99.5 // Mock value, would be calculated from actual system metrics

	// Calculate data consistency score (mock calculation)
	metrics.DataConsistencyScore = 98.7 // Mock value, would be calculated from validation results

	// Calculate user satisfaction score (mock calculation)
	metrics.UserSatisfactionScore = 4.6 // Mock value, would be calculated from user feedback

	return metrics, nil
}

// GetRealtimeDashboardData returns data for real-time dashboard
func (pm *PerformanceMetrics) GetRealtimeDashboardData() map[string]interface{} {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	data := make(map[string]interface{})

	// Current metrics
	if len(pm.syncDuration) > 0 {
		data["last_sync_duration"] = pm.syncDuration[len(pm.syncDuration)-1].Milliseconds()
		data["avg_sync_duration"] = pm.calculateDurationAverage(pm.syncDuration).Milliseconds()
	}

	if len(pm.throughput) > 0 {
		data["last_throughput"] = pm.throughput[len(pm.throughput)-1]
		data["avg_throughput"] = pm.calculateIntAverage(pm.throughput)
	}

	if len(pm.errorRates) > 0 {
		data["last_error_rate"] = pm.errorRates[len(pm.errorRates)-1]
		data["avg_error_rate"] = pm.calculateFloatAverage(pm.errorRates)
	}

	if len(pm.memoryUsage) > 0 {
		data["current_memory_mb"] = pm.memoryUsage[len(pm.memoryUsage)-1] / 1024 / 1024
		data["peak_memory_mb"] = pm.calculateMaxUint64(pm.memoryUsage) / 1024 / 1024
	}

	// System status
	data["total_samples"] = len(pm.syncDuration)
	data["last_updated"] = time.Now().Format(time.RFC3339)

	// Health indicators
	data["health_status"] = pm.calculateHealthStatus()

	return data
}

// analyzeTrends performs trend analysis on the collected metrics
func (pm *PerformanceMetrics) analyzeTrends() *TrendAnalysis {
	if len(pm.syncDuration) < 3 {
		return &TrendAnalysis{
			SyncDurationTrend: "insufficient_data",
			ThroughputTrend:   "insufficient_data",
			ErrorRateTrend:    "insufficient_data",
			ConfidenceLevel:   0.0,
		}
	}

	// Simple trend analysis using linear regression
	syncTrend := pm.calculateTrend(pm.durationToFloat64(pm.syncDuration))
	throughputTrend := pm.calculateTrend(pm.intToFloat64(pm.throughput))
	errorTrend := pm.calculateTrend(pm.errorRates)

	return &TrendAnalysis{
		SyncDurationTrend: pm.trendToString(syncTrend),
		ThroughputTrend:   pm.trendToString(throughputTrend),
		ErrorRateTrend:    pm.trendToString(errorTrend),
		TrendSlope:        syncTrend,
		ConfidenceLevel:   85.0, // Mock confidence level
		PredictedValue:    pm.predictNextValue(pm.durationToFloat64(pm.syncDuration)),
	}
}

// generateRecommendations generates performance improvement recommendations
func (pm *PerformanceMetrics) generateRecommendations(report *PerformanceReport) []string {
	var recommendations []string

	// Check sync duration
	if report.AvgSyncDuration > 5*time.Second {
		recommendations = append(recommendations,
			"Consider optimizing sync operations - average duration exceeds 5 seconds")
	}

	// Check error rate
	if report.AvgErrorRate > 2.0 {
		recommendations = append(recommendations,
			"High error rate detected - investigate sync reliability issues")
	}

	// Check memory usage
	if report.PeakMemoryUsage > 1024*1024*1024 { // 1GB
		recommendations = append(recommendations,
			"High memory usage detected - consider memory optimization")
	}

	// Check throughput trends
	if report.TrendAnalysis.ThroughputTrend == "decreasing" {
		recommendations = append(recommendations,
			"Throughput is trending downward - investigate performance bottlenecks")
	}

	// Check response time
	if report.AvgResponseTime > 500*time.Millisecond {
		recommendations = append(recommendations,
			"API response time is high - consider caching or optimization")
	}

	if len(recommendations) == 0 {
		recommendations = append(recommendations, "System performance is optimal")
	}

	return recommendations
}

// GetLastSyncTime returns the timestamp of the last synchronization
func (pm *PerformanceMetrics) GetLastSyncTime() time.Time {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()
	return pm.lastSyncTime
}

// GetActiveSyncCount returns the number of currently active sync operations
func (pm *PerformanceMetrics) GetActiveSyncCount() int {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()
	return pm.activeSyncCount
}

// GetAverageResponseTime returns the average response time in milliseconds
func (pm *PerformanceMetrics) GetAverageResponseTime() float64 {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	if len(pm.responseTime) == 0 {
		return 0.0
	}

	avg := pm.calculateDurationAverage(pm.responseTime)
	return float64(avg.Nanoseconds()) / 1000000.0 // Convert to milliseconds
}

// GetErrorRate returns the current error rate as a percentage
func (pm *PerformanceMetrics) GetErrorRate() float64 {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	if len(pm.errorRates) == 0 {
		return 0.0
	}

	return pm.calculateFloatAverage(pm.errorRates)
}

// GetThroughput returns the current throughput (operations per second)
func (pm *PerformanceMetrics) GetThroughput() float64 {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	if len(pm.throughput) == 0 {
		return 0.0
	}

	return pm.calculateIntAverage(pm.throughput)
}

// GetPerformanceTrend returns the performance trend analysis
func (pm *PerformanceMetrics) GetPerformanceTrend() string {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()

	if len(pm.responseTime) < 2 {
		return "insufficient_data"
	}

	values := pm.durationToFloat64(pm.responseTime)
	slope := pm.calculateTrend(values)
	return pm.trendToString(slope)
}

// GetTotalOperations returns the total number of operations processed
func (pm *PerformanceMetrics) GetTotalOperations() int {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()
	return pm.totalOperations
}

// GetFailedOperations returns the total number of failed operations
func (pm *PerformanceMetrics) GetFailedOperations() int {
	pm.mutex.RLock()
	defer pm.mutex.RUnlock()
	return pm.failedOperations
}

// SetLastSyncTime updates the last synchronization timestamp
func (pm *PerformanceMetrics) SetLastSyncTime(t time.Time) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	pm.lastSyncTime = t
}

// IncrementActiveSyncCount increments the active sync counter
func (pm *PerformanceMetrics) IncrementActiveSyncCount() {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	pm.activeSyncCount++
}

// DecrementActiveSyncCount decrements the active sync counter
func (pm *PerformanceMetrics) DecrementActiveSyncCount() {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	if pm.activeSyncCount > 0 {
		pm.activeSyncCount--
	}
}

// AddRecentError adds an error message to the recent errors list
func (pm *PerformanceMetrics) AddRecentError(err string) {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()

	pm.recentErrors = append(pm.recentErrors, err)
	pm.failedOperations++

	// Keep only last 100 errors
	if len(pm.recentErrors) > 100 {
		pm.recentErrors = pm.recentErrors[1:]
	}
}

// IncrementTotalOperations increments the total operations counter
func (pm *PerformanceMetrics) IncrementTotalOperations() {
	pm.mutex.Lock()
	defer pm.mutex.Unlock()
	pm.totalOperations++
}
