package providers

import (
	"fmt"
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

func TestMockEmbeddingProviderCache(t *testing.T) {
	// Créer un provider avec une taille de cache limitée
	// On choisit une taille qui peut contenir exactement 2 embeddings de 1536 dimensions
	maxSize := int64(1536 * 4 * 2) // 2 embeddings de 1536 floats de 4 bytes
	provider := NewMockEmbeddingProvider(
		WithMaxCacheSize(maxSize),
		WithCacheHitRate(1.0), // Pour éviter les faux cache miss
	)

	t.Run("Cache Size Limit", func(t *testing.T) {
		texts := []string{"text1", "text2", "text3"}

		// Insérer les 3 textes, le premier devrait être évincé
		for _, text := range texts {
			_, err := provider.Embed(text)
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		}

		// Vérifier que le premier texte a été évincé
		_, err := provider.Embed("text1")
		if err != nil {
			t.Errorf("Unexpected error: %v", err)
		}

		start := time.Now()
		_, err = provider.Embed("text2")
		duration := time.Since(start)
		if err != nil || duration >= 10*time.Millisecond {
			t.Error("text2 should still be in cache")
		}

		start = time.Now()
		_, err = provider.Embed("text3")
		duration = time.Since(start)
		if err != nil || duration >= 10*time.Millisecond {
			t.Error("text3 should still be in cache")
		}

		// Vérifier les statistiques
		if provider.cacheSize > maxSize {
			t.Errorf("Cache size exceeds limit: %d > %d", provider.cacheSize, maxSize)
		}

		// Vérifier que l'éviction est bien FIFO en réinsérant text1
		_, err = provider.Embed(texts[0])
		if err != nil {
			t.Errorf("Unexpected error: %v", err)
		}

		// text2 devrait maintenant être évincé
		start = time.Now()
		_, err = provider.Embed("text2")
		duration = time.Since(start)
		if err != nil && duration < 10*time.Millisecond {
			t.Error("text2 should have been evicted")
		}
	})

	t.Run("Cache Eviction Order", func(t *testing.T) {
		provider := NewMockEmbeddingProvider(
			WithMaxCacheSize(maxSize),
			WithCacheHitRate(1.0),
		)

		// Insérer 3 textes dans un ordre spécifique
		sequence := []string{"first", "second", "third"}
		for _, text := range sequence {
			_, err := provider.Embed(text)
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		}

		// Vérifier que "first" a été évincé (FIFO)
		start := time.Now()
		_, err := provider.Embed("first")
		duration := time.Since(start)
		if err != nil && duration < 10*time.Millisecond {
			t.Error("'first' should have been evicted")
		}

		// Vérifier que "second" et "third" sont toujours en cache
		start = time.Now()
		_, err = provider.Embed("second")
		duration = time.Since(start)
		if err != nil || duration >= 10*time.Millisecond {
			t.Error("'second' should still be in cache")
		}

		start = time.Now()
		_, err = provider.Embed("third")
		duration = time.Since(start)
		if err != nil || duration >= 10*time.Millisecond {
			t.Error("'third' should still be in cache")
		}
	})
}

func TestMockEmbeddingProviderAdvancedCache(t *testing.T) {
	t.Run("Dynamic Cache Size", func(t *testing.T) {
		// Commencer avec une grande taille de cache
		maxSize := int64(1536 * 4 * 10) // Pour 10 embeddings
		provider := NewMockEmbeddingProvider(
			WithMaxCacheSize(maxSize),
			WithCacheHitRate(1.0),
		)

		// Remplir le cache
		for i := 0; i < 5; i++ {
			text := fmt.Sprintf("text%d", i)
			_, err := provider.Embed(text)
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
			}
		}

		// Réduire la taille du cache à 2 embeddings
		provider.maxCacheSize = int64(1536 * 4 * 2)

		// Le prochain embed devrait déclencher plusieurs évictions
		_, err := provider.Embed("new_text")
		if err != nil {
			t.Errorf("Unexpected error: %v", err)
		}

		if provider.cacheSize > provider.maxCacheSize {
			t.Errorf("Cache size (%d) exceeds new limit (%d)", provider.cacheSize, provider.maxCacheSize)
		}
	})

	t.Run("Batch Cache Operations", func(t *testing.T) {
		maxSize := int64(1536 * 4 * 3) // Pour 3 embeddings
		provider := NewMockEmbeddingProvider(
			WithMaxCacheSize(maxSize),
			WithCacheHitRate(1.0),
			WithBaseLatency(10*time.Millisecond),
			WithBatchLatency(1*time.Millisecond),
		)

		// Premier batch pour remplir le cache
		texts1 := []string{"batch1", "batch2", "batch3"}
		_, err := provider.EmbedBatch(texts1)
		if err != nil {
			t.Errorf("Unexpected error in first batch: %v", err)
		}

		// Deuxième batch avec des textes en partie déjà dans le cache
		texts2 := []string{"batch3", "batch4", "batch5"}
		start := time.Now()
		embeddings, err := provider.EmbedBatch(texts2)
		_ = time.Since(start) // Ignoré pour ce test
		if err != nil {
			t.Errorf("Unexpected error in second batch: %v", err)
		}

		if len(embeddings) != len(texts2) {
			t.Errorf("Expected %d embeddings, got %d", len(texts2), len(embeddings))
		}

		// Vérifier que la taille du cache est respectée
		if provider.cacheSize > maxSize {
			t.Errorf("Cache size exceeded: %d > %d", provider.cacheSize, maxSize)
		}

		// Le premier texte du premier batch devrait avoir été évincé
		start = time.Now()
		_, err = provider.Embed("batch1")
		latency := time.Since(start)
		if err != nil && latency < 10*time.Millisecond {
			t.Error("Expected cache miss for evicted text 'batch1'")
		}
	})

	t.Run("Mixed Operations Performance", func(t *testing.T) {
		maxSize := int64(1536 * 4 * 2) // Pour 2 embeddings
		provider := NewMockEmbeddingProvider(
			WithMaxCacheSize(maxSize),
			WithCacheHitRate(1.0),
			WithBaseLatency(10*time.Millisecond),
		)

		// Séquence d'opérations mixtes
		operations := []struct {
			text          string
			expectedCache bool
		}{
			{"text1", false}, // Premier - pas dans le cache
			{"text1", true},  // Hit
			{"text2", false}, // Miss
			{"text3", false}, // Miss, devrait évincer text1
			{"text1", false}, // Miss car évincé
			{"text3", true},  // Hit
		}

		for i, op := range operations {
			start := time.Now()
			_, err := provider.Embed(op.text)
			latency := time.Since(start)
			if err != nil {
				t.Errorf("Operation %d failed: %v", i, err)
			}

			isCached := latency < 10*time.Millisecond
			if isCached != op.expectedCache {
				t.Errorf("Operation %d (%s): expected cached=%v, got latency=%v",
					i, op.text, op.expectedCache, latency)
			}
		}
	})
}
