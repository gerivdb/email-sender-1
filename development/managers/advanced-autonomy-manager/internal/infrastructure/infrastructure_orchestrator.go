// Package infrastructure provides tools for automated infrastructure management
// within the AdvancedAutonomyManager ecosystem - Phase 4 Implementation.
package infrastructure

import (
	"advanced-autonomy-manager/internal/config"
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

// Common errors
var (
	ErrServiceNotFound           = errors.New("service not found in infrastructure configuration")
	ErrServiceAlreadyRunning     = errors.New("service is already running")
	ErrServiceNotRunning         = errors.New("service is not running")
	ErrInfrastructureUnavailable = errors.New("infrastructure components are unavailable")
	ErrInvalidConfiguration      = errors.New("invalid infrastructure configuration")
	ErrStartupTimeout            = errors.New("service startup timed out")
	ErrShutdownTimeout           = errors.New("service shutdown timed out")
	ErrInsufficientResources     = errors.New("insufficient system resources")
	ErrSecurityValidationFailed  = errors.New("security validation failed")
)

// InfrastructureOrchestratorInterface - Interface principale pour l'orchestration infrastructure (Phase 4)
type InfrastructureOrchestratorInterface interface {
	// Démarrage orchestré de l'infrastructure complète
	StartInfrastructureStack(ctx context.Context, config *StackConfig) (*StartupResult, error)

	// Arrêt propre de l'infrastructure
	StopInfrastructureStack(ctx context.Context, graceful bool) (*ShutdownResult, error)

	// Surveillance continue de l'état
	MonitorInfrastructureHealth(ctx context.Context) (*HealthStatus, error)

	// Récupération automatique en cas de panne
	RecoverFailedServices(ctx context.Context, services []string) (*RecoveryResult, error)

	// Gestion des mises à jour rolling
	PerformRollingUpdate(ctx context.Context, updatePlan *UpdatePlan) error
}

// ServiceStatus represents the current status of an infrastructure service
type ServiceStatus struct {
	Name           string        `json:"name"`
	Running        bool          `json:"running"`
	HealthStatus   bool          `json:"health_status"`
	StartupTime    time.Duration `json:"startup_time,omitempty"`
	LastHealthTime time.Time     `json:"last_health_time,omitempty"`
	Endpoint       string        `json:"endpoint,omitempty"`
	Errors         []string      `json:"errors,omitempty"`
}

// StackConfig defines configuration for starting the infrastructure stack
type StackConfig struct {
	Environment     string              `json:"environment"`       // dev, prod, test
	ServicesToStart []string            `json:"services_to_start"` // Services to start or "all"
	HealthTimeout   time.Duration       `json:"health_timeout"`    // Timeout for health checks
	Dependencies    map[string][]string `json:"dependencies"`      // Graph of dependencies
	ResourceLimits  *ResourceConfig     `json:"resource_limits"`   // CPU/RAM limits
}

// ResourceConfig defines resource limits for services
type ResourceConfig struct {
	MaxCPU     float64 `json:"max_cpu"`     // Maximum CPU usage in cores
	MaxMemory  int64   `json:"max_memory"`  // Maximum memory usage in MiB
	MaxStorage int64   `json:"max_storage"` // Maximum storage usage in MiB
}

// StartupResult contains the results of starting up the infrastructure stack
type StartupResult struct {
	ServicesStarted  []ServiceStatus `json:"services_started"`
	TotalStartupTime time.Duration   `json:"total_startup_time"`
	Warnings         []string        `json:"warnings,omitempty"`
	HealthChecks     map[string]bool `json:"health_checks"`
}

// ShutdownResult contains the results of shutting down the infrastructure stack
type ShutdownResult struct {
	ServicesStopped []string      `json:"services_stopped"`
	TotalTime       time.Duration `json:"total_time"`
	Errors          []string      `json:"errors,omitempty"`
}

// HealthStatus represents the overall health of the infrastructure stack
type HealthStatus struct {
	Timestamp     time.Time                `json:"timestamp"`
	OverallHealth bool                     `json:"overall_health"`
	ServiceHealth map[string]ServiceStatus `json:"service_health"`
	Issues        []string                 `json:"issues,omitempty"`
}

// RecoveryResult contains the result of an automatic recovery attempt
type RecoveryResult struct {
	Timestamp            time.Time     `json:"timestamp"`
	ServicesRecovered    []string      `json:"services_recovered"`
	ServicesNotRecovered []string      `json:"services_not_recovered,omitempty"`
	TotalRecoveryTime    time.Duration `json:"total_recovery_time"`
	Actions              []string      `json:"actions_taken"`
}

// UpdatePlan defines a plan for performing rolling updates
type UpdatePlan struct {
	Services           []string `json:"services"`
	UpdateOrder        []string `json:"update_order"`
	HealthCheckAfter   bool     `json:"health_check_after"`
	BackupBeforeUpdate bool     `json:"backup_before_update"`
	RollbackOnFailure  bool     `json:"rollback_on_failure"`
}

// InfrastructureManager defines the interface for managing infrastructure
type InfrastructureManager interface {
	// StartInfrastructureStack orchestrates the startup of the complete infrastructure
	StartInfrastructureStack(ctx context.Context, config *StackConfig) (*StartupResult, error)

	// StopInfrastructureStack performs a clean shutdown of the infrastructure
	StopInfrastructureStack(ctx context.Context, graceful bool) (*ShutdownResult, error)

	// MonitorInfrastructureHealth continuously monitors the health of the infrastructure
	MonitorInfrastructureHealth(ctx context.Context) (*HealthStatus, error)

	// RecoverFailedServices attempts automatic recovery of failed services
	RecoverFailedServices(ctx context.Context, services []string) (*RecoveryResult, error)

	// PerformRollingUpdate performs rolling updates with minimal downtime
	PerformRollingUpdate(ctx context.Context, updatePlan *UpdatePlan) error
}

// InfrastructureOrchestrator implements the InfrastructureManager interface
type InfrastructureOrchestrator struct {
	config          *config.InfrastructureConfig
	containerClient ContainerManagerClient
	serviceGraph    *ServiceDependencyGraph
	healthMonitor   *HealthMonitor
	lock            sync.RWMutex
	runningServices map[string]*ServiceStatus
	logger          Logger
}

// ContainerManagerClient defines the interface for communicating with ContainerManager
type ContainerManagerClient interface {
	StartContainers(ctx context.Context, services []string) error
	StopContainers(ctx context.Context, services []string, graceful bool) error
	GetContainerStatus(ctx context.Context, service string) (*ServiceStatus, error)
	GetAllContainerStatuses(ctx context.Context) (map[string]*ServiceStatus, error)
}

// ServiceDependencyGraph manages service dependencies
type ServiceDependencyGraph struct {
	dependencies map[string][]string
	lock         sync.RWMutex
}

// HealthMonitor continuously monitors service health
type HealthMonitor struct {
	checkInterval time.Duration
	timeout       time.Duration
	endpoints     map[string]string
	status        map[string]bool
	lock          sync.RWMutex
	stopCh        chan struct{}
}

// Logger provides a structured logging interface
type Logger interface {
	Info(msg string, keyvals ...interface{})
	Error(msg string, keyvals ...interface{})
	Debug(msg string, keyvals ...interface{})
	Warn(msg string, keyvals ...interface{})
}

// NewInfrastructureOrchestrator creates a new instance of InfrastructureOrchestrator
func NewInfrastructureOrchestrator(
	cfg *config.InfrastructureConfig,
	containerClient ContainerManagerClient,
	logger Logger,
) (*InfrastructureOrchestrator, error) {
	if cfg == nil {
		return nil, ErrInvalidConfiguration
	}

	if containerClient == nil {
		return nil, errors.New("container manager client is required")
	}

	// Initialize dependency graph
	graph := &ServiceDependencyGraph{
		dependencies: make(map[string][]string),
	}

	// Initialize health monitor
	healthMonitor := &HealthMonitor{
		checkInterval: cfg.ServiceDiscovery.HealthCheckInterval,
		timeout:       30 * time.Second, // Default timeout
		endpoints:     make(map[string]string),
		status:        make(map[string]bool),
		stopCh:        make(chan struct{}),
	}

	orchestrator := &InfrastructureOrchestrator{
		config:          cfg,
		containerClient: containerClient,
		serviceGraph:    graph,
		healthMonitor:   healthMonitor,
		runningServices: make(map[string]*ServiceStatus),
		logger:          logger,
	}

	return orchestrator, nil
}

// StartInfrastructureStack implements InfrastructureManager.StartInfrastructureStack
func (io *InfrastructureOrchestrator) StartInfrastructureStack(
	ctx context.Context,
	config *StackConfig,
) (*StartupResult, error) {
	startTime := time.Now()
	io.logger.Info("Starting infrastructure stack", "environment", config.Environment)

	// Validate configuration
	if config == nil {
		return nil, ErrInvalidConfiguration
	}

	// Determine services to start
	services := config.ServicesToStart
	if len(services) == 0 || (len(services) == 1 && services[0] == "all") {
		// Start all services defined in configuration
		services = io.getAllServices()
	}

	// Log startup plan
	io.logger.Info("Infrastructure startup plan",
		"services", services,
		"environment", config.Environment,
		"dependencies", len(config.Dependencies))

	// Build dependency graph if specified
	if len(config.Dependencies) > 0 {
		io.serviceGraph.lock.Lock()
		io.serviceGraph.dependencies = config.Dependencies
		io.serviceGraph.lock.Unlock()
	} else {
		// Load dependencies from configuration if not provided in the config
		io.loadDependenciesFromConfig()
	}

	// Create a startup sequencer
	sequencer := NewStartupSequencer(io.serviceGraph, io.healthMonitor, io.containerClient, io.logger)

	// Configure the startup sequence
	sequencerConfig := &StartupSequencerConfig{
		MaxParallelServices: io.getParallelServicesLimit(),
		DefaultTimeout:      config.HealthTimeout,
		RetryAttempts:       io.getRetryAttemptsFromConfig(),
		RetryDelay:          io.getRetryDelayFromConfig(),
	}

	// Execute the startup sequence
	sequenceResult, err := sequencer.StartServices(ctx, services, sequencerConfig)
	if err != nil {
		io.logger.Error("Failed to execute startup sequence", "error", err)
		return nil, fmt.Errorf("startup sequence failed: %w", err)
	}

	// Convert sequence result to StartupResult
	result := &StartupResult{
		ServicesStarted: make([]ServiceStatus, 0, len(services)),
		HealthChecks:    make(map[string]bool),
		Warnings:        make([]string, 0),
	}

	// Process startup result
	for service, serviceResult := range sequenceResult.ServiceResults {
		status := ServiceStatus{
			Name:           service,
			Running:        serviceResult.Successful,
			HealthStatus:   serviceResult.HealthStatus,
			StartupTime:    serviceResult.Duration,
			LastHealthTime: time.Now(),
		}

		result.ServicesStarted = append(result.ServicesStarted, status)
		result.HealthChecks[service] = serviceResult.HealthStatus

		if serviceResult.Error != "" {
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Service %s error: %s", service, serviceResult.Error))
		} else if !serviceResult.HealthStatus {
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Service %s started but not healthy", service))
		}

		// Update internal running services map
		if serviceResult.Successful {
			io.updateRunningServiceStatus(service, &status)
		}
	}

	result.TotalStartupTime = sequenceResult.TotalTime
	io.logger.Info("Infrastructure stack startup completed",
		"duration", result.TotalStartupTime,
		"services_started", len(result.ServicesStarted),
		"warnings", len(result.Warnings))

	return result, nil
}

// StopInfrastructureStack implements InfrastructureManager.StopInfrastructureStack
func (io *InfrastructureOrchestrator) StopInfrastructureStack(
	ctx context.Context,
	graceful bool,
) (*ShutdownResult, error) {
	startTime := time.Now()
	io.logger.Info("Stopping infrastructure stack", "graceful", graceful)

	io.lock.RLock()
	runningServices := make([]string, 0, len(io.runningServices))
	for service := range io.runningServices {
		runningServices = append(runningServices, service)
	}
	io.lock.RUnlock()

	// Get reverse order of services to ensure proper shutdown
	reversedServices, err := io.getShutdownOrder(runningServices)
	if err != nil {
		io.logger.Error("Failed to determine service shutdown order", "error", err)
		return nil, fmt.Errorf("failed to determine service shutdown order: %w", err)
	}

	// Stop services in reverse order
	result := &ShutdownResult{
		ServicesStopped: make([]string, 0, len(reversedServices)),
		Errors:          make([]string, 0),
	}

	for _, service := range reversedServices {
		io.logger.Info("Stopping service", "service", service)
		if err := io.stopService(ctx, service, graceful); err != nil {
			io.logger.Error("Failed to stop service", "service", service, "error", err)
			result.Errors = append(result.Errors, fmt.Sprintf("Failed to stop %s: %v", service, err))
			continue
		}
		result.ServicesStopped = append(result.ServicesStopped, service)
	}

	result.TotalTime = time.Since(startTime)
	io.logger.Info("Infrastructure stack shutdown completed",
		"duration", result.TotalTime,
		"services_stopped", len(result.ServicesStopped),
		"errors", len(result.Errors))

	return result, nil
}

// MonitorInfrastructureHealth implements InfrastructureManager.MonitorInfrastructureHealth
func (io *InfrastructureOrchestrator) MonitorInfrastructureHealth(
	ctx context.Context,
) (*HealthStatus, error) {
	io.logger.Debug("Checking infrastructure health")

	// Get current status from container manager
	containerStatuses, err := io.containerClient.GetAllContainerStatuses(ctx)
	if err != nil {
		io.logger.Error("Failed to get container statuses", "error", err)
		return nil, fmt.Errorf("failed to get container statuses: %w", err)
	}

	healthStatus := &HealthStatus{
		Timestamp:     time.Now(),
		OverallHealth: true,
		ServiceHealth: make(map[string]ServiceStatus),
		Issues:        make([]string, 0),
	}

	// Convert container statuses to service statuses
	for serviceName, containerStatus := range containerStatuses {
		status := ServiceStatus{
			Name:           serviceName,
			Running:        containerStatus.Running,
			HealthStatus:   containerStatus.HealthStatus,
			LastHealthTime: containerStatus.LastHealthTime,
			Endpoint:       containerStatus.Endpoint,
			Errors:         containerStatus.Errors,
		}

		healthStatus.ServiceHealth[serviceName] = status

		// Update overall health
		if !status.HealthStatus {
			healthStatus.OverallHealth = false
			healthStatus.Issues = append(healthStatus.Issues,
				fmt.Sprintf("Service %s is unhealthy", serviceName))
		}
	}

	io.logger.Debug("Infrastructure health check completed",
		"overall_health", healthStatus.OverallHealth,
		"services_checked", len(healthStatus.ServiceHealth),
		"issues", len(healthStatus.Issues))

	return healthStatus, nil
}

// RecoverFailedServices implements InfrastructureManager.RecoverFailedServices
func (io *InfrastructureOrchestrator) RecoverFailedServices(
	ctx context.Context,
	services []string,
) (*RecoveryResult, error) {
	startTime := time.Now()
	io.logger.Info("Attempting recovery of failed services", "services", services)

	result := &RecoveryResult{
		Timestamp:            time.Now(),
		ServicesRecovered:    make([]string, 0),
		ServicesNotRecovered: make([]string, 0),
		Actions:              make([]string, 0),
	}

	for _, service := range services {
		io.logger.Info("Attempting recovery of service", "service", service)

		// Check current status
		status, err := io.containerClient.GetContainerStatus(ctx, service)
		if err != nil {
			io.logger.Error("Failed to get service status", "service", service, "error", err)
			result.ServicesNotRecovered = append(result.ServicesNotRecovered, service)
			continue
		}

		if status.Running && status.HealthStatus {
			io.logger.Info("Service already healthy, skipping recovery", "service", service)
			continue
		}

		// Attempt recovery by restarting
		action := fmt.Sprintf("Restarting service %s", service)
		result.Actions = append(result.Actions, action)

		// Stop service first
		if err := io.stopService(ctx, service, true); err != nil {
			io.logger.Error("Failed to stop service for recovery", "service", service, "error", err)
			result.ServicesNotRecovered = append(result.ServicesNotRecovered, service)
			continue
		}

		// Start service again
		if err := io.startService(ctx, service); err != nil {
			io.logger.Error("Failed to restart service for recovery", "service", service, "error", err)
			result.ServicesNotRecovered = append(result.ServicesNotRecovered, service)
			continue
		}

		// Wait for service to become healthy
		if healthy := io.waitForServiceHealth(ctx, service, 60*time.Second); !healthy {
			io.logger.Error("Service failed to become healthy after restart", "service", service)
			result.ServicesNotRecovered = append(result.ServicesNotRecovered, service)
			continue
		}

		io.logger.Info("Service recovery successful", "service", service)
		result.ServicesRecovered = append(result.ServicesRecovered, service)
	}

	result.TotalRecoveryTime = time.Since(startTime)
	io.logger.Info("Service recovery completed",
		"duration", result.TotalRecoveryTime,
		"recovered", len(result.ServicesRecovered),
		"failed", len(result.ServicesNotRecovered))

	return result, nil
}

// PerformRollingUpdate implements InfrastructureManager.PerformRollingUpdate
func (io *InfrastructureOrchestrator) PerformRollingUpdate(
	ctx context.Context,
	updatePlan *UpdatePlan,
) error {
	io.logger.Info("Starting rolling update", "services", updatePlan.Services)

	// Validate update plan
	if updatePlan == nil || len(updatePlan.Services) == 0 {
		return ErrInvalidConfiguration
	}

	// Use specified order or determine optimal order
	updateOrder := updatePlan.UpdateOrder
	if len(updateOrder) == 0 {
		var err error
		updateOrder, err = io.getStartupOrder(updatePlan.Services)
		if err != nil {
			io.logger.Error("Failed to determine update order", "error", err)
			return fmt.Errorf("failed to determine update order: %w", err)
		}
	}

	// Backup if requested
	if updatePlan.BackupBeforeUpdate {
		// Implementation-specific backup logic would go here
		io.logger.Info("Creating backup before update")
	}

	// Perform rolling update service by service
	for _, service := range updateOrder {
		io.logger.Info("Updating service", "service", service)

		// Stop service
		if err := io.stopService(ctx, service, true); err != nil {
			io.logger.Error("Failed to stop service for update", "service", service, "error", err)
			if updatePlan.RollbackOnFailure {
				io.logger.Warn("Rolling back update due to failure")
				// Implementation-specific rollback logic would go here
				return fmt.Errorf("update failed, rolled back: %w", err)
			}
			return fmt.Errorf("update failed: %w", err)
		}

		// Start service (with new version via container manager)
		if err := io.startService(ctx, service); err != nil {
			io.logger.Error("Failed to start updated service", "service", service, "error", err)
			if updatePlan.RollbackOnFailure {
				io.logger.Warn("Rolling back update due to failure")
				// Implementation-specific rollback logic would go here
				return fmt.Errorf("update failed, rolled back: %w", err)
			}
			return fmt.Errorf("update failed: %w", err)
		}

		// Check health if requested
		if updatePlan.HealthCheckAfter {
			if healthy := io.waitForServiceHealth(ctx, service, 60*time.Second); !healthy {
				io.logger.Error("Updated service failed health check", "service", service)
				if updatePlan.RollbackOnFailure {
					io.logger.Warn("Rolling back update due to failed health check")
					// Implementation-specific rollback logic would go here
					return fmt.Errorf("health check failed after update, rolled back")
				}
				return fmt.Errorf("health check failed after update")
			}
		}

		io.logger.Info("Service updated successfully", "service", service)
	}

	io.logger.Info("Rolling update completed successfully", "services", len(updatePlan.Services))
	return nil
}

// --- Helper methods ---

// startService starts a specific service
func (io *InfrastructureOrchestrator) startService(ctx context.Context, service string) error {
	return io.containerClient.StartContainers(ctx, []string{service})
}

// stopService stops a specific service
func (io *InfrastructureOrchestrator) stopService(ctx context.Context, service string, graceful bool) error {
	return io.containerClient.StopContainers(ctx, []string{service}, graceful)
}

// waitForServiceHealth waits for a service to become healthy with timeout
func (io *InfrastructureOrchestrator) waitForServiceHealth(
	ctx context.Context,
	service string,
	timeout time.Duration,
) bool {
	deadline := time.Now().Add(timeout)
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		if time.Now().After(deadline) {
			io.logger.Warn("Health check timed out", "service", service, "timeout", timeout)
			return false
		}

		status, err := io.containerClient.GetContainerStatus(ctx, service)
		if err != nil {
			io.logger.Error("Failed to check service health", "service", service, "error", err)
		} else if status.HealthStatus {
			return true
		}

		select {
		case <-ctx.Done():
			io.logger.Error("Context cancelled while waiting for service health", "service", service)
			return false
		case <-ticker.C:
			// Continue checking
		}
	}
}

// loadDependenciesFromConfig loads service dependencies from the configuration file
func (io *InfrastructureOrchestrator) loadDependenciesFromConfig() {
	if io.config == nil || io.config.Services == nil {
		io.logger.Warn("No service dependencies defined in configuration")
		return
	}

	dependencies := make(map[string][]string)
	for service, config := range io.config.Services {
		dependencies[service] = config.Requires
	}

	io.serviceGraph.lock.Lock()
	io.serviceGraph.dependencies = dependencies
	io.serviceGraph.lock.Unlock()
}

// getAllServices returns all services defined in configuration
func (io *InfrastructureOrchestrator) getAllServices() []string {
	// In a real implementation, this would parse docker-compose.yml or similar
	// For now, returning a hardcoded list of services from the plan
	return []string{
		"qdrant",
		"redis",
		"postgresql",
		"prometheus",
		"grafana",
		"rag-server",
	}
}

// getParallelServicesLimit returns the maximum number of services to start in parallel
func (io *InfrastructureOrchestrator) getParallelServicesLimit() int {
	if io.config == nil || !io.config.DependencyResolution.ParallelStartEnabled {
		return 1 // Sequential startup
	}

	// Default to 3 parallel services if not specified otherwise
	return 3
}

// getRetryAttemptsFromConfig returns the number of retry attempts from config
func (io *InfrastructureOrchestrator) getRetryAttemptsFromConfig() int {
	if io.config == nil || !io.config.DependencyResolution.RetryFailedServices {
		return 1 // No retries
	}

	return io.config.DependencyResolution.MaxRetries
}

// getRetryDelayFromConfig returns the retry delay from config
func (io *InfrastructureOrchestrator) getRetryDelayFromConfig() time.Duration {
	if io.config == nil {
		return 5 * time.Second // Default delay
	}

	// Calculate backoff based on configuration
	// For simplicity we're using a fixed delay here, but this could be enhanced
	// to implement exponential backoff based on the "exponential" setting
	return 5 * time.Second
}

// updateRunningServiceStatus updates the status of a running service
func (io *InfrastructureOrchestrator) updateRunningServiceStatus(service string, status *ServiceStatus) {
	io.lock.Lock()
	defer io.lock.Unlock()

	io.runningServices[service] = status
}

// getShutdownOrder returns the reverse order for shutdown (stub, à adapter selon la logique réelle)
func (io *InfrastructureOrchestrator) getShutdownOrder(services []string) ([]string, error) {
	reversed := make([]string, len(services))
	for i, s := range services {
		reversed[len(services)-1-i] = s
	}
	return reversed, nil
}

// getStartupOrder returns the order for startup (stub, à adapter selon la logique réelle)
func (io *InfrastructureOrchestrator) getStartupOrder(services []string) ([]string, error) {
	// Ici, on retourne simplement l'ordre reçu
	return services, nil
}
