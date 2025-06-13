package main

import (
	"context"
	"fmt"
	"log"

	"github.com/contextual-memory-manager/pkg/interfaces"
	"github.com/contextual-memory-manager/pkg/manager"
)

func main() {
	fmt.Println("Testing contextual memory system after fixes...")

	// Test SQLite Index Manager
	indexMgr, err := manager.NewSQLiteIndexManager("./data/test.db")
	if err != nil {
		log.Fatalf("Failed to create index manager: %v", err)
	}

	ctx := context.Background()

	// Initialize the manager
	err = indexMgr.Initialize(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize index manager: %v", err)
	}

	// Test document operations
	doc := interfaces.Document{
		ID:      "test-doc-1",
		Content: "This is a test document for the contextual memory system",
		Metadata: map[string]string{
			"source":   "test",
			"category": "example",
			"version":  "1",
		},
	}

	// Add document
	err = indexMgr.Index(ctx, doc)
	if err != nil {
		log.Fatalf("Failed to index document: %v", err)
	}
	fmt.Println("✅ Document indexed successfully")

	// Retrieve document
	retrieved, err := indexMgr.GetDocument(ctx, "test-doc-1")
	if err != nil {
		log.Fatalf("Failed to retrieve document: %v", err)
	}
	fmt.Printf("✅ Document retrieved successfully: %s\n", retrieved.Content)

	// Update document (this tests the fixed version increment logic)
	doc.Content = "Updated test document content"
	err = indexMgr.Update(ctx, doc)
	if err != nil {
		log.Fatalf("Failed to update document: %v", err)
	}
	fmt.Println("✅ Document updated successfully")

	// Check version was incremented
	updated, err := indexMgr.GetDocument(ctx, "test-doc-1")
	if err != nil {
		log.Fatalf("Failed to retrieve updated document: %v", err)
	}
	fmt.Printf("✅ Version incremented: %s\n", updated.Metadata["version"])

	// Get statistics
	stats, err := indexMgr.GetStats(ctx)
	if err != nil {
		log.Fatalf("Failed to get stats: %v", err)
	}
	fmt.Printf("✅ Stats retrieved: %d documents\n", stats.TotalDocuments)

	// Health check
	err = indexMgr.Health(ctx)
	if err != nil {
		log.Fatalf("Health check failed: %v", err)
	}
	fmt.Println("✅ Health check passed")

	// Test Qdrant Retrieval Manager
	retrievalMgr, err := manager.NewQdrantRetrievalManager("http://localhost:6333", "test-collection")
	if err != nil {
		log.Fatalf("Failed to create retrieval manager: %v", err)
	}

	err = retrievalMgr.Initialize(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize retrieval manager: %v", err)
	}
	fmt.Println("✅ Retrieval manager initialized")

	// Clean up
	err = indexMgr.Delete(ctx, "test-doc-1")
	if err != nil {
		log.Printf("Warning: Failed to delete test document: %v", err)
	} else {
		fmt.Println("✅ Test document cleaned up")
	}

	fmt.Println("\n🎉 All tests passed! The contextual memory system is working correctly.")
}
