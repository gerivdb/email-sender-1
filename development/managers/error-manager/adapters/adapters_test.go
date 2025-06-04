package adapters

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestNewScriptInventoryAdapter(t *testing.T) {
	config := ScriptInventoryConfig{
		ScriptInventoryPath: "test_path",
		PythonExecutable:    "python",
		WorkingDirectory:    os.TempDir(),
		TimeoutSeconds:      10,
	}

	adapter := NewScriptInventoryAdapter(config)

	if adapter.scriptPath != config.ScriptInventoryPath {
		t.Errorf("Expected scriptPath %s, got %s", config.ScriptInventoryPath, adapter.scriptPath)
	}

	expectedTimeout := 10 * time.Second
	if adapter.timeout != expectedTimeout {
		t.Errorf("Expected timeout %v, got %v", expectedTimeout, adapter.timeout)
	}
}

func TestValidatePaths(t *testing.T) {
	// Créer un répertoire temporaire pour les tests
	tempDir, err := os.MkdirTemp("", "script_adapter_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Créer un fichier script temporaire
	scriptPath := filepath.Join(tempDir, "test_script.ps1")
	if err := os.WriteFile(scriptPath, []byte("# Test script"), 0644); err != nil {
		t.Fatalf("Failed to create test script: %v", err)
	}

	config := ScriptInventoryConfig{
		ScriptInventoryPath: scriptPath,
		WorkingDirectory:    tempDir,
		TimeoutSeconds:      5,
	}

	adapter := NewScriptInventoryAdapter(config)

	// Test avec des chemins valides
	if err := adapter.validatePaths(); err != nil {
		t.Errorf("validatePaths should succeed with valid paths: %v", err)
	}

	// Test avec chemin inexistant
	adapter.scriptPath = "/nonexistent/path"
	if err := adapter.validatePaths(); err == nil {
		t.Error("validatePaths should fail with nonexistent path")
	}
}

func TestConvertToScriptInfo(t *testing.T) {
	adapter := &ScriptInventoryAdapter{}

	testData := map[string]interface{}{
		"Path": "test/path.ps1",
		"Type": "PowerShell",
		"Size": float64(1024),
		"Hash": "abc123",
		"Dependencies": []interface{}{"dep1", "dep2"},
		"Metadata": map[string]interface{}{
			"version": "1.0",
			"author":  "test",
		},
	}

	result := adapter.convertToScriptInfo(testData)

	if result.Path != "test/path.ps1" {
		t.Errorf("Expected Path 'test/path.ps1', got '%s'", result.Path)
	}

	if result.Type != "PowerShell" {
		t.Errorf("Expected Type 'PowerShell', got '%s'", result.Type)
	}

	if result.Size != 1024 {
		t.Errorf("Expected Size 1024, got %d", result.Size)
	}

	if len(result.Dependencies) != 2 {
		t.Errorf("Expected 2 dependencies, got %d", len(result.Dependencies))
	}

	if result.Metadata["version"] != "1.0" {
		t.Errorf("Expected version '1.0', got '%s'", result.Metadata["version"])
	}
}

func TestDuplicationErrorHandler(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "duplication_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	handler := NewDuplicationErrorHandler(tempDir, time.Second)

	// Tester la génération d'erreur de duplication
	dupError := handler.GenerateDuplicationError("source.go", "duplicate.go", 0.95)

	if dupError.SourceFile != "source.go" {
		t.Errorf("Expected SourceFile 'source.go', got '%s'", dupError.SourceFile)
	}

	if dupError.DuplicateFile != "duplicate.go" {
		t.Errorf("Expected DuplicateFile 'duplicate.go', got '%s'", dupError.DuplicateFile)
	}

	if dupError.SimilarityScore != 0.95 {
		t.Errorf("Expected SimilarityScore 0.95, got %f", dupError.SimilarityScore)
	}

	if dupError.Severity != "ERROR" {
		t.Errorf("Expected Severity 'ERROR' for high similarity, got '%s'", dupError.Severity)
	}
}

func TestProcessDuplicationReport(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "duplication_report_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Créer un rapport de test
	report := DuplicationReport{
		GeneratedAt:  time.Now(),
		TotalFiles:   2,
		Duplications: []DuplicationError{
			{
				ID:              "test1",
				Timestamp:       time.Now(),
				SourceFile:      "file1.go",
				DuplicateFile:   "file2.go",
				SimilarityScore: 0.85,
				ErrorCode:       "SCRIPT_DUPLICATION",
				Severity:        "WARNING",
			},
		},
		Summary: map[string]int{
			"total_duplications": 1,
		},
	}

	reportPath := filepath.Join(tempDir, "test_report.json")
	reportData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		t.Fatalf("Failed to marshal report: %v", err)
	}

	if err := os.WriteFile(reportPath, reportData, 0644); err != nil {
		t.Fatalf("Failed to write report file: %v", err)
	}

	// Tester le traitement du rapport
	handler := NewDuplicationErrorHandler(tempDir, time.Second)
	
	var processedErrors []DuplicationError
	handler.SetErrorCallback(func(err DuplicationError) {
		processedErrors = append(processedErrors, err)
	})

	if err := handler.ProcessDuplicationReport(reportPath); err != nil {
		t.Errorf("Failed to process duplication report: %v", err)
	}

	if len(processedErrors) != 1 {
		t.Errorf("Expected 1 processed error, got %d", len(processedErrors))
	}

	if processedErrors[0].ID != "test1" {
		t.Errorf("Expected processed error ID 'test1', got '%s'", processedErrors[0].ID)
	}
}

func TestCreateEnhancedErrorEntry(t *testing.T) {
	baseError := map[string]interface{}{
		"id":             "test123",
		"timestamp":      time.Now(),
		"message":        "Test error message",
		"module":         "test-module",
		"error_code":     "TEST001",
		"severity":       "ERROR",
		"manager_context": map[string]interface{}{
			"component": "test",
		},
	}

	dupContext := &DuplicationContext{
		SourceFile:       "test.go",
		DuplicateFiles:   []string{"test_copy.go"},
		SimilarityScores: map[string]float64{"test_copy.go": 0.95},
		DetectionMethod:  "script_analysis",
		LastDetection:    time.Now(),
	}

	enhanced := CreateEnhancedErrorEntry(baseError, dupContext)

	if enhanced.ID != "test123" {
		t.Errorf("Expected ID 'test123', got '%s'", enhanced.ID)
	}

	if enhanced.DuplicationContext == nil {
		t.Error("Expected DuplicationContext to be set")
	}

	if enhanced.DuplicationContext.SourceFile != "test.go" {
		t.Errorf("Expected SourceFile 'test.go', got '%s'", enhanced.DuplicationContext.SourceFile)
	}
}

func TestCalculateCorrelationScore(t *testing.T) {
	errorEntry := &EnhancedErrorEntry{
		ID:        "test123",
		Timestamp: time.Now(),
		Module:    "test-module",
		Message:   "Error in test.go",
	}

	duplication := DuplicationError{
		ID:              "dup123",
		Timestamp:       time.Now(),
		SourceFile:      "test.go",
		SimilarityScore: 0.95,
	}

	score := CalculateCorrelationScore(errorEntry, duplication)

	if score <= 0 {
		t.Errorf("Expected correlation score > 0, got %f", score)
	}

	if score > 1 {
		t.Errorf("Expected correlation score <= 1, got %f", score)
	}
}
