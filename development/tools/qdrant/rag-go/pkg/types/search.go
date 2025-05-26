package types

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

// SearchResult represents a search result from the RAG system
type SearchResult struct {
	// Document is the found document
	Document *Document `json:"document"`

	// Score is the similarity score (0.0 to 1.0)
	Score float64 `json:"score"`

	// Distance is the vector distance (optional, depends on metric)
	Distance *float64 `json:"distance,omitempty"`

	// Rank is the rank in the search results (1-based)
	Rank int `json:"rank"`

	// SearchMetadata contains additional search-related information
	SearchMetadata map[string]interface{} `json:"search_metadata,omitempty"`
}

// NewSearchResult creates a new search result
func NewSearchResult(document *Document, score float64, rank int) *SearchResult {
	return &SearchResult{
		Document:       document,
		Score:          score,
		Rank:           rank,
		SearchMetadata: make(map[string]interface{}),
	}
}

// Validate checks if the search result is valid
func (sr *SearchResult) Validate() error {
	// Check if document exists
	if sr.Document == nil {
		return errors.New("search result must contain a document")
	}

	// Validate the document
	if err := sr.Document.Validate(); err != nil {
		return fmt.Errorf("document validation failed: %w", err)
	}

	// Check score range
	if sr.Score < 0.0 || sr.Score > 1.0 {
		return fmt.Errorf("score must be between 0.0 and 1.0, got %f", sr.Score)
	}

	// Check rank
	if sr.Rank < 1 {
		return fmt.Errorf("rank must be positive, got %d", sr.Rank)
	}

	// Check distance if present
	if sr.Distance != nil && *sr.Distance < 0.0 {
		return fmt.Errorf("distance must be non-negative, got %f", *sr.Distance)
	}

	return nil
}

// ToJSON serializes the search result to JSON
func (sr *SearchResult) ToJSON() ([]byte, error) {
	// Validate before serialization
	if err := sr.Validate(); err != nil {
		return nil, fmt.Errorf("search result validation failed: %w", err)
	}

	data, err := json.Marshal(sr)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal search result to JSON: %w", err)
	}

	return data, nil
}

// FromJSON deserializes the search result from JSON
func (sr *SearchResult) FromJSON(data []byte) error {
	if err := json.Unmarshal(data, sr); err != nil {
		return fmt.Errorf("failed to unmarshal search result from JSON: %w", err)
	}

	// Validate after deserialization
	if err := sr.Validate(); err != nil {
		return fmt.Errorf("search result validation failed after deserialization: %w", err)
	}

	return nil
}

// SetDistance sets the distance value
func (sr *SearchResult) SetDistance(distance float64) {
	sr.Distance = &distance
}

// GetDistance gets the distance value
func (sr *SearchResult) GetDistance() (float64, bool) {
	if sr.Distance == nil {
		return 0.0, false
	}
	return *sr.Distance, true
}

// SetSearchMetadata sets a search metadata field
func (sr *SearchResult) SetSearchMetadata(key string, value interface{}) {
	if sr.SearchMetadata == nil {
		sr.SearchMetadata = make(map[string]interface{})
	}
	sr.SearchMetadata[key] = value
}

// GetSearchMetadata gets a search metadata field
func (sr *SearchResult) GetSearchMetadata(key string) (interface{}, bool) {
	if sr.SearchMetadata == nil {
		return nil, false
	}
	value, exists := sr.SearchMetadata[key]
	return value, exists
}

// SetSearchTime sets the search execution time
func (sr *SearchResult) SetSearchTime(duration time.Duration) {
	sr.SetSearchMetadata("search_time_ms", duration.Milliseconds())
}

// GetSearchTime gets the search execution time
func (sr *SearchResult) GetSearchTime() time.Duration {
	if timeMs, exists := sr.GetSearchMetadata("search_time_ms"); exists {
		switch v := timeMs.(type) {
		case int64:
			return time.Duration(v) * time.Millisecond
		case float64:
			return time.Duration(v) * time.Millisecond
		case int:
			return time.Duration(v) * time.Millisecond
		}
	}
	return 0
}

// SetSearchQuery sets the original search query
func (sr *SearchResult) SetSearchQuery(query string) {
	sr.SetSearchMetadata("search_query", query)
}

// GetSearchQuery gets the original search query
func (sr *SearchResult) GetSearchQuery() string {
	if query, exists := sr.GetSearchMetadata("search_query"); exists {
		if queryStr, ok := query.(string); ok {
			return queryStr
		}
	}
	return ""
}

// SetCollectionName sets the collection name where the document was found
func (sr *SearchResult) SetCollectionName(collectionName string) {
	sr.SetSearchMetadata("collection_name", collectionName)
}

// GetCollectionName gets the collection name where the document was found
func (sr *SearchResult) GetCollectionName() string {
	if collection, exists := sr.GetSearchMetadata("collection_name"); exists {
		if collectionStr, ok := collection.(string); ok {
			return collectionStr
		}
	}
	return ""
}

// SearchResults represents a list of search results
type SearchResults struct {
	// Results is the list of search results
	Results []*SearchResult `json:"results"`

	// TotalCount is the total number of available results
	TotalCount int `json:"total_count"`

	// QueryTime is the time taken to execute the query
	QueryTime time.Duration `json:"query_time"`

	// SearchMetadata contains global search metadata
	SearchMetadata map[string]interface{} `json:"search_metadata,omitempty"`
}

// NewSearchResults creates a new search results container
func NewSearchResults() *SearchResults {
	return &SearchResults{
		Results:        make([]*SearchResult, 0),
		TotalCount:     0,
		QueryTime:      0,
		SearchMetadata: make(map[string]interface{}),
	}
}

// AddResult adds a search result to the collection
func (sr *SearchResults) AddResult(result *SearchResult) error {
	if result == nil {
		return errors.New("cannot add nil search result")
	}

	if err := result.Validate(); err != nil {
		return fmt.Errorf("invalid search result: %w", err)
	}

	sr.Results = append(sr.Results, result)
	return nil
}

// GetResults returns all search results
func (sr *SearchResults) GetResults() []*SearchResult {
	return sr.Results
}

// GetResultCount returns the number of results
func (sr *SearchResults) GetResultCount() int {
	return len(sr.Results)
}

// GetTopResults returns the top N results
func (sr *SearchResults) GetTopResults(n int) []*SearchResult {
	if n <= 0 {
		return []*SearchResult{}
	}

	if n >= len(sr.Results) {
		return sr.Results
	}

	return sr.Results[:n]
}

// FilterByScore filters results by minimum score
func (sr *SearchResults) FilterByScore(minScore float64) *SearchResults {
	filtered := NewSearchResults()
	filtered.TotalCount = sr.TotalCount
	filtered.QueryTime = sr.QueryTime
	filtered.SearchMetadata = sr.SearchMetadata

	for _, result := range sr.Results {
		if result.Score >= minScore {
			filtered.Results = append(filtered.Results, result)
		}
	}

	return filtered
}

// FilterBySource filters results by document source
func (sr *SearchResults) FilterBySource(source string) *SearchResults {
	filtered := NewSearchResults()
	filtered.TotalCount = sr.TotalCount
	filtered.QueryTime = sr.QueryTime
	filtered.SearchMetadata = sr.SearchMetadata

	for _, result := range sr.Results {
		if result.Document.GetSource() == source {
			filtered.Results = append(filtered.Results, result)
		}
	}

	return filtered
}

// FilterByFileType filters results by document file type
func (sr *SearchResults) FilterByFileType(fileType string) *SearchResults {
	filtered := NewSearchResults()
	filtered.TotalCount = sr.TotalCount
	filtered.QueryTime = sr.QueryTime
	filtered.SearchMetadata = sr.SearchMetadata

	for _, result := range sr.Results {
		if strings.EqualFold(result.Document.GetFileType(), fileType) {
			filtered.Results = append(filtered.Results, result)
		}
	}

	return filtered
}

// Validate checks if the search results are valid
func (sr *SearchResults) Validate() error {
	// Check if total count is non-negative
	if sr.TotalCount < 0 {
		return fmt.Errorf("total count must be non-negative, got %d", sr.TotalCount)
	}

	// Check if query time is non-negative
	if sr.QueryTime < 0 {
		return fmt.Errorf("query time must be non-negative, got %v", sr.QueryTime)
	}

	// Validate each result
	for i, result := range sr.Results {
		if err := result.Validate(); err != nil {
			return fmt.Errorf("result at index %d is invalid: %w", i, err)
		}
	}

	return nil
}

// ToJSON serializes the search results to JSON
func (sr *SearchResults) ToJSON() ([]byte, error) {
	// Validate before serialization
	if err := sr.Validate(); err != nil {
		return nil, fmt.Errorf("search results validation failed: %w", err)
	}

	data, err := json.Marshal(sr)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal search results to JSON: %w", err)
	}

	return data, nil
}

// FromJSON deserializes the search results from JSON
func (sr *SearchResults) FromJSON(data []byte) error {
	if err := json.Unmarshal(data, sr); err != nil {
		return fmt.Errorf("failed to unmarshal search results from JSON: %w", err)
	}

	// Validate after deserialization
	if err := sr.Validate(); err != nil {
		return fmt.Errorf("search results validation failed after deserialization: %w", err)
	}

	return nil
}
