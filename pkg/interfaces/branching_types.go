package interfaces

import (
	"time"
)

// Level 1: Micro-Sessions Temporelles structures
type Session struct {
	ID        string            `json:"id" yaml:"id"`
	Timestamp time.Time         `json:"timestamp" yaml:"timestamp"`
	Scope     string            `json:"scope" yaml:"scope"`
	Duration  time.Duration     `json:"duration" yaml:"duration"`
	Status    SessionStatus     `json:"status" yaml:"status"`
	Metadata  map[string]string `json:"metadata" yaml:"metadata"`
	BranchID  string            `json:"branch_id" yaml:"branch_id"`
	UserID    string            `json:"user_id" yaml:"user_id"`
	CreatedAt time.Time         `json:"created_at" yaml:"created_at"`
	EndedAt   *time.Time        `json:"ended_at,omitempty" yaml:"ended_at,omitempty"`
}

type SessionStatus string

const (
	SessionStatusActive   SessionStatus = "active"
	SessionStatusEnded    SessionStatus = "ended"
	SessionStatusArchived SessionStatus = "archived"
	SessionStatusExpired  SessionStatus = "expired"
)

type SessionConfig struct {
	MaxDuration   time.Duration     `json:"max_duration" yaml:"max_duration"`
	AutoArchive   bool              `json:"auto_archive" yaml:"auto_archive"`
	NamingPattern string            `json:"naming_pattern" yaml:"naming_pattern"`
	Scope         string            `json:"scope" yaml:"scope"`
	Metadata      map[string]string `json:"metadata" yaml:"metadata"`
}

type SessionFilters struct {
	UserID    string        `json:"user_id,omitempty" yaml:"user_id,omitempty"`
	Status    SessionStatus `json:"status,omitempty" yaml:"status,omitempty"`
	StartDate *time.Time    `json:"start_date,omitempty" yaml:"start_date,omitempty"`
	EndDate   *time.Time    `json:"end_date,omitempty" yaml:"end_date,omitempty"`
	Scope     string        `json:"scope,omitempty" yaml:"scope,omitempty"`
}

// Level 2: Event-Driven Branching structures
type BranchingEvent struct {
	Type        EventType             `json:"type" yaml:"type"`
	Trigger     string                `json:"trigger" yaml:"trigger"`
	Context     map[string]interface{} `json:"context" yaml:"context"`
	AutoCreated bool                  `json:"auto_created" yaml:"auto_created"`
	Priority    EventPriority         `json:"priority" yaml:"priority"`
	CreatedAt   time.Time             `json:"created_at" yaml:"created_at"`
	ProcessedAt *time.Time            `json:"processed_at,omitempty" yaml:"processed_at,omitempty"`
}

type EventType string

const (
	EventTypeCommit       EventType = "commit"
	EventTypePush         EventType = "push"
	EventTypePullRequest  EventType = "pull_request"
	EventTypeIssue        EventType = "issue"
	EventTypeTimer        EventType = "timer"
	EventTypeUserTrigger  EventType = "user_trigger"
	EventTypeSystemTrigger EventType = "system_trigger"
)

type EventPriority int

const (
	EventPriorityLow    EventPriority = 1
	EventPriorityMedium EventPriority = 2
	EventPriorityHigh   EventPriority = 3
	EventPriorityCritical EventPriority = 4
)

// Core Branch structure used across all levels
type Branch struct {
	ID          string            `json:"id" yaml:"id"`
	Name        string            `json:"name" yaml:"name"`
	BaseBranch  string            `json:"base_branch" yaml:"base_branch"`
	CreatedAt   time.Time         `json:"created_at" yaml:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at" yaml:"updated_at"`
	Status      BranchStatus      `json:"status" yaml:"status"`
	Metadata    map[string]string `json:"metadata" yaml:"metadata"`
	SessionID   string            `json:"session_id,omitempty" yaml:"session_id,omitempty"`
	EventID     string            `json:"event_id,omitempty" yaml:"event_id,omitempty"`
	Level       int               `json:"level" yaml:"level"` // 1-8 indicating which level created this branch
}

type BranchStatus string

const (
	BranchStatusActive   BranchStatus = "active"
	BranchStatusMerged   BranchStatus = "merged"
	BranchStatusClosed   BranchStatus = "closed"
	BranchStatusArchived BranchStatus = "archived"
	BranchStatusConflict BranchStatus = "conflict"
)

// Level 3: Multi-Dimensional Branching structures
type BranchDimension struct {
	Name        string                 `json:"name" yaml:"name"`
	Value       string                 `json:"value" yaml:"value"`
	Type        DimensionType          `json:"type" yaml:"type"`
	Weight      float64                `json:"weight" yaml:"weight"`
	Constraints map[string]interface{} `json:"constraints,omitempty" yaml:"constraints,omitempty"`
}

type DimensionType string

const (
	DimensionTypeFeature     DimensionType = "feature"
	DimensionTypeBugfix      DimensionType = "bugfix"
	DimensionTypeHotfix      DimensionType = "hotfix"
	DimensionTypeExperiment  DimensionType = "experiment"
	DimensionTypeRefactor    DimensionType = "refactor"
	DimensionTypeDocumentation DimensionType = "documentation"
	DimensionTypePerformance DimensionType = "performance"
	DimensionTypeSecurity    DimensionType = "security"
)

type BranchTag struct {
	Key       string    `json:"key" yaml:"key"`
	Value     string    `json:"value" yaml:"value"`
	Category  string    `json:"category" yaml:"category"`
	CreatedAt time.Time `json:"created_at" yaml:"created_at"`
}

type DimensionQuery struct {
	Dimensions []BranchDimension `json:"dimensions" yaml:"dimensions"`
	Tags       []BranchTag       `json:"tags,omitempty" yaml:"tags,omitempty"`
	Operator   QueryOperator     `json:"operator" yaml:"operator"`
	Limit      int               `json:"limit,omitempty" yaml:"limit,omitempty"`
}

type QueryOperator string

const (
	QueryOperatorAND QueryOperator = "AND"
	QueryOperatorOR  QueryOperator = "OR"
	QueryOperatorNOT QueryOperator = "NOT"
)

// Level 4: Contextual Memory Integration structures
type MemoryContext struct {
	ContextID   string                 `json:"context_id" yaml:"context_id"`
	Type        MemoryContextType      `json:"type" yaml:"type"`
	Content     map[string]interface{} `json:"content" yaml:"content"`
	Associations []string              `json:"associations,omitempty" yaml:"associations,omitempty"`
	CreatedAt   time.Time             `json:"created_at" yaml:"created_at"`
}

type MemoryContextType string

const (
	MemoryContextTypeCode        MemoryContextType = "code"
	MemoryContextTypeDocumentation MemoryContextType = "documentation"
	MemoryContextTypeDecision    MemoryContextType = "decision"
	MemoryContextTypePattern     MemoryContextType = "pattern"
	MemoryContextTypeIssue       MemoryContextType = "issue"
)

type Documentation struct {
	ID          string                 `json:"id" yaml:"id"`
	BranchID    string                 `json:"branch_id" yaml:"branch_id"`
	Content     string                 `json:"content" yaml:"content"`
	Type        DocumentationType      `json:"type" yaml:"type"`
	GeneratedAt time.Time             `json:"generated_at" yaml:"generated_at"`
	Metadata    map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
}

type DocumentationType string

const (
	DocumentationTypeAutoGenerated DocumentationType = "auto_generated"
	DocumentationTypeUserProvided   DocumentationType = "user_provided"
	DocumentationTypeAISuggested    DocumentationType = "ai_suggested"
)

// Level 5: Temporal Branching structures
type TemporalSnapshot struct {
	ID          string                 `json:"id" yaml:"id"`
	BranchID    string                 `json:"branch_id" yaml:"branch_id"`
	Timestamp   time.Time             `json:"timestamp" yaml:"timestamp"`
	CommitHash  string                 `json:"commit_hash" yaml:"commit_hash"`
	State       map[string]interface{} `json:"state" yaml:"state"`
	Metadata    map[string]string     `json:"metadata" yaml:"metadata"`
	CreatedAt   time.Time             `json:"created_at" yaml:"created_at"`
}

type TimeRange struct {
	Start time.Time `json:"start" yaml:"start"`
	End   time.Time `json:"end" yaml:"end"`
}

// Level 6: Predictive Branching structures
type BranchingIntent struct {
	Goal        string                 `json:"goal" yaml:"goal"`
	Context     map[string]interface{} `json:"context" yaml:"context"`
	Constraints []string               `json:"constraints,omitempty" yaml:"constraints,omitempty"`
	Priority    IntentPriority         `json:"priority" yaml:"priority"`
	Deadline    *time.Time            `json:"deadline,omitempty" yaml:"deadline,omitempty"`
}

type IntentPriority int

const (
	IntentPriorityLow    IntentPriority = 1
	IntentPriorityMedium IntentPriority = 2
	IntentPriorityHigh   IntentPriority = 3
	IntentPriorityUrgent IntentPriority = 4
)

type PredictedBranch struct {
	RecommendedName   string             `json:"recommended_name" yaml:"recommended_name"`
	BaseBranch        string             `json:"base_branch" yaml:"base_branch"`
	Confidence        float64            `json:"confidence" yaml:"confidence"`
	Reasoning         string             `json:"reasoning" yaml:"reasoning"`
	EstimatedDuration time.Duration      `json:"estimated_duration" yaml:"estimated_duration"`
	SuggestedTags     []BranchTag        `json:"suggested_tags,omitempty" yaml:"suggested_tags,omitempty"`
	Risks             []string           `json:"risks,omitempty" yaml:"risks,omitempty"`
}

type BranchingAnalysis struct {
	ProjectID          string                 `json:"project_id" yaml:"project_id"`
	AnalyzedPeriod     TimeRange             `json:"analyzed_period" yaml:"analyzed_period"`
	Patterns           []BranchingPattern    `json:"patterns" yaml:"patterns"`
	Recommendations    []string              `json:"recommendations" yaml:"recommendations"`
	EfficiencyScore    float64               `json:"efficiency_score" yaml:"efficiency_score"`
	GeneratedAt        time.Time             `json:"generated_at" yaml:"generated_at"`
}

type BranchingPattern struct {
	Type        PatternType `json:"type" yaml:"type"`
	Frequency   int         `json:"frequency" yaml:"frequency"`
	Description string      `json:"description" yaml:"description"`
	Impact      float64     `json:"impact" yaml:"impact"`
}

type PatternType string

const (
	PatternTypeNaming       PatternType = "naming"
	PatternTypeTiming       PatternType = "timing"
	PatternTypeMerging      PatternType = "merging"
	PatternTypeConflicts    PatternType = "conflicts"
	PatternTypeDuration     PatternType = "duration"
	PatternTypeLifecycle    PatternType = "lifecycle"
	PatternTypeMerge        PatternType = "merge"
	PatternTypeCollaboration PatternType = "collaboration"
)

type BranchingStrategy struct {
	Name        string                 `json:"name" yaml:"name"`
	Rules       []BranchingRule        `json:"rules" yaml:"rules"`
	Parameters  map[string]interface{} `json:"parameters" yaml:"parameters"`
	CreatedAt   time.Time             `json:"created_at" yaml:"created_at"`
	UpdatedAt   time.Time             `json:"updated_at" yaml:"updated_at"`
}

type BranchingRule struct {
	Condition string `json:"condition" yaml:"condition"`
	Action    string `json:"action" yaml:"action"`
	Priority  int    `json:"priority" yaml:"priority"`
}

type OptimizedStrategy struct {
	OriginalStrategy  BranchingStrategy `json:"original_strategy" yaml:"original_strategy"`
	OptimizedStrategy BranchingStrategy `json:"optimized_strategy" yaml:"optimized_strategy"`
	Improvements      []string          `json:"improvements" yaml:"improvements"`
	ExpectedBenefits  []string          `json:"expected_benefits" yaml:"expected_benefits"`
	ConfidenceScore   float64           `json:"confidence_score" yaml:"confidence_score"`
}

// Level 7: Branching as Code structures
type BranchingCode struct {
	Code        string                 `json:"code" yaml:"code"`
	Language    CodeLanguage           `json:"language" yaml:"language"`
	Version     string                 `json:"version" yaml:"version"`
	Parameters  map[string]interface{} `json:"parameters,omitempty" yaml:"parameters,omitempty"`
	Metadata    map[string]string     `json:"metadata,omitempty" yaml:"metadata,omitempty"`
	CreatedAt   time.Time             `json:"created_at" yaml:"created_at"`
}

type CodeLanguage string

const (
	CodeLanguageYAML CodeLanguage = "yaml"
	CodeLanguageJSON CodeLanguage = "json"
	CodeLanguageGo   CodeLanguage = "go"
	CodeLanguageLua  CodeLanguage = "lua"
)

type ExecutionResult struct {
	Success     bool                   `json:"success" yaml:"success"`
	CreatedBranches []string           `json:"created_branches,omitempty" yaml:"created_branches,omitempty"`
	Errors      []string               `json:"errors,omitempty" yaml:"errors,omitempty"`
	Output      map[string]interface{} `json:"output,omitempty" yaml:"output,omitempty"`
	ExecutedAt  time.Time             `json:"executed_at" yaml:"executed_at"`
	Duration    time.Duration         `json:"duration" yaml:"duration"`
}

type ValidationResult struct {
	Valid       bool     `json:"valid" yaml:"valid"`
	Errors      []string `json:"errors,omitempty" yaml:"errors,omitempty"`
	Warnings    []string `json:"warnings,omitempty" yaml:"warnings,omitempty"`
	ValidatedAt time.Time `json:"validated_at" yaml:"validated_at"`
}

// Level 8: Quantum Branching structures
type DevelopmentApproach struct {
	ID          string                 `json:"id" yaml:"id"`
	Name        string                 `json:"name" yaml:"name"`
	Description string                 `json:"description" yaml:"description"`
	Strategy    string                 `json:"strategy" yaml:"strategy"`
	Parameters  map[string]interface{} `json:"parameters" yaml:"parameters"`
	Weight      float64                `json:"weight" yaml:"weight"`
}

type QuantumBranch struct {
	ID         string                `json:"id" yaml:"id"`
	Name       string                `json:"name" yaml:"name"`
	Approaches []DevelopmentApproach `json:"approaches" yaml:"approaches"`
	Status     QuantumStatus         `json:"status" yaml:"status"`
	CreatedAt  time.Time            `json:"created_at" yaml:"created_at"`
	UpdatedAt  time.Time            `json:"updated_at" yaml:"updated_at"`
}

type QuantumStatus string

const (
	QuantumStatusPending    QuantumStatus = "pending"
	QuantumStatusExecuting  QuantumStatus = "executing"
	QuantumStatusCompleted  QuantumStatus = "completed"
	QuantumStatusFailed     QuantumStatus = "failed"
	QuantumStatusOptimized  QuantumStatus = "optimized"
)

type ApproachResult struct {
	ApproachID   string                 `json:"approach_id" yaml:"approach_id"`
	BranchID     string                 `json:"branch_id" yaml:"branch_id"`
	Success      bool                   `json:"success" yaml:"success"`
	Score        float64                `json:"score" yaml:"score"`
	Metrics      map[string]float64     `json:"metrics" yaml:"metrics"`
	Output       map[string]interface{} `json:"output,omitempty" yaml:"output,omitempty"`
	Errors       []string               `json:"errors,omitempty" yaml:"errors,omitempty"`
	CompletedAt  time.Time             `json:"completed_at" yaml:"completed_at"`
	Duration     time.Duration         `json:"duration" yaml:"duration"`
}

// PatternSimilarity represents similarity between branching patterns
type PatternSimilarity struct {
	PatternID          string                 `json:"pattern_id" yaml:"pattern_id"`
	ProjectID          string                 `json:"project_id" yaml:"project_id"`
	Score              float64                `json:"score" yaml:"score"`                      // Similarity score (0.0 - 1.0)
	Pattern            *BranchingPattern      `json:"pattern" yaml:"pattern"`
	ContextSimilarity  float64                `json:"context_similarity" yaml:"context_similarity"`   // Context match score
	MetricsSimilarity  float64                `json:"metrics_similarity" yaml:"metrics_similarity"`   // Performance metrics similarity
	TimingSimilarity   float64                `json:"timing_similarity" yaml:"timing_similarity"`     // Time-based similarity
	Metadata           map[string]interface{} `json:"metadata,omitempty" yaml:"metadata,omitempty"`
	FoundAt            time.Time             `json:"found_at" yaml:"found_at"`
	DistanceMetrics    map[string]float64     `json:"distance_metrics" yaml:"distance_metrics"`       // Various distance measurements
}
