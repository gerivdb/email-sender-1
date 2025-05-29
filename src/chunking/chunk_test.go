package chunking

import (
	"testing"
	"time"
)

func TestFixedSizeChunker(t *testing.T) {
	chunker := &FixedSizeChunker{}

	tests := []struct {
		name    string
		text    string
		options ChunkingOptions
		want    int // nombre attendu de chunks
	}{
		{
			name: "Empty text",
			text: "",
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ChunkOverlap:     10,
				ParentDocumentID: "test-1",
			},
			want: 0,
		},

		{
			name: "Short text",
			text: "This is a short text.",
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ChunkOverlap:     10,
				ParentDocumentID: "test-2",
			},
			want: 1,
		},
		{
			name: "Text equal to chunk size",
			text: "This text is exactly 50 characters long...........",
			options: ChunkingOptions{
				MaxChunkSize:     50,
				ChunkOverlap:     10,
				ParentDocumentID: "test-3",
			},
			want: 1,
		},

		{
			name: "Text larger than chunk size",
			text: "This is a longer text that should be split into multiple chunks. It contains multiple sentences and should generate several chunks.",
			options: ChunkingOptions{
				MaxChunkSize:     50,
				ChunkOverlap:     10,
				ParentDocumentID: "test-4",
			},
			want: 3,
		},

		{
			name: "Text with sentence boundaries",
			text: "First sentence. Second sentence. Third sentence. Fourth sentence.",
			options: ChunkingOptions{
				MaxChunkSize:      20,
				ChunkOverlap:      5,
				ParentDocumentID:  "test-5",
				PreserveStructure: true,
			},
			want: 4,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chunks, err := chunker.Chunk(tt.text, tt.options)

			if tt.text == "" {
				if err == nil {
					t.Error("Expected error for empty text, got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			if len(chunks) != tt.want {
				t.Errorf("Got %d chunks, want %d", len(chunks), tt.want)
			}

			// Vérifier les propriétés de base des chunks
			for i, chunk := range chunks {
				if chunk.ID == "" {
					t.Errorf("Chunk %d: ID is empty", i)
				}
				if chunk.ParentDocumentID != tt.options.ParentDocumentID {
					t.Errorf("Chunk %d: wrong parent ID", i)
				}
				if chunk.ChunkIndex != i {
					t.Errorf("Chunk %d: wrong index", i)
				}
				if chunk.Text == "" {
					t.Errorf("Chunk %d: text is empty", i)
				}
				if chunk.CreatedAt.IsZero() {
					t.Errorf("Chunk %d: creation time not set", i)
				}
			}

			// Vérifier le chevauchement
			if len(chunks) > 1 {
				for i := 1; i < len(chunks); i++ {
					overlap := chunks[i-1].EndOffset - chunks[i].StartOffset
					if overlap != tt.options.ChunkOverlap {
						t.Errorf("Wrong overlap between chunks %d and %d: got %d, want %d",
							i-1, i, overlap, tt.options.ChunkOverlap)
					}
				}
			}
		})
	}
}

func TestSemanticChunker(t *testing.T) {
	chunker := &SemanticChunker{}

	tests := []struct {
		name    string
		text    string
		options ChunkingOptions
		want    int // nombre attendu de chunks
	}{
		{
			name: "Empty text",
			text: "",
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-1",
			},
			want: 0,
		},

		{
			name: "Simple text without sections",
			text: "This is a simple text without any sections or special formatting.",
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-2",
			},
			want: 1,
		},

		{
			name: "Markdown with sections",
			text: `## Section 1
This is the content of section 1.

## Section 2
This is the content of section 2.

## Section 3
This is the content of section 3.`,
			options: ChunkingOptions{
				MaxChunkSize:     50,
				ParentDocumentID: "test-3",
			},
			want: 3,
		},

		{
			name: "Text with paragraphs",
			text: `First paragraph with multiple sentences.
This is still part of the first paragraph.

Second paragraph with its own content.
More text in the second paragraph.

Third paragraph here.
End of text.`,
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-4",
			},
			want: 3,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chunks, err := chunker.Chunk(tt.text, tt.options)

			if tt.text == "" {
				if err == nil {
					t.Error("Expected error for empty text, got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			if len(chunks) != tt.want {
				t.Errorf("Got %d chunks, want %d", len(chunks), tt.want)
			}

			// Vérifier les propriétés de base des chunks
			for i, chunk := range chunks {
				if chunk.ID == "" {
					t.Errorf("Chunk %d: ID is empty", i)
				}
				if chunk.ParentDocumentID != tt.options.ParentDocumentID {
					t.Errorf("Chunk %d: wrong parent ID", i)
				}
				if chunk.ChunkIndex != i {
					t.Errorf("Chunk %d: wrong index", i)
				}
				if chunk.Text == "" {
					t.Errorf("Chunk %d: text is empty", i)
				}
				if chunk.CreatedAt.IsZero() {
					t.Errorf("Chunk %d: creation time not set", i)
				}
			}
		})
	}
}

func TestAdaptiveChunker(t *testing.T) {
	chunker := NewAdaptiveChunker()

	tests := []struct {
		name         string
		text         string
		options      ChunkingOptions
		wantStrategy string // "fixed-size" ou "semantic"
	}{
		{
			name: "Markdown text",
			text: `# Title
## Section 1
Content with *formatting* and [links](https://example.com).

## Section 2
More content with ` + "`code`" + ` and **bold** text.`,
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-1",
			},
			wantStrategy: "semantic",
		},

		{
			name: "Code text",
			text: `func main() {
    fmt.Println("Hello, world!")
    for i := 0; i < 10; i++ {
        doSomething(i)
    }
}`,
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-2",
			},
			wantStrategy: "fixed-size",
		},

		{
			name: "Simple prose",
			text: "This is just regular text without any special formatting or structure.",
			options: ChunkingOptions{
				MaxChunkSize:     100,
				ParentDocumentID: "test-3",
			},
			wantStrategy: "fixed-size",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chunks, err := chunker.Chunk(tt.text, tt.options)
			if err != nil {
				t.Errorf("Unexpected error: %v", err)
				return
			}

			// Vérifier que les chunks ont été créés
			if len(chunks) == 0 {
				t.Error("No chunks created")
			}

			// Vérifier les propriétés de base des chunks
			for i, chunk := range chunks {
				if chunk.ID == "" {
					t.Errorf("Chunk %d: ID is empty", i)
				}
				if chunk.ParentDocumentID != tt.options.ParentDocumentID {
					t.Errorf("Chunk %d: wrong parent ID", i)
				}
				if chunk.ChunkIndex != i {
					t.Errorf("Chunk %d: wrong index", i)
				}
				if chunk.Text == "" {
					t.Errorf("Chunk %d: text is empty", i)
				}
			}
		})
	}
}

func TestChunkMetadata(t *testing.T) {
	chunker := NewAdaptiveChunker()

	metadata := map[string]interface{}{
		"source": "test-file.txt",
		"author": "Test Author",
		"date":   time.Now(),
	}

	options := ChunkingOptions{
		MaxChunkSize:     100,
		ChunkOverlap:     20,
		ParentDocumentID: "test-doc",
		Metadata:         metadata,
	}

	text := "Test text for metadata verification. Should be preserved in all chunks."

	chunks, err := chunker.Chunk(text, options)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// Vérifier que les métadonnées sont préservées dans tous les chunks
	for i, chunk := range chunks {
		if chunk.Metadata == nil {
			t.Errorf("Chunk %d: metadata is nil", i)
			continue
		}

		for key, want := range metadata {
			got, ok := chunk.Metadata[key]
			if !ok {
				t.Errorf("Chunk %d: missing metadata key %q", i, key)
			} else if got != want {
				t.Errorf("Chunk %d: metadata key %q: got %v, want %v", i, key, got, want)
			}
		}
	}
}
