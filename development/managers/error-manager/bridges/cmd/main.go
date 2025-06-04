// Main program to start the real-time bridge
// Section 8.2 - Optimisation Surveillance Temps Réel
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"bridges"
)

func main() {
	fmt.Println("🚀 Starting Real-time Bridge for Section 8.2")
	fmt.Println("Optimisation Surveillance Temps Réel - plan-dev-v42")
	// Create bridge configuration with watch paths
	config := bridges.RealtimeBridgeConfig{
		HTTPPort:         8080,
		WatchPaths:       []string{"../../../scripts", "../../../development", "./test-files"},
		LogFilePath:      "./realtime_bridge.log",
		DebounceMs:       500,
		MaxEvents:        100,
		EnableFileWatch:  true,
		EnableHTTPServer: true,
	}

	// Create and start the bridge
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	bridge, err := bridges.NewRealtimeBridge(config)
	if err != nil {
		log.Fatalf("Failed to create realtime bridge: %v", err)
	}

	// Display watch paths
	for _, path := range config.WatchPaths {
		if _, err := os.Stat(path); err == nil {
			fmt.Printf("👁️  Watching: %s\n", path)
		} else {
			log.Printf("Warning: Watch path does not exist: %s", path)
		}
	}

	// Start bridge in background
	go func() {
		if err := bridge.Start(); err != nil {
			log.Printf("Bridge error: %v", err)
		}
	}()

	fmt.Printf("🌐 Bridge started on http://localhost:%d\n", config.HTTPPort)
	fmt.Println("📊 Health check: /health")
	fmt.Println("📋 Status: /status")
	fmt.Println("📡 Events: /events")
	fmt.Println("Press Ctrl+C to stop...")

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	<-sigChan
	fmt.Println("\n🛑 Stopping Real-time Bridge...")

	cancel()
	time.Sleep(1 * time.Second)
	fmt.Println("✅ Bridge stopped")
}
