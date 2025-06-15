// Package integration provides integration with existing 17 managers
// Following DRY principle by reusing existing managers
package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

// ManagerHub centralizes access to all 17 existing managers
// Implements SOLID principles with segregated interfaces
type ManagerHub struct {
	config       *types.ManagersConfig
	logger       *zap.Logger
	managers     map[string]interfaces.Manager
	healthStatus map[string]interfaces.HealthStatus
	mu           sync.RWMutex
	ctx          context.Context
	cancel       context.CancelFunc
	healthTicker *time.Ticker
}

// Manager represents the common interface for all managers
type Manager = interfaces.Manager

// HealthStatus represents the health state of a manager
type HealthStatus = interfaces.HealthStatus

// NewManagerHub creates a new manager hub instance
func NewManagerHub(config *types.ManagersConfig, logger *zap.Logger) (*ManagerHub, error) {
	if config == nil {
		return nil, fmt.Errorf("managers config cannot be nil")
	}

	ctx, cancel := context.WithCancel(context.Background())
	hub := &ManagerHub{
		config:       config,
		logger:       logger,
		managers:     make(map[string]interfaces.Manager),
		healthStatus: make(map[string]interfaces.HealthStatus),
		ctx:          ctx,
		cancel:       cancel,
		healthTicker: time.NewTicker(config.HealthCheckInterval),
	}

	// Initialize all 17 managers
	if err := hub.initializeManagers(); err != nil {
		return nil, fmt.Errorf("failed to initialize managers: %w", err)
	}

	return hub, nil
}

// initializeManagers sets up connections to all existing managers
func (h *ManagerHub) initializeManagers() error {
	h.logger.Info("Initializing 17 existing managers for FMOUA integration")

	// List of the 17 existing managers to integrate
	managerTypes := []string{
		"ErrorManager",
		"StorageManager",
		"SecurityManager",
		"MonitoringManager",
		"CacheManager",
		"ConfigManager",
		"LogManager",
		"MetricsManager",
		"HealthManager",
		"BackupManager",
		"ValidationManager",
		"TestManager",
		"DeploymentManager",
		"NetworkManager",
		"DatabaseManager",
		"AuthManager",
		"APIManager",
	}

	for _, managerType := range managerTypes {
		manager, err := h.createManagerProxy(managerType)
		if err != nil {
			h.logger.Warn("Failed to create manager proxy",
				zap.String("manager", managerType),
				zap.Error(err))
			continue
		}
		h.managers[managerType] = manager
		h.healthStatus[managerType] = interfaces.HealthStatus{
			IsHealthy:    false,
			LastCheck:    time.Now(),
			ResponseTime: 0,
		}

		h.logger.Info("Manager proxy created", zap.String("manager", managerType))
	}

	return nil
}

// createManagerProxy creates a proxy to connect to existing managers
func (h *ManagerHub) createManagerProxy(managerType string) (interfaces.Manager, error) {
	// This would normally connect to the actual manager implementations
	// For now, create proxy managers that simulate the interface
	return NewManagerProxy(managerType, h.config, h.logger), nil
}

// Start initializes all managers and starts health monitoring
func (h *ManagerHub) Start(ctx context.Context) error {
	h.logger.Info("Starting ManagerHub with all integrated managers")

	// Start all managers
	var wg sync.WaitGroup
	errors := make(chan error, len(h.managers))

	for name, manager := range h.managers {
		wg.Add(1)
		go func(name string, mgr Manager) {
			defer wg.Done()
			if err := mgr.Start(ctx); err != nil {
				errors <- fmt.Errorf("failed to start %s: %w", name, err)
				return
			}
			h.logger.Info("Manager started successfully", zap.String("manager", name))
		}(name, manager)
	}
	// Wait for all managers to start with timeout
	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		close(errors)
		// Collect any errors
		var startErrors []error
		for err := range errors {
			startErrors = append(startErrors, err)
		}
		if len(startErrors) > 0 {
			return fmt.Errorf("failed to start some managers: %v", startErrors)
		}
	case <-time.After(30 * time.Second):
		return fmt.Errorf("timeout starting managers")
	}

	// Start health monitoring
	go h.healthMonitoring()

	h.logger.Info("ManagerHub started successfully",
		zap.Int("active_managers", len(h.managers)))

	return nil
}

// healthMonitoring performs continuous health checks on all managers
func (h *ManagerHub) healthMonitoring() {
	for {
		select {
		case <-h.ctx.Done():
			return
		case <-h.healthTicker.C:
			h.performHealthChecks()
		}
	}
}

// performHealthChecks checks health of all managers
func (h *ManagerHub) performHealthChecks() {
	h.mu.Lock()
	defer h.mu.Unlock()

	for name, manager := range h.managers {
		start := time.Now()
		err := manager.Health()
		responseTime := time.Since(start)
		status := interfaces.HealthStatus{
			IsHealthy:    err == nil,
			LastCheck:    time.Now(),
			ResponseTime: responseTime,
		}

		if err != nil {
			status.ErrorMessage = err.Error()
		}

		h.healthStatus[name] = status

		if !status.IsHealthy {
			h.logger.Warn("Manager health check failed",
				zap.String("manager", name),
				zap.Error(err),
				zap.Duration("response_time", responseTime))
		}
	}
}

// GetManager returns a specific manager by name
func (h *ManagerHub) GetManager(name string) (interfaces.Manager, error) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	manager, exists := h.managers[name]
	if !exists {
		return nil, fmt.Errorf("manager %s not found", name)
	}

	return manager, nil
}

// GetHealthStatus returns health status for all managers
func (h *ManagerHub) GetHealthStatus() map[string]interfaces.HealthStatus {
	h.mu.RLock()
	defer h.mu.RUnlock()

	status := make(map[string]interfaces.HealthStatus)
	for name, health := range h.healthStatus {
		status[name] = health
	}

	return status
}

// GetActiveManagers returns list of currently active managers
func (h *ManagerHub) GetActiveManagers() []string {
	h.mu.RLock()
	defer h.mu.RUnlock()

	var active []string
	for name, status := range h.healthStatus {
		if status.IsHealthy {
			active = append(active, name)
		}
	}

	return active
}

// Stop gracefully shuts down all managers
func (h *ManagerHub) Stop() error {
	h.logger.Info("Stopping ManagerHub and all integrated managers")

	h.cancel()
	h.healthTicker.Stop()

	var errors []error
	for name, manager := range h.managers {
		if err := manager.Stop(); err != nil {
			errors = append(errors, fmt.Errorf("failed to stop %s: %w", name, err))
		}
	}

	if len(errors) > 0 {
		return fmt.Errorf("errors stopping managers: %v", errors)
	}

	h.logger.Info("ManagerHub stopped successfully")
	return nil
}

// ExecuteManagerOperation executes an operation through a specific manager
func (h *ManagerHub) ExecuteManagerOperation(managerName, operation string, params map[string]interface{}) (interface{}, error) {
	_, err := h.GetManager(managerName)
	if err != nil {
		return nil, err
	}

	// Check if manager is healthy
	h.mu.RLock()
	status := h.healthStatus[managerName]
	h.mu.RUnlock()

	if !status.IsHealthy {
		return nil, fmt.Errorf("manager %s is not healthy", managerName)
	}

	// For now, return success - this would be implemented per manager type
	h.logger.Info("Executing manager operation",
		zap.String("manager", managerName),
		zap.String("operation", operation))

	return fmt.Sprintf("Operation %s executed on %s", operation, managerName), nil
}

// Ensure ManagerHub implements the interface
var _ interfaces.ManagerHub = (*ManagerHub)(nil)

// Ensure ManagerProxy implements the Manager interface
var _ interfaces.Manager = (*ManagerProxy)(nil)
