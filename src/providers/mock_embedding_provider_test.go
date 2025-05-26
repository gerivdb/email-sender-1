package providers

import (
	"testing"
	"time"
)

func TestMockEmbeddingProvider(t *testing.T) {
	// Créer un provider avec des latences courtes pour les tests
	provider := NewMockEmbeddingProvider(
		WithBaseLatency(10*time.Millisecond),
		WithBatchLatency(1*time.Millisecond),
		WithCacheHitRate(0.8),
	)

	t.Run("Single Embedding", func(t *testing.T) {
		text := "test text"
		embedding, err := provider.Embed(text)
		if err != nil {
			t.Errorf("Unexpected error: %v", err)
		}
		if len(embedding) != 1536 {
			t.Errorf("Expected embedding dimension 1536, got %d", len(embedding))
		}

		// Tester le cache
		start := time.Now()
		embedding2, _ := provider.Embed(text)
		duration := time.Since(start)

		if duration >= 10*time.Millisecond {
			t.Errorf("Cache miss: operation took too long (%v)", duration)
		}
		if len(embedding2) != 1536 {
			t.Errorf("Cached embedding has wrong dimension: %d", len(embedding2))
		}
	})

	t.Run("Batch Embedding", func(t *testing.T) {
		texts := []string{"text1", "text2", "text3"}
		embeddings, err := provider.EmbedBatch(texts)
		if err != nil {
			t.Errorf("Unexpected error: %v", err)
		}
		if len(embeddings) != len(texts) {
			t.Errorf("Expected %d embeddings, got %d", len(texts), len(embeddings))
		}
		for i, embedding := range embeddings {
			if len(embedding) != 1536 {
				t.Errorf("Embedding %d has wrong dimension: %d", i, len(embedding))
			}
		}
	})

	t.Run("Statistics", func(t *testing.T) {
		// Réinitialiser avec un nouveau provider
		provider := NewMockEmbeddingProvider()
		
		// Faire quelques requêtes
		text := "test stats"
		provider.Embed(text)
		provider.Embed(text) // Devrait être un cache hit
		
		totalReqs, cacheHits, avgLatency := provider.GetStats()
		
		if totalReqs != 2 {
			t.Errorf("Expected 2 total requests, got %d", totalReqs)
		}
		if cacheHits != 1 {
			t.Errorf("Expected 1 cache hit, got %d", cacheHits)
		}
		if avgLatency <= 0 {
			t.Errorf("Average latency should be positive, got %v", avgLatency)
		}
	})
}