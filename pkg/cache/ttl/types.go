// types.go - Additional TTL types and configurations for EMAIL_SENDER_1
package ttl

import (
	"context"
	"time"
)

// Analyzer represents the main TTL analyzer interface
type Analyzer interface {
	AnalyzeUsagePatterns() (*AnalysisReport, error)
	OptimizeTTLSettings() error
	GetRecommendations() []TTLRecommendation
	StartAutoOptimization(ctx context.Context, interval time.Duration) error
	AnalyzePattern(pattern string) *PatternAnalysis
	OptimizeTTL(pattern string) error
	GetOptimizationRecommendations() []OptimizationRecommendation
}

// AlertConfig represents alert configuration for TTL monitoring
type AlertConfig struct {
	Enabled          bool                     `json:"enabled"`
	HitRateThreshold float64                  `json:"hit_rate_threshold"`
	Channels         []AlertChannel           `json:"channels"`
	Intervals        map[string]time.Duration `json:"intervals"`
	MetricType       string                   `json:"metric_type"`
	Threshold        float64                  `json:"threshold"`
	Action           string                   `json:"action"`
}

// AlertChannel defines different alert delivery channels
type AlertChannel struct {
	Type    string            `json:"type"`
	Enabled bool              `json:"enabled"`
	Config  map[string]string `json:"config"`
}

// AnalysisReport contains the results of TTL analysis
type AnalysisReport struct {
	Timestamp        time.Time                   `json:"timestamp"`
	UsagePatterns    map[string]*PatternAnalysis `json:"usage_patterns"`
	Recommendations  []TTLRecommendation         `json:"recommendations"`
	PerformanceStats *PerformanceStats           `json:"performance_stats"`
	HealthScore      float64                     `json:"health_score"`
}

// PatternAnalysis contains analysis of specific usage patterns
type PatternAnalysis struct {
	KeyPattern      string        `json:"key_pattern"`
	AccessFrequency float64       `json:"access_frequency"`
	AverageTTL      time.Duration `json:"average_ttl"`
	HitRate         float64       `json:"hit_rate"`
	RecommendedTTL  time.Duration `json:"recommended_ttl"`
}

// TTLRecommendation represents a TTL optimization recommendation
type TTLRecommendation struct {
	KeyPattern       string        `json:"key_pattern"`
	CurrentTTL       time.Duration `json:"current_ttl"`
	RecommendedTTL   time.Duration `json:"recommended_ttl"`
	Reasoning        string        `json:"reasoning"`
	Priority         string        `json:"priority"`
	EstimatedSavings float64       `json:"estimated_savings"`
}

// DataType represents different types of data managed by TTL
type DataType string

const (
	DefaultValues DataType = "default_values"
	Statistics    DataType = "statistics"
	MLModels      DataType = "ml_models"
	Configuration DataType = "configuration"
	UserSessions  DataType = "user_sessions"
)

// Define constants for alert types
const (
	HitRateAlert = "hit_rate_alert"
	MemoryAlert  = "memory_alert"
	LatencyAlert = "latency_alert"
	LogAlert     = "log_alert"
)

// MetricData represents current cache performance metrics
type MetricData struct {
	HitRate     float64   `json:"hit_rate"`
	MissRate    float64   `json:"miss_rate"`
	MemoryUsage float64   `json:"memory_usage"`
	CacheSize   int64     `json:"cache_size"`
	Latency     float64   `json:"latency_ms"`
	Throughput  float64   `json:"throughput_per_sec"`
	ErrorRate   float64   `json:"error_rate"`
	LastUpdated time.Time `json:"last_updated"`
}

// OptimizationRecommendation represents a cache optimization recommendation
type OptimizationRecommendation struct {
	Type         string        `json:"type"`
	KeyPattern   string        `json:"key_pattern"`
	Description  string        `json:"description"`
	CurrentTTL   time.Duration `json:"current_ttl"`
	SuggestedTTL time.Duration `json:"suggested_ttl"`
	Impact       string        `json:"impact"`
	Priority     int           `json:"priority"`
	Reasoning    string        `json:"reasoning"`
	Confidence   float64       `json:"confidence"`
}
