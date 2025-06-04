package auto_fix

import (
	"context"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// ValidationResult represents the result of validating a proposed fix
type ValidationResult struct {
	IsValid        bool                `json:"is_valid"`
	ConfidenceScore float64            `json:"confidence_score"`
	SafetyLevel    SafetyLevel         `json:"safety_level"`
	TestResults    []TestResult        `json:"test_results"`
	CompilationOK  bool               `json:"compilation_ok"`
	StaticCheckOK  bool               `json:"static_check_ok"`
	TestsPassing   bool               `json:"tests_passing"`
	Errors         []string           `json:"errors,omitempty"`
	Warnings       []string           `json:"warnings,omitempty"`
	Metrics        ValidationMetrics   `json:"metrics"`
	Duration       time.Duration       `json:"duration"`
}

// TestResult represents the result of running a specific test
type TestResult struct {
	TestName  string        `json:"test_name"`
	Passed    bool          `json:"passed"`
	Output    string        `json:"output"`
	Error     string        `json:"error,omitempty"`
	Duration  time.Duration `json:"duration"`
}

// ValidationMetrics contains metrics about the validation process
type ValidationMetrics struct {
	CodeCoverage      float64 `json:"code_coverage"`
	ComplexityBefore  int     `json:"complexity_before"`
	ComplexityAfter   int     `json:"complexity_after"`
	LinesChanged      int     `json:"lines_changed"`
	FilesAffected     int     `json:"files_affected"`
	PerformanceImpact float64 `json:"performance_impact"`
}

// SandboxConfig defines configuration for the validation sandbox
type SandboxConfig struct {
	TempDir            string        `json:"temp_dir"`
	Timeout            time.Duration `json:"timeout"`
	MaxMemory          int64         `json:"max_memory_mb"`
	EnableTests        bool          `json:"enable_tests"`
	EnableStaticCheck  bool          `json:"enable_static_check"`
	EnableBenchmarks   bool          `json:"enable_benchmarks"`
	AllowNetworking    bool          `json:"allow_networking"`
	PreserveArtifacts  bool          `json:"preserve_artifacts"`
}

// ValidationSystem handles validation of proposed fixes
type ValidationSystem struct {
	config      SandboxConfig
	mutex       sync.RWMutex
	activeTests map[string]*TestExecution
	metrics     *ValidationMetrics
}

// TestExecution tracks an ongoing test execution
type TestExecution struct {
	ID        string
	StartTime time.Time
	Context   context.Context
	Cancel    context.CancelFunc
	TempDir   string
}

// NewValidationSystem creates a new validation system
func NewValidationSystem(config SandboxConfig) *ValidationSystem {
	if config.Timeout == 0 {
		config.Timeout = 5 * time.Minute
	}
	if config.MaxMemory == 0 {
		config.MaxMemory = 512 // 512MB default
	}
	if config.TempDir == "" {
		config.TempDir = os.TempDir()
	}

	return &ValidationSystem{
		config:      config,
		activeTests: make(map[string]*TestExecution),
		metrics:     &ValidationMetrics{},
	}
}

// ValidateProposedFix validates a proposed fix using sandbox testing
func (vs *ValidationSystem) ValidateProposedFix(fix *FixSuggestion, originalCode string) (*ValidationResult, error) {
	startTime := time.Now()
	
	result := &ValidationResult{
		ConfidenceScore: 0.0,
		SafetyLevel:     SafetyLevelLow,
		TestResults:     []TestResult{},
		Metrics:         ValidationMetrics{},
	}

	// Create sandbox environment
	sandboxDir, err := vs.createSandbox(fix, originalCode)
	if err != nil {
		return result, fmt.Errorf("failed to create sandbox: %w", err)
	}
	defer vs.cleanupSandbox(sandboxDir)

	// Execute validation steps
	validationSteps := []struct {
		name string
		fn   func(string, *FixSuggestion, string) error
	}{
		{"syntax_check", vs.validateSyntax},
		{"compilation_check", vs.validateCompilation},
		{"static_analysis", vs.validateStaticAnalysis},
		{"test_execution", vs.validateTests},
		{"performance_impact", vs.validatePerformance},
	}

	for _, step := range validationSteps {
		if err := step.fn(sandboxDir, fix, originalCode); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("%s failed: %v", step.name, err))
		}
	}

	// Calculate confidence score
	result.ConfidenceScore = vs.calculateConfidenceScore(result)
	result.SafetyLevel = vs.determineSafetyLevel(result)
	result.IsValid = result.ConfidenceScore >= 0.7 && len(result.Errors) == 0
	result.Duration = time.Since(startTime)

	return result, nil
}

// createSandbox creates a temporary environment for testing the fix
func (vs *ValidationSystem) createSandbox(fix *FixSuggestion, originalCode string) (string, error) {
	// Create temporary directory
	sandboxDir, err := ioutil.TempDir(vs.config.TempDir, "autofix_sandbox_*")
	if err != nil {
		return "", fmt.Errorf("failed to create temp dir: %w", err)
	}

	// Apply the fix to create modified code
	modifiedCode, err := vs.applyFixToCode(originalCode, fix)
	if err != nil {
		os.RemoveAll(sandboxDir)
		return "", fmt.Errorf("failed to apply fix: %w", err)
	}

	// Write modified code to sandbox
	codeFile := filepath.Join(sandboxDir, "main.go")
	if err := ioutil.WriteFile(codeFile, []byte(modifiedCode), 0644); err != nil {
		os.RemoveAll(sandboxDir)
		return "", fmt.Errorf("failed to write code file: %w", err)
	}

	// Copy test files if they exist
	if err := vs.copyTestFiles(sandboxDir); err != nil {
		// Non-fatal, log warning
		fmt.Printf("Warning: failed to copy test files: %v\n", err)
	}

	// Create go.mod if it doesn't exist
	goModPath := filepath.Join(sandboxDir, "go.mod")
	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		goModContent := `module sandbox_test

go 1.21

require (
	github.com/stretchr/testify v1.8.4
)
`
		if err := ioutil.WriteFile(goModPath, []byte(goModContent), 0644); err != nil {
			os.RemoveAll(sandboxDir)
			return "", fmt.Errorf("failed to create go.mod: %w", err)
		}
	}

	return sandboxDir, nil
}

// applyFixToCode applies the suggested fix to the original code
func (vs *ValidationSystem) applyFixToCode(originalCode string, fix *FixSuggestion) (string, error) {
	switch fix.Category {
	case "unused_imports":
		return vs.applyUnusedImportsFix(originalCode, fix)
	case "unused_variables":
		return vs.applyUnusedVariablesFix(originalCode, fix)
	case "formatting":
		return vs.applyFormattingFix(originalCode, fix)
	case "error_handling":
		return vs.applyErrorHandlingFix(originalCode, fix)
	default:
		// For other types, use regex-based replacement
		return vs.applyRegexFix(originalCode, fix)
	}
}

// applyUnusedImportsFix removes unused imports
func (vs *ValidationSystem) applyUnusedImportsFix(code string, fix *FixSuggestion) (string, error) {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, "", code, parser.ParseComments)
	if err != nil {
		return "", fmt.Errorf("failed to parse code: %w", err)
	}

	// Find and remove unused imports
	for _, imp := range node.Imports {
		if imp.Path != nil {
			importPath := strings.Trim(imp.Path.Value, `"`)
			if vs.isImportUnused(node, importPath) {
				// Remove this import
				code = vs.removeImportFromCode(code, importPath)
			}
		}
	}

	return code, nil
}

// applyUnusedVariablesFix removes or modifies unused variables
func (vs *ValidationSystem) applyUnusedVariablesFix(code string, fix *FixSuggestion) (string, error) {
	// Simple implementation - replace unused variables with blank identifier
	for _, pattern := range fix.Patterns {
		if strings.Contains(pattern, "var ") {
			// Replace with blank identifier assignment
			replacement := strings.Replace(pattern, "var ", "_ = ", 1)
			code = strings.Replace(code, pattern, replacement, 1)
		}
	}
	return code, nil
}

// applyFormattingFix applies formatting corrections
func (vs *ValidationSystem) applyFormattingFix(code string, fix *FixSuggestion) (string, error) {
	// Use gofmt to format the code
	cmd := exec.Command("gofmt")
	cmd.Stdin = strings.NewReader(code)
	
	output, err := cmd.Output()
	if err != nil {
		return code, fmt.Errorf("gofmt failed: %w", err)
	}
	
	return string(output), nil
}

// applyErrorHandlingFix improves error handling
func (vs *ValidationSystem) applyErrorHandlingFix(code string, fix *FixSuggestion) (string, error) {
	// Add proper error checking where missing
	for _, pattern := range fix.Patterns {
		if strings.Contains(pattern, "err :=") && !strings.Contains(pattern, "if err") {
			// Add error check after error assignment
			lines := strings.Split(code, "\n")
			for i, line := range lines {
				if strings.Contains(line, pattern) {
					// Insert error check after this line
					errorCheck := "\tif err != nil {\n\t\treturn err\n\t}"
					lines = append(lines[:i+1], append([]string{errorCheck}, lines[i+1:]...)...)
					break
				}
			}
			code = strings.Join(lines, "\n")
		}
	}
	return code, nil
}

// applyRegexFix applies regex-based fixes
func (vs *ValidationSystem) applyRegexFix(code string, fix *FixSuggestion) (string, error) {
	modifiedCode := code
	for i, pattern := range fix.Patterns {
		if i < len(fix.Replacements) {
			modifiedCode = strings.Replace(modifiedCode, pattern, fix.Replacements[i], -1)
		}
	}
	return modifiedCode, nil
}

// validateSyntax checks if the modified code has valid syntax
func (vs *ValidationSystem) validateSyntax(sandboxDir string, fix *FixSuggestion, originalCode string) error {
	codeFile := filepath.Join(sandboxDir, "main.go")
	
	fset := token.NewFileSet()
	_, err := parser.ParseFile(fset, codeFile, nil, parser.ParseComments)
	if err != nil {
		return fmt.Errorf("syntax validation failed: %w", err)
	}
	
	return nil
}

// validateCompilation checks if the modified code compiles
func (vs *ValidationSystem) validateCompilation(sandboxDir string, fix *FixSuggestion, originalCode string) error {
	ctx, cancel := context.WithTimeout(context.Background(), vs.config.Timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "go", "build", "./...")
	cmd.Dir = sandboxDir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("compilation failed: %w, output: %s", err, string(output))
	}
	
	return nil
}

// validateStaticAnalysis runs static analysis tools on the modified code
func (vs *ValidationSystem) validateStaticAnalysis(sandboxDir string, fix *FixSuggestion, originalCode string) error {
	if !vs.config.EnableStaticCheck {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), vs.config.Timeout)
	defer cancel()

	// Run go vet
	cmd := exec.CommandContext(ctx, "go", "vet", "./...")
	cmd.Dir = sandboxDir
	
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("go vet failed: %w, output: %s", err, string(output))
	}

	// Run staticcheck if available
	if _, err := exec.LookPath("staticcheck"); err == nil {
		cmd = exec.CommandContext(ctx, "staticcheck", "./...")
		cmd.Dir = sandboxDir
		
		if output, err := cmd.CombinedOutput(); err != nil {
			// staticcheck failures are warnings, not errors
			fmt.Printf("staticcheck warnings: %s\n", string(output))
		}
	}

	return nil
}

// validateTests runs tests in the sandbox environment
func (vs *ValidationSystem) validateTests(sandboxDir string, fix *FixSuggestion, originalCode string) error {
	if !vs.config.EnableTests {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), vs.config.Timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "go", "test", "./...", "-v")
	cmd.Dir = sandboxDir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("tests failed: %w, output: %s", err, string(output))
	}
	
	return nil
}

// validatePerformance checks performance impact of the fix
func (vs *ValidationSystem) validatePerformance(sandboxDir string, fix *FixSuggestion, originalCode string) error {
	if !vs.config.EnableBenchmarks {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), vs.config.Timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "go", "test", "-bench=.", "-benchmem", "./...")
	cmd.Dir = sandboxDir
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		// Benchmark failures are not critical
		fmt.Printf("benchmark warnings: %s\n", string(output))
	}
	
	return nil
}

// calculateConfidenceScore calculates a confidence score for the fix
func (vs *ValidationSystem) calculateConfidenceScore(result *ValidationResult) float64 {
	score := 0.0
	maxScore := 0.0

	// Syntax check (20%)
	maxScore += 0.2
	if len(result.Errors) == 0 || !vs.hasError(result.Errors, "syntax") {
		score += 0.2
	}

	// Compilation check (30%)
	maxScore += 0.3
	if result.CompilationOK {
		score += 0.3
	}

	// Static analysis check (20%)
	maxScore += 0.2
	if result.StaticCheckOK {
		score += 0.2
	}

	// Tests passing (25%)
	maxScore += 0.25
	if result.TestsPassing {
		score += 0.25
	}

	// No errors bonus (5%)
	maxScore += 0.05
	if len(result.Errors) == 0 {
		score += 0.05
	}

	return score / maxScore
}

// determineSafetyLevel determines the safety level of the fix
func (vs *ValidationSystem) determineSafetyLevel(result *ValidationResult) SafetyLevel {
	if len(result.Errors) > 0 {
		return SafetyLevelUnsafe
	}

	if result.ConfidenceScore >= 0.9 && result.CompilationOK && result.StaticCheckOK && result.TestsPassing {
		return SafetyLevelHigh
	}

	if result.ConfidenceScore >= 0.7 && result.CompilationOK {
		return SafetyLevelMedium
	}

	return SafetyLevelLow
}

// Helper functions

// isImportUnused checks if an import is unused in the AST
func (vs *ValidationSystem) isImportUnused(node *ast.File, importPath string) bool {
	// Simple heuristic - check if import name appears in code
	// This is a simplified version; real implementation would use type checking
	importName := filepath.Base(importPath)
	
	// Walk the AST to find usages
	used := false
	ast.Inspect(node, func(n ast.Node) bool {
		if ident, ok := n.(*ast.Ident); ok {
			if ident.Name == importName {
				used = true
				return false
			}
		}
		return true
	})
	
	return !used
}

// removeImportFromCode removes an import from source code
func (vs *ValidationSystem) removeImportFromCode(code, importPath string) string {
	lines := strings.Split(code, "\n")
	for i, line := range lines {
		if strings.Contains(line, `"`+importPath+`"`) {
			// Remove this line
			lines = append(lines[:i], lines[i+1:]...)
			break
		}
	}
	return strings.Join(lines, "\n")
}

// hasError checks if error list contains specific error type
func (vs *ValidationSystem) hasError(errors []string, errorType string) bool {
	for _, err := range errors {
		if strings.Contains(strings.ToLower(err), errorType) {
			return true
		}
	}
	return false
}

// copyTestFiles copies test files to sandbox
func (vs *ValidationSystem) copyTestFiles(sandboxDir string) error {
	// Look for test files in current directory
	currentDir, err := os.Getwd()
	if err != nil {
		return err
	}

	testFiles, err := filepath.Glob(filepath.Join(currentDir, "*_test.go"))
	if err != nil {
		return err
	}

	for _, testFile := range testFiles {
		content, err := ioutil.ReadFile(testFile)
		if err != nil {
			continue
		}

		basename := filepath.Base(testFile)
		destPath := filepath.Join(sandboxDir, basename)
		if err := ioutil.WriteFile(destPath, content, 0644); err != nil {
			return err
		}
	}

	return nil
}

// cleanupSandbox removes sandbox directory
func (vs *ValidationSystem) cleanupSandbox(sandboxDir string) {
	if !vs.config.PreserveArtifacts {
		os.RemoveAll(sandboxDir)
	} else {
		fmt.Printf("Sandbox preserved at: %s\n", sandboxDir)
	}
}

// GetActiveTests returns currently running tests
func (vs *ValidationSystem) GetActiveTests() map[string]*TestExecution {
	vs.mutex.RLock()
	defer vs.mutex.RUnlock()
	
	tests := make(map[string]*TestExecution)
	for id, test := range vs.activeTests {
		tests[id] = test
	}
	return tests
}

// CancelTest cancels a running test
func (vs *ValidationSystem) CancelTest(testID string) error {
	vs.mutex.Lock()
	defer vs.mutex.Unlock()
	
	if test, exists := vs.activeTests[testID]; exists {
		test.Cancel()
		delete(vs.activeTests, testID)
		return nil
	}
	
	return fmt.Errorf("test %s not found", testID)
}
