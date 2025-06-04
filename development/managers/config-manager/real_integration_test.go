package configmanager

import (
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"
)

// MockRealIntegratedErrorManager implements RealIntegratedErrorManager for testing
type MockRealIntegratedErrorManager struct {
	propagatedErrors []PropagatedError
	hooks            map[string][]func(string, error, map[string]interface{})
	mu               sync.RWMutex
}

// PropagatedError represents an error that was propagated
type PropagatedError struct {
	Module    string
	Error     error
	Context   map[string]interface{}
	Timestamp time.Time
}

// NewMockRealIntegratedErrorManager creates a new mock for testing
func NewMockRealIntegratedErrorManager() *MockRealIntegratedErrorManager {
	return &MockRealIntegratedErrorManager{
		propagatedErrors: make([]PropagatedError, 0),
		hooks:            make(map[string][]func(string, error, map[string]interface{})),
	}
}

// PropagateError implements RealIntegratedErrorManager interface
func (m *MockRealIntegratedErrorManager) PropagateError(module string, err error, context map[string]interface{}) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.propagatedErrors = append(m.propagatedErrors, PropagatedError{
		Module:    module,
		Error:     err,
		Context:   context,
		Timestamp: time.Now(),
	})

	// Execute hooks
	if hooks, exists := m.hooks[module]; exists {
		for _, hook := range hooks {
			go hook(module, err, context)
		}
	}
}

// AddHook implements RealIntegratedErrorManager interface
func (m *MockRealIntegratedErrorManager) AddHook(module string, hook func(string, error, map[string]interface{})) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.hooks[module] = append(m.hooks[module], hook)
}

// GetPropagatedErrors returns all propagated errors for testing
func (m *MockRealIntegratedErrorManager) GetPropagatedErrors() []PropagatedError {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return append([]PropagatedError{}, m.propagatedErrors...)
}

// GetErrorsForModule returns errors for a specific module
func (m *MockRealIntegratedErrorManager) GetErrorsForModule(module string) []PropagatedError {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var moduleErrors []PropagatedError
	for _, err := range m.propagatedErrors {
		if err.Module == module {
			moduleErrors = append(moduleErrors, err)
		}
	}
	return moduleErrors
}

// ClearErrors clears all propagated errors
func (m *MockRealIntegratedErrorManager) ClearErrors() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.propagatedErrors = make([]PropagatedError, 0)
}

// TestRealIntegratedManagerConnector_Initialization tests the connector initialization
func TestRealIntegratedManagerConnector_Initialization(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	// Test initial state
	if connector.IsConnected() {
		t.Error("Expected connector to not be connected initially")
	}

	if connector.GetConfigManager() != nil {
		t.Error("Expected config manager to be nil initially")
	}

	// Test initialization
	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize with real manager: %v", err)
	}

	if cm == nil {
		t.Fatal("Expected config manager to be returned")
	}

	if !connector.IsConnected() {
		t.Error("Expected connector to be connected after initialization")
	}

	if connector.GetConfigManager() == nil {
		t.Error("Expected config manager to be available after initialization")
	}

	// Verify no errors were propagated during successful initialization
	errors := mockErrorMgr.GetErrorsForModule("config-manager")
	if len(errors) > 0 {
		t.Errorf("Expected no errors during successful initialization, got %d", len(errors))
	}
}

// TestRealIntegratedManagerConnector_ProjectDefaults tests project default setup
func TestRealIntegratedManagerConnector_ProjectDefaults(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Test that project defaults are set
	testCases := []struct {
		key           string
		expectedValue interface{}
	}{
		{"app.name", "EMAIL_SENDER_1"},
		{"app.version", "1.0.0"},
		{"app.environment", "development"},
		{"app.debug", true},
		{"logging.level", "Info"},
		{"managers.enabled", true},
		{"managers.config_manager.enabled", true},
		{"database.driver", "sqlite"},
		{"email.smtp.port", 587},
	}

	for _, tc := range testCases {
		value := cm.Get(tc.key)
		if value != tc.expectedValue {
			t.Errorf("Expected %s to be %v, got %v", tc.key, tc.expectedValue, value)
		}
	}
}

// TestRealIntegratedManagerConnector_ErrorPropagation tests error propagation
func TestRealIntegratedManagerConnector_ErrorPropagation(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	// Create a scenario that will cause an error
	// We'll simulate this by calling LoadManagerConfig with invalid path
	_, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Try to load a non-existent config file
	err = connector.LoadManagerConfig("test-manager", "/non/existent/path.json", "json")
	if err == nil {
		t.Error("Expected error when loading non-existent file")
	}

	// Check that error was propagated
	propagatedErrors := mockErrorMgr.GetErrorsForModule("config-manager")
	if len(propagatedErrors) == 0 {
		t.Error("Expected error to be propagated to IntegratedErrorManager")
	}

	// Verify error context
	lastError := propagatedErrors[len(propagatedErrors)-1]
	if lastError.Context["operation"] != "load_manager_config" {
		t.Error("Expected operation context to be 'load_manager_config'")
	}
	if lastError.Context["manager"] != "test-manager" {
		t.Error("Expected manager context to be 'test-manager'")
	}
}

// TestRealIntegratedManagerConnector_ManagerConfig tests manager-specific configuration
func TestRealIntegratedManagerConnector_ManagerConfig(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Set some manager-specific configuration
	cm.Set("managers.test_manager.enabled", true)
	cm.Set("managers.test_manager.timeout", 30)
	cm.Set("managers.test_manager.retries", 3)

	// Test GetManagerConfig
	config, err := connector.GetManagerConfig("test_manager")
	if err != nil {
		t.Fatalf("Failed to get manager config: %v", err)
	}

	expectedKeys := []string{"enabled", "timeout", "retries"}
	for _, key := range expectedKeys {
		if _, exists := config[key]; !exists {
			t.Errorf("Expected key %s to exist in manager config", key)
		}
	}

	// Verify values
	if config["enabled"] != true {
		t.Errorf("Expected enabled to be true, got %v", config["enabled"])
	}
	if config["timeout"] != 30 {
		t.Errorf("Expected timeout to be 30, got %v", config["timeout"])
	}
	if config["retries"] != 3 {
		t.Errorf("Expected retries to be 3, got %v", config["retries"])
	}
}

// TestRealIntegratedManagerConnector_ValidationWithErrors tests validation with propagation
func TestRealIntegratedManagerConnector_ValidationWithErrors(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)
	_, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Test validation with missing required keys
	requiredKeys := []string{"enabled", "timeout", "nonexistent_key"}
	err = connector.ValidateManagerConfig("test_manager", requiredKeys)
	if err == nil {
		t.Error("Expected validation error for missing required key")
	}

	// Check that validation error was propagated
	propagatedErrors := mockErrorMgr.GetErrorsForModule("config-manager")
	if len(propagatedErrors) == 0 {
		t.Error("Expected validation error to be propagated")
	}

	// Verify error context
	found := false
	for _, propagatedErr := range propagatedErrors {
		if propagatedErr.Context["operation"] == "validate_manager_config" {
			found = true
			if propagatedErr.Context["manager"] != "test_manager" {
				t.Error("Expected manager context to be 'test_manager'")
			}
			break
		}
	}
	if !found {
		t.Error("Expected to find validation error in propagated errors")
	}
}

// TestRealIntegratedManagerConnector_SetupManagerDefaults tests manager defaults setup
func TestRealIntegratedManagerConnector_SetupManagerDefaults(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Setup manager defaults
	err = connector.SetupManagerDefaults()
	if err != nil {
		t.Fatalf("Failed to setup manager defaults: %v", err)
	}

	// Test that manager-specific defaults are set
	testCases := []struct {
		key           string
		expectedValue interface{}
	}{
		{"managers.error_manager.max_errors", 1000},
		{"managers.dependency_manager.package_timeout", 60},
		{"managers.process_manager.max_processes", 10},
		{"managers.script_manager.script_timeout", 120},
		{"managers.roadmap_manager.validation_enabled", true},
		{"managers.mode_manager.default_mode", "development"},
		{"managers.integrated_manager.centralized_errors", true},
	}

	for _, tc := range testCases {
		value := cm.Get(tc.key)
		if value != tc.expectedValue {
			t.Errorf("Expected %s to be %v, got %v", tc.key, tc.expectedValue, value)
		}
	}
}

// TestRealIntegratedManagerConnector_ErrorHooks tests error hook functionality
func TestRealIntegratedManagerConnector_ErrorHooks(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	// Track hook executions
	var hookExecuted bool
	var hookModule string
	var hookError error
	var hookContext map[string]interface{}

	// Add a test hook to the mock error manager
	mockErrorMgr.AddHook("config-manager", func(module string, err error, context map[string]interface{}) {
		hookExecuted = true
		hookModule = module
		hookError = err
		hookContext = context
	})

	_, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Trigger an error that should execute the hook
	testError := errors.New("test error for hook")
	connector.propagateError("config-manager", testError, map[string]interface{}{
		"test_context": "hook_test",
	})

	// Give the hook time to execute (it's called in a goroutine)
	time.Sleep(50 * time.Millisecond)

	// Verify hook was executed
	if !hookExecuted {
		t.Error("Expected hook to be executed")
	}
	if hookModule != "config-manager" {
		t.Errorf("Expected hook module to be 'config-manager', got '%s'", hookModule)
	}
	if hookError == nil || hookError.Error() != "test error for hook" {
		t.Errorf("Expected hook error to match test error, got %v", hookError)
	}
	if hookContext["test_context"] != "hook_test" {
		t.Error("Expected hook context to be preserved")
	}
}

// TestRealIntegratedManagerConnector_MultipleManagers tests multiple manager configurations
func TestRealIntegratedManagerConnector_MultipleManagers(t *testing.T) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		t.Fatalf("Failed to initialize: %v", err)
	}

	// Configure multiple managers
	managers := []string{"error_manager", "dependency_manager", "process_manager"}
	for i, manager := range managers {
		cm.Set(fmt.Sprintf("managers.%s.enabled", manager), true)
		cm.Set(fmt.Sprintf("managers.%s.priority", manager), i+1)
		cm.Set(fmt.Sprintf("managers.%s.timeout", manager), (i+1)*10)
	}

	// Test each manager configuration
	for i, manager := range managers {
		config, err := connector.GetManagerConfig(manager)
		if err != nil {
			t.Errorf("Failed to get config for %s: %v", manager, err)
			continue
		}

		if config["enabled"] != true {
			t.Errorf("Expected %s to be enabled", manager)
		}
		if config["priority"] != i+1 {
			t.Errorf("Expected %s priority to be %d, got %v", manager, i+1, config["priority"])
		}
		if config["timeout"] != (i+1)*10 {
			t.Errorf("Expected %s timeout to be %d, got %v", manager, (i+1)*10, config["timeout"])
		}
	}
}

// TestRealIntegratedManagerConnector_EdgeCases tests edge cases and error scenarios
func TestRealIntegratedManagerConnector_EdgeCases(t *testing.T) {
	t.Run("NilErrorManager", func(t *testing.T) {
		// Test with nil error manager
		connector := NewRealIntegratedManagerConnector(nil)

		if connector.IsConnected() {
			t.Error("Expected connector to not be connected with nil error manager")
		}

		// Should still work but without error propagation
		cm, err := connector.InitializeWithRealManager()
		if err != nil {
			t.Fatalf("Failed to initialize with nil error manager: %v", err)
		}
		if cm == nil {
			t.Error("Expected config manager to be created even with nil error manager")
		}
	})

	t.Run("UninitializedConnector", func(t *testing.T) {
		mockErrorMgr := NewMockRealIntegratedErrorManager()
		connector := NewRealIntegratedManagerConnector(mockErrorMgr)

		// Test operations before initialization
		err := connector.LoadManagerConfig("test", "path", "json")
		if err == nil {
			t.Error("Expected error when using uninitialized connector")
		}

		err = connector.ValidateManagerConfig("test", []string{"key"})
		if err == nil {
			t.Error("Expected error when validating with uninitialized connector")
		}

		config, err := connector.GetManagerConfig("test")
		if err == nil {
			t.Error("Expected error when getting config from uninitialized connector")
		}
		if config != nil {
			t.Error("Expected nil config from uninitialized connector")
		}
	})

	t.Run("EmptyManagerName", func(t *testing.T) {
		mockErrorMgr := NewMockRealIntegratedErrorManager()
		connector := NewRealIntegratedManagerConnector(mockErrorMgr)

		_, err := connector.InitializeWithRealManager()
		if err != nil {
			t.Fatalf("Failed to initialize: %v", err)
		}

		// Test with empty manager name
		config, err := connector.GetManagerConfig("")
		if err != nil {
			t.Errorf("Unexpected error with empty manager name: %v", err)
		}
		// Should return empty config for empty manager name
		if len(config) != 0 {
			t.Error("Expected empty config for empty manager name")
		}
	})
}

// BenchmarkRealIntegratedManagerConnector_ErrorPropagation benchmarks error propagation performance
func BenchmarkRealIntegratedManagerConnector_ErrorPropagation(b *testing.B) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	_, err := connector.InitializeWithRealManager()
	if err != nil {
		b.Fatalf("Failed to initialize: %v", err)
	}

	testError := errors.New("benchmark test error")
	context := map[string]interface{}{
		"operation": "benchmark",
		"iteration": 0,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		context["iteration"] = i
		connector.propagateError("config-manager", testError, context)
	}
}

// BenchmarkRealIntegratedManagerConnector_GetManagerConfig benchmarks manager config retrieval
func BenchmarkRealIntegratedManagerConnector_GetManagerConfig(b *testing.B) {
	mockErrorMgr := NewMockRealIntegratedErrorManager()
	connector := NewRealIntegratedManagerConnector(mockErrorMgr)

	cm, err := connector.InitializeWithRealManager()
	if err != nil {
		b.Fatalf("Failed to initialize: %v", err)
	}

	// Set up some manager configuration
	for i := 0; i < 10; i++ {
		cm.Set(fmt.Sprintf("managers.test_manager.key_%d", i), fmt.Sprintf("value_%d", i))
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := connector.GetManagerConfig("test_manager")
		if err != nil {
			b.Fatalf("Failed to get manager config: %v", err)
		}
	}
}
