// Manager Toolkit - Core Implementation (Part 2)

package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"go/token"
	"os"
	"path/filepath"
	"time"
)

// ToolkitOperation represents the common interface for all toolkit operations
type ToolkitOperation interface {
	Execute(ctx context.Context, options *OperationOptions) error
	Validate(ctx context.Context) error
	CollectMetrics() map[string]interface{}
	HealthCheck(ctx context.Context) error
}

// OperationOptions holds options for operations
type OperationOptions struct {
	Target string
	Output string
	Force  bool
}

// NewManagerToolkit creates a new toolkit instance
func NewManagerToolkit(baseDir, configPath string, verbose bool) (*ManagerToolkit, error) {
	// Initialize logger
	logger, err := NewLogger(verbose)
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %w", err)
	}

	// Load or create config
	config, err := LoadOrCreateConfig(configPath, baseDir)
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	toolkit := &ManagerToolkit{
		Config:    config,
		Logger:    logger,
		FileSet:   token.NewFileSet(),
		BaseDir:   baseDir,
		StartTime: time.Now(),
		Stats:     &ToolkitStats{},
	}

	logger.Info("Manager Toolkit v%s initialized", ToolVersion)
	logger.Info("Base directory: %s", baseDir)
	logger.Info("Dry run mode: %v", config.EnableDryRun)

	return toolkit, nil
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

// RunAnalysis performs comprehensive analysis
func (mt *ManagerToolkit) RunAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting comprehensive analysis...")

	analyzer := &InterfaceAnalyzer{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
	}

	report, err := analyzer.AnalyzeInterfaces()
	if err != nil {
		return fmt.Errorf("analysis failed: %w", err)
	}

	// Generate detailed report
	if opts.Output != "" {
		if err := mt.SaveAnalysisReport(report, opts.Output); err != nil {
			return fmt.Errorf("failed to save report: %w", err)
		}
	}

	mt.PrintAnalysisResults(report)
	return nil
}

// RunMigration performs interface migration
func (mt *ManagerToolkit) RunMigration(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🚀 Starting interface migration...")

	migrator := &InterfaceMigrator{
		BaseDir:       mt.BaseDir,
		InterfacesDir: mt.Config.InterfacesDir,
		FileSet:       mt.FileSet,
		Logger:        mt.Logger,
		Stats:         mt.Stats,
		DryRun:        mt.Config.EnableDryRun,
	}

	return migrator.ExecuteMigration()
}

// FixImports fixes import statements across all files
func (mt *ManagerToolkit) FixImports(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Fixing import statements...")

	fixer := &ImportFixer{
		BaseDir:    mt.BaseDir,
		ModuleName: mt.Config.ModuleName,
		FileSet:    mt.FileSet,
		Logger:     mt.Logger,
		Stats:      mt.Stats,
		DryRun:     mt.Config.EnableDryRun,
	}

	if opts.Target != "" {
		return fixer.FixSingleFile(opts.Target)
	}

	return fixer.FixAllImports()
}

// RemoveDuplicates removes duplicate code and methods
func (mt *ManagerToolkit) RemoveDuplicates(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🧹 Removing duplicate code...")

	remover := &DuplicateRemover{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	if opts.Target != "" {
		return remover.ProcessSingleFile(opts.Target)
	}

	return remover.ProcessAllFiles()
}

// FixSyntaxErrors fixes syntax errors in Go files
func (mt *ManagerToolkit) FixSyntaxErrors(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔨 Fixing syntax errors...")

	fixer := &SyntaxFixer{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	if opts.Target != "" {
		return fixer.FixSingleFile(opts.Target)
	}

	return fixer.FixAllFiles()
}

// RunHealthCheck performs system health check
func (mt *ManagerToolkit) RunHealthCheck(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🏥 Running health check...")

	checker := &HealthChecker{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
	}

	report := checker.CheckHealth()
	mt.PrintHealthReport(report)

	if opts.Output != "" {
		return mt.SaveHealthReport(report, opts.Output)
	}

	return nil
}

// InitializeConfig creates initial configuration
func (mt *ManagerToolkit) InitializeConfig(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("⚙️ Initializing configuration...")

	configPath := opts.Target
	if configPath == "" {
		configPath = filepath.Join(mt.BaseDir, ConfigFile)
	}

	return CreateDefaultConfig(configPath)
}

// RunFullSuite runs all operations in sequence
func (mt *ManagerToolkit) RunFullSuite(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🎯 Running full maintenance suite...")

	operations := []Operation{
		OpAnalyze,
		OpSyntaxFix,
		OpFixImports,
		OpRemoveDups,
		OpMigrate,
		OpHealthCheck,
	}

	for _, op := range operations {
		if err := mt.ExecuteOperation(ctx, op, opts); err != nil {
			return fmt.Errorf("full suite failed at %s: %w", string(op), err)
		}
	}

	mt.Logger.Info("✅ Full maintenance suite completed successfully")
	return nil
}

// Close cleans up resources
func (mt *ManagerToolkit) Close() error {
	if mt.Logger != nil {
		return mt.Logger.Close()
	}
	return nil
}

// Helper functions for configuration management
func LoadOrCreateConfig(configPath, baseDir string) (*ToolkitConfig, error) {
	if configPath == "" {
		configPath = filepath.Join(baseDir, ConfigFile)
	}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		config := CreateDefaultConfigStruct(baseDir)
		if err := SaveConfig(config, configPath); err != nil {
			return nil, err
		}
		return config, nil
	}

	return LoadConfig(configPath)
}

func CreateDefaultConfigStruct(baseDir string) *ToolkitConfig {
	return &ToolkitConfig{
		BaseDirectory:   baseDir,
		InterfacesDir:   filepath.Join(baseDir, "interfaces"),
		ToolsDir:        filepath.Join(baseDir, "tools"),
		ExcludePatterns: []string{"*.test.go", "*/vendor/*", "*/.git/*", "*/node_modules/*"},
		IncludePatterns: []string{"*.go"},
		BackupEnabled:   true,
		VerboseLogging:  false,
		MaxFileSize:     10 * 1024 * 1024, // 10MB
		ModuleName:      "github.com/email-sender/managers",
		EnableDryRun:    false,
	}
}

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

func SaveConfig(config *ToolkitConfig, path string) error {
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, data, 0644)
}

func CreateDefaultConfig(path string) error {
	baseDir := filepath.Dir(path)
	config := CreateDefaultConfigStruct(baseDir)
	return SaveConfig(config, path)
}

// SaveAnalysisReport saves the analysis report to a file
func (mt *ManagerToolkit) SaveAnalysisReport(report *AnalysisReport, outputPath string) error {
	if outputPath == "" {
		outputPath = filepath.Join(mt.Config.BaseDir, "analysis-report.json")
	}

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write report: %w", err)
	}

	mt.Logger.Info("Analysis report saved to: %s", outputPath)
	return nil
}

// PrintAnalysisResults prints analysis results to console
func (mt *ManagerToolkit) PrintAnalysisResults(report *AnalysisReport) {
	mt.Logger.Info("=== ANALYSIS RESULTS ===")
	mt.Logger.Info("Files Analyzed: %d", len(report.Files))
	mt.Logger.Info("Interfaces Found: %d", len(report.Interfaces))
	mt.Logger.Info("Total Methods: %d", report.TotalMethods)
	mt.Logger.Info("Syntax Errors: %d", len(report.SyntaxErrors))
	mt.Logger.Info("Quality Score: %.2f", report.QualityScore.OverallScore)

	if len(report.SyntaxErrors) > 0 {
		mt.Logger.Info("Syntax Errors:")
		for _, err := range report.SyntaxErrors {
			mt.Logger.Info("  %s:%d - %s", err.File, err.Line, err.Message)
		}
	}
}

// PrintHealthReport prints health report to console
func (mt *ManagerToolkit) PrintHealthReport(report *HealthReport) {
	mt.Logger.Info("=== HEALTH REPORT ===")
	mt.Logger.Info("Overall Health: %s (Score: %.1f)", report.OverallHealth, report.Score)
	mt.Logger.Info("Total Files: %d", report.FileStatistics.TotalFiles)
	mt.Logger.Info("Go Files: %d", report.FileStatistics.GoFiles)
	mt.Logger.Info("Test Files: %d", report.FileStatistics.TestFiles)
	mt.Logger.Info("Issues Found: %d", len(report.Issues))

	if len(report.Issues) > 0 {
		mt.Logger.Info("Issues:")
		for _, issue := range report.Issues {
			mt.Logger.Info("  [%s] %s: %s", issue.Severity, issue.Type, issue.Description)
		}
	}

	if len(report.Recommendations) > 0 {
		mt.Logger.Info("Recommendations:")
		for _, rec := range report.Recommendations {
			mt.Logger.Info("  - %s", rec)
		}
	}
}

// SaveHealthReport saves the health report to a file
func (mt *ManagerToolkit) SaveHealthReport(report *HealthReport, outputPath string) error {
	if outputPath == "" {
		outputPath = filepath.Join(mt.Config.BaseDir, "health-report.json")
	}

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal health report: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write health report: %w", err)
	}

	mt.Logger.Info("Health report saved to: %s", outputPath)
	return nil
}

// Phase 1.1.1 & 1.1.2 - New Analysis Operations Implementation

// RunStructValidation performs Go struct validation using StructValidator
func (mt *ManagerToolkit) RunStructValidation(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting struct validation analysis...")

	validator := &StructValidator{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	target := opts.Target
	if target == "" {
		target = mt.BaseDir
	}

	return validator.Execute(ctx, &OperationOptions{
		Target: target,
		Output: opts.Output,
		Force:  opts.Force,
	})
}

// RunImportConflictResolution performs import conflict resolution using ImportConflictResolver
func (mt *ManagerToolkit) RunImportConflictResolution(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔧 Starting import conflict resolution...")

	resolver := &ImportConflictResolver{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	target := opts.Target
	if target == "" {
		target = mt.BaseDir
	}

	return resolver.Execute(ctx, &OperationOptions{
		Target: target,
		Output: opts.Output,
		Force:  opts.Force,
	})
}

// RunDependencyAnalysis performs dependency analysis using DependencyAnalyzer
func (mt *ManagerToolkit) RunDependencyAnalysis(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("📦 Starting dependency analysis...")

	analyzer := &DependencyAnalyzer{
		BaseDir: mt.BaseDir,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	target := opts.Target
	if target == "" {
		target = mt.BaseDir
	}

	return analyzer.Execute(ctx, &OperationOptions{
		Target: target,
		Output: opts.Output,
		Force:  opts.Force,
	})
}

// RunDuplicateTypeDetection performs duplicate type detection using DuplicateTypeDetector
func (mt *ManagerToolkit) RunDuplicateTypeDetection(ctx context.Context, opts *OperationOptions) error {
	mt.Logger.Info("🔍 Starting duplicate type detection...")

	detector := &DuplicateTypeDetector{
		BaseDir: mt.BaseDir,
		FileSet: mt.FileSet,
		Logger:  mt.Logger,
		Stats:   mt.Stats,
		DryRun:  mt.Config.EnableDryRun,
	}

	target := opts.Target
	if target == "" {
		target = mt.BaseDir
	}

	return detector.Execute(ctx, &OperationOptions{
		Target: target,
		Output: opts.Output,
		Force:  opts.Force,
	})
}
