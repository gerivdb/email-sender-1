package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

// QDrantClient handles interactions with QDrant vector database
type QDrantClient struct {
	baseURL    string
	httpClient *http.Client
	logger     *log.Logger
}

// QDrantPoint represents a point in QDrant collection
type QDrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float64              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// QDrantResponse represents QDrant API response
type QDrantResponse struct {
	Result interface{} `json:"result"`
	Status string      `json:"status"`
	Time   float64     `json:"time"`
}

// NewQDrantClient creates a new QDrant client
func NewQDrantClient(baseURL string) *QDrantClient {
	return &QDrantClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: log.Default(),
	}
}

// StorePlanEmbeddings stores plan embeddings in QDrant
func (qc *QDrantClient) StorePlanEmbeddings(plan *DynamicPlan) error {
	qc.logger.Printf("📡 Storing embeddings for plan: %s", plan.ID)
	
	if len(plan.Embeddings) == 0 {
		return fmt.Errorf("plan has no embeddings to store")
	}
	
	// Create QDrant point
	point := QDrantPoint{
		ID:     plan.ID,
		Vector: plan.Embeddings,
		Payload: map[string]interface{}{
			"title":        plan.Metadata.Title,
			"version":      plan.Metadata.Version,
			"file_path":    plan.Metadata.FilePath,
			"task_count":   len(plan.Tasks),
			"progression":  plan.Metadata.Progression,
			"created_at":   plan.CreatedAt.Unix(),
			"updated_at":   plan.UpdatedAt.Unix(),
		},
	}
	
	// Store in QDrant collection
	err := qc.upsertPoint("development_plans", point)
	if err != nil {
		return fmt.Errorf("failed to store embeddings: %w", err)
	}
	
	qc.logger.Printf("✅ Successfully stored embeddings for plan: %s", plan.ID)
	return nil
}

// upsertPoint inserts or updates a point in QDrant collection
func (qc *QDrantClient) upsertPoint(collection string, point QDrantPoint) error {
	url := fmt.Sprintf("%s/collections/%s/points", qc.baseURL, collection)
	
	// Create request payload
	payload := map[string]interface{}{
		"points": []QDrantPoint{point},
	}
	
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal point data: %w", err)
	}
	
	// Create HTTP request
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	
	req.Header.Set("Content-Type", "application/json")
	
	// Send request
	resp, err := qc.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()
	
	// Check response
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("QDrant request failed with status %d: %s", resp.StatusCode, string(body))
	}
	
	return nil
}

// SearchSimilarPlans finds similar plans using vector search
func (qc *QDrantClient) SearchSimilarPlans(queryVector []float64, limit int) ([]QDrantPoint, error) {
	qc.logger.Printf("🔍 Searching for similar plans (limit: %d)", limit)
	
	url := fmt.Sprintf("%s/collections/development_plans/points/search", qc.baseURL)
	
	// Create search payload
	payload := map[string]interface{}{
		"vector": queryVector,
		"limit":  limit,
		"with_payload": true,
	}
	
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal search data: %w", err)
	}
	
	// Create HTTP request
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	
	req.Header.Set("Content-Type", "application/json")
	
	// Send request
	resp, err := qc.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()
	
	// Parse response
	var response QDrantResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("search request failed with status %d", resp.StatusCode)
	}
	
	// Extract results
	results := []QDrantPoint{}
	if resultArray, ok := response.Result.([]interface{}); ok {
		for _, item := range resultArray {
			if itemMap, ok := item.(map[string]interface{}); ok {
				point := QDrantPoint{
					ID: fmt.Sprintf("%v", itemMap["id"]),
				}
				if payload, exists := itemMap["payload"]; exists {
					point.Payload = payload.(map[string]interface{})
				}
				results = append(results, point)
			}
		}
	}
	
	qc.logger.Printf("✅ Found %d similar plans", len(results))
	return results, nil
}

// HealthCheck verifies QDrant connection
func (qc *QDrantClient) HealthCheck() error {
	url := fmt.Sprintf("%s/collections", qc.baseURL)
	
	resp, err := qc.httpClient.Get(url)
	if err != nil {
		return fmt.Errorf("failed to connect to QDrant: %w", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("QDrant health check failed with status %d", resp.StatusCode)
	}
	
	qc.logger.Printf("✅ QDrant connection healthy")
	return nil
}

// EnsureCollection creates the development_plans collection if it doesn't exist
func (qc *QDrantClient) EnsureCollection() error {
	qc.logger.Printf("🔧 Ensuring collection 'development_plans' exists")
	
	// First check if collection exists
	url := fmt.Sprintf("%s/collections/development_plans", qc.baseURL)
	resp, err := qc.httpClient.Get(url)
	if err == nil && resp.StatusCode == http.StatusOK {
		resp.Body.Close()
		qc.logger.Printf("✅ Collection 'development_plans' already exists")
		return nil
	}
	if resp != nil {
		resp.Body.Close()
	}
	
	// Create collection
	createURL := fmt.Sprintf("%s/collections/development_plans", qc.baseURL)
	payload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     384,
			"distance": "Cosine",
		},
	}
	
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal collection config: %w", err)
	}
	
	req, err := http.NewRequest("PUT", createURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	
	req.Header.Set("Content-Type", "application/json")
	
	resp, err = qc.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to create collection: %w", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("collection creation failed with status %d: %s", resp.StatusCode, string(body))
	}
	
	qc.logger.Printf("✅ Successfully created collection 'development_plans'")
	return nil
}
