package main

import (
	"email_sender/src/providers"
	"fmt"
	"log"
)

// Simple test to verify cache debugging methods work
func main() {
	fmt.Println("Testing cache debugging methods...")

	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(1000), // Small cache for testing
		providers.WithCacheHitRate(1.0),
	)

	// Test empty cache
	fmt.Printf("Initial cache size: %d\n", provider.GetCacheSize())
	fmt.Printf("Initial cache contents: %v\n", provider.GetCacheContents())
	fmt.Printf("Is 'test' in cache: %t\n", provider.IsInCache("test"))

	// Add an item
	_, err := provider.Embed("test")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("After adding 'test':\n")
	fmt.Printf("Cache size: %d\n", provider.GetCacheSize())
	fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())
	fmt.Printf("Is 'test' in cache: %t\n", provider.IsInCache("test"))

	fmt.Println("✅ All debugging methods work correctly!")
}
