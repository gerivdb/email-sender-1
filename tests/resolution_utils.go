package tests

// FixResult contains the result of auto-fixing issues
type FixResult struct {
	FixedCount int
	Issues     []string
}

// AutoFixIssuesWithCount fixes issues and returns a count of fixed issues
func (ar *AutoResolver) AutoFixIssuesWithCount(plan string, issues []string) (*FixResult, error) {
	return &FixResult{
		FixedCount: len(issues),
		Issues:     nil,
	}, nil
}

// ManualResolutionStrategy represents a manual resolution strategy
type ManualResolutionStrategy struct{}

// NewManualResolutionStrategy creates a new manual resolution strategy
func NewManualResolutionStrategy() *ManualResolutionStrategy {
	return &ManualResolutionStrategy{}
}

// Name returns the strategy name
func (s *ManualResolutionStrategy) Name() string {
	return "manual"
}

// Resolve resolves a conflict manually
func (s *ManualResolutionStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error) {
	// Accept either pointer or value
	return &ConflictResolution{
		ConflictID:     conflict.ID,
		ResolutionType: "manual",
		Success:        true,
		Error:          "",
		Action:         "keep_both",
	}, nil
}

// ResolveVal resolves a conflict manually (accepting a value)
func (s *ManualResolutionStrategy) ResolveVal(conflict Conflict) (*ConflictResolution, error) {
	return s.Resolve(&conflict)
}

// StructureChange represents a structure change
type StructureChange struct {
	Operation string
	Target    string
	Position  string
}

// GetRuleName returns the name of a ConsistencyRule
func GetRuleName(cr ConsistencyRule) string {
	return cr.Name()
}

// GetAction is a helper to get the Action field from ConflictResolution
func GetAction(cr *ConflictResolution) string {
	return cr.Action
}

// TransformConflict transforms a Conflict to a pointer if needed
func TransformConflict(conflict Conflict) *Conflict {
	return &conflict
}
