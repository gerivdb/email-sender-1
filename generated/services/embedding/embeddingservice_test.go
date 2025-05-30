package embedding

import (
	"context"
	"fmt"
	"math"
	"strings"
	"testing"
)

func TestGenerateEmbedding(t *testing.T) {
	tests := []struct {
		name    string
		text    string
		wantErr bool
	}{
		{
			name:    "Valid text",
			text:    "This is a test text",
			wantErr: false,
		},
		{
			name:    "Empty text",
			text:    "",
			wantErr: true,
		},
		{
			name:    "Whitespace only",
			text:    "   ",
			wantErr: true,
		},
		{
			name:    "Long text",
			text:    strings.Repeat("test text ", 100),
			wantErr: false,
		},
	}

	ctx := context.Background()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			embedding, err := GenerateEmbedding(ctx, tt.text)

			if (err != nil) != tt.wantErr {
				t.Errorf("GenerateEmbedding() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr {
				// Check embedding dimensions
				if len(embedding) == 0 {
					t.Error("GenerateEmbedding() returned empty embedding")
				}

				// Check that values are within reasonable bounds
				for i, val := range embedding {
					if val < -1 || val > 1 {
						t.Errorf("Embedding value at position %d is outside expected range [-1,1]: %f", i, val)
					}
				}
			}
		})
	}
}

func TestGenerateEmbedding_Consistency(t *testing.T) {
	ctx := context.Background()
	text := "This is a test text"

	// Generate embeddings multiple times for the same text
	embedding1, err1 := GenerateEmbedding(ctx, text)
	if err1 != nil {
		t.Fatalf("First embedding generation failed: %v", err1)
	}

	embedding2, err2 := GenerateEmbedding(ctx, text)
	if err2 != nil {
		t.Fatalf("Second embedding generation failed: %v", err2)
	}

	// Compare dimensions
	if len(embedding1) != len(embedding2) {
		t.Errorf("Inconsistent embedding dimensions: %d vs %d", len(embedding1), len(embedding2))
	}

	// Compare values (allowing for small numerical differences)
	const epsilon = 1e-6
	for i := range embedding1 {
		diff := math.Abs(float64(embedding1[i] - embedding2[i]))
		if diff > epsilon {
			t.Errorf("Inconsistent embedding values at position %d: %f vs %f", i, embedding1[i], embedding2[i])
		}
	}
}

func TestGenerateEmbedding_ConcurrentAccess(t *testing.T) {
	ctx := context.Background()
	const numGoroutines = 10

	// Channel to collect errors
	errChan := make(chan error, numGoroutines)

	// Start multiple goroutines generating embeddings
	for i := 0; i < numGoroutines; i++ {
		go func(i int) {
			text := fmt.Sprintf("Test text %d", i)
			_, err := GenerateEmbedding(ctx, text)
			errChan <- err
		}(i)
	}

	// Collect results
	for i := 0; i < numGoroutines; i++ {
		if err := <-errChan; err != nil {
			t.Errorf("Goroutine %d failed: %v", i, err)
		}
	}
}
