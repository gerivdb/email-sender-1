package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/development"
)

func main() {
	fmt.Println("🚀 Starting Advanced 8-Level Branching Framework...")

	// Create a new branching manager
	config := &development.BranchingConfig{
		DefaultSessionDuration: 3600,  // 1 hour in seconds
		MaxSessionDuration:     86400, // 24 hours in seconds
		SessionNamingPattern:   "session-{timestamp}",
		AutoArchiveEnabled:     true,
		EventQueueSize:         1000,
		GitHooksEnabled:        true,
		AutoBranchingEnabled:   true,
	}

	manager := development.NewBranchingManagerImpl(config)

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		fmt.Println("\n🛑 Shutting down gracefully...")
		cancel()
	}()

	// Start the branching manager
	if err := manager.Start(ctx); err != nil {
		log.Fatalf("Failed to start branching manager: %v", err)
	}

	fmt.Println("✅ Branching Framework started successfully!")
	fmt.Println("Press Ctrl+C to stop...")

	// Wait for shutdown signal
	<-ctx.Done()

	// Stop the manager
	if err := manager.Stop(); err != nil {
		log.Printf("Error stopping manager: %v", err)
	}

	fmt.Println("👋 Branching Framework stopped.")
}
