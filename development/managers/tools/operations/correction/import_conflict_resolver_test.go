// Manager Toolkit - Import Conflict Resolver Tests
// Tests for import_conflict_resolver.go functionality

package correction

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestNewImportConflictResolver tests resolver creation
func TestNewImportConflictResolver(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_test")
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
			resolver, err := NewImportConflictResolver(tt.baseDir, nil, false)

			if tt.wantError {
				if err == nil {
					t.Error("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if resolver == nil {
				t.Fatal("Resolver should not be nil")
			}

			if resolver.BaseDir != tt.baseDir {
				t.Errorf("Base directory: expected %s, got %s", tt.baseDir, resolver.BaseDir)
			}
		})
	}
}

// TestImportConflictResolver_ToolkitOperationInterface tests toolkit.ToolkitOperation interface compliance
func TestImportConflictResolver_ToolkitOperationInterface(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_interface_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files with various import conflicts
	testFiles := map[string]string{
		"main.go": `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"os"
	"log"
	"context"
)

func main() {
	fmt.Println("Hello World")
	ctx := context.Background()
	_ = ctx
}`,
		"conflicts.go": `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"  // Duplicate import (
	"github.com/email-sender/tools/core/toolkit"
	"os"
	"path/filepath"
	"path/filepath" as fp  // Duplicate with alias
	"log"
	"encoding/json"
	// unused import (
	"github.com/email-sender/tools/core/toolkit"
	"unused"
)

func testFunction() {
	fmt.Println("test")
	os.Exit(0)
	log.Println("log")
}`,
		"aliases.go": `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	ctx "context"  // Conflicting alias
	"fmt"
	f "fmt"       // Another conflicting alias
)

func aliasTest() {
	ctx1 := context.Background()
	ctx2 := ctx.Background()
	fmt.Println("test")
	f.Println("alias test")
}`,
	}
	for filename, content := range testFiles {
		err := os.WriteFile(filepath.Join(tempDir, filename), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	resolver, err := NewImportConflictResolver(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create resolver: %v", err)
	}

	ctx := context.Background()

	// Test Validate() method
	t.Run("Validate method", func(t *testing.T) {
		err := resolver.Validate(ctx)
		if err != nil {
			t.Errorf("Validate() failed: %v", err)
		}
	})

	// Test HealthCheck() method
	t.Run("HealthCheck method", func(t *testing.T) {
		err := resolver.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck() failed: %v", err)
		}
	})

	// Test CollectMetrics() method
	t.Run("CollectMetrics method", func(t *testing.T) {
		metrics := resolver.CollectMetrics()
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
		if tool, ok := metrics["tool"].(string); !ok || tool != "ImportConflictResolver" {
			t.Errorf("Expected tool name 'ImportConflictResolver', got %v", metrics["tool"])
		}
	})

	// Test Execute() method
	t.Run("Execute method", func(t *testing.T) {
		opts := &OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, "import_conflicts_report.json"),
			Force:  false,
		}

		err := resolver.Execute(ctx, opts)
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

			var report ImportReport
			err = json.Unmarshal(data, &report)
			if err != nil {
				t.Errorf("Failed to parse output JSON: %v", err)
			}

			// Check report structure
			if report.Tool != "ImportConflictResolver" {
				t.Errorf("Expected tool 'ImportConflictResolver', got %s", report.Tool)
			}
			if report.FilesAnalyzed == 0 {
				t.Error("Expected at least one file to be analyzed")
			}
		}
	})
}

// TestImportConflictResolver_DetectConflicts tests conflict detection functionality
func TestImportConflictResolver_DetectConflicts(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "detect_conflicts_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files with various conflict scenarios
	testCases := map[string]struct {
		content            string
		expectedConflicts  int
		expectedDuplicates int
		hasUnused          bool
	}{
		"duplicate_imports.go": {
			content: `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"  // Duplicate
	"os"
	"os"   // Another duplicate
	"log"
)

func main() {
	fmt.Println("test")
	os.Exit(0)
	log.Println("done")
}`,
			expectedConflicts:  2, // Two duplicate conflicts
			expectedDuplicates: 2,
			hasUnused:          false,
		},
		"alias_conflicts.go": {
			content: `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	ctx "context"  // Alias conflict
	"fmt"
	f "fmt"       // Another alias conflict
	"os"
)

func main() {
	ctx1 := context.Background()
	ctx2 := ctx.Background()
	fmt.Println("test")
	f.Println("alias")
	os.Exit(0)
}`,
			expectedConflicts:  2, // Two alias conflicts
			expectedDuplicates: 0,
			hasUnused:          false,
		},
		"unused_imports.go": {
			content: `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"os"
	"log"      // Used
	"unused1"  // Unused
	"unused2"  // Unused
	"net/http" // Unused
)

func main() {
	fmt.Println("test")
	os.Exit(0)
	log.Println("done")
}`,
			expectedConflicts:  0, // No conflicts, just unused
			expectedDuplicates: 0,
			hasUnused:          true,
		},
		"mixed_issues.go": {
			content: `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"     // Duplicate
	"context"
	ctx "context" // Alias conflict
	"os"
	"unused"  // Unused
	"log"
)

func main() {
	fmt.Println("test")
	ctx1 := context.Background()
	ctx2 := ctx.Background()
	os.Exit(0)
	log.Println("done")
}`,
			expectedConflicts:  2, // Duplicate + alias conflict
			expectedDuplicates: 1,
			hasUnused:          true,
		},
	}

	for filename, testCase := range testCases {
		err := os.WriteFile(filepath.Join(tempDir, filename), []byte(testCase.content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	resolver, err := NewImportConflictResolver(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create resolver: %v", err)
	}

	// Run conflict detection
	ctx := context.Background()
	reportPath := filepath.Join(tempDir, "conflicts_report.json")
	opts := &OperationOptions{
		Target: tempDir,
		Output: reportPath,
		Force:  false,
	}

	err = resolver.Execute(ctx, opts)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Read and verify report
	data, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report ImportReport
	err = json.Unmarshal(data, &report)
	if err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}

	// Verify basic report structure
	if report.Tool != "ImportConflictResolver" {
		t.Errorf("Expected tool 'ImportConflictResolver', got %s", report.Tool)
	}

	if report.FilesAnalyzed != len(testCases) {
		t.Errorf("Expected %d files analyzed, got %d", len(testCases), report.FilesAnalyzed)
	}

	// Verify conflicts were detected
	totalExpectedConflicts := 0
	for _, tc := range testCases {
		totalExpectedConflicts += tc.expectedConflicts
	}

	if report.ConflictsFound < totalExpectedConflicts {
		t.Errorf("Expected at least %d conflicts, got %d", totalExpectedConflicts, report.ConflictsFound)
	}

	// Verify file analyses contain required fields
	for _, analysis := range report.FileAnalyses {
		if analysis.File == "" {
			t.Error("File analysis missing file name")
		}
		if len(analysis.Imports) == 0 {
			t.Error("File analysis missing imports")
		}

		// Check conflict details
		for _, conflict := range analysis.Conflicts {
			if conflict.ConflictType == "" {
				t.Error("Conflict missing type")
			}
			if conflict.ImportPath == "" {
				t.Error("Conflict missing import path")
			}
			if conflict.Description == "" {
				t.Error("Conflict missing description")
			}
			if conflict.Suggestion == "" {
				t.Error("Conflict missing suggestion")
			}
		}
	}
}

// TestImportConflictResolver_ResolveConflicts tests conflict resolution functionality
func TestImportConflictResolver_ResolveConflicts(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "resolve_conflicts_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create file with resolvable conflicts
	originalContent := `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"  // Duplicate - should be removed
	"os"
	"log"
	"unused" // Should be flagged as unused
)

func main() {
	fmt.Println("Hello")
	os.Exit(0)
	log.Println("Done")
}
`

	testFile := filepath.Join(tempDir, "test.go")
	err = os.WriteFile(testFile, []byte(originalContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	resolver, err := NewImportConflictResolver(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create resolver: %v", err)
	}

	ctx := context.Background()
	opts := &OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "resolution_report.json"),
		Force:  true, // Force resolution
	}

	err = resolver.Execute(ctx, opts)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Read the report to verify conflicts were detected
	data, err := os.ReadFile(opts.Output)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report ImportReport
	err = json.Unmarshal(data, &report)
	if err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}

	// Verify conflicts were found
	if report.ConflictsFound == 0 {
		t.Error("Expected conflicts to be found")
	}

	// Verify resolution suggestions were provided
	hasResolutionSuggestion := false
	for _, analysis := range report.FileAnalyses {
		for _, conflict := range analysis.Conflicts {
			if conflict.Suggestion != "" {
				hasResolutionSuggestion = true
				break
			}
		}
	}

	if !hasResolutionSuggestion {
		t.Error("Expected at least one resolution suggestion")
	}
}

// TestImportConflictResolver_EdgeCases tests edge cases and error conditions
func TestImportConflictResolver_EdgeCases(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_edge_test")
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

		resolver, err := NewImportConflictResolver(emptyDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create resolver: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: emptyDir,
			Output: "",
			Force:  false,
		}

		err = resolver.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle empty directory gracefully: %v", err)
		}
	})

	t.Run("No imports", func(t *testing.T) {
		noImportsDir := filepath.Join(tempDir, "no_imports")
		err := os.MkdirAll(noImportsDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create no_imports dir: %v", err)
		}

		// Create Go file without imports
		content := `package main

func main() {
	println("Hello World")
}
`
		err = os.WriteFile(filepath.Join(noImportsDir, "simple.go"), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create simple file: %v", err)
		}

		resolver, err := NewImportConflictResolver(noImportsDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create resolver: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: noImportsDir,
			Output: "",
			Force:  false,
		}

		err = resolver.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle files without imports gracefully: %v", err)
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

		import (
	"github.com/email-sender/tools/core/toolkit"
			"fmt"
			this is not valid import syntax
			"os"
		)

		func main() {
			fmt.Println("test")
		}`

		err = os.WriteFile(filepath.Join(invalidDir, "broken.go"), []byte(invalidContent), 0644)
		if err != nil {
			t.Fatalf("Failed to create broken file: %v", err)
		}

		resolver, err := NewImportConflictResolver(invalidDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create resolver: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: invalidDir,
			Output: "",
			Force:  false,
		}

		// Should handle parsing errors gracefully
		err = resolver.Execute(ctx, opts)
		if err != nil {
			// It's acceptable for this to error, but shouldn't panic
			t.Logf("Expected error for invalid syntax: %v", err)
		}
	})
}

// TestImportConflictResolver_DryRunMode tests dry run functionality
func TestImportConflictResolver_DryRunMode(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_dryrun_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test file with conflicts
	testContent := `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"  // Duplicate
	"os"
)

func main() {
	fmt.Println("test")
	os.Exit(0)
}`

	err = os.WriteFile(filepath.Join(tempDir, "test.go"), []byte(testContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test dry run mode
	resolver, err := NewImportConflictResolver(tempDir, nil, true) // dry run = true
	if err != nil {
		t.Fatalf("Failed to create resolver: %v", err)
	}

	ctx := context.Background()
	opts := &OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "dryrun_report.json"),
		Force:  false,
	}

	err = resolver.Execute(ctx, opts)
	if err != nil {
		t.Errorf("Execute in dry run mode failed: %v", err)
	}

	// Verify metrics indicate dry run
	metrics := resolver.CollectMetrics()
	if dryRun, ok := metrics["dry_run"].(bool); !ok || !dryRun {
		t.Error("Expected dry_run metric to be true")
	}

	// Verify original file was not modified
	originalData, err := os.ReadFile(filepath.Join(tempDir, "test.go"))
	if err != nil {
		t.Fatalf("Failed to read original file: %v", err)
	}

	if !strings.Contains(string(originalData), "\"fmt\"") ||
		!strings.Contains(string(originalData), "\"fmt\"  // Duplicate") {
		t.Error("Original file should not be modified in dry run mode")
	}
}

// TestImportConflictResolver_Metrics tests metrics collection
func TestImportConflictResolver_Metrics(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_metrics_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	resolver, err := NewImportConflictResolver(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create resolver: %v", err)
	}

	// Test initial metrics
	metrics := resolver.CollectMetrics()

	expectedKeys := []string{"tool", "base_dir", "dry_run", "files_analyzed", "conflicts_found", "duplicates_removed"}
	for _, key := range expectedKeys {
		if _, exists := metrics[key]; !exists {
			t.Errorf("Missing expected metric key: %s", key)
		}
	}

	// Verify metric types
	if tool, ok := metrics["tool"].(string); !ok || tool != "ImportConflictResolver" {
		t.Errorf("Expected tool to be 'ImportConflictResolver', got %v", metrics["tool"])
	}

	if baseDir, ok := metrics["base_dir"].(string); !ok || baseDir != tempDir {
		t.Errorf("Expected base_dir to be %s, got %v", tempDir, metrics["base_dir"])
	}

	if _, ok := metrics["dry_run"].(bool); !ok {
		t.Error("Expected dry_run to be boolean")
	}
}

// TestImportConflictResolver_HealthCheck tests health check functionality
func TestImportConflictResolver_HealthCheck(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "import_resolver_health_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("Healthy resolver", func(t *testing.T) {
		resolver, err := NewImportConflictResolver(tempDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create resolver: %v", err)
		}

		ctx := context.Background()
		err = resolver.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck failed for valid setup: %v", err)
		}
	})

	t.Run("Invalid base directory", func(t *testing.T) {
		resolver, err := NewImportConflictResolver("/non/existent/path", nil, false)
		if err == nil {
			ctx := context.Background()
			err = resolver.HealthCheck(ctx)
			if err == nil {
				t.Error("HealthCheck should fail for non-existent directory")
			}
		}
	})
}

// BenchmarkImportConflictResolver_Execute benchmarks the Execute method
func BenchmarkImportConflictResolver_Execute(b *testing.B) {
	tempDir, err := os.MkdirTemp("", "import_resolver_bench")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create multiple test files with conflicts
	for i := 0; i < 10; i++ {
		content := fmt.Sprintf(`package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"fmt"  // Duplicate
	"os"
	"log"
	"context"
	ctx "context"  // Alias conflict
	"net/http"
	"encoding/json"
	"unused%d"  // Unused import
)

func benchFunc%d() {
	fmt.Println("bench")
	os.Exit(0)
	log.Println("log")
	ctx1 := context.Background()
	ctx2 := ctx.Background()
	_, _ = ctx1, ctx2
}`, i, i)

		err := os.WriteFile(filepath.Join(tempDir, fmt.Sprintf("bench_%d.go", i)), []byte(content), 0644)
		if err != nil {
			b.Fatalf("Failed to create bench file: %v", err)
		}
	}

	resolver, err := NewImportConflictResolver(tempDir, nil, false)
	if err != nil {
		b.Fatalf("Failed to create resolver: %v", err)
	}

	ctx := context.Background()
	opts := &OperationOptions{
		Target: tempDir,
		Output: "",
		Force:  false,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := resolver.Execute(ctx, opts)
		if err != nil {
			b.Fatal(err)
		}
	}
}


