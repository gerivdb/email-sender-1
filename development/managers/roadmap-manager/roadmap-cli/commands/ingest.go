// Package commands provides CLI commands for plan ingestion functionality
package commands

import (
	"context"
	"fmt"
	"path/filepath"
	"runtime"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/ingestion"
	parallelprocessor "github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/parallel"
	rag "github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/rag"
	"github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/storage"

	"github.com/spf13/cobra"
)

var ingestCmd = &cobra.Command{
	Use:   "ingest",
	Short: "📥 Ingest roadmap plans from EMAIL_SENDER_1 ecosystem",
	Long: `Ingest and process consolidated roadmap plans from the EMAIL_SENDER_1 ecosystem.
This command:
- Scans consolidated plans directory for markdown files
- Chunks plans into searchable segments  
- Extracts cross-plan dependencies
- Indexes content in RAG vector database for intelligent analysis
- Optionally stores enriched plan items with detailed metadata to roadmap storage

Plans are automatically chunked by:
- Headers (# ## ### etc.)
- Task items (- [ ] checkboxes)  
- List items (- * + bullets)
- Content sections

Enhanced parsing (--enriched flag) extracts:
- Inputs, outputs, scripts, prerequisites
- Methods, URIs, tools, frameworks  
- Complexity, effort, business value, risk assessments
- Technical debt and performance metrics

The ingested data enhances RAG-powered recommendations and dependency analysis.`,
	RunE: runIngest,
}

var (
	plansDir   string
	dryRun     bool
	storageDir string
	enriched   bool
	// Parallel processing flags
	workers   int
	batchSize int
	timeout   int
	parallel  bool
)

func init() {
	ingestCmd.Flags().StringVar(&plansDir, "plans-dir", "", "path to consolidated plans directory")
	ingestCmd.Flags().BoolVar(&dryRun, "dry-run", false, "analyze plans without indexing to RAG")
	ingestCmd.Flags().StringVar(&storageDir, "storage-dir", "", "custom directory for storing roadmap data (default: ~/.roadmap-cli)")
	ingestCmd.Flags().BoolVar(&enriched, "enriched", false, "use enriched parsing with detailed metadata extraction")

	// Parallel processing flags
	ingestCmd.Flags().BoolVar(&parallel, "parallel", false, "enable parallel processing for massive plan ingestion")
	ingestCmd.Flags().IntVar(&workers, "workers", 0, "number of worker goroutines (default: CPU count)")
	ingestCmd.Flags().IntVar(&batchSize, "batch-size", 5, "number of files per batch for parallel processing")
	ingestCmd.Flags().IntVar(&timeout, "timeout", 30, "timeout in seconds for individual operations")
}

// NewIngestCommand returns the ingest command
func NewIngestCommand() *cobra.Command {
	return ingestCmd
}

func runIngest(cmd *cobra.Command, args []string) error {
	fmt.Println("📥 EMAIL_SENDER_1 Roadmap Plan Ingestion")
	fmt.Println("=======================================")
	fmt.Println()

	// Determine plans directory
	if plansDir == "" {
		// Default to EMAIL_SENDER_1 ecosystem structure
		workingDir := cmd.Flag("config").Value.String()
		if workingDir == "" {
			workingDir = "."
		}
		// Navigate to EMAIL_SENDER_1 plans directory
		plansDir = filepath.Join(workingDir, "..", "..", "projet", "roadmaps", "plans", "consolidated")
	}

	fmt.Printf("📁 Plans Directory: %s\n", plansDir)
	fmt.Printf("🔄 Dry Run Mode: %v\n", dryRun)
	fmt.Printf("🔬 Enriched Parsing: %v\n", enriched)
	fmt.Printf("⚡ Parallel Processing: %v\n", parallel)
	if parallel {
		actualWorkers := workers
		if actualWorkers == 0 {
			actualWorkers = runtime.NumCPU()
		}
		fmt.Printf("👥 Workers: %d\n", actualWorkers)
		fmt.Printf("📦 Batch Size: %d\n", batchSize)
		fmt.Printf("⏱️  Timeout: %ds\n", timeout)
	}
	if enriched {
		if cmd.Flag("storage-dir").Changed {
			fmt.Printf("💾 Custom Storage Directory: %s\n", storageDir)
		} else {
			fmt.Printf("💾 Storage Path: %s\n", storage.GetDefaultStoragePath())
		}
	}
	fmt.Println()
	// Initialize storage if enriched mode is enabled
	var roadmapStorage *storage.JSONStorage
	if enriched && !dryRun {
		// Use centralized storage path configuration
		storageFile := storage.GetDefaultStoragePath()

		// If user provided a custom storage-dir, use that instead
		if cmd.Flag("storage-dir").Changed {
			storageFile = filepath.Join(storageDir, "roadmap.json")
		}

		var err error
		roadmapStorage, err = storage.NewJSONStorage(storageFile)
		if err != nil {
			return fmt.Errorf("failed to initialize storage: %w", err)
		}
		defer roadmapStorage.Close()
		fmt.Printf("💾 Storage initialized: %s\n", storageFile)
		fmt.Println()
	}

	// Create RAG client for indexing (unless dry run)
	var ragClient ingestion.RAGClient
	if !dryRun {
		ragClient = rag.NewRAGClient(
			"http://localhost:6333", // QDrant URL
			"http://localhost:8080", // OpenAI URL (placeholder)
			"test-api-key",          // API key (placeholder)
		)

		// Test RAG connectivity
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := ragClient.HealthCheck(ctx); err != nil {
			fmt.Printf("⚠️  RAG system not available: %v\n", err)
			fmt.Println("   Proceeding with analysis only (no indexing)")
			ragClient = nil
		} else {
			fmt.Println("✅ RAG system connected")
		}
		fmt.Println()
	}

	// Create plan ingester
	ingester := ingestion.NewPlanIngester(plansDir, ragClient)
	// Determine which processing method to use
	if enriched {
		return runEnrichedIngestion(ingester, roadmapStorage)
	} else {
		return runStandardIngestion(ingester)
	}
}

// runStandardIngestion performs the original plan ingestion with RAG indexing
func runStandardIngestion(ingester *ingestion.PlanIngester) error {
	// Start standard ingestion
	fmt.Println("🔍 Scanning and processing plan files...")
	ctx := context.Background()

	result, err := ingester.IngestAllPlans(ctx)
	if err != nil {
		return fmt.Errorf("ingestion failed: %w", err)
	}

	// Display results
	fmt.Println()
	fmt.Println("📊 Ingestion Results")
	fmt.Println("===================")
	fmt.Printf("📄 Files Processed: %d\n", result.FilesProcessed)
	fmt.Printf("🧩 Chunks Created: %d\n", result.ChunksCreated)
	fmt.Printf("🔗 Dependencies Found: %d\n", result.DependenciesFound)
	fmt.Printf("⏱️  Processing Time: %v\n", result.ProcessingTime)

	if len(result.Errors) > 0 {
		fmt.Printf("⚠️  Errors: %d\n", len(result.Errors))
		for i, err := range result.Errors {
			if i < 5 { // Show first 5 errors
				fmt.Printf("   - %s\n", err)
			}
		}
		if len(result.Errors) > 5 {
			fmt.Printf("   ... and %d more errors\n", len(result.Errors)-5)
		}
	}
	// Display ingestion summary (limit for large datasets)
	fmt.Println()
	summary := ingester.GetIngestionSummary()
	fmt.Println("📈 Content Analysis")
	fmt.Println("==================")

	if totalChunks, ok := summary["total_chunks"].(int); ok && totalChunks > 100000 {
		fmt.Printf("⚠️  Large dataset detected (%d chunks) - showing limited summary\n", totalChunks)

		if chunkTypes, ok := summary["chunk_types"].(map[string]int); ok {
			fmt.Println("Chunk types:")
			for chunkType, count := range chunkTypes {
				fmt.Printf("   %s: %d\n", chunkType, count)
			}
		}

		if planFiles, ok := summary["plan_files"].(map[string]int); ok {
			fmt.Printf("Plans processed: %d files\n", len(planFiles))
		}
	} else {
		// Normal detailed summary for smaller datasets
		if chunkTypes, ok := summary["chunk_types"].(map[string]int); ok {
			for chunkType, count := range chunkTypes {
				fmt.Printf("   %s: %d\n", chunkType, count)
			}
		}

		if planFiles, ok := summary["plan_files"].(map[string]int); ok {
			fmt.Println()
			fmt.Println("📋 Plans Processed:")
			count := 0
			for planFile, chunks := range planFiles {
				if count < 10 { // Show first 10 files
					fmt.Printf("   %s: %d chunks\n", planFile, chunks)
				}
				count++
			}
			if len(planFiles) > 10 {
				fmt.Printf("   ... and %d more files\n", len(planFiles)-10)
			}
		}
	}

	fmt.Println()
	if dryRun {
		fmt.Println("✅ Dry run completed successfully!")
		fmt.Println("💡 Remove --dry-run flag to index content in RAG system")
	} else {
		fmt.Println("🎉 Plan ingestion completed successfully!")
		fmt.Println("💡 Use 'roadmap-cli intelligence analyze' to query the ingested plans")
	}

	return nil
}

// runEnrichedIngestion performs enriched plan ingestion with detailed metadata extraction and storage
func runEnrichedIngestion(ingester *ingestion.PlanIngester, roadmapStorage *storage.JSONStorage) error {
	fmt.Println("🔬 Starting enriched plan ingestion...")

	// Create context for enriched operations
	ctx := context.Background()

	// Get plan files to process
	planFiles, err := filepath.Glob(filepath.Join(plansDir, "*.md"))
	if err != nil {
		return fmt.Errorf("failed to find plan files: %w", err)
	}

	if len(planFiles) == 0 {
		fmt.Println("⚠️  No markdown plan files found in directory")
		return nil
	}

	fmt.Printf("📄 Found %d plan files to process\n", len(planFiles))
	fmt.Println()

	startTime := time.Now()
	if dryRun {
		// Dry run: analyze enriched content without storing
		enrichedResult, err := ingester.IngestEnrichedPlans(ctx)
		if err != nil {
			return fmt.Errorf("enriched analysis failed: %w", err)
		}

		// Display enriched analysis results
		fmt.Println("📊 Enriched Analysis Results (Dry Run)")
		fmt.Println("=====================================")
		fmt.Printf("📋 Enriched Items Found: %d\n", len(enrichedResult.EnrichedItems))
		complexityCount := map[string]int{}
		riskCount := map[string]int{}

		for _, item := range enrichedResult.EnrichedItems {
			if item.Complexity != "" {
				complexityCount[string(item.Complexity)]++
			}
			if item.RiskLevel != "" {
				riskCount[string(item.RiskLevel)]++
			}
		}

		if len(complexityCount) > 0 {
			fmt.Println("\n🧩 Complexity Distribution:")
			for level, count := range complexityCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}

		if len(riskCount) > 0 {
			fmt.Println("\n⚠️  Risk Level Distribution:")
			for level, count := range riskCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}
		// Show sample enriched items
		if len(enrichedResult.EnrichedItems) > 0 {
			fmt.Println("\n📋 Sample Enriched Items:")
			sampleCount := 3
			if len(enrichedResult.EnrichedItems) < sampleCount {
				sampleCount = len(enrichedResult.EnrichedItems)
			}

			for i := 0; i < sampleCount; i++ {
				item := enrichedResult.EnrichedItems[i]
				fmt.Printf("\n   Title: %s\n", item.Title)
				fmt.Printf("   Complexity: %s | Risk: %s\n", item.Complexity, item.RiskLevel)
				if len(item.Tools) > 0 {
					fmt.Printf("   Tools: %v\n", item.Tools)
				}
				if len(item.Prerequisites) > 0 {
					fmt.Printf("   Prerequisites: %v\n", item.Prerequisites)
				}
			}
		}
	} else {
		// Full ingestion with storage
		if roadmapStorage == nil {
			return fmt.Errorf("storage not initialized for enriched ingestion")
		}

		// Check if parallel processing is enabled
		if parallel {
			return runParallelEnrichedIngestion(ingester, roadmapStorage, planFiles)
		}

		// Use the integrated ingestion method (sequential)
		createdItems, err := ingester.IngestAndStoreEnrichedPlans(roadmapStorage, planFiles)
		if err != nil {
			return fmt.Errorf("enriched ingestion and storage failed: %w", err)
		}

		// Display storage results
		fmt.Println("📊 Enriched Ingestion & Storage Results")
		fmt.Println("======================================")
		fmt.Printf("💾 Items Stored: %d\n", len(createdItems))

		// Show summary statistics
		complexityCount := map[string]int{}
		priorityCount := map[string]int{}

		for _, item := range createdItems {
			if item.Complexity != "" {
				complexityCount[string(item.Complexity)]++
			}
			if item.Priority != "" {
				priorityCount[string(item.Priority)]++
			}
		}

		if len(complexityCount) > 0 {
			fmt.Println("\n🧩 Stored Items by Complexity:")
			for level, count := range complexityCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}

		if len(priorityCount) > 0 {
			fmt.Println("\n🎯 Stored Items by Priority:")
			for level, count := range priorityCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}
	}

	processingTime := time.Since(startTime)
	fmt.Printf("\n⏱️  Processing Time: %v\n", processingTime)

	fmt.Println()
	if dryRun {
		fmt.Println("✅ Enriched dry run completed successfully!")
		fmt.Println("💡 Remove --dry-run flag to store enriched items to roadmap storage")
	} else {
		fmt.Println("🎉 Enriched plan ingestion completed successfully!")
		fmt.Println("💡 Use 'roadmap-cli view' to see stored roadmap items")
		fmt.Println("💡 Use 'roadmap-cli intelligence analyze' for AI-powered insights")
	}

	return nil
}

// runParallelEnrichedIngestion performs enriched plan ingestion using parallel processing
func runParallelEnrichedIngestion(ingester *ingestion.PlanIngester, roadmapStorage *storage.JSONStorage, planFiles []string) error {
	fmt.Println("🚀 Starting parallel enriched plan ingestion...")
	// Configure parallel processing
	config := parallelprocessor.ProcessorConfig{
		Workers:   workers,
		BatchSize: batchSize,
		Timeout:   time.Duration(timeout) * time.Second,
	}

	// Use default workers if not specified
	if config.Workers == 0 {
		config.Workers = runtime.NumCPU()
	}

	fmt.Printf("⚙️  Configuration: %d workers, batch size %d, timeout %v\n",
		config.Workers, config.BatchSize, config.Timeout)
	// Initialize performance monitoring
	monitor := parallelprocessor.NewPerformanceMonitor(2*time.Second, 1000) // Sample every 2 seconds, max 1000 samples
	ctx := context.Background()
	monitor.Start(ctx)

	// Create parallel processor
	processor := parallelprocessor.NewPlanProcessor(config)
	// Initialize batch storage for optimized writes
	batchStorageConfig := parallelprocessor.DefaultBatchStorageConfig()
	batchStorage := parallelprocessor.NewConcurrentBatchStorage(roadmapStorage, batchStorageConfig)
	defer batchStorage.Close()

	fmt.Println("📊 Performance monitoring started...")
	fmt.Println()

	// Start parallel processing
	allItems, processingMetrics, err := processor.ProcessPlansParallel(ctx, planFiles, ingester, roadmapStorage)
	if err != nil {
		return fmt.Errorf("parallel processing failed: %w", err)
	}

	// Stop monitoring and get report
	performanceReport := monitor.Stop()
	storageMetrics := batchStorage.GetMetrics()

	// Display comprehensive results
	fmt.Println()
	fmt.Println("📊 Parallel Processing Results")
	fmt.Println("=============================")
	fmt.Printf("💾 Items Created: %d\n", len(allItems))
	fmt.Printf("📄 Files Processed: %d/%d\n", processingMetrics.FilesProcessed, processingMetrics.TotalFiles)
	fmt.Printf("📦 Batches Processed: %d\n", processingMetrics.Batches)
	fmt.Printf("⏱️  Total Processing Time: %v\n", processingMetrics.Duration)

	if len(processingMetrics.Errors) > 0 {
		fmt.Printf("⚠️  Processing Errors: %d\n", len(processingMetrics.Errors))
		for i, error := range processingMetrics.Errors {
			if i < 3 { // Show first 3 errors
				fmt.Printf("   - %s\n", error)
			}
		}
		if len(processingMetrics.Errors) > 3 {
			fmt.Printf("   ... and %d more errors\n", len(processingMetrics.Errors)-3)
		}
	}

	// Display performance metrics
	fmt.Println()
	fmt.Println("🚀 Performance Metrics")
	fmt.Println("======================")
	fmt.Printf("⏱️  Total Duration: %v\n", performanceReport.Duration)
	fmt.Printf("🧠 Peak Memory Usage: %d MB\n", performanceReport.PeakMemoryMB)
	fmt.Printf("📈 Average Memory Usage: %d MB\n", performanceReport.AverageMemoryMB)
	fmt.Printf("🔄 Peak Goroutines: %d\n", performanceReport.PeakGoroutines)
	fmt.Printf("🗑️  Average GC Pause: %.2f ms\n", performanceReport.AverageGCPauseMS)
	fmt.Printf("📊 Memory Growth Rate: %.2f MB/sec\n", performanceReport.MemoryGrowthRate)

	// Display storage metrics
	fmt.Println()
	fmt.Println("💾 Storage Performance")
	fmt.Println("=====================")
	fmt.Printf("📝 Total Items Stored: %d\n", storageMetrics.TotalItems)
	fmt.Printf("📦 Batches Written: %d\n", storageMetrics.BatchesWritten)
	fmt.Printf("🔄 Flush Operations: %d\n", storageMetrics.FlushCount)
	fmt.Printf("⚡ Average Batch Write Time: %v\n", storageMetrics.AvgBatchTime)
	fmt.Printf("⏰ Timer Flushes: %d\n", storageMetrics.TimerFlushes)
	fmt.Printf("🧠 Memory Flushes: %d\n", storageMetrics.MemoryFlushes)

	// Display item statistics
	if len(allItems) > 0 {
		complexityCount := map[string]int{}
		priorityCount := map[string]int{}

		for _, item := range allItems {
			if item.Complexity != "" {
				complexityCount[string(item.Complexity)]++
			}
			if item.Priority != "" {
				priorityCount[string(item.Priority)]++
			}
		}

		if len(complexityCount) > 0 {
			fmt.Println()
			fmt.Println("🧩 Items by Complexity:")
			for level, count := range complexityCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}

		if len(priorityCount) > 0 {
			fmt.Println()
			fmt.Println("🎯 Items by Priority:")
			for level, count := range priorityCount {
				fmt.Printf("   %s: %d items\n", level, count)
			}
		}
	}

	// Display performance recommendations
	if len(performanceReport.Recommendations) > 0 {
		fmt.Println()
		fmt.Println("💡 Performance Recommendations")
		fmt.Println("==============================")
		for _, rec := range performanceReport.Recommendations {
			fmt.Printf("   • %s\n", rec)
		}
	}

	// Calculate throughput metrics
	if processingMetrics.Duration.Seconds() > 0 {
		filesPerSecond := float64(processingMetrics.FilesProcessed) / processingMetrics.Duration.Seconds()
		itemsPerSecond := float64(len(allItems)) / processingMetrics.Duration.Seconds()

		fmt.Println()
		fmt.Println("📈 Throughput Metrics")
		fmt.Println("====================")
		fmt.Printf("📄 Files/second: %.2f\n", filesPerSecond)
		fmt.Printf("📝 Items/second: %.2f\n", itemsPerSecond)

		// Compare with estimated sequential processing
		estimatedSequentialTime := time.Duration(float64(processingMetrics.TotalFiles)*2.0) * time.Second // Assume 2 seconds per file
		speedupFactor := float64(estimatedSequentialTime) / float64(processingMetrics.Duration)
		fmt.Printf("⚡ Estimated speedup: %.1fx faster than sequential\n", speedupFactor)
	}

	fmt.Println()
	fmt.Println("🎉 Parallel enriched plan ingestion completed successfully!")
	fmt.Println("💡 Use 'roadmap-cli view' to see stored roadmap items")
	fmt.Println("💡 Use 'roadmap-cli intelligence analyze' for AI-powered insights")

	return nil
}
