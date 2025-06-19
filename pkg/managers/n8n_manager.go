package managers

import (
	"context"
	"time"

	"email_sender/pkg/converters"
	"email_sender/pkg/mapping"
)

// N8NManager définit l'interface pour la gestion des workflows N8N hybrides
type N8NManager interface {
	// Lifecycle Management
	Start(ctx context.Context) error
	Stop() error
	IsHealthy() bool
	GetStatus() ManagerStatus

	// Workflow Management
	ExecuteWorkflow(ctx context.Context, request *WorkflowRequest) (*WorkflowResponse, error)
	ValidateWorkflow(ctx context.Context, workflow *WorkflowDefinition) (*ValidationResult, error)
	GetWorkflowStatus(workflowID string) (*WorkflowStatus, error)
	CancelWorkflow(ctx context.Context, workflowID string) error

	// Data Management
	ConvertData(ctx context.Context, data *DataConversionRequest) (*DataConversionResponse, error)
	ValidateSchema(ctx context.Context, schema *SchemaValidationRequest) (*SchemaValidationResponse, error)

	// Parameter Management
	MapParameters(ctx context.Context, params *ParameterMappingRequest) (*ParameterMappingResponse, error)
	ValidateParameters(ctx context.Context, params *ParameterValidationRequest) (*ParameterValidationResponse, error)

	// Queue Management
	EnqueueJob(ctx context.Context, job *Job) error
	DequeueJob(ctx context.Context, queueName string) (*Job, error)
	GetQueueStatus(queueName string) (*QueueStatus, error)

	// Monitoring & Logging
	GetMetrics() (*ManagerMetrics, error)
	GetLogs(ctx context.Context, filter *LogFilter) ([]*LogEntry, error)
	Subscribe(eventType EventType) (<-chan Event, error)
}

// WorkflowRequest représente une demande d'exécution de workflow
type WorkflowRequest struct {
	WorkflowID    string                 `json:"workflow_id"`
	NodeID        string                 `json:"node_id"`
	Parameters    map[string]interface{} `json:"parameters"`
	InputData     []interface{}          `json:"input_data"`
	Options       *ExecutionOptions      `json:"options,omitempty"`
	TraceID       string                 `json:"trace_id,omitempty"`
	CorrelationID string                 `json:"correlation_id,omitempty"`
}

// WorkflowResponse représente la réponse d'exécution de workflow
type WorkflowResponse struct {
	ExecutionID   string            `json:"execution_id"`
	Status        ExecutionStatus   `json:"status"`
	OutputData    []interface{}     `json:"output_data"`
	Errors        []string          `json:"errors,omitempty"`
	Warnings      []string          `json:"warnings,omitempty"`
	Metrics       *ExecutionMetrics `json:"metrics"`
	TraceID       string            `json:"trace_id,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
}

// WorkflowDefinition représente la définition d'un workflow
type WorkflowDefinition struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description,omitempty"`
	Version     string                 `json:"version"`
	Nodes       []*NodeDefinition      `json:"nodes"`
	Connections []*Connection          `json:"connections"`
	Settings    map[string]interface{} `json:"settings,omitempty"`
}

// NodeDefinition représente la définition d'un nœud
type NodeDefinition struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"`
	Name       string                 `json:"name"`
	Parameters map[string]interface{} `json:"parameters"`
	Position   *NodePosition          `json:"position,omitempty"`
}

// Connection représente une connexion entre nœuds
type Connection struct {
	SourceNode   string `json:"source_node"`
	SourceOutput string `json:"source_output"`
	TargetNode   string `json:"target_node"`
	TargetInput  string `json:"target_input"`
}

// NodePosition représente la position d'un nœud
type NodePosition struct {
	X int `json:"x"`
	Y int `json:"y"`
}

// ExecutionOptions définit les options d'exécution
type ExecutionOptions struct {
	Timeout       time.Duration `json:"timeout,omitempty"`
	RetryCount    int           `json:"retry_count,omitempty"`
	RetryDelay    time.Duration `json:"retry_delay,omitempty"`
	Async         bool          `json:"async"`
	EnableTracing bool          `json:"enable_tracing"`
}

// ExecutionStatus représente le statut d'exécution
type ExecutionStatus string

const (
	ExecutionStatusPending   ExecutionStatus = "pending"
	ExecutionStatusRunning   ExecutionStatus = "running"
	ExecutionStatusSuccess   ExecutionStatus = "success"
	ExecutionStatusFailed    ExecutionStatus = "failed"
	ExecutionStatusCancelled ExecutionStatus = "cancelled"
	ExecutionStatusTimeout   ExecutionStatus = "timeout"
)

// ExecutionMetrics contient les métriques d'exécution
type ExecutionMetrics struct {
	StartTime     time.Time     `json:"start_time"`
	EndTime       time.Time     `json:"end_time"`
	Duration      time.Duration `json:"duration"`
	NodesExecuted int           `json:"nodes_executed"`
	DataProcessed int64         `json:"data_processed"`
	MemoryUsed    int64         `json:"memory_used"`
	CPUUsed       float64       `json:"cpu_used"`
}

// ValidationResult représente le résultat de validation
type ValidationResult struct {
	Valid    bool              `json:"valid"`
	Errors   []ValidationError `json:"errors,omitempty"`
	Warnings []ValidationError `json:"warnings,omitempty"`
	Score    float64           `json:"score"`
}

// ValidationError représente une erreur de validation
type ValidationError struct {
	Code     string `json:"code"`
	Message  string `json:"message"`
	Path     string `json:"path,omitempty"`
	Severity string `json:"severity"`
}

// WorkflowStatus représente le statut d'un workflow
type WorkflowStatus struct {
	WorkflowID   string          `json:"workflow_id"`
	ExecutionID  string          `json:"execution_id"`
	Status       ExecutionStatus `json:"status"`
	Progress     float64         `json:"progress"`
	CurrentNode  string          `json:"current_node,omitempty"`
	StartTime    time.Time       `json:"start_time"`
	LastUpdate   time.Time       `json:"last_update"`
	EstimatedEnd *time.Time      `json:"estimated_end,omitempty"`
}

// DataConversionRequest représente une demande de conversion de données
type DataConversionRequest struct {
	SourceFormat string             `json:"source_format"`
	TargetFormat string             `json:"target_format"`
	Data         interface{}        `json:"data"`
	Options      *ConversionOptions `json:"options,omitempty"`
}

// DataConversionResponse représente la réponse de conversion de données
type DataConversionResponse struct {
	ConvertedData interface{}          `json:"converted_data"`
	Metadata      *converters.Metadata `json:"metadata"`
	Errors        []string             `json:"errors,omitempty"`
	Warnings      []string             `json:"warnings,omitempty"`
}

// ConversionOptions définit les options de conversion
type ConversionOptions struct {
	ValidateSchema bool                            `json:"validate_schema"`
	NullHandling   converters.NullHandlingStrategy `json:"null_handling"`
	TypeMapping    map[string]string               `json:"type_mapping,omitempty"`
}

// SchemaValidationRequest représente une demande de validation de schéma
type SchemaValidationRequest struct {
	SchemaName string      `json:"schema_name"`
	Data       interface{} `json:"data"`
	Strict     bool        `json:"strict"`
}

// SchemaValidationResponse représente la réponse de validation de schéma
type SchemaValidationResponse struct {
	Valid              bool              `json:"valid"`
	Errors             []ValidationError `json:"errors,omitempty"`
	CompatibilityScore float64           `json:"compatibility_score"`
	Suggestions        []string          `json:"suggestions,omitempty"`
}

// ParameterMappingRequest représente une demande de mapping de paramètres
type ParameterMappingRequest struct {
	SourceParameters map[string]interface{} `json:"source_parameters"`
	TargetSchema     string                 `json:"target_schema"`
	NodeType         string                 `json:"node_type"`
}

// ParameterMappingResponse représente la réponse de mapping de paramètres
type ParameterMappingResponse struct {
	MappedParameters map[string]interface{} `json:"mapped_parameters"`
	MappingResult    *mapping.MappingResult `json:"mapping_result"`
	Errors           []string               `json:"errors,omitempty"`
	Warnings         []string               `json:"warnings,omitempty"`
}

// ParameterValidationRequest représente une demande de validation de paramètres
type ParameterValidationRequest struct {
	Parameters map[string]interface{} `json:"parameters"`
	Schema     string                 `json:"schema"`
	NodeType   string                 `json:"node_type"`
}

// ParameterValidationResponse représente la réponse de validation de paramètres
type ParameterValidationResponse struct {
	Valid     bool                   `json:"valid"`
	Errors    []ValidationError      `json:"errors,omitempty"`
	Sanitized map[string]interface{} `json:"sanitized,omitempty"`
}

// Job représente un travail dans la queue
type Job struct {
	ID            string                 `json:"id"`
	Type          string                 `json:"type"`
	QueueName     string                 `json:"queue_name"`
	Priority      int                    `json:"priority"`
	Payload       map[string]interface{} `json:"payload"`
	ScheduledAt   time.Time              `json:"scheduled_at"`
	MaxRetries    int                    `json:"max_retries"`
	RetryCount    int                    `json:"retry_count"`
	TraceID       string                 `json:"trace_id,omitempty"`
	CorrelationID string                 `json:"correlation_id,omitempty"`
}

// QueueStatus représente le statut d'une queue
type QueueStatus struct {
	Name         string    `json:"name"`
	Size         int       `json:"size"`
	Processing   int       `json:"processing"`
	Failed       int       `json:"failed"`
	LastActivity time.Time `json:"last_activity"`
	Workers      int       `json:"workers"`
	Throughput   float64   `json:"throughput"`
}

// ManagerStatus représente le statut du manager
type ManagerStatus struct {
	Running       bool                       `json:"running"`
	Healthy       bool                       `json:"healthy"`
	StartTime     time.Time                  `json:"start_time"`
	LastHeartbeat time.Time                  `json:"last_heartbeat"`
	Version       string                     `json:"version"`
	Components    map[string]ComponentStatus `json:"components"`
}

// ComponentStatus représente le statut d'un composant
type ComponentStatus struct {
	Name    string `json:"name"`
	Status  string `json:"status"`
	Healthy bool   `json:"healthy"`
	Message string `json:"message,omitempty"`
}

// ManagerMetrics contient les métriques du manager
type ManagerMetrics struct {
	WorkflowsExecuted    int64         `json:"workflows_executed"`
	WorkflowsSucceeded   int64         `json:"workflows_succeeded"`
	WorkflowsFailed      int64         `json:"workflows_failed"`
	AverageExecutionTime float64       `json:"average_execution_time"`
	DataConverted        int64         `json:"data_converted"`
	ParametersMapped     int64         `json:"parameters_mapped"`
	QueuedJobs           int64         `json:"queued_jobs"`
	ProcessedJobs        int64         `json:"processed_jobs"`
	MemoryUsage          int64         `json:"memory_usage"`
	CPUUsage             float64       `json:"cpu_usage"`
	Uptime               time.Duration `json:"uptime"`
}

// LogEntry représente une entrée de log
type LogEntry struct {
	Timestamp     time.Time              `json:"timestamp"`
	Level         string                 `json:"level"`
	Message       string                 `json:"message"`
	Component     string                 `json:"component"`
	TraceID       string                 `json:"trace_id,omitempty"`
	CorrelationID string                 `json:"correlation_id,omitempty"`
	Fields        map[string]interface{} `json:"fields,omitempty"`
}

// LogFilter définit les filtres pour les logs
type LogFilter struct {
	Level         string     `json:"level,omitempty"`
	Component     string     `json:"component,omitempty"`
	TraceID       string     `json:"trace_id,omitempty"`
	CorrelationID string     `json:"correlation_id,omitempty"`
	StartTime     *time.Time `json:"start_time,omitempty"`
	EndTime       *time.Time `json:"end_time,omitempty"`
	Limit         int        `json:"limit,omitempty"`
}

// EventType représente le type d'événement
type EventType string

const (
	EventTypeWorkflowStarted   EventType = "workflow.started"
	EventTypeWorkflowCompleted EventType = "workflow.completed"
	EventTypeWorkflowFailed    EventType = "workflow.failed"
	EventTypeNodeExecuted      EventType = "node.executed"
	EventTypeDataConverted     EventType = "data.converted"
	EventTypeParameterMapped   EventType = "parameter.mapped"
	EventTypeJobQueued         EventType = "job.queued"
	EventTypeJobProcessed      EventType = "job.processed"
	EventTypeError             EventType = "error"
)

// Event représente un événement système
type Event struct {
	ID            string                 `json:"id"`
	Type          EventType              `json:"type"`
	Timestamp     time.Time              `json:"timestamp"`
	Source        string                 `json:"source"`
	Data          map[string]interface{} `json:"data"`
	TraceID       string                 `json:"trace_id,omitempty"`
	CorrelationID string                 `json:"correlation_id,omitempty"`
}

// N8NManagerConfig représente la configuration du manager N8N
type N8NManagerConfig struct {
	// Core Configuration
	Name              string        `json:"name"`
	Version           string        `json:"version"`
	MaxConcurrency    int           `json:"max_concurrency"`
	DefaultTimeout    time.Duration `json:"default_timeout"`
	HeartbeatInterval time.Duration `json:"heartbeat_interval"`

	// CLI Configuration
	CLIPath        string            `json:"cli_path"`
	CLITimeout     time.Duration     `json:"cli_timeout"`
	CLIRetries     int               `json:"cli_retries"`
	CLIEnvironment map[string]string `json:"cli_environment,omitempty"`

	// Queue Configuration
	DefaultQueue string         `json:"default_queue"`
	QueueWorkers map[string]int `json:"queue_workers"`
	QueueRetries int            `json:"queue_retries"`

	// Monitoring Configuration
	EnableMetrics   bool          `json:"enable_metrics"`
	EnableTracing   bool          `json:"enable_tracing"`
	LogLevel        string        `json:"log_level"`
	MetricsInterval time.Duration `json:"metrics_interval"`

	// Security Configuration
	CredentialMasking     bool `json:"credential_masking"`
	ParameterSanitization bool `json:"parameter_sanitization"`
	AuditLogging          bool `json:"audit_logging"`
}
