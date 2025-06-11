package validation

import (
	"context"
	"testing"
)

func TestMetadataConsistencyRule(t *testing.T) {
	rule := NewMetadataConsistencyRule()
	
	if rule.GetID() != "metadata_consistency" {
		t.Errorf("Expected ID 'metadata_consistency', got %s", rule.GetID())
	}

	if rule.GetPriority() != 1 {
		t.Errorf("Expected priority 1, got %d", rule.GetPriority())
	}

	// Test avec données simulées
	ctx := context.Background()
	data := ValidationData{
		MarkdownPlan: createTestMarkdownPlan(),
		DynamicPlan:  createTestDynamicPlan(),
	}

	issues, err := rule.Validate(ctx, "test-plan", data)
	if err != nil {
		t.Errorf("Expected no error, got: %v", err)
	}

	if len(issues) == 0 {
		t.Log("No metadata inconsistencies found (expected for test data)")
	}
}

func TestTaskConsistencyRule(t *testing.T) {
	rule := NewTaskConsistencyRule()
	
	if rule.GetID() != "task_consistency" {
		t.Errorf("Expected ID 'task_consistency', got %s", rule.GetID())
	}

	ctx := context.Background()
	data := ValidationData{
		MarkdownPlan: createTestMarkdownPlan(),
		DynamicPlan:  createTestDynamicPlan(),
	}

	issues, err := rule.Validate(ctx, "test-plan", data)
	if err != nil {
		t.Errorf("Expected no error, got: %v", err)
	}

	if len(issues) == 0 {
		t.Log("No task inconsistencies found (expected for test data)")
	}
}

func TestStructureConsistencyRule(t *testing.T) {
	rule := NewStructureConsistencyRule()
	
	if rule.GetID() != "structure_consistency" {
		t.Errorf("Expected ID 'structure_consistency', got %s", rule.GetID())
	}

	ctx := context.Background()
	data := ValidationData{
		MarkdownPlan: createTestMarkdownPlan(),
		DynamicPlan:  createTestDynamicPlan(),
	}

	issues, err := rule.Validate(ctx, "test-plan", data)
	if err != nil {
		t.Errorf("Expected no error, got: %v", err)
	}

	if len(issues) == 0 {
		t.Log("No structure inconsistencies found (expected for test data)")
	}
}

func TestTimestampConsistencyRule(t *testing.T) {
	rule := NewTimestampConsistencyRule()
	
	if rule.GetID() != "timestamp_consistency" {
		t.Errorf("Expected ID 'timestamp_consistency', got %s", rule.GetID())
	}

	ctx := context.Background()
	data := ValidationData{
		MarkdownPlan: createTestMarkdownPlan(),
		DynamicPlan:  createTestDynamicPlan(),
	}

	issues, err := rule.Validate(ctx, "test-plan", data)
	if err != nil {
		t.Errorf("Expected no error, got: %v", err)
	}

	if len(issues) == 0 {
		t.Log("No timestamp inconsistencies found (expected for test data)")
	}
}

func TestGetAllValidationRules(t *testing.T) {
	rules := GetAllValidationRules()
	
	expectedCount := 4 // metadata, task, structure, timestamp
	if len(rules) != expectedCount {
		t.Errorf("Expected %d rules, got %d", expectedCount, len(rules))
	}

	// Vérifier que toutes les règles ont des IDs uniques
	ids := make(map[string]bool)
	for _, rule := range rules {
		id := rule.GetID()
		if ids[id] {
			t.Errorf("Duplicate rule ID found: %s", id)
		}
		ids[id] = true
	}
}

func BenchmarkMetadataRule(b *testing.B) {
	rule := NewMetadataConsistencyRule()
	ctx := context.Background()
	data := ValidationData{
		MarkdownPlan: createTestMarkdownPlan(),
		DynamicPlan:  createTestDynamicPlan(),
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rule.Validate(ctx, "benchmark-plan", data)
	}
}

// Fonctions utilitaires pour créer des données de test
func createTestMarkdownPlan() interface{} {
	return map[string]interface{}{
		"title":       "Test Plan",
		"version":     "1.0",
		"progression": 50.0,
		"tasks": []map[string]interface{}{
			{
				"id":        "task-1",
				"title":     "Test Task 1",
				"completed": false,
			},
			{
				"id":        "task-2", 
				"title":     "Test Task 2",
				"completed": true,
			},
		},
	}
}

func createTestDynamicPlan() interface{} {
	return map[string]interface{}{
		"title":       "Test Plan",
		"version":     "1.0",
		"progression": 50.0,
		"tasks": []map[string]interface{}{
			{
				"id":        "task-1",
				"title":     "Test Task 1",
				"completed": false,
			},
			{
				"id":        "task-2",
				"title":     "Test Task 2",
				"completed": true,
			},
		},
	}
}
