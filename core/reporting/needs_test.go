package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// Helper function to create a dummy issues.json file for testing
func createDummyIssuesFile(t *testing.T, path string, content []map[string]interface{}) {
	jsonContent, err := json.Marshal(content)
	if err != nil {
		t.Fatalf("Failed to marshal dummy content: %v", err)
	}
	err = os.WriteFile(path, jsonContent, 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy issues file: %v", err)
	}
}

func TestParseNeedsFromIssues(t *testing.T) {
	tempDir := t.TempDir()
	issuesFilePath := filepath.Join(tempDir, "issues.json")

	// Test Case 1: issues.json exists and contains data
	dummyIssues := []map[string]interface{}{
		{"id": "ISSUE-001", "description": "Bug fix", "status": "Closed", "priority": "Low"},
		{"id": "ISSUE-002", "description": "New feature", "status": "Open", "priority": "High"},
	}
	createDummyIssuesFile(t, issuesFilePath, dummyIssues)

	needs, err := ParseNeedsFromIssues(issuesFilePath)
	if err != nil {
		t.Fatalf("ParseNeedsFromIssues failed: %v", err)
	}

	expectedNeeds := []Need{
		{ID: "ISSUE-001", Description: "Bug fix", Status: "Closed", Priority: "Low"},
		{ID: "ISSUE-002", Description: "New feature", Status: "Open", Priority: "High"},
	}

	if !reflect.DeepEqual(needs, expectedNeeds) {
		t.Errorf("Parsed needs mismatch.\nExpected: %+v\nGot: %+v", expectedNeeds, needs)
	}

	// Test Case 2: issues.json does not exist (should return default needs)
	nonExistentFilePath := filepath.Join(tempDir, "non_existent_issues.json")
	needs, err = ParseNeedsFromIssues(nonExistentFilePath)
	if err != nil {
		t.Fatalf("ParseNeedsFromIssues failed for non-existent file: %v", err)
	}

	// Verify that default needs are returned
	if len(needs) != 3 {
		t.Errorf("Expected 3 default needs, got %d", len(needs))
	}
	if needs[0].ID != "REQ-001" {
		t.Errorf("Default need ID mismatch: expected REQ-001, got %s", needs[0].ID)
	}
}

func TestGenerateNeedsReport(t *testing.T) {
	tempDir := t.TempDir()
	outputPathJSON := filepath.Join(tempDir, "besoins.json")
	outputPathMD := filepath.Join(tempDir, "BESOINS_INITIAUX.md")

	needs := []Need{
		{ID: "REQ-001", Description: "Implémenter la fonctionnalité de scan des modules", Status: "Ouvert", Priority: "Haute"},
		{ID: "REQ-002", Description: "Générer un rapport d'analyse d'écart", Status: "En cours", Priority: "Haute"},
	}

	err := GenerateNeedsReport(outputPathJSON, outputPathMD, needs)
	if err != nil {
		t.Fatalf("GenerateNeedsReport failed: %v", err)
	}

	// Verify JSON output
	jsonBytes, err := os.ReadFile(outputPathJSON) // Change to os.ReadFile
	if err != nil {
		t.Fatalf("Failed to read JSON output: %v", err)
	}
	var readNeeds []Need
	err = json.Unmarshal(jsonBytes, &readNeeds)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON output: %v", err)
	}
	if !reflect.DeepEqual(readNeeds, needs) {
		t.Errorf("JSON needs mismatch.\nExpected: %+v\nGot: %+v", needs, readNeeds)
	}

	// Verify Markdown output
	markdownContent, err := os.ReadFile(outputPathMD) // Change to os.ReadFile
	if err != nil {
		t.Fatalf("Failed to read Markdown output: %v", err)
	}
	mdString := string(markdownContent)
	if !strings.Contains(mdString, "# Rapport des Besoins") {
		t.Errorf("Markdown content missing header")
	}
	if !strings.Contains(mdString, "- **ID**: REQ-001") {
		t.Errorf("Markdown content missing REQ-001 details")
	}
	if !strings.Contains(mdString, "- **ID**: REQ-002") {
		t.Errorf("Markdown content missing REQ-002 details")
	}
}
