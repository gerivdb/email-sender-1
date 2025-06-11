package validation

import (
	"context"
	"fmt"
	"time"
)

// MetadataConsistencyRule vérifie la cohérence des métadonnées
type MetadataConsistencyRule struct {
	ID          string
	Description string
	Priority    int
}

// GetID retourne l'identifiant de la règle
func (rule *MetadataConsistencyRule) GetID() string {
	return rule.ID
}

// GetDescription retourne la description de la règle
func (rule *MetadataConsistencyRule) GetDescription() string {
	return rule.Description
}

// GetPriority retourne la priorité de la règle
func (rule *MetadataConsistencyRule) GetPriority() int {
	return rule.Priority
}

// CanAutoFix indique si la règle peut corriger automatiquement
func (rule *MetadataConsistencyRule) CanAutoFix() bool {
	return true
}

// Validate vérifie la cohérence des métadonnées
func (rule *MetadataConsistencyRule) Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error) {
	issues := []ValidationIssue{}

	// Simuler la récupération des métadonnées
	markdownMeta := rule.getMarkdownMetadata(planID)
	dynamicMeta := rule.getDynamicMetadata(planID)

	// Comparer les versions
	if markdownMeta.Version != dynamicMeta.Version {
		issues = append(issues, ValidationIssue{
			Type:        "metadata_version_mismatch",
			Severity:    SeverityWarning,
			Message:     fmt.Sprintf("Version mismatch: Markdown=%s, Dynamic=%s", markdownMeta.Version, dynamicMeta.Version),
			Location:    "plan_header",
			Suggestion:  "Synchronize version numbers between both systems",
			AutoFixable: true,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"markdown_version": markdownMeta.Version,
				"dynamic_version":  dynamicMeta.Version,
			},
		})
	} // Comparer les versions (simplified since we don't have Progression field yet)
	if markdownMeta.Version != dynamicMeta.Version {
		issues = append(issues, ValidationIssue{
			Type:        "metadata_version_mismatch",
			Severity:    SeverityWarning,
			Message:     fmt.Sprintf("Version mismatch: Markdown=%s, Dynamic=%s", markdownMeta.Version, dynamicMeta.Version),
			Location:    "plan_header",
			Suggestion:  "Synchronize version numbers between both systems",
			AutoFixable: true,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"markdown_version": markdownMeta.Version,
				"dynamic_version":  dynamicMeta.Version,
			},
		})
	}

	return issues, nil
}

// TaskConsistencyRule vérifie la cohérence des tâches et statuts
type TaskConsistencyRule struct {
	ID          string
	Description string
	Priority    int
}

func (rule *TaskConsistencyRule) GetID() string {
	return rule.ID
}

func (rule *TaskConsistencyRule) GetDescription() string {
	return rule.Description
}

func (rule *TaskConsistencyRule) GetPriority() int {
	return rule.Priority
}

func (rule *TaskConsistencyRule) CanAutoFix() bool {
	return true
}

func (rule *TaskConsistencyRule) Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error) {
	issues := []ValidationIssue{}

	// Simuler la récupération des tâches
	markdownTasks := rule.getMarkdownTasks(planID)
	dynamicTasks := rule.getDynamicTasks(planID)

	// Vérifier le nombre de tâches
	if len(markdownTasks) != len(dynamicTasks) {
		issues = append(issues, ValidationIssue{
			Type:        "task_count_mismatch",
			Severity:    SeverityError,
			Message:     fmt.Sprintf("Task count mismatch: Markdown=%d, Dynamic=%d", len(markdownTasks), len(dynamicTasks)),
			Location:    "task_lists",
			Suggestion:  "Synchronize task lists between both systems",
			AutoFixable: false,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"markdown_count": len(markdownTasks),
				"dynamic_count":  len(dynamicTasks),
			},
		})
	}

	// Vérifier les statuts des tâches
	statusMismatches := 0
	minTasks := len(markdownTasks)
	if len(dynamicTasks) < minTasks {
		minTasks = len(dynamicTasks)
	}

	for i := 0; i < minTasks; i++ {
		if markdownTasks[i].Status != dynamicTasks[i].Status {
			statusMismatches++
			if statusMismatches <= 3 { // Limite les détails à 3 pour éviter le spam
				issues = append(issues, ValidationIssue{
					Type:        "task_status_mismatch",
					Severity:    SeverityWarning,
					Message:     fmt.Sprintf("Task %d status mismatch: '%s' vs '%s'", i+1, markdownTasks[i].Status, dynamicTasks[i].Status),
					Location:    fmt.Sprintf("task_%d", i+1),
					Suggestion:  "Synchronize task status or resolve manually",
					AutoFixable: true,
					RuleID:      rule.ID,
					Details: map[string]interface{}{
						"task_index":      i,
						"markdown_status": markdownTasks[i].Status,
						"dynamic_status":  dynamicTasks[i].Status,
					},
				})
			}
		}
	}

	// Ajouter un résumé si trop de conflits
	if statusMismatches > 3 {
		issues = append(issues, ValidationIssue{
			Type:        "task_status_bulk_mismatch",
			Severity:    SeverityError,
			Message:     fmt.Sprintf("Multiple status mismatches detected: %d total conflicts", statusMismatches),
			Location:    "task_statuses",
			Suggestion:  "Perform bulk synchronization of task statuses",
			AutoFixable: false,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"total_mismatches": statusMismatches,
			},
		})
	}

	return issues, nil
}

// StructureConsistencyRule vérifie la cohérence de la hiérarchie des phases
type StructureConsistencyRule struct {
	ID          string
	Description string
	Priority    int
}

func (rule *StructureConsistencyRule) GetID() string {
	return rule.ID
}

func (rule *StructureConsistencyRule) GetDescription() string {
	return rule.Description
}

func (rule *StructureConsistencyRule) GetPriority() int {
	return rule.Priority
}

func (rule *StructureConsistencyRule) CanAutoFix() bool {
	return false // Structure changes are complex
}

func (rule *StructureConsistencyRule) Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error) {
	issues := []ValidationIssue{}

	// Simuler la récupération de la structure
	markdownStructure := rule.getMarkdownStructure(planID)
	dynamicStructure := rule.getDynamicStructure(planID)

	// Vérifier le nombre de phases
	if len(markdownStructure.Phases) != len(dynamicStructure.Phases) {
		issues = append(issues, ValidationIssue{
			Type:        "structure_phase_count_mismatch",
			Severity:    SeverityError,
			Message:     fmt.Sprintf("Phase count mismatch: Markdown=%d, Dynamic=%d", len(markdownStructure.Phases), len(dynamicStructure.Phases)),
			Location:    "phase_structure",
			Suggestion:  "Review and synchronize phase structure",
			AutoFixable: false,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"markdown_phases": len(markdownStructure.Phases),
				"dynamic_phases":  len(dynamicStructure.Phases),
			},
		})
	}

	// Vérifier la hiérarchie des sections
	hierarchyIssues := rule.compareHierarchy(markdownStructure, dynamicStructure)
	for _, issue := range hierarchyIssues {
		issue.RuleID = rule.ID
		issues = append(issues, issue)
	}

	return issues, nil
}

// TimestampConsistencyRule détecte les modifications désynchronisées
type TimestampConsistencyRule struct {
	ID          string
	Description string
	Priority    int
}

func (rule *TimestampConsistencyRule) GetID() string {
	return rule.ID
}

func (rule *TimestampConsistencyRule) GetDescription() string {
	return rule.Description
}

func (rule *TimestampConsistencyRule) GetPriority() int {
	return rule.Priority
}

func (rule *TimestampConsistencyRule) CanAutoFix() bool {
	return true
}

func (rule *TimestampConsistencyRule) Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error) {
	issues := []ValidationIssue{}

	// Simuler la récupération des timestamps
	markdownTime := rule.getMarkdownTimestamp(planID)
	dynamicTime := rule.getDynamicTimestamp(planID)

	// Calculer la différence
	timeDiff := markdownTime.Sub(dynamicTime)
	if timeDiff < 0 {
		timeDiff = -timeDiff
	}

	// Seuil d'alerte : 1 heure
	alertThreshold := time.Hour
	if timeDiff > alertThreshold {
		severity := SeverityWarning
		if timeDiff > 24*time.Hour {
			severity = SeverityError
		}

		issues = append(issues, ValidationIssue{
			Type:        "timestamp_sync_drift",
			Severity:    severity,
			Message:     fmt.Sprintf("Timestamp drift detected: %v difference", timeDiff),
			Location:    "modification_timestamps",
			Suggestion:  "Synchronize timestamps or check synchronization process",
			AutoFixable: true,
			RuleID:      rule.ID,
			Details: map[string]interface{}{
				"markdown_timestamp": markdownTime.Unix(),
				"dynamic_timestamp":  dynamicTime.Unix(),
				"difference_hours":   timeDiff.Hours(),
			},
		})
	}

	return issues, nil
}

// Legacy data types for backward compatibility with existing rules
type LegacyPlanMetadata struct {
	Version      string    `json:"version"`
	Progression  float64   `json:"progression"`
	LastModified time.Time `json:"last_modified"`
}

type LegacyTask struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Status      string `json:"status"`
	Description string `json:"description"`
}

type LegacyPlanStructure struct {
	Phases []LegacyPhase `json:"phases"`
}

type LegacyPhase struct {
	ID       string    `json:"id"`
	Title    string    `json:"title"`
	Sections []Section `json:"sections"`
}

type Section struct {
	ID    string       `json:"id"`
	Title string       `json:"title"`
	Tasks []LegacyTask `json:"tasks"`
}

// Méthodes de récupération simulées pour MetadataConsistencyRule
func (rule *MetadataConsistencyRule) getMarkdownMetadata(planID string) *PlanMetadata {
	return &PlanMetadata{
		Version: "2.1",
		Author:  "Test Author",
		Created: "2025-01-06",
		Updated: "2025-01-06",
		Status:  "active",
	}
}

func (rule *MetadataConsistencyRule) getDynamicMetadata(planID string) *PlanMetadata {
	return &PlanMetadata{
		Version: "2.0",
		Author:  "Test Author",
		Created: "2025-01-05",
		Updated: "2025-01-05",
		Status:  "active",
	}
}

// Méthodes de récupération simulées pour TaskConsistencyRule
func (rule *TaskConsistencyRule) getMarkdownTasks(planID string) []Task {
	return []Task{
		{ID: "1", Name: "Task 1", Status: "completed", Description: "First task"},
		{ID: "2", Name: "Task 2", Status: "in-progress", Description: "Second task"},
		{ID: "3", Name: "Task 3", Status: "not-started", Description: "Third task"},
	}
}

func (rule *TaskConsistencyRule) getDynamicTasks(planID string) []Task {
	return []Task{
		{ID: "1", Name: "Task 1", Status: "completed", Description: "First task"},
		{ID: "2", Name: "Task 2", Status: "not-started", Description: "Second task"}, // Status différent
		{ID: "3", Name: "Task 3", Status: "not-started", Description: "Third task"},
	}
}

// Méthodes de récupération simulées pour StructureConsistencyRule
func (rule *StructureConsistencyRule) getMarkdownStructure(planID string) LegacyPlanStructure {
	return LegacyPlanStructure{
		Phases: []LegacyPhase{
			{ID: "1", Title: "Phase 1", Sections: []Section{{ID: "1.1", Title: "Section 1.1"}}},
			{ID: "2", Title: "Phase 2", Sections: []Section{{ID: "2.1", Title: "Section 2.1"}}},
		},
	}
}

func (rule *StructureConsistencyRule) getDynamicStructure(planID string) LegacyPlanStructure {
	return LegacyPlanStructure{
		Phases: []LegacyPhase{
			{ID: "1", Title: "Phase 1", Sections: []Section{{ID: "1.1", Title: "Section 1.1"}}},
			{ID: "2", Title: "Phase 2", Sections: []Section{{ID: "2.1", Title: "Section 2.1"}}},
			{ID: "3", Title: "Phase 3", Sections: []Section{{ID: "3.1", Title: "Section 3.1"}}}, // Phase supplémentaire
		},
	}
}

func (rule *StructureConsistencyRule) compareHierarchy(markdown, dynamic LegacyPlanStructure) []ValidationIssue {
	issues := []ValidationIssue{}

	// Comparer les titres des phases communes
	minPhases := len(markdown.Phases)
	if len(dynamic.Phases) < minPhases {
		minPhases = len(dynamic.Phases)
	}

	for i := 0; i < minPhases; i++ {
		if markdown.Phases[i].Title != dynamic.Phases[i].Title {
			issues = append(issues, ValidationIssue{
				Type:        "structure_phase_title_mismatch",
				Severity:    SeverityWarning,
				Message:     fmt.Sprintf("Phase %d title mismatch: '%s' vs '%s'", i+1, markdown.Phases[i].Title, dynamic.Phases[i].Title),
				Location:    fmt.Sprintf("phase_%d", i+1),
				Suggestion:  "Review phase titles for consistency",
				AutoFixable: false,
				Details: map[string]interface{}{
					"phase_index":    i,
					"markdown_title": markdown.Phases[i].Title,
					"dynamic_title":  dynamic.Phases[i].Title,
				},
			})
		}
	}

	return issues
}

// Méthodes de récupération simulées pour TimestampConsistencyRule
func (rule *TimestampConsistencyRule) getMarkdownTimestamp(planID string) time.Time {
	return time.Now().Add(-30 * time.Minute)
}

func (rule *TimestampConsistencyRule) getDynamicTimestamp(planID string) time.Time {
	return time.Now().Add(-2 * time.Hour)
}

// Factory functions pour créer les règles
func NewMetadataConsistencyRule() *MetadataConsistencyRule {
	return &MetadataConsistencyRule{
		ID:          "metadata_consistency",
		Description: "Validates consistency of plan metadata between Markdown and dynamic systems",
		Priority:    1,
	}
}

func NewTaskConsistencyRule() *TaskConsistencyRule {
	return &TaskConsistencyRule{
		ID:          "task_consistency",
		Description: "Validates consistency of tasks and their statuses",
		Priority:    2,
	}
}

func NewStructureConsistencyRule() *StructureConsistencyRule {
	return &StructureConsistencyRule{
		ID:          "structure_consistency",
		Description: "Validates consistency of plan structure and hierarchy",
		Priority:    3,
	}
}

func NewTimestampConsistencyRule() *TimestampConsistencyRule {
	return &TimestampConsistencyRule{
		ID:          "timestamp_consistency",
		Description: "Validates synchronization of modification timestamps",
		Priority:    4,
	}
}

// GetAllValidationRules retourne toutes les règles de validation disponibles
func GetAllValidationRules() []ValidationRule {
	return []ValidationRule{
		NewMetadataConsistencyRule(),
		NewTaskConsistencyRule(),
		NewStructureConsistencyRule(),
		NewTimestampConsistencyRule(),
	}
}
