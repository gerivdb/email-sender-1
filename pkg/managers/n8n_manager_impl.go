package managers

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sync"
	"time"

	"email_sender/pkg/bridge"
	"email_sender/pkg/converters"
	"email_sender/pkg/mapping"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// DefaultN8NManager implémentation concrète du N8NManager
type DefaultN8NManager struct {
	config    *N8NManagerConfig
	logger    *zap.Logger
	running   bool
	startTime time.Time
	mu        sync.RWMutex

	// Core Components
	converter   *converters.N8NToGoConverter
	goConverter *converters.GoToN8NConverter
	mapper      *mapping.ParameterMapper
	validator   *converters.SchemaValidator

	// Bridge Components
	eventBus        *bridge.EventBus
	statusTracker   *bridge.StatusTracker
	callbackHandler *bridge.CallbackHandler

	// Queue Management
	queues       map[string]*JobQueue
	queueWorkers map[string][]*QueueWorker

	// Execution Management
	executions map[string]*ExecutionContext
	workflows  map[string]*WorkflowContext

	// Monitoring
	metrics     *ManagerMetrics
	subscribers map[EventType][]chan Event

	// Lifecycle
	ctx    context.Context
	cancel context.CancelFunc
}

// ExecutionContext représente le contexte d'exécution d'un workflow
type ExecutionContext struct {
	ID            string
	WorkflowID    string
	Status        ExecutionStatus
	StartTime     time.Time
	EndTime       time.Time
	Parameters    map[string]interface{}
	InputData     []interface{}
	OutputData    []interface{}
	Errors        []string
	Warnings      []string
	Metrics       *ExecutionMetrics
	TraceID       string
	CorrelationID string
	mu            sync.RWMutex
}

// WorkflowContext représente le contexte d'un workflow
type WorkflowContext struct {
	Definition    *WorkflowDefinition
	Executions    []*ExecutionContext
	LastExecution *ExecutionContext
	TotalRuns     int64
	SuccessRuns   int64
	FailedRuns    int64
	mu            sync.RWMutex
}

// JobQueue représente une queue de travaux
type JobQueue struct {
	Name         string
	Jobs         chan *Job
	Processing   map[string]*Job
	Failed       []*Job
	Workers      int
	Throughput   float64
	LastActivity time.Time
	mu           sync.RWMutex
}

// QueueWorker représente un worker de queue
type QueueWorker struct {
	ID        string
	QueueName string
	Running   bool
	Processed int64
	mu        sync.RWMutex
}

// NewDefaultN8NManager crée une nouvelle instance du manager N8N
func NewDefaultN8NManager(config *N8NManagerConfig, logger *zap.Logger) (*DefaultN8NManager, error) {
	if config == nil {
		return nil, fmt.Errorf("config cannot be nil")
	}
	if logger == nil {
		return nil, fmt.Errorf("logger cannot be nil")
	}

	ctx, cancel := context.WithCancel(context.Background())

	manager := &DefaultN8NManager{
		config:       config,
		logger:       logger,
		ctx:          ctx,
		cancel:       cancel,
		queues:       make(map[string]*JobQueue),
		queueWorkers: make(map[string][]*QueueWorker),
		executions:   make(map[string]*ExecutionContext),
		workflows:    make(map[string]*WorkflowContext),
		subscribers:  make(map[EventType][]chan Event),
		metrics: &ManagerMetrics{
			WorkflowsExecuted:    0,
			WorkflowsSucceeded:   0,
			WorkflowsFailed:      0,
			AverageExecutionTime: 0.0,
			DataConverted:        0,
			ParametersMapped:     0,
			QueuedJobs:           0,
			ProcessedJobs:        0,
			MemoryUsage:          0,
			CPUUsage:             0.0,
			Uptime:               0,
		},
	}

	// Initialize components
	if err := manager.initializeComponents(); err != nil {
		return nil, fmt.Errorf("failed to initialize components: %w", err)
	}

	logger.Info("N8N Manager created successfully",
		zap.String("version", config.Version),
		zap.String("name", config.Name))

	return manager, nil
}

// initializeComponents initialise les composants du manager
func (m *DefaultN8NManager) initializeComponents() error {
	// Initialize converters
	var err error

	// N8N to Go converter
	m.converter, err = converters.NewN8NToGoConverter(m.logger, converters.ConversionOptions{
		NullHandling:   converters.NullHandlingDefault,
		TypeValidation: true,
		SkipBinaryData: false,
		MaxFieldDepth:  10,
	})
	if err != nil {
		return fmt.Errorf("failed to create N8N to Go converter: %w", err)
	}

	// Go to N8N converter
	m.goConverter = converters.NewGoToN8NConverter(m.logger, converters.GoToN8NOptions{
		UseOmitEmpty:         true,
		FieldNameTransformer: converters.DefaultFieldNameTransformer,
		TimeFormat:           time.RFC3339,
	})

	// Parameter mapper
	m.mapper = mapping.NewParameterMapper(m.logger, mapping.MappingOptions{
		StrictMode:          false,
		ValidateTypes:       true,
		AllowPartialMapping: true,
		CustomMappings:      make(map[string]string),
	})

	// Schema validator
	m.validator = converters.NewSchemaValidator(m.logger, converters.SchemaValidatorOptions{
		StrictMode:           false,
		AllowAdditionalProps: true,
		ValidateFormats:      true,
	})

	// Initialize bridge components
	m.eventBus = bridge.NewEventBus(m.logger)
	m.statusTracker = bridge.NewStatusTracker(m.logger)
	m.callbackHandler = bridge.NewCallbackHandler(m.logger)

	// Initialize default queue
	m.initializeDefaultQueue()

	m.logger.Info("All components initialized successfully")
	return nil
}

// initializeDefaultQueue initialise la queue par défaut
func (m *DefaultN8NManager) initializeDefaultQueue() {
	defaultQueue := &JobQueue{
		Name:         m.config.DefaultQueue,
		Jobs:         make(chan *Job, 1000),
		Processing:   make(map[string]*Job),
		Failed:       make([]*Job, 0),
		Workers:      m.config.QueueWorkers[m.config.DefaultQueue],
		Throughput:   0.0,
		LastActivity: time.Now(),
	}

	if defaultQueue.Workers == 0 {
		defaultQueue.Workers = 5 // Default workers
	}

	m.queues[m.config.DefaultQueue] = defaultQueue
	m.queueWorkers[m.config.DefaultQueue] = make([]*QueueWorker, 0, defaultQueue.Workers)

	m.logger.Info("Default queue initialized",
		zap.String("queue", m.config.DefaultQueue),
		zap.Int("workers", defaultQueue.Workers))
}

// Start démarre le manager N8N
func (m *DefaultN8NManager) Start(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.running {
		return fmt.Errorf("manager is already running")
	}

	m.logger.Info("Starting N8N Manager...")

	// Start components
	if err := m.eventBus.Start(ctx); err != nil {
		return fmt.Errorf("failed to start event bus: %w", err)
	}

	if err := m.statusTracker.Start(ctx); err != nil {
		return fmt.Errorf("failed to start status tracker: %w", err)
	}

	if err := m.callbackHandler.Start(ctx); err != nil {
		return fmt.Errorf("failed to start callback handler: %w", err)
	}

	// Start queue workers
	m.startQueueWorkers(ctx)

	// Start monitoring
	go m.startMonitoring(ctx)

	// Start heartbeat
	go m.startHeartbeat(ctx)

	m.running = true
	m.startTime = time.Now()

	m.logger.Info("N8N Manager started successfully",
		zap.Time("start_time", m.startTime))

	// Emit start event
	m.emitEvent(EventType("manager.started"), map[string]interface{}{
		"start_time": m.startTime,
		"config":     m.config.Name,
	})

	return nil
}

// Stop arrête le manager N8N
func (m *DefaultN8NManager) Stop() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.running {
		return fmt.Errorf("manager is not running")
	}

	m.logger.Info("Stopping N8N Manager...")

	// Cancel context
	m.cancel()

	// Stop components
	m.eventBus.Stop()
	m.statusTracker.Stop()
	m.callbackHandler.Stop()

	// Stop queue workers
	m.stopQueueWorkers()

	m.running = false

	uptime := time.Since(m.startTime)
	m.metrics.Uptime = uptime

	m.logger.Info("N8N Manager stopped successfully",
		zap.Duration("uptime", uptime))

	// Emit stop event
	m.emitEvent(EventType("manager.stopped"), map[string]interface{}{
		"uptime": uptime.String(),
	})

	return nil
}

// IsHealthy vérifie si le manager est en bonne santé
func (m *DefaultN8NManager) IsHealthy() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if !m.running {
		return false
	}

	// Check components health
	if !m.eventBus.IsHealthy() {
		return false
	}

	if !m.statusTracker.IsHealthy() {
		return false
	}

	// Check queue health
	for _, queue := range m.queues {
		if len(queue.Processing) > queue.Workers*10 { // Too many processing jobs
			return false
		}
	}

	return true
}

// GetStatus retourne le statut du manager
func (m *DefaultN8NManager) GetStatus() ManagerStatus {
	m.mu.RLock()
	defer m.mu.RUnlock()

	components := make(map[string]ComponentStatus)
	components["eventBus"] = ComponentStatus{
		Name:    "EventBus",
		Status:  m.getComponentStatus(m.eventBus.IsHealthy()),
		Healthy: m.eventBus.IsHealthy(),
	}
	components["statusTracker"] = ComponentStatus{
		Name:    "StatusTracker",
		Status:  m.getComponentStatus(m.statusTracker.IsHealthy()),
		Healthy: m.statusTracker.IsHealthy(),
	}
	components["callbackHandler"] = ComponentStatus{
		Name:    "CallbackHandler",
		Status:  m.getComponentStatus(m.callbackHandler.IsHealthy()),
		Healthy: m.callbackHandler.IsHealthy(),
	}

	return ManagerStatus{
		Running:       m.running,
		Healthy:       m.IsHealthy(),
		StartTime:     m.startTime,
		LastHeartbeat: time.Now(),
		Version:       m.config.Version,
		Components:    components,
	}
}

// ExecuteWorkflow exécute un workflow
func (m *DefaultN8NManager) ExecuteWorkflow(ctx context.Context, request *WorkflowRequest) (*WorkflowResponse, error) {
	if !m.running {
		return nil, fmt.Errorf("manager is not running")
	}

	// Generate execution ID
	executionID := uuid.New().String()

	// Create execution context
	execution := &ExecutionContext{
		ID:            executionID,
		WorkflowID:    request.WorkflowID,
		Status:        ExecutionStatusPending,
		StartTime:     time.Now(),
		Parameters:    request.Parameters,
		InputData:     request.InputData,
		OutputData:    make([]interface{}, 0),
		Errors:        make([]string, 0),
		Warnings:      make([]string, 0),
		TraceID:       request.TraceID,
		CorrelationID: request.CorrelationID,
		Metrics: &ExecutionMetrics{
			StartTime:     time.Now(),
			NodesExecuted: 0,
			DataProcessed: 0,
			MemoryUsed:    0,
			CPUUsed:       0.0,
		},
	}

	// Store execution context
	m.mu.Lock()
	m.executions[executionID] = execution
	m.mu.Unlock()

	// Emit workflow started event
	m.emitEvent(EventTypeWorkflowStarted, map[string]interface{}{
		"execution_id":   executionID,
		"workflow_id":    request.WorkflowID,
		"trace_id":       request.TraceID,
		"correlation_id": request.CorrelationID,
	})

	// Execute workflow
	response, err := m.executeWorkflowInternal(ctx, request, execution)
	if err != nil {
		execution.mu.Lock()
		execution.Status = ExecutionStatusFailed
		execution.EndTime = time.Now()
		execution.Errors = append(execution.Errors, err.Error())
		execution.mu.Unlock()

		// Update metrics
		m.mu.Lock()
		m.metrics.WorkflowsFailed++
		m.mu.Unlock()

		// Emit workflow failed event
		m.emitEvent(EventTypeWorkflowFailed, map[string]interface{}{
			"execution_id": executionID,
			"error":        err.Error(),
		})

		return nil, err
	}

	// Update execution context
	execution.mu.Lock()
	execution.Status = ExecutionStatusSuccess
	execution.EndTime = time.Now()
	execution.OutputData = response.OutputData
	execution.Metrics.EndTime = time.Now()
	execution.Metrics.Duration = execution.EndTime.Sub(execution.StartTime)
	execution.mu.Unlock()

	// Update metrics
	m.mu.Lock()
	m.metrics.WorkflowsExecuted++
	m.metrics.WorkflowsSucceeded++
	// Update average execution time
	totalExecutions := m.metrics.WorkflowsExecuted
	if totalExecutions > 0 {
		currentAvg := m.metrics.AverageExecutionTime
		newDuration := execution.Metrics.Duration.Seconds()
		m.metrics.AverageExecutionTime = (currentAvg*float64(totalExecutions-1) + newDuration) / float64(totalExecutions)
	}
	m.mu.Unlock()

	// Emit workflow completed event
	m.emitEvent(EventTypeWorkflowCompleted, map[string]interface{}{
		"execution_id": executionID,
		"duration":     execution.Metrics.Duration.String(),
	})

	return response, nil
}

// executeWorkflowInternal exécute le workflow en interne
func (m *DefaultN8NManager) executeWorkflowInternal(ctx context.Context, request *WorkflowRequest, execution *ExecutionContext) (*WorkflowResponse, error) {
	// Map parameters
	mappingRequest := &ParameterMappingRequest{
		SourceParameters: request.Parameters,
		TargetSchema:     request.NodeID,
		NodeType:         "go-cli",
	}

	mappingResponse, err := m.MapParameters(ctx, mappingRequest)
	if err != nil {
		return nil, fmt.Errorf("parameter mapping failed: %w", err)
	}

	// Convert input data
	var convertedInput interface{}
	if len(request.InputData) > 0 {
		conversionRequest := &DataConversionRequest{
			SourceFormat: "n8n",
			TargetFormat: "go",
			Data:         request.InputData,
			Options: &ConversionOptions{
				ValidateSchema: true,
				NullHandling:   converters.NullHandlingDefault,
			},
		}

		conversionResponse, err := m.ConvertData(ctx, conversionRequest)
		if err != nil {
			return nil, fmt.Errorf("data conversion failed: %w", err)
		}
		convertedInput = conversionResponse.ConvertedData
	}

	// Execute CLI command
	output, err := m.executeCLI(ctx, mappingResponse.MappedParameters, convertedInput)
	if err != nil {
		return nil, fmt.Errorf("CLI execution failed: %w", err)
	}

	// Convert output back to N8N format
	outputConversionRequest := &DataConversionRequest{
		SourceFormat: "go",
		TargetFormat: "n8n",
		Data:         output,
		Options: &ConversionOptions{
			ValidateSchema: false,
			NullHandling:   converters.NullHandlingDefault,
		},
	}

	outputConversionResponse, err := m.ConvertData(ctx, outputConversionRequest)
	if err != nil {
		return nil, fmt.Errorf("output conversion failed: %w", err)
	}

	// Prepare response
	response := &WorkflowResponse{
		ExecutionID:   execution.ID,
		Status:        ExecutionStatusSuccess,
		OutputData:    []interface{}{outputConversionResponse.ConvertedData},
		Errors:        make([]string, 0),
		Warnings:      make([]string, 0),
		Metrics:       execution.Metrics,
		TraceID:       request.TraceID,
		CorrelationID: request.CorrelationID,
	}

	return response, nil
}

// executeCLI exécute la commande CLI
func (m *DefaultN8NManager) executeCLI(ctx context.Context, parameters map[string]interface{}, inputData interface{}) (interface{}, error) {
	// Prepare CLI command
	args := []string{}

	// Convert parameters to CLI arguments
	for key, value := range parameters {
		args = append(args, fmt.Sprintf("--%s", key))
		args = append(args, fmt.Sprintf("%v", value))
	}

	// Create command with timeout
	cmdCtx, cancel := context.WithTimeout(ctx, m.config.CLITimeout)
	defer cancel()

	cmd := exec.CommandContext(cmdCtx, m.config.CLIPath, args...)

	// Set environment variables
	if m.config.CLIEnvironment != nil {
		env := os.Environ()
		for key, value := range m.config.CLIEnvironment {
			env = append(env, fmt.Sprintf("%s=%s", key, value))
		}
		cmd.Env = env
	}

	// Execute command
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("CLI command failed: %w", err)
	}

	// Parse output as JSON
	var result interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		// If not JSON, return as string
		return string(output), nil
	}

	return result, nil
}

// Helper methods
func (m *DefaultN8NManager) getComponentStatus(healthy bool) string {
	if healthy {
		return "running"
	}
	return "failed"
}

func (m *DefaultN8NManager) emitEvent(eventType EventType, data map[string]interface{}) {
	event := Event{
		ID:        uuid.New().String(),
		Type:      eventType,
		Timestamp: time.Now(),
		Source:    "n8n-manager",
		Data:      data,
	}

	// Send to subscribers
	m.mu.RLock()
	subscribers := m.subscribers[eventType]
	m.mu.RUnlock()

	for _, ch := range subscribers {
		select {
		case ch <- event:
		default:
			// Channel is full, skip
		}
	}
}

func (m *DefaultN8NManager) startQueueWorkers(ctx context.Context) {
	for queueName, queue := range m.queues {
		for i := 0; i < queue.Workers; i++ {
			worker := &QueueWorker{
				ID:        fmt.Sprintf("%s-worker-%d", queueName, i),
				QueueName: queueName,
				Running:   true,
				Processed: 0,
			}
			m.queueWorkers[queueName] = append(m.queueWorkers[queueName], worker)
			go m.runQueueWorker(ctx, worker, queue)
		}
	}
}

func (m *DefaultN8NManager) stopQueueWorkers() {
	for _, workers := range m.queueWorkers {
		for _, worker := range workers {
			worker.mu.Lock()
			worker.Running = false
			worker.mu.Unlock()
		}
	}
}

func (m *DefaultN8NManager) runQueueWorker(ctx context.Context, worker *QueueWorker, queue *JobQueue) {
	m.logger.Info("Starting queue worker", zap.String("worker", worker.ID))

	for {
		select {
		case <-ctx.Done():
			return
		case job := <-queue.Jobs:
			if !worker.Running {
				return
			}
			m.processJob(ctx, job, worker, queue)
		}
	}
}

func (m *DefaultN8NManager) processJob(ctx context.Context, job *Job, worker *QueueWorker, queue *JobQueue) {
	// Implementation placeholder
	worker.mu.Lock()
	worker.Processed++
	worker.mu.Unlock()

	queue.mu.Lock()
	queue.LastActivity = time.Now()
	queue.mu.Unlock()

	m.logger.Debug("Job processed",
		zap.String("job_id", job.ID),
		zap.String("worker", worker.ID))
}

func (m *DefaultN8NManager) startMonitoring(ctx context.Context) {
	ticker := time.NewTicker(m.config.MetricsInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			m.updateMetrics()
		}
	}
}

func (m *DefaultN8NManager) updateMetrics() {
	// Update uptime
	if m.running {
		m.mu.Lock()
		m.metrics.Uptime = time.Since(m.startTime)
		m.mu.Unlock()
	}
}

func (m *DefaultN8NManager) startHeartbeat(ctx context.Context) {
	ticker := time.NewTicker(m.config.HeartbeatInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			m.emitEvent(EventType("manager.heartbeat"), map[string]interface{}{
				"timestamp": time.Now(),
				"healthy":   m.IsHealthy(),
			})
		}
	}
}
