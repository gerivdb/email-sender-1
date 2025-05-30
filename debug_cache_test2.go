package main

import (
	"email_sender/src/providers"
	"fmt"
	"time"
)

func main() {
	maxSize := int64(1536 * 4 * 2) // Pour 2 embeddings exactement
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Printf("Cache max size: %d\n", maxSize)

	// Insérer les 3 textes et vérifier l'état du cache après chaque insertion
	sequence := []string{"first", "second", "third"}
	for i, text := range sequence {
		fmt.Printf("\n--- Inserting '%s' (step %d) ---\n", text, i+1)

		_, err := provider.Embed(text)
		if err != nil {
			fmt.Printf("Error embedding '%s': %v\n", text, err)
			continue
		}

		// Afficher l'état du cache
		fmt.Printf("Cache size after inserting '%s': %d\n", text, provider.GetCacheSize())

		// Tester si chaque élément de la séquence est toujours en cache
		for j := 0; j <= i; j++ {
			testText := sequence[j]
			start := time.Now()
			_, err := provider.Embed(testText)
			duration := time.Since(start)

			inCache := duration < 10*time.Millisecond && err == nil
			fmt.Printf("  '%s' in cache: %v (duration: %v)\n", testText, inCache, duration)
		}
	}

	fmt.Printf("\n--- Final Cache Test ---\n")
	// Test final selon la logique du test unitaire
	tests := []struct {
		text     string
		expected bool
		reason   string
	}{
		{"first", false, "should have been evicted (FIFO)"},
		{"second", true, "should still be in cache"},
		{"third", true, "should still be in cache"},
	}

	for _, test := range tests {
		start := time.Now()
		_, err := provider.Embed(test.text)
		duration := time.Since(start)

		inCache := duration < 10*time.Millisecond && err == nil
		status := "PASS"
		if inCache != test.expected {
			status = "FAIL"
		}

		fmt.Printf("%s - '%s': %v (expected: %v, duration: %v) - %s\n",
			status, test.text, inCache, test.expected, duration, test.reason)
	}
}
