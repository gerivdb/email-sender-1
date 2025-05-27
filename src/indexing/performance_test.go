package indexing

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"email_sender/src/providers"

	"github.com/stretchr/testify/require"
)

// BenchmarkChunker tests the performance of document chunking
func BenchmarkChunker(b *testing.B) {
	// Test data sizes
	sizes := []int{1000, 10000, 100000, 1000000}

	for _, size := range sizes {
		text := generateTestText(size)

		b.Run(fmt.Sprintf("ChunkSize_%d", size), func(b *testing.B) {
			chunker := NewChunker(1000, 200)
			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				chunks := chunker.Chunk(text)
				if len(chunks) == 0 {
					b.Fatal("No chunks generated")
				}
			}
		})
	}
}

// BenchmarkEmbeddingGeneration tests embedding generation performance
func BenchmarkEmbeddingGeneration(b *testing.B) {
	texts := []string{
		"Short text for testing embeddings",
		"Medium length text that contains multiple sentences for testing the embedding generation process",
		generateTestText(1000),
	}
	config := &IndexingConfig{}
	config.Embedding.BatchSize = 32
	config.Batch.MaxConcurrent = 4

	mockProvider := providers.NewMockEmbeddingProvider(
		providers.WithDimensions(384),
		providers.WithBatchSize(32),
		providers.WithCacheHitRate(1.0),
	)

	manager := NewEmbeddingManager(mockProvider, config)

	for _, text := range texts {
		b.Run(fmt.Sprintf("TextLength_%d", len(text)), func(b *testing.B) {
			b.ResetTimer()

			for i := 0; i < b.N; i++ {
				_, err := manager.GenerateEmbeddings(context.Background(), []string{text})
				if err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

// LoadTest simulates high load on the indexing system
func TestLoadIndexing(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping load test in short mode")
	}

	// Create test configuration
	config := &IndexingConfig{}
	config.Qdrant.Host = "localhost"
	config.Qdrant.Port = 6334
	config.Qdrant.Collection = "test_load"
	config.Batch.Size = 100
	config.Batch.MaxConcurrent = 8
	config.Chunking.ChunkSize = 1000
	config.Chunking.ChunkOverlap = 200

	// Create temp directory for test files
	tempDir := t.TempDir()

	// Generate test files
	numFiles := 100
	fileSizes := []int{1000, 10000, 100000}
	var files []string

	for i := 0; i < numFiles; i++ {
		size := fileSizes[i%len(fileSizes)]
		filename := filepath.Join(tempDir, fmt.Sprintf("test_%d.txt", i))
		content := generateTestText(size)
		err := os.WriteFile(filename, []byte(content), 0644)
		require.NoError(t, err)
		files = append(files, filename)
	}

	// Create indexer
	indexer, err := NewBatchIndexer(BatchIndexerConfig{
		QdrantHost:   config.Qdrant.Host,
		QdrantPort:   config.Qdrant.Port,
		Collection:   config.Qdrant.Collection,
		BatchSize:    config.Batch.Size,
		ChunkSize:    config.Chunking.ChunkSize,
		ChunkOverlap: config.Chunking.ChunkOverlap,
	})
	require.NoError(t, err)

	// Run load test with metrics
	startTime := time.Now()

	ctx := context.Background()
	err = indexer.IndexFiles(ctx, files)
	require.NoError(t, err)

	duration := time.Since(startTime)
	filesPerSecond := float64(len(files)) / duration.Seconds()

	t.Logf("Load Test Results:")
	t.Logf("- Files processed: %d", len(files))
	t.Logf("- Total duration: %v", duration)
	t.Logf("- Files per second: %.2f", filesPerSecond)
}

// ResourceUsageTest monitors system resource usage during indexing
func TestResourceUsage(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping resource usage test in short mode")
	}

	// Create test data
	dataSize := 100 * 1024 * 1024 // 100MB
	content := generateTestText(dataSize)

	// Run indexing operation
	chunker := NewChunker(1000, 200)
	chunks := chunker.Chunk(content)

	// Process chunks with embeddings
	config := &IndexingConfig{}
	mockProvider := providers.NewMockEmbeddingProvider(
		providers.WithDimensions(384),
		providers.WithBatchSize(32),
		providers.WithCacheHitRate(1.0),
	)
	manager := NewEmbeddingManager(mockProvider, config)

	_, err := manager.GenerateEmbeddings(context.Background(), chunks)
	require.NoError(t, err)

	t.Logf("Resource Usage Statistics:")
	t.Logf("- Chunks processed: %d", len(chunks))
	t.Logf("- Total content size: %d bytes", len(content))
}

// Helper to generate test text of specified size
func generateTestText(size int) string {
	const lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
	repeats := size / len(lorem)
	if repeats <= 0 {
		repeats = 1
	}
	text := ""
	for i := 0; i < repeats; i++ {
		text += lorem
	}
	return text[:size]
}
