package gapanalyzer

import (
	"encoding/json"
	"os" // Use os instead of ioutil for file operations
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// Helper function to create a dummy modules.json file for testing
func createDummyModulesFile(t *testing.T, path string, content []string) {
	jsonContent, err := json.Marshal(content)
	if err != nil {
		t.Fatalf("Failed to marshal dummy content: %v", err)
	}
	err = os.WriteFile(path, jsonContent, 0o644) // Use os.WriteFile
	if err != nil {
		t.Fatalf("Failed to write dummy modules file: %v", err)
	}
}

func TestAnalyzeGoModulesGap(t *testing.T) {
	tempDir := t.TempDir()
	existingModulesPath := filepath.Join(tempDir, "modules.json")
	expectedModulesPath := filepath.Join(tempDir, "expected_modules.json")

	// Define a common set of expected modules for consistent testing
	commonExpectedModules := []string{
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/scanmodules",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/gapanalyzer",
	}
	createDummyModulesFile(t, expectedModulesPath, commonExpectedModules)

	// Test Case 1: No gaps
	createDummyModulesFile(t, existingModulesPath, commonExpectedModules)
	result, err := AnalyzeGoModulesGap(existingModulesPath, expectedModulesPath) // Pass expectedModulesPath
	if err != nil {
		t.Fatalf("AnalyzeGoModulesGap failed: %v", err)
	}
	if result.GapFound {
		t.Errorf("Expected no gaps, but found gaps: %v", result.GapDetails)
	}
	if len(result.MissingModules) != 0 {
		t.Errorf("Expected no missing modules, got %v", result.MissingModules)
	}
	if len(result.ExtraModules) != 0 {
		t.Errorf("Expected no extra modules, got %v", result.ExtraModules)
	}

	// Test Case 2: Missing modules
	createDummyModulesFile(t, existingModulesPath, []string{
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/scanmodules",
	})
	result, err = AnalyzeGoModulesGap(existingModulesPath, expectedModulesPath) // Pass expectedModulesPath
	if err != nil {
		t.Fatalf("AnalyzeGoModulesGap failed: %v", err)
	}
	if !result.GapFound {
		t.Errorf("Expected gaps, but found none")
	}
	expectedMissing := []string{"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/gapanalyzer"}
	if !reflect.DeepEqual(result.MissingModules, expectedMissing) {
		t.Errorf("Expected missing modules %v, got %v", expectedMissing, result.MissingModules)
	}
	if len(result.ExtraModules) != 0 {
		t.Errorf("Expected no extra modules, got %v", result.ExtraModules)
	}

	// Test Case 3: Extra modules
	createDummyModulesFile(t, existingModulesPath, []string{
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/scanmodules",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/gapanalyzer",
		"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/newmodule", // Extra
	})
	result, err = AnalyzeGoModulesGap(existingModulesPath, expectedModulesPath) // Pass expectedModulesPath
	if err != nil {
		t.Fatalf("AnalyzeGoModulesGap failed: %v", err)
	}
	if !result.GapFound {
		t.Errorf("Expected gaps, but found none")
	}
	if len(result.MissingModules) != 0 {
		t.Errorf("Expected no missing modules, got %v", result.MissingModules)
	}
	expectedExtra := []string{"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/newmodule"}
	if !reflect.DeepEqual(result.ExtraModules, expectedExtra) {
		t.Errorf("Expected extra modules %v, got %v", expectedExtra, result.ExtraModules)
	}
}

func TestGenerateGapAnalysisReport(t *testing.T) {
	tempDir := t.TempDir()
	outputPathJSON := filepath.Join(tempDir, "gap-analysis-initial.json")
	outputPathMD := filepath.Join(tempDir, "GAP_ANALYSIS_INIT.md")

	analysisResult := &GapAnalysisResult{
		GapFound: true,
		GapDetails: map[string]interface{}{
			"missing_modules": []string{"moduleC"},
			"extra_modules":   []string{"moduleD"},
		},
		Timestamp:       "2025-06-30T00:00:00Z",
		ExistingModules: []string{"moduleA", "moduleB", "moduleD"},
		ExpectedModules: []string{"moduleA", "moduleB", "moduleC"},
		MissingModules:  []string{"moduleC"},
		ExtraModules:    []string{"moduleD"},
	}

	err := GenerateGapAnalysisReport(outputPathJSON, outputPathMD, analysisResult)
	if err != nil {
		t.Fatalf("GenerateGapAnalysisReport failed: %v", err)
	}

	// Verify JSON output
	jsonBytes, err := os.ReadFile(outputPathJSON) // Use os.ReadFile
	if err != nil {
		t.Fatalf("Failed to read JSON output: %v", err)
	}
	var readResult GapAnalysisResult
	err = json.Unmarshal(jsonBytes, &readResult)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON output: %v", err)
	}
	if !reflect.DeepEqual(readResult.MissingModules, analysisResult.MissingModules) {
		t.Errorf("JSON missing modules mismatch: expected %v, got %v", analysisResult.MissingModules, readResult.MissingModules)
	}
	if !reflect.DeepEqual(readResult.ExtraModules, analysisResult.ExtraModules) {
		t.Errorf("JSON extra modules mismatch: expected %v, got %v", analysisResult.ExtraModules, readResult.ExtraModules)
	}

	// Verify Markdown output
	markdownContent, err := os.ReadFile(outputPathMD) // Use os.ReadFile
	if err != nil {
		t.Fatalf("Failed to read Markdown output: %v", err)
	}
	mdString := string(markdownContent)
	if !strings.Contains(mdString, "Rapport d'Analyse d'Écart des Modules Go") {
		t.Errorf("Markdown content missing header")
	}
	if !strings.Contains(mdString, "Modules Manquants (Attendus mais non trouvés) :\n- moduleC") {
		t.Errorf("Markdown content missing missing modules")
	}
	if !strings.Contains(mdString, "Modules Supplémentaires (Trouvés mais non attendus) :\n- moduleD") {
		t.Errorf("Markdown content missing extra modules")
	}
}
