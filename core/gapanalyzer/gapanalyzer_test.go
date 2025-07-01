package gapanalyzer

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time" // Add time import for GapAnalysis
	// Import the main package of gapanalyzer to access its types and functions
	// This is typically not how you test, but given the structure,
	// we're testing the package's exported functions.
	// For actual unit tests, you'd test functions directly within the same package.
	// However, the original test implies running the main logic.
	// Let's assume for now that the test should use the types from the package itself.
)

// Helper function to create a dummy modules.json file for testing
func createDummyModulesFile(t *testing.T, path string, content []ModuleInfo) { // Changed content type
	repoStructure := RepositoryStructure{ // Wrap in RepositoryStructure
		Modules:      content,
		TotalModules: len(content),
		GeneratedAt:  time.Now(),
		RootPath:     "test_root",
	}
	jsonContent, err := json.Marshal(repoStructure)
	if err != nil {
		t.Fatalf("Failed to marshal dummy content: %v", err)
	}
	err = os.WriteFile(path, jsonContent, 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy modules file: %v", err)
	}
}

func TestAnalyzeGaps(t *testing.T) { // Renamed function
	tempDir := t.TempDir()
	modulesJSONPath := filepath.Join(tempDir, "modules.json")
	gapAnalysisJSONPath := filepath.Join(tempDir, "gap-analysis.json")
	gapAnalysisMDPath := filepath.Join(tempDir, "gap-analysis.md")

	// Define a common set of expected modules for consistent testing
	commonExpectedModules := GetExpectedModules() // Use exported function

	// Test Case 1: No gaps
	existingModules := []ModuleInfo{
		{Name: "core/scanmodules", Path: "path/to/scanmodules"},
		{Name: "core/gapanalyzer", Path: "path/to/gapanalyzer"},
		{Name: "core/reporting", Path: "path/to/reporting"},
		{Name: "cmd/auto-roadmap-runner", Path: "path/to/auto-roadmap-runner"},
		{Name: "tests/validation", Path: "path/to/tests/validation"},
		// Add more modules as per GetExpectedModules if needed for 100% match
		{Name: "projet/mcp/servers/gateway", Path: "path/to/gateway"},
	}
	createDummyModulesFile(t, modulesJSONPath, existingModules)

	// Simulate running the main logic
	repoStructure := RepositoryStructure{Modules: existingModules}
	analysis := AnalyzeGaps(repoStructure, commonExpectedModules) // Use exported function

	if analysis.ComplianceRate != 100.0 {
		t.Errorf("Expected 100%% compliance, got %.1f%%", analysis.ComplianceRate)
	}
	if len(analysis.MissingModules) != 0 {
		t.Errorf("Expected no missing modules, got %v", analysis.MissingModules)
	}
	if len(analysis.ExtraModules) != 0 {
		t.Errorf("Expected no extra modules, got %v", analysis.ExtraModules)
	}

	// Test Case 2: Missing modules
	missingModules := []ModuleInfo{
		{Name: "core/scanmodules", Path: "path/to/scanmodules"},
	}
	createDummyModulesFile(t, modulesJSONPath, missingModules)
	repoStructure = RepositoryStructure{Modules: missingModules}
	analysis = AnalyzeGaps(repoStructure, commonExpectedModules)

	if analysis.ComplianceRate == 100.0 {
		t.Errorf("Expected less than 100%% compliance, got %.1f%%", analysis.ComplianceRate)
	}
	if len(analysis.MissingModules) == 0 {
		t.Errorf("Expected missing modules, but found none")
	}
	// Check for a specific missing module
	foundMissing := false
	for _, m := range analysis.MissingModules {
		if m.Name == "core/gapanalyzer" { // Example of a module that should be missing
			foundMissing = true
			break
		}
	}
	if !foundMissing {
		t.Errorf("Expected 'core/gapanalyzer' to be missing, but it was not")
	}
	if len(analysis.ExtraModules) != 0 {
		t.Errorf("Expected no extra modules, got %v", analysis.ExtraModules)
	}

	// Test Case 3: Extra modules
	extraModules := []ModuleInfo{
		{Name: "core/scanmodules", Path: "path/to/scanmodules"},
		{Name: "core/gapanalyzer", Path: "path/to/gapanalyzer"},
		{Name: "core/reporting", Path: "path/to/reporting"},
		{Name: "cmd/auto-roadmap-runner", Path: "path/to/auto-roadmap-runner"},
		{Name: "tests/validation", Path: "path/to/tests/validation"},
		{Name: "projet/mcp/servers/gateway", Path: "path/to/gateway"},
		{Name: "extra/unwanted/module", Path: "path/to/extra"}, // Extra
	}
	createDummyModulesFile(t, modulesJSONPath, extraModules)
	repoStructure = RepositoryStructure{Modules: extraModules}
	analysis = AnalyzeGaps(repoStructure, commonExpectedModules)

	if analysis.ComplianceRate != 100.0 { // Should still be 100% if all required are present
		t.Errorf("Compliance rate should be 100%% if all required modules are present, got %.1f%%", analysis.ComplianceRate)
	}
	if len(analysis.MissingModules) != 0 {
		t.Errorf("Expected no missing modules, got %v", analysis.MissingModules)
	}
	if len(analysis.ExtraModules) == 0 {
		t.Errorf("Expected extra modules, but found none")
	}
	// Check for a specific extra module
	foundExtra := false
	for _, m := range analysis.ExtraModules {
		if m.Name == "extra/unwanted/module" {
			foundExtra = true
			break
		}
	}
	if !foundExtra {
		t.Errorf("Expected 'extra/unwanted/module' to be extra, but it was not")
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

func TestGenerateMarkdownReport(t *testing.T) { // Renamed function
	analysisResult := GapAnalysis{ // Use GapAnalysis type
		AnalysisDate:   time.Now(),
		Summary:        "Test summary for markdown report.",
		TotalExpected:  3,
		TotalFound:     2,
		ComplianceRate: 66.7,
		MissingModules: []ExpectedModule{
			{Name: "moduleC", Path: "path/to/moduleC", Required: true, Description: "Missing required module"},
		},
		ExtraModules: []ModuleInfo{
			{Name: "moduleD", Path: "path/to/moduleD", Description: "Extra module"},
		},
		MatchingModules: []ModuleInfo{
			{Name: "moduleA", Path: "path/to/moduleA"},
			{Name: "moduleB", Path: "path/to/moduleB"},
		},
		Recommendations: []string{"Recommendation 1", "Recommendation 2"},
	}

	markdownContent := GenerateMarkdownReport(analysisResult) // Use exported function

	if !strings.Contains(markdownContent, "📊 Analyse d'Écart des Modules") {
		t.Errorf("Markdown content missing header")
	}
	if !strings.Contains(markdownContent, "❌ Modules Manquants") {
		t.Errorf("Markdown content missing missing modules section")
	}
	if !strings.Contains(markdownContent, "- **REQUIS** `moduleC` (path/to/moduleC)\n  - **Catégorie:** \n  - **Description:** Missing required module") {
		t.Errorf("Markdown content missing details for missing module")
	}
	if !strings.Contains(markdownContent, "⚠️ Modules Supplémentaires") {
		t.Errorf("Markdown content missing extra modules section")
	}
	if !strings.Contains(markdownContent, "- `moduleD` - Extra module") {
		t.Errorf("Markdown content missing details for extra module")
	}
	if !strings.Contains(markdownContent, "🎯 Recommandations") {
		t.Errorf("Markdown content missing recommendations section")
	}
	if !strings.Contains(markdownContent, "1. Recommendation 1") {
		t.Errorf("Markdown content missing recommendation 1")
	}
}
