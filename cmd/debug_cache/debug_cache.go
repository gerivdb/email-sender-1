<<<<<<< HEAD:cmd/debug_cache/debug_cache.go
// Moved from debug_cache_test.go
package debug_cache

import (
	"email_sender/src/providers"
	"fmt"
)

func main() {
	// Test simple pour debug du cache
	maxSize := int64(1536 * 4 * 2)	// Pour 2 embeddings exactement
	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0),
	)

	fmt.Printf("Cache max size: %d\n", maxSize)

	texts := []string{"text1", "text2", "text3"}

	for _, text := range texts {
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
}
=======
// Moved from debug_cache_test.go
package main

import (
	"fmt"

	"github.com/gerivdb/email-sender-1/src/providers"
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

	for _, text := range texts {
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
}
>>>>>>> migration/gateway-manager-v77:cmd/debug_cache/main.go
