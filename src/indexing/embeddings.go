package indexing

import (
	"context"
	"fmt"
	"sync"
)

// EmbeddingProvider interface for different embedding models
type EmbeddingProvider interface {
	// GetEmbeddings generates embeddings for a batch of texts
	GetEmbeddings(ctx context.Context, texts []string) ([][]float32, error)

	// GetDimensions returns the dimensionality of the embeddings
	GetDimensions() int

	// GetBatchSize returns the maximum batch size supported
	GetBatchSize() int
}

// EmbeddingManager manages the generation of embeddings with batching and caching
type EmbeddingManager struct {
	provider EmbeddingProvider
	cache    *sync.Map // cache for previously computed embeddings
	config   *IndexingConfig
}

// NewEmbeddingManager creates a new EmbeddingManager instance
func NewEmbeddingManager(provider EmbeddingProvider, config *IndexingConfig) *EmbeddingManager {
	return &EmbeddingManager{
		provider: provider,
		cache:    &sync.Map{},
		config:   config,
	}
}

// GenerateEmbeddings generates embeddings for multiple texts in batches
func (em *EmbeddingManager) GenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error) {
	if len(texts) == 0 {
		return nil, nil
	}

	// Get batch size from provider
	batchSize := em.provider.GetBatchSize()
	if batchSize <= 0 {
		batchSize = em.config.Embedding.BatchSize
	}

	// Process in batches
	var (
		allEmbeddings [][]float32
		mu            sync.Mutex
		wg            sync.WaitGroup
		errChan       = make(chan error, 1)
		semaphore     = make(chan struct{}, em.config.Batch.MaxConcurrent)
	)

	// Process texts in batches
	for i := 0; i < len(texts); i += batchSize {
		end := i + batchSize
		if end > len(texts) {
			end = len(texts)
		}

		batch := texts[i:end]
		wg.Add(1)

		go func(batch []string, startIdx int) {
			defer wg.Done()
			semaphore <- struct{}{}        // Acquire semaphore
			defer func() { <-semaphore }() // Release semaphore

			// Try to get embeddings from cache first
			cached, missing, _ := em.getCachedEmbeddings(batch)

			// Generate embeddings for missing texts
			var newEmbeddings [][]float32
			if len(missing) > 0 {
				var err error
				newEmbeddings, err = em.provider.GetEmbeddings(ctx, missing)
				if err != nil {
					select {
					case errChan <- fmt.Errorf("error generating embeddings for batch starting at %d: %v", startIdx, err):
					default:
					}
					return
				}

				// Cache new embeddings
				em.cacheEmbeddings(missing, newEmbeddings)
			}

			// Merge cached and new embeddings
			embeddings := make([][]float32, len(batch))
			newEmbIdx := 0
			for i, text := range batch {
				if emb, ok := cached[text]; ok {
					embeddings[i] = emb
				} else {
					embeddings[i] = newEmbeddings[newEmbIdx]
					newEmbIdx++
				}
			}

			// Store results
			mu.Lock()
			if len(allEmbeddings) < startIdx+len(embeddings) {
				// Extend slice if needed
				newSlice := make([][]float32, startIdx+len(embeddings))
				copy(newSlice, allEmbeddings)
				allEmbeddings = newSlice
			}
			copy(allEmbeddings[startIdx:], embeddings)
			mu.Unlock()
		}(batch, i)
	}

	// Wait for all batches to complete
	wg.Wait()

	// Check for errors
	select {
	case err := <-errChan:
		return nil, err
	default:
		return allEmbeddings, nil
	}
}

// getCachedEmbeddings retrieves cached embeddings and returns missing texts
func (em *EmbeddingManager) getCachedEmbeddings(texts []string) (map[string][]float32, []string, []int) {
	cached := make(map[string][]float32)
	var missing []string
	var missingIndices []int

	for i, text := range texts {
		if emb, ok := em.cache.Load(text); ok {
			cached[text] = emb.([]float32)
		} else {
			missing = append(missing, text)
			missingIndices = append(missingIndices, i)
		}
	}

	return cached, missing, missingIndices
}

// cacheEmbeddings stores embeddings in the cache
func (em *EmbeddingManager) cacheEmbeddings(texts []string, embeddings [][]float32) {
	for i, text := range texts {
		em.cache.Store(text, embeddings[i])
	}
}

// ClearCache clears the embedding cache
func (em *EmbeddingManager) ClearCache() {
	em.cache = &sync.Map{}
}

// GetDimensions returns the embedding dimensions
func (em *EmbeddingManager) GetDimensions() int {
	return em.provider.GetDimensions()
}
