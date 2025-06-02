package main

import (
	"fmt"
	"log"
	"time"

	"email_sender/cmd/roadmap-cli/priority"
	"email_sender/cmd/roadmap-cli/types"
)

// TestResult represents the result of a priority algorithm test
type TestResult struct {
	AlgorithmName string
	TaskTitle     string
	Score         float64
	Factors       map[string]float64
	Success       bool
	Error         error
}

func main() {
	fmt.Println("🧪 Priority Engine Algorithm Validation Tests")
	fmt.Println("=" + string(make([]byte, 50)))
	fmt.Println()

	// Create test data
	testItems := createTestData()
	
	// Test all algorithms
	algorithms := []priority.PriorityCalculator{
		priority.NewEisenhowerCalculator(),
		priority.NewMoSCoWCalculator(),
		priority.NewWSJFCalculator(),
		priority.NewCustomWeightedCalculator(),
		priority.NewHybridCalculator(),
	}

	var allResults []TestResult

	for _, algorithm := range algorithms {
		fmt.Printf("Testing %s:\n", algorithm.GetName())
		fmt.Printf("Description: %s\n", algorithm.GetDescription())
		fmt.Println("-" + string(make([]byte, 40)))

		for _, item := range testItems {
			result := testAlgorithm(algorithm, item)
			allResults = append(allResults, result)
			
			if result.Success {
				fmt.Printf("✅ %s: Score %.2f\n", result.TaskTitle, result.Score)
				displayFactors(result.Factors)
			} else {
				fmt.Printf("❌ %s: Error - %v\n", result.TaskTitle, result.Error)
			}
		}
		fmt.Println()
	}

	// Display summary
	displaySummary(allResults)
	
	// Test priority engine integration
	testPriorityEngine(testItems)
	
	// Test weighting configuration
	testWeightingConfig()
	
	// Performance benchmarks
	runPerformanceBenchmarks(testItems)
}

// createTestData creates sample roadmap items for testing
func createTestData() []types.RoadmapItem {
	now := time.Now()
	
	return []types.RoadmapItem{
		{
			ID:            "urgent-bug",
			Title:         "Critical Security Bug Fix",
			Description:   "Fix critical security vulnerability in authentication",
			Status:        types.StatusInProgress,
			Priority:      types.PriorityCritical,
			TargetDate:    now.Add(24 * time.Hour), // Due tomorrow
			Progress:      30,
			Complexity:    types.BasicComplexityHigh,
			Effort:        16, // hours
			BusinessValue: 10,
			RiskLevel:     types.RiskHigh,
			Prerequisites: []string{"security-audit"},
		},
		{
			ID:            "feature-enhancement",
			Title:         "Add User Dashboard",
			Description:   "Create comprehensive user dashboard with analytics",
			Status:        types.StatusPlanned,
			Priority:      types.PriorityMedium,
			TargetDate:    now.Add(30 * 24 * time.Hour), // Due in 30 days
			Progress:      0,
			Complexity:    types.BasicComplexityMedium,
			Effort:        40, // hours
			BusinessValue: 7,
			RiskLevel:     types.RiskMedium,
			Prerequisites: []string{"user-research", "design-mockups"},
		},
		{
			ID:            "tech-debt",
			Title:         "Refactor Legacy Code",
			Description:   "Clean up old codebase and improve maintainability",
			Status:        types.StatusPlanned,
			Priority:      types.PriorityLow,
			TargetDate:    now.Add(90 * 24 * time.Hour), // Due in 90 days
			Progress:      0,
			Complexity:    types.BasicComplexityHigh,
			Effort:        80, // hours
			BusinessValue: 3,
			RiskLevel:     types.RiskLow,
			TechnicalDebt: 8,
		},
		{
			ID:            "quick-win",
			Title:         "Update Help Documentation",
			Description:   "Update user help documentation with new features",
			Status:        types.StatusPlanned,
			Priority:      types.PriorityLow,
			TargetDate:    now.Add(7 * 24 * time.Hour), // Due in 7 days
			Progress:      0,
			Complexity:    types.BasicComplexityLow,
			Effort:        4, // hours
			BusinessValue: 5,
			RiskLevel:     types.RiskLow,
		},
		{
			ID:            "blocked-feature",
			Title:         "Integration with External API",
			Description:   "Integrate with third-party payment processor",
			Status:        types.StatusBlocked,
			Priority:      types.PriorityHigh,
			TargetDate:    now.Add(14 * 24 * time.Hour), // Due in 14 days
			Progress:      10,
			Complexity:    types.BasicComplexityHigh,
			Effort:        32, // hours
			BusinessValue: 9,
			RiskLevel:     types.RiskHigh,
			Prerequisites: []string{"api-credentials", "compliance-review"},
		},
	}
}

// testAlgorithm tests a single algorithm with a single item
func testAlgorithm(algorithm priority.PriorityCalculator, item types.RoadmapItem) TestResult {
	config := priority.DefaultWeightingConfig()
	
	result := TestResult{
		AlgorithmName: algorithm.GetName(),
		TaskTitle:     item.Title,
	}
	
	priority, err := algorithm.Calculate(item, config)
	if err != nil {
		result.Success = false
		result.Error = err
		return result
	}
	
	result.Success = true
	result.Score = priority.Score
	result.Factors = make(map[string]float64)
	
	// Convert PriorityFactor keys to strings for display
	for factor, value := range priority.Factors {
		result.Factors[string(factor)] = value
	}
	
	return result
}

// displayFactors shows the factor breakdown
func displayFactors(factors map[string]float64) {
	fmt.Print("  Factors: ")
	var parts []string
	for factor, value := range factors {
		parts = append(parts, fmt.Sprintf("%s:%.2f", factor, value))
	}
	fmt.Println(fmt.Sprintf("[%s]", joinStrings(parts, ", ")))
}

// displaySummary shows test results summary
func displaySummary(results []TestResult) {
	fmt.Println("📊 Test Summary")
	fmt.Println("=" + string(make([]byte, 30)))
	
	algorithmStats := make(map[string]struct {
		Total   int
		Success int
		Failed  int
		AvgScore float64
	})
	
	for _, result := range results {
		stats := algorithmStats[result.AlgorithmName]
		stats.Total++
		if result.Success {
			stats.Success++
			stats.AvgScore += result.Score
		} else {
			stats.Failed++
		}
		algorithmStats[result.AlgorithmName] = stats
	}
	
	for algorithm, stats := range algorithmStats {
		if stats.Success > 0 {
			stats.AvgScore /= float64(stats.Success)
		}
		
		fmt.Printf("Algorithm: %s\n", algorithm)
		fmt.Printf("  ✅ Success: %d/%d\n", stats.Success, stats.Total)
		if stats.Failed > 0 {
			fmt.Printf("  ❌ Failed: %d\n", stats.Failed)
		}
		if stats.Success > 0 {
			fmt.Printf("  📈 Avg Score: %.2f\n", stats.AvgScore)
		}
		fmt.Println()
	}
}

// testPriorityEngine tests the main priority engine
func testPriorityEngine(items []types.RoadmapItem) {
	fmt.Println("🔧 Priority Engine Integration Test")
	fmt.Println("-" + string(make([]byte, 35)))
	
	engine := priority.NewEngine()
	
	// Test basic functionality
	fmt.Println("Testing basic calculate function...")
	for _, item := range items {
		if priority, err := engine.Calculate(item); err == nil {
			fmt.Printf("✅ %s: %.2f\n", item.Title, priority.Score)
		} else {
			fmt.Printf("❌ %s: %v\n", item.Title, err)
		}
	}
	
	// Test ranking
	fmt.Println("\nTesting ranking function...")
	ranked, err := engine.Rank(items)
	if err != nil {
		log.Printf("❌ Ranking failed: %v", err)
	} else {
		fmt.Println("✅ Ranking successful:")
		for i, item := range ranked {
			if priority, err := engine.Calculate(item); err == nil {
				fmt.Printf("  %d. %s (%.2f)\n", i+1, item.Title, priority.Score)
			}
		}
	}
	
	// Test algorithm switching
	fmt.Println("\nTesting algorithm switching...")
	algorithms := []priority.PriorityCalculator{
		priority.NewMoSCoWCalculator(),
		priority.NewWSJFCalculator(),
		priority.NewHybridCalculator(),
	}
	
	testItem := items[0] // Use first item
	for _, algorithm := range algorithms {
		engine.SetCalculator(algorithm)
		if priority, err := engine.Calculate(testItem); err == nil {
			fmt.Printf("✅ %s: %.2f\n", algorithm.GetName(), priority.Score)
		} else {
			fmt.Printf("❌ %s: %v\n", algorithm.GetName(), err)
		}
	}
	
	fmt.Println()
}

// testWeightingConfig tests custom weighting configurations
func testWeightingConfig() {
	fmt.Println("⚖️  Weighting Configuration Test")
	fmt.Println("-" + string(make([]byte, 32)))
	
	engine := priority.NewEngine()
	testItem := types.RoadmapItem{
		ID:            "test-config",
		Title:         "Configuration Test Item",
		Priority:      types.PriorityMedium,
		TargetDate:    time.Now().Add(7 * 24 * time.Hour),
		Effort:        20,
		BusinessValue: 6,
		RiskLevel:     types.RiskMedium,
	}
	
	// Test different weighting configurations
	configs := []struct {
		Name   string
		Config priority.WeightingConfig
	}{
		{
			Name: "Urgency-focused",
			Config: priority.WeightingConfig{
				Urgency:       0.5,
				Impact:        0.2,
				Effort:        0.1,
				Dependencies:  0.1,
				BusinessValue: 0.05,
				Risk:          0.05,
			},
		},
		{
			Name: "Business-value-focused",
			Config: priority.WeightingConfig{
				Urgency:       0.1,
				Impact:        0.3,
				Effort:        0.1,
				Dependencies:  0.1,
				BusinessValue: 0.35,
				Risk:          0.05,
			},
		},
		{
			Name: "Effort-optimized",
			Config: priority.WeightingConfig{
				Urgency:       0.2,
				Impact:        0.2,
				Effort:        0.4,
				Dependencies:  0.1,
				BusinessValue: 0.05,
				Risk:          0.05,
			},
		},
	}
	
	for _, config := range configs {
		engine.SetWeightingConfig(config.Config)
		if priority, err := engine.Calculate(testItem); err == nil {
			fmt.Printf("✅ %s: %.2f\n", config.Name, priority.Score)
		} else {
			fmt.Printf("❌ %s: %v\n", config.Name, err)
		}
	}
	
	fmt.Println()
}

// runPerformanceBenchmarks runs performance tests
func runPerformanceBenchmarks(items []types.RoadmapItem) {
	fmt.Println("🚀 Performance Benchmarks")
	fmt.Println("-" + string(make([]byte, 25)))
	
	engine := priority.NewEngine()
	
	// Benchmark single calculations
	start := time.Now()
	for i := 0; i < 1000; i++ {
		for _, item := range items {
			engine.Calculate(item)
		}
	}
	duration := time.Since(start)
	
	totalCalculations := 1000 * len(items)
	avgPerCalc := duration / time.Duration(totalCalculations)
	
	fmt.Printf("✅ Calculated %d priorities in %v\n", totalCalculations, duration)
	fmt.Printf("✅ Average per calculation: %v\n", avgPerCalc)
	
	// Benchmark ranking
	start = time.Now()
	for i := 0; i < 100; i++ {
		engine.Rank(items)
	}
	rankDuration := time.Since(start)
	
	fmt.Printf("✅ Ranked %d item lists in %v\n", 100, rankDuration)
	fmt.Printf("✅ Average per ranking: %v\n", rankDuration/100)
	
	if avgPerCalc < time.Millisecond {
		fmt.Println("🎉 Performance: Excellent!")
	} else if avgPerCalc < 10*time.Millisecond {
		fmt.Println("👍 Performance: Good")
	} else {
		fmt.Println("⚠️  Performance: Could be improved")
	}
	
	fmt.Println()
}

// Helper function to join strings (since strings.Join is not always available)
func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	if len(strs) == 1 {
		return strs[0]
	}
	
	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}
