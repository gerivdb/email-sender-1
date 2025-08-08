package interfaces

import "time"

// Types d’email template
const (
	EmailTemplateTypeHTML = "html"
	EmailTemplateTypeText = "text"
)

type EmailTemplateType string

type EmailTemplate struct {
	ID        string
	Name      string
	Subject   string
	Body      string
	Content   string // Ajout pour compatibilité avec template_manager.go
	Type      EmailTemplateType
	Variables map[string]interface{}
	Metadata  map[string]interface{}
	CreatedAt time.Time
	UpdatedAt time.Time
	Version   int
	IsActive  bool
}

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
	Email                   struct {
		ID         string
		From       string
		To         []string
		Subject    string
		Body       string
		CreatedAt  time.Time
		Status     string
		RetryCount int
	}
	QueueStatus struct {
		QueueName       string
		Length          int
		Processing      bool
		LastUpdated     time.Time
		Size            int
		FailedEmails    int
		ScheduledEmails int
		IsPaused        bool
		TotalProcessed  int
		TotalFailed     int
		TotalRetries    int
	}
	DateRange    struct{}
	EmailStats   struct{}
	HealthStatus struct {
		Status    string
		CheckedAt time.Time
		Details   map[string]interface{}
		Message   string
		Timestamp time.Time
	}
	DeliveryReport      struct{}
	Notification        struct{}
	NotificationChannel struct{}
	Alert               struct{}
	AlertEvent          struct{}
	NotificationStats   struct{}
	ChannelPerformance  struct{}
	APIEndpoint         struct{}
	APIRequest          struct{}
	APIResponse         struct{}
	APIStatus           struct{}
	APIConfig           struct{}
	SyncJob             struct{}
	SyncStatus          struct{}
	SyncEvent           struct{}
	Webhook             struct{}
	WebhookLog          struct{}
	DataTransformation  struct{}
	Integration         struct{}
	OperationMetrics    struct{}
	SystemMetrics       struct{}
	VulnerabilityReport struct{}
)

// Enum ManagerStatus pour compatibilité email-manager
/*
	ManagerStatus déjà défini dans manager_common.go.
	Retirer la redéclaration ici pour éviter le conflit.
*/
