package validation

import (
	"context"
	"testing"
)

func TestFormatParser_DetectFormat(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		expected FormatType
	}{
		{"YAML file", "test.yaml", FormatYAML},
		{"YML file", "test.yml", FormatYAML},
		{"JSON file", "test.json", FormatJSON},
		{"Markdown file", "test.md", FormatMarkdown},
		{"Unknown file", "test.txt", FormatUnknown},
	}

	parser := NewFormatParser()
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parser.DetectFormat(tt.filename)
			if result != tt.expected {
				t.Errorf("DetectFormat(%s) = %s, want %s", tt.filename, result, tt.expected)
			}
		})
	}
}

func TestFormatParser_ParseYAML(t *testing.T) {
	yamlContent := `
metadata:
  title: "Test Plan"
  version: "1.0.0"
  author: "Test Author"
  created: "2025-01-01"
  status: "active"
phases:
  - id: "phase-1"
    name: "Test Phase"
    status: "in-progress"
    progress: 50.0
    start_date: "2025-01-01"
    end_date: "2025-01-31"
    tasks: []
    milestones: []
    resources: []
`

	parser := NewFormatParser()
	doc, err := parser.ParseContent([]byte(yamlContent), "yaml")
	if err != nil {
		t.Fatalf("ParseContent failed: %v", err)
	}

	if doc.Metadata.Title != "Test Plan" {
		t.Errorf("Expected title 'Test Plan', got '%s'", doc.Metadata.Title)
	}

	if doc.Metadata.Version != "1.0.0" {
		t.Errorf("Expected version '1.0.0', got '%s'", doc.Metadata.Version)
	}

	if len(doc.Phases) != 1 {
		t.Errorf("Expected 1 phase, got %d", len(doc.Phases))
	}

	if doc.Phases[0].Name != "Test Phase" {
		t.Errorf("Expected phase name 'Test Phase', got '%s'", doc.Phases[0].Name)
	}
}

func TestFormatParser_ParseJSON(t *testing.T) {
	jsonContent := `{
  "metadata": {
    "title": "Test Plan",
    "version": "1.0.0",
    "author": "Test Author",
    "created": "2025-01-01",
    "status": "active"
  },
  "phases": [
    {
      "id": "phase-1",
      "name": "Test Phase",
      "status": "in-progress",
      "progress": 50.0,
      "start_date": "2025-01-01",
      "end_date": "2025-01-31",
      "tasks": [],
      "milestones": [],
      "resources": []
    }
  ]
}`

	parser := NewFormatParser()
	doc, err := parser.ParseContent([]byte(jsonContent), "json")
	if err != nil {
		t.Fatalf("ParseContent failed: %v", err)
	}

	if doc.Metadata.Title != "Test Plan" {
		t.Errorf("Expected title 'Test Plan', got '%s'", doc.Metadata.Title)
	}

	if len(doc.Phases) != 1 {
		t.Errorf("Expected 1 phase, got %d", len(doc.Phases))
	}
}

func TestFormatParser_ConvertToYAML(t *testing.T) {
	doc := &PlanDocument{
		Metadata: PlanMetadata{
			Title:   "Test Plan",
			Version: "1.0.0",
			Author:  "Test Author",
			Created: "2025-01-01",
			Status:  "active",
		},
		Phases: []Phase{
			{
				ID:        "phase-1",
				Name:      "Test Phase",
				Status:    "in-progress",
				Progress:  50.0,
				StartDate: "2025-01-01",
				EndDate:   "2025-01-31",
			},
		},
	}

	parser := NewFormatParser()
	yamlBytes, err := parser.ConvertToYAML(doc)
	if err != nil {
		t.Fatalf("ConvertToYAML failed: %v", err)
	}

	// Parse it back to verify
	parsedDoc, err := parser.ParseContent(yamlBytes, "yaml")
	if err != nil {
		t.Fatalf("Re-parsing converted YAML failed: %v", err)
	}

	if parsedDoc.Metadata.Title != doc.Metadata.Title {
		t.Errorf("Title mismatch after conversion")
	}
}

func TestFormatParser_ConvertToJSON(t *testing.T) {
	doc := &PlanDocument{
		Metadata: PlanMetadata{
			Title:   "Test Plan",
			Version: "1.0.0",
			Author:  "Test Author",
			Created: "2025-01-01",
			Status:  "active",
		},
		Phases: []Phase{
			{
				ID:        "phase-1",
				Name:      "Test Phase",
				Status:    "in-progress",
				Progress:  50.0,
				StartDate: "2025-01-01",
				EndDate:   "2025-01-31",
			},
		},
	}

	parser := NewFormatParser()
	jsonBytes, err := parser.ConvertToJSON(doc)
	if err != nil {
		t.Fatalf("ConvertToJSON failed: %v", err)
	}

	// Parse it back to verify
	parsedDoc, err := parser.ParseContent(jsonBytes, "json")
	if err != nil {
		t.Fatalf("Re-parsing converted JSON failed: %v", err)
	}

	if parsedDoc.Metadata.Title != doc.Metadata.Title {
		t.Errorf("Title mismatch after conversion")
	}
}

func TestFormatConsistencyRule_ValidateMetadata(t *testing.T) {
	rule := NewFormatConsistencyRule()

	tests := []struct {
		name     string
		metadata PlanMetadata
		wantErrs int
	}{
		{
			name: "valid metadata",
			metadata: PlanMetadata{
				Title:   "Test Plan",
				Version: "1.0.0",
				Author:  "Test Author",
				Created: "2025-01-01",
				Status:  "active",
			},
			wantErrs: 0,
		},
		{
			name: "missing required fields",
			metadata: PlanMetadata{
				Description: "Missing required fields",
			},
			wantErrs: 3, // title, version, author
		},
		{
			name: "invalid date format",
			metadata: PlanMetadata{
				Title:   "Test Plan",
				Version: "1.0.0",
				Author:  "Test Author",
				Created: "invalid-date",
			},
			wantErrs: 1,
		}, {
			name: "invalid status",
			metadata: PlanMetadata{
				Title:   "Test Plan",
				Version: "1.0.0",
				Author:  "Test Author",
				Status:  "invalid-status",
			},
			wantErrs: 0, // warning, not error
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := rule.ValidateMetadata(&tt.metadata)
			errorCount := 0
			for _, issue := range issues {
				if issue.Type == "error" {
					errorCount++
				}
			}
			if errorCount != tt.wantErrs {
				t.Errorf("ValidateMetadata() error count = %d, want %d", errorCount, tt.wantErrs)
			}
		})
	}
}

func TestFormatConsistencyRule_ValidateMetadata_Warnings(t *testing.T) {
	rule := NewFormatConsistencyRule()

	tests := []struct {
		name         string
		metadata     PlanMetadata
		wantWarnings int
	}{
		{
			name: "invalid status generates warning",
			metadata: PlanMetadata{
				Title:   "Test Plan",
				Version: "1.0.0",
				Author:  "Test Author",
				Status:  "invalid-status",
			},
			wantWarnings: 1,
		},
		{
			name: "invalid priority generates warning",
			metadata: PlanMetadata{
				Title:    "Test Plan",
				Version:  "1.0.0",
				Author:   "Test Author",
				Priority: "invalid-priority",
			},
			wantWarnings: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := rule.ValidateMetadata(&tt.metadata)
			warningCount := 0
			for _, issue := range issues {
				if issue.Type == "warning" {
					warningCount++
				}
			}
			if warningCount != tt.wantWarnings {
				t.Errorf("ValidateMetadata() warning count = %d, want %d", warningCount, tt.wantWarnings)
			}
		})
	}
}

func TestFormatConsistencyRule_ValidatePhases(t *testing.T) {
	rule := NewFormatConsistencyRule()

	tests := []struct {
		name     string
		phases   []Phase
		wantErrs int
	}{
		{
			name: "valid phases",
			phases: []Phase{
				{
					ID:        "phase-1",
					Name:      "Test Phase",
					Status:    "in-progress",
					Progress:  50.0,
					StartDate: "2025-01-01",
					EndDate:   "2025-01-31",
				},
			},
			wantErrs: 0,
		},
		{
			name:     "empty phases",
			phases:   []Phase{},
			wantErrs: 0, // warning, not error
		},
		{
			name: "missing required fields",
			phases: []Phase{
				{
					Description: "Missing required fields",
					Progress:    50.0,
				},
			},
			wantErrs: 2, // id, name
		},
		{
			name: "invalid progress",
			phases: []Phase{
				{
					ID:       "phase-1",
					Name:     "Test Phase",
					Progress: 150.0, // invalid
				},
			},
			wantErrs: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := rule.ValidatePhases(tt.phases)
			errorCount := 0
			for _, issue := range issues {
				if issue.Type == "error" {
					errorCount++
				}
			}
			if errorCount != tt.wantErrs {
				t.Errorf("ValidatePhases() error count = %d, want %d", errorCount, tt.wantErrs)
			}
		})
	}
}

func TestFormatConsistencyRule_ValidateTask(t *testing.T) {
	rule := NewFormatConsistencyRule()

	tests := []struct {
		name     string
		task     Task
		wantErrs int
	}{{
		name: "valid task",
		task: Task{
			ID:           "task-1",
			Name:         "Test Task",
			Status:       "in-progress",
			Progress:     50.0,
			EstimatedHrs: 8,
			ActualHrs:    6,
			StartDate:    "2025-01-01",
			EndDate:      "2025-01-05",
		},
		wantErrs: 0,
	},
		{
			name: "missing required fields",
			task: Task{
				Description: "Missing required fields",
			},
			wantErrs: 2, // id, name
		}, {
			name: "invalid progress and negative hours",
			task: Task{
				ID:           "task-1",
				Name:         "Test Task",
				Progress:     150.0, // invalid
				EstimatedHrs: -1,    // invalid
				ActualHrs:    -1,    // invalid
			},
			wantErrs: 3,
		}, {
			name: "time overrun",
			task: Task{
				ID:           "task-1",
				Name:         "Test Task",
				EstimatedHrs: 8,
				ActualHrs:    15, // 87.5% overrun
			},
			wantErrs: 0, // warning, not error
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issues := rule.validateTask(&tt.task, "test.task")
			errorCount := 0
			for _, issue := range issues {
				if issue.Type == "error" {
					errorCount++
				}
			}
			if errorCount != tt.wantErrs {
				t.Errorf("validateTask() error count = %d, want %d", errorCount, tt.wantErrs)
			}
		})
	}
}

func TestFormatConsistencyRule_Validate(t *testing.T) {
	rule := NewFormatConsistencyRule()

	doc := &PlanDocument{
		Metadata: PlanMetadata{
			Title:   "Test Plan",
			Version: "1.0.0",
			Author:  "Test Author",
			Created: "2025-01-01",
			Status:  "active",
		},
		Phases: []Phase{
			{
				ID:        "phase-1",
				Name:      "Test Phase",
				Status:    "in-progress",
				Progress:  50.0,
				StartDate: "2025-01-01",
				EndDate:   "2025-01-31",
				Tasks: []Task{
					{
						ID:       "task-1",
						Name:     "Test Task",
						Status:   "in-progress",
						Progress: 50.0,
					},
				},
			},
		},
	}

	ctx := context.Background()
	issues, err := rule.Validate(ctx, doc)
	if err != nil {
		t.Fatalf("Validate failed: %v", err)
	}

	// Should have no errors for this valid document
	errorCount := 0
	for _, issue := range issues {
		if issue.Type == "error" {
			errorCount++
		}
	}

	if errorCount > 0 {
		t.Errorf("Expected no errors, got %d", errorCount)
		for _, issue := range issues {
			if issue.Type == "error" {
				t.Logf("Error: %s at %s", issue.Message, issue.Location)
			}
		}
	}
}

func TestFormatConsistencyRule_ValidateInvalidData(t *testing.T) {
	rule := NewFormatConsistencyRule()

	// Test with invalid data type
	ctx := context.Background()
	_, err := rule.Validate(ctx, "invalid data")
	if err == nil {
		t.Error("Expected error for invalid data type, got nil")
	}
}

func TestValidationIntegration(t *testing.T) {
	// Test the complete flow: parse file -> validate -> report issues
	parser := NewFormatParser()
	rule := NewFormatConsistencyRule()

	// Create a test document with some issues
	yamlContent := `
metadata:
  title: ""  # missing title (error)
  version: "1.0.0"
  author: "Test Author"
  created: "invalid-date"  # invalid date (error)
  status: "unknown-status"  # invalid status (warning)
phases:
  - id: "phase-1"
    name: "Test Phase"
    status: "in-progress"
    progress: 150.0  # invalid progress (error)
    start_date: "2025-01-01"
    end_date: "2025-01-31"
    tasks:
      - id: ""  # missing id (error)
        name: "Test Task"
        status: "in-progress"
        progress: 50.0
    milestones: []
    resources: []
`

	// Parse the document
	doc, err := parser.ParseContent([]byte(yamlContent), "yaml")
	if err != nil {
		t.Fatalf("ParseContent failed: %v", err)
	}

	// Validate the document
	ctx := context.Background()
	issues, err := rule.Validate(ctx, doc)
	if err != nil {
		t.Fatalf("Validate failed: %v", err)
	}

	// Check that we found the expected issues
	errorCount := 0
	warningCount := 0
	for _, issue := range issues {
		switch issue.Type {
		case "error":
			errorCount++
		case "warning":
			warningCount++
		}
	}

	expectedErrors := 4   // missing title, invalid date, invalid progress, missing task id
	expectedWarnings := 1 // invalid status

	if errorCount != expectedErrors {
		t.Errorf("Expected %d errors, got %d", expectedErrors, errorCount)
	}

	if warningCount != expectedWarnings {
		t.Errorf("Expected %d warnings, got %d", expectedWarnings, warningCount)
	}

	// Log issues for debugging
	t.Logf("Found %d total issues:", len(issues))
	for _, issue := range issues {
		t.Logf("  %s: %s (%s)", issue.Type, issue.Message, issue.Location)
	}
}
