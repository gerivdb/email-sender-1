package dependency

import (
	"context"
	"time"

	"go.uber.org/zap"
)

// SecurityManagerInterface defines the interface for SecurityManager integration
type SecurityManagerInterface interface {
	ScanDependenciesForVulnerabilities(ctx context.Context, deps []Dependency) (*VulnerabilityReport, error)
	ValidateAPIKeyAccess(ctx context.Context, key string) (bool, error)
	HealthCheck(ctx context.Context) error
	GetSecret(key string) (string, error)
	EncryptData(data []byte) ([]byte, error)
	DecryptData(encryptedData []byte) ([]byte, error)
}

// MonitoringManagerInterface defines the interface for MonitoringManager integration
type MonitoringManagerInterface interface {
	StartOperationMonitoring(ctx context.Context, operationName string) (*OperationMetrics, error)
	StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error // Changed from RecordOperationMetrics for consistency if Stop is more apt
	CheckSystemHealth(ctx context.Context) (*SystemMetrics, error)                // Changed from local HealthStatus to SystemMetrics
	ConfigureAlerts(ctx context.Context, config *AlertConfig) error               // AlertConfig remains local as it's specific to this module's alerting config structure
	HealthCheck(ctx context.Context) error
	CollectMetrics(ctx context.Context) (*SystemMetrics, error)
}

// StorageManagerInterface defines the interface for StorageManager integration
type StorageManagerInterface interface {
	SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error
	GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error)
	QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*DependencyMetadata, error) // DependencyQuery remains local
	HealthCheck(ctx context.Context) error
	StoreObject(ctx context.Context, key string, data interface{}) error
	GetObject(ctx context.Context, key string, target interface{}) error
	DeleteObject(ctx context.Context, key string) error
	ListObjects(ctx context.Context, prefix string) ([]string, error)
}

// ContainerManagerInterface defines the interface for ContainerManager integration
type ContainerManagerInterface interface {
	ValidateForContainerization(ctx context.Context, deps []Dependency) (*ContainerValidationResult, error) // ContainerValidationResult is local
	OptimizeForContainer(ctx context.Context, deps []Dependency) (*ContainerOptimization, error)            // ContainerOptimization is local
	HealthCheck(ctx context.Context) error
	GetContainerDependencies(ctx context.Context, containerID string) ([]*ContainerDependency, error)
	ValidateContainerCompatibility(ctx context.Context, dependencies []Dependency) error
	BuildDependencyImage(ctx context.Context, config *ImageBuildConfig) error
}

// DeploymentManagerInterface defines the interface for DeploymentManager integration
type DeploymentManagerInterface interface {
	CheckDeploymentReadiness(ctx context.Context, deps []Dependency, env string) (*DeploymentReadiness, error) // Changed to DeploymentReadiness
	GenerateDeploymentPlan(ctx context.Context, deps []Dependency, env string) (*DeploymentPlan, error)        // DeploymentPlan is local
	HealthCheck(ctx context.Context) error
	CheckDependencyCompatibility(ctx context.Context, deps []*DependencyMetadata, targetPlatform string) (*DeploymentReadiness, error) // Changed param and return
	GenerateArtifactMetadata(ctx context.Context, deps []*DependencyMetadata) (*ArtifactMetadata, error)                               // Changed param and return
	ValidateDeploymentDependencies(ctx context.Context, dependencies []Dependency) error
	UpdateDeploymentConfig(ctx context.Context, config *DeploymentConfig) error
	GetEnvironmentDependencies(ctx context.Context, env string) ([]*EnvironmentDependency, error)
}

// AlertConfig defines configuration for dependency operation alerts (local type)
type AlertConfig struct {
	Name            string             `json:"name"`
	Enabled         bool               `json:"enabled"`
	Conditions      []string           `json:"conditions"`
	Thresholds      map[string]float64 `json:"thresholds"`
	NotifyChannels  []string           `json:"notify_channels"`
	SuppressTimeout int                `json:"suppress_timeout_minutes"`
	MetricName      string             `json:"metric_name"`
	Threshold       float64            `json:"threshold"`
	Operator        string             `json:"operator"`
	Recipients      []string           `json:"recipients"`
}

// HealthStatus for monitoring integration (local type, distinct from IntegrationHealthStatus)
type HealthStatus struct {
	Status       string            `json:"status"`
	Timestamp    time.Time         `json:"timestamp"`
	Details      map[string]string `json:"details"`
	ResponseTime time.Duration     `json:"response_time"`
}

// DependencyQuery represents a query for dependencies (local type)
type DependencyQuery struct {
	Name       string   `json:"name,omitempty"`
	Version    string   `json:"version,omitempty"`
	Repository string   `json:"repository,omitempty"`
	License    string   `json:"license,omitempty"`
	Tags       []string `json:"tags,omitempty"`
	HasVulns   *bool    `json:"has_vulnerabilities,omitempty"`
	Limit      int      `json:"limit,omitempty"`
	Offset     int      `json:"offset,omitempty"`
}

// ContainerValidationResult represents container validation results (local type)
type ContainerValidationResult struct {
	IsValid                bool                    `json:"is_valid"` // Was Compatible
	Timestamp              time.Time               `json:"timestamp"`
	ValidationErrors       []string                `json:"validation_errors"` // Was Issues
	Recommendations        []string                `json:"recommendations"`
	PlatformCompatibility  map[string]bool         `json:"platform_compatibility"`
	RequiredDependencies   []ContainerDependency   `json:"required_dependencies"` // ContainerDependency is local
	OptimizationsSuggested []ContainerOptimization `json:"optimizations_suggested"`
}

// ContainerOptimization represents container optimization suggestions (local type)
type ContainerOptimization struct {
	Type            string    `json:"type"`
	Description     string    `json:"description"`
	EstimatedSaving string    `json:"estimated_saving"`
	Timestamp       time.Time `json:"timestamp"`
	Difficulty      string    `json:"difficulty"`
	Impact          string    `json:"impact"`
}

// ContainerDependency represents a container dependency (local type)
type ContainerDependency struct {
	Name       string `json:"name"`
	Version    string `json:"version"`
	Type       string `json:"type"`
	Required   bool   `json:"required"`
	ConfigPath string `json:"config_path"`
}

// DeploymentPlan represents a deployment plan (local type)
type DeploymentPlan struct {
	ID            string                 `json:"id"`
	Environment   string                 `json:"environment"`
	Dependencies  []Dependency           `json:"dependencies"` // Local Dependency type
	Steps         []DeploymentStep       `json:"steps"`        // Local DeploymentStep type
	EstimatedTime time.Duration          `json:"estimated_time"`
	RollbackPlan  string                 `json:"rollback_plan"`
	Configuration map[string]interface{} `json:"configuration"`
	CreatedAt     time.Time              `json:"created_at"`
}

// DeploymentStep represents a step in a deployment plan (local type)
type DeploymentStep struct {
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	Description string        `json:"description"`
	Command     string        `json:"command"`
	Timeout     time.Duration `json:"timeout"`
	Required    bool          `json:"required"`
	Order       int           `json:"order"`
}

// VulnerabilityReport represents a security vulnerability report (local type)
type VulnerabilityReport struct {
	Timestamp       time.Time
	TotalScanned    int
	CriticalCount   int
	HighCount       int
	MediumCount     int
	LowCount        int
	Vulnerabilities []Vulnerability
}

// Vulnerability represents a single security vulnerability (local type)
type Vulnerability struct {
	PackageName string
	Version     string
	Description string
	Severity    string
	CVEIDs      []string
	FixedIn     string
}

// OperationMetrics represents metrics for a monitored operation (local type)
type OperationMetrics struct {
	OperationName string
	Timestamp     time.Time
	Success       bool
	DurationMs    int64
	ErrorMessage  string
	CPUUsage      float64
	MemoryUsage   float64
	Tags          map[string]string
}

// SystemMetrics represents system-wide metrics (local type)
type SystemMetrics struct {
	Timestamp    time.Time
	CPUUsage     float64
	MemoryUsage  float64
	DiskUsage    float64
	NetworkIn    int64
	NetworkOut   int64
	ErrorCount   int
	RequestCount int
}

// IntegrationHealthStatus represents the health status of all integrated managers
type IntegrationHealthStatus struct {
	Overall     string            `json:"overall"`
	Healthy     bool              `json:"healthy"`
	Message     string            `json:"message"`
	Managers    map[string]string `json:"managers"`
	LastChecked time.Time         `json:"last_checked"`
}

// DeploymentReadiness represents the readiness status for deployment
type DeploymentReadiness struct {
	Compatible      bool              `json:"compatible"`
	Ready           bool              `json:"ready"`
	TargetPlatforms []string          `json:"target_platforms"`
	BlockingIssues  []string          `json:"blocking_issues"`
	Warnings        []string          `json:"warnings"`
	Recommendations []string          `json:"recommendations"`
	Environment     string            `json:"environment"`
	Timestamp       time.Time         `json:"timestamp"`
	Details         map[string]string `json:"details"`
}

// ArtifactMetadata represents metadata for a deployment artifact.
type ArtifactMetadata struct {
	Name              string    `json:"name"`
	Version           string    `json:"version"`
	BuildDate         time.Time `json:"build_date"`
	Checksum          string    `json:"checksum"`
	Size              int64     `json:"size"`
	TargetEnvironment string    `json:"target_environment"`
	DependencyHash    string    `json:"dependency_hash"` // Hash of dependencies used for this artifact
}

// ErrorManager defines the interface for error handling
type ErrorManager interface {
	ProcessError(err error, source string, fields ...zap.Field) error
	CatalogError(entry *ErrorEntry) error
	ValidateErrorEntry(entry *ErrorEntry) error
}

// ErrorEntry represents a structured error entry
type ErrorEntry struct {
	ID             string                 `json:"id"`
	Timestamp      time.Time              `json:"timestamp"`
	Message        string                 `json:"message"`
	StackTrace     string                 `json:"stack_trace"`
	Module         string                 `json:"module"`
	ErrorCode      string                 `json:"error_code"`
	ManagerContext map[string]interface{} `json:"manager_context"`
	Severity       string                 `json:"severity"`
}

// Dependency defines a project dependency (local type)
type Dependency struct {
	Name       string
	Version    string
	Repository string
	License    string
}
