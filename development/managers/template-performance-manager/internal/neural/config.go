// Package neural provides configuration for the neural pattern processor
package neural

import (
	"time"
)

// Config holds configuration for the neural pattern processor
type Config struct {
	// AI/ML settings
	AIServiceURL        string  `json:"ai_service_url"`
	ModelPath           string  `json:"model_path"`
	ConfidenceThreshold float64 `json:"confidence_threshold"`

	// Pattern analysis settings
	MaxPatternAge    time.Duration `json:"max_pattern_age"`
	PatternCacheSize int           `json:"pattern_cache_size"`
	// Performance constraints
	MaxAnalysisTime    time.Duration `json:"max_analysis_time"`
	MaxConcurrentTasks int           `json:"max_concurrent_tasks"`
	PerformanceTarget  time.Duration `json:"performance_target"` // < 100ms

	// Historical data settings
	HistoryRetention  time.Duration `json:"history_retention"`
	EnrichmentEnabled bool          `json:"enrichment_enabled"`

	// Machine learning settings
	LearningEnabled     bool          `json:"learning_enabled"`
	ModelUpdateInterval time.Duration `json:"model_update_interval"`
	TrainingDataSize    int           `json:"training_data_size"`
}

// DefaultConfig returns the default configuration for the neural processor
func DefaultConfig() Config {
	return Config{
		AIServiceURL:        "http://localhost:8080/ai",
		ModelPath:           "./models/template_patterns.model",
		ConfidenceThreshold: 0.75,

		MaxPatternAge:      24 * time.Hour,
		PatternCacheSize:   10000,
		MaxAnalysisTime:    95 * time.Millisecond, // < 100ms constraint
		MaxConcurrentTasks: 10,
		PerformanceTarget:  100 * time.Millisecond, // < 100ms constraint

		HistoryRetention:  30 * 24 * time.Hour, // 30 days
		EnrichmentEnabled: true,

		LearningEnabled:     true,
		ModelUpdateInterval: time.Hour,
		TrainingDataSize:    50000,
	}
}
