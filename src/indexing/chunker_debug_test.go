package indexing

import (
	"fmt"
	"testing"
)

func TestChunkerDebug(t *testing.T) {
	// Test case 1: "Text with exact chunk size"
	fmt.Println("=== Test case 1: Text with exact chunk size ===")
	text1 := "This is a text that should be split into exactly two chunks with some overlap between them."
	fmt.Printf("Original text (%d chars): %q\n", len(text1), text1)

	chunker1 := NewChunker(50, 10)
	chunks1 := chunker1.Chunk(text1)
	fmt.Printf("Result: %d chunks (expected: 2)\n", len(chunks1))
	for i, chunk := range chunks1 {
		fmt.Printf("Chunk %d (%d chars): %q\n", i, len(chunk), chunk)
	}

	// Test case 2: "Long text with multiple chunks"
	fmt.Println("\n=== Test case 2: Long text with multiple chunks ===")
	text2 := "This is a longer text. It contains multiple sentences. These sentences should be split into different chunks. We want to make sure the chunking respects sentence boundaries. This is important for maintaining context."
	fmt.Printf("Original text (%d chars): %q\n", len(text2), text2)

	chunker2 := NewChunker(50, 10)
	chunks2 := chunker2.Chunk(text2)
	fmt.Printf("Result: %d chunks (expected: 3)\n", len(chunks2))
	for i, chunk := range chunks2 {
		fmt.Printf("Chunk %d (%d chars): %q\n", i, len(chunk), chunk)
	}

	// Let's also test the normalization
	fmt.Println("\n=== Testing normalization ===")
	normalized1 := normalizeText(text1)
	fmt.Printf("Text1 normalized (%d chars): %q\n", len(normalized1), normalized1)

	normalized2 := normalizeText(text2)
	fmt.Printf("Text2 normalized (%d chars): %q\n", len(normalized2), normalized2)
}
