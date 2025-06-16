package integration

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

// Mock manager for testing
type MockManager struct {
	name      string
	isHealthy bool
	err       error
	started   bool
	mu        sync.Mutex
}

func (m *MockManager) Name() string {
	return m.name
}

func (m *MockManager) Status() interfaces.HealthStatus {
	m.mu.Lock()
	defer m.mu.Unlock()
	return interfaces.HealthStatus{
		IsHealthy:    m.isHealthy,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 10 * time.Millisecond,
	}
}

func (m *MockManager) Start(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.err != nil {
		return m.err
	}
	m.started = true
	return nil
}

func (m *MockManager) Stop() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.err != nil {
		return m.err
	}
	m.started = false
	return nil
}

func (m *MockManager) Health() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if !m.isHealthy {
		return errors.New("manager unhealthy")
	}
	return m.err
}

func createTestManagerHub(t *testing.T) *ManagerHub {
	config := &types.ManagersConfig{
		HealthCheckInterval: 100 * time.Millisecond,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
		Managers: map[string]types.ManagerConfig{
			"TestManager1": {Enabled: true, Priority: 1},
			"TestManager2": {Enabled: true, Priority: 2},
			"TestManager3": {Enabled: false, Priority: 3},
		},
	}
	logger := zap.NewNop()

	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create manager hub: %v", err)
	}
	return hub
}

func TestNewManagerHub(t *testing.T) {
	tests := []struct {
		name        string
		config      *types.ManagersConfig
		expectError bool
	}{
		{
			name: "valid config",
			config: &types.ManagersConfig{
				HealthCheckInterval: 30 * time.Second,
				DefaultTimeout:      10 * time.Second,
				MaxRetries:          3,
				Managers: map[string]types.ManagerConfig{
					"TestManager": {Enabled: true, Priority: 1},
				},
			},
			expectError: false,
		},
		{
			name:        "nil config",
			config:      nil,
			expectError: true,
		},
	}

	logger := zap.NewNop()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hub, err := NewManagerHub(tt.config, logger)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if !tt.expectError && hub == nil {
				t.Error("Hub should not be nil")
			}
		})
	}
}

func TestManagerHub_InitializeManagers(t *testing.T) {
	hub := createTestManagerHub(t)

	// Check that all 17 managers are initialized
	expectedManagers := []string{
		"ErrorManager", "StorageManager", "SecurityManager", "MonitoringManager",
		"CacheManager", "ConfigManager", "LogManager", "MetricsManager",
		"HealthManager", "BackupManager", "ValidationManager", "TestManager",
		"DeploymentManager", "NetworkManager", "DatabaseManager", "AuthManager", "APIManager",
	}

	for _, managerName := range expectedManagers {
		if _, exists := hub.managers[managerName]; !exists {
			t.Errorf("Manager '%s' should be initialized", managerName)
		}
		if _, exists := hub.healthStatus[managerName]; !exists {
			t.Errorf("Health status for '%s' should be initialized", managerName)
		}
	}

	if len(hub.managers) != 17 {
		t.Errorf("Expected 17 managers, got %d", len(hub.managers))
	}
}

func TestManagerHub_Start(t *testing.T) {
	hub := createTestManagerHub(t)
	ctx := context.Background()

	// Test successful start
	err := hub.Start(ctx)
	if err != nil {
		t.Errorf("Unexpected error starting hub: %v", err)
	}

	// Test that health monitoring is started
	time.Sleep(150 * time.Millisecond) // Wait for at least one health check

	healthStatuses := hub.GetHealthStatus()
	if len(healthStatuses) == 0 {
		t.Error("Health statuses should be available after start")
	}

	// Cleanup
	hub.Stop()
}

func TestManagerHub_Stop(t *testing.T) {
	hub := createTestManagerHub(t)
	ctx := context.Background()

	hub.Start(ctx)

	err := hub.Stop()
	if err != nil {
		t.Errorf("Unexpected error stopping hub: %v", err)
	}

	// Verify context is cancelled
	select {
	case <-hub.ctx.Done():
		// Expected
	default:
		t.Error("Context should be cancelled after stop")
	}
}

func TestManagerHub_GetManager(t *testing.T) {
	hub := createTestManagerHub(t)

	tests := []struct {
		name        string
		managerName string
		expectError bool
	}{
		{
			name:        "existing manager",
			managerName: "ErrorManager",
			expectError: false,
		},
		{
			name:        "non-existing manager",
			managerName: "NonExistentManager",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			manager, err := hub.GetManager(tt.managerName)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if !tt.expectError && manager == nil {
				t.Error("Manager should not be nil")
			}
		})
	}
}

func TestManagerHub_GetHealthStatus(t *testing.T) {
	hub := createTestManagerHub(t)
	ctx := context.Background()

	hub.Start(ctx)
	defer hub.Stop()

	// Wait for health checks to run
	time.Sleep(150 * time.Millisecond)

	healthStatus := hub.GetHealthStatus()
	if len(healthStatus) == 0 {
		t.Error("Should have health status for managers")
	}

	// Check health status structure
	for name, status := range healthStatus {
		if status.LastCheck.IsZero() {
			t.Errorf("Manager '%s' should have LastCheck set", name)
		}
		if status.ResponseTime < 0 {
			t.Errorf("Manager '%s' should have non-negative ResponseTime", name)
		}
	}
}

func TestManagerHub_GetActiveManagers(t *testing.T) {
	config := &types.ManagersConfig{
		Managers: map[string]types.ManagerConfig{
			"manager1": {Enabled: true, Priority: 1},
			"manager2": {Enabled: true, Priority: 2},
			"manager3": {Enabled: false, Priority: 3},
		},
		HealthCheckInterval: 1 * time.Second,
	}

	logger := zap.NewNop()
	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}
	hub.initializeManagers()

	// Add mock managers manually and set them as healthy
	mockManager1 := &MockManager{name: "manager1", isHealthy: true, err: nil}
	mockManager2 := &MockManager{name: "manager2", isHealthy: true, err: nil}

	hub.managers["manager1"] = mockManager1
	hub.managers["manager2"] = mockManager2

	// Update health status to healthy
	hub.mu.Lock()
	hub.healthStatus["manager1"] = interfaces.HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 5 * time.Millisecond,
	}
	hub.healthStatus["manager2"] = interfaces.HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 5 * time.Millisecond,
	}
	hub.mu.Unlock()

	activeManagers := hub.GetActiveManagers()
	if len(activeManagers) == 0 {
		t.Error("Should have active managers")
	}

	// Should have 2 enabled managers from test config
	if len(activeManagers) != 2 {
		t.Errorf("Expected 2 active managers, got %d", len(activeManagers))
	}
}

func TestManagerHub_ExecuteManagerOperation(t *testing.T) {
	config := &types.ManagersConfig{
		Managers: map[string]types.ManagerConfig{
			"TestManager": {Enabled: true, Priority: 1},
		},
		HealthCheckInterval: 1 * time.Second,
	}

	logger := zap.NewNop()
	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}
	// Manually add a mock manager for testing
	mockManager := &MockManager{
		name:      "TestManager",
		isHealthy: true,
		err:       nil,
	}
	hub.managers["TestManager"] = mockManager

	// Update health status to healthy
	hub.mu.Lock()
	hub.healthStatus["TestManager"] = interfaces.HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 5 * time.Millisecond,
	}
	hub.mu.Unlock()

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	tests := []struct {
		name        string
		managerName string
		operation   string
		params      map[string]interface{}
		expectError bool
	}{
		{
			name:        "valid operation",
			managerName: "TestManager",
			operation:   "cleanup",
			params:      map[string]interface{}{"target": "temp_files"},
			expectError: false,
		},
		{
			name:        "invalid manager",
			managerName: "InvalidManager",
			operation:   "test",
			params:      map[string]interface{}{},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := hub.ExecuteManagerOperation(tt.managerName, tt.operation, tt.params)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
			if !tt.expectError && result == nil {
				t.Error("Result should not be nil for successful operation")
			}
		})
	}
}

func TestManagerHub_HealthMonitoring(t *testing.T) {
	// Create hub with shorter health check interval for testing
	config := &types.ManagersConfig{
		HealthCheckInterval: 50 * time.Millisecond,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
		Managers: map[string]types.ManagerConfig{
			"TestManager": {Enabled: true, Priority: 1},
		},
	}
	logger := zap.NewNop()

	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}

	// Replace one manager with a mock that can simulate health changes
	mockManager := &MockManager{
		name:      "TestManager",
		isHealthy: true,
		err:       nil,
	}
	hub.managers["TestManager"] = mockManager

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	// Wait for initial health check
	time.Sleep(100 * time.Millisecond)

	status := hub.GetHealthStatus()["TestManager"]
	if !status.IsHealthy {
		t.Error("Manager should be healthy initially")
	}

	// Make manager unhealthy
	mockManager.mu.Lock()
	mockManager.isHealthy = false
	mockManager.mu.Unlock()

	// Wait for health check to detect the change
	time.Sleep(100 * time.Millisecond)

	status = hub.GetHealthStatus()["TestManager"]
	if status.IsHealthy {
		t.Error("Health monitoring should detect unhealthy manager")
	}
}

func TestManagerHub_ConcurrentOperations(t *testing.T) {
	config := &types.ManagersConfig{
		Managers: map[string]types.ManagerConfig{
			"TestManager": {Enabled: true, Priority: 1},
		},
		HealthCheckInterval: 1 * time.Second,
	}

	logger := zap.NewNop()
	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}

	// Add mock manager
	mockManager := &MockManager{
		name:      "TestManager",
		isHealthy: true,
		err:       nil,
	}
	hub.managers["TestManager"] = mockManager

	// Update health status to healthy
	hub.mu.Lock()
	hub.healthStatus["TestManager"] = interfaces.HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 5 * time.Millisecond,
	}
	hub.mu.Unlock()

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	numOperations := 10
	results := make(chan error, numOperations)

	// Run concurrent operations
	for i := 0; i < numOperations; i++ {
		go func(id int) {
			_, err := hub.ExecuteManagerOperation("TestManager", "test_op", map[string]interface{}{
				"operation_id": id,
			})
			results <- err
		}(i)
	}

	// Collect results
	for i := 0; i < numOperations; i++ {
		err := <-results
		if err != nil {
			t.Errorf("Concurrent operation %d failed: %v", i, err)
		}
	}
}

func TestManagerHub_PerformanceCompliance(t *testing.T) {
	config := &types.ManagersConfig{
		Managers: map[string]types.ManagerConfig{
			"TestManager": {Enabled: true, Priority: 1},
		},
		HealthCheckInterval: 1 * time.Second,
	}

	logger := zap.NewNop()
	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}
	// Add mock manager
	mockManager := &MockManager{
		name:      "TestManager",
		isHealthy: true,
		err:       nil,
	}
	hub.managers["TestManager"] = mockManager

	// Update health status to healthy
	hub.mu.Lock()
	hub.healthStatus["TestManager"] = interfaces.HealthStatus{
		IsHealthy:    true,
		LastCheck:    time.Now(),
		ErrorMessage: "",
		ResponseTime: 5 * time.Millisecond,
	}
	hub.mu.Unlock()

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	// Test operation latency
	operations := []struct {
		managerName string
		operation   string
	}{
		{"TestManager", "status"},
		{"TestManager", "check"},
		{"TestManager", "get"},
	}

	for _, op := range operations {
		startTime := time.Now()
		_, err := hub.ExecuteManagerOperation(op.managerName, op.operation, map[string]interface{}{})
		duration := time.Since(startTime)

		if err != nil {
			t.Errorf("Operation %s.%s failed: %v", op.managerName, op.operation, err)
		}
		if duration > 100*time.Millisecond {
			t.Errorf("Operation %s.%s took %v, exceeds 100ms FMOUA requirement",
				op.managerName, op.operation, duration)
		}
	}
}

func TestManagerHub_StartTimeout(t *testing.T) {
	// Create a mock manager that takes too long to start
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
		Managers: map[string]types.ManagerConfig{
			"SlowManager": {Enabled: true, Priority: 1},
		},
	}
	logger := zap.NewNop()

	hub, err := NewManagerHub(config, logger)
	if err != nil {
		t.Fatalf("Failed to create hub: %v", err)
	}

	// This test would need actual slow-starting managers to be meaningful
	// For now, we just verify that the timeout mechanism is in place
	ctx := context.Background()
	err = hub.Start(ctx)
	// Should not timeout with mock managers that start quickly
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}

	hub.Stop()
}

func TestManagerHub_ManagerIntegration(t *testing.T) {
	hub := createTestManagerHub(t)

	// Verify all 17 managers are properly integrated
	expectedManagers := map[string]bool{
		"ErrorManager":      true,
		"StorageManager":    true,
		"SecurityManager":   true,
		"MonitoringManager": true,
		"CacheManager":      true,
		"ConfigManager":     true,
		"LogManager":        true,
		"MetricsManager":    true,
		"HealthManager":     true,
		"BackupManager":     true,
		"ValidationManager": true,
		"TestManager":       true,
		"DeploymentManager": true,
		"NetworkManager":    true,
		"DatabaseManager":   true,
		"AuthManager":       true,
		"APIManager":        true,
	}

	for managerName := range expectedManagers {
		manager, err := hub.GetManager(managerName)
		if err != nil {
			t.Errorf("Manager '%s' should be available: %v", managerName, err)
		}
		if manager == nil {
			t.Errorf("Manager '%s' should not be nil", managerName)
		} // Managers are wrapped in proxies, so names include "-proxy" suffix
		expectedName := managerName + "-proxy"
		if manager.Name() != expectedName {
			t.Errorf("Manager name mismatch: expected '%s', got '%s'", expectedName, manager.Name())
		}
	}
}

func BenchmarkManagerHub_ExecuteManagerOperation(b *testing.B) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 100 * time.Millisecond,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
		Managers: map[string]types.ManagerConfig{
			"TestManager1": {Enabled: true, Priority: 1},
			"TestManager2": {Enabled: true, Priority: 2},
			"TestManager3": {Enabled: false, Priority: 3},
		},
	}
	logger := zap.NewNop()

	hub, err := NewManagerHub(config, logger)
	if err != nil {
		b.Fatalf("Failed to create manager hub: %v", err)
	}

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		hub.ExecuteManagerOperation("StorageManager", "benchmark_op", map[string]interface{}{
			"iteration": i,
		})
	}
}

func BenchmarkManagerHub_GetHealthStatus(b *testing.B) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 100 * time.Millisecond,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
		Managers: map[string]types.ManagerConfig{
			"TestManager1": {Enabled: true, Priority: 1},
			"TestManager2": {Enabled: true, Priority: 2},
			"TestManager3": {Enabled: false, Priority: 3},
		},
	}
	logger := zap.NewNop()

	hub, err := NewManagerHub(config, logger)
	if err != nil {
		b.Fatalf("Failed to create manager hub: %v", err)
	}

	ctx := context.Background()
	hub.Start(ctx)
	defer hub.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		hub.GetHealthStatus()
	}
}
