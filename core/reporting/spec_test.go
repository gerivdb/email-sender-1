package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// Helper function to create a dummy needs.json file for testing
func createDummyNeedsFile(t *testing.T, path string, content []Need) {
	jsonContent, err := json.Marshal(content)
	if err != nil {
		t.Fatalf("Failed to marshal dummy content: %v", err)
	}
	err = os.WriteFile(path, jsonContent, 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy needs file: %v", err)
	}
}

func TestValidateSpecifications(t *testing.T) {
	tempDir := t.TempDir()
	needsFilePath := filepath.Join(tempDir, "needs.json")

	// Test Case 1: needs.json exists and contains data
	dummyNeeds := []Need{
		{ID: "REQ-001", Description: "Implémenter la fonctionnalité de scan des modules", Status: "Ouvert", Priority: "Haute"},
		{ID: "REQ-002", Description: "Générer un rapport d'analyse d'écart", Status: "En cours", Priority: "Haute"},
		{ID: "REQ-004", Description: "Nouvelle exigence", Status: "Fermé", Priority: "Basse"},
	}
	createDummyNeedsFile(t, needsFilePath, dummyNeeds)

	specs, err := ValidateSpecifications(needsFilePath)
	if err != nil {
		t.Fatalf("ValidateSpecifications failed: %v", err)
	}

	expectedSpecs := []Specification{
		{ID: "SPEC-001", Description: "Spécification de Implémenter la fonctionnalité de scan des modules", Status: "Approuvée", Completeness: "Complete"},
		{ID: "SPEC-002", Description: "Spécification de Générer un rapport d'analyse d'écart", Status: "En révision", Completeness: "Partial"},
		{ID: "SPEC-004", Description: "Spécification de Nouvelle exigence", Status: "Non démarrée", Completeness: "Missing"},
	}

	if !reflect.DeepEqual(specs, expectedSpecs) {
		t.Errorf("Validated specifications mismatch.\nExpected: %+v\nGot: %+v", expectedSpecs, specs)
	}

	// Test Case 2: needs.json does not exist (should return default specs)
	nonExistentFilePath := filepath.Join(tempDir, "non_existent_needs.json")
	specs, err = ValidateSpecifications(nonExistentFilePath)
	if err != nil {
		t.Fatalf("ValidateSpecifications failed for non-existent file: %v", err)
	}

	// Verify that default specs are returned
	if len(specs) != 3 {
		t.Errorf("Expected 3 default specs, got %d", len(specs))
	}
	if specs[0].ID != "SPEC-001" {
		t.Errorf("Default spec ID mismatch: expected SPEC-001, got %s", specs[0].ID)
	}
}

func TestGenerateSpecReport(t *testing.T) {
	tempDir := t.TempDir()
	outputPathJSON := filepath.Join(tempDir, "spec.json")
	outputPathMD := filepath.Join(tempDir, "SPEC_INIT.md")

	specs := []Specification{
		{ID: "SPEC-001", Description: "Spécification du module de scan", Status: "Approuvée", Completeness: "Complete"},
		{ID: "SPEC-002", Description: "Spécification du rapport d'analyse d'écart", Status: "En révision", Completeness: "Partial"},
	}

	err := GenerateSpecReport(outputPathJSON, outputPathMD, specs)
	if err != nil {
		t.Fatalf("GenerateSpecReport failed: %v", err)
	}

	// Verify JSON output
	jsonBytes, err := os.ReadFile(outputPathJSON)
	if err != nil {
		t.Fatalf("Failed to read JSON output: %v", err)
	}
	var readSpecs []Specification
	err = json.Unmarshal(jsonBytes, &readSpecs)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON output: %v", err)
	}
	if !reflect.DeepEqual(readSpecs, specs) {
		t.Errorf("JSON specs mismatch.\nExpected: %+v\nGot: %+v", specs, readSpecs)
	}

	// Verify Markdown output
	markdownContent, err := os.ReadFile(outputPathMD)
	if err != nil {
		t.Fatalf("Failed to read Markdown output: %v", err)
	}
	mdString := string(markdownContent)
	if !strings.Contains(mdString, "# Rapport des Spécifications") {
		t.Errorf("Markdown content missing header")
	}
	if !strings.Contains(mdString, "- **ID**: SPEC-001") {
		t.Errorf("Markdown content missing SPEC-001 details")
	}
	if !strings.Contains(mdString, "- **ID**: SPEC-002") {
		t.Errorf("Markdown content missing SPEC-002 details")
	}
}
