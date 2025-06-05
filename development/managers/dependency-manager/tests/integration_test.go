package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// MockSecurityManager implements SecurityManagerInterface for testing
type MockSecurityManager struct {
	logger *zap.Logger
}

func (m *MockSecurityManager) GetSecret(key string) (string, error) {
	return "mock-secret-value", nil
}

func (m *MockSecurityManager) ValidateAPIKey(ctx context.Context, key string) (bool, error) {
	return true, nil
}

func (m *MockSecurityManager) EncryptData(data []byte) ([]byte, error) {
	return append([]byte("encrypted:"), data...), nil
}

func (m *MockSecurityManager) DecryptData(encryptedData []byte) ([]byte, error) {
	if len(encryptedData) > 10 {
		return encryptedData[10:], nil
	}
	return encryptedData, nil
}

func (m *MockSecurityManager) HealthCheck(ctx context.Context) error {
	m.logger.Info("SecurityManager health check passed")
	return nil
}

// MockMonitoringManager implements MonitoringManagerInterface for testing
type MockMonitoringManager struct {
	logger *zap.Logger
}

func (m *MockMonitoringManager) CollectMetrics(ctx context.Context) (*SystemMetrics, error) {
	return &SystemMetrics{
		Timestamp:    time.Now(),
		CPUUsage:     45.5,
		MemoryUsage:  62.3,
		DiskUsage:    78.1,
		NetworkIn:    1024,
		NetworkOut:   2048,
		ErrorCount:   0,
		RequestCount: 100,
	}, nil
}

func (m *MockMonitoringManager) CheckSystemHealth(ctx context.Context) (*HealthStatus, error) {
	return &HealthStatus{
		Overall: "healthy",
		Components: map[string]string{
			"cpu":     "healthy",
			"memory":  "healthy",
			"disk":    "healthy",
			"network": "healthy",
		},
		LastChecked: time.Now(),
	}, nil
}

func (m *MockMonitoringManager) ConfigureAlerts(ctx context.Context, config *AlertConfig) error {
	m.logger.Info("Alert configured",
		zap.String("metric", config.MetricName),
		zap.Float64("threshold", config.Threshold))
	return nil
}

func (m *MockMonitoringManager) HealthCheck(ctx context.Context) error {
	m.logger.Info("MonitoringManager health check passed")
	return nil
}

// MockStorageManager implements StorageManagerInterface for testing
type MockStorageManager struct {
	logger   *zap.Logger
	metadata map[string]*DependencyMetadata
}

func NewMockStorageManager(logger *zap.Logger) *MockStorageManager {
	return &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*DependencyMetadata),
	}
}

func (m *MockStorageManager) SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error {
	m.metadata[metadata.Name] = metadata
	m.logger.Info("Dependency metadata saved",
		zap.String("name", metadata.Name),
		zap.String("version", metadata.Version))
	return nil
}

func (m *MockStorageManager) GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error) {
	if metadata, exists := m.metadata[name]; exists {
		return metadata, nil
	}
	return nil, fmt.Errorf("metadata not found for dependency: %s", name)
}

func (m *MockStorageManager) QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*DependencyMetadata, error) {
	var results []*DependencyMetadata
	for _, metadata := range m.metadata {
		// Simple name matching for mock
		if query.Name == "" || metadata.Name == query.Name {
			results = append(results, metadata)
		}
	}
	return results, nil
}

func (m *MockStorageManager) HealthCheck(ctx context.Context) error {
	m.logger.Info("StorageManager health check passed")
	return nil
}

// MockContainerManager implements ContainerManagerInterface for testing
type MockContainerManager struct {
	logger *zap.Logger
}

func (m *MockContainerManager) GetContainerDependencies(ctx context.Context, containerID string) ([]*ContainerDependency, error) {
	return []*ContainerDependency{
		{
			Name:     "golang",
			Version:  "1.21",
			Type:     "runtime",
			Required: true,
		},
	}, nil
}

func (m *MockContainerManager) ValidateContainerCompatibility(ctx context.Context, dependencies []Dependency) error {
	m.logger.Info("Container compatibility validated",
		zap.Int("dependencies_count", len(dependencies)))
	return nil
}

func (m *MockContainerManager) BuildDependencyImage(ctx context.Context, config *ImageBuildConfig) error {
	m.logger.Info("Dependency image built",
		zap.String("base_image", config.BaseImage),
		zap.Int("dependencies_count", len(config.Dependencies)))
	return nil
}

func (m *MockContainerManager) HealthCheck(ctx context.Context) error {
	m.logger.Info("ContainerManager health check passed")
	return nil
}

// MockDeploymentManager implements DeploymentManagerInterface for testing
type MockDeploymentManager struct {
	logger *zap.Logger
}

func (m *MockDeploymentManager) ValidateDeploymentDependencies(ctx context.Context, dependencies []Dependency) error {
	m.logger.Info("Deployment dependencies validated",
		zap.Int("dependencies_count", len(dependencies)))
	return nil
}

func (m *MockDeploymentManager) UpdateDeploymentConfig(ctx context.Context, config *DeploymentConfig) error {
	m.logger.Info("Deployment config updated",
		zap.String("environment", config.Environment),
		zap.String("version", config.Version))
	return nil
}

func (m *MockDeploymentManager) GetEnvironmentDependencies(ctx context.Context, env string) ([]*EnvironmentDependency, error) {
	return []*EnvironmentDependency{
		{
			Name:        "database",
			Version:     "13.0",
			Environment: env,
			Required:    true,
			ConfigKey:   "DATABASE_URL",
		},
	}, nil
}

func (m *MockDeploymentManager) HealthCheck(ctx context.Context) error {
	m.logger.Info("DeploymentManager health check passed")
	return nil
}

// Integration Test Scenarios

func TestAdvancedManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	
	// Create mock configuration
	config := getDefaultConfig()
	
	// Create DependencyManager with integration
	manager := NewGoModManager("go.mod", config)
	
	// Setup mock managers
	securityManager := &MockSecurityManager{logger: logger}
	monitoringManager := &MockMonitoringManager{logger: logger}
	storageManager := NewMockStorageManager(logger)
	containerManager := &MockContainerManager{logger: logger}
	deploymentManager := &MockDeploymentManager{logger: logger}
	
	// Configure integrations
	manager.SetSecurityManager(securityManager)
	manager.SetMonitoringManager(monitoringManager)
	manager.SetStorageManager(storageManager)
	manager.SetContainerManager(containerManager)
	manager.SetDeploymentManager(deploymentManager)
	
	t.Run("Security Audit Integration", func(t *testing.T) {
		err := manager.AuditWithSecurityManager()
		if err != nil {
			t.Errorf("Security audit integration failed: %v", err)
		}
	})
	
	t.Run("Performance Monitoring Integration", func(t *testing.T) {
		// Test monitored add operation
		err := manager.AddWithMonitoring("github.com/test/mock-module", "v1.0.0")
		if err != nil {
			t.Errorf("Monitored add operation failed: %v", err)
		}
	})
	
	t.Run("Container Deployment Validation", func(t *testing.T) {
		err := manager.ValidateForContainerDeployment()
		if err != nil {
			t.Errorf("Container deployment validation failed: %v", err)
		}
	})
	
	t.Run("Deployment Readiness Check", func(t *testing.T) {
		err := manager.CheckDeploymentReadiness("development")
		if err != nil {
			t.Errorf("Deployment readiness check failed: %v", err)
		}
	})
	
	t.Run("Integration Health Check", func(t *testing.T) {
		err := manager.PerformIntegrationHealthCheck()
		if err != nil {
			t.Errorf("Integration health check failed: %v", err)
		}
	})
	
	t.Run("Enhanced Metadata Listing", func(t *testing.T) {
		metadata, err := manager.ListWithEnhancedMetadata()
		if err != nil {
			t.Errorf("Enhanced metadata listing failed: %v", err)
		}
		
		if len(metadata) == 0 {
			t.Log("No enhanced metadata found (expected for empty go.mod)")
		}
	})
	
	t.Run("Metadata Synchronization", func(t *testing.T) {
		err := manager.SyncDependencyMetadata()
		if err != nil {
			t.Errorf("Metadata synchronization failed: %v", err)
		}
	})
}

func TestManagerIntegratorHealthChecks(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	integrator := NewManagerIntegrator(logger, errorManager)
	
	// Test with no managers configured
	t.Run("No Managers Configured", func(t *testing.T) {
		ctx := context.Background()
		status, err := integrator.PerformHealthCheck(ctx)
		if err != nil {
			t.Errorf("Health check failed: %v", err)
		}
		
		if status.Overall != "no_managers_configured" {
			t.Errorf("Expected 'no_managers_configured', got '%s'", status.Overall)
		}
	})
	
	// Test with all managers configured
	t.Run("All Managers Configured", func(t *testing.T) {
		integrator.SetSecurityManager(&MockSecurityManager{logger: logger})
		integrator.SetMonitoringManager(&MockMonitoringManager{logger: logger})
		integrator.SetStorageManager(NewMockStorageManager(logger))
		integrator.SetContainerManager(&MockContainerManager{logger: logger})
		integrator.SetDeploymentManager(&MockDeploymentManager{logger: logger})
		
		ctx := context.Background()
		status, err := integrator.PerformHealthCheck(ctx)
		if err != nil {
			t.Errorf("Health check failed: %v", err)
		}
		
		if status.Overall != "healthy" {
			t.Errorf("Expected 'healthy', got '%s'", status.Overall)
		}
		
		expectedManagers := []string{
			"SecurityManager", "MonitoringManager", "StorageManager", 
			"ContainerManager", "DeploymentManager",
		}
		
		for _, manager := range expectedManagers {
			if status.Managers[manager] != "healthy" {
				t.Errorf("Expected %s to be 'healthy', got '%s'", manager, status.Managers[manager])
			}
		}
	})
}

func TestSecurityAuditWithManager(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	integrator := NewManagerIntegrator(logger, errorManager)
	securityManager := &MockSecurityManager{logger: logger}
	integrator.SetSecurityManager(securityManager)
	
	dependencies := []Dependency{
		{Name: "github.com/test/module1", Version: "v1.0.0"},
		{Name: "github.com/test/module2", Version: "v2.1.0"},
	}
	
	ctx := context.Background()
	result, err := integrator.SecurityAuditWithManager(ctx, dependencies)
	if err != nil {
		t.Errorf("Security audit failed: %v", err)
	}
	
	if result.TotalScanned != 2 {
		t.Errorf("Expected 2 dependencies scanned, got %d", result.TotalScanned)
	}
	
	if len(result.Dependencies) != 2 {
		t.Errorf("Expected 2 dependency results, got %d", len(result.Dependencies))
	}
}

func TestMonitorOperationPerformance(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	integrator := NewManagerIntegrator(logger, errorManager)
	monitoringManager := &MockMonitoringManager{logger: logger}
	integrator.SetMonitoringManager(monitoringManager)
	
	operationExecuted := false
	ctx := context.Background()
	
	err := integrator.MonitorOperationPerformance(ctx, "test_operation", func() error {
		operationExecuted = true
		time.Sleep(100 * time.Millisecond) // Simulate work
		return nil
	})
	
	if err != nil {
		t.Errorf("Monitored operation failed: %v", err)
	}
	
	if !operationExecuted {
		t.Error("Operation was not executed")
	}
}

func TestCrossManagerCommunication(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &ErrorManagerImpl{logger: logger}
	
	integrator := NewManagerIntegrator(logger, errorManager)
	
	// Setup all managers
	securityManager := &MockSecurityManager{logger: logger}
	monitoringManager := &MockMonitoringManager{logger: logger}
	storageManager := NewMockStorageManager(logger)
	containerManager := &MockContainerManager{logger: logger}
	deploymentManager := &MockDeploymentManager{logger: logger}
	
	integrator.SetSecurityManager(securityManager)
	integrator.SetMonitoringManager(monitoringManager)
	integrator.SetStorageManager(storageManager)
	integrator.SetContainerManager(containerManager)
	integrator.SetDeploymentManager(deploymentManager)
	
	// Test cross-manager workflow
	ctx := context.Background()
	dependencies := []Dependency{
		{Name: "github.com/test/secure-module", Version: "v1.0.0"},
	}
	
	// 1. Security audit
	auditResult, err := integrator.SecurityAuditWithManager(ctx, dependencies)
	if err != nil {
		t.Errorf("Security audit failed: %v", err)
	}
	
	// 2. Persist metadata
	err = integrator.PersistDependencyMetadata(ctx, dependencies)
	if err != nil {
		t.Errorf("Metadata persistence failed: %v", err)
	}
	
	// 3. Validate container compatibility
	err = integrator.ValidateContainerCompatibility(ctx, dependencies)
	if err != nil {
		t.Errorf("Container validation failed: %v", err)
	}
	
	// 4. Check deployment readiness
	err = integrator.CheckDeploymentReadiness(ctx, dependencies, "development")
	if err != nil {
		t.Errorf("Deployment readiness check failed: %v", err)
	}
	
	// 5. Final health check
	status, err := integrator.PerformHealthCheck(ctx)
	if err != nil {
		t.Errorf("Health check failed: %v", err)
	}
	
	if status.Overall != "healthy" {
		t.Errorf("Expected healthy status after workflow, got: %s", status.Overall)
	}
	
	t.Logf("Cross-manager workflow completed successfully")
	t.Logf("Security audit scanned %d dependencies", auditResult.TotalScanned)
	t.Logf("Overall integration health: %s", status.Overall)
}
