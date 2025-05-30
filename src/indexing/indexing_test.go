package indexing

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestChunker(t *testing.T) {
	tests := []struct {
		name      string
		text      string
		chunkSize int
		overlap   int
		want      int // nombre attendu de chunks
	}{
		{
			name:      "Empty text",
			text:      "",
			chunkSize: 100,
			overlap:   20,
			want:      0,
		},
		{
			name:      "Short text",
			text:      "This is a short text.",
			chunkSize: 100,
			overlap:   20,
			want:      1,
		},
		{
			name:      "Text with exact chunk size",
			text:      "This is a text that should be split into exactly two chunks with some overlap between them.",
			chunkSize: 50,
			overlap:   10,
			want:      2,
		},
		{
			name:      "Long text with multiple chunks",
			text:      "This is a longer text. It contains multiple sentences. These sentences should be split into different chunks. We want to make sure the chunking respects sentence boundaries. This is important for maintaining context.",
			chunkSize: 50,
			overlap:   10,
			want:      3,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chunker := NewChunker(tt.chunkSize, tt.overlap)
			got := chunker.Chunk(tt.text)

			if len(got) != tt.want {
				t.Errorf("Chunker.Chunk() got %v chunks, want %v", len(got), tt.want)
			}

			// Verify overlap
			if len(got) > 1 {
				for i := 1; i < len(got); i++ {
					prevChunk := got[i-1]
					currChunk := got[i]

					// Check if there's meaningful overlap
					if len(prevChunk) > 0 && len(currChunk) > 0 {
						overlap := findOverlap(prevChunk, currChunk)
						if overlap == 0 {
							t.Errorf("No overlap found between chunks %d and %d", i-1, i)
						}
					}
				}
			}
		})
	}
}

func findOverlap(s1, s2 string) int {
	for i := 0; i < len(s1); i++ {
		if len(s1[i:]) > len(s2) {
			continue
		}
		if s1[i:] == s2[:len(s1[i:])] {
			return len(s1) - i
		}
	}
	return 0
}

func TestTextReader(t *testing.T) {
	// Create temporary test files
	tmpDir := t.TempDir()

	files := map[string]struct {
		content  string
		encoding string
	}{
		"utf8.txt": {
			content:  "Hello, World!",
			encoding: "UTF-8",
		},
		"windows1252.txt": {
			content:  "Hello, World with special chars: é à ç",
			encoding: "windows-1252",
		},
	}

	for filename, test := range files {
		path := filepath.Join(tmpDir, filename)
		err := os.WriteFile(path, []byte(test.content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		t.Run(filename, func(t *testing.T) {
			reader := NewTextReader()
			doc, err := reader.Read(path)
			if err != nil {
				t.Fatalf("TextReader.Read() error = %v", err)
			}

			if doc == nil {
				t.Fatal("TextReader.Read() returned nil document")
			}

			if doc.Content == "" {
				t.Error("TextReader.Read() returned empty content")
			}

			if doc.Encoding == "" {
				t.Error("TextReader.Read() returned empty encoding")
			}
		})
	}
}

func TestBatchIndexer(t *testing.T) {
	// Mock configuration
	config := &IndexingConfig{}
	config.Qdrant.Host = "localhost"
	config.Qdrant.Port = 6334
	config.Qdrant.Collection = "test_collection"
	config.Batch.Size = 10
	config.Chunking.ChunkSize = 100
	config.Chunking.ChunkOverlap = 20

	// Create temporary test files
	tmpDir := t.TempDir()
	testFiles := []struct {
		name    string
		content string
	}{
		{"test1.txt", "This is test file 1"},
		{"test2.txt", "This is test file 2"},
		{"test3.md", "# Test file 3\nThis is a markdown file."},
	}

	var filePaths []string
	for _, tf := range testFiles {
		path := filepath.Join(tmpDir, tf.name)
		err := os.WriteFile(path, []byte(tf.content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}
		filePaths = append(filePaths, path)
	}

	// Skip actual Qdrant operations in tests
	t.Skip("Skipping BatchIndexer integration test - requires running Qdrant instance")
}

func TestEmbeddingManager(t *testing.T) {
	// Mock implementation of EmbeddingProvider
	mockProvider := &MockEmbeddingProvider{
		dimensions: 384,
		batchSize:  32,
	}

	config := &IndexingConfig{}
	config.Embedding.BatchSize = 32
	config.Batch.MaxConcurrent = 4

	manager := NewEmbeddingManager(mockProvider, config)

	tests := []struct {
		name    string
		texts   []string
		wantDim int
		wantErr bool
	}{
		{
			name:    "Empty input",
			texts:   []string{},
			wantDim: 384,
			wantErr: false,
		},
		{
			name:    "Single text",
			texts:   []string{"Hello, World!"},
			wantDim: 384,
			wantErr: false,
		},
		{
			name:    "Multiple texts",
			texts:   []string{"Hello", "World", "Test"},
			wantDim: 384,
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			embeddings, err := manager.GenerateEmbeddings(context.Background(), tt.texts)

			if (err != nil) != tt.wantErr {
				t.Errorf("EmbeddingManager.GenerateEmbeddings() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr {
				if len(tt.texts) > 0 && (embeddings == nil || len(embeddings) != len(tt.texts)) {
					t.Errorf("EmbeddingManager.GenerateEmbeddings() wrong number of embeddings, got %v, want %v",
						len(embeddings), len(tt.texts))
				}

				for _, emb := range embeddings {
					if len(emb) != tt.wantDim {
						t.Errorf("EmbeddingManager.GenerateEmbeddings() wrong embedding dimension, got %v, want %v",
							len(emb), tt.wantDim)
					}
				}
			}
		})
	}
}

// MockEmbeddingProvider implements EmbeddingProvider for testing
type MockEmbeddingProvider struct {
	dimensions int
	batchSize  int
}

func (m *MockEmbeddingProvider) GetEmbeddings(ctx context.Context, texts []string) ([][]float32, error) {
	embeddings := make([][]float32, len(texts))
	for i := range texts {
		embeddings[i] = make([]float32, m.dimensions)
		// Fill with dummy values
		for j := range embeddings[i] {
			embeddings[i][j] = float32(i + j)
		}
	}
	return embeddings, nil
}

func (m *MockEmbeddingProvider) GetDimensions() int {
	return m.dimensions
}

func (m *MockEmbeddingProvider) GetBatchSize() int {
	return m.batchSize
}
