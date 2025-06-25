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
		indexTest(qdrantClient)
	case "search":
		searchTest(qdrantClient)
	default:
		printUsage()
	}
}

func printUsage() {
	fmt.Println("RAG-Go System v1.0")
	fmt.Println("Commands: test, index, search")
}

func testConnection(client *client.QdrantClient) {
	fmt.Println("Testing QDrant...")
	if err := client.HealthCheck(); err != nil {
		log.Fatalf("Failed: %v", err)
	}
	fmt.Println("✓ QDrant OK!")
}

func indexTest(client *client.QdrantClient) {
	fmt.Println("Testing indexing...")
	err := client.CreateCollection("test", 384)
	if err != nil {
		fmt.Printf("Collection: %v\n", err)
	}
	fmt.Println("✓ Indexing ready!")
}

func searchTest(client *client.QdrantClient) {
	fmt.Println("Testing search...")
	vector := make([]float32, 384)
	results, err := client.Search("test", client.SearchRequest{
		Vector: vector,
		Limit:  3,
	})
	if err != nil {
		log.Printf("Search error: %v", err)
		return
	}
	fmt.Printf("✓ Found %d results\n", len(results))
}
