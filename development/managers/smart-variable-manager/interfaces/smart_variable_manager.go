package interfaces

import (
	"context"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
)

// SmartVariableSuggestionManager defines the interface for intelligent variable suggestion system
type SmartVariableSuggestionManager interface {
	interfaces.BaseManager // Embed FMOUA BaseManager
	AnalyzeContext(ctx context.Context, projectPath string) (*ContextAnalysis, error)
	SuggestVariables(ctx context.Context, context *ContextAnalysis, template string) (*VariableSuggestions, error)
	LearnFromUsage(ctx context.Context, variables map[string]interface{}, outcome *UsageOutcome) error
	GetVariablePatterns(ctx context.Context, filters *PatternFilters) (*VariablePatterns, error)
	ValidateVariableUsage(ctx context.Context, variables map[string]interface{}) (*ValidationReport, error)
}

// ContextAnalysis contains comprehensive project context analysis
type ContextAnalysis struct {
	ProjectInfo     ProjectInfo      `json:"project_info"`
	CodePatterns    CodePatterns     `json:"code_patterns"`
	Dependencies    []DependencyInfo `json:"dependencies"`
	ConventionInfo  ConventionInfo   `json:"convention_info"`
	HistoricalData  HistoricalData   `json:"historical_data"`
	EnvironmentInfo EnvironmentInfo  `json:"environment_info"`
	Confidence      float64          `json:"confidence"`
	AnalyzedAt      time.Time        `json:"analyzed_at"`
}

// ProjectInfo contains basic project information
type ProjectInfo struct {
	Name         string            `json:"name"`
	Language     string            `json:"language"`
	Framework    string            `json:"framework"`
	Version      string            `json:"version"`
	Architecture string            `json:"architecture"`
	Metadata     map[string]string `json:"metadata"`
}

// CodePatterns contains detected code patterns
type CodePatterns struct {
	NamingConventions  []NamingPattern    `json:"naming_conventions"`
	TypeUsage          map[string]int     `json:"type_usage"`
	CommonStructures   []StructurePattern `json:"common_structures"`
	FunctionSignatures []FunctionPattern  `json:"function_signatures"`
	VariableScopes     []ScopePattern     `json:"variable_scopes"`
}

// NamingPattern represents a naming convention pattern
type NamingPattern struct {
	Type       string   `json:"type"`       // variable, function, constant, etc.
	Pattern    string   `json:"pattern"`    // camelCase, snake_case, etc.
	Frequency  int      `json:"frequency"`  // how often this pattern appears
	Confidence float64  `json:"confidence"` // confidence in this pattern
	Examples   []string `json:"examples"`   // example names following this pattern
}

// StructurePattern represents common code structures
type StructurePattern struct {
	Type     string            `json:"type"`     // struct, interface, function, etc.
	Name     string            `json:"name"`     // pattern name
	Fields   []FieldPattern    `json:"fields"`   // common fields in this structure
	Usage    int               `json:"usage"`    // frequency of usage
	Context  string            `json:"context"`  // where this pattern is typically used
	Metadata map[string]string `json:"metadata"` // additional pattern information
}

// FieldPattern represents a field pattern in structures
type FieldPattern struct {
	Name         string   `json:"name"`
	Type         string   `json:"type"`
	Required     bool     `json:"required"`
	DefaultValue string   `json:"default_value,omitempty"`
	Frequency    int      `json:"frequency"`
	Tags         []string `json:"tags,omitempty"`
}

// FunctionPattern represents function signature patterns
type FunctionPattern struct {
	Name        string             `json:"name"`
	Parameters  []ParameterPattern `json:"parameters"`
	ReturnTypes []string           `json:"return_types"`
	Usage       int                `json:"usage"`
	Category    string             `json:"category"` // handler, utility, business, etc.
	Complexity  int                `json:"complexity"`
}

// ParameterPattern represents parameter patterns in functions
type ParameterPattern struct {
	Name         string `json:"name"`
	Type         string `json:"type"`
	Position     int    `json:"position"`
	Optional     bool   `json:"optional"`
	DefaultValue string `json:"default_value,omitempty"`
	Frequency    int    `json:"frequency"`
}

// ScopePattern represents variable scope usage patterns
type ScopePattern struct {
	Scope     string            `json:"scope"` // global, package, function, block
	Variables []VariableInfo    `json:"variables"`
	Usage     int               `json:"usage"`
	Context   string            `json:"context"`
	Metadata  map[string]string `json:"metadata"`
}

// VariableInfo contains information about a variable
type VariableInfo struct {
	Name         string      `json:"name"`
	Type         string      `json:"type"`
	InitialValue interface{} `json:"initial_value,omitempty"`
	Mutability   string      `json:"mutability"` // const, var, mutable
	Lifetime     string      `json:"lifetime"`   // temporary, persistent, session
	Purpose      string      `json:"purpose"`    // config, data, control, etc.
}

// DependencyInfo contains information about project dependencies
type DependencyInfo struct {
	Name      string            `json:"name"`
	Version   string            `json:"version"`
	Type      string            `json:"type"`      // direct, indirect, dev
	Usage     []string          `json:"usage"`     // where it's used
	Variables []string          `json:"variables"` // variables typically used with this dependency
	Metadata  map[string]string `json:"metadata"`
}

// ConventionInfo contains information about coding conventions
type ConventionInfo struct {
	Language    string                 `json:"language"`
	Style       string                 `json:"style"` // google, airbnb, standard, etc.
	Rules       map[string]interface{} `json:"rules"`
	Enforced    bool                   `json:"enforced"`   // whether conventions are enforced
	ToolsUsed   []string               `json:"tools_used"` // linters, formatters used
	CustomRules []ConventionRule       `json:"custom_rules"`
}

// ConventionRule represents a custom coding convention rule
type ConventionRule struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Rule        string   `json:"rule"`
	Severity    string   `json:"severity"` // error, warning, info
	Examples    []string `json:"examples"`
	Enabled     bool     `json:"enabled"`
}

// HistoricalData contains historical usage patterns
type HistoricalData struct {
	VariableUsage    map[string]VariableUsageHistory `json:"variable_usage"`
	PatternEvolution []PatternEvolution              `json:"pattern_evolution"`
	SuccessRates     map[string]float64              `json:"success_rates"`
	UserPreferences  UserPreferences                 `json:"user_preferences"`
	ProjectHistory   []ProjectSnapshot               `json:"project_history"`
}

// VariableUsageHistory tracks how variables have been used over time
type VariableUsageHistory struct {
	Name        string         `json:"name"`
	Type        string         `json:"type"`
	UsageCount  int            `json:"usage_count"`
	SuccessRate float64        `json:"success_rate"`
	Contexts    []UsageContext `json:"contexts"`
	Trends      []UsageTrend   `json:"trends"`
	LastUsed    time.Time      `json:"last_used"`
}

// UsageContext represents where and how a variable was used
type UsageContext struct {
	Project   string            `json:"project"`
	File      string            `json:"file"`
	Function  string            `json:"function"`
	Line      int               `json:"line"`
	Value     interface{}       `json:"value"`
	Success   bool              `json:"success"`
	Timestamp time.Time         `json:"timestamp"`
	Metadata  map[string]string `json:"metadata"`
}

// UsageTrend represents usage trends over time
type UsageTrend struct {
	Period      string    `json:"period"` // daily, weekly, monthly
	Count       int       `json:"count"`
	SuccessRate float64   `json:"success_rate"`
	Timestamp   time.Time `json:"timestamp"`
}

// PatternEvolution tracks how patterns have evolved
type PatternEvolution struct {
	Pattern    string            `json:"pattern"`
	Changes    []PatternChange   `json:"changes"`
	Versions   []PatternVersion  `json:"versions"`
	Trend      string            `json:"trend"` // increasing, decreasing, stable
	Prediction PatternPrediction `json:"prediction"`
}

// PatternChange represents a change in a pattern
type PatternChange struct {
	Type        string    `json:"type"` // added, removed, modified
	Description string    `json:"description"`
	Impact      string    `json:"impact"` // low, medium, high
	Timestamp   time.Time `json:"timestamp"`
	Reason      string    `json:"reason"`
}

// PatternVersion represents a version of a pattern
type PatternVersion struct {
	Version    string    `json:"version"`
	Pattern    string    `json:"pattern"`
	Usage      int       `json:"usage"`
	CreatedAt  time.Time `json:"created_at"`
	Deprecated bool      `json:"deprecated"`
}

// PatternPrediction contains AI-based pattern predictions
type PatternPrediction struct {
	FutureUsage     int      `json:"future_usage"`
	Confidence      float64  `json:"confidence"`
	Timeframe       string   `json:"timeframe"` // short, medium, long term
	Factors         []string `json:"factors"`   // factors influencing the prediction
	Recommendations []string `json:"recommendations"`
}

// UserPreferences contains user-specific preferences
type UserPreferences struct {
	PreferredNaming     string                 `json:"preferred_naming"`
	PreferredTypes      []string               `json:"preferred_types"`
	AvoidedPatterns     []string               `json:"avoided_patterns"`
	CustomConventions   []string               `json:"custom_conventions"`
	LearningEnabled     bool                   `json:"learning_enabled"`
	SuggestionLevel     string                 `json:"suggestion_level"` // minimal, moderate, aggressive
	PersonalizationData map[string]interface{} `json:"personalization_data"`
}

// ProjectSnapshot represents a snapshot of project state
type ProjectSnapshot struct {
	Timestamp      time.Time       `json:"timestamp"`
	Version        string          `json:"version"`
	FileCount      int             `json:"file_count"`
	LineCount      int             `json:"line_count"`
	VariableCount  int             `json:"variable_count"`
	PatternChanges []PatternChange `json:"pattern_changes"`
	Metrics        ProjectMetrics  `json:"metrics"`
}

// ProjectMetrics contains project-level metrics
type ProjectMetrics struct {
	Complexity      float64            `json:"complexity"`
	Maintainability float64            `json:"maintainability"`
	TestCoverage    float64            `json:"test_coverage"`
	TechnicalDebt   float64            `json:"technical_debt"`
	CodeQuality     float64            `json:"code_quality"`
	CustomMetrics   map[string]float64 `json:"custom_metrics"`
}

// EnvironmentInfo contains information about the development environment
type EnvironmentInfo struct {
	IDE             string            `json:"ide"`
	Extensions      []string          `json:"extensions"`
	OperatingSystem string            `json:"operating_system"`
	GoVersion       string            `json:"go_version"`
	ToolsAvailable  []string          `json:"tools_available"`
	Configuration   map[string]string `json:"configuration"`
}

// VariableSuggestions contains intelligent variable suggestions
type VariableSuggestions struct {
	Suggestions   []VariableSuggestion    `json:"suggestions"`
	Context       SuggestionContext       `json:"context"`
	Confidence    float64                 `json:"confidence"`
	Reasoning     string                  `json:"reasoning"`
	Alternatives  []AlternativeSuggestion `json:"alternatives"`
	BestPractices []BestPractice          `json:"best_practices"`
	Warnings      []SuggestionWarning     `json:"warnings"`
	GeneratedAt   time.Time               `json:"generated_at"`
}

// VariableSuggestion represents a single variable suggestion
type VariableSuggestion struct {
	Name            string                 `json:"name"`
	Type            string                 `json:"type"`
	DefaultValue    interface{}            `json:"default_value,omitempty"`
	Description     string                 `json:"description"`
	Confidence      float64                `json:"confidence"`
	Rationale       string                 `json:"rationale"`
	Category        string                 `json:"category"`     // config, data, control, computed
	Scope           string                 `json:"scope"`        // local, package, global
	Mutability      string                 `json:"mutability"`   // const, var, mutable
	RequiredBy      []string               `json:"required_by"`  // functions/features that need this variable
	RelatedVars     []string               `json:"related_vars"` // related variables
	Examples        []UsageExample         `json:"examples"`
	ValidationRules []ValidationRule       `json:"validation_rules"`
	Tags            []string               `json:"tags"`
	Metadata        map[string]interface{} `json:"metadata"`
}

// SuggestionContext provides context for variable suggestions
type SuggestionContext struct {
	TemplateType    string          `json:"template_type"`
	ProjectContext  string          `json:"project_context"`
	UserPreferences UserPreferences `json:"user_preferences"`
	CurrentVars     []string        `json:"current_vars"`
	Dependencies    []string        `json:"dependencies"`
	Framework       string          `json:"framework"`
	Environment     string          `json:"environment"`
	Constraints     []Constraint    `json:"constraints"`
	Goals           []string        `json:"goals"`
}

// AlternativeSuggestion represents alternative suggestions
type AlternativeSuggestion struct {
	Name        string                 `json:"name"`
	Type        string                 `json:"type"`
	Value       interface{}            `json:"value"`
	Description string                 `json:"description"`
	Confidence  float64                `json:"confidence"`
	TradeOffs   []TradeOff             `json:"trade_offs"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// BestPractice represents a coding best practice suggestion
type BestPractice struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Category    string   `json:"category"` // naming, typing, structure, security
	Impact      string   `json:"impact"`   // low, medium, high
	Effort      string   `json:"effort"`   // minimal, moderate, significant
	Examples    []string `json:"examples"`
	References  []string `json:"references"`
	Priority    int      `json:"priority"`
}

// SuggestionWarning represents warnings about suggestions
type SuggestionWarning struct {
	Type       string   `json:"type"` // naming, type, scope, performance
	Message    string   `json:"message"`
	Severity   string   `json:"severity"` // info, warning, error
	Suggestion string   `json:"suggestion"`
	AutoFix    bool     `json:"auto_fix"`
	References []string `json:"references"`
}

// UsageExample provides examples of how to use a variable
type UsageExample struct {
	Context     string      `json:"context"`
	Code        string      `json:"code"`
	Value       interface{} `json:"value"`
	Description string      `json:"description"`
	Language    string      `json:"language"`
	Framework   string      `json:"framework,omitempty"`
}

// ValidationRule defines validation rules for variables
type ValidationRule struct {
	Type     string      `json:"type"`     // required, type, range, pattern, custom
	Value    interface{} `json:"value"`    // validation value/pattern
	Message  string      `json:"message"`  // error message if validation fails
	Severity string      `json:"severity"` // error, warning, info
	AutoFix  bool        `json:"auto_fix"` // whether this can be auto-fixed
}

// Constraint represents a constraint on variable suggestions
type Constraint struct {
	Type       string      `json:"type"` // naming, type, scope, value
	Rule       string      `json:"rule"`
	Value      interface{} `json:"value"`
	Reason     string      `json:"reason"`
	Negotiable bool        `json:"negotiable"` // whether this constraint can be relaxed
}

// TradeOff represents trade-offs between different suggestions
type TradeOff struct {
	Aspect      string  `json:"aspect"`    // performance, readability, maintainability
	Impact      string  `json:"impact"`    // positive, negative, neutral
	Magnitude   float64 `json:"magnitude"` // 0.0 to 1.0
	Description string  `json:"description"`
}

// UsageOutcome represents the outcome of using suggested variables
type UsageOutcome struct {
	Variables       map[string]interface{} `json:"variables"`
	Success         bool                   `json:"success"`
	ErrorMessages   []string               `json:"error_messages"`
	PerformanceData PerformanceData        `json:"performance_data"`
	UserFeedback    UserFeedback           `json:"user_feedback"`
	Context         string                 `json:"context"`
	Timestamp       time.Time              `json:"timestamp"`
	Metadata        map[string]interface{} `json:"metadata"`
}

// PerformanceData contains performance metrics for variable usage
type PerformanceData struct {
	ExecutionTime   time.Duration `json:"execution_time"`
	MemoryUsage     int64         `json:"memory_usage"`
	CPUUsage        float64       `json:"cpu_usage"`
	NetworkCalls    int           `json:"network_calls"`
	DatabaseQueries int           `json:"database_queries"`
	CacheHits       int           `json:"cache_hits"`
	CacheMisses     int           `json:"cache_misses"`
}

// UserFeedback contains user feedback on suggestions
type UserFeedback struct {
	Rating        int      `json:"rating"` // 1-5 star rating
	Comments      string   `json:"comments"`
	Helpful       bool     `json:"helpful"`
	Accurate      bool     `json:"accurate"`
	Suggestions   []string `json:"suggestions"` // user's suggestions for improvement
	WouldUseAgain bool     `json:"would_use_again"`
}

// PatternFilters defines filters for pattern queries
type PatternFilters struct {
	ProjectType   []string  `json:"project_type"`
	Language      []string  `json:"language"`
	Framework     []string  `json:"framework"`
	DateRange     DateRange `json:"date_range"`
	MinUsage      int       `json:"min_usage"`
	MinConfidence float64   `json:"min_confidence"`
	Categories    []string  `json:"categories"`
	Tags          []string  `json:"tags"`
	UserID        string    `json:"user_id,omitempty"`
}

// DateRange represents a date range filter
type DateRange struct {
	From time.Time `json:"from"`
	To   time.Time `json:"to"`
}

// VariablePatterns contains patterns of variable usage
type VariablePatterns struct {
	Patterns        []VariablePattern       `json:"patterns"`
	Statistics      PatternStatistics       `json:"statistics"`
	Trends          []PatternTrend          `json:"trends"`
	Recommendations []PatternRecommendation `json:"recommendations"`
	GeneratedAt     time.Time               `json:"generated_at"`
	Metadata        map[string]interface{}  `json:"metadata"`
}

// VariablePattern represents a pattern of variable usage
type VariablePattern struct {
	Name       string                 `json:"name"`
	Type       string                 `json:"type"`
	Pattern    string                 `json:"pattern"` // naming pattern, usage pattern
	Frequency  int                    `json:"frequency"`
	Confidence float64                `json:"confidence"`
	Context    []string               `json:"context"` // where this pattern is used
	Examples   []string               `json:"examples"`
	Variations []PatternVariation     `json:"variations"`
	Evolution  PatternEvolution       `json:"evolution"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// PatternVariation represents variations of a pattern
type PatternVariation struct {
	Name       string   `json:"name"`
	Difference string   `json:"difference"` // what's different about this variation
	Frequency  int      `json:"frequency"`
	Confidence float64  `json:"confidence"`
	Context    string   `json:"context"`
	Examples   []string `json:"examples"`
}

// PatternStatistics contains statistical information about patterns
type PatternStatistics struct {
	TotalPatterns       int                   `json:"total_patterns"`
	MostUsedPattern     string                `json:"most_used_pattern"`
	AverageConfidence   float64               `json:"average_confidence"`
	PatternDistribution map[string]int        `json:"pattern_distribution"`
	TrendSummary        string                `json:"trend_summary"`
	QualityMetrics      PatternQualityMetrics `json:"quality_metrics"`
}

// PatternTrend represents trends in pattern usage
type PatternTrend struct {
	Pattern    string    `json:"pattern"`
	Direction  string    `json:"direction"` // increasing, decreasing, stable
	Magnitude  float64   `json:"magnitude"` // how much it's changing
	Timeframe  string    `json:"timeframe"` // daily, weekly, monthly
	Confidence float64   `json:"confidence"`
	StartDate  time.Time `json:"start_date"`
	EndDate    time.Time `json:"end_date"`
	Factors    []string  `json:"factors"` // factors influencing the trend
}

// PatternRecommendation represents recommendations for pattern usage
type PatternRecommendation struct {
	Type       string   `json:"type"` // adopt, avoid, modify, optimize
	Pattern    string   `json:"pattern"`
	Reason     string   `json:"reason"`
	Benefits   []string `json:"benefits"`
	Risks      []string `json:"risks"`
	Action     string   `json:"action"`
	Priority   int      `json:"priority"`
	Confidence float64  `json:"confidence"`
}

// PatternQualityMetrics contains quality metrics for patterns
type PatternQualityMetrics struct {
	Accuracy       float64 `json:"accuracy"`
	Completeness   float64 `json:"completeness"`
	Consistency    float64 `json:"consistency"`
	Relevance      float64 `json:"relevance"`
	Freshness      float64 `json:"freshness"`
	OverallQuality float64 `json:"overall_quality"`
}

// ValidationReport contains validation results for variable usage
type ValidationReport struct {
	Valid         bool                    `json:"valid"`
	Score         float64                 `json:"score"` // overall validation score
	Issues        []ValidationIssue       `json:"issues"`
	Suggestions   []ImprovementSuggestion `json:"suggestions"`
	Compliance    ComplianceReport        `json:"compliance"`
	Performance   PerformanceAnalysis     `json:"performance"`
	Security      SecurityAnalysis        `json:"security"`
	BestPractices BestPracticeReport      `json:"best_practices"`
	GeneratedAt   time.Time               `json:"generated_at"`
	Metadata      map[string]interface{}  `json:"metadata"`
}

// ValidationIssue represents a validation issue
type ValidationIssue struct {
	Variable    string   `json:"variable"`
	Type        string   `json:"type"`     // naming, type, value, scope, security
	Severity    string   `json:"severity"` // error, warning, info
	Message     string   `json:"message"`
	Line        int      `json:"line,omitempty"`
	Column      int      `json:"column,omitempty"`
	AutoFixable bool     `json:"auto_fixable"`
	Suggestion  string   `json:"suggestion"`
	References  []string `json:"references"`
}

// ImprovementSuggestion represents suggestions for improvement
type ImprovementSuggestion struct {
	Type       string   `json:"type"` // refactor, rename, retype, restructure
	Variable   string   `json:"variable"`
	Current    string   `json:"current"`
	Suggested  string   `json:"suggested"`
	Reason     string   `json:"reason"`
	Benefits   []string `json:"benefits"`
	Impact     string   `json:"impact"` // low, medium, high
	Effort     string   `json:"effort"` // minimal, moderate, significant
	Confidence float64  `json:"confidence"`
}

// ComplianceReport contains compliance analysis
type ComplianceReport struct {
	Standard        string                     `json:"standard"` // go-fmt, golint, custom
	Compliant       bool                       `json:"compliant"`
	Score           float64                    `json:"score"`
	Violations      []ComplianceViolation      `json:"violations"`
	Recommendations []ComplianceRecommendation `json:"recommendations"`
}

// ComplianceViolation represents a compliance violation
type ComplianceViolation struct {
	Rule        string `json:"rule"`
	Variable    string `json:"variable"`
	Severity    string `json:"severity"`
	Message     string `json:"message"`
	AutoFixable bool   `json:"auto_fixable"`
	Fix         string `json:"fix,omitempty"`
}

// ComplianceRecommendation represents compliance recommendations
type ComplianceRecommendation struct {
	Rule     string   `json:"rule"`
	Action   string   `json:"action"`
	Priority int      `json:"priority"`
	Benefits []string `json:"benefits"`
	Effort   string   `json:"effort"`
}

// PerformanceAnalysis contains performance analysis of variable usage
type PerformanceAnalysis struct {
	OverallScore  float64                   `json:"overall_score"`
	MemoryUsage   MemoryAnalysis            `json:"memory_usage"`
	CPUUsage      CPUAnalysis               `json:"cpu_usage"`
	IOOperations  IOAnalysis                `json:"io_operations"`
	Bottlenecks   []PerformanceBottleneck   `json:"bottlenecks"`
	Optimizations []PerformanceOptimization `json:"optimizations"`
	Issues        []PerformanceIssue        `json:"issues"`
}

// PerformanceIssue represents a performance issue with variable usage
type PerformanceIssue struct {
	Variable    string  `json:"variable"`
	Type        string  `json:"type"`     // memory, cpu, io
	Severity    string  `json:"severity"` // low, medium, high, critical
	Description string  `json:"description"`
	Impact      string  `json:"impact"`
	Suggestion  string  `json:"suggestion"`
	Confidence  float64 `json:"confidence"`
}

// MemoryAnalysis contains memory usage analysis
type MemoryAnalysis struct {
	TotalUsage    int64                `json:"total_usage"`
	PerVariable   map[string]int64     `json:"per_variable"`
	Leaks         []MemoryLeak         `json:"leaks"`
	Optimizations []MemoryOptimization `json:"optimizations"`
}

// CPUAnalysis contains CPU usage analysis
type CPUAnalysis struct {
	TotalUsage    float64            `json:"total_usage"`
	PerVariable   map[string]float64 `json:"per_variable"`
	HotSpots      []CPUHotSpot       `json:"hot_spots"`
	Optimizations []CPUOptimization  `json:"optimizations"`
}

// IOAnalysis contains I/O operations analysis
type IOAnalysis struct {
	TotalOperations int              `json:"total_operations"`
	PerVariable     map[string]int   `json:"per_variable"`
	Bottlenecks     []IOBottleneck   `json:"bottlenecks"`
	Optimizations   []IOOptimization `json:"optimizations"`
}

// PerformanceBottleneck represents a performance bottleneck
type PerformanceBottleneck struct {
	Type        string   `json:"type"` // memory, cpu, io, network
	Variable    string   `json:"variable"`
	Impact      string   `json:"impact"` // low, medium, high, critical
	Description string   `json:"description"`
	Magnitude   float64  `json:"magnitude"`
	Solutions   []string `json:"solutions"`
}

// PerformanceOptimization represents a performance optimization opportunity
type PerformanceOptimization struct {
	Type                 string  `json:"type"`
	Variable             string  `json:"variable"`
	Description          string  `json:"description"`
	ExpectedGain         float64 `json:"expected_gain"`
	ImplementationEffort string  `json:"implementation_effort"`
	Priority             int     `json:"priority"`
	Code                 string  `json:"code,omitempty"`
}

// Memory-related types
type MemoryLeak struct {
	Variable    string `json:"variable"`
	Type        string `json:"type"` // goroutine, channel, reference
	Severity    string `json:"severity"`
	Description string `json:"description"`
	Fix         string `json:"fix"`
}

type MemoryOptimization struct {
	Variable       string `json:"variable"`
	Type           string `json:"type"` // pooling, reuse, compression
	Description    string `json:"description"`
	ExpectedSaving int64  `json:"expected_saving"`
	Implementation string `json:"implementation"`
}

// CPU-related types
type CPUHotSpot struct {
	Variable    string   `json:"variable"`
	Usage       float64  `json:"usage"`
	Frequency   int      `json:"frequency"`
	Description string   `json:"description"`
	Solutions   []string `json:"solutions"`
}

type CPUOptimization struct {
	Variable       string  `json:"variable"`
	Type           string  `json:"type"` // caching, algorithm, parallelization
	Description    string  `json:"description"`
	ExpectedGain   float64 `json:"expected_gain"`
	Implementation string  `json:"implementation"`
}

// I/O-related types
type IOBottleneck struct {
	Variable    string   `json:"variable"`
	Type        string   `json:"type"` // file, network, database
	Operations  int      `json:"operations"`
	Description string   `json:"description"`
	Solutions   []string `json:"solutions"`
}

type IOOptimization struct {
	Variable       string `json:"variable"`
	Type           string `json:"type"` // batching, caching, connection_pooling
	Description    string `json:"description"`
	ExpectedGain   int    `json:"expected_gain"`
	Implementation string `json:"implementation"`
}

// SecurityAnalysis contains security analysis of variable usage
type SecurityAnalysis struct {
	OverallRisk      string                    `json:"overall_risk"` // low, medium, high, critical
	Vulnerabilities  []SecurityVulnerability   `json:"vulnerabilities"`
	Recommendations  []SecurityRecommendation  `json:"recommendations"`
	ComplianceChecks []SecurityComplianceCheck `json:"compliance_checks"`
}

// SecurityVulnerability represents a security vulnerability
type SecurityVulnerability struct {
	Variable    string   `json:"variable"`
	Type        string   `json:"type"`     // injection, exposure, weak_crypto, etc.
	Severity    string   `json:"severity"` // low, medium, high, critical
	Description string   `json:"description"`
	Impact      string   `json:"impact"`
	Mitigation  string   `json:"mitigation"`
	References  []string `json:"references"`
	CVSS        float64  `json:"cvss,omitempty"`
}

// SecurityRecommendation represents security recommendations
type SecurityRecommendation struct {
	Variable    string   `json:"variable"`
	Type        string   `json:"type"` // sanitization, validation, encryption
	Priority    int      `json:"priority"`
	Description string   `json:"description"`
	Action      string   `json:"action"`
	Benefits    []string `json:"benefits"`
	References  []string `json:"references"`
}

// SecurityComplianceCheck represents security compliance checks
type SecurityComplianceCheck struct {
	Standard    string `json:"standard"` // OWASP, SOC2, GDPR, etc.
	Rule        string `json:"rule"`
	Variable    string `json:"variable"`
	Compliant   bool   `json:"compliant"`
	Description string `json:"description"`
	Required    bool   `json:"required"`
	Fix         string `json:"fix,omitempty"`
}

// BestPracticeReport contains best practice analysis
type BestPracticeReport struct {
	OverallScore    float64                      `json:"overall_score"`
	Categories      map[string]float64           `json:"categories"` // naming: 0.8, typing: 0.9, etc.
	Violations      []BestPracticeViolation      `json:"violations"`
	Recommendations []BestPracticeRecommendation `json:"recommendations"`
	Achievements    []BestPracticeAchievement    `json:"achievements"`
}

// BestPracticeViolation represents a best practice violation
type BestPracticeViolation struct {
	Variable    string   `json:"variable"`
	Category    string   `json:"category"` // naming, typing, structure, documentation
	Practice    string   `json:"practice"` // specific practice violated
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	Example     string   `json:"example"`
	Fix         string   `json:"fix"`
	References  []string `json:"references"`
}

// BestPracticeRecommendation represents best practice recommendations
type BestPracticeRecommendation struct {
	Category    string   `json:"category"`
	Practice    string   `json:"practice"`
	Priority    int      `json:"priority"`
	Description string   `json:"description"`
	Benefits    []string `json:"benefits"`
	Examples    []string `json:"examples"`
	References  []string `json:"references"`
}

// BestPracticeAchievement represents achieved best practices
type BestPracticeAchievement struct {
	Category    string   `json:"category"`
	Practice    string   `json:"practice"`
	Score       float64  `json:"score"`
	Description string   `json:"description"`
	Variables   []string `json:"variables"` // variables that demonstrate this practice
}
