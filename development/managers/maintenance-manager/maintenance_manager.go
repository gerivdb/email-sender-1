package maintenance_manager

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"

	"EMAIL_SENDER_1/maintenance-manager/src/ai"
	"EMAIL_SENDER_1/maintenance-manager/src/cleanup"
	"EMAIL_SENDER_1/maintenance-manager/src/core"
	"EMAIL_SENDER_1/maintenance-manager/src/integration"
	"EMAIL_SENDER_1/maintenance-manager/src/templates"
	"EMAIL_SENDER_1/maintenance-manager/src/vector"
)

var (
	configPath  string
	verboseMode bool
	dryRun      bool
)

// MaintenanceManager represents the main application structure
type MaintenanceManager struct {
	logger         *zap.Logger
	config         *core.Config
	integrationHub *integration.IntegrationHub
	goGenEngine    *templates.GoGenEngine
	vectorDB       *vector.QdrantManager
	aiAnalyzer     *ai.AIAnalyzer
	cleanupMgr     *cleanup.CleanupManager
	ctx            context.Context
	cancel         context.CancelFunc
}

// NewMaintenanceManager creates a new maintenance manager instance
func NewMaintenanceManager() (*MaintenanceManager, error) {
	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &MaintenanceManager{
		logger: logger,
		ctx:    ctx,
		cancel: cancel,
	}, nil
}

// Initialize initializes all components of the maintenance manager
func (mm *MaintenanceManager) Initialize() error {
	mm.logger.Info("Initializing Maintenance Manager")

	// Load configuration
	if err := mm.loadConfig(); err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Initialize IntegrationHub for manager coordination
	hub, err := integration.NewIntegrationHub(mm.logger, mm.config.ManagerIntegration)
	if err != nil {
		return fmt.Errorf("failed to create integration hub: %w", err)
	}
	mm.integrationHub = hub

	// Initialize IntegrationHub and discover managers
	if err := mm.integrationHub.Initialize(mm.ctx); err != nil {
		return fmt.Errorf("failed to initialize integration hub: %w", err)
	}

	// Initialize GoGen template engine
	engine, err := templates.NewGoGenEngine(mm.logger, mm.config.AIConfig)
	if err != nil {
		return fmt.Errorf("failed to create GoGen engine: %w", err)
	}
	mm.goGenEngine = engine

	// Initialize vector database if enabled
	if mm.config.VectorDB.Enabled {
		vectorDB, err := vector.NewQdrantManager(mm.logger, mm.config.VectorDB)
		if err != nil {
			mm.logger.Warn("Failed to initialize vector database", zap.Error(err))
		} else {
			mm.vectorDB = vectorDB
		}
	}

	// Initialize AI analyzer
	aiAnalyzer, err := ai.NewAIAnalyzer(mm.logger, mm.config.AIConfig, mm.vectorDB)
	if err != nil {
		return fmt.Errorf("failed to create AI analyzer: %w", err)
	}
	mm.aiAnalyzer = aiAnalyzer

	// Initialize cleanup manager
	cleanupMgr, err := cleanup.NewCleanupManager(mm.logger, mm.config)
	if err != nil {
		return fmt.Errorf("failed to create cleanup manager: %w", err)
	}
	mm.cleanupMgr = cleanupMgr

	mm.logger.Info("Maintenance Manager initialized successfully")
	return nil
}

// loadConfig loads the configuration from file
func (mm *MaintenanceManager) loadConfig() error {
	viper.SetConfigName("maintenance-config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("../config")
	viper.AddConfigPath("../../config")

	if configPath != "" {
		viper.SetConfigFile(configPath)
	}

	if err := viper.ReadInConfig(); err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	config := &core.Config{}
	if err := viper.Unmarshal(config); err != nil {
		return fmt.Errorf("failed to unmarshal config: %w", err)
	}

	mm.config = config
	mm.logger.Info("Configuration loaded", zap.String("config_file", viper.ConfigFileUsed()))
	return nil
}

// Shutdown gracefully shuts down the maintenance manager
func (mm *MaintenanceManager) Shutdown() error {
	mm.logger.Info("Shutting down Maintenance Manager")

	if mm.cancel != nil {
		mm.cancel()
	}

	if mm.integrationHub != nil {
		if err := mm.integrationHub.Shutdown(); err != nil {
			mm.logger.Error("Failed to shutdown integration hub", zap.Error(err))
		}
	}

	if mm.vectorDB != nil {
		if err := mm.vectorDB.Close(); err != nil {
			mm.logger.Error("Failed to close vector database", zap.Error(err))
		}
	}

	mm.logger.Sync()
	return nil
}

// CLI Commands

var rootCmd = &cobra.Command{
	Use:   "maintenance-manager",
	Short: "Advanced maintenance and organization framework",
	Long: `
Framework de Maintenance et Organisation Ultra-Avancé (FMOUA)
An intelligent maintenance system with AI integration and manager coordination.
`,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		if verboseMode {
			// Switch to development logger for verbose output
			logger, _ := zap.NewDevelopment()
			log.SetOutput(os.Stdout)
		}
	},
}

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize the maintenance manager",
	RunE: func(cmd *cobra.Command, args []string) error {
		mm, err := NewMaintenanceManager()
		if err != nil {
			return err
		}
		defer mm.Shutdown()

		return mm.Initialize()
	},
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check the status of all managers and components",
	RunE: func(cmd *cobra.Command, args []string) error {
		mm, err := NewMaintenanceManager()
		if err != nil {
			return err
		}
		defer mm.Shutdown()

		if err := mm.Initialize(); err != nil {
			return err
		}

		// Check integration hub status
		status := mm.integrationHub.GetStatus()
		fmt.Printf("Integration Hub Status:\n")
		fmt.Printf("  Registered Managers: %d\n", status.RegisteredManagers)
		fmt.Printf("  Active Managers: %d\n", status.ActiveManagers)
		fmt.Printf("  Last Health Check: %s\n", status.LastHealthCheck.Format("2006-01-02 15:04:05"))

		// Check individual manager health
		healthStatus, err := mm.integrationHub.CheckAllManagersHealth(mm.ctx)
		if err != nil {
			return fmt.Errorf("failed to check manager health: %w", err)
		}

		fmt.Printf("\nManager Health Status:\n")
		for name, healthy := range healthStatus {
			status := "❌ UNHEALTHY"
			if healthy {
				status = "✅ HEALTHY"
			}
			fmt.Printf("  %s: %s\n", name, status)
		}

		return nil
	},
}

var generateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate code using GoGen templates",
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) < 1 {
			return fmt.Errorf("template name required")
		}

		templateName := args[0]

		mm, err := NewMaintenanceManager()
		if err != nil {
			return err
		}
		defer mm.Shutdown()

		if err := mm.Initialize(); err != nil {
			return err
		}

		// Get template variables from flags
		variables := map[string]interface{}{
			"dry_run": dryRun,
		}

		if len(args) > 1 {
			outputPath := args[1]
			variables["output_path"] = outputPath
		}

		// Generate using GoGen engine
		result, err := mm.goGenEngine.Generate(mm.ctx, templateName, variables)
		if err != nil {
			return fmt.Errorf("failed to generate template: %w", err)
		}

		fmt.Printf("Generated %d files:\n", len(result.GeneratedFiles))
		for _, file := range result.GeneratedFiles {
			fmt.Printf("  ✅ %s\n", file)
		}

		if len(result.Errors) > 0 {
			fmt.Printf("\nErrors encountered:\n")
			for _, err := range result.Errors {
				fmt.Printf("  ❌ %s\n", err)
			}
		}

		return nil
	},
}

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Run intelligent cleanup operations",
	RunE: func(cmd *cobra.Command, args []string) error {
		mm, err := NewMaintenanceManager()
		if err != nil {
			return err
		}
		defer mm.Shutdown()

		if err := mm.Initialize(); err != nil {
			return err
		}

		// Run cleanup operations
		result, err := mm.cleanupMgr.RunCleanup(mm.ctx, cleanup.CleanupOptions{
			DryRun:    dryRun,
			Recursive: true,
			MaxDepth:  10,
		})
		if err != nil {
			return fmt.Errorf("cleanup failed: %w", err)
		}

		fmt.Printf("Cleanup completed:\n")
		fmt.Printf("  Files processed: %d\n", result.FilesProcessed)
		fmt.Printf("  Files moved: %d\n", result.FilesMoved)
		fmt.Printf("  Directories created: %d\n", result.DirectoriesCreated)
		fmt.Printf("  Errors: %d\n", len(result.Errors))

		if len(result.Errors) > 0 {
			fmt.Printf("\nErrors:\n")
			for _, err := range result.Errors {
				fmt.Printf("  ❌ %s\n", err)
			}
		}

		return nil
	},
}

var analyzeCmd = &cobra.Command{
	Use:   "analyze",
	Short: "Run AI-powered analysis of the project",
	RunE: func(cmd *cobra.Command, args []string) error {
		mm, err := NewMaintenanceManager()
		if err != nil {
			return err
		}
		defer mm.Shutdown()

		if err := mm.Initialize(); err != nil {
			return err
		}

		// Run AI analysis
		analysisPath := "."
		if len(args) > 0 {
			analysisPath = args[0]
		}

		result, err := mm.aiAnalyzer.AnalyzePath(mm.ctx, analysisPath)
		if err != nil {
			return fmt.Errorf("analysis failed: %w", err)
		}

		fmt.Printf("AI Analysis Results:\n")
		fmt.Printf("  Files analyzed: %d\n", result.FilesAnalyzed)
		fmt.Printf("  Patterns detected: %d\n", len(result.Patterns))
		fmt.Printf("  Recommendations: %d\n", len(result.Recommendations))

		if len(result.Patterns) > 0 {
			fmt.Printf("\nDetected Patterns:\n")
			for _, pattern := range result.Patterns {
				fmt.Printf("  📊 %s (confidence: %.2f)\n", pattern.Name, pattern.Confidence)
			}
		}

		if len(result.Recommendations) > 0 {
			fmt.Printf("\nRecommendations:\n")
			for _, rec := range result.Recommendations {
				fmt.Printf("  💡 %s (priority: %s)\n", rec.Description, rec.Priority)
			}
		}

		return nil
	},
}

func init() {
	// Global flags
	rootCmd.PersistentFlags().StringVarP(&configPath, "config", "c", "", "Path to configuration file")
	rootCmd.PersistentFlags().BoolVarP(&verboseMode, "verbose", "v", false, "Enable verbose logging")
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", false, "Run in dry-run mode (no actual changes)")

	// Add subcommands
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(generateCmd)
	rootCmd.AddCommand(cleanupCmd)
	rootCmd.AddCommand(analyzeCmd)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
