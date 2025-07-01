package toolkit

import (
	"context"
	"encoding/json"
	"fmt"
	"go/token"
	"os"
	"time"

	"github.com/email-sender/tools/core/platform" // Import platform package
	"github.com/email-sender/tools/core/registry"
	"github.com/email-sender/tools/operations/analysis"
	"github.com/email-sender/tools/operations/correction"
	"github.com/email-sender/tools/operations/migration"
	"github.com/email-sender/tools/operations/validation"
)

// Configuration constants (can be kept here or made configurable)
const (
	ToolVersion    = "3.0.0" // This might be better as a variable in ManagerToolkit or from config
)

// ManagerToolkit structure
type ManagerToolkit struct {
	Config    *platform.ToolkitConfig // Use platform.ToolkitConfig
	Logger    *platform.Logger        // Use platform.Logger
	FileSet   *token.FileSet
	BaseDir   string
	StartTime time.Time
	Stats     *platform.ToolkitStats  // Use platform.ToolkitStats
}

// NewManagerToolkit creates a new toolkit instance
func NewManagerToolkit(baseDir, configPath string, verbose bool) (*ManagerToolkit, error) {
	logger, err := platform.NewLogger(verbose) // Use platform.NewLogger
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %w", err)
	}

	config, err := LoadOrCreateConfig(configPath, baseDir) // This will now return *platform.ToolkitConfig
	if err != nil {
		logger.Error("Failed to load config: %v", err)
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	manager := &ManagerToolkit{
		Config:    config,
		Logger:    logger,
		FileSet:   token.NewFileSet(),
		BaseDir:   baseDir,
		StartTime: time.Now(),
		Stats:     &platform.ToolkitStats{}, // Use platform.ToolkitStats
	}

	logger.Info("Manager Toolkit v%s initialized", ToolVersion)
	logger.Info("Base directory: %s", baseDir)
	logger.Info("Dry run mode: %v", config.EnableDryRun)

	return manager, nil
}

// LoadOrCreateConfig loads an existing config or creates a default one
func LoadOrCreateConfig(configPath, baseDir string) (*ToolkitConfig, error) {
	if configPath == "" {
		// Create default config
		// DefaultBaseDir was CLI specific, pass baseDir if needed by CreateDefaultConfigStruct
		return CreateDefaultConfigStruct(baseDir), nil
	}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		config := CreateDefaultConfigStruct(baseDir)
		if errSave := SaveConfig(config, configPath); errSave != nil {
			// Log this error? For now, return it.
			return nil, fmt.Errorf("failed to save default config: %w", errSave)
		}
		return config, nil
	}

	return LoadConfig(configPath)
}

// CreateDefaultConfigStruct creates a default configuration
func CreateDefaultConfigStruct(baseDir string) *ToolkitConfig {
	// Ensure this aligns with toolkit.ToolkitConfig fields
	return &ToolkitConfig{
		MaxWorkers: 4, // Example default
		Plugins:    []string{},
		EnableDryRun: false, // Default dry run to false
		// BaseDir is not part of ToolkitConfig struct, it's a runtime param for NewManagerToolkit
		// LogPath can be set here if desired, e.g., "toolkit.log"
	}
}

// LoadConfig loads configuration from a JSON file
func LoadConfig(path string) (*ToolkitConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var config ToolkitConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}
	return &config, nil
}

// SaveConfig saves configuration to a JSON file
func SaveConfig(config *ToolkitConfig, path string) error {
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

// Close closes the toolkit and releases resources
func (mt *ManagerToolkit) Close() error {
	if mt.Logger != nil {
		return mt.Logger.Close()
	}
	return nil
}

// PrintFinalStats prints a summary of operations performed
func (mt *ManagerToolkit) PrintFinalStats() {
	// This function is primarily for CLI output.
	// It could remain here, or the stats could be returned for the CLI to print.
	// For now, keep it for simplicity of refactoring.
	fmt.Printf("\n--- Manager Toolkit v%s Results ---\n", ToolVersion)
	fmt.Printf("Files processed:     %d\n", mt.Stats.FilesProcessed)
	fmt.Printf("Files modified:      %d\n", mt.Stats.FilesModified)
	fmt.Printf("Files created:       %d\n", mt.Stats.FilesCreated)
	fmt.Printf("Operations executed: %d\n", mt.Stats.OperationsExecuted)
	fmt.Printf("Execution time:      %v\n", mt.Stats.ExecutionTime)
	if mt.Stats.ErrorsEncountered > 0 {
		fmt.Printf("Errors encountered:  %d\n", mt.Stats.ErrorsEncountered)
	}
}

// ExecuteOperation executes the specified operation
// Note: The 'op Operation' from manager_toolkit.go's main package was an alias to toolkit.Operation.
// Here, we directly use toolkit.Operation.
func (mt *ManagerToolkit) ExecuteOperation(ctx context.Context, op Operation, opts *OperationOptions) error {
	mt.Logger.Info("Starting operation: %s", string(op))
	startTime := time.Now()
	mt.Stats.OperationsExecuted++ // Increment when an attempt to execute is made

	var err error

	globalRegistry := registry.GetGlobalRegistry()
	if globalRegistry != nil {
		var toolImpl ToolkitOperation // Explicitly use the interface type
		toolImpl, errGetTool := globalRegistry.GetTool(op) // op is already toolkit.Operation
		if errGetTool == nil && toolImpl != nil {
			mt.Logger.Info("Using registered tool: %s", toolImpl.String())
			// Ensure DryRun from options is respected if the tool doesn't directly see mt.Config
            if opts == nil { opts = &OperationOptions{} } // Ensure opts is not nil
            opts.DryRun = mt.Config.EnableDryRun // Propagate dry run setting
			err = toolImpl.Execute(ctx, opts)
		} else {
			if errGetTool != nil {
				mt.Logger.Debug("Tool for operation '%s' not found in registry: %v. Falling back to manual dispatch.", string(op), errGetTool)
			} else if toolImpl == nil {
                 mt.Logger.Debug("Tool for operation '%s' resolved to nil in registry. Falling back to manual dispatch.", string(op))
            }
			err = mt.manualDispatch(ctx, op, opts) // Fallback to manual dispatch
		}
	} else {
		mt.Logger.Warn("Global tool registry is not available. Falling back to manual dispatch.")
		err = mt.manualDispatch(ctx, op, opts) // Fallback to manual dispatch
	}

	duration := time.Since(startTime)
	// Assign duration to stats.ExecutionTime is tricky if this is total time vs per-op.
	// Let's assume ToolkitStats.ExecutionTime is cumulative for now.
	mt.Stats.ExecutionTime += duration

	if err != nil {
		mt.Logger.Error("Operation %s failed after %v: %v", string(op), duration, err)
		mt.Stats.ErrorsEncountered++
		return err
	}

	mt.Logger.Info("Operation %s completed successfully in %v", string(op), duration)
	return nil
}

// manualDispatch handles operations not found in the registry or when registry is unavailable.
// This is effectively the switch statement from the original manager_toolkit.go.
// The CLI's local Operation constants (OpAnalyze, OpMigrate, etc.) need to be mapped to toolkit.Operation strings.
func (mt *ManagerToolkit) manualDispatch(ctx context.Context, op Operation, opts *OperationOptions) error {
    mt.Logger.Info("Manually dispatching operation: %s", string(op))
    if opts == nil { opts = &OperationOptions{} }
    opts.DryRun = mt.Config.EnableDryRun // Ensure dry run is set

	// These string values come from toolkit.Operation constants if they match,
	// or from CLI-specific operations.
	switch op {
	// Matching toolkit.Operation constants directly
	case ValidateStructs:
		return mt.RunStructValidation(ctx, opts)
	case ResolveImports:
		return mt.RunImportConflictResolution(ctx, opts)
	case AnalyzeDeps:
		return mt.RunDependencyAnalysis(ctx, opts)
	case DetectDuplicates:
		return mt.RunDuplicateTypeDetection(ctx, opts)
	case SyntaxCheck: // This is "check-syntax"
		return mt.RunSyntaxCheck(ctx, opts)
	case TypeDefGen: // This is "generate-typedefs"
		return mt.RunTypeDefGen(ctx, opts)
	case NormalizeNaming:
		return mt.RunNormalizeNaming(ctx, opts)

	// Operations that might be CLI-specific or have different string values
	// These need to be defined as constants of type toolkit.Operation if used by CLI
	// For now, compare with their string values as defined in the CLI's original constants
	case "analyze": // Corresponds to original OpAnalyze
		return mt.RunAnalysis(ctx, opts)
	case "migrate": // Corresponds to original OpMigrate
		return mt.RunMigration(ctx, opts)
	case "fix-imports": // Corresponds to original OpFixImports
		return mt.FixImports(ctx, opts)
	case "remove-duplicates": // Corresponds to original OpRemoveDups
		return mt.RemoveDuplicates(ctx, opts)
	case "fix-syntax": // Corresponds to original OpSyntaxFix
		return mt.FixSyntaxErrors(ctx, opts)
	case "health-check": // Corresponds to original OpHealthCheck
		return mt.RunHealthCheck(ctx, opts)
	case "init-config": // Corresponds to original OpInitConfig
		return mt.InitializeConfig(ctx, opts)
	case "full-suite": // Corresponds to original OpFullSuite
		return mt.RunFullSuite(ctx, opts)

	// The following were CLI-specific constants that had different string values
	// than their toolkit counterparts, or were unique to CLI.
	// OpValidateStructs: "validate-structs" (toolkit.ValidateStructs is same)
	// OpResolveImports: "resolve-imports" (toolkit.ResolveImports is same)
	// OpAnalyzeDeps: "analyze-dependencies" (toolkit.AnalyzeDeps is same)
	// OpDetectDuplicates: "detect-duplicates" (toolkit.DetectDuplicates is same)
	// OpSyntaxCheck: "syntax-check" (toolkit.SyntaxCheck is "check-syntax", so this is different)
	// OpTypeDefGen: "type-def-gen" (toolkit.TypeDefGen is "generate-typedefs", so this is different)
	// OpNormalizeNaming: "normalize-naming" (toolkit.NormalizeNaming is same)

	// If the string value "syntax-check" was passed, and it's different from toolkit.SyntaxCheck ("check-syntax")
    // then it would fall to default. The CLI needs to pass the exact string values defined in toolkit.Operation constants.
    // The original CLI defined its own Operation type and constants. Now, we assume `op` is one of toolkit.Operation.
    // The switch above handles toolkit.Operation values. If the CLI passes strings like "analyze",
    // they need to be converted to toolkit.Operation type before calling ExecuteOperation.
    // The current ExecuteOperation signature takes toolkit.Operation, so the mapping happens before this call.
    // This manualDispatch is a fallback if registry lookup fails.

	default:
		return fmt.Errorf("unknown operation for manual dispatch: %s", string(op))
	}
}


// Specific operation runner methods (RunStructValidation, etc.)
// These methods now use types from their respective imported packages (validation, correction, analysis, migration)
// and toolkit types (Logger, ToolkitStats, OperationOptions).

func (mt *ManagerToolkit) RunStructValidation(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting struct validation on: %s", opts.Target)
	validatorImpl, err := validation.NewStructValidator(mt.BaseDir, mt.Logger, mt.Config.EnableDryRun)
	if err != nil {
		return fmt.Errorf("failed to create struct validator: %w", err)
	}
	if err := validatorImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("struct validation failed: %w", err)
	}
	metrics := validatorImpl.CollectMetrics()
	if filesAnalyzed, ok := metrics["files_analyzed"].(int); ok {
		mt.Stats.FilesAnalyzed += filesAnalyzed
		mt.Stats.FilesProcessed += filesAnalyzed
	}
	return nil
}

func (mt *ManagerToolkit) RunImportConflictResolution(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting import conflict resolution on: %s", opts.Target)
	resolver := &correction.ImportConflictResolver{
		BaseDir: mt.BaseDir,
		FileSet: token.NewFileSet(), // Create new or pass from mt? For isolation, new is okay.
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}
	if err := resolver.Execute(ctx, opts); err != nil {
		return fmt.Errorf("import conflict resolution failed: %w", err)
	}
	metrics := resolver.CollectMetrics()
	if filesAnalyzed, ok := metrics["files_analyzed"].(int); ok { mt.Stats.FilesAnalyzed += filesAnalyzed; mt.Stats.FilesProcessed += filesAnalyzed }
	if filesModified, ok := metrics["files_modified"].(int); ok { mt.Stats.FilesModified += filesModified }
	if importsFixed, ok := metrics["imports_fixed"].(int); ok { mt.Stats.ImportsFixed += importsFixed }
	return nil
}

func (mt *ManagerToolkit) RunDependencyAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting dependency analysis on: %s", opts.Target)
	analyzerImpl := &analysis.DependencyAnalyzer{
		BaseDir: mt.BaseDir,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}
	if err := analyzerImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("dependency analysis failed: %w", err)
	}
	metrics := analyzerImpl.CollectMetrics()
	if filesAnalyzed, ok := metrics["files_analyzed"].(int); ok { mt.Stats.FilesAnalyzed += filesAnalyzed; mt.Stats.FilesProcessed += filesAnalyzed }
	return nil
}

func (mt *ManagerToolkit) RunDuplicateTypeDetection(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting duplicate type detection on: %s", opts.Target)
	detectorImpl := &analysis.DuplicateTypeDetector{
		BaseDir: mt.BaseDir,
		FileSet: token.NewFileSet(),
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}
	if err := detectorImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("duplicate type detection failed: %w", err)
	}
	metrics := detectorImpl.CollectMetrics()
	if filesAnalyzed, ok := metrics["files_analyzed"].(int); ok { mt.Stats.FilesAnalyzed += filesAnalyzed; mt.Stats.FilesProcessed += filesAnalyzed }
	if duplicatesFound, ok := metrics["duplicates_found"].(int); ok { mt.Stats.DuplicatesFound += duplicatesFound }
	return nil
}

func (mt *ManagerToolkit) RunSyntaxCheck(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Starting syntax checking...")
	checkerImpl := analysis.NewSyntaxChecker(mt.BaseDir, mt.Logger, mt.Stats, mt.Config.EnableDryRun)
	// Validate is optional if Execute also validates or if New initializes correctly
	// if err := checkerImpl.Validate(ctx); err != nil {
	// 	return fmt.Errorf("syntax checker validation failed: %w", err)
	// }
	if err := checkerImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("syntax checking failed: %w", err)
	}
	// Metrics collection would be similar to above
	mt.Logger.Info("✅ Syntax checking completed successfully")
	return nil
}

func (mt *ManagerToolkit) RunTypeDefGen(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Starting type definition generation...")
	generatorImpl := migration.NewTypeDefGenerator(mt.BaseDir, mt.Logger, mt.Stats, mt.Config.EnableDryRun)
	// if err := generatorImpl.Validate(ctx); err != nil {
	// 	return fmt.Errorf("type definition generator validation failed: %w", err)
	// }
	if err := generatorImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("type definition generation failed: %w", err)
	}
	mt.Logger.Info("✅ Type definition generation completed successfully")
	return nil
}

func (mt *ManagerToolkit) RunNormalizeNaming(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Starting naming normalization...")
	normalizerImpl := correction.NewNamingNormalizer(mt.BaseDir, mt.Logger, mt.Stats, mt.Config.EnableDryRun)
	// if err := normalizerImpl.Validate(ctx); err != nil {
	// 	return fmt.Errorf("naming normalizer validation failed: %w", err)
	// }
	if err := normalizerImpl.Execute(ctx, opts); err != nil {
		return fmt.Errorf("naming normalization failed: %w", err)
	}
	mt.Logger.Info("✅ Naming normalization completed successfully")
	return nil
}

// Stubs for other operations mentioned in the CLI's Op constants
func (mt *ManagerToolkit) RunAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Running comprehensive analysis on: %s (Not fully implemented in toolkit library)", opts.Target)
	return nil // Placeholder
}
func (mt *ManagerToolkit) RunMigration(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🚀 Running interface migration on: %s (Not fully implemented in toolkit library)", opts.Target)
	return nil // Placeholder
}
func (mt *ManagerToolkit) FixImports(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Fixing import statements on: %s (Not fully implemented, use ResolveImports or specific tool)", opts.Target)
	// This might be a more general version of ResolveImports or a sequence of operations.
	// For now, it's a distinct operation from the CLI.
	return mt.RunImportConflictResolution(ctx, opts) // Or a more general import fixer
}
func (mt *ManagerToolkit) RemoveDuplicates(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔄 Removing duplicate code on: %s (Not fully implemented, use DetectDuplicates or specific tool)", opts.Target)
	return mt.RunDuplicateTypeDetection(ctx, opts) // Or a more general duplicate remover
}
func (mt *ManagerToolkit) FixSyntaxErrors(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Fixing syntax errors on: %s (Not fully implemented, use SyntaxCheck or specific tool)", opts.Target)
	// This implies correction, SyntaxCheck is just detection.
	// This might be a wrapper around a syntax corrector tool if one exists.
	return mt.RunSyntaxCheck(ctx, opts) // Or a syntax corrector
}
func (mt *ManagerToolkit) RunHealthCheck(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("💉 Running health check on: %s (Not fully implemented in toolkit library)", opts.Target)
	// This would likely be a sequence of various validation/analysis operations.
	return nil // Placeholder
}
func (mt *ManagerToolkit) InitializeConfig(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("⚙️ Initializing toolkit configuration (Not fully implemented in toolkit library beyond LoadOrCreate)")
	// The LoadOrCreateConfig already handles initialization if file is missing.
	// This CLI op might do more, like interactive setup.
	return nil // Placeholder
}
func (mt *ManagerToolkit) RunFullSuite(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🚀 Running full toolkit suite on: %s", opts.Target)
	// Define the sequence of toolkit.Operation constants for the full suite
	suiteOperations := []Operation{
		// Example sequence, adjust as needed
		ValidateStructs,
		SyntaxCheck,
		AnalyzeDeps,
		DetectDuplicates,
		ResolveImports,
		NormalizeNaming,
		// Add other relevant operations from toolkit.Operation constants
	}
	for _, op := range suiteOperations {
		if err := mt.ExecuteOperation(ctx, op, opts); err != nil { // Recursive call, ensure op is toolkit.Operation
			mt.Logger.Error("Full suite operation %s failed: %v", string(op), err)
			// Decide if to continue or stop on first error
			return fmt.Errorf("full suite operation %s failed: %w", string(op), err)
		}
	}
	return nil
}
