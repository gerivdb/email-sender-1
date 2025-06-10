// Package analytics provides configuration for the performance metrics engine
package analytics

import (
	"time"
)

// Config holds configuration for the performance metrics engine
type Config struct {
	// Collection settings
	CollectionInterval    time.Duration `json:"collection_interval"`
	MaxCollectionTime     time.Duration `json:"max_collection_time"`
	BufferSize           int           `json:"buffer_size"`
	
	// Storage settings
	StorageType          string        `json:"storage_type"` // "memory", "redis", "postgres"
	StorageURL           string        `json:"storage_url"`
	RetentionPeriod      time.Duration `json:"retention_period"`
	
	// Real-time monitoring
	MonitoringEnabled    bool          `json:"monitoring_enabled"`
	CallbackTimeout      time.Duration `json:"callback_timeout"`
	MonitoringInterval   time.Duration `json:"monitoring_interval"`
	
	// Dashboard export
	DashboardEnabled     bool          `json:"dashboard_enabled"`
	ExportFormats        []string      `json:"export_formats"`
	RefreshInterval      time.Duration `json:"refresh_interval"`
	
	// AI integration
	AIInsightsEnabled    bool          `json:"ai_insights_enabled"`
	AIServiceURL         string        `json:"ai_service_url"`
	InsightConfidence    float64       `json:"insight_confidence"`
		// Performance settings
	MaxConcurrentOps     int           `json:"max_concurrent_ops"`
	AsyncProcessing      bool          `json:"async_processing"`
	CompressionEnabled   bool          `json:"compression_enabled"`
	PerformanceTarget    time.Duration `json:"performance_target"` // < 50ms
	EnableRealTime       bool          `json:"enable_real_time"`
}

// DefaultConfig returns the default configuration for the metrics engine
func DefaultConfig() Config {
	return Config{
		CollectionInterval:    time.Second,
		MaxCollectionTime:     45 * time.Millisecond, // < 50ms constraint
		BufferSize:           1000,
		
		StorageType:          "memory",
		StorageURL:           "",
		RetentionPeriod:      7 * 24 * time.Hour, // 7 days
		
		MonitoringEnabled:    true,
		CallbackTimeout:      5 * time.Second,
		MonitoringInterval:   10 * time.Second,
		
		DashboardEnabled:     true,
		ExportFormats:        []string{"json", "html", "csv"},
		RefreshInterval:      30 * time.Second,
		
		AIInsightsEnabled:    true,
		AIServiceURL:         "http://localhost:8080/ai",
		InsightConfidence:    0.8,
				MaxConcurrentOps:     20,
		AsyncProcessing:      true,
		CompressionEnabled:   false,
		PerformanceTarget:    50 * time.Millisecond, // < 50ms constraint
		EnableRealTime:       true,
	}
}
