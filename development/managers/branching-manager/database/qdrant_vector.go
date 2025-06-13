package database

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// QdrantVectorManager implements vector operations for AI-powered branching features
type QdrantVectorManager struct {
	client     *http.Client
	baseURL    string
	apiKey     string
	collection string
}

// QdrantConfig holds Qdrant connection configuration
type QdrantConfig struct {
	BaseURL    string
	APIKey     string
	Collection string
	Timeout    time.Duration
}

// VectorPoint represents a point in Qdrant vector space
type VectorPoint struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// SearchRequest represents a Qdrant search request
type SearchRequest struct {
	Vector    []float32 `json:"vector"`
	Limit     int       `json:"limit"`
	WithScore bool      `json:"with_score"`
}

// SearchResult represents a Qdrant search result
type SearchResult struct {
	ID      string                 `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
}

// SearchResponse represents a Qdrant search response
type SearchResponse struct {
	Result []SearchResult `json:"result"`
	Status string         `json:"status"`
	Time   float64        `json:"time"`
}

// NewQdrantVectorManager creates a new Qdrant vector manager
func NewQdrantVectorManager(config *QdrantConfig) (*QdrantVectorManager, error) {
	client := &http.Client{
		Timeout: config.Timeout,
	}

	manager := &QdrantVectorManager{
		client:     client,
		baseURL:    config.BaseURL,
		apiKey:     config.APIKey,
		collection: config.Collection,
	}

	// Initialize collection if it doesn't exist
	if err := manager.initializeCollection(); err != nil {
		return nil, fmt.Errorf("failed to initialize collection: %v", err)
	}

	return manager, nil
}

// initializeCollection creates the Qdrant collection if it doesn't exist
func (q *QdrantVectorManager) initializeCollection() error {
	// Check if collection exists
	req, err := http.NewRequest("GET", fmt.Sprintf("%s/collections/%s", q.baseURL, q.collection), nil)
	if err != nil {
		return err
	}

	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// If collection exists, return
	if resp.StatusCode == 200 {
		return nil
	}

	// Create collection with vector configuration for branching embeddings
	collectionConfig := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     384, // Standard embedding size for sentence transformers
			"distance": "Cosine",
		},
		"optimizers_config": map[string]interface{}{
			"default_segment_number": 2,
		},
		"replication_factor": 1,
	}

	jsonData, err := json.Marshal(collectionConfig)
	if err != nil {
		return err
	}

	req, err = http.NewRequest("PUT", fmt.Sprintf("%s/collections/%s", q.baseURL, q.collection), bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err = q.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to create collection: %s", string(body))
	}

	return nil
}

// IndexSession stores session embeddings for similarity search
func (q *QdrantVectorManager) IndexSession(ctx context.Context, session *interfaces.Session, embedding []float32) error {
	point := VectorPoint{
		ID:     session.ID,
		Vector: embedding,
		Payload: map[string]interface{}{
			"type":       "session",
			"scope":      session.Scope,
			"status":     session.Status,
			"duration":   session.Duration.String(),
			"created_at": session.CreatedAt.Unix(),
			"metadata":   session.Metadata,
		},
	}

	return q.upsertPoints(ctx, []VectorPoint{point})
}

// IndexBranch stores branch embeddings for similarity search
func (q *QdrantVectorManager) IndexBranch(ctx context.Context, branch *interfaces.Branch, embedding []float32) error {
	point := VectorPoint{
		ID:     branch.ID,
		Vector: embedding,
		Payload: map[string]interface{}{
			"type":        "branch",
			"name":        branch.Name,
			"base_branch": branch.BaseBranch,
			"status":      branch.Status,
			"session_id":  branch.SessionID,
			"created_at":  branch.CreatedAt.Unix(),
			"git_hash":    branch.GitHash,
			"metadata":    branch.Metadata,
		},
	}

	return q.upsertPoints(ctx, []VectorPoint{point})
}

// IndexBranchingPattern stores branching pattern embeddings for AI analysis
func (q *QdrantVectorManager) IndexBranchingPattern(ctx context.Context, pattern *interfaces.BranchingPattern, embedding []float32) error {
	point := VectorPoint{
		ID:     pattern.ID,
		Vector: embedding,
		Payload: map[string]interface{}{
			"type":         "pattern",
			"pattern_type": pattern.Type,
			"frequency":    pattern.Frequency,
			"success_rate": pattern.SuccessRate,
			"complexity":   pattern.Complexity,
			"created_at":   pattern.CreatedAt.Unix(),
			"metadata":     pattern.Metadata,
		},
	}

	return q.upsertPoints(ctx, []VectorPoint{point})
}

// IndexQuantumApproach stores quantum approach embeddings for optimization
func (q *QdrantVectorManager) IndexQuantumApproach(ctx context.Context, approach *interfaces.BranchApproach, embedding []float32) error {
	point := VectorPoint{
		ID:     approach.ID,
		Vector: embedding,
		Payload: map[string]interface{}{
			"type":       "quantum_approach",
			"name":       approach.Name,
			"strategy":   approach.Strategy,
			"status":     approach.Status,
			"score":      approach.Score,
			"confidence": approach.Confidence,
			"created_at": approach.CreatedAt.Unix(),
			"metadata":   approach.Metadata,
		},
	}

	return q.upsertPoints(ctx, []VectorPoint{point})
}

// SearchSimilarSessions finds sessions similar to the given embedding
func (q *QdrantVectorManager) SearchSimilarSessions(ctx context.Context, embedding []float32, limit int) ([]*interfaces.SessionSimilarity, error) {
	results, err := q.searchSimilar(ctx, embedding, limit, map[string]interface{}{
		"type": "session",
	})
	if err != nil {
		return nil, err
	}

	var similarities []*interfaces.SessionSimilarity
	for _, result := range results {
		similarity := &interfaces.SessionSimilarity{
			SessionID: result.ID,
			Score:     result.Score,
			Scope:     getStringFromPayload(result.Payload, "scope"),
			Status:    getStringFromPayload(result.Payload, "status"),
			Metadata:  getMapFromPayload(result.Payload, "metadata"),
		}
		similarities = append(similarities, similarity)
	}

	return similarities, nil
}

// SearchSimilarBranches finds branches similar to the given embedding
func (q *QdrantVectorManager) SearchSimilarBranches(ctx context.Context, embedding []float32, limit int) ([]*interfaces.BranchSimilarity, error) {
	results, err := q.searchSimilar(ctx, embedding, limit, map[string]interface{}{
		"type": "branch",
	})
	if err != nil {
		return nil, err
	}

	var similarities []*interfaces.BranchSimilarity
	for _, result := range results {
		similarity := &interfaces.BranchSimilarity{
			BranchID:   result.ID,
			Score:      result.Score,
			Name:       getStringFromPayload(result.Payload, "name"),
			BaseBranch: getStringFromPayload(result.Payload, "base_branch"),
			Status:     getStringFromPayload(result.Payload, "status"),
			Metadata:   getMapFromPayload(result.Payload, "metadata"),
		}
		similarities = append(similarities, similarity)
	}

	return similarities, nil
}

// SearchSimilarPatterns finds branching patterns similar to the given embedding
func (q *QdrantVectorManager) SearchSimilarPatterns(ctx context.Context, embedding []float32, limit int) ([]*interfaces.PatternSimilarity, error) {
	results, err := q.searchSimilar(ctx, embedding, limit, map[string]interface{}{
		"type": "pattern",
	})
	if err != nil {
		return nil, err
	}

	var similarities []*interfaces.PatternSimilarity
	for _, result := range results {
		similarity := &interfaces.PatternSimilarity{
			PatternID:   result.ID,
			Score:       result.Score,
			Type:        getStringFromPayload(result.Payload, "pattern_type"),
			Frequency:   getFloat32FromPayload(result.Payload, "frequency"),
			SuccessRate: getFloat32FromPayload(result.Payload, "success_rate"),
			Complexity:  getFloat32FromPayload(result.Payload, "complexity"),
			Metadata:    getMapFromPayload(result.Payload, "metadata"),
		}
		similarities = append(similarities, similarity)
	}

	return similarities, nil
}

// SearchOptimalApproaches finds optimal quantum approaches based on similarity
func (q *QdrantVectorManager) SearchOptimalApproaches(ctx context.Context, embedding []float32, limit int) ([]*interfaces.ApproachSimilarity, error) {
	results, err := q.searchSimilar(ctx, embedding, limit, map[string]interface{}{
		"type": "quantum_approach",
	})
	if err != nil {
		return nil, err
	}

	var similarities []*interfaces.ApproachSimilarity
	for _, result := range results {
		similarity := &interfaces.ApproachSimilarity{
			ApproachID:    result.ID,
			Score:         result.Score,
			Name:          getStringFromPayload(result.Payload, "name"),
			Strategy:      getStringFromPayload(result.Payload, "strategy"),
			Status:        getStringFromPayload(result.Payload, "status"),
			ApproachScore: getFloat32FromPayload(result.Payload, "score"),
			Confidence:    getFloat32FromPayload(result.Payload, "confidence"),
			Metadata:      getMapFromPayload(result.Payload, "metadata"),
		}
		similarities = append(similarities, similarity)
	}

	return similarities, nil
}

// upsertPoints uploads points to Qdrant
func (q *QdrantVectorManager) upsertPoints(ctx context.Context, points []VectorPoint) error {
	requestBody := map[string]interface{}{
		"points": points,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, "PUT",
		fmt.Sprintf("%s/collections/%s/points", q.baseURL, q.collection),
		bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to upsert points: %s", string(body))
	}

	return nil
}

// searchSimilar performs similarity search with optional filters
func (q *QdrantVectorManager) searchSimilar(ctx context.Context, embedding []float32, limit int, filter map[string]interface{}) ([]SearchResult, error) {
	requestBody := map[string]interface{}{
		"vector":     embedding,
		"limit":      limit,
		"with_score": true,
	}

	if filter != nil {
		requestBody["filter"] = map[string]interface{}{
			"must": []map[string]interface{}{
				{
					"key": "type",
					"match": map[string]interface{}{
						"value": filter["type"],
					},
				},
			},
		}
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, "POST",
		fmt.Sprintf("%s/collections/%s/points/search", q.baseURL, q.collection),
		bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to search: %s", string(body))
	}

	var searchResponse SearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResponse); err != nil {
		return nil, err
	}

	return searchResponse.Result, nil
}

// DeletePoint removes a point from the vector database
func (q *QdrantVectorManager) DeletePoint(ctx context.Context, pointID string) error {
	requestBody := map[string]interface{}{
		"points": []string{pointID},
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, "POST",
		fmt.Sprintf("%s/collections/%s/points/delete", q.baseURL, q.collection),
		bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete point: %s", string(body))
	}

	return nil
}

// GetCollectionInfo returns information about the collection
func (q *QdrantVectorManager) GetCollectionInfo(ctx context.Context) (map[string]interface{}, error) {
	req, err := http.NewRequestWithContext(ctx, "GET",
		fmt.Sprintf("%s/collections/%s", q.baseURL, q.collection), nil)
	if err != nil {
		return nil, err
	}

	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get collection info: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return result, nil
}

// Helper functions to extract values from payload
func getStringFromPayload(payload map[string]interface{}, key string) string {
	if val, ok := payload[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

func getFloat32FromPayload(payload map[string]interface{}, key string) float32 {
	if val, ok := payload[key]; ok {
		switch v := val.(type) {
		case float32:
			return v
		case float64:
			return float32(v)
		case int:
			return float32(v)
		}
	}
	return 0.0
}

func getMapFromPayload(payload map[string]interface{}, key string) map[string]interface{} {
	if val, ok := payload[key]; ok {
		if m, ok := val.(map[string]interface{}); ok {
			return m
		}
	}
	return nil
}

// GenerateEmbedding creates embeddings for text content (mock implementation)
// In production, this would call a real embedding service like OpenAI, Cohere, or local models
func (q *QdrantVectorManager) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	// Mock embedding generation - in production, integrate with actual embedding service
	embedding := make([]float32, 384)

	// Simple hash-based mock embedding
	hash := simpleHash(text)
	for i := range embedding {
		embedding[i] = float32((hash+(uint32(i)*7))%1000)/1000.0 - 0.5
	}

	return embedding, nil
}

// simpleHash creates a simple hash for mock embedding generation
func simpleHash(s string) uint32 {
	h := uint32(0)
	for _, c := range s {
		h = h*31 + uint32(c)
	}
	return h
}

// Health checks the Qdrant connection health
func (q *QdrantVectorManager) Health(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, "GET", q.baseURL, nil)
	if err != nil {
		return err
	}

	if q.apiKey != "" {
		req.Header.Set("api-key", q.apiKey)
	}

	resp, err := q.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("qdrant health check failed with status: %d", resp.StatusCode)
	}

	return nil
}
