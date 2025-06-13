// Package tests contains test stubs
package tests

import (
	"time"
)

// Mock for the validator function
func (cv *ConsistencyValidator) ValidatePlan(planPath string) (*ValidationResult, error) {
	return &ValidationResult{
		TestName:    "ValidatePlan",
		Success:     true,
		TotalTests:  5,
		PassedTests: 5,
		FailedTests: 0,
		Score:       1.0,
		Duration:    100 * time.Millisecond,
		Issues:      nil,
	}, nil
}

// Mock for the resolver function (commented out to avoid duplicate declaration)
// Replaced by the implementation in fix_validation_test.go
/*
func (ar *AutoResolver) AutoFixIssues(planPath string, issues []string) (string, error) {
	// Return a fixed plan path and no error
	return planPath, nil
}
*/

// Implementations moved to resolution_utils.go

// Info adds Info logging method to Logger
func (l *Logger) Info(format string, args ...interface{}) {
	l.Printf(format, args...)
}

// ResolutionStrategy represents a conflict resolution strategy
type ResolutionStrategy interface {
	Resolve(conflict *Conflict) (*ConflictResolution, error)
	Name() string
}

// MockTaskChange represents a mock task change for testing
type MockTaskChange struct {
	Status    string
	Timestamp time.Time
}

// MetadataChange represents a metadata change
type MetadataChange struct {
	Source   string
	Priority string
}

// TimestampBasedStrategy represents a timestamp-based resolution strategy
type TimestampBasedStrategy struct{}

// NewTimestampBasedStrategy creates a new timestamp-based strategy
func NewTimestampBasedStrategy() *TimestampBasedStrategy {
	return &TimestampBasedStrategy{}
}

// Resolve resolves a conflict based on timestamps
func (s *TimestampBasedStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error) {
	return &ConflictResolution{
		ConflictID:     conflict.ID,
		ResolutionType: "auto",
		Success:        true,
		Error:          "",
	}, nil
}

// Name returns the strategy name
func (s *TimestampBasedStrategy) Name() string {
	return "timestamp"
}

// PriorityBasedStrategy represents a priority-based resolution strategy
type PriorityBasedStrategy struct{}

// NewPriorityBasedStrategy creates a new priority-based strategy
func NewPriorityBasedStrategy() *PriorityBasedStrategy {
	return &PriorityBasedStrategy{}
}

// Resolve resolves a conflict based on priority
func (s *PriorityBasedStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error) {
	return &ConflictResolution{
		ConflictID:     conflict.ID,
		ResolutionType: "auto",
		Success:        true,
		Error:          "",
	}, nil
}

// Name returns the strategy name
func (s *PriorityBasedStrategy) Name() string {
	return "priority"
}
