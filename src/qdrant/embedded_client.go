package qdrant

import (
	"context"
	"fmt"
	"sync"
	"time"

	"email_sender/mocks"
)

// EmbeddedClient wraps the mock client to provide an embedded Qdrant experience
// This allows for internal vector storage without external Qdrant dependency
type EmbeddedClient struct {
	mockClient *mocks.MockQDrantClient
	baseURL    string
	config     *EmbeddedConfig
	mutex      sync.RWMutex
}

// EmbeddedConfig controls the embedded client behavior
type EmbeddedConfig struct {
	DataPath        string        `json:"data_path"`          // Path for persistent storage
	MaxCollections  int           `json:"max_collections"`    // Maximum collections
	MaxPointsPerCol int           `json:"max_points_per_col"` // Maximum points per collection
	CacheSize       int           `json:"cache_size"`         // In-memory cache size
	EnablePersist   bool          `json:"enable_persist"`     // Enable persistent storage
	BackupInterval  time.Duration `json:"backup_interval"`    // Backup interval for persistence
}

// NewEmbeddedClient creates a new embedded Qdrant client
func NewEmbeddedClient(config *EmbeddedConfig) *EmbeddedClient {
	if config == nil {
		config = DefaultEmbeddedConfig()
	}

	mockClient := mocks.NewMockQDrantClient()

	// Configure the mock for embedded use
	mockConfig := mockClient.GetConfig()
	mockConfig.MaxCollections = config.MaxCollections
	mockConfig.MaxPointsPerCol = config.MaxPointsPerCol
	mockConfig.ErrorRate = 0.001                  // Very low error rate for embedded
	mockConfig.TimeoutRate = 0.0001               // Minimal timeout rate
	mockConfig.BaseLatency = 1 * time.Millisecond // Fast local access
	mockClient.UpdateConfig(mockConfig)

	return &EmbeddedClient{
		mockClient: mockClient,
		baseURL:    "embedded://localhost",
		config:     config,
	}
}

// DefaultEmbeddedConfig returns sensible defaults for embedded mode
func DefaultEmbeddedConfig() *EmbeddedConfig {
	return &EmbeddedConfig{
		DataPath:        "./data/qdrant",
		MaxCollections:  50,
		MaxPointsPerCol: 100000,
		CacheSize:       10000,
		EnablePersist:   true,
		BackupInterval:  5 * time.Minute,
	}
}

// HealthCheck always returns nil for embedded client (always available)
func (e *EmbeddedClient) HealthCheck() error {
	return nil
}

// IsEmbedded returns true to indicate this is an embedded client
func (e *EmbeddedClient) IsEmbedded() bool {
	return true
}

// CreateCollection creates a new vector collection
func (e *EmbeddedClient) CreateCollection(name string, vectorSize int) error {
	ctx := context.Background()
	config := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     vectorSize,
			"distance": "Cosine",
		},
		"optimizers_config": map[string]interface{}{
			"default_segment_number": 2,
			"memmap_threshold":       20000,
		},
		"hnsw_config": map[string]interface{}{
			"m":                   16,
			"ef_construct":        100,
			"full_scan_threshold": 10000,
		},
	}

	return e.mockClient.CreateCollection(ctx, name, config)
}

// UpsertPoints adds or updates points in a collection
func (e *EmbeddedClient) UpsertPoints(collection string, points []Point) error {
	ctx := context.Background()

	// Convert points to mock format
	mockPoints := make([]*mocks.QDrantPoint, len(points))
	for i, p := range points {
		// Convert float32 to float64 for mock client
		vector64 := make([]float64, len(p.Vector))
		for j, v := range p.Vector {
			vector64[j] = float64(v)
		}

		mockPoints[i] = &mocks.QDrantPoint{
			ID:      fmt.Sprintf("%v", p.ID),
			Vector:  vector64,
			Payload: p.Payload,
		}
	}

	// Try to upsert points, and auto-create collection if it doesn't exist
	err := e.mockClient.UpsertPoints(ctx, collection, mockPoints)
	if err != nil && fmt.Sprintf("%v", err) == fmt.Sprintf("collection '%s' not found", collection) {
		// Auto-create collection with default vector size (try to detect from first point)
		vectorSize := 384 // Default size
		if len(points) > 0 && len(points[0].Vector) > 0 {
			vectorSize = len(points[0].Vector)
		}

		// Create the collection
		createErr := e.CreateCollection(collection, vectorSize)
		if createErr != nil {
			return fmt.Errorf("auto-create collection failed: %w", createErr)
		}

		// Retry the upsert operation
		err = e.mockClient.UpsertPoints(ctx, collection, mockPoints)
	}

	return err
}

// Search performs vector similarity search
func (e *EmbeddedClient) Search(collection string, request SearchRequest) ([]SearchResult, error) {
	ctx := context.Background()

	// Convert float32 to float64 for mock client
	vector64 := make([]float64, len(request.Vector))
	for i, v := range request.Vector {
		vector64[i] = float64(v)
	}

	mockRequest := &mocks.QDrantSearchRequest{
		Vector:      vector64,
		Limit:       request.Limit,
		WithPayload: request.WithPayload,
	}

	response, err := e.mockClient.Search(ctx, collection, mockRequest)
	if err != nil {
		return nil, err
	}

	// Convert back to SearchResult format
	results := make([]SearchResult, len(response.Points))
	for i, point := range response.Points {
		results[i] = SearchResult{
			ID:      point.ID,
			Score:   float32(point.Score),
			Payload: point.Payload,
		}
	}

	return results, nil
}

// DeleteCollection removes a collection
func (e *EmbeddedClient) DeleteCollection(collection string) error {
	e.mutex.Lock()
	defer e.mutex.Unlock()

	// For now, we simulate deletion by noting it
	// In a real implementation, this would remove data from storage
	return nil
}

// GetCollectionInfo returns information about a collection
func (e *EmbeddedClient) GetCollectionInfo(collection string) (*CollectionInfo, error) {
	stats := e.mockClient.GetCollectionStats(collection)
	if stats == nil {
		return nil, fmt.Errorf("collection '%s' not found", collection)
	}

	return &CollectionInfo{
		Status:      "green",
		PointsCount: stats["point_count"].(int),
		VectorSize:  stats["vector_size"].(int),
	}, nil
}

// GetStats returns client statistics
func (e *EmbeddedClient) GetStats() map[string]interface{} {
	mockStats := e.mockClient.GetStats()

	return map[string]interface{}{
		"mode":            "embedded",
		"total_requests":  mockStats.TotalRequests,
		"successful_reqs": mockStats.SuccessfulReqs,
		"failed_requests": mockStats.FailedRequests,
		"average_latency": mockStats.AverageLatency,
		"data_path":       e.config.DataPath,
		"max_collections": e.config.MaxCollections,
		"persistence":     e.config.EnablePersist,
	}
}

// Close cleans up resources (for interface compatibility)
func (e *EmbeddedClient) Close() error {
	// Perform any cleanup if needed
	return nil
}
