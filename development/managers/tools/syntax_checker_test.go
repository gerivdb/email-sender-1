// Manager Toolkit - Syntax Checker Tests
// Version: 3.0.0

package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"go/token"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSyntaxChecker_ImplementsToolkitOperation(t *testing.T) {
	var _ ToolkitOperation = &SyntaxChecker{}
}

func TestSyntaxChecker_NewInstance(t *testing.T) {
	tmpDir := t.TempDir()
	logger := &Logger{}
	stats := &ToolkitStats{}

	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	assert.Equal(t, tmpDir, checker.BaseDir)
	assert.NotNil(t, checker.FileSet)
	assert.Equal(t, logger, checker.Logger)
	assert.Equal(t, stats, checker.Stats)
	assert.False(t, checker.DryRun)
}

func TestSyntaxChecker_Validate(t *testing.T) {
	tests := []struct {
		name          string
		checker       *SyntaxChecker
		expectedError string
	}{
		{
			name: "valid_checker",
			checker: &SyntaxChecker{
				BaseDir: t.TempDir(),
				Logger:  &Logger{},
			},
			expectedError: "",
		},
		{
			name: "missing_base_dir",
			checker: &SyntaxChecker{
				Logger: &Logger{},
			},
			expectedError: "BaseDir is required",
		},
		{
			name: "missing_logger",
			checker: &SyntaxChecker{
				BaseDir: t.TempDir(),
			},
			expectedError: "Logger is required",
		},
		{
			name: "non_existent_directory",
			checker: &SyntaxChecker{
				BaseDir: "/non/existent/path",
				Logger:  &Logger{},
			},
			expectedError: "base directory does not exist",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx := context.Background()
			err := tt.checker.Validate(ctx)

			if tt.expectedError == "" {
				assert.NoError(t, err)
			} else {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			}
		})
	}
}

func TestSyntaxChecker_HealthCheck(t *testing.T) {
	tmpDir := t.TempDir()
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  &Logger{},
		Stats:   &ToolkitStats{},
	}

	ctx := context.Background()
	err := checker.HealthCheck(ctx)
	assert.NoError(t, err)
}

func TestSyntaxChecker_HealthCheck_Failures(t *testing.T) {
	tests := []struct {
		name          string
		checker       *SyntaxChecker
		expectedError string
	}{
		{
			name: "missing_fileset",
			checker: &SyntaxChecker{
				BaseDir: t.TempDir(),
				Logger:  &Logger{},
			},
			expectedError: "FileSet not initialized",
		},
		{
			name: "invalid_directory",
			checker: &SyntaxChecker{
				BaseDir: "/invalid/path",
				FileSet: token.NewFileSet(),
				Logger:  &Logger{},
			},
			expectedError: "base directory does not exist",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx := context.Background()
			err := tt.checker.HealthCheck(ctx)
			assert.Error(t, err)
			assert.Contains(t, err.Error(), tt.expectedError)
		})
	}
}

func TestSyntaxChecker_CollectMetrics(t *testing.T) {
	tmpDir := t.TempDir()
	stats := &ToolkitStats{
		FilesAnalyzed: 5,
		ErrorsFixed:   3,
	}

	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  &Logger{},
		Stats:   stats,
		DryRun:  true,
	}

	metrics := checker.CollectMetrics()

	assert.Equal(t, "SyntaxChecker", metrics["tool"])
	assert.Equal(t, "3.0.0", metrics["version"])
	assert.Equal(t, true, metrics["dry_run_mode"])
	assert.Equal(t, tmpDir, metrics["base_directory"])
	assert.Equal(t, 5, metrics["files_analyzed"])
	assert.Equal(t, 3, metrics["errors_fixed"])
}

func TestSyntaxChecker_Execute_ValidGoFile(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a valid Go file
	validGoCode := `package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
`

	goFile := filepath.Join(tmpDir, "valid.go")
	err := os.WriteFile(goFile, []byte(validGoCode), 0644)
	require.NoError(t, err)

	logger := &Logger{}
	stats := &ToolkitStats{}
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "syntax_report.json"),
		Force:  false,
	}

	err = checker.Execute(ctx, options)
	assert.NoError(t, err)
	assert.Greater(t, stats.FilesAnalyzed, 0)

	// Check report was generated
	_, err = os.Stat(options.Output)
	assert.NoError(t, err)
}

func TestSyntaxChecker_Execute_SyntaxError(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with syntax error
	invalidGoCode := `package main

import "fmt"

func main() {
	fmt.Println("Hello, World!"
	// Missing closing parenthesis
}
`

	goFile := filepath.Join(tmpDir, "invalid.go")
	err := os.WriteFile(goFile, []byte(invalidGoCode), 0644)
	require.NoError(t, err)

	logger := &Logger{}
	stats := &ToolkitStats{}
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true, // Don't actually fix
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "syntax_report.json"),
		Force:  false,
	}

	err = checker.Execute(ctx, options)
	assert.NoError(t, err)

	// Read and verify report
	reportData, err := os.ReadFile(options.Output)
	require.NoError(t, err)

	var report SyntaxReport
	err = json.Unmarshal(reportData, &report)
	require.NoError(t, err)

	assert.Equal(t, "SyntaxChecker", report.Tool)
	assert.Equal(t, "3.0.0", report.Version)
	assert.True(t, report.DryRunMode)
	assert.Greater(t, report.ErrorsFound, 0)
	assert.Len(t, report.Errors, 1)
	assert.Equal(t, "parsing", report.Errors[0].ErrorType)
}

func TestSyntaxChecker_Execute_FormattingIssue(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with formatting issues
	unformattedGoCode := `package main

import "fmt"

func main(){
fmt.Println("Hello, World!")
}
`

	goFile := filepath.Join(tmpDir, "unformatted.go")
	err := os.WriteFile(goFile, []byte(unformattedGoCode), 0644)
	require.NoError(t, err)

	logger := &Logger{}
	stats := &ToolkitStats{}
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "syntax_report.json"),
		Force:  true, // Allow fixing
	}

	err = checker.Execute(ctx, options)
	assert.NoError(t, err)

	// Check if file was formatted
	formattedContent, err := os.ReadFile(goFile)
	require.NoError(t, err)

	// Should now be properly formatted
	assert.Contains(t, string(formattedContent), "func main() {")
	assert.Contains(t, string(formattedContent), "\tfmt.Println")
}

func TestSyntaxChecker_Execute_WithDryRun(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with formatting issues
	unformattedGoCode := `package main

import "fmt"

func main(){
fmt.Println("Hello, World!")
}
`

	goFile := filepath.Join(tmpDir, "unformatted.go")
	err := os.WriteFile(goFile, []byte(unformattedGoCode), 0644)
	require.NoError(t, err)

	originalContent, err := os.ReadFile(goFile)
	require.NoError(t, err)

	logger := &Logger{}
	stats := &ToolkitStats{}
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true, // Don't actually change files
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "syntax_report.json"),
		Force:  true,
	}

	err = checker.Execute(ctx, options)
	assert.NoError(t, err)

	// File should remain unchanged in dry-run mode
	currentContent, err := os.ReadFile(goFile)
	require.NoError(t, err)
	assert.Equal(t, string(originalContent), string(currentContent))

	// But report should indicate potential fixes
	reportData, err := os.ReadFile(options.Output)
	require.NoError(t, err)

	var report SyntaxReport
	err = json.Unmarshal(reportData, &report)
	require.NoError(t, err)

	assert.True(t, report.DryRunMode)
}

func TestSyntaxChecker_AnalyzeSyntaxError(t *testing.T) {
	checker := &SyntaxChecker{
		Logger: &Logger{},
	}

	file := "test.go"
	src := []byte("package main\n\nfunc main() {\n")

	// Simulate a parse error (this would come from go/parser)
	parseErr := fmt.Errorf("test.go:3:1: expected '}', found 'EOF'")

	syntaxErr := checker.analyzeSyntaxError(file, src, parseErr)

	assert.Equal(t, file, syntaxErr.File)
	assert.Contains(t, syntaxErr.Message, "expected")
	assert.Equal(t, "expected_token", syntaxErr.ErrorType)
	assert.Equal(t, "error", syntaxErr.Severity)
}

func TestSyntaxChecker_FixUnterminatedStrings(t *testing.T) {
	checker := &SyntaxChecker{}

	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "unterminated_double_quote",
			input:    `fmt.Println("Hello, World!`,
			expected: `fmt.Println("Hello, World!"`,
		},
		{
			name:     "unterminated_backtick",
			input:    "msg := `Hello, World!",
			expected: "msg := `Hello, World!`",
		},
		{
			name:     "properly_terminated",
			input:    `fmt.Println("Hello, World!")`,
			expected: `fmt.Println("Hello, World!")`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := checker.fixUnterminatedStrings(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestSyntaxChecker_FixMissingBraces(t *testing.T) {
	checker := &SyntaxChecker{}

	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "missing_one_brace",
			input:    "func main() {\n\tfmt.Println(\"test\")",
			expected: "func main() {\n\tfmt.Println(\"test\")\n}",
		},
		{
			name:     "missing_two_braces",
			input:    "func main() {\n\tif true {\n\t\tfmt.Println(\"test\")",
			expected: "func main() {\n\tif true {\n\t\tfmt.Println(\"test\")\n}\n}",
		},
		{
			name:     "balanced_braces",
			input:    "func main() {\n\tfmt.Println(\"test\")\n}",
			expected: "func main() {\n\tfmt.Println(\"test\")\n}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := checker.fixMissingBraces(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestSyntaxChecker_CategorizeErrors(t *testing.T) {
	checker := &SyntaxChecker{}

	report := &SyntaxReport{
		Errors: []SyntaxError{
			{ErrorType: "parsing"},
			{ErrorType: "formatting"},
			{ErrorType: "unterminated"},
			{ErrorType: "expected_token"},
			{ErrorType: "unknown"},
		},
		Summary: SyntaxSummary{},
	}

	checker.categorizeErrors(report)

	assert.Equal(t, 2, report.Summary.ParsingErrors) // parsing + expected_token
	assert.Equal(t, 1, report.Summary.FormattingErrors)
	assert.Equal(t, 1, report.Summary.UnterminatedErrors)
	assert.Equal(t, 1, report.Summary.MiscErrors) // unknown type
}

func TestSyntaxChecker_Integration_WithManagerToolkit(t *testing.T) {
	tmpDir := t.TempDir()

	// Create test Go file with formatting issue
	testCode := `package main

import "fmt"

func main(){
fmt.Println("Hello, World!")
}
`

	goFile := filepath.Join(tmpDir, "test.go")
	err := os.WriteFile(goFile, []byte(testCode), 0644)
	require.NoError(t, err)

	// Create ManagerToolkit instance
	toolkit, err := NewManagerToolkit(tmpDir, "", false)
	require.NoError(t, err)
	defer toolkit.Close()

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "syntax_report.json"),
		Force:  true,
	}

	// This would be called if OpSyntaxCheck was implemented in ExecuteOperation	// For now, test the tool directly
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  toolkit.Logger,
		Stats:   toolkit.Stats,
		DryRun:  false,
	}

	err = checker.Execute(ctx, options)
	assert.NoError(t, err)
	assert.Greater(t, toolkit.Stats.FilesAnalyzed, 0)

	// Verify report exists
	_, err = os.Stat(options.Output)
	assert.NoError(t, err)
}

// Benchmark tests
func BenchmarkSyntaxChecker_Execute(b *testing.B) {
	tmpDir := b.TempDir()

	// Create multiple Go files for benchmarking
	for i := 0; i < 10; i++ {
		testCode := fmt.Sprintf(`package main

import "fmt"

func main() {
	fmt.Println("Hello, World! %d")
}
`, i)

		goFile := filepath.Join(tmpDir, fmt.Sprintf("test%d.go", i))
		err := os.WriteFile(goFile, []byte(testCode), 0644)
		require.NoError(b, err)
	}

	logger := &Logger{}
	stats := &ToolkitStats{}
	checker := &SyntaxChecker{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true,
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Force:  false,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		stats.FilesAnalyzed = 0
		stats.ErrorsFixed = 0
		checker.Execute(ctx, options)
	}
}
