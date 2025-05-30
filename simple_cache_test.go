package main

import (
	"email_sender/src/providers"
	"fmt"
	"os"
)

func main() {
	// Create a file to write results (bypass antivirus console blocking)
	file, _ := os.Create("test_results.txt")
	defer file.Close()

	maxSize := int64(1536 * 4 * 2) // For exactly 2 embeddings
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Fprintf(file, "Testing cache eviction with maxSize=%d\n", maxSize)

	// Insert the 3 embeddings
	sequence := []string{"first", "second", "third"}
	for _, text := range sequence {
		provider.Embed(text)
		fmt.Fprintf(file, "Inserted '%s', cache size: %d\n", text, provider.GetCacheSize())
	}

	// Check final state
	fmt.Fprintf(file, "\nFinal cache state:\n")
	for _, text := range sequence {
		inCache := provider.IsInCache(text)
		fmt.Fprintf(file, "'%s' in cache: %t\n", text, inCache)
	}

	// Expected: first=false, second=true, third=true
	expectedResults := map[string]bool{
		"first":  false,
		"second": true,
		"third":  true,
	}

	allPassed := true
	fmt.Fprintf(file, "\nTest results:\n")
	for text, expected := range expectedResults {
		actual := provider.IsInCache(text)
		if actual == expected {
			fmt.Fprintf(file, "PASS: '%s' expected=%t, actual=%t\n", text, expected, actual)
		} else {
			fmt.Fprintf(file, "FAIL: '%s' expected=%t, actual=%t\n", text, expected, actual)
			allPassed = false
		}
	}

	if allPassed {
		fmt.Fprintf(file, "\nOVERALL: ALL TESTS PASSED\n")
		fmt.Println("All tests passed! Check test_results.txt")
	} else {
		fmt.Fprintf(file, "\nOVERALL: SOME TESTS FAILED\n")
		fmt.Println("Some tests failed! Check test_results.txt")
	}
}
