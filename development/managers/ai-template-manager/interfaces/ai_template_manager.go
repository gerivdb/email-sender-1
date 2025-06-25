package interfaces

import (
	"time"
	
	"github.com/chrlesur/Email_Sender/development/managers/interfaces"
)

// AITemplateManager defines the interface for AI-powered template management
type AITemplateManager interface {
	interfaces.BaseManager // Embed FMOUA BaseManager
	ProcessTemplate(templatePath string, vars map[string]interface{}) (*Template, error)
	AnalyzePatterns(projectPath string) (*PatternAnalysis, error)
	GenerateSuggestions(context *ProjectContext) (*Suggestions, error)
	OptimizeTemplate(template *Template, performance *PerformanceMetrics) (*Template, error)
	ValidateVariables(template *Template, vars map[string]interface{}) (*ValidationResult, error)
}

// Template represents an AI-processed template
type Template struct {
	ID        string                 `json:"id"`
	Name      string                 `json:"name"`
	Content   string                 `json:"content"`
	Variables map[string]VariableInfo `json:"variables"`
	Metadata  TemplateMetadata       `json:"metadata"`
}

// VariableInfo contains information about template variables
type VariableInfo struct {
	Type        string      `json:"type"`
	Default     interface{} `json:"default"`
	Required    bool        `json:"required"`
	Description string      `json:"description"`
	Pattern     string      `json:"pattern,omitempty"`
	Enum        []string    `json:"enum,omitempty"`
}

// TemplateMetadata contains template metadata
type TemplateMetadata struct {
	CreatedAt       time.Time          `json:"created_at"`
	UpdatedAt       time.Time          `json:"updated_at"`
	Version         string             `json:"version"`
	Author          string             `json:"author"`
	Category        string             `json:"category"`
	Tags            []string           `json:"tags"`
	UsageCount      int                `json:"usage_count"`
	PerformanceInfo PerformanceMetrics `json:"performance_info"`
}

// PerformanceMetrics contains template performance data
type PerformanceMetrics struct {
	AverageProcessingTime time.Duration `json:"average_processing_time"`
	SuccessRate          float64       `json:"success_rate"`
	ErrorRate            float64       `json:"error_rate"`
	OptimizationScore    float64       `json:"optimization_score"`
}// PatternAnalysis contains AI analysis of code patterns
type PatternAnalysis struct {
	Functions        []FunctionInfo     `json:"functions"`
	Structs          []StructInfo       `json:"structs"`
	Variables        []VariablePattern  `json:"variables"`
	Patterns         []CodePattern      `json:"patterns"`
	Complexity       ComplexityMetrics  `json:"complexity"`
	Recommendations  []Recommendation   `json:"recommendations"`
}

// FunctionInfo represents information about a function
type FunctionInfo struct {
	Name        string            `json:"name"`
	Parameters  []ParameterInfo   `json:"parameters"`
	ReturnType  string            `json:"return_type"`
	Complexity  int               `json:"complexity"`
	UsageCount  int               `json:"usage_count"`
	Metadata    map[string]string `json:"metadata"`
}

// StructInfo represents information about a struct
type StructInfo struct {
	Name     string       `json:"name"`
	Fields   []FieldInfo  `json:"fields"`
	Methods  []string     `json:"methods"`
	Tags     []string     `json:"tags"`
	Metadata map[string]string `json:"metadata"`
}

// VariablePattern represents a variable usage pattern
type VariablePattern struct {
	Name         string   `json:"name"`
	Type         string   `json:"type"`
	Scope        string   `json:"scope"`
	UsagePattern string   `json:"usage_pattern"`
	Frequency    int      `json:"frequency"`
}// CodePattern represents a detected code pattern
type CodePattern struct {
	Type         string            `json:"type"`
	Description  string            `json:"description"`
	Confidence   float64           `json:"confidence"`
	Instances    []PatternInstance `json:"instances"`
	Suggestions  []string          `json:"suggestions"`
}

// ComplexityMetrics contains code complexity analysis
type ComplexityMetrics struct {
	CyclomaticComplexity int     `json:"cyclomatic_complexity"`
	CognitiveComplexity  int     `json:"cognitive_complexity"`
	LinesOfCode          int     `json:"lines_of_code"`
	TechnicalDebt        float64 `json:"technical_debt"`
	Maintainability      float64 `json:"maintainability"`
}

// Recommendation represents an AI-generated recommendation
type Recommendation struct {
	Type        string   `json:"type"`
	Priority    int      `json:"priority"`
	Description string   `json:"description"`
	Action      string   `json:"action"`
	Impact      string   `json:"impact"`
	References  []string `json:"references"`
}

// ProjectContext provides context for template generation
type ProjectContext struct {
	ProjectPath     string            `json:"project_path"`
	Language        string            `json:"language"`
	Framework       string            `json:"framework"`
	Dependencies    []string          `json:"dependencies"`
	Conventions     map[string]string `json:"conventions"`
	History         []HistoryEntry    `json:"history"`
	Configuration   map[string]interface{} `json:"configuration"`
}// Suggestions contains AI-generated suggestions
type Suggestions struct {
	Templates       []TemplateSuggestion `json:"templates"`
	Variables       []VariableSuggestion `json:"variables"`
	Optimizations   []OptimizationSuggestion `json:"optimizations"`
	BestPractices   []BestPracticeSuggestion `json:"best_practices"`
	Confidence      float64              `json:"confidence"`
	Reasoning       string               `json:"reasoning"`
}

// Supporting types for detailed analysis
type ParameterInfo struct {
	Name     string `json:"name"`
	Type     string `json:"type"`
	Optional bool   `json:"optional"`
	Default  string `json:"default,omitempty"`
}

type FieldInfo struct {
	Name string `json:"name"`
	Type string `json:"type"`
	Tag  string `json:"tag,omitempty"`
}

type PatternInstance struct {
	File     string `json:"file"`
	Line     int    `json:"line"`
	Column   int    `json:"column"`
	Context  string `json:"context"`
}

type HistoryEntry struct {
	Timestamp time.Time `json:"timestamp"`
	Action    string    `json:"action"`
	Context   string    `json:"context"`
	Success   bool      `json:"success"`
}

type TemplateSuggestion struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Content     string  `json:"content"`
	Confidence  float64 `json:"confidence"`
	Category    string  `json:"category"`
}

type VariableSuggestion struct {
	Name        string      `json:"name"`
	Type        string      `json:"type"`
	Default     interface{} `json:"default"`
	Description string      `json:"description"`
	Confidence  float64     `json:"confidence"`
	Source      string      `json:"source"`
}

type OptimizationSuggestion struct {
	Type        string  `json:"type"`
	Description string  `json:"description"`
	Impact      string  `json:"impact"`
	Effort      string  `json:"effort"`
	Confidence  float64 `json:"confidence"`
	Code        string  `json:"code,omitempty"`
}

type BestPracticeSuggestion struct {
	Category    string  `json:"category"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Example     string  `json:"example,omitempty"`
	Reference   string  `json:"reference,omitempty"`
	Priority    int     `json:"priority"`
}

// ValidationResult contains template variable validation results
type ValidationResult struct {
	Valid      bool                    `json:"valid"`
	Errors     []ValidationError       `json:"errors"`
	Warnings   []ValidationWarning     `json:"warnings"`
	Missing    []string                `json:"missing"`
	Unused     []string                `json:"unused"`
	Suggestions []VariableSuggestion   `json:"suggestions"`
}

type ValidationError struct {
	Variable string `json:"variable"`
	Message  string `json:"message"`
	Code     string `json:"code"`
	Line     int    `json:"line,omitempty"`
	Column   int    `json:"column,omitempty"`
}

type ValidationWarning struct {
	Variable string `json:"variable"`
	Message  string `json:"message"`
	Code     string `json:"code"`
	Severity string `json:"severity"`
}

// ScopeInfo contains variable scope analysis
type ScopeInfo struct {
	Variables map[string]string `json:"variables"`
	Functions []string          `json:"functions"`
	Types     []string          `json:"types"`
	Imports   []string          `json:"imports"`
}
