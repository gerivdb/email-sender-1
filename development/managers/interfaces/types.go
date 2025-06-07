package interfaces

import (
	"time"
)

// DependencyMetadata représente les métadonnées d'une dépendance
type DependencyMetadata struct {
	Name            string            `json:"name"`
	Version         string            `json:"version"`
	Repository      string            `json:"repository"`
	License         string            `json:"license"`
	Vulnerabilities []Vulnerability   `json:"vulnerabilities"`
	Description     string            `json:"description,omitempty"` // Added Description
	LastUpdated     time.Time         `json:"last_updated"`
	Dependencies    []string          `json:"dependencies"`
	Tags            map[string]string `json:"tags"`
	Attributes      map[string]string `json:"attributes,omitempty"`
	UpdatedAt       time.Time         `json:"updated_at"`
	Type            string            `json:"type,omitempty"`
	Direct          bool              `json:"direct,omitempty"`
	Required        bool              `json:"required,omitempty"`
	Source          string            `json:"source,omitempty"`
	PackageManager  string            `json:"package_manager,omitempty"`
	CreatedAt       time.Time         `json:"created_at,omitempty"` // Added CreatedAt
}

// Vulnerability représente une vulnérabilité de sécurité
type Vulnerability struct {
	ID          string    `json:"id,omitempty"`           // Added
	PackageName string    `json:"package_name,omitempty"` // Added
	Version     string    `json:"version,omitempty"`      // Added
	Severity    string    `json:"severity"`
	Description string    `json:"description"`
	CVEIDs      []string  `json:"cve_ids,omitempty"`
	FixedIn     []string  `json:"fixed_in,omitempty"`     // Added, can be multiple versions
	CVSS        float64   `json:"cvss,omitempty"`         // Added
	PublishedAt time.Time `json:"published_at,omitempty"` // Added
}

// SystemMetrics for monitoring (updated as per plan)
type SystemMetrics struct {
	CPUUsage    float64           `json:"cpu_usage_percent"`
	MemoryUsage float64           `json:"memory_usage_percent"`
	DiskUsage   map[string]float64 `json:"disk_usage_percent,omitempty"`
	NetworkIO   map[string]int64  `json:"network_io_bytes,omitempty"`
	Timestamp   time.Time         `json:"timestamp"`
}

// VulnerabilityReport pour les analyses de sécurité
type VulnerabilityReport struct {
	Timestamp         time.Time       `json:"timestamp"`
	Vulnerabilities   []Vulnerability `json:"vulnerabilities"`
	Summary           string          `json:"summary,omitempty"`
	TotalScanned      int             `json:"total_scanned"`
	CriticalCount     int             `json:"critical_count"`
	HighCount         int             `json:"high_count"`
	MediumCount       int             `json:"medium_count"`
	LowCount          int             `json:"low_count"`
}

// VulnerabilityInfo details d'une vulnérabilité - This might be redundant if Vulnerability struct is comprehensive
type VulnerabilityInfo struct {
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
}

// OperationMetrics for monitoring (updated as per plan)
type OperationMetrics struct {
	OperationName string                 `json:"operation_name"`
	DurationMs    int64                  `json:"duration_ms"`
	Success       bool                   `json:"success"`
	ErrorCount    int                    `json:"error_count,omitempty"`
	Timestamp     time.Time              `json:"timestamp"`
	Details       map[string]interface{} `json:"details,omitempty"`
	Tags          map[string]string      `json:"tags,omitempty"`
}

// ManagerStatus defines the operational status of a manager.
type ManagerStatus string

const (
	StatusStarting ManagerStatus = "starting"
	StatusRunning  ManagerStatus = "running"
	StatusStopping ManagerStatus = "stopping"
	StatusStopped  ManagerStatus = "stopped"
	StatusError    ManagerStatus = "error"
	StatusUnknown  ManagerStatus = "unknown"
)

// DependencyConflict represents a conflict between dependencies.
type DependencyConflict struct {
	Type        string `json:"type"`
	Description string `json:"description"`
	Path        string `json:"path,omitempty"`
	Version     string `json:"version,omitempty"`
	Resolution  string `json:"resolution,omitempty"`
}

// IntegrationHealthStatus defines the health status of an integrated manager or system.
type IntegrationHealthStatus struct {
	Healthy     bool              `json:"healthy"`
	Message     string            `json:"message,omitempty"`
	Error       string            `json:"error,omitempty"`
	LastChecked time.Time         `json:"last_checked,omitempty"`
	Details     map[string]string `json:"details,omitempty"`
	Overall   string            `json:"overall_status,omitempty"`
	Managers  map[string]string `json:"manager_statuses,omitempty"`
}

// DeploymentReadiness defines the readiness status for a deployment.
type DeploymentReadiness struct {
	Compatible        bool              `json:"compatible"`
	TargetPlatforms   []string          `json:"target_platforms,omitempty"`
	BlockingIssues    []string          `json:"blocking_issues,omitempty"`
	Recommendations   []string          `json:"recommendations,omitempty"`
	Details           map[string]string `json:"details,omitempty"`
	Timestamp         time.Time         `json:"timestamp"`
	Environment       string            `json:"environment,omitempty"` // Added from local manager_interfaces
	Ready             bool              `json:"ready"`                 // Added from local manager_interfaces
}

// ArtifactMetadata defines metadata for a build artifact.
type ArtifactMetadata struct {
	Name         string    `json:"name"`
	Version      string    `json:"version"`
	BuildDate    time.Time `json:"build_date"`
	Checksum     string    `json:"checksum"`
	Path         string    `json:"path,omitempty"`
	Size         int64     `json:"size,omitempty"`
	Dependencies []string  `json:"dependencies,omitempty"` // List of dependency names/versions
}
