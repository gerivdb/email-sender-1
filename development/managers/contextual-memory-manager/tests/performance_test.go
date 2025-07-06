package tests

import (
	"context"
	"fmt"
	"log"
	"testing"
	"time"

	cmmInterfaces "github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	cmmManager "github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/manager"

	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

func TestPerformance(t *testing.T) {
	fmt.Println("=== Performance Test ===")

	// Initialize the manager with mock dependencies
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	manager := cmmManager.NewContextualMemoryManager()
	require.NotNil(t, manager)

	// Create a test configuration for the manager
	config := cmmInterfaces.Config{
		DatabaseURL: "sqlite:///tmp/performance.db",
		VectorDB: cmmInterfaces.VectorDBConfig{
			Type:       "qdrant",
			URL:        "http://localhost:6333",
			Collection: "perf_docs",
			Dimension:  1536,
		},
		Embedding: cmmInterfaces.EmbeddingConfig{
			Provider:  "openai",
			Model:     "text-embedding-ada-002",
			Dimension: 1536,
		},
		Cache: cmmInterfaces.CacheConfig{
			Type:    "memory",
			TTL:     time.Hour,
			MaxSize: 1000,
		},
	}

	ctx := context.Background()

	// Initialize the manager
	fmt.Println("Initializing manager for performance test...")
	err := manager.Initialize(ctx, config)
	if err != nil {
		log.Fatalf("Failed to initialize manager: %v", err)
	}
	fmt.Println("Manager initialized.")

	// Test Indexing Performance
	numDocs := 100
	fmt.Printf("\nTesting indexing performance for %d documents...\n", numDocs)
	start := time.Now()
	for i := 0; i < numDocs; i++ {
		doc := cmmInterfaces.Document{
			ID:      fmt.Sprintf("perf-doc-%d", i),
			Content: fmt.Sprintf("This is a performance test document number %d.", i),
			Metadata: map[string]string{
				"test_type": "performance",
				"sequence":  fmt.Sprintf("%d", i),
			},
		}
		err := manager.Index(ctx, doc)
		if err != nil {
			log.Fatalf("Failed to index document %d: %v", i, err)
		}
	}
	duration := time.Since(start)
	fmt.Printf("Indexed %d documents in %s (Avg: %s/doc)\n", numDocs, duration, duration/time.Duration(numDocs))

	// Test Search Performance
	numSearches := 50
	fmt.Printf("\nTesting search performance for %d queries...\n", numSearches)
	searchQuery := "performance test document"
	start = time.Now()
	for i := 0; i < numSearches; i++ {
		_, err := manager.Search(ctx, searchQuery, 5) // Search for top 5 results
		if err != nil {
			log.Fatalf("Failed to search document %d: %v", i, err)
		}
	}
	duration = time.Since(start)
	fmt.Printf("Performed %d searches in %s (Avg: %s/search)\n", numSearches, duration, duration/time.Duration(numSearches))

	// Test GetStats Performance
	fmt.Println("\nTesting GetStats performance...")
	start = time.Now()
	_, err = manager.GetStats(ctx)
	if err != nil {
		log.Fatalf("Failed to get stats: %v", err)
	}
	duration = time.Since(start)
	fmt.Printf("GetStats took %s\n", duration)

	fmt.Println("\n=== Performance Test Complete ===")
}
