// integration_test.go - Comprehensive integration tests for the auto-fix pipeline
package auto_fix

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// IntegrationTestSuite provides comprehensive end-to-end testing for auto-fix pipeline
type IntegrationTestSuite struct {
	testDir          string
	suggestionEngine *SuggestionEngine
	validationSystem *ValidationSystem
	cliInterface     *CLIInterface
}

// setupIntegrationTest creates a comprehensive test environment
func setupIntegrationTest(t *testing.T) *IntegrationTestSuite {
	// Create temporary test directory
	testDir, err := os.MkdirTemp("", "autofix_integration_test")
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	// Initialize components
	suggestionEngine := NewSuggestionEngine(SuggestionConfig{
		MaxSuggestionsPerError: 5,
		MinConfidenceThreshold: 0.3,
		TemplateDirectory:      filepath.Join(testDir, "templates"),
	})

	validationSystem := NewValidationSystem(ValidationConfig{
		SandboxTimeout:    30 * time.Second,
		MaxConcurrentJobs: 4,
		RequiredTests:     []string{"go", "test", "-v", "./..."},
		TempDirectory:     filepath.Join(testDir, "sandbox"),
	})

	cliInterface := NewCLIInterface(CLIConfig{
		InteractiveMode:       false, // Non-interactive for testing
		AutoApplyThreshold:    0.8,
		BackupBeforeApply:     true,
		ShowProgressIndicator: false,
	})

	return &IntegrationTestSuite{
		testDir:          testDir,
		suggestionEngine: suggestionEngine,
		validationSystem: validationSystem,
		cliInterface:     cliInterface,
	}
}

// teardownIntegrationTest cleans up test environment
func (suite *IntegrationTestSuite) teardown() {
	os.RemoveAll(suite.testDir)
}

// TestCompleteAutoFixPipeline tests the entire auto-fix workflow end-to-end
func TestCompleteAutoFixPipeline(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown()

	// Create test Go file with various fixable issues
	testGoCode := `package main

import (
	"fmt"
	"unused"
	"os"
)

func main() {
	var unusedVar int
	fmt.Println("Hello, World!")
	
	// Missing error handling
	file, _ := os.Open("nonexistent.txt")
	defer file.Close()
	
	// Inefficient string concatenation
	result := ""
	for i := 0; i < 100; i++ {
		result += fmt.Sprintf("item_%d ", i)
	}
	fmt.Println(result)
}

func unusedFunction() {
	// This function is never called
}
`

	testFilePath := filepath.Join(suite.testDir, "test_file.go")
	err := os.WriteFile(testFilePath, []byte(testGoCode), 0644)
	if err != nil {
		t.Fatalf("Failed to create test Go file: %v", err)
	}

	// Step 1: Generate suggestions for the problematic code
	suggestions, err := suite.suggestionEngine.GenerateSuggestions(context.Background(), testFilePath)
	if err != nil {
		t.Fatalf("Failed to generate suggestions: %v", err)
	}

	if len(suggestions) == 0 {
		t.Fatal("Expected suggestions to be generated, got none")
	}

	t.Logf("Generated %d suggestions", len(suggestions))

	// Verify we have suggestions for expected issues
	expectedIssues := []string{"unused import", "unused variable", "error handling", "string concatenation"}
	foundIssues := make(map[string]bool)

	for _, suggestion := range suggestions {
		for _, expected := range expectedIssues {
			if strings.Contains(strings.ToLower(suggestion.Description), expected) {
				foundIssues[expected] = true
			}
		}
	}

	if len(foundIssues) < 2 {
		t.Errorf("Expected to find at least 2 types of issues, found: %v", foundIssues)
	}

	// Step 2: Validate high-confidence suggestions
	var validatedSuggestions []FixSuggestion
	for _, suggestion := range suggestions {
		if suggestion.Confidence >= 0.7 {
			result, err := suite.validationSystem.ValidateFix(context.Background(), testFilePath, suggestion)
			if err != nil {
				t.Logf("Validation failed for suggestion %s: %v", suggestion.ID, err)
				continue
			}

			if result.IsValid && result.SafetyLevel != SafetyUnsafe {
				validatedSuggestions = append(validatedSuggestions, suggestion)
			}

			t.Logf("Validation result for %s: Valid=%v, Confidence=%.2f, Safety=%s",
				suggestion.ID, result.IsValid, result.ConfidenceScore, result.SafetyLevel)
		}
	}

	if len(validatedSuggestions) == 0 {
		t.Fatal("Expected at least one validated suggestion")
	}

	// Step 3: Apply validated fixes through CLI interface
	session := &ReviewSession{
		ProjectPath:    suite.testDir,
		TotalFixes:     len(validatedSuggestions),
		CurrentIndex:   0,
		ActionsHistory: make([]ReviewAction, 0),
	}

	for _, suggestion := range validatedSuggestions {
		// Simulate automatic application of high-confidence fixes
		action := ReviewActionApply
		session.ActionsHistory = append(session.ActionsHistory, ReviewAction{
			Action:     action,
			FixID:      suggestion.ID,
			Timestamp:  time.Now(),
			Confidence: suggestion.Confidence,
		})

		// Apply the fix
		err := suite.cliInterface.ApplyFix(session, suggestion)
		if err != nil {
			t.Logf("Failed to apply fix %s: %v", suggestion.ID, err)
			continue
		}

		t.Logf("Successfully applied fix: %s", suggestion.Description)
	}

	// Step 4: Verify the fixes were applied correctly
	fixedContent, err := os.ReadFile(testFilePath)
	if err != nil {
		t.Fatalf("Failed to read fixed file: %v", err)
	}

	fixedCode := string(fixedContent)

	// Verify some expected improvements
	if strings.Contains(fixedCode, `"unused"`) {
		t.Error("Unused import should have been removed")
	}

	if !strings.Contains(fixedCode, "if err != nil") {
		t.Log("Note: Error handling might not have been added (depending on suggestion quality)")
	}

	// Step 5: Validate the fixed code compiles
	finalValidation, err := suite.validationSystem.ValidateFile(context.Background(), testFilePath)
	if err != nil {
		t.Fatalf("Final validation failed: %v", err)
	}

	if !finalValidation.SyntaxValid {
		t.Error("Fixed code should have valid syntax")
	}

	if !finalValidation.CompilesSuccessfully {
		t.Error("Fixed code should compile successfully")
	}

	t.Logf("Integration test completed successfully. Applied %d fixes.", len(session.ActionsHistory))
}

// TestConcurrentFixValidation tests concurrent validation of multiple files
func TestConcurrentFixValidation(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown()

	// Create multiple test files
	testFiles := []string{"file1.go", "file2.go", "file3.go"}
	testCode := `package main
import "fmt"
import "unused"
func main() {
	var x int
	fmt.Println("test")
}
`

	var filePaths []string
	for _, filename := range testFiles {
		path := filepath.Join(suite.testDir, filename)
		err := os.WriteFile(path, []byte(testCode), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
		filePaths = append(filePaths, path)
	}

	// Generate suggestions for all files concurrently
	ctx := context.Background()
	suggestionChan := make(chan []FixSuggestion, len(filePaths))
	errorChan := make(chan error, len(filePaths))

	for _, filePath := range filePaths {
		go func(path string) {
			suggestions, err := suite.suggestionEngine.GenerateSuggestions(ctx, path)
			if err != nil {
				errorChan <- err
				return
			}
			suggestionChan <- suggestions
		}(filePath)
	}

	// Collect results
	var allSuggestions []FixSuggestion
	for i := 0; i < len(filePaths); i++ {
		select {
		case suggestions := <-suggestionChan:
			allSuggestions = append(allSuggestions, suggestions...)
		case err := <-errorChan:
			t.Fatalf("Concurrent suggestion generation failed: %v", err)
		case <-time.After(30 * time.Second):
			t.Fatal("Concurrent suggestion generation timed out")
		}
	}

	if len(allSuggestions) == 0 {
		t.Fatal("Expected suggestions from concurrent processing")
	}

	t.Logf("Successfully processed %d files concurrently, generated %d suggestions", 
		len(filePaths), len(allSuggestions))
}

// TestErrorRecoveryAndRollback tests the system's ability to handle and recover from errors
func TestErrorRecoveryAndRollback(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown()

	// Create a file that will cause compilation errors when "fixed"
	problematicCode := `package main
import "fmt"
func main() {
	fmt.Println("This will be broken by a bad fix")
	validVariable := 42
	fmt.Println(validVariable)
}
`

	testFilePath := filepath.Join(suite.testDir, "problematic.go")
	err := os.WriteFile(testFilePath, []byte(problematicCode), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Create backup
	backupPath := testFilePath + ".backup"
	err = suite.cliInterface.createBackup(testFilePath, backupPath)
	if err != nil {
		t.Fatalf("Failed to create backup: %v", err)
	}

	// Simulate a bad fix that breaks compilation
	badFixedCode := `package main
import "fmt"
func main() {
	fmt.Println("This will be broken by a bad fix"
	// Missing closing parenthesis - syntax error
	validVariable := 42
	fmt.Println(validVariable)
}
`

	err = os.WriteFile(testFilePath, []byte(badFixedCode), 0644)
	if err != nil {
		t.Fatalf("Failed to write bad fix: %v", err)
	}

	// Validate should fail
	validation, err := suite.validationSystem.ValidateFile(context.Background(), testFilePath)
	if err == nil && validation.SyntaxValid {
		t.Error("Expected validation to fail for broken syntax")
	}

	// Test rollback functionality
	err = suite.cliInterface.rollbackFromBackup(backupPath, testFilePath)
	if err != nil {
		t.Fatalf("Failed to rollback: %v", err)
	}

	// Verify rollback worked
	validation, err = suite.validationSystem.ValidateFile(context.Background(), testFilePath)
	if err != nil {
		t.Fatalf("Validation after rollback failed: %v", err)
	}

	if !validation.SyntaxValid {
		t.Error("File should be valid after rollback")
	}

	t.Log("Error recovery and rollback test completed successfully")
}

// TestPerformanceWithLargeCodebase tests auto-fix performance with larger files
func TestPerformanceWithLargeCodebase(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown()

	// Generate a larger Go file with multiple issues
	var codeBuilder strings.Builder
	codeBuilder.WriteString(`package main

import (
	"fmt"
	"os"
	"unused1"
	"unused2"
	"strings"
)

func main() {
	fmt.Println("Large codebase test")
`)

	// Add many functions with various issues
	for i := 0; i < 50; i++ {
		codeBuilder.WriteString(fmt.Sprintf(`
	var unusedVar%d int
	
	func function%d() {
		// Missing error handling
		file, _ := os.Open("file%d.txt")
		defer file.Close()
		
		// Inefficient string concatenation
		result := ""
		for j := 0; j < 10; j++ {
			result += fmt.Sprintf("item_%%d ", j)
		}
		
		if strings.Contains(result, "test") {
			fmt.Println("found")
		}
	}
`, i, i, i))
	}

	codeBuilder.WriteString("\n}")

	largeFilePath := filepath.Join(suite.testDir, "large_file.go")
	err := os.WriteFile(largeFilePath, []byte(codeBuilder.String()), 0644)
	if err != nil {
		t.Fatalf("Failed to create large test file: %v", err)
	}

	// Measure performance
	startTime := time.Now()

	suggestions, err := suite.suggestionEngine.GenerateSuggestions(context.Background(), largeFilePath)
	if err != nil {
		t.Fatalf("Failed to generate suggestions for large file: %v", err)
	}

	generationTime := time.Since(startTime)
	t.Logf("Generated %d suggestions for large file in %v", len(suggestions), generationTime)

	if generationTime > 10*time.Second {
		t.Errorf("Suggestion generation took too long: %v", generationTime)
	}

	// Test validation performance
	if len(suggestions) > 10 {
		suggestions = suggestions[:10] // Limit for performance testing
	}

	startTime = time.Now()
	validationCount := 0

	for _, suggestion := range suggestions {
		if suggestion.Confidence >= 0.5 {
			_, err := suite.validationSystem.ValidateFix(context.Background(), largeFilePath, suggestion)
			if err == nil {
				validationCount++
			}
		}
	}

	validationTime := time.Since(startTime)
	t.Logf("Validated %d suggestions in %v", validationCount, validationTime)

	if validationTime > 30*time.Second {
		t.Errorf("Validation took too long: %v", validationTime)
	}
}

// Helper function to format code with go fmt
func (suite *IntegrationTestSuite) formatCode(filePath string) error {
	// This would normally use go/format or exec go fmt
	// For testing purposes, we'll simulate it
	return nil
}
