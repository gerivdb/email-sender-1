// Framework de Maintenance et Organisation Ultra-Avancé (FMOUA)
// Main orchestrator implementing the specifications from plan-dev-v53
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/cobra"
	"go.uber.org/zap"

	"email_sender/pkg/fmoua/ai"
	"email_sender/pkg/fmoua/core"
	"email_sender/pkg/fmoua/integration"
	"email_sender/pkg/fmoua/interfaces"
)

// FMOUAFramework represents the main Framework instance
type FMOUAFramework struct {
	config         *core.FMOUAConfig
	orchestrator   *core.MaintenanceOrchestrator
	integrationHub interfaces.ManagerHub
	aiEngine       interfaces.IntelligenceEngine
	logger         *zap.Logger
	ctx            context.Context
	cancel         context.CancelFunc
}

// NewFMOUAFramework creates a new instance following DRY, KISS, SOLID principles
func NewFMOUAFramework(configPath string) (*FMOUAFramework, error) {
	// Initialize context
	ctx, cancel := context.WithCancel(context.Background())

	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize logger: %w", err)
	}

	// Load configuration
	config, err := core.LoadFMOUAConfig(configPath)
	if err != nil {
		logger.Error("Failed to load configuration", zap.Error(err))
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	// Initialize Integration Hub for 17 existing managers
	integrationHub, err := integration.NewManagerHub(&config.ManagersConfig, logger)
	if err != nil {
		logger.Error("Failed to initialize manager hub", zap.Error(err))
		return nil, fmt.Errorf("failed to initialize manager hub: %w", err)
	}

	// Initialize AI Engine (AI-First principle)
	aiEngine, err := ai.NewIntelligenceEngine(&config.AIConfig, logger)
	if err != nil {
		logger.Error("Failed to initialize AI engine", zap.Error(err))
		return nil, fmt.Errorf("failed to initialize AI engine: %w", err)
	}

	// Initialize Main Orchestrator
	orchestrator, err := core.NewMaintenanceOrchestrator(config, integrationHub, aiEngine, logger)
	if err != nil {
		logger.Error("Failed to initialize orchestrator", zap.Error(err))
		return nil, fmt.Errorf("failed to initialize orchestrator: %w", err)
	}

	return &FMOUAFramework{
		config:         config,
		orchestrator:   orchestrator,
		integrationHub: integrationHub,
		aiEngine:       aiEngine,
		logger:         logger,
		ctx:            ctx,
		cancel:         cancel,
	}, nil
}

// Start initializes and starts the FMOUA framework
func (f *FMOUAFramework) Start() error {
	f.logger.Info("Starting FMOUA Framework",
		zap.String("version", "1.0"),
		zap.String("objective", "AI-powered repository maintenance with <100ms latency"))

	startTime := time.Now()

	// Start Integration Hub (connect to 17 existing managers)
	if err := f.integrationHub.Start(f.ctx); err != nil {
		return fmt.Errorf("failed to start integration hub: %w", err)
	}

	// Start AI Engine
	if err := f.aiEngine.Start(f.ctx); err != nil {
		return fmt.Errorf("failed to start AI engine: %w", err)
	}

	// Start Main Orchestrator
	if err := f.orchestrator.Start(f.ctx); err != nil {
		return fmt.Errorf("failed to start orchestrator: %w", err)
	}

	startupTime := time.Since(startTime)
	f.logger.Info("FMOUA Framework started successfully",
		zap.Duration("startup_time", startupTime),
		zap.String("compliance", "<100ms latency target"))

	return nil
}

// Stop gracefully shuts down the FMOUA framework
func (f *FMOUAFramework) Stop() error {
	f.logger.Info("Stopping FMOUA Framework")

	f.cancel()

	// Stop components in reverse order
	if err := f.orchestrator.Stop(); err != nil {
		f.logger.Error("Failed to stop orchestrator", zap.Error(err))
	}

	if err := f.aiEngine.Stop(); err != nil {
		f.logger.Error("Failed to stop AI engine", zap.Error(err))
	}

	if err := f.integrationHub.Stop(); err != nil {
		f.logger.Error("Failed to stop integration hub", zap.Error(err))
	}

	f.logger.Info("FMOUA Framework stopped")
	return nil
}

func main() {
	var configPath string
	var verbose bool

	// Root command
	rootCmd := &cobra.Command{
		Use:   "fmoua",
		Short: "Framework de Maintenance et Organisation Ultra-Avancé",
		Long: `FMOUA - AI-powered repository maintenance and organization framework
Implements DRY, KISS, SOLID principles with <100ms latency target.
Integrates 17 existing managers with QDrant vectorization.`,
		Version: "1.0.0",
	}

	// Global flags
	rootCmd.PersistentFlags().StringVarP(&configPath, "config", "c", "./config/fmoua.yaml", "Configuration file path")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Verbose output")

	// Organize command
	organizeCmd := &cobra.Command{
		Use:   "organize [repository_path]",
		Short: "AI-powered repository organization",
		Long:  "Analyze and reorganize repository structure using AI decision engine",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			repoPath := args[0]

			framework, err := NewFMOUAFramework(configPath)
			if err != nil {
				return fmt.Errorf("failed to initialize FMOUA: %w", err)
			}
			defer framework.Stop()

			if err := framework.Start(); err != nil {
				return fmt.Errorf("failed to start FMOUA: %w", err)
			}

			decision, err := framework.orchestrator.ExecuteOrganization(repoPath)
			if err != nil {
				return fmt.Errorf("organization failed: %w", err)
			}

			fmt.Printf("Organization completed successfully:\n")
			fmt.Printf("  Confidence: %.2f\n", decision.Confidence)
			fmt.Printf("  Recommendation: %s\n", decision.Recommendation)
			fmt.Printf("  Actions: %d\n", len(decision.Actions))
			fmt.Printf("  Execution time: %v\n", decision.ExecutionTime)

			return nil
		},
	}

	// Cleanup command
	cleanupCmd := &cobra.Command{
		Use:   "cleanup [level]",
		Short: "Multi-level intelligent cleanup",
		Long:  "Perform cleanup operations with AI analysis (levels 1-3)",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			level := 1
			if args[0] == "2" {
				level = 2
			} else if args[0] == "3" {
				level = 3
			}

			framework, err := NewFMOUAFramework(configPath)
			if err != nil {
				return fmt.Errorf("failed to initialize FMOUA: %w", err)
			}
			defer framework.Stop()

			if err := framework.Start(); err != nil {
				return fmt.Errorf("failed to start FMOUA: %w", err)
			}

			targets := []string{"temp_files", "cache", "logs"}
			if level > 1 {
				targets = append(targets, "duplicate_files", "unused_imports")
			}
			if level > 2 {
				targets = append(targets, "dead_code", "obsolete_files")
			}

			err = framework.orchestrator.ExecuteCleanup(level, targets)
			if err != nil {
				return fmt.Errorf("cleanup failed: %w", err)
			}

			fmt.Printf("Cleanup level %d completed successfully\n", level)
			return nil
		},
	}

	// Health command
	healthCmd := &cobra.Command{
		Use:   "health",
		Short: "Check system health",
		Long:  "Get health status of all integrated managers and AI engine",
		RunE: func(cmd *cobra.Command, args []string) error {
			framework, err := NewFMOUAFramework(configPath)
			if err != nil {
				return fmt.Errorf("failed to initialize FMOUA: %w", err)
			}
			defer framework.Stop()

			if err := framework.Start(); err != nil {
				return fmt.Errorf("failed to start FMOUA: %w", err)
			}

			health := framework.orchestrator.GetHealth()

			fmt.Printf("FMOUA System Health Status:\n")
			if overall, ok := health["overall_status"].(map[string]interface{}); ok {
				fmt.Printf("  Overall Status: %v\n", overall["status"])
				fmt.Printf("  Active Managers: %v/%v\n", overall["active_managers"], overall["total_managers"])
				fmt.Printf("  AI Enabled: %v\n", overall["ai_enabled"])
			}

			if managers, ok := health["managers"].(map[string]interfaces.HealthStatus); ok {
				fmt.Printf("\nManagers Status:\n")
				for name, status := range managers {
					healthStatus := "❌"
					if status.IsHealthy {
						healthStatus = "✅"
					}
					fmt.Printf("  %s %s (Response: %v)\n", healthStatus, name, status.ResponseTime)
				}
			}

			return nil
		},
	}

	// Server command
	serverCmd := &cobra.Command{
		Use:   "server",
		Short: "Start FMOUA server mode",
		Long:  "Start FMOUA in server mode for continuous monitoring and operations",
		RunE: func(cmd *cobra.Command, args []string) error {
			framework, err := NewFMOUAFramework(configPath)
			if err != nil {
				return fmt.Errorf("failed to initialize FMOUA: %w", err)
			}

			if err := framework.Start(); err != nil {
				return fmt.Errorf("failed to start FMOUA: %w", err)
			}

			fmt.Println("FMOUA Server started successfully")
			fmt.Println("Press Ctrl+C to stop...")

			// Keep running until interrupted
			select {}
		},
	}

	// Add commands
	rootCmd.AddCommand(organizeCmd)
	rootCmd.AddCommand(cleanupCmd)
	rootCmd.AddCommand(healthCmd)
	rootCmd.AddCommand(serverCmd)

	// Execute
	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

// getDefaultConfigPath returns the default configuration path
func getDefaultConfigPath() string {
	if configPath := os.Getenv("FMOUA_CONFIG"); configPath != "" {
		return configPath
	}

	// Try to find config in common locations
	possiblePaths := []string{
		"./config/fmoua.yaml",
		"./fmoua.yaml",
		"/etc/fmoua/fmoua.yaml",
		filepath.Join(os.Getenv("HOME"), ".config", "fmoua", "fmoua.yaml"),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	// Return default if none found
	return "./config/fmoua.yaml"
}
