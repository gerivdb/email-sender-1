// Manager Toolkit - Type Definition Generator Tests
// Version: 3.0.0

package migration

import (
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTypeDefGenerator_ImplementsToolkitOperation(t *testing.T) {
	var _ toolkit.ToolkitOperation = &TypeDefGenerator{}
}

func TestTypeDefGenerator_NewInstance(t *testing.T) {
	tmpDir := t.TempDir()
	toolkit.Logger := &Logger{}
	stats := &ToolkitStats{}

	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	assert.Equal(t, tmpDir, generator.BaseDir)
	assert.NotNil(t, generator.FileSet)
	assert.Equal(t, logger, generator.Logger)
	assert.Equal(t, stats, generator.Stats)
	assert.False(t, generator.DryRun)
}

func TestTypeDefGenerator_Validate(t *testing.T) {
	tests := []struct {
		name          string
		generator     *TypeDefGenerator
		expectedError string
	}{
		{
			name: "valid_generator",
			generator: &TypeDefGenerator{
				BaseDir: t.TempDir(),
				Logger:  &Logger{},
			},
			expectedError: "",
		},
		{
			name: "missing_base_dir",
			generator: &TypeDefGenerator{
				Logger: &Logger{},
			},
			expectedError: "BaseDir is required",
		},
		{
			name: "missing_logger",
			generator: &TypeDefGenerator{
				BaseDir: t.TempDir(),
			},
			expectedError: "Logger is required",
		},
		{
			name: "non_existent_directory",
			generator: &TypeDefGenerator{
				BaseDir: "/non/existent/path",
				Logger:  &Logger{},
			},
			expectedError: "base directory does not exist",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx := context.Background()
			err := tt.generator.Validate(ctx)

			if tt.expectedError == "" {
				assert.NoError(t, err)
			} else {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			}
		})
	}
}

func TestTypeDefGenerator_HealthCheck(t *testing.T) {
	tmpDir := t.TempDir()
	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  &Logger{},
		Stats:   &ToolkitStats{},
	}

	ctx := context.Background()
	err := generator.HealthCheck(ctx)
	assert.NoError(t, err)
}

func TestTypeDefGenerator_HealthCheck_Failures(t *testing.T) {
	tests := []struct {
		name          string
		generator     *TypeDefGenerator
		expectedError string
	}{
		{
			name: "missing_fileset",
			generator: &TypeDefGenerator{
				BaseDir: t.TempDir(),
				Logger:  &Logger{},
			},
			expectedError: "FileSet not initialized",
		},
		{
			name: "invalid_directory",
			generator: &TypeDefGenerator{
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
			err := tt.generator.HealthCheck(ctx)
			assert.Error(t, err)
			assert.Contains(t, err.Error(), tt.expectedError)
		})
	}
}

func TestTypeDefGenerator_CollectMetrics(t *testing.T) {
	tmpDir := t.TempDir()
	stats := &ToolkitStats{
		FilesAnalyzed: 10,
		ErrorsFixed:   5,
	}

	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  &Logger{},
		Stats:   stats,
		DryRun:  true,
	}

	metrics := generator.CollectMetrics()

	assert.Equal(t, "TypeDefGenerator", metrics["tool"])
	assert.Equal(t, "3.0.0", metrics["version"])
	assert.Equal(t, true, metrics["dry_run_mode"])
	assert.Equal(t, tmpDir, metrics["base_directory"])
	assert.Equal(t, 10, metrics["files_analyzed"])
	assert.Equal(t, 5, metrics["errors_fixed"])
}

func TestTypeDefGenerator_Execute_WithUndefinedTypes(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with undefined types
	goCodeWithUndefined := `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"

type UserProfile struct {
	ID       UserID          // Undefined type
	Settings UserSettings    // Undefined type
	Metadata CustomMetadata // Undefined type
}

func ProcessUser(user UserProfile, config AppConfig) error {
	fmt.Println("Processing user")
	return nil
}
`

	goFile := filepath.Join(tmpDir, "example.go")
	err := os.WriteFile(goFile, []byte(goCodeWithUndefined), 0644)
	require.NoError(t, err)

	toolkit.Logger := &Logger{}
	stats := &ToolkitStats{}
	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  true, // Don't actually generate files
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "typegen_report.json"),
		Force:  false,
	}

	err = generator.Execute(ctx, options)
	assert.NoError(t, err)

	// Check report was generated
	reportData, err := os.ReadFile(options.Output)
	require.NoError(t, err)

	var report TypeGenReport
	err = json.Unmarshal(reportData, &report)
	require.NoError(t, err)

	assert.Equal(t, "TypeDefGenerator", report.Tool)
	assert.Equal(t, "3.0.0", report.Version)
	assert.True(t, report.DryRunMode)
	assert.Greater(t, report.Summary.UndefinedFound, 0)
	assert.GreaterOrEqual(t, len(report.UndefinedTypes), 3) // At least UserID, UserSettings, CustomMetadata, AppConfig
}

func TestTypeDefGenerator_Execute_ValidGoFile(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with only defined types
	validGoCode := `package main

import (
	"github.com/email-sender/tools/core/toolkit"
	"fmt"

type User struct {
	ID   int
	Name string
}

func main() {
	user := User{ID: 1, Name: "Test"}
	fmt.Println(user)
}
`

	goFile := filepath.Join(tmpDir, "valid.go")
	err := os.WriteFile(goFile, []byte(validGoCode), 0644)
	require.NoError(t, err)

	toolkit.Logger := &Logger{}
	stats := &ToolkitStats{}
	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false,
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "typegen_report.json"),
		Force:  false,
	}

	err = generator.Execute(ctx, options)
	assert.NoError(t, err)
	assert.Greater(t, stats.FilesAnalyzed, 0)

	// Check report was generated
	reportData, err := os.ReadFile(options.Output)
	require.NoError(t, err)

	var report TypeGenReport
	err = json.Unmarshal(reportData, &report)
	require.NoError(t, err)

	assert.Equal(t, 0, report.Summary.UndefinedFound) // No undefined types
}

func TestTypeDefGenerator_IsUndefinedType(t *testing.T) {
	generator := &TypeDefGenerator{}

	tests := []struct {
		name        string
		typeName    string
		goCode      string
		isUndefined bool
	}{
		{
			name:        "builtin_type_string",
			typeName:    "string",
			goCode:      "package main\n",
			isUndefined: false,
		},
		{
			name:        "builtin_type_int",
			typeName:    "int",
			goCode:      "package main\n",
			isUndefined: false,
		},
		{
			name:        "defined_type_in_file",
			typeName:    "CustomType",
			goCode:      "package main\n\ntype CustomType struct {}\n",
			isUndefined: false,
		},
		{
			name:        "undefined_type",
			typeName:    "UndefinedType",
			goCode:      "package main\n\ntype Other struct {}\n",
			isUndefined: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fset := token.NewFileSet()
			file, err := parser.ParseFile(fset, "test.go", tt.goCode, 0)
			require.NoError(t, err)

			result := generator.isUndefinedType(tt.typeName, file)
			assert.Equal(t, tt.isUndefined, result)
		})
	}
}

func TestTypeDefGenerator_GenerateSuggestions(t *testing.T) {
	generator := &TypeDefGenerator{}

	tests := []struct {
		name                string
		typeName            string
		context             string
		expectedSuggestions int
	}{
		{
			name:                "config_type",
			typeName:            "AppConfig",
			context:             "struct_field",
			expectedSuggestions: 1,
		},
		{
			name:                "interface_type",
			typeName:            "UserInterface",
			context:             "parameter",
			expectedSuggestions: 1,
		},
		{
			name:                "error_type",
			typeName:            "CustomError",
			context:             "variable",
			expectedSuggestions: 2, // struct + Error method
		},
		{
			name:                "id_type",
			typeName:            "UserID",
			context:             "struct_field",
			expectedSuggestions: 1,
		},
		{
			name:                "generic_type",
			typeName:            "SomeType",
			context:             "variable",
			expectedSuggestions: 2, // struct + interface suggestions
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			suggestions := generator.generateSuggestions(tt.typeName, tt.context)
			assert.GreaterOrEqual(t, len(suggestions), tt.expectedSuggestions)

			// Check that suggestions contain the type name
			for _, suggestion := range suggestions {
				assert.Contains(t, suggestion, tt.typeName)
			}
		})
	}
}

func TestTypeDefGenerator_GenerateTypeDefinition(t *testing.T) {
	generator := &TypeDefGenerator{}

	occurrences := []UndefinedType{
		{
			Name:      "UserConfig",
			Package:   "main",
			File:      "test.go",
			Context:   "struct_field",
			UsageType: "type_reference",
		},
		{
			Name:      "UserConfig",
			Package:   "main",
			File:      "test.go",
			Context:   "variable_declaration",
			UsageType: "type_reference",
		},
	}

	generatedType := generator.generateTypeDefinition("UserConfig", occurrences)
	require.NotNil(t, generatedType)

	assert.Equal(t, "UserConfig", generatedType.Name)
	assert.Equal(t, "main", generatedType.Package)
	assert.Equal(t, "test.go", generatedType.File)
	assert.Contains(t, generatedType.Definition, "UserConfig")
	assert.Contains(t, generatedType.Definition, "struct")
	assert.NotEmpty(t, generatedType.Reasoning)
}

func TestTypeDefGenerator_WithForceGeneration(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a Go file with undefined types
	goCodeWithUndefined := `package main

type Config struct {
	Database DatabaseConfig // Undefined
}
`

	goFile := filepath.Join(tmpDir, "config.go")
	err := os.WriteFile(goFile, []byte(goCodeWithUndefined), 0644)
	require.NoError(t, err)

	toolkit.Logger := &Logger{}
	stats := &ToolkitStats{}
	generator := &TypeDefGenerator{
		BaseDir: tmpDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  false, // Actually generate
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: tmpDir,
		Output: filepath.Join(tmpDir, "typegen_report.json"),
		Force:  true, // Force generation
	}

	err = generator.Execute(ctx, options)
	assert.NoError(t, err)

	// Check report
	reportData, err := os.ReadFile(options.Output)
	require.NoError(t, err)

	var report TypeGenReport
	err = json.Unmarshal(reportData, &report)
	require.NoError(t, err)

	assert.False(t, report.DryRunMode)
	assert.Greater(t, report.Summary.UndefinedFound, 0)
	assert.GreaterOrEqual(t, report.Summary.TypesGenerated, 1)
}

// Benchmark tests
func BenchmarkTypeDefGenerator_Execute(b *testing.B) {
	tmpDir := b.TempDir()

	// Create multiple Go files with undefined types
	for i := 0; i < 5; i++ {
		testCode := fmt.Sprintf(`package main

type User%d struct {
	ID       UserID%d
	Config   UserConfig%d
	Metadata CustomMetadata%d
}

func Process%d(user User%d) error {
	return nil
}
`, i, i, i, i, i, i)

		goFile := filepath.Join(tmpDir, fmt.Sprintf("test%d.go", i))
		err := os.WriteFile(goFile, []byte(testCode), 0644)
		require.NoError(b, err)
	}

	toolkit.Logger := &Logger{}
	stats := &ToolkitStats{}
	generator := &TypeDefGenerator{
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
		generator.Execute(ctx, options)
	}
}


