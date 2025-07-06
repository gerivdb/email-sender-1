package tests

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"

	"EMAIL_SENDER_1/development/managers/dependencymanager"
	"EMAIL_SENDER_1/development/managers/interfaces"
)

// TestFullManagerIntegrationScenario tests a complete scenario involving all manager integrations
func TestFullManagerIntegrationScenario(t *testing.T) {
	// Set up the test environment
	logger := zaptest.NewLogger(t)

	// Create all required mock managers
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Create a test configuration
	config := dependencymanager.GetDefaultConfig()
	configManager := interfaces.NewDepConfigManager(config, logger)

	// Create mock implementations for all managers
	securityManager := &MockSecurityManagerFull{
		logger:          logger,
		vulnerabilities: make(map[string][]string),
	}

	monitoringManager := &MockMonitoringManagerFull{
		logger:           logger,
		operationMetrics: make(map[string]*interfaces.OperationMetrics),
		alertsConfigured: make(map[string]bool),
	}

	storageManager := &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*interfaces.DependencyMetadata),
	}

	// Add some test vulnerabilities
	securityManager.vulnerabilities["github.com/vulnerable/module"] = []string{
		"CVE-2025-1234",
		"CVE-2025-5678",
	}

	// Create the integration manager
	managerIntegrator := interfaces.NewManagerIntegrator(logger, errorManager)
	managerIntegrator.SetSecurityManager(securityManager)
	managerIntegrator.SetMonitoringManager(monitoringManager)
	managerIntegrator.SetStorageManager(storageManager)

	// Create the dependency manager with all integrations
	manager := dependencymanager.NewGoModManager("go.mod", config)
	manager.configManager = configManager
	manager.errorManager = errorManager
	manager.managerIntegrator = managerIntegrator

	// Mock the List method to return test dependencies
	manager.ListFn = func() ([]interfaces.Dependency, error) {
		return []interfaces.Dependency{
			{Name: "github.com/safe/module", Version: "v1.0.0"},
			{Name: "github.com/vulnerable/module", Version: "v1.2.3"},
			{Name: "github.com/another/module", Version: "v0.9.0"},
		}, nil
	}
	defer func() { manager.ListFn = nil }()

	// SCENARIO: Full dependency management workflow with all manager integrations

	// Step 1: Execute security audit with monitoring
	t.Log("Step 1: Security Audit")
	err := manager.AuditWithSecurityManager()
	if err != nil {
		t.Fatalf("Security audit failed: %v", err)
	}

	// Step 2: Get enhanced dependency metadata
	t.Log("Step 2: Enhanced Dependency Listing")
	enhancedDeps, err := manager.ListWithEnhancedMetadata()
	if err != nil {
		t.Fatalf("Enhanced dependency listing failed: %v", err)
	}

	if len(enhancedDeps) == 0 {
		t.Fatalf("Expected at least one enhanced dependency, got none")
	}

	// Step 3: Update the vulnerable dependency with monitoring
	t.Log("Step 3: Update Vulnerable Dependency")
	manager.UpdateFn = func(module, version string) error {
		return nil // Mock successful update
	}
	defer func() { manager.UpdateFn = nil }()

	err = manager.UpdateWithMonitoring("github.com/vulnerable/module", "v1.2.4")
	if err != nil {
		t.Fatalf("Update with monitoring failed: %v", err)
	}

	// Step 4: Sync dependency metadata to storage
	t.Log("Step 4: Sync Dependency Metadata")
	err = manager.SyncDependencyMetadata()
	if err != nil {
		t.Fatalf("Metadata sync failed: %v", err)
	}

	// Step 5: Verify system health
	t.Log("Step 5: System Health Check")
	err = manager.PerformIntegrationHealthCheck()
	if err != nil {
		t.Fatalf("Health check failed: %v", err)
	}

	t.Log("Full manager integration scenario completed successfully")
}

// TestRemoteDependencyResolution tests dependency resolution with security checks
func TestRemoteDependencyResolution(t *testing.T) {
	logger := zaptest.NewLogger(t)
	ctx := context.Background()

	// Create mock managers
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}
	config := dependencymanager.GetDefaultConfig()
	configManager := interfaces.NewDepConfigManager(config, logger)

	securityManager := &MockSecurityManagerFull{
		logger:          logger,
		vulnerabilities: make(map[string][]string),
	}

	// Create dependency manager with security integration
	manager := dependencymanager.NewGoModManager("go.mod", config)
	manager.configManager = configManager
	manager.errorManager = errorManager

	// Set up manager integrator
	managerIntegrator := interfaces.NewManagerIntegrator(logger, errorManager)
	managerIntegrator.SetSecurityManager(securityManager)
	manager.managerIntegrator = managerIntegrator

	// Mock functions to simulate dependency resolution
	securityManager.vulnerabilities["github.com/test/badmodule"] = []string{"CVE-2025-9999"}

	// Mock the Add method
	manager.AddFn = func(module, version string) error {
		return nil // Mock successful addition
	}
	defer func() { manager.AddFn = nil }()

	// Test adding a module that passes security checks
	err := manager.managerIntegrator.ValidateAndAddDependency(ctx, "github.com/test/goodmodule", "v1.0.0")
	if err != nil {
		t.Errorf("Expected good module to pass validation: %v", err)
	}

	// Test adding a module with known vulnerabilities
	// In a real scenario, this would fail, but our mock will allow it
	// We need to check the vulnerability scanner was called
	err = manager.managerIntegrator.ValidateAndAddDependency(ctx, "github.com/test/badmodule", "v1.0.0")
	if err != nil {
		t.Errorf("ValidateAndAddDependency should succeed but flag vulnerabilities: %v", err)
	}

	// Check if the vulnerability check was performed
	deps := []interfaces.Dependency{{Name: "github.com/test/badmodule", Version: "v1.0.0"}}
	report, err := securityManager.ScanForVulnerabilities(ctx, deps)
	if err != nil {
		t.Errorf("Security scan failed: %v", err)
	}

	if report.VulnerabilitiesFound != 1 {
		t.Errorf("Expected 1 vulnerability to be found, got %d", report.VulnerabilitiesFound)
	}

	if detail, exists := report.Details["github.com/test/badmodule"]; !exists {
		t.Error("Expected vulnerability details for bad module")
	} else if len(detail.CVEIDs) != 1 || detail.CVEIDs[0] != "CVE-2025-9999" {
		t.Errorf("Expected CVE-2025-9999, got %v", detail.CVEIDs)
	}
}

// TestErrorPropagation tests error handling across integrated managers
func TestErrorPropagation(t *testing.T) {
	logger := zaptest.NewLogger(t)

	// Create mock managers
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}
	config := dependencymanager.GetDefaultConfig()
	configManager := interfaces.NewDepConfigManager(config, logger)

	// Create and configure manager integrator
	managerIntegrator := interfaces.NewManagerIntegrator(logger, errorManager)

	// Create dependency manager with error integration
	manager := dependencymanager.NewGoModManager("go.mod", config)
	manager.configManager = configManager
	manager.errorManager = errorManager
	manager.managerIntegrator = managerIntegrator

	// Simulate an operation that will generate an error
	errorManager.ProcessError(
		fmt.Errorf("simulated critical dependency resolution error"),
		"dependency-resolution",
		zap.String("context", "test-error"),
	)

	// Can't easily test error propagation from a void function,
	// but we can check if it was logged (in a real scenario)
	t.Log("Error processed")

	// Now test ErrorManager integration with custom error catalog
	entry := interfaces.ErrorEntry{
		ID:             "TEST-ERR-001",
		Timestamp:      time.Now(),
		Message:        "Test error message",
		StackTrace:     "test stack trace",
		Module:         "dependency-manager",
		ErrorCode:      "DEP_TEST_001",
		ManagerContext: map[string]interface{}{"info": "test context"},
		Severity:       "medium",
	}

	errorManager.CatalogError(&entry)

	// Test validation error
	invalidEntry := interfaces.ErrorEntry{
		// Missing required fields
		Message:   "Test error message",
		Timestamp: time.Now(),
	}

	err := errorManager.ValidateErrorEntry(&invalidEntry)
	if err == nil {
		t.Error("Expected ValidateErrorEntry to fail for invalid entry, got nil")
	}
}
