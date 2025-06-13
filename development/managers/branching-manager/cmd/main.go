package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	// Parse command line flags
	configPath := flag.String("config", "./config/branching_config.yaml", "Path to configuration file")
	flag.Parse()

	// Create and initialize the branching manager
	manager, err := NewBranchingManager(*configPath)
	if err != nil {
		log.Fatalf("Failed to create branching manager: %v", err)
	}

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start the manager
	if err := manager.Start(ctx); err != nil {
		log.Fatalf("Failed to start branching manager: %v", err)
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	fmt.Println("BranchingManager is running...")
	fmt.Println("Press Ctrl+C to stop")

	// Wait for shutdown signal
	<-sigChan
	fmt.Println("\nReceived shutdown signal, stopping...")

	// Cancel context to signal shutdown
	cancel()

	// Stop the manager
	if err := manager.Stop(); err != nil {
		log.Printf("Error stopping branching manager: %v", err)
	}

	fmt.Println("BranchingManager stopped successfully")
}
