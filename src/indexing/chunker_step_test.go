package indexing

import (
	"fmt"
	"testing"
)

func TestChunkerStepByStep(t *testing.T) {
	text := "This is a text that should be split into exactly two chunks with some overlap between them."
	chunkSize := 50
	overlap := 10

	fmt.Printf("Input: %q (length: %d)\n", text, len(text))
	fmt.Printf("ChunkSize: %d, Overlap: %d\n", chunkSize, overlap)

	chunker := NewChunker(chunkSize, overlap)

	// Let's manually trace through the chunking logic
	normalizedText := normalizeText(text)
	fmt.Printf("Normalized: %q (length: %d)\n", normalizedText, len(normalizedText))

	start := 0
	textLen := len(normalizedText)
	chunkIndex := 0

	for start < textLen {
		fmt.Printf("\n--- Chunk %d ---\n", chunkIndex)
		fmt.Printf("Start: %d, TextLen: %d\n", start, textLen)

		// Calculate end position for this chunk
		end := start + chunkSize
		if end > textLen {
			end = textLen
		}
		fmt.Printf("Initial end: %d\n", end)

		// Adjust chunk boundary to respect sentence endings
		if end < textLen {
			originalEnd := end
			end = adjustChunkBoundary(normalizedText, end)
			fmt.Printf("Adjusted end: %d (was %d)\n", end, originalEnd)
		}

		// Extract chunk
		chunk := normalizedText[start:end]
		fmt.Printf("Chunk text: %q (length: %d)\n", chunk, len(chunk))

		// If this chunk reaches the end of text, we're done
		if end >= textLen {
			fmt.Printf("Reached end of text, breaking\n")
			break
		}

		// Calculate next start position with overlap
		nextStart := end - overlap
		if nextStart < 0 {
			nextStart = 0
		}
		fmt.Printf("Next start (with overlap): %d\n", nextStart)

		// Find a good starting point (beginning of sentence or word)
		if nextStart > 0 && nextStart < textLen {
			originalNext := nextStart
			nextStart = findNextStartingPoint(normalizedText, nextStart)
			fmt.Printf("Adjusted next start: %d (was %d)\n", nextStart, originalNext)
		}

		// Break if we can't make progress or if we're going backwards
		if nextStart >= end || nextStart <= start {
			fmt.Printf("Breaking: nextStart (%d) >= end (%d) or nextStart (%d) <= start (%d)\n", nextStart, end, nextStart, start)
			break
		}

		start = nextStart
		chunkIndex++

		if chunkIndex > 5 {
			fmt.Printf("Safety break\n")
			break
		}
	}

	// Now test with actual chunker
	fmt.Printf("\n=== Actual chunker result ===\n")
	chunks := chunker.Chunk(text)
	fmt.Printf("Got %d chunks:\n", len(chunks))
	for i, chunk := range chunks {
		fmt.Printf("Chunk %d: %q (length: %d)\n", i, chunk, len(chunk))
	}
}
