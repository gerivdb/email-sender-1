package vector_benchmark

import (
	"context"
	"flag"
	"fmt"
	"time"

	"go.uber.org/zap"
)

func main() {
	var (
		qdrantHost	= flag.String("host", "localhost", "Qdrant host")
		qdrantPort	= flag.Int("port", 6333, "Qdrant port")
		collectionName	= flag.String("collection", "benchmark_test", "Collection name")
		iterations	= flag.Int("iterations", 1000, "Number of iterations")
	)
	flag.Parse()

	// Setup logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	logger.Info("Starting vector benchmark",
		zap.String("host", *qdrantHost),
		zap.Int("port", *qdrantPort),
		zap.String("collection", *collectionName),
		zap.Int("iterations", *iterations))

	// Create client
	config := &vectorization.ClientConfig{
		Host:		*qdrantHost,
		Port:		*qdrantPort,
		CollectionName:	*collectionName,
		VectorSize:	384,	// Default vector size
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
		logger.Info("Collection does not exist, creating...", zap.String("collection", *collectionName))

		err = client.CreateCollection(ctx)
		if err != nil {
			logger.Error("Failed to create collection", zap.Error(err))
			return
		}
	}

	// Run benchmark
	logger.Info("Running search benchmark...")
	start := time.Now()

	// Simulate benchmark queries
	testVector := make([]float32, 384)
	for i := 0; i < *iterations; i++ {
		// Fill test vector with some data
		for j := range testVector {
			testVector[j] = float32(i+j) / float32(*iterations)
		}

		// Search similar vectors
		_, err := client.SearchSimilar(ctx, testVector, 10)
		if err != nil {
			logger.Error("Search failed", zap.Error(err), zap.Int("iteration", i))
			break
		}

		if i%100 == 0 {
			logger.Info("Benchmark progress", zap.Int("completed", i), zap.Int("total", *iterations))
		}
	}

	duration := time.Since(start)

	fmt.Printf("✅ Vector benchmark completed\n")
	fmt.Printf("📊 Iterations: %d\n", *iterations)
	fmt.Printf("⏱️ Total time: %v\n", duration)
	fmt.Printf("📈 Average time per query: %v\n", duration/time.Duration(*iterations))
	fmt.Printf("🎉 vector-benchmark - COMPLETED\n")
}
