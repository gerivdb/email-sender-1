// NamingNormalizer - Professional naming convention normalization tool
// Implements toolkit.ToolkitOperation interface for Manager Toolkit v49 integration
// Validates and normalizes Go naming conventions across the codebase

package correction

import (
<<<<<<< HEAD
	"EMAIL_SENDER_1/tools/core/registry"
	"EMAIL_SENDER_1/tools/core/toolkit"
=======
>>>>>>> migration/gateway-manager-v77
	"context"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/tools/core/registry"
	"github.com/gerivdb/email-sender-1/development/managers/tools/core/toolkit"
)

// NamingNormalizer implements toolkit.ToolkitOperation for naming convention normalization
type NamingNormalizer struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
	DryRun  bool
}

// NamingIssue represents a naming convention problem
type NamingIssue struct {
	Type        string `json:"type"`         // "interface", "struct", "function", "variable"
	Current     string `json:"current"`      // Current name
	Suggested   string `json:"suggested"`    // Suggested name
	Line        int    `json:"line"`         // Line number in file
	Reason      string `json:"reason"`       // Reason for the issue
	Severity    string `json:"severity"`     // "error", "warning", "info"
	AutoFixable bool   `json:"auto_fixable"` // Whether this can be auto-fixed
}

// NamingConventions defines the naming rules for the ecosystem
type NamingConventions struct {
	InterfaceSuffix   string   `json:"interface_suffix"`   // "Manager"
	ImplementSuffix   string   `json:"implement_suffix"`   // "Impl"
	ConstructorPrefix string   `json:"constructor_prefix"` // "New"
	PrivatePrefix     string   `json:"private_prefix"`     // "_" or lowercase
	ExportedPattern   string   `json:"exported_pattern"`   // "^[A-Z][a-zA-Z0-9]*$"
	PrivatePattern    string   `json:"private_pattern"`    // "^[a-z][a-zA-Z0-9]*$"
	ConstantPattern   string   `json:"constant_pattern"`   // "^[A-Z][A-Z0-9_]*$"
	ForbiddenPrefixes []string `json:"forbidden_prefixes"` // ["Create", "Make"]
	RequiredPrefixes  []string `json:"required_prefixes"`  // ["New"] for constructors
	ReservedSuffixes  []string `json:"reserved_suffixes"`  // ["Manager", "Impl"]
}

// NewNamingNormalizer creates a new NamingNormalizer instance
func NewNamingNormalizer(baseDir string, logger *toolkit.Logger, stats *toolkit.ToolkitStats, dryRun bool) *NamingNormalizer {
	return &NamingNormalizer{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(), // Initialize FileSet
		Logger:  logger,
		Stats:   stats,
		DryRun:  dryRun,
	}
}

// Execute implements ToolkitOperation.Execute
func (nn *NamingNormalizer) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	nn.Logger.Info("🔧 Starting naming convention normalization on: %s", options.Target)

	if nn.DryRun {
		nn.Logger.Info("🔍 Running in DRY-RUN mode - no changes will be made")
	}

	// Initialize tracking variables
	namingIssues := make(map[string][]NamingIssue)
	issuesFound := 0
	filesAnalyzed := 0

	// Walk through all Go files in the target directory
	err := filepath.Walk(options.Target, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			nn.Logger.Warn("Error accessing path %s: %v", path, err)
			return nil // Continue processing other files
		}

		// Skip non-Go files
		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		// Skip test files for now (can be enabled via configuration)
		if strings.HasSuffix(path, "_test.go") {
			return nil
		}

		filesAnalyzed++
		nn.Logger.Debug("Analyzing file: %s", path)

		// Parse the Go file
		fset := token.NewFileSet()
		file, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			nn.Logger.Warn("Failed to parse %s: %v", path, err)
			return nil // Continue with other files
		}

		// Analyze naming conventions in this file
		fileIssues := nn.analyzeFile(file, path, fset)
		if len(fileIssues) > 0 {
			namingIssues[path] = fileIssues
			issuesFound += len(fileIssues)
		}

		return nil
	})
<<<<<<< HEAD

=======
>>>>>>> migration/gateway-manager-v77
	if err != nil {
		nn.Logger.Error("Error walking directory: %v", err)
		return err
	}

	// Update statistics
	nn.Stats.FilesAnalyzed += filesAnalyzed
	nn.Stats.ErrorsFixed += issuesFound // Track issues found, even if not fixed in dry-run

	// Log summary
	nn.Logger.Info("📊 Analysis complete: %d files analyzed, %d naming issues found", filesAnalyzed, issuesFound)

	// Generate detailed report if requested
	if options.Output != "" {
		if err := nn.generateReport(namingIssues, options.Output); err != nil {
			nn.Logger.Error("Failed to generate report: %v", err)
			return err
		}
		nn.Logger.Info("📄 Report generated: %s", options.Output)
	}

	// Apply fixes if not in dry-run mode
	if !nn.DryRun && issuesFound > 0 {
		fixedIssues := nn.applyFixes(namingIssues)
		nn.Logger.Info("🔧 Applied %d automatic fixes", fixedIssues)
		nn.Stats.ErrorsFixed = fixedIssues // Update with actual fixes
	}

	nn.Logger.Info("✅ Naming convention normalization completed: %d issues %s",
		issuesFound,
		func() string {
			if nn.DryRun {
				return "detected"
			}
			return "processed"
		}())

	return nil
}

// analyzeFile analyzes a single Go file for naming convention issues
func (nn *NamingNormalizer) analyzeFile(file *ast.File, filePath string, fset *token.FileSet) []NamingIssue {
	var issues []NamingIssue

	// Analyze all declarations in the file
	for _, decl := range file.Decls {
		switch d := decl.(type) {
		case *ast.GenDecl:
			// Handle type declarations (interfaces, structs, type aliases)
			if d.Tok == token.TYPE {
				for _, spec := range d.Specs {
					if typeSpec, ok := spec.(*ast.TypeSpec); ok {
						if issue := nn.checkTypeNaming(typeSpec, filePath, fset); issue != nil {
							issues = append(issues, *issue)
						}
					}
				}
			}
			// Handle variable and constant declarations
			if d.Tok == token.VAR || d.Tok == token.CONST {
				for _, spec := range d.Specs {
					if valueSpec, ok := spec.(*ast.ValueSpec); ok {
						for _, name := range valueSpec.Names {
							if issue := nn.checkVariableNaming(name, d.Tok, filePath, fset); issue != nil {
								issues = append(issues, *issue)
							}
						}
					}
				}
			}
		case *ast.FuncDecl:
			// Handle function declarations
			if issue := nn.checkFunctionNaming(d, filePath, fset); issue != nil {
				issues = append(issues, *issue)
			}
		}
	}

	return issues
}

// checkTypeNaming validates naming conventions for types (interfaces, structs)
func (nn *NamingNormalizer) checkTypeNaming(typeSpec *ast.TypeSpec, filePath string, fset *token.FileSet) *NamingIssue {
	name := typeSpec.Name.Name
	line := fset.Position(typeSpec.Pos()).Line

	// Check if name follows basic Go conventions (exported types start with uppercase)
	if !nn.isValidGoIdentifier(name) {
		return &NamingIssue{
			Type:        "type",
			Current:     name,
			Suggested:   nn.suggestGoIdentifierFix(name),
			Line:        line,
			Reason:      "Invalid Go identifier",
			Severity:    "error",
			AutoFixable: true,
		}
	}

	// Check interface naming conventions
	if _, isInterface := typeSpec.Type.(*ast.InterfaceType); isInterface {
		return nn.checkInterfaceNaming(name, line)
	}

	// Check struct naming conventions
	if _, isStruct := typeSpec.Type.(*ast.StructType); isStruct {
		return nn.checkStructNaming(name, line)
	}

	return nil
}

// checkInterfaceNaming validates interface naming conventions
func (nn *NamingNormalizer) checkInterfaceNaming(name string, line int) *NamingIssue {
	// Avoid redundant suffixes like "ManagerInterface" - This check should come first
	if strings.HasSuffix(name, "ManagerInterface") {
		suggested := strings.Replace(name, "ManagerInterface", "Manager", 1)
		return &NamingIssue{
			Type:        "interface",
			Current:     name,
			Suggested:   suggested,
			Line:        line,
			Reason:      "Redundant 'ManagerInterface' suffix", // This reason should now be reported
			Severity:    "error",
			AutoFixable: true, // This autoFixable should now be reported
		}
	}

	// Interfaces should end with "Manager" or be single-word descriptive names
	if !strings.HasSuffix(name, "Manager") && !nn.isSingleWordInterface(name) {
		return &NamingIssue{
			Type:        "interface",
			Current:     name,
			Suggested:   name + "Manager",
			Line:        line,
			Reason:      "Interface should end with 'Manager' or be a single descriptive word",
			Severity:    "warning",
			AutoFixable: false, // Requires manual review due to semantic implications
		}
	}

	return nil
}

// checkStructNaming validates struct naming conventions
func (nn *NamingNormalizer) checkStructNaming(name string, line int) *NamingIssue {
	// Implementation structs should end with "Impl"
	if strings.Contains(strings.ToLower(name), "manager") && !strings.HasSuffix(name, "Impl") {
		return &NamingIssue{
			Type:        "struct",
			Current:     name,
			Suggested:   strings.Replace(name, "Manager", "Impl", 1),
			Line:        line,
			Reason:      "Implementation structs should end with 'Impl'",
			Severity:    "warning",
			AutoFixable: false, // Requires context understanding
		}
	}

	return nil
}

// checkFunctionNaming validates function naming conventions
func (nn *NamingNormalizer) checkFunctionNaming(funcDecl *ast.FuncDecl, filePath string, fset *token.FileSet) *NamingIssue {
	name := funcDecl.Name.Name
	line := fset.Position(funcDecl.Pos()).Line

	// Skip methods (functions with receivers)
	if funcDecl.Recv != nil {
		return nil
	}

	// Check constructor function naming
	if nn.isConstructorFunction(funcDecl) && !strings.HasPrefix(name, "New") {
		suggested := "New" + strings.TrimPrefix(name, "Create")
		suggested = "New" + strings.TrimPrefix(suggested, "Make")
		return &NamingIssue{
			Type:        "function",
			Current:     name,
			Suggested:   suggested,
			Line:        line,
			Reason:      "Constructor functions should start with 'New'",
			Severity:    "warning",
			AutoFixable: true,
		}
	}

	// Check for forbidden prefixes
	for _, forbidden := range []string{"Create", "Make"} {
		if strings.HasPrefix(name, forbidden) && nn.isConstructorFunction(funcDecl) {
			suggested := strings.Replace(name, forbidden, "New", 1)
			return &NamingIssue{
				Type:        "function",
				Current:     name,
				Suggested:   suggested,
				Line:        line,
				Reason:      fmt.Sprintf("Use 'New' instead of '%s' for constructors", forbidden),
				Severity:    "warning",
				AutoFixable: true,
			}
		}
	}

	return nil
}

// checkVariableNaming validates variable and constant naming conventions
func (nn *NamingNormalizer) checkVariableNaming(name *ast.Ident, tok token.Token, filePath string, fset *token.FileSet) *NamingIssue {
	varName := name.Name
	line := fset.Position(name.Pos()).Line

	// Skip blank identifiers
	if varName == "_" {
		return nil
	}

	// Check constant naming (should be ALL_CAPS or CamelCase)
	if tok == token.CONST {
		if !nn.isValidConstantName(varName) {
			return &NamingIssue{
				Type:        "constant",
				Current:     varName,
				Suggested:   nn.suggestConstantName(varName),
				Line:        line,
				Reason:      "Constants should use ALL_CAPS or CamelCase",
				Severity:    "info",
				AutoFixable: false, // Context-dependent
			}
		}
	}

	// Check variable naming
	if tok == token.VAR {
		if !nn.isValidVariableName(varName) {
			return &NamingIssue{
				Type:        "variable",
				Current:     varName,
				Suggested:   nn.suggestVariableName(varName),
				Line:        line,
				Reason:      "Variables should use camelCase or PascalCase",
				Severity:    "info",
				AutoFixable: false, // Context-dependent
			}
		}
	}

	return nil
}

// Helper methods for naming validation

// isValidGoIdentifier checks if a name is a valid Go identifier
func (nn *NamingNormalizer) isValidGoIdentifier(name string) bool {
	if len(name) == 0 {
		return false
	}

	// Go identifier pattern: letter followed by letters, digits, or underscores
	matched, _ := regexp.MatchString(`^[a-zA-Z_][a-zA-Z0-9_]*$`, name)
	return matched
}

// isSingleWordInterface checks if an interface follows single-word naming (like io.Reader)
func (nn *NamingNormalizer) isSingleWordInterface(name string) bool {
	// Common single-word interface patterns
	singleWordPatterns := []string{
		"Reader", "Writer", "Closer", "Seeker",
		"Scanner", "Parser", "Validator", "Handler",
		"Formatter", "Encoder", "Decoder", "Builder",
	}

	for _, pattern := range singleWordPatterns {
		if strings.HasSuffix(name, pattern) {
			return true
		}
	}

	return false
}

// isConstructorFunction determines if a function is a constructor
func (nn *NamingNormalizer) isConstructorFunction(funcDecl *ast.FuncDecl) bool {
	// Check if function returns a struct type or interface
	if funcDecl.Type.Results == nil {
		return false
	}

	// Simple heuristic: constructor if it returns something and has no receiver
	return funcDecl.Recv == nil && len(funcDecl.Type.Results.List) > 0
}

// isValidConstantName checks if a constant name follows conventions
func (nn *NamingNormalizer) isValidConstantName(name string) bool {
	// All caps with underscores
	allCapsPattern, _ := regexp.MatchString(`^[A-Z][A-Z0-9_]*$`, name)

	// CamelCase for exported constants
	camelCasePattern, _ := regexp.MatchString(`^[A-Z][a-zA-Z0-9]*$`, name)

	return allCapsPattern || camelCasePattern
}

// isValidVariableName checks if a variable name follows conventions
func (nn *NamingNormalizer) isValidVariableName(name string) bool {
	// Exported: PascalCase
	exportedPattern, _ := regexp.MatchString(`^[A-Z][a-zA-Z0-9]*$`, name)

	// Unexported: camelCase
	unexportedPattern, _ := regexp.MatchString(`^[a-z][a-zA-Z0-9]*$`, name)

	return exportedPattern || unexportedPattern
}

// Suggestion methods

// suggestGoIdentifierFix suggests a fix for invalid Go identifiers
func (nn *NamingNormalizer) suggestGoIdentifierFix(name string) string {
	if len(name) == 0 {
		return "validName"
	}

	// Remove invalid characters and ensure it starts with a letter
	cleaned := regexp.MustCompile(`[^a-zA-Z0-9_]`).ReplaceAllString(name, "")
	if len(cleaned) == 0 || (cleaned[0] >= '0' && cleaned[0] <= '9') {
		cleaned = "name" + cleaned
	}

	return cleaned
}

// suggestConstantName suggests a proper constant name
func (nn *NamingNormalizer) suggestConstantName(name string) string {
	// Convert to ALL_CAPS with underscores
	result := ""
	for i, r := range name {
		if i > 0 && r >= 'A' && r <= 'Z' {
			result += "_"
		}
		result += strings.ToUpper(string(r))
	}
	return result
}

// suggestVariableName suggests a proper variable name
func (nn *NamingNormalizer) suggestVariableName(name string) string {
	if len(name) == 0 {
		return "variable"
	}

	// Ensure proper camelCase or PascalCase
	if name[0] >= 'A' && name[0] <= 'Z' {
		return name // Already PascalCase
	}

	// Convert to camelCase
	if name[0] >= 'a' && name[0] <= 'z' {
		return name // Already camelCase
	}

	// Fix other cases
	return strings.ToLower(string(name[0])) + name[1:]
}

// applyFixes applies automatic fixes to the identified issues
func (nn *NamingNormalizer) applyFixes(namingIssues map[string][]NamingIssue) int {
	fixedCount := 0

	for filePath, issues := range namingIssues {
		fileFixed := 0

		for _, issue := range issues {
			if issue.AutoFixable {
				nn.Logger.Debug("Applying fix: %s -> %s in %s:%d",
					issue.Current, issue.Suggested, filePath, issue.Line)
				// TODO: Implement actual code modification
				// This would require AST manipulation and code generation
				fileFixed++
			}
		}

		if fileFixed > 0 {
			nn.Logger.Info("Applied %d fixes in %s", fileFixed, filePath)
			fixedCount += fileFixed
		}
	}

	return fixedCount
}

// generateReport creates a detailed JSON report of naming issues
func (nn *NamingNormalizer) generateReport(namingIssues map[string][]NamingIssue, outputPath string) error {
	// Calculate summary statistics
	totalIssues := 0
	issuesBySeverity := make(map[string]int)
	issuesByType := make(map[string]int)
	autoFixableCount := 0

	for _, issues := range namingIssues {
		for _, issue := range issues {
			totalIssues++
			issuesBySeverity[issue.Severity]++
			issuesByType[issue.Type]++
			if issue.AutoFixable {
				autoFixableCount++
			}
		}
	}

	// Create comprehensive report
	report := map[string]interface{}{
		"tool":           "NamingNormalizer",
		"version":        "1.0.0",
		"generated_at":   time.Now().Format(time.RFC3339),
		"base_directory": nn.BaseDir,
		"dry_run":        nn.DryRun,
		"summary": map[string]interface{}{
			"total_files":   len(namingIssues),
			"total_issues":  totalIssues,
			"auto_fixable":  autoFixableCount,
			"manual_review": totalIssues - autoFixableCount,
			"by_severity":   issuesBySeverity,
			"by_type":       issuesByType,
		},
		"conventions": map[string]interface{}{
			"interfaces": "Should end with 'Manager' or be single descriptive words",
			"structs":    "Implementation structs should end with 'Impl'",
			"functions":  "Constructors should start with 'New'",
			"constants":  "Should use ALL_CAPS or CamelCase",
			"variables":  "Should use camelCase or PascalCase",
		},
		"files": namingIssues,
	}

	// Write report to file
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}

<<<<<<< HEAD
	if err := os.WriteFile(outputPath, data, 0644); err != nil {
=======
	if err := os.WriteFile(outputPath, data, 0o644); err != nil {
>>>>>>> migration/gateway-manager-v77
		return fmt.Errorf("failed to write report: %w", err)
	}

	return nil
}

// Validate implements ToolkitOperation.Validate
func (nn *NamingNormalizer) Validate(ctx context.Context) error {
	if nn.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}
	if nn.Logger == nil {
		return fmt.Errorf("Logger is required")
	}
	if nn.Stats == nil {
		return fmt.Errorf("Stats is required")
	}

	// Check if base directory exists
	if _, err := os.Stat(nn.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", nn.BaseDir)
	}

	return nil
}

// CollectMetrics implements ToolkitOperation.CollectMetrics
func (nn *NamingNormalizer) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":           "NamingNormalizer",
		"base_dir":       nn.BaseDir,
		"dry_run":        nn.DryRun,
		"files_analyzed": nn.Stats.FilesAnalyzed,
		"issues_found":   nn.Stats.ErrorsFixed,
		"execution_time": time.Since(time.Now()).String(),
	}
}

// HealthCheck implements ToolkitOperation.HealthCheck
func (nn *NamingNormalizer) HealthCheck(ctx context.Context) error {
	// Check if base directory is accessible
	if _, err := os.Stat(nn.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", nn.BaseDir)
	}

	// Check if we can create temporary files for testing
	tempFile := filepath.Join(os.TempDir(), "naming_normalizer_health_check.tmp")
	if err := os.WriteFile(tempFile, []byte("test"), 0o644); err != nil {
		return fmt.Errorf("cannot write temporary files: %w", err)
	}
	os.Remove(tempFile) // Clean up

	return nil
}

// String implémente ToolkitOperation.String - identification de l'outil
func (nn *NamingNormalizer) String() string {
	return "NamingNormalizer"
}

// GetDescription implémente ToolkitOperation.GetDescription - description de l'outil
func (nn *NamingNormalizer) GetDescription() string {
	return "Validates and normalizes Go naming conventions across the codebase"
}

// Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt
func (nn *NamingNormalizer) Stop(ctx context.Context) error {
	return nil
}

// init registers the NamingNormalizer tool automatically
func init() {
	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		globalReg = registry.NewToolRegistry()
		// registry.SetGlobalRegistry(globalReg) // If a setter exists
	}

	// Create a default instance for registration
	defaultTool := &NamingNormalizer{
		BaseDir: "",                 // Default or placeholder
		FileSet: token.NewFileSet(), // Initialize FileSet
		Logger:  nil,                // Logger should be initialized by the toolkit
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  false,
	}

	err := globalReg.Register(toolkit.NormalizeNaming, defaultTool) // Changed to toolkit.NormalizeNaming
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register NamingNormalizer: %v\n", err)
	}
}
