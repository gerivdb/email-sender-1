// Package qdrant provides a unified Qdrant client implementation
// This is part of Phase 2 of plan-dev-v56: Unification des Clients Qdrant
package qdrant

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"

	"go.uber.org/zap"
)

// QdrantInterface defines the unified interface for all Qdrant operations
// Implementation of Phase 2.1.1.1: Créer planning-ecosystem-sync/pkg/qdrant/client.go
type QdrantInterface interface {
	Connect(ctx context.Context) error
	CreateCollection(ctx context.Context, name string, config CollectionConfig) error
	UpsertPoints(ctx context.Context, collection string, points []Point) error
	SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error)
	DeleteCollection(ctx context.Context, name string) error
	HealthCheck(ctx context.Context) error
}

// CollectionConfig represents configuration for creating collections
type CollectionConfig struct {
	VectorSize    int    `json:"vector_size"`
	Distance      string `json:"distance"` // cosine, euclidean, dot
	OnDiskPayload bool   `json:"on_disk_payload"`
	ReplicaCount  int    `json:"replica_count"`
	ShardNumber   int    `json:"shard_number"`
}

// Point represents a vector point with metadata
type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

// SearchRequest represents a vector search request
type SearchRequest struct {
	Vector      []float32              `json:"vector"`
	Limit       int                    `json:"limit"`
	WithPayload bool                   `json:"with_payload"`
	WithVector  bool                   `json:"with_vector"`
	Filter      map[string]interface{} `json:"filter,omitempty"`
	Offset      int                    `json:"offset,omitempty"`
}

// SearchResponse represents the response from a vector search
type SearchResponse struct {
	Result []ScoredPoint `json:"result"`
}

// ScoredPoint represents a search result with score
type ScoredPoint struct {
	ID      interface{}            `json:"id"`
	Score   float32                `json:"score"`
	Vector  []float32              `json:"vector,omitempty"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

// UnifiedClient implements the QdrantInterface with advanced features
// Phase 2.1.1: Architecture du Client de Référence
type UnifiedClient struct {
	baseURL    string
	httpClient *http.Client
	logger     *zap.Logger

	// Phase 2.1.2.1: Connection pooling
	connPool *ConnectionPool

	// Phase 2.1.2.1: Retry configuration
	maxRetries int
	retryDelay time.Duration

	// Phase 2.1.2.2: Monitoring
	metrics *ClientMetrics

	// Thread safety
	mu sync.RWMutex
}

// ConnectionPool manages HTTP connections with pooling
// Implementation of Phase 2.1.2.1.1: Implémenter connection pooling
type ConnectionPool struct {
	transport *http.Transport
	maxConns  int
	timeout   time.Duration
}

// ClientMetrics tracks client performance metrics
// Implementation of Phase 2.1.2.2.1: Intégrer avec le système de métriques existant
type ClientMetrics struct {
	RequestCount    int64         `json:"request_count"`
	ErrorCount      int64         `json:"error_count"`
	AverageLatency  time.Duration `json:"average_latency"`
	LastRequest     time.Time     `json:"last_request"`
	ConnectionsUsed int           `json:"connections_used"`
}

// NewUnifiedClient creates a new unified Qdrant client
// Phase 2.1.1.1.1: Définir l'interface unifiée QdrantInterface
func NewUnifiedClient(baseURL string, logger *zap.Logger) (*UnifiedClient, error) {
	if logger == nil {
		logger = zap.NewNop()
	}

	// Phase 2.1.2.1.1: Initialize connection pooling
	pool := &ConnectionPool{
		transport: &http.Transport{
			MaxIdleConns:        10,
			MaxIdleConnsPerHost: 10,
			IdleConnTimeout:     90 * time.Second,
		},
		maxConns: 10,
		timeout:  30 * time.Second,
	}

	client := &UnifiedClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Transport: pool.transport,
			Timeout:   pool.timeout,
		},
		logger:     logger,
		connPool:   pool,
		maxRetries: 3,
		retryDelay: time.Second,
		metrics:    &ClientMetrics{},
	}

	return client, nil
}

// Connect establishes connection to Qdrant server
// Phase 2.1.1.1.2: Implémenter les méthodes de base (Connect, CreateCollection, Upsert, Search)
func (c *UnifiedClient) Connect(ctx context.Context) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.logger.Info("Establishing connection to Qdrant", zap.String("url", c.baseURL))

	// Test connection with health check
	if err := c.HealthCheck(ctx); err != nil {
		return fmt.Errorf("failed to connect to Qdrant: %w", err)
	}

	c.logger.Info("Successfully connected to Qdrant")
	return nil
}

// CreateCollection creates a new vector collection
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func (c *UnifiedClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error {
	c.logger.Info("Creating collection",
		zap.String("name", name),
		zap.Int("vector_size", config.VectorSize),
		zap.String("distance", config.Distance))

	payload := map[string]interface{}{
		"vectors": map[string]interface{}{
			"size":     config.VectorSize,
			"distance": config.Distance,
		},
		"on_disk_payload":    config.OnDiskPayload,
		"replication_factor": config.ReplicaCount,
		"shard_number":       config.ShardNumber,
	}

	url := fmt.Sprintf("%s/collections/%s", c.baseURL, name)

	// Phase 2.1.2.1.2: Retry logic with exponential backoff
	return c.executeWithRetry(ctx, "PUT", url, payload, nil)
}

// UpsertPoints inserts or updates vector points
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func (c *UnifiedClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	if len(points) == 0 {
		return nil
	}

	c.logger.Info("Upserting points",
		zap.String("collection", collection),
		zap.Int("count", len(points)))

	// Phase 2.1.2.1.3: Optimize batch operations
	const batchSize = 100
	for i := 0; i < len(points); i += batchSize {
		end := i + batchSize
		if end > len(points) {
			end = len(points)
		}

		batch := points[i:end]
		payload := map[string]interface{}{
			"points": batch,
		}

		url := fmt.Sprintf("%s/collections/%s/points", c.baseURL, collection)

		if err := c.executeWithRetry(ctx, "PUT", url, payload, nil); err != nil {
			return fmt.Errorf("failed to upsert batch %d-%d: %w", i, end-1, err)
		}

		c.logger.Debug("Upserted batch",
			zap.Int("start", i),
			zap.Int("end", end-1),
			zap.Int("size", len(batch)))
	}

	return nil
}

// SearchPoints performs vector similarity search
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func (c *UnifiedClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error) {
	c.logger.Debug("Searching points",
		zap.String("collection", collection),
		zap.Int("limit", req.Limit))

	payload := map[string]interface{}{
		"vector":       req.Vector,
		"limit":        req.Limit,
		"with_payload": req.WithPayload,
		"with_vector":  req.WithVector,
	}

	if req.Filter != nil {
		payload["filter"] = req.Filter
	}

	if req.Offset > 0 {
		payload["offset"] = req.Offset
	}

	url := fmt.Sprintf("%s/collections/%s/points/search", c.baseURL, collection)

	var response SearchResponse
	if err := c.executeWithRetry(ctx, "POST", url, payload, &response); err != nil {
		return nil, fmt.Errorf("search failed: %w", err)
	}

	c.logger.Debug("Search completed",
		zap.Int("results", len(response.Result)))

	return &response, nil
}

// DeleteCollection deletes a vector collection
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func (c *UnifiedClient) DeleteCollection(ctx context.Context, name string) error {
	c.logger.Info("Deleting collection", zap.String("name", name))

	url := fmt.Sprintf("%s/collections/%s", c.baseURL, name)
	return c.executeWithRetry(ctx, "DELETE", url, nil, nil)
}

// HealthCheck verifies Qdrant server health
// Phase 2.1.1.1.2: Implémenter les méthodes de base
func (c *UnifiedClient) HealthCheck(ctx context.Context) error {
	url := fmt.Sprintf("%s/health", c.baseURL)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	start := time.Now()
	resp, err := c.httpClient.Do(req)
	latency := time.Since(start)

	// Phase 2.1.2.2: Update metrics
	c.updateMetrics(latency, err == nil)

	if err != nil {
		return fmt.Errorf("health check request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status: %d", resp.StatusCode)
	}

	return nil
}

// executeWithRetry implements retry logic with exponential backoff
// Phase 2.1.2.1.2: Ajouter retry logic avec backoff exponentiel
func (c *UnifiedClient) executeWithRetry(ctx context.Context, method, url string, payload interface{}, response interface{}) error {
	var lastErr error

	for attempt := 0; attempt <= c.maxRetries; attempt++ {
		if attempt > 0 {
			// Exponential backoff
			delay := c.retryDelay * time.Duration(1<<uint(attempt-1))
			c.logger.Debug("Retrying request",
				zap.Int("attempt", attempt),
				zap.Duration("delay", delay))

			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(delay):
			}
		}

		start := time.Now()
		err := c.executeRequest(ctx, method, url, payload, response)
		latency := time.Since(start)

		// Phase 2.1.2.2: Update metrics
		c.updateMetrics(latency, err == nil)

		if err == nil {
			return nil
		}

		lastErr = err

		// Don't retry on certain errors
		if !c.shouldRetry(err) {
			break
		}

		c.logger.Warn("Request failed, will retry",
			zap.Error(err),
			zap.Int("attempt", attempt+1),
			zap.Int("max_retries", c.maxRetries))
	}

	return fmt.Errorf("request failed after %d retries: %w", c.maxRetries, lastErr)
}

// executeRequest performs the actual HTTP request
func (c *UnifiedClient) executeRequest(ctx context.Context, method, url string, payload interface{}, response interface{}) error {
	var req *http.Request
	var err error

	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return fmt.Errorf("failed to marshal payload: %w", err)
		}

		req, err = http.NewRequestWithContext(ctx, method, url, bytes.NewReader(data))
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}

		req.Header.Set("Content-Type", "application/json")
	} else {
		req, err = http.NewRequestWithContext(ctx, method, url, nil)
		if err != nil {
			return fmt.Errorf("failed to create request: %w", err)
		}
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	// Phase 2.1.1.1.3: Standardized error handling
	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(body))
	}

	if response != nil {
		if err := json.NewDecoder(resp.Body).Decode(response); err != nil {
			return fmt.Errorf("failed to decode response: %w", err)
		}
	}

	return nil
}

// shouldRetry determines if an error is retryable
func (c *UnifiedClient) shouldRetry(err error) bool {
	// Don't retry context cancellation
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return false
	}

	// Retry on network errors and 5xx HTTP errors
	return true
}

// updateMetrics updates client performance metrics
// Phase 2.1.2.2.1: Intégrer avec le système de métriques existant
func (c *UnifiedClient) updateMetrics(latency time.Duration, success bool) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.metrics.RequestCount++
	c.metrics.LastRequest = time.Now()

	if !success {
		c.metrics.ErrorCount++
	}

	// Update average latency
	if c.metrics.RequestCount == 1 {
		c.metrics.AverageLatency = latency
	} else {
		// Simple moving average
		c.metrics.AverageLatency = (c.metrics.AverageLatency + latency) / 2
	}
}

// GetMetrics returns current client metrics
// Phase 2.1.2.2.1: Monitoring integration
func (c *UnifiedClient) GetMetrics() ClientMetrics {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return *c.metrics
}

// LogPerformanceStats logs current performance statistics
// Phase 2.1.2.2.2: Ajouter logging structuré (zap.Logger)
func (c *UnifiedClient) LogPerformanceStats() {
	metrics := c.GetMetrics()

	c.logger.Info("Client performance stats",
		zap.Int64("total_requests", metrics.RequestCount),
		zap.Int64("errors", metrics.ErrorCount),
		zap.Duration("avg_latency", metrics.AverageLatency),
		zap.Time("last_request", metrics.LastRequest),
		zap.Float64("error_rate", float64(metrics.ErrorCount)/float64(metrics.RequestCount)*100))
}

// Close cleanly shuts down the client
func (c *UnifiedClient) Close() error {
	c.logger.Info("Closing Qdrant client")

	// Log final performance stats
	c.LogPerformanceStats()

	// Close HTTP transport
	if transport, ok := c.httpClient.Transport.(*http.Transport); ok {
		transport.CloseIdleConnections()
	}

	return nil
}
