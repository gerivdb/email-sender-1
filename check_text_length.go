package main

import "fmt"

func main() {
	text := "This is a longer text that should be split into multiple chunks. It contains multiple sentences and should generate several chunks."
	fmt.Printf("Text length: %d\n", len(text))
	fmt.Printf("Text: %q\n", text)
}
