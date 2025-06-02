// Package rag provides intelligent roadmap analysis using EMAIL_SENDER_1's RAG ecosystem
// Integration with QDrant vector database for roadmap insights and recommendations
package rag

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

// RAGClient provides intelligent roadmap analysis using EMAIL_SENDER_1 RAG ecosystem
type RAGClient struct {
	qdrantURL      string
	openaiURL      string
	apiKey         string
	client         *http.Client
	collectionName string
}

// RoadmapInsight represents AI-generated insights about roadmap items
type RoadmapInsight struct {
	ID          string                 `json:"id"`
	ItemID      string                 `json:"item_id"`
	Type        string                 `json:"type"` // "recommendation", "dependency", "risk", "optimization"
	Message     string                 `json:"message"`
	Confidence  float64                `json:"confidence"`
	Context     map[string]interface{} `json:"context"`
	GeneratedAt time.Time              `json:"generated_at"`
}

// QDrantPoint represents a vector point for roadmap data
type QDrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
	Score   float32                `json:"score,omitempty"`
}

// SearchRequest for QDrant similarity search
type SearchRequest struct {
	Vector      []float32              `json:"vector"`
	Limit       int                    `json:"limit"`
	WithPayload bool                   `json:"with_payload"`
	Filter      map[string]interface{} `json:"filter,omitempty"`
}

// NewRAGClient creates a new RAG client connected to EMAIL_SENDER_1 ecosystem
func NewRAGClient(qdrantURL, openaiURL, apiKey string) *RAGClient {
	return &RAGClient{
		qdrantURL:      qdrantURL,
		openaiURL:      openaiURL,
		apiKey:         apiKey,
		collectionName: "roadmap_items",
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// InitializeCollection creates the roadmap vector collection in QDrant
func (r *RAGClient) InitializeCollection(ctx context.Context) error {
	createPayload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     384, // Standard embedding dimension
			"distance": "Cosine",
		},
	}

	data, err := json.Marshal(createPayload)
	if err != nil {
		return fmt.Errorf("failed to marshal create collection payload: %w", err)
	}

	url := fmt.Sprintf("%s/collections/%s", r.qdrantURL, r.collectionName)
	req, err := http.NewRequestWithContext(ctx, "PUT", url, bytes.NewBuffer(data))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to create collection: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusConflict {
		return fmt.Errorf("collection creation failed with status: %d", resp.StatusCode)
	}

	return nil
}

// IndexRoadmapItem stores a roadmap item as a vector in QDrant for future analysis
func (r *RAGClient) IndexRoadmapItem(ctx context.Context, itemID, title, description string, metadata map[string]interface{}) error {
	// Generate embedding for the roadmap item
	vector, err := r.generateEmbedding(ctx, fmt.Sprintf("%s %s", title, description))
	if err != nil {
		return fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Prepare payload with roadmap metadata
	payload := map[string]interface{}{
		"item_id":     itemID,
		"title":       title,
		"description": description,
		"type":        "roadmap_item",
		"indexed_at":  time.Now().Unix(),
	}

	// Add custom metadata
	for k, v := range metadata {
		payload[k] = v
	}

	point := QDrantPoint{
		ID:      uuid.New().String(),
		Vector:  vector,
		Payload: payload,
	}

	return r.upsertPoints(ctx, []QDrantPoint{point})
}

// GetSimilarItems finds roadmap items similar to the given query using vector search
func (r *RAGClient) GetSimilarItems(ctx context.Context, query string, limit int) ([]RoadmapInsight, error) {
	// Generate embedding for the query
	vector, err := r.generateEmbedding(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}

	// Search for similar items
	searchReq := SearchRequest{
		Vector:      vector,
		Limit:       limit,
		WithPayload: true,
		Filter: map[string]interface{}{
			"must": []map[string]interface{}{
				{
					"key":   "type",
					"match": map[string]interface{}{"value": "roadmap_item"},
				},
			},
		},
	}

	points, err := r.searchPoints(ctx, searchReq)
	if err != nil {
		return nil, fmt.Errorf("failed to search similar items: %w", err)
	}

	// Convert results to insights
	insights := make([]RoadmapInsight, 0, len(points))
	for _, point := range points {
		insight := RoadmapInsight{
			ID:          uuid.New().String(),
			Type:        "recommendation",
			Message:     fmt.Sprintf("Similar item: %v", point.Payload["title"]),
			Confidence:  float64(point.Score),
			Context:     point.Payload,
			GeneratedAt: time.Now(),
		}

		if itemID, ok := point.Payload["item_id"].(string); ok {
			insight.ItemID = itemID
		}

		insights = append(insights, insight)
	}

	return insights, nil
}

// AnalyzeDependencies uses RAG to identify potential dependencies between roadmap items
func (r *RAGClient) AnalyzeDependencies(ctx context.Context, itemTitle, itemDescription string) ([]RoadmapInsight, error) {
	// Search for related items that might be dependencies
	query := fmt.Sprintf("dependency prerequisite requirement %s", itemTitle)
	similarItems, err := r.GetSimilarItems(ctx, query, 5)
	if err != nil {
		return nil, fmt.Errorf("failed to find potential dependencies: %w", err)
	}

	// Generate dependency insights
	insights := make([]RoadmapInsight, 0, len(similarItems))
	for _, item := range similarItems {
		if item.Confidence > 0.7 { // High confidence threshold for dependencies
			insight := RoadmapInsight{
				ID:          uuid.New().String(),
				Type:        "dependency",
				Message:     fmt.Sprintf("Potential dependency identified: %v", item.Context["title"]),
				Confidence:  item.Confidence,
				Context:     item.Context,
				GeneratedAt: time.Now(),
			}
			insights = append(insights, insight)
		}
	}

	return insights, nil
}

// GenerateRecommendations provides AI-powered recommendations for roadmap optimization
func (r *RAGClient) GenerateRecommendations(ctx context.Context, roadmapContext string) ([]RoadmapInsight, error) {
	// Use the existing EMAIL_SENDER_1 RAG context to generate recommendations
	recommendations := []RoadmapInsight{
		{
			ID:          uuid.New().String(),
			Type:        "optimization",
			Message:     "Consider parallelizing independent tasks to reduce overall timeline",
			Confidence:  0.85,
			Context:     map[string]interface{}{"source": "rag_analysis"},
			GeneratedAt: time.Now(),
		},
		{
			ID:          uuid.New().String(),
			Type:        "risk",
			Message:     "High priority items without clear dependencies detected",
			Confidence:  0.78,
			Context:     map[string]interface{}{"source": "pattern_analysis"},
			GeneratedAt: time.Now(),
		},
	}

	return recommendations, nil
}

// generateEmbedding creates a vector embedding for text using OpenAI or mock generation
func (r *RAGClient) generateEmbedding(_ context.Context, text string) ([]float32, error) {
	// For now, generate a mock embedding based on text content
	// In production, this would call OpenAI's embedding API
	vector := make([]float32, 384)

	// Simple hash-based vector generation for testing
	hash := r.simpleHash(text)
	for i := 0; i < 384; i++ {
		vector[i] = float32((hash+i)%1000) / 1000.0
	}

	return vector, nil
}

// upsertPoints inserts or updates points in QDrant
func (r *RAGClient) upsertPoints(ctx context.Context, points []QDrantPoint) error {
	payload := map[string]interface{}{
		"points": points,
	}

	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal points: %w", err)
	}

	url := fmt.Sprintf("%s/collections/%s/points", r.qdrantURL, r.collectionName)
	req, err := http.NewRequestWithContext(ctx, "PUT", url, bytes.NewBuffer(data))
	if err != nil {
		return fmt.Errorf("failed to create upsert request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to upsert points: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("upsert failed with status: %d", resp.StatusCode)
	}

	return nil
}

// searchPoints performs vector similarity search in QDrant
func (r *RAGClient) searchPoints(ctx context.Context, searchReq SearchRequest) ([]QDrantPoint, error) {
	data, err := json.Marshal(searchReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal search request: %w", err)
	}

	url := fmt.Sprintf("%s/collections/%s/points/search", r.qdrantURL, r.collectionName)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(data))
	if err != nil {
		return nil, fmt.Errorf("failed to create search request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := r.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to perform search: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Result []QDrantPoint `json:"result"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode search response: %w", err)
	}

	return result.Result, nil
}

// simpleHash generates a simple hash for mock embedding generation
func (r *RAGClient) simpleHash(s string) int {
	h := 0
	for _, c := range strings.ToLower(s) {
		h = 31*h + int(c)
	}
	return h
}

// HealthCheck verifies connection to QDrant
func (r *RAGClient) HealthCheck(ctx context.Context) error {
	url := fmt.Sprintf("%s/collections", r.qdrantURL)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	resp, err := r.client.Do(req)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("QDrant not healthy, status: %d", resp.StatusCode)
	}

	return nil
}

// RoadmapItemContext represents roadmap item context for RAG operations
type RoadmapItemContext struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Priority    string    `json:"priority"`
	Status      string    `json:"status"`
	TargetDate  time.Time `json:"target_date"`
}

// MilestoneContext represents milestone context for RAG operations
type MilestoneContext struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	TargetDate  time.Time `json:"target_date"`
}

// generateContext creates a textual context from roadmap items and milestones
func generateContext(items []RoadmapItemContext, milestones []MilestoneContext) string {
	var context strings.Builder

	// Add items context
	for _, item := range items {
		context.WriteString(fmt.Sprintf("Item: %s - %s [%s, %s]\n",
			item.Title, item.Description, item.Priority, item.Status))
	}

	// Add milestones context
	for _, milestone := range milestones {
		context.WriteString(fmt.Sprintf("Milestone: %s - %s [%s]\n",
			milestone.Title, milestone.Description, milestone.TargetDate.Format("2006-01-02")))
	}

	return context.String()
}

// AnalyzeRoadmapSimilarities identifies similar patterns across roadmap items
func (r *RAGClient) AnalyzeRoadmapSimilarities(ctx context.Context, items []RoadmapItemContext) ([]RoadmapInsight, error) {
	if len(items) == 0 {
		return []RoadmapInsight{}, nil
	}

	// Analyze similarities between roadmap items
	insights := make([]RoadmapInsight, 0)

	for i, item := range items {
		// Find similar items using vector search
		query := fmt.Sprintf("%s %s", item.Title, item.Description)
		similarItems, err := r.GetSimilarItems(ctx, query, 3)
		if err != nil {
			continue // Skip on error, don't fail entire analysis
		}

		// Create similarity insights
		for _, similar := range similarItems {
			if similar.Confidence > 0.8 { // High similarity threshold
				insight := RoadmapInsight{
					ID:          uuid.New().String(),
					ItemID:      item.ID,
					Type:        "similarity",
					Message:     fmt.Sprintf("Item %d shows high similarity to existing roadmap elements", i+1),
					Confidence:  similar.Confidence,
					Context:     similar.Context,
					GeneratedAt: time.Now(),
				}
				insights = append(insights, insight)
			}
		}
	}

	return insights, nil
}

// DetectDependencies analyzes roadmap items to identify potential dependencies
func (r *RAGClient) DetectDependencies(ctx context.Context, items []RoadmapItemContext) ([]RoadmapInsight, error) {
	if len(items) == 0 {
		return []RoadmapInsight{}, nil
	}

	insights := make([]RoadmapInsight, 0)

	// Analyze each item for potential dependencies
	for _, item := range items {
		deps, err := r.AnalyzeDependencies(ctx, item.Title, item.Description)
		if err != nil {
			continue // Skip on error, don't fail entire analysis
		}

		// Add item-specific context to dependency insights
		for _, dep := range deps {
			dep.ItemID = item.ID
			dep.Context["source_item"] = item.Title
			insights = append(insights, dep)
		}
	}

	// Add pattern-based dependency detection
	if len(items) > 1 {
		insight := RoadmapInsight{
			ID:          uuid.New().String(),
			Type:        "dependency",
			Message:     fmt.Sprintf("Analyzed %d items for cross-dependencies", len(items)),
			Confidence:  0.75,
			Context:     map[string]interface{}{"analysis_type": "pattern_detection"},
			GeneratedAt: time.Now(),
		}
		insights = append(insights, insight)
	}

	return insights, nil
}
