// Script Manager with ErrorManager Integration
// Section 1.4 - Implementation des Recommandations - Phase 1

// This module provides a comprehensive Script Manager with full ErrorManager integration
// for executing, managing, and monitoring PowerShell and other scripts

package scriptmanager

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
	errormanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/error-manager"
)

// ScriptManager manages script execution and lifecycle with ErrorManager integration
type ScriptManager struct {
	config         *Config
	logger         *zap.Logger
	errorManager   *ErrorManager
	circuitBreaker *CircuitBreaker
	scripts        map[string]*ManagedScript
	modules        map[string]*ScriptModule
	templates      map[string]*ScriptTemplate
	executors      map[string]ScriptExecutor
	mu             sync.RWMutex
	ctx            context.Context
	cancel         context.CancelFunc
}

// ManagedScript represents a script under management
type ManagedScript struct {
	ID           string                 `json:"id"`
	Name         string                 `json:"name"`
	Path         string                 `json:"path"`
	Type         ScriptType             `json:"type"`
	Status       ScriptStatus           `json:"status"`
	LastRun      time.Time              `json:"last_run"`
	RunCount     int                    `json:"run_count"`
	SuccessCount int                    `json:"success_count"`
	ErrorCount   int                    `json:"error_count"`
	Dependencies []string               `json:"dependencies"`
	Parameters   map[string]interface{} `json:"parameters"`
	Metadata     map[string]string      `json:"metadata"`
	Timeout      time.Duration          `json:"timeout"`
	RetryPolicy  *RetryPolicy           `json:"retry_policy"`
	mu           sync.RWMutex           `json:"-"`
}

// ScriptModule represents a PowerShell module or script library
type ScriptModule struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Path        string            `json:"path"`
	Version     string            `json:"version"`
	Functions   []string          `json:"functions"`
	Dependencies []string          `json:"dependencies"`
	Metadata    map[string]string `json:"metadata"`
	IsLoaded    bool              `json:"is_loaded"`
}

// ScriptTemplate represents a script template for generation
type ScriptTemplate struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Category    string                 `json:"category"`
	Description string                 `json:"description"`
	Template    string                 `json:"template"`
	Parameters  []TemplateParameter    `json:"parameters"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// TemplateParameter represents a template parameter
type TemplateParameter struct {
	Name         string      `json:"name"`
	Type         string      `json:"type"`
	Required     bool        `json:"required"`
	DefaultValue interface{} `json:"default_value"`
	Description  string      `json:"description"`
}

// ScriptType defines the type of script
type ScriptType string

const (
	ScriptTypePowerShell ScriptType = "powershell"
	ScriptTypePython     ScriptType = "python"
	ScriptTypeJavaScript ScriptType = "javascript"
	ScriptTypeBash       ScriptType = "bash"
	ScriptTypeBatch      ScriptType = "batch"
)

// ScriptStatus defines the status of a script
type ScriptStatus string

const (
	ScriptStatusIdle    ScriptStatus = "idle"
	ScriptStatusRunning ScriptStatus = "running"
	ScriptStatusSuccess ScriptStatus = "success"
	ScriptStatusFailed  ScriptStatus = "failed"
	ScriptStatusTimeout ScriptStatus = "timeout"
)

// ScriptExecutor interface for different script types
type ScriptExecutor interface {
	Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
	Validate(script *ManagedScript) error
	GetDefaultTimeout() time.Duration
	SupportsType(scriptType ScriptType) bool
}

// ExecutionResult represents the result of script execution
type ExecutionResult struct {
	Success      bool                   `json:"success"`
	ExitCode     int                    `json:"exit_code"`
	Output       string                 `json:"output"`
	Error        string                 `json:"error"`
	Duration     time.Duration          `json:"duration"`
	StartTime    time.Time              `json:"start_time"`
	EndTime      time.Time              `json:"end_time"`
	Metadata     map[string]interface{} `json:"metadata"`
	RetryAttempt int                    `json:"retry_attempt"`
}

// RetryPolicy defines retry behavior for failed scripts
type RetryPolicy struct {
	MaxAttempts int           `json:"max_attempts"`
	BackoffType BackoffType   `json:"backoff_type"`
	InitialWait time.Duration `json:"initial_wait"`
	MaxWait     time.Duration `json:"max_wait"`
	Multiplier  float64       `json:"multiplier"`
}

// BackoffType defines the type of backoff strategy
type BackoffType string

const (
	BackoffFixed       BackoffType = "fixed"
	BackoffLinear      BackoffType = "linear"
	BackoffExponential BackoffType = "exponential"
)

// Config defines the configuration for the Script Manager
type Config struct {
	ScriptPaths        map[string]string `json:"script_paths"`
	ModulePaths        []string          `json:"module_paths"`
	TemplatePaths      []string          `json:"template_paths"`
	DefaultTimeout     time.Duration     `json:"default_timeout"`
	MaxConcurrent      int               `json:"max_concurrent"`
	AllowedExtensions  []string          `json:"allowed_extensions"`
	ExecutionMode      string            `json:"execution_mode"`
	EnableLogging      bool              `json:"enable_logging"`
	EnableMonitoring   bool              `json:"enable_monitoring"`
	EnableCache        bool              `json:"enable_cache"`
	CacheDirectory     string            `json:"cache_directory"`
	TempDirectory      string            `json:"temp_directory"`
	PowerShellExePath  string            `json:"powershell_exe_path"`
	PythonExePath      string            `json:"python_exe_path"`
	NodeExePath        string            `json:"node_exe_path"`
}

// ErrorManager provides centralized error handling
type ErrorManager struct {
	logger *zap.Logger
}

// ErrorHooks defines error handling hooks
type ErrorHooks struct {
	OnError    func(err error, context map[string]interface{})
	OnRecovery func(err error, context map[string]interface{})
}

// CircuitBreaker provides resilience patterns (placeholder for integration)
type CircuitBreaker struct {
	// Implementation from existing circuit-breaker module
}

// NewScriptManager creates a new Script Manager with ErrorManager integration
func NewScriptManager(config *Config) *ScriptManager {
	ctx, cancel := context.WithCancel(context.Background())
	
	logger, _ := zap.NewProduction()
	
	errorManager := &ErrorManager{
		logger: logger,
	}
	
	sm := &ScriptManager{
		config:       config,
		logger:       logger,
		errorManager: errorManager,
		scripts:      make(map[string]*ManagedScript),
		modules:      make(map[string]*ScriptModule),
		templates:    make(map[string]*ScriptTemplate),
		executors:    make(map[string]ScriptExecutor),
		ctx:          ctx,
		cancel:       cancel,
	}
	
	// Initialize default executors
	sm.initializeExecutors()
	
	// Load existing scripts and modules
	sm.discoverAndLoadScripts()
	sm.discoverAndLoadModules()
	sm.discoverAndLoadTemplates()
	
	logger.Info("Script Manager initialized successfully",
		zap.Int("scripts_loaded", len(sm.scripts)),
		zap.Int("modules_loaded", len(sm.modules)),
		zap.Int("templates_loaded", len(sm.templates)))
	
	return sm
}

// ProcessError handles errors through the centralized ErrorManager system
func (em *ErrorManager) ProcessError(ctx context.Context, err error, hooks *ErrorHooks) error {
	// Create error entry
	entry := errormanager.ErrorEntry{
		ID:             uuid.New().String(),
		Timestamp:      time.Now(),
		Message:        err.Error(),
		Module:         "script-manager",
		ErrorCode:      "SCRIPT_ERROR_001",
		ManagerContext: "Script operation failed",
		Severity:       em.determineSeverity(err),
		StackTrace:     fmt.Sprintf("%+v", err),
	}

	// Validate error entry
	if validationErr := errormanager.ValidateErrorEntry(entry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("original_error", err.Error()))
		return err
	}

	// Catalog the error
	errormanager.CatalogError(entry)

	// Execute hooks if provided
	if hooks != nil && hooks.OnError != nil {
		hooks.OnError(err, map[string]interface{}{
			"module":      "script-manager",
			"error_id":    entry.ID,
			"timestamp":   entry.Timestamp,
			"error_code":  entry.ErrorCode,
		})
	}

	em.logger.Error("Script Manager error processed",
		zap.String("error_id", entry.ID),
		zap.String("error_code", entry.ErrorCode),
		zap.String("severity", entry.Severity),
		zap.Error(err))

	return err
}

// determineSeverity determines error severity based on error content
func (em *ErrorManager) determineSeverity(err error) string {
	errorMsg := strings.ToLower(err.Error())
	
	// Critical errors
	if strings.Contains(errorMsg, "system") ||
		strings.Contains(errorMsg, "critical") ||
		strings.Contains(errorMsg, "panic") ||
		strings.Contains(errorMsg, "fatal") {
		return "critical"
	}
	
	// High severity errors
	if strings.Contains(errorMsg, "permission") ||
		strings.Contains(errorMsg, "access denied") ||
		strings.Contains(errorMsg, "execution policy") ||
		strings.Contains(errorMsg, "module not found") {
		return "high"
	}
	
	// Medium severity errors
	if strings.Contains(errorMsg, "timeout") ||
		strings.Contains(errorMsg, "connection") ||
		strings.Contains(errorMsg, "syntax") ||
		strings.Contains(errorMsg, "parameter") {
		return "medium"
	}
	
	// Default to low severity
	return "low"
}

// initializeExecutors initializes script executors for different script types
func (sm *ScriptManager) initializeExecutors() {
	sm.executors["powershell"] = &PowerShellExecutor{
		config: sm.config,
		logger: sm.logger,
	}
	
	sm.executors["python"] = &PythonExecutor{
		config: sm.config,
		logger: sm.logger,
	}
	
	sm.executors["javascript"] = &JavaScriptExecutor{
		config: sm.config,
		logger: sm.logger,
	}
	
	if runtime.GOOS != "windows" {
		sm.executors["bash"] = &BashExecutor{
			config: sm.config,
			logger: sm.logger,
		}
	} else {
		sm.executors["batch"] = &BatchExecutor{
			config: sm.config,
			logger: sm.logger,
		}
	}
}

// discoverAndLoadScripts discovers and loads scripts from configured paths
func (sm *ScriptManager) discoverAndLoadScripts() {
	hooks := &ErrorHooks{
		OnError: func(err error, context map[string]interface{}) {
			sm.logger.Warn("Script discovery error", zap.Error(err), zap.Any("context", context))
		},
	}
	
	for category, path := range sm.config.ScriptPaths {
		if err := sm.scanScriptsInPath(path, category); err != nil {
			sm.errorManager.ProcessError(sm.ctx, err, hooks)
		}
	}
}

// scanScriptsInPath scans a directory for scripts
func (sm *ScriptManager) scanScriptsInPath(path, category string) error {
	return filepath.Walk(path, func(filePath string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if info.IsDir() {
			return nil
		}
		
		// Check if file extension is allowed
		ext := strings.ToLower(filepath.Ext(filePath))
		allowed := false
		for _, allowedExt := range sm.config.AllowedExtensions {
			if ext == allowedExt {
				allowed = true
				break
			}
		}
		
		if !allowed {
			return nil
		}
		
		// Create managed script
		script := &ManagedScript{
			ID:           uuid.New().String(),
			Name:         strings.TrimSuffix(info.Name(), ext),
			Path:         filePath,
			Type:         sm.getScriptType(ext),
			Status:       ScriptStatusIdle,
			Dependencies: []string{},
			Parameters:   make(map[string]interface{}),
			Metadata:     map[string]string{"category": category},
			Timeout:      sm.config.DefaultTimeout,
			RetryPolicy: &RetryPolicy{
				MaxAttempts: 3,
				BackoffType: BackoffExponential,
				InitialWait: 1 * time.Second,
				MaxWait:     60 * time.Second,
				Multiplier:  2.0,
			},
		}
		
		sm.mu.Lock()
		sm.scripts[script.ID] = script
		sm.mu.Unlock()
		
		sm.logger.Debug("Script discovered",
			zap.String("script_id", script.ID),
			zap.String("name", script.Name),
			zap.String("path", script.Path),
			zap.String("type", string(script.Type)))
		
		return nil
	})
}

// getScriptType determines script type from file extension
func (sm *ScriptManager) getScriptType(ext string) ScriptType {
	switch strings.ToLower(ext) {
	case ".ps1", ".psm1":
		return ScriptTypePowerShell
	case ".py":
		return ScriptTypePython
	case ".js":
		return ScriptTypeJavaScript
	case ".sh":
		return ScriptTypeBash
	case ".bat", ".cmd":
		return ScriptTypeBatch
	default:
		return ScriptTypePowerShell // Default to PowerShell
	}
}

// discoverAndLoadModules discovers and loads PowerShell modules
func (sm *ScriptManager) discoverAndLoadModules() {
	hooks := &ErrorHooks{
		OnError: func(err error, context map[string]interface{}) {
			sm.logger.Warn("Module discovery error", zap.Error(err), zap.Any("context", context))
		},
	}
	
	for _, path := range sm.config.ModulePaths {
		if err := sm.scanModulesInPath(path); err != nil {
			sm.errorManager.ProcessError(sm.ctx, err, hooks)
		}
	}
}

// scanModulesInPath scans a directory for PowerShell modules
func (sm *ScriptManager) scanModulesInPath(path string) error {
	return filepath.Walk(path, func(filePath string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if info.IsDir() {
			return nil
		}
		
		ext := strings.ToLower(filepath.Ext(filePath))
		if ext != ".psm1" {
			return nil
		}
		
		// Create script module
		module := &ScriptModule{
			ID:           uuid.New().String(),
			Name:         strings.TrimSuffix(info.Name(), ext),
			Path:         filePath,
			Version:      "1.0.0", // Default version
			Functions:    []string{},
			Dependencies: []string{},
			Metadata:     make(map[string]string),
			IsLoaded:     false,
		}
		
		sm.mu.Lock()
		sm.modules[module.ID] = module
		sm.mu.Unlock()
		
		sm.logger.Debug("Module discovered",
			zap.String("module_id", module.ID),
			zap.String("name", module.Name),
			zap.String("path", module.Path))
		
		return nil
	})
}

// discoverAndLoadTemplates discovers and loads script templates
func (sm *ScriptManager) discoverAndLoadTemplates() {
	hooks := &ErrorHooks{
		OnError: func(err error, context map[string]interface{}) {
			sm.logger.Warn("Template discovery error", zap.Error(err), zap.Any("context", context))
		},
	}
	
	for _, path := range sm.config.TemplatePaths {
		if err := sm.scanTemplatesInPath(path); err != nil {
			sm.errorManager.ProcessError(sm.ctx, err, hooks)
		}
	}
}

// scanTemplatesInPath scans a directory for script templates
func (sm *ScriptManager) scanTemplatesInPath(path string) error {
	return filepath.Walk(path, func(filePath string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if info.IsDir() {
			return nil
		}
		
		ext := strings.ToLower(filepath.Ext(filePath))
		if ext != ".json" {
			return nil
		}
		
		// Load template configuration
		data, err := ioutil.ReadFile(filePath)
		if err != nil {
			return err
		}
		
		var template ScriptTemplate
		if err := json.Unmarshal(data, &template); err != nil {
			return err
		}
		
		if template.ID == "" {
			template.ID = uuid.New().String()
		}
		
		sm.mu.Lock()
		sm.templates[template.ID] = &template
		sm.mu.Unlock()
		
		sm.logger.Debug("Template discovered",
			zap.String("template_id", template.ID),
			zap.String("name", template.Name),
			zap.String("category", template.Category))
		
		return nil
	})
}

// ExecuteScript executes a script with the specified parameters
func (sm *ScriptManager) ExecuteScript(scriptID string, parameters map[string]interface{}) (*ExecutionResult, error) {
	sm.mu.RLock()
	script, exists := sm.scripts[scriptID]
	sm.mu.RUnlock()
	
	if !exists {
		err := fmt.Errorf("script not found: %s", scriptID)
		hooks := &ErrorHooks{
			OnError: func(err error, context map[string]interface{}) {
				sm.logger.Error("Script execution failed", zap.Error(err), zap.Any("context", context))
			},
		}
		sm.errorManager.ProcessError(sm.ctx, err, hooks)
		return nil, err
	}
	
	// Get executor for script type
	executor, exists := sm.executors[string(script.Type)]
	if !exists {
		err := fmt.Errorf("no executor found for script type: %s", script.Type)
		hooks := &ErrorHooks{
			OnError: func(err error, context map[string]interface{}) {
				sm.logger.Error("Script executor not found", zap.Error(err), zap.Any("context", context))
			},
		}
		sm.errorManager.ProcessError(sm.ctx, err, hooks)
		return nil, err
	}
	
	// Update script status
	script.mu.Lock()
	script.Status = ScriptStatusRunning
	script.LastRun = time.Now()
	script.RunCount++
	script.mu.Unlock()
	
	// Create execution context with timeout
	ctx, cancel := context.WithTimeout(sm.ctx, script.Timeout)
	defer cancel()
	
	// Execute script
	result, err := executor.Execute(ctx, script, parameters)
	
	// Update script status based on result
	script.mu.Lock()
	if err != nil || !result.Success {
		script.Status = ScriptStatusFailed
		script.ErrorCount++
		
		// Handle retry logic if configured
		if script.RetryPolicy != nil && result.RetryAttempt < script.RetryPolicy.MaxAttempts {
			script.mu.Unlock()
			return sm.retryScriptExecution(script, parameters, result.RetryAttempt+1)
		}
	} else {
		script.Status = ScriptStatusSuccess
		script.SuccessCount++
	}
	script.mu.Unlock()
	
	if err != nil {
		hooks := &ErrorHooks{
			OnError: func(err error, context map[string]interface{}) {
				sm.logger.Error("Script execution error",
					zap.Error(err),
					zap.String("script_id", scriptID),
					zap.String("script_name", script.Name),
					zap.Any("context", context))
			},
		}
		sm.errorManager.ProcessError(sm.ctx, err, hooks)
	}
	
	sm.logger.Info("Script execution completed",
		zap.String("script_id", scriptID),
		zap.String("script_name", script.Name),
		zap.Bool("success", result.Success),
		zap.Duration("duration", result.Duration),
		zap.Int("exit_code", result.ExitCode))
	
	return result, err
}

// retryScriptExecution retries script execution with backoff
func (sm *ScriptManager) retryScriptExecution(script *ManagedScript, parameters map[string]interface{}, attempt int) (*ExecutionResult, error) {
	// Calculate backoff delay
	var delay time.Duration
	switch script.RetryPolicy.BackoffType {
	case BackoffFixed:
		delay = script.RetryPolicy.InitialWait
	case BackoffLinear:
		delay = script.RetryPolicy.InitialWait * time.Duration(attempt)
	case BackoffExponential:
		delay = script.RetryPolicy.InitialWait * time.Duration(float64(attempt)*script.RetryPolicy.Multiplier)
	}
	
	if delay > script.RetryPolicy.MaxWait {
		delay = script.RetryPolicy.MaxWait
	}
	
	sm.logger.Info("Retrying script execution",
		zap.String("script_id", script.ID),
		zap.Int("attempt", attempt),
		zap.Duration("delay", delay))
	
	// Wait before retry
	select {
	case <-time.After(delay):
	case <-sm.ctx.Done():
		return nil, sm.ctx.Err()
	}
	
	// Get executor and retry
	executor := sm.executors[string(script.Type)]
	ctx, cancel := context.WithTimeout(sm.ctx, script.Timeout)
	defer cancel()
	
	result, err := executor.Execute(ctx, script, parameters)
	result.RetryAttempt = attempt
	
	return result, err
}

// ListScripts returns a list of all managed scripts
func (sm *ScriptManager) ListScripts() []*ManagedScript {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	scripts := make([]*ManagedScript, 0, len(sm.scripts))
	for _, script := range sm.scripts {
		scripts = append(scripts, script)
	}
	
	return scripts
}

// GetScript returns a specific script by ID
func (sm *ScriptManager) GetScript(scriptID string) (*ManagedScript, error) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	script, exists := sm.scripts[scriptID]
	if !exists {
		return nil, fmt.Errorf("script not found: %s", scriptID)
	}
	
	return script, nil
}

// GetScriptByName returns a script by name
func (sm *ScriptManager) GetScriptByName(name string) (*ManagedScript, error) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	for _, script := range sm.scripts {
		if script.Name == name {
			return script, nil
		}
	}
	
	return nil, fmt.Errorf("script not found: %s", name)
}

// ListModules returns a list of all available modules
func (sm *ScriptManager) ListModules() []*ScriptModule {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	modules := make([]*ScriptModule, 0, len(sm.modules))
	for _, module := range sm.modules {
		modules = append(modules, module)
	}
	
	return modules
}

// ListTemplates returns a list of all available templates
func (sm *ScriptManager) ListTemplates() []*ScriptTemplate {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	templates := make([]*ScriptTemplate, 0, len(sm.templates))
	for _, template := range sm.templates {
		templates = append(templates, template)
	}
	
	return templates
}

// CreateScriptFromTemplate creates a new script from a template
func (sm *ScriptManager) CreateScriptFromTemplate(templateID, scriptName string, parameters map[string]interface{}) (*ManagedScript, error) {
	sm.mu.RLock()
	template, exists := sm.templates[templateID]
	sm.mu.RUnlock()
	
	if !exists {
		err := fmt.Errorf("template not found: %s", templateID)
		hooks := &ErrorHooks{
			OnError: func(err error, context map[string]interface{}) {
				sm.logger.Error("Template not found", zap.Error(err), zap.Any("context", context))
			},
		}
		sm.errorManager.ProcessError(sm.ctx, err, hooks)
		return nil, err
	}
	
	// Process template and create script
	scriptContent := sm.processTemplate(template, parameters)
	
	// Determine script path
	scriptPath := filepath.Join(sm.config.ScriptPaths["generated"], scriptName+".ps1")
	
	// Write script file
	if err := ioutil.WriteFile(scriptPath, []byte(scriptContent), 0644); err != nil {
		hooks := &ErrorHooks{
			OnError: func(err error, context map[string]interface{}) {
				sm.logger.Error("Failed to write script file", zap.Error(err), zap.Any("context", context))
			},
		}
		sm.errorManager.ProcessError(sm.ctx, err, hooks)
		return nil, err
	}
	
	// Create managed script
	script := &ManagedScript{
		ID:           uuid.New().String(),
		Name:         scriptName,
		Path:         scriptPath,
		Type:         ScriptTypePowerShell,
		Status:       ScriptStatusIdle,
		Dependencies: []string{},
		Parameters:   parameters,
		Metadata:     map[string]string{"template_id": templateID, "generated": "true"},
		Timeout:      sm.config.DefaultTimeout,
		RetryPolicy: &RetryPolicy{
			MaxAttempts: 3,
			BackoffType: BackoffExponential,
			InitialWait: 1 * time.Second,
			MaxWait:     60 * time.Second,
			Multiplier:  2.0,
		},
	}
	
	sm.mu.Lock()
	sm.scripts[script.ID] = script
	sm.mu.Unlock()
	
	sm.logger.Info("Script created from template",
		zap.String("script_id", script.ID),
		zap.String("script_name", scriptName),
		zap.String("template_id", templateID),
		zap.String("script_path", scriptPath))
	
	return script, nil
}

// processTemplate processes a template with parameters
func (sm *ScriptManager) processTemplate(template *ScriptTemplate, parameters map[string]interface{}) string {
	content := template.Template
	
	// Simple template parameter replacement
	for _, param := range template.Parameters {
		placeholder := fmt.Sprintf("{{%s}}", param.Name)
		value := ""
		
		if val, exists := parameters[param.Name]; exists {
			value = fmt.Sprintf("%v", val)
		} else if param.DefaultValue != nil {
			value = fmt.Sprintf("%v", param.DefaultValue)
		}
		
		content = strings.ReplaceAll(content, placeholder, value)
	}
	
	return content
}

// GetMetrics returns performance and usage metrics
func (sm *ScriptManager) GetMetrics() map[string]interface{} {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	
	totalScripts := len(sm.scripts)
	totalRuns := 0
	totalSuccesses := 0
	totalErrors := 0
	
	scriptsByType := make(map[string]int)
	scriptsByStatus := make(map[string]int)
	
	for _, script := range sm.scripts {
		script.mu.RLock()
		totalRuns += script.RunCount
		totalSuccesses += script.SuccessCount
		totalErrors += script.ErrorCount
		
		scriptsByType[string(script.Type)]++
		scriptsByStatus[string(script.Status)]++
		script.mu.RUnlock()
	}
	
	return map[string]interface{}{
		"total_scripts":      totalScripts,
		"total_modules":      len(sm.modules),
		"total_templates":    len(sm.templates),
		"total_runs":         totalRuns,
		"total_successes":    totalSuccesses,
		"total_errors":       totalErrors,
		"success_rate":       float64(totalSuccesses) / float64(totalRuns) * 100,
		"scripts_by_type":    scriptsByType,
		"scripts_by_status":  scriptsByStatus,
		"available_executors": len(sm.executors),
	}
}

// Shutdown gracefully shuts down the Script Manager
func (sm *ScriptManager) Shutdown() error {
	sm.logger.Info("Shutting down Script Manager")
	
	// Cancel context to stop any running operations
	sm.cancel()
	
	// Wait for any running scripts to complete or timeout
	// This is a simplified approach - in production, you might want to track active executions
	time.Sleep(2 * time.Second)
	
	sm.logger.Info("Script Manager shutdown completed")
	return nil
}

// ValidateScript validates a script for syntax and dependencies
func (sm *ScriptManager) ValidateScript(scriptID string) error {
	script, err := sm.GetScript(scriptID)
	if err != nil {
		return err
	}
	
	executor, exists := sm.executors[string(script.Type)]
	if !exists {
		return fmt.Errorf("no executor found for script type: %s", script.Type)
	}
	
	return executor.Validate(script)
}
