package main

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
)

func TestGenerateSpecifications(t *testing.T) {
	tmpDir := "/tmp"

	// Generate specifications
	report, err := generateSpecifications(tmpDir)
	if err != nil {
		t.Fatalf("Failed to generate specifications: %v", err)
	}

	// Validate basic structure
	if report.ProjectName == "" {
		t.Error("Expected project name to be set")
	}

	if len(report.AutomationSpecs) == 0 {
		t.Error("Expected automation specs to be generated")
	}

	if len(report.WorkflowSpecs) == 0 {
		t.Error("Expected workflow specs to be generated")
	}

	if len(report.TechnicalRequirements) == 0 {
		t.Error("Expected technical requirements to be generated")
	}

	if len(report.ImplementationPlan) == 0 {
		t.Error("Expected implementation plan to be generated")
	}

	if report.Summary == "" {
		t.Error("Expected summary to be generated")
	}

	// Validate timestamp
	if time.Since(report.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
}

func TestGenerateAutomationSpecs(t *testing.T) {
	specs := generateAutomationSpecs()

	if len(specs) == 0 {
		t.Error("Expected automation specs to be generated")
	}

	// Check for required specs
	expectedSpecs := map[string]bool{
		"Documentation Inventory Scanner": false,
		"Gap Analysis Engine":             false,
		"Documentation Generator":         false,
		"Documentation Linter":            false,
		"Coverage Reporter":               false,
	}

	for _, spec := range specs {
		if _, exists := expectedSpecs[spec.Name]; exists {
			expectedSpecs[spec.Name] = true
		}
	}

	for name, found := range expectedSpecs {
		if !found {
			t.Errorf("Expected automation spec '%s' not found", name)
		}
	}

	// Validate spec structure
	for _, spec := range specs {
		if spec.Name == "" {
			t.Error("Spec name should not be empty")
		}
		if spec.Description == "" {
			t.Error("Spec description should not be empty")
		}
		if len(spec.Inputs) == 0 {
			t.Error("Spec should have inputs defined")
		}
		if len(spec.Outputs) == 0 {
			t.Error("Spec should have outputs defined")
		}
		if spec.Priority == "" {
			t.Error("Spec priority should be set")
		}
		if spec.EstimatedEffort == "" {
			t.Error("Spec estimated effort should be set")
		}
	}
}

func TestGenerateWorkflowSpecs(t *testing.T) {
	workflows := generateWorkflowSpecs()

	if len(workflows) == 0 {
		t.Error("Expected workflow specs to be generated")
	}

	// Check for required workflows
	expectedWorkflows := map[string]bool{
		"Full Documentation Audit":        false,
		"Continuous Documentation Sync":   false,
	}

	for _, workflow := range workflows {
		if _, exists := expectedWorkflows[workflow.Name]; exists {
			expectedWorkflows[workflow.Name] = true
		}
	}

	for name, found := range expectedWorkflows {
		if !found {
			t.Errorf("Expected workflow '%s' not found", name)
		}
	}

	// Validate workflow structure
	for _, workflow := range workflows {
		if workflow.Name == "" {
			t.Error("Workflow name should not be empty")
		}
		if workflow.Description == "" {
			t.Error("Workflow description should not be empty")
		}
		if len(workflow.Steps) == 0 {
			t.Error("Workflow should have steps defined")
		}
		if len(workflow.Triggers) == 0 {
			t.Error("Workflow should have triggers defined")
		}
		if len(workflow.Outputs) == 0 {
			t.Error("Workflow should have outputs defined")
		}

		// Validate workflow steps
		for _, step := range workflow.Steps {
			if step.Name == "" {
				t.Error("Workflow step name should not be empty")
			}
			if step.Action == "" {
				t.Error("Workflow step action should not be empty")
			}
			if step.Validation == "" {
				t.Error("Workflow step validation should not be empty")
			}
			if step.ErrorHandling == "" {
				t.Error("Workflow step error handling should not be empty")
			}
		}
	}
}

func TestGenerateArchitectureSpecs(t *testing.T) {
	arch := generateArchitectureSpecs()

	if arch.Pattern == "" {
		t.Error("Architecture pattern should be defined")
	}

	if len(arch.Components) == 0 {
		t.Error("Architecture should have components defined")
	}

	if len(arch.Integrations) == 0 {
		t.Error("Architecture should have integrations defined")
	}

	if len(arch.DataFlow) == 0 {
		t.Error("Architecture should have data flow defined")
	}

	// Validate components
	for _, component := range arch.Components {
		if component.Name == "" {
			t.Error("Component name should not be empty")
		}
		if component.Type == "" {
			t.Error("Component type should not be empty")
		}
		if component.Purpose == "" {
			t.Error("Component purpose should not be empty")
		}
		if component.Technology == "" {
			t.Error("Component technology should not be empty")
		}
	}

	// Validate security spec
	if len(arch.Security.Logging) == 0 {
		t.Error("Security logging requirements should be defined")
	}

	// Validate scalability spec
	if len(arch.Scalability.Performance) == 0 {
		t.Error("Performance requirements should be defined")
	}
}

func TestGenerateTechnicalRequirements(t *testing.T) {
	requirements := generateTechnicalRequirements()

	if len(requirements) == 0 {
		t.Error("Expected technical requirements to be generated")
	}

	// Check for required categories
	expectedCategories := map[string]bool{
		"performance":     false,
		"reliability":     false,
		"usability":       false,
		"maintainability": false,
		"integration":     false,
	}

	for _, req := range requirements {
		if _, exists := expectedCategories[req.Category]; exists {
			expectedCategories[req.Category] = true
		}
	}

	for category, found := range expectedCategories {
		if !found {
			t.Errorf("Expected requirement category '%s' not found", category)
		}
	}

	// Validate requirement structure
	for _, req := range requirements {
		if req.Category == "" {
			t.Error("Requirement category should not be empty")
		}
		if req.Requirement == "" {
			t.Error("Requirement description should not be empty")
		}
		if req.Rationale == "" {
			t.Error("Requirement rationale should not be empty")
		}
		if req.Priority == "" {
			t.Error("Requirement priority should not be empty")
		}
		if len(req.Acceptance) == 0 {
			t.Error("Requirement should have acceptance criteria")
		}
	}
}

func TestGenerateImplementationPlan(t *testing.T) {
	plan := generateImplementationPlan()

	if len(plan) == 0 {
		t.Error("Expected implementation plan to be generated")
	}

	// Should have at least 3 phases
	if len(plan) < 3 {
		t.Error("Expected at least 3 implementation phases")
	}

	// Check for expected phases
	expectedPhases := map[string]bool{
		"Phase 1: Foundation": false,
		"Phase 2: Automation": false,
		"Phase 3: Integration": false,
	}

	for _, phase := range plan {
		if _, exists := expectedPhases[phase.Phase]; exists {
			expectedPhases[phase.Phase] = true
		}
	}

	for phaseName, found := range expectedPhases {
		if !found {
			t.Errorf("Expected phase '%s' not found", phaseName)
		}
	}

	// Validate phase structure
	for _, phase := range plan {
		if phase.Phase == "" {
			t.Error("Phase name should not be empty")
		}
		if phase.Description == "" {
			t.Error("Phase description should not be empty")
		}
		if len(phase.Objectives) == 0 {
			t.Error("Phase should have objectives defined")
		}
		if len(phase.Deliverables) == 0 {
			t.Error("Phase should have deliverables defined")
		}
		if phase.Duration == "" {
			t.Error("Phase duration should be defined")
		}
		if len(phase.Risks) == 0 {
			t.Error("Phase should have risks identified")
		}
	}

	// Validate phase dependencies
	foundPhasesWithDeps := 0
	for _, phase := range plan {
		if len(phase.Dependencies) > 0 {
			foundPhasesWithDeps++
		}
	}

	if foundPhasesWithDeps == 0 {
		t.Error("Expected some phases to have dependencies")
	}
}

func TestSpecSummaryGeneration(t *testing.T) {
	automationSpecs := generateAutomationSpecs()
	workflowSpecs := generateWorkflowSpecs()

	summary := generateSpecSummary(automationSpecs, workflowSpecs)

	if summary == "" {
		t.Error("Expected summary to be generated")
	}

	// Should mention key numbers
	if !strings.Contains(summary, "Automation Components") {
		t.Error("Summary should mention automation components")
	}

	if !strings.Contains(summary, "Workflow Definitions") {
		t.Error("Summary should mention workflow definitions")
	}

	// Should mention key features
	expectedFeatures := []string{
		"scanning", "analysis", "synchronization", "reporting", "integration",
	}

	for _, feature := range expectedFeatures {
		if !strings.Contains(strings.ToLower(summary), feature) {
			t.Errorf("Summary should mention '%s'", feature)
		}
	}
}

func TestJSONOutput(t *testing.T) {
	// Create a minimal test report
	report := &SpecificationReport{
		GeneratedAt:     time.Now(),
		ProjectName:     "test-project",
		AutomationSpecs: []AutomationSpec{{Name: "test", Description: "test spec"}},
		WorkflowSpecs:   []WorkflowSpec{{Name: "test", Description: "test workflow"}},
		ArchitectureSpecs: ArchitectureSpec{
			Pattern:    "test_pattern",
			Components: []ComponentSpec{{Name: "test", Type: "test"}},
		},
		TechnicalRequirements: []TechnicalRequirement{{Category: "test", Requirement: "test req"}},
		ImplementationPlan:    []ImplementationPhase{{Phase: "test", Description: "test phase"}},
		Summary:               "test summary",
	}

	// Test JSON encoding
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Test JSON decoding
	var decoded SpecificationReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Validate key fields
	if decoded.ProjectName != report.ProjectName {
		t.Errorf("ProjectName mismatch: got %s, expected %s", 
			decoded.ProjectName, report.ProjectName)
	}
	if len(decoded.AutomationSpecs) != len(report.AutomationSpecs) {
		t.Errorf("AutomationSpecs length mismatch: got %d, expected %d", 
			len(decoded.AutomationSpecs), len(report.AutomationSpecs))
	}
	if decoded.Summary != report.Summary {
		t.Errorf("Summary mismatch: got %s, expected %s", 
			decoded.Summary, report.Summary)
	}
}

func TestCompleteSpecificationWorkflow(t *testing.T) {
	tmpDir := "/tmp/test-project"

	// Run complete workflow
	report, err := generateSpecifications(tmpDir)
	if err != nil {
		t.Fatalf("Failed to generate specifications: %v", err)
	}

	// Validate comprehensive report
	if len(report.AutomationSpecs) < 3 {
		t.Errorf("Expected multiple automation specs, got %d", len(report.AutomationSpecs))
	}

	if len(report.WorkflowSpecs) < 2 {
		t.Errorf("Expected multiple workflow specs, got %d", len(report.WorkflowSpecs))
	}

	if len(report.TechnicalRequirements) < 5 {
		t.Errorf("Expected multiple technical requirements, got %d", len(report.TechnicalRequirements))
	}

	if len(report.ImplementationPlan) < 3 {
		t.Errorf("Expected multiple implementation phases, got %d", len(report.ImplementationPlan))
	}

	// Test JSON output
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Validate JSON structure
	var decoded SpecificationReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Basic validation
	if time.Since(decoded.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
}