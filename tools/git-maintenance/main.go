package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
)

type Config struct {
	DryRun         bool   `json:"dryRun"`
	Verbose        bool   `json:"verbose"`
	SyncStrategy   string `json:"syncStrategy"`
	MaxConcurrency int    `json:"maxConcurrency"`
	TimeoutSeconds int    `json:"timeoutSeconds"`
}

func main() {
	var (
		dryRun     = flag.Bool("dry-run", false, "Show what would be done without making changes")
		verbose    = flag.Bool("verbose", false, "Enable verbose output")
		strategy   = flag.String("strategy", "auto-ff", "Sync strategy: auto-ff, manual-review, force-sync")
		configFile = flag.String("config", "", "Path to configuration file")
		action     = flag.String("action", "sync", "Action to perform: sync, status, cleanup")
	)
	flag.Parse()

	config := Config{
		DryRun:         *dryRun,
		Verbose:        *verbose,
		SyncStrategy:   *strategy,
		MaxConcurrency: 4,
		TimeoutSeconds: 30,
	}

	if *configFile != "" {
		if err := loadConfig(*configFile, &config); err != nil {
			log.Printf("Warning: Could not load config file: %v", err)
		}
	}

	if config.Verbose {
		log.Printf("Starting git-maintenance with config: %+v", config)
	}

	switch *action {
	case "sync":
		if err := performSync(config); err != nil {
			log.Fatalf("Sync failed: %v", err)
		}
	case "status":
		if err := showStatus(config); err != nil {
			log.Fatalf("Status check failed: %v", err)
		}
	case "cleanup":
		if err := performCleanup(config); err != nil {
			log.Fatalf("Cleanup failed: %v", err)
		}
	default:
		log.Fatalf("Unknown action: %s", *action)
	}
}

func loadConfig(filename string, config *Config) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, config)
}

func performSync(config Config) error {
	fmt.Printf("🔄 Starting submodule synchronization (strategy: %s)\n", config.SyncStrategy)

	if config.DryRun {
		fmt.Println("🧪 DRY RUN MODE - No changes will be made")
	}

	sync := NewSubmoduleSync(config)
	return sync.Execute()
}

func showStatus(config Config) error {
	fmt.Println("📊 Checking submodule status...")

	sync := NewSubmoduleSync(config)
	return sync.ShowStatus()
}

func performCleanup(config Config) error {
	fmt.Println("🧹 Performing submodule cleanup...")

	if config.DryRun {
		fmt.Println("🧪 DRY RUN MODE - No changes will be made")
	}

	sync := NewSubmoduleSync(config)
	return sync.Cleanup()
}
