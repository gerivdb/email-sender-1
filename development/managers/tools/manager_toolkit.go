// Manager Toolkit - Unified Professional Development Tool
// Version: 2.0.0
// Provides comprehensive analysis, migration, and maintenance utilities
// for the Email Sender Manager Ecosystem

package tools

import (
	"context"
	"flag"
	"fmt"
	"go/token"
	"log"
	"os"
	"path/filepath"
	"time"
)

// Configuration constants
const (
	ToolVersion    = "2.0.0"
	DefaultBaseDir = "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers"
	ConfigFile     = "toolkit.config.json"
	LogFile        = "toolkit.log"
)

// Main toolkit structure
type ManagerToolkit struct {
	Config    *ToolkitConfig
	Logger    *Logger
	FileSet   *token.FileSet
	BaseDir   string
	StartTime time.Time
	Stats     *ToolkitStats
}

// Configuration structure
type ToolkitConfig struct {
	BaseDir         string   `json:"base_dir"`
	BaseDirectory   string   `json:"base_directory"`
	InterfacesDir   string   `json:"interfaces_dir"`
	ToolsDir        string   `json:"tools_dir"`
	ExcludePatterns []string `json:"exclude_patterns"`
	IncludePatterns []string `json:"include_patterns"`
	BackupEnabled   bool     `json:"backup_enabled"`
	VerboseLogging  bool     `json:"verbose_logging"`
	MaxFileSize     int64    `json:"max_file_size"`
	ModuleName      string   `json:"module_name"`
	EnableDryRun    bool     `json:"enable_dry_run"`
}

// Statistics tracking
type ToolkitStats struct {
	FilesAnalyzed      int           `json:"files_analyzed"`
	FilesModified      int           `json:"files_modified"`
	FilesCreated       int           `json:"files_created"`
	ErrorsFixed        int           `json:"errors_fixed"`
	InterfacesMoved    int           `json:"interfaces_moved"`
	DuplicatesRemoved  int           `json:"duplicates_removed"`
	ImportsFixed       int           `json:"imports_fixed"`
	OperationsExecuted int           `json:"operations_executed"`
	FilesProcessed     int           `json:"files_processed"`
	ExecutionTime      time.Duration `json:"execution_time"`
	// Additional fields for test compatibility
	TotalFiles      int `json:"total_files"`
	InterfaceFiles  int `json:"interface_files"`
	TotalInterfaces int `json:"total_interfaces"`
}

// Logger with levels
type Logger struct {
	file    *os.File
	verbose bool
}

// Command line operations
type Operation string

const (
	OpAnalyze     Operation = "analyze"
	OpMigrate     Operation = "migrate"
	OpFixImports  Operation = "fix-imports"
	OpRemoveDups  Operation = "remove-duplicates"
	OpSyntaxFix   Operation = "fix-syntax"
	OpHealthCheck Operation = "health-check"
	OpInitConfig  Operation = "init-config"
	OpFullSuite   Operation = "full-suite"
	// Phase 1.1.1 & 1.1.2 - New Analysis Operations
	OpValidateStructs  Operation = "validate-structs"
	OpResolveImports   Operation = "resolve-imports"
	OpAnalyzeDeps      Operation = "analyze-dependencies"
	OpDetectDuplicates Operation = "detect-duplicates"
)

func main() {
	var (
		operation  = flag.String("op", "", "Operation to perform: analyze|migrate|fix-imports|remove-duplicates|fix-syntax|health-check|init-config|full-suite|validate-structs|resolve-imports|analyze-dependencies|detect-duplicates")
		baseDir    = flag.String("dir", DefaultBaseDir, "Base directory to work with")
		configPath = flag.String("config", "", "Path to configuration file")
		dryRun     = flag.Bool("dry-run", false, "Perform dry run without making changes")
		verbose    = flag.Bool("verbose", false, "Enable verbose logging")
		target     = flag.String("target", "", "Specific file or directory target")
		output     = flag.String("output", "", "Output file for reports")
		force      = flag.Bool("force", false, "Force operations without confirmation")
		help       = flag.Bool("help", false, "Show help information")
	)
	flag.Parse()

	if *help || *operation == "" {
		showHelp()
		return
	}

	// Initialize toolkit
	toolkit, err := NewManagerToolkit(*baseDir, *configPath, *verbose)
	if err != nil {
		log.Fatalf("Failed to initialize toolkit: %v", err)
	}
	defer toolkit.Close()

	toolkit.Config.EnableDryRun = *dryRun

	// Execute operation
	ctx := context.Background()
	if err := toolkit.ExecuteOperation(ctx, Operation(*operation), &OperationOptions{
		Target: *target,
		Output: *output,
		Force:  *force,
	}); err != nil {
		toolkit.Logger.Error("Operation failed: %v", err)
		os.Exit(1)
	}

	toolkit.PrintFinalStats()
}

// Logger methods
func (l *Logger) Info(format string, args ...interface{}) {
	message := fmt.Sprintf(format, args...)
	l.log("INFO", message)
}

func (l *Logger) Warn(format string, args ...interface{}) {
	message := fmt.Sprintf(format, args...)
	l.log("WARN", message)
}

func (l *Logger) Error(format string, args ...interface{}) {
	message := fmt.Sprintf(format, args...)
	l.log("ERROR", message)
}

func (l *Logger) Debug(format string, args ...interface{}) {
	if l.verbose {
		message := fmt.Sprintf(format, args...)
		l.log("DEBUG", message)
	}
}

func (l *Logger) log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logMessage := fmt.Sprintf("[%s] %s: %s\n", timestamp, level, message)

	// Print to console
	fmt.Print(logMessage)

	// Write to file if available
	if l.file != nil {
		l.file.WriteString(logMessage)
	}
}

// NewLogger creates a new logger instance
func NewLogger(verbose bool) (*Logger, error) {
	logger := &Logger{
		verbose: verbose,
	}

	// Create log file
	logFile := filepath.Join(os.TempDir(), fmt.Sprintf("manager-toolkit-%d.log", time.Now().Unix()))
	file, err := os.Create(logFile)
	if err != nil {
		return logger, nil // Return logger without file if creation fails
	}

	logger.file = file
	return logger, nil
}

// Close closes the logger file
func (l *Logger) Close() error {
	if l.file != nil {
		return l.file.Close()
	}
	return nil
}

// showHelp displays usage information
func showHelp() {
	fmt.Printf(`Manager Toolkit v%s - Professional Development Tools

Usage:
  manager-toolkit -op=<operation> [options]

Operations:
  analyze         - Comprehensive interface analysis
  migrate         - Professional interface migration  
  fix-imports     - Fix import statements across all files
  remove-duplicates - Remove duplicate code and methods
  fix-syntax      - Fix syntax errors in Go files
  health-check    - Comprehensive codebase health check
  init-config     - Initialize configuration file
  full-suite      - Run complete maintenance suite

Options:
  -dir string        Base directory to work with (default: current)
  -config string     Path to configuration file
  -dry-run          Perform dry run without making changes
  -verbose          Enable verbose logging
  -target string    Specific file or directory target
  -output string    Output file for reports
  -force            Force operation without confirmation

Examples:
  manager-toolkit -op=analyze -verbose
  manager-toolkit -op=fix-imports -dir=/path/to/project -dry-run
  manager-toolkit -op=full-suite -config=./toolkit.json

`, ToolVersion)
}

// PrintFinalStats prints a summary of operations performed
func (mt *ManagerToolkit) PrintFinalStats() {
	fmt.Printf("\n--- Manager Toolkit v%s Results ---\n", ToolVersion)
	fmt.Printf("Files processed:     %d\n", mt.Stats.FilesProcessed)
	fmt.Printf("Files modified:      %d\n", mt.Stats.FilesModified)
	fmt.Printf("Files created:       %d\n", mt.Stats.FilesCreated)
	fmt.Printf("Operations executed: %d\n", mt.Stats.OperationsExecuted)
	fmt.Printf("Execution time:      %v\n", mt.Stats.ExecutionTime)
}

// ExecuteOperation executes the specified operation
func (mt *ManagerToolkit) ExecuteOperation(ctx context.Context, op Operation, opts *OperationOptions) error {
	mt.Logger.Info("Starting operation: %s", string(op))
	startTime := time.Now()

	var err error
	switch op {
	case OpAnalyze:
		err = mt.RunAnalysis(ctx, opts)
	case OpMigrate:
		err = mt.RunMigration(ctx, opts)
	case OpFixImports:
		err = mt.FixImports(ctx, opts)
	case OpRemoveDups:
		err = mt.RemoveDuplicates(ctx, opts)
	case OpSyntaxFix:
		err = mt.FixSyntaxErrors(ctx, opts)
	case OpHealthCheck:
		err = mt.RunHealthCheck(ctx, opts)
	case OpInitConfig:
		err = mt.InitializeConfig(ctx, opts)
	case OpFullSuite:
		err = mt.RunFullSuite(ctx, opts)
	// Phase 1.1.1 & 1.1.2 - New Analysis Operations
	case OpValidateStructs:
		err = mt.RunStructValidation(ctx, opts)
	case OpResolveImports:
		err = mt.RunImportConflictResolution(ctx, opts)
	case OpAnalyzeDeps:
		err = mt.RunDependencyAnalysis(ctx, opts)
	case OpDetectDuplicates:
		err = mt.RunDuplicateTypeDetection(ctx, opts)
	default:
		return fmt.Errorf("unknown operation: %s", string(op))
	}

	duration := time.Since(startTime)
	mt.Stats.ExecutionTime = duration

	if err != nil {
		mt.Logger.Error("Operation %s failed after %v: %v", string(op), duration, err)
		return err
	}

	mt.Logger.Info("Operation %s completed successfully in %v", string(op), duration)
	return nil
}

// RunStructValidation validates struct declarations in the codebase
func (mt *ManagerToolkit) RunStructValidation(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting struct validation on: %s", opts.Target)

	// Create a new struct validator
	validator, err := NewStructValidator(mt.BaseDir, mt.Logger, mt.Config.EnableDryRun)
	if err != nil {
		return fmt.Errorf("failed to create struct validator: %w", err)
	}

	// Execute the validation
	if err := validator.Execute(ctx, opts); err != nil {
		return fmt.Errorf("struct validation failed: %w", err)
	}

	// Update stats
	metrics := validator.CollectMetrics()
	mt.Stats.FilesAnalyzed += metrics["files_analyzed"].(int)
	mt.Stats.FilesProcessed += metrics["files_analyzed"].(int)
	mt.Stats.OperationsExecuted++

	return nil
}

// RunImportConflictResolution resolves import conflicts in Go files
func (mt *ManagerToolkit) RunImportConflictResolution(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting import conflict resolution on: %s", opts.Target)

	// Create a new import conflict resolver
	resolver := &ImportConflictResolver{
		BaseDir: mt.BaseDir,
		FileSet: token.NewFileSet(),
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	// Execute the resolution
	if err := resolver.Execute(ctx, opts); err != nil {
		return fmt.Errorf("import conflict resolution failed: %w", err)
	}

	// Update stats
	metrics := resolver.CollectMetrics()
	mt.Stats.FilesAnalyzed += metrics["files_analyzed"].(int)
	mt.Stats.FilesModified += metrics["files_modified"].(int)
	mt.Stats.ImportsFixed += metrics["imports_fixed"].(int)
	mt.Stats.FilesProcessed += metrics["files_analyzed"].(int)
	mt.Stats.OperationsExecuted++

	return nil
}

// RunDependencyAnalysis analyzes dependencies in the codebase
func (mt *ManagerToolkit) RunDependencyAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting dependency analysis on: %s", opts.Target)

	// Create a new dependency analyzer
	analyzer := &DependencyAnalyzer{
		BaseDir: mt.BaseDir,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	// Execute the analysis
	if err := analyzer.Execute(ctx, opts); err != nil {
		return fmt.Errorf("dependency analysis failed: %w", err)
	}

	// Update stats
	metrics := analyzer.CollectMetrics()
	mt.Stats.FilesAnalyzed += metrics["files_analyzed"].(int)
	mt.Stats.FilesProcessed += metrics["files_analyzed"].(int)
	mt.Stats.OperationsExecuted++

	return nil
}

// RunDuplicateTypeDetection detects duplicate type definitions
func (mt *ManagerToolkit) RunDuplicateTypeDetection(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting duplicate type detection on: %s", opts.Target)

	// Create a new duplicate type detector
	detector := &DuplicateTypeDetector{
		BaseDir: mt.BaseDir,
		FileSet: token.NewFileSet(),
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	// Execute the detection
	if err := detector.Execute(ctx, opts); err != nil {
		return fmt.Errorf("duplicate type detection failed: %w", err)
	}

	// Update stats
	metrics := detector.CollectMetrics()
	mt.Stats.FilesAnalyzed += metrics["files_analyzed"].(int)
	mt.Stats.FilesProcessed += metrics["files_analyzed"].(int)
	mt.Stats.OperationsExecuted++

	return nil
}

// RunAnalysis performs comprehensive analysis
func (mt *ManagerToolkit) RunAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Running comprehensive analysis on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// RunMigration performs interface migration
func (mt *ManagerToolkit) RunMigration(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🚀 Running interface migration on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// FixImports fixes import statements
func (mt *ManagerToolkit) FixImports(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Fixing import statements on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// RemoveDuplicates removes duplicate code
func (mt *ManagerToolkit) RemoveDuplicates(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔄 Removing duplicate code on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// FixSyntaxErrors fixes syntax errors
func (mt *ManagerToolkit) FixSyntaxErrors(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Fixing syntax errors on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// RunHealthCheck performs a health check on the codebase
func (mt *ManagerToolkit) RunHealthCheck(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("💉 Running health check on: %s", opts.Target)
	// Implementation will be added in future phases
	return nil
}

// InitializeConfig initializes the toolkit configuration
func (mt *ManagerToolkit) InitializeConfig(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("⚙️ Initializing toolkit configuration")
	// Implementation will be added in future phases
	return nil
}

// RunFullSuite runs the full suite of toolkit operations
func (mt *ManagerToolkit) RunFullSuite(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🚀 Running full toolkit suite on: %s", opts.Target)

	operations := []Operation{
		OpAnalyze,
		OpValidateStructs,
		OpResolveImports,
		OpAnalyzeDeps,
		OpDetectDuplicates,
		OpFixImports,
		OpRemoveDups,
		OpSyntaxFix,
		OpMigrate,
		OpHealthCheck,
	}

	for _, op := range operations {
		if err := mt.ExecuteOperation(ctx, op, opts); err != nil {
			mt.Logger.Error("Full suite operation %s failed: %v", string(op), err)
			return fmt.Errorf("full suite operation %s failed: %w", string(op), err)
		}
	}

	return nil
}

// Close closes the toolkit and frees resources
func (mt *ManagerToolkit) Close() {
	if mt.Logger != nil && mt.Logger.file != nil {
		mt.Logger.Close()
	}
}
