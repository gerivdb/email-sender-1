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
	Enabled  bool   `yaml:"enabled"`
	Path     string `yaml:"path"`
	Priority int    `yaml:"priority"`
}

// OrganizationConfig for intelligent repository organization
type OrganizationConfig struct {
	MaxFilesPerFolder   int                          `yaml:"max_files_per_folder"`
	AutoCategorization  bool                         `yaml:"auto_categorization"`
	PatternLearning     bool                         `yaml:"pattern_learning"`
	SimilarityThreshold float64                      `yaml:"similarity_threshold"`
	FilePatterns        map[string]FilePatternConfig `yaml:"file_patterns"`
}

// FilePatternConfig defines how different file types should be organized
type FilePatternConfig struct {
	Extensions   []string `yaml:"extensions"`
	Organization string   `yaml:"organization"`
}

// CleanupConfig defines the 3-level cleanup system
type CleanupConfig struct {
	Levels map[int]CleanupLevelConfig `yaml:"levels"`
}

// CleanupLevelConfig defines each cleanup level's behavior
type CleanupLevelConfig struct {
	Name                   string   `yaml:"name"`
	AutoApprove            bool     `yaml:"auto_approve"`
	AIAnalysisRequired     bool     `yaml:"ai_analysis_required"`
	ManualApprovalRequired bool     `yaml:"manual_approval_required"`
	BackupBefore           bool     `yaml:"backup_before"`
	ConfidenceThreshold    float64  `yaml:"confidence_threshold"`
	Targets                []string `yaml:"targets"`
}

// PerformanceConfig defines performance targets (< 100ms latency)
type PerformanceConfig struct {
	TargetLatencyMs  int  `yaml:"target_latency_ms"`
	MaxConcurrentOps int  `yaml:"max_concurrent_operations"`
	CacheEnabled     bool `yaml:"cache_enabled"`
}

// SecurityConfig for security settings
type SecurityConfig struct {
	EnabledChecks    []string          `yaml:"enabled_checks"`
	ScanIntervalMin  int               `yaml:"scan_interval_minutes"`
	ThreatDetection  bool              `yaml:"threat_detection"`
	AuthRequired     bool              `yaml:"auth_required"`
	EncryptionLevel  string            `yaml:"encryption_level"`
	AllowedUsers     []string          `yaml:"allowed_users"`
	RestrictedPaths  []string          `yaml:"restricted_paths"`
	SecurityPolicies map[string]string `yaml:"security_policies"`
}

// MonitoringConfig for system monitoring
type MonitoringConfig struct {
	Enabled          bool               `yaml:"enabled"`
	MetricsInterval  time.Duration      `yaml:"metrics_interval"`
	AlertThresholds  map[string]float64 `yaml:"alert_thresholds"`
	LogLevel         string             `yaml:"log_level"`
	EnableProfiling  bool               `yaml:"enable_profiling"`
	HealthCheckPort  int                `yaml:"health_check_port"`
	DashboardEnabled bool               `yaml:"dashboard_enabled"`
}

// DatabaseConfig for database connections
type DatabaseConfig struct {
	Type              string            `yaml:"type"`
	Host              string            `yaml:"host"`
	Port              int               `yaml:"port"`
	Database          string            `yaml:"database"`
	Username          string            `yaml:"username"`
	Password          string            `yaml:"password"`
	MaxConnections    int               `yaml:"max_connections"`
	ConnectionTimeout time.Duration     `yaml:"connection_timeout"`
	QueryTimeout      time.Duration     `yaml:"query_timeout"`
	SSLMode           string            `yaml:"ssl_mode"`
	MigrationPath     string            `yaml:"migration_path"`
	BackupEnabled     bool              `yaml:"backup_enabled"`
	BackupInterval    time.Duration     `yaml:"backup_interval"`
	AdditionalParams  map[string]string `yaml:"additional_params"`
}

// LoggingConfig for logging configuration
type LoggingConfig struct {
	Level           string `yaml:"level"`
	Format          string `yaml:"format"`
	OutputPath      string `yaml:"output_path"`
	ErrorOutputPath string `yaml:"error_output_path"`
	EnableConsole   bool   `yaml:"enable_console"`
	EnableFile      bool   `yaml:"enable_file"`
	MaxSizeMB       int    `yaml:"max_size_mb"`
	MaxBackups      int    `yaml:"max_backups"`
	MaxAgeDays      int    `yaml:"max_age_days"`
	Compress        bool   `yaml:"compress"`
}

// GoGenConfig for native Hygen replacement
type GoGenConfig struct {
	TemplatesPath string                    `yaml:"templates_path"`
	OutputPath    string                    `yaml:"output_path"`
	Templates     map[string]TemplateConfig `yaml:"templates"`
}

// TemplateConfig for GoGen templates
type TemplateConfig struct {
	Description string            `yaml:"description"`
	Files       []FileTemplate    `yaml:"files"`
	Variables   map[string]string `yaml:"variables"`
}

// FileTemplate defines a file template for GoGen
type FileTemplate struct {
	Path     string `yaml:"path"`
	Template string `yaml:"template"`
}

// PowerShellIntegrationConfig for PowerShell script integration
type PowerShellIntegrationConfig struct {
	Enabled         bool              `yaml:"enabled"`
	ScriptsPath     string            `yaml:"scripts_path"`
	ExecutionPolicy string            `yaml:"execution_policy"`
	Timeout         time.Duration     `yaml:"timeout"`
	AllowedScripts  []string          `yaml:"allowed_scripts"`
	Environment     map[string]string `yaml:"environment"`
}
