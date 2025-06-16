// Package types provides shared type definitions for FMOUA
// Avoids import cycles between core, ai, and integration packages
package types

import (
	"time"
)

// AIConfig implements AI-First principle
type AIConfig struct {
	Enabled               bool          `yaml:"enabled"`
	Provider              string        `yaml:"provider"`
	Model                 string        `yaml:"model"`
	ConfidenceThreshold   float64       `yaml:"confidence_threshold"`
	LearningEnabled       bool          `yaml:"learning_enabled"`
	PatternRecognition    bool          `yaml:"pattern_recognition"`
	DecisionAutonomyLevel int           `yaml:"decision_autonomy_level"`
	QDrant                *QDrantConfig `yaml:"qdrant"`
	CacheSize             int           `yaml:"cache_size"`
}

// QDrantConfig for vectorization support
type QDrantConfig struct {
	Host           string        `yaml:"host"`
	Port           int           `yaml:"port"`
	CollectionName string        `yaml:"collection_name"`
	VectorSize     int           `yaml:"vector_size"`
	DistanceMetric string        `yaml:"distance_metric"`
	Timeout        time.Duration `yaml:"timeout"`
	APIKey         string        `yaml:"api_key,omitempty"`
}

// ManagersConfig for integrating existing 17 managers (DRY principle)
type ManagersConfig struct {
	Managers            map[string]ManagerConfig `yaml:"managers"`
	HealthCheckInterval time.Duration            `yaml:"health_check_interval"`
	DefaultTimeout      time.Duration            `yaml:"default_timeout"`
	MaxRetries          int                      `yaml:"max_retries"`
}

// ManagerConfig for individual manager configuration
type ManagerConfig struct {
	ID       string                 `yaml:"id"`
	Type     string                 `yaml:"type"`
	Enabled  bool                   `yaml:"enabled"`
	Path     string                 `yaml:"path"`
	Priority int                    `yaml:"priority"`
	Config   map[string]interface{} `yaml:"config"`
}

// ManagerStatus represents the current state of a manager
type ManagerStatus string

const (
	ManagerStatusStopped     ManagerStatus = "stopped"
	ManagerStatusInitialized ManagerStatus = "initialized"
	ManagerStatusStarting    ManagerStatus = "starting"
	ManagerStatusRunning     ManagerStatus = "running"
	ManagerStatusStopping    ManagerStatus = "stopping"
	ManagerStatusError       ManagerStatus = "error"
)

// EmailManagerConfig for email management configuration
type EmailManagerConfig struct {
	Providers   map[string]EmailProviderConfig `yaml:"providers"`
	Templates   TemplateEngineConfig           `yaml:"templates"`
	QueueConfig QueueConfig                    `yaml:"queue"`
	Tracking    TrackingConfig                 `yaml:"tracking"`
}

// EmailProviderConfig for email provider settings
type EmailProviderConfig struct {
	Type        string            `yaml:"type"` // smtp, sendgrid, mailgun, etc.
	Host        string            `yaml:"host"`
	Port        int               `yaml:"port"`
	Username    string            `yaml:"username"`
	Password    string            `yaml:"password"`
	APIKey      string            `yaml:"api_key"`
	Settings    map[string]string `yaml:"settings"`
	RateLimit   int               `yaml:"rate_limit"`
	Timeout     time.Duration     `yaml:"timeout"`
}

// TemplateEngineConfig for email templates
type TemplateEngineConfig struct {
	TemplatesPath string            `yaml:"templates_path"`
	CacheEnabled  bool              `yaml:"cache_enabled"`
	CacheSize     int               `yaml:"cache_size"`
	DefaultLang   string            `yaml:"default_lang"`
	Variables     map[string]string `yaml:"variables"`
}

// QueueConfig for email queue management
type QueueConfig struct {
	Type         string        `yaml:"type"` // memory, redis, database
	MaxSize      int           `yaml:"max_size"`
	Workers      int           `yaml:"workers"`
	RetryAttempts int          `yaml:"retry_attempts"`
	RetryDelay   time.Duration `yaml:"retry_delay"`
	BatchSize    int           `yaml:"batch_size"`
}

// TrackingConfig for email tracking
type TrackingConfig struct {
	Enabled       bool   `yaml:"enabled"`
	ClickTracking bool   `yaml:"click_tracking"`
	OpenTracking  bool   `yaml:"open_tracking"`
	UnsubscribeURL string `yaml:"unsubscribe_url"`
}

// DatabaseManagerConfig for database management configuration
type DatabaseManagerConfig struct {
	Connections map[string]DatabaseConfig `yaml:"connections"`
	PoolConfig  ConnectionPoolConfig      `yaml:"pool"`
	Migration   MigrationConfig           `yaml:"migration"`
	Backup      BackupConfig              `yaml:"backup"`
}

// DatabaseConfig for individual database configuration
type DatabaseConfig struct {
	Type         string        `yaml:"type"` // postgresql, mysql, mongodb
	Host         string        `yaml:"host"`
	Port         int           `yaml:"port"`
	Database     string        `yaml:"database"`
	Username     string        `yaml:"username"`
	Password     string        `yaml:"password"`
	SSLMode      string        `yaml:"ssl_mode"`
	MaxConns     int           `yaml:"max_conns"`
	MinConns     int           `yaml:"min_conns"`
	MaxLifetime  time.Duration `yaml:"max_lifetime"`
	MaxIdleTime  time.Duration `yaml:"max_idle_time"`
}

// ConnectionPoolConfig for database connection pooling
type ConnectionPoolConfig struct {
	MaxOpen         int           `yaml:"max_open"`
	MaxIdle         int           `yaml:"max_idle"`
	ConnMaxLifetime time.Duration `yaml:"conn_max_lifetime"`
	ConnMaxIdleTime time.Duration `yaml:"conn_max_idle_time"`
}

// MigrationConfig for database migrations
type MigrationConfig struct {
	Enabled     bool   `yaml:"enabled"`
	TableName   string `yaml:"table_name"`
	SchemaPath  string `yaml:"schema_path"`
	AutoMigrate bool   `yaml:"auto_migrate"`
}

// BackupConfig for database backups
type BackupConfig struct {
	Enabled      bool          `yaml:"enabled"`
	Schedule     string        `yaml:"schedule"` // cron format
	Retention    time.Duration `yaml:"retention"`
	StoragePath  string        `yaml:"storage_path"`
	Compression  bool          `yaml:"compression"`
}

// CacheManagerConfig for cache management configuration
type CacheManagerConfig struct {
	Backends   map[string]CacheBackendConfig `yaml:"backends"`
	Strategies CacheStrategiesConfig         `yaml:"strategies"`
	Monitoring CacheMonitoringConfig         `yaml:"monitoring"`
}

// CacheBackendConfig for cache backend settings
type CacheBackendConfig struct {
	Type        string            `yaml:"type"` // redis, memcached, memory
	Addresses   []string          `yaml:"addresses"`
	Password    string            `yaml:"password"`
	Database    int               `yaml:"database"`
	MaxRetries  int               `yaml:"max_retries"`
	PoolSize    int               `yaml:"pool_size"`
	Timeout     time.Duration     `yaml:"timeout"`
	Settings    map[string]string `yaml:"settings"`
}

// CacheStrategiesConfig for cache strategies
type CacheStrategiesConfig struct {
	DefaultTTL     time.Duration `yaml:"default_ttl"`
	EvictionPolicy string        `yaml:"eviction_policy"` // lru, lfu, fifo
	MaxMemory      string        `yaml:"max_memory"`
	Serialization  string        `yaml:"serialization"` // json, gob, msgpack
}

// CacheMonitoringConfig for cache monitoring
type CacheMonitoringConfig struct {
	Enabled        bool          `yaml:"enabled"`
	MetricsPrefix  string        `yaml:"metrics_prefix"`
	StatsInterval  time.Duration `yaml:"stats_interval"`
	AlertThreshold float64       `yaml:"alert_threshold"`
}

// WebhookManagerConfig for webhook management configuration
type WebhookManagerConfig struct {
	Server WebhookServerConfig `yaml:"server"`
	Client WebhookClientConfig `yaml:"client"`
	Auth   WebhookAuthConfig   `yaml:"auth"`
}

// WebhookServerConfig for webhook server settings
type WebhookServerConfig struct {
	Enabled     bool          `yaml:"enabled"`
	Host        string        `yaml:"host"`
	Port        int           `yaml:"port"`
	TLS         bool          `yaml:"tls"`
	CertFile    string        `yaml:"cert_file"`
	KeyFile     string        `yaml:"key_file"`
	ReadTimeout time.Duration `yaml:"read_timeout"`
	WriteTimeout time.Duration `yaml:"write_timeout"`
	IdleTimeout time.Duration `yaml:"idle_timeout"`
}

// WebhookClientConfig for webhook client settings
type WebhookClientConfig struct {
	Timeout        time.Duration `yaml:"timeout"`
	MaxRetries     int           `yaml:"max_retries"`
	RetryDelay     time.Duration `yaml:"retry_delay"`
	MaxRetryDelay  time.Duration `yaml:"max_retry_delay"`
	CircuitBreaker CircuitBreakerConfig `yaml:"circuit_breaker"`
}

// CircuitBreakerConfig for circuit breaker settings
type CircuitBreakerConfig struct {
	MaxRequests    uint32        `yaml:"max_requests"`
	Interval       time.Duration `yaml:"interval"`
	Timeout        time.Duration `yaml:"timeout"`
	ReadyToTrip    func(counts uint64) bool `yaml:"-"`
}

// WebhookAuthConfig for webhook authentication
type WebhookAuthConfig struct {
	Type       string            `yaml:"type"` // basic, bearer, hmac, custom
	Username   string            `yaml:"username"`
	Password   string            `yaml:"password"`
	Token      string            `yaml:"token"`
	Secret     string            `yaml:"secret"`
	Headers    map[string]string `yaml:"headers"`
}

// Task represents a task to be executed by managers
type Task struct {
	ID          string                 `json:"id"`
	Type        string                 `json:"type"`
	Priority    int                    `json:"priority"`
	Payload     map[string]interface{} `json:"payload"`
	Timeout     time.Duration          `json:"timeout"`
	RetryCount  int                    `json:"retry_count"`
	MaxRetries  int                    `json:"max_retries"`
	CreatedAt   time.Time              `json:"created_at"`
	ScheduledAt time.Time              `json:"scheduled_at"`
	Context     map[string]interface{} `json:"context"`
}

// Result represents the result of a task execution
type Result struct {
	TaskID      string                 `json:"task_id"`
	Success     bool                   `json:"success"`
	Data        map[string]interface{} `json:"data"`
	Error       string                 `json:"error,omitempty"`
	Duration    time.Duration          `json:"duration"`
	Timestamp   time.Time              `json:"timestamp"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// CleanupLevelConfig for cleanup level configuration
type CleanupLevelConfig struct {
	Level       int      `yaml:"level"`
	Description string   `yaml:"description"`
	Actions     []string `yaml:"actions"`
	DryRun      bool     `yaml:"dry_run"`
	Aggressive  bool     `yaml:"aggressive"`
}
