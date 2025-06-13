package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
	"./interfaces"
)

// DefaultManagerCoordinator provides a concrete implementation of ManagerCoordinator
type DefaultManagerCoordinator struct {
	name         string
	manager      interfaces.BaseManager
	version      string
	capabilities []string
	logger       *logrus.Logger
	mutex        sync.RWMutex
	
	// State tracking
	status           ManagerStatus
	operationCount   int64
	errorCount       int64
	lastOperation    time.Time
	lastError        error
	healthChecker    HealthChecker
}

// NewDefaultManagerCoordinator creates a new coordinator for a manager
func NewDefaultManagerCoordinator(name string, manager interfaces.BaseManager, logger *logrus.Logger) *DefaultManagerCoordinator {
	coordinator := &DefaultManagerCoordinator{
		name:         name,
		manager:      manager,
		version:      "1.0.0", // Could be extracted from manager metadata
		capabilities: []string{}, // Could be extracted from manager interface
		logger:       logger,
		status:       StatusActive,
	}
	
	// Initialize health checker
	coordinator.healthChecker = NewDefaultHealthChecker(name, manager, logger)
	
	// Detect capabilities based on manager interfaces
	coordinator.detectCapabilities()
	
	return coordinator
}

// GetStatus returns the current status of the manager
func (dmc *DefaultManagerCoordinator) GetStatus() ManagerStatus {
	dmc.mutex.RLock()
	defer dmc.mutex.RUnlock()
	return dmc.status
}

// ExecuteOperation executes an operation on the managed component
func (dmc *DefaultManagerCoordinator) ExecuteOperation(ctx context.Context, op *Operation) (*OperationResult, error) {
	dmc.mutex.Lock()
	dmc.operationCount++
	dmc.lastOperation = time.Now()
	dmc.mutex.Unlock()
	
	startTime := time.Now()
	result := &OperationResult{
		Success:        false,
		Duration:       0,
		Data:           make(map[string]interface{}),
		Errors:         []string{},
		Warnings:       []string{},
		ManagerResults: make(map[string]interface{}),
	}
	
	dmc.logger.WithFields(logrus.Fields{
		"manager": dmc.name,
		"operation_id": op.ID,
		"operation_type": op.Type,
	}).Info("Executing operation")
	
	// Execute operation based on type
	var err error
	switch op.Type {
	case "health_check":
		err = dmc.executeHealthCheck(ctx, op, result)
	case "initialize":
		err = dmc.executeInitialize(ctx, op, result)
	case "cleanup":
		err = dmc.executeCleanup(ctx, op, result)
	case "status":
		err = dmc.executeStatus(ctx, op, result)
	default:
		// Try to execute custom operation if manager supports it
		err = dmc.executeCustomOperation(ctx, op, result)
	}
	
	result.Duration = time.Since(startTime)
	
	if err != nil {
		dmc.mutex.Lock()
		dmc.errorCount++
		dmc.lastError = err
		dmc.mutex.Unlock()
		
		result.Success = false
		result.Errors = append(result.Errors, err.Error())
		
		dmc.logger.WithFields(logrus.Fields{
			"manager": dmc.name,
			"operation_id": op.ID,
			"error": err.Error(),
		}).Error("Operation failed")
	} else {
		result.Success = true
		
		dmc.logger.WithFields(logrus.Fields{
			"manager": dmc.name,
			"operation_id": op.ID,
			"duration": result.Duration,
		}).Info("Operation completed successfully")
	}
	
	return result, err
}

// IsHealthy returns the current health status
func (dmc *DefaultManagerCoordinator) IsHealthy() bool {
	if dmc.healthChecker == nil {
		return true // Default to healthy if no health checker
	}
	
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	healthStatus := dmc.healthChecker.CheckHealth(ctx)
	return healthStatus.IsHealthy
}

// GetCapabilities returns the list of capabilities
func (dmc *DefaultManagerCoordinator) GetCapabilities() []string {
	dmc.mutex.RLock()
	defer dmc.mutex.RUnlock()
	
	capabilities := make([]string, len(dmc.capabilities))
	copy(capabilities, dmc.capabilities)
	return capabilities
}

// GetVersion returns the manager version
func (dmc *DefaultManagerCoordinator) GetVersion() string {
	dmc.mutex.RLock()
	defer dmc.mutex.RUnlock()
	return dmc.version
}

// GetMetrics returns coordination metrics
func (dmc *DefaultManagerCoordinator) GetMetrics() map[string]interface{} {
	dmc.mutex.RLock()
	defer dmc.mutex.RUnlock()
	
	return map[string]interface{}{
		"operation_count": dmc.operationCount,
		"error_count":     dmc.errorCount,
		"last_operation":  dmc.lastOperation,
		"status":          dmc.status,
		"is_healthy":      dmc.IsHealthy(),
	}
}

// SetStatus updates the manager status
func (dmc *DefaultManagerCoordinator) SetStatus(status ManagerStatus) {
	dmc.mutex.Lock()
	defer dmc.mutex.Unlock()
	dmc.status = status
}

// Private methods

func (dmc *DefaultManagerCoordinator) detectCapabilities() {
	capabilities := []string{"base_manager"}
	
	// Check for standard interfaces
	if _, ok := dmc.manager.(interfaces.MonitoringManager); ok {
		capabilities = append(capabilities, "monitoring", "metrics_collection", "health_checks")
	}
	
	if _, ok := dmc.manager.(interfaces.StorageManager); ok {
		capabilities = append(capabilities, "storage", "persistence", "data_management")
	}
	
	if _, ok := dmc.manager.(interfaces.SecurityManager); ok {
		capabilities = append(capabilities, "security", "encryption", "authentication")
	}
	
	if _, ok := dmc.manager.(interfaces.ContainerManager); ok {
		capabilities = append(capabilities, "containerization", "docker", "orchestration")
	}
	
	if _, ok := dmc.manager.(interfaces.DeploymentManager); ok {
		capabilities = append(capabilities, "deployment", "ci_cd", "build_management")
	}
	
	// Add common capabilities
	capabilities = append(capabilities, "initialization", "cleanup", "status_reporting")
	
	dmc.capabilities = capabilities
}

func (dmc *DefaultManagerCoordinator) executeHealthCheck(ctx context.Context, op *Operation, result *OperationResult) error {
	if dmc.manager == nil {
		return fmt.Errorf("manager not available")
	}
	
	err := dmc.manager.HealthCheck(ctx)
	if err != nil {
		result.Data["health_status"] = "unhealthy"
		result.Data["health_error"] = err.Error()
		return err
	}
	
	result.Data["health_status"] = "healthy"
	return nil
}

func (dmc *DefaultManagerCoordinator) executeInitialize(ctx context.Context, op *Operation, result *OperationResult) error {
	if dmc.manager == nil {
		return fmt.Errorf("manager not available")
	}
	
	err := dmc.manager.Initialize(ctx)
	if err != nil {
		dmc.SetStatus(StatusError)
		return err
	}
	
	dmc.SetStatus(StatusActive)
	result.Data["initialization_status"] = "completed"
	return nil
}

func (dmc *DefaultManagerCoordinator) executeCleanup(ctx context.Context, op *Operation, result *OperationResult) error {
	if dmc.manager == nil {
		return fmt.Errorf("manager not available")
	}
	
	err := dmc.manager.Cleanup()
	if err != nil {
		return err
	}
	
	dmc.SetStatus(StatusInactive)
	result.Data["cleanup_status"] = "completed"
	return nil
}

func (dmc *DefaultManagerCoordinator) executeStatus(ctx context.Context, op *Operation, result *OperationResult) error {
	metrics := dmc.GetMetrics()
	result.Data["manager_status"] = metrics
	return nil
}

func (dmc *DefaultManagerCoordinator) executeCustomOperation(ctx context.Context, op *Operation, result *OperationResult) error {
	// Try to execute operation based on manager-specific interfaces
	switch op.Type {
	case "collect_metrics":
		if monitoringMgr, ok := dmc.manager.(interfaces.MonitoringManager); ok {
			metrics, err := monitoringMgr.CollectMetrics(ctx)
			if err != nil {
				return err
			}
			result.Data["metrics"] = metrics
			return nil
		}
		
	case "start_monitoring":
		if monitoringMgr, ok := dmc.manager.(interfaces.MonitoringManager); ok {
			err := monitoringMgr.StartMonitoring(ctx)
			if err != nil {
				return err
			}
			result.Data["monitoring_status"] = "started"
			return nil
		}
		
	case "encrypt_data":
		if securityMgr, ok := dmc.manager.(interfaces.SecurityManager); ok {
			if data, exists := op.Parameters["data"]; exists {
				if dataBytes, ok := data.([]byte); ok {
					encrypted, err := securityMgr.EncryptData(dataBytes)
					if err != nil {
						return err
					}
					result.Data["encrypted_data"] = encrypted
					return nil
				}
			}
		}
	}
	
	return fmt.Errorf("unsupported operation type: %s for manager: %s", op.Type, dmc.name)
}
