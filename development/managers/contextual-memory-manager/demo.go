package contextual_memory_manager

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	cmmInterfaces "github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	cmmManager "github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/manager"
)

// Demo function to test the contextual memory system end-to-end
func RunDemo() {
	fmt.Println("=== Contextual Memory Manager Demo ===")

	// Create manager
	mgr := cmmManager.NewContextualMemoryManager()

	// Create test configuration
	config := cmmInterfaces.Config{
		DatabaseURL:	"sqlite:///tmp/demo.db",
		VectorDB: cmmInterfaces.VectorDBConfig{
			Type:		"qdrant",
			URL:		"http://localhost:6333",
			Collection:	"documents",
			Dimension:	1536,
		},
		Embedding: cmmInterfaces.EmbeddingConfig{
			Provider:	"openai",
			Model:		"text-embedding-ada-002",
			Dimension:	1536,
		},
		Cache: cmmInterfaces.CacheConfig{
			Type:		"memory",
			TTL:		time.Hour,
			MaxSize:	1000,
		},
		Integrations: map[string]interface{}{
			"webhooks": map[string]interface{}{
				"enabled":	true,
				"port":		8080,
			},
		},
	}

	ctx := context.Background()

	// Test 1: Version
	fmt.Printf("Manager Version: %s\n", mgr.GetVersion())

	// Test 2: Initialize (this will use mock implementations)
	fmt.Println("\nInitializing manager...")
	if err := mgr.Initialize(ctx, config); err != nil {
		log.Printf("Note: Initialization failed as expected (using mocks): %v", err)
	} else {
		fmt.Println("✓ Manager initialized successfully")
	}

	// Test 3: Create test document
	testDoc := cmmInterfaces.Document{
		ID:		"test-doc-1",
		Content:	"This is a test document for the contextual memory system",
		Metadata: map[string]string{
			"type":		"test",
			"author":	"demo",
			"created":	time.Now().Format(time.RFC3339),
		},
	}

	// Test 4: Index document (will likely fail with mock, but that's expected)
	fmt.Println("\nTesting document indexing...")
	if err := mgr.Index(ctx, testDoc); err != nil {
		log.Printf("Note: Indexing failed as expected (using mocks): %v", err)
	} else {
		fmt.Printf("✓ Document '%s' indexed successfully\n", testDoc.ID)
	}

	// Test 5: Health check
	fmt.Println("\nPerforming health check...")
	if err := mgr.Health(ctx); err != nil {
		log.Printf("Note: Health check failed as expected (using mocks): %v", err)
	} else {
		fmt.Println("✓ System health check passed")
	}

	// Test 6: Get stats
	fmt.Println("\nGetting system stats...")
	stats, err := mgr.GetStats(ctx)
	if err != nil {
		log.Printf("Note: Stats failed as expected (using mocks): %v", err)
	} else {
		statsJSON, _ := json.MarshalIndent(stats, "", "  ")
		fmt.Printf("✓ System stats:\n%s\n", statsJSON)
	}

	fmt.Println("\n=== Demo Complete ===")
	fmt.Println("Note: Some operations failed as expected since we're using mock implementations.")
	fmt.Println("In a real deployment, you would configure actual Qdrant and OpenAI connections.")
}
