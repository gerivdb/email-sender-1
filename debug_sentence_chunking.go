package main

import (
	"email_sender/src/chunking"
	"fmt"
)

func main() {
	text := "First sentence. Second sentence. Third sentence. Fourth sentence."
	fmt.Printf("Text: %q\n", text)
	fmt.Printf("Text length: %d characters\n", len(text))
	fmt.Printf("Text runes: %d\n", len([]rune(text)))

	// Let's analyze where the sentences are:
	runes := []rune(text)
	fmt.Println("\nSentence analysis:")
	for i, r := range runes {
		if r == '.' {
			fmt.Printf("Period at position %d: '%c'\n", i, r)
			if i+1 < len(runes) {
				fmt.Printf("  Next char at %d: '%c' (space: %t)\n", i+1, runes[i+1], runes[i+1] == ' ')
			}
		}
	}

	chunker := &chunking.FixedSizeChunker{}
	options := chunking.ChunkingOptions{
		MaxChunkSize:      20,
		ChunkOverlap:      5,
		ParentDocumentID:  "test-5",
		PreserveStructure: true,
	}

	chunks, err := chunker.Chunk(text, options)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("\nActual chunks: %d\n", len(chunks))
	for i, chunk := range chunks {
		fmt.Printf("Chunk %d (pos %d-%d, len %d): %q\n",
			i, chunk.StartOffset, chunk.EndOffset,
			chunk.EndOffset-chunk.StartOffset, chunk.Text)

		if i > 0 {
			overlap := chunks[i-1].EndOffset - chunk.StartOffset
			fmt.Printf("  Overlap with previous: %d (expected: 5)\n", overlap)
		}
	}

	// Manual analysis of expected chunks
	fmt.Println("\nExpected behavior:")
	fmt.Println("Chunk 0 (0-15): 'First sentence.'")       // 15 chars
	fmt.Println("Chunk 1 (10-31): 'ce. Second sentence.'") // 21 chars, overlap 5
	fmt.Println("Chunk 2 (26-46): 'ce. Third sentence.'")  // 20 chars, overlap 5
	fmt.Println("Chunk 3 (41-65): 'ce. Fourth sentence.'") // 24 chars, overlap 5
}
