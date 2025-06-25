// Manager Toolkit - Type Definition Generator
// Version: 3.0.0
// Generates missing type definitions based on usage analysis

package migration

import (
	"github.com/gerivdb/email-sender-1/tools/core/registry"
	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"context"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// TypeDefGenerator implémente l'interface toolkit.ToolkitOperation pour la génération de définitions de types
type TypeDefGenerator struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
	DryRun  bool
}

// UndefinedType représente un type non défini détecté
type UndefinedType struct {
	Name        string   `json:"name"`
	Package     string   `json:"package"`
	File        string   `json:"file"`
	Line        int      `json:"line"`
	Column      int      `json:"column"`
	Context     string   `json:"context"`     // Contexte d'utilisation
	UsageType   string   `json:"usage_type"`  // struct, interface, variable, etc.
	Suggestions []string `json:"suggestions"` // Suggestions de définition
}

// GeneratedType représente un type généré automatiquement
type GeneratedType struct {
	Name       string `json:"name"`
	Definition string `json:"definition"`
	Package    string `json:"package"`
	File       string `json:"file"`
	Reasoning  string `json:"reasoning"`
}

// TypeGenReport représente le rapport de génération de types
type TypeGenReport struct {
	Tool            string          `json:"tool"`
	Version         string          `json:"version"`
	Timestamp       time.Time       `json:"timestamp"`
	FilesAnalyzed   int             `json:"files_analyzed"`
	UndefinedTypes  []UndefinedType `json:"undefined_types"`
	GeneratedTypes  []GeneratedType `json:"generated_types"`
	DryRunMode      bool            `json:"dry_run_mode"`
	Summary         TypeGenSummary  `json:"summary"`
}

// TypeGenSummary fournit un résumé de la génération
type TypeGenSummary struct {
	UndefinedFound   int `json:"undefined_found"`
	TypesGenerated   int `json:"types_generated"`
	StructsGenerated int `json:"structs_generated"`
	InterfacesGen    int `json:"interfaces_generated"`
	AliasesGenerated int `json:"aliases_generated"`
}

// NewTypeDefGenerator creates a new TypeDefGenerator instance
func NewTypeDefGenerator(baseDir string, logger *toolkit.Logger, stats *toolkit.ToolkitStats, dryRun bool) *TypeDefGenerator {
	return &TypeDefGenerator{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  dryRun,
	}
}

// Execute implémente ToolkitOperation.Execute
func (tdg *TypeDefGenerator) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	if tdg.Logger == nil {
		return fmt.Errorf("logger is required")
	}

	tdg.Logger.Info("🔧 Starting type definition generation on: %s", options.Target)

	if tdg.FileSet == nil {
		tdg.FileSet = token.NewFileSet()
	}

	report := &TypeGenReport{
		Tool:           "TypeDefGenerator",
		Version:        "3.0.0",
		Timestamp:      time.Now(),
		DryRunMode:     tdg.DryRun,
		UndefinedTypes: make([]UndefinedType, 0),
		GeneratedTypes: make([]GeneratedType, 0),
		Summary:        TypeGenSummary{},
	}

	undefinedTypes := make(map[string][]UndefinedType)
	filesAnalyzed := 0

	err := filepath.Walk(options.Target, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip non-Go files
		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		// Skip test files and vendor directories
		if strings.Contains(path, "vendor/") || strings.Contains(path, ".git/") {
			return nil
		}

		filesAnalyzed++

		// Parse the file
		src, err := os.ReadFile(path)
		if err != nil {
			tdg.Logger.Error("Failed to read file %s: %v", path, err)
			return nil // Continue with other files
		}

		file, err := parser.ParseFile(tdg.FileSet, path, src, parser.ParseComments)
		if err != nil {
			tdg.Logger.Warn("Failed to parse file %s: %v", path, err)
			return nil // Continue with other files
		}

		// Analyze for undefined types
		ast.Inspect(file, func(n ast.Node) bool {
			switch node := n.(type) {
			case *ast.StructType:
				// Check field types in structs
				for _, field := range node.Fields.List {
					if ident, ok := field.Type.(*ast.Ident); ok {
						if tdg.isUndefinedType(ident.Name, file) {
							pos := tdg.FileSet.Position(ident.Pos())
							undefinedType := UndefinedType{
								Name:        ident.Name,
								Package:     file.Name.Name,
								File:        path,
								Line:        pos.Line,
								Column:      pos.Column,
								Context:     "struct_field",
								UsageType:   "type_reference",
								Suggestions: tdg.generateSuggestions(ident.Name, "struct_field"),
							}
							undefinedTypes[ident.Name] = append(undefinedTypes[ident.Name], undefinedType)
						}
					}
				}
			case *ast.GenDecl:
				if node.Tok == token.VAR || node.Tok == token.CONST {
					// Check variable/constant type declarations
					for _, spec := range node.Specs {
						if valueSpec, ok := spec.(*ast.ValueSpec); ok && valueSpec.Type != nil {
							if ident, ok := valueSpec.Type.(*ast.Ident); ok {
								if tdg.isUndefinedType(ident.Name, file) {
									pos := tdg.FileSet.Position(ident.Pos())
									undefinedType := UndefinedType{
										Name:        ident.Name,
										Package:     file.Name.Name,
										File:        path,
										Line:        pos.Line,
										Column:      pos.Column,
										Context:     "variable_declaration",
										UsageType:   "type_reference",
										Suggestions: tdg.generateSuggestions(ident.Name, "variable"),
									}
									undefinedTypes[ident.Name] = append(undefinedTypes[ident.Name], undefinedType)
								}
							}
						}
					}
				}
			case *ast.FuncDecl:
				// Check function parameters and return types
				if node.Type.Params != nil {
					for _, param := range node.Type.Params.List {
						if ident, ok := param.Type.(*ast.Ident); ok {
							if tdg.isUndefinedType(ident.Name, file) {
								pos := tdg.FileSet.Position(ident.Pos())
								undefinedType := UndefinedType{
									Name:        ident.Name,
									Package:     file.Name.Name,
									File:        path,
									Line:        pos.Line,
									Column:      pos.Column,
									Context:     "function_parameter",
									UsageType:   "type_reference",
									Suggestions: tdg.generateSuggestions(ident.Name, "parameter"),
								}
								undefinedTypes[ident.Name] = append(undefinedTypes[ident.Name], undefinedType)
							}
						}
					}
				}
			}
			return true
		})

		return nil
	})

	if err != nil {
		tdg.Logger.Error("Error walking directory: %v", err)
		return err
	}

	// Generate type definitions for undefined types
	for typeName, occurrences := range undefinedTypes {
		report.UndefinedTypes = append(report.UndefinedTypes, occurrences...)
		
		if !tdg.DryRun && options.Force {
			generatedType := tdg.generateTypeDefinition(typeName, occurrences)
			if generatedType != nil {
				report.GeneratedTypes = append(report.GeneratedTypes, *generatedType)
				report.Summary.TypesGenerated++
				
				// Determine type category
				if strings.Contains(generatedType.Definition, "struct") {
					report.Summary.StructsGenerated++
				} else if strings.Contains(generatedType.Definition, "interface") {
					report.Summary.InterfacesGen++
				} else {
					report.Summary.AliasesGenerated++
				}
				
				tdg.Logger.Info("✅ Generated type definition for: %s", typeName)
			}
		}
	}

	// Update report summary
	report.FilesAnalyzed = filesAnalyzed
	report.Summary.UndefinedFound = len(undefinedTypes)

	// Update toolkit stats
	if tdg.Stats != nil {
		tdg.Stats.FilesAnalyzed += filesAnalyzed
		tdg.Stats.ErrorsFixed += report.Summary.TypesGenerated
	}

	// Generate report if output specified
	if options.Output != "" {
		if err := tdg.generateReport(report, options.Output); err != nil {
			tdg.Logger.Error("Failed to generate report: %v", err)
			return err
		}
		tdg.Logger.Info("📄 Report generated: %s", options.Output)
	}

	tdg.Logger.Info("✅ Type definition generation completed: %d files analyzed, %d undefined types found, %d types generated", 
		filesAnalyzed, report.Summary.UndefinedFound, report.Summary.TypesGenerated)

	return nil
}

// Validate implémente ToolkitOperation.Validate
func (tdg *TypeDefGenerator) Validate(ctx context.Context) error {
	if tdg.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}
	if tdg.Logger == nil {
		return fmt.Errorf("Logger is required")
	}
	if _, err := os.Stat(tdg.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", tdg.BaseDir)
	}
	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (tdg *TypeDefGenerator) CollectMetrics() map[string]interface{} {
	metrics := map[string]interface{}{
		"tool":           "TypeDefGenerator",
		"version":        "3.0.0",
		"dry_run_mode":   tdg.DryRun,
		"base_directory": tdg.BaseDir,
	}

	if tdg.Stats != nil {
		metrics["files_analyzed"] = tdg.Stats.FilesAnalyzed
		metrics["errors_fixed"] = tdg.Stats.ErrorsFixed
	}

	return metrics
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (tdg *TypeDefGenerator) HealthCheck(ctx context.Context) error {
	if tdg.FileSet == nil {
		return fmt.Errorf("FileSet not initialized")
	}

	// Check access to base directory
	if _, err := os.Stat(tdg.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", tdg.BaseDir)
	}

	// Test parser functionality
	testCode := "package main\n\ntype TestType struct {}\n"
	_, err := parser.ParseFile(tdg.FileSet, "test.go", testCode, 0)
	if err != nil {
		return fmt.Errorf("parser functionality test failed: %v", err)
	}

	return nil
}

// isUndefinedType vérifie si un type est non défini dans le contexte actuel
func (tdg *TypeDefGenerator) isUndefinedType(typeName string, file *ast.File) bool {
	// Skip built-in types
	builtinTypes := map[string]bool{
		"bool": true, "byte": true, "complex64": true, "complex128": true,
		"error": true, "float32": true, "float64": true,
		"int": true, "int8": true, "int16": true, "int32": true, "int64": true,
		"rune": true, "string": true,
		"uint": true, "uint8": true, "uint16": true, "uint32": true, "uint64": true, "uintptr": true,
		"interface{}": true, "any": true,
	}

	if builtinTypes[typeName] {
		return false
	}

	// Check if type is defined in current file
	for _, decl := range file.Decls {
		if genDecl, ok := decl.(*ast.GenDecl); ok && genDecl.Tok == token.TYPE {
			for _, spec := range genDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					if typeSpec.Name.Name == typeName {
						return false // Type is defined
					}
				}
			}
		}
	}

	// Check imports (simplified)
	for _, imp := range file.Imports {
		// This is a simplified check - in reality we'd need to resolve imports properly
		if strings.Contains(imp.Path.Value, strings.ToLower(typeName)) {
			return false
		}
	}

	return true // Type appears to be undefined
}

// generateSuggestions génère des suggestions de définition pour un type
func (tdg *TypeDefGenerator) generateSuggestions(typeName string, context string) []string {
	suggestions := make([]string, 0)

	// Generate different type suggestions based on naming conventions
	if strings.HasSuffix(typeName, "Config") || strings.HasSuffix(typeName, "Settings") {
		suggestions = append(suggestions, fmt.Sprintf("type %s struct {\n\t// Configuration fields\n}", typeName))
	} else if strings.HasSuffix(typeName, "Interface") || strings.HasSuffix(typeName, "er") {
		suggestions = append(suggestions, fmt.Sprintf("type %s interface {\n\t// Interface methods\n}", typeName))
	} else if strings.HasSuffix(typeName, "Error") {
		suggestions = append(suggestions, fmt.Sprintf("type %s struct {\n\tmessage string\n}", typeName))
		suggestions = append(suggestions, fmt.Sprintf("func (e %s) Error() string {\n\treturn e.message\n}", typeName))
	} else if strings.HasSuffix(typeName, "ID") || strings.HasSuffix(typeName, "Key") {
		suggestions = append(suggestions, fmt.Sprintf("type %s string", typeName))
	} else {
		// Generic struct suggestion
		suggestions = append(suggestions, fmt.Sprintf("type %s struct {\n\t// TODO: Add fields\n}", typeName))
		// Generic interface suggestion
		suggestions = append(suggestions, fmt.Sprintf("type %s interface {\n\t// TODO: Add methods\n}", typeName))
	}

	return suggestions
}

// generateTypeDefinition génère une définition de type automatiquement
func (tdg *TypeDefGenerator) generateTypeDefinition(typeName string, occurrences []UndefinedType) *GeneratedType {
	if len(occurrences) == 0 {
		return nil
	}

	// Analyze usage context to determine best type definition
	structUsages := 0
	interfaceUsages := 0
	
	for _, occ := range occurrences {
		switch occ.Context {
		case "struct_field", "variable_declaration":
			structUsages++
		case "function_parameter":
			interfaceUsages++
		}
	}

	var definition string
	var reasoning string

	if structUsages > interfaceUsages {
		definition = tdg.generateStructDefinition(typeName, occurrences)
		reasoning = "Generated as struct based on field usage patterns"
	} else {
		definition = tdg.generateInterfaceDefinition(typeName, occurrences)
		reasoning = "Generated as interface based on parameter usage patterns"
	}

	// Use the first occurrence for package and file info
	firstOcc := occurrences[0]
	
	return &GeneratedType{
		Name:       typeName,
		Definition: definition,
		Package:    firstOcc.Package,
		File:       firstOcc.File,
		Reasoning:  reasoning,
	}
}

// generateStructDefinition génère une définition de structure
func (tdg *TypeDefGenerator) generateStructDefinition(typeName string, occurrences []UndefinedType) string {
	return fmt.Sprintf(`// %s represents a %s structure
// Generated automatically by TypeDefGenerator
type %s struct {
	// TODO: Add appropriate fields based on usage
	// Found %d usage(s) in codebase
}`, typeName, strings.ToLower(typeName), typeName, len(occurrences))
}

// generateInterfaceDefinition génère une définition d'interface
func (tdg *TypeDefGenerator) generateInterfaceDefinition(typeName string, occurrences []UndefinedType) string {
	return fmt.Sprintf(`// %s represents a %s interface
// Generated automatically by TypeDefGenerator
type %s interface {
	// TODO: Add appropriate methods based on usage
	// Found %d usage(s) in codebase
}`, typeName, strings.ToLower(typeName), typeName, len(occurrences))
}

// generateReport génère un rapport JSON
func (tdg *TypeDefGenerator) generateReport(report *TypeGenReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %v", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write report file: %v", err)
	}

	return nil
}

// String implémente ToolkitOperation.String - identification de l'outil
func (tdg *TypeDefGenerator) String() string {
	return "TypeDefGenerator"
}

// GetDescription implémente ToolkitOperation.GetDescription - description de l'outil
func (tdg *TypeDefGenerator) GetDescription() string {
	return "Generates missing type definitions based on usage analysis in Go codebases"
}

// Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt
func (tdg *TypeDefGenerator) Stop(ctx context.Context) error {
	return nil
}

// init registers the TypeDefGenerator tool automatically
func init() {
	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		globalReg = registry.NewToolRegistry()
		// registry.SetGlobalRegistry(globalReg) // If a setter exists
	}
	
	// Create a default instance for registration
	defaultTool := &TypeDefGenerator{
		BaseDir: "", // Default or placeholder
		FileSet: token.NewFileSet(), // Initialize FileSet
		Logger:  nil, // Logger should be initialized by the toolkit
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  false,
	}
	
	err := globalReg.Register(toolkit.TypeDefGen, defaultTool) // Changed to toolkit.TypeDefGen
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register TypeDefGenerator: %v\n", err)
	}
}


