// Package main provides the command-line interface for the contextual memory manager
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/manager"
)

// CLI represents the command-line interface
type CLI struct {
	manager interfaces.ContextualMemoryManager
	config  interfaces.Config
}

func main() {
	// Parse command line arguments
	var (
		command    = flag.String("command", "help", "Command to execute (help, init, index, search, delete, list, stats, health)")
		configFile = flag.String("config", "config.json", "Configuration file path")
		docID      = flag.String("id", "", "Document ID")
		content    = flag.String("content", "", "Document content")
		metadata   = flag.String("metadata", "", "Document metadata (JSON format)")
		query      = flag.String("query", "", "Search query")
		limit      = flag.Int("limit", 10, "Search result limit")
		offset     = flag.Int("offset", 0, "List offset")
		format     = flag.String("format", "json", "Output format (json, text)")
	)
	flag.Parse()
	cli := &CLI{}

	// For help and version commands, don't need full initialization
	if *command == "help" {
		cli.showHelp()
		return
	}

	if *command == "version" {
		fmt.Println("Contextual Memory Manager CLI v1.0.0")
		return
	}

	// Load configuration for other commands
	fmt.Printf("Loading configuration from: %s\n", *configFile)
	if err := cli.loadConfig(*configFile); err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}
	fmt.Println("Configuration loaded successfully")

	// Initialize manager
	fmt.Println("Creating manager...")
	cli.manager = manager.NewContextualMemoryManager()
	fmt.Println("Manager created successfully")

	ctx := context.Background()

	fmt.Printf("Executing command: %s\n", *command)
	// Execute command
	switch *command {
	case "init":
		cli.initialize(ctx)
	case "index":
		cli.indexDocument(ctx, *docID, *content, *metadata)
	case "search":
		cli.search(ctx, *query, *limit, *format)
	case "delete":
		cli.deleteDocument(ctx, *docID)
	case "get":
		cli.getDocument(ctx, *docID, *format)
	case "list":
		cli.listDocuments(ctx, *offset, *limit, *format)
	case "stats":
		cli.getStats(ctx, *format)
	case "health":
		cli.healthCheck(ctx)
	default:
		fmt.Printf("Unknown command: %s\n", *command)
		cli.showHelp()
		os.Exit(1)
	}
}

// loadConfig loads configuration from file
func (c *CLI) loadConfig(configFile string) error {
	// Try to load from file, if it doesn't exist, use default config
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		log.Printf("Configuration file %s not found, using default configuration", configFile)
		c.config = getDefaultConfig()
		return nil
	}

	data, err := os.ReadFile(configFile)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	if err := json.Unmarshal(data, &c.config); err != nil {
		return fmt.Errorf("failed to parse config file: %w", err)
	}

	return nil
}

// getDefaultConfig returns default configuration
func getDefaultConfig() interfaces.Config {
	return interfaces.Config{
		DatabaseURL: "sqlite:///tmp/contextual_memory.db",
		VectorDB: interfaces.VectorDBConfig{
			Type:       "qdrant",
			URL:        "http://localhost:6333",
			Collection: "documents",
			Dimension:  1536,
		},
		Embedding: interfaces.EmbeddingConfig{
			Provider:  "openai",
			Model:     "text-embedding-ada-002",
			Dimension: 1536,
		},
		Cache: interfaces.CacheConfig{
			Type:    "memory",
			TTL:     time.Hour,
			MaxSize: 1000,
		},
		Integrations: map[string]interface{}{
			"webhooks": map[string]interface{}{
				"enabled": true,
				"port":    8080,
			},
		},
	}
}

// showHelp displays help information
func (c *CLI) showHelp() {
	fmt.Println("Contextual Memory Manager CLI")
	fmt.Println("")
	fmt.Println("Commands:")
	fmt.Println("  help                                    Show this help message")
	fmt.Println("  init                                    Initialize the system")
	fmt.Println("  index -id ID -content TEXT [-metadata JSON]  Index a document")
	fmt.Println("  search -query TEXT [-limit N]          Search documents")
	fmt.Println("  get -id ID                              Get a document by ID")
	fmt.Println("  delete -id ID                           Delete a document")
	fmt.Println("  list [-offset N] [-limit N]            List documents")
	fmt.Println("  stats                                   Show system statistics")
	fmt.Println("  health                                  Check system health")
	fmt.Println("  version                                 Show version information")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  -config FILE                            Configuration file (default: config.json)")
	fmt.Println("  -format FORMAT                          Output format: json, text (default: json)")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println(`  contextual-memory-cli index -id "doc1" -content "Hello world"`)
	fmt.Println(`  contextual-memory-cli search -query "hello" -limit 5`)
	fmt.Println(`  contextual-memory-cli list -limit 20`)
}

// initialize initializes the contextual memory system
func (c *CLI) initialize(ctx context.Context) {
	fmt.Println("Initializing Contextual Memory Manager...")

	if err := c.manager.Initialize(ctx, c.config); err != nil {
		log.Fatalf("Failed to initialize: %v", err)
	}

	fmt.Println("✓ Contextual Memory Manager initialized successfully")
}

// indexDocument indexes a new document
func (c *CLI) indexDocument(ctx context.Context, docID, content, metadataStr string) {
	if docID == "" {
		log.Fatal("Document ID is required")
	}
	if content == "" {
		log.Fatal("Document content is required")
	}

	// Parse metadata if provided
	var metadata map[string]string
	if metadataStr != "" {
		if err := json.Unmarshal([]byte(metadataStr), &metadata); err != nil {
			log.Fatalf("Failed to parse metadata: %v", err)
		}
	}

	doc := interfaces.Document{
		ID:       docID,
		Content:  content,
		Metadata: metadata,
	}

	fmt.Printf("Indexing document %s...\n", docID)

	if err := c.manager.Index(ctx, doc); err != nil {
		log.Fatalf("Failed to index document: %v", err)
	}

	fmt.Printf("✓ Document %s indexed successfully\n", docID)
}

// search performs a search query
func (c *CLI) search(ctx context.Context, query string, limit int, format string) {
	if query == "" {
		log.Fatal("Search query is required")
	}

	fmt.Printf("Searching for: %s\n", query)

	results, err := c.manager.Search(ctx, query, limit)
	if err != nil {
		log.Fatalf("Failed to search: %v", err)
	}

	c.printSearchResults(results, format)
}

// deleteDocument deletes a document by ID
func (c *CLI) deleteDocument(ctx context.Context, docID string) {
	if docID == "" {
		log.Fatal("Document ID is required")
	}

	fmt.Printf("Deleting document %s...\n", docID)

	if err := c.manager.Delete(ctx, docID); err != nil {
		log.Fatalf("Failed to delete document: %v", err)
	}

	fmt.Printf("✓ Document %s deleted successfully\n", docID)
}

// getDocument retrieves a document by ID
func (c *CLI) getDocument(ctx context.Context, docID, format string) {
	if docID == "" {
		log.Fatal("Document ID is required")
	}

	doc, err := c.manager.GetDocument(ctx, docID)
	if err != nil {
		log.Fatalf("Failed to get document: %v", err)
	}

	c.printDocument(doc, format)
}

// listDocuments lists all documents
func (c *CLI) listDocuments(ctx context.Context, offset, limit int, format string) {
	fmt.Printf("Listing documents (offset: %d, limit: %d)...\n", offset, limit)

	docs, err := c.manager.ListDocuments(ctx, offset, limit)
	if err != nil {
		log.Fatalf("Failed to list documents: %v", err)
	}

	c.printDocuments(docs, format)
}

// getStats shows system statistics
func (c *CLI) getStats(ctx context.Context, format string) {
	stats, err := c.manager.GetStats(ctx)
	if err != nil {
		log.Fatalf("Failed to get stats: %v", err)
	}

	c.printStats(stats, format)
}

// healthCheck performs a system health check
func (c *CLI) healthCheck(ctx context.Context) {
	fmt.Println("Performing health check...")

	if err := c.manager.Health(ctx); err != nil {
		fmt.Printf("✗ Health check failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✓ System is healthy")
}

// getVersion shows version information
func (c *CLI) getVersion() {
	fmt.Printf("Contextual Memory Manager CLI v%s\n", c.manager.GetVersion())
}

// printSearchResults prints search results in the specified format
func (c *CLI) printSearchResults(results []interfaces.SearchResult, format string) {
	if format == "json" {
		data, _ := json.MarshalIndent(results, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Printf("Found %d results:\n\n", len(results))
		for i, result := range results {
			fmt.Printf("%d. Document ID: %s\n", i+1, result.Document.ID)
			fmt.Printf("   Score: %.4f\n", result.Score)
			fmt.Printf("   Content: %s\n", truncateString(result.Document.Content, 100))
			if len(result.Document.Metadata) > 0 {
				fmt.Printf("   Metadata: %v\n", result.Document.Metadata)
			}
			fmt.Println()
		}
	}
}

// printDocument prints a single document
func (c *CLI) printDocument(doc *interfaces.Document, format string) {
	if format == "json" {
		data, _ := json.MarshalIndent(doc, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Printf("Document ID: %s\n", doc.ID)
		fmt.Printf("Content: %s\n", doc.Content)
		if len(doc.Metadata) > 0 {
			fmt.Printf("Metadata: %v\n", doc.Metadata)
		}
	}
}

// printDocuments prints multiple documents
func (c *CLI) printDocuments(docs []interfaces.Document, format string) {
	if format == "json" {
		data, _ := json.MarshalIndent(docs, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Printf("Found %d documents:\n\n", len(docs))
		for i, doc := range docs {
			fmt.Printf("%d. Document ID: %s\n", i+1, doc.ID)
			fmt.Printf("   Content: %s\n", truncateString(doc.Content, 100))
			if len(doc.Metadata) > 0 {
				fmt.Printf("   Metadata: %v\n", doc.Metadata)
			}
			fmt.Println()
		}
	}
}

// printStats prints system statistics
func (c *CLI) printStats(stats interfaces.IndexStats, format string) {
	if format == "json" {
		data, _ := json.MarshalIndent(stats, "", "  ")
		fmt.Println(string(data))
	} else {
		fmt.Println("System Statistics:")
		fmt.Printf("  Total Documents: %d\n", stats.TotalDocuments)
		fmt.Printf("  Index Size: %d bytes\n", stats.IndexSize)
		fmt.Printf("  Vector Dimension: %d\n", stats.VectorDimension)
		fmt.Printf("  Last Updated: %s\n", stats.LastUpdated.Format(time.RFC3339))
	}
}

// truncateString truncates a string to the specified length
func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}
