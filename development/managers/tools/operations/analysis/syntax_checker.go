// Manager Toolkit - Syntax Checker
// Version: 3.0.0
// Detects and corrects syntax errors in Go source files

package analysis

import (
	"context"
	"encoding/json"
	"fmt"
	"go/format"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"time"

	"email_sender/development/managers/tools/core/registry"
	"email_sender/development/managers/tools/core/toolkit"
)

// SyntaxChecker implémente l'interface toolkit.ToolkitOperation pour la correction de syntaxe
type SyntaxChecker struct {
	BaseDir string
	FileSet *token.FileSet
	Logger  *toolkit.Logger
	Stats   *toolkit.ToolkitStats
	DryRun  bool
}

// SyntaxError représente une erreur de syntaxe détectée
type SyntaxError struct {
	File           string `json:"file"`
	Line           int    `json:"line"`
	Column         int    `json:"column"`
	Position       int    `json:"position"`
	Message        string `json:"message"`
	ErrorType      string `json:"error_type"`
	Severity       string `json:"severity"`
	OriginalCode   string `json:"original_code,omitempty"`
	SuggestedFix   string `json:"suggested_fix,omitempty"`
	FixApplied     bool   `json:"fix_applied"`
	FixDescription string `json:"fix_description,omitempty"`
}

// SyntaxReport représente le rapport de vérification syntaxique
type SyntaxReport struct {
	Tool          string        `json:"tool"`
	Version       string        `json:"version"`
	Timestamp     time.Time     `json:"timestamp"`
	TotalFiles    int           `json:"total_files"`
	FilesAnalyzed int           `json:"files_analyzed"`
	ErrorsFound   int           `json:"errors_found"`
	ErrorsFixed   int           `json:"errors_fixed"`
	DryRunMode    bool          `json:"dry_run_mode"`
	Errors        []SyntaxError `json:"errors"`
	Summary       SyntaxSummary `json:"summary"`
}

// SyntaxSummary fournit un résumé des erreurs par type
type SyntaxSummary struct {
	ParsingErrors      int `json:"parsing_errors"`
	FormattingErrors   int `json:"formatting_errors"`
	UnterminatedErrors int `json:"unterminated_errors"`
	MiscErrors         int `json:"misc_errors"`
}

// NewSyntaxChecker creates a new SyntaxChecker instance
func NewSyntaxChecker(baseDir string, logger *toolkit.Logger, stats *toolkit.ToolkitStats, dryRun bool) *SyntaxChecker {
	return &SyntaxChecker{
		BaseDir: baseDir,
		FileSet: token.NewFileSet(),
		Logger:  logger,
		Stats:   stats,
		DryRun:  dryRun,
	}
}

// Execute implémente ToolkitOperation.Execute
func (sc *SyntaxChecker) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	if sc.Logger == nil {
		return fmt.Errorf("logger is required")
	}

	sc.Logger.Info("🔧 Starting syntax checking on: %s", options.Target)

	if sc.FileSet == nil {
		sc.FileSet = token.NewFileSet()
	}

	report := &SyntaxReport{
		Tool:       "SyntaxChecker",
		Version:    "3.0.0",
		Timestamp:  time.Now(),
		DryRunMode: sc.DryRun,
		Errors:     make([]SyntaxError, 0),
		Summary:    SyntaxSummary{},
	}

	syntaxErrors := 0
	fixedErrors := 0
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

		report.TotalFiles++

		// Read file content
		src, err := os.ReadFile(path)
		if err != nil {
			sc.Logger.Error("Failed to read file %s: %v", path, err)
			return nil // Continue with other files
		}

		filesAnalyzed++

		// Parse the file to detect syntax errors
		file, parseErr := parser.ParseFile(sc.FileSet, path, src, parser.ParseComments)
		if parseErr != nil {
			syntaxErr := sc.analyzeSyntaxError(path, src, parseErr)
			report.Errors = append(report.Errors, syntaxErr)
			syntaxErrors++

			sc.Logger.Warn("Syntax error in %s: %v", path, parseErr)

			// Attempt to fix if not in dry-run mode
			if !sc.DryRun && options.Force {
				if fixed, fixDesc := sc.attemptFix(path, src, parseErr); fixed {
					fixedErrors++
					syntaxErr.FixApplied = true
					syntaxErr.FixDescription = fixDesc
					sc.Logger.Info("✅ Fixed syntax error in %s: %s", path, fixDesc)
				}
			}
		} else if file != nil {
			// Check for formatting issues
			if formatted, err := format.Source(src); err == nil {
				if string(formatted) != string(src) {
					formatErr := SyntaxError{
						File:         path,
						ErrorType:    "formatting",
						Severity:     "warning",
						Message:      "File needs formatting",
						OriginalCode: string(src),
						SuggestedFix: string(formatted),
					}

					if !sc.DryRun && options.Force {
						if err := os.WriteFile(path, formatted, info.Mode()); err == nil {
							formatErr.FixApplied = true
							formatErr.FixDescription = "Applied go fmt formatting"
							fixedErrors++
							sc.Logger.Info("✅ Formatted file: %s", path)
						}
					}

					report.Errors = append(report.Errors, formatErr)
					report.Summary.FormattingErrors++
				}
			}
		}

		return nil
	})
	if err != nil {
		sc.Logger.Error("Error walking directory: %v", err)
		return err
	}

	// Update report summary
	report.FilesAnalyzed = filesAnalyzed
	report.ErrorsFound = syntaxErrors + report.Summary.FormattingErrors
	report.ErrorsFixed = fixedErrors
	sc.categorizeErrors(report)

	// Update toolkit stats
	if sc.Stats != nil {
		sc.Stats.FilesAnalyzed += filesAnalyzed
		sc.Stats.ErrorsFixed += fixedErrors
	}

	// Generate report if output specified
	if options.Output != "" {
		if err := sc.generateReport(report, options.Output); err != nil {
			sc.Logger.Error("Failed to generate report: %v", err)
			return err
		}
		sc.Logger.Info("📄 Report generated: %s", options.Output)
	}

	sc.Logger.Info("✅ Syntax check completed: %d files analyzed, %d errors found, %d fixed",
		filesAnalyzed, report.ErrorsFound, fixedErrors)

	return nil
}

// Validate implémente ToolkitOperation.Validate
func (sc *SyntaxChecker) Validate(ctx context.Context) error {
	if sc.BaseDir == "" {
		return fmt.Errorf("BaseDir is required")
	}
	if sc.Logger == nil {
		return fmt.Errorf("Logger is required")
	}
	if _, err := os.Stat(sc.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", sc.BaseDir)
	}
	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (sc *SyntaxChecker) CollectMetrics() map[string]interface{} {
	metrics := map[string]interface{}{
		"tool":           "SyntaxChecker",
		"version":        "3.0.0",
		"dry_run_mode":   sc.DryRun,
		"base_directory": sc.BaseDir,
	}

	if sc.Stats != nil {
		metrics["files_analyzed"] = sc.Stats.FilesAnalyzed
		metrics["errors_fixed"] = sc.Stats.ErrorsFixed
	}

	return metrics
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (sc *SyntaxChecker) HealthCheck(ctx context.Context) error {
	if sc.FileSet == nil {
		return fmt.Errorf("FileSet not initialized")
	}

	// Check access to base directory
	if _, err := os.Stat(sc.BaseDir); os.IsNotExist(err) {
		return fmt.Errorf("base directory does not exist: %s", sc.BaseDir)
	}

	// Test parser functionality
	testCode := "package main\n\nfunc main() {}\n"
	_, err := parser.ParseFile(sc.FileSet, "test.go", testCode, 0)
	if err != nil {
		return fmt.Errorf("parser functionality test failed: %v", err)
	}

	return nil
}

// analyzeSyntaxError analyse une erreur de syntaxe et retourne une structure SyntaxError
func (sc *SyntaxChecker) analyzeSyntaxError(file string, src []byte, parseErr error) SyntaxError {
	syntaxErr := SyntaxError{
		File:      file,
		Message:   parseErr.Error(),
		ErrorType: "parsing",
		Severity:  "error",
	}

	// Extract position information if available
	if pos := parseErr.Error(); strings.Contains(pos, ":") {
		parts := strings.Split(pos, ":")
		if len(parts) >= 3 {
			// Try to parse line and column numbers
			var line, col int
			if _, err := fmt.Sscanf(parts[1], "%d", &line); err == nil {
				syntaxErr.Line = line
			}
			if _, err := fmt.Sscanf(parts[2], "%d", &col); err == nil {
				syntaxErr.Column = col
			}
		}
	}

	// Categorize error type
	errorMsg := strings.ToLower(parseErr.Error())
	switch {
	case strings.Contains(errorMsg, "expected"):
		syntaxErr.ErrorType = "expected_token"
	case strings.Contains(errorMsg, "unexpected"):
		syntaxErr.ErrorType = "unexpected_token"
	case strings.Contains(errorMsg, "unterminated"):
		syntaxErr.ErrorType = "unterminated"
	default:
		syntaxErr.ErrorType = "parsing"
	}

	return syntaxErr
}

// attemptFix tente de corriger automatiquement les erreurs syntaxiques courantes
func (sc *SyntaxChecker) attemptFix(file string, src []byte, parseErr error) (bool, string) {
	content := string(src)
	originalContent := content
	fixed := false
	description := ""

	// Fix common syntax errors
	if strings.Contains(parseErr.Error(), "expected ';'") {
		// Try to add missing semicolons (though rare in Go)
		content = sc.fixMissingSemicolons(content)
		if content != originalContent {
			fixed = true
			description = "Added missing semicolons"
		}
	}

	if strings.Contains(parseErr.Error(), "unterminated string") {
		content = sc.fixUnterminatedStrings(content)
		if content != originalContent {
			fixed = true
			description = "Fixed unterminated strings"
		}
	}

	if strings.Contains(parseErr.Error(), "expected '}'") {
		content = sc.fixMissingBraces(content)
		if content != originalContent {
			fixed = true
			description = "Added missing closing braces"
		}
	}

	// Apply common formatting fixes
	if !fixed {
		if formatted, err := format.Source([]byte(content)); err == nil {
			content = string(formatted)
			if content != originalContent {
				fixed = true
				description = "Applied automatic formatting"
			}
		}
	}

	// Write the fixed content if changes were made
	if fixed && !sc.DryRun {
		if err := os.WriteFile(file, []byte(content), 0o644); err != nil {
			sc.Logger.Error("Failed to write fixed file %s: %v", file, err)
			return false, ""
		}
	}

	return fixed, description
}

// fixMissingSemicolons ajoute des points-virgules manquants
func (sc *SyntaxChecker) fixMissingSemicolons(content string) string {
	// This is rarely needed in Go, but handle edge cases
	lines := strings.Split(content, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "import") && !strings.HasSuffix(trimmed, ")") && !strings.HasSuffix(trimmed, ";") {
			lines[i] = line + ";"
		}
	}
	return strings.Join(lines, "\n")
}

// fixUnterminatedStrings corrige les chaînes non terminées
func (sc *SyntaxChecker) fixUnterminatedStrings(content string) string {
	// Simple heuristic: add closing quotes to lines ending with unmatched quotes
	lines := strings.Split(content, "\n")
	for i, line := range lines {
		quotes := strings.Count(line, "\"")
		backquotes := strings.Count(line, "`")

		if quotes%2 == 1 && !strings.Contains(line, "//") {
			lines[i] = line + "\""
		}
		if backquotes%2 == 1 && !strings.Contains(line, "//") {
			lines[i] = line + "`"
		}
	}
	return strings.Join(lines, "\n")
}

// fixMissingBraces ajoute des accolades manquantes
func (sc *SyntaxChecker) fixMissingBraces(content string) string {
	openBraces := strings.Count(content, "{")
	closeBraces := strings.Count(content, "}")

	if openBraces > closeBraces {
		missing := openBraces - closeBraces
		for i := 0; i < missing; i++ {
			content += "\n}"
		}
	}

	return content
}

// categorizeErrors catégorise les erreurs dans le résumé
func (sc *SyntaxChecker) categorizeErrors(report *SyntaxReport) {
	for _, err := range report.Errors {
		switch err.ErrorType {
		case "parsing", "expected_token", "unexpected_token":
			report.Summary.ParsingErrors++
		case "formatting":
			report.Summary.FormattingErrors++
		case "unterminated":
			report.Summary.UnterminatedErrors++
		default:
			report.Summary.MiscErrors++
		}
	}
}

// generateReport génère un rapport JSON des erreurs de syntaxe
func (sc *SyntaxChecker) generateReport(report *SyntaxReport, outputPath string) error {
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %v", err)
	}

	if err := os.WriteFile(outputPath, data, 0o644); err != nil {
		return fmt.Errorf("failed to write report file: %v", err)
	}

	return nil
}

// toolkit.ToolkitOperation interface implementation (Phase 2.1 - New methods)

// String returns the tool identifier
func (sc *SyntaxChecker) String() string {
	return "SyntaxChecker"
}

// GetDescription returns the tool description
func (sc *SyntaxChecker) GetDescription() string {
	return "Detects and corrects syntax errors in Go source files"
}

// Stop handles graceful shutdown
func (sc *SyntaxChecker) Stop(ctx context.Context) error {
	// Syntax checker doesn't have background processes to stop
	if sc.Logger != nil {
		sc.Logger.Info("SyntaxChecker stopping gracefully")
	}
	return nil
}

// init registers the SyntaxChecker tool automatically
func init() {
	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		globalReg = registry.NewToolRegistry()
		// registry.SetGlobalRegistry(globalReg) // If a setter exists
	}

	// Create a default instance for registration
	defaultTool := &SyntaxChecker{
		BaseDir: "",                 // Default or placeholder
		FileSet: token.NewFileSet(), // Initialize FileSet
		Logger:  nil,                // Logger should be initialized by the toolkit
		Stats:   &toolkit.ToolkitStats{},
		DryRun:  false,
	}

	err := globalReg.Register(toolkit.SyntaxCheck, defaultTool) // Changed to toolkit.SyntaxCheck
	if err != nil {
		// Log error but don't panic during package initialization
		fmt.Printf("Warning: Failed to register SyntaxChecker: %v\n", err)
	}
}
