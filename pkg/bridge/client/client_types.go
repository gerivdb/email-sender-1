package client

import (
	"fmt"
	"net/url"
	"time"
)

// ClientConfig configuration du client HTTP N8N
type ClientConfig struct {
	// Connection settings
	BaseURL     string `yaml:"base_url" env:"N8N_BASE_URL" validate:"required,url"`
	APIKey      string `yaml:"api_key" env:"N8N_API_KEY"`
	BearerToken string `yaml:"bearer_token" env:"N8N_BEARER_TOKEN"`

	// HTTP client settings
	Timeout    time.Duration `yaml:"timeout" env:"N8N_TIMEOUT" default:"30s"`
	MaxRetries int           `yaml:"max_retries" env:"N8N_MAX_RETRIES" default:"3"`
	RetryDelay time.Duration `yaml:"retry_delay" env:"N8N_RETRY_DELAY" default:"1s"`

	// Connection pooling
	MaxIdleConns          int           `yaml:"max_idle_conns" env:"N8N_MAX_IDLE_CONNS" default:"10"`
	MaxIdleConnsPerHost   int           `yaml:"max_idle_conns_per_host" env:"N8N_MAX_IDLE_CONNS_PER_HOST" default:"2"`
	IdleConnTimeout       time.Duration `yaml:"idle_conn_timeout" env:"N8N_IDLE_CONN_TIMEOUT" default:"90s"`
	DisableKeepAlives     bool          `yaml:"disable_keep_alives" env:"N8N_DISABLE_KEEP_ALIVES" default:"false"`
	TLSHandshakeTimeout   time.Duration `yaml:"tls_handshake_timeout" env:"N8N_TLS_HANDSHAKE_TIMEOUT" default:"10s"`
	ResponseHeaderTimeout time.Duration `yaml:"response_header_timeout" env:"N8N_RESPONSE_HEADER_TIMEOUT" default:"10s"`

	// Headers and metadata
	CustomHeaders map[string]string `yaml:"custom_headers"`
	Version       string            `yaml:"version" default:"1.0.0"`

	// Debugging
	EnableDebug bool `yaml:"enable_debug" env:"N8N_ENABLE_DEBUG" default:"false"`
	LogRequests bool `yaml:"log_requests" env:"N8N_LOG_REQUESTS" default:"false"`
}

// Validate valide la configuration du client
func (c *ClientConfig) Validate() error {
	if c.BaseURL == "" {
		return fmt.Errorf("base URL is required")
	}

	if _, err := url.Parse(c.BaseURL); err != nil {
		return fmt.Errorf("invalid base URL: %w", err)
	}

	if c.APIKey == "" && c.BearerToken == "" {
		return fmt.Errorf("either API key or bearer token is required")
	}

	if c.Timeout <= 0 {
		return fmt.Errorf("timeout must be positive")
	}

	if c.MaxRetries < 0 {
		return fmt.Errorf("max retries cannot be negative")
	}

	return nil
}

// WorkflowExecutionRequest requête d'exécution de workflow
type WorkflowExecutionRequest struct {
	WorkflowID string                 `json:"workflowId" validate:"required"`
	Data       map[string]interface{} `json:"data,omitempty"`
	Metadata   *ExecutionMetadata     `json:"metadata,omitempty"`
	Options    *ExecutionOptions      `json:"options,omitempty"`
}

// WorkflowExecutionResponse réponse d'exécution de workflow
type WorkflowExecutionResponse struct {
	ExecutionID string                 `json:"executionId"`
	Status      ExecutionStatusType    `json:"status"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Error       *ExecutionError        `json:"error,omitempty"`
	StartedAt   time.Time              `json:"startedAt"`
	FinishedAt  *time.Time             `json:"finishedAt,omitempty"`
	Duration    *time.Duration         `json:"duration,omitempty"`
}

// ExecutionMetadata métadonnées d'exécution
type ExecutionMetadata struct {
	Source      string            `json:"source,omitempty"`
	Trigger     string            `json:"trigger,omitempty"`
	UserID      string            `json:"userId,omitempty"`
	Tags        []string          `json:"tags,omitempty"`
	Environment string            `json:"environment,omitempty"`
	Custom      map[string]string `json:"custom,omitempty"`
}

// ExecutionOptions options d'exécution
type ExecutionOptions struct {
	WaitForCompletion     bool          `json:"waitForCompletion,omitempty"`
	Timeout               time.Duration `json:"timeout,omitempty"`
	SaveDataOutput        bool          `json:"saveDataOutput,omitempty"`
	SaveExecutionProgress bool          `json:"saveExecutionProgress,omitempty"`
}

// WorkflowFilters filtres pour la liste des workflows
type WorkflowFilters struct {
	Active   *bool    `json:"active,omitempty"`
	Tags     []string `json:"tags,omitempty"`
	Name     string   `json:"name,omitempty"`
	Limit    int      `json:"limit,omitempty"`
	Offset   int      `json:"offset,omitempty"`
	SortBy   string   `json:"sortBy,omitempty"`
	SortDesc bool     `json:"sortDesc,omitempty"`
}

// ToQueryParams convertit les filtres en paramètres de requête
func (f *WorkflowFilters) ToQueryParams() url.Values {
	params := url.Values{}

	if f.Active != nil {
		if *f.Active {
			params.Set("active", "true")
		} else {
			params.Set("active", "false")
		}
	}

	if f.Name != "" {
		params.Set("name", f.Name)
	}

	if len(f.Tags) > 0 {
		for _, tag := range f.Tags {
			params.Add("tags", tag)
		}
	}

	if f.Limit > 0 {
		params.Set("limit", fmt.Sprintf("%d", f.Limit))
	}

	if f.Offset > 0 {
		params.Set("offset", fmt.Sprintf("%d", f.Offset))
	}

	if f.SortBy != "" {
		params.Set("sortBy", f.SortBy)
	}

	if f.SortDesc {
		params.Set("sortDesc", "true")
	}

	return params
}

// WorkflowSummary résumé d'un workflow
type WorkflowSummary struct {
	ID         string     `json:"id"`
	Name       string     `json:"name"`
	Active     bool       `json:"active"`
	Tags       []string   `json:"tags"`
	CreatedAt  time.Time  `json:"createdAt"`
	UpdatedAt  time.Time  `json:"updatedAt"`
	NodesCount int        `json:"nodesCount"`
	LastRun    *time.Time `json:"lastRun,omitempty"`
}

// ExecutionStatus statut d'exécution détaillé
type ExecutionStatus struct {
	ID         string                 `json:"id"`
	WorkflowID string                 `json:"workflowId"`
	Status     ExecutionStatusType    `json:"status"`
	Mode       ExecutionMode          `json:"mode"`
	StartedAt  time.Time              `json:"startedAt"`
	StoppedAt  *time.Time             `json:"stoppedAt,omitempty"`
	FinishedAt *time.Time             `json:"finishedAt,omitempty"`
	Data       map[string]interface{} `json:"data,omitempty"`
	Error      *ExecutionError        `json:"error,omitempty"`
	Progress   *ExecutionProgress     `json:"progress,omitempty"`
	RetryCount int                    `json:"retryCount"`
}

// ExecutionStatusType types de statut d'exécution
type ExecutionStatusType string

const (
	ExecutionStatusRunning  ExecutionStatusType = "running"
	ExecutionStatusSuccess  ExecutionStatusType = "success"
	ExecutionStatusError    ExecutionStatusType = "error"
	ExecutionStatusCanceled ExecutionStatusType = "canceled"
	ExecutionStatusWaiting  ExecutionStatusType = "waiting"
	ExecutionStatusUnknown  ExecutionStatusType = "unknown"
)

// ExecutionMode modes d'exécution
type ExecutionMode string

const (
	ExecutionModeManual    ExecutionMode = "manual"
	ExecutionModeTrigger   ExecutionMode = "trigger"
	ExecutionModeWebhook   ExecutionMode = "webhook"
	ExecutionModeScheduled ExecutionMode = "scheduled"
	ExecutionModeRetry     ExecutionMode = "retry"
)

// ExecutionError erreur d'exécution
type ExecutionError struct {
	Message   string                 `json:"message"`
	Type      string                 `json:"type,omitempty"`
	Stack     string                 `json:"stack,omitempty"`
	NodeName  string                 `json:"nodeName,omitempty"`
	Context   map[string]interface{} `json:"context,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
}

// ExecutionProgress progression d'exécution
type ExecutionProgress struct {
	TotalNodes     int            `json:"totalNodes"`
	CompletedNodes int            `json:"completedNodes"`
	CurrentNode    string         `json:"currentNode,omitempty"`
	StartedNodes   []string       `json:"startedNodes,omitempty"`
	FinishedNodes  []string       `json:"finishedNodes,omitempty"`
	ErrorNodes     []string       `json:"errorNodes,omitempty"`
	Percentage     float64        `json:"percentage"`
	EstimatedTime  *time.Duration `json:"estimatedTime,omitempty"`
}

// ClientMetrics métriques du client HTTP
type ClientMetrics struct {
	TotalRequests       int64               `json:"total_requests"`
	SuccessfulRequests  int64               `json:"successful_requests"`
	FailedRequests      int64               `json:"failed_requests"`
	RetryCount          int64               `json:"retry_count"`
	AverageResponseTime time.Duration       `json:"average_response_time"`
	LastRequestTime     time.Time           `json:"last_request_time"`
	ConnectionPoolStats ConnectionPoolStats `json:"connection_pool_stats"`
}

// ConnectionPoolStats statistiques du pool de connexions
type ConnectionPoolStats struct {
	IdleConnections   int `json:"idle_connections"`
	ActiveConnections int `json:"active_connections"`
	TotalConnections  int `json:"total_connections"`
}

// RequestOptions options pour une requête spécifique
type RequestOptions struct {
	Timeout        time.Duration     `json:"timeout,omitempty"`
	MaxRetries     int               `json:"max_retries,omitempty"`
	CustomHeaders  map[string]string `json:"custom_headers,omitempty"`
	SkipValidation bool              `json:"skip_validation,omitempty"`
}

// ResponseWrapper wrapper générique pour les réponses N8N
type ResponseWrapper[T any] struct {
	Data    T                      `json:"data"`
	Success bool                   `json:"success"`
	Error   *ExecutionError        `json:"error,omitempty"`
	Meta    map[string]interface{} `json:"meta,omitempty"`
}

// PaginatedResponse réponse paginée générique
type PaginatedResponse[T any] struct {
	Data       []T  `json:"data"`
	Total      int  `json:"total"`
	Limit      int  `json:"limit"`
	Offset     int  `json:"offset"`
	HasMore    bool `json:"hasMore"`
	NextOffset *int `json:"nextOffset,omitempty"`
}
