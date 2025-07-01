// Package main demonstrates the complete functionality of the TemplatePerformanceAnalyticsManager
// This example shows how to use all major features including neural pattern analysis,
// performance metrics collection, and adaptive optimization.
package examples

import (
	"context"
	"fmt"
	"log"
	"time"

	manager "EMAIL_SENDER_1/development/managers/template-performance-manager"
	"EMAIL_SENDER_1/development/managers/template-performance-manager/interfaces"
)

func main() {
	fmt.Println("=== TemplatePerformanceAnalyticsManager Demo ===")
	fmt.Println("Demonstrating advanced AI-powered template performance analytics and optimization")

	// Create and configure the manager
	config := manager.DefaultConfig()
	config.EnableRealTimeMode = true
	config.MaxConcurrentAnalyses = 10
	config.LogLevel = "INFO"

	mgr, err := manager.New(config)
	if err != nil {
		log.Fatalf("Failed to create manager: %v", err)
	}

	ctx := context.Background()

	// Initialize the manager
	fmt.Println("\n🔧 Initializing TemplatePerformanceAnalyticsManager...")
	if err := mgr.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize manager: %v", err)
	}

	// Start the manager
	fmt.Println("🚀 Starting manager...")
	if err := mgr.Start(ctx); err != nil {
		log.Fatalf("Failed to start manager: %v", err)
	}
	defer mgr.Stop(ctx)

	// Set up callbacks for real-time monitoring
	setupCallbacks(mgr)

	// Demonstrate the complete workflow
	demonstrateWorkflow(ctx, mgr)

	fmt.Println("\n✅ Demo completed successfully!")
}

func setupCallbacks(mgr *manager.Manager) {
	fmt.Println("📊 Setting up real-time monitoring callbacks...")

	mgr.SetCallbacks(
		// Analysis completion callback
		func(analysis *interfaces.PerformanceAnalysis) {
			fmt.Printf("✅ Analysis completed: %s (Duration: %v)\n",
				analysis.ID, analysis.Duration)
		},
		// Optimization application callback
		func(result *interfaces.OptimizationResult) {
			fmt.Printf("⚡ Optimization applied: %s (Gain: %.2f%%)\n",
				result.ID, result.PerformanceGain*100)
		},
		// Error callback
		func(err error) {
			fmt.Printf("❌ Error occurred: %v\n", err)
		},
	)
}

func demonstrateWorkflow(ctx context.Context, mgr *manager.Manager) {
	fmt.Println("\n🎯 Demonstrating complete workflow...")

	// Step 1: Analyze Simple Template
	fmt.Println("\n--- Step 1: Simple Template Analysis ---")
	simpleAnalysis := analyzeSimpleTemplate(ctx, mgr)

	// Step 2: Analyze Complex Template
	fmt.Println("\n--- Step 2: Complex Template Analysis ---")
	complexAnalysis := analyzeComplexTemplate(ctx, mgr)

	// Step 3: Apply Optimizations
	fmt.Println("\n--- Step 3: Applying Optimizations ---")
	applyOptimizations(ctx, mgr, complexAnalysis)

	// Step 4: Retrieve Performance Metrics
	fmt.Println("\n--- Step 4: Retrieving Performance Metrics ---")
	retrieveMetrics(ctx, mgr)

	// Step 5: Generate Analytics Report
	fmt.Println("\n--- Step 5: Generating Analytics Report ---")
	generateReport(ctx, mgr)

	// Step 6: Show Manager Status
	fmt.Println("\n--- Step 6: Manager Status ---")
	showManagerStatus(mgr)
}

func analyzeSimpleTemplate(ctx context.Context, mgr *manager.Manager) *interfaces.PerformanceAnalysis {
	fmt.Println("Analyzing simple email template...")

	request := interfaces.AnalysisRequest{
		ID: "simple_email_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID:  "simple_email_template",
			Content:     "Hello {{.CustomerName}}, thank you for your order!",
			Variables:   map[string]interface{}{"CustomerName": "John Doe"},
			Metadata:    map[string]interface{}{"category": "order_confirmation", "priority": "high"},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:   "session_simple_001",
			UserID:      "user_001",
			TemplateID:  "simple_email_template",
			StartTime:   time.Now().Add(-2 * time.Minute),
			EndTime:     time.Now(),
			Actions:     []string{"view", "generate"},
			Performance: map[string]float64{"generation_time": 0.8, "load_time": 0.2},
		},
		CurrentConfig: map[string]interface{}{
			"cache_enabled": true,
			"compression":   false,
		},
		TargetMetrics: map[string]float64{
			"generation_time": 0.5,
			"response_time":   0.3,
		},
	}

	analysis, err := mgr.AnalyzeTemplatePerformance(ctx, request)
	if err != nil {
		log.Printf("Simple template analysis failed: %v", err)
		return nil
	}

	fmt.Printf("✅ Simple template analysis completed:\n")
	fmt.Printf("   - Complexity: %.2f\n", analysis.PatternAnalysis.Complexity)
	fmt.Printf("   - Confidence: %.2f\n", analysis.PatternAnalysis.Confidence)
	fmt.Printf("   - Processing Time: %v\n", analysis.PatternAnalysis.ProcessingTime)
	fmt.Printf("   - Optimizations Found: %d\n", len(analysis.Optimizations))

	return analysis
}

func analyzeComplexTemplate(ctx context.Context, mgr *manager.Manager) *interfaces.PerformanceAnalysis {
	fmt.Println("Analyzing complex e-commerce template...")

	request := interfaces.AnalysisRequest{
		ID: "complex_ecommerce_analysis",
		TemplateData: interfaces.TemplateData{
			TemplateID: "complex_ecommerce_template",
			Content: `
Dear {{.CustomerName}},

Your order #{{.OrderID}} has been processed!

{{range .Items}}
{{if .IsAvailable}}
✅ {{.Name}} - Quantity: {{.Quantity}} - Price: ${{.Price | printf "%.2f"}}
   {{if .HasDiscount}}💰 Discount Applied: {{.Discount}}%{{end}}
{{else}}
❌ {{.Name}} - Currently Out of Stock
{{end}}
{{end}}

{{if gt (len .Items) 3}}
📦 Bulk order detected - Additional 5% discount applied!
{{end}}

Total: ${{.Total | printf "%.2f"}}
Estimated Delivery: {{.DeliveryDate | formatDate}}

{{if .IsPremiumCustomer}}
🌟 Thank you for being a Premium customer!
Free shipping has been applied to your order.
{{end}}

Best regards,
The E-commerce Team
			`,
			Variables: map[string]interface{}{
				"CustomerName": "Jane Smith",
				"OrderID":      "ORD-2024-001",
				"Items": []map[string]interface{}{
					{"Name": "Laptop", "Quantity": 1, "Price": 1299.99, "IsAvailable": true, "HasDiscount": true, "Discount": 10},
					{"Name": "Mouse", "Quantity": 2, "Price": 29.99, "IsAvailable": true, "HasDiscount": false},
					{"Name": "Keyboard", "Quantity": 1, "Price": 89.99, "IsAvailable": false},
					{"Name": "Monitor", "Quantity": 1, "Price": 399.99, "IsAvailable": true, "HasDiscount": true, "Discount": 15},
				},
				"Total":             1649.96,
				"DeliveryDate":      time.Now().Add(3 * 24 * time.Hour),
				"IsPremiumCustomer": true,
			},
			Metadata: map[string]interface{}{
				"category":   "order_confirmation",
				"priority":   "high",
				"complexity": "high",
				"features":   []string{"loops", "conditionals", "formatting", "calculations"},
			},
			GeneratedAt: time.Now(),
		},
		SessionData: interfaces.SessionData{
			SessionID:  "session_complex_001",
			UserID:     "user_002",
			TemplateID: "complex_ecommerce_template",
			StartTime:  time.Now().Add(-15 * time.Minute),
			EndTime:    time.Now(),
			Actions:    []string{"view", "edit", "preview", "generate", "send"},
			Performance: map[string]float64{
				"generation_time": 4.2,
				"load_time":       1.1,
				"render_time":     2.8,
				"memory_usage":    2048,
			},
		},
		CurrentConfig: map[string]interface{}{
			"cache_enabled":      false,
			"compression":        false,
			"parallelization":    false,
			"optimization_level": 0,
		},
		TargetMetrics: map[string]float64{
			"generation_time": 2.0,
			"response_time":   1.0,
			"memory_usage":    1024,
			"throughput":      100,
		},
	}

	analysis, err := mgr.AnalyzeTemplatePerformance(ctx, request)
	if err != nil {
		log.Printf("Complex template analysis failed: %v", err)
		return nil
	}

	fmt.Printf("✅ Complex template analysis completed:\n")
	fmt.Printf("   - Complexity: %.2f (High complexity detected)\n", analysis.PatternAnalysis.Complexity)
	fmt.Printf("   - Confidence: %.2f\n", analysis.PatternAnalysis.Confidence)
	fmt.Printf("   - Processing Time: %v\n", analysis.PatternAnalysis.ProcessingTime)
	fmt.Printf("   - Patterns Found: %d\n", len(analysis.PatternAnalysis.Patterns))
	fmt.Printf("   - Optimizations Recommended: %d\n", len(analysis.Optimizations))

	// Show optimization recommendations
	fmt.Println("   📈 Optimization Recommendations:")
	for i, opt := range analysis.Optimizations {
		if i < 3 { // Show first 3 recommendations
			fmt.Printf("      %d. %s (Impact: %.1f%%, Confidence: %.2f)\n",
				i+1, opt.Description, opt.ExpectedImpact*100, opt.Confidence)
		}
	}

	return analysis
}

func applyOptimizations(ctx context.Context, mgr *manager.Manager, analysis *interfaces.PerformanceAnalysis) {
	if analysis == nil || len(analysis.Optimizations) == 0 {
		fmt.Println("No optimizations available to apply")
		return
	}

	fmt.Printf("Applying top %d optimization recommendations...\n", min(3, len(analysis.Optimizations)))

	// Select top 3 optimizations
	selectedOptimizations := analysis.Optimizations
	if len(selectedOptimizations) > 3 {
		selectedOptimizations = selectedOptimizations[:3]
	}

	request := interfaces.OptimizationApplicationRequest{
		ID:              "optimization_application_001",
		TemplateID:      analysis.Request.TemplateData.TemplateID,
		Recommendations: selectedOptimizations,
		Configuration: map[string]interface{}{
			"apply_immediately": true,
			"rollback_enabled":  true,
			"enable_ab_testing": true,
			"test_percentage":   20, // 20% of traffic for A/B testing
			"test_duration":     "1h",
		},
	}

	result, err := mgr.ApplyOptimizations(ctx, request)
	if err != nil {
		log.Printf("Failed to apply optimizations: %v", err)
		return
	}

	fmt.Printf("✅ Optimizations applied successfully:\n")
	fmt.Printf("   - Application ID: %s\n", result.ID)
	fmt.Printf("   - Template ID: %s\n", result.TemplateID)
	fmt.Printf("   - Performance Gain: %.2f%%\n", result.PerformanceGain*100)
	fmt.Printf("   - Applied Optimizations: %d\n", len(result.AppliedOptimizations))
	fmt.Printf("   - A/B Test Enabled: %t\n", result.ABTestConfig != nil && result.ABTestConfig.Enabled)

	if result.BeforeMetrics != nil && result.AfterMetrics != nil {
		fmt.Printf("   📊 Performance Improvement:\n")
		fmt.Printf("      - Generation Time: %.2fs → %.2fs (%.1f%% improvement)\n",
			result.BeforeMetrics.Generation.Time,
			result.AfterMetrics.Generation.Time,
			(result.BeforeMetrics.Generation.Time-result.AfterMetrics.Generation.Time)/result.BeforeMetrics.Generation.Time*100)
	}
}

func retrieveMetrics(ctx context.Context, mgr *manager.Manager) {
	fmt.Println("Retrieving performance metrics...")

	filter := interfaces.MetricsFilter{
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-1 * time.Hour),
			End:   time.Now(),
		},
		IncludeTemplateID: true,
		IncludeUserID:     true,
	}

	metrics, err := mgr.GetPerformanceMetrics(ctx, filter)
	if err != nil {
		log.Printf("Failed to retrieve metrics: %v", err)
		return
	}

	fmt.Printf("✅ Performance metrics retrieved:\n")
	fmt.Printf("   - Metrics ID: %s\n", metrics.ID)
	fmt.Printf("   - Template ID: %s\n", metrics.TemplateID)
	fmt.Printf("   - Collection Time: %v\n", metrics.CollectionTime)
	fmt.Printf("   - Generation Metrics:\n")
	fmt.Printf("      * Time: %.2fs\n", metrics.Generation.Time)
	fmt.Printf("      * Memory Usage: %.0f KB\n", metrics.Generation.MemoryUsage)
	fmt.Printf("   - Performance Data:\n")
	fmt.Printf("      * Response Time: %.2fs\n", metrics.Performance.ResponseTime)
	fmt.Printf("      * Throughput: %.0f req/s\n", metrics.Performance.Throughput)
}

func generateReport(ctx context.Context, mgr *manager.Manager) {
	fmt.Println("Generating comprehensive analytics report...")

	request := interfaces.ReportRequest{
		ID: "demo_analytics_report",
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-2 * time.Hour),
			End:   time.Now(),
		},
		Format: "json",
		Options: map[string]interface{}{
			"include_raw_data":        true,
			"include_predictions":     true,
			"include_recommendations": true,
			"detail_level":            "comprehensive",
		},
	}

	report, err := mgr.GenerateAnalyticsReport(ctx, request)
	if err != nil {
		log.Printf("Failed to generate report: %v", err)
		return
	}

	fmt.Printf("✅ Analytics report generated:\n")
	fmt.Printf("   - Report ID: %s\n", report.ID)
	fmt.Printf("   - Generated At: %s\n", report.GeneratedAt.Format("2006-01-02 15:04:05"))
	fmt.Printf("   - Time Range: %s to %s\n",
		report.TimeRange.Start.Format("15:04:05"),
		report.TimeRange.End.Format("15:04:05"))
	fmt.Printf("   - Summary:\n")
	fmt.Printf("      * Total Analyses: %d\n", report.Summary.TotalAnalyses)
	fmt.Printf("      * Average Performance: %.2f\n", report.Summary.AveragePerformance)
	fmt.Printf("      * Optimization Gains: %.2f%%\n", report.Summary.OptimizationGains*100)
	fmt.Printf("      * Top Patterns: %v\n", report.Summary.TopPatterns)
}

func showManagerStatus(mgr *manager.Manager) {
	status := mgr.GetManagerStatus()

	fmt.Printf("📊 Manager Status:\n")
	fmt.Printf("   - Initialized: %t\n", status.IsInitialized)
	fmt.Printf("   - Running: %t\n", status.IsRunning)
	fmt.Printf("   - Start Time: %s\n", status.StartTime.Format("2006-01-02 15:04:05"))
	fmt.Printf("   - Last Update: %s\n", status.LastUpdate.Format("2006-01-02 15:04:05"))
	fmt.Printf("   - Total Requests: %d\n", status.RequestCount)
	fmt.Printf("   - Error Count: %d\n", status.ErrorCount)
	fmt.Printf("   - Active Analyses: %d\n", status.ActiveAnalyses)
	fmt.Printf("   - Version: %s\n", status.Version)

	if status.ErrorCount > 0 {
		errorRate := float64(status.ErrorCount) / float64(status.RequestCount) * 100
		fmt.Printf("   - Error Rate: %.2f%%\n", errorRate)
	}

	uptime := time.Since(status.StartTime)
	fmt.Printf("   - Uptime: %v\n", uptime.Round(time.Second))
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
