package auto_fix

import (
	"go/parser"
	"go/token"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestValidationSystem_ValidateProposedFix(t *testing.T) {
	config := SandboxConfig{
		Timeout:           30 * time.Second,
		EnableTests:       true,
		EnableStaticCheck: true,
		PreserveArtifacts: false,
	}

	vs := NewValidationSystem(config)

	tests := []struct {
		name             string
		fix              *FixSuggestion
		originalCode     string
		expectValid      bool
		expectConfidence float64
		expectSafety     SafetyLevel
	}{
		{
			name: "Valid unused import fix",
			fix: &FixSuggestion{
				ID:          "test-unused-import",
				Category:    "unused_imports",
				Description: "Remove unused import",
				Patterns:    []string{`"fmt"`},
				Confidence:  0.9,
				SafetyLevel: SafetyLevelHigh,
			},
			originalCode: `package main

import (
	"fmt"
	"strings"
)

func main() {
	s := strings.ToUpper("hello")
	println(s)
}`,
			expectValid:      true,
			expectConfidence: 0.8,
			expectSafety:     SafetyLevelHigh,
		},
		{
			name: "Invalid syntax fix",
			fix: &FixSuggestion{
				ID:           "test-syntax-error",
				Category:     "formatting",
				Description:  "Bad syntax fix",
				Patterns:     []string{"func main()"},
				Replacements: []string{"func main("},
				Confidence:   0.5,
				SafetyLevel:  SafetyLevelLow,
			},
			originalCode: `package main

func main() {
	println("hello")
}`,
			expectValid:      false,
			expectConfidence: 0.0,
			expectSafety:     SafetyLevelUnsafe,
		},
		{
			name: "Formatting fix",
			fix: &FixSuggestion{
				ID:          "test-formatting",
				Category:    "formatting",
				Description: "Format code",
				Confidence:  0.95,
				SafetyLevel: SafetyLevelHigh,
			},
			originalCode: `package main
func main(){println("hello")}`,
			expectValid:      true,
			expectConfidence: 0.9,
			expectSafety:     SafetyLevelHigh,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := vs.ValidateProposedFix(tt.fix, tt.originalCode)
			if err != nil {
				t.Fatalf("ValidateProposedFix() error = %v", err)
			}

			if result.IsValid != tt.expectValid {
				t.Errorf("ValidateProposedFix() IsValid = %v, want %v", result.IsValid, tt.expectValid)
			}

			if result.SafetyLevel != tt.expectSafety {
				t.Errorf("ValidateProposedFix() SafetyLevel = %v, want %v", result.SafetyLevel, tt.expectSafety)
			}

			// Check confidence score is in reasonable range
			if tt.expectValid && result.ConfidenceScore < 0.5 {
				t.Errorf("ValidateProposedFix() ConfidenceScore = %v, expected > 0.5 for valid fix", result.ConfidenceScore)
			}
		})
	}
}

func TestValidationSystem_CreateSandbox(t *testing.T) {
	config := SandboxConfig{
		TempDir:           os.TempDir(),
		PreserveArtifacts: false,
	}

	vs := NewValidationSystem(config)

	fix := &FixSuggestion{
		ID:       "test-fix",
		Category: "formatting",
	}

	originalCode := `package main

func main() {
	println("hello")
}`

	sandboxDir, err := vs.createSandbox(fix, originalCode)
	if err != nil {
		t.Fatalf("createSandbox() error = %v", err)
	}
	defer vs.cleanupSandbox(sandboxDir)

	// Check sandbox directory exists
	if _, err := os.Stat(sandboxDir); os.IsNotExist(err) {
		t.Fatalf("Sandbox directory not created: %s", sandboxDir)
	}

	// Check main.go exists
	mainFile := filepath.Join(sandboxDir, "main.go")
	if _, err := os.Stat(mainFile); os.IsNotExist(err) {
		t.Fatalf("main.go not created in sandbox")
	}

	// Check go.mod exists
	goModFile := filepath.Join(sandboxDir, "go.mod")
	if _, err := os.Stat(goModFile); os.IsNotExist(err) {
		t.Fatalf("go.mod not created in sandbox")
	}

	// Verify code content
	content, err := ioutil.ReadFile(mainFile)
	if err != nil {
		t.Fatalf("Failed to read main.go: %v", err)
	}

	if !strings.Contains(string(content), "package main") {
		t.Errorf("main.go does not contain expected code")
	}
}

func TestValidationSystem_ApplyFixToCode(t *testing.T) {
	vs := NewValidationSystem(SandboxConfig{})

	tests := []struct {
		name         string
		originalCode string
		fix          *FixSuggestion
		expectError  bool
		expectChange bool
	}{
		{
			name: "Unused import fix",
			originalCode: `package main

import (
	"fmt"
	"strings"
)

func main() {
	s := strings.ToUpper("hello")
	println(s)
}`,
			fix: &FixSuggestion{
				Category: "unused_imports",
				Patterns: []string{`"fmt"`},
			},
			expectError:  false,
			expectChange: true,
		},
		{
			name: "Formatting fix",
			originalCode: `package main
func main(){println("hello")}`,
			fix: &FixSuggestion{
				Category: "formatting",
			},
			expectError:  false,
			expectChange: true,
		},
		{
			name: "Error handling fix",
			originalCode: `package main

func main() {
	err := doSomething()
	println("done")
}

func doSomething() error {
	return nil
}`,
			fix: &FixSuggestion{
				Category: "error_handling",
				Patterns: []string{"err := doSomething()"},
			},
			expectError:  false,
			expectChange: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := vs.applyFixToCode(tt.originalCode, tt.fix)

			if tt.expectError && err == nil {
				t.Errorf("applyFixToCode() expected error but got none")
			}

			if !tt.expectError && err != nil {
				t.Errorf("applyFixToCode() unexpected error = %v", err)
			}

			if tt.expectChange && result == tt.originalCode {
				t.Errorf("applyFixToCode() expected code change but got same code")
			}
		})
	}
}

func TestValidationSystem_CalculateConfidenceScore(t *testing.T) {
	vs := NewValidationSystem(SandboxConfig{})

	tests := []struct {
		name     string
		result   *ValidationResult
		expected float64
	}{
		{
			name: "Perfect score",
			result: &ValidationResult{
				CompilationOK: true,
				StaticCheckOK: true,
				TestsPassing:  true,
				Errors:        []string{},
			},
			expected: 1.0,
		},
		{
			name: "Compilation only",
			result: &ValidationResult{
				CompilationOK: true,
				StaticCheckOK: false,
				TestsPassing:  false,
				Errors:        []string{},
			},
			expected: 0.55, // 0.2 + 0.3 + 0.05
		},
		{
			name: "Has errors",
			result: &ValidationResult{
				CompilationOK: true,
				StaticCheckOK: true,
				TestsPassing:  true,
				Errors:        []string{"syntax error"},
			},
			expected: 0.75, // No syntax bonus
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			score := vs.calculateConfidenceScore(tt.result)
			if score != tt.expected {
				t.Errorf("calculateConfidenceScore() = %v, want %v", score, tt.expected)
			}
		})
	}
}

func TestValidationSystem_DetermineSafetyLevel(t *testing.T) {
	vs := NewValidationSystem(SandboxConfig{})

	tests := []struct {
		name     string
		result   *ValidationResult
		expected SafetyLevel
	}{
		{
			name: "High safety",
			result: &ValidationResult{
				ConfidenceScore: 0.95,
				CompilationOK:   true,
				StaticCheckOK:   true,
				TestsPassing:    true,
				Errors:          []string{},
			},
			expected: SafetyLevelHigh,
		},
		{
			name: "Medium safety",
			result: &ValidationResult{
				ConfidenceScore: 0.75,
				CompilationOK:   true,
				StaticCheckOK:   false,
				TestsPassing:    false,
				Errors:          []string{},
			},
			expected: SafetyLevelMedium,
		},
		{
			name: "Low safety",
			result: &ValidationResult{
				ConfidenceScore: 0.6,
				CompilationOK:   true,
				StaticCheckOK:   false,
				TestsPassing:    false,
				Errors:          []string{},
			},
			expected: SafetyLevelLow,
		},
		{
			name: "Unsafe",
			result: &ValidationResult{
				ConfidenceScore: 0.5,
				CompilationOK:   false,
				StaticCheckOK:   false,
				TestsPassing:    false,
				Errors:          []string{"compilation error"},
			},
			expected: SafetyLevelUnsafe,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			level := vs.determineSafetyLevel(tt.result)
			if level != tt.expected {
				t.Errorf("determineSafetyLevel() = %v, want %v", level, tt.expected)
			}
		})
	}
}

func TestValidationSystem_ValidateSyntax(t *testing.T) {
	vs := NewValidationSystem(SandboxConfig{})

	// Create temporary directory
	tempDir, err := ioutil.TempDir("", "test_syntax_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	tests := []struct {
		name        string
		code        string
		expectError bool
	}{
		{
			name: "Valid syntax",
			code: `package main

func main() {
	println("hello")
}`,
			expectError: false,
		},
		{
			name: "Invalid syntax",
			code: `package main

func main( {
	println("hello")
}`,
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Write code to file
			codeFile := filepath.Join(tempDir, "main.go")
			if err := ioutil.WriteFile(codeFile, []byte(tt.code), 0644); err != nil {
				t.Fatalf("Failed to write test file: %v", err)
			}

			err := vs.validateSyntax(tempDir, &FixSuggestion{}, tt.code)

			if tt.expectError && err == nil {
				t.Errorf("validateSyntax() expected error but got none")
			}

			if !tt.expectError && err != nil {
				t.Errorf("validateSyntax() unexpected error = %v", err)
			}
		})
	}
}

func TestValidationSystem_ConcurrentValidation(t *testing.T) {
	config := SandboxConfig{
		Timeout:           10 * time.Second,
		EnableTests:       false, // Disable for faster testing
		EnableStaticCheck: false,
	}

	vs := NewValidationSystem(config)

	// Test concurrent validation
	fixes := []*FixSuggestion{
		{ID: "fix1", Category: "formatting", Confidence: 0.9},
		{ID: "fix2", Category: "formatting", Confidence: 0.8},
		{ID: "fix3", Category: "formatting", Confidence: 0.7},
	}

	originalCode := `package main

func main() {
	println("hello")
}`

	// Run validations concurrently
	results := make(chan *ValidationResult, len(fixes))
	errors := make(chan error, len(fixes))

	for _, fix := range fixes {
		go func(f *FixSuggestion) {
			result, err := vs.ValidateProposedFix(f, originalCode)
			if err != nil {
				errors <- err
			} else {
				results <- result
			}
		}(fix)
	}

	// Collect results
	successCount := 0
	errorCount := 0

	for i := 0; i < len(fixes); i++ {
		select {
		case <-results:
			successCount++
		case <-errors:
			errorCount++
		case <-time.After(30 * time.Second):
			t.Fatalf("Timeout waiting for validation results")
		}
	}

	if successCount == 0 {
		t.Errorf("No successful validations, expected at least 1")
	}

	t.Logf("Concurrent validation: %d successes, %d errors", successCount, errorCount)
}

func BenchmarkValidationSystem_ValidateProposedFix(b *testing.B) {
	config := SandboxConfig{
		Timeout:           30 * time.Second,
		EnableTests:       false, // Disable for benchmarking
		EnableStaticCheck: false,
	}

	vs := NewValidationSystem(config)

	fix := &FixSuggestion{
		ID:          "bench-fix",
		Category:    "formatting",
		Confidence:  0.9,
		SafetyLevel: SafetyLevelHigh,
	}

	originalCode := `package main

func main() {
	println("hello")
}`

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			_, err := vs.ValidateProposedFix(fix, originalCode)
			if err != nil {
				b.Fatalf("Validation failed: %v", err)
			}
		}
	})
}

func TestValidationSystem_IsImportUnused(t *testing.T) {
	vs := NewValidationSystem(SandboxConfig{})

	tests := []struct {
		name       string
		code       string
		importPath string
		expected   bool
	}{
		{
			name: "Used import",
			code: `package main

import "fmt"

func main() {
	fmt.Println("hello")
}`,
			importPath: "fmt",
			expected:   false,
		},
		{
			name: "Unused import",
			code: `package main

import "fmt"

func main() {
	println("hello")
}`,
			importPath: "fmt",
			expected:   true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Parse the code
			fset := token.NewFileSet()
			node, err := parser.ParseFile(fset, "", tt.code, parser.ParseComments)
			if err != nil {
				t.Fatalf("Failed to parse code: %v", err)
			}

			result := vs.isImportUnused(node, tt.importPath)
			if result != tt.expected {
				t.Errorf("isImportUnused() = %v, want %v", result, tt.expected)
			}
		})
	}
}
