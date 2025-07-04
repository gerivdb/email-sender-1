// Simple persistent bridge for PowerShell integration testing
// Section 8.2 - Optimisation Surveillance Temps Réel
package main

import (
	"fmt"
	"log"

	"github.com/gerivdb/email-sender-1/development/managers/bridges"
)

func RunPersistentBridge() {
	fmt.Println("🚀 Persistent Real-time Bridge for PowerShell Integration")
	fmt.Println("Section 8.2 - Optimisation Surveillance Temps Réel")
	// Create a simple configuration for testing
	config := bridges.RealtimeBridgeConfig{
		HTTPPort:         8080,
		WatchPaths:       []string{".", "../../../scripts"},
		LogFilePath:      "./integration_test.log",
		DebounceMs:       500,
		MaxEvents:        50,
		EnableFileWatch:  true,
		EnableHTTPServer: true,
	}

	bridge, err := bridges.NewRealtimeBridge(config)
	if err != nil {
		log.Fatalf("Failed to create bridge: %v", err)
	}

	fmt.Printf("🌐 Starting bridge on port %d...\n", config.HTTPPort)
	fmt.Println("📊 Health: http://localhost:8080/health")
	fmt.Println("📋 Status: http://localhost:8080/status")
	fmt.Println("📡 Events: http://localhost:8080/events")
	fmt.Println("🛑 The bridge will run until process is terminated")

	// Run bridge indefinitely
	if err := bridge.Start(); err != nil {
		log.Fatalf("Bridge failed: %v", err)
	}

	// Keep the main goroutine alive
	select {}
}
