// Main simplified version of the Advanced Autonomy Manager
// This version focuses on the core architecture and discovery system
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"advanced-autonomy-manager/interfaces"
	"advanced-autonomy-manager/internal/config"
	"advanced-autonomy-manager/internal/discovery"
)

// SimpleLogger implements the interfaces.Logger interface
type SimpleLogger struct{}

func (l *SimpleLogger) Debug(msg string, fields ...interface{}) {
	log.Printf("[DEBUG] %s %v", msg, fields)
}

func (l *SimpleLogger) Info(msg string, fields ...interface{}) {
	log.Printf("[INFO] %s %v", msg, fields)
}

func (l *SimpleLogger) Warn(msg string, fields ...interface{}) {
	log.Printf("[WARN] %s %v", msg, fields)
}

func (l *SimpleLogger) Error(msg string, fields ...interface{}) {
	log.Printf("[ERROR] %s %v", msg, fields)
}

func (l *SimpleLogger) Fatal(msg string, fields ...interface{}) {
	log.Fatalf("[FATAL] %s %v", msg, fields)
}

func (l *SimpleLogger) With(fields ...interface{}) interfaces.Logger {
	return l
}

func main() {
	logger := &SimpleLogger{}
	logger.Info("Starting Advanced Autonomy Manager (21st FMOUA Manager)")
	// Load configuration
	cfg, err := config.LoadConfigFromFile("config.yaml")
	if err != nil {
		logger.Fatal("Failed to load configuration", err)
	}

	logger.Info("Configuration loaded successfully")

	// Initialize discovery service
	discoveryService, err := discovery.NewManagerDiscoveryService(cfg.DiscoveryConfig, logger)
	if err != nil {
		logger.Fatal("Failed to create discovery service", err)
	}

	logger.Info("Discovery service initialized")

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Discover managers
	logger.Info("Starting manager discovery...")
	managers, err := discoveryService.DiscoverAllManagers(ctx)
	if err != nil {
		logger.Error("Manager discovery failed", err)
	} else {
		logger.Info(fmt.Sprintf("Discovered %d managers", len(managers)))
		
		// List discovered managers
		for name, manager := range managers {
			health := manager.GetHealth()
			logger.Info(fmt.Sprintf("Manager: %s, Health: %v, Score: %.2f", 
				name, health.IsHealthy, health.Score))
		}
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	logger.Info("Advanced Autonomy Manager is running...")
	logger.Info("Discovery and coordination layer active")
	logger.Info("Press Ctrl+C to stop")

	// Run main loop
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-sigChan:
			logger.Info("Shutdown signal received")
			cancel()
			
			// Cleanup discovered managers
			for name, manager := range managers {
				logger.Info(fmt.Sprintf("Stopping manager: %s", name))
				if err := manager.Stop(ctx); err != nil {
					logger.Error(fmt.Sprintf("Failed to stop manager %s", name), err)
				}
			}
			
			logger.Info("Advanced Autonomy Manager stopped")
			return

		case <-ticker.C:
			// Periodic health check
			logger.Info("Performing periodic ecosystem health check...")
			healthyCount := 0
			totalCount := len(managers)
			
			for name, manager := range managers {
				health := manager.GetHealth()
				if health.IsHealthy {
					healthyCount++
				} else {
					logger.Warn(fmt.Sprintf("Manager %s unhealthy: %s", name, health.Message))
				}
			}
			
			healthRatio := float64(healthyCount) / float64(totalCount) * 100
			logger.Info(fmt.Sprintf("Ecosystem health: %.1f%% (%d/%d managers healthy)", 
				healthRatio, healthyCount, totalCount))

		case <-ctx.Done():
			logger.Info("Context cancelled, shutting down...")
			return
		}
	}
}
