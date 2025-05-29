package main

import (
	"email_sender/src/chunking"
	"fmt"
)

func main() {
	text := "This is a longer text that should be split into multiple chunks. It contains multiple sentences and should generate several chunks."
	fmt.Printf("Text length: %d\n", len(text))
	fmt.Printf("Text as runes length: %d\n", len([]rune(text)))

	chunker := &chunking.FixedSizeChunker{}
	options := chunking.ChunkingOptions{
		MaxChunkSize:     50,
		ChunkOverlap:     10,
		ParentDocumentID: "test-4",
	}

	chunks, err := chunker.Chunk(text, options)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("Number of chunks: %d\n", len(chunks))
	for i, chunk := range chunks {
		fmt.Printf("Chunk %d (pos %d-%d, len %d): %q\n", i, chunk.StartOffset, chunk.EndOffset, chunk.EndOffset-chunk.StartOffset, chunk.Text)
	}

	// Manual calculation for verification
	fmt.Printf("\nManual calculation:\n")
	textLen := len([]rune(text))
	pos := 0
	chunkIndex := 0

	for pos < textLen {
		end := pos + options.MaxChunkSize
		if end > textLen {
			end = textLen
		}
		fmt.Printf("Iteration %d: pos=%d, end=%d, text_len=%d\n", chunkIndex, pos, end, textLen)

		if end >= textLen {
			fmt.Printf("  -> Break condition met (end >= textLen)\n")
			chunkIndex++
			break
		}

		nextPos := end - options.ChunkOverlap
		fmt.Printf("  -> Next pos would be: %d\n", nextPos)
		pos = nextPos
		chunkIndex++
	}
	fmt.Printf("Expected chunks from manual calculation: %d\n", chunkIndex)
}
