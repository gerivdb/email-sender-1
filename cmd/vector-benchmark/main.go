// Performance benchmarking tool for vector operations
// Part of EMAIL_SENDER_1 vectorization Go native migration
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"runtime"
	"sync"
	"time"

	"email_sender/pkg/vectorization"

	"go.uber.org/zap"
)

type BenchmarkConfig struct {
	VectorCount   int    `json:"vector_count"`
	VectorSize    int    `json:"vector_size"`
	BatchSize     int    `json:"batch_size"`
	Concurrency   int    `json:"concurrency"`
	SearchQueries int    `json:"search_queries"`
	SearchLimit   int    `json:"search_limit"`
	OutputFile    string `json:"output_file"`
	WarmupRounds  int    `json:"warmup_rounds"`
}

type BenchmarkResults struct {
	Config            BenchmarkConfig `json:"config"`
	InsertionTime     time.Duration   `json:"insertion_time"`
	SearchTime        time.Duration   `json:"search_time"`
	VectorsPerSecond  float64         `json:"vectors_per_second"`
	SearchesPerSecond float64         `json:"searches_per_second"`
	MemoryUsage       MemoryStats     `json:"memory_usage"`
	Timestamp         time.Time       `json:"timestamp"`
	GoVersion         string          `json:"go_version"`
	Architecture      string          `json:"architecture"`
}

type MemoryStats struct {
	AllocMB      float64 `json:"alloc_mb"`
	TotalAllocMB float64 `json:"total_alloc_mb"`
	SysMB        float64 `json:"sys_mb"`
	NumGC        uint32  `json:"num_gc"`
}

var (
	configFile = flag.String("config", "benchmark.json", "Benchmark configuration file")
	verbose    = flag.Bool("verbose", false, "Enable verbose logging")
	profile    = flag.Bool("profile", false, "Enable CPU profiling")
)

func main() {
	flag.Parse()

	// Initialize logger
	var logger *zap.Logger
	var err error
	if *verbose {
		logger, err = zap.NewDevelopment()
	} else {
		logger, err = zap.NewProduction()
	}
	if err != nil {
		log.Fatal("Failed to initialize logger:", err)
	}
	defer logger.Sync()

	// Load benchmark configuration
	config, err := loadBenchmarkConfig(*configFile)
	if err != nil {
		logger.Fatal("Failed to load config", zap.Error(err))
	}

	logger.Info("Starting vectorization benchmark",
		zap.Int("vector_count", config.VectorCount),
		zap.Int("vector_size", config.VectorSize),
		zap.Int("batch_size", config.BatchSize),
		zap.Int("concurrency", config.Concurrency))

	// Run benchmark
	results, err := runBenchmark(config, logger)
	if err != nil {
		logger.Fatal("Benchmark failed", zap.Error(err))
	}

	// Print results
	printResults(results)

	// Save results if output file specified
	if config.OutputFile != "" {
		if err := saveResults(results, config.OutputFile); err != nil {
			logger.Error("Failed to save results", zap.Error(err))
		} else {
			logger.Info("Results saved", zap.String("file", config.OutputFile))
		}
	}
}

func loadBenchmarkConfig(filename string) (BenchmarkConfig, error) {
	// Default configuration
	config := BenchmarkConfig{
		VectorCount:   1000,
		VectorSize:    384,
		BatchSize:     100,
		Concurrency:   4,
		SearchQueries: 100,
		SearchLimit:   10,
		WarmupRounds:  3,
	}

	// Try to load from file
	if data, err := os.ReadFile(filename); err == nil {
		if err := json.Unmarshal(data, &config); err != nil {
			return config, fmt.Errorf("failed to parse config: %w", err)
		}
	} else if !os.IsNotExist(err) {
		return config, fmt.Errorf("failed to read config file: %w", err)
	}

	// Validate configuration
	if config.VectorCount <= 0 {
		config.VectorCount = 1000
	}
	if config.VectorSize <= 0 {
		config.VectorSize = 384
	}
	if config.BatchSize <= 0 {
		config.BatchSize = 100
	}
	if config.Concurrency <= 0 {
		config.Concurrency = runtime.NumCPU()
	}

	return config, nil
}

func runBenchmark(config BenchmarkConfig, logger *zap.Logger) (BenchmarkResults, error) {
	// Create vector client
	vectorConfig := vectorization.DefaultConfig()
	vectorConfig.CollectionName = fmt.Sprintf("benchmark_%d", time.Now().Unix())
	vectorConfig.VectorSize = config.VectorSize

	client, err := vectorization.NewVectorClient(vectorConfig, logger)
	if err != nil {
		return BenchmarkResults{}, fmt.Errorf("failed to create client: %w", err)
	}
	defer client.Close()

	ctx := context.Background()

	// Clean up collection at the end
	defer func() {
		if err := client.DeleteCollection(ctx); err != nil {
			logger.Warn("Failed to cleanup collection", zap.Error(err))
		}
	}()

	// Create collection
	if err := client.CreateCollection(ctx); err != nil {
		return BenchmarkResults{}, fmt.Errorf("failed to create collection: %w", err)
	}

	// Generate test vectors
	logger.Info("Generating test vectors")
	vectors := vectorization.GenerateTestVectors(config.VectorCount, config.VectorSize)

	// Warmup rounds
	for i := 0; i < config.WarmupRounds; i++ {
		logger.Info("Warmup round", zap.Int("round", i+1))
		warmupVectors := vectorization.GenerateTestVectors(100, config.VectorSize)
		if err := client.UpsertVectors(ctx, warmupVectors); err != nil {
			logger.Warn("Warmup failed", zap.Error(err))
		}
	}

	// Benchmark vector insertion
	logger.Info("Benchmarking vector insertion")
	insertionStart := time.Now()
	memBefore := getMemoryStats()

	if err := insertVectorsConcurrent(ctx, client, vectors, config, logger); err != nil {
		return BenchmarkResults{}, fmt.Errorf("insertion benchmark failed: %w", err)
	}

	insertionTime := time.Since(insertionStart)
	memAfterInsert := getMemoryStats()

	// Wait for indexing to complete
	time.Sleep(2 * time.Second)

	// Benchmark vector search
	logger.Info("Benchmarking vector search")
	searchStart := time.Now()

	searchTime, err := benchmarkSearch(ctx, client, vectors, config, logger)
	if err != nil {
		return BenchmarkResults{}, fmt.Errorf("search benchmark failed: %w", err)
	}

	memAfterSearch := getMemoryStats()

	// Calculate performance metrics
	vectorsPerSecond := float64(config.VectorCount) / insertionTime.Seconds()
	searchesPerSecond := float64(config.SearchQueries) / searchTime.Seconds()

	results := BenchmarkResults{
		Config:            config,
		InsertionTime:     insertionTime,
		SearchTime:        searchTime,
		VectorsPerSecond:  vectorsPerSecond,
		SearchesPerSecond: searchesPerSecond,
		MemoryUsage:       memAfterSearch,
		Timestamp:         time.Now(),
		GoVersion:         runtime.Version(),
		Architecture:      runtime.GOARCH,
	}

	logger.Info("Benchmark completed",
		zap.Duration("insertion_time", insertionTime),
		zap.Duration("search_time", searchTime),
		zap.Float64("vectors_per_second", vectorsPerSecond),
		zap.Float64("searches_per_second", searchesPerSecond),
		zap.Float64("memory_alloc_mb", memAfterSearch.AllocMB))

	return results, nil
}

func insertVectorsConcurrent(ctx context.Context, client *vectorization.VectorClient,
	vectors []vectorization.VectorData, config BenchmarkConfig, logger *zap.Logger) error {

	// Create batches
	batches := make([][]vectorization.VectorData, 0)
	for i := 0; i < len(vectors); i += config.BatchSize {
		end := i + config.BatchSize
		if end > len(vectors) {
			end = len(vectors)
		}
		batches = append(batches, vectors[i:end])
	}

	// Use worker pool for concurrent insertion
	batchChan := make(chan []vectorization.VectorData, len(batches))
	errorChan := make(chan error, config.Concurrency)

	// Start workers
	var wg sync.WaitGroup
	for i := 0; i < config.Concurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for batch := range batchChan {
				start := time.Now()
				if err := client.UpsertVectors(ctx, batch); err != nil {
					logger.Error("Batch insertion failed",
						zap.Int("worker", workerID),
						zap.Int("batch_size", len(batch)),
						zap.Error(err))
					errorChan <- err
					return
				}
				logger.Debug("Batch inserted",
					zap.Int("worker", workerID),
					zap.Int("batch_size", len(batch)),
					zap.Duration("duration", time.Since(start)))
			}
		}(i)
	}

	// Send batches to workers
	go func() {
		for _, batch := range batches {
			batchChan <- batch
		}
		close(batchChan)
	}()

	// Wait for completion
	wg.Wait()

	// Check for errors
	select {
	case err := <-errorChan:
		return err
	default:
		return nil
	}
}

func benchmarkSearch(ctx context.Context, client *vectorization.VectorClient,
	vectors []vectorization.VectorData, config BenchmarkConfig, logger *zap.Logger) (time.Duration, error) {

	searchStart := time.Now()

	// Perform concurrent searches
	var wg sync.WaitGroup
	errorChan := make(chan error, config.Concurrency)
	queriesPerWorker := config.SearchQueries / config.Concurrency

	for i := 0; i < config.Concurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			for j := 0; j < queriesPerWorker; j++ {
				// Use a random vector as query
				queryIndex := (workerID*queriesPerWorker + j) % len(vectors)
				queryVector := vectors[queryIndex].Vector

				_, err := client.SearchSimilar(ctx, queryVector, uint64(config.SearchLimit))
				if err != nil {
					logger.Error("Search failed",
						zap.Int("worker", workerID),
						zap.Int("query", j),
						zap.Error(err))
					errorChan <- err
					return
				}
			}
		}(i)
	}

	wg.Wait()

	// Check for errors
	select {
	case err := <-errorChan:
		return 0, err
	default:
		return time.Since(searchStart), nil
	}
}

func getMemoryStats() MemoryStats {
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return MemoryStats{
		AllocMB:      float64(m.Alloc) / 1024 / 1024,
		TotalAllocMB: float64(m.TotalAlloc) / 1024 / 1024,
		SysMB:        float64(m.Sys) / 1024 / 1024,
		NumGC:        m.NumGC,
	}
}

func printResults(results BenchmarkResults) {
	fmt.Println("\n" + "="*60)
	fmt.Println("VECTORIZATION BENCHMARK RESULTS")
	fmt.Println("=" * 60)

	fmt.Printf("Configuration:\n")
	fmt.Printf("  Vectors: %d (size: %d)\n", results.Config.VectorCount, results.Config.VectorSize)
	fmt.Printf("  Batch Size: %d\n", results.Config.BatchSize)
	fmt.Printf("  Concurrency: %d\n", results.Config.Concurrency)
	fmt.Printf("  Search Queries: %d (limit: %d)\n", results.Config.SearchQueries, results.Config.SearchLimit)

	fmt.Printf("\nPerformance:\n")
	fmt.Printf("  Insertion Time: %v\n", results.InsertionTime)
	fmt.Printf("  Search Time: %v\n", results.SearchTime)
	fmt.Printf("  Vectors/Second: %.2f\n", results.VectorsPerSecond)
	fmt.Printf("  Searches/Second: %.2f\n", results.SearchesPerSecond)

	fmt.Printf("\nMemory Usage:\n")
	fmt.Printf("  Allocated: %.2f MB\n", results.MemoryUsage.AllocMB)
	fmt.Printf("  System: %.2f MB\n", results.MemoryUsage.SysMB)
	fmt.Printf("  GC Cycles: %d\n", results.MemoryUsage.NumGC)

	fmt.Printf("\nEnvironment:\n")
	fmt.Printf("  Go Version: %s\n", results.GoVersion)
	fmt.Printf("  Architecture: %s\n", results.Architecture)
	fmt.Printf("  Timestamp: %s\n", results.Timestamp.Format(time.RFC3339))

	fmt.Println("=" * 60)

	// Performance assessment
	fmt.Println("\nPERFORMANCE ASSESSMENT:")

	if results.VectorsPerSecond > 1000 {
		fmt.Println("✅ Insertion performance: EXCELLENT (>1000 vectors/sec)")
	} else if results.VectorsPerSecond > 500 {
		fmt.Println("✅ Insertion performance: GOOD (>500 vectors/sec)")
	} else if results.VectorsPerSecond > 100 {
		fmt.Println("⚠️  Insertion performance: ACCEPTABLE (>100 vectors/sec)")
	} else {
		fmt.Println("❌ Insertion performance: POOR (<100 vectors/sec)")
	}

	if results.SearchesPerSecond > 100 {
		fmt.Println("✅ Search performance: EXCELLENT (>100 searches/sec)")
	} else if results.SearchesPerSecond > 50 {
		fmt.Println("✅ Search performance: GOOD (>50 searches/sec)")
	} else if results.SearchesPerSecond > 10 {
		fmt.Println("⚠️  Search performance: ACCEPTABLE (>10 searches/sec)")
	} else {
		fmt.Println("❌ Search performance: POOR (<10 searches/sec)")
	}

	if results.MemoryUsage.AllocMB < 100 {
		fmt.Println("✅ Memory usage: EXCELLENT (<100 MB)")
	} else if results.MemoryUsage.AllocMB < 500 {
		fmt.Println("✅ Memory usage: GOOD (<500 MB)")
	} else {
		fmt.Println("⚠️  Memory usage: HIGH (>500 MB)")
	}
}

func saveResults(results BenchmarkResults, filename string) error {
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal results: %w", err)
	}

	return os.WriteFile(filename, data, 0644)
}
