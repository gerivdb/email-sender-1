package main

import (
	"email_sender/src/providers"
	"fmt"
)

func main() {
	fmt.Println("=== Cache Eviction Logic Verification ===")

	// Test configuration: cache for exactly 2 embeddings
	maxSize := int64(1536 * 4 * 2) // 12,288 bytes for 2 embeddings

	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0), // 100% deterministic for testing
	)

	fmt.Printf("Cache max size: %d bytes\n", maxSize)
	fmt.Printf("Size per embedding: %d bytes\n", 1536*4)
	fmt.Printf("Expected capacity: 2 embeddings\n\n")

	// Test sequence that should trigger eviction
	sequence := []string{"first", "second", "third"}

	for i, text := range sequence {
		fmt.Printf("--- Step %d: Adding '%s' ---\n", i+1, text)

		// Embed the text
		_, err := provider.Embed(text)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			continue
		}

		// Check cache state
		fmt.Printf("Cache size: %d / %d bytes\n", provider.GetCacheSize(), maxSize)
		fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())

		// Check what's in cache
		for j := 0; j <= i; j++ {
			inCache := provider.IsInCache(sequence[j])
			fmt.Printf("  '%s' in cache: %t\n", sequence[j], inCache)
		}
		fmt.Println()
	}

	// Final verification according to FIFO logic
	fmt.Println("=== Final Verification ===")

	expected := map[string]bool{
		"first":  false, // Should be evicted (oldest)
		"second": true,  // Should remain
		"third":  true,  // Should remain
	}

	allCorrect := true
	for text, expectedInCache := range expected {
		actualInCache := provider.IsInCache(text)
		status := "✓ PASS"
		if actualInCache != expectedInCache {
			status = "✗ FAIL"
			allCorrect = false
		}
		fmt.Printf("%s - '%s': in cache = %t (expected: %t)\n",
			status, text, actualInCache, expectedInCache)
	}

	fmt.Printf("\nOverall result: ")
	if allCorrect {
		fmt.Printf("✓ ALL TESTS PASSED - Cache eviction logic is working correctly!\n")
	} else {
		fmt.Printf("✗ SOME TESTS FAILED - Cache eviction logic needs fixing\n")
	}

	fmt.Printf("\nFinal cache state:\n")
	fmt.Printf("Size: %d / %d bytes\n", provider.GetCacheSize(), maxSize)
	fmt.Printf("Contents: %v\n", provider.GetCacheContents())
}
