package main

import (
	"context"
	"testing"
	"time"
	
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// TestDependencyManagerWithSecurityManager tests the integration between DependencyManager and SecurityManager
func TestDependencyManagerWithSecurityManager(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create a test config
	config := &Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: struct {
			LogPath            string `json:"logPath"`
			LogLevel           string `json:"logLevel"`
			GoModPath          string `json:"goModPath"`
			AutoTidy           bool   `json:"autoTidy"`
			VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
			BackupOnChange     bool   `json:"backupOnChange"`
		}{
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
	configManager := NewDepConfigManager(config, logger, errorManager)
	
	// Create DependencyManager with ConfigManager and SecurityManager
	manager := NewGoModManager("go.mod", config)
	
	// Set managers
	manager.configManager = configManager
	manager.SetSecurityManager(securityManager)
	
	// Create test dependencies
	safeDep := Dependency{Name: "github.com/safe/pkg", Version: "v1.0.0"}
	vulnDep := Dependency{Name: "github.com/vulnerable/pkg", Version: "v1.0.0"}
	
	// Test security scan with a safe dependency
	ctx := context.Background()
	safeResult, err := securityManager.ScanForVulnerabilities(ctx, []Dependency{safeDep})
	if err != nil {
		t.Errorf("Security scan failed: %v", err)
	}
	
	if safeResult.VulnerabilitiesFound != 0 {
		t.Errorf("Expected 0 vulnerabilities for safe dependency, got %d", safeResult.VulnerabilitiesFound)
	}
	
	// Test security scan with a vulnerable dependency
	vulnResult, err := securityManager.ScanForVulnerabilities(ctx, []Dependency{vulnDep})
	if err != nil {
		t.Errorf("Security scan failed: %v", err)
	}
	
	if vulnResult.VulnerabilitiesFound != 1 {
		t.Errorf("Expected 1 vulnerable dependency, got %d", vulnResult.VulnerabilitiesFound)
	}
	
	// Test the DependencyManager.AuditWithSecurityManager method
	// First, mock the List method to return our test dependencies
	originalListFn := manager.List
	manager.List = func() ([]Dependency, error) {
		return []Dependency{safeDep, vulnDep}, nil
	}
	defer func() { manager.List = originalListFn }()
	
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
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create a test config
	config := &Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: struct {
			LogPath            string `json:"logPath"`
			LogLevel           string `json:"logLevel"`
			GoModPath          string `json:"goModPath"`
			AutoTidy           bool   `json:"autoTidy"`
			VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
			BackupOnChange     bool   `json:"backupOnChange"`
		}{
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
		operationMetrics: make(map[string]*OperationMetrics),
	}
	
	// Create ConfigManager
	configManager := NewDepConfigManager(config, logger, errorManager)
	
	// Create DependencyManager
	manager := NewGoModManager("go.mod", config)
	
	// Set managers
	manager.configManager = configManager
	manager.SetMonitoringManager(monitoringManager)
	
	// Create manager integrator
	manager.managerIntegrator = NewManagerIntegrator(logger, errorManager)
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
	alertConfig := &AlertConfig{
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
	errorManager := &ErrorManagerImpl{logger: logger}
	
	// Create a test config
	config := &Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: struct {
			LogPath            string `json:"logPath"`
			LogLevel           string `json:"logLevel"`
			GoModPath          string `json:"goModPath"`
			AutoTidy           bool   `json:"autoTidy"`
			VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
			BackupOnChange     bool   `json:"backupOnChange"`
		}{
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
		operationMetrics: make(map[string]*OperationMetrics),
	}
	
	storageManager := &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*DependencyMetadata),
	}
	
	// Create ConfigManager
	configManager := NewDepConfigManager(config, logger, errorManager)
	
	// Create manager integrator
	integrator := NewManagerIntegrator(logger, errorManager)
	integrator.SetSecurityManager(securityManager)
	integrator.SetMonitoringManager(monitoringManager)
	integrator.SetStorageManager(storageManager)
	
	// Create DependencyManager
	manager := NewGoModManager("go.mod", config)
	
	// Set managers
	manager.configManager = configManager
	manager.managerIntegrator = integrator
	
	// Mock the List method
	manager.List = func() ([]Dependency, error) {
		return []Dependency{
			{Name: "github.com/pkg/errors", Version: "v0.9.1"},
			{Name: "github.com/stretchr/testify", Version: "v1.8.0"},
		}, nil
	}
	
	// Test integrated audit flow
	ctx := context.Background()
	
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
	originalUpdateFn := manager.Update
	manager.Update = func(module string) error {
		return nil
	}
	defer func() { manager.Update = originalUpdateFn }()
	
	err = manager.UpdateWithMonitoring("github.com/pkg/errors")
	if err != nil {
		t.Errorf("UpdateWithMonitoring failed: %v", err)
	}
	
	// Step 5: Health check
	err = manager.PerformIntegrationHealthCheck()
	if err != nil {
		t.Errorf("PerformIntegrationHealthCheck failed: %v", err)
	}
}

// Mock implementations for testing

type MockSecurityManagerFull struct {
	logger          *zap.Logger
	vulnerabilities map[string][]string
}

func (m *MockSecurityManagerFull) GetSecret(key string) (string, error) {
	return "mock-secret", nil
}

func (m *MockSecurityManagerFull) EncryptData(data []byte) ([]byte, error) {
	return append([]byte("encrypted:"), data...), nil
}

func (m *MockSecurityManagerFull) DecryptData(encryptedData []byte) ([]byte, error) {
	return []byte("decrypted-data"), nil
}

func (m *MockSecurityManagerFull) ScanForVulnerabilities(ctx context.Context, dependencies []Dependency) (*VulnerabilityReport, error) {
	report := &VulnerabilityReport{
		TotalScanned:         len(dependencies),
		VulnerabilitiesFound: 0,
		Timestamp:            time.Now(),
		Details:              make(map[string]*VulnerabilityInfo),
	}
	
	// Check each dependency against our vulnerability database
	for _, dep := range dependencies {
		if cves, exists := m.vulnerabilities[dep.Name]; exists {
			report.VulnerabilitiesFound++
			report.Details[dep.Name] = &VulnerabilityInfo{
				Severity:    "high",
				Description: "Security vulnerability found in package",
				CVEIDs:      cves,
				FixVersion:  dep.Version + "-patched",
			}
		}
	}
	
	return report, nil
}

type MockMonitoringManagerFull struct {
	logger           *zap.Logger
	operationMetrics map[string]*OperationMetrics
	alertsConfigured map[string]bool
}

func (m *MockMonitoringManagerFull) StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error) {
	if m.operationMetrics == nil {
		m.operationMetrics = make(map[string]*OperationMetrics)
	}
	
	if m.alertsConfigured == nil {
		m.alertsConfigured = make(map[string]bool)
	}
	
	metrics := &OperationMetrics{
		Operation:   operation,
		StartTime:   time.Now(),
		CPUUsage:    5.0,
		MemoryUsage: 10.0,
	}
	
	m.operationMetrics[operation] = metrics
	return metrics, nil
}

func (m *MockMonitoringManagerFull) StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error {
	if metrics == nil {
		return nil
	}
	
	metrics.EndTime = time.Now()
	metrics.Duration = metrics.EndTime.Sub(metrics.StartTime)
	
	m.operationMetrics[metrics.Operation] = metrics
	return nil
}

func (m *MockMonitoringManagerFull) ConfigureAlerts(ctx context.Context, config *AlertConfig) error {
	if m.alertsConfigured == nil {
		m.alertsConfigured = make(map[string]bool)
	}
	
	m.alertsConfigured[config.Name] = config.Enabled
	return nil
}

// DependencyMetadata type for testing
type DependencyMetadata struct {
	Name        string            `json:"name"`
	Version     string            `json:"version"`
	LastUpdated time.Time         `json:"last_updated"`
	Repository  string            `json:"repository,omitempty"`
	Author      string            `json:"author,omitempty"`
	License     string            `json:"license,omitempty"`
	Description string            `json:"description,omitempty"`
	Homepage    string            `json:"homepage,omitempty"`
	Stars       int               `json:"stars,omitempty"`
	Tags        map[string]string `json:"tags,omitempty"`
}

// SystemMetrics for monitoring
type SystemMetrics struct {
	Timestamp    time.Time `json:"timestamp"`
	CPUUsage     float64   `json:"cpu_usage"`  // percentage
	MemoryUsage  float64   `json:"memory_usage"` // percentage
	DiskUsage    float64   `json:"disk_usage"`   // percentage
	NetworkIn    int64     `json:"network_in"`    // bytes per second
	NetworkOut   int64     `json:"network_out"`   // bytes per second
	ErrorCount   int       `json:"error_count"`
	RequestCount int       `json:"request_count"`
}

// HealthStatus for health checks
type HealthStatus struct {
	Overall    string            `json:"overall"`
	Components map[string]string `json:"components"`
	LastChecked time.Time        `json:"last_checked"`
}

// DependencyQuery for database searches
type DependencyQuery struct {
	Name      string   `json:"name,omitempty"`
	Version   string   `json:"version,omitempty"`
	Tags      []string `json:"tags,omitempty"`
	Limit     int      `json:"limit,omitempty"`
	SortBy    string   `json:"sort_by,omitempty"`
	SortOrder string   `json:"sort_order,omitempty"`
}

// ContainerDependency represents a dependency needed in a container
type ContainerDependency struct {
	Name     string `json:"name"`
	Version  string `json:"version"`
	Type     string `json:"type"` // runtime, build, etc.
	Required bool   `json:"required"`
}

// ImageBuildConfig represents configuration for building container images
type ImageBuildConfig struct {
	BaseImage    string       `json:"base_image"`
	Dependencies []Dependency `json:"dependencies"`
	BuildArgs    []string     `json:"build_args,omitempty"`
	Tags         []string     `json:"tags,omitempty"`
}

// DeploymentConfig represents configuration for deployment
type DeploymentConfig struct {
	Environment string            `json:"environment"`
	Version     string            `json:"version"`
	Variables   map[string]string `json:"variables,omitempty"`
}

// EnvironmentDependency represents a dependency required by an environment
type EnvironmentDependency struct {
	Name        string `json:"name"`
	Version     string `json:"version"`
	Environment string `json:"environment"`
	Required    bool   `json:"required"`
	ConfigKey   string `json:"config_key,omitempty"`
}
