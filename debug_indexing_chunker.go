package main

import (
	"email_sender/src/indexing"
	"fmt"
)

func main() {
	text := "This is a longer text. It contains multiple sentences. These sentences should be split into different chunks. We want to make sure the chunking respects sentence boundaries. This is important for maintaining context."
	fmt.Printf("Text length: %d\n", len(text))

	chunker := indexing.NewChunker(50, 10)
	chunks := chunker.Chunk(text)

	fmt.Printf("Number of chunks: %d\n", len(chunks))
	for i, chunk := range chunks {
		fmt.Printf("Chunk %d (len %d): %q\n", i, len(chunk), chunk)
	}

	fmt.Printf("\nCompare with our test text:\n")
	text2 := "This is a longer text that should be split into multiple chunks. It contains multiple sentences and should generate several chunks."
	fmt.Printf("Text2 length: %d\n", len(text2))

	chunks2 := chunker.Chunk(text2)
	fmt.Printf("Number of chunks: %d\n", len(chunks2))
	for i, chunk := range chunks2 {
		fmt.Printf("Chunk %d (len %d): %q\n", i, len(chunk), chunk)
	}
}
