// Manager Toolkit - Interface Analyzer Professional Tests
// Tests for interface_analyzer_pro.go functionality

package analysis

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestNewInterfaceAnalyzerPro tests analyzer creation
func TestNewInterfaceAnalyzerPro(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "analyzer_test")
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
			analyzer, err := NewInterfaceAnalyzerPro(tt.baseDir, nil, false)

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

// TestAnalyzeInterfaces tests interface analysis functionality
func TestAnalyzeInterfaces(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "analyze_interfaces_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test interface files
	testInterfaces := map[string]string{
		"user_manager.go": `package main

type UserManager interface {
	CreateUser(name string) (*User, error)
	GetUser(id int) (*User, error)
	UpdateUser(user *User) error
	DeleteUser(id int) error
	ListUsers() ([]*User, error)
}

type User struct {
	ID   int    ` + "`json:\"id\"`" + `
	Name string ` + "`json:\"name\"`" + `
}`,
		"data_provider.go": `package main

import (
	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"context"

type DataProvider interface {
	FetchData(ctx context.Context, query string) ([]byte, error)
	SaveData(ctx context.Context, data []byte) error
	DeleteData(ctx context.Context, id string) error
}`,
		"empty_interface.go": `package main

type EmptyInterface interface {}`,
		"no_interface.go": `package main

func regularFunction() string {
	return "not an interface"
}

type RegularStruct struct {
	Field string
}`,
	}

	for filename, content := range testInterfaces {
		err := ioutil.WriteFile(filepath.Join(tempDir, filename), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	results, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		t.Fatalf("Analysis failed: %v", err)
	}

	// Verify results
	if len(results.Interfaces) == 0 {
		t.Error("Expected to find interfaces, but found none")
	}

	// Check specific interfaces
	foundUserManager := false
	foundDataProvider := false
	foundEmptyInterface := false

	for _, iface := range results.Interfaces {
		switch iface.Name {
		case "UserManager":
			foundUserManager = true
			if len(iface.Methods) != 5 {
				t.Errorf("UserManager should have 5 methods, got %d", len(iface.Methods))
			}
		case "DataProvider":
			foundDataProvider = true
			if len(iface.Methods) != 3 {
				t.Errorf("DataProvider should have 3 methods, got %d", len(iface.Methods))
			}
		case "EmptyInterface":
			foundEmptyInterface = true
			if len(iface.Methods) != 0 {
				t.Errorf("EmptyInterface should have 0 methods, got %d", len(iface.Methods))
			}
		}
	}

	if !foundUserManager {
		t.Error("UserManager interface not found")
	}
	if !foundDataProvider {
		t.Error("DataProvider interface not found")
	}
	if !foundEmptyInterface {
		t.Error("EmptyInterface not found")
	}

	// Verify statistics
	if results.Stats.TotalFiles == 0 {
		t.Error("Total files should be greater than 0")
	}
	if results.Stats.InterfaceFiles == 0 {
		t.Error("Interface files should be greater than 0")
	}
	if results.Stats.TotalInterfaces == 0 {
		t.Error("Total interfaces should be greater than 0")
	}
}

// TestAnalyzeSpecificInterface tests analysis of a specific interface
func TestAnalyzeSpecificInterface(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "specific_interface_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test interface
	interfaceContent := `package main

import (
	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"context"

type DatabaseManager interface {
	// Connect establishes database connection
	Connect(dsn string) error
	
	// Query executes a query and returns results
	Query(ctx context.Context, sql string, args ...interface{}) ([]map[string]interface{}, error)
	
	// Execute runs a command without returning results
	Execute(ctx context.Context, sql string, args ...interface{}) error
	
	// Close closes the database connection
	Close() error
}`

	filename := filepath.Join(tempDir, "database.go")
	err = ioutil.WriteFile(filename, []byte(interfaceContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create interface file: %v", err)
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	results, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		t.Fatalf("Analysis failed: %v", err)
	}

	// Find DatabaseManager interface
	var dbManager *InterfaceInfo
	for _, iface := range results.Interfaces {
		if iface.Name == "DatabaseManager" {
			dbManager = &iface
			break
		}
	}

	if dbManager == nil {
		t.Fatal("DatabaseManager interface not found")
	}

	// Verify interface details
	if len(dbManager.Methods) != 4 {
		t.Errorf("DatabaseManager should have 4 methods, got %d", len(dbManager.Methods))
	}

	// Check specific methods
	methodNames := make(map[string]bool)
	for _, method := range dbManager.Methods {
		methodNames[method.Name] = true
	}

	expectedMethods := []string{"Connect", "Query", "Execute", "Close"}
	for _, expectedMethod := range expectedMethods {
		if !methodNames[expectedMethod] {
			t.Errorf("Method %s not found in DatabaseManager interface", expectedMethod)
		}
	}

	// Verify the Query method has parameters and return values
	var queryMethod *MethodInfo
	for _, method := range dbManager.Methods {
		if method.Name == "Query" {
			queryMethod = &method
			break
		}
	}

	if queryMethod == nil {
		t.Fatal("Query method not found")
	}

	if len(queryMethod.Parameters) == 0 {
		t.Error("Query method should have parameters")
	}
	if len(queryMethod.Returns) == 0 {
		t.Error("Query method should have return values")
	}
}

// TestGenerateAnalysisReport tests report generation
func TestGenerateAnalysisReport(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "report_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test interface
	interfaceContent := `package main

type ReportTestInterface interface {
	Method1() string
	Method2(param int) error
}`

	err = ioutil.WriteFile(filepath.Join(tempDir, "test.go"), []byte(interfaceContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	_, err = analyzer.AnalyzeInterfaces()
	if err != nil {
		t.Fatalf("Analysis failed: %v", err)
	}

	// Test JSON report generation
	jsonReport, err := analyzer.GenerateAnalysisReport("json")
	if err != nil {
		t.Errorf("Failed to generate JSON report: %v", err)
	}
	if len(jsonReport) == 0 {
		t.Error("JSON report should not be empty")
	}
	if !strings.Contains(string(jsonReport), "ReportTestInterface") {
		t.Error("JSON report should contain interface name")
	}
	// Test YAML report generation
	yamlReport, err := analyzer.GenerateAnalysisReport("yaml")
	if err != nil {
		t.Errorf("Failed to generate YAML report: %v", err)
	}
	if len(yamlReport) == 0 {
		t.Error("YAML report should not be empty")
	}
	// Test invalid format
	_, err = analyzer.GenerateAnalysisReport("invalid")
	if err == nil {
		t.Error("Expected error for invalid format")
	}
}

// TestInterfaceComplexity tests complexity analysis
func TestInterfaceComplexity(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "complexity_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create interfaces with different complexity levels
	testInterfaces := map[string]string{
		"simple.go": `package main
type SimpleInterface interface {
	GetValue() string
}`,
		"complex.go": `package main
import (
	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"context"
type ComplexInterface interface {
	Process(ctx context.Context, data []byte, options map[string]interface{}) (*Result, error)
	Configure(settings *Settings) error
	Validate(rules []ValidationRule) ([]ValidationError, error)
	Transform(input interface{}, transformers ...Transformer) (interface{}, error)
	Aggregate(results []Result, aggregator func([]Result) Result) Result
}

type Result struct {
	Data []byte
	Meta map[string]interface{}
}

type Settings struct {
	Timeout int
	Retries int
}

type ValidationRule interface {
	Apply(interface{}) error
}

type ValidationError struct {
	Field   string
	Message string
}

type Transformer interface {
	Transform(interface{}) (interface{}, error)
}`,
	}

	for filename, content := range testInterfaces {
		err := ioutil.WriteFile(filepath.Join(tempDir, filename), []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	results, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		t.Fatalf("Analysis failed: %v", err)
	}

	// Find interfaces and verify complexity
	var simpleInterface, complexInterface *InterfaceInfo
	for _, iface := range results.Interfaces {
		if iface.Name == "SimpleInterface" {
			simpleInterface = &iface
		} else if iface.Name == "ComplexInterface" {
			complexInterface = &iface
		}
	}

	if simpleInterface == nil {
		t.Fatal("SimpleInterface not found")
	}
	if complexInterface == nil {
		t.Fatal("ComplexInterface not found")
	}

	// Verify method counts
	if len(simpleInterface.Methods) != 1 {
		t.Errorf("SimpleInterface should have 1 method, got %d", len(simpleInterface.Methods))
	}
	if len(complexInterface.Methods) != 5 {
		t.Errorf("ComplexInterface should have 5 methods, got %d", len(complexInterface.Methods))
	}

	// Complex interface should have methods with more parameters
	hasComplexMethod := false
	for _, method := range complexInterface.Methods {
		if len(method.Parameters) > 2 {
			hasComplexMethod = true
			break
		}
	}
	if !hasComplexMethod {
		t.Error("ComplexInterface should have at least one method with multiple parameters")
	}
}

// TestAnalyzerWithLogger tests analyzer with custom toolkit.Logger
func TestAnalyzerWithLogger(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "logger_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create simple interface
	interfaceContent := `package main
type LoggerTestInterface interface {
	Log(message string) error
}`
	err = ioutil.WriteFile(filepath.Join(tempDir, "logger_test.go"), []byte(interfaceContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, true) // verbose mode
	if err != nil {
		t.Fatalf("Failed to create analyzer: %v", err)
	}

	results, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		t.Fatalf("Analysis failed: %v", err)
	}

	if len(results.Interfaces) == 0 {
		t.Error("Expected to find interface")
	}
}

// TestAnalyzerErrorHandling tests error handling scenarios
func TestAnalyzerErrorHandling(t *testing.T) {
	tempDir, err := ioutil.TempDir("", "error_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	tests := []struct {
		name        string
		filename    string
		content     string
		expectError bool
	}{
		{
			name:     "Valid Go file",
			filename: "valid.go",
			content: `package main
type ValidInterface interface {
	Method() error
}`,
			expectError: false,
		},
		{
			name:     "Invalid Go syntax",
			filename: "invalid.go",
			content: `package main
type InvalidInterface interface {
	Method() error
	// Missing closing brace`,
			expectError: true,
		},
		{
			name:        "Empty file",
			filename:    "empty.go",
			content:     "",
			expectError: false, // Empty files should be handled gracefully
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Clean temp directory
			files, _ := filepath.Glob(filepath.Join(tempDir, "*.go"))
			for _, f := range files {
				os.Remove(f)
			} // Create test file
			err := ioutil.WriteFile(filepath.Join(tempDir, tt.filename), []byte(tt.content), 0644)
			if err != nil {
				t.Fatalf("Failed to create test file: %v", err)
			}

			analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
			if err != nil {
				t.Fatalf("Failed to create analyzer: %v", err)
			}

			_, err = analyzer.AnalyzeInterfaces()

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		})
	}
}

// BenchmarkAnalyzeInterfaces benchmarks interface analysis performance
func BenchmarkAnalyzeInterfaces(b *testing.B) {
	tempDir, err := ioutil.TempDir("", "benchmark_analyzer")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create multiple interface files for benchmarking
	for i := 0; i < 10; i++ {
		content := fmt.Sprintf(`package main

type Interface%d interface {
	Method1%d() string
	Method2%d(param int) error
	Method3%d() (string, error)
}`, i, i, i, i)

		filename := filepath.Join(tempDir, fmt.Sprintf("interface%d.go", i))
		err := ioutil.WriteFile(filename, []byte(content), 0644)
		if err != nil {
			b.Fatalf("Failed to create test file: %v", err)
		}
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		b.Fatalf("Failed to create analyzer: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		analyzer.AnalyzeInterfaces()
	}
}

// BenchmarkGenerateReport benchmarks report generation performance
func BenchmarkGenerateReport(b *testing.B) {
	tempDir, err := ioutil.TempDir("", "benchmark_report")
	if err != nil {
		b.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Create test interface
	interfaceContent := `package main
type BenchmarkInterface interface {
	Method1() string
	Method2(int) error
	Method3() (string, error)
}`

	err = ioutil.WriteFile(filepath.Join(tempDir, "benchmark.go"), []byte(interfaceContent), 0644)
	if err != nil {
		b.Fatalf("Failed to create test file: %v", err)
	}
	analyzer, err := NewInterfaceAnalyzerPro(tempDir, nil, false)
	if err != nil {
		b.Fatalf("Failed to create analyzer: %v", err)
	}

	_, err = analyzer.AnalyzeInterfaces()
	if err != nil {
		b.Fatalf("Analysis failed: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		analyzer.GenerateAnalysisReport("json")
	}
}


