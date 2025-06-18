package serialization

import (
	"time"
)

// SerializationConfig configuration pour la sérialisation
type SerializationConfig struct {
	// Output options
	PrettyPrint    bool `yaml:"pretty_print" env:"SERIALIZATION_PRETTY_PRINT" default:"false"`
	ValidateInput  bool `yaml:"validate_input" env:"SERIALIZATION_VALIDATE_INPUT" default:"true"`
	ValidateOutput bool `yaml:"validate_output" env:"SERIALIZATION_VALIDATE_OUTPUT" default:"true"`

	// Performance options
	EnableCaching bool          `yaml:"enable_caching" env:"SERIALIZATION_ENABLE_CACHING" default:"true"`
	CacheTTL      time.Duration `yaml:"cache_ttl" env:"SERIALIZATION_CACHE_TTL" default:"5m"`
	MaxCacheSize  int           `yaml:"max_cache_size" env:"SERIALIZATION_MAX_CACHE_SIZE" default:"1000"`

	// Compatibility options
	StrictMode     bool     `yaml:"strict_mode" env:"SERIALIZATION_STRICT_MODE" default:"false"`
	IgnoreFields   []string `yaml:"ignore_fields"`
	RequiredFields []string `yaml:"required_fields"`

	// Error handling
	ContinueOnError bool `yaml:"continue_on_error" env:"SERIALIZATION_CONTINUE_ON_ERROR" default:"false"`
	LogErrors       bool `yaml:"log_errors" env:"SERIALIZATION_LOG_ERRORS" default:"true"`
}

// WorkflowData structure Go pour les workflows
type WorkflowData struct {
	ID          string                 `json:"id" validate:"required"`
	Name        string                 `json:"name" validate:"required"`
	Active      bool                   `json:"active"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	Tags        []string               `json:"tags"`
	Settings    map[string]interface{} `json:"settings"`
	Connections map[string]interface{} `json:"connections"`
	Nodes       []WorkflowNode         `json:"nodes" validate:"min=1"`
}

// WorkflowNode représente un node dans le workflow
type WorkflowNode struct {
	ID          string                 `json:"id" validate:"required"`
	Name        string                 `json:"name" validate:"required"`
	Type        string                 `json:"type" validate:"required"`
	TypeVersion int                    `json:"typeVersion"`
	Position    NodePosition           `json:"position"`
	Parameters  map[string]interface{} `json:"parameters"`
	Credentials map[string]string      `json:"credentials"`
	Disabled    bool                   `json:"disabled"`
}

// NodePosition position d'un node dans l'interface
type NodePosition struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

// N8NWorkflowData format JSON exact de N8N
type N8NWorkflowData struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Active      bool                   `json:"active"`
	CreatedAt   string                 `json:"createdAt"`
	UpdatedAt   string                 `json:"updatedAt"`
	Tags        []string               `json:"tags"`
	Settings    map[string]interface{} `json:"settings"`
	Connections map[string]interface{} `json:"connections"`
	Nodes       []N8NNode              `json:"nodes"`
}

// N8NNode format JSON exact d'un node N8N
type N8NNode struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Type        string                 `json:"type"`
	TypeVersion int                    `json:"typeVersion"`
	Position    [2]float64             `json:"position"` // [x, y]
	Parameters  map[string]interface{} `json:"parameters"`
	Credentials map[string]string      `json:"credentials,omitempty"`
	Disabled    *bool                  `json:"disabled,omitempty"` // Pointeur pour omitempty
}

// SchemaValidator interface pour validation des schémas
type SchemaValidator interface {
	ValidateN8NSchema(data []byte) error
	ValidateGoSchema(workflow *WorkflowData) error
	LoadSchema(schemaPath string) error
}

// ConversionResult résultat d'une conversion
type ConversionResult struct {
	Success        bool                   `json:"success"`
	Data           []byte                 `json:"data,omitempty"`
	Workflow       *WorkflowData          `json:"workflow,omitempty"`
	Errors         []ConversionError      `json:"errors,omitempty"`
	Warnings       []ConversionWarning    `json:"warnings,omitempty"`
	ProcessingTime time.Duration          `json:"processing_time"`
	Metadata       map[string]interface{} `json:"metadata,omitempty"`
}

// ConversionError erreur de conversion
type ConversionError struct {
	Code        string `json:"code"`
	Message     string `json:"message"`
	Field       string `json:"field,omitempty"`
	Value       string `json:"value,omitempty"`
	Severity    string `json:"severity"` // error, warning, info
	Recoverable bool   `json:"recoverable"`
}

// ConversionWarning avertissement de conversion
type ConversionWarning struct {
	Code       string `json:"code"`
	Message    string `json:"message"`
	Field      string `json:"field,omitempty"`
	Suggestion string `json:"suggestion,omitempty"`
}

// SerializationMetrics métriques de sérialisation
type SerializationMetrics struct {
	TotalConversions      int64         `json:"total_conversions"`
	SuccessfulConversions int64         `json:"successful_conversions"`
	FailedConversions     int64         `json:"failed_conversions"`
	AverageProcessingTime time.Duration `json:"average_processing_time"`
	CacheHits             int64         `json:"cache_hits"`
	CacheMisses           int64         `json:"cache_misses"`
	LastResetTime         time.Time     `json:"last_reset_time"`
}

// PerformanceOptions options de performance
type PerformanceOptions struct {
	// Zero-copy operations
	EnableZeroCopy     bool `json:"enable_zero_copy"`
	StreamProcessing   bool `json:"stream_processing"`
	ParallelProcessing bool `json:"parallel_processing"`

	// Memory management
	MaxMemoryUsage    int64 `json:"max_memory_usage"`
	EnableCompression bool  `json:"enable_compression"`
	PoolBuffers       bool  `json:"pool_buffers"`

	// Timeout options
	ConversionTimeout time.Duration `json:"conversion_timeout"`
	ValidationTimeout time.Duration `json:"validation_timeout"`
}

// BatchConversionRequest requête de conversion par lot
type BatchConversionRequest struct {
	Workflows [][]byte               `json:"workflows"`
	Options   *PerformanceOptions    `json:"options,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// BatchConversionResponse réponse de conversion par lot
type BatchConversionResponse struct {
	Results         []ConversionResult   `json:"results"`
	TotalProcessed  int                  `json:"total_processed"`
	TotalSuccessful int                  `json:"total_successful"`
	TotalFailed     int                  `json:"total_failed"`
	ProcessingTime  time.Duration        `json:"processing_time"`
	Metrics         SerializationMetrics `json:"metrics"`
}

// Constantes d'erreur
const (
	ErrCodeInvalidJSON        = "INVALID_JSON"
	ErrCodeSchemaValidation   = "SCHEMA_VALIDATION"
	ErrCodeMissingField       = "MISSING_FIELD"
	ErrCodeInvalidFieldValue  = "INVALID_FIELD_VALUE"
	ErrCodeConversionTimeout  = "CONVERSION_TIMEOUT"
	ErrCodeMemoryLimit        = "MEMORY_LIMIT"
	ErrCodeUnsupportedVersion = "UNSUPPORTED_VERSION"
)

// Constantes de sévérité
const (
	SeverityError   = "error"
	SeverityWarning = "warning"
	SeverityInfo    = "info"
)
