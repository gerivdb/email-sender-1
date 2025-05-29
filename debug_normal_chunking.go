package main

import (
	"email_sender/src/chunking"
	"fmt"
)

func main() {
	text := "This is a longer text that should be split into multiple chunks. It contains multiple sentences and should generate several chunks."
	fmt.Printf("Text: %q\n", text)
	fmt.Printf("Text length: %d characters\n", len(text))

	chunker := &chunking.FixedSizeChunker{}
	options := chunking.ChunkingOptions{
		MaxChunkSize:      50,
		ChunkOverlap:      10,
		ParentDocumentID:  "test-4",
		PreserveStructure: false, // Note: false here
	}

	chunks, err := chunker.Chunk(text, options)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("\nActual chunks: %d (expected: 3)\n", len(chunks))
	for i, chunk := range chunks {
		fmt.Printf("Chunk %d (pos %d-%d, len %d): %q\n",
			i, chunk.StartOffset, chunk.EndOffset,
			chunk.EndOffset-chunk.StartOffset, chunk.Text)

		if i > 0 {
			overlap := chunks[i-1].EndOffset - chunk.StartOffset
			fmt.Printf("  Overlap with previous: %d (expected: 10)\n", overlap)
		}
	}

	// Manual calculation of expected chunks
	fmt.Println("\nExpected behavior (without PreserveStructure):")
	fmt.Println("Chunk 0 (0-50): first 50 chars")
	fmt.Println("Chunk 1 (40-90): chars 40-90 (overlap 10)")
	fmt.Println("Chunk 2 (80-131): chars 80-131 (overlap 10)")
}
