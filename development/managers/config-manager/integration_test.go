package configmanager

import (
	"sync"
	"testing"
)

// MockIntegrationManager implements IntegrationManager for testing
type MockIntegrationManager struct {
	configManager ConfigManager
	errorLog      []ErrorLogEntry
	mu            sync.Mutex
}

type ErrorLogEntry struct {
	Module  string
	Error   error
	Context map[string]interface{}
}

func NewMockIntegrationManager() *MockIntegrationManager {
	return &MockIntegrationManager{
		errorLog: make([]ErrorLogEntry, 0),
	}
}

func (m *MockIntegrationManager) InitializeConfigManager() (ConfigManager, error) {
	cm, err := New()
	if err != nil {
		return nil, err
	}
	m.configManager = cm
	return cm, nil
}

func (m *MockIntegrationManager) GetConfigManager() ConfigManager {
	return m.configManager
}

func (m *MockIntegrationManager) PropagateError(module string, err error, context map[string]interface{}) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.errorLog = append(m.errorLog, ErrorLogEntry{
		Module:  module,
		Error:   err,
		Context: context,
	})
}

func (m *MockIntegrationManager) GetErrorLog() []ErrorLogEntry {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]ErrorLogEntry{}, m.errorLog...)
}

func (m *MockIntegrationManager) ClearErrorLog() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.errorLog = make([]ErrorLogEntry, 0)
}

// Test Integration Manager Creation
func TestNewIntegratedConfigManager(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	if icm == nil {
		t.Fatal("IntegratedConfigManager is nil")
	}

	if icm.IsInitialized() {
		t.Error("IntegratedConfigManager should not be initialized yet")
	}
}

// Test Integration Manager Initialization
func TestIntegratedConfigManagerInitialization(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	// Initialize the config manager
	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	if !icm.IsInitialized() {
		t.Error("IntegratedConfigManager should be initialized")
	}

	// Test that config manager is accessible
	cm := icm.GetConfigManager()
	if cm == nil {
		t.Error("ConfigManager should not be nil after initialization")
	}

	// Test default values are set
	appName, err := cm.GetString("app.name")
	if err != nil {
		t.Errorf("Failed to get app.name: %v", err)
	}

	expected := "EMAIL_SENDER_1"
	if appName != expected {
		t.Errorf("Expected app.name to be '%s', got '%s'", expected, appName)
	}
}

// Test Manager Configuration Retrieval
func TestGetManagerConfig(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Test getting configuration for config-manager
	config, err := icm.GetManagerConfig("config_manager")
	if err != nil {
		t.Errorf("Failed to get config for config_manager: %v", err)
	}

	if config == nil {
		t.Error("Manager config should not be nil")
	}

	// Check if enabled is set correctly
	enabled, ok := config["enabled"].(bool)
	if !ok {
		t.Error("Expected enabled to be a boolean")
	}

	if !enabled {
		t.Error("config_manager should be enabled by default")
	}
}

// Test Manager Config File Loading
func TestLoadManagerConfigFile(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Try to load a config file (should handle missing file gracefully)
	err = icm.LoadManagerConfigFile("test-manager", "non-existent-config.json")
	if err == nil {
		t.Error("Expected error for non-existent config file")
	}

	// Check that error was propagated
	errorLog := mockIM.GetErrorLog()
	found := false
	for _, entry := range errorLog {
		if entry.Module == "config-manager" && entry.Context["operation"] == "load_manager_config" {
			found = true
			break
		}
	}

	if !found {
		t.Error("Expected error to be propagated to integration manager")
	}
}

// Test Manager Config Validation
func TestValidateManagerConfig(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Test validation with existing keys (should pass)
	err = icm.ValidateManagerConfig("config_manager", []string{"enabled"})
	if err != nil {
		t.Errorf("Validation should pass for existing keys: %v", err)
	}

	// Test validation with missing keys (should fail)
	err = icm.ValidateManagerConfig("config_manager", []string{"missing_key"})
	if err == nil {
		t.Error("Expected validation to fail for missing keys")
	}
}

// Test Error Propagation During Initialization
func TestErrorPropagationDuringInit(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	// Create a custom IntegratedConfigManager that will fail during validation
	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	// Initialize normally first
	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Manually test error propagation by triggering a validation error
	cm := icm.GetConfigManager()
	cm.SetRequiredKeys([]string{"non.existent.key"})

	err = cm.Validate()
	if err == nil {
		t.Error("Expected validation to fail")
	}

	// Simulate error propagation
	mockIM.PropagateError("config-manager", err, map[string]interface{}{
		"operation": "test_validation",
		"phase":     "manual_test",
	})

	// Check error log
	errorLog := mockIM.GetErrorLog()
	if len(errorLog) == 0 {
		t.Error("Expected at least one error in log")
	}

	found := false
	for _, entry := range errorLog {
		if entry.Module == "config-manager" && entry.Context["operation"] == "test_validation" {
			found = true
			break
		}
	}

	if !found {
		t.Error("Expected test validation error in log")
	}
}

// Test Integration with Nil Integration Manager
func TestIntegrationWithNilManager(t *testing.T) {
	icm, err := NewIntegratedConfigManager(nil)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager with nil integration manager: %v", err)
	}

	// Should still initialize successfully
	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager with nil integration manager: %v", err)
	}

	// Should still work normally
	cm := icm.GetConfigManager()
	if cm == nil {
		t.Error("ConfigManager should not be nil")
	}

	appName, err := cm.GetString("app.name")
	if err != nil {
		t.Errorf("Failed to get app.name: %v", err)
	}

	if appName != "EMAIL_SENDER_1" {
		t.Errorf("Expected app.name to be 'EMAIL_SENDER_1', got '%s'", appName)
	}
}

// Test Multiple Initialization Calls
func TestMultipleInitialization(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	// First initialization
	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Second initialization should be idempotent
	err = icm.Initialize()
	if err != nil {
		t.Errorf("Second initialization should not fail: %v", err)
	}

	// Should still be initialized
	if !icm.IsInitialized() {
		t.Error("IntegratedConfigManager should still be initialized")
	}
}

// Test Integration Scenario with Other Managers
func TestIntegrationScenario(t *testing.T) {
	mockIM := NewMockIntegrationManager()

	icm, err := NewIntegratedConfigManager(mockIM)
	if err != nil {
		t.Fatalf("Failed to create IntegratedConfigManager: %v", err)
	}

	err = icm.Initialize()
	if err != nil {
		t.Fatalf("Failed to initialize IntegratedConfigManager: %v", err)
	}

	// Simulate other managers requesting configuration
	managers := []string{
		"error_manager",
		"dependency_manager",
		"process_manager",
		"script_manager",
		"roadmap_manager",
		"mode_manager",
	}

	for _, managerName := range managers {
		config, err := icm.GetManagerConfig(managerName)
		if err != nil {
			t.Errorf("Failed to get config for %s: %v", managerName, err)
			continue
		}

		if config == nil {
			t.Errorf("Config for %s should not be nil", managerName)
			continue
		}

		// Each manager should be enabled by default
		enabled, ok := config["enabled"].(bool)
		if !ok {
			t.Errorf("Expected enabled to be boolean for %s", managerName)
			continue
		}

		if !enabled {
			t.Errorf("Manager %s should be enabled by default", managerName)
		}
	}

	// Test database configuration access
	cm := icm.GetConfigManager()

	dbHost, err := cm.GetString("database.host")
	if err != nil {
		t.Errorf("Failed to get database.host: %v", err)
	}

	if dbHost != "localhost" {
		t.Errorf("Expected database.host to be 'localhost', got '%s'", dbHost)
	}

	dbPort, err := cm.GetInt("database.port")
	if err != nil {
		t.Errorf("Failed to get database.port: %v", err)
	}

	if dbPort != 5432 {
		t.Errorf("Expected database.port to be 5432, got %d", dbPort)
	}
}
