package interfaces

import "context"

// DependencyManager interface pour la gestion des dépendances
type DependencyManager interface {
	BaseManager
	GetID() string
	GetName() string
	GetVersion() string
	GetStatus() ManagerStatus
	Initialize(ctx context.Context) error
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	Health(ctx context.Context) error

	// Gestion des dépendances
	AnalyzeDependencies(ctx context.Context, projectPath string) (*DependencyAnalysis, error)
	ResolveDependencies(ctx context.Context, dependencies []string) (*ResolutionResult, error)
	UpdateDependency(ctx context.Context, name, version string) error
	CheckForUpdates(ctx context.Context) ([]DependencyUpdate, error)
	ValidateDependencies(ctx context.Context) (*ValidationResult, error)

	// Gestion des conflits
	DetectConflicts(ctx context.Context) ([]DependencyConflict, error)
	ResolveConflict(ctx context.Context, conflict *DependencyConflict) error

	// Métadonnées
	GetDependencyInfo(ctx context.Context, name string) (*DependencyMetadata, error)
	UpdateMetadata(ctx context.Context, metadata *DependencyMetadata) error

	// ===== NOUVELLE SECTION: GESTION DES IMPORTS =====
	// Validation des imports
	ValidateImportPaths(ctx context.Context, projectPath string) (*ImportValidationResult, error)
	FixRelativeImports(ctx context.Context, projectPath string) error
	NormalizeModulePaths(ctx context.Context, projectPath string, expectedPrefix string) error
	DetectImportConflicts(ctx context.Context, projectPath string) ([]ImportConflict, error)
	GenerateImportReport(ctx context.Context, projectPath string) (*ImportReport, error)

	// Analyse et correction automatique
	ScanInvalidImports(ctx context.Context, projectPath string) ([]ImportIssue, error)
	AutoFixImports(ctx context.Context, projectPath string, options *ImportFixOptions) (*ImportFixResult, error)
	ValidateModuleStructure(ctx context.Context, projectPath string) (*ModuleStructureValidation, error)
}

// PackageResolver interface pour la résolution de packages
type PackageResolver interface {
	Resolve(ctx context.Context, packageName, version string) (*ResolvedPackage, error)
	GetVersions(ctx context.Context, packageName string) ([]string, error)
	FindCompatibleVersion(ctx context.Context, packageName string, constraints []string) (string, error)
}

// VersionManager interface pour la gestion des versions
type VersionManager interface {
	CompareVersions(v1, v2 string) int
	IsCompatible(version string, constraints []string) bool
	GetLatestVersion(ctx context.Context, packageName string) (string, error)
	GetLatestStableVersion(ctx context.Context, packageName string) (string, error)
}

// ===== TYPES POUR LA GESTION DES IMPORTS =====

// ImportIssue représente un problème d'import détecté
type ImportIssue struct {
	FilePath     string            `json:"file_path"`
	LineNumber   int               `json:"line_number"`
	ImportPath   string            `json:"import_path"`
	IssueType    ImportIssueType   `json:"issue_type"`
	Severity     string            `json:"severity"` // "low", "medium", "high", "critical"
	Description  string            `json:"description"`
	SuggestedFix string            `json:"suggested_fix"`
	AutoFixable  bool              `json:"auto_fixable"`
	Context      map[string]string `json:"context"`
}

// ImportIssueType énumère les types de problèmes d'imports
type ImportIssueType string

const (
	ImportIssueRelative      ImportIssueType = "relative_import"
	ImportIssueInvalidPath   ImportIssueType = "invalid_path"
	ImportIssueCircular      ImportIssueType = "circular_dependency"
	ImportIssueMissingModule ImportIssueType = "missing_module"
	ImportIssueUnused        ImportIssueType = "unused_import"
	ImportIssueInconsistent  ImportIssueType = "inconsistent_naming"
)

// ImportConflict représente un conflit entre imports
type ImportConflict struct {
	Type             string   `json:"type"`
	ConflictingPaths []string `json:"conflicting_paths"`
	Severity         string   `json:"severity"`
	Description      string   `json:"description"`
	Resolution       string   `json:"resolution"`
}

// ImportValidationResult contient les résultats de validation des imports
type ImportValidationResult struct {
	ProjectPath     string            `json:"project_path"`
	TotalFiles      int               `json:"total_files"`
	FilesWithIssues int               `json:"files_with_issues"`
	Issues          []ImportIssue     `json:"issues"`
	Conflicts       []ImportConflict  `json:"conflicts"`
	Summary         ValidationSummary `json:"summary"`
	Timestamp       string            `json:"timestamp"`
}

// ValidationSummary résume les problèmes trouvés
type ValidationSummary struct {
	RelativeImports      int `json:"relative_imports"`
	InvalidPaths         int `json:"invalid_paths"`
	CircularDependencies int `json:"circular_dependencies"`
	MissingModules       int `json:"missing_modules"`
	UnusedImports        int `json:"unused_imports"`
	InconsistentNaming   int `json:"inconsistent_naming"`
}

// ImportFixOptions configure les options de correction automatique
type ImportFixOptions struct {
	FixRelativeImports   bool   `json:"fix_relative_imports"`
	NormalizeModulePaths bool   `json:"normalize_module_paths"`
	RemoveUnusedImports  bool   `json:"remove_unused_imports"`
	StandardizeNaming    bool   `json:"standardize_naming"`
	ExpectedModulePrefix string `json:"expected_module_prefix"`
	PreserveCasingRules  bool   `json:"preserve_casing_rules"`
	CreateBackups        bool   `json:"create_backups"`
}

// ImportFixResult contient les résultats des corrections appliquées
type ImportFixResult struct {
	FilesModified   []string `json:"files_modified"`
	FilesCreated    []string `json:"files_created"`
	BackupsCreated  []string `json:"backups_created"`
	IssuesFixed     int      `json:"issues_fixed"`
	IssuesRemaining int      `json:"issues_remaining"`
	Summary         string   `json:"summary"`
}

// ModuleStructureValidation valide la structure globale des modules
type ModuleStructureValidation struct {
	ModuleName        string   `json:"module_name"`
	GoModValid        bool     `json:"go_mod_valid"`
	GoSumValid        bool     `json:"go_sum_valid"`
	ModulePathCorrect bool     `json:"module_path_correct"`
	DependenciesValid bool     `json:"dependencies_valid"`
	Errors            []string `json:"errors"`
	Warnings          []string `json:"warnings"`
}

// ImportReport génère un rapport complet des imports du projet
type ImportReport struct {
	ProjectPath     string              `json:"project_path"`
	ModuleName      string              `json:"module_name"`
	TotalGoFiles    int                 `json:"total_go_files"`
	TotalImports    int                 `json:"total_imports"`
	ExternalImports int                 `json:"external_imports"`
	InternalImports int                 `json:"internal_imports"`
	RelativeImports int                 `json:"relative_imports"`
	Issues          []ImportIssue       `json:"issues"`
	DependencyGraph map[string][]string `json:"dependency_graph"`
	Statistics      ImportStatistics    `json:"statistics"`
	Recommendations []string            `json:"recommendations"`
	GeneratedAt     string              `json:"generated_at"`
}

// ImportStatistics contient des statistiques sur les imports
type ImportStatistics struct {
	TopExternalDependencies []DependencyUsage `json:"top_external_dependencies"`
	LargestInternalModules  []ModuleUsage     `json:"largest_internal_modules"`
	CircularDependencies    []string          `json:"circular_dependencies"`
	UnusedImports           []string          `json:"unused_imports"`
}

// DependencyUsage statistique d'usage d'une dépendance
type DependencyUsage struct {
	Name  string `json:"name"`
	Count int    `json:"count"`
}

// ModuleUsage statistique d'usage d'un module interne
type ModuleUsage struct {
	Path  string `json:"path"`
	Count int    `json:"count"`
}
