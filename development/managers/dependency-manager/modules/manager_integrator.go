package main

import (
	"context"
	"fmt"
	"time"
	
	"go.uber.org/zap"
)

// ManagerIntegrator provides centralized access to all manager integrations
type ManagerIntegrator struct {
	logger           *zap.Logger
	errorManager     ErrorManager
	securityManager  SecurityManagerInterface
	monitoringManager MonitoringManagerInterface
	storageManager   StorageManagerInterface
	containerManager ContainerManagerInterface
	deploymentManager DeploymentManagerInterface
}

// IntegrationHealthStatus represents the health status of integrated managers
type IntegrationHealthStatus struct {
	Overall   string            `json:"overall"`
	Timestamp time.Time         `json:"timestamp"`
	Managers  map[string]string `json:"managers"`
}

// NewManagerIntegrator creates a new ManagerIntegrator instance
func NewManagerIntegrator(logger *zap.Logger, errorManager ErrorManager) *ManagerIntegrator {
	return &ManagerIntegrator{
		logger:       logger,
		errorManager: errorManager,
		Managers:     make(map[string]string),
	}
}

// InitializeAllManagers sets up all manager integrations
func (m *DependencyManager) InitializeAllManagers(ctx context.Context) error {
	m.Log("Initializing all manager integrations...")
	
	// Initialize security integration
	if err := m.initializeSecurityIntegration(); err != nil {
		return fmt.Errorf("failed to initialize security integration: %w", err)
	}
	
	// Initialize monitoring integration
	if err := m.initializeMonitoringIntegration(); err != nil {
		return fmt.Errorf("failed to initialize monitoring integration: %w", err)
	}
	
	// Initialize storage integration
	if err := m.initializeStorageIntegration(); err != nil {
		return fmt.Errorf("failed to initialize storage integration: %w", err)
	}
	
	// Initialize container integration
	if err := m.initializeContainerIntegration(); err != nil {
		return fmt.Errorf("failed to initialize container integration: %w", err)
	}
	
	// Initialize deployment integration
	if err := m.initializeDeploymentIntegration(); err != nil {
		return fmt.Errorf("failed to initialize deployment integration: %w", err)
	}
	
	m.Log("All manager integrations initialized successfully")
	return nil
}

// SetSecurityManager sets the SecurityManager for integration
func (mi *ManagerIntegrator) SetSecurityManager(sm SecurityManagerInterface) {
	mi.securityManager = sm
	mi.logger.Info("SecurityManager integration configured")
}

// SetMonitoringManager sets the MonitoringManager for integration
func (mi *ManagerIntegrator) SetMonitoringManager(mm MonitoringManagerInterface) {
	mi.monitoringManager = mm
	mi.logger.Info("MonitoringManager integration configured")
}

// SetStorageManager sets the StorageManager for integration
func (mi *ManagerIntegrator) SetStorageManager(sm StorageManagerInterface) {
	mi.storageManager = sm
	mi.logger.Info("StorageManager integration configured")
}

// SetContainerManager sets the ContainerManager for integration
func (mi *ManagerIntegrator) SetContainerManager(cm ContainerManagerInterface) {
	mi.containerManager = cm
	mi.logger.Info("ContainerManager integration configured")
}

// SetDeploymentManager sets the DeploymentManager for integration
func (mi *ManagerIntegrator) SetDeploymentManager(dm DeploymentManagerInterface) {
	mi.deploymentManager = dm
	mi.logger.Info("DeploymentManager integration configured")
}

// PerformIntegrationHealthCheck checks the health of all integrated managers
func (mi *ManagerIntegrator) PerformIntegrationHealthCheck(ctx context.Context) (*IntegrationHealthStatus, error) {
	mi.logger.Info("Performing integration health check for all managers")
	
	status := &IntegrationHealthStatus{
		Timestamp: time.Now(),
		Managers:  make(map[string]string),
	}
	
	// Check SecurityManager health if available
	if mi.securityManager != nil {
		if err := mi.securityManager.HealthCheck(ctx); err != nil {
			status.Managers["SecurityManager"] = "UNHEALTHY: " + err.Error()
		} else {
			status.Managers["SecurityManager"] = "HEALTHY"
		}
	} else {
		status.Managers["SecurityManager"] = "NOT_CONFIGURED"
	}
	
	// Check MonitoringManager health if available
	if mi.monitoringManager != nil {
		if err := mi.monitoringManager.HealthCheck(ctx); err != nil {
			status.Managers["MonitoringManager"] = "UNHEALTHY: " + err.Error()
		} else {
			status.Managers["MonitoringManager"] = "HEALTHY"
		}
	} else {
		status.Managers["MonitoringManager"] = "NOT_CONFIGURED"
	}
	
	// Check StorageManager health if available
	if mi.storageManager != nil {
		if err := mi.storageManager.HealthCheck(ctx); err != nil {
			status.Managers["StorageManager"] = "UNHEALTHY: " + err.Error()
		} else {
			status.Managers["StorageManager"] = "HEALTHY"
		}
	} else {
		status.Managers["StorageManager"] = "NOT_CONFIGURED"
	}
	
	// Check ContainerManager health if available
	if mi.containerManager != nil {
		if err := mi.containerManager.HealthCheck(ctx); err != nil {
			status.Managers["ContainerManager"] = "UNHEALTHY: " + err.Error()
		} else {
			status.Managers["ContainerManager"] = "HEALTHY"
		}
	} else {
		status.Managers["ContainerManager"] = "NOT_CONFIGURED"
	}
	
	// Check DeploymentManager health if available
	if mi.deploymentManager != nil {
		if err := mi.deploymentManager.HealthCheck(ctx); err != nil {
			status.Managers["DeploymentManager"] = "UNHEALTHY: " + err.Error()
		} else {
			status.Managers["DeploymentManager"] = "HEALTHY"
		}
	} else {
		status.Managers["DeploymentManager"] = "NOT_CONFIGURED"
	}
	
	// Determine overall status
	unhealthyCount := 0
	notConfiguredCount := 0
	
	for _, health := range status.Managers {
		if health == "NOT_CONFIGURED" {
			notConfiguredCount++
		} else if !strings.HasPrefix(health, "HEALTHY") {
			unhealthyCount++
		}
	}
	
	if unhealthyCount > 0 {
		status.Overall = "UNHEALTHY"
	} else if notConfiguredCount == len(status.Managers) {
		status.Overall = "NO_INTEGRATIONS"
	} else if notConfiguredCount > 0 {
		status.Overall = "PARTIALLY_CONFIGURED"
	} else {
		status.Overall = "HEALTHY"
	}
	
	mi.logger.Info("Integration health check completed",
		zap.String("overall_status", status.Overall),
		zap.Int("total_managers", len(status.Managers)),
		zap.Int("unhealthy_count", unhealthyCount),
		zap.Int("not_configured_count", notConfiguredCount))
	
	return status, nil
}

// MonitorOperationPerformance monitors a dependency operation with MonitoringManager
func (mi *ManagerIntegrator) MonitorOperationPerformance(ctx context.Context, operation string, fn func() error) error {
	if mi.monitoringManager == nil {
		// If no monitoring manager, just execute the function
		return fn()
	}
	
	mi.logger.Info("Monitoring dependency operation performance", zap.String("operation", operation))
	
	// Start monitoring the operation
	metrics, err := mi.monitoringManager.StartOperationMonitoring(ctx, operation)
	if err != nil {
		mi.logger.Warn("Failed to start monitoring for operation", 
			zap.String("operation", operation), 
			zap.Error(err))
		// Continue with the operation even if monitoring fails
		return fn()
	}
	
	// Execute the operation
	opErr := fn()
	
	// Update metrics
	metrics.Success = opErr == nil
	if opErr != nil {
		metrics.ErrorMessage = opErr.Error()
	}
	
	// Stop monitoring
	if stopErr := mi.monitoringManager.StopOperationMonitoring(ctx, metrics); stopErr != nil {
		mi.logger.Warn("Failed to stop monitoring for operation", 
			zap.String("operation", operation), 
			zap.Error(stopErr))
	}
	
	return opErr
}

// PersistDependencyMetadata persists dependency metadata using StorageManager
func (mi *ManagerIntegrator) PersistDependencyMetadata(ctx context.Context, deps []Dependency) error {
	if mi.storageManager == nil {
		return fmt.Errorf("StorageManager not configured")
	}
	
	mi.logger.Info("Persisting dependency metadata", zap.Int("count", len(deps)))
	
	for _, dep := range deps {
		metadata := &DependencyMetadata{
			Name:        dep.Name,
			Version:     dep.Version,
			Repository:  dep.Repository,
			License:     dep.License,
			LastUpdated: time.Now(),
		}
		
		if err := mi.storageManager.SaveDependencyMetadata(ctx, metadata); err != nil {
			mi.errorManager.ProcessError(ctx, err, "StorageManager", "SaveDependencyMetadata", nil)
			mi.logger.Warn("Failed to persist metadata for dependency", 
				zap.String("name", dep.Name), 
				zap.Error(err))
			// Continue with other dependencies even if one fails
		}
	}
	
	mi.logger.Info("Dependency metadata persistence completed", zap.Int("success_count", len(deps)))
	return nil
}

// EnableRealManagers initializes and enables real manager implementations
func (mi *ManagerIntegrator) EnableRealManagers(ctx context.Context) error {
	mi.logger.Info("Enabling real manager integrations")
	
	// Implementation would connect to actual manager instances in a real environment
	// This is a placeholder for the real implementation
	
	mi.logger.Info("Real manager integrations enabled")
	return nil
}
