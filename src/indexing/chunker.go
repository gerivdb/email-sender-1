package indexing

import (
	"strings"
	"unicode"
)

// Chunker handles the splitting of documents into overlapping chunks
type Chunker struct {
	chunkSize    int
	chunkOverlap int
}

// ChunkMetadata contains metadata about a chunk
type ChunkMetadata struct {
	Index       int      // Position of the chunk in the sequence
	StartOffset int      // Start position in original text
	EndOffset   int      // End position in original text
	Keywords    []string // Important keywords in the chunk
}

// NewChunker creates a new Chunker instance
func NewChunker(chunkSize, chunkOverlap int) *Chunker {
	return &Chunker{
		chunkSize:    chunkSize,
		chunkOverlap: chunkOverlap,
	}
}

// Chunk splits text into overlapping chunks with metadata
func (c *Chunker) Chunk(text string) []string {
	if len(text) == 0 {
		return nil
	}

	// Normalize text by removing excessive whitespace
	text = normalizeText(text)

	// Calculate actual chunk size based on word boundaries
	actualChunkSize := c.chunkSize
	if actualChunkSize <= 0 {
		actualChunkSize = 1000 // default size
	}

	// Calculate overlap
	overlap := c.chunkOverlap
	if overlap <= 0 {
		overlap = actualChunkSize / 4 // default 25% overlap
	}

	// Split into chunks
	var chunks []string
	start := 0
	textLen := len(text)

	for start < textLen {
		// Calculate end position for this chunk
		end := start + actualChunkSize
		if end > textLen {
			end = textLen
		}

		// Adjust chunk boundary to respect sentence endings
		if end < textLen {
			end = adjustChunkBoundary(text, end)
		}

		// Extract chunk
		chunk := text[start:end]
		chunks = append(chunks, strings.TrimSpace(chunk))

		// Calculate next start position with overlap
		start = end - overlap
		if start < 0 {
			start = 0
		}

		// Find a good starting point (beginning of sentence or word)
		if start > 0 && start < textLen {
			start = findNextStartingPoint(text, start)
		}

		// Break if we can't make progress
		if start >= end {
			break
		}
	}

	return chunks
}

// ChunkWithMetadata splits text into chunks and returns metadata for each chunk
func (c *Chunker) ChunkWithMetadata(text string) ([]string, []ChunkMetadata) {
	chunks := c.Chunk(text)
	metadata := make([]ChunkMetadata, len(chunks))

	offset := 0
	for i, chunk := range chunks {
		// Find actual start offset accounting for whitespace normalization
		startOffset := strings.Index(text[offset:], strings.TrimSpace(chunk)) + offset
		endOffset := startOffset + len(chunk)

		metadata[i] = ChunkMetadata{
			Index:       i,
			StartOffset: startOffset,
			EndOffset:   endOffset,
			Keywords:    extractKeywords(chunk),
		}

		offset = startOffset + 1
	}

	return chunks, metadata
}

// adjustChunkBoundary finds a suitable boundary near the given position
func adjustChunkBoundary(text string, pos int) int {
	// Look for sentence endings within a reasonable range
	maxLookahead := 100
	minLookbehind := 50

	// First try to find sentence ending
	for i := 0; i < maxLookahead && pos+i < len(text); i++ {
		if isSentenceEnding(text, pos+i) {
			return pos + i + 1 // Include the punctuation
		}
	}

	// If no sentence ending found, look for previous one
	for i := 0; i < minLookbehind && pos-i > 0; i++ {
		if isSentenceEnding(text, pos-i) {
			return pos - i + 1 // Include the punctuation
		}
	}

	// If no good boundary found, at least break at a word boundary
	return findWordBoundary(text, pos)
}

// findNextStartingPoint finds the next suitable starting point for a chunk
func findNextStartingPoint(text string, pos int) int {
	for pos < len(text) {
		// Skip whitespace
		for pos < len(text) && unicode.IsSpace(rune(text[pos])) {
			pos++
		}

		// Check if we're at the start of a sentence
		if pos > 0 && isSentenceEnding(text, pos-1) {
			return pos
		}

		// If not at sentence start, find next word boundary
		if pos < len(text) && !unicode.IsSpace(rune(text[pos])) {
			pos = findWordBoundary(text, pos)
		}

		pos++
	}
	return pos
}

// isSentenceEnding checks if position is at a sentence ending
func isSentenceEnding(text string, pos int) bool {
	if pos < 0 || pos >= len(text) {
		return false
	}

	// Check for sentence ending punctuation
	if strings.ContainsRune(".!?", rune(text[pos])) {
		// Verify it's not part of an abbreviation or number
		if pos > 0 && unicode.IsDigit(rune(text[pos-1])) {
			return false
		}
		if pos > 3 {
			prev := text[pos-3 : pos]
			// Common abbreviations
			if strings.Contains("Mr.|Ms.|Dr.|Sr.|Jr.|vs.|etc", prev) {
				return false
			}
		}
		return true
	}
	return false
}

// findWordBoundary finds the nearest word boundary
func findWordBoundary(text string, pos int) int {
	// Look forward for word boundary
	for i := 0; pos+i < len(text) && !unicode.IsSpace(rune(text[pos+i])); i++ {
		if pos+i == len(text)-1 {
			return len(text)
		}
	}

	// Look backward for word boundary
	for i := 0; pos-i >= 0 && !unicode.IsSpace(rune(text[pos-i])); i++ {
		if pos-i == 0 {
			return 0
		}
	}

	return pos
}

// normalizeText removes excessive whitespace and normalizes line endings
func normalizeText(text string) string {
	// Replace Windows line endings with Unix style
	text = strings.ReplaceAll(text, "\r\n", "\n")

	// Replace multiple newlines with single newline
	text = strings.ReplaceAll(text, "\n\n", "\n")

	// Replace tabs with spaces
	text = strings.ReplaceAll(text, "\t", " ")

	// Normalize spaces
	text = strings.Join(strings.Fields(text), " ")

	return text
}

// extractKeywords extracts important keywords from a chunk of text
func extractKeywords(text string) []string {
	words := strings.Fields(text)
	// Simple stopwords list - in production this should be more comprehensive
	stopwords := map[string]bool{
		"the": true, "be": true, "to": true, "of": true, "and": true,
		"a": true, "in": true, "that": true, "have": true, "i": true,
		"it": true, "for": true, "not": true, "on": true, "with": true,
		"he": true, "as": true, "you": true, "do": true, "at": true,
	}

	var keywords []string
	seen := make(map[string]bool)

	for _, word := range words {
		word = strings.ToLower(word)
		if len(word) > 3 && !stopwords[word] && !seen[word] {
			keywords = append(keywords, word)
			seen[word] = true
			if len(keywords) >= 10 { // Limit number of keywords per chunk
				break
			}
		}
	}

	return keywords
}
