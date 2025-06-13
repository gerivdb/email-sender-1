package tests

import (
	"fmt"
)

// GetName is a compatibility method for ValidatonRule
func (rule ValidationRule) GetName() string {
	return rule.Name
}

// GetSeverity returns the severity of a ValidationRule
func (rule ValidationRule) GetSeverity() string {
	return rule.Severity
}

// GetDescription returns the description of a ValidationRule
func (rule ValidationRule) GetDescription() string {
	return rule.Description
}

// GetType is a compatibility method for ConflictType
func (ct ConflictType) GetType() string {
	return string(ct)
}

// FixResultAdapter adapts string to FixResult
type FixResultAdapter struct {
	OriginalResult string
	FixedCount     int
	Issues         []string
}

// NewFixResultAdapter creates a new FixResultAdapter from a string result
func NewFixResultAdapter(result string) *FixResultAdapter {
	return &FixResultAdapter{
		OriginalResult: result,
		FixedCount:     1, // Assuming at least one fix was applied
		Issues:         nil,
	}
}

// ConvertToFixResult converts a string to a FixResult pointer
func ConvertToFixResult(result string) *FixResult {
	return &FixResult{
		FixedCount: 1, // Assuming at least one fix was applied
		Issues:     nil,
	}
}

// String returns the string representation of a FixResult
func (fr *FixResult) String() string {
	return fmt.Sprintf("Fixed %d issues", fr.FixedCount)
}

// AddMethod adds GetName method to ConsistencyRule
func (cr *BaseConsistencyRule) GetName() string {
	return cr.Name()
}
