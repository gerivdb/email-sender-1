package main

import (
	"fmt"

	"github.com/qdrant/go-client/qdrant"
)

func main() {
	fmt.Println("Testing Qdrant types...")

	// Test creating a config
	config := &qdrant.Config{
		Host: "localhost",
		Port: 6333,
	}
	fmt.Printf("Config: %+v\n", config)
}
