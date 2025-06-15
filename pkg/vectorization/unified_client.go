package vectorization

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// UnifiedQdrantClient is the unified Qdrant client based on audit analysis
type UnifiedQdrantClient struct {
	BaseURL    string
	HTTPClient *http.Client
	RetryCount int
	Timeout    time.Duration
}

// ClientConfig holds configuration for the unified client
type ClientConfig struct {
	Host       string        `yaml:"host" json:"host"`
	Port       int           `yaml:"port" json:"port"`
	APIKey     string        `yaml:"api_key" json:"api_key"`
	RetryCount int           `yaml:"retry_count" json:"retry_count"`
	Timeout    time.Duration `yaml:"timeout" json:"timeout"`
}

// TaskPoint represents a vectorized task based on Python analysis
type TaskPoint struct {
	ID      interface{} `json:"id"`
	Vector  []float32   `json:"vector"`
	Payload TaskPayload `json:"payload"`
}

// TaskPayload contains all metadata from Python vectorization analysis
type TaskPayload struct {
	TaskID        string    `json:"taskId"`
	Description   string    `json:"description"`
	Status        string    `json:"status"` // "completed" or "pending"
	IndentLevel   int       `json:"indentLevel"`
	ParentID      string    `json:"parentId"`
	Section       string    `json:"section"`
	IsMVP         bool      `json:"isMVP"`
	Priority      string    `json:"priority"` // P0-P3
	EstimatedTime string    `json:"estimatedTime"`
	Category      string    `json:"category"`
	LastUpdated   time.Time `json:"lastUpdated"`
	FilePath      string    `json:"filePath"`
}

// Collection represents a Qdrant collection
type Collection struct {
	Name   string `json:"name"`
	Status string `json:"status"`
}

// CollectionInfo contains collection metadata
type CollectionInfo struct {
	Status      string `json:"status"`
	PointsCount int    `json:"points_count"`
	VectorSize  int    `json:"vector_size"`
}

// SearchRequest for vector similarity search
type SearchRequest struct {
	Vector      []float32 `json:"vector"`
	Limit       int       `json:"limit"`
	WithPayload bool      `json:"with_payload"`
}

// SearchResult contains search response
type SearchResult struct {
	ID      interface{} `json:"id"`
	Score   float32     `json:"score"`
	Payload TaskPayload `json:"payload"`
}

// BatchInsertRequest for batch point insertion
type BatchInsertRequest struct {
	Points []TaskPoint `json:"points"`
}

// NewUnifiedQdrantClient creates a new unified client
func NewUnifiedQdrantClient(config ClientConfig) *UnifiedQdrantClient {
	baseURL := fmt.Sprintf("http://%s:%d", config.Host, config.Port)
	
	httpClient := &http.Client{
		Timeout: config.Timeout,
	}
	
	if config.RetryCount == 0 {
		config.RetryCount = 3
	}
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Second
	}
	
	return &UnifiedQdrantClient{
		BaseURL:    baseURL,
		HTTPClient: httpClient,
		RetryCount: config.RetryCount,
		Timeout:    config.Timeout,
	}
}

// CreateCollection creates a new collection with vector configuration
func (c *UnifiedQdrantClient) CreateCollection(ctx context.Context, name string, vectorSize int) error {
	payload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     vectorSize,
			"distance": "Cosine",
		},
	}
	
	return c.makeRequest(ctx, "PUT", fmt.Sprintf("/collections/%s", name), payload, nil)
}

// InsertPoints inserts points in batches (migrated from Python batch logic)
func (c *UnifiedQdrantClient) InsertPoints(ctx context.Context, collectionName string, points []TaskPoint) error {
	const batchSize = 100 // Same as Python implementation
	
	for i := 0; i < len(points); i += batchSize {
		end := i + batchSize
		if end > len(points) {
			end = len(points)
		}
		
		batch := points[i:end]
		request := BatchInsertRequest{Points: batch}
		
		err := c.makeRequest(ctx, "PUT", fmt.Sprintf("/collections/%s/points", collectionName), request, nil)
		if err != nil {
			return fmt.Errorf("batch insert failed at index %d: %w", i, err)
		}
	}
	
	return nil
}

// SearchPoints performs vector similarity search
func (c *UnifiedQdrantClient) SearchPoints(ctx context.Context, collectionName string, vector []float32, limit int) ([]SearchResult, error) {
	request := SearchRequest{
		Vector:      vector,
		Limit:       limit,
		WithPayload: true,
	}
	
	var response struct {
		Result []SearchResult `json:"result"`
	}
	
	err := c.makeRequest(ctx, "POST", fmt.Sprintf("/collections/%s/points/search", collectionName), request, &response)
	if err != nil {
		return nil, err
	}
	
	return response.Result, nil
}

// GetCollectionInfo retrieves collection information
func (c *UnifiedQdrantClient) GetCollectionInfo(ctx context.Context, collectionName string) (*CollectionInfo, error) {
	var response struct {
		Result CollectionInfo `json:"result"`
	}
	
	err := c.makeRequest(ctx, "GET", fmt.Sprintf("/collections/%s", collectionName), nil, &response)
	if err != nil {
		return nil, err
	}
	
	return &response.Result, nil
}

// makeRequest is the internal HTTP request method with retry logic
func (c *UnifiedQdrantClient) makeRequest(ctx context.Context, method, path string, body interface{}, result interface{}) error {
	var lastErr error
	
	for attempt := 0; attempt <= c.RetryCount; attempt++ {
		if attempt > 0 {
			// Exponential backoff
			backoff := time.Duration(attempt) * 100 * time.Millisecond
			select {
			case <-time.After(backoff):
			case <-ctx.Done():
				return ctx.Err()
			}
		}
		
		lastErr = c.doRequest(ctx, method, path, body, result)
		if lastErr == nil {
			return nil
		}
		
		// Don't retry on client errors (4xx)
		if httpErr, ok := lastErr.(*HTTPError); ok && httpErr.StatusCode >= 400 && httpErr.StatusCode < 500 {
			return lastErr
		}
	}
	
	return fmt.Errorf("request failed after %d attempts: %w", c.RetryCount, lastErr)
}

// doRequest performs the actual HTTP request
func (c *UnifiedQdrantClient) doRequest(ctx context.Context, method, path string, body interface{}, result interface{}) error {
	url := c.BaseURL + path
	
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("failed to marshal request body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonData)
	}
	
	req, err := http.NewRequestWithContext(ctx, method, url, reqBody)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	
	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()
	
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}
	
	if resp.StatusCode >= 400 {
		return &HTTPError{
			StatusCode: resp.StatusCode,
			Message:    string(respBody),
		}
	}
	
	if result != nil {
		if err := json.Unmarshal(respBody, result); err != nil {
			return fmt.Errorf("failed to unmarshal response: %w", err)
		}
	}
	
	return nil
}

// HTTPError represents an HTTP error response
type HTTPError struct {
	StatusCode int
	Message    string
}

func (e *HTTPError) Error() string {
	return fmt.Sprintf("HTTP %d: %s", e.StatusCode, e.Message)
}
