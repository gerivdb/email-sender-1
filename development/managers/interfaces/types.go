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
	LastUpdated     time.Time         `json:"last_updated"`
	Dependencies    []string          `json:"dependencies"`
	Tags            map[string]string `json:"tags"`
	Attributes      map[string]string `json:"attributes,omitempty"`
	UpdatedAt       time.Time         `json:"updated_at"`
}

// Vulnerability représente une vulnérabilité de sécurité
type Vulnerability struct {
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
}

// SystemMetrics pour le monitoring
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

// VulnerabilityReport pour les analyses de sécurité
type VulnerabilityReport struct {
	TotalScanned         int                           `json:"total_scanned"`
	VulnerabilitiesFound int                           `json:"vulnerabilities_found"`
	Timestamp            time.Time                     `json:"timestamp"`
	Details              map[string]*VulnerabilityInfo `json:"details"`
}

// VulnerabilityInfo détails d'une vulnérabilité
type VulnerabilityInfo struct {
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
}

// OperationMetrics pour le monitoring des opérations
type OperationMetrics struct {
	OperationName string        `json:"operation_name"`
	StartTime     time.Time     `json:"start_time"`
	Duration      time.Duration `json:"duration"`
	Status        string        `json:"status"`
	ErrorMessage  string        `json:"error_message,omitempty"`
}
