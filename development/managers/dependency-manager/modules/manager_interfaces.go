package main

import (
	"context"
	"time"

	"./interfaces"
)

// SecurityManagerInterface defines the interface for SecurityManager integration
type SecurityManagerInterface interface {
	ScanDependenciesForVulnerabilities(ctx context.Context, deps []Dependency) (*interfaces.VulnerabilityReport, error)
	ValidateAPIKeyAccess(ctx context.Context, key string) (bool, error)
	HealthCheck(ctx context.Context) error
}

// MonitoringManagerInterface defines the interface for MonitoringManager integration
type MonitoringManagerInterface interface {
	StartOperationMonitoring(ctx context.Context, operationName string) (*interfaces.OperationMetrics, error)
	StopOperationMonitoring(ctx context.Context, metrics *interfaces.OperationMetrics) error // Changed from RecordOperationMetrics for consistency if Stop is more apt
	CheckSystemHealth(ctx context.Context) (*interfaces.SystemMetrics, error) // Changed from local HealthStatus to interfaces.SystemMetrics
	ConfigureAlerts(ctx context.Context, config *AlertConfig) error // AlertConfig remains local as it's specific to this module's alerting config structure
	HealthCheck(ctx context.Context) error
	CollectMetrics(ctx context.Context) (*interfaces.SystemMetrics, error)
}

// StorageManagerInterface defines the interface for StorageManager integration
type StorageManagerInterface interface {
	SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error
	GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)
	QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error) // DependencyQuery remains local
	HealthCheck(ctx context.Context) error
	StoreObject(ctx context.Context, key string, data interface{}) error
	GetObject(ctx context.Context, key string, target interface{}) error
	DeleteObject(ctx context.Context, key string) error
	ListObjects(ctx context.Context, prefix string) ([]string, error)
}

// ContainerManagerInterface defines the interface for ContainerManager integration
type ContainerManagerInterface interface {
	ValidateForContainerization(ctx context.Context, deps []Dependency) (*ContainerValidationResult, error) // ContainerValidationResult is local
	OptimizeForContainer(ctx context.Context, deps []Dependency) (*ContainerOptimization, error)       // ContainerOptimization is local
	HealthCheck(ctx context.Context) error
}

// DeploymentManagerInterface defines the interface for DeploymentManager integration
type DeploymentManagerInterface interface {
	CheckDeploymentReadiness(ctx context.Context, deps []Dependency, env string) (*interfaces.DeploymentReadiness, error) // Changed to interfaces.DeploymentReadiness
	GenerateDeploymentPlan(ctx context.Context, deps []Dependency, env string) (*DeploymentPlan, error)       // DeploymentPlan is local
	HealthCheck(ctx context.Context) error
	CheckDependencyCompatibility(ctx context.Context, deps []*interfaces.DependencyMetadata, targetPlatform string) (*interfaces.DeploymentReadiness, error) // Changed param and return
	GenerateArtifactMetadata(ctx context.Context, deps []*interfaces.DependencyMetadata) (*interfaces.ArtifactMetadata, error) // Changed param and return
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

// HealthStatus for monitoring integration (local type, distinct from interfaces.IntegrationHealthStatus)
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

// Note: Local types like AlertConfig, HealthStatus, DependencyQuery,
// ContainerValidationResult, ContainerOptimization, ContainerDependency,
// DeploymentPlan, DeploymentStep are kept local as they might be specific
// to this module's internal workings or its direct interface contracts
// before mapping to/from the shared `interfaces` package types.
// The key is that methods intended for cross-manager communication
// (if these interfaces were implemented by truly separate manager microservices)
// should standardize on types from the `interfaces` package.
// For now, focusing on what makes this module compile with the given plan.
// ArtifactMetadata used by DeploymentManagerInterface is now expected from interfaces package.
// DeploymentReadiness used by DeploymentManagerInterface is now expected from interfaces package.
// OperationMetrics and SystemMetrics are now from interfaces package.
// DependencyMetadata is now from interfaces package.
// VulnerabilityReport is now from interfaces package.
// IntegrationHealthStatus (if it were used by these interfaces) would be from interfaces package.
// SecurityAuditResult and VulnerabilityInfo (local) are removed as VulnerabilityReport from interfaces package is used.
