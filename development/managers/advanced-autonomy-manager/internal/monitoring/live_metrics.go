// Package monitoring implements the Real-Time Monitoring Dashboard component
package monitoring

import (
	"time"
)

// LiveMetrics représente des métriques en temps réel
type LiveMetrics struct {
	Timestamp time.Time              `json:"timestamp"`
	Values    map[string]interface{} `json:"values"`
	Source    string                 `json:"source"`
	// Champs ajoutés pour correspondre à l'utilisation dans real_time_monitoring_dashboard.go
	LastUpdate    time.Time     `json:"last_update"`
	HealthScore   float64       `json:"health_score"`
	Status        string        `json:"status"`
	ResponseTime  time.Duration `json:"response_time"`
	ThroughputRPS float64       `json:"throughput_rps"`
	ErrorRate     float64       `json:"error_rate"`
	ResourceUsage *ResourceUsage `json:"resource_usage"`
}
