package validation

import (
	"context"
	"fmt"
	"time"
)

// FormatConsistencyRule validates format-specific requirements
type FormatConsistencyRule struct {
	ID          string
	Name        string
	Description string
	Severity    string
}

// NewFormatConsistencyRule creates a new format consistency rule
func NewFormatConsistencyRule() *FormatConsistencyRule {
	return &FormatConsistencyRule{
		ID:          "format-consistency",
		Name:        "Format Consistency",
		Description: "Validates format-specific requirements for planning documents",
		Severity:    "error",
	}
}

// ValidateMetadata validates the metadata section of a plan document
func (r *FormatConsistencyRule) ValidateMetadata(metadata *PlanMetadata) []ValidationIssue {
	var issues []ValidationIssue

	// Required fields
	if metadata.Title == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Metadata title is required",
			Location: "metadata.title",
			RuleID:   r.ID,
		})
	}

	if metadata.Version == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Metadata version is required",
			Location: "metadata.version",
			RuleID:   r.ID,
		})
	}

	if metadata.Author == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Metadata author is required",
			Location: "metadata.author",
			RuleID:   r.ID,
		})
	}
	// Validate date formats
	if metadata.Created != "" {
		if !isValidDateFormat(metadata.Created) {
			issues = append(issues, ValidationIssue{
				Type:     "error",
				Message:  "Created date must be in ISO 8601 format (YYYY-MM-DD)",
				Location: "metadata.created",
				RuleID:   r.ID,
			})
		}
	}

	if metadata.Updated != "" {
		if !isValidDateFormat(metadata.Updated) {
			issues = append(issues, ValidationIssue{
				Type:     "error",
				Message:  "Updated date must be in ISO 8601 format (YYYY-MM-DD)",
				Location: "metadata.updated",
				RuleID:   r.ID,
			})
		}
	}

	// Validate status
	validStatuses := []string{"active", "inactive", "completed", "cancelled", "draft"}
	if metadata.Status != "" && !contains(validStatuses, metadata.Status) {
		issues = append(issues, ValidationIssue{
			Type:     "warning",
			Message:  fmt.Sprintf("Status '%s' is not a standard value. Expected one of: %v", metadata.Status, validStatuses),
			Location: "metadata.status",
			RuleID:   r.ID,
		})
	}

	// Validate priority
	validPriorities := []string{"low", "medium", "high", "critical"}
	if metadata.Priority != "" && !contains(validPriorities, metadata.Priority) {
		issues = append(issues, ValidationIssue{
			Type:     "warning",
			Message:  fmt.Sprintf("Priority '%s' is not a standard value. Expected one of: %v", metadata.Priority, validPriorities),
			Location: "metadata.priority",
			RuleID:   r.ID,
		})
	}

	return issues
}

// ValidatePhases validates all phases in a plan document
func (r *FormatConsistencyRule) ValidatePhases(phases []Phase) []ValidationIssue {
	var issues []ValidationIssue

	if len(phases) == 0 {
		issues = append(issues, ValidationIssue{
			Type:     "warning",
			Message:  "Plan document should contain at least one phase",
			Location: "phases",
			RuleID:   r.ID,
		})
		return issues
	}

	for i, phase := range phases {
		location := fmt.Sprintf("phases[%d]", i)
		issues = append(issues, r.validatePhase(&phase, location)...)
	}

	return issues
}

// validatePhase validates a single phase
func (r *FormatConsistencyRule) validatePhase(phase *Phase, location string) []ValidationIssue {
	var issues []ValidationIssue

	// Required fields
	if phase.ID == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Phase ID is required",
			Location: location + ".id",
			RuleID:   r.ID,
		})
	}

	if phase.Name == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Phase name is required",
			Location: location + ".name",
			RuleID:   r.ID,
		})
	}

	// Validate progress range
	if phase.Progress < 0 || phase.Progress > 100 {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Phase progress must be between 0 and 100",
			Location: location + ".progress",
			RuleID:   r.ID,
		})
	}

	// Validate tasks
	for j, task := range phase.Tasks {
		taskLocation := fmt.Sprintf("%s.tasks[%d]", location, j)
		issues = append(issues, r.validateTask(&task, taskLocation)...)
	}

	return issues
}

// validateTask validates a single task
func (r *FormatConsistencyRule) validateTask(task *Task, location string) []ValidationIssue {
	var issues []ValidationIssue

	// Required fields
	if task.ID == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Task ID is required",
			Location: location + ".id",
			RuleID:   r.ID,
		})
	}

	if task.Name == "" {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Task name is required",
			Location: location + ".name",
			RuleID:   r.ID,
		})
	}
	// Validate progress range
	if task.Progress < 0 || task.Progress > 100 {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Task progress must be between 0 and 100",
			Location: location + ".progress",
			RuleID:   r.ID,
		})
	}

	// Validate time tracking
	if task.EstimatedHrs < 0 {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Estimated hours cannot be negative",
			Location: location + ".estimated_hours",
			RuleID:   r.ID,
		})
	}

	if task.ActualHrs < 0 {
		issues = append(issues, ValidationIssue{
			Type:     "error",
			Message:  "Actual hours cannot be negative",
			Location: location + ".actual_hours",
			RuleID:   r.ID,
		})
	}

	// Check for time overruns
	if task.EstimatedHrs > 0 && task.ActualHrs > 0 {
		overrun := (float64(task.ActualHrs) - float64(task.EstimatedHrs)) / float64(task.EstimatedHrs) * 100
		if overrun > 20 { // 20% overrun threshold
			issues = append(issues, ValidationIssue{
				Type:     "warning",
				Message:  fmt.Sprintf("Task has significant time overrun (%.1f%% over estimate)", overrun),
				Location: location + ".actual_hours",
				RuleID:   r.ID,
			})
		}
	}

	return issues
}

// Validate implements the ValidationRule interface
func (r *FormatConsistencyRule) Validate(ctx context.Context, data interface{}) ([]ValidationIssue, error) {
	// Check if data is a PlanDocument
	planDoc, ok := data.(*PlanDocument)
	if !ok {
		return nil, fmt.Errorf("FormatConsistencyRule can only validate PlanDocument objects")
	}

	var allIssues []ValidationIssue

	// Validate metadata
	allIssues = append(allIssues, r.ValidateMetadata(&planDoc.Metadata)...)

	// Validate phases
	allIssues = append(allIssues, r.ValidatePhases(planDoc.Phases)...)

	return allIssues, nil
}

// GetID returns the rule ID
func (r *FormatConsistencyRule) GetID() string {
	return r.ID
}

// GetName returns the rule name
func (r *FormatConsistencyRule) GetName() string {
	return r.Name
}

// GetDescription returns the rule description
func (r *FormatConsistencyRule) GetDescription() string {
	return r.Description
}

// GetSeverity returns the rule severity
func (r *FormatConsistencyRule) GetSeverity() string {
	return r.Severity
}

// Helper functions

// isValidDateFormat validates ISO 8601 date format (YYYY-MM-DD)
func isValidDateFormat(date string) bool {
	_, err := time.Parse("2006-01-02", date)
	return err == nil
}

// contains checks if a slice contains a specific string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
