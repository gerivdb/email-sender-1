// Manager Toolkit - Dependency Analyzer Tests
// Tests for dependency_analyzer.go functionality

package analysis

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

// TestNewDependencyAnalyzer tests analyzer creation
func TestNewDependencyAnalyzer(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_test")
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
			analyzer, err := NewDependencyAnalyzer(tt.baseDir, nil, false)

			if tt.wantError {
				if err == nil {
					t.Error("Expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}

			if analyzer == nil {
				t.Fatal("Analyzer should not be nil")
			}

			if analyzer.BaseDir != tt.baseDir {
				t.Errorf("Base directory: expected %s, got %s", tt.baseDir, analyzer.BaseDir)
			}
		})
	}
}

// TestDependencyAnalyzer_ToolkitOperationInterface tests toolkit.ToolkitOperation interface compliance
func TestDependencyAnalyzer_ToolkitOperationInterface(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_interface_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test project structure with dependencies
	testFiles := map[string]string{
		"go.mod": `module example.com/test

go 1.19

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/stretchr/testify v1.8.4
)

require (
	github.com/bytedance/sonic v1.9.1 // indirect
	github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
	github.com/gabriel-vasile/mimetype v1.4.2 // indirect
	github.com/gin-contrib/sse v0.1.0 // indirect
	github.com/go-playground/locales v0.14.1 // indirect
	github.com/go-playground/universal-translator v0.18.1 // indirect
	github.com/go-playground/validator/v10 v10.14.0 // indirect
)`,
		"main.go": `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"log"
	"net/http"
	
	"github.com/gin-gonic/gin"
	"example.com/test/internal/handler"
	"example.com/test/internal/service"
)

func main() {
	r := gin.Default()
	h := handler.NewHandler()
	s := service.NewService()
	
	r.GET("/", h.Home)
	r.GET("/health", s.Health)
	
	log.Fatal(http.ListenAndServe(":8080", r))
}`,
		"internal/handler/handler.go": `package handler

import (
	"github.com/email-sender/tools/core/toolkit"
	"net/http"
	"github.com/gin-gonic/gin"
)

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) Home(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Hello World"})
}`,
		"internal/service/service.go": `package service

import (
	"github.com/email-sender/tools/core/toolkit"
	"net/http"
	"github.com/gin-gonic/gin"
)

type Service struct{}

func NewService() *Service {
	return &Service{}
}

func (s *Service) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "healthy"})
}`,
		"pkg/utils/utils.go": `package utils

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"strings"
)

func FormatString(s string) string {
	return strings.ToUpper(fmt.Sprintf("Formatted: %s", s))
}`,
	}

	for filename, content := range testFiles {
		dir := filepath.Dir(filepath.Join(tempDir, filename))
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			t.Fatalf("Failed to create directory %s: %v", dir, err)
		}

		err = os.WriteFile(filepath.Join(tempDir, filename), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	ctx := context.Background()

	// Test Validate() method
	t.Run("Validate method", func(t *testing.T) {
		err := analyzer.Validate(ctx)
		if err != nil {
			t.Errorf("Validate() failed: %v", err)
		}
	})

	// Test HealthCheck() method
	t.Run("HealthCheck method", func(t *testing.T) {
		err := analyzer.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck() failed: %v", err)
		}
	})

	// Test CollectMetrics() method
	t.Run("CollectMetrics method", func(t *testing.T) {
		metrics := analyzer.CollectMetrics()
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
		if tool, ok := metrics["tool"].(string); !ok || tool != "DependencyAnalyzer" {
			t.Errorf("Expected tool name 'DependencyAnalyzer', got %v", metrics["tool"])
		}
	})

	// Test Execute() method
	t.Run("Execute method", func(t *testing.T) {
		opts := &OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, "dependency_analysis_report.json"),
			Force:  false,
		}

		err := analyzer.Execute(ctx, opts)
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

			var report DependencyReport
			err = json.Unmarshal(data, &report)
			if err != nil {
				t.Errorf("Failed to parse output JSON: %v", err)
			} // Check report structure
			if report.Tool != "DependencyAnalyzer" {
				t.Errorf("Expected tool 'DependencyAnalyzer', got %s", report.Tool)
			}
			if report.TotalDependencies == 0 {
				t.Error("Expected at least one dependency to be analyzed")
			}
		}
	})
}

// TestDependencyAnalyzer_AnalyzeDependencies tests dependency analysis functionality
func TestDependencyAnalyzer_AnalyzeDependencies(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "analyze_dependencies_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files with various dependency scenarios
	testCases := map[string]struct {
		content              string
		expectedDependencies int
		hasCircularDeps      bool
		hasUnusedDeps        bool
		hasExternalDeps      bool
	}{
		"go.mod": {
			content: `module example.com/test

go 1.19

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/stretchr/testify v1.8.4
	github.com/unused/package v1.0.0
)

require (
	github.com/bytedance/sonic v1.9.1 // indirect
	github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
)`,
			expectedDependencies: 5, // 3 direct + 2 indirect
			hasCircularDeps:      false,
			hasUnusedDeps:        true, // unused/package
			hasExternalDeps:      true,
		},
		"main.go": {
			content: `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"log"
	"net/http"
	
	"github.com/gin-gonic/gin"
	"example.com/test/internal/handler"
	"example.com/test/internal/service"
)

func main() {
	r := gin.Default()
	h := handler.NewHandler()
	s := service.NewService()
	
	r.GET("/", h.Home)
	r.GET("/health", s.Health)
	
	fmt.Println("Server starting...")
	log.Fatal(http.ListenAndServe(":8080", r))
}`,
			expectedDependencies: 6, // 3 std lib + 3 internal/external
			hasCircularDeps:      false,
			hasUnusedDeps:        false,
			hasExternalDeps:      true,
		},
		"internal/handler/handler.go": {
			content: `package handler

import (
	"github.com/email-sender/tools/core/toolkit"
	"net/http"
	"github.com/gin-gonic/gin"
	"example.com/test/internal/service"
)

type Handler struct {
	service *service.Service
}

func NewHandler() *Handler {
	return &Handler{
		service: service.NewService(),
	}
}

func (h *Handler) Home(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Hello World"})
}`,
			expectedDependencies: 3, // net/http, gin, internal service
			hasCircularDeps:      false,
			hasUnusedDeps:        false,
			hasExternalDeps:      true,
		},
		"internal/service/service.go": {
			content: `package service

import (
	"github.com/email-sender/tools/core/toolkit"
	"net/http"
	"github.com/gin-gonic/gin"
	"example.com/test/internal/handler" // Circular dependency!
)

type Service struct {
	handler interface{}
}

func NewService() *Service {
	return &Service{}
}

func (s *Service) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "healthy"})
}`,
			expectedDependencies: 3,
			hasCircularDeps:      true, // service imports handler, handler imports service
			hasUnusedDeps:        false,
			hasExternalDeps:      true,
		},
	}

	for filename, testCase := range testCases {
		dir := filepath.Dir(filepath.Join(tempDir, filename))
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			t.Fatalf("Failed to create directory %s: %v", dir, err)
		}

		err = os.WriteFile(filepath.Join(tempDir, filename), []byte(testCase.content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}

	analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	// Run dependency analysis
	ctx := context.Background()
	reportPath := filepath.Join(tempDir, "dependency_report.json")
	opts := &OperationOptions{
		Target: tempDir,
		Output: reportPath,
		Force:  false,
	}

	err = analyzer.Execute(ctx, opts)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Read and verify report
	data, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report DependencyReport
	err = json.Unmarshal(data, &report)
	if err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}

	// Verify basic report structure
	if report.Tool != "DependencyAnalyzer" {
		t.Errorf("Expected tool 'DependencyAnalyzer', got %s", report.Tool)
	}
	if report.TotalDependencies == 0 {
		t.Error("Expected dependencies to be analyzed")
	}

	// Verify dependencies were found
	if len(report.Dependencies) == 0 {
		t.Error("Expected dependencies to be found")
	}
	// Check for specific dependency types (based on module path patterns)
	hasStdLib := false
	hasExternal := false
	hasInternal := false

	for _, dep := range report.Dependencies {
		// Determine type based on module path
		moduleType := ""
		if dep.ModulePath == "" {
			moduleType = "standard" // Standard library
		} else if strings.Contains(dep.ModulePath, ".") && !strings.HasPrefix(dep.ModulePath, "example.com/test") {
			moduleType = "external" // External dependency
		} else {
			moduleType = "internal" // Internal package
		}

		switch moduleType {
		case "standard":
			hasStdLib = true
		case "external":
			hasExternal = true
		case "internal":
			hasInternal = true
		}
	}

	if !hasStdLib {
		t.Error("Expected to find standard library dependencies")
	}
	if !hasExternal {
		t.Error("Expected to find external dependencies")
	}
	if !hasInternal {
		t.Error("Expected to find internal dependencies")
	}
	// Verify analysis results contain required fields
	for _, dep := range report.Dependencies {
		if dep.Name == "" {
			t.Error("Dependency missing name")
		}
		if dep.ModulePath == "" && !strings.Contains(dep.Name, "/") {
			// Standard library packages typically don't have module paths
			continue
		}
		if dep.Version == "" && dep.ModulePath != "" && strings.Contains(dep.ModulePath, ".") {
			t.Error("External dependency missing version")
		}
	}
	// Check for circular dependencies (this feature might not be implemented yet)
	// hasCircular := len(report.CircularDependencies) > 0
	hasCircular := false // Placeholder - actual circular dependency detection not implemented
	expectedCircular := false
	for _, tc := range testCases {
		if tc.hasCircularDeps {
			expectedCircular = true
			break
		}
	}

	if expectedCircular && !hasCircular {
		t.Error("Expected circular dependencies to be detected")
	}
	// Verify graph structure if present (not implemented in current version)
	// if report.DependencyGraph != nil {
	//	if len(report.DependencyGraph.Nodes) == 0 {
	//		t.Error("Expected dependency graph to have nodes")
	//	}
	//	if len(report.DependencyGraph.Edges) == 0 {
	//		t.Error("Expected dependency graph to have edges")
	//	}
	// }
}

// TestDependencyAnalyzer_ModuleAnalysis tests Go module analysis
func TestDependencyAnalyzer_ModuleAnalysis(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "module_analysis_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create go.mod with various dependency types
	goModContent := `module example.com/test

go 1.19

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/stretchr/testify v1.8.4
	golang.org/x/crypto v0.10.0
)

require (
	github.com/bytedance/sonic v1.9.1 // indirect
	github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
	github.com/gabriel-vasile/mimetype v1.4.2 // indirect
	golang.org/x/net v0.10.0 // indirect
	golang.org/x/sys v0.9.0 // indirect
)

replace github.com/gin-gonic/gin => ../local-gin

exclude github.com/old/package v1.0.0`

	err = os.WriteFile(filepath.Join(tempDir, "go.mod"), []byte(goModContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create go.mod: %v", err)
	}

	analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	ctx := context.Background()
	reportPath := filepath.Join(tempDir, "module_report.json")
	opts := &OperationOptions{
		Target: tempDir,
		Output: reportPath,
		Force:  false,
	}

	err = analyzer.Execute(ctx, opts)
	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	// Read and verify report
	data, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	var report DependencyReport
	err = json.Unmarshal(data, &report)
	if err != nil {
		t.Fatalf("Failed to parse report: %v", err)
	}
	// Verify module information was parsed (using existing fields in DependencyReport)
	if report.ModuleName != "example.com/test" {
		t.Errorf("Expected module name 'example.com/test', got %s", report.ModuleName)
	}

	if report.GoVersion != "1.19" {
		t.Errorf("Expected Go version '1.19', got %s", report.GoVersion)
	}
	// Verify dependencies were categorized correctly (using IsIndirect field)
	directDeps := 0
	indirectDeps := 0
	for _, dep := range report.Dependencies {
		if !dep.IsIndirect {
			directDeps++
		} else {
			indirectDeps++
		}
	}

	if directDeps < 3 {
		t.Errorf("Expected at least 3 direct dependencies, got %d", directDeps)
	}

	if indirectDeps < 5 {
		t.Errorf("Expected at least 5 indirect dependencies, got %d", indirectDeps)
	}
}

// TestDependencyAnalyzer_EdgeCases tests edge cases and error conditions
func TestDependencyAnalyzer_EdgeCases(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_edge_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("No go.mod file", func(t *testing.T) {
		noModDir := filepath.Join(tempDir, "no_mod")
		err := os.MkdirAll(noModDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create no_mod dir: %v", err)
		}

		// Create Go file without go.mod
		content := `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"

func main() {
	fmt.Println("Hello World")
}
`
		err = os.WriteFile(filepath.Join(noModDir, "main.go"), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create main.go: %v", err)
		}

		analyzer, err := NewDependencyAnalyzer(noModDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create analyzer: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: noModDir,
			Output: "",
			Force:  false,
		}

		err = analyzer.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle missing go.mod gracefully: %v", err)
		}
	})

	t.Run("Invalid go.mod syntax", func(t *testing.T) {
		invalidModDir := filepath.Join(tempDir, "invalid_mod")
		err := os.MkdirAll(invalidModDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create invalid_mod dir: %v", err)
		}

		// Create invalid go.mod
		invalidGoMod := `this is not a valid go.mod file
		syntax error here
		module but no name
		require without version`

		err = os.WriteFile(filepath.Join(invalidModDir, "go.mod"), []byte(invalidGoMod), 0644)
		if err != nil {
			t.Fatalf("Failed to create invalid go.mod: %v", err)
		}

		analyzer, err := NewDependencyAnalyzer(invalidModDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create analyzer: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: invalidModDir,
			Output: "",
			Force:  false,
		}

		// Should handle parsing errors gracefully
		err = analyzer.Execute(ctx, opts)
		if err != nil {
			// It's acceptable for this to error, but shouldn't panic
			t.Logf("Expected error for invalid go.mod: %v", err)
		}
	})

	t.Run("Empty directory", func(t *testing.T) {
		emptyDir := filepath.Join(tempDir, "empty")
		err := os.MkdirAll(emptyDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create empty dir: %v", err)
		}

		analyzer, err := NewDependencyAnalyzer(emptyDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create analyzer: %v", err)
		}

		ctx := context.Background()
		opts := &OperationOptions{
			Target: emptyDir,
			Output: "",
			Force:  false,
		}

		err = analyzer.Execute(ctx, opts)
		if err != nil {
			t.Errorf("Execute should handle empty directory gracefully: %v", err)
		}
	})
}

// TestDependencyAnalyzer_DryRunMode tests dry run functionality
func TestDependencyAnalyzer_DryRunMode(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_dryrun_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test files
	goModContent := `module example.com/test

require (
	github.com/gin-gonic/gin v1.9.1
)`

	err = os.WriteFile(filepath.Join(tempDir, "go.mod"), []byte(goModContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create go.mod: %v", err)
	}

	// Test dry run mode
	analyzer, err := NewDependencyAnalyzer(tempDir, nil, true) // dry run = true
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	ctx := context.Background()
	opts := &OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "dryrun_report.json"),
		Force:  false,
	}

	err = analyzer.Execute(ctx, opts)
	if err != nil {
		t.Errorf("Execute in dry run mode failed: %v", err)
	}

	// Verify metrics indicate dry run
	metrics := analyzer.CollectMetrics()
	if dryRun, ok := metrics["dry_run"].(bool); !ok || !dryRun {
		t.Error("Expected dry_run metric to be true")
	}
}

// TestDependencyAnalyzer_Metrics tests metrics collection
func TestDependencyAnalyzer_Metrics(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_metrics_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	// Test initial metrics
	metrics := analyzer.CollectMetrics()

	expectedKeys := []string{"tool", "base_dir", "dry_run", "files_analyzed", "dependencies_found", "circular_dependencies"}
	for _, key := range expectedKeys {
		if _, exists := metrics[key]; !exists {
			t.Errorf("Missing expected metric key: %s", key)
		}
	}

	// Verify metric types
	if tool, ok := metrics["tool"].(string); !ok || tool != "DependencyAnalyzer" {
		t.Errorf("Expected tool to be 'DependencyAnalyzer', got %v", metrics["tool"])
	}

	if baseDir, ok := metrics["base_dir"].(string); !ok || baseDir != tempDir {
		t.Errorf("Expected base_dir to be %s, got %v", tempDir, metrics["base_dir"])
	}

	if _, ok := metrics["dry_run"].(bool); !ok {
		t.Error("Expected dry_run to be boolean")
	}
}

// TestDependencyAnalyzer_HealthCheck tests health check functionality
func TestDependencyAnalyzer_HealthCheck(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_health_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("Healthy analyzer", func(t *testing.T) {
		analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
		if err != nil {
			t.Fatalf("Failed to create analyzer: %v", err)
		}

		ctx := context.Background()
		err = analyzer.HealthCheck(ctx)
		if err != nil {
			t.Errorf("HealthCheck failed for valid setup: %v", err)
		}
	})

	t.Run("Invalid base directory", func(t *testing.T) {
		analyzer, err := NewDependencyAnalyzer("/non/existent/path", nil, false)
		if err == nil {
			ctx := context.Background()
			err = analyzer.HealthCheck(ctx)
			if err == nil {
				t.Error("HealthCheck should fail for non-existent directory")
			}
		}
	})
}

// BenchmarkDependencyAnalyzer_Execute benchmarks the Execute method
func BenchmarkDependencyAnalyzer_Execute(b *testing.B) {
	tempDir, err := os.MkdirTemp("", "dependency_analyzer_bench")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create go.mod with multiple dependencies
	goModContent := `module example.com/bench

go 1.19

require (
	github.com/gin-gonic/gin v1.9.1
	github.com/stretchr/testify v1.8.4
	golang.org/x/crypto v0.10.0
	github.com/gorilla/mux v1.8.0
	github.com/lib/pq v1.10.9
)

require (
	github.com/bytedance/sonic v1.9.1 // indirect
	github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311 // indirect
	github.com/gabriel-vasile/mimetype v1.4.2 // indirect
	golang.org/x/net v0.10.0 // indirect
	golang.org/x/sys v0.9.0 // indirect
)`

	err = os.WriteFile(filepath.Join(tempDir, "go.mod"), []byte(goModContent), 0644)
	if err != nil {
		b.Fatalf("Failed to create go.mod: %v", err)
	}

	// Create multiple Go files
	for i := 0; i < 5; i++ {
		content := fmt.Sprintf(`package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"
	"log"
	"net/http"
	
	"github.com/gin-gonic/gin"
	"github.com/gorilla/mux"
	"example.com/bench/pkg/service%d"
)

func handler%d() {
	fmt.Println("handler %d")
	log.Println("log %d")
	r := gin.Default()
	m := mux.NewRouter()
	_, _ = r, m
}`, i, i, i, i)

		dir := filepath.Join(tempDir, fmt.Sprintf("pkg/service%d", i))
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			b.Fatalf("Failed to create service dir: %v", err)
		}

		err = os.WriteFile(filepath.Join(dir, "service.go"), []byte(content), 0644)
		if err != nil {
			b.Fatalf("Failed to create service file: %v", err)
		}
	}

	analyzer, err := NewDependencyAnalyzer(tempDir, nil, false)
	if err != nil {
		b.Fatalf("Failed to create analyzer: %v", err)
	}

	ctx := context.Background()
	opts := &OperationOptions{
		Target: tempDir,
		Output: "",
		Force:  false,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := analyzer.Execute(ctx, opts)
		if err != nil {
			b.Fatal(err)
		}
	}
}


