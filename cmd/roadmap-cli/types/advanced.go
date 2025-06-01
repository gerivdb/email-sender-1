package types

import (
	"time"
)

// TechnicalSpec represents detailed technical specifications
type TechnicalSpec struct {
	DatabaseSchemas    []DatabaseSchema    `json:"database_schemas,omitempty"`
	APIEndpoints      []APIEndpoint       `json:"api_endpoints,omitempty"`
	CodeReferences    []CodeReference     `json:"code_references,omitempty"`
	SystemRequirements []SystemRequirement `json:"system_requirements,omitempty"`
	PerformanceTargets []PerformanceTarget `json:"performance_targets,omitempty"`
}

// DatabaseSchema represents database structure specifications
type DatabaseSchema struct {
	TableName   string            `json:"table_name"`
	Fields      []DatabaseField   `json:"fields"`
	Indexes     []string          `json:"indexes,omitempty"`
	Constraints []string          `json:"constraints,omitempty"`
	Relations   []TableRelation   `json:"relations,omitempty"`
	Description string            `json:"description,omitempty"`
}

// DatabaseField represents a database table field
type DatabaseField struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Nullable    bool   `json:"nullable"`
	PrimaryKey  bool   `json:"primary_key,omitempty"`
	ForeignKey  string `json:"foreign_key,omitempty"`
	Default     string `json:"default,omitempty"`
	Description string `json:"description,omitempty"`
}

// TableRelation represents relationships between tables
type TableRelation struct {
	RelationType string `json:"relation_type"` // "one-to-one", "one-to-many", "many-to-many"
	TargetTable  string `json:"target_table"`
	ForeignKey   string `json:"foreign_key"`
	Description  string `json:"description,omitempty"`
}

// APIEndpoint represents API endpoint specifications
type APIEndpoint struct {
	Method      string            `json:"method"`
	Path        string            `json:"path"`
	Description string            `json:"description,omitempty"`
	Parameters  []APIParameter    `json:"parameters,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	RequestBody string            `json:"request_body,omitempty"`
	Response    string            `json:"response,omitempty"`
	StatusCodes []int             `json:"status_codes,omitempty"`
}

// APIParameter represents API endpoint parameters
type APIParameter struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Required    bool   `json:"required"`
	Location    string `json:"location"` // "query", "path", "header", "body"
	Description string `json:"description,omitempty"`
	Example     string `json:"example,omitempty"`
}

// CodeReference represents code implementation references
type CodeReference struct {
	FilePath    string   `json:"file_path"`
	Language    string   `json:"language"`
	Functions   []string `json:"functions,omitempty"`
	Classes     []string `json:"classes,omitempty"`
	Interfaces  []string `json:"interfaces,omitempty"`
	Description string   `json:"description,omitempty"`
	LineNumbers []int    `json:"line_numbers,omitempty"`
}

// SystemRequirement represents system-level requirements
type SystemRequirement struct {
	Type        string `json:"type"` // "hardware", "software", "network", "security"
	Name        string `json:"name"`
	Version     string `json:"version,omitempty"`
	Description string `json:"description,omitempty"`
	Critical    bool   `json:"critical"`
}

// PerformanceTarget represents performance specifications
type PerformanceTarget struct {
	Metric      string  `json:"metric"` // "response_time", "throughput", "memory", "cpu"
	Target      float64 `json:"target"`
	Unit        string  `json:"unit"`
	Description string  `json:"description,omitempty"`
	Critical    bool    `json:"critical"`
}

// ComplexityMetrics represents detailed complexity analysis
type ComplexityMetrics struct {
	Technical    ComplexityLevel `json:"technical"`
	Database     ComplexityLevel `json:"database"`
	Integration  ComplexityLevel `json:"integration"`
	Testing      ComplexityLevel `json:"testing"`
	Deployment   ComplexityLevel `json:"deployment"`
	Overall      ComplexityLevel `json:"overall"`
	Factors      []string        `json:"factors,omitempty"`
	RiskLevel    string          `json:"risk_level"` // "low", "medium", "high", "critical"
}

// ComplexityLevel represents a complexity rating with details
type ComplexityLevel struct {
	Score       int      `json:"score"`       // 1-10 scale
	Level       string   `json:"level"`       // "trivial", "simple", "moderate", "complex", "expert"
	Justification string `json:"justification,omitempty"`
	Factors     []string `json:"factors,omitempty"`
}

// ImplementationStep represents detailed implementation steps
type ImplementationStep struct {
	ID             string                 `json:"id"`
	Order          int                    `json:"order"`
	Title          string                 `json:"title"`
	Description    string                 `json:"description"`
	Type           string                 `json:"type"` // "setup", "implementation", "testing", "deployment", "validation"
	Commands       []string               `json:"commands,omitempty"`
	Files          []string               `json:"files,omitempty"`
	Prerequisites  []string               `json:"prerequisites,omitempty"`
	Validation     []ValidationStep       `json:"validation,omitempty"`
	EstimatedTime  time.Duration          `json:"estimated_time,omitempty"`
	Status         string                 `json:"status"` // "pending", "in_progress", "completed", "blocked", "failed"
	Notes          string                 `json:"notes,omitempty"`
	Metadata       map[string]interface{} `json:"metadata,omitempty"`
}

// ValidationStep represents validation criteria for implementation steps
type ValidationStep struct {
	Type        string `json:"type"` // "test", "manual", "automated", "performance"
	Description string `json:"description"`
	Command     string `json:"command,omitempty"`
	Expected    string `json:"expected,omitempty"`
	Critical    bool   `json:"critical"`
}

// TechnicalDependency represents advanced dependency relationships
type TechnicalDependency struct {
	Type        string `json:"type"` // "technical", "business", "data", "infrastructure"
	TargetID    string `json:"target_id"`
	Relationship string `json:"relationship"` // "blocks", "enables", "requires", "enhances"
	Strength    int    `json:"strength"` // 1-5 scale of dependency strength
	Description string `json:"description,omitempty"`
	Critical    bool   `json:"critical"`
}

// TaskParameters represents detailed task parameters as found in plan files
type TaskParameters struct {
	Inputs         []string             `json:"inputs,omitempty"`          // Entrées
	Outputs        []string             `json:"outputs,omitempty"`         // Sorties
	Scripts        []string             `json:"scripts,omitempty"`         // Scripts
	URIs           []string             `json:"uris,omitempty"`            // URI
	Methods        []string             `json:"methods,omitempty"`         // Méthodes
	Prerequisites  []string             `json:"prerequisites,omitempty"`   // Conditions préalables
	Tools          []string             `json:"tools,omitempty"`           // Outils
	Frameworks     []string             `json:"frameworks,omitempty"`      // Frameworks
	Commands       []string             `json:"commands,omitempty"`        // Commandes
	ConfigFiles    []string             `json:"config_files,omitempty"`    // Fichiers de configuration
	Dependencies   []string             `json:"dependencies,omitempty"`    // Dépendances
	Environment    map[string]string    `json:"environment,omitempty"`     // Variables d'environnement
	Validation     []string             `json:"validation,omitempty"`      // Critères de validation
}

// DetailedTaskStep represents an ultra-detailed task step with all parameters
type DetailedTaskStep struct {
	ID               string                 `json:"id"`
	Level            int                    `json:"level"`           // Level 1-12
	Title            string                 `json:"title"`
	Description      string                 `json:"description"`
	Parameters       *TaskParameters        `json:"parameters,omitempty"`
	SubSteps         []DetailedTaskStep     `json:"sub_steps,omitempty"`
	EstimatedTime    string                 `json:"estimated_time,omitempty"`
	Complexity       string                 `json:"complexity,omitempty"`
	Priority         string                 `json:"priority,omitempty"`
	Status           string                 `json:"status,omitempty"`
	Progress         int                    `json:"progress,omitempty"`
	Prerequisites    []string               `json:"prerequisites,omitempty"`
	Type             string                 `json:"type,omitempty"`
	Metadata         map[string]interface{} `json:"metadata,omitempty"`
}

// ParameterExtractionStats tracks detailed parameter extraction statistics
type ParameterExtractionStats struct {
	TotalTasksWithParams   int `json:"total_tasks_with_params"`
	InputsExtracted        int `json:"inputs_extracted"`
	OutputsExtracted       int `json:"outputs_extracted"`
	ScriptsExtracted       int `json:"scripts_extracted"`
	URIsExtracted          int `json:"uris_extracted"`
	MethodsExtracted       int `json:"methods_extracted"`
	PrerequisitesExtracted int `json:"prerequisites_extracted"`
	ToolsExtracted         int `json:"tools_extracted"`
	FrameworksExtracted    int `json:"frameworks_extracted"`
}

// HierarchyLevel represents position in the roadmap hierarchy
type HierarchyLevel struct {
	Level      int      `json:"level"`       // 1=Phase, 2=Section, 3=Subsection, 4=Step, 5=Sub-step, 6=Detail, 7=Sub-detail, 8=Micro-step, 9=Sub-micro, 10=Granular, 11=Atomic, 12=Ultra-detailed
	Path       []string `json:"path"`        // Full hierarchy path
	Parent     string   `json:"parent,omitempty"`
	Children   []string `json:"children,omitempty"`
	Position   int      `json:"position"`    // Position at current level
	MaxDepth   int      `json:"max_depth"`   // Maximum depth allowed (now supports up to 12)
	LevelName  string   `json:"level_name"`  // Human-readable level name
}

// AdvancedRoadmapItem extends the basic RoadmapItem with advanced features
type AdvancedRoadmapItem struct {
	// Basic fields (inherited from RoadmapItem)
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Status      string    `json:"status"`
	Priority    string    `json:"priority"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	
	// Advanced hierarchical fields (supports up to 12 levels)
	Hierarchy           HierarchyLevel         `json:"hierarchy"`
	ParentItemID        string                 `json:"parent_item_id,omitempty"`
	ChildItems          []string               `json:"child_items,omitempty"`
	HierarchyPath       []string               `json:"hierarchy_path"`
		// Detailed task parameters (extracted from markdown)
	TaskParameters      *TaskParameters        `json:"task_parameters,omitempty"`
	DetailedSteps       []DetailedTaskStep     `json:"detailed_steps,omitempty"`
	
	// Technical specifications
	TechnicalSpec       TechnicalSpec          `json:"technical_spec,omitempty"`
	ImplementationSteps []ImplementationStep   `json:"implementation_steps,omitempty"`
	ComplexityMetrics   ComplexityMetrics      `json:"complexity_metrics,omitempty"`
	
	// Advanced dependencies
	TechnicalDependencies []TechnicalDependency `json:"technical_dependencies,omitempty"`
	
	// Extended metadata
	Tags                []string               `json:"tags,omitempty"`
	AssignedTeams       []string               `json:"assigned_teams,omitempty"`
	EstimatedEffort     time.Duration          `json:"estimated_effort,omitempty"`
	ActualEffort        time.Duration          `json:"actual_effort,omitempty"`
	BusinessValue       int                    `json:"business_value,omitempty"` // 1-10 scale
	RiskFactors         []string               `json:"risk_factors,omitempty"`
	
	// Source information
	SourceFile          string                 `json:"source_file,omitempty"`
	SourceLine          int                    `json:"source_line,omitempty"`
	LastParsed          time.Time              `json:"last_parsed,omitempty"`
}

// AdvancedRoadmap represents a collection of advanced roadmap items
type AdvancedRoadmap struct {
	Version     string                 `json:"version"`
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	
	// Hierarchical structure (supports up to 12 levels)
	Items       []AdvancedRoadmapItem  `json:"items"`
	Hierarchy   map[string][]string    `json:"hierarchy"` // level -> item IDs
	MaxDepth    int                    `json:"max_depth"` // Now supports up to 12
	
	// Level names mapping
	LevelNames  map[int]string         `json:"level_names"` // 1="Phase", 2="Section", etc.
	
	// Detailed parameters extraction statistics
	ParameterStats *ParameterExtractionStats `json:"parameter_stats,omitempty"`
	
	// Analytics
	TotalItems             int                 `json:"total_items"`
	CompletedItems         int                 `json:"completed_items"`
	OverallProgress        float64             `json:"overall_progress"`
	ComplexityDistribution map[string]int      `json:"complexity_distribution,omitempty"`
	EffortEstimation       time.Duration       `json:"effort_estimation,omitempty"`
	RiskAssessment         string              `json:"risk_assessment,omitempty"`
	
	// Technical overview
	TechStack      []string            `json:"tech_stack,omitempty"`
	DatabaseTypes  []string            `json:"database_types,omitempty"`
	APIPatterns    []string            `json:"api_patterns,omitempty"`
}
