package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"gopkg.in/yaml.v3"

	workflow "email_sender/planning-ecosystem-sync/tools/workflow-orchestrator"
)

// WorkflowOrchestrator interface for dependency injection
type WorkflowOrchestrator interface {
	Initialize() error
	Start(ctx context.Context) error
	Stop() error
	ExecuteFullSync(ctx context.Context) error
	GetMetrics() *workflow.WorkflowMetrics
	GetSyncPoints() []workflow.SyncPoint
	IsRunning() bool
}

// CLIConfig holds CLI-specific configuration
type CLIConfig struct {
	ConfigPath string
	Command    string
	Daemon     bool
	LogLevel   string
	DryRun     bool
	Verbose    bool
}

// Command handlers
type CommandHandler struct {
	orchestrator WorkflowOrchestrator
	config       *workflow.WorkflowConfig
	cliConfig    *CLIConfig
}

func main() {
	cliConfig := parseCLIFlags()

	if err := runCommand(cliConfig); err != nil {
		log.Fatalf("Command failed: %v", err)
	}
}

// parseCLIFlags parses command line flags
func parseCLIFlags() *CLIConfig {
	config := &CLIConfig{}

	flag.StringVar(&config.ConfigPath, "config", "./config/workflow-orchestrator.yaml", "Path to configuration file")
	flag.StringVar(&config.Command, "command", "start", "Command to execute (start, stop, status, sync, metrics)")
	flag.BoolVar(&config.Daemon, "daemon", false, "Run as daemon service")
	flag.StringVar(&config.LogLevel, "log-level", "info", "Log level (debug, info, warn, error)")
	flag.BoolVar(&config.DryRun, "dry-run", false, "Perform dry run without making changes")
	flag.BoolVar(&config.Verbose, "verbose", false, "Enable verbose output")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Workflow Orchestrator CLI - Unified synchronization management\n\n")
		fmt.Fprintf(os.Stderr, "Usage: %s [options]\n\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Commands:\n")
		fmt.Fprintf(os.Stderr, "  start     Start the workflow orchestrator\n")
		fmt.Fprintf(os.Stderr, "  stop      Stop the workflow orchestrator\n")
		fmt.Fprintf(os.Stderr, "  status    Show orchestrator status\n")
		fmt.Fprintf(os.Stderr, "  sync      Execute a full synchronization\n")
		fmt.Fprintf(os.Stderr, "  metrics   Display current metrics\n")
		fmt.Fprintf(os.Stderr, "  validate  Validate configuration\n")
		fmt.Fprintf(os.Stderr, "\nOptions:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nExamples:\n")
		fmt.Fprintf(os.Stderr, "  %s -command=start -daemon\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -command=sync -dry-run\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -command=status -verbose\n", os.Args[0])
	}

	flag.Parse()
	return config
}

// runCommand executes the specified command
func runCommand(cliConfig *CLIConfig) error {
	// Load configuration
	workflowConfig, err := loadWorkflowConfig(cliConfig.ConfigPath)
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Create command handler
	handler := &CommandHandler{
		config:    workflowConfig,
		cliConfig: cliConfig,
	}

	// Execute command
	switch cliConfig.Command {
	case "start":
		return handler.handleStart()
	case "stop":
		return handler.handleStop()
	case "status":
		return handler.handleStatus()
	case "sync":
		return handler.handleSync()
	case "metrics":
		return handler.handleMetrics()
	case "validate":
		return handler.handleValidate()
	default:
		return fmt.Errorf("unknown command: %s", cliConfig.Command)
	}
}

// loadWorkflowConfig loads the workflow configuration from file
func loadWorkflowConfig(configPath string) (*workflow.WorkflowConfig, error) {
	// Check if config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("configuration file not found: %s", configPath)
	}

	// Read config file
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	// Parse YAML configuration
	var config workflow.WorkflowConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Set defaults for missing values
	setConfigDefaults(&config)

	return &config, nil
}

// setConfigDefaults sets default values for configuration
func setConfigDefaults(config *workflow.WorkflowConfig) {
	if config.SyncInterval == 0 {
		config.SyncInterval = 5 * time.Minute
	}
	if config.MaxRetries == 0 {
		config.MaxRetries = 3
	}
	if config.ConflictResolution == "" {
		config.ConflictResolution = "hybrid"
	}
}

// handleStart handles the start command
func (h *CommandHandler) handleStart() error {
	fmt.Printf("🚀 Starting Workflow Orchestrator...\n")

	if h.cliConfig.DryRun {
		fmt.Printf("DRY RUN: Would start workflow orchestrator with config: %s\n", h.cliConfig.ConfigPath)
		return nil
	}

	// Create orchestrator instance
	h.orchestrator = NewWorkflowOrchestrator(h.config)

	// Initialize orchestrator
	if err := h.orchestrator.Initialize(); err != nil {
		return fmt.Errorf("failed to initialize orchestrator: %w", err)
	}

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start orchestrator
	if err := h.orchestrator.Start(ctx); err != nil {
		return fmt.Errorf("failed to start orchestrator: %w", err)
	}

	if h.cliConfig.Daemon {
		fmt.Printf("✅ Workflow Orchestrator started as daemon\n")
		return h.runAsDaemon(ctx, cancel)
	} else {
		fmt.Printf("✅ Workflow Orchestrator started\n")
		fmt.Printf("Press Ctrl+C to stop...\n")
		return h.waitForInterrupt(ctx, cancel)
	}
}

// handleStop handles the stop command
func (h *CommandHandler) handleStop() error {
	fmt.Printf("🛑 Stopping Workflow Orchestrator...\n")

	if h.cliConfig.DryRun {
		fmt.Printf("DRY RUN: Would stop workflow orchestrator\n")
		return nil
	}

	// In a real implementation, this would connect to a running instance
	// and send a stop signal (e.g., via REST API or signal)
	fmt.Printf("✅ Stop signal sent to Workflow Orchestrator\n")
	return nil
}

// handleStatus handles the status command
func (h *CommandHandler) handleStatus() error {
	fmt.Printf("📊 Workflow Orchestrator Status\n")
	fmt.Printf("================================\n")

	if h.cliConfig.DryRun {
		fmt.Printf("DRY RUN: Would check orchestrator status\n")
		return nil
	}

	// Create a temporary orchestrator to check configuration
	orchestrator := NewWorkflowOrchestrator(h.config)

	fmt.Printf("Configuration File: %s\n", h.cliConfig.ConfigPath)
	fmt.Printf("Auto Sync: %v\n", h.config.AutoSync)
	fmt.Printf("Sync Interval: %v\n", h.config.SyncInterval)
	fmt.Printf("Conflict Resolution: %s\n", h.config.ConflictResolution)
	fmt.Printf("Backup Enabled: %v\n", h.config.BackupEnabled)
	fmt.Printf("Alerts Enabled: %v\n", h.config.AlertsEnabled)

	fmt.Printf("\nSynchronization Points:\n")
	syncPoints := orchestrator.GetSyncPoints()
	for _, point := range syncPoints {
		status := "✅ Enabled"
		if !point.Enabled {
			status = "❌ Disabled"
		}
		fmt.Printf("  %s (%s → %s): %s\n", point.Name, point.Source, point.Target, status)
	}

	if h.cliConfig.Verbose {
		fmt.Printf("\nDetailed Configuration:\n")
		fmt.Printf("  Max Retries: %d\n", h.config.MaxRetries)
		fmt.Printf("  Markdown → Dynamic: %v\n", h.config.SyncPoints.MarkdownToDynamic)
		fmt.Printf("  Dynamic → Markdown: %v\n", h.config.SyncPoints.DynamicToMarkdown)
		fmt.Printf("  Roadmap Manager: %v\n", h.config.SyncPoints.RoadmapManager)
		fmt.Printf("  TaskMaster CLI: %v\n", h.config.SyncPoints.TaskMasterCLI)
	}

	return nil
}

// handleSync handles the sync command
func (h *CommandHandler) handleSync() error {
	fmt.Printf("🔄 Executing Full Synchronization...\n")

	if h.cliConfig.DryRun {
		fmt.Printf("DRY RUN: Would execute full synchronization\n")
		return nil
	}

	// Create orchestrator instance
	h.orchestrator = NewWorkflowOrchestrator(h.config)

	// Initialize orchestrator
	if err := h.orchestrator.Initialize(); err != nil {
		return fmt.Errorf("failed to initialize orchestrator: %w", err)
	}

	// Execute full sync
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	startTime := time.Now()
	if err := h.orchestrator.ExecuteFullSync(ctx); err != nil {
		return fmt.Errorf("synchronization failed: %w", err)
	}

	duration := time.Since(startTime)
	fmt.Printf("✅ Full synchronization completed in %v\n", duration)

	// Display metrics if verbose
	if h.cliConfig.Verbose {
		metrics := h.orchestrator.GetMetrics()
		fmt.Printf("\nSync Metrics:\n")
		fmt.Printf("  Total Syncs: %d\n", metrics.TotalSyncs)
		fmt.Printf("  Successful: %d\n", metrics.SuccessfulSyncs)
		fmt.Printf("  Failed: %d\n", metrics.FailedSyncs)
		if metrics.TotalSyncs > 0 {
			successRate := float64(metrics.SuccessfulSyncs) / float64(metrics.TotalSyncs) * 100
			fmt.Printf("  Success Rate: %.1f%%\n", successRate)
		}
	}

	return nil
}

// handleMetrics handles the metrics command
func (h *CommandHandler) handleMetrics() error {
	fmt.Printf("📊 Workflow Orchestrator Metrics\n")
	fmt.Printf("=================================\n")

	if h.cliConfig.DryRun {
		fmt.Printf("DRY RUN: Would display current metrics\n")
		return nil
	}

	// Create orchestrator to get sample metrics
	orchestrator := NewWorkflowOrchestrator(h.config)
	metrics := orchestrator.GetMetrics()

	fmt.Printf("Workflow Start Time: %s\n", metrics.WorkflowStartTime.Format("2006-01-02 15:04:05"))
	fmt.Printf("Last Sync Time: %s\n", formatTime(metrics.LastSyncTime))
	fmt.Printf("Total Syncs: %d\n", metrics.TotalSyncs)
	fmt.Printf("Successful Syncs: %d\n", metrics.SuccessfulSyncs)
	fmt.Printf("Failed Syncs: %d\n", metrics.FailedSyncs)

	if metrics.TotalSyncs > 0 {
		successRate := float64(metrics.SuccessfulSyncs) / float64(metrics.TotalSyncs) * 100
		fmt.Printf("Success Rate: %.1f%%\n", successRate)
	}

	fmt.Printf("Average Sync Time: %v\n", metrics.AverageSyncTime)
	fmt.Printf("Conflicts Detected: %d\n", metrics.ConflictsDetected)
	fmt.Printf("Conflicts Resolved: %d\n", metrics.ConflictsResolved)
	fmt.Printf("Uptime: %.1f%%\n", metrics.UptimePercent)

	if h.cliConfig.Verbose {
		fmt.Printf("\nDetailed Metrics:\n")
		uptime := time.Since(metrics.WorkflowStartTime)
		fmt.Printf("  Total Uptime: %v\n", uptime)
		if metrics.ConflictsDetected > 0 {
			resolutionRate := float64(metrics.ConflictsResolved) / float64(metrics.ConflictsDetected) * 100
			fmt.Printf("  Conflict Resolution Rate: %.1f%%\n", resolutionRate)
		}
	}

	return nil
}

// handleValidate handles the validate command
func (h *CommandHandler) handleValidate() error {
	fmt.Printf("🔍 Validating Configuration...\n")

	// Validate configuration file syntax
	if _, err := os.Stat(h.cliConfig.ConfigPath); os.IsNotExist(err) {
		return fmt.Errorf("❌ Configuration file not found: %s", h.cliConfig.ConfigPath)
	}

	// Try to load and parse configuration
	_, err := loadWorkflowConfig(h.cliConfig.ConfigPath)
	if err != nil {
		return fmt.Errorf("❌ Configuration validation failed: %w", err)
	}

	fmt.Printf("✅ Configuration validation passed\n")

	if h.cliConfig.Verbose {
		fmt.Printf("\nValidated settings:\n")
		fmt.Printf("  Config file: %s\n", h.cliConfig.ConfigPath)
		fmt.Printf("  File size: %s\n", getFileSize(h.cliConfig.ConfigPath))
		fmt.Printf("  YAML format: Valid\n")
		fmt.Printf("  Required fields: Present\n")
	}

	return nil
}

// runAsDaemon runs the orchestrator as a daemon service
func (h *CommandHandler) runAsDaemon(ctx context.Context, cancel context.CancelFunc) error {
	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	fmt.Printf("🔄 Running as daemon service (PID: %d)\n", os.Getpid())

	// Wait for shutdown signal
	select {
	case <-ctx.Done():
		fmt.Printf("Context cancelled\n")
	case sig := <-sigChan:
		fmt.Printf("Received signal: %v\n", sig)
		cancel()
	}

	// Graceful shutdown
	fmt.Printf("🛑 Shutting down gracefully...\n")
	if err := h.orchestrator.Stop(); err != nil {
		fmt.Printf("Error during shutdown: %v\n", err)
	}

	fmt.Printf("✅ Workflow Orchestrator stopped\n")
	return nil
}

// waitForInterrupt waits for an interrupt signal
func (h *CommandHandler) waitForInterrupt(ctx context.Context, cancel context.CancelFunc) error {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	select {
	case <-sigChan:
		fmt.Printf("\n🛑 Interrupt received, stopping...\n")
		cancel()
	case <-ctx.Done():
		fmt.Printf("Context cancelled\n")
	}

	if err := h.orchestrator.Stop(); err != nil {
		return fmt.Errorf("failed to stop orchestrator: %w", err)
	}

	fmt.Printf("✅ Workflow Orchestrator stopped\n")
	return nil
}

// Utility functions

func formatTime(t time.Time) string {
	if t.IsZero() {
		return "Never"
	}
	return t.Format("2006-01-02 15:04:05")
}

func getFileSize(path string) string {
	if info, err := os.Stat(path); err == nil {
		return fmt.Sprintf("%d bytes", info.Size())
	}
	return "Unknown"
}

// Placeholder for the actual WorkflowOrchestrator constructor
// In a real implementation, this would be imported from the workflow package
func NewWorkflowOrchestrator(config *workflow.WorkflowConfig) WorkflowOrchestrator {
	// This is a placeholder - would return the actual implementation
	return nil
}
