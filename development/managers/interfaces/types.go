package interfaces

type DependencyConfig struct {
	Name    string
	Version string
}

type PackageManagerConfig struct {
	Type string
	Path string
}

type RegistryConfig struct {
	URL       string
	AuthToken string
}

type AuthConfig struct {
	Username string
	Password string
}

type SecurityConfig struct {
	EnableChecks bool
}

type ResolutionConfig struct {
	Strategy string
}

type CacheConfig struct {
	Enabled bool
	TTL     int
}

type DependencyMetadata struct {
	Name    string
	Version string
}

type ImageBuildConfig struct {
	BaseImage string
}

type DeploymentConfig struct {
	Env string
}

type EnvironmentDependency struct {
	Name string
}

// Types pour lever les erreurs d'interfaces
type (
	DependencyAnalysis      struct{}
	ResolutionResult        struct{}
	DependencyUpdate        struct{}
	ValidationResult        struct{}
	DependencyConflict      struct{}
	ResolvedPackage         struct{}
	SessionConfig           struct{}
	Session                 struct{}
	SessionFilters          struct{}
	BranchingEvent          struct{}
	Branch                  struct{}
	BranchDimension         struct{}
	BranchTag               struct{}
	DimensionQuery          struct{}
	MemoryContext           struct{}
	Documentation           struct{}
	TemporalSnapshot        struct{}
	TimeRange               struct{}
	BranchingIntent         struct{}
	PredictedBranch         struct{}
	BranchingAnalysis       struct{}
	BranchingStrategy       struct{}
	OptimizedStrategy       struct{}
	BranchingCode           struct{}
	ExecutionResult         struct{}
	QuantumBranch           struct{}
	DevelopmentApproach     struct{}
	ApproachResult          struct{}
	ContextualMemoryManager struct{}
	Email                   struct{}
	EmailTemplate           struct{}
	QueueStatus             struct{}
	DateRange               struct{}
	EmailStats              struct{}
	DeliveryReport          struct{}
	Notification            struct{}
	NotificationChannel     struct{}
	Alert                   struct{}
	AlertEvent              struct{}
	NotificationStats       struct{}
	ChannelPerformance      struct{}
	APIEndpoint             struct{}
	APIRequest              struct{}
	APIResponse             struct{}
	APIStatus               struct{}
	APIConfig               struct{}
	SyncJob                 struct{}
	SyncStatus              struct{}
	SyncEvent               struct{}
	Webhook                 struct{}
	WebhookLog              struct{}
	DataTransformation      struct{}
	Integration             struct{}
	OperationMetrics        struct{}
	SystemMetrics           struct{}
	VulnerabilityReport     struct{}
)
