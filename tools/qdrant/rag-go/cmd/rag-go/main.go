package main

import (
	"fmt"
	"log"
	"os"
	"rag-go-system/pkg/client"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		return
	}

	command := os.Args[1]
	qdrantClient := client.NewQdrantClient("http://localhost:6333")

	switch command {
	case "test":
		testConnection(qdrantClient)
	case "index":
		if len(os.Args) < 3 {
			fmt.Println("Usage: rag-go index <document>")
			return
		}
		indexDocument(qdrantClient, os.Args[2])
	case "search":
		if len(os.Args) < 3 {
			fmt.Println("Usage: rag-go search <query>")
			return
		}
		searchDocuments(qdrantClient, os.Args[2])
	default:
		printUsage()
	}
}

func printUsage() {
	fmt.Println("RAG-Go System v1.0")
	fmt.Println("Usage:")
	fmt.Println("  rag-go test              - Test connection to QDrant")
	fmt.Println("  rag-go index <document>  - Index a document")
	fmt.Println("  rag-go search <query>    - Search documents")
}

func testConnection(client *client.QdrantClient) {
	fmt.Println("Testing QDrant connection...")
	
	if err := client.HealthCheck(); err != nil {
		log.Fatalf("Connection failed: %v", err)
	}
	
	fmt.Println("✓ QDrant connection successful!")
}

func indexDocument(client *client.QdrantClient, document string) {
	fmt.Printf("Indexing document: %s\n", document)
	
	// Créer collection si elle n'existe pas
	err := client.CreateCollection("documents", 384)
	if err != nil {
		fmt.Printf("Collection exists or created: %v\n", err)
	}
	
	// Simuler un vecteur (à remplacer par de vrais embeddings)
	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = 0.1 // Simulation simple
	}
	
	// Créer le point
	points := []client.Point{
		{
			ID:     "doc_" + document,
			Vector: vector,
			Payload: map[string]interface{}{
				"content": "Contenu de " + document,
				"source":  document,
			},
		},
	}
	
	// Indexer
	if err := client.UpsertPoints("documents", points); err != nil {
		log.Fatalf("Indexing failed: %v", err)
	}
	
	fmt.Println("✓ Document indexed successfully!")
}

func searchDocuments(client *client.QdrantClient, query string) {
	fmt.Printf("Searching for: %s\n", query)
	
	// Simuler un vecteur de requête
	vector := make([]float32, 384)
	for i := range vector {
		vector[i] = 0.1 // Simulation simple
	}
	
	// Rechercher
	results, err := client.Search("documents", client.SearchRequest{
		Vector:      vector,
		Limit:       5,
		WithPayload: true,
	})
	
	if err != nil {
		log.Fatalf("Search failed: %v", err)
	}
	
	fmt.Printf("Found %d results:\n", len(results))
	for i, result := range results {
		fmt.Printf("%d. Score: %.4f\n", i+1, result.Score)
		if content, ok := result.Payload["content"]; ok {
			fmt.Printf("   Content: %s\n", content)
		}
		if source, ok := result.Payload["source"]; ok {
			fmt.Printf("   Source: %s\n", source)
		}
		fmt.Println()
	}
}