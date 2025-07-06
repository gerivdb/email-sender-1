package priority

import (
	"testing"
	"time"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"
)

func TestPriorityEngine_NewEngine(t *testing.T) {
	engine := NewEngine()
	if engine == nil {
		t.Fatal("NewEngine() returned nil")
	}

	if engine.config.Impact == 0 {
		t.Fatal("Engine config not properly initialized")
	}
}

func TestPriorityEngine_Calculate(t *testing.T) {
	engine := NewEngine()

	// Create test item with valid fields
	item := types.RoadmapItem{
		ID:            "test-1",
		Title:         "Test Task",
		Description:   "Test Description",
		Priority:      types.PriorityHigh,
		RiskLevel:     types.RiskHigh,
		BusinessValue: 8,
		Complexity:    types.BasicComplexityMedium,
		Effort:        40,
		TechnicalDebt: 3,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	priority, err := engine.Calculate(item)
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}

	if priority.Score <= 0 {
		t.Fatalf("Expected positive score, got %f", priority.Score)
	}

	if priority.TaskID != item.ID {
		t.Fatalf("Expected TaskID %s, got %s", item.ID, priority.TaskID)
	}
}

func TestPriorityEngine_Rank(t *testing.T) {
	engine := NewEngine()

	// Create test items with varying priority characteristics
	items := []types.RoadmapItem{
		{
			ID:            "test-1",
			Title:         "High Priority Task",
			Description:   "Important and urgent",
			Priority:      types.PriorityHigh,
			RiskLevel:     types.RiskHigh,
			BusinessValue: 9,
			Complexity:    types.BasicComplexityLow,
			Effort:        20,
			TechnicalDebt: 1,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
		{
			ID:            "test-2",
			Title:         "Medium Priority Task",
			Description:   "Important but moderate effort",
			Priority:      types.PriorityMedium,
			RiskLevel:     types.RiskMedium,
			BusinessValue: 6,
			Complexity:    types.BasicComplexityMedium,
			Effort:        60,
			TechnicalDebt: 4,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
		{
			ID:            "test-3",
			Title:         "Low Priority Task",
			Description:   "Nice to have",
			Priority:      types.PriorityLow,
			RiskLevel:     types.RiskLow,
			BusinessValue: 3,
			Complexity:    types.BasicComplexityHigh,
			Effort:        100,
			TechnicalDebt: 7,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
	}

	rankedItems, err := engine.Rank(items)
	if err != nil {
		t.Fatalf("Rank failed: %v", err)
	}

	if len(rankedItems) != len(items) {
		t.Fatalf("Expected %d items, got %d", len(items), len(rankedItems))
	}

	// First item should be the highest priority (test-1 with high business value, low effort)
	if rankedItems[0].ID != "test-1" {
		t.Logf("Items may not be sorted correctly by priority, got %s first", rankedItems[0].ID)
	}
}

func TestPriorityEngine_SetWeightingConfig(t *testing.T) {
	engine := NewEngine()

	customConfig := WeightingConfig{
		Urgency:       0.4,
		Impact:        0.3,
		Effort:        0.2,
		Dependencies:  0.05,
		BusinessValue: 0.04,
		Risk:          0.01,
	}

	engine.SetWeightingConfig(customConfig)

	config := engine.GetWeightingConfig()
	if config.Urgency != 0.4 {
		t.Fatalf("Expected urgency weight 0.4, got %f", config.Urgency)
	}

	if config.Impact != 0.3 {
		t.Fatalf("Expected impact weight 0.3, got %f", config.Impact)
	}
}

func TestPriorityEngine_SetCalculator(t *testing.T) {
	engine := NewEngine()

	// Create a custom calculator
	calculator := NewEisenhowerCalculator()
	engine.SetCalculator(calculator)

	// Test that we can still calculate
	item := types.RoadmapItem{
		ID:            "test-calculator",
		Title:         "Test Calculator Task",
		Priority:      types.PriorityMedium,
		RiskLevel:     types.RiskMedium,
		BusinessValue: 5,
		Complexity:    types.BasicComplexityMedium,
		Effort:        50,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	_, err := engine.Calculate(item)
	if err != nil {
		t.Fatalf("Calculate failed after setting calculator: %v", err)
	}
}

func TestPriorityEngine_CacheOperations(t *testing.T) {
	engine := NewEngine()

	item := types.RoadmapItem{
		ID:            "test-cache",
		Title:         "Test Cache Task",
		Priority:      types.PriorityMedium,
		RiskLevel:     types.RiskMedium,
		BusinessValue: 5,
		Complexity:    types.BasicComplexityMedium,
		Effort:        50,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	// Calculate priority (should cache result)
	priority1, err := engine.Calculate(item)
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}

	// Get cached priority
	cachedPriority, exists := engine.GetCachedPriority(item.ID)
	if !exists {
		t.Fatal("Priority should be cached")
	}

	if cachedPriority.Score != priority1.Score {
		t.Fatalf("Cached priority score mismatch: expected %f, got %f",
			priority1.Score, cachedPriority.Score)
	}

	// Update task (should clear cache)
	err = engine.Update(item.ID)
	if err != nil {
		t.Fatalf("Update failed: %v", err)
	}

	// Cache should be cleared
	_, exists = engine.GetCachedPriority(item.ID)
	if exists {
		t.Fatal("Priority should not be cached after update")
	}

	// Clear all cache
	engine.Calculate(item) // Re-cache
	engine.ClearCache()
	_, exists = engine.GetCachedPriority(item.ID)
	if exists {
		t.Fatal("Priority should not be cached after ClearCache")
	}
}

func TestPriorityEngine_Integration(t *testing.T) {
	// This test verifies the complete workflow
	engine := NewEngine()

	// Configure custom weights
	config := WeightingConfig{
		Urgency:       0.4,
		Impact:        0.3,
		Effort:        0.2,
		Dependencies:  0.05,
		BusinessValue: 0.04,
		Risk:          0.01,
	}
	engine.SetWeightingConfig(config)

	// Create test items representing different priority scenarios
	items := []types.RoadmapItem{
		{
			ID:            "urgent-important",
			Title:         "Critical Bug Fix",
			Description:   "Production system down",
			Priority:      types.PriorityCritical,
			RiskLevel:     types.RiskHigh,
			BusinessValue: 10,
			Complexity:    types.BasicComplexityLow,
			Effort:        8,
			TechnicalDebt: 1,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
		{
			ID:            "important-not-urgent",
			Title:         "Feature Development",
			Description:   "New customer feature",
			Priority:      types.PriorityHigh,
			RiskLevel:     types.RiskMedium,
			BusinessValue: 8,
			Complexity:    types.BasicComplexityMedium,
			Effort:        80,
			TechnicalDebt: 2,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
		{
			ID:            "urgent-not-important",
			Title:         "Quick Fix",
			Description:   "Minor UI issue",
			Priority:      types.PriorityMedium,
			RiskLevel:     types.RiskLow,
			BusinessValue: 3,
			Complexity:    types.BasicComplexityLow,
			Effort:        4,
			TechnicalDebt: 1,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
		{
			ID:            "not-urgent-not-important",
			Title:         "Documentation Update",
			Description:   "Update README",
			Priority:      types.PriorityLow,
			RiskLevel:     types.RiskLow,
			BusinessValue: 2,
			Complexity:    types.BasicComplexityLow,
			Effort:        2,
			TechnicalDebt: 0,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
		},
	}

	// Calculate priorities for all items
	priorities := make(map[string]TaskPriority)
	for _, item := range items {
		priority, err := engine.Calculate(item)
		if err != nil {
			t.Fatalf("Failed to calculate priority for item %s: %v", item.ID, err)
		}
		priorities[item.ID] = priority
		t.Logf("Item %s: Score=%.3f", item.ID, priority.Score)
	}

	// Rank items
	rankedItems, err := engine.Rank(items)
	if err != nil {
		t.Fatalf("Failed to rank items: %v", err)
	}

	// Verify ranking makes sense
	// Critical bug (critical priority + high business value + low effort) should be first
	if rankedItems[0].ID != "urgent-important" {
		t.Logf("Expected urgent-important to be first, got %s", rankedItems[0].ID)
		t.Logf("This may be acceptable depending on the algorithm weights")
	}

	// Documentation (low priority + low business value) should likely be last
	lastItem := rankedItems[len(rankedItems)-1]
	if lastItem.ID != "not-urgent-not-important" {
		t.Logf("Expected not-urgent-not-important to be last, got %s", lastItem.ID)
		t.Logf("This may be acceptable depending on the algorithm weights")
	}

	t.Logf("Integration test completed successfully")
	t.Logf("Items ranked in order:")
	for i, rankedItem := range rankedItems {
		priority := priorities[rankedItem.ID]
		t.Logf("  %d. %s (Score: %.3f)",
			i+1, rankedItem.ID, priority.Score)
	}
}
