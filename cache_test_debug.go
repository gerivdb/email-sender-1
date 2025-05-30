package main

import (
	"email_sender/src/providers"
	"fmt"
	"os"
)

func main() {
	// Open debug file
	file, err := os.Create("cache_debug_output.txt")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	maxSize := int64(1536 * 4 * 2) // Pour 2 embeddings exactement
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Fprintf(file, "Cache max size: %d bytes\n", maxSize)
	fmt.Fprintf(file, "Expected size per embedding: %d bytes\n", 1536*4)

	// Test the exact sequence from the failing test
	sequence := []string{"first", "second", "third"}
	for i, text := range sequence {
		fmt.Fprintf(file, "\n--- Step %d: Inserting '%s' ---\n", i+1, text)

		_, err := provider.Embed(text)
		if err != nil {
			fmt.Fprintf(file, "Error embedding '%s': %v\n", text, err)
			continue
		}

		// Check cache state
		fmt.Fprintf(file, "Cache size after '%s': %d\n", text, provider.GetCacheSize())
		cacheContents := provider.GetCacheContents()
		fmt.Fprintf(file, "Cache contents: %v\n", cacheContents)

		// Test what's in cache
		for j := 0; j <= i; j++ {
			inCache := provider.IsInCache(sequence[j])
			fmt.Fprintf(file, "  '%s' in cache: %v\n", sequence[j], inCache)
		}
	}

	fmt.Fprintf(file, "\n--- Final Test Results ---\n")

	// The expected result according to FIFO with cache size for 2 embeddings:
	// After inserting "first", "second", "third" → "first" should be evicted
	expectedResults := map[string]bool{
		"first":  false, // should be evicted
		"second": true,  // should remain
		"third":  true,  // should remain
	}

	allPassed := true
	for text, expected := range expectedResults {
		actual := provider.IsInCache(text)
		status := "PASS"
		if actual != expected {
			status = "FAIL"
			allPassed = false
		}
		fmt.Fprintf(file, "%s - '%s': in cache = %v (expected: %v)\n",
			status, text, actual, expected)
	}

	fmt.Fprintf(file, "\nOverall result: ")
	if allPassed {
		fmt.Fprintf(file, "ALL TESTS PASSED\n")
	} else {
		fmt.Fprintf(file, "SOME TESTS FAILED\n")
	}

	fmt.Fprintf(file, "\nFinal cache state:\n")
	fmt.Fprintf(file, "Cache size: %d / %d bytes\n", provider.GetCacheSize(), maxSize)
	fmt.Fprintf(file, "Cache contents: %v\n", provider.GetCacheContents())

	// Close file and print to console
	file.Close()

	// Read the file back and print to console
	content, _ := os.ReadFile("cache_debug_output.txt")
	fmt.Print(string(content))
}
