// Cache analyzer tool for TTL optimization
package cache_analyzer

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"email_sender/pkg/cache/ttl"

	"github.com/redis/go-redis/v9"
)

// AnalysisReport contains the results of cache analysis
type AnalysisReport struct {
	Timestamp		time.Time		`json:"timestamp"`
	OverallMetrics		*ttl.MetricData		`json:"overall_metrics"`
	TTLAnalysis		*ttl.AnalyzerMetrics	`json:"ttl_analysis"`
	Recommendations		[]Recommendation	`json:"recommendations"`
	PerformanceScore	float64			`json:"performance_score"`
	Summary			string			`json:"summary"`
}

// Recommendation represents an optimization recommendation
type Recommendation struct {
	Type		string	`json:"type"`
	DataType	string	`json:"data_type,omitempty"`
	Description	string	`json:"description"`
	Impact		string	`json:"impact"`		// high, medium, low
	Effort		string	`json:"effort"`		// high, medium, low
	Priority	int	`json:"priority"`	// 1-10
	Implementation	string	`json:"implementation"`
}

// CacheAnalyzer performs comprehensive cache analysis
type CacheAnalyzer struct {
	redis		*redis.Client
	ttlManager	*ttl.TTLManager
	metrics		*ttl.CacheMetrics
	analyzer	*ttl.TTLAnalyzer
}

func main() {
	var (
		redisAddr	= flag.String("redis", "localhost:6379", "Redis address")
		redisPassword	= flag.String("password", "", "Redis password")
		redisDB		= flag.Int("db", 0, "Redis database")
		outputFile	= flag.String("output", "cache_analysis_report.json", "Output file for analysis report")
		duration	= flag.Duration("duration", 5*time.Minute, "Analysis duration")
		verbose		= flag.Bool("verbose", false, "Verbose output")
	)
	flag.Parse()

	fmt.Println("🔍 Cache Analyzer Tool - TTL Optimization")
	fmt.Println("==========================================")

	// Initialize Redis client
	rdb := redis.NewClient(&redis.Options{
		Addr:		*redisAddr,
		Password:	*redisPassword,
		DB:		*redisDB,
	})
	defer rdb.Close()

	// Test connection
	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	fmt.Printf("✅ Connected to Redis at %s\n", *redisAddr)

	// Initialize components
	analyzer := NewCacheAnalyzer(rdb)
	defer analyzer.Close()

	// Run analysis
	fmt.Printf("🔬 Starting cache analysis (duration: %v)\n", *duration)
	report := analyzer.RunAnalysis(ctx, *duration, *verbose)

	// Save report
	if err := saveReport(report, *outputFile); err != nil {
		log.Fatalf("Failed to save report: %v", err)
	}
	fmt.Printf("📄 Analysis report saved to: %s\n", *outputFile)

	// Display summary
	displaySummary(report)
}

// NewCacheAnalyzer creates a new cache analyzer
func NewCacheAnalyzer(rdb *redis.Client) *CacheAnalyzer {
	ttlConfig := ttl.DefaultTTLConfig()
	ttlManager := ttl.NewTTLManager(rdb, ttlConfig)
	metrics := ttl.NewCacheMetrics(rdb)

	return &CacheAnalyzer{
		redis:		rdb,
		ttlManager:	ttlManager,
		metrics:	metrics,
		analyzer:	ttl.NewTTLAnalyzer(ttlManager),
	}
}

// RunAnalysis performs comprehensive cache analysis
func (ca *CacheAnalyzer) RunAnalysis(ctx context.Context, duration time.Duration, verbose bool) *AnalysisReport {
	report := &AnalysisReport{
		Timestamp:		time.Now(),
		Recommendations:	make([]Recommendation, 0),
	}

	if verbose {
		fmt.Println("📊 Collecting baseline metrics...")
	}

	// Collect baseline metrics
	baselineMetrics := ca.metrics.GetMetrics()

	// Run analysis for specified duration
	analysisCtx, cancel := context.WithTimeout(ctx, duration)
	defer cancel()

	// Perform periodic analysis
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	analysisCount := 0
	for {
		select {
		case <-analysisCtx.Done():
			goto analysisComplete
		case <-ticker.C:
			analysisCount++
			if verbose {
				fmt.Printf("📈 Analysis cycle %d...\n", analysisCount)
			}
			ca.analyzer.AnalyzeUsagePatterns()
		}
	}

analysisComplete:
	if verbose {
		fmt.Println("✅ Analysis complete, generating report...")
	}

	// Collect final metrics
	report.OverallMetrics = ca.metrics.GetMetrics()
	report.TTLAnalysis = ca.analyzer.GetMetrics()

	// Generate recommendations
	report.Recommendations = ca.generateRecommendations(baselineMetrics, report.OverallMetrics)

	// Calculate performance score
	report.PerformanceScore = ca.calculatePerformanceScore(report.OverallMetrics)

	// Generate summary
	report.Summary = ca.generateSummary(report)

	return report
}

// generateRecommendations creates optimization recommendations
func (ca *CacheAnalyzer) generateRecommendations(baseline, current *ttl.MetricData) []Recommendation {
	recommendations := make([]Recommendation, 0)

	// Check overall hit rate
	if current.HitRate < 0.8 {
		rec := Recommendation{
			Type:		"performance",
			Description:	fmt.Sprintf("Cache hit rate is %.1f%%, below optimal threshold of 80%%", current.HitRate*100),
			Impact:		"high",
			Effort:		"medium",
			Priority:	9,
			Implementation:	"Consider increasing TTL for frequently accessed data types or improving cache warming strategies",
		}
		recommendations = append(recommendations, rec)
	}

	// Check memory usage
	if current.MemoryUsage > 400 {	// 400MB threshold
		rec := Recommendation{
			Type:		"memory",
			Description:	fmt.Sprintf("Memory usage is high: %.1f MB", current.MemoryUsage),
			Impact:		"medium",
			Effort:		"low",
			Priority:	7,
			Implementation:	"Reduce TTL for less critical data types or implement more aggressive eviction policies",
		}
		recommendations = append(recommendations, rec)
	}

	// Check latency
	if current.AvgLatency > 50*time.Millisecond {
		rec := Recommendation{
			Type:		"latency",
			Description:	fmt.Sprintf("Average latency is high: %v", current.AvgLatency),
			Impact:		"high",
			Effort:		"high",
			Priority:	8,
			Implementation:	"Investigate network issues, optimize Redis configuration, or consider connection pooling",
		}
		recommendations = append(recommendations, rec)
	}

	// Check type-specific recommendations
	for dataType, typeMetric := range current.TypeMetrics {
		if typeMetric.HitRate < 0.7 {
			rec := Recommendation{
				Type:		"ttl_optimization",
				DataType:	string(dataType),
				Description:	fmt.Sprintf("%s has low hit rate: %.1f%%", dataType, typeMetric.HitRate*100),
				Impact:		"medium",
				Effort:		"low",
				Priority:	6,
				Implementation:	fmt.Sprintf("Increase TTL for %s from current average of %v", dataType, typeMetric.AvgTTL),
			}
			recommendations = append(recommendations, rec)
		}

		if typeMetric.AccessPattern == "rare" && typeMetric.AvgTTL > 1*time.Hour {
			rec := Recommendation{
				Type:		"ttl_optimization",
				DataType:	string(dataType),
				Description:	fmt.Sprintf("%s has rare access pattern but long TTL", dataType),
				Impact:		"low",
				Effort:		"low",
				Priority:	4,
				Implementation:	fmt.Sprintf("Reduce TTL for %s to save memory", dataType),
			}
			recommendations = append(recommendations, rec)
		}
	}

	// Check throughput
	if current.ThroughputPerSec < 1000 {
		rec := Recommendation{
			Type:		"throughput",
			Description:	fmt.Sprintf("Throughput is low: %.0f ops/sec", current.ThroughputPerSec),
			Impact:		"medium",
			Effort:		"medium",
			Priority:	5,
			Implementation:	"Consider pipelining, connection pooling, or Redis cluster setup",
		}
		recommendations = append(recommendations, rec)
	}

	return recommendations
}

// calculatePerformanceScore calculates overall performance score (0-100)
func (ca *CacheAnalyzer) calculatePerformanceScore(metrics *ttl.MetricData) float64 {
	score := 0.0

	// Hit rate score (30% weight)
	hitRateScore := metrics.HitRate * 100
	score += hitRateScore * 0.3

	// Latency score (25% weight)
	latencyScore := 100.0
	if metrics.AvgLatency > 10*time.Millisecond {
		latencyScore = max(0, 100-float64(metrics.AvgLatency.Milliseconds()-10)*2)
	}
	score += latencyScore * 0.25

	// Throughput score (20% weight)
	throughputScore := min(100, metrics.ThroughputPerSec/50)	// 5000 ops/sec = 100%
	score += throughputScore * 0.2

	// Memory efficiency score (15% weight)
	memoryScore := 100.0
	if metrics.MemoryUsage > 200 {	// 200MB baseline
		memoryScore = max(0, 100-(metrics.MemoryUsage-200)/10)
	}
	score += memoryScore * 0.15

	// Error rate score (10% weight)
	errorRate := float64(metrics.ErrorCount) / float64(max64(metrics.TotalRequests, 1))
	errorScore := max(0, 100-errorRate*1000)	// 1% error rate = 90 points
	score += errorScore * 0.1

	return min(100, max(0, score))
}

// generateSummary creates a summary of the analysis
func (ca *CacheAnalyzer) generateSummary(report *AnalysisReport) string {
	summary := fmt.Sprintf("Cache Analysis Summary (Score: %.1f/100)\n", report.PerformanceScore)
	summary += "==================================================\n\n"

	metrics := report.OverallMetrics
	summary += fmt.Sprintf("📊 Key Metrics:\n")
	summary += fmt.Sprintf("  • Hit Rate: %.1f%%\n", metrics.HitRate*100)
	summary += fmt.Sprintf("  • Cache Size: %d keys\n", metrics.CacheSize)
	summary += fmt.Sprintf("  • Memory Usage: %.1f MB\n", metrics.MemoryUsage)
	summary += fmt.Sprintf("  • Avg Latency: %v\n", metrics.AvgLatency)
	summary += fmt.Sprintf("  • Throughput: %.0f ops/sec\n", metrics.ThroughputPerSec)
	summary += "\n"

	// Performance assessment
	if report.PerformanceScore >= 90 {
		summary += "🏆 Excellent: Cache performance is optimal\n"
	} else if report.PerformanceScore >= 80 {
		summary += "✅ Good: Cache performance is satisfactory with minor optimization opportunities\n"
	} else if report.PerformanceScore >= 70 {
		summary += "⚠️  Fair: Cache performance needs improvement\n"
	} else {
		summary += "❌ Poor: Cache performance requires immediate attention\n"
	}

	// Top recommendations
	summary += "\n🔧 Top Recommendations:\n"
	highPriorityRecs := 0
	for _, rec := range report.Recommendations {
		if rec.Priority >= 7 && highPriorityRecs < 3 {
			summary += fmt.Sprintf("  %d. %s (Priority: %d)\n", highPriorityRecs+1, rec.Description, rec.Priority)
			highPriorityRecs++
		}
	}

	if highPriorityRecs == 0 {
		summary += "  No high-priority recommendations\n"
	}

	return summary
}

// saveReport saves the analysis report to a file
func saveReport(report *AnalysisReport, filename string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}

	return os.WriteFile(filename, data, 0644)
}

// displaySummary displays the analysis summary
func displaySummary(report *AnalysisReport) {
	fmt.Println("\n" + report.Summary)

	fmt.Printf("\n📈 Detailed Analysis:\n")
	fmt.Printf("  • Analysis Runs: %d\n", report.TTLAnalysis.AnalysisRuns)
	fmt.Printf("  • Optimizations Suggested: %d\n", report.TTLAnalysis.OptimizationsSuggested)
	fmt.Printf("  • Optimizations Applied: %d\n", report.TTLAnalysis.OptimizationsApplied)

	fmt.Printf("\n📋 Data Type Breakdown:\n")
	for dataType, typeMetric := range report.OverallMetrics.TypeMetrics {
		fmt.Printf("  • %s: %d keys, %.1f%% hit rate, %s access pattern\n",
			dataType, typeMetric.KeyCount, typeMetric.HitRate*100, typeMetric.AccessPattern)
	}

	if len(report.Recommendations) > 0 {
		fmt.Printf("\n💡 All Recommendations (%d total):\n", len(report.Recommendations))
		for i, rec := range report.Recommendations {
			fmt.Printf("  %d. [%s] %s (Priority: %d, Impact: %s)\n",
				i+1, rec.Type, rec.Description, rec.Priority, rec.Impact)
		}
	}
}

// Close cleans up resources
func (ca *CacheAnalyzer) Close() {
	if ca.metrics != nil {
		ca.metrics.Close()
	}
	if ca.ttlManager != nil {
		ca.ttlManager.Close()
	}
}

// Helper functions
func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

func max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}

func max64(a, b int64) int64 {
	if a > b {
		return a
	}
	return b
}
