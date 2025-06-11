// Package validation provides validation rules for planning ecosystem consistency
package validation

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
	"crypto/sha256"
	"encoding/hex"
)

// MetadataRule validates metadata consistency between Markdown and dynamic plans
type MetadataRule struct {
	name        string
	description string
	severity    ValidationSeverity
}

// NewMetadataRule creates a new metadata validation rule
func NewMetadataRule() *MetadataRule {
	return &MetadataRule{
		name:        "metadata_consistency",
		description: "Validates consistency of plan metadata (version, progression, dates)",
		severity:    SeverityError,
	}
}

func (mr *MetadataRule) Name() string        { return mr.name }
func (mr *MetadataRule) Description() string { return mr.description }
func (mr *MetadataRule) Severity() ValidationSeverity { return mr.severity }
func (mr *MetadataRule) CanAutoFix() bool    { return true }

func (mr *MetadataRule) Validate(ctx context.Context, planID string, data interface{}) ([]ValidationIssue, error) {
	var issues []ValidationIssue
	
	// Mock data structure for testing - in real implementation this would connect to actual data sources
	markdownMetadata := map[string]interface{}{
		"version":     "v55",
		"progression": 90.0,
		"date":        "2025-06-11",
		"title":       "Plan de développement v55",
	}
	
	dynamicMetadata := map[string]interface{}{
		"version":     "v55",
		"progression": 85.0, // Intentional mismatch for demonstration
		"date":        "2025-06-11",
		"title":       "Plan de développement v55",
	}
	
	// Validate version consistency
	if markdownMetadata["version"] != dynamicMetadata["version"] {
		issues = append(issues, ValidationIssue{
			ID:          generateIssueID("metadata", "version", planID),
			Type:        "metadata_version_mismatch",
			Severity:    mr.severity,
			Message:     fmt.Sprintf("Version mismatch: Markdown=%s, Dynamic=%s", markdownMetadata["version"], dynamicMetadata["version"]),
			Location:    "plan_metadata.version",
			Suggestion:  "Synchronize version numbers between Markdown and dynamic systems",
			AutoFixable: true,
			RuleName:    mr.name,
			Timestamp:   time.Now(),
		})
	}
	
	// Validate progression consistency (with tolerance)
	markdownProg, ok1 := markdownMetadata["progression"].(float64)
	dynamicProg, ok2 := dynamicMetadata["progression"].(float64)
	
	if ok1 && ok2 {
		tolerance := 5.0 // 5% tolerance
		if abs(markdownProg-dynamicProg) > tolerance {
			issues = append(issues, ValidationIssue{
				ID:          generateIssueID("metadata", "progression", planID),
				Type:        "metadata_progression_mismatch",
				Severity:    SeverityWarning,
				Message:     fmt.Sprintf("Progression mismatch beyond tolerance: Markdown=%.1f%%, Dynamic=%.1f%%, Difference=%.1f%%", markdownProg, dynamicProg, abs(markdownProg-dynamicProg)),
				Location:    "plan_metadata.progression",
				Suggestion:  "Recalculate progression or synchronize between systems",
				AutoFixable: true,
				RuleName:    mr.name,
				Timestamp:   time.Now(),
			})
		}
	}
	
	return issues, nil
}

func (mr *MetadataRule) AutoFix(ctx context.Context, issue ValidationIssue) error {
	switch issue.Type {
	case "metadata_version_mismatch":
		// Auto-fix: use the more recent version or apply priority logic
		return fmt.Errorf("auto-fix for version mismatch: use dynamic version as source of truth")
	case "metadata_progression_mismatch":
		// Auto-fix: recalculate progression based on actual task completion
		return fmt.Errorf("auto-fix for progression mismatch: recalculate based on task completion")
	default:
		return fmt.Errorf("unknown issue type for auto-fix: %s", issue.Type)
	}
}

// TaskRule validates task consistency between Markdown and dynamic plans
type TaskRule struct {
	name        string
	description string
	severity    ValidationSeverity
}

// NewTaskRule creates a new task validation rule
func NewTaskRule() *TaskRule {
	return &TaskRule{
		name:        "task_consistency",
		description: "Validates task status and content consistency",
		severity:    SeverityError,
	}
}

func (tr *TaskRule) Name() string        { return tr.name }
func (tr *TaskRule) Description() string { return tr.description }
func (tr *TaskRule) Severity() ValidationSeverity { return tr.severity }
func (tr *TaskRule) CanAutoFix() bool    { return true }

func (tr *TaskRule) Validate(ctx context.Context, planID string, data interface{}) ([]ValidationIssue, error) {
	var issues []ValidationIssue
	
	// Mock task data for demonstration
	markdownTasks := []map[string]interface{}{
		{"id": "task_1", "title": "Implement feature A", "completed": true, "phase": "Phase 1"},
		{"id": "task_2", "title": "Write tests for feature A", "completed": false, "phase": "Phase 1"},
		{"id": "task_3", "title": "Deploy feature A", "completed": false, "phase": "Phase 2"},
	}
	
	dynamicTasks := []map[string]interface{}{
		{"id": "task_1", "title": "Implement feature A", "completed": true, "phase": "Phase 1"},
		{"id": "task_2", "title": "Write tests for feature A", "completed": true, "phase": "Phase 1"}, // Status mismatch
		{"id": "task_3", "title": "Deploy feature A", "completed": false, "phase": "Phase 2"},
		{"id": "task_4", "title": "New task from dynamic", "completed": false, "phase": "Phase 2"}, // Missing in Markdown
	}
	
	// Create maps for easier comparison
	markdownTaskMap := make(map[string]map[string]interface{})
	for _, task := range markdownTasks {
		if id, ok := task["id"].(string); ok {
			markdownTaskMap[id] = task
		}
	}
	
	dynamicTaskMap := make(map[string]map[string]interface{})
	for _, task := range dynamicTasks {
		if id, ok := task["id"].(string); ok {
			dynamicTaskMap[id] = task
		}
	}
	
	// Check for status mismatches
	for id, markdownTask := range markdownTaskMap {
		if dynamicTask, exists := dynamicTaskMap[id]; exists {
			markdownCompleted := markdownTask["completed"].(bool)
			dynamicCompleted := dynamicTask["completed"].(bool)
			
			if markdownCompleted != dynamicCompleted {
				issues = append(issues, ValidationIssue{
					ID:          generateIssueID("task", "status", id),
					Type:        "task_status_mismatch",
					Severity:    tr.severity,
					Message:     fmt.Sprintf("Task status mismatch for '%s': Markdown=%t, Dynamic=%t", markdownTask["title"], markdownCompleted, dynamicCompleted),
					Location:    fmt.Sprintf("task.%s.completed", id),
					Suggestion:  "Synchronize task completion status between systems",
					AutoFixable: true,
					RuleName:    tr.name,
					Timestamp:   time.Now(),
					Context: map[string]interface{}{
						"task_id":            id,
						"task_title":         markdownTask["title"],
						"markdown_completed": markdownCompleted,
						"dynamic_completed":  dynamicCompleted,
					},
				})
			}
		}
	}
	
	// Check for missing tasks
	for id, dynamicTask := range dynamicTaskMap {
		if _, exists := markdownTaskMap[id]; !exists {
			issues = append(issues, ValidationIssue{
				ID:          generateIssueID("task", "missing", id),
				Type:        "task_missing_in_markdown",
				Severity:    SeverityWarning,
				Message:     fmt.Sprintf("Task '%s' exists in dynamic system but missing in Markdown", dynamicTask["title"]),
				Location:    fmt.Sprintf("markdown_plan.tasks"),
				Suggestion:  "Add missing task to Markdown plan or remove from dynamic system",
				AutoFixable: true,
				RuleName:    tr.name,
				Timestamp:   time.Now(),
				Context: map[string]interface{}{
					"task_id":    id,
					"task_title": dynamicTask["title"],
					"phase":      dynamicTask["phase"],
				},
			})
		}
	}
	
	return issues, nil
}

func (tr *TaskRule) AutoFix(ctx context.Context, issue ValidationIssue) error {
	switch issue.Type {
	case "task_status_mismatch":
		// Auto-fix: use dynamic system as source of truth for task status
		return fmt.Errorf("auto-fix task status: sync from dynamic to markdown")
	case "task_missing_in_markdown":
		// Auto-fix: add missing task to markdown
		return fmt.Errorf("auto-fix missing task: add to markdown plan")
	default:
		return fmt.Errorf("unknown issue type for auto-fix: %s", issue.Type)
	}
}

// StructureRule validates structural consistency of plans
type StructureRule struct {
	name        string
	description string
	severity    ValidationSeverity
}

// NewStructureRule creates a new structure validation rule
func NewStructureRule() *StructureRule {
	return &StructureRule{
		name:        "structure_consistency",
		description: "Validates plan structure consistency (phases, sections, hierarchy)",
		severity:    SeverityError,
	}
}

func (sr *StructureRule) Name() string        { return sr.name }
func (sr *StructureRule) Description() string { return sr.description }
func (sr *StructureRule) Severity() ValidationSeverity { return sr.severity }
func (sr *StructureRule) CanAutoFix() bool    { return false } // Structure changes are complex, require manual review

func (sr *StructureRule) Validate(ctx context.Context, planID string, data interface{}) ([]ValidationIssue, error) {
	var issues []ValidationIssue
	
	// Mock structure data
	markdownStructure := map[string]interface{}{
		"phases": []string{"Phase 1", "Phase 2", "Phase 3"},
		"sections_per_phase": map[string]int{
			"Phase 1": 3,
			"Phase 2": 4,
			"Phase 3": 2,
		},
	}
	
	dynamicStructure := map[string]interface{}{
		"phases": []string{"Phase 1", "Phase 2", "Phase 3", "Phase 4"}, // Extra phase
		"sections_per_phase": map[string]int{
			"Phase 1": 3,
			"Phase 2": 4,
			"Phase 3": 2,
			"Phase 4": 1,
		},
	}
	
	// Check phase consistency
	markdownPhases := markdownStructure["phases"].([]string)
	dynamicPhases := dynamicStructure["phases"].([]string)
	
	if len(markdownPhases) != len(dynamicPhases) {
		issues = append(issues, ValidationIssue{
			ID:          generateIssueID("structure", "phases", planID),
			Type:        "structure_phase_count_mismatch",
			Severity:    sr.severity,
			Message:     fmt.Sprintf("Phase count mismatch: Markdown=%d, Dynamic=%d", len(markdownPhases), len(dynamicPhases)),
			Location:    "plan_structure.phases",
			Suggestion:  "Synchronize phase structure between Markdown and dynamic systems",
			AutoFixable: false,
			RuleName:    sr.name,
			Timestamp:   time.Now(),
			Context: map[string]interface{}{
				"markdown_phases": markdownPhases,
				"dynamic_phases":  dynamicPhases,
			},
		})
	}
	
	// Check for missing phases
	markdownPhaseSet := make(map[string]bool)
	for _, phase := range markdownPhases {
		markdownPhaseSet[phase] = true
	}
	
	for _, phase := range dynamicPhases {
		if !markdownPhaseSet[phase] {
			issues = append(issues, ValidationIssue{
				ID:          generateIssueID("structure", "phase_missing", phase),
				Type:        "structure_phase_missing_in_markdown",
				Severity:    SeverityWarning,
				Message:     fmt.Sprintf("Phase '%s' exists in dynamic system but missing in Markdown", phase),
				Location:    "plan_structure.phases",
				Suggestion:  fmt.Sprintf("Add phase '%s' to Markdown plan or remove from dynamic system", phase),
				AutoFixable: false,
				RuleName:    sr.name,
				Timestamp:   time.Now(),
				Context: map[string]interface{}{
					"missing_phase": phase,
				},
			})
		}
	}
	
	return issues, nil
}

func (sr *StructureRule) AutoFix(ctx context.Context, issue ValidationIssue) error {
	// Structure rules don't support auto-fix due to complexity
	return fmt.Errorf("structure issues require manual review and cannot be auto-fixed")
}

// ContentIntegrityRule validates content integrity using checksums
type ContentIntegrityRule struct {
	name        string
	description string
	severity    ValidationSeverity
}

// NewContentIntegrityRule creates a new content integrity validation rule
func NewContentIntegrityRule() *ContentIntegrityRule {
	return &ContentIntegrityRule{
		name:        "content_integrity",
		description: "Validates content integrity using checksums and hashes",
		severity:    SeverityCritical,
	}
}

func (cir *ContentIntegrityRule) Name() string        { return cir.name }
func (cir *ContentIntegrityRule) Description() string { return cir.description }
func (cir *ContentIntegrityRule) Severity() ValidationSeverity { return cir.severity }
func (cir *ContentIntegrityRule) CanAutoFix() bool    { return false } // Content corruption requires manual investigation

func (cir *ContentIntegrityRule) Validate(ctx context.Context, planID string, data interface{}) ([]ValidationIssue, error) {
	var issues []ValidationIssue
	
	// Mock content data with checksums
	markdownContent := "# Plan de développement v55\n\n## Phase 1\n- [x] Task 1\n- [ ] Task 2\n"
	dynamicContent := "# Plan de développement v55\n\n## Phase 1\n- [x] Task 1\n- [x] Task 2\n" // Different content
	
	markdownHash := calculateSHA256(markdownContent)
	dynamicHash := calculateSHA256(dynamicContent)
	
	if markdownHash != dynamicHash {
		issues = append(issues, ValidationIssue{
			ID:          generateIssueID("content", "integrity", planID),
			Type:        "content_integrity_mismatch",
			Severity:    cir.severity,
			Message:     "Content integrity check failed - checksums don't match between Markdown and dynamic content",
			Location:    "plan_content",
			Suggestion:  "Investigate content differences and synchronize systems",
			AutoFixable: false,
			RuleName:    cir.name,
			Timestamp:   time.Now(),
			Context: map[string]interface{}{
				"markdown_hash": markdownHash,
				"dynamic_hash":  dynamicHash,
				"content_size_markdown": len(markdownContent),
				"content_size_dynamic":  len(dynamicContent),
			},
		})
	}
	
	return issues, nil
}

func (cir *ContentIntegrityRule) AutoFix(ctx context.Context, issue ValidationIssue) error {
	// Content integrity issues require manual investigation
	return fmt.Errorf("content integrity issues require manual investigation and cannot be auto-fixed")
}

// Helper functions

// generateIssueID generates a unique ID for validation issues
func generateIssueID(category, issueType, identifier string) string {
	timestamp := time.Now().Unix()
	raw := fmt.Sprintf("%s_%s_%s_%d", category, issueType, identifier, timestamp)
	hash := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(hash[:])[:16] // Use first 16 characters
}

// calculateSHA256 calculates SHA256 hash of content
func calculateSHA256(content string) string {
	hash := sha256.Sum256([]byte(content))
	return hex.EncodeToString(hash[:])
}

// abs returns absolute value of float64
func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}

// ValidationRuleFactory creates validation rules based on configuration
type ValidationRuleFactory struct{}

// NewValidationRuleFactory creates a new validation rule factory
func NewValidationRuleFactory() *ValidationRuleFactory {
	return &ValidationRuleFactory{}
}

// CreateRule creates a validation rule by name
func (vrf *ValidationRuleFactory) CreateRule(ruleName string) (ValidationRule, error) {
	switch strings.ToLower(ruleName) {
	case "metadata", "metadata_consistency":
		return NewMetadataRule(), nil
	case "task", "task_consistency":
		return NewTaskRule(), nil
	case "structure", "structure_consistency":
		return NewStructureRule(), nil
	case "content", "content_integrity":
		return NewContentIntegrityRule(), nil
	default:
		return nil, fmt.Errorf("unknown validation rule: %s", ruleName)
	}
}

// GetAvailableRules returns a list of available validation rules
func (vrf *ValidationRuleFactory) GetAvailableRules() []string {
	return []string{
		"metadata_consistency",
		"task_consistency",
		"structure_consistency",
		"content_integrity",
	}
}

// CreateDefaultRules creates a set of default validation rules
func (vrf *ValidationRuleFactory) CreateDefaultRules() []ValidationRule {
	return []ValidationRule{
		NewMetadataRule(),
		NewTaskRule(),
		NewStructureRule(),
		NewContentIntegrityRule(),
	}
}
