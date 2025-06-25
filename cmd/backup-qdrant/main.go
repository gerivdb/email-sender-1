package main

import (
	"fmt"
	"log"

	"github.com/qdrant/go-client/qdrant"
)

func main() {
	// Configuration basique  
	config := &qdrant.Config{
		Host: "localhost",
		Port: 6334,
	}

	log.Printf("Creating Qdrant client with config: %+v", config)

	// Essayer de créer un client
	client, err := qdrant.NewClient(config)
	if err != nil {
		log.Fatalf("Failed to create Qdrant client: %v", err)
	}

	fmt.Printf("✅ Qdrant client created successfully: %T\n", client)
	fmt.Println("🎉 backup-qdrant main structure test - PASSED")
}
