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

	autonomy "advanced-autonomy-manager"
	"advanced-autonomy-manager/internal/config"
)

func main() {
	// Parse command line flags
	var (
		configPath = flag.String("config", "config.yaml", "Path to configuration file")
		logLevel   = flag.String("log-level", "info", "Log level (debug, info, warn, error)")
		version    = flag.Bool("version", false, "Show version information")
	)
	flag.Parse()

	if *version {
		fmt.Printf("AdvancedAutonomyManager v1.0.0 - 21st Manager in FMOUA Framework\n")
		fmt.Printf("Complete autonomy for maintenance and organization across 20 ecosystem managers\n")
		os.Exit(0)
	}

	// Load configuration
	autonomyConfig, err := config.LoadConfigFromFile(*configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Create logger (simple stdout logger for now)
	logger := &SimpleLogger{level: *logLevel}

	// Create the AdvancedAutonomyManager
	manager, err := autonomy.NewAdvancedAutonomyManager(autonomyConfig, logger)
	if err != nil {
		log.Fatalf("Failed to create AdvancedAutonomyManager: %v", err)
	}

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Initialize the manager
	logger.Info("Initializing AdvancedAutonomyManager - 21st Manager in FMOUA Framework")
	if err := manager.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize AdvancedAutonomyManager: %v", err)
	}

	logger.Info("AdvancedAutonomyManager initialized successfully")
	logger.Info("Starting autonomous operations across 20 ecosystem managers")

	// Start autonomous maintenance in background
	go func() {
		ticker := time.NewTicker(5 * time.Minute) // Autonomous maintenance every 5 minutes
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				logger.Debug("Triggering autonomous maintenance cycle")
				if result, err := manager.OrchestrateAutonomousMaintenance(ctx); err != nil {
					logger.WithError(err).Error("Autonomous maintenance failed")
				} else {
					logger.Info(fmt.Sprintf("Autonomous maintenance completed: %d decisions executed across %d managers", 
						result.DecisionsExecuted, len(result.ManagersAffected)))
				}
			}
		}
	}()

	// Start ecosystem health monitoring
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if health, err := manager.MonitorEcosystemHealth(ctx); err != nil {
					logger.WithError(err).Warn("Failed to monitor ecosystem health")
				} else {
					logger.Debug(fmt.Sprintf("Ecosystem health: %.2f%% (emergency: %s)", 
						health.OverallHealth*100, health.EmergencyStatus))
				}
			}
		}
	}()

	logger.Info("AdvancedAutonomyManager is now running - providing complete ecosystem autonomy")
	logger.Info("Press Ctrl+C to shutdown gracefully")

	// Wait for shutdown signal
	<-sigChan
	logger.Info("Shutdown signal received, starting graceful shutdown...")

	// Perform graceful shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	if err := manager.Cleanup(); err != nil {
		logger.WithError(err).Error("Error during cleanup")
	} else {
		logger.Info("AdvancedAutonomyManager shutdown completed successfully")
	}

	// Cancel the main context
	cancel()

	select {
	case <-shutdownCtx.Done():
		logger.Warn("Shutdown timeout exceeded")
		os.Exit(1)
	default:
		logger.Info("Goodbye!")
		os.Exit(0)
	}
}

// SimpleLogger is a basic logger implementation
type SimpleLogger struct {
	level string
}

func (l *SimpleLogger) Info(msg string) {
	log.Printf("[INFO] %s", msg)
}

func (l *SimpleLogger) Debug(msg string) {
	if l.level == "debug" {
		log.Printf("[DEBUG] %s", msg)
	}
}

func (l *SimpleLogger) Warn(msg string) {
	log.Printf("[WARN] %s", msg)
}

func (l *SimpleLogger) Error(msg string) {
	log.Printf("[ERROR] %s", msg)
}

func (l *SimpleLogger) WithError(err error) LoggerWithError {
	return &LoggerWithErrorImpl{logger: l, err: err}
}

type LoggerWithError interface {
	Error(msg string)
	Warn(msg string)
}

type LoggerWithErrorImpl struct {
	logger *SimpleLogger
	err    error
}

func (l *LoggerWithErrorImpl) Error(msg string) {
	log.Printf("[ERROR] %s: %v", msg, l.err)
}

func (l *LoggerWithErrorImpl) Warn(msg string) {
	log.Printf("[WARN] %s: %v", msg, l.err)
}
	if err := manager.Start(); err != nil {
		log.Fatalf("Failed to start manager: %v", err)
	}

	// Attendre un signal d'arrêt
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh

	// Arrêter le manager
	if err := manager.Stop(); err != nil {
		log.Printf("Error stopping manager: %v", err)
	}

	// Nettoyer les ressources
	if err := manager.Cleanup(); err != nil {
		log.Printf("Error cleaning up manager: %v", err)
	}

	fmt.Println("AdvancedAutonomyManager stopped gracefully")
}
