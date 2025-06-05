package n8nmanager

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
	errormanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/error-manager"
)

// N8NManager manages n8n workflows and executions with centralized error handling
type N8NManager struct {
	baseURL      string
	apiKey       string
	httpClient   *http.Client
	logger       *zap.Logger
	errorManager *ErrorManager
	metrics      *N8NMetrics
	mu           sync.RWMutex
}

// ErrorManager interface for dependency injection
type ErrorManager interface {
	ValidateErrorEntry(entry errormanager.ErrorEntry) error
	CatalogError(entry errormanager.ErrorEntry) error
}

// ErrorHooks defines hooks for error handling
type ErrorHooks struct {
	OnError    func(error)
	OnRetry    func(int, error)
	OnRecover  func()
	OnCircuit  func(string, error)
}

// N8NMetrics holds metrics for n8n operations
type N8NMetrics struct {
	WorkflowExecutions     int64
	FailedExecutions       int64
	SuccessfulExecutions   int64
	AverageExecutionTime   time.Duration
	LastExecutionTime      time.Time
	mu                     sync.RWMutex
}

// Config holds configuration for N8NManager
type Config struct {
	BaseURL     string        `json:"base_url"`
	APIKey      string        `json:"api_key"`
	Timeout     time.Duration `json:"timeout"`
	MaxRetries  int           `json:"max_retries"`
	EnableTLS   bool          `json:"enable_tls"`
	LogLevel    string        `json:"log_level"`
}

// WorkflowExecution represents an n8n workflow execution
type WorkflowExecution struct {
	ID           string                 `json:"id"`
	WorkflowID   string                 `json:"workflowId"`
	Status       string                 `json:"status"`
	StartedAt    time.Time              `json:"startedAt"`
	FinishedAt   time.Time              `json:"finishedAt"`
	Data         map[string]interface{} `json:"data"`
	Error        string                 `json:"error,omitempty"`
}

// Workflow represents an n8n workflow
type Workflow struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Active      bool                   `json:"active"`
	Tags        []string               `json:"tags"`
	CreatedAt   time.Time              `json:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt"`
	Nodes       []interface{}          `json:"nodes"`
	Connections map[string]interface{} `json:"connections"`
}

// NewN8NManager creates a new N8N manager with ErrorManager integration
func NewN8NManager(config Config, logger *zap.Logger, errorManager *ErrorManager) *N8NManager {
	if logger == nil {
		logger = zap.NewNop()
	}

	return &N8NManager{
		baseURL:      config.BaseURL,
		apiKey:       config.APIKey,
		logger:       logger,
		errorManager: errorManager,
		metrics:      &N8NMetrics{},
		httpClient: &http.Client{
			Timeout: config.Timeout,
		},
	}
}

// ProcessError processes errors using the centralized ErrorManager
func (nm *N8NManager) ProcessError(ctx context.Context, err error, operation string, workflowContext map[string]interface{}) error {
	if err == nil {
		return nil
	}

	// Generate unique error ID
	errorID := uuid.New().String()

	// Create error entry
	errorEntry := errormanager.ErrorEntry{
		ID:        errorID,
		Timestamp: time.Now(),
		Level:     nm.determineErrorLevel(err),
		Component: "n8n-manager",
		Operation: operation,
		Message:   err.Error(),
		Context: map[string]interface{}{
			"base_url":    nm.baseURL,
			"operation":   operation,
			"error_id":    errorID,
			"workflow_context": workflowContext,
		},
		ManagerContext: workflowContext,
		Tags:          []string{"n8n", "workflow", "manager"},
		Severity:      nm.determineSeverity(err),
		Category:      nm.categorizeError(err),
	}

	// Validate error entry
	if nm.errorManager != nil {
		if validationErr := nm.errorManager.ValidateErrorEntry(errorEntry); validationErr != nil {
			nm.logger.Error("Error entry validation failed",
				zap.Error(validationErr),
				zap.String("original_error", err.Error()),
				zap.String("operation", operation))
		}

		// Catalog the error
		if catalogErr := nm.errorManager.CatalogError(errorEntry); catalogErr != nil {
			nm.logger.Error("Error cataloging failed",
				zap.Error(catalogErr),
				zap.String("original_error", err.Error()),
				zap.String("operation", operation))
		}
	}

	// Log with structured logging
	nm.logger.Error("N8N operation failed",
		zap.Error(err),
		zap.String("operation", operation),
		zap.String("error_id", errorID),
		zap.Any("workflow_context", workflowContext),
		zap.String("severity", errorEntry.Severity),
		zap.String("category", errorEntry.Category))

	return fmt.Errorf("n8n-manager operation '%s' failed with ID %s: %w", operation, errorID, err)
}

// ExecuteWorkflow executes a workflow by ID with comprehensive error handling
func (nm *N8NManager) ExecuteWorkflow(ctx context.Context, workflowID string, inputData map[string]interface{}) (*WorkflowExecution, error) {
	nm.mu.Lock()
	nm.metrics.WorkflowExecutions++
	nm.mu.Unlock()

	start := time.Now()
	workflowContext := map[string]interface{}{
		"workflow_id": workflowID,
		"input_data":  inputData,
		"start_time":  start,
	}

	nm.logger.Info("Executing workflow",
		zap.String("workflow_id", workflowID),
		zap.Any("input_data", inputData))

	// Prepare request
	url := fmt.Sprintf("%s/api/v1/workflows/%s/execute", nm.baseURL, workflowID)
	
	jsonData, err := json.Marshal(inputData)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "workflow_execute_marshal", workflowContext)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, strings.NewReader(string(jsonData)))
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "workflow_execute_request", workflowContext)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-N8N-API-KEY", nm.apiKey)

	// Execute request
	resp, err := nm.httpClient.Do(req)
	if err != nil {
		nm.updateMetrics(false, time.Since(start))
		return nil, nm.ProcessError(ctx, err, "workflow_execute_http", workflowContext)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		nm.updateMetrics(false, time.Since(start))
		return nil, nm.ProcessError(ctx, err, "workflow_execute_read", workflowContext)
	}

	if resp.StatusCode != http.StatusOK {
		nm.updateMetrics(false, time.Since(start))
		err = fmt.Errorf("n8n API returned status %d: %s", resp.StatusCode, string(body))
		return nil, nm.ProcessError(ctx, err, "workflow_execute_status", workflowContext)
	}

	var execution WorkflowExecution
	if err := json.Unmarshal(body, &execution); err != nil {
		nm.updateMetrics(false, time.Since(start))
		return nil, nm.ProcessError(ctx, err, "workflow_execute_unmarshal", workflowContext)
	}

	nm.updateMetrics(true, time.Since(start))
	
	nm.logger.Info("Workflow executed successfully",
		zap.String("workflow_id", workflowID),
		zap.String("execution_id", execution.ID),
		zap.Duration("duration", time.Since(start)))

	return &execution, nil
}

// GetWorkflows retrieves all workflows with error handling
func (nm *N8NManager) GetWorkflows(ctx context.Context) ([]Workflow, error) {
	nm.logger.Info("Retrieving workflows")

	url := fmt.Sprintf("%s/api/v1/workflows", nm.baseURL)
	
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_workflows_request", map[string]interface{}{})
	}

	req.Header.Set("X-N8N-API-KEY", nm.apiKey)

	resp, err := nm.httpClient.Do(req)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_workflows_http", map[string]interface{}{})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_workflows_read", map[string]interface{}{})
	}

	if resp.StatusCode != http.StatusOK {
		err = fmt.Errorf("n8n API returned status %d: %s", resp.StatusCode, string(body))
		return nil, nm.ProcessError(ctx, err, "get_workflows_status", map[string]interface{}{})
	}

	var response struct {
		Data []Workflow `json:"data"`
	}
	
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, nm.ProcessError(ctx, err, "get_workflows_unmarshal", map[string]interface{}{})
	}

	nm.logger.Info("Retrieved workflows successfully",
		zap.Int("count", len(response.Data)))

	return response.Data, nil
}

// GetExecutionStatus gets the status of a workflow execution
func (nm *N8NManager) GetExecutionStatus(ctx context.Context, executionID string) (*WorkflowExecution, error) {
	nm.logger.Info("Getting execution status",
		zap.String("execution_id", executionID))

	url := fmt.Sprintf("%s/api/v1/executions/%s", nm.baseURL, executionID)
	
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_execution_status_request", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	req.Header.Set("X-N8N-API-KEY", nm.apiKey)

	resp, err := nm.httpClient.Do(req)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_execution_status_http", map[string]interface{}{
			"execution_id": executionID,
		})
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nm.ProcessError(ctx, err, "get_execution_status_read", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	if resp.StatusCode != http.StatusOK {
		err = fmt.Errorf("n8n API returned status %d: %s", resp.StatusCode, string(body))
		return nil, nm.ProcessError(ctx, err, "get_execution_status_status", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	var execution WorkflowExecution
	if err := json.Unmarshal(body, &execution); err != nil {
		return nil, nm.ProcessError(ctx, err, "get_execution_status_unmarshal", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	nm.logger.Info("Retrieved execution status successfully",
		zap.String("execution_id", executionID),
		zap.String("status", execution.Status))

	return &execution, nil
}

// StopExecution stops a running workflow execution
func (nm *N8NManager) StopExecution(ctx context.Context, executionID string) error {
	nm.logger.Info("Stopping execution",
		zap.String("execution_id", executionID))

	url := fmt.Sprintf("%s/api/v1/executions/%s/stop", nm.baseURL, executionID)
	
	req, err := http.NewRequestWithContext(ctx, "POST", url, nil)
	if err != nil {
		return nm.ProcessError(ctx, err, "stop_execution_request", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	req.Header.Set("X-N8N-API-KEY", nm.apiKey)

	resp, err := nm.httpClient.Do(req)
	if err != nil {
		return nm.ProcessError(ctx, err, "stop_execution_http", map[string]interface{}{
			"execution_id": executionID,
		})
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		err = fmt.Errorf("n8n API returned status %d: %s", resp.StatusCode, string(body))
		return nm.ProcessError(ctx, err, "stop_execution_status", map[string]interface{}{
			"execution_id": executionID,
		})
	}

	nm.logger.Info("Execution stopped successfully",
		zap.String("execution_id", executionID))

	return nil
}

// HealthCheck performs a health check on the n8n instance
func (nm *N8NManager) HealthCheck(ctx context.Context) error {
	nm.logger.Info("Performing health check")

	url := fmt.Sprintf("%s/healthz", nm.baseURL)
	
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nm.ProcessError(ctx, err, "health_check_request", map[string]interface{}{})
	}

	resp, err := nm.httpClient.Do(req)
	if err != nil {
		return nm.ProcessError(ctx, err, "health_check_http", map[string]interface{}{})
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		err = fmt.Errorf("n8n health check failed with status %d: %s", resp.StatusCode, string(body))
		return nm.ProcessError(ctx, err, "health_check_status", map[string]interface{}{})
	}

	nm.logger.Info("Health check passed")
	return nil
}

// GetMetrics returns current metrics
func (nm *N8NManager) GetMetrics() N8NMetrics {
	nm.metrics.mu.RLock()
	defer nm.metrics.mu.RUnlock()
	return *nm.metrics
}

// Helper methods

func (nm *N8NManager) updateMetrics(success bool, duration time.Duration) {
	nm.metrics.mu.Lock()
	defer nm.metrics.mu.Unlock()
	
	if success {
		nm.metrics.SuccessfulExecutions++
	} else {
		nm.metrics.FailedExecutions++
	}
	
	nm.metrics.AverageExecutionTime = (nm.metrics.AverageExecutionTime + duration) / 2
	nm.metrics.LastExecutionTime = time.Now()
}

func (nm *N8NManager) determineErrorLevel(err error) string {
	errMsg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(errMsg, "connection") || strings.Contains(errMsg, "network"):
		return "ERROR"
	case strings.Contains(errMsg, "timeout"):
		return "WARN"
	case strings.Contains(errMsg, "unauthorized") || strings.Contains(errMsg, "forbidden"):
		return "ERROR"
	case strings.Contains(errMsg, "not found"):
		return "WARN"
	default:
		return "ERROR"
	}
}

func (nm *N8NManager) determineSeverity(err error) string {
	errMsg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(errMsg, "critical") || strings.Contains(errMsg, "fatal"):
		return "CRITICAL"
	case strings.Contains(errMsg, "connection") || strings.Contains(errMsg, "network"):
		return "HIGH"
	case strings.Contains(errMsg, "timeout"):
		return "MEDIUM"
	case strings.Contains(errMsg, "not found"):
		return "LOW"
	default:
		return "MEDIUM"
	}
}

func (nm *N8NManager) categorizeError(err error) string {
	errMsg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(errMsg, "connection") || strings.Contains(errMsg, "network"):
		return "NETWORK"
	case strings.Contains(errMsg, "timeout"):
		return "PERFORMANCE"
	case strings.Contains(errMsg, "unauthorized") || strings.Contains(errMsg, "forbidden"):
		return "SECURITY"
	case strings.Contains(errMsg, "not found"):
		return "RESOURCE"
	case strings.Contains(errMsg, "json") || strings.Contains(errMsg, "unmarshal"):
		return "DATA"
	default:
		return "GENERAL"
	}
}
