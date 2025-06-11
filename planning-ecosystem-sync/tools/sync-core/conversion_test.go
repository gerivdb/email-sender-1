package main

import (
	"encoding/json"
	"fmt"
	"testing"
	"time"
)

// TestConvertToDynamic tests the conversion of markdown data to dynamic plan format
func TestConvertToDynamic(t *testing.T) {
	parser := NewMarkdownParser()
	
	// Test metadata
	metadata := &PlanMetadata{
		FilePath:    "test/plan-dev-v48-repovisualizer.md",
		Title:       "Plan de développement v48 - Repository Visualizer",
		Version:     "v48",
		Date:        "2025-06-11",
		Progression: 75.0,
		Description: "Test plan for repository visualizer",
	}
	
	// Test tasks
	tasks := []Task{
		{
			ID:          "task_1",
			Title:       "Architecture de base",
			Description: "Définir l'architecture du système",
			Status:      "completed",
			Phase:       "Phase 1",
			Level:       1,
			Priority:    "high",
			Completed:   true,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		},
		{
			ID:          "task_2",
			Title:       "Implémentation parser",
			Description: "Développer le parser de fichiers",
			Status:      "in_progress",
			Phase:       "Phase 2",
			Level:       2,
			Priority:    "medium",
			Completed:   false,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Dependencies: []string{"task_1"},
		},
	}
	
	// Convert to dynamic format
	plan, err := parser.ConvertToDynamic(metadata, tasks)
	if err != nil {
		t.Fatalf("ConvertToDynamic failed: %v", err)
	}
	
	// Verify plan data integrity
	if plan.ID == "" {
		t.Error("Plan ID should not be empty")
	}
	
	if plan.Metadata.Title != metadata.Title {
		t.Errorf("Expected title %s, got %s", metadata.Title, plan.Metadata.Title)
	}
	
	if len(plan.Tasks) != len(tasks) {
		t.Errorf("Expected %d tasks, got %d", len(tasks), len(plan.Tasks))
	}
	
	// Verify embeddings are generated (should be 384 dimensions)
	if len(plan.Embeddings) != 384 {
		t.Errorf("Expected 384 embeddings dimensions, got %d", len(plan.Embeddings))
	}
	
	// Verify timestamps are set
	if plan.CreatedAt.IsZero() {
		t.Error("CreatedAt timestamp should be set")
	}
	
	if plan.UpdatedAt.IsZero() {
		t.Error("UpdatedAt timestamp should be set")
	}
	
	t.Logf("✅ ConvertToDynamic test passed - Plan ID: %s", plan.ID)
}

// TestEmbeddingsGeneration tests the embeddings generation functionality
func TestEmbeddingsGeneration(t *testing.T) {
	parser := NewMarkdownParser()
	
	title := "Test Plan for Embeddings"
	tasks := []Task{
		{
			Title:       "Test task 1",
			Description: "First test task description",
		},
		{
			Title:       "Test task 2",
			Description: "Second test task description",
		},
	}
	
	// Generate embeddings
	embeddings, err := parser.generateEmbeddings(title, tasks)
	if err != nil {
		t.Fatalf("generateEmbeddings failed: %v", err)
	}
	
	// Verify dimension is 384 (standard for many models)
	if len(embeddings) != 384 {
		t.Errorf("Expected 384 dimensions, got %d", len(embeddings))
	}
	
	// Verify embeddings are in valid range [-1, 1]
	for i, val := range embeddings {
		if val < -1.0 || val > 1.0 {
			t.Errorf("Embedding value at index %d is out of range [-1, 1]: %f", i, val)
		}
	}
	
	// Verify embeddings are not all zeros
	allZeros := true
	for _, val := range embeddings {
		if val != 0.0 {
			allZeros = false
			break
		}
	}
	
	if allZeros {
		t.Error("Embeddings should not be all zeros")
	}
	
	t.Logf("✅ Embeddings generation test passed - Generated %d-dimensional vector", len(embeddings))
}

// TestPlanValidation tests the plan validation functionality
func TestPlanValidation(t *testing.T) {
	parser := NewMarkdownParser()
	
	// Test valid plan
	validPlan := &DynamicPlan{
		ID: "test_plan_123",
		Metadata: PlanMetadata{
			Title:    "Valid Test Plan",
			FilePath: "test/valid_plan.md",
		},
		Tasks: []Task{
			{
				ID:    "task_1",
				Title: "Valid Task",
			},
		},
		Embeddings: make([]float64, 384), // Correct dimension
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	
	err := parser.ValidateConversion(validPlan)
	if err != nil {
		t.Errorf("Valid plan should pass validation, got error: %v", err)
	}
	
	// Test invalid plan - missing ID
	invalidPlan1 := &DynamicPlan{
		ID: "", // Missing ID
		Metadata: PlanMetadata{
			Title: "Invalid Test Plan",
		},
		Tasks: []Task{
			{
				ID:    "task_1",
				Title: "Valid Task",
			},
		},
	}
	
	err = parser.ValidateConversion(invalidPlan1)
	if err == nil {
		t.Error("Plan with missing ID should fail validation")
	}
	
	// Test invalid plan - no tasks
	invalidPlan2 := &DynamicPlan{
		ID: "test_plan_456",
		Metadata: PlanMetadata{
			Title: "Invalid Test Plan",
		},
		Tasks: []Task{}, // No tasks
	}
	
	err = parser.ValidateConversion(invalidPlan2)
	if err == nil {
		t.Error("Plan with no tasks should fail validation")
	}
	
	// Test invalid embeddings dimension
	invalidPlan3 := &DynamicPlan{
		ID: "test_plan_789",
		Metadata: PlanMetadata{
			Title: "Invalid Test Plan",
		},
		Tasks: []Task{
			{
				ID:    "task_1",
				Title: "Valid Task",
			},
		},
		Embeddings: make([]float64, 256), // Wrong dimension
	}
	
	err = parser.ValidateConversion(invalidPlan3)
	if err == nil {
		t.Error("Plan with wrong embeddings dimension should fail validation")
	}
	
	t.Logf("✅ Plan validation test passed")
}

// TestSerialization tests the plan serialization functionality
func TestSerialization(t *testing.T) {
	parser := NewMarkdownParser()
	
	// Create test plan
	plan := &DynamicPlan{
		ID: "test_plan_serialization",
		Metadata: PlanMetadata{
			Title:       "Serialization Test Plan",
			Version:     "v1.0",
			FilePath:    "test/serialization_test.md",
			Progression: 50.0,
		},
		Tasks: []Task{
			{
				ID:          "task_1",
				Title:       "Serialization Task",
				Description: "Test task for serialization",
				Status:      "pending",
				Phase:       "Phase 1",
				Level:       1,
				Priority:    "medium",
				Completed:   false,
				Dependencies: []string{},
				CreatedAt:   time.Now(),
				UpdatedAt:   time.Now(),
			},
		},
		Embeddings: make([]float64, 384),
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	
	// Serialize plan
	data, err := parser.SerializePlan(plan)
	if err != nil {
		t.Fatalf("SerializePlan failed: %v", err)
	}
	
	// Verify serialized data is valid JSON
	var deserializedPlan DynamicPlan
	err = json.Unmarshal(data, &deserializedPlan)
	if err != nil {
		t.Fatalf("Failed to deserialize plan: %v", err)
	}
	
	// Verify data integrity after serialization/deserialization
	if deserializedPlan.ID != plan.ID {
		t.Errorf("Expected ID %s, got %s", plan.ID, deserializedPlan.ID)
	}
	
	if deserializedPlan.Metadata.Title != plan.Metadata.Title {
		t.Errorf("Expected title %s, got %s", plan.Metadata.Title, deserializedPlan.Metadata.Title)
	}
	
	if len(deserializedPlan.Tasks) != len(plan.Tasks) {
		t.Errorf("Expected %d tasks, got %d", len(plan.Tasks), len(deserializedPlan.Tasks))
	}
	
	if len(deserializedPlan.Embeddings) != len(plan.Embeddings) {
		t.Errorf("Expected %d embeddings, got %d", len(plan.Embeddings), len(deserializedPlan.Embeddings))
	}
	
	// Verify JSON size is reasonable (not empty)
	if len(data) < 100 {
		t.Error("Serialized data seems too small, might be incomplete")
	}
	
	t.Logf("✅ Serialization test passed - Serialized to %d bytes", len(data))
}

// TestPlanIDGeneration tests the plan ID generation functionality
func TestPlanIDGeneration(t *testing.T) {
	// Test ID generation consistency
	filePath1 := "test/plan-dev-v48.md"
	filePath2 := "test/plan-dev-v49.md"
	
	id1a := generatePlanID(filePath1)
	id1b := generatePlanID(filePath1)
	id2 := generatePlanID(filePath2)
	
	// Same file path should generate same ID
	if id1a != id1b {
		t.Errorf("Same file path should generate same ID: %s != %s", id1a, id1b)
	}
	
	// Different file paths should generate different IDs
	if id1a == id2 {
		t.Errorf("Different file paths should generate different IDs: %s == %s", id1a, id2)
	}
	
	// IDs should have correct format (plan_ prefix)
	if !startsWith(id1a, "plan_") {
		t.Errorf("Plan ID should start with 'plan_': %s", id1a)
	}
	
	// IDs should have reasonable length
	if len(id1a) < 10 {
		t.Errorf("Plan ID seems too short: %s", id1a)
	}
	
	t.Logf("✅ Plan ID generation test passed - Generated IDs: %s, %s", id1a, id2)
}

// Helper function to check string prefix
func startsWith(s, prefix string) bool {
	return len(s) >= len(prefix) && s[:len(prefix)] == prefix
}

// BenchmarkConversion benchmarks the conversion performance
func BenchmarkConversion(b *testing.B) {
	parser := NewMarkdownParser()
	
	metadata := &PlanMetadata{
		FilePath:    "benchmark/plan.md",
		Title:       "Benchmark Plan",
		Version:     "v1.0",
		Date:        "2025-06-11",
		Progression: 50.0,
		Description: "Benchmark test plan",
	}
	
	// Create multiple tasks for realistic benchmark
	tasks := make([]Task, 100)
	for i := 0; i < 100; i++ {
		tasks[i] = Task{
			ID:          fmt.Sprintf("task_%d", i),
			Title:       fmt.Sprintf("Task %d", i),
			Description: fmt.Sprintf("Description for task %d", i),
			Status:      "pending",
			Phase:       fmt.Sprintf("Phase %d", i%5+1),
			Level:       i%3 + 1,
			Priority:    "medium",
			Completed:   false,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}
	}
	
	b.ResetTimer()
	
	for i := 0; i < b.N; i++ {
		_, err := parser.ConvertToDynamic(metadata, tasks)
		if err != nil {
			b.Fatalf("Conversion failed: %v", err)
		}
	}
}
