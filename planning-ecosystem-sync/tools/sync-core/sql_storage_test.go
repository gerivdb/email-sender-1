package sync_core

import (
	"fmt"
	"testing"
	"time"
)

// TestSQLStorageIntegration tests the SQL storage functionality
func TestSQLStorageIntegration(t *testing.T) {	// Use SQLite for testing
	config := DatabaseConfig{
		Driver:		"sqlite",
		Connection:	"file:test.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Create test plan
	plan := &DynamicPlan{
		ID:	"test_plan_sql",
		Metadata: PlanMetadata{
			Title:		"SQL Test Plan",
			Version:	"v1.0",
			FilePath:	"test/sql_test.md",
			Description:	"Test plan for SQL storage",
			Progression:	60.0,
		},
		Tasks: []Task{
			{
				ID:		"task_sql_1",
				Title:		"SQL Task 1",
				Description:	"First SQL test task",
				Status:		"completed",
				Phase:		"Phase 1",
				Level:		1,
				Priority:	"high",
				Completed:	true,
				Dependencies:	[]string{},
				CreatedAt:	time.Now(),
				UpdatedAt:	time.Now(),
			},
			{
				ID:		"task_sql_2",
				Title:		"SQL Task 2",
				Description:	"Second SQL test task",
				Status:		"in_progress",
				Phase:		"Phase 2",
				Level:		2,
				Priority:	"medium",
				Completed:	false,
				Dependencies:	[]string{"task_sql_1"},
				CreatedAt:	time.Now(),
				UpdatedAt:	time.Now(),
			},
		},
		Embeddings:	make([]float64, 384),
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	// Test storing plan
	err = storage.StorePlan(plan)
	if err != nil {
		t.Fatalf("Failed to store plan: %v", err)
	}

	// Test retrieving plan
	retrievedPlan, err := storage.GetPlan("test_plan_sql")
	if err != nil {
		t.Fatalf("Failed to retrieve plan: %v", err)
	}

	// Verify data integrity
	if retrievedPlan.ID != plan.ID {
		t.Errorf("Expected ID %s, got %s", plan.ID, retrievedPlan.ID)
	}

	if retrievedPlan.Metadata.Title != plan.Metadata.Title {
		t.Errorf("Expected title %s, got %s", plan.Metadata.Title, retrievedPlan.Metadata.Title)
	}

	if len(retrievedPlan.Tasks) != len(plan.Tasks) {
		t.Errorf("Expected %d tasks, got %d", len(plan.Tasks), len(retrievedPlan.Tasks))
	}

	// Verify task data integrity
	for i, expectedTask := range plan.Tasks {
		if i >= len(retrievedPlan.Tasks) {
			t.Errorf("Missing task at index %d", i)
			continue
		}

		retrievedTask := retrievedPlan.Tasks[i]

		if retrievedTask.ID != expectedTask.ID {
			t.Errorf("Task %d: Expected ID %s, got %s", i, expectedTask.ID, retrievedTask.ID)
		}

		if retrievedTask.Title != expectedTask.Title {
			t.Errorf("Task %d: Expected title %s, got %s", i, expectedTask.Title, retrievedTask.Title)
		}

		if len(retrievedTask.Dependencies) != len(expectedTask.Dependencies) {
			t.Errorf("Task %d: Expected %d dependencies, got %d", i, len(expectedTask.Dependencies), len(retrievedTask.Dependencies))
		}
	}

	t.Logf("✅ SQL storage integration test passed")
}

// TestSQLStorageRecovery tests error handling and recovery
func TestSQLStorageRecovery(t *testing.T) {	// Use SQLite for testing
	config := DatabaseConfig{
		Driver:		"sqlite",
		Connection:	"file:test_recovery.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Test retrieving non-existent plan
	_, err = storage.GetPlan("non_existent_plan")
	if err == nil {
		t.Error("Should fail when retrieving non-existent plan")
	}

	// Test storing plan with missing required fields
	invalidPlan := &DynamicPlan{
		ID:	"",	// Missing ID
		Metadata: PlanMetadata{
			Title: "Invalid Plan",
		},
		Tasks:		[]Task{},
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	err = storage.StorePlan(invalidPlan)
	if err == nil {
		t.Error("Should fail when storing plan with missing ID")
	}

	t.Logf("✅ SQL storage recovery test passed")
}

// TestSQLStorageStatistics tests the statistics functionality
func TestSQLStorageStatistics(t *testing.T) {
	// Use SQLite for testing
	config := DatabaseConfig{
		Driver:		"sqlite",
		Connection:	"file:test_stats.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Store a test plan
	plan := &DynamicPlan{
		ID:	"test_plan_stats",
		Metadata: PlanMetadata{
			Title:		"Statistics Test Plan",
			FilePath:	"test/stats_test.md",
		},
		Tasks: []Task{
			{
				ID:		"task_stats_1",
				Title:		"Completed Task",
				Status:		"completed",
				Completed:	true,
				CreatedAt:	time.Now(),
				UpdatedAt:	time.Now(),
			},
			{
				ID:		"task_stats_2",
				Title:		"Pending Task",
				Status:		"pending",
				Completed:	false,
				CreatedAt:	time.Now(),
				UpdatedAt:	time.Now(),
			},
		},
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	err = storage.StorePlan(plan)
	if err != nil {
		t.Fatalf("Failed to store plan: %v", err)
	}

	// Get statistics
	stats, err := storage.GetSyncStats()
	if err != nil {
		t.Fatalf("Failed to get statistics: %v", err)
	}

	// Verify statistics
	if totalPlans, ok := stats["total_plans"].(int); !ok || totalPlans < 1 {
		t.Errorf("Expected at least 1 plan, got %v", stats["total_plans"])
	}

	if totalTasks, ok := stats["total_tasks"].(int); !ok || totalTasks < 2 {
		t.Errorf("Expected at least 2 tasks, got %v", stats["total_tasks"])
	}

	if completedTasks, ok := stats["completed_tasks"].(int); !ok || completedTasks < 1 {
		t.Errorf("Expected at least 1 completed task, got %v", stats["completed_tasks"])
	}

	t.Logf("✅ SQL storage statistics test passed - Stats: %+v", stats)
}

// TestSQLStoragePerformance tests the performance of SQL operations
func TestSQLStoragePerformance(t *testing.T) {	// Use SQLite for testing
	config := DatabaseConfig{
		Driver:		"sqlite",
		Connection:	"file:test_perf.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Create a plan with many tasks
	tasks := make([]Task, 100)
	for i := 0; i < 100; i++ {
		tasks[i] = Task{
			ID:		fmt.Sprintf("perf_task_%d", i),
			Title:		fmt.Sprintf("Performance Task %d", i),
			Description:	fmt.Sprintf("Description for performance task %d", i),
			Status:		"pending",
			Phase:		fmt.Sprintf("Phase %d", i%5+1),
			Level:		i%3 + 1,
			Priority:	"medium",
			Completed:	false,
			CreatedAt:	time.Now(),
			UpdatedAt:	time.Now(),
		}
	}

	plan := &DynamicPlan{
		ID:	"test_plan_perf",
		Metadata: PlanMetadata{
			Title:		"Performance Test Plan",
			FilePath:	"test/perf_test.md",
		},
		Tasks:		tasks,
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	// Measure storage time
	startTime := time.Now()
	err = storage.StorePlan(plan)
	storageTime := time.Since(startTime)

	if err != nil {
		t.Fatalf("Failed to store performance test plan: %v", err)
	}

	// Measure retrieval time
	startTime = time.Now()
	retrievedPlan, err := storage.GetPlan("test_plan_perf")
	retrievalTime := time.Since(startTime)

	if err != nil {
		t.Fatalf("Failed to retrieve performance test plan: %v", err)
	}

	// Verify data integrity
	if len(retrievedPlan.Tasks) != 100 {
		t.Errorf("Expected 100 tasks, got %d", len(retrievedPlan.Tasks))
	}

	// Performance thresholds (reasonable for 100 tasks)
	maxStorageTime := 5 * time.Second
	maxRetrievalTime := 2 * time.Second

	if storageTime > maxStorageTime {
		t.Errorf("Storage took too long: %v (max: %v)", storageTime, maxStorageTime)
	}

	if retrievalTime > maxRetrievalTime {
		t.Errorf("Retrieval took too long: %v (max: %v)", retrievalTime, maxRetrievalTime)
	}
	t.Logf("✅ SQL storage performance test passed - Storage: %v, Retrieval: %v", storageTime, retrievalTime)
}
