package interfaces

import (
	"context"
	"testing"
	"time"
)

// Mock implementations for testing

type MockManager struct {
	name      string
	isHealthy bool
	err       error
}

func (m *MockManager) Name() string {
	return m.name
}

func (m *MockManager) Status() HealthStatus {
	return HealthStatus{
		IsHealthy:    m.isHealthy,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 10 * time.Millisecond,
	}
}

func (m *MockManager) Start(ctx context.Context) error {
	return m.err
}

func (m *MockManager) Stop() error {
	return m.err
}

func (m *MockManager) Health() error {
	return m.err
}

type MockManagerHub struct {
	managers map[string]Manager
	err      error
}

func (h *MockManagerHub) Start(ctx context.Context) error {
	return h.err
}

func (h *MockManagerHub) Stop() error {
	return h.err
}

func (h *MockManagerHub) GetManager(name string) (Manager, error) {
	if manager, exists := h.managers[name]; exists {
		return manager, nil
	}
	return nil, h.err
}

func (h *MockManagerHub) GetHealthStatus() map[string]HealthStatus {
	status := make(map[string]HealthStatus)
	for name, manager := range h.managers {
		status[name] = manager.Status()
	}
	return status
}

func (h *MockManagerHub) GetActiveManagers() []string {
	var active []string
	for name := range h.managers {
		active = append(active, name)
	}
	return active
}

func (h *MockManagerHub) ExecuteManagerOperation(managerName, operation string, params map[string]interface{}) (interface{}, error) {
	if h.err != nil {
		return nil, h.err
	}
	return "operation_result", nil
}

type MockIntelligenceEngine struct {
	err   error
	stats *PerformanceStats
}

func (e *MockIntelligenceEngine) Start(ctx context.Context) error {
	return e.err
}

func (e *MockIntelligenceEngine) Stop() error {
	return e.err
}

func (e *MockIntelligenceEngine) AnalyzeRepository(repoPath string) (*AIDecision, error) {
	if e.err != nil {
		return nil, e.err
	}
	return &AIDecision{
		ID:             "test_decision",
		Type:           DecisionOrganization,
		Confidence:     0.9,
		Recommendation: "Test recommendation",
		Actions:        []RecommendedAction{},
		Reasoning:      "Test reasoning",
		Timestamp:      time.Now(),
		ExecutionTime:  50 * time.Millisecond,
		Metadata:       map[string]interface{}{"test": "value"},
	}, nil
}

func (e *MockIntelligenceEngine) MakeOrganizationDecision(context map[string]interface{}) (*AIDecision, error) {
	if e.err != nil {
		return nil, e.err
	}
	return &AIDecision{
		ID:             "org_decision",
		Type:           DecisionOrganization,
		Confidence:     0.85,
		Recommendation: "Reorganize by domain",
		Actions:        []RecommendedAction{},
		Reasoning:      "Code organization can be improved",
		Timestamp:      time.Now(),
		ExecutionTime:  75 * time.Millisecond,
		Metadata:       context,
	}, nil
}

func (e *MockIntelligenceEngine) OptimizePerformance(metrics map[string]interface{}) (*AIDecision, error) {
	if e.err != nil {
		return nil, e.err
	}
	return &AIDecision{
		ID:             "perf_decision",
		Type:           DecisionPerformance,
		Confidence:     0.95,
		Recommendation: "Enable caching",
		Actions:        []RecommendedAction{},
		Reasoning:      "Cache hit rate is low",
		Timestamp:      time.Now(),
		ExecutionTime:  30 * time.Millisecond,
		Metadata:       metrics,
	}, nil
}

func (e *MockIntelligenceEngine) GetPerformanceStats() *PerformanceStats {
	if e.stats != nil {
		return e.stats
	}
	return &PerformanceStats{
		TotalRequests:     100,
		AverageLatency:    50 * time.Millisecond,
		SuccessRate:       0.95,
		CacheHitRate:      0.8,
		LastResponseTime:  45 * time.Millisecond,
		LatencyUnder100ms: 95,
	}
}

// Tests for interface implementations

func TestManagerInterface(t *testing.T) {
	manager := &MockManager{
		name:      "test_manager",
		isHealthy: true,
		err:       nil,
	}

	if manager.Name() != "test_manager" {
		t.Errorf("Expected name 'test_manager', got '%s'", manager.Name())
	}

	status := manager.Status()
	if !status.IsHealthy {
		t.Error("Manager should be healthy")
	}
	if status.ResponseTime <= 0 {
		t.Error("Response time should be positive")
	}

	ctx := context.Background()
	if err := manager.Start(ctx); err != nil {
		t.Errorf("Unexpected error starting manager: %v", err)
	}

	if err := manager.Stop(); err != nil {
		t.Errorf("Unexpected error stopping manager: %v", err)
	}

	if err := manager.Health(); err != nil {
		t.Errorf("Unexpected error checking health: %v", err)
	}
}

func TestManagerHubInterface(t *testing.T) {
	hub := &MockManagerHub{
		managers: map[string]Manager{
			"test_manager": &MockManager{name: "test_manager", isHealthy: true},
		},
		err: nil,
	}

	ctx := context.Background()
	if err := hub.Start(ctx); err != nil {
		t.Errorf("Unexpected error starting hub: %v", err)
	}

	manager, err := hub.GetManager("test_manager")
	if err != nil {
		t.Errorf("Unexpected error getting manager: %v", err)
	}
	if manager.Name() != "test_manager" {
		t.Errorf("Expected manager name 'test_manager', got '%s'", manager.Name())
	}

	status := hub.GetHealthStatus()
	if len(status) == 0 {
		t.Error("Should have at least one manager status")
	}

	active := hub.GetActiveManagers()
	if len(active) == 0 {
		t.Error("Should have at least one active manager")
	}

	result, err := hub.ExecuteManagerOperation("test_manager", "test_op", map[string]interface{}{})
	if err != nil {
		t.Errorf("Unexpected error executing operation: %v", err)
	}
	if result != "operation_result" {
		t.Errorf("Expected 'operation_result', got '%v'", result)
	}

	if err := hub.Stop(); err != nil {
		t.Errorf("Unexpected error stopping hub: %v", err)
	}
}

func TestIntelligenceEngineInterface(t *testing.T) {
	engine := &MockIntelligenceEngine{
		err: nil,
		stats: &PerformanceStats{
			TotalRequests:     50,
			AverageLatency:    40 * time.Millisecond,
			SuccessRate:       0.98,
			CacheHitRate:      0.85,
			LastResponseTime:  35 * time.Millisecond,
			LatencyUnder100ms: 50,
		},
	}

	ctx := context.Background()
	if err := engine.Start(ctx); err != nil {
		t.Errorf("Unexpected error starting engine: %v", err)
	}

	decision, err := engine.AnalyzeRepository("/test/repo")
	if err != nil {
		t.Errorf("Unexpected error analyzing repository: %v", err)
	}
	if decision.Type != DecisionOrganization {
		t.Errorf("Expected DecisionOrganization, got %v", decision.Type)
	}
	if decision.Confidence <= 0 {
		t.Error("Confidence should be positive")
	}

	orgDecision, err := engine.MakeOrganizationDecision(map[string]interface{}{"test": "context"})
	if err != nil {
		t.Errorf("Unexpected error making organization decision: %v", err)
	}
	if orgDecision.Type != DecisionOrganization {
		t.Errorf("Expected DecisionOrganization, got %v", orgDecision.Type)
	}

	perfDecision, err := engine.OptimizePerformance(map[string]interface{}{"metric": "value"})
	if err != nil {
		t.Errorf("Unexpected error optimizing performance: %v", err)
	}
	if perfDecision.Type != DecisionPerformance {
		t.Errorf("Expected DecisionPerformance, got %v", perfDecision.Type)
	}

	stats := engine.GetPerformanceStats()
	if stats.TotalRequests != 50 {
		t.Errorf("Expected 50 total requests, got %d", stats.TotalRequests)
	}
	if stats.SuccessRate != 0.98 {
		t.Errorf("Expected success rate 0.98, got %f", stats.SuccessRate)
	}

	if err := engine.Stop(); err != nil {
		t.Errorf("Unexpected error stopping engine: %v", err)
	}
}

func TestHealthStatus(t *testing.T) {
	status := HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 25 * time.Millisecond,
	}

	if !status.IsHealthy {
		t.Error("Status should be healthy")
	}
	if status.ResponseTime <= 0 {
		t.Error("Response time should be positive")
	}
	if status.ErrorMessage != "" {
		t.Error("Error message should be empty for healthy status")
	}
}

func TestAIDecision(t *testing.T) {
	actions := []RecommendedAction{
		{
			Type:       "move_file",
			Target:     "/src/file.go",
			Parameters: map[string]interface{}{"destination": "/pkg/file.go"},
			Priority:   1,
			Risk:       "low",
			Impact:     "positive",
		},
	}

	decision := AIDecision{
		ID:             "test_decision_001",
		Type:           DecisionOrganization,
		Confidence:     0.92,
		Recommendation: "Move file to appropriate package",
		Actions:        actions,
		Reasoning:      "File belongs to pkg domain based on imports",
		Timestamp:      time.Now(),
		ExecutionTime:  60 * time.Millisecond,
		Metadata:       map[string]interface{}{"file_count": 1},
	}

	if decision.ID == "" {
		t.Error("Decision ID should not be empty")
	}
	if decision.Confidence <= 0 || decision.Confidence > 1 {
		t.Error("Confidence should be between 0 and 1")
	}
	if len(decision.Actions) == 0 {
		t.Error("Should have at least one action")
	}
	if decision.ExecutionTime <= 0 {
		t.Error("Execution time should be positive")
	}
}

func TestDecisionTypes(t *testing.T) {
	types := []DecisionType{
		DecisionOrganization,
		DecisionOptimization,
		DecisionCleaning,
		DecisionMaintenance,
		DecisionSecurity,
		DecisionPerformance,
		DecisionArchitecture,
	}

	for _, dt := range types {
		if string(dt) == "" {
			t.Errorf("Decision type %v should not be empty", dt)
		}
	}
}

func TestRecommendedAction(t *testing.T) {
	action := RecommendedAction{
		Type:       "create_directory",
		Target:     "/pkg/new_domain",
		Parameters: map[string]interface{}{"mode": "0755"},
		Priority:   2,
		Risk:       "low",
		Impact:     "positive",
	}

	if action.Type == "" {
		t.Error("Action type should not be empty")
	}
	if action.Target == "" {
		t.Error("Action target should not be empty")
	}
	if action.Priority <= 0 {
		t.Error("Action priority should be positive")
	}
}

func TestPerformanceStats(t *testing.T) {
	stats := PerformanceStats{
		TotalRequests:     1000,
		AverageLatency:    45 * time.Millisecond,
		SuccessRate:       0.99,
		CacheHitRate:      0.75,
		LastResponseTime:  40 * time.Millisecond,
		LatencyUnder100ms: 995,
	}

	if stats.TotalRequests <= 0 {
		t.Error("Total requests should be positive")
	}
	if stats.SuccessRate <= 0 || stats.SuccessRate > 1 {
		t.Error("Success rate should be between 0 and 1")
	}
	if stats.CacheHitRate < 0 || stats.CacheHitRate > 1 {
		t.Error("Cache hit rate should be between 0 and 1")
	}
	if stats.LatencyUnder100ms > stats.TotalRequests {
		t.Error("Latency under 100ms cannot exceed total requests")
	}
}
