package main

import (
	"log"

	"go.uber.org/zap"
)

func main() {
	logger, _ := zap.NewDevelopment()
	defer logger.Sync()

	// Test creating a sync client
	client, err := NewSyncClient("http://localhost:6333", logger)
	if err != nil {
		log.Fatalf("Failed to create sync client: %v", err)
	}

	// Test health check
	if err := client.HealthCheck(); err != nil {
		log.Fatalf("Health check failed: %v", err)
	}

	logger.Info("✅ SyncClient successfully created and tested")
}
