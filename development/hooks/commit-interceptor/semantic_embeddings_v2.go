package commitinterceptor

import (
	"strings"
)

// SemanticEmbedding represents a semantic embedding for content
type SemanticEmbedding struct {
	Content  string
	Vector   []float64
	Metadata map[string]interface{}
}

// NewSemanticEmbedding creates a new semantic embedding
func NewSemanticEmbedding(content string) *SemanticEmbedding {
	return &SemanticEmbedding{
		Content:  content,
		Vector:   []float64{},
		Metadata: make(map[string]interface{}),
	}
}

// GetSimilarity returns a simple similarity score between two embeddings
// This is a placeholder implementation
func (se *SemanticEmbedding) GetSimilarity(other *SemanticEmbedding) float64 {
	// Simple token-based similarity for placeholder
	tokens1 := strings.Fields(strings.ToLower(se.Content))
	tokens2 := strings.Fields(strings.ToLower(other.Content))

	// Convert to maps for faster lookup
	map1 := make(map[string]bool)
	map2 := make(map[string]bool)

	for _, t := range tokens1 {
		map1[t] = true
	}

	for _, t := range tokens2 {
		map2[t] = true
	}

	// Count common tokens
	commonCount := 0
	for t := range map1 {
		if map2[t] {
			commonCount++
		}
	}

	totalTokens := len(map1) + len(map2) - commonCount

	if totalTokens == 0 {
		return 0
	}

	return float64(commonCount) / float64(totalTokens)
}
