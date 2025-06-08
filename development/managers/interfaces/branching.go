package interfaces

import (
	"context"
	"time"
)

// BranchingManager defines the interface for the ultra-advanced 8-level branching framework
type BranchingManager interface {
	BaseManager

	// Level 1: Micro-Sessions Temporelles (30min timestamped sessions)
	CreateSession(ctx context.Context, config SessionConfig) (*Session, error)
	EndSession(ctx context.Context, sessionID string) error
	GetSessionHistory(ctx context.Context, filters SessionFilters) ([]*Session, error)
	GetActiveSession(ctx context.Context) (*Session, error)

	// Level 2: Event-Driven Branching (automatic triggers)
	TriggerBranchCreation(ctx context.Context, event BranchingEvent) (*Branch, error)
	ProcessGitHook(ctx context.Context, hookType string, payload map[string]interface{}) error
	HandleEventDriven(ctx context.Context, eventType string, context map[string]interface{}) error

	// Level 3: Multi-Dimensional Branching (tags/classifications)
	CreateMultiDimBranch(ctx context.Context, dimensions []BranchDimension) (*Branch, error)
	TagBranch(ctx context.Context, branchID string, tags []BranchTag) error
	SearchBranchesByDimensions(ctx context.Context, query DimensionQuery) ([]*Branch, error)

	// Level 4: Contextual Memory Integration (auto-documentation)
	IntegrateContextualMemory(ctx context.Context, branchID string, memoryContext MemoryContext) error
	GenerateAutoDocumentation(ctx context.Context, branchID string) (*Documentation, error)
	LinkBranchToContext(ctx context.Context, branchID string, contextID string) error

	// Level 5: Temporal Branching & Time-Travel (hourly snapshots)
	CreateTemporalSnapshot(ctx context.Context, branchID string) (*TemporalSnapshot, error)
	TimeTravelToBranch(ctx context.Context, snapshotID string, targetTime time.Time) error
	GetTemporalHistory(ctx context.Context, branchID string, timeRange TimeRange) ([]*TemporalSnapshot, error)

	// Level 6: Predictive Branching (AI-powered optimization)
	PredictOptimalBranch(ctx context.Context, intent BranchingIntent) (*PredictedBranch, error)
	AnalyzeBranchingPatterns(ctx context.Context, projectID string) (*BranchingAnalysis, error)
	OptimizeBranchingStrategy(ctx context.Context, currentStrategy BranchingStrategy) (*OptimizedStrategy, error)

	// Level 7: Branching as Code (declarative configuration)
	ExecuteBranchingCode(ctx context.Context, code BranchingCode) (*ExecutionResult, error)
	ValidateBranchingCode(ctx context.Context, code BranchingCode) (*ValidationResult, error)
	GenerateBranchingCode(ctx context.Context, fromBranches []string) (*BranchingCode, error)

	// Level 8: Quantum Branching (parallel development approaches)
	CreateQuantumBranch(ctx context.Context, approaches []DevelopmentApproach) (*QuantumBranch, error)
	ExecuteParallelApproaches(ctx context.Context, quantumBranchID string) ([]*ApproachResult, error)
	SelectOptimalApproach(ctx context.Context, results []*ApproachResult) (*ApproachResult, error)

	// Integration methods
	IntegrateWithStorageManager(ctx context.Context, storageManager StorageManager) error
	IntegrateWithErrorManager(ctx context.Context, errorManager ErrorManager) error
	IntegrateWithContextualMemory(ctx context.Context, memoryManager ContextualMemoryManager) error
}
