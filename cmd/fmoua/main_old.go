// Framework de Maintenance et Organisation Ultra-Avancé (FMOUA)
// Main orchestrator implementing the specifications from plan-dev-v53
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"

	"email_sender/pkg/fmoua/core"
	"email_sender/pkg/fmoua/integration"
	"email_sender/pkg/fmoua/ai"
	"email_sender/pkg/fmoua/interfaces"
)

// FMOUAFramework represents the main Framework instance
type FMOUAFramework struct {	config           *core.FMOUAConfig
	orchestrator     *core.MaintenanceOrchestrator
	integrationHub   interfaces.ManagerHub
	aiEngine         interfaces.IntelligenceEngine
	logger           *zap.Logger
	ctx              context.Context
	cancel           context.CancelFunc
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
	
	startupDuration := time.Since(startTime)
	f.logger.Info("FMOUA Framework started successfully",
		zap.Duration("startup_time", startupDuration),
		zap.Bool("under_100ms_target", startupDuration < 100*time.Millisecond))
	
	return nil
}

// Stop gracefully shuts down the framework
func (f *FMOUAFramework) Stop() error {
	f.logger.Info("Stopping FMOUA Framework")
	
	// Cancel context to signal shutdown
	f.cancel()
	
	// Stop components in reverse order
	if err := f.orchestrator.Stop(); err != nil {
		f.logger.Error("Error stopping orchestrator", zap.Error(err))
	}
	
	if err := f.aiEngine.Stop(); err != nil {
		f.logger.Error("Error stopping AI engine", zap.Error(err))
	}
	
	if err := f.integrationHub.Stop(); err != nil {
		f.logger.Error("Error stopping integration hub", zap.Error(err))
	}
	
	f.logger.Info("FMOUA Framework stopped")
	return f.logger.Sync()
}

// OrganizeRepository performs intelligent repository organization
func (f *FMOUAFramework) OrganizeRepository(repositoryPath string) (*core.OrganizationResult, error) {
	f.logger.Info("Starting repository organization", zap.String("path", repositoryPath))
	
	startTime := time.Now()
	
	// Use AI-First approach for organization decisions
	result, err := f.orchestrator.OrganizeWithAI(f.ctx, repositoryPath)
	if err != nil {
		f.logger.Error("Repository organization failed", zap.Error(err))
		return nil, fmt.Errorf("organization failed: %w", err)
	}
	
	duration := time.Since(startTime)
	f.logger.Info("Repository organization completed",
		zap.Duration("duration", duration),
		zap.Int("files_processed", result.FilesProcessed),
		zap.Float64("improvement_score", result.ImprovementScore),
		zap.Bool("under_100ms_target", duration < 100*time.Millisecond))
	
	return result, nil
}

// CleanupRepository performs intelligent cleanup with QDrant vectorization
func (f *FMOUAFramework) CleanupRepository(repositoryPath string, level int) (*core.CleanupResult, error) {
	f.logger.Info("Starting repository cleanup", 
		zap.String("path", repositoryPath),
		zap.Int("level", level))
	
	return f.orchestrator.PerformIntelligentCleanup(f.ctx, repositoryPath, level)
}

// GetHealthScore returns the current repository health assessment
func (f *FMOUAFramework) GetHealthScore(repositoryPath string) (*core.HealthScore, error) {
	return f.orchestrator.AssessRepositoryHealth(f.ctx, repositoryPath)
}

// GenerateWithGoGen performs code generation using native Go templates (replacing Hygen)
func (f *FMOUAFramework) GenerateWithGoGen(templateName string, variables map[string]interface{}) (*core.GenerationResult, error) {
	f.logger.Info("Starting GoGen generation", 
		zap.String("template", templateName),
		zap.Any("variables", variables))
	
	return f.orchestrator.GenerateWithGoGen(f.ctx, templateName, variables)
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "fmoua",
		Short: "Framework de Maintenance et Organisation Ultra-Avancé",
		Long: `Framework d'organisation intelligent avec IA intégrée pour la maintenance 
de repositories. Latence cible < 100ms, intégration avec 17 managers existants,
vectorisation QDrant et remplacement natif Hygen par GoGen.`,
		Run: func(cmd *cobra.Command, args []string) {
			configPath := viper.GetString("config")
			repositoryPath := viper.GetString("repository")
			
			framework, err := NewFMOUAFramework(configPath)
			if err != nil {
				log.Fatalf("Failed to initialize FMOUA: %v", err)
			}
			defer framework.Stop()
			
			if err := framework.Start(); err != nil {
				log.Fatalf("Failed to start FMOUA: %v", err)
			}
			
			// Perform organization if repository path is provided
			if repositoryPath != "" {
				result, err := framework.OrganizeRepository(repositoryPath)
				if err != nil {
					log.Fatalf("Organization failed: %v", err)
				}
				
				fmt.Printf("✅ Organization completed successfully!\n")
				fmt.Printf("📁 Files processed: %d\n", result.FilesProcessed)
				fmt.Printf("📊 Improvement score: %.2f%%\n", result.ImprovementScore*100)
				fmt.Printf("⚡ Duration: %v\n", result.Duration)
				fmt.Printf("🎯 Under 100ms target: %v\n", result.Duration < 100*time.Millisecond)
			}
		},
	}
	
	// Add subcommands
	rootCmd.AddCommand(
		newOrganizeCmd(),
		newCleanupCmd(),
		newHealthCmd(),
		newGenerateCmd(),
	)
	
	// Add flags
	rootCmd.PersistentFlags().StringP("config", "c", "./config/fmoua.yaml", "Configuration file path")
	rootCmd.PersistentFlags().StringP("repository", "r", ".", "Repository path to process")
	
	viper.BindPFlags(rootCmd.PersistentFlags())
	
	if err := rootCmd.Execute(); err != nil {
		log.Fatalf("Command execution failed: %v", err)
	}
}

// newOrganizeCmd creates the organize subcommand
func newOrganizeCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "organize [path]",
		Short: "Organize repository with AI intelligence",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			path := "."
			if len(args) > 0 {
				path = args[0]
			}
			
			framework, err := NewFMOUAFramework(viper.GetString("config"))
			if err != nil {
				log.Fatalf("Failed to initialize FMOUA: %v", err)
			}
			defer framework.Stop()
			
			if err := framework.Start(); err != nil {
				log.Fatalf("Failed to start FMOUA: %v", err)
			}
			
			result, err := framework.OrganizeRepository(path)
			if err != nil {
				log.Fatalf("Organization failed: %v", err)
			}
			
			fmt.Printf("✅ Organization completed: %d files processed in %v\n", 
				result.FilesProcessed, result.Duration)
		},
	}
}

// newCleanupCmd creates the cleanup subcommand
func newCleanupCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "cleanup [path]",
		Short: "Intelligent repository cleanup with QDrant vectorization",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			path := "."
			if len(args) > 0 {
				path = args[0]
			}
			
			level, _ := cmd.Flags().GetInt("level")
			
			framework, err := NewFMOUAFramework(viper.GetString("config"))
			if err != nil {
				log.Fatalf("Failed to initialize FMOUA: %v", err)
			}
			defer framework.Stop()
			
			if err := framework.Start(); err != nil {
				log.Fatalf("Failed to start FMOUA: %v", err)
			}
			
			result, err := framework.CleanupRepository(path, level)
			if err != nil {
				log.Fatalf("Cleanup failed: %v", err)
			}
			
			fmt.Printf("✅ Cleanup completed: %d files cleaned, %s freed\n", 
				result.FilesRemoved, result.SpaceFreed)
		},
	}
	
	cmd.Flags().IntP("level", "l", 1, "Cleanup level (1-3)")
	return cmd
}

// newHealthCmd creates the health assessment subcommand
func newHealthCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "health [path]",
		Short: "Assess repository health score",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			path := "."
			if len(args) > 0 {
				path = args[0]
			}
			
			framework, err := NewFMOUAFramework(viper.GetString("config"))
			if err != nil {
				log.Fatalf("Failed to initialize FMOUA: %v", err)
			}
			defer framework.Stop()
			
			if err := framework.Start(); err != nil {
				log.Fatalf("Failed to start FMOUA: %v", err)
			}
			
			health, err := framework.GetHealthScore(path)
			if err != nil {
				log.Fatalf("Health assessment failed: %v", err)
			}
			
			fmt.Printf("📊 Repository Health Score: %.2f%%\n", health.OverallScore*100)
			fmt.Printf("📁 Organization Score: %.2f%%\n", health.OrganizationScore*100)
			fmt.Printf("🧹 Cleanliness Score: %.2f%%\n", health.CleanlinessScore*100)
			fmt.Printf("⚡ Performance Score: %.2f%%\n", health.PerformanceScore*100)
		},
	}
}

// newGenerateCmd creates the GoGen generation subcommand
func newGenerateCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "generate [template]",
		Short: "Generate code using GoGen (native Hygen replacement)",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			template := args[0]
			name, _ := cmd.Flags().GetString("name")
			outputDir, _ := cmd.Flags().GetString("output")
			
			variables := map[string]interface{}{
				"name":       name,
				"outputDir":  outputDir,
				"timestamp":  time.Now().Format("2006-01-02 15:04:05"),
			}
			
			framework, err := NewFMOUAFramework(viper.GetString("config"))
			if err != nil {
				log.Fatalf("Failed to initialize FMOUA: %v", err)
			}
			defer framework.Stop()
			
			if err := framework.Start(); err != nil {
				log.Fatalf("Failed to start FMOUA: %v", err)
			}
			
			result, err := framework.GenerateWithGoGen(template, variables)
			if err != nil {
				log.Fatalf("Generation failed: %v", err)
			}
			
			fmt.Printf("✅ GoGen generation completed: %d files generated\n", result.FilesGenerated)
		},
	}
	
	cmd.Flags().StringP("name", "n", "", "Name for generation")
	cmd.Flags().StringP("output", "o", ".", "Output directory")
	return cmd
}
