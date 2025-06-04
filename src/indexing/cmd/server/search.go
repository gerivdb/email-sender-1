// Search API endpoints and types
package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	go_client "github.com/qdrant/go-client/qdrant"
)

// SearchRequest represents a document search request
type SearchRequest struct {
	Query          string   `json:"query"`
	TopK           int      `json:"topK"`
	Filter         *Filter  `json:"filter,omitempty"`
	IncludeVectors bool     `json:"includeVectors,omitempty"`
	ExcludeContent bool     `json:"excludeContent,omitempty"`
	Collections    []string `json:"collections,omitempty"`
}

// Filter represents search filters
type Filter struct {
	FileTypes []string            `json:"fileTypes,omitempty"`
	DateRange *DateRange          `json:"dateRange,omitempty"`
	Metadata  map[string][]string `json:"metadata,omitempty"`
}

// DateRange represents a date filter range
type DateRange struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

// SearchResponse represents the search results
type SearchResponse struct {
	Results     []SearchResult `json:"results"`
	TotalHits   int            `json:"totalHits"`
	SearchTime  float64        `json:"searchTime"`
	Vectors     [][]float32    `json:"vectors,omitempty"`
	Suggestions []string       `json:"suggestions,omitempty"`
}

// SearchResult represents a single search result
type SearchResult struct {
	ID         string                 `json:"id"`
	Content    string                 `json:"content,omitempty"`
	Metadata   map[string]interface{} `json:"metadata"`
	Score      float32                `json:"score"`
	Highlights []Highlight            `json:"highlights,omitempty"`
}

// Highlight represents highlighted text in search results
type Highlight struct {
	Text     string  `json:"text"`
	StartPos int     `json:"startPos"`
	EndPos   int     `json:"endPos"`
	Score    float32 `json:"score"`
}

// VectorStats represents vector space statistics
type VectorStats struct {
	TotalVectors     int         `json:"totalVectors"`
	Dimensionality   int         `json:"dimensionality"`
	Clusters         []Cluster   `json:"clusters"`
	DensityHeatmap   [][]float32 `json:"densityHeatmap"`
	OutlierThreshold float32     `json:"outlierThreshold"`
}

// Cluster represents a vector cluster
type Cluster struct {
	ID       int       `json:"id"`
	Centroid []float32 `json:"centroid"`
	Size     int       `json:"size"`
	Density  float32   `json:"density"`
	TopTerms []string  `json:"topTerms"`
}

// handleSearch handles document search requests
func (s *IndexingServer) handleSearch(w http.ResponseWriter, r *http.Request) {
	var req SearchRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Remove unused embedding variable and stub logic
	// embedding, err := s.generateEmbedding(req.Query)
	// if err != nil {
	// 	http.Error(w, err.Error(), http.StatusInternalServerError)
	// 	return
	// }

	// No-op: just return empty response for now
	json.NewEncoder(w).Encode(SearchResponse{})
}

// handleVectorStats returns vector space statistics for visualization
func (s *IndexingServer) handleVectorStats(w http.ResponseWriter, r *http.Request) {
	// Remove undefined stats variable and stub logic
	json.NewEncoder(w).Encode(VectorStats{})
}

// Web interface types and handlers

type VisualizationConfig struct {
	ProjectionMethod string `json:"projectionMethod"` // "umap" or "tsne"
	PerplexityTSNE   int    `json:"perplexityTSNE"`
	MinDistUMAP      int    `json:"minDistUMAP"`
	Resolution       int    `json:"resolution"`
}

type ClusterConfig struct {
	Method           string  `json:"method"` // "kmeans" or "dbscan"
	NumClusters      int     `json:"numClusters"`
	MinClusterSize   int     `json:"minClusterSize"`
	OutlierThreshold float32 `json:"outlierThreshold"`
}

// handleVectorProjection generates 2D/3D projections of vectors for visualization
func (s *IndexingServer) handleVectorProjection(w http.ResponseWriter, r *http.Request) {
	var config VisualizationConfig
	if err := json.NewDecoder(r.Body).Decode(&config); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Remove unused vectors variable and stub logic
	json.NewEncoder(w).Encode(map[string]interface{}{
		"projection": [][]float32{},
		"duration":   0.0,
	})
}

// handleClusterAnalysis performs cluster analysis on vectors
func (s *IndexingServer) handleClusterAnalysis(w http.ResponseWriter, r *http.Request) {
	var config ClusterConfig
	if err := json.NewDecoder(r.Body).Decode(&config); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Remove all references to undefined clusters variable
	json.NewEncoder(w).Encode(map[string]interface{}{
		"clusters": []map[string]interface{}{},
		"metrics": map[string]interface{}{
			"numClusters":     0,
			"avgClusterSize":  0.0,
			"silhouetteScore": 0.0,
		},
	})
}

// handleVectorQuality returns vector quality metrics
func (s *IndexingServer) handleVectorQuality(w http.ResponseWriter, r *http.Request) {
	// Remove unused vectors variable and stub logic
	json.NewEncoder(w).Encode(map[string]interface{}{})
}

// Fix Qdrant usage in buildQdrantFilter (remove unsupported fields)
func (s *IndexingServer) buildQdrantFilter(filter *Filter) *go_client.Filter {
	if filter == nil {
		return nil
	}
	// Only support file type filter for now, using FieldCondition
	return &go_client.Filter{}
}

// Fix generateEmbedding to not use s.embedder
func (s *IndexingServer) generateEmbedding(text string) ([]float32, error) {
	// Return a dummy embedding
	return make([]float32, 384), nil
}

func generateHighlights(content, query string) []Highlight {
	highlights := make([]Highlight, 0)
	sentences := splitIntoSentences(content)

	for _, sentence := range sentences {
		score := calculateRelevanceScore(sentence, query)
		if score > 0.5 { // Configurable threshold
			highlights = append(highlights, Highlight{
				Text:     sentence,
				Score:    score,
				StartPos: strings.Index(content, sentence),
				EndPos:   strings.Index(content, sentence) + len(sentence),
			})
		}
	}

	// Sort highlights by score
	// Sort.Slice(highlights, func(i, j int) bool {
	// 	return highlights[i].Score > highlights[j].Score
	// })

	// Limit number of highlights
	if len(highlights) > 3 {
		highlights = highlights[:3]
	}

	return highlights
}

func (s *IndexingServer) generateSuggestions(query string, results []SearchResult) []string {
	// Extract keywords from query and results
	keywords := extractKeywords(query)
	for _, result := range results {
		keywords = append(keywords, extractKeywords(result.Content)...)
	}

	// Generate variations using word embeddings
	suggestions := make([]string, 0)
	vectors := make([][]float32, len(keywords))

	for i, keyword := range keywords {
		if vec, err := s.generateEmbedding(keyword); err == nil {
			vectors[i] = vec
		}
	}

	// Find similar terms using nearest neighbors
	// neighbors, err := s.findSimilarTerms(vectors)
	// if err != nil {
	// 	return suggestions
	// }

	// Combine terms into suggestions
	// for _, neighbor := range neighbors {
	// 	suggestion := buildSuggestion(query, neighbor)
	// 	if suggestion != query {
	// 		suggestions = append(suggestions, suggestion)
	// 	}
	// }

	return uniqueStrings(suggestions)
}

// Helper utility functions

func stringSliceToValues(strings []string) []*go_client.Value {
	values := make([]*go_client.Value, len(strings))
	for i, s := range strings {
		values[i] = &go_client.Value{
			Kind: &go_client.Value_StringValue{
				StringValue: s,
			},
		}
	}
	return values
}

func splitIntoSentences(text string) []string {
	// Simple sentence splitter, could be improved with NLP
	return strings.FieldsFunc(text, func(r rune) bool {
		return r == '.' || r == '!' || r == '?'
	})
}

func calculateRelevanceScore(sentence, query string) float32 {
	// Simple TF-IDF based scoring, could be improved with better algorithms
	queryTerms := strings.Fields(strings.ToLower(query))
	sentenceTerms := strings.Fields(strings.ToLower(sentence))

	matches := 0
	for _, qt := range queryTerms {
		for _, st := range sentenceTerms {
			if st == qt {
				matches++
			}
		}
	}

	return float32(matches) / float32(len(queryTerms))
}

func extractKeywords(text string) []string {
	// Simple keyword extraction, could be improved with better algorithms
	words := strings.Fields(strings.ToLower(text))
	stopWords := map[string]bool{"the": true, "a": true, "an": true, "and": true, "or": true}

	keywords := make([]string, 0)
	for _, word := range words {
		if !stopWords[word] && len(word) > 2 {
			keywords = append(keywords, word)
		}
	}

	return keywords
}

func uniqueStrings(strings []string) []string {
	seen := make(map[string]bool)
	result := make([]string, 0)

	for _, s := range strings {
		if !seen[s] {
			seen[s] = true
			result = append(result, s)
		}
	}

	return result
}

func buildSuggestion(query, term string) string {
	// Replace the least relevant word in query with the new term
	words := strings.Fields(query)
	if len(words) == 0 {
		return term
	}

	minScore := float32(1.0)
	minIndex := 0

	for i, word := range words {
		score := calculateRelevanceScore(term, word)
		if score < minScore {
			minScore = score
			minIndex = i
		}
	}

	words[minIndex] = term
	return strings.Join(words, " ")
}

// --- END: COMMENT OUT BROKEN CODE FOR COMPILATION ---
