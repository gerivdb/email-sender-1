package main

import (
	"email_sender/src/providers"
	"fmt"
)

func main() {
	// Test simple pour debug du cache
	maxSize := int64(1536 * 4 * 2) // Pour 2 embeddings exactement
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Printf("Cache max size: %d\n", maxSize)

	texts := []string{"text1", "text2", "text3"}

	for i, text := range texts {
		fmt.Printf("\n--- Avant ajout de %s ---\n", text)
		fmt.Printf("Cache size: %d\n", provider.GetCacheSize())
		fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())

		_, err := provider.Embed(text)
		if err != nil {
			fmt.Printf("Erreur: %v\n", err)
		}

		fmt.Printf("--- Après ajout de %s ---\n", text)
		fmt.Printf("Cache size: %d\n", provider.GetCacheSize())
		fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())
	}

	fmt.Printf("\n--- Test cache hits ---\n")

	// Test text2
	fmt.Printf("Testing text2...\n")
	embed := provider.GetCacheContents()
	fmt.Printf("Cache contents before text2: %v\n", embed)

	for _, text := range []string{"text2", "text3"} {
		if embedding := testCacheHit(provider, text); embedding != nil {
			fmt.Printf("%s: CACHE HIT\n", text)
		} else {
			fmt.Printf("%s: CACHE MISS\n", text)
		}
	}
}

func testCacheHit(provider *providers.MockEmbeddingProvider, text string) []float32 {
	// On simule checkCache - nous devons accéder au cache directement
	contents := provider.GetCacheContents()
	for _, key := range contents {
		if key == text {
			return []float32{1.0} // Trouvé
		}
	}
	return nil // Pas trouvé
}
