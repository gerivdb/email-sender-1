package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/gerivdb/email-sender-1/src/indexing"

	"github.com/schollz/progressbar/v3"
)

type indexCommand struct {
	config     string
	source     string
	recursive  bool
	batchSize  int
	concurrent int
	timeout    time.Duration
	dryRun     bool
}

type statusCommand struct {
	config string
}

type purgeCommand struct {
	config string
	force  bool
}

func main() {
	// Main command flags
	configFlag := flag.String("config", "indexing_config.json", "Path to configuration file")

	// Subcommands
	indexCmd := flag.NewFlagSet("index", flag.ExitOnError)
	statusCmd := flag.NewFlagSet("status", flag.ExitOnError)
	purgeCmd := flag.NewFlagSet("purge", flag.ExitOnError)

	// index command flags
	index := &indexCommand{}
	indexCmd.StringVar(&index.config, "config", *configFlag, "Path to configuration file")
	indexCmd.StringVar(&index.source, "source", "", "Source directory or file to index")
	indexCmd.BoolVar(&index.recursive, "recursive", true, "Recursively process directories")
	indexCmd.IntVar(&index.batchSize, "batch-size", 100, "Number of documents to process in each batch")
	indexCmd.IntVar(&index.concurrent, "concurrent", 4, "Number of concurrent processing routines")
	indexCmd.DurationVar(&index.timeout, "timeout", 30*time.Minute, "Timeout for the entire operation")
	indexCmd.BoolVar(&index.dryRun, "dry-run", false, "Show what would be indexed without actually indexing")

	// status command flags
	status := &statusCommand{}
	statusCmd.StringVar(&status.config, "config", *configFlag, "Path to configuration file")

	// purge command flags
	purge := &purgeCommand{}
	purgeCmd.StringVar(&purge.config, "config", *configFlag, "Path to configuration file")
	purgeCmd.BoolVar(&purge.force, "force", false, "Force purge without confirmation")

	// Parse command line
	flag.Parse()

	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	// Handle subcommands
	switch os.Args[1] {
	case "index":
		indexCmd.Parse(os.Args[2:])
		if err := runIndex(index); err != nil {
			log.Fatal(err)
		}

	case "status":
		statusCmd.Parse(os.Args[2:])
		if err := runStatus(status); err != nil {
			log.Fatal(err)
		}

	case "purge":
		purgeCmd.Parse(os.Args[2:])
		if err := runPurge(purge); err != nil {
			log.Fatal(err)
		}

	default:
		printUsage()
		os.Exit(1)
	}
}

func runIndex(cmd *indexCommand) error {
	if cmd.source == "" {
		return fmt.Errorf("source directory or file required")
	}
	// Load configuration
	config, err := indexing.LoadConfig(cmd.config)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	// Override config with command line flags
	if cmd.batchSize > 0 {
		config.Batch.Size = cmd.batchSize
	}
	if cmd.concurrent > 0 {
		config.Batch.MaxConcurrent = cmd.concurrent
	}

	// Create batch indexer
	indexer, err := indexing.NewBatchIndexer(indexing.BatchIndexerConfig{
		QdrantHost:   config.Qdrant.Host,
		QdrantPort:   config.Qdrant.Port,
		Collection:   config.Qdrant.Collection,
		BatchSize:    config.Batch.Size,
		ChunkSize:    config.Chunking.ChunkSize,
		ChunkOverlap: config.Chunking.ChunkOverlap,
	})
	if err != nil {
		return fmt.Errorf("failed to create indexer: %v", err)
	}

	// Collect files to process
	var files []string
	err = filepath.Walk(cmd.source, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			ext := filepath.Ext(path)
			for _, supported := range config.FileTypes.SupportedFormats {
				if ext == supported {
					files = append(files, path)
					break
				}
			}
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to collect files: %v", err)
	}

	if len(files) == 0 {
		return fmt.Errorf("no supported files found in %s", cmd.source)
	}

	// If dry run, just print what would be indexed
	if cmd.dryRun {
		fmt.Printf("Would index %d files:\n", len(files))
		for _, f := range files {
			fmt.Printf("  %s\n", f)
		}
		return nil
	}
	// Create progress bar
	_ = progressbar.Default(int64(len(files)))

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), cmd.timeout)
	defer cancel()

	// Start indexing
	fmt.Printf("Starting indexing of %d files...\n", len(files))
	startTime := time.Now()

	err = indexer.IndexFiles(ctx, files)
	if err != nil {
		return fmt.Errorf("indexing failed: %v", err)
	}

	duration := time.Since(startTime)
	fmt.Printf("\nIndexing completed in %v\n", duration)
	return nil
}

func runStatus(cmd *statusCommand) error {
	config, err := indexing.LoadConfig(cmd.config)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	// Create Qdrant client and get collection stats
	// This would typically show:
	// - Number of documents indexed
	// - Total vectors stored
	// - Storage size
	// - Last indexing operation
	// - etc.

	fmt.Println("Collection Status:")
	fmt.Printf("Host: %s:%d\n", config.Qdrant.Host, config.Qdrant.Port)
	fmt.Printf("Collection: %s\n", config.Qdrant.Collection)
	// Add actual status information here

	return nil
}

func runPurge(cmd *purgeCommand) error {
	if !cmd.force {
		fmt.Print("Are you sure you want to purge the collection? [y/N] ")
		var response string
		fmt.Scanln(&response)
		if response != "y" && response != "Y" {
			fmt.Println("Purge cancelled")
			return nil
		}
	}

	config, err := indexing.LoadConfig(cmd.config)
	if err != nil {
		return fmt.Errorf("failed to load config: %v", err)
	}

	// Implement purge logic here
	fmt.Printf("Purging collection %s...\n", config.Qdrant.Collection)

	return nil
}

func printUsage() {
	fmt.Println("Usage:")
	fmt.Println("  index    Index documents into Qdrant")
	fmt.Println("  status   Show indexing status")
	fmt.Println("  purge    Remove all documents from collection")
	fmt.Println("\nRun '[command] -h' for detailed usage of each command")
}
