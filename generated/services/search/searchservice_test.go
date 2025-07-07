package search

import (
	"context"
	"fmt"
	"testing"
)

// MockQDrantClient implements QDrantClient interface for testing
type MockQDrantClient struct {
	searchResults []SearchResult
	searchError   error
	insertError   error
}

func (m *MockQDrantClient) Search(ctx context.Context, vector []float64, limit int) ([]SearchResult, error) {
	return m.searchResults, m.searchError
}

func (m *MockQDrantClient) Insert(ctx context.Context, id string, vector []float64, metadata map[string]interface{}) error {
	return m.insertError
}

// MockEmbeddingService implements EmbeddingService interface for testing
type MockEmbeddingService struct {
	embeddings []float64
	err        error
}

func (m *MockEmbeddingService) GenerateEmbedding(ctx context.Context, text string) ([]float64, error) {
	return m.embeddings, m.err
}

func TestSearchService_Search(t *testing.T) {
	// Setup mocks
	mockQDrant := &MockQDrantClient{
		searchResults: []SearchResult{
			{
				ID:       "1",
				Score:    0.9,
				Content:  "Test content",
				Metadata: map[string]interface{}{"title": "Test Doc"},
			},
		},
	}
	mockEmbedding := &MockEmbeddingService{
		embeddings: []float64{0.1, 0.2, 0.3},
	}

	// Create service
	service := NewSearchService(mockQDrant, mockEmbedding)

	// Test successful search
	req := &SearchRequest{
		Query:     "test query",
		Limit:     5,
		Filters:   map[string]interface{}{"type": "test"},
		Threshold: 0.7,
	}

	result, err := service.Search(context.Background(), req)
	if err != nil {
		t.Errorf("Search failed: %v", err)
	}
	if len(result.Results) != 1 {
		t.Errorf("Expected 1 result, got %d", len(result.Results))
	}

	// Test with embedding error
	mockEmbedding.err = fmt.Errorf("embedding error")
	_, err = service.Search(context.Background(), req)
	if err == nil {
		t.Error("Expected error when embedding fails")
	}

	// Test with search error
	mockEmbedding.err = nil
	mockQDrant.searchError = fmt.Errorf("search error")
	_, err = service.Search(context.Background(), req)
	if err == nil {
		t.Error("Expected error when search fails")
	}
}

func TestSearchService_IndexDocument(t *testing.T) {
	// Setup mocks
	mockQDrant := &MockQDrantClient{}
	mockEmbedding := &MockEmbeddingService{
		embeddings: []float64{0.1, 0.2, 0.3},
	}

	// Create service
	service := NewSearchService(mockQDrant, mockEmbedding)

	// Test successful indexing
	doc := &Document{
		ID:      "test-id",
		Content: "test content",
		Metadata: map[string]interface{}{
			"title": "Test Doc",
		},
	}

	err := service.IndexDocument(context.Background(), doc)
	if err != nil {
		t.Errorf("IndexDocument failed: %v", err)
	}

	// Test with embedding error
	mockEmbedding.err = fmt.Errorf("embedding error")
	err = service.IndexDocument(context.Background(), doc)
	if err == nil {
		t.Error("Expected error when embedding fails")
	}

	// Test with insert error
	mockEmbedding.err = nil
	mockQDrant.insertError = fmt.Errorf("insert error")
	err = service.IndexDocument(context.Background(), doc)
	if err == nil {
		t.Error("Expected error when insert fails")
	}
}
