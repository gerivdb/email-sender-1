package interfaces

import (
	"context"
	"time"
)

// Import types needed for interface compatibility
type MetricsFilter struct {
	TimeRange     TimeFrame `json:"time_range"`
	TemplateIDs   []string  `json:"template_ids"`
	UserIDs       []string  `json:"user_ids"`
	MetricTypes   []string  `json:"metric_types"`
	MinConfidence float64   `json:"min_confidence"`
}

type OptimizationApplicationRequest struct {
	OptimizationID  string        `json:"optimization_id"`
	TargetTemplates []string      `json:"target_templates"`
	ValidateOnly    bool          `json:"validate_only"`
	Rollback        bool          `json:"rollback"`
	Timeout         time.Duration `json:"timeout"`
}

type NeuralRecommendation struct {
	Type           string  `json:"type"`
	Action         string  `json:"action"`
	ExpectedImpact float64 `json:"expected_impact"`
	Priority       int     `json:"priority"`
}

// NeuralPatternProcessor - Processeur IA pour analyse patterns templates
type NeuralPatternProcessor interface {
	// Lifecycle methods
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error

	// Analyse patterns templates avec IA (< 100ms)
	AnalyzeTemplatePatterns(ctx context.Context, templatePath string) (*PatternAnalysis, error)

	// Extraction patterns d'usage
	ExtractUsagePatterns(sessionData *SessionData) (*UsagePattern, error)

	// Corrélation métriques performance
	CorrelatePerformanceMetrics(metrics *PerformanceMetrics) (*Correlation, error)

	// Optimisation reconnaissance patterns
	OptimizePatternRecognition(feedback *OptimizationFeedback) error

	// Get insights for reporting
	GetInsights(ctx context.Context, timeRange TimeFrame) ([]NeuralRecommendation, error)

	// Health check processeur
	HealthCheck(ctx context.Context) error

	// Nettoyage ressources
	Cleanup() error
}

// PerformanceMetricsEngine - Moteur de collecte métriques (< 50ms)
type PerformanceMetricsEngine interface {
	// Lifecycle methods
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error

	// Collecte métriques usage
	CollectUsageMetrics(ctx context.Context, sessionID string) (*MetricsReport, error)

	// Collecte métriques performance
	CollectPerformanceMetrics(ctx context.Context, sessionData *SessionData) (*PerformanceMetrics, error)

	// Get metrics with filter
	GetMetrics(ctx context.Context, filter MetricsFilter) (*PerformanceMetrics, error)

	// Agrégation métriques par timeframe
	AggregateMetrics(timeframe TimeFrame) (*AggregatedMetrics, error)

	// Export dashboard métriques
	ExportMetricsDashboard(format ExportFormat) (*DashboardData, error)

	// Export dashboard data for reporting
	ExportDashboardData(ctx context.Context, timeRange TimeFrame) (map[string]interface{}, error)

	// Configuration monitoring temps réel
	SetupRealTimeMonitoring(callback MetricsCallback) error
}

// AdaptiveOptimizationEngine - Moteur d'optimisation adaptative
type AdaptiveOptimizationEngine interface {
	// Lifecycle methods
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error

	// Optimisation génération templates
	OptimizeTemplateGeneration(ctx context.Context, request *OptimizationRequest) (*OptimizationResult, error)

	// Generate optimizations for analysis
	GenerateOptimizations(ctx context.Context, request *OptimizationRequest) ([]*OptimizationResult, error)

	// Apply optimizations
	ApplyOptimizations(ctx context.Context, request *OptimizationApplicationRequest) (*OptimizationResult, error)

	// Application changements adaptatifs
	ApplyAdaptiveChanges(ctx context.Context, changes []AdaptiveChange) (*ApplicationResult, error)

	// Validation optimisations
	ValidateOptimizations(ctx context.Context, optimizations []Optimization) (*ValidationResult, error)

	// Get optimization history for reporting
	GetOptimizationHistory(ctx context.Context, timeRange TimeFrame) ([]*OptimizationResult, error)

	// Apprentissage à partir feedback
	LearnFromFeedback(ctx context.Context, feedback *OptimizationFeedback) error
}

// Types de données pour Neural Processing

// SessionData - Données de session pour analyse
type SessionData struct {
	SessionID       string                 `json:"session_id"`
	UserID          string                 `json:"user_id"`
	StartTime       time.Time              `json:"start_time"`
	EndTime         time.Time              `json:"end_time"`
	TemplateUsage   []TemplateUsageRecord  `json:"template_usage"`
	PerformanceData []PerformanceSnapshot  `json:"performance_data"`
	ErrorEvents     []ErrorEvent           `json:"error_events"`
	Context         map[string]interface{} `json:"context"`
}

// PerformanceMetrics - Métriques performance système
type PerformanceMetrics struct {
	SystemMetrics   *SystemMetrics              `json:"system_metrics"`
	TemplateMetrics map[string]*TemplateMetrics `json:"template_metrics"`
	UserMetrics     map[string]*UserMetrics     `json:"user_metrics"`
	Timestamp       time.Time                   `json:"timestamp"`
	CollectionTime  time.Duration               `json:"collection_time"`
}

// Correlation - Résultat corrélation métriques
type Correlation struct {
	MetricPairs  []MetricCorrelation `json:"metric_pairs"`
	Strength     float64             `json:"strength"`
	Significance float64             `json:"significance"`
	Pattern      string              `json:"pattern"`
	Confidence   float64             `json:"confidence"`
}

// OptimizationFeedback - Feedback pour optimisation
type OptimizationFeedback struct {
	OptimizationID  string    `json:"optimization_id"`
	UserRating      int       `json:"user_rating"` // 1-5
	PerformanceGain float64   `json:"performance_gain"`
	Issues          []string  `json:"issues"`
	Suggestions     []string  `json:"suggestions"`
	Success         bool      `json:"success"`
	Timestamp       time.Time `json:"timestamp"`
}

// MetricsReport - Rapport métriques détaillé
type MetricsReport struct {
	SessionID      string             `json:"session_id"`
	Metrics        *MetricsCollection `json:"metrics"`
	Correlations   []Correlation      `json:"correlations"`
	Insights       []MetricInsight    `json:"insights"`
	CollectedAt    time.Time          `json:"collected_at"`
	ProcessingTime time.Duration      `json:"processing_time"`
}

// AggregatedMetrics - Métriques agrégées
type AggregatedMetrics struct {
	Timeframe TimeFrame            `json:"timeframe"`
	StartTime time.Time            `json:"start_time"`
	EndTime   time.Time            `json:"end_time"`
	Summary   *MetricsSummary      `json:"summary"`
	Trends    []TrendAnalysis      `json:"trends"`
	Anomalies []PerformanceAnomaly `json:"anomalies"`
}

// AdaptiveChange - Changement adaptatif
type AdaptiveChange struct {
	ID              string                 `json:"id"`
	Type            string                 `json:"type"`
	TargetComponent string                 `json:"target_component"`
	Parameters      map[string]interface{} `json:"parameters"`
	ExpectedImpact  float64                `json:"expected_impact"`
	Priority        int                    `json:"priority"`
}

// ApplicationResult - Résultat application changements
type ApplicationResult struct {
	AppliedChanges    []string               `json:"applied_changes"`
	FailedChanges     []string               `json:"failed_changes"`
	PerformanceImpact map[string]float64     `json:"performance_impact"`
	Success           bool                   `json:"success"`
	RollbackData      map[string]interface{} `json:"rollback_data"`
}

// Optimization - Optimisation individuelle
type Optimization struct {
	ID           string                 `json:"id"`
	Type         string                 `json:"type"`
	Target       string                 `json:"target"`
	Algorithm    string                 `json:"algorithm"`
	Parameters   map[string]interface{} `json:"parameters"`
	ExpectedGain float64                `json:"expected_gain"`
}

// ValidationResult - Résultat validation optimisations
type ValidationResult struct {
	ValidOptimizations   []string          `json:"valid_optimizations"`
	InvalidOptimizations []ValidationError `json:"invalid_optimizations"`
	OverallScore         float64           `json:"overall_score"`
	Recommendations      []string          `json:"recommendations"`
}

// Types de support détaillés

// TemplateUsageRecord - Enregistrement usage template
type TemplateUsageRecord struct {
	TemplateID     string                 `json:"template_id"`
	Timestamp      time.Time              `json:"timestamp"`
	Parameters     map[string]interface{} `json:"parameters"`
	GenerationTime time.Duration          `json:"generation_time"`
	OutputSize     int64                  `json:"output_size"`
	Success        bool                   `json:"success"`
	ErrorMessage   string                 `json:"error_message,omitempty"`
}

// ErrorEvent - Événement d'erreur
type ErrorEvent struct {
	Timestamp  time.Time              `json:"timestamp"`
	Type       string                 `json:"type"`
	Message    string                 `json:"message"`
	StackTrace string                 `json:"stack_trace,omitempty"`
	Context    map[string]interface{} `json:"context"`
	Severity   string                 `json:"severity"`
}

// SystemMetrics - Métriques système
type SystemMetrics struct {
	CPUUsage       float64    `json:"cpu_usage"`
	MemoryUsage    int64      `json:"memory_usage"`
	DiskIO         *IOMetrics `json:"disk_io"`
	NetworkIO      *IOMetrics `json:"network_io"`
	GoroutineCount int        `json:"goroutine_count"`
	GCStats        *GCMetrics `json:"gc_stats"`
}

// TemplateMetrics - Métriques par template
type TemplateMetrics struct {
	TemplateID      string        `json:"template_id"`
	UsageCount      int64         `json:"usage_count"`
	AverageTime     time.Duration `json:"average_time"`
	ErrorRate       float64       `json:"error_rate"`
	CacheHitRate    float64       `json:"cache_hit_rate"`
	PopularityScore float64       `json:"popularity_score"`
}

// UserMetrics - Métriques par utilisateur
type UserMetrics struct {
	UserID             string                 `json:"user_id"`
	SessionCount       int                    `json:"session_count"`
	TemplateUsage      map[string]int         `json:"template_usage"`
	AverageSessionTime time.Duration          `json:"average_session_time"`
	ErrorEncountered   int                    `json:"errors_encountered"`
	Preferences        map[string]interface{} `json:"preferences"`
}

// MetricCorrelation - Corrélation entre métriques
type MetricCorrelation struct {
	Metric1      string  `json:"metric1"`
	Metric2      string  `json:"metric2"`
	Coefficient  float64 `json:"coefficient"`
	PValue       float64 `json:"p_value"`
	Relationship string  `json:"relationship"`
}

// MetricsCollection - Collection complète métriques
type MetricsCollection struct {
	Generation  *GenerationMetrics  `json:"generation"`
	Performance *PerformanceMetrics `json:"performance"`
	Usage       *UsageMetrics       `json:"usage"`
	Quality     *QualityMetrics     `json:"quality"`
	User        *UserMetrics        `json:"user"`
}

// MetricInsight - Insight métrique
type MetricInsight struct {
	Type           string  `json:"type"`
	Description    string  `json:"description"`
	Metric         string  `json:"metric"`
	Value          float64 `json:"value"`
	Threshold      float64 `json:"threshold"`
	Severity       string  `json:"severity"`
	Recommendation string  `json:"recommendation"`
}

// MetricsSummary - Résumé métriques
type MetricsSummary struct {
	TotalEvents      int64         `json:"total_events"`
	AverageLatency   time.Duration `json:"average_latency"`
	ErrorRate        float64       `json:"error_rate"`
	ThroughputRPS    float64       `json:"throughput_rps"`
	TopPerformers    []string      `json:"top_performers"`
	BottomPerformers []string      `json:"bottom_performers"`
}

// ValidationError - Erreur de validation
type ValidationError struct {
	OptimizationID string `json:"optimization_id"`
	ErrorType      string `json:"error_type"`
	Message        string `json:"message"`
	Severity       string `json:"severity"`
}

// PerformanceProfile represents a performance profile for pattern analysis
type PerformanceProfile struct {
	ID             string                 `json:"id"`
	TemplateID     string                 `json:"template_id"`
	Metrics        map[string]float64     `json:"metrics"`
	Patterns       map[string]interface{} `json:"patterns"`
	Timestamp      time.Time              `json:"timestamp"`
	Version        string                 `json:"version"`
	GenerationTime time.Duration          `json:"generation_time"`
	MemoryUsage    int64                  `json:"memory_usage"`
	CPUUtilization float64                `json:"cpu_utilization"`
	CacheHitRate   float64                `json:"cache_hit_rate"`
	ErrorRate      float64                `json:"error_rate"`
}

// IOMetrics represents I/O performance metrics
type IOMetrics struct {
	BytesRead    int64 `json:"bytes_read"`
	BytesWritten int64 `json:"bytes_written"`
	ReadOps      int64 `json:"read_ops"`
	WriteOps     int64 `json:"write_ops"`
}

// GCMetrics represents garbage collection metrics
type GCMetrics struct {
	NumGC       uint32        `json:"num_gc"`
	TotalPause  time.Duration `json:"total_pause"`
	LastPause   time.Duration `json:"last_pause"`
	MemoryFreed int64         `json:"memory_freed"`
}

// GenerationMetrics represents template generation metrics
type GenerationMetrics struct {
	TotalGenerations    int64         `json:"total_generations"`
	AverageTime         time.Duration `json:"average_time"`
	SuccessRate         float64       `json:"success_rate"`
	CacheEfficiency     float64       `json:"cache_efficiency"`
	ResourceUtilization float64       `json:"resource_utilization"`
}

// QualityMetrics represents code quality metrics
type QualityMetrics struct {
	CodeQualityScore    float64 `json:"code_quality_score"`
	ConsistencyScore    float64 `json:"consistency_score"`
	MaintenabilityIndex float64 `json:"maintenability_index"`
	ComplexityScore     float64 `json:"complexity_score"`
	SecurityScore       float64 `json:"security_score"`
}
