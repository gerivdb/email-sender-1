package test

import (
	"fmt"
	"log"
	"os"
)

func RunTests() {
	fmt.Println("🔧 EMAIL_SENDER_1 Orchestrator Test")
	fmt.Printf("Arguments: %v\n", os.Args)

	if len(os.Args) < 2 {
		fmt.Println("Usage: go run . <config_file>")
		os.Exit(1)
	}

	configPath := os.Args[1]
	fmt.Printf("Loading config from: %s\n", configPath)

	// Test loading configuration
	config, err := LoadOrchestratorConfig(configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	fmt.Printf("✅ Configuration loaded successfully!\n")
	fmt.Printf("Project Root: %s\n", config.ProjectRoot)
	fmt.Printf("Algorithms Path: %s\n", config.AlgorithmsPath)
	fmt.Printf("Number of algorithms: %d\n", len(config.Algorithms))

	for i, alg := range config.Algorithms {
		fmt.Printf("  %d. %s (%s) - Enabled: %t\n", i+1, alg.Name, alg.ID, alg.Enabled)
	}
}
