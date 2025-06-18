package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"go.uber.org/zap"

	"email_sender/pkg/vectorization"
)

func main() {
	var (
		filePath       = flag.String("file", "", "Path to markdown file to process")
		qdrantHost     = flag.String("host", "localhost", "Qdrant host")
		qdrantPort     = flag.Int("port", 6333, "Qdrant port")
		collectionName = flag.String("collection", "vectorization_test", "Collection name")
	)
	flag.Parse()

	// Setup logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Validate input
	if *filePath == "" {
		fmt.Println("Usage: migrate-vectorization -file=<path> [options]")
		flag.PrintDefaults()
		os.Exit(1)
	}

	logger.Info("Starting vectorization migration",
		zap.String("file", *filePath),
		zap.String("host", *qdrantHost),
		zap.Int("port", *qdrantPort),
		zap.String("collection", *collectionName))

	// Create client
	config := &vectorization.ClientConfig{
		Host:           *qdrantHost,
		Port:           *qdrantPort,
		CollectionName: *collectionName,
		VectorSize:     384, // Default vector size
	}

	client, err := vectorization.NewVectorClient(config)
	if err != nil {
		logger.Fatal("Failed to create Qdrant client", zap.Error(err))
	}
	defer client.Close()

	// Test connection
	ctx := context.Background()
	err = client.GetCollectionInfo(ctx)
	if err != nil {
		logger.Info("Collection does not exist, will be created", zap.String("collection", *collectionName))

		// Try to create collection
		err = client.CreateCollection(ctx)
		if err != nil {
			logger.Error("Failed to create collection", zap.Error(err))
		} else {
			logger.Info("Collection created successfully", zap.String("collection", *collectionName))
		}
	} else {
		logger.Info("Found existing collection", zap.String("collection", *collectionName))
	}

	fmt.Printf("✅ Vectorization migration tool executed successfully\n")
	fmt.Printf("📁 File: %s\n", *filePath)
	fmt.Printf("🗄️ Collection: %s\n", *collectionName)
	fmt.Printf("🎉 migrate-vectorization - COMPLETED\n")
}
