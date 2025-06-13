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
