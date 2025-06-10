package interfaces

import (
	"context"
	"time"
)

// TemplatePerformanceAnalyticsManager - Interface principale pour l'analyse et optimisation performance templates
type TemplatePerformanceAnalyticsManager interface {
	BaseManager
	
	// Core Analytics - Analyse performance templates
	AnalyzeTemplatePerformance(ctx context.Context, templateID string) (*PerformanceAnalysis, error)
	CollectUsageMetrics(ctx context.Context, sessionID string) (*UsageMetrics, error)
	OptimizeTemplateGeneration(ctx context.Context, request *OptimizationRequest) (*OptimizationResult, error)
	
	// Neural Processing - Traitement IA des patterns
	ProcessNeuralPatterns(ctx context.Context, templatePath string) (*NeuralAnalysis, error)
	AdaptContentGeneration(ctx context.Context, adaptationRequest *AdaptationRequest) (*AdaptationResult, error)
	
	// Reporting & Monitoring - Rapports et surveillance
	GeneratePerformanceReport(ctx context.Context, timeframe TimeFrame) (*PerformanceReport, error)
	SetupRealTimeMonitoring(callback MetricsCallback) error
	ExportAnalyticsDashboard(format ExportFormat) (*DashboardData, error)
}

// BaseManager - Interface de base pour tous les managers
type BaseManager interface {
	Initialize(ctx context.Context) error
	HealthCheck(ctx context.Context) error
	Cleanup() error
	GetMetrics() map[string]interface{}
}

// Types de données principaux

// PerformanceAnalysis - Résultat d'analyse performance d'un template
type PerformanceAnalysis struct {
	ID               string                 `json:"id"`
	TemplateID       string                 `json:"template_id"`
	StartTime        time.Time              `json:"start_time"`
	EndTime          time.Time              `json:"end_time"`
	Duration         time.Duration          `json:"duration"`
	Status           string                 `json:"status"`
	Error            string                 `json:"error,omitempty"`
	Request          *AnalysisRequest       `json:"request"`
	PatternAnalysis  *PatternAnalysis       `json:"pattern_analysis"`
	Metrics          *PerformanceMetrics    `json:"metrics"`
	Optimizations    []*OptimizationResult  `json:"optimizations"`
	GenerationTime   time.Duration          `json:"generation_time"`
	MemoryUsage      int64                 `json:"memory_usage"`
	CPUUtilization   float64               `json:"cpu_utilization"`
	CacheHitRate     float64               `json:"cache_hit_rate"`
	QualityScore     float64               `json:"quality_score"`
	UsagePatterns    []UsagePattern        `json:"usage_patterns"`
	Recommendations  []OptimizationHint    `json:"recommendations"`
	Timestamp        time.Time             `json:"timestamp"`
	AnalysisTime     time.Duration         `json:"analysis_time"`
}

// UsageMetrics - Métriques d'utilisation collectées
type UsageMetrics struct {
	SessionID        string                 `json:"session_id"`
	TemplateUsage    map[string]int         `json:"template_usage"`
	ErrorRates       map[string]float64     `json:"error_rates"`
	PerformanceData  *PerformanceSnapshot   `json:"performance_data"`
	UserSegmentation map[string]interface{} `json:"user_segmentation"`
	CollectedAt      time.Time              `json:"collected_at"`
	ProcessingTime   time.Duration          `json:"processing_time"`
}

// OptimizationRequest - Demande d'optimisation
type OptimizationRequest struct {
	AnalysisID      string                 `json:"analysis_id"`
	TemplateID      string                 `json:"template_id"`
	PatternData     *PatternAnalysis       `json:"pattern_data"`
	MetricsData     *PerformanceMetrics    `json:"metrics_data"`
	CurrentConfig   map[string]interface{} `json:"current_config"`
	TargetMetrics   map[string]float64     `json:"target_metrics"`
	Constraints     map[string]interface{} `json:"constraints"`
	Priority        OptimizationPriority   `json:"priority"`
	MaxProcessTime  time.Duration          `json:"max_process_time"`
}

// OptimizationResult - Résultat d'optimisation
type OptimizationResult struct {
	RequestID         string             `json:"request_id"`
	OriginalMetrics   map[string]float64 `json:"original_metrics"`
	OptimizedMetrics  map[string]float64 `json:"optimized_metrics"`
	Improvements      map[string]float64 `json:"improvements"`
	AppliedChanges    []string          `json:"applied_changes"`
	Success           bool               `json:"success"`
	ProcessingTime    time.Duration      `json:"processing_time"`
	ConfidenceScore   float64           `json:"confidence_score"`
}

// UsagePattern - Pattern d'utilisation détecté
type UsagePattern struct {
	PatternID       string            `json:"pattern_id"`
	Frequency       int               `json:"frequency"`
	Context         map[string]string `json:"context"`
	Performance     *MetricSnapshot   `json:"performance"`
	UserSegment     string            `json:"user_segment"`
	Priority        int               `json:"priority"`
	Confidence      float64           `json:"confidence"`
}

// OptimizationHint - Suggestion d'optimisation
type OptimizationHint struct {
	Type            string           `json:"type"`
	Description     string           `json:"description"`
	Impact          string           `json:"impact"`
	Complexity      int              `json:"complexity"`
	EstimatedGain   float64          `json:"estimated_gain"`
	Implementation  string           `json:"implementation"`
}

// Types d'énumération
type OptimizationPriority int

const (
	PriorityLow OptimizationPriority = iota
	PriorityMedium
	PriorityHigh
	PriorityCritical
)

type TimeFrame string

const (
	TimeFrameHour  TimeFrame = "hour"
	TimeFrameDay   TimeFrame = "day"
	TimeFrameWeek  TimeFrame = "week"
	TimeFrameMonth TimeFrame = "month"
)

type ExportFormat string

const (
	FormatJSON ExportFormat = "json"
	FormatHTML ExportFormat = "html"
	FormatCSV  ExportFormat = "csv"
)

// Types de support
type MetricSnapshot struct {
	Timestamp       time.Time     `json:"timestamp"`
	GenerationTime  time.Duration `json:"generation_time"`
	MemoryUsage     int64        `json:"memory_usage"`
	CPUUtilization  float64      `json:"cpu_utilization"`
	ErrorCount      int          `json:"error_count"`
}

type PerformanceSnapshot struct {
	TotalRequests   int64                  `json:"total_requests"`
	AverageLatency  time.Duration          `json:"average_latency"`
	ThroughputRPS   float64               `json:"throughput_rps"`
	ErrorRate       float64               `json:"error_rate"`
	ResourceUsage   map[string]interface{} `json:"resource_usage"`
	LastUpdated     time.Time              `json:"last_updated"`
	RefreshInterval time.Duration          `json:"refresh_interval"`
}

// Interfaces de callback
type MetricsCallback func(metrics *MetricsCollection) error

// Types pour Neural Processing et autres fonctionnalités
type NeuralAnalysis struct {
	PatternAnalysis  *PatternAnalysis       `json:"pattern_analysis"`
	Predictions      []PerformancePrediction `json:"predictions"`
	Recommendations  []NeuralRecommendation  `json:"recommendations"`
	ConfidenceScore  float64                `json:"confidence_score"`
	ProcessingTime   time.Duration          `json:"processing_time"`
}

type AdaptationRequest struct {
	TemplateID      string                 `json:"template_id"`
	TargetProfile   *UserProfile           `json:"target_profile"`
	AdaptationRules map[string]interface{} `json:"adaptation_rules"`
}

type AdaptationResult struct {
	AdaptedTemplate  *Template             `json:"adapted_template"`
	Changes          []AdaptationChange    `json:"changes"`
	PerformanceGain  float64              `json:"performance_gain"`
	Success          bool                 `json:"success"`
}

type PerformanceReport struct {
	TimeFrame        TimeFrame             `json:"timeframe"`
	Summary          *ReportSummary        `json:"summary"`
	DetailedMetrics  map[string]interface{} `json:"detailed_metrics"`
	Trends           []TrendAnalysis       `json:"trends"`
	GeneratedAt      time.Time             `json:"generated_at"`
}

type DashboardData struct {
	Format          ExportFormat           `json:"format"`
	Data            map[string]interface{} `json:"data"`
	LastUpdated     time.Time              `json:"last_updated"`
	RefreshInterval time.Duration          `json:"refresh_interval"`
}

// Types supplémentaires pour le support complet
type PatternAnalysis struct {
	Patterns        []DetectedPattern      `json:"patterns"`
	Correlations    []PatternCorrelation   `json:"correlations"`
	Anomalies       []PerformanceAnomaly   `json:"anomalies"`
	Confidence      float64               `json:"confidence"`
}

type PerformancePrediction struct {
	Metric          string        `json:"metric"`
	PredictedValue  float64       `json:"predicted_value"`
	Confidence      float64       `json:"confidence"`
	TimeHorizon     time.Duration `json:"time_horizon"`
}

type UserProfile struct {
	UserID          string                 `json:"user_id"`
	Preferences     map[string]interface{} `json:"preferences"`
	UsageHistory    []UsageRecord          `json:"usage_history"`
	PerformanceReqs map[string]float64     `json:"performance_requirements"`
}

type Template struct {
	ID              string                 `json:"id"`
	Name            string                 `json:"name"`
	Content         string                 `json:"content"`
	Variables       map[string]interface{} `json:"variables"`
	Metadata        map[string]string      `json:"metadata"`
}

type AdaptationChange struct {
	Type            string      `json:"type"`
	Description     string      `json:"description"`
	Impact          float64     `json:"impact"`
	Applied         bool        `json:"applied"`
}

type ReportSummary struct {
	TotalTemplates      int           `json:"total_templates"`
	TotalAnalyses       int           `json:"total_analyses"`
	OptimizationGains   float64       `json:"optimization_gains"`
	TopPatterns         []string      `json:"top_patterns"`
	AveragePerformance  float64       `json:"average_performance"`
	TopIssues          []string       `json:"top_issues"`
	ImprovementAreas   []string       `json:"improvement_areas"`
	OverallScore       float64        `json:"overall_score"`
}

type TrendAnalysis struct {
	Metric          string        `json:"metric"`
	Trend           string        `json:"trend"` // "increasing", "decreasing", "stable"
	ChangeRate      float64       `json:"change_rate"`
	Significance    float64       `json:"significance"`
}

type DetectedPattern struct {
	ID              string                 `json:"id"`
	Type            string                 `json:"type"`
	Frequency       int                    `json:"frequency"`
	Characteristics map[string]interface{} `json:"characteristics"`
}

type PatternCorrelation struct {
	Pattern1        string        `json:"pattern1"`
	Pattern2        string        `json:"pattern2"`
	Strength        float64       `json:"strength"`
	Type            string        `json:"type"`
}

type PerformanceAnomaly struct {
	Timestamp       time.Time     `json:"timestamp"`
	Metric          string        `json:"metric"`
	ExpectedValue   float64       `json:"expected_value"`
	ActualValue     float64       `json:"actual_value"`
	Severity        string        `json:"severity"`
}

type UsageRecord struct {
	Timestamp       time.Time              `json:"timestamp"`
	TemplateID      string                 `json:"template_id"`
	Parameters      map[string]interface{} `json:"parameters"`
	Performance     *MetricSnapshot        `json:"performance"`
}

// Additional missing types for manager compatibility (not defined in neural_processor.go)
type AnalysisRequest struct {
	TemplateID      string                 `json:"template_id"`
	SessionData     *SessionData           `json:"session_data"`
	TemplateData    *SessionData           `json:"template_data"`
	CurrentConfig   map[string]interface{} `json:"current_config"`
	TargetMetrics   map[string]float64     `json:"target_metrics"`
	Priority        OptimizationPriority   `json:"priority"`
	MaxProcessTime  time.Duration          `json:"max_process_time"`
}

type ReportRequest struct {
	TimeRange       TimeFrame              `json:"time_range"`
	IncludeDetails  bool                   `json:"include_details"`
	Format          ExportFormat           `json:"format"`
	Filters         *MetricsFilter         `json:"filters"`
}

type AnalyticsReport struct {
	ID              string                    `json:"id"`
	TimeRange       TimeFrame                 `json:"timeframe"`
	Summary         *ReportSummary            `json:"summary"`
	MetricsData     map[string]interface{}    `json:"metrics_data"`
	Insights        []NeuralRecommendation    `json:"insights"`
	Optimizations   []*OptimizationResult     `json:"optimizations"`
	GeneratedAt     time.Time                 `json:"generated_at"`
}

type ManagerStatus struct {
	IsInitialized   bool                   `json:"is_initialized"`
	IsRunning       bool                   `json:"is_running"`
	Version         string                 `json:"version"`
	StartTime       time.Time              `json:"start_time"`
	LastUpdate      time.Time              `json:"last_update"`
	RequestCount    int64                  `json:"request_count"`
	ErrorCount      int64                  `json:"error_count"`
	ActiveAnalyses  int                    `json:"active_analyses"`
	Health          string                 `json:"health"`
}
