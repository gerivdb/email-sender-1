// Process Manager with ErrorManager Integration
// Section 1.4 - Implementation des Recommandations - Phase 1

// This module provides a comprehensive Process Manager with full ErrorManager integration
// for managing the lifecycle of other managers and external processes

package processmanager

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"syscall"
	"time"

	errormanager "EMAIL_SENDER_1/managers/error-manager"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// ProcessManager manages the lifecycle of other managers and external processes
type ProcessManager struct {
	processes      map[string]*ManagedProcess
	manifests      map[string]*ManagerManifest
	config         *Config
	logger         *zap.Logger
	errorManager   *ErrorManager
	mu             sync.RWMutex
	circuitBreaker *CircuitBreaker
}

// ManagedProcess represents a process under management
type ManagedProcess struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Command     string                 `json:"command"`
	Args        []string               `json:"args"`
	Env         map[string]string      `json:"env"`
	Status      ProcessStatus          `json:"status"`
	PID         int                    `json:"pid"`
	StartTime   time.Time              `json:"start_time"`
	Retries     int                    `json:"retries"`
	MaxRetries  int                    `json:"max_retries"`
	HealthCheck *HealthCheckConfig     `json:"health_check"`
	Context     map[string]interface{} `json:"context"`
	cmd         *exec.Cmd
	cancel      context.CancelFunc
}

// ManagerManifest describes a manager's capabilities and requirements
type ManagerManifest struct {
	Name         string                 `json:"name"`
	Version      string                 `json:"version"`
	Type         string                 `json:"type"` // go, powershell, node, etc.
	Command      string                 `json:"command"`
	Args         []string               `json:"args"`
	Dependencies []string               `json:"dependencies"`
	HealthCheck  *HealthCheckConfig     `json:"health_check"`
	Tasks        []TaskDefinition       `json:"tasks"`
	Metadata     map[string]interface{} `json:"metadata"`
}

// TaskDefinition describes a task that can be executed
type TaskDefinition struct {
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Command     string                 `json:"command"`
	Args        []string               `json:"args"`
	Timeout     time.Duration          `json:"timeout"`
	Context     map[string]interface{} `json:"context"`
}

// HealthCheckConfig defines health check parameters
type HealthCheckConfig struct {
	Enabled      bool          `json:"enabled"`
	Interval     time.Duration `json:"interval"`
	Timeout      time.Duration `json:"timeout"`
	Retries      int           `json:"retries"`
	Endpoint     string        `json:"endpoint,omitempty"`
	Command      string        `json:"command,omitempty"`
	ExpectedExit int           `json:"expected_exit"`
}

// ProcessStatus represents the status of a managed process
type ProcessStatus string

const (
	StatusStopped  ProcessStatus = "stopped"
	StatusStarting ProcessStatus = "starting"
	StatusRunning  ProcessStatus = "running"
	StatusStopping ProcessStatus = "stopping"
	StatusFailed   ProcessStatus = "failed"
	StatusUnknown  ProcessStatus = "unknown"
)

// Config holds the process manager configuration
type Config struct {
	MaxProcesses        int                  `json:"max_processes"`
	DefaultTimeout      time.Duration        `json:"default_timeout"`
	HealthCheckInterval time.Duration        `json:"health_check_interval"`
	ManifestDir         string               `json:"manifest_dir"`
	LogLevel            string               `json:"log_level"`
	CircuitBreaker      CircuitBreakerConfig `json:"circuit_breaker"`
}

// CircuitBreakerConfig holds circuit breaker configuration
type CircuitBreakerConfig struct {
	Enabled          bool          `json:"enabled"`
	FailureThreshold int           `json:"failure_threshold"`
	ResetTimeout     time.Duration `json:"reset_timeout"`
	MaxRequests      int           `json:"max_requests"`
}

// ErrorManager encapsulates error management functionality
type ErrorManager struct {
	logger *zap.Logger
}

// CircuitBreaker provides circuit breaker functionality for process operations
type CircuitBreaker struct {
	enabled          bool
	failureThreshold int
	resetTimeout     time.Duration
	maxRequests      int
	failures         int
	lastFailureTime  time.Time
	state            string // CLOSED, OPEN, HALF_OPEN
	mu               sync.Mutex
}

// NewProcessManager creates a new ProcessManager with ErrorManager integration
func NewProcessManager(config *Config) *ProcessManager {
	logger, _ := zap.NewProduction()

	errorManager := &ErrorManager{
		logger: logger,
	}

	circuitBreaker := &CircuitBreaker{
		enabled:          config.CircuitBreaker.Enabled,
		failureThreshold: config.CircuitBreaker.FailureThreshold,
		resetTimeout:     config.CircuitBreaker.ResetTimeout,
		maxRequests:      config.CircuitBreaker.MaxRequests,
		state:            "CLOSED",
	}

	return &ProcessManager{
		processes:      make(map[string]*ManagedProcess),
		manifests:      make(map[string]*ManagerManifest),
		config:         config,
		logger:         logger,
		errorManager:   errorManager,
		circuitBreaker: circuitBreaker,
	}
}

// ProcessError handles and catalogs errors with ErrorManager integration
func (em *ErrorManager) ProcessError(ctx context.Context, err error, component, operation string) error { // Create error entry
	entry := errormanager.ErrorEntry{
		ID:             uuid.New().String(),
		Timestamp:      time.Now(),
		Message:        err.Error(),
		Module:         "process-manager",
		ErrorCode:      determineErrorCode(err, operation),
		ManagerContext: fmt.Sprintf("Component: %s, Operation: %s", component, operation),
		Severity:       determineSeverity(err),
		StackTrace:     fmt.Sprintf("%+v", err),
	}

	// Validate error entry
	if validationErr := errormanager.ValidateErrorEntry(entry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("original_error", err.Error()),
			zap.String("component", component),
			zap.String("operation", operation))
		return err
	}

	// Catalog error
	errormanager.CatalogError(entry)

	// Log with context
	em.logger.Error("Process manager error",
		zap.Error(err),
		zap.String("component", component),
		zap.String("operation", operation),
		zap.String("error_id", entry.ID),
		zap.String("severity", entry.Severity))

	return err
}

// StartProcess starts a new managed process
func (pm *ProcessManager) StartProcess(name, command string, args []string, env map[string]string) (*ManagedProcess, error) {
	ctx := context.Background()

	if !pm.circuitBreaker.CanExecute() {
		err := fmt.Errorf("circuit breaker is open for process operations")
		return nil, pm.errorManager.ProcessError(ctx, err, "circuit-breaker", "start_process")
	}

	pm.mu.Lock()
	defer pm.mu.Unlock()

	// Check if process already exists
	if _, exists := pm.processes[name]; exists {
		err := fmt.Errorf("process %s already exists", name)
		pm.circuitBreaker.RecordFailure()
		return nil, pm.errorManager.ProcessError(ctx, err, "process-lifecycle", "start_process")
	}

	// Check max processes limit
	if len(pm.processes) >= pm.config.MaxProcesses {
		err := fmt.Errorf("maximum number of processes (%d) reached", pm.config.MaxProcesses)
		pm.circuitBreaker.RecordFailure()
		return nil, pm.errorManager.ProcessError(ctx, err, "resource-management", "start_process")
	}

	// Create managed process
	process := &ManagedProcess{
		ID:         uuid.New().String(),
		Name:       name,
		Command:    command,
		Args:       args,
		Env:        env,
		Status:     StatusStarting,
		StartTime:  time.Now(),
		MaxRetries: 3,
		Context:    make(map[string]interface{}),
	}

	// Start the process
	if err := pm.startProcessExecution(process); err != nil {
		pm.circuitBreaker.RecordFailure()
		return nil, pm.errorManager.ProcessError(ctx, err, "process-execution", "start_process")
	}

	pm.processes[name] = process
	pm.circuitBreaker.RecordSuccess()

	pm.logger.Info("Process started successfully",
		zap.String("name", name),
		zap.String("id", process.ID),
		zap.Int("pid", process.PID))

	return process, nil
}

// startProcessExecution handles the actual process execution
func (pm *ProcessManager) startProcessExecution(process *ManagedProcess) error {
	ctx, cancel := context.WithTimeout(context.Background(), pm.config.DefaultTimeout)
	process.cancel = cancel

	cmd := exec.CommandContext(ctx, process.Command, process.Args...)

	// Set environment variables
	cmd.Env = os.Environ()
	for key, value := range process.Env {
		cmd.Env = append(cmd.Env, fmt.Sprintf("%s=%s", key, value))
	}

	// Start the process
	if err := cmd.Start(); err != nil {
		process.Status = StatusFailed
		return fmt.Errorf("failed to start process: %w", err)
	}

	process.cmd = cmd
	process.PID = cmd.Process.Pid
	process.Status = StatusRunning

	// Monitor process in goroutine
	go pm.monitorProcess(process)

	return nil
}

// monitorProcess monitors a running process
func (pm *ProcessManager) monitorProcess(process *ManagedProcess) {
	defer func() {
		if process.cancel != nil {
			process.cancel()
		}
	}()

	// Wait for process to complete
	err := process.cmd.Wait()

	pm.mu.Lock()
	defer pm.mu.Unlock()

	if err != nil {
		process.Status = StatusFailed
		pm.errorManager.ProcessError(context.Background(), err, "process-monitoring", "process_wait")

		// Retry logic
		if process.Retries < process.MaxRetries {
			process.Retries++
			pm.logger.Warn("Process failed, retrying",
				zap.String("name", process.Name),
				zap.Int("retry", process.Retries),
				zap.Int("max_retries", process.MaxRetries))

			// Restart process after delay
			go func() {
				time.Sleep(time.Second * 5)
				pm.startProcessExecution(process)
			}()
			return
		}
	} else {
		process.Status = StatusStopped
	}

	pm.logger.Info("Process monitoring completed",
		zap.String("name", process.Name),
		zap.String("status", string(process.Status)))
}

// StopProcess stops a managed process
func (pm *ProcessManager) StopProcess(name string) error {
	ctx := context.Background()

	pm.mu.Lock()
	defer pm.mu.Unlock()

	process, exists := pm.processes[name]
	if !exists {
		err := fmt.Errorf("process %s not found", name)
		return pm.errorManager.ProcessError(ctx, err, "process-lifecycle", "stop_process")
	}

	if process.Status != StatusRunning {
		err := fmt.Errorf("process %s is not running (status: %s)", name, process.Status)
		return pm.errorManager.ProcessError(ctx, err, "process-lifecycle", "stop_process")
	}

	process.Status = StatusStopping

	// Send termination signal
	if process.cmd != nil && process.cmd.Process != nil {
		if err := process.cmd.Process.Signal(syscall.SIGTERM); err != nil {
			// Force kill if graceful termination fails
			if killErr := process.cmd.Process.Kill(); killErr != nil {
				err = fmt.Errorf("failed to kill process: %w", killErr)
				return pm.errorManager.ProcessError(ctx, err, "process-termination", "stop_process")
			}
		}
	}

	if process.cancel != nil {
		process.cancel()
	}

	process.Status = StatusStopped
	pm.logger.Info("Process stopped", zap.String("name", name))

	return nil
}

// GetProcessStatus returns the status of a managed process
func (pm *ProcessManager) GetProcessStatus(name string) (*ManagedProcess, error) {
	ctx := context.Background()

	pm.mu.RLock()
	defer pm.mu.RUnlock()

	process, exists := pm.processes[name]
	if !exists {
		err := fmt.Errorf("process %s not found", name)
		return nil, pm.errorManager.ProcessError(ctx, err, "process-query", "get_status")
	}

	// Create a copy to avoid data races
	processCopy := *process
	return &processCopy, nil
}

// ListProcesses returns all managed processes
func (pm *ProcessManager) ListProcesses() map[string]*ManagedProcess {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	result := make(map[string]*ManagedProcess)
	for name, process := range pm.processes {
		processCopy := *process
		result[name] = &processCopy
	}

	return result
}

// LoadManifests loads manager manifests from the manifest directory
func (pm *ProcessManager) LoadManifests() error {
	pm.logger.Info("Loading manager manifests",
		zap.String("manifest_dir", pm.config.ManifestDir))

	// Implementation would scan the manifest directory and load .json files
	// For now, this is a placeholder
	pm.logger.Info("Manifest loading completed")

	return nil
}

// ExecuteTask executes a task defined in a manager manifest
func (pm *ProcessManager) ExecuteTask(managerName, taskName string, params map[string]interface{}) error {
	ctx := context.Background()

	manifest, exists := pm.manifests[managerName]
	if !exists {
		err := fmt.Errorf("manager %s not found", managerName)
		return pm.errorManager.ProcessError(ctx, err, "task-execution", "execute_task")
	}

	// Find the task
	var task *TaskDefinition
	for _, t := range manifest.Tasks {
		if t.Name == taskName {
			task = &t
			break
		}
	}

	if task == nil {
		err := fmt.Errorf("task %s not found in manager %s", taskName, managerName)
		return pm.errorManager.ProcessError(ctx, err, "task-execution", "execute_task")
	}

	pm.logger.Info("Executing task",
		zap.String("manager", managerName),
		zap.String("task", taskName))

	// Execute the task (implementation would handle different manager types)
	return nil
}

// HealthCheck performs health checks on all managed processes
func (pm *ProcessManager) HealthCheck() map[string]bool {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	results := make(map[string]bool)

	for name, process := range pm.processes {
		healthy := pm.checkProcessHealth(process)
		results[name] = healthy

		if !healthy {
			pm.errorManager.ProcessError(context.Background(),
				fmt.Errorf("health check failed for process %s", name),
				"health-check", "periodic_check")
		}
	}

	return results
}

// checkProcessHealth checks if a process is healthy
func (pm *ProcessManager) checkProcessHealth(process *ManagedProcess) bool {
	if process.Status != StatusRunning {
		return false
	}

	if process.cmd == nil || process.cmd.Process == nil {
		return false
	}

	// Check if process is still running
	if err := process.cmd.Process.Signal(syscall.Signal(0)); err != nil {
		return false
	}

	return true
}

// Shutdown gracefully shuts down the process manager
func (pm *ProcessManager) Shutdown() error {
	pm.logger.Info("Shutting down process manager")

	pm.mu.Lock()
	defer pm.mu.Unlock()

	// Stop all processes
	for name := range pm.processes {
		if err := pm.StopProcess(name); err != nil {
			pm.logger.Error("Failed to stop process during shutdown",
				zap.String("name", name),
				zap.Error(err))
		}
	}

	pm.logger.Info("Process manager shutdown completed")
	return nil
}

// Circuit Breaker methods

// CanExecute checks if the circuit breaker allows execution
func (cb *CircuitBreaker) CanExecute() bool {
	if !cb.enabled {
		return true
	}

	cb.mu.Lock()
	defer cb.mu.Unlock()

	switch cb.state {
	case "CLOSED":
		return true
	case "OPEN":
		if time.Since(cb.lastFailureTime) > cb.resetTimeout {
			cb.state = "HALF_OPEN"
			return true
		}
		return false
	case "HALF_OPEN":
		return true
	default:
		return true
	}
}

// RecordSuccess records a successful operation
func (cb *CircuitBreaker) RecordSuccess() {
	if !cb.enabled {
		return
	}

	cb.mu.Lock()
	defer cb.mu.Unlock()

	cb.failures = 0
	cb.state = "CLOSED"
}

// RecordFailure records a failed operation
func (cb *CircuitBreaker) RecordFailure() {
	if !cb.enabled {
		return
	}

	cb.mu.Lock()
	defer cb.mu.Unlock()

	cb.failures++
	cb.lastFailureTime = time.Now()

	if cb.failures >= cb.failureThreshold {
		cb.state = "OPEN"
	}
}

// Helper functions

// determineErrorCode determines error code based on error type and operation
func determineErrorCode(err error, operation string) string {
	switch operation {
	case "start_process":
		return "PROC_START_ERROR"
	case "stop_process":
		return "PROC_STOP_ERROR"
	case "process_wait":
		return "PROC_WAIT_ERROR"
	case "execute_task":
		return "TASK_EXEC_ERROR"
	case "health_check":
		return "HEALTH_CHECK_ERROR"
	default:
		return "GENERAL_PROC_ERROR"
	}
}

// determineSeverity determines error severity based on error message
func determineSeverity(err error) string {
	message := err.Error()
	switch {
	case contains(message, "critical", "fatal", "panic"):
		return "critical"
	case contains(message, "timeout", "failed to start", "kill"):
		return "high"
	case contains(message, "warning", "retry"):
		return "medium"
	default:
		return "low"
	}
}

// contains checks if text contains any of the keywords
func contains(text string, keywords ...string) bool {
	for _, keyword := range keywords {
		if len(text) >= len(keyword) {
			for i := 0; i <= len(text)-len(keyword); i++ {
				if text[i:i+len(keyword)] == keyword {
					return true
				}
			}
		}
	}
	return false
}
