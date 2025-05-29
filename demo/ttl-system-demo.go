// Demo script for TTL Management System
// This script demonstrates the TTL system implementation
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"email_sender/pkg/cache/ttl"

	"github.com/redis/go-redis/v9"
)

func main() {
	fmt.Println("=== TTL Management System Demo ===")

	// Initialize Redis client
	rdb := redis.NewClient(&redis.Options{
		Addr:     "localhost:6379",
		Password: "",
		DB:       0,
	})

	ctx := context.Background()

	// Test Redis connection
	_, err := rdb.Ping(ctx).Result()
	if err != nil {
		log.Printf("Warning: Redis not available - running in demo mode: %v", err)
		runDemoMode()
		return
	}

	fmt.Println("✅ Redis connection successful")
	// Initialize TTL Manager
	manager := ttl.NewTTLManager(rdb, ttl.DefaultTTLConfig())

	fmt.Println("✅ TTL Manager initialized")

	// Demo 1: Set cache entries with different TTLs
	fmt.Println("\n📝 Demo 1: Setting cache entries with type-specific TTLs")

	entries := []struct {
		key      string
		value    string
		dataType ttl.DataType
	}{
		{"user:123:profile", `{"name":"John","email":"john@example.com"}`, ttl.DefaultValues},
		{"stats:daily:2024", `{"visits":1000,"conversions":50}`, ttl.Statistics},
		{"model:sentiment:v1", `{"accuracy":0.95,"last_trained":"2024-01-01"}`, ttl.MLModels},
		{"config:email:smtp", `{"host":"smtp.example.com","port":587}`, ttl.Configuration},
		{"session:user123", `{"id":"sess_123","created":"2024-01-01T10:00:00Z"}`, ttl.UserSessions},
	}

	for _, entry := range entries {
		err := manager.SetWithTTL(ctx, entry.key, entry.value, entry.dataType)
		if err != nil {
			log.Printf("Error setting %s: %v", entry.key, err)
			continue
		}

		ttl_val, _ := rdb.TTL(ctx, entry.key).Result()
		fmt.Printf("  ✅ %s: TTL = %v (type: %s)\n", entry.key, ttl_val, entry.dataType)
	}

	// Demo 2: Check invalidation strategies
	fmt.Println("\n🔄 Demo 2: Testing invalidation strategies")

	// Initialize invalidation manager
	invalidationMgr := ttl.NewInvalidationManager()

	// Add time-based invalidation
	timeStrategy := ttl.NewTimeBasedInvalidation(30 * time.Minute)
	timeStrategy.AddPattern("session:*")
	invalidationMgr.AddStrategy("time_based", timeStrategy)

	// Add event-based invalidation
	eventStrategy := ttl.NewEventBasedInvalidation()
	eventStrategy.AddTrigger("user_logout", []string{"session:*"})
	invalidationMgr.AddStrategy("event_based", eventStrategy)

	fmt.Println("  ✅ Time-based invalidation strategy added")
	fmt.Println("  ✅ Event-based invalidation strategy added")

	// Demo 3: Monitoring and analytics
	fmt.Println("\n📊 Demo 3: Cache monitoring and analytics")

	// Get current metrics
	metrics := manager.GetMetrics()
	fmt.Printf("  📈 Total Operations: %d\n", metrics.TotalOperations)
	fmt.Printf("  📈 Cache Hits: %d\n", metrics.CacheHits)
	fmt.Printf("  📈 TTL Expirations: %d\n", metrics.TTLExpirations)

	// Demo TTL analyzer
	analyzer := ttl.NewTTLAnalyzer(manager, 5*time.Minute)
	performance := analyzer.GetPerformanceStats()

	fmt.Printf("  📊 Hit Rate: %.2f%%\n", performance.HitRate*100)
	fmt.Printf("  📊 Avg Response Time: %v\n", performance.AverageResponseTime)
	fmt.Printf("  📊 Memory Usage: %.2f MB\n", float64(performance.MemoryUsage)/(1024*1024))

	// Demo 4: Cache analysis tool
	fmt.Println("\n🔍 Demo 4: Cache analysis and recommendations")

	report := generateAnalysisReport(manager, analyzer)
	fmt.Printf("  📋 Performance Score: %d/100\n", report.PerformanceScore)
	fmt.Printf("  💡 Recommendations: %d found\n", len(report.Recommendations))

	for i, rec := range report.Recommendations {
		if i < 3 { // Show first 3 recommendations
			fmt.Printf("    %d. %s (Priority: %d)\n", i+1, rec.Description, rec.Priority)
		}
	}

	fmt.Println("\n✅ TTL System demo completed successfully!")
	fmt.Println("📝 Check /tools/cache-analyzer for detailed analysis tool")
}

// Analysis report structure
type AnalysisReport struct {
	PerformanceScore  int                `json:"performance_score"`
	Recommendations   []Recommendation   `json:"recommendations"`
	TTLEfficiency     map[string]float64 `json:"ttl_efficiency"`
	MemoryUtilization float64            `json:"memory_utilization"`
}

type Recommendation struct {
	Type        string `json:"type"`
	Description string `json:"description"`
	Priority    int    `json:"priority"`
	Impact      string `json:"impact"`
}

func generateAnalysisReport(manager *ttl.TTLManager, analyzer *ttl.TTLAnalyzer) AnalysisReport {
	// Simulate analysis results
	recommendations := []Recommendation{
		{
			Type:        "TTL_OPTIMIZATION",
			Description: "Increase Statistics TTL to 48h for better hit rate",
			Priority:    8,
			Impact:      "Medium",
		},
		{
			Type:        "MEMORY_OPTIMIZATION",
			Description: "Enable LRU eviction for DefaultValues cache",
			Priority:    6,
			Impact:      "Low",
		},
		{
			Type:        "PERFORMANCE",
			Description: "Consider Redis cluster for high-traffic patterns",
			Priority:    9,
			Impact:      "High",
		},
	}

	return AnalysisReport{
		PerformanceScore: 85,
		Recommendations:  recommendations,
		TTLEfficiency: map[string]float64{
			"default_values": 0.82,
			"statistics":     0.91,
			"ml_models":      0.76,
			"configuration":  0.88,
			"user_sessions":  0.79,
		},
		MemoryUtilization: 0.67,
	}
}

func runDemoMode() {
	fmt.Println("\n🔧 Running in Demo Mode (Redis not available)")
	fmt.Println("\n📋 TTL Configuration:")
	config := ttl.DefaultTTLConfig()
	fmt.Printf("  - DefaultValues: %v\n", config.DefaultValues)
	fmt.Printf("  - Statistics: %v\n", config.Statistics)
	fmt.Printf("  - MLModels: %v\n", config.MLModels)
	fmt.Printf("  - Configuration: %v\n", config.Configuration)
	fmt.Printf("  - UserSessions: %v\n", config.UserSessions)

	fmt.Println("\n✅ Demo completed (offline mode)")
	fmt.Println("💡 To run full demo, ensure Redis is running on localhost:6379")
}
