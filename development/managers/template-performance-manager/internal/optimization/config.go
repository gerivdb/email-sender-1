// Package optimization provides configuration for the adaptive optimization engine
package optimization

import (
	"time"
)

// Config holds configuration for the adaptive optimization engine
type Config struct {	// Optimization settings
	OptimizationEnabled     bool          `json:"optimization_enabled"`
	MaxOptimizationTime     time.Duration `json:"max_optimization_time"`
	OptimizationTimeout     time.Duration `json:"optimization_timeout"`
	TargetPerformanceGain   float64       `json:"target_performance_gain"`
	ConfidenceThreshold     float64       `json:"confidence_threshold"`
	
	// Machine learning settings
	MLEnabled              bool          `json:"ml_enabled"`
	ModelPath              string        `json:"model_path"`
	LearningRate           float64       `json:"learning_rate"`
	TrainingDataSize       int           `json:"training_data_size"`
	
	// A/B Testing
	ABTestingEnabled       bool          `json:"ab_testing_enabled"`
	TestDuration           time.Duration `json:"test_duration"`
	MinSampleSize          int           `json:"min_sample_size"`
	SignificanceLevel      float64       `json:"significance_level"`
	
	// Rollback settings
	RollbackEnabled        bool          `json:"rollback_enabled"`
	RollbackThreshold      float64       `json:"rollback_threshold"`
	AutoRollbackTimeout    time.Duration `json:"auto_rollback_timeout"`
	
	// Feedback processing
	FeedbackEnabled        bool          `json:"feedback_enabled"`
	FeedbackWeight         float64       `json:"feedback_weight"`
	FeedbackAggregation    time.Duration `json:"feedback_aggregation"`
		// Performance monitoring
	MonitoringEnabled      bool          `json:"monitoring_enabled"`
	ImpactValidationPeriod time.Duration `json:"impact_validation_period"`
	PerformanceThreshold   float64       `json:"performance_threshold"`
	PerformanceGainTarget  float64       `json:"performance_gain_target"`
	
	// Resource limits
	MaxConcurrentOpts      int           `json:"max_concurrent_opts"`
	MemoryLimit            int64         `json:"memory_limit"`
	CPULimit               float64       `json:"cpu_limit"`
}

// DefaultConfig returns the default configuration for the optimization engine
func DefaultConfig() Config {
	return Config{		OptimizationEnabled:     true,
		MaxOptimizationTime:     5 * time.Minute,
		OptimizationTimeout:     30 * time.Second,
		TargetPerformanceGain:   0.25, // 25% improvement target
		ConfidenceThreshold:     0.75, // 75% confidence threshold
		
		MLEnabled:              true,
		ModelPath:              "./models/optimization.model",
		LearningRate:           0.01,
		TrainingDataSize:       10000,
		
		ABTestingEnabled:       true,
		TestDuration:           24 * time.Hour,
		MinSampleSize:          100,
		SignificanceLevel:      0.05,
		
		RollbackEnabled:        true,
		RollbackThreshold:      -0.05, // Rollback if 5% degradation
		AutoRollbackTimeout:    10 * time.Minute,
		
		FeedbackEnabled:        true,
		FeedbackWeight:         0.3,
		FeedbackAggregation:    time.Hour,
				MonitoringEnabled:      true,
		ImpactValidationPeriod: 24 * time.Hour,
		PerformanceThreshold:   0.1, // 10% improvement threshold
		PerformanceGainTarget:  0.25, // 25% gain target
		
		MaxConcurrentOpts:      5,
		MemoryLimit:            1024 * 1024 * 1024, // 1GB
		CPULimit:               0.8, // 80% CPU
	}
}
