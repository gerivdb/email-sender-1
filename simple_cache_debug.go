package main

import (
	"email_sender/src/providers"
	"log"
	"os"
	"time"
	"fmt"
)

func main() {
	// Open debug file
	debugFile, err := os.Create("cache_debug.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer debugFile.Close()

	maxSize := int64(1536 * 4 * 2) // Pour 2 embeddings exactement
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Fprintf(debugFile, "Cache max size: %d bytes\n", maxSize)

	// Test the exact sequence from the failing test
	sequence := []string{"first", "second", "third"}
	for i, text := range sequence {
		fmt.Fprintf(debugFile, "\n--- Inserting '%s' (step %d) ---\n", text, i+1)
		
		_, err := provider.Embed(text)
		if err != nil {
			fmt.Fprintf(debugFile, "Error embedding '%s': %v\n", text, err)
			continue
		}
		
		fmt.Fprintf(debugFile, "Cache size after inserting '%s': %d\n", text, provider.GetCacheSize())
	}

	fmt.Fprintf(debugFile, "\n--- Testing cache hits ---\n")
	
	// Test each item to see if it's in cache
	testItems := []string{"first", "second", "third"}
	for _, text := range testItems {
		start := time.Now()
		_, err := provider.Embed(text)
		duration := time.Since(start)
		
		inCache := duration < 10*time.Millisecond && err == nil
		fmt.Fprintf(debugFile, "'%s': duration=%v, error=%v, inCache=%v\n", 
			text, duration, err, inCache)
	}

	fmt.Fprintf(debugFile, "\nFinal cache size: %d\n", provider.GetCacheSize())
}
