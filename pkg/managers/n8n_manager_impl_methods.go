package managers

import (
	"context"
	"fmt"
	"time"

	"email_sender/pkg/converters"
	"email_sender/pkg/mapping"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Implémentation des méthodes manquantes pour DefaultN8NManager

// ValidateWorkflow valide un workflow
func (m *DefaultN8NManager) ValidateWorkflow(ctx context.Context, workflow *WorkflowDefinition) (*ValidationResult, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	result := &ValidationResult{
		Valid:    true,
		Errors:   make([]ValidationError, 0),
		Warnings: make([]ValidationError, 0),
		Score:    100.0,
	}

	// Basic validation
	if workflow.ID == "" {
		result.Valid = false
		result.Errors = append(result.Errors, ValidationError{
			Code:     "missing_id",
			Message:  "Workflow ID is required",
			Severity: "error",
		})
	}

	if workflow.Name == "" {
		result.Warnings = append(result.Warnings, ValidationError{
			Code:     "missing_name",
			Message:  "Workflow name is recommended",
			Severity: "warning",
		})
		result.Score -= 10
	}

	if len(workflow.Nodes) == 0 {
		result.Valid = false
		result.Errors = append(result.Errors, ValidationError{
			Code:     "no_nodes",
			Message:  "Workflow must have at least one node",
			Severity: "error",
		})
	}

	return result, nil
}

// GetWorkflowStatus retourne le statut d'un workflow
func (m *DefaultN8NManager) GetWorkflowStatus(workflowID string) (*WorkflowStatus, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	// Find the most recent execution for this workflow
	var latestExecution *ExecutionContext
	for _, execution := range m.executions {
		if execution.WorkflowID == workflowID {
			if latestExecution == nil || execution.StartTime.After(latestExecution.StartTime) {
				latestExecution = execution
			}
		}
	}

	if latestExecution == nil {
		return nil, fmt.Errorf("no execution found for workflow %s", workflowID)
	}

	progress := 0.0
	if latestExecution.Status == ExecutionStatusRunning {
		progress = 0.5 // 50% when running
	} else if latestExecution.Status == ExecutionStatusSuccess {
		progress = 1.0 // 100% when completed
	}

	status := &WorkflowStatus{
		WorkflowID:  workflowID,
		ExecutionID: latestExecution.ID,
		Status:      latestExecution.Status,
		Progress:    progress,
		StartTime:   latestExecution.StartTime,
		LastUpdate:  latestExecution.EndTime,
	}

	if !latestExecution.EndTime.IsZero() {
		status.LastUpdate = latestExecution.EndTime
	}

	return status, nil
}

// CancelWorkflow annule un workflow
func (m *DefaultN8NManager) CancelWorkflow(ctx context.Context, workflowID string) error {
	if !m.running {
		return fmt.Errorf("manager is not running")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	// Find running executions for this workflow
	for executionID, execution := range m.executions {
		if execution.WorkflowID == workflowID && execution.Status == ExecutionStatusRunning {
			execution.mu.Lock()
			execution.Status = ExecutionStatusCancelled
			execution.EndTime = time.Now()
			execution.mu.Unlock()

			m.logger.Info("Workflow execution cancelled",
				zap.String("workflow_id", workflowID),
				zap.String("execution_id", executionID))

			// Emit cancelled event
			m.emitEvent(EventType("workflow.cancelled"), map[string]interface{}{
				"workflow_id":  workflowID,
				"execution_id": executionID,
			})

			return nil
		}
	}

	return fmt.Errorf("no running execution found for workflow %s", workflowID)
}

// ConvertData convertit les données
func (m *DefaultN8NManager) ConvertData(ctx context.Context, data *DataConversionRequest) (*DataConversionResponse, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	response := &DataConversionResponse{
		Errors:   make([]string, 0),
		Warnings: make([]string, 0),
	}

	// Use the appropriate converter based on source/target format
	switch {
	case data.SourceFormat == "n8n" && data.TargetFormat == "go":
		// Convert N8N data to Go format
		n8nData, ok := data.Data.(converters.N8NData)
		if !ok {
			return nil, fmt.Errorf("invalid N8N data format")
		}

		result, err := m.converter.Convert(n8nData)
		if err != nil {
			return nil, fmt.Errorf("N8N to Go conversion failed: %w", err)
		}

		response.ConvertedData = result.Data
		response.Metadata = &result.Metadata
		response.Errors = result.Errors
		response.Warnings = result.Warnings

		// Update metrics
		m.mu.Lock()
		m.metrics.DataConverted++
		m.mu.Unlock()

	case data.SourceFormat == "go" && data.TargetFormat == "n8n":
		// Convert Go data to N8N format
		goData, ok := data.Data.([]converters.GoStruct)
		if !ok {
			return nil, fmt.Errorf("invalid Go data format")
		}

		result, err := m.goConverter.Convert(goData)
		if err != nil {
			return nil, fmt.Errorf("Go to N8N conversion failed: %w", err)
		}

		response.ConvertedData = result.N8NData
		response.Errors = result.Errors
		response.Warnings = result.Warnings

		// Update metrics
		m.mu.Lock()
		m.metrics.DataConverted++
		m.mu.Unlock()

	default:
		return nil, fmt.Errorf("unsupported conversion: %s to %s", data.SourceFormat, data.TargetFormat)
	}

	// Emit data converted event
	m.emitEvent(EventTypeDataConverted, map[string]interface{}{
		"source_format": data.SourceFormat,
		"target_format": data.TargetFormat,
		"data_size":     len(fmt.Sprintf("%v", data.Data)),
	})

	return response, nil
}

// ValidateSchema valide un schéma
func (m *DefaultN8NManager) ValidateSchema(ctx context.Context, schema *SchemaValidationRequest) (*SchemaValidationResponse, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	result, err := m.validator.ValidateData(schema.Data, schema.SchemaName)
	if err != nil {
		return nil, fmt.Errorf("schema validation failed: %w", err)
	}

	response := &SchemaValidationResponse{
		Valid:              result.Valid,
		CompatibilityScore: result.CompatibilityScore,
		Suggestions:        result.Suggestions,
	}

	// Convert validation errors
	for _, validationError := range result.Errors {
		response.Errors = append(response.Errors, ValidationError{
			Code:     validationError.Code,
			Message:  validationError.Message,
			Path:     validationError.Path,
			Severity: validationError.Severity,
		})
	}

	return response, nil
}

// MapParameters mappe les paramètres
func (m *DefaultN8NManager) MapParameters(ctx context.Context, params *ParameterMappingRequest) (*ParameterMappingResponse, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	// Create mapping parameters for the mapper
	parameters := make([]mapping.Parameter, 0, len(params.SourceParameters))
	for key, value := range params.SourceParameters {
		parameters = append(parameters, mapping.Parameter{
			Name:  key,
			Value: value,
			Type:  fmt.Sprintf("%T", value),
		})
	}

	result, err := m.mapper.MapParameters(parameters)
	if err != nil {
		return nil, fmt.Errorf("parameter mapping failed: %w", err)
	}

	// Convert back to map
	mappedParams := make(map[string]interface{})
	for _, param := range result.MappedParameters {
		mappedParams[param.Name] = param.Value
	}

	response := &ParameterMappingResponse{
		MappedParameters: mappedParams,
		MappingResult:    result,
		Errors:           result.Errors,
		Warnings:         result.Warnings,
	}

	// Update metrics
	m.mu.Lock()
	m.metrics.ParametersMapped++
	m.mu.Unlock()

	// Emit parameter mapped event
	m.emitEvent(EventTypeParameterMapped, map[string]interface{}{
		"parameter_count": len(params.SourceParameters),
		"node_type":       params.NodeType,
	})

	return response, nil
}

// ValidateParameters valide les paramètres
func (m *DefaultN8NManager) ValidateParameters(ctx context.Context, params *ParameterValidationRequest) (*ParameterValidationResponse, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	response := &ParameterValidationResponse{
		Valid:     true,
		Errors:    make([]ValidationError, 0),
		Sanitized: make(map[string]interface{}),
	}

	// Basic parameter validation
	for key, value := range params.Parameters {
		// Copy to sanitized
		response.Sanitized[key] = value

		// Basic validation rules
		if value == nil && params.NodeType == "required" {
			response.Valid = false
			response.Errors = append(response.Errors, ValidationError{
				Code:     "required_parameter_missing",
				Message:  fmt.Sprintf("Required parameter '%s' is missing", key),
				Path:     key,
				Severity: "error",
			})
		}

		// Sanitize strings
		if str, ok := value.(string); ok {
			// Basic sanitization - remove potential injection patterns
			if len(str) > 1000 {
				response.Sanitized[key] = str[:1000] // Truncate
			}
		}
	}

	return response, nil
}

// EnqueueJob ajoute un job à la queue
func (m *DefaultN8NManager) EnqueueJob(ctx context.Context, job *Job) error {
	if !m.running {
		return fmt.Errorf("manager is not running")
	}

	queueName := job.QueueName
	if queueName == "" {
		queueName = m.config.DefaultQueue
	}

	m.mu.RLock()
	queue, exists := m.queues[queueName]
	m.mu.RUnlock()

	if !exists {
		return fmt.Errorf("queue '%s' not found", queueName)
	}

	// Set defaults
	if job.ID == "" {
		job.ID = uuid.New().String()
	}
	if job.ScheduledAt.IsZero() {
		job.ScheduledAt = time.Now()
	}

	select {
	case queue.Jobs <- job:
		// Update metrics
		m.mu.Lock()
		m.metrics.QueuedJobs++
		m.mu.Unlock()

		// Emit job queued event
		m.emitEvent(EventTypeJobQueued, map[string]interface{}{
			"job_id":     job.ID,
			"job_type":   job.Type,
			"queue_name": queueName,
		})

		return nil
	case <-ctx.Done():
		return ctx.Err()
	default:
		return fmt.Errorf("queue '%s' is full", queueName)
	}
}

// DequeueJob récupère un job de la queue
func (m *DefaultN8NManager) DequeueJob(ctx context.Context, queueName string) (*Job, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	if queueName == "" {
		queueName = m.config.DefaultQueue
	}

	m.mu.RLock()
	queue, exists := m.queues[queueName]
	m.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("queue '%s' not found", queueName)
	}

	select {
	case job := <-queue.Jobs:
		// Update metrics
		m.mu.Lock()
		m.metrics.ProcessedJobs++
		m.mu.Unlock()

		// Emit job processed event
		m.emitEvent(EventTypeJobProcessed, map[string]interface{}{
			"job_id":     job.ID,
			"job_type":   job.Type,
			"queue_name": queueName,
		})

		return job, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// GetQueueStatus retourne le statut d'une queue
func (m *DefaultN8NManager) GetQueueStatus(queueName string) (*QueueStatus, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	m.mu.RLock()
	queue, exists := m.queues[queueName]
	m.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("queue '%s' not found", queueName)
	}

	queue.mu.RLock()
	status := &QueueStatus{
		Name:         queue.Name,
		Size:         len(queue.Jobs),
		Processing:   len(queue.Processing),
		Failed:       len(queue.Failed),
		LastActivity: queue.LastActivity,
		Workers:      queue.Workers,
		Throughput:   queue.Throughput,
	}
	queue.mu.RUnlock()

	return status, nil
}

// GetMetrics retourne les métriques du manager
func (m *DefaultN8NManager) GetMetrics() (*ManagerMetrics, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	// Update uptime
	m.metrics.Uptime = time.Since(m.startTime)

	// Create a copy to avoid race conditions
	metrics := &ManagerMetrics{
		WorkflowsExecuted:    m.metrics.WorkflowsExecuted,
		WorkflowsSucceeded:   m.metrics.WorkflowsSucceeded,
		WorkflowsFailed:      m.metrics.WorkflowsFailed,
		AverageExecutionTime: m.metrics.AverageExecutionTime,
		DataConverted:        m.metrics.DataConverted,
		ParametersMapped:     m.metrics.ParametersMapped,
		QueuedJobs:           m.metrics.QueuedJobs,
		ProcessedJobs:        m.metrics.ProcessedJobs,
		MemoryUsage:          m.metrics.MemoryUsage,
		CPUUsage:             m.metrics.CPUUsage,
		Uptime:               m.metrics.Uptime,
	}

	return metrics, nil
}

// GetLogs retourne les logs filtrés
func (m *DefaultN8NManager) GetLogs(ctx context.Context, filter *LogFilter) ([]*LogEntry, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	// Basic implementation - in a real system, this would query a log storage
	logs := make([]*LogEntry, 0)

	// Create sample log entries for demonstration
	logs = append(logs, &LogEntry{
		Timestamp:     time.Now().Add(-5 * time.Minute),
		Level:         "INFO",
		Message:       "Manager started",
		Component:     "n8n-manager",
		TraceID:       "",
		CorrelationID: "",
		Fields:        map[string]interface{}{"version": m.config.Version},
	})

	logs = append(logs, &LogEntry{
		Timestamp:     time.Now().Add(-2 * time.Minute),
		Level:         "DEBUG",
		Message:       "Workflow executed successfully",
		Component:     "n8n-manager",
		TraceID:       "",
		CorrelationID: "",
		Fields:        map[string]interface{}{"execution_count": m.metrics.WorkflowsExecuted},
	})

	// Apply filters
	filteredLogs := make([]*LogEntry, 0)
	for _, log := range logs {
		if filter.Level != "" && log.Level != filter.Level {
			continue
		}
		if filter.Component != "" && log.Component != filter.Component {
			continue
		}
		if filter.StartTime != nil && log.Timestamp.Before(*filter.StartTime) {
			continue
		}
		if filter.EndTime != nil && log.Timestamp.After(*filter.EndTime) {
			continue
		}
		filteredLogs = append(filteredLogs, log)
	}

	// Apply limit
	if filter.Limit > 0 && len(filteredLogs) > filter.Limit {
		filteredLogs = filteredLogs[:filter.Limit]
	}

	return filteredLogs, nil
}

// Subscribe s'abonne aux événements
func (m *DefaultN8NManager) Subscribe(eventType EventType) (<-chan Event, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	ch := make(chan Event, 100) // Buffered channel

	m.mu.Lock()
	m.subscribers[eventType] = append(m.subscribers[eventType], ch)
	m.mu.Unlock()

	m.logger.Info("New subscriber registered",
		zap.String("event_type", string(eventType)))

	return ch, nil
}
