package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"go.uber.org/zap"

	"email_sender/internal/vectorization"
)

func main() {
	var (
		filePath       = flag.String("file", "", "Path to markdown file to process")
		qdrantHost     = flag.String("host", "localhost", "Qdrant host")
		qdrantPort     = flag.Int("port", 6333, "Qdrant port")
		collectionName = flag.String("collection", "roadmap_tasks", "Collection name")
		vectorSize     = flag.Int("vector-size", 1536, "Vector size")
		batchSize      = flag.Int("batch-size", 100, "Batch size for insertion")
		verbose        = flag.Bool("verbose", false, "Enable verbose logging")
	)
	flag.Parse()

	if *filePath == "" {
		fmt.Println("Usage: go run cmd/migrate-vectorization/main.go -file <path_to_markdown_file>")
		flag.PrintDefaults()
		os.Exit(1)
	}

	// Setup logger
	var logger *zap.Logger
	var err error
	if *verbose {
		logger, err = zap.NewDevelopment()
	} else {
		logger, err = zap.NewProduction()
	}
	if err != nil {
		log.Fatalf("Failed to create logger: %v", err)
	}
	defer logger.Sync()

	logger.Info("Starting vectorization migration",
		zap.String("file", *filePath),
		zap.String("host", *qdrantHost),
		zap.Int("port", *qdrantPort),
		zap.String("collection", *collectionName))

	// Create client
	config := vectorization.ClientConfig{
		Host:       *qdrantHost,
		Port:       *qdrantPort,
		RetryCount: 3,
		Timeout:    30 * time.Second,
	}

	client := vectorization.NewUnifiedQdrantClient(config)

	// Test connection
	ctx := context.Background()
	info, err := client.GetCollectionInfo(ctx, *collectionName)
	if err != nil {
		logger.Info("Collection does not exist, will be created", zap.String("collection", *collectionName))
	} else {
		logger.Info("Found existing collection",
			zap.String("collection", *collectionName),
			zap.String("status", info.Status),
			zap.Int("points", info.PointsCount))
	}

	// Create extractor
	extractor := vectorization.NewMarkdownTaskExtractor(client, logger)

	// Process file
	extractionConfig := vectorization.TaskExtractionConfig{
		CollectionName: *collectionName,
		VectorSize:     *vectorSize,
		BatchSize:      *batchSize,
	}

	start := time.Now()
	err = extractor.ProcessMarkdownFile(ctx, *filePath, extractionConfig)
	if err != nil {
		logger.Fatal("Failed to process markdown file", zap.Error(err))
	}

	duration := time.Since(start)
	logger.Info("Vectorization migration completed successfully",
		zap.Duration("duration", duration),
		zap.String("file", *filePath))

	// Verify results
	info, err = client.GetCollectionInfo(ctx, *collectionName)
	if err != nil {
		logger.Error("Failed to get collection info after processing", zap.Error(err))
	} else {
		logger.Info("Final collection status",
			zap.String("collection", *collectionName),
			zap.String("status", info.Status),
			zap.Int("points", info.PointsCount))
	}

	fmt.Printf("✅ Migration completed successfully!\n")
	fmt.Printf("📊 Collection: %s\n", *collectionName)
	fmt.Printf("📁 File: %s\n", *filePath)
	fmt.Printf("⏱️  Duration: %v\n", duration)
	if info != nil {
		fmt.Printf("📈 Points in collection: %d\n", info.PointsCount)
	}
}
