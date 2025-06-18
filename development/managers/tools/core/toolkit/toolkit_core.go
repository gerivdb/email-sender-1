// Manager Toolkit - Core Type Definitions
// Version: 3.0.0

package toolkit

import (
	"context"
	"fmt"
	"time"
)

// ToolkitOperation represents the common interface for all toolkit operations
type ToolkitOperation interface {
	// Exécution principale
	Execute(ctx context.Context, options *OperationOptions) error

	// Validation pré-exécution
	Validate(ctx context.Context) error

	// Métriques post-exécution
	CollectMetrics() map[string]interface{}

	// Vérification de santé
	HealthCheck(ctx context.Context) error

	// Identification de l'outil (NOUVEAU - résout l'ambiguïté d'identification)
	String() string

	// Description de l'outil (NOUVEAU - améliore la documentation)
	GetDescription() string

	// Gestion des signaux d'arrêt (NOUVEAU - pour la robustesse)
	Stop(ctx context.Context) error
}

// OperationOptions holds options for operations
type OperationOptions struct {
	// Core options
	Target string `json:"target"` // Specific file or directory target
	Output string `json:"output"` // Output file for reports
	Force  bool   `json:"force"`  // Force operations without confirmation

	// Runtime control options (Phase 2.1 - Critical fixes)
	DryRun   bool          `json:"dry_run"`   // Simulation mode without making changes
	Verbose  bool          `json:"verbose"`   // Enable detailed logging
	Timeout  time.Duration `json:"timeout"`   // Operation timeout duration
	Workers  int           `json:"workers"`   // Number of concurrent workers
	LogLevel string        `json:"log_level"` // Logging level (DEBUG, INFO, WARN, ERROR)

	// Advanced options
	Context context.Context `json:"-"`      // Execution context (not serialized)
	Config  *ToolkitConfig  `json:"config"` // Runtime configuration override
}

// Type Operation représente le type d'opération dans le toolkit
type Operation string

// Configuration du toolkit
type ToolkitConfig struct {
	ConfigPath   string
	LogPath      string
	MaxWorkers   int
	Plugins      []string
	EnableDryRun bool `json:"enable_dry_run"`
}

// Constantes d'opération partagées
const (
	// Opérations d'analyse
	AnalyzeDeps      Operation = "analyze-dependencies"
	SyntaxCheck      Operation = "check-syntax"
	DetectDuplicates Operation = "detect-duplicates"

	// Opérations de validation
	ValidateStructs Operation = "validate-structs"

	// Opérations de correction
	ResolveImports  Operation = "resolve-imports"
	NormalizeNaming Operation = "normalize-naming"

	// Opérations de migration
	TypeDefGen Operation = "generate-typedefs"
)

// ToolkitStats tracks operation statistics
type ToolkitStats struct {
	OperationsExecuted int           `json:"operations_executed"`
	FilesAnalyzed      int           `json:"files_analyzed"`
	FilesProcessed     int           `json:"files_processed"`
	ExecutionTime      time.Duration `json:"execution_time"`
	ErrorCount         int           `json:"error_count"`
	WarningCount       int           `json:"warning_count"`
	ErrorsFixed        int           `json:"errors_fixed"`
	FilesModified      int           `json:"files_modified"`
}

// Logger provides logging functionality for toolkit operations
type Logger struct {
	Level      string `json:"level"`
	OutputPath string `json:"output_path"`
	Verbose    bool   `json:"verbose"`
}

// LogLevel constants
const (
	LogLevelDebug = "DEBUG"
	LogLevelInfo  = "INFO"
	LogLevelWarn  = "WARN"
	LogLevelError = "ERROR"
)

// NewLogger creates a new logger instance
func NewLogger(verbose bool) (*Logger, error) {
	return &Logger{
		Level:      LogLevelInfo,
		OutputPath: "",
		Verbose:    verbose,
	}, nil
}

// Info logs an info message
func (l *Logger) Info(format string, args ...interface{}) {
	l.log(LogLevelInfo, format, args...)
}

// Error logs an error message
func (l *Logger) Error(format string, args ...interface{}) {
	l.log(LogLevelError, format, args...)
}

// Warn logs a warning message
func (l *Logger) Warn(format string, args ...interface{}) {
	l.log(LogLevelWarn, format, args...)
}

// Debug logs a debug message
func (l *Logger) Debug(format string, args ...interface{}) {
	l.log(LogLevelDebug, format, args...)
}

// log is the internal logging function
func (l *Logger) log(level, format string, args ...interface{}) {
	if !l.shouldLog(level) {
		return
	}

	// For now, just print to stdout. In a real implementation,
	// this would write to the configured output path
	fmt.Printf("[%s] %s\n", level, fmt.Sprintf(format, args...))
}

// shouldLog determines if a message should be logged based on level
func (l *Logger) shouldLog(level string) bool {
	// Simple level checking
	switch l.Level {
	case LogLevelDebug:
		return true
	case LogLevelInfo:
		return level != LogLevelDebug
	case LogLevelWarn:
		return level != LogLevelDebug && level != LogLevelInfo
	case LogLevelError:
		return level == LogLevelError
	default:
		return true
	}
}

// Close closes the logger (placeholder)
func (l *Logger) Close() error {
	return nil
}
