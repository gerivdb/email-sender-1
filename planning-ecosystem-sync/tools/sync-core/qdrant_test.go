package sync_core

import (
	"testing"
	"time"

	"go.uber.org/zap/zaptest"
)

func TestSyncClient_NewSyncClient(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	if client == nil {
		t.Fatal("Client should not be nil")
	}

	if client.logger != logger {
		t.Error("Logger not properly set")
	}
}

func TestSyncClient_HealthCheck(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	// Test health check with mock client
	if err := client.HealthCheck(); err != nil {
		t.Errorf("Health check should not fail with mock client: %v", err)
	}
}

func TestSyncClient_StorePlanEmbeddings(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	// Create test plan
	plan := &DynamicPlan{
		ID:		"test-plan-123",
		Embeddings:	[]float64{0.1, 0.2, 0.3, 0.4, 0.5},
		Metadata: PlanMetadata{
			Title:		"Test Plan",
			Version:	"1.0.0",
			FilePath:	"/test/plan.md",
			Progression:	0.5,
			Description:	"Test plan description",
		},
		Tasks:		[]Task{},
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	// Test storing embeddings
	if err := client.StorePlanEmbeddings(plan); err != nil {
		t.Errorf("Failed to store plan embeddings: %v", err)
	}
}

func TestSyncClient_StorePlanEmbeddings_EmptyEmbeddings(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	// Create plan with no embeddings
	plan := &DynamicPlan{
		ID:		"test-plan-no-embeddings",
		Embeddings:	[]float64{},	// Empty embeddings
		Metadata: PlanMetadata{
			Title: "Test Plan No Embeddings",
		},
		CreatedAt:	time.Now(),
		UpdatedAt:	time.Now(),
	}

	// Should return error for empty embeddings
	if err := client.StorePlanEmbeddings(plan); err == nil {
		t.Error("Expected error for plan with no embeddings")
	}
}

func TestSyncClient_SearchSimilarPlans(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	queryVector := []float32{0.1, 0.2, 0.3, 0.4, 0.5}
	limit := 10

	response, err := client.SearchSimilarPlans(queryVector, limit)
	if err != nil {
		t.Errorf("Failed to search similar plans: %v", err)
	}

	if response == nil {
		t.Error("Response should not be nil")
	}
}

func TestSyncClient_SyncPlanData(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	// Create test plans
	plans := []*DynamicPlan{
		{
			ID:		"plan-1",
			Embeddings:	[]float64{0.1, 0.2, 0.3},
			Metadata: PlanMetadata{
				Title:		"Plan 1",
				Description:	"First test plan",
			},
			CreatedAt:	time.Now(),
			UpdatedAt:	time.Now(),
		},
		{
			ID:		"plan-2",
			Embeddings:	[]float64{0.4, 0.5, 0.6},
			Metadata: PlanMetadata{
				Title:		"Plan 2",
				Description:	"Second test plan",
			},
			CreatedAt:	time.Now(),
			UpdatedAt:	time.Now(),
		},
	}

	// Test syncing plans
	if err := client.SyncPlanData(plans); err != nil {
		t.Errorf("Failed to sync plan data: %v", err)
	}
}

func TestSyncClient_SyncPlanData_ValidationError(t *testing.T) {
	logger := zaptest.NewLogger(t)

	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		t.Fatalf("Failed to create sync client: %v", err)
	}

	// Create plans with validation issues
	plans := []*DynamicPlan{
		{
			ID:		"",	// Missing ID
			Embeddings:	[]float64{0.1, 0.2, 0.3},
			Metadata: PlanMetadata{
				Title: "Plan with no ID",
			},
		},
		{
			ID:		"plan-no-embeddings",
			Embeddings:	[]float64{},	// No embeddings
			Metadata: PlanMetadata{
				Title: "Plan with no embeddings",
			},
		},
	}

	// Should return validation error
	if err := client.SyncPlanData(plans); err == nil {
		t.Error("Expected validation error for invalid plans")
	}
}
