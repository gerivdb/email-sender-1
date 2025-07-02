package interfaces

import (
	"context"
	"time"
)

// BaseManager provides the foundation for all managers
type BaseManager interface {
	Start(ctx context.Context) error
	Stop() error
	IsHealthy() bool
	GetStatus() string
}

// StorageManager handles data storage operations
type StorageManager interface {
	BaseManager
	Store(ctx context.Context, collection, key string, value string) error
	Get(ctx context.Context, collection, key string) (string, error)
	Update(ctx context.Context, collection, key string, value string) error
	Delete(ctx context.Context, collection, key string) error
	List(ctx context.Context, collection string) ([]string, error)
}

// ErrorManager handles error management and recovery
type ErrorManager interface {
	BaseManager
	HandleError(err error) error
	RecordError(err error)
	GetErrorHistory() []error
}

// ContextualMemoryManager manages contextual memory operations
type ContextualMemoryManager interface {
	BaseManager
	StoreContext(ctx context.Context, data interface{}) error
	RetrieveContext(id string) (interface{}, error)
}

// Session represents a branching session
// Session represents a branching session
type Session struct {
	ID        string
	Timestamp time.Time
	Scope     string
	Duration  time.Duration
	Status    SessionStatus
	Metadata  map[string]string
	CreatedAt time.Time
	EndedAt   *time.Time
	BranchID  string
}

// SessionStatus represents the status of a session
type SessionStatus string

const (
	SessionStatusActive   SessionStatus = "active"
	SessionStatusEnded    SessionStatus = "ended"
	SessionStatusArchived SessionStatus = "archived"
)

// SessionConfig provides configuration for creating a new session
type SessionConfig struct {
	Scope         string
	MaxDuration   time.Duration
	NamingPattern string
	Metadata      map[string]string
}

// SessionFilters provides filters for querying sessions
type SessionFilters struct {
	Status    SessionStatus
	Scope     string
	BranchID  string
	StartTime *time.Time
	EndTime   *time.Time
	Limit     int
	Offset    int
}

// BranchingEvent represents an event in the branching system
// BranchingEvent represents an event in the branching system
type BranchingEvent struct {
	ID          string
	Type        EventType
	Trigger     string
	Context     map[string]interface{}
	AutoCreated bool
	Priority    EventPriority
	CreatedAt   time.Time
	Data        interface{} // Generic data payload for the event
}

// EventType represents the type of branching event
type EventType string

const (
	EventTypeSessionCreated EventType = "session_created"
	EventTypeSessionEnded   EventType = "session_ended"
	EventTypeBranchCreated  EventType = "branch_created"
	EventTypeBranchMerged   EventType = "branch_merged"
	EventTypeCommit         EventType = "commit"
	EventTypePush           EventType = "push"
	EventTypePullRequest    EventType = "pull_request"
	EventTypeTimer          EventType = "timer"
	EventTypeSystemTrigger  EventType = "system_trigger"
)

// EventPriority represents the priority of an event
type EventPriority int

const (
	EventPriorityLow      EventPriority = 1
	EventPriorityMedium   EventPriority = 5
	EventPriorityHigh     EventPriority = 10
	EventPriorityCritical EventPriority = 100
)

// TemporalSnapshot represents a point-in-time snapshot
// TemporalSnapshot represents a point-in-time snapshot of a branch
type TemporalSnapshot struct {
	ID         string
	BranchID   string
	Timestamp  time.Time
	CommitHash string
	State      map[string]interface{} // Represents the state of the branch at the time of snapshot
	Metadata   map[string]string
	CreatedAt  time.Time
}

// TimeRange defines a start and end time
type TimeRange struct {
	Start time.Time
	End   time.Time
}

// QuantumBranch represents a quantum superposition of development approaches
type QuantumBranch struct {
	ID                string
	Name              string
	Goal              string
	Approaches        []BranchApproach
	OptimalApproachID *string
	Status            QuantumStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	Metadata          map[string]string
}

// QuantumStatus represents the status of a quantum branch
type QuantumStatus string

const (
	QuantumStatusActive         QuantumStatus = "active"
	QuantumStatusExecuted       QuantumStatus = "executed"
	QuantumStatusOptimized      QuantumStatus = "optimized"
	QuantumStatusCompleted      QuantumStatus = "completed"
	QuantumStatusFailed         QuantumStatus = "failed"
	QuantumStatusPartialSuccess QuantumStatus = "partial_success"
)

// QuantumBranchConfig provides configuration for creating a new quantum branch
type QuantumBranchConfig struct {
	Name       string
	Goal       string
	Approaches []BranchApproachConfig
	Metadata   map[string]string
}

// BranchApproachConfig provides configuration for a single approach within a quantum branch
type BranchApproachConfig struct {
	Name            string
	Strategy        string
	Parameters      map[string]interface{}
	Priority        int
	EstimatedEffort int // in seconds
}

// BranchApproach represents a single development approach within a quantum branch
type BranchApproach struct {
	ID              string
	Name            string
	BranchID        string
	Strategy        string
	Parameters      map[string]interface{}
	Priority        int
	EstimatedEffort int // in seconds
	Status          ApproachStatus
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// ApproachStatus represents the status of a development approach
type ApproachStatus string

const (
	ApproachStatusPending    ApproachStatus = "pending"
	ApproachStatusInProgress ApproachStatus = "in_progress"
	ApproachStatusCompleted  ApproachStatus = "completed"
	ApproachStatusFailed     ApproachStatus = "failed"
	ApproachStatusCancelled  ApproachStatus = "cancelled"
)

// ApproachProgress represents the progress of a development approach
type ApproachProgress struct {
	BranchID             string
	CompletionPercentage float64
	CommitCount          int
	LastActivity         time.Time
}

// ApproachResult represents the result of executing a single development approach
type ApproachResult struct {
	ApproachID    string
	ApproachName  string
	BranchID      string
	Status        ApproachStatus
	ExecutionTime time.Duration
	Success       bool
	ErrorMessage  string
	CompletedAt   time.Time
	Metrics       ApproachMetrics
	Artifacts     []string
}

// ApproachMetrics represents various metrics for a development approach
type ApproachMetrics struct {
	LinesOfCode      int
	TestCoverage     float64
	ComplexityScore  float64
	PerformanceScore float64
	// Add more metrics as needed
}

// QuantumAnalysis provides an analysis of quantum branch execution
type QuantumAnalysis struct {
	TotalApproaches          int
	SuccessfulApproaches     int
	FailedApproaches         int
	AverageExecutionTime     time.Duration
	AverageMetrics           ApproachMetrics
	RecommendedOptimizations []string
}

// QuantumExecutionResult represents the overall result of executing a quantum branch
type QuantumExecutionResult struct {
	QuantumBranchID string
	ExecutedAt      time.Time
	Results         []ApproachResult
	Analysis        QuantumAnalysis
	Errors          []error
	Status          QuantumExecutionStatus
}

// OptimalApproachSelection represents the selection of the optimal approach
type OptimalApproachSelection struct {
	QuantumBranchID    string
	OptimalApproachID  string
	OptimalResult      *ApproachResult
	Confidence         float64
	AlternativeOptions []AlternativeOption
	SelectionReasons   []string
	SelectedAt         time.Time
	Metrics            map[string]ApproachMetrics
}

// AlternativeOption represents an alternative approach
type AlternativeOption struct {
	ApproachID string
	Score      float64
	Reason     string
}

// Branch represents a development branch
type Branch struct {
	ID         string
	Name       string
	BaseBranch string
	CreatedAt  time.Time
	UpdatedAt  time.Time
	Status     BranchStatus
	Metadata   map[string]string
	EventID    string
	Level      int // Represents the level of branching (e.g., 1: micro-session, 2: event-driven)
}

// BranchStatus represents the status of a branch
type BranchStatus string

const (
	BranchStatusActive   BranchStatus = "active"
	BranchStatusMerged   BranchStatus = "merged"
	BranchStatusArchived BranchStatus = "archived"
	BranchStatusDeleted  BranchStatus = "deleted"
)

// BranchDimension represents a single dimension for multi-dimensional branching
type BranchDimension struct {
	Name   string
	Value  string
	Type   DimensionType
	Weight float64 // 0.0 to 1.0, importance of this dimension
}

// DimensionType represents the type of a dimension
type DimensionType string

const (
	DimensionTypeFeature    DimensionType = "feature"
	DimensionTypeBug        DimensionType = "bug"
	DimensionTypeTeam       DimensionType = "team"
	DimensionTypePriority   DimensionType = "priority"
	DimensionTypeComponent  DimensionType = "component"
	DimensionTypeExperiment DimensionType = "experiment"
)

// BranchTag represents a tag associated with a branch
type BranchTag struct {
	Key       string
	Value     string
	Category  string
	CreatedAt time.Time
}

// DimensionQuery provides criteria for searching branches by dimensions
type DimensionQuery struct {
	Dimensions []BranchDimension
	Tags       []BranchTag
	Operator   QueryOperator
	Limit      int
	Offset     int
}

// QueryOperator defines how multiple query criteria are combined
type QueryOperator string

const (
	QueryOperatorAND QueryOperator = "AND"
	QueryOperatorOR  QueryOperator = "OR"
	QueryOperatorNOT QueryOperator = "NOT"
)

// MemoryContext represents a piece of contextual memory
type MemoryContext struct {
	ContextID   string
	ContentType string
	Content     string
	Source      string
	Timestamp   time.Time
	Metadata    map[string]string
	Type        MemoryContextType
}

// MemoryContextType defines the type of memory context
type MemoryContextType string

const (
	MemoryContextTypeCode    MemoryContextType = "code"
	MemoryContextTypeDoc     MemoryContextType = "documentation"
	MemoryContextTypeCommit  MemoryContextType = "commit"
	MemoryContextTypeIssue   MemoryContextType = "issue"
	MemoryContextTypeGeneral MemoryContextType = "general"
)

// Documentation represents generated documentation for a branch
type Documentation struct {
	ID          string
	BranchID    string
	Content     string
	Type        DocumentationType
	GeneratedAt time.Time
	Metadata    map[string]interface{}
}

// DocumentationType defines the type of documentation
type DocumentationType string

const (
	DocumentationTypeAutoGenerated DocumentationType = "auto_generated"
	DocumentationTypeManual        DocumentationType = "manual"
)

// BranchingIntent represents a user's intent for branching
type BranchingIntent struct {
	Goal        string
	Description string
	Priority    IntentPriority
	Metadata    map[string]string
}

// IntentPriority defines the priority of a branching intent
type IntentPriority int

const (
	IntentPriorityLow    IntentPriority = 1
	IntentPriorityMedium IntentPriority = 5
	IntentPriorityHigh   IntentPriority = 10
)

// PredictedBranch represents a prediction for an optimal branch
type PredictedBranch struct {
	RecommendedName   string
	Confidence        float64
	Reasoning         []string
	SuggestedTags     []BranchTag
	Risks             []string
	EstimatedDuration time.Duration
	Metadata          map[string]string
}

// BranchingAnalysis provides insights into branching patterns
type BranchingAnalysis struct {
	ProjectID       string
	AnalyzedPeriod  TimeRange
	Patterns        []BranchingPattern
	Recommendations []string
	EfficiencyScore float64 // 0.0 to 10.0
	GeneratedAt     time.Time
}

// BranchingPattern represents a recurring pattern in branching
type BranchingPattern struct {
	Type        string
	Frequency   float64
	AvgDuration time.Duration
	Impact      float64 // 0.0 to 10.0
	Metadata    map[string]string
}

// BranchingStrategy defines a set of rules for branching
type BranchingStrategy struct {
	Name        string
	Description string
	Rules       []StrategyRule
	Metadata    map[string]string
}

// StrategyRule defines a single rule within a branching strategy
type StrategyRule struct {
	Condition string
	Action    string
	Priority  int
}

// OptimizedStrategy represents an optimized branching strategy
type OptimizedStrategy struct {
	OptimizedStrategy BranchingStrategy
	Improvements      []string
	ConfidenceScore   float64
	ExpectedBenefit   float64
}

// BranchingAsCodeConfig defines a declarative branching configuration
type BranchingAsCodeConfig struct {
	ID         string
	Name       string
	Language   CodeLanguage
	Code       string
	Parameters map[string]interface{}
	TemplateID string
	CreatedAt  time.Time
}

// CodeLanguage represents the language of the branching as code configuration
type CodeLanguage string

const (
	LanguageYAML CodeLanguage = "yaml"
	LanguageJSON CodeLanguage = "json"
	LanguageGo   CodeLanguage = "go"
	LanguageLua  CodeLanguage = "lua"
)

// BranchingCodeValidation represents the result of validating branching code
type BranchingCodeValidation struct {
	ConfigID    string
	Language    CodeLanguage
	ValidatedAt time.Time
	IsValid     bool
	Errors      []string
	Warnings    []string
	Suggestions []string
}

// BranchingTemplate represents a reusable branching template
type BranchingTemplate struct {
	ID        string
	Name      string
	Language  CodeLanguage
	Code      string
	Variables []string
	CreatedAt time.Time
}

// ParsedBranchingConfig represents a parsed branching configuration
type ParsedBranchingConfig struct {
	Operations []BranchingOperation
}

// BranchingOperation defines a single operation within a branching configuration
type BranchingOperation struct {
	Type   OperationType
	Name   string
	Config map[string]interface{}
}

// OperationType defines the type of branching operation
type OperationType string

const (
	OpTypeCreate OperationType = "create"
	OpTypeModify OperationType = "modify"
	OpTypeDelete OperationType = "delete"
	OpTypeMerge  OperationType = "merge"
)

// ExecutionResult represents the result of executing a branching as code configuration
type ExecutionResult struct {
	CreatedBranches   []string
	ModifiedBranches  []string
	DeletedBranches   []string
	Log               []string
	ValidationResults []string
}

// QuantumExecutionStatus represents the status of a quantum branch execution
type QuantumExecutionStatus string

const (
	QuantumExecutionStatusSuccess        QuantumExecutionStatus = "success"
	QuantumExecutionStatusPartialSuccess QuantumExecutionStatus = "partial_success"
	QuantumExecutionStatusFailed         QuantumExecutionStatus = "failed"
)

// GitBranchResult represents the result of a Git branch operation
type GitBranchResult struct {
	BranchID   string
	BranchName string
	Success    bool
	Error      string
}

// GitMergeResult represents the result of a Git merge operation
type GitMergeResult struct {
	SourceBranch string
	TargetBranch string
	Success      bool
	Conflict     bool
	Message      string
	Error        string
}

// GitCommitResult represents the result of a Git commit operation
type GitCommitResult struct {
	CommitHash string
	Message    string
	Success    bool
	Error      string
}

// GitBranchInfo provides information about a Git branch
type GitBranchInfo struct {
	Name       string
	CommitHash string
	IsHead     bool
	IsRemote   bool
}

// GitRepositoryStatus represents the status of a Git repository
type GitRepositoryStatus struct {
	IsClean       bool
	HasChanges    bool
	Untracked     []string
	Staged        []string
	Unstaged      []string
	CurrentBranch string
	LastCommit    string
}

// GitOperations provides an interface for Git operations
type GitOperations interface {
	Clone(ctx context.Context, repoURL, path string) error
	Checkout(ctx context.Context, branchName string) error
	CreateBranch(ctx context.Context, branchName, baseBranch string) (*GitBranchResult, error)
	Merge(ctx context.Context, sourceBranch, targetBranch string) (*GitMergeResult, error)
	Commit(ctx context.Context, message string) (*GitCommitResult, error)
	Push(ctx context.Context, remote, branch string) error
	Pull(ctx context.Context, remote, branch string) error
	GetBranchInfo(ctx context.Context, branchName string) (*GitBranchInfo, error)
	GetRepoStatus(ctx context.Context) (*GitRepositoryStatus, error)
	Add(ctx context.Context, files []string) error
	Reset(ctx context.Context, mode string) error
}

// BranchingManager is the main interface for the branching manager
type BranchingManager interface {
	BaseManager

	// Session management
	CreateSession(name string) (*Session, error)
	GetSession(id string) (*Session, error)
	EndSession(id string) error

	// Event processing
	ProcessEvent(event *BranchingEvent) error

	// Temporal operations
	CreateSnapshot(sessionID string) (*TemporalSnapshot, error)
	RestoreFromSnapshot(snapshotID string) (*Branch, error) // Changed return type to Branch
	GetTemporalHistory(ctx context.Context, branchID string, timeRange TimeRange) ([]*TemporalSnapshot, error)

	// Quantum operations
	CreateQuantumBranch(quantumConfig QuantumBranchConfig) (*QuantumBranch, error) // Changed parameter type
	ExecuteQuantumApproaches(ctx context.Context, quantumBranchID string) (*QuantumExecutionResult, error)
	SelectOptimalApproach(ctx context.Context, executionResult *QuantumExecutionResult) (*OptimalApproachSelection, error)

	// Multi-dimensional branching
	CreateMultiDimBranch(ctx context.Context, dimensions []BranchDimension) (*Branch, error)
	TagBranch(ctx context.Context, branchID string, tags []BranchTag) error
	SearchBranchesByDimensions(ctx context.Context, query DimensionQuery) ([]*Branch, error)

	// Contextual Memory integration
	IntegrateContextualMemory(ctx context.Context, branchID string, memoryContext MemoryContext) error
	GenerateAutoDocumentation(ctx context.Context, branchID string) (*Documentation, error)
	LinkBranchToContext(ctx context.Context, branchID string, contextID string) error

	// Predictive Branching
	PredictOptimalBranch(ctx context.Context, intent BranchingIntent) (*PredictedBranch, error)
	AnalyzeBranchingPatterns(ctx context.Context, projectID string) (*BranchingAnalysis, error)
	OptimizeBranchingStrategy(ctx context.Context, currentStrategy BranchingStrategy) (*OptimizedStrategy, error)

	// Branching as Code
	ExecuteBranchingAsCode(ctx context.Context, config BranchingAsCodeConfig) (*BranchingAsCodeResult, error)
	ValidateBranchingCode(ctx context.Context, config BranchingAsCodeConfig) (*BranchingCodeValidation, error)
	LoadBranchingTemplate(ctx context.Context, templateID string, params map[string]interface{}) (*BranchingAsCodeConfig, error)
}

// BranchingAsCodeResult represents the result of executing a branching as code configuration
type BranchingAsCodeResult struct {
	ConfigID          string
	Language          CodeLanguage
	ExecutedAt        time.Time
	Status            ExecutionStatus
	CreatedBranches   []string
	ModifiedBranches  []string
	DeletedBranches   []string
	ExecutionLog      []string
	ValidationResults []string
}

// Similarity results
type SessionSimilarity struct {
	SessionID string
	Score     float64
	Reason    string
}

type BranchSimilarity struct {
	BranchID string
	Score    float64
	Reason   string
}

type PatternSimilarity struct {
	PatternID string
	Score     float64
	Reason    string
}

type ApproachSimilarity struct {
	ApproachID string
	Score      float64
	Reason     string
}

// VectorManager provides an interface for vector database operations
type VectorManager interface {
	StoreVector(ctx context.Context, collection string, vector []float32, payload map[string]interface{}) (string, error)
	SearchVectors(ctx context.Context, collection string, queryVector []float32, limit int, filter map[string]interface{}) ([]map[string]interface{}, error)
	DeleteVectors(ctx context.Context, collection string, ids []string) error
	UpdatePayload(ctx context.Context, collection string, id string, payload map[string]interface{}) error
}
