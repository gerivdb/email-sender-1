// Manager Toolkit - Unified Professional Development Tool
// Version: 2.0.0
// Provides comprehensive analysis, migration, and maintenance utilities
// for the Email Sender Manager Ecosystem

package main

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
)

func main() {
	var (
		operation  = flag.String("op", "", "Operation to perform: analyze|migrate|fix-imports|remove-duplicates|fix-syntax|health-check|init-config|full-suite")
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

// PrintFinalStats prints final statistics
func (mt *ManagerToolkit) PrintFinalStats() {
	mt.Logger.Info("=== FINAL STATISTICS ===")
	mt.Logger.Info("Operations Executed: %d", mt.Stats.OperationsExecuted)
	mt.Logger.Info("Files Processed: %d", mt.Stats.FilesProcessed)
	mt.Logger.Info("Files Modified: %d", mt.Stats.FilesModified)
	mt.Logger.Info("Files Created: %d", mt.Stats.FilesCreated)
	mt.Logger.Info("Errors Fixed: %d", mt.Stats.ErrorsFixed)
	mt.Logger.Info("Imports Fixed: %d", mt.Stats.ImportsFixed)
	mt.Logger.Info("Duplicates Removed: %d", mt.Stats.DuplicatesRemoved)
	mt.Logger.Info("Total Execution Time: %v", mt.Stats.ExecutionTime)
}
