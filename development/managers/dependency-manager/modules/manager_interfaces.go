package main

import (
	"context"
	"time"
)

// SecurityManagerInterface defines the interface for SecurityManager integration
type SecurityManagerInterface interface {
	ScanDependenciesForVulnerabilities(ctx context.Context, deps []Dependency) (*SecurityAuditResult, error)
	ValidateAPIKeyAccess(ctx context.Context, key string) (bool, error)
	HealthCheck(ctx context.Context) error
}

// MonitoringManagerInterface defines the interface for MonitoringManager integration
type MonitoringManagerInterface interface {
	StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error)
	StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error
	CheckSystemHealth(ctx context.Context) (*HealthStatus, error)
	ConfigureAlerts(ctx context.Context, config *AlertConfig) error
	HealthCheck(ctx context.Context) error
	CollectMetrics(ctx context.Context) (*SystemMetrics, error)
}

// StorageManagerInterface defines the interface for StorageManager integration
type StorageManagerInterface interface {
	SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error
	GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error)
	QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*DependencyMetadata, error)
	HealthCheck(ctx context.Context) error
	StoreObject(ctx context.Context, key string, data interface{}) error
	GetObject(ctx context.Context, key string, target interface{}) error
	DeleteObject(ctx context.Context, key string) error
	ListObjects(ctx context.Context, prefix string) ([]string, error)
}

// ContainerManagerInterface defines the interface for ContainerManager integration
type ContainerManagerInterface interface {
	ValidateForContainerization(ctx context.Context, deps []Dependency) (*ContainerValidationResult, error)
	OptimizeForContainer(ctx context.Context, deps []Dependency) (*ContainerOptimization, error)
	HealthCheck(ctx context.Context) error
}

// DeploymentManagerInterface defines the interface for DeploymentManager integration
type DeploymentManagerInterface interface {
	CheckDeploymentReadiness(ctx context.Context, deps []Dependency, env string) (*DeploymentReadiness, error)
	GenerateDeploymentPlan(ctx context.Context, deps []Dependency, env string) (*DeploymentPlan, error)
	HealthCheck(ctx context.Context) error
}

// OperationMetrics represents metrics for a monitored operation
type OperationMetrics struct {
	Operation    string        `json:"operation"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time,omitempty"`
	Duration     time.Duration `json:"duration"`
	CPUUsage     float64       `json:"cpu_usage"`
	MemoryUsage  float64       `json:"memory_usage"`
	Success      bool          `json:"success"`
	ErrorMessage string        `json:"error_message,omitempty"`
}

// AlertConfig defines configuration for dependency operation alerts
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

// SystemMetrics for monitoring integration
type SystemMetrics struct {
	Timestamp    time.Time `json:"timestamp"`
	CPUUsage     float64   `json:"cpu_usage"`
	MemoryUsage  float64   `json:"memory_usage"`
	DiskUsage    float64   `json:"disk_usage"`
	NetworkIn    int64     `json:"network_in"`
	NetworkOut   int64     `json:"network_out"`
	ErrorCount   int64     `json:"error_count"`
	RequestCount int64     `json:"request_count"`
}

// HealthStatus for monitoring integration
type HealthStatus struct {
	Status       string            `json:"status"`
	Timestamp    time.Time         `json:"timestamp"`
	Details      map[string]string `json:"details"`
	ResponseTime time.Duration     `json:"response_time"`
}

// DependencyMetadata represents metadata for dependency storage
type DependencyMetadata struct {
	Name            string            `json:"name"`
	Version         string            `json:"version"`
	Repository      string            `json:"repository"`
	License         string            `json:"license"`
	Vulnerabilities []Vulnerability   `json:"vulnerabilities"`
	LastUpdated     time.Time         `json:"last_updated"`
	Dependencies    []string          `json:"dependencies"`
	Tags            map[string]string `json:"tags"`
}

// Vulnerability represents a security vulnerability
type Vulnerability struct {
	ID          string    `json:"id"`
	Severity    string    `json:"severity"`
	Description string    `json:"description"`
	FixedIn     string    `json:"fixed_in,omitempty"`
	CVSS        float64   `json:"cvss"`
	PublishedAt time.Time `json:"published_at"`
}

// DependencyQuery represents a query for dependencies
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

// ContainerValidationResult represents container validation results
type ContainerValidationResult struct {
	IsValid                bool                    `json:"is_valid"`
	Timestamp              time.Time               `json:"timestamp"`
	ValidationErrors       []string                `json:"validation_errors"`
	Recommendations        []string                `json:"recommendations"`
	PlatformCompatibility  map[string]bool         `json:"platform_compatibility"`
	RequiredDependencies   []ContainerDependency   `json:"required_dependencies"`
	OptimizationsSuggested []ContainerOptimization `json:"optimizations_suggested"`
}

// ContainerOptimization represents container optimization suggestions
type ContainerOptimization struct {
	Type            string    `json:"type"`
	Description     string    `json:"description"`
	EstimatedSaving string    `json:"estimated_saving"`
	Timestamp       time.Time `json:"timestamp"`
	Difficulty      string    `json:"difficulty"`
	Impact          string    `json:"impact"`
}

// ContainerDependency represents a container dependency
type ContainerDependency struct {
	Name       string `json:"name"`
	Version    string `json:"version"`
	Type       string `json:"type"`
	Required   bool   `json:"required"`
	ConfigPath string `json:"config_path"`
}

// SecurityAuditResult represents security audit results
type SecurityAuditResult struct {
	Timestamp       time.Time           `json:"timestamp"`
	Vulnerabilities []VulnerabilityInfo `json:"vulnerabilities"`
	RiskScore       float64             `json:"risk_score"`
	Recommendations []string            `json:"recommendations"`
}

// VulnerabilityInfo represents vulnerability information
type VulnerabilityInfo struct {
	ID          string    `json:"id"`
	Package     string    `json:"package"`
	Version     string    `json:"version"`
	Severity    string    `json:"severity"`
	Description string    `json:"description"`
	FixedIn     string    `json:"fixed_in,omitempty"`
	CVSS        float64   `json:"cvss"`
	PublishedAt time.Time `json:"published_at"`
}

// DeploymentReadiness represents deployment readiness status
type DeploymentReadiness struct {
	Ready         bool              `json:"ready"`
	Timestamp     time.Time         `json:"timestamp"`
	ChecksPassed  []string          `json:"checks_passed"`
	ChecksFailed  []string          `json:"checks_failed"`
	Warnings      []string          `json:"warnings"`
	Environment   string            `json:"environment"`
	Dependencies  []Dependency      `json:"dependencies"`
	Configuration map[string]string `json:"configuration"`
}

// DeploymentPlan represents a deployment plan
type DeploymentPlan struct {
	ID            string                 `json:"id"`
	Environment   string                 `json:"environment"`
	Dependencies  []Dependency           `json:"dependencies"`
	Steps         []DeploymentStep       `json:"steps"`
	EstimatedTime time.Duration          `json:"estimated_time"`
	RollbackPlan  string                 `json:"rollback_plan"`
	Configuration map[string]interface{} `json:"configuration"`
	CreatedAt     time.Time              `json:"created_at"`
}

// DeploymentStep represents a step in a deployment plan
type DeploymentStep struct {
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	Description string        `json:"description"`
	Command     string        `json:"command"`
	Timeout     time.Duration `json:"timeout"`
	Required    bool          `json:"required"`
	Order       int           `json:"order"`
}

// IntegrationHealthStatus represents the health status of integrated managers
type IntegrationHealthStatus struct {
	Overall   string            `json:"overall"`
	Timestamp time.Time         `json:"timestamp"`
	Managers  map[string]string `json:"managers"`
}

// These interfaces allow us to use only the functions we need from each manager
// while maintaining compatibility with the full manager implementations.
// They also help with testing by making it easier to create mock implementations.
