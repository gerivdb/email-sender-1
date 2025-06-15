// Vector Migration Tool - Command Line Interface for EMAIL_SENDER_1
// Replaces Python vectorization scripts with Go native implementation
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"email_sender/pkg/vectorization"

	"go.uber.org/zap"
)

// CLI command structure
type Command struct {
	Name        string
	Description string
	Execute     func(args []string) error
}

var (
	// Global flags
	configFile = flag.String("config", "config/vector.json", "Configuration file path")
	verbose    = flag.Bool("verbose", false, "Enable verbose logging")
	dryRun     = flag.Bool("dry-run", false, "Dry run mode - no actual operations")

	// Global logger
	logger *zap.Logger
)

func main() {
	flag.Parse()

	// Initialize logger
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

	// Define available commands
	commands := map[string]Command{
		"create":   {Name: "create", Description: "Create a new vector collection", Execute: createCollection},
		"migrate":  {Name: "migrate", Description: "Migrate vectors from JSON/Python to Qdrant", Execute: migrateVectors},
		"test":     {Name: "test", Description: "Generate and insert test vectors", Execute: testVectors},
		"search":   {Name: "search", Description: "Search for similar vectors", Execute: searchVectors},
		"info":     {Name: "info", Description: "Get collection information", Execute: collectionInfo},
		"delete":   {Name: "delete", Description: "Delete a collection", Execute: deleteCollection},
		"export":   {Name: "export", Description: "Export vectors to JSON", Execute: exportVectors},
		"validate": {Name: "validate", Description: "Validate vector data integrity", Execute: validateVectors},
	}

	// Parse command
	args := flag.Args()
	if len(args) == 0 {
		printUsage(commands)
		os.Exit(1)
	}

	commandName := args[0]
	command, exists := commands[commandName]
	if !exists {
		fmt.Printf("Unknown command: %s\n\n", commandName)
		printUsage(commands)
		os.Exit(1)
	}

	// Execute command
	if err := command.Execute(args[1:]); err != nil {
		logger.Error("Command failed", zap.String("command", commandName), zap.Error(err))
		os.Exit(1)
	}

	logger.Info("Command completed successfully", zap.String("command", commandName))
}

func printUsage(commands map[string]Command) {
	fmt.Println("Vector Migration Tool - Go Native Implementation")
	fmt.Println("Usage: vector-migration [global-flags] <command> [command-args]")
	fmt.Println()
	fmt.Println("Global Flags:")
	flag.PrintDefaults()
	fmt.Println()
	fmt.Println("Available Commands:")
	for _, cmd := range commands {
		fmt.Printf("  %-12s %s\n", cmd.Name, cmd.Description)
	}
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  vector-migration create")
	fmt.Println("  vector-migration migrate --input vectors.json")
	fmt.Println("  vector-migration test --count 1000")
	fmt.Println("  vector-migration search --query-file query.json --limit 10")
}

func loadConfig() (vectorization.VectorConfig, error) {
	config := vectorization.DefaultConfig()

	if *configFile != "" {
		data, err := os.ReadFile(*configFile)
		if err != nil {
			if !os.IsNotExist(err) {
				return config, fmt.Errorf("failed to read config file: %w", err)
			}
			logger.Info("Config file not found, using defaults", zap.String("file", *configFile))
		} else {
			if err := json.Unmarshal(data, &config); err != nil {
				return config, fmt.Errorf("failed to parse config file: %w", err)
			}
			logger.Info("Loaded configuration", zap.String("file", *configFile))
		}
	}

	return config, nil
}

func createClient() (*vectorization.VectorClient, error) {
	config, err := loadConfig()
	if err != nil {
		return nil, err
	}

	return vectorization.NewVectorClient(config, logger)
}

// Command implementations

func createCollection(args []string) error {
	if *dryRun {
		logger.Info("DRY RUN: Would create collection")
		return nil
	}

	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()
	return client.CreateCollection(ctx)
}

func migrateVectors(args []string) error {
	var inputFile string
	var batchSize int

	// Parse command-specific flags
	fs := flag.NewFlagSet("migrate", flag.ExitOnError)
	fs.StringVar(&inputFile, "input", "vectors.json", "Input JSON file with vectors")
	fs.IntVar(&batchSize, "batch-size", 100, "Batch size for migration")
	fs.Parse(args)

	if *dryRun {
		logger.Info("DRY RUN: Would migrate vectors",
			zap.String("input", inputFile),
			zap.Int("batch_size", batchSize))
		return nil
	}

	// Load vectors from file
	vectors, err := vectorization.LoadVectorsFromJSON(inputFile)
	if err != nil {
		return fmt.Errorf("failed to load vectors: %w", err)
	}

	logger.Info("Loaded vectors from file",
		zap.String("file", inputFile),
		zap.Int("count", len(vectors)))

	// Create client and migrate in batches
	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()

	// Migrate in batches
	for i := 0; i < len(vectors); i += batchSize {
		end := i + batchSize
		if end > len(vectors) {
			end = len(vectors)
		}

		batch := vectors[i:end]
		logger.Info("Migrating batch",
			zap.Int("start", i),
			zap.Int("end", end),
			zap.Int("size", len(batch)))

		if err := client.UpsertVectors(ctx, batch); err != nil {
			return fmt.Errorf("failed to migrate batch %d-%d: %w", i, end, err)
		}
	}

	return nil
}

func testVectors(args []string) error {
	var count int
	var vectorSize int
	var outputFile string

	fs := flag.NewFlagSet("test", flag.ExitOnError)
	fs.IntVar(&count, "count", 100, "Number of test vectors to generate")
	fs.IntVar(&vectorSize, "size", 384, "Vector dimension size")
	fs.StringVar(&outputFile, "output", "", "Save generated vectors to file")
	fs.Parse(args)

	// Generate test vectors
	vectors := vectorization.GenerateTestVectors(count, vectorSize)
	logger.Info("Generated test vectors", zap.Int("count", len(vectors)))

	// Save to file if requested
	if outputFile != "" {
		if err := vectorization.SaveVectorsToJSON(vectors, outputFile); err != nil {
			return fmt.Errorf("failed to save vectors: %w", err)
		}
		logger.Info("Saved vectors to file", zap.String("file", outputFile))
	}

	if *dryRun {
		logger.Info("DRY RUN: Would insert test vectors")
		return nil
	}

	// Insert into Qdrant
	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()

	start := time.Now()
	if err := client.UpsertVectors(ctx, vectors); err != nil {
		return fmt.Errorf("failed to insert test vectors: %w", err)
	}

	duration := time.Since(start)
	vectorsPerSecond := float64(len(vectors)) / duration.Seconds()

	logger.Info("Test vectors inserted successfully",
		zap.Duration("duration", duration),
		zap.Float64("vectors_per_second", vectorsPerSecond))

	return nil
}

func searchVectors(args []string) error {
	var queryFile string
	var limit int
	var outputFile string

	fs := flag.NewFlagSet("search", flag.ExitOnError)
	fs.StringVar(&queryFile, "query-file", "", "JSON file with query vector")
	fs.IntVar(&limit, "limit", 10, "Maximum number of results")
	fs.StringVar(&outputFile, "output", "", "Save search results to file")
	fs.Parse(args)

	if queryFile == "" {
		return fmt.Errorf("query-file is required")
	}

	// Load query vector
	vectors, err := vectorization.LoadVectorsFromJSON(queryFile)
	if err != nil {
		return fmt.Errorf("failed to load query vector: %w", err)
	}

	if len(vectors) == 0 {
		return fmt.Errorf("no vectors found in query file")
	}

	queryVector := vectors[0].Vector

	if *dryRun {
		logger.Info("DRY RUN: Would search for similar vectors",
			zap.String("query_file", queryFile),
			zap.Int("limit", limit))
		return nil
	}

	// Perform search
	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()

	start := time.Now()
	results, err := client.SearchSimilar(ctx, queryVector, uint64(limit))
	if err != nil {
		return fmt.Errorf("search failed: %w", err)
	}

	duration := time.Since(start)

	logger.Info("Search completed",
		zap.Duration("duration", duration),
		zap.Int("results", len(results)))

	// Save results if requested
	if outputFile != "" {
		if err := vectorization.SaveVectorsToJSON(results, outputFile); err != nil {
			return fmt.Errorf("failed to save results: %w", err)
		}
		logger.Info("Saved search results", zap.String("file", outputFile))
	}

	// Print results summary
	fmt.Printf("Found %d similar vectors in %v:\n", len(results), duration)
	for i, result := range results {
		fmt.Printf("  %d. ID: %s, Category: %v\n",
			i+1, result.ID, result.Payload["category"])
	}

	return nil
}

func collectionInfo(args []string) error {
	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()
	info, err := client.GetCollectionInfo(ctx)
	if err != nil {
		return fmt.Errorf("failed to get collection info: %w", err)
	}

	// Pretty print collection info
	fmt.Printf("Collection Information:\n")
	fmt.Printf("  Status: %s\n", info.Status)
	if config := info.GetConfig(); config != nil {
		if params := config.GetParams(); params != nil {
			if vectors := params.GetVectorsConfig(); vectors != nil {
				fmt.Printf("  Vector Size: %d\n", vectors.GetSize())
				fmt.Printf("  Distance: %s\n", vectors.GetDistance())
			}
		}
	}

	logger.Info("Collection info retrieved successfully")
	return nil
}

func deleteCollection(args []string) error {
	var force bool

	fs := flag.NewFlagSet("delete", flag.ExitOnError)
	fs.BoolVar(&force, "force", false, "Force deletion without confirmation")
	fs.Parse(args)

	if !force && !*dryRun {
		fmt.Print("Are you sure you want to delete the collection? (y/N): ")
		var response string
		fmt.Scanln(&response)
		if strings.ToLower(response) != "y" && strings.ToLower(response) != "yes" {
			fmt.Println("Deletion cancelled")
			return nil
		}
	}

	if *dryRun {
		logger.Info("DRY RUN: Would delete collection")
		return nil
	}

	client, err := createClient()
	if err != nil {
		return err
	}
	defer client.Close()

	ctx := context.Background()
	return client.DeleteCollection(ctx)
}

func exportVectors(args []string) error {
	var outputFile string
	var limit int

	fs := flag.NewFlagSet("export", flag.ExitOnError)
	fs.StringVar(&outputFile, "output", "exported_vectors.json", "Output file path")
	fs.IntVar(&limit, "limit", 1000, "Maximum number of vectors to export")
	fs.Parse(args)

	// For now, this is a placeholder since the Qdrant Go client
	// doesn't have a direct "list all points" method
	// In a real implementation, you'd need to use scroll or search with empty filter

	logger.Info("Export functionality not yet implemented - placeholder")

	if *dryRun {
		logger.Info("DRY RUN: Would export vectors",
			zap.String("output", outputFile),
			zap.Int("limit", limit))
	}

	return fmt.Errorf("export functionality not yet implemented")
}

func validateVectors(args []string) error {
	var inputFile string

	fs := flag.NewFlagSet("validate", flag.ExitOnError)
	fs.StringVar(&inputFile, "input", "vectors.json", "Input JSON file to validate")
	fs.Parse(args)

	// Load and validate vectors
	vectors, err := vectorization.LoadVectorsFromJSON(inputFile)
	if err != nil {
		return fmt.Errorf("failed to load vectors: %w", err)
	}

	logger.Info("Validating vectors", zap.Int("count", len(vectors)))

	// Validation checks
	errors := 0
	vectorSizes := make(map[int]int)

	for i, vector := range vectors {
		// Check vector ID
		if vector.ID == "" {
			logger.Warn("Vector missing ID", zap.Int("index", i))
			errors++
		}

		// Check vector data
		if len(vector.Vector) == 0 {
			logger.Warn("Vector has no data", zap.Int("index", i), zap.String("id", vector.ID))
			errors++
		}

		// Track vector sizes
		vectorSizes[len(vector.Vector)]++

		// Check for NaN or infinite values
		for j, val := range vector.Vector {
			if val != val { // NaN check
				logger.Warn("Vector contains NaN",
					zap.Int("vector_index", i),
					zap.Int("component_index", j),
					zap.String("id", vector.ID))
				errors++
			}
		}
	}

	// Print validation summary
	fmt.Printf("Validation Results:\n")
	fmt.Printf("  Total vectors: %d\n", len(vectors))
	fmt.Printf("  Errors found: %d\n", errors)
	fmt.Printf("  Vector sizes:\n")
	for size, count := range vectorSizes {
		fmt.Printf("    Size %d: %d vectors\n", size, count)
	}

	if errors > 0 {
		return fmt.Errorf("validation failed with %d errors", errors)
	}

	logger.Info("Validation completed successfully")
	return nil
}
