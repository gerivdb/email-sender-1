package models

import (
	"testing"
	"time"

	"email_sender/cmd/roadmap-cli/priority"
	"email_sender/cmd/roadmap-cli/types"
)

func TestPriorityVisualization_ActiveView_Unique(t *testing.T) {
	engine := priority.NewEngine()
	items := []types.RoadmapItem{
		{
			ID:           "test-1",
			Title:        "Test Item",
			Priority:     types.PriorityHigh,
			RiskLevel:    types.RiskMedium,
			BusinessValue: 7,
			Complexity:   types.BasicComplexityMedium,
			Effort:       5,
			TechnicalDebt: 2,
		},
	}

	viz := NewPriorityVisualization(engine, items)
	viz.SetActive(true)

	// Test that View() returns content when active
	result := viz.View()
	if result == "" {
		t.Error("View() returned empty string when visualization is active")
	}

	// Test that View() returns empty string when inactive
	viz.SetActive(false)
	result = viz.View()
	if result != "" {
		t.Error("View() should return empty string when visualization is inactive")
	}
}

func TestPriorityVisualization_EdgeCases_Unique(t *testing.T) {
	engine := priority.NewEngine()

	// Test with empty items
	emptyItems := []types.RoadmapItem{}
	viz := NewPriorityVisualization(engine, emptyItems)
	if viz == nil {
		t.Fatal("NewPriorityVisualization() returned nil for empty items")
	}

	viz.SetActive(true)
	result := viz.View()
	// Should not crash with empty items
	if result == "" {
		t.Log("View() returned empty string for empty items - this is acceptable")
	}
}

func TestPriorityView_NewPriorityView_Unique(t *testing.T) {
	engine := priority.NewEngine()
	items := []types.RoadmapItem{
		{
			ID:           "test-1",
			Title:        "Test Item",
			Priority:     types.PriorityHigh,
			RiskLevel:    types.RiskMedium,
			BusinessValue: 7,
			Complexity:   types.BasicComplexityMedium,
			Effort:       3,
			TechnicalDebt: 2,
		},
	}

	view := NewPriorityView(engine, items)
	if view == nil {
		t.Fatal("NewPriorityView() returned nil")
		return
	}

	if view.engine != engine {
		t.Error("PriorityView engine not set correctly")
	}

	if len(view.items) != len(items) {
		t.Errorf("PriorityView items count = %d, expected %d", len(view.items), len(items))
	}
}

func TestPriorityEngine_Calculate_Unique(t *testing.T) {
	engine := priority.NewEngine()

	item := types.RoadmapItem{
		ID:           "test-1",
		Title:        "High Value Task",
		Priority:     types.PriorityHigh,
		RiskLevel:    types.RiskMedium,
		BusinessValue: 8,
		Complexity:   types.BasicComplexityMedium,
		Effort:       3,
		TechnicalDebt: 2,
		CreatedAt:    time.Now().Add(-time.Hour),
		TargetDate:   time.Now().Add(4 * time.Hour), // Due soon
	}

	taskPriority, err := engine.Calculate(item)
	if err != nil {
		t.Fatalf("Calculate() failed: %v", err)
	}

	if taskPriority.TaskID != item.ID {
		t.Errorf("TaskID = %s, expected %s", taskPriority.TaskID, item.ID)
	}

	if taskPriority.Score <= 0 {
		t.Error("Priority score should be greater than 0")
	}
}

func TestPriorityEngine_Rank_Unique(t *testing.T) {
	engine := priority.NewEngine()

	items := []types.RoadmapItem{
		{
			ID:           "low-priority",
			Title:        "Low Priority Task",
			Priority:     types.PriorityLow,
			RiskLevel:    types.RiskLow,
			BusinessValue: 2,
			Complexity:   types.BasicComplexityHigh,
			Effort:       8,
			TechnicalDebt: 2,
		},
		{
			ID:           "high-priority",
			Title:        "High Priority Task",
			Priority:     types.PriorityHigh,
			RiskLevel:    types.RiskHigh,
			BusinessValue: 9,
			Complexity:   types.BasicComplexityLow,
			Effort:       3,
			TechnicalDebt: 5,
		},
		{
			ID:           "medium-priority",
			Title:        "Medium Priority Task",
			Priority:     types.PriorityMedium,
			RiskLevel:    types.RiskMedium,
			BusinessValue: 5,
			Complexity:   types.BasicComplexityMedium,
			Effort:       5,
			TechnicalDebt: 2,
		},
	}

	ranked, err := engine.Rank(items)
	if err != nil {
		t.Fatalf("Rank() failed: %v", err)
	}

	if len(ranked) != len(items) {
		t.Errorf("Ranked items count = %d, expected %d", len(ranked), len(items))
	}

	// Verify high priority task is ranked first
	if ranked[0].ID != "high-priority" {
		t.Errorf("Expected high-priority task to be ranked first, got: %s", ranked[0].ID)
	}
}

func TestPriorityEngine_WeightingConfig_Unique(t *testing.T) {
	engine := priority.NewEngine()

	// Test default config
	defaultConfig := engine.GetWeightingConfig()
	if defaultConfig.Impact == 0 {
		t.Error("Default weighting config should have non-zero impact weight")
	}

	// Test setting custom config
	customConfig := priority.WeightingConfig{
		Urgency:       0.3,
		Impact:        0.3,
		Effort:        0.2,
		Dependencies:  0.05,
		BusinessValue: 0.1,
		Risk:          0.05,
	}

	engine.SetWeightingConfig(customConfig)
	retrievedConfig := engine.GetWeightingConfig()

	if retrievedConfig.Urgency != customConfig.Urgency {
		t.Errorf("Urgency weight = %f, expected %f", retrievedConfig.Urgency, customConfig.Urgency)
	}

	if retrievedConfig.Impact != customConfig.Impact {
		t.Errorf("Impact weight = %f, expected %f", retrievedConfig.Impact, customConfig.Impact)
	}
}

func TestIntegration_PriorityViewAndVisualization_Unique(t *testing.T) {
	engine := priority.NewEngine()
	items := []types.RoadmapItem{
		{
			ID:           "integration-test-1",
			Title:        "Integration Test Task",
			Priority:     types.PriorityHigh,
			RiskLevel:    types.RiskMedium,
			BusinessValue: 8,
			Complexity:   types.BasicComplexityMedium,
			Effort:       3,
			TechnicalDebt: 2,
		},
	}

	// Test PriorityView
	priorityView := NewPriorityView(engine, items)
	if priorityView == nil {
		t.Error("Failed to create PriorityView")
	}

	// Test PriorityVisualization
	priorityViz := NewPriorityVisualization(engine, items)
	if priorityViz == nil {
		t.Error("Failed to create PriorityVisualization")
	}

	priorityViz.SetActive(true)
	viz := priorityViz.View()
	if viz == "" {
		t.Error("PriorityVisualization.View() returned empty string")
	}

	// Test that priorities are calculated for all items
	if priorityViz != nil && len(priorityViz.priorities) == 0 {
		t.Error("No priorities calculated for items")
	}
}

func TestPriorityEngine_ExtremeValues(t *testing.T) {
	e := priority.NewEngine()

	// Test avec des valeurs extrêmes
	item := types.RoadmapItem{
		ID:           "extreme-test",
		Title:        "Extreme Value Task",
		Priority:     types.PriorityHigh,
		RiskLevel:    types.RiskHigh,
		BusinessValue: 1000, // Valeur extrême
		Complexity:   types.BasicComplexityLow,
		Effort:       0,     // Effort nul
		TechnicalDebt: -1,   // Dette technique négative (invalide)
	}

	_, err := e.Calculate(item)
	if err == nil {
		t.Error("Calculate() devrait échouer pour des valeurs invalides")
	}

	// Test avec des valeurs minimales
	item = types.RoadmapItem{
		ID:           "minimal-test",
		Title:        "Minimal Value Task",
		Priority:     types.PriorityLow,
		RiskLevel:    types.RiskLow,
		BusinessValue: 0,
		Complexity:   types.BasicComplexityHigh,
		Effort:       1,
		TechnicalDebt: 0,
	}

	priorityScore, err := e.Calculate(item)
	if err != nil {
		t.Fatalf("Calculate() a échoué pour des valeurs minimales : %v", err)
	}

	if priorityScore.Score <= 0 {
		t.Error("Le score de priorité devrait être supérieur à 0 pour des valeurs minimales valides")
	}
}
