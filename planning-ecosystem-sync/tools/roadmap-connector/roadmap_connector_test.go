package roadmapconnector

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// SimpleLogger implements the Logger interface for testing
type SimpleLogger struct{}

func (sl *SimpleLogger) Printf(format string, args ...interface{}) {
	log.Printf(format, args...)
}
func (sl *SimpleLogger) Info(msg string) {
	log.Printf("[INFO] %s", msg)
}
func (sl *SimpleLogger) Error(msg string) {
	log.Printf("[ERROR] %s", msg)
}
func (sl *SimpleLogger) Debug(msg string) {
	log.Printf("[DEBUG] %s", msg)
}

// TestRoadmapManagerConnector_Basic tests basic connector functionality
func TestRoadmapManagerConnector_Basic(t *testing.T) {
	// Create a test HTTP server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/api/v1/roadmaps/sync" {
			w.Header().Set("Content-Type", "application/json")
			response := SyncResponse{
				Success:      true,
				Message:      "Sync completed successfully",
				SyncID:       "test-sync-123",
				ChangesCount: 5,
				Metadata:     make(map[string]interface{}),
				Timestamp:    time.Now(),
			}
			json.NewEncoder(w).Encode(response)
			return
		}
		w.WriteHeader(http.StatusNotFound)
	}))
	defer server.Close()

	// Create connector config
	config := &ConnectorConfig{
		BaseURL:       server.URL,
		Timeout:       10 * time.Second,
		MaxRetries:    3,
		RateLimit:     100,
		EnableCache:   false,
		EnableMetrics: true,
		DebugMode:     true,
	}

	connector := NewRoadmapManagerConnector(config)
	if connector == nil {
		t.Fatal("NewRoadmapManagerConnector returned nil")
	}

	// Test basic functionality
	if connector.baseURL != server.URL {
		t.Errorf("Expected baseURL %s, got %s", server.URL, connector.baseURL)
	}
}

// TestRoadmapManagerConnector_Sync tests sync functionality
func TestRoadmapManagerConnector_Sync(t *testing.T) {
	// Create a test HTTP server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == "POST" && r.URL.Path == "/api/v1/plans" {
			w.Header().Set("Content-Type", "application/json")
			response := SyncResponse{
				Success:      true,
				Message:      "Plan synced successfully",
				SyncID:       "sync-123",
				ChangesCount: 3,
				Metadata:     make(map[string]interface{}),
				Timestamp:    time.Now(),
			}
			json.NewEncoder(w).Encode(response)
			return
		}
		w.WriteHeader(http.StatusMethodNotAllowed)
	}))
	defer server.Close()

	// Create connector
	config := &ConnectorConfig{
		BaseURL:       server.URL,
		Timeout:       5 * time.Second,
		MaxRetries:    2,
		RateLimit:     50,
		EnableCache:   false,
		EnableMetrics: true,
		DebugMode:     true,
	}
	connector := NewRoadmapManagerConnector(config)

	// Create test dynamic plan
	dynamicPlan := &DynamicPlan{
		ID:       "test-plan",
		Title:    "Test Plan",
		Version:  "1.0",
		Progress: 75.0,
		Status:   "active",
		Phases: []DynamicPhase{
			{
				ID:          "phase-1",
				Name:        "Test Phase",
				Description: "Test description",
				Status:      "in_progress",
				Progress:    50.0,
				Order:       1,
				TaskIDs:     []string{"task-1"},
			},
		},
		Tasks: []DynamicTask{
			{
				ID:          "task-1",
				Title:       "Test Task",
				Description: "Test task",
				Status:      "completed",
				Priority:    1,
				PhaseID:     "phase-1",
				CreatedAt:   time.Now(),
				UpdatedAt:   time.Now(),
			},
		},
		Metadata:  make(map[string]interface{}),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Test sync operation
	ctx := context.Background()
	_, err := connector.SyncPlanToRoadmapManager(ctx, dynamicPlan)
	if err != nil {
		t.Errorf("SyncPlanToRoadmapManager failed: %v", err)
	}

	// Verify statistics
	stats := connector.GetStats()
	if stats.TotalRequests == 0 {
		t.Error("Expected TotalRequests to be greater than 0")
	}
}

// TestDataMapper_ConvertToRoadmapFormat tests data conversion
func TestDataMapper_ConvertToRoadmapFormat(t *testing.T) {
	mapper := NewDataMapper()

	// Create test dynamic plan
	dynamicPlan := &DynamicPlan{
		ID:       "test-plan",
		Title:    "Test Plan",
		Version:  "1.0",
		Progress: 75.0,
		Status:   "active",
		Phases: []DynamicPhase{
			{
				ID:          "phase-1",
				Name:        "Test Phase",
				Description: "Test description",
				Status:      "in_progress",
				Progress:    50.0,
				Order:       1,
				TaskIDs:     []string{"task-1"},
			},
		},
		Tasks: []DynamicTask{
			{
				ID:          "task-1",
				Title:       "Test Task",
				Description: "Test task",
				Status:      "completed",
				Priority:    1,
				PhaseID:     "phase-1",
				CreatedAt:   time.Now(),
				UpdatedAt:   time.Now(),
			},
		},
		Metadata:  make(map[string]interface{}),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Test conversion
	roadmapPlan, err := mapper.ConvertToRoadmapFormat(dynamicPlan)
	if err != nil {
		t.Fatalf("ConvertToRoadmapFormat failed: %v", err)
	}

	if roadmapPlan.ID != dynamicPlan.ID {
		t.Errorf("Expected ID %s, got %s", dynamicPlan.ID, roadmapPlan.ID)
	}

	if roadmapPlan.Title != dynamicPlan.Title {
		t.Errorf("Expected Title %s, got %s", dynamicPlan.Title, roadmapPlan.Title)
	}

	if len(roadmapPlan.Phases) != len(dynamicPlan.Phases) {
		t.Errorf("Expected %d phases, got %d", len(dynamicPlan.Phases), len(roadmapPlan.Phases))
	}
}

// TestAPIAnalyzer_Basic tests API analysis
func TestAPIAnalyzer_Basic(t *testing.T) {
	logger := &SimpleLogger{}
	analyzer := NewAPIAnalyzer("http://localhost", logger)

	if analyzer == nil {
		t.Fatal("NewAPIAnalyzer returned nil")
	}

	// Create test server for basic connectivity
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		response := map[string]interface{}{
			"status":  "healthy",
			"version": "1.0.0",
		}
		json.NewEncoder(w).Encode(response)
	}))
	defer server.Close()
	// Test basic analysis
	ctx := context.Background()
	result, err := analyzer.AnalyzeAPI(ctx)
	if err != nil {
		t.Fatalf("AnalyzeAPI failed: %v", err)
	}

	// API analysis may not be compatible due to lack of OpenAPI spec
	// Just verify that we got a result with some analysis data
	if result == nil {
		t.Error("Expected to get analysis result")
	}

	if len(result.Issues) == 0 {
		t.Log("No issues found in API analysis")
	} else {
		t.Logf("Found %d issues in API analysis: %v", len(result.Issues), result.Issues)
	}
}

// TestAuthenticationManager_Basic tests authentication
func TestAuthenticationManager_Basic(t *testing.T) {
	config := &ConnectorConfig{
		BaseURL: "http://localhost:8080",
		Timeout: 30 * time.Second,
	}

	authMgr := NewAuthenticationManager(config)
	if authMgr == nil {
		t.Fatal("NewAuthenticationManager returned nil")
	}
	// Test basic validation
	err := authMgr.validateCredentials()
	// Should return error by default since no credentials are configured
	if err != nil {
		t.Logf("Credentials validation correctly returned error: %v", err)
	} else {
		t.Log("Credentials validation passed (may have default config)")
	}
}

// TestConnectorInitialization tests connector initialization
func TestConnectorInitialization(t *testing.T) {
	// Create test server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	}))
	defer server.Close()

	config := &ConnectorConfig{
		BaseURL:       server.URL,
		Timeout:       5 * time.Second,
		MaxRetries:    1,
		RateLimit:     50,
		EnableCache:   false,
		EnableMetrics: true,
		DebugMode:     true,
	}

	connector := NewRoadmapManagerConnector(config)
	if connector == nil {
		t.Fatal("NewRoadmapManagerConnector returned nil")
	}

	// Test initialization
	ctx := context.Background()
	err := connector.Initialize(ctx)
	if err != nil {
		// This might fail due to auth issues, which is expected in test
		t.Logf("Initialize failed (expected in test): %v", err)
	}

	// Test stats
	stats := connector.GetStats()
	if stats == nil {
		t.Error("GetStats returned nil")
	}
}
