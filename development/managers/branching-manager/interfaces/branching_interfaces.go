package interfaces

import (
	"context"
	"time"
)

// =============================================================================
// BASE INTERFACES
// =============================================================================

// BaseManager interface pour tous les managers
type BaseManager interface {
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	HealthCheck(ctx context.Context) error
}

// StorageManager interface pour la gestion du stockage
type StorageManager interface {
	Store(ctx context.Context, key string, value interface{}) error
	Retrieve(ctx context.Context, key string) (interface{}, error)
	Delete(ctx context.Context, key string) error
	List(ctx context.Context, pattern string) ([]string, error)
}

// ErrorManager interface pour la gestion des erreurs
type ErrorManager interface {
	LogError(ctx context.Context, err error) error
	GetErrors(ctx context.Context) ([]error, error)
	ClearErrors(ctx context.Context) error
}

// ContextualMemoryManager interface pour la mémoire contextuelle
type ContextualMemoryManager interface {
	Store(ctx context.Context, key string, value interface{}, context map[string]interface{}) error
	Retrieve(ctx context.Context, key string) (interface{}, map[string]interface{}, error)
	Search(ctx context.Context, query map[string]interface{}) ([]interface{}, error)
}

// =============================================================================
// CORE EVENT TYPES
// =============================================================================

// EventType énumération des types d'événements
type EventType string

const (
	EventSessionStart    EventType = "session_start"
	EventSessionEnd      EventType = "session_end"
	EventBranchCreate    EventType = "branch_create"
	EventBranchMerge     EventType = "branch_merge"
	EventQuantumCollapse EventType = "quantum_collapse"
)

// BranchingEvent représente un événement dans le système de branchement
type BranchingEvent struct {
	ID        string                 `json:"id"`
	Type      EventType              `json:"type"`
	Source    string                 `json:"source"`
	Target    string                 `json:"target"`
	Payload   map[string]interface{} `json:"payload"`
	Timestamp time.Time              `json:"timestamp"`
}

// Session représente une session de branchement
type Session struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	State     string                 `json:"state"`
	Data      map[string]interface{} `json:"data"`
	CreatedAt time.Time              `json:"created_at"`
	UpdatedAt time.Time              `json:"updated_at"`
	ExpiresAt time.Time              `json:"expires_at"`
}

// TemporalSnapshot représente un instantané temporel
type TemporalSnapshot struct {
	ID        string                 `json:"id"`
	Timestamp time.Time              `json:"timestamp"`
	State     map[string]interface{} `json:"state"`
	Metadata  map[string]interface{} `json:"metadata"`
}

// QuantumBranch représente une branche quantique
type QuantumBranch struct {
	ID              string                 `json:"id"`
	SuperpositionID string                 `json:"superposition_id"`
	Probability     float64                `json:"probability"`
	State           map[string]interface{} `json:"state"`
	Entangled       []string               `json:"entangled"`
}

// =============================================================================
// ENUMERATION TYPES
// =============================================================================

// RecommendationType énumération des types de recommandations
type RecommendationType string

const (
	RecommendationTypeImprovement  RecommendationType = "improvement"
	RecommendationTypeOptimization RecommendationType = "optimization"
	RecommendationTypeWarning      RecommendationType = "warning"
)

// Priority énumération des priorités
type Priority string

const (
	PriorityLow    Priority = "low"
	PriorityMedium Priority = "medium"
	PriorityHigh   Priority = "high"
)

// Impact énumération des impacts
type Impact string

const (
	ImpactLow    Impact = "low"
	ImpactMedium Impact = "medium"
	ImpactHigh   Impact = "high"
)

// Effort énumération des efforts
type Effort string

const (
	EffortLow    Effort = "low"
	EffortMedium Effort = "medium"
	EffortHigh   Effort = "high"
)

// PatternType énumération des types de patterns
type PatternType string

const (
	PatternTypeLifecycle     PatternType = "lifecycle"
	PatternTypeMerge         PatternType = "merge"
	PatternTypeCollaboration PatternType = "collaboration"
	PatternTypeTiming        PatternType = "timing"
	PatternTypeQuality       PatternType = "quality"
)

// =============================================================================
// BRANCHING STRATEGY TYPES
// =============================================================================

// BranchingStrategy représente une stratégie de branchement
type BranchingStrategy struct {
	ProjectID         string `json:"project_id"`
	Type              string `json:"type"`
	MergeStrategy     string `json:"merge_strategy"`
	RequireReview     bool   `json:"require_review"`
	AutoDelete        bool   `json:"auto_delete"`
	ProtectBaseBranch bool   `json:"protect_base_branch"`
}

// BranchingIntent représente l'intention de création d'une branche
type BranchingIntent struct {
	Description         string                 `json:"description"`
	BranchType          string                 `json:"branch_type"`
	EstimatedDuration   time.Duration          `json:"estimated_duration"`
	PreferredBaseBranch string                 `json:"preferred_base_branch"`
	RelatedBranches     []string               `json:"related_branches"`
	ProjectContext      map[string]interface{} `json:"project_context"`
}

// BranchPrediction représente une prédiction de résultat de branche
type BranchPrediction struct {
	SuccessProbability  float64       `json:"success_probability"`
	ConflictProbability float64       `json:"conflict_probability"`
	Duration            time.Duration `json:"duration"`
	Complexity          float64       `json:"complexity"`
	TestPassProbability float64       `json:"test_pass_probability"`
}

// Recommendation représente une recommandation
type Recommendation struct {
	Type        RecommendationType `json:"type"`
	Priority    Priority           `json:"priority"`
	Category    string             `json:"category"`
	Title       string             `json:"title"`
	Description string             `json:"description"`
	Action      string             `json:"action"`
	Impact      Impact             `json:"impact"`
	Effort      Effort             `json:"effort"`
	Timeline    string             `json:"timeline"`
	Tags        []string           `json:"tags"`
}

// =============================================================================
// PATTERN ANALYSIS TYPES
// =============================================================================

// TimeRange représente une plage temporelle
type TimeRange struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

// PatternContext représente le contexte d'un pattern
type PatternContext struct {
	ProjectType      string    `json:"project_type"`
	TeamSize         int       `json:"team_size"`
	DevelopmentPhase string    `json:"development_phase"`
	TimeRange        TimeRange `json:"time_range"`
}

// PatternMetrics représente les métriques d'un pattern
type PatternMetrics struct {
	AverageDuration  time.Duration `json:"average_duration"`
	SuccessRate      float64       `json:"success_rate"`
	ComplexityScore  float64       `json:"complexity_score"`
	PerformanceScore float64       `json:"performance_score"`
	QualityScore     float64       `json:"quality_score"`
}

// PatternTrigger représente un déclencheur de pattern
type PatternTrigger struct {
	Type       string                 `json:"type"`
	Frequency  float64                `json:"frequency"`
	Conditions map[string]interface{} `json:"conditions"`
}

// PatternOutcome représente un résultat de pattern
type PatternOutcome struct {
	Type          string        `json:"type"`
	Probability   float64       `json:"probability"`
	AverageTime   time.Duration `json:"average_time"`
	QualityImpact float64       `json:"quality_impact"`
}

// BranchingPattern représente un pattern de branchement identifié
type BranchingPattern struct {
	ID          string           `json:"id"`
	Name        string           `json:"name"`
	Description string           `json:"description"`
	Type        PatternType      `json:"type"`
	Frequency   float64          `json:"frequency"`
	Context     PatternContext   `json:"context"`
	Metrics     PatternMetrics   `json:"metrics"`
	Triggers    []PatternTrigger `json:"triggers"`
	Outcomes    []PatternOutcome `json:"outcomes"`
	DetectedAt  time.Time        `json:"detected_at"`
}

// PatternSimilarity représente la similarité entre patterns
type PatternSimilarity struct {
	PatternID         string                 `json:"pattern_id"`
	ProjectID         string                 `json:"project_id"`
	Score             float32                `json:"score"`
	Pattern           *BranchingPattern      `json:"pattern"`
	ContextSimilarity float64                `json:"context_similarity"`
	MetricsSimilarity float64                `json:"metrics_similarity"`
	TimingSimilarity  float64                `json:"timing_similarity"`
	FoundAt           time.Time              `json:"found_at"`
	Frequency         int                    `json:"frequency"`
	SuccessRate       float32                `json:"success_rate"`
	DistanceMetrics   map[string]float64     `json:"distance_metrics"`
	Metadata          map[string]interface{} `json:"metadata"`
}

// AnalysisSummary représente un résumé d'analyse
type AnalysisSummary struct {
	TotalPatterns     int                `json:"total_patterns"`
	ConfidenceScore   float64            `json:"confidence_score"`
	TopInsights       []string           `json:"top_insights"`
	PredictedTrends   []string           `json:"predicted_trends"`
	Recommendations   []Recommendation   `json:"recommendations"`
	PatternCategories map[string]int     `json:"pattern_categories"`
	QualityMetrics    map[string]float64 `json:"quality_metrics"`
}

// BranchingAnalysis représente une analyse de patterns de branchement
type BranchingAnalysis struct {
	ProjectID  string             `json:"project_id"`
	AnalyzedAt time.Time          `json:"analyzed_at"`
	Patterns   []BranchingPattern `json:"patterns"`
	Summary    AnalysisSummary    `json:"summary"`
}

// =============================================================================
// STRATEGY OPTIMIZATION TYPES
// =============================================================================

// StrategyOptimization représente une optimisation de stratégie
type StrategyOptimization struct {
	Area          string  `json:"area"`
	Current       string  `json:"current"`
	Recommended   string  `json:"recommended"`
	ExpectedGain  float64 `json:"expected_gain"`
	Confidence    float64 `json:"confidence"`
	Justification string  `json:"justification"`
}

// ABTestSuggestion représente une suggestion de test A/B
type ABTestSuggestion struct {
	TestName     string        `json:"test_name"`
	ControlGroup string        `json:"control_group"`
	TestGroup    string        `json:"test_group"`
	Metrics      []string      `json:"metrics"`
	Duration     time.Duration `json:"duration"`
	TrafficSplit float64       `json:"traffic_split"`
}

// ImplementationStep représente une étape d'implémentation
type ImplementationStep struct {
	Phase         int           `json:"phase"`
	Description   string        `json:"description"`
	Duration      time.Duration `json:"duration"`
	Prerequisites []string      `json:"prerequisites"`
	Risks         []string      `json:"risks"`
}

// RiskAssessment représente une évaluation de risque
type RiskAssessment struct {
	Category    string  `json:"category"`
	Probability float64 `json:"probability"`
	Impact      string  `json:"impact"`
	Mitigation  string  `json:"mitigation"`
}

// OptimizedStrategy représente une stratégie optimisée
type OptimizedStrategy struct {
	RecommendedChanges  []StrategyOptimization `json:"recommended_changes"`
	ExpectedImprovement map[string]float64     `json:"expected_improvement"`
	Confidence          float64                `json:"confidence"`
	ABTestSuggestions   []ABTestSuggestion     `json:"ab_test_suggestions"`
	ImplementationPlan  []ImplementationStep   `json:"implementation_plan"`
	RiskAssessment      []RiskAssessment       `json:"risk_assessment"`
	Metadata            map[string]interface{} `json:"metadata"`
}

// PredictedBranch représente une prédiction de branche optimale
type PredictedBranch struct {
	SuggestedName      string                 `json:"suggested_name"`
	BaseBranch         string                 `json:"base_branch"`
	Strategy           BranchingStrategy      `json:"strategy"`
	EstimatedDuration  time.Duration          `json:"estimated_duration"`
	SuccessProbability float64                `json:"success_probability"`
	Confidence         float64                `json:"confidence"`
	Recommendations    []Recommendation       `json:"recommendations"`
	Reasoning          string                 `json:"reasoning"`
	Metadata           map[string]interface{} `json:"metadata"`
}

// =============================================================================
// PREDICTION INTERFACES
// =============================================================================

// BranchingPredictor interface pour la prédiction de branchement
type BranchingPredictor interface {
	PredictOptimalBranch(ctx context.Context, intent BranchingIntent) (*PredictedBranch, error)
	AnalyzeBranchingPatterns(ctx context.Context, projectID string) (*BranchingAnalysis, error)
	OptimizeBranchingStrategy(ctx context.Context, currentStrategy BranchingStrategy) (*OptimizedStrategy, error)
}
