package platform

import (
	"context"
	"log"
	"os"
	"time"
)

// ToolkitOperation represents the common interface for all toolkit operations
type ToolkitOperation interface {
	Execute(ctx context.Context, options *OperationOptions) error
	Validate(ctx context.Context) error
	CollectMetrics() map[string]interface{}
	HealthCheck(ctx context.Context) error
	String() string
	GetDescription() string
	Stop(ctx context.Context) error
}

// OperationOptions holds options for operations
type OperationOptions struct {
	Target   string          `json:"target"`
	Output   string          `json:"output"`
	Force    bool            `json:"force"`
	DryRun   bool            `json:"dry_run"`
	Verbose  bool            `json:"verbose"`
	Timeout  time.Duration   `json:"timeout"`
	Workers  int             `json:"workers"`
	LogLevel string          `json:"log_level"`
	Context  context.Context `json:"-"`
	Config   *ToolkitConfig  `json:"config"`
}

// Operation represents the type of operation in the toolkit
type Operation string

// ToolkitConfig configuration for the toolkit
type ToolkitConfig struct {
	ConfigPath   string   `json:"config_path,omitempty"`
	LogPath      string   `json:"log_path,omitempty"`
	MaxWorkers   int      `json:"max_workers,omitempty"`
	Plugins      []string `json:"plugins,omitempty"`
	EnableDryRun bool     `json:"enable_dry_run"`
}

// ToolkitStats holds statistics about toolkit operations
type ToolkitStats struct {
	FilesProcessed     int           `json:"files_processed"`
	FilesModified      int           `json:"files_modified"`
	FilesCreated       int           `json:"files_created"`
	OperationsExecuted int           `json:"operations_executed"`
	ExecutionTime      time.Duration `json:"execution_time"`
	ErrorsEncountered  int           `json:"errors_encountered"`
	ImportsFixed       int           `json:"imports_fixed,omitempty"`
	DuplicatesFound    int           `json:"duplicates_found,omitempty"`
}

// Logger defines a simple logger interface
type Logger struct {
	verbose   bool
	stdLogger *log.Logger
}

// NewLogger creates a new Logger instance
func NewLogger(verbose bool) (*Logger, error) {
	return &Logger{
		verbose:   verbose,
		stdLogger: log.New(os.Stdout, "", log.LstdFlags),
	}, nil
}

func (l *Logger) Info(format string, args ...interface{}) {
	l.stdLogger.Printf("INFO: "+format+"\n", args...)
}
func (l *Logger) Warn(format string, args ...interface{}) {
	l.stdLogger.Printf("WARN: "+format+"\n", args...)
}
func (l *Logger) Error(format string, args ...interface{}) {
	l.stdLogger.Printf("ERROR: "+format+"\n", args...)
}
func (l *Logger) Debug(format string, args ...interface{}) {
	if l.verbose {
		l.stdLogger.Printf("DEBUG: "+format+"\n", args...)
	}
}
func (l *Logger) Close() error {
	return nil
}

// Shared Operation constants
const (
	AnalyzeDeps      Operation = "analyze-dependencies"
	SyntaxCheck      Operation = "check-syntax"
	DetectDuplicates Operation = "detect-duplicates"
	ValidateStructs  Operation = "validate-structs"
	ResolveImports   Operation = "resolve-imports"
	NormalizeNaming  Operation = "normalize-naming"
	TypeDefGen       Operation = "generate-typedefs"
)
