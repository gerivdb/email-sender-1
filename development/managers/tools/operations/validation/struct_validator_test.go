// Manager Toolkit - Struct Validator Tests
// Tests for struct_validator.go functionality

package validation

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"testing"
)

// TestNewStructValidator tests validator creation
func TestNewStructValidator(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	tests := []struct {
		name      string
		baseDir   string
		wantError bool
	}{
		{
			name:      "Valid base directory",
			baseDir:   tempDir,
			wantError: false,
		},
		{
			name:      "Empty base directory",
			baseDir:   "",
			wantError: true,
		},
		{
			name:      "Non-existent directory",
			baseDir:   "/non/existent/path",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			validator, err := NewStructValidator(tt.baseDir, nil, false)

			if tt.wantError {
				if err == nil {
					t.Error("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if validator == nil {
				t.Fatal("Validator should not be nil")
			}

			if validator.BaseDir != tt.baseDir {
				t.Errorf("Base directory: expected %s, got %s", tt.baseDir, validator.BaseDir)
			}
		})
	}
}

// TestStructValidator_ToolkitOperationInterface tests toolkit.ToolkitOperation interface compliance
func TestStructValidator_ToolkitOperationInterface(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_interface_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test struct files
	testFiles := map[string]string{
		"valid_struct.go": `package main

type User struct {
	ID   int    ` + "`json:\"id\"`" + `
	Name string ` + "`json:\"name\"`" + `
	Age  int    ` + "`json:\"age\"`" + `
}

type Product struct {
	ID    uint   ` + "`json:\"id\"`" + `
	Title string ` + "`json:\"title\"`" + `
	Price float64 ` + "`json:\"price\"`" + `
}`,
		"invalid_struct.go": `package main

type InvalidStruct struct {
	ID   int    // Missing JSON tag
	Name string ` + "`json:\"name\"`" + `
	     int    // Missing field name
}

type {  // Invalid struct declaration
	Field string
}`,
	}

	for filename, content := range testFiles {
		err := os.WriteFile(filepath.Join(tempDir, filename), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	validator, err := NewStructValidator(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create validator: %v", err)
	}

	ctx := context.Background()

	// Test Validate() method
	t.Run("Validate method", func(t *testing.T) {
		err := validator.Validate(ctx)
		if err != nil {
			t.Errorf("Validate() failed: %v", err)
		}
	})

	// Test HealthCheck() method
	t.Run("HealthCheck method", func(t *testing.T) {
		err := validator.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck() failed: %v", err)
		}
	})

	// Test CollectMetrics() method
	t.Run("CollectMetrics method", func(t *testing.T) {
		metrics := validator.CollectMetrics()
		if metrics == nil {
			t.Error("CollectMetrics() returned nil")
		}

		// Check required metric fields
		requiredFields := []string{"tool", "base_dir", "dry_run"}
		for _, field := range requiredFields {
			if _, exists := metrics[field]; !exists {
				t.Errorf("Missing required metric field: %s", field)
			}
		}

		// Verify tool name
		if tool, ok := metrics["tool"].(string); !ok || tool != "StructValidator" {
			t.Errorf("Expected tool name 'StructValidator', got %v", metrics["tool"])
		}
	})

	// Test Execute() method
	t.Run("Execute method", func(t *testing.T) {
		opts := &toolkit.OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, "struct_validation_report.json"),
			Force:  false,
		}

		err := validator.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute() failed: %v", err)
		}

		// Verify output file was created
		if opts.Output != "" {
			if _, err := os.Stat(opts.Output); os.IsNotExist(err) {
				t.Errorf("Expected output file %s was not created", opts.Output)
			}

			// Verify output file content
			data, err := os.ReadFile(opts.Output)
			if err != nil {
				t.Errorf("Failed to read output file: %v", err)
			}

			var report ValidationReport
			err = json.Unmarshal(data, &report)
			if err != nil {
				t.Errorf("Failed to parse output JSON: %v", err)
			}

			// Check report structure
			if report.Tool != "StructValidator" {
				t.Errorf("Expected tool 'StructValidator', got %s", report.Tool)
			}
			if report.FilesAnalyzed == 0 {
				t.Error("Expected at least one file to be analyzed")
			}
		}
	})
}

// TestStructValidator_ValidateStructs tests struct validation functionality
func TestStructValidator_ValidateStructs(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "validate_structs_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files with various struct issues
	testCases := map[string]struct {
		content         string
		expectedErrors  int
		expectedStructs int
	}{
		"valid_structs.go": {
			content: `package main

type ValidUser struct {
	ID       int    ` + "`json:\"id\" db:\"id\"`" + `
	Username string ` + "`json:\"username\" db:\"username\"`" + `
	Email    string ` + "`json:\"email\" db:\"email\"`" + `
}

type ValidProduct struct {
	ID          uint    ` + "`json:\"id\"`" + `
	Name        string  ` + "`json:\"name\"`" + `
	Price       float64 ` + "`json:\"price\"`" + `
	InStock     bool    ` + "`json:\"in_stock\"`" + `
}`,
			expectedErrors:  0,
			expectedStructs: 2,
		},
		"invalid_structs.go": {
			content: `package main

type InvalidStruct1 struct {
	ID   int    // Missing JSON tag
	Name string ` + "`json:\"name\"`" + `
}

type InvalidStruct2 struct {
	     string  // Missing field name
	Age  int    ` + "`json:\"age\"`" + `
}

type InvalidStruct3 {  // Missing struct keyword
	Field string
}`,
			expectedErrors:  3, // Should detect multiple issues
			expectedStructs: 2, // Only valid struct declarations counted
		},
		"mixed_structs.go": {
			content: `package main

type GoodStruct struct {
	Field1 string ` + "`json:\"field1\"`" + `
	Field2 int    ` + "`json:\"field2\"`" + `
}

type BadStruct struct {
	Field1 string  // Missing JSON tag
	Field2 int     ` + "`json:\"field2\"`" + `
}`,
			expectedErrors:  1,
			expectedStructs: 2,
		},
	}

	for filename, testCase := range testCases {
		err := os.WriteFile(filepath.Join(tempDir, filename), []byte(testCase.content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	validator, err := NewStructValidator(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create validator: %v", err)
	}

	// Run validation
	ctx := context.Background()
	reportPath := filepath.Join(tempDir, "validation_report.json")
	opts := &toolkit.OperationOptions{
		Target: tempDir,
		Output: reportPath,
		Force:  false,
	}

	err = validator.Execute(ctx, opts)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Read and verify report
	data, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report ValidationReport
	err = json.Unmarshal(data, &report)
	if err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}

	// Verify basic report structure
	if report.Tool != "StructValidator" {
		t.Errorf("Expected tool 'StructValidator', got %s", report.Tool)
	}

	if report.FilesAnalyzed != len(testCases) {
		t.Errorf("Expected %d files analyzed, got %d", len(testCases), report.FilesAnalyzed)
	}

	// Verify errors were detected
	totalExpectedErrors := 0
	totalExpectedStructs := 0
	for _, tc := range testCases {
		totalExpectedErrors += tc.expectedErrors
		totalExpectedStructs += tc.expectedStructs
	}

	if report.ErrorsFound < 1 {
		t.Error("Expected validation errors to be found")
	}

	if report.StructsAnalyzed < totalExpectedStructs {
		t.Errorf("Expected at least %d structs analyzed, got %d", totalExpectedStructs, report.StructsAnalyzed)
	}

	// Verify validation errors contain required fields
	for _, validationError := range report.ValidationErrors {
		if validationError.File == "" {
			t.Error("Validation error missing file")
		}
		if validationError.ErrorType == "" {
			t.Error("Validation error missing error type")
		}
		if validationError.Description == "" {
			t.Error("Validation error missing description")
		}
	}
}

// TestStructValidator_EdgeCases tests edge cases and error conditions
func TestStructValidator_EdgeCases(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_edge_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("Empty directory", func(t *testing.T) {
		emptyDir := filepath.Join(tempDir, "empty")
		err := os.MkdirAll(emptyDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create empty dir: %v", err)
		}

		validator, err := NewStructValidator(emptyDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create validator: %v", err)
		}

		ctx := context.Background()
		opts := &toolkit.OperationOptions{
			Target: emptyDir,
			Output: "",
			Force:  false,
		}

		err = validator.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle empty directory gracefully: %v", err)
		}
	})

	t.Run("Non-Go files", func(t *testing.T) {
		nonGoDir := filepath.Join(tempDir, "non_go")
		err := os.MkdirAll(nonGoDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create non-go dir: %v", err)
		}

		// Create non-Go files
		files := map[string]string{
			"readme.txt":  "This is not a Go file",
			"config.json": `{"key": "value"}`,
			"script.sh":   "#!/bin/bash\necho 'hello'",
		}
		for filename, content := range files {
			err := os.WriteFile(filepath.Join(nonGoDir, filename), []byte(content), 0644)
			if err != nil {
				t.Fatalf("Failed to create test file %s: %v", filename, err)
			}
		}

		validator, err := NewStructValidator(nonGoDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create validator: %v", err)
		}

		ctx := context.Background()
		opts := &toolkit.OperationOptions{
			Target: nonGoDir,
			Output: "",
			Force:  false,
		}

		err = validator.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle non-Go files gracefully: %v", err)
		}
	})

	t.Run("Invalid Go syntax", func(t *testing.T) {
		invalidDir := filepath.Join(tempDir, "invalid")
		err := os.MkdirAll(invalidDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create invalid dir: %v", err)
		}

		// Create file with invalid Go syntax
		invalidContent := `package main

		this is not valid go code
		type Broken struct {
			field without type
		}
		another broken line
		`
		err = os.WriteFile(filepath.Join(invalidDir, "broken.go"), []byte(invalidContent), 0644)
		if err != nil {
			t.Fatalf("Failed to create broken file: %v", err)
		}

		validator, err := NewStructValidator(invalidDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create validator: %v", err)
		}

		ctx := context.Background()
		opts := &toolkit.OperationOptions{
			Target: invalidDir,
			Output: "",
			Force:  false,
		}

		// Should handle parsing errors gracefully
		err = validator.Execute(ctx, opts)
		if err != nil {
			// It's acceptable for this to error, but shouldn't panic
			t.Logf("Expected error for invalid syntax: %v", err)
		}
	})
}

// TestStructValidator_DryRunMode tests dry run functionality
func TestStructValidator_DryRunMode(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_dryrun_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test file
	testContent := `package main

type TestStruct struct {
	ID   int    // Missing JSON tag
	Name string ` + "`json:\"name\"`" + `
}`

	err = os.WriteFile(filepath.Join(tempDir, "test.go"), []byte(testContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test dry run mode
	validator, err := NewStructValidator(tempDir, nil, true) // dry run = true
	if err != nil {
		t.Fatalf("Failed to create validator: %v", err)
	}

	ctx := context.Background()
	opts := &toolkit.OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "dryrun_report.json"),
		Force:  false,
	}

	err = validator.Execute(ctx, opts)
	if err != nil {
		t.Errorf("Execute in dry run mode failed: %v", err)
	}

	// Verify metrics indicate dry run
	metrics := validator.CollectMetrics()
	if dryRun, ok := metrics["dry_run"].(bool); !ok || !dryRun {
		t.Error("Expected dry_run metric to be true")
	}
}

// TestStructValidator_Metrics tests metrics collection
func TestStructValidator_Metrics(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_metrics_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	validator, err := NewStructValidator(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create validator: %v", err)
	}

	// Test initial metrics
	metrics := validator.CollectMetrics()

	expectedKeys := []string{"tool", "base_dir", "dry_run", "files_analyzed", "structs_analyzed", "errors_found"}
	for _, key := range expectedKeys {
		if _, exists := metrics[key]; !exists {
			t.Errorf("Missing expected metric key: %s", key)
		}
	}

	// Verify metric types
	if tool, ok := metrics["tool"].(string); !ok || tool != "StructValidator" {
		t.Errorf("Expected tool to be 'StructValidator', got %v", metrics["tool"])
	}

	if baseDir, ok := metrics["base_dir"].(string); !ok || baseDir != tempDir {
		t.Errorf("Expected base_dir to be %s, got %v", tempDir, metrics["base_dir"])
	}

	if _, ok := metrics["dry_run"].(bool); !ok {
		t.Error("Expected dry_run to be boolean")
	}
}

// TestStructValidator_HealthCheck tests health check functionality
func TestStructValidator_HealthCheck(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "struct_validator_health_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("Healthy validator", func(t *testing.T) {
		validator, err := NewStructValidator(tempDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create validator: %v", err)
		}

		ctx := context.Background()
		err = validator.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck failed for valid setup: %v", err)
		}
	})

	t.Run("Invalid base directory", func(t *testing.T) {
		validator, err := NewStructValidator("/non/existent/path", nil, false)
		if err == nil {
			ctx := context.Background()
			err = validator.HealthCheck(ctx)
			if err == nil {
				t.Error("HealthCheck should fail for non-existent directory")
			}
		}
	})
}

// BenchmarkStructValidator_Execute benchmarks the Execute method
func BenchmarkStructValidator_Execute(b *testing.B) {
	tempDir, err := os.MkdirTemp("", "struct_validator_bench")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create multiple test files
	for i := 0; i < 10; i++ {
		content := fmt.Sprintf(`package main

type BenchStruct%d struct {
	ID       int    `+"`json:\"id\"`"+`
	Field1   string `+"`json:\"field1\"`"+`
	Field2   int    `+"`json:\"field2\"`"+`
	Field3   bool   `+"`json:\"field3\"`"+`
}

type BenchStruct%dExtra struct {
	Name     string  `+"`json:\"name\"`"+`
	Value    float64 `+"`json:\"value\"`"+`
}`, i, i)

		err := os.WriteFile(filepath.Join(tempDir, fmt.Sprintf("bench_%d.go", i)), []byte(content), 0644)
		if err != nil {
			b.Fatalf("Failed to create bench file: %v", err)
		}
	}

	validator, err := NewStructValidator(tempDir, nil, false)
	if err != nil {
		b.Fatalf("Failed to create validator: %v", err)
	}

	ctx := context.Background()
	opts := &toolkit.OperationOptions{
		Target: tempDir,
		Output: "",
		Force:  false,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := validator.Execute(ctx, opts)
		if err != nil {
			b.Fatal(err)
		}
	}
}


