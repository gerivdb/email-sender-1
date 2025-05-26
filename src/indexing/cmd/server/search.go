// Search API endpoints and types
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/qdrant/go-client/qdrant"
	"github.com/yourusername/yourproject/kmeans"
	"github.com/yourusername/yourproject/umap"
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

	// Generate query embedding
	embedding, err := s.generateEmbedding(req.Query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Create search request for Qdrant
	searchReq := &qdrant.SearchPoints{
		CollectionName: s.config.Qdrant.Collection,
		Vector:         embedding,
		Limit:          uint64(req.TopK),
		WithPayload:    &qdrant.WithPayloadSelector{SelectorOptions: &qdrant.WithPayloadSelector_Enable{Enable: true}},
	}

	// Add filters if present
	if req.Filter != nil {
		filter := s.buildQdrantFilter(req.Filter)
		searchReq.Filter = filter
	}

	// Perform search
	startTime := time.Now()
	resp, err := s.indexer.client.Search(context.Background(), searchReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Process results
	results := make([]SearchResult, 0, len(resp.Result))
	var vectors [][]float32

	for _, point := range resp.Result {
		result := SearchResult{
			ID:       point.Id.GetUuid(),
			Score:    point.Score,
			Metadata: make(map[string]interface{}),
		}

		// Extract content and metadata from payload
		if payload := point.Payload; payload != nil {
			if content, ok := payload["content"]; ok {
				result.Content = content.GetStringValue()
			}
			for k, v := range payload {
				if k != "content" {
					result.Metadata[k] = extractValue(v)
				}
			}
		}

		// Add highlights if available
		if !req.ExcludeContent && result.Content != "" {
			result.Highlights = generateHighlights(result.Content, req.Query)
		}

		results = append(results, result)

		// Include vectors if requested
		if req.IncludeVectors && point.Vector != nil {
			vectors = append(vectors, point.Vector.GetData())
		}
	}

	// Generate related suggestions
	suggestions := s.generateSuggestions(req.Query, results)

	// Create response
	searchResp := SearchResponse{
		Results:     results,
		TotalHits:   len(results),
		SearchTime:  time.Since(startTime).Seconds(),
		Vectors:     vectors,
		Suggestions: suggestions,
	}

	json.NewEncoder(w).Encode(searchResp)
}

// handleVectorStats returns vector space statistics for visualization
func (s *IndexingServer) handleVectorStats(w http.ResponseWriter, r *http.Request) {
	// Get collection info
	info, err := s.indexer.client.CollectionInfo(context.Background(), &qdrant.CollectionInfo{
		CollectionName: s.config.Qdrant.Collection,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate vector statistics
	stats := VectorStats{
		TotalVectors:   int(info.GetPointsCount()),
		Dimensionality: int(info.GetConfig().GetParams().GetSize()),
	}

	// Calculate clusters (simplified)
	clusters, err := s.calculateClusters()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	stats.Clusters = clusters

	// Generate density heatmap
	heatmap, err := s.generateDensityHeatmap()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	stats.DensityHeatmap = heatmap

	json.NewEncoder(w).Encode(stats)
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

	// Get vectors from collection
	vectors, err := s.getAllVectors()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Generate projection
	var projection [][]float32
	startTime := time.Now()

	switch config.ProjectionMethod {
	case "umap":
		projector := umap.New(umap.WithMinDist(float64(config.MinDistUMAP)))
		projection, err = projector.FitTransform(vectors)
	case "tsne":
		projector := tsne.New(tsne.WithPerplexity(float64(config.PerplexityTSNE)))
		projection, err = projector.FitTransform(vectors)
	default:
		http.Error(w, "unsupported projection method", http.StatusBadRequest)
		return
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Record performance metrics
	duration := time.Since(startTime)
	s.metrics.LatencyP95.Set(float64(duration.Milliseconds()) / 1000.0)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"projection": projection,
		"duration":   duration.Seconds(),
	})
}

// handleClusterAnalysis performs cluster analysis on vectors
func (s *IndexingServer) handleClusterAnalysis(w http.ResponseWriter, r *http.Request) {
	var config ClusterConfig
	if err := json.NewDecoder(r.Body).Decode(&config); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Get clusters
	clusters, err := s.calculateClusters()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate additional cluster statistics
	clusterStats := make([]map[string]interface{}, len(clusters))
	for i, cluster := range clusters {
		stats := map[string]interface{}{
			"id":       cluster.ID,
			"size":     cluster.Size,
			"density":  cluster.Density,
			"topTerms": cluster.TopTerms,
		}

		// Calculate intra-cluster distance
		avgDistance := calculateIntraClusterDistance(cluster)
		stats["avgDistance"] = avgDistance

		// Calculate silhouette score
		silhouette := calculateSilhouetteScore(cluster, clusters)
		stats["silhouette"] = silhouette

		clusterStats[i] = stats
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"clusters": clusterStats,
		"metrics": map[string]interface{}{
			"numClusters":     len(clusters),
			"avgClusterSize":  float64(s.getTotalVectors()) / float64(len(clusters)),
			"silhouetteScore": calculateOverallSilhouetteScore(clusters),
		},
	})
}

// handleVectorQuality returns vector quality metrics
func (s *IndexingServer) handleVectorQuality(w http.ResponseWriter, r *http.Request) {
	vectors, err := s.getAllVectors()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate quality metrics
	stats := make(map[string]interface{})

	// Vector norms
	norms := calculateVectorNorms(vectors)
	stats["normStats"] = calculateDistributionStats(norms)

	// Vector sparsity
	sparsity := calculateVectorSparsity(vectors)
	stats["sparsityStats"] = calculateDistributionStats(sparsity)

	// Inter-vector similarity
	similarity := calculateInterVectorSimilarity(vectors)
	stats["similarityStats"] = calculateDistributionStats(similarity)

	// Record metrics
	s.metrics.RecordVectorQualityStats(stats)

	json.NewEncoder(w).Encode(stats)
}

func calculateVectorNorms(vectors [][]float32) []float32 {
	norms := make([]float32, len(vectors))
	for i, vec := range vectors {
		var sum float32
		for _, v := range vec {
			sum += v * v
		}
		norms[i] = float32(math.Sqrt(float64(sum)))
	}
	return norms
}

func calculateVectorSparsity(vectors [][]float32) []float32 {
	sparsity := make([]float32, len(vectors))
	threshold := float32(0.01) // Consider values below this as zero

	for i, vec := range vectors {
		zeros := 0
		for _, v := range vec {
			if math.Abs(float64(v)) < float64(threshold) {
				zeros++
			}
		}
		sparsity[i] = float32(zeros) / float32(len(vec))
	}
	return sparsity
}

func calculateInterVectorSimilarity(vectors [][]float32) []float32 {
	n := len(vectors)
	if n < 2 {
		return []float32{}
	}

	similarities := make([]float32, n*(n-1)/2)
	idx := 0

	for i := 0; i < n-1; i++ {
		for j := i + 1; j < n; j++ {
			similarities[idx] = cosineSimilarity(vectors[i], vectors[j])
			idx++
		}
	}
	return similarities
}

func cosineSimilarity(a, b []float32) float32 {
	if len(a) != len(b) {
		return 0
	}

	var dotProduct, normA, normB float32
	for i := range a {
		dotProduct += a[i] * b[i]
		normA += a[i] * a[i]
		normB += b[i] * b[i]
	}

	if normA == 0 || normB == 0 {
		return 0
	}

	return dotProduct / float32(math.Sqrt(float64(normA))*math.Sqrt(float64(normB)))
}

func calculateDistributionStats(values []float32) map[string]float32 {
	if len(values) == 0 {
		return nil
	}

	sort.Slice(values, func(i, j int) bool {
		return values[i] < values[j]
	})

	n := len(values)
	var sum, sumSq float32
	for _, v := range values {
		sum += v
		sumSq += v * v
	}

	mean := sum / float32(n)
	variance := sumSq/float32(n) - mean*mean
	stddev := float32(math.Sqrt(float64(variance)))

	return map[string]float32{
		"min":    values[0],
		"max":    values[n-1],
		"mean":   mean,
		"median": values[n/2],
		"stddev": stddev,
		"p05":    values[n*5/100],
		"p95":    values[n*95/100],
	}
}

// Helper functions

func (s *IndexingServer) generateEmbedding(text string) ([]float32, error) {
	// Use OpenAI or other embedding provider
	vector, err := s.embedder.GenerateEmbedding(context.Background(), text)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %v", err)
	}

	// Record quality metrics
	s.metrics.RecordEmbeddingQuality(vector)

	return vector, nil
}

func (s *IndexingServer) buildQdrantFilter(filter *Filter) *qdrant.Filter {
	if filter == nil {
		return nil
	}

	conditions := make([]*qdrant.Condition, 0)

	// Add file type filter
	if len(filter.FileTypes) > 0 {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.ConditionOneOf{
				OneOf: &qdrant.Value{
					Kind: &qdrant.Value_ListValue{
						ListValue: &qdrant.ListValue{
							Values: stringSliceToValues(filter.FileTypes),
						},
					},
				},
			},
		})
	}

	// Add date range filter
	if filter.DateRange != nil {
		conditions = append(conditions,
			&qdrant.Condition{
				ConditionRange: &qdrant.Range{
					Lt: &qdrant.Value{
						Kind: &qdrant.Value_DatetimeValue{
							DatetimeValue: filter.DateRange.End.Format(time.RFC3339),
						},
					},
					Gt: &qdrant.Value{
						Kind: &qdrant.Value_DatetimeValue{
							DatetimeValue: filter.DateRange.Start.Format(time.RFC3339),
						},
					},
				},
			},
		)
	}

	// Add metadata filters
	for key, values := range filter.Metadata {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.ConditionOneOf{
				OneOf: &qdrant.Value{
					Kind: &qdrant.Value_ListValue{
						ListValue: &qdrant.ListValue{
							Values: stringSliceToValues(values),
						},
					},
				},
			},
		})
	}

	return &qdrant.Filter{
		Must: conditions,
	}
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
	sort.Slice(highlights, func(i, j int) bool {
		return highlights[i].Score > highlights[j].Score
	})

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
	neighbors, err := s.findSimilarTerms(vectors)
	if err != nil {
		return suggestions
	}

	// Combine terms into suggestions
	for _, neighbor := range neighbors {
		suggestion := buildSuggestion(query, neighbor)
		if suggestion != query {
			suggestions = append(suggestions, suggestion)
		}
	}

	return uniqueStrings(suggestions)
}

func (s *IndexingServer) calculateClusters() ([]Cluster, error) {
	// Get all vectors from collection
	vectors, err := s.getAllVectors()
	if err != nil {
		return nil, err
	}

	// Use k-means clustering
	k := int(math.Sqrt(float64(len(vectors)))) // Heuristic for number of clusters
	clusters, err := kmeans.Cluster(vectors, k)
	if err != nil {
		return nil, err
	}

	// Calculate cluster statistics
	results := make([]Cluster, len(clusters))
	for i, cluster := range clusters {
		density := calculateClusterDensity(cluster)
		topTerms := s.findTopTermsForCluster(cluster)

		results[i] = Cluster{
			ID:       i,
			Centroid: cluster.Centroid,
			Size:     len(cluster.Points),
			Density:  density,
			TopTerms: topTerms,
		}

		// Record metrics
		s.metrics.RecordClusterMetrics(density, calculateOutlierScore(cluster))
	}

	return results, nil
}

func (s *IndexingServer) generateDensityHeatmap() ([][]float32, error) {
	// Get all vectors
	vectors, err := s.getAllVectors()
	if err != nil {
		return nil, err
	}

	// Project vectors to 2D using UMAP
	projector := umap.New()
	projection, err := projector.FitTransform(vectors)
	if err != nil {
		return nil, err
	}

	// Calculate density heatmap
	resolution := 50
	heatmap := make([][]float32, resolution)
	for i := range heatmap {
		heatmap[i] = make([]float32, resolution)
	}

	// Calculate density for each grid cell
	for _, point := range projection {
		x := int((point[0] + 1) * float32(resolution) / 2)
		y := int((point[1] + 1) * float32(resolution) / 2)
		if x >= 0 && x < resolution && y >= 0 && y < resolution {
			heatmap[y][x]++
		}
	}

	// Normalize heatmap
	maxDensity := float32(0)
	for i := range heatmap {
		for j := range heatmap[i] {
			if heatmap[i][j] > maxDensity {
				maxDensity = heatmap[i][j]
			}
		}
	}

	for i := range heatmap {
		for j := range heatmap[i] {
			heatmap[i][j] /= maxDensity
		}
	}

	return heatmap, nil
}

// Helper utility functions

func stringSliceToValues(strings []string) []*qdrant.Value {
	values := make([]*qdrant.Value, len(strings))
	for i, s := range strings {
		values[i] = &qdrant.Value{
			Kind: &qdrant.Value_StringValue{
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
