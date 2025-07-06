package tests

import (
	"context"
	"testing"
	"time"

	"go.uber.org/zap/zaptest"

	"github.com/gerivdb/email-sender-1/development/managers/dependencymanager"
	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
)

// TestDependencyManagerWithSecurityManager tests the integration between DependencyManager and SecurityManager
func TestDependencyManagerWithSecurityManager(t *testing.T) {
	logger := zaptest.NewLogger(t)

	// Create a test config
	config := &interfaces.Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: interfaces.ConfigSettings{
			LogPath:            "logs/dependency-manager.log",
			LogLevel:           "info",
			GoModPath:          "go.mod",
			AutoTidy:           true,
			VulnerabilityCheck: true,
			BackupOnChange:     true,
		},
	}

	// Create mock SecurityManager
	securityManager := &MockSecurityManagerFull{
		logger:          logger,
		vulnerabilities: make(map[string][]string),
	}

	// Add some test vulnerabilities
	securityManager.vulnerabilities["github.com/vulnerable/pkg"] = []string{"CVE-2025-1234", "CVE-2025-5678"}

	// Create ConfigManager
	configManager := interfaces.NewDepConfigManager(config, logger)

	// Create DependencyManager with ConfigManager and SecurityManager
	manager := dependencymanager.NewGoModManager("go.mod", config)

	// Set managers
	manager.configManager = configManager
	manager.SetSecurityManager(securityManager)

	// Create test dependencies
	safeDep := interfaces.Dependency{Name: "github.com/safe/pkg", Version: "v1.0.0"}
	vulnDep := interfaces.Dependency{Name: "github.com/vulnerable/pkg", Version: "v1.0.0"}

	// Test security scan with a safe dependency
	ctx := context.Background()
	safeResult, err := securityManager.ScanForVulnerabilities(ctx, []interfaces.Dependency{safeDep})
	if err != nil {
		t.Errorf("Security scan failed: %v", err)
	}

	if safeResult.VulnerabilitiesFound != 0 {
		t.Errorf("Expected 0 vulnerabilities for safe dependency, got %d", safeResult.VulnerabilitiesFound)
	}

	// Test security scan with a vulnerable dependency
	vulnResult, err := securityManager.ScanForVulnerabilities(ctx, []interfaces.Dependency{vulnDep})
	if err != nil {
		t.Errorf("Security scan failed: %v", err)
	}

	if vulnResult.VulnerabilitiesFound != 1 {
		t.Errorf("Expected 1 vulnerable dependency, got %d", vulnResult.VulnerabilitiesFound)
	}

	// Test the DependencyManager.AuditWithSecurityManager method
	// First, mock the List method to return our test dependencies
	manager.ListFn = func() ([]interfaces.Dependency, error) {
		return []interfaces.Dependency{safeDep, vulnDep}, nil
	}
	defer func() { manager.ListFn = nil }()

	err = manager.AuditWithSecurityManager()
	if err != nil {
		t.Errorf("AuditWithSecurityManager failed: %v", err)
	}

	// Check the report was generated (we can't see the output in this test)
	t.Log("AuditWithSecurityManager completed successfully")
}

// TestDependencyManagerWithMonitoringManager tests the integration between DependencyManager and MonitoringManager
func TestDependencyManagerWithMonitoringManager(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Create a test config
	config := &interfaces.Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: interfaces.ConfigSettings{
			LogPath:            "logs/dependency-manager.log",
			LogLevel:           "info",
			GoModPath:          "go.mod",
			AutoTidy:           true,
			VulnerabilityCheck: true,
			BackupOnChange:     true,
		},
	}

	// Create mock MonitoringManager
	monitoringManager := &MockMonitoringManagerFull{
		logger:           logger,
		operationMetrics: make(map[string]*interfaces.OperationMetrics),
	}

	// Create ConfigManager
	configManager := interfaces.NewDepConfigManager(config, logger)

	// Create DependencyManager
	manager := dependencymanager.NewGoModManager("go.mod", config)

	// Set managers
	manager.configManager = configManager
	manager.SetMonitoringManager(monitoringManager)

	// Create manager integrator
	manager.managerIntegrator = interfaces.NewManagerIntegrator(logger, errorManager)
	manager.managerIntegrator.SetMonitoringManager(monitoringManager)

	// Test monitoring operations
	ctx := context.Background()

	// Start monitoring a test operation
	metrics, err := monitoringManager.StartOperationMonitoring(ctx, "test_operation")
	if err != nil {
		t.Errorf("StartOperationMonitoring failed: %v", err)
	}

	// Simulate work
	time.Sleep(10 * time.Millisecond)

	// Stop monitoring
	metrics.Success = true
	err = monitoringManager.StopOperationMonitoring(ctx, metrics)
	if err != nil {
		t.Errorf("StopOperationMonitoring failed: %v", err)
	}

	// Test AddWithMonitoring
	testFn := func() error {
		return nil
	}

	err = manager.managerIntegrator.MonitorOperationPerformance(ctx, "add_dependency", testFn)
	if err != nil {
		t.Errorf("MonitorOperationPerformance failed: %v", err)
	}

	// Check if the operation was monitored
	if _, exists := monitoringManager.operationMetrics["add_dependency"]; !exists {
		t.Error("Operation 'add_dependency' was not monitored")
	}

	// Test ConfigureAlerts
	alertConfig := &interfaces.AlertConfig{
		Name:            "test_alert",
		Enabled:         true,
		Conditions:      []string{"condition1", "condition2"},
		Thresholds:      map[string]float64{"threshold": 10.0},
		NotifyChannels:  []string{"email"},
		SuppressTimeout: 60,
	}

	err = monitoringManager.ConfigureAlerts(ctx, alertConfig)
	if err != nil {
		t.Errorf("ConfigureAlerts failed: %v", err)
	}

	// Test if alert was configured
	if !monitoringManager.alertsConfigured["test_alert"] {
		t.Error("Alert 'test_alert' was not configured")
	}
}

// TestDependencyManagerCrossManagerIntegration tests the integration between DependencyManager and multiple managers
func TestDependencyManagerCrossManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Create a test config
	config := &interfaces.Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: interfaces.ConfigSettings{
			LogPath:            "logs/dependency-manager.log",
			LogLevel:           "info",
			GoModPath:          "go.mod",
			AutoTidy:           true,
			VulnerabilityCheck: true,
			BackupOnChange:     true,
		},
	}

	// Create mock managers
	securityManager := &MockSecurityManagerFull{
		logger:          logger,
		vulnerabilities: make(map[string][]string),
	}

	monitoringManager := &MockMonitoringManagerFull{
		logger:           logger,
		operationMetrics: make(map[string]*interfaces.OperationMetrics),
	}

	storageManager := &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*interfaces.DependencyMetadata),
	}

	// Create ConfigManager
	configManager := interfaces.NewDepConfigManager(config, logger)

	// Create manager integrator
	integrator := interfaces.NewManagerIntegrator(logger, errorManager)
	integrator.SetSecurityManager(securityManager)
	integrator.SetMonitoringManager(monitoringManager)
	integrator.SetStorageManager(storageManager)

	// Create DependencyManager
	manager := dependencymanager.NewGoModManager("go.mod", config)

	// Set managers
	manager.configManager = configManager
	manager.managerIntegrator = integrator

	// Mock the List method
	manager.ListFn = func() ([]interfaces.Dependency, error) {
		return []interfaces.Dependency{
			{Name: "github.com/pkg/errors", Version: "v0.9.1"},
			{Name: "github.com/stretchr/testify", Version: "v1.8.0"},
		}, nil
	}

	// Test integrated audit flow

	// Add a test vulnerability
	securityManager.vulnerabilities["github.com/pkg/errors"] = []string{"CVE-2025-TEST"}

	// Step 1: Security audit with monitoring
	err := manager.AuditWithSecurityManager()
	if err != nil {
		t.Errorf("AuditWithSecurityManager failed: %v", err)
	}

	// Step 2: Store metadata about the vulnerable package
	err = manager.SyncDependencyMetadata()
	if err != nil {
		t.Errorf("SyncDependencyMetadata failed: %v", err)
	}

	// Step 3: Retrieve enhanced metadata
	enhancedDeps, err := manager.ListWithEnhancedMetadata()
	if err != nil {
		t.Errorf("ListWithEnhancedMetadata failed: %v", err)
	}

	if len(enhancedDeps) != 2 {
		t.Errorf("Expected 2 dependencies with enhanced metadata, got %d", len(enhancedDeps))
	}

	// Step 4: Update with monitoring
	manager.UpdateFn = func(module, version string) error {
		return nil
	}
	defer func() { manager.UpdateFn = nil }()

	err = manager.UpdateWithMonitoring("github.com/pkg/errors", "v0.9.2")
	if err != nil {
		t.Errorf("UpdateWithMonitoring failed: %v", err)
	}

	// Step 5: Health check
	err = manager.PerformIntegrationHealthCheck()
	if err != nil {
		t.Errorf("PerformIntegrationHealthCheck failed: %v", err)
	}
}
