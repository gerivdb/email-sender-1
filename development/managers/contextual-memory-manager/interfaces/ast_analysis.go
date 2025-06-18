// interfaces/ast_analysis.go
package interfaces

import (
	"context"
	"time"
)

// ASTAnalysisManager interface pour l'analyse structurelle du code
type ASTAnalysisManager interface {
	BaseManager

	// Analyse structurelle
	AnalyzeFile(ctx context.Context, filePath string) (*ASTAnalysisResult, error)
	AnalyzeWorkspace(ctx context.Context, workspacePath string) (*WorkspaceAnalysis, error)

	// Traversée système fichiers
	TraverseFileSystem(ctx context.Context, rootPath string, filters TraversalFilters) (*FileSystemGraph, error)
	MapDependencies(ctx context.Context, filePath string) (*DependencyGraph, error)

	// Recherche contextuelle AST
	SearchByStructure(ctx context.Context, query StructuralQuery) ([]StructuralResult, error)
	GetSimilarStructures(ctx context.Context, referenceFile string, limit int) ([]StructuralMatch, error)

	// Cache et performance
	GetCacheStats(ctx context.Context) (*ASTCacheStats, error)
	ClearCache(ctx context.Context) error

	// Intégration avec ContextualMemoryManager
	EnrichContextWithAST(ctx context.Context, action Action) (*EnrichedAction, error)
	GetStructuralContext(ctx context.Context, filePath string, lineNumber int) (*StructuralContext, error)
}

// Types de support AST
type ASTAnalysisResult struct {
	FilePath         string                 `json:"file_path"`
	Package          string                 `json:"package"`
	Imports          []ImportInfo           `json:"imports"`
	Functions        []FunctionInfo         `json:"functions"`
	Types            []TypeInfo             `json:"types"`
	Variables        []VariableInfo         `json:"variables"`
	Constants        []ConstantInfo         `json:"constants"`
	Dependencies     []DependencyRelation   `json:"dependencies"`
	Complexity       ComplexityMetrics      `json:"complexity"`
	Context          map[string]interface{} `json:"context"`
	Timestamp        time.Time              `json:"timestamp"`
	AnalysisDuration time.Duration          `json:"analysis_duration"`
}

type WorkspaceAnalysis struct {
	RootPath           string               `json:"root_path"`
	Files              []ASTAnalysisResult  `json:"files"`
	GlobalDependencies []DependencyRelation `json:"global_dependencies"`
	PackageStructure   PackageStructure     `json:"package_structure"`
	Metrics            WorkspaceMetrics     `json:"metrics"`
	BuildTime          time.Duration        `json:"build_time"`
}

type StructuralQuery struct {
	Type          string          `json:"type"` // function, type, variable, import
	Name          string          `json:"name,omitempty"`
	Package       string          `json:"package,omitempty"`
	Signature     string          `json:"signature,omitempty"`
	ReturnType    string          `json:"return_type,omitempty"`
	Parameters    []ParameterInfo `json:"parameters,omitempty"`
	WorkspacePath string          `json:"workspace_path,omitempty"`
	IncludeUsages bool            `json:"include_usages"`
	Limit         int             `json:"limit,omitempty"`
}

type FunctionInfo struct {
	Name          string            `json:"name"`
	Package       string            `json:"package"`
	Signature     string            `json:"signature"`
	Parameters    []ParameterInfo   `json:"parameters"`
	ReturnTypes   []string          `json:"return_types"`
	LineStart     int               `json:"line_start"`
	LineEnd       int               `json:"line_end"`
	Complexity    int               `json:"complexity"`
	IsExported    bool              `json:"is_exported"`
	Documentation string            `json:"documentation,omitempty"`
	Annotations   map[string]string `json:"annotations,omitempty"`
}

type TypeInfo struct {
	Name          string         `json:"name"`
	Kind          string         `json:"kind"` // struct, interface, type alias
	Package       string         `json:"package"`
	Fields        []FieldInfo    `json:"fields,omitempty"`
	Methods       []FunctionInfo `json:"methods,omitempty"`
	IsExported    bool           `json:"is_exported"`
	Documentation string         `json:"documentation,omitempty"`
	LineStart     int            `json:"line_start"`
	LineEnd       int            `json:"line_end"`
}

type VariableInfo struct {
	Name          string `json:"name"`
	Type          string `json:"type"`
	Package       string `json:"package"`
	IsExported    bool   `json:"is_exported"`
	Value         string `json:"value,omitempty"`
	LineNumber    int    `json:"line_number"`
	Documentation string `json:"documentation,omitempty"`
}

type ConstantInfo struct {
	Name          string `json:"name"`
	Type          string `json:"type"`
	Value         string `json:"value"`
	Package       string `json:"package"`
	IsExported    bool   `json:"is_exported"`
	LineNumber    int    `json:"line_number"`
	Documentation string `json:"documentation,omitempty"`
}

type ImportInfo struct {
	Path       string `json:"path"`
	Alias      string `json:"alias,omitempty"`
	IsStandard bool   `json:"is_standard"`
	LineNumber int    `json:"line_number"`
}

type ParameterInfo struct {
	Name       string `json:"name"`
	Type       string `json:"type"`
	IsVariadic bool   `json:"is_variadic"`
}

type FieldInfo struct {
	Name       string `json:"name"`
	Type       string `json:"type"`
	Tag        string `json:"tag,omitempty"`
	IsEmbedded bool   `json:"is_embedded"`
	IsExported bool   `json:"is_exported"`
}

type DependencyRelation struct {
	From       string `json:"from"`
	To         string `json:"to"`
	Type       string `json:"type"` // import, function_call, type_usage
	LineNumber int    `json:"line_number,omitempty"`
}

type DependencyGraph struct {
	Nodes     map[string]*DependencyNode `json:"nodes"`
	Edges     []DependencyEdge           `json:"edges"`
	Cycles    [][]string                 `json:"cycles,omitempty"`
	Levels    map[string]int             `json:"levels"`
	BuildTime time.Duration              `json:"build_time"`
}

type DependencyNode struct {
	ID       string                 `json:"id"`
	Type     string                 `json:"type"`
	Package  string                 `json:"package"`
	FilePath string                 `json:"file_path"`
	Metadata map[string]interface{} `json:"metadata"`
}

type DependencyEdge struct {
	From   string  `json:"from"`
	To     string  `json:"to"`
	Type   string  `json:"type"`
	Weight float64 `json:"weight"`
}

type ComplexityMetrics struct {
	CyclomaticComplexity int `json:"cyclomatic_complexity"`
	LinesOfCode          int `json:"lines_of_code"`
	FunctionCount        int `json:"function_count"`
	TypeCount            int `json:"type_count"`
	DependencyCount      int `json:"dependency_count"`
	CognitiveComplexity  int `json:"cognitive_complexity"`
}

type PackageStructure struct {
	Packages      map[string]*PackageInfo `json:"packages"`
	Relationships []PackageRelation       `json:"relationships"`
}

type PackageInfo struct {
	Name    string       `json:"name"`
	Path    string       `json:"path"`
	Files   []string     `json:"files"`
	Exports []ExportInfo `json:"exports"`
	Imports []string     `json:"imports"`
}

type ExportInfo struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	Signature string `json:"signature,omitempty"`
}

type PackageRelation struct {
	From string `json:"from"`
	To   string `json:"to"`
	Type string `json:"type"`
}

type WorkspaceMetrics struct {
	TotalFiles        int     `json:"total_files"`
	TotalLines        int     `json:"total_lines"`
	TotalFunctions    int     `json:"total_functions"`
	TotalTypes        int     `json:"total_types"`
	PackageCount      int     `json:"package_count"`
	AverageComplexity float64 `json:"average_complexity"`
}

type TraversalFilters struct {
	Extensions     []string `json:"extensions"`
	ExcludePaths   []string `json:"exclude_paths"`
	IncludePaths   []string `json:"include_paths"`
	MaxDepth       int      `json:"max_depth"`
	FollowSymlinks bool     `json:"follow_symlinks"`
}

type FileSystemGraph struct {
	Root          string               `json:"root"`
	Nodes         map[string]*FileNode `json:"nodes"`
	Relationships []FileRelation       `json:"relationships"`
	TraversalTime time.Duration        `json:"traversal_time"`
}

type FileNode struct {
	Path       string    `json:"path"`
	Type       string    `json:"type"` // file, directory
	Size       int64     `json:"size"`
	ModTime    time.Time `json:"mod_time"`
	Extension  string    `json:"extension"`
	IsAnalyzed bool      `json:"is_analyzed"`
}

type FileRelation struct {
	From string `json:"from"`
	To   string `json:"to"`
	Type string `json:"type"`
}

type StructuralResult struct {
	FilePath  string                 `json:"file_path"`
	MatchType string                 `json:"match_type"`
	Element   interface{}            `json:"element"`
	Relevance float64                `json:"relevance"`
	Context   map[string]interface{} `json:"context"`
}

type StructuralMatch struct {
	FilePath        string   `json:"file_path"`
	Similarity      float64  `json:"similarity"`
	MatchedElements []string `json:"matched_elements"`
	Differences     []string `json:"differences"`
}

type ASTCacheStats struct {
	TotalEntries int       `json:"total_entries"`
	HitRate      float64   `json:"hit_rate"`
	MissRate     float64   `json:"miss_rate"`
	MemoryUsage  int64     `json:"memory_usage"`
	OldestEntry  time.Time `json:"oldest_entry"`
	NewestEntry  time.Time `json:"newest_entry"`
}

type StructuralContext struct {
	CurrentFunction *FunctionInfo  `json:"current_function,omitempty"`
	CurrentType     *TypeInfo      `json:"current_type,omitempty"`
	LocalVariables  []VariableInfo `json:"local_variables"`
	Scope           string         `json:"scope"` // package, type, function, block
	RelatedElements []interface{}  `json:"related_elements"`
}

type EnrichedAction struct {
	OriginalAction    Action                 `json:"original_action"`
	ASTResult         *ASTAnalysisResult     `json:"ast_result,omitempty"`
	StructuralContext *StructuralContext     `json:"structural_context,omitempty"`
	ASTContext        map[string]interface{} `json:"ast_context"`
	Timestamp         time.Time              `json:"timestamp"`
}
