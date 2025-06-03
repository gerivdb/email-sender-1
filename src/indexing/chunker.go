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

		// Adjust chunk boundary to respect sentence endings only if not at text end
		if end < textLen {
			adjustedEnd := adjustChunkBoundary(text, end)
			// Only use adjusted end if it doesn't make the chunk too long
			if adjustedEnd > start && adjustedEnd <= start+actualChunkSize+20 {
				end = adjustedEnd
			}
		}

		// Extract chunk
		chunk := text[start:end]
		chunks = append(chunks, strings.TrimSpace(chunk))

		// If this chunk reaches the end of text, we're done
		if end >= textLen {
			break
		}

		// Calculate next start position with overlap
		// Use the actual chunk size, not the adjusted end for overlap calculation
		nextStart := start + actualChunkSize - overlap

		// Ensure we don't go backwards
		if nextStart <= start {
			nextStart = start + (actualChunkSize / 2) // Move forward by half chunk size
		}

		// Ensure we're making progress and not exceeding text length
		if nextStart >= textLen {
			break
		}

		// Find a good starting point (beginning of sentence or word)
		if nextStart > 0 && nextStart < textLen {
			originalNext := nextStart
			nextStart = findNextStartingPoint(text, nextStart)
			// If finding starting point pushes us too far forward, use original
			if nextStart > originalNext+20 {
				nextStart = originalNext
			}
		}

		// Final safety check - ensure we're making meaningful progress
		if nextStart <= start {
			break
		}

		start = nextStart
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
	// If pos is at or beyond text end, return text length
	if pos >= len(text) {
		return len(text)
	}

	// Look for sentence endings within a small range FORWARD first
	maxLookahead := 20 // Small lookahead to avoid chunks that are too long

	// First try to find sentence ending forward (preferred)
	for i := 0; i < maxLookahead && pos+i < len(text); i++ {
		if isSentenceEnding(text, pos+i) {
			return pos + i + 1 // Include the punctuation
		}
	}

	// If no sentence ending found forward, look for word boundary forward
	for i := 0; i < maxLookahead && pos+i < len(text); i++ {
		if unicode.IsSpace(rune(text[pos+i])) {
			return pos + i
		}
	}

	// If no good boundary found forward, look for word boundary backward (small range)
	maxLookback := 10 // Very small lookback to avoid very short chunks
	for i := 1; i <= maxLookback && pos-i > 0; i++ {
		if unicode.IsSpace(rune(text[pos-i])) {
			return pos - i
		}
	}

	// If nothing found, return original position
	return pos
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
	// Ensure pos is within bounds
	if pos <= 0 {
		return 0
	}
	if pos >= len(text) {
		return len(text)
	}

	// If we're already at a space (word boundary), return this position
	if unicode.IsSpace(rune(text[pos])) {
		return pos
	}

	// Look forward for word boundary (space)
	for i := 1; pos+i < len(text); i++ {
		if unicode.IsSpace(rune(text[pos+i])) {
			return pos + i
		}
	}

	// If no space found forward, we're at the end of text
	if pos < len(text) {
		return len(text)
	}

	// Look backward for word boundary (space)
	for i := 1; pos-i >= 0; i++ {
		if unicode.IsSpace(rune(text[pos-i])) {
			return pos - i + 1 // Return position after the space
		}
	}

	// If no space found backward, we're at the beginning
	return 0
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
