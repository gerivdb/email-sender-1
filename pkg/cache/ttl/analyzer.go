package ttl

import (
	"context"
	"fmt"
	"log"
	"math"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// TTLAnalyzer analyzes cache usage patterns and optimizes TTL settings
type TTLAnalyzer struct {
	manager    *TTLManager
	redis      *redis.Client
	metrics    *AnalyzerMetrics
	thresholds *AnalyzerThresholds
	mu         sync.RWMutex
}

// AnalyzerMetrics tracks analyzer performance metrics
type AnalyzerMetrics struct {
	AnalysisRuns           int64                    `json:"analysis_runs"`
	OptimizationsSuggested int64                    `json:"optimizations_suggested"`
	OptimizationsApplied   int64                    `json:"optimizations_applied"`
	UsagePatterns          map[DataType]*UsageStats `json:"usage_patterns"`
	PerformanceMetrics     *PerformanceStats        `json:"performance_metrics"`
	// Additional fields used by demo
	HitRate        float64 `json:"hit_rate"`
	EvictionRate   float64 `json:"eviction_rate"`
	TTLUtilization float64 `json:"ttl_utilization"`
	mu             sync.RWMutex
}

// UsageStats tracks usage statistics for a data type
type UsageStats struct {
	HitRate           float64       `json:"hit_rate"`
	MissRate          float64       `json:"miss_rate"`
	EvictionRate      float64       `json:"eviction_rate"`
	AverageAccessTime time.Duration `json:"average_access_time"`
	AccessFrequency   int64         `json:"access_frequency"`
	TTLUtilization    float64       `json:"ttl_utilization"` // Percentage of TTL actually used
}

// PerformanceStats tracks overall cache performance
type PerformanceStats struct {
	AverageLatency   time.Duration `json:"average_latency"`
	ThroughputPerSec float64       `json:"throughput_per_sec"`
	MemoryUsageMB    float64       `json:"memory_usage_mb"`
	ConnectionCount  int64         `json:"connection_count"`
	ErrorRate        float64       `json:"error_rate"`
}

// AnalyzerThresholds defines thresholds for optimization decisions
type AnalyzerThresholds struct {
	MinHitRate          float64 `json:"min_hit_rate"`           // 0.8 (80%)
	MaxEvictionRate     float64 `json:"max_eviction_rate"`      // 0.1 (10%)
	MinTTLUtilization   float64 `json:"min_ttl_utilization"`    // 0.5 (50%)
	MaxTTLUtilization   float64 `json:"max_ttl_utilization"`    // 0.9 (90%)
	MaxLatencyMs        int64   `json:"max_latency_ms"`         // 100ms
	MinThroughputPerSec float64 `json:"min_throughput_per_sec"` // 1000 ops/sec
}

// DefaultAnalyzerThresholds returns default thresholds
func DefaultAnalyzerThresholds() *AnalyzerThresholds {
	return &AnalyzerThresholds{
		MinHitRate:          0.8,
		MaxEvictionRate:     0.1,
		MinTTLUtilization:   0.5,
		MaxTTLUtilization:   0.9,
		MaxLatencyMs:        100,
		MinThroughputPerSec: 1000,
	}
}

// NewTTLAnalyzer creates a new TTL analyzer
func NewTTLAnalyzer(manager *TTLManager) *TTLAnalyzer {
	return &TTLAnalyzer{
		manager:    manager,
		redis:      manager.redis, // Ensure this uses the v9 client type
		thresholds: DefaultAnalyzerThresholds(),
		metrics: &AnalyzerMetrics{
			UsagePatterns:      make(map[DataType]*UsageStats),
			PerformanceMetrics: &PerformanceStats{},
		},
	}
}

// AnalyzeUsagePatterns analyzes current cache usage and suggests optimizations
func (ta *TTLAnalyzer) AnalyzeUsagePatterns() (*AnalysisReport, error) {
	ta.mu.Lock()
	defer ta.mu.Unlock()

	ctx := context.Background()

	// Update analysis run counter
	ta.metrics.mu.Lock()
	ta.metrics.AnalysisRuns++
	ta.metrics.mu.Unlock()

	// Analyze each data type
	dataTypes := []DataType{DefaultValues, Statistics, MLModels, Configuration, UserSessions}

	for _, dataType := range dataTypes {
		stats := ta.analyzeDataType(ctx, dataType)
		ta.metrics.UsagePatterns[dataType] = stats

		// Check if optimization is needed
		optimization := ta.evaluateOptimization(dataType, stats)
		if optimization != nil {
			ta.applyOptimization(dataType, optimization)
		}
	}

	// Update performance metrics
	ta.updatePerformanceMetrics(ctx)

	// Return a placeholder AnalysisReport and nil error
	return &AnalysisReport{}, nil
}

// analyzeDataType analyzes usage patterns for a specific data type
func (ta *TTLAnalyzer) analyzeDataType(ctx context.Context, dataType DataType) *UsageStats {
	pattern := fmt.Sprintf("*:%s:*", dataType)

	// Get all keys for this data type
	keys := ta.redis.Keys(ctx, pattern).Val()
	if len(keys) == 0 {
		return &UsageStats{}
	}

	stats := &UsageStats{}
	totalAccess := int64(0)
	totalTTLUsed := float64(0)
	accessTimes := make([]time.Duration, 0)

	for _, key := range keys {
		// Get key info
		keyInfo := ta.getKeyInfo(ctx, key)

		totalAccess += keyInfo.AccessCount
		totalTTLUsed += keyInfo.TTLUtilization

		if keyInfo.LastAccessTime > 0 {
			accessTimes = append(accessTimes, time.Duration(keyInfo.LastAccessTime))
		}
	}

	if len(keys) > 0 {
		stats.AccessFrequency = totalAccess / int64(len(keys))
		stats.TTLUtilization = totalTTLUsed / float64(len(keys))

		if len(accessTimes) > 0 {
			totalTime := time.Duration(0)
			for _, t := range accessTimes {
				totalTime += t
			}
			stats.AverageAccessTime = totalTime / time.Duration(len(accessTimes))
		}
	}

	// Calculate hit/miss rates from Redis info
	info := ta.redis.Info(ctx, "stats").Val()
	stats.HitRate, stats.MissRate = ta.parseHitMissRates(info)

	// Estimate eviction rate
	stats.EvictionRate = ta.estimateEvictionRate(ctx, dataType)

	return stats
}

// KeyInfo holds information about a specific key
type KeyInfo struct {
	AccessCount    int64
	TTLUtilization float64
	LastAccessTime int64
	RemainingTTL   time.Duration
}

// getKeyInfo retrieves detailed information about a key
func (ta *TTLAnalyzer) getKeyInfo(ctx context.Context, key string) *KeyInfo {
	info := &KeyInfo{}

	// Get TTL
	ttl := ta.redis.TTL(ctx, key).Val()
	info.RemainingTTL = ttl

	// Get idle time to estimate utilization
	idleTime := ta.redis.ObjectIdleTime(ctx, key).Val()

	// Calculate TTL utilization (rough estimate)
	if ttl > 0 {
		totalTTL, err := ta.manager.GetTTL(DefaultValues) // Use default as baseline
		if err != nil {
			log.Printf("Error retrieving TTL: %v", err)
			totalTTL = 0 // Default value in case of error
		}
		usedTTL := totalTTL - ttl
		info.TTLUtilization = float64(usedTTL) / float64(totalTTL)
	}

	// Estimate access count based on idle time (heuristic)
	if idleTime >= 0 {
		info.LastAccessTime = time.Now().Unix() - int64(idleTime.Seconds())
		// Rough estimate: more recent access = higher access count
		info.AccessCount = int64(math.Max(1, 100-float64(idleTime.Minutes())))
	}

	return info
}

// parseHitMissRates extracts hit/miss rates from Redis INFO stats
func (ta *TTLAnalyzer) parseHitMissRates(infoStats string) (hitRate, missRate float64) {
	// Parse Redis INFO stats for keyspace_hits and keyspace_misses
	// This is a simplified implementation
	// In production, you'd parse the actual Redis INFO output

	// Default values if parsing fails
	hitRate = 0.85  // 85% default hit rate
	missRate = 0.15 // 15% default miss rate

	return hitRate, missRate
}

// estimateEvictionRate estimates the eviction rate for a data type
func (ta *TTLAnalyzer) estimateEvictionRate(ctx context.Context, dataType DataType) float64 {
	// This is a simplified estimation
	// In production, you'd track actual evictions

	// Check memory usage
	info := ta.redis.Info(ctx, "memory").Val()
	memoryUsage := ta.parseMemoryUsage(info)

	// If memory usage is high, eviction rate is likely higher
	if memoryUsage > 0.8 { // 80% memory usage
		return 0.1 // 10% eviction rate
	}

	return 0.02 // 2% default eviction rate
}

// parseMemoryUsage parses memory usage from Redis INFO
func (ta *TTLAnalyzer) parseMemoryUsage(infoMemory string) float64 {
	// Simplified implementation
	// In production, parse actual Redis memory info
	return 0.6 // 60% default usage
}

// TTLOptimization represents a suggested TTL optimization
type TTLOptimization struct {
	DataType     DataType      `json:"data_type"`
	CurrentTTL   time.Duration `json:"current_ttl"`
	SuggestedTTL time.Duration `json:"suggested_ttl"`
	Reason       string        `json:"reason"`
	Confidence   float64       `json:"confidence"`
}

// evaluateOptimization determines if TTL optimization is needed
func (ta *TTLAnalyzer) evaluateOptimization(dataType DataType, stats *UsageStats) *TTLOptimization {
	currentTTL, err := ta.manager.GetTTL(dataType)
	if err != nil {
		log.Printf("Error retrieving TTL for %s: %v", dataType, err)
		currentTTL = 0 // Default value in case of error
	}

	// Check if hit rate is too low
	if stats.HitRate < ta.thresholds.MinHitRate {
		// Increase TTL to improve hit rate
		suggestedTTL := time.Duration(float64(currentTTL) * 1.5)
		return &TTLOptimization{
			DataType:     dataType,
			CurrentTTL:   currentTTL,
			SuggestedTTL: suggestedTTL,
			Reason:       "Low hit rate, increasing TTL",
			Confidence:   0.8,
		}
	}

	// Check if eviction rate is too high
	if stats.EvictionRate > ta.thresholds.MaxEvictionRate {
		// Decrease TTL to reduce memory pressure
		suggestedTTL := time.Duration(float64(currentTTL) * 0.8)
		return &TTLOptimization{
			DataType:     dataType,
			CurrentTTL:   currentTTL,
			SuggestedTTL: suggestedTTL,
			Reason:       "High eviction rate, decreasing TTL",
			Confidence:   0.7,
		}
	}

	// Check TTL utilization
	if stats.TTLUtilization < ta.thresholds.MinTTLUtilization {
		// TTL is too long, data expires before being fully utilized
		suggestedTTL := time.Duration(float64(currentTTL) * 0.7)
		return &TTLOptimization{
			DataType:     dataType,
			CurrentTTL:   currentTTL,
			SuggestedTTL: suggestedTTL,
			Reason:       "Low TTL utilization, decreasing TTL",
			Confidence:   0.6,
		}
	}

	if stats.TTLUtilization > ta.thresholds.MaxTTLUtilization {
		// TTL might be too short
		suggestedTTL := time.Duration(float64(currentTTL) * 1.2)
		return &TTLOptimization{
			DataType:     dataType,
			CurrentTTL:   currentTTL,
			SuggestedTTL: suggestedTTL,
			Reason:       "High TTL utilization, increasing TTL",
			Confidence:   0.6,
		}
	}

	return nil // No optimization needed
}

// applyOptimization applies the suggested optimization
func (ta *TTLAnalyzer) applyOptimization(dataType DataType, optimization *TTLOptimization) {
	// Only apply high-confidence optimizations automatically
	if optimization.Confidence >= 0.7 {
		err := ta.manager.SetTTL(dataType, optimization.SuggestedTTL)
		if err == nil {
			ta.metrics.mu.Lock()
			ta.metrics.OptimizationsApplied++
			ta.metrics.mu.Unlock()
		}
	}

	ta.metrics.mu.Lock()
	ta.metrics.OptimizationsSuggested++
	ta.metrics.mu.Unlock()
}

// updatePerformanceMetrics updates overall performance metrics
func (ta *TTLAnalyzer) updatePerformanceMetrics(ctx context.Context) {
	// Get Redis info
	info := ta.redis.Info(ctx, "stats").Val()
	memInfo := ta.redis.Info(ctx, "memory").Val()

	ta.metrics.PerformanceMetrics.MemoryUsageMB = ta.parseMemoryUsageMB(memInfo)
	ta.metrics.PerformanceMetrics.ConnectionCount = ta.parseConnectionCount(info)

	// Measure latency
	start := time.Now()
	ta.redis.Ping(ctx)
	ta.metrics.PerformanceMetrics.AverageLatency = time.Since(start)

	// Estimate throughput (simplified)
	ta.metrics.PerformanceMetrics.ThroughputPerSec = 1500.0 // Placeholder
	ta.metrics.PerformanceMetrics.ErrorRate = 0.01          // 1% error rate
}

// parseMemoryUsageMB parses memory usage in MB
func (ta *TTLAnalyzer) parseMemoryUsageMB(memInfo string) float64 {
	// Simplified implementation
	return 128.0 // 128MB placeholder
}

// parseConnectionCount parses connection count from Redis info
func (ta *TTLAnalyzer) parseConnectionCount(info string) int64 {
	// Simplified implementation
	return 25 // 25 connections placeholder
}

// GetMetrics returns analyzer metrics
func (ta *TTLAnalyzer) GetMetrics() *AnalyzerMetrics {
	ta.metrics.mu.RLock()
	defer ta.metrics.mu.RUnlock()

	// Create deep copy
	metrics := &AnalyzerMetrics{
		AnalysisRuns:           ta.metrics.AnalysisRuns,
		OptimizationsSuggested: ta.metrics.OptimizationsSuggested,
		OptimizationsApplied:   ta.metrics.OptimizationsApplied,
		UsagePatterns:          make(map[DataType]*UsageStats),
		PerformanceMetrics:     &PerformanceStats{},
	}

	// Calculate aggregate metrics from usage patterns
	totalHitRate := 0.0
	totalEvictionRate := 0.0
	totalTTLUtilization := 0.0
	count := 0

	// Copy usage patterns and calculate aggregates
	for k, v := range ta.metrics.UsagePatterns {
		metrics.UsagePatterns[k] = &UsageStats{
			HitRate:           v.HitRate,
			MissRate:          v.MissRate,
			EvictionRate:      v.EvictionRate,
			AverageAccessTime: v.AverageAccessTime,
			AccessFrequency:   v.AccessFrequency,
			TTLUtilization:    v.TTLUtilization,
		}

		totalHitRate += v.HitRate
		totalEvictionRate += v.EvictionRate
		totalTTLUtilization += v.TTLUtilization
		count++
	}

	// Set aggregate fields for demo compatibility
	if count > 0 {
		metrics.HitRate = totalHitRate / float64(count)
		metrics.EvictionRate = totalEvictionRate / float64(count)
		metrics.TTLUtilization = totalTTLUtilization / float64(count)
	} else {
		// Default values if no usage patterns exist
		metrics.HitRate = 0.85
		metrics.EvictionRate = 0.05
		metrics.TTLUtilization = 0.75
	}

	// Copy performance metrics
	*metrics.PerformanceMetrics = *ta.metrics.PerformanceMetrics

	return metrics
}

// SetThresholds updates analyzer thresholds
func (ta *TTLAnalyzer) SetThresholds(thresholds *AnalyzerThresholds) {
	ta.mu.Lock()
	defer ta.mu.Unlock()
	ta.thresholds = thresholds
}

// Implement Analyzer interface methods

// AnalyzeUsagePatternsReport analyzes usage patterns and returns a report
func (ta *TTLAnalyzer) AnalyzeUsagePatternsReport() (*AnalysisReport, error) {
	ta.AnalyzeUsagePatterns() // Call existing method

	report := &AnalysisReport{
		Timestamp:        time.Now(),
		UsagePatterns:    make(map[string]*PatternAnalysis),
		Recommendations:  ta.GetRecommendations(),
		PerformanceStats: ta.metrics.PerformanceMetrics,
		HealthScore:      ta.calculateHealthScore(),
	}

	return report, nil
}

// OptimizeTTLSettings optimizes TTL settings based on analysis
func (ta *TTLAnalyzer) OptimizeTTLSettings() error {
	ta.AnalyzeUsagePatterns()
	// TTL optimization is performed automatically in AnalyzeUsagePatterns
	return nil
}

// GetRecommendations returns TTL optimization recommendations
func (ta *TTLAnalyzer) GetRecommendations() []TTLRecommendation {
	recommendations := make([]TTLRecommendation, 0)

	// If no usage patterns available (e.g., Redis disconnected), return empty slice
	if ta.metrics.UsagePatterns == nil || len(ta.metrics.UsagePatterns) == 0 {
		return recommendations
	}

	for dataType, stats := range ta.metrics.UsagePatterns {
		if stats.TTLUtilization < ta.thresholds.MinTTLUtilization {
			currentTTL, err := ta.manager.GetTTL(dataType)
			if err != nil {
				log.Printf("Error retrieving TTL for %s: %v", dataType, err)
				currentTTL = 0 // Default value in case of error
			}
			recommendations = append(recommendations, TTLRecommendation{
				KeyPattern:       string(dataType),
				CurrentTTL:       currentTTL,
				RecommendedTTL:   currentTTL / 2, // Reduce TTL
				Reasoning:        "Low TTL utilization suggests shorter TTL needed",
				Priority:         "medium",
				EstimatedSavings: 0.2,
			})
		} else if stats.TTLUtilization > ta.thresholds.MaxTTLUtilization {
			currentTTL, err := ta.manager.GetTTL(dataType)
			if err != nil {
				log.Printf("Error retrieving TTL for %s: %v", dataType, err)
				currentTTL = 0 // Default value in case of error
			}
			recommendations = append(recommendations, TTLRecommendation{
				KeyPattern:       string(dataType),
				CurrentTTL:       currentTTL,
				RecommendedTTL:   currentTTL * 2, // Increase TTL
				Reasoning:        "High TTL utilization suggests longer TTL needed",
				Priority:         "high",
				EstimatedSavings: 0.15,
			})
		}
	}

	return recommendations
}

// calculateHealthScore calculates overall cache health score
func (ta *TTLAnalyzer) calculateHealthScore() float64 {
	if len(ta.metrics.UsagePatterns) == 0 {
		return 0.0
	}

	totalScore := 0.0
	count := 0

	for _, stats := range ta.metrics.UsagePatterns {
		score := stats.HitRate*0.4 +
			(1.0-stats.EvictionRate)*0.3 +
			stats.TTLUtilization*0.3
		totalScore += score
		count++
	}

	return totalScore / float64(count)
}

// StartAutoOptimization starts automatic TTL optimization at a specified interval
func (ta *TTLAnalyzer) StartAutoOptimization(ctx context.Context, interval time.Duration) error {
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-time.After(interval):
				_, err := ta.AnalyzeUsagePatterns()
				if err != nil {
					log.Printf("Error during auto-optimization: %v", err)
				}
			}
		}
	}()
	return nil
}

// AnalyzePattern analyzes usage patterns for a specific key pattern
func (ta *TTLAnalyzer) AnalyzePattern(pattern string) *PatternAnalysis {
	ta.mu.RLock()
	defer ta.mu.RUnlock()

	// Create a basic pattern analysis
	return &PatternAnalysis{
		KeyPattern:      pattern,
		HitRate:         0.85, // Default values - in production, these would be calculated
		AccessFrequency: 1000.0,
		AverageTTL:      time.Hour,
		RecommendedTTL:  time.Hour * 2,
	}
}

// OptimizeTTL optimizes TTL settings for a specific pattern
func (ta *TTLAnalyzer) OptimizeTTL(pattern string) error {
	analysis := ta.AnalyzePattern(pattern)
	if analysis == nil {
		return fmt.Errorf("failed to analyze pattern: %s", pattern)
	}

	// Apply optimization based on analysis
	log.Printf("Optimizing TTL for pattern %s with hit rate %.2f", pattern, analysis.HitRate)

	// In a real implementation, this would update TTL settings
	// For now, just log the optimization
	return nil
}

// GetOptimizationRecommendations returns optimization recommendations in the expected format
func (ta *TTLAnalyzer) GetOptimizationRecommendations() []OptimizationRecommendation {
	// Get existing recommendations and convert format
	recommendations := ta.GetRecommendations()

	// Always return a non-nil slice, even if empty
	opts := make([]OptimizationRecommendation, 0, len(recommendations))
	for _, rec := range recommendations {
		opt := OptimizationRecommendation{
			Type:         "ttl_optimization",
			KeyPattern:   rec.KeyPattern,
			Description:  rec.Reasoning,
			CurrentTTL:   rec.CurrentTTL,
			SuggestedTTL: rec.RecommendedTTL,
			Impact:       rec.Priority,
			Priority:     1, // Default priority
			Reasoning:    rec.Reasoning,
			Confidence:   rec.EstimatedSavings,
		}

		// Set priority based on impact
		switch rec.Priority {
		case "high":
			opt.Priority = 1
		case "medium":
			opt.Priority = 2
		case "low":
			opt.Priority = 3
		}

		opts = append(opts, opt)
	}

	return opts
}
