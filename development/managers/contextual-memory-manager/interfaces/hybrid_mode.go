// interfaces/hybrid_mode.go
package interfaces

import (
	"context"
	"time"
)

// HybridModeManager interface pour la gestion du mode hybride RAG+AST
type HybridModeManager interface {
	BaseManager

	// Sélection de mode
	SelectOptimalMode(ctx context.Context, query ContextQuery) (*ModeDecision, error)
	GetModeRecommendation(ctx context.Context, filePath string, queryType string) (*ModeRecommendation, error)

	// Combinaison de résultats
	CombineResults(ctx context.Context, astResults []StructuralResult, ragResults []RetrievalResult) (*HybridResult, error)
	ScoreResults(ctx context.Context, results []HybridResult) ([]ScoredResult, error)

	// Fallback et récupération
	ExecuteFallback(ctx context.Context, primaryMode AnalysisMode, query ContextQuery) (*HybridResult, error)

	// Métriques et optimisation
	GetPerformanceMetrics(ctx context.Context) (*HybridMetrics, error)
	OptimizeSelection(ctx context.Context, historicalData []ModeDecision) error
}

type AnalysisMode int

const (
	ModePureAST AnalysisMode = iota
	ModePureRAG
	ModeHybridASTFirst
	ModeHybridRAGFirst
	ModeParallel
)

func (am AnalysisMode) String() string {
	switch am {
	case ModePureAST:
		return "pure_ast"
	case ModePureRAG:
		return "pure_rag"
	case ModeHybridASTFirst:
		return "hybrid_ast_first"
	case ModeHybridRAGFirst:
		return "hybrid_rag_first"
	case ModeParallel:
		return "parallel"
	default:
		return "unknown"
	}
}

type ModeDecision struct {
	SelectedMode      AnalysisMode           `json:"selected_mode"`
	Confidence        float64                `json:"confidence"`
	Reasoning         []string               `json:"reasoning"`
	ASTScore          float64                `json:"ast_score"`
	RAGScore          float64                `json:"rag_score"`
	HybridRecommended bool                   `json:"hybrid_recommended"`
	DecisionTime      time.Duration          `json:"decision_time"`
	CacheHit          bool                   `json:"cache_hit"`
	Metadata          map[string]interface{} `json:"metadata"`
}

type ModeRecommendation struct {
	RecommendedMode  AnalysisMode           `json:"recommended_mode"`
	Confidence       float64                `json:"confidence"`
	Factors          []RecommendationFactor `json:"factors"`
	EstimatedQuality float64                `json:"estimated_quality"`
	EstimatedSpeed   time.Duration          `json:"estimated_speed"`
}

type RecommendationFactor struct {
	Name   string  `json:"name"`
	Weight float64 `json:"weight"`
	Value  float64 `json:"value"`
	Impact string  `json:"impact"`
}

type HybridResult struct {
	Query          ContextQuery           `json:"query"`
	ASTResults     []StructuralResult     `json:"ast_results,omitempty"`
	RAGResults     []RetrievalResult      `json:"rag_results,omitempty"`
	CombinedScore  float64                `json:"combined_score"`
	FinalResults   []interface{}          `json:"final_results"`
	UsedMode       AnalysisMode           `json:"used_mode"`
	ProcessingTime time.Duration          `json:"processing_time"`
	QualityMetrics QualityMetrics         `json:"quality_metrics"`
	Metadata       map[string]interface{} `json:"metadata"`
}

type ScoredResult struct {
	Result       interface{} `json:"result"`
	Score        float64     `json:"score"`
	Source       string      `json:"source"` // ast, rag, combined
	Confidence   float64     `json:"confidence"`
	Relevance    float64     `json:"relevance"`
	Freshness    float64     `json:"freshness"`
	Completeness float64     `json:"completeness"`
}

type QualityMetrics struct {
	Precision          float64 `json:"precision"`
	Recall             float64 `json:"recall"`
	F1Score            float64 `json:"f1_score"`
	Relevance          float64 `json:"relevance"`
	Completeness       float64 `json:"completeness"`
	Freshness          float64 `json:"freshness"`
	StructuralAccuracy float64 `json:"structural_accuracy"`
}

type HybridMetrics struct {
	TotalQueries        int64                  `json:"total_queries"`
	ModeDistribution    map[AnalysisMode]int64 `json:"mode_distribution"`
	AverageDecisionTime time.Duration          `json:"average_decision_time"`
	AverageQuality      float64                `json:"average_quality"`
	CacheHitRate        float64                `json:"cache_hit_rate"`
	FallbackRate        float64                `json:"fallback_rate"`
	OptimizationGains   map[string]float64     `json:"optimization_gains"`
	LastOptimization    time.Time              `json:"last_optimization"`
}

type HybridConfig struct {
	ASTThreshold       float64       `yaml:"ast_threshold"`        // 0.8
	RAGFallbackEnabled bool          `yaml:"rag_fallback_enabled"` // true
	QualityScoreMin    float64       `yaml:"quality_score_min"`    // 0.7
	MaxFileAge         time.Duration `yaml:"max_file_age"`         // 1h
	PreferAST          []string      `yaml:"prefer_ast"`           // [".go", ".js", ".ts"]
	PreferRAG          []string      `yaml:"prefer_rag"`           // [".md", ".txt"]
	CacheDecisions     bool          `yaml:"cache_decisions"`      // true
	DecisionCacheTTL   time.Duration `yaml:"decision_cache_ttl"`   // 5m
	ParallelAnalysis   bool          `yaml:"parallel_analysis"`    // true
	MaxAnalysisTime    time.Duration `yaml:"max_analysis_time"`    // 1s
	WeightFactors      WeightFactors `yaml:"weight_factors"`
}

type WeightFactors struct {
	FileExtension      float64 `yaml:"file_extension"`      // 0.3
	QueryComplexity    float64 `yaml:"query_complexity"`    // 0.2
	CodeStructure      float64 `yaml:"code_structure"`      // 0.25
	DocumentationRatio float64 `yaml:"documentation_ratio"` // 0.15
	RecentModification float64 `yaml:"recent_modification"` // 0.1
}

type ContextQuery struct {
	Query          string        `json:"query"`
	FilePath       string        `json:"file_path,omitempty"`
	LineNumber     int           `json:"line_number,omitempty"`
	QueryType      string        `json:"query_type"` // function_search, type_definition, usage_analysis, etc.
	Scope          string        `json:"scope"`      // file, package, workspace
	Filters        QueryFilters  `json:"filters,omitempty"`
	MaxResults     int           `json:"max_results,omitempty"`
	IncludeContext bool          `json:"include_context"`
	PreferredMode  *AnalysisMode `json:"preferred_mode,omitempty"`
}

type QueryFilters struct {
	FileExtensions []string      `json:"file_extensions,omitempty"`
	Packages       []string      `json:"packages,omitempty"`
	ExcludePaths   []string      `json:"exclude_paths,omitempty"`
	MinRelevance   float64       `json:"min_relevance,omitempty"`
	MaxAge         time.Duration `json:"max_age,omitempty"`
}
