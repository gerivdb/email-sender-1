// Comprehensive test suite for NamingNormalizer
// Tests naming convention validation, suggestion generation, and toolkit.ToolkitOperation interface compliance

package correction

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestNamingNormalizerInterface verifies toolkit.ToolkitOperation interface compliance
func TestNamingNormalizerInterface(t *testing.T) {
	// Create test environment
	tempDir := t.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger: %v", err)
	}
	defer logger.Close()

	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)

	// Test interface compliance
	var _ toolkit.ToolkitOperation = normalizer

	ctx := context.Background()

	// Test Validate method
	if err := normalizer.Validate(ctx); err != nil {
		t.Errorf("Validate() failed: %v", err)
	}

	// Test HealthCheck method
	if err := normalizer.HealthCheck(ctx); err != nil {
		t.Errorf("HealthCheck() failed: %v", err)
	}

	// Test CollectMetrics method
	metrics := normalizer.CollectMetrics()
	expectedKeys := []string{"tool", "base_dir", "dry_run", "files_analyzed", "issues_found"}
	for _, key := range expectedKeys {
		if _, exists := metrics[key]; !exists {
			t.Errorf("CollectMetrics() missing key: %s", key)
		}
	}

	// Verify tool name
	if metrics["tool"] != "NamingNormalizer" {
		t.Errorf("Expected tool name 'NamingNormalizer', got %v", metrics["tool"])
	}
}

// TestNamingNormalizerValidation tests validation logic
func TestNamingNormalizerValidation(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for validation test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats

	tests := []struct {
		name        string
		baseDir     string
		logger      *toolkit.Logger // Corrected field definition
		stats       *toolkit.ToolkitStats // Corrected field definition
		expectError bool
	}{
		{
			name:        "Valid configuration",
			baseDir:     t.TempDir(),
			logger:      logger,
			stats:       stats,
			expectError: false,
		},
		{
			name:        "Empty base directory",
			baseDir:     "",
			logger:      logger,
			stats:       stats,
			expectError: true,
		},
		{
			name:        "Nil logger",
			baseDir:     t.TempDir(),
			logger:      nil,
			stats:       stats,
			expectError: true,
		},
		{
			name:        "Nil stats",
			baseDir:     t.TempDir(),
			logger:      logger,
			stats:       nil,
			expectError: true,
		},
		{
			name:        "Non-existent directory",
			baseDir:     "/non/existent/path",
			logger:      logger,
			stats:       stats,
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			normalizer := NewNamingNormalizer(tt.baseDir, tt.logger, tt.stats, true)
			err := normalizer.Validate(context.Background())

			if tt.expectError && err == nil {
				t.Errorf("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		})
	}
}

// TestInterfaceNamingConventions tests interface naming validation
func TestInterfaceNamingConventions(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for interface naming test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	tests := []struct {
		name           string
		interfaceName  string
		expectIssue    bool
		expectedReason string
		autoFixable    bool
	}{
		{
			name:          "Valid Manager interface",
			interfaceName: "SecurityManager",
			expectIssue:   false,
		},
		{
			name:          "Valid single word interface",
			interfaceName: "Reader",
			expectIssue:   false,
		},
		{
			name:           "Missing Manager suffix",
			interfaceName:  "Security",
			expectIssue:    true,
			expectedReason: "Interface should end with 'Manager' or be a single descriptive word",
			autoFixable:    false,
		},
		{
			name:           "Redundant ManagerInterface suffix",
			interfaceName:  "SecurityManagerInterface",
			expectIssue:    true,
			expectedReason: "Redundant 'ManagerInterface' suffix",
			autoFixable:    true,
		},
		{
			name:          "Valid single word pattern",
			interfaceName: "Handler",
			expectIssue:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issue := normalizer.checkInterfaceNaming(tt.interfaceName, 1)

			if tt.expectIssue {
				if issue == nil {
					t.Errorf("Expected issue for interface name '%s' but got none", tt.interfaceName)
					return
				}

				if issue.Type != "interface" {
					t.Errorf("Expected issue type 'interface', got '%s'", issue.Type)
				}

				if issue.Current != tt.interfaceName {
					t.Errorf("Expected current name '%s', got '%s'", tt.interfaceName, issue.Current)
				}

				if !strings.Contains(issue.Reason, tt.expectedReason) {
					t.Errorf("Expected reason to contain '%s', got '%s'", tt.expectedReason, issue.Reason)
				}

				if issue.AutoFixable != tt.autoFixable {
					t.Errorf("Expected autoFixable %v, got %v", tt.autoFixable, issue.AutoFixable)
				}
			} else {
				if issue != nil {
					t.Errorf("Unexpected issue for interface name '%s': %+v", tt.interfaceName, issue)
				}
			}
		})
	}
}

// TestStructNamingConventions tests struct naming validation
func TestStructNamingConventions(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for struct naming test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	tests := []struct {
		name           string
		structName     string
		expectIssue    bool
		expectedReason string
	}{
		{
			name:        "Valid implementation struct",
			structName:  "SecurityImpl",
			expectIssue: false,
		},
		{
			name:        "Valid regular struct",
			structName:  "UserData",
			expectIssue: false,
		},
		{
			name:           "Manager struct without Impl suffix",
			structName:     "SecurityManager",
			expectIssue:    true,
			expectedReason: "Implementation structs should end with 'Impl'",
		},
		{
			name:        "Non-manager struct",
			structName:  "Config",
			expectIssue: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			issue := normalizer.checkStructNaming(tt.structName, 1)

			if tt.expectIssue {
				if issue == nil {
					t.Errorf("Expected issue for struct name '%s' but got none", tt.structName)
					return
				}

				if issue.Type != "struct" {
					t.Errorf("Expected issue type 'struct', got '%s'", issue.Type)
				}

				if !strings.Contains(issue.Reason, tt.expectedReason) {
					t.Errorf("Expected reason to contain '%s', got '%s'", tt.expectedReason, issue.Reason)
				}
			} else {
				if issue != nil {
					t.Errorf("Unexpected issue for struct name '%s': %+v", tt.structName, issue)
				}
			}
		})
	}
}

// TestGoIdentifierValidation tests basic Go identifier validation
func TestGoIdentifierValidation(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for identifier validation test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	tests := []struct {
		name       string
		identifier string
		valid      bool
		suggestion string
	}{
		{
			name:       "Valid identifier",
			identifier: "ValidName",
			valid:      true,
		},
		{
			name:       "Valid with underscore",
			identifier: "valid_name",
			valid:      true,
		},
		{
			name:       "Valid with numbers",
			identifier: "name123",
			valid:      true,
		},
		{
			name:       "Invalid - starts with number",
			identifier: "123name",
			valid:      false,
			suggestion: "name123name",
		},
		{
			name:       "Invalid - contains spaces",
			identifier: "invalid name",
			valid:      false,
			suggestion: "invalidname",
		},
		{
			name:       "Invalid - special characters",
			identifier: "invalid-name",
			valid:      false,
			suggestion: "invalidname",
		},
		{
			name:       "Empty identifier",
			identifier: "",
			valid:      false,
			suggestion: "validName",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := normalizer.isValidGoIdentifier(tt.identifier)
			if valid != tt.valid {
				t.Errorf("Expected valid=%v for identifier '%s', got %v", tt.valid, tt.identifier, valid)
			}

			if !tt.valid {
				suggestion := normalizer.suggestGoIdentifierFix(tt.identifier)
				if suggestion != tt.suggestion {
					t.Errorf("Expected suggestion '%s' for identifier '%s', got '%s'",
						tt.suggestion, tt.identifier, suggestion)
				}
			}
		})
	}
}

// TestConstantNamingConventions tests constant naming validation
func TestConstantNamingConventions(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for constant naming test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	tests := []struct {
		name         string
		constantName string
		valid        bool
		suggestion   string
	}{
		{
			name:         "Valid ALL_CAPS constant",
			constantName: "MAX_SIZE",
			valid:        true,
		},
		{
			name:         "Valid CamelCase constant",
			constantName: "DefaultTimeout",
			valid:        true,
		},
		{
			name:         "Invalid lowercase",
			constantName: "maxSize",
			valid:        false,
			suggestion:   "MAX_SIZE",
		},
		{
			name:         "Invalid mixed case",
			constantName: "maxSIZE",
			valid:        false,
			suggestion:   "MAX_S_I_Z_E",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := normalizer.isValidConstantName(tt.constantName)
			if valid != tt.valid {
				t.Errorf("Expected valid=%v for constant '%s', got %v", tt.valid, tt.constantName, valid)
			}

			if !tt.valid {
				suggestion := normalizer.suggestConstantName(tt.constantName)
				if suggestion != tt.suggestion {
					t.Errorf("Expected suggestion '%s' for constant '%s', got '%s'",
						tt.suggestion, tt.constantName, suggestion)
				}
			}
		})
	}
}

// TestVariableNamingConventions tests variable naming validation
func TestVariableNamingConventions(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for variable naming test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	tests := []struct {
		name         string
		variableName string
		valid        bool
	}{
		{
			name:         "Valid camelCase",
			variableName: "userName",
			valid:        true,
		},
		{
			name:         "Valid PascalCase",
			variableName: "UserName",
			valid:        true,
		},
		{
			name:         "Valid single letter",
			variableName: "i",
			valid:        true,
		},
		{
			name:         "Valid with numbers",
			variableName: "user2",
			valid:        true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			valid := normalizer.isValidVariableName(tt.variableName)
			if valid != tt.valid {
				t.Errorf("Expected valid=%v for variable '%s', got %v", tt.valid, tt.variableName, valid)
			}
		})
	}
}

// TestExecuteWithTestFiles tests the Execute method with actual Go files
func TestExecuteWithTestFiles(t *testing.T) {
	// Create test directory structure
	tempDir := t.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for execute test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats

	// Create test Go files with naming issues
	testFiles := map[string]string{
		"good_interface.go": `package test
type SecurityManager interface {
	Validate() error
}
type SecurityImpl struct {}
func NewSecurity() *SecurityImpl { return &SecurityImpl{} }
`,
		"bad_interface.go": `package test
type SecurityManagerInterface interface {
	Validate() error
}
type SecurityManager struct {}
func CreateSecurity() *SecurityManager { return &SecurityManager{} }
`,
		"mixed_issues.go": `package test
type Security interface {
	Process() error
}
type UserManager struct {}
func MakeUser() *UserManager { return &UserManager{} }
const maxSize = 100
`,
	}

	// Write test files
	for filename, content := range testFiles {
		filePath := filepath.Join(tempDir, filename)
		if err := os.WriteFile(filePath, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	// Test execution
	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)
	options := &toolkit.OperationOptions{ // Changed to toolkit.OperationOptions
		Target: tempDir,
		Output: filepath.Join(tempDir, "naming_report.json"),
	}

	ctx := context.Background()
	if err := normalizer.Execute(ctx, options); err != nil {
		t.Fatalf("Execute() failed: %v", err)
	}

	// Verify statistics were updated
	if stats.FilesAnalyzed == 0 {
		t.Error("Expected files to be analyzed")
	}

	// Verify report was generated
	reportPath := options.Output
	if _, err := os.Stat(reportPath); os.IsNotExist(err) {
		t.Error("Expected report file to be generated")
	}

	// Parse and validate report content
	reportData, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report map[string]interface{}
	if err := json.Unmarshal(reportData, &report); err != nil {
		t.Fatalf("Failed to parse report JSON: %v", err)
	}

	// Validate report structure
	expectedFields := []string{"tool", "version", "generated_at", "summary", "files"}
	for _, field := range expectedFields {
		if _, exists := report[field]; !exists {
			t.Errorf("Report missing required field: %s", field)
		}
	}

	// Verify tool name
	if report["tool"] != "NamingNormalizer" {
		t.Errorf("Expected tool name 'NamingNormalizer', got %v", report["tool"])
	}

	// Check summary section
	summary, ok := report["summary"].(map[string]interface{})
	if !ok {
		t.Fatal("Report summary is not a map")
	}

	totalIssues, ok := summary["total_issues"].(float64)
	if !ok || totalIssues == 0 {
		t.Error("Expected to find naming issues in test files")
	}

	t.Logf("Report generated successfully with %.0f issues found", totalIssues)
}

// TestReportGeneration tests the report generation functionality
func TestReportGeneration(t *testing.T) {
	tempDir := t.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for report generation test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)

	// Create test issues
	namingIssues := map[string][]NamingIssue{
		"test.go": {
			{
				Type:        "interface",
				Current:     "SecurityManagerInterface",
				Suggested:   "SecurityManager",
				Line:        5,
				Reason:      "Redundant suffix",
				Severity:    "error",
				AutoFixable: true,
			},
			{
				Type:        "function",
				Current:     "CreateUser",
				Suggested:   "NewUser",
				Line:        10,
				Reason:      "Constructor naming",
				Severity:    "warning",
				AutoFixable: true,
			},
		},
	}

	reportPath := filepath.Join(tempDir, "test_report.json")
	if err := normalizer.generateReport(namingIssues, reportPath); err != nil {
		t.Fatalf("generateReport() failed: %v", err)
	}

	// Verify report file exists
	if _, err := os.Stat(reportPath); os.IsNotExist(err) {
		t.Fatal("Report file was not created")
	}

	// Parse and validate report
	reportData, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report map[string]interface{}
	if err := json.Unmarshal(reportData, &report); err != nil {
		t.Fatalf("Failed to parse report JSON: %v", err)
	}

	// Validate report content
	if report["tool"] != "NamingNormalizer" {
		t.Errorf("Expected tool 'NamingNormalizer', got %v", report["tool"])
	}

	summary := report["summary"].(map[string]interface{})
	if summary["total_issues"].(float64) != 2 {
		t.Errorf("Expected 2 total issues, got %v", summary["total_issues"])
	}

	if summary["auto_fixable"].(float64) != 2 {
		t.Errorf("Expected 2 auto-fixable issues, got %v", summary["auto_fixable"])
	}

	t.Log("Report generation test passed successfully")
}

// TestHealthCheck tests the health check functionality
func TestHealthCheck(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for health check test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats

	t.Run("Valid directory", func(t *testing.T) {
		tempDir := t.TempDir()
		normalizer := NewNamingNormalizer(tempDir, logger, stats, true)

		if err := normalizer.HealthCheck(context.Background()); err != nil {
			t.Errorf("HealthCheck() failed for valid directory: %v", err)
		}
	})

	t.Run("Invalid directory", func(t *testing.T) {
		normalizer := NewNamingNormalizer("/non/existent/path", logger, stats, true)

		if err := normalizer.HealthCheck(context.Background()); err == nil {
			t.Error("HealthCheck() should fail for non-existent directory")
		}
	})
}

// BenchmarkNamingAnalysis benchmarks the naming analysis performance
func BenchmarkNamingAnalysis(b *testing.B) {
	tempDir := b.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		b.Fatalf("Failed to create logger for benchmark: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats

	// Create a test file with various naming patterns
	testContent := `package test

type SecurityManager interface {
	Validate() error
}

type SecurityImpl struct {
	name string
}

func NewSecurity() *SecurityImpl {
	return &SecurityImpl{}
}

const MAX_SIZE = 100
var userName string
`

	testFile := filepath.Join(tempDir, "benchmark_test.go")
	if err := os.WriteFile(testFile, []byte(testContent), 0644); err != nil {
		b.Fatalf("Failed to create test file: %v", err)
	}

	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)
	options := &toolkit.OperationOptions{ // Changed to toolkit.OperationOptions
		Target: tempDir,
		Output: "",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		stats = &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
		normalizer.Stats = stats
		if err := normalizer.Execute(context.Background(), options); err != nil {
			b.Fatalf("Execute() failed: %v", err)
		}
	}
}

// TestMetricsCollection tests the metrics collection functionality
func TestMetricsCollection(t *testing.T) {
	tempDir := t.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for metrics test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{ // Changed to toolkit.ToolkitStats
		FilesAnalyzed: 5,
		ErrorsFixed:   3,
	}

	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)
	metrics := normalizer.CollectMetrics()

	// Verify expected metrics are present
	expectedMetrics := map[string]interface{}{
		"tool":           "NamingNormalizer",
		"base_dir":       tempDir,
		"dry_run":        true,
		"files_analyzed": 5,
		"issues_found":   3,
	}

	for key, expectedValue := range expectedMetrics {
		if actualValue, exists := metrics[key]; !exists {
			t.Errorf("Missing metric: %s", key)
		} else if actualValue != expectedValue {
			t.Errorf("Metric %s: expected %v, got %v", key, expectedValue, actualValue)
		}
	}
}

// TestSingleWordInterfaceRecognition tests recognition of valid single-word interfaces
func TestSingleWordInterfaceRecognition(t *testing.T) {
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for single word interface test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats
	normalizer := NewNamingNormalizer(t.TempDir(), logger, stats, true)

	validSingleWords := []string{
		"Reader", "Writer", "Closer", "Seeker", "Scanner",
		"Parser", "Validator", "Handler", "Formatter",
		"Encoder", "Decoder", "Builder",
	}

	for _, word := range validSingleWords {
		t.Run(word, func(t *testing.T) {
			if !normalizer.isSingleWordInterface(word) {
				t.Errorf("Expected '%s' to be recognized as valid single-word interface", word)
			}
		})
	}

	// Test invalid single words
	invalidWords := []string{"Security", "Database", "Random"}
	for _, word := range invalidWords {
		t.Run("Invalid_"+word, func(t *testing.T) {
			if normalizer.isSingleWordInterface(word) {
				t.Errorf("Expected '%s' to NOT be recognized as valid single-word interface", word)
			}
		})
	}
}

// TestDryRunMode tests that dry-run mode doesn't make actual changes
func TestDryRunMode(t *testing.T) {
	tempDir := t.TempDir()
	logger, err := toolkit.NewLogger(false) // Changed to toolkit.NewLogger
	if err != nil {
		t.Fatalf("Failed to create logger for dry run test: %v", err)
	}
	defer logger.Close()
	stats := &toolkit.ToolkitStats{} // Changed to toolkit.ToolkitStats

	// Create test file with issues
	testContent := `package test
type SecurityManagerInterface interface {
	Validate() error
}
`
	testFile := filepath.Join(tempDir, "test.go")
	if err := os.WriteFile(testFile, []byte(testContent), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Store original content
	originalContent, _ := os.ReadFile(testFile)

	// Run in dry-run mode
	normalizer := NewNamingNormalizer(tempDir, logger, stats, true)
	options := &toolkit.OperationOptions{ // Changed to toolkit.OperationOptions
		Target: tempDir,
		Output: filepath.Join(tempDir, "report.json"),
	}

	if err := normalizer.Execute(context.Background(), options); err != nil {
		t.Fatalf("Execute() failed: %v", err)
	}

	// Verify file content unchanged
	currentContent, _ := os.ReadFile(testFile)
	if string(currentContent) != string(originalContent) {
		t.Error("File content was modified in dry-run mode")
	}

	// Verify issues were detected
	if stats.ErrorsFixed == 0 {
		t.Error("Expected issues to be detected even in dry-run mode")
	}
}


