package core

import (
	"time"
)

// Config represents the main configuration for the maintenance manager
type Config struct {
	// General settings
	RepositoryPath    string `yaml:"repository_path" json:"repository_path"`
	MaxFilesPerFolder int    `yaml:"max_files_per_folder" json:"max_files_per_folder"`
	AutonomyLevel     int    `yaml:"autonomy_level" json:"autonomy_level"`

	// AI Configuration
	AIConfig AIConfig `yaml:"ai_config" json:"ai_config"`

	// Vector Database Configuration
	VectorDB VectorDBConfig `yaml:"vector_db" json:"vector_db"`

	// Manager Integration Settings
	ManagerIntegration ManagerIntegrationConfig `yaml:"manager_integration" json:"manager_integration"`

	// Existing Scripts Configuration
	ExistingScripts []ScriptConfig `yaml:"existing_scripts" json:"existing_scripts"`

	// Cleanup Configuration
	CleanupConfig CleanupConfig `yaml:"cleanup_config" json:"cleanup_config"`

	// Performance Settings
	Performance PerformanceConfig `yaml:"performance" json:"performance"`

	// Organization Rules
	OrganizationRules OrganizationRulesConfig `yaml:"organization_rules" json:"organization_rules"`

	// Security Settings
	Security SecurityConfig `yaml:"security" json:"security"`

	// Logging Configuration
	Logging LoggingConfig `yaml:"logging" json:"logging"`

	// Monitoring Configuration
	Monitoring MonitoringConfig `yaml:"monitoring" json:"monitoring"`

	// Backup Configuration
	Backup BackupConfig `yaml:"backup" json:"backup"`
}

// AIConfig contains AI-related configuration
type AIConfig struct {
	PatternAnalysisEnabled    bool    `yaml:"pattern_analysis_enabled" json:"pattern_analysis_enabled"`
	PredictiveMaintenance     bool    `yaml:"predictive_maintenance" json:"predictive_maintenance"`
	IntelligentCategorization bool    `yaml:"intelligent_categorization" json:"intelligent_categorization"`
	LearningRate              float64 `yaml:"learning_rate" json:"learning_rate"`
	ConfidenceThreshold       float64 `yaml:"confidence_threshold" json:"confidence_threshold"`
}

// VectorDBConfig contains vector database configuration
type VectorDBConfig struct {
	Enabled        bool   `yaml:"enabled" json:"enabled"`
	Host           string `yaml:"host" json:"host"`
	Port           int    `yaml:"port" json:"port"`
	CollectionName string `yaml:"collection_name" json:"collection_name"`
	VectorSize     int    `yaml:"vector_size" json:"vector_size"`
}

// ManagerIntegrationConfig defines which managers to integrate with
type ManagerIntegrationConfig struct {
	ErrorManager         bool `yaml:"error_manager" json:"error_manager"`
	StorageManager       bool `yaml:"storage_manager" json:"storage_manager"`
	SecurityManager      bool `yaml:"security_manager" json:"security_manager"`
	IntegratedManager    bool `yaml:"integrated_manager" json:"integrated_manager"`
	DocumentationManager bool `yaml:"documentation_manager" json:"documentation_manager"`
	LoggingManager       bool `yaml:"logging_manager" json:"logging_manager"`
	MonitoringManager    bool `yaml:"monitoring_manager" json:"monitoring_manager"`
	PerformanceManager   bool `yaml:"performance_manager" json:"performance_manager"`
	CacheManager         bool `yaml:"cache_manager" json:"cache_manager"`
	ConfigManager        bool `yaml:"config_manager" json:"config_manager"`
	EmailManager         bool `yaml:"email_manager" json:"email_manager"`
	NotificationManager  bool `yaml:"notification_manager" json:"notification_manager"`
	SchedulerManager     bool `yaml:"scheduler_manager" json:"scheduler_manager"`
	TestManager          bool `yaml:"test_manager" json:"test_manager"`
	DependencyManager    bool `yaml:"dependency_manager" json:"dependency_manager"`
	GitManager           bool `yaml:"git_manager" json:"git_manager"`
	BackupManager        bool `yaml:"backup_manager" json:"backup_manager"`
}

// ScriptConfig represents configuration for existing scripts
type ScriptConfig struct {
	Name        string                 `yaml:"name" json:"name"`
	Path        string                 `yaml:"path" json:"path"`
	Type        string                 `yaml:"type" json:"type"`
	Purpose     string                 `yaml:"purpose" json:"purpose"`
	Integration bool                   `yaml:"integration" json:"integration"`
	Parameters  map[string]interface{} `yaml:"parameters" json:"parameters"`
}

// CleanupConfig contains cleanup-related settings
type CleanupConfig struct {
	EnabledLevels          []int     `yaml:"enabled_levels" json:"enabled_levels"`
	RetentionPeriodDays    int       `yaml:"retention_period_days" json:"retention_period_days"`
	BackupBeforeCleanup    bool      `yaml:"backup_before_cleanup" json:"backup_before_cleanup"`
	SafetyChecks           bool      `yaml:"safety_checks" json:"safety_checks"`
	GitHistoryPreservation bool      `yaml:"git_history_preservation" json:"git_history_preservation"`
	SafetyThreshold        float64   `yaml:"safety_threshold" json:"safety_threshold"`
	MinFileSize            int       `yaml:"min_file_size" json:"min_file_size"`
	MaxFileAge             int       `yaml:"max_file_age" json:"max_file_age"`
}

// PerformanceConfig contains performance-related settings
type PerformanceConfig struct {
	MaxConcurrentOperations int           `yaml:"max_concurrent_operations" json:"max_concurrent_operations"`
	OperationTimeout        time.Duration `yaml:"operation_timeout" json:"operation_timeout"`
	HealthCheckInterval     time.Duration `yaml:"health_check_interval" json:"health_check_interval"`
	OptimizationInterval    time.Duration `yaml:"optimization_interval" json:"optimization_interval"`
}

// OrganizationRulesConfig defines rules for file organization
type OrganizationRulesConfig struct {
	ExcludeFolders        []string            `yaml:"exclude_folders" json:"exclude_folders"`
	FileCategories        map[string][]string `yaml:"file_categories" json:"file_categories"`
	SubdivisionStrategies map[string][]string `yaml:"subdivision_strategies" json:"subdivision_strategies"`
}

// SecurityConfig contains security-related settings
type SecurityConfig struct {
	ProtectedFiles   []string `yaml:"protected_files" json:"protected_files"`
	ProtectedFolders []string `yaml:"protected_folders" json:"protected_folders"`
}

// LoggingConfig contains logging configuration
type LoggingConfig struct {
	Level      string `yaml:"level" json:"level"`
	File       string `yaml:"file" json:"file"`
	MaxSize    string `yaml:"max_size" json:"max_size"`
	MaxAge     string `yaml:"max_age" json:"max_age"`
	MaxBackups int    `yaml:"max_backups" json:"max_backups"`
	Compress   bool   `yaml:"compress" json:"compress"`
}

// MonitoringConfig contains monitoring and metrics configuration
type MonitoringConfig struct {
	Enabled          bool                  `yaml:"enabled" json:"enabled"`
	MetricsEndpoint  string                `yaml:"metrics_endpoint" json:"metrics_endpoint"`
	HealthEndpoint   string                `yaml:"health_endpoint" json:"health_endpoint"`
	DashboardEnabled bool                  `yaml:"dashboard_enabled" json:"dashboard_enabled"`
	AlertThresholds  AlertThresholdsConfig `yaml:"alert_thresholds" json:"alert_thresholds"`
}

// AlertThresholdsConfig defines alert thresholds
type AlertThresholdsConfig struct {
	StructureScoreMin          int `yaml:"structure_score_min" json:"structure_score_min"`
	CleanupFrequencyDays       int `yaml:"cleanup_frequency_days" json:"cleanup_frequency_days"`
	OptimizationFrequencyHours int `yaml:"optimization_frequency_hours" json:"optimization_frequency_hours"`
}

// BackupConfig contains backup-related settings
type BackupConfig struct {
	Enabled                  bool   `yaml:"enabled" json:"enabled"`
	BackupBeforeOrganization bool   `yaml:"backup_before_organization" json:"backup_before_organization"`
	BackupRetentionDays      int    `yaml:"backup_retention_days" json:"backup_retention_days"`
	BackupLocation           string `yaml:"backup_location" json:"backup_location"`
	IncrementalBackup        bool   `yaml:"incremental_backup" json:"incremental_backup"`
}

// AutonomyLevel constants
const (
	AssistedOperations = 0
	SemiAutonomous     = 1
	FullyAutonomous    = 2
)

// Manager interface types
type ManagerInterface string

const (
	ErrorManagerType         ManagerInterface = "error-manager"
	StorageManagerType       ManagerInterface = "storage-manager"
	SecurityManagerType      ManagerInterface = "security-manager"
	IntegratedManagerType    ManagerInterface = "integrated-manager"
	DocumentationManagerType ManagerInterface = "documentation-manager"
	LoggingManagerType       ManagerInterface = "logging-manager"
	MonitoringManagerType    ManagerInterface = "monitoring-manager"
	PerformanceManagerType   ManagerInterface = "performance-manager"
	CacheManagerType         ManagerInterface = "cache-manager"
	ConfigManagerType        ManagerInterface = "config-manager"
	EmailManagerType         ManagerInterface = "email-manager"
	NotificationManagerType  ManagerInterface = "notification-manager"
	SchedulerManagerType     ManagerInterface = "scheduler-manager"
	TestManagerType          ManagerInterface = "test-manager"
	DependencyManagerType    ManagerInterface = "dependency-manager"
	GitManagerType           ManagerInterface = "git-manager"
	BackupManagerType        ManagerInterface = "backup-manager"
)

// Manager represents a general manager interface
type Manager interface {
	Initialize() error
	GetHealth() HealthStatus
	GetMetrics() map[string]interface{}
	Stop() error
}

// HealthStatus represents the health status of a component
type HealthStatus struct {
	Status  string            `json:"status"`
	Details map[string]string `json:"details"`
}

// Operation represents an operation that can be performed
type Operation interface {
	Execute() error
	GetType() string
	GetDescription() string
	Validate() error
}

// FileInfo represents information about a file
type FileInfo struct {
	Path       string            `json:"path"`
	Size       int64             `json:"size"`
	ModTime    time.Time         `json:"mod_time"`
	IsDir      bool              `json:"is_dir"`
	Type       string            `json:"type"`
	Category   string            `json:"category"`
	Metadata   map[string]string `json:"metadata"`
	Vector     []float64         `json:"vector,omitempty"`
	Confidence float64           `json:"confidence"`
}

// OrganizationPlan represents a plan for organizing files
type OrganizationPlan struct {
	ID            string           `json:"id"`
	Operations    []OrganizationOp `json:"operations"`
	EstimatedTime time.Duration    `json:"estimated_time"`
	RiskLevel     string           `json:"risk_level"`
	Confidence    float64          `json:"confidence"`
	CreatedAt     time.Time        `json:"created_at"`
}

// OrganizationOp represents a single organization operation
type OrganizationOp struct {
	Type       string            `json:"type"`
	SourcePath string            `json:"source_path"`
	TargetPath string            `json:"target_path"`
	Reason     string            `json:"reason"`
	Confidence float64           `json:"confidence"`
	Metadata   map[string]string `json:"metadata"`
}

// AnalysisResult represents the result of an AI analysis
type AnalysisResult struct {
	StructureScore  float64              `json:"structure_score"`
	Recommendations []string             `json:"recommendations"`
	Issues          []string             `json:"issues"`
	Patterns        []Pattern            `json:"patterns"`
	Suggestions     []OptimizationSuggestion `json:"suggestions"`
	Confidence      float64              `json:"confidence"`
	AnalyzedAt      time.Time            `json:"analyzed_at"`
}

// OptimizationSuggestion represents an AI-generated optimization suggestion
type OptimizationSuggestion struct {
	Type        string  `json:"type"`
	Description string  `json:"description"`
	Priority    int     `json:"priority"`
	Confidence  float64 `json:"confidence"`
}

// Pattern represents a detected pattern in the file structure
type Pattern struct {
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Files       []string `json:"files"`
	Confidence  float64  `json:"confidence"`
	Severity    string   `json:"severity"`
}

// CleanupReport represents the result of a cleanup operation
type CleanupReport struct {
	FilesRemoved     int           `json:"files_removed"`
	FilesReorganized int           `json:"files_reorganized"`
	SpaceFreed       int64         `json:"space_freed"`
	Errors           []string      `json:"errors"`
	Warnings         []string      `json:"warnings"`
	BackupCreated    bool          `json:"backup_created"`
	BackupPath       string        `json:"backup_path"`
	Duration         time.Duration `json:"duration"`
	Operations       []CleanupOp   `json:"operations"`
	CompletedAt      time.Time     `json:"completed_at"`
}

// CleanupOp represents a single cleanup operation
type CleanupOp struct {
	Type        string    `json:"type"`
	FilePath    string    `json:"file_path"`
	Action      string    `json:"action"`
	Reason      string    `json:"reason"`
	Success     bool      `json:"success"`
	Error       string    `json:"error,omitempty"`
	CompletedAt time.Time `json:"completed_at"`
}
