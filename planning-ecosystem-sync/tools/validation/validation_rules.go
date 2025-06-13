package validation

import (
	"context"
)

// ValidationRules defines the validation rules

// MetadataRule validates metadata
type MetadataRule struct {
	id          string
	description string
	priority    int
}

// NewMetadataRule creates a new metadata rule
func NewMetadataRule() *MetadataRule {
	return &MetadataRule{
		id:          "metadata",
		description: "Validates metadata fields and structures",
		priority:    5,
	}
}

// GetID returns the rule ID
func (r *MetadataRule) GetID() string {
	return r.id
}

// GetDescription returns the rule description
func (r *MetadataRule) GetDescription() string {
	return r.description
}

// GetPriority returns the rule priority
func (r *MetadataRule) GetPriority() int {
	return r.priority
}

// Using ValidationSeverity from consistency-validator.go

// Validate validates metadata
func (r *MetadataRule) Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error) {
	// This is a placeholder implementation
	if data.MarkdownPlan == nil && data.DynamicPlan == nil {
		return []ValidationIssue{{
			Type:     "error",
			Severity: SeverityCritical,
			Message:  "metadata cannot be nil",
			Location: planID,
			RuleID:   r.id,
		}}, nil
	}
	return []ValidationIssue{}, nil
}

// CanAutoFix returns whether this rule can automatically fix issues
func (r *MetadataRule) CanAutoFix() bool {
	return true
}
