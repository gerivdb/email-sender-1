// Package mocks provides advanced mock implementations for RAG components
// Time-Saving Method 2: Mock-First Strategy
// ROI: +24h immediate + 18h/month (eliminates external dependencies during development)
package mocks

import (
	"context"
	"fmt"
	"math"
	"math/rand"
	"sort"
	"sync"
	"time"
)

// QDrantPoint represents a vector point in QDrant
type QDrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float64              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
	Score   float64                `json:"score,omitempty"`
}

// QDrantSearchRequest represents a search request to QDrant
type QDrantSearchRequest struct {
	Vector      []float64              `json:"vector"`
	Limit       int                    `json:"limit"`
	Filter      map[string]interface{} `json:"filter,omitempty"`
	WithPayload bool                   `json:"with_payload"`
	Threshold   float64                `json:"score_threshold,omitempty"`
}

// QDrantSearchResponse represents QDrant search response
type QDrantSearchResponse struct {
	Points []QDrantPoint `json:"result"`
	Status string        `json:"status"`
	Time   float64       `json:"time"`
}

// MockQDrantClient provides sophisticated QDrant simulation
type MockQDrantClient struct {
	collections map[string][]*QDrantPoint
	mutex       sync.RWMutex
	config      *MockConfig
	stats       *MockStats
}

// MockConfig controls mock behavior and performance simulation
type MockConfig struct {
	BaseLatency      time.Duration `json:"base_latency"`       // 50ms
	LatencyVariation time.Duration `json:"latency_variation"`  // ±20ms
	ErrorRate        float64       `json:"error_rate"`         // 2%
	TimeoutRate      float64       `json:"timeout_rate"`       // 1%
	MaxCollections   int           `json:"max_collections"`    // 100
	MaxPointsPerCol  int           `json:"max_points_per_col"` // 10000
	EnableMetrics    bool          `json:"enable_metrics"`
}

// MockStats tracks mock performance and usage
type MockStats struct {
	TotalRequests   int64         `json:"total_requests"`
	SuccessfulReqs  int64         `json:"successful_requests"`
	FailedRequests  int64         `json:"failed_requests"`
	TimeoutRequests int64         `json:"timeout_requests"`
	AverageLatency  time.Duration `json:"average_latency"`
	LastRequestTime time.Time     `json:"last_request_time"`
}

// NewMockQDrantClient creates a realistic QDrant mock
func NewMockQDrantClient() *MockQDrantClient {
	mock := &MockQDrantClient{
		collections: make(map[string][]*QDrantPoint),
		config: &MockConfig{
			BaseLatency:      50 * time.Millisecond,
			LatencyVariation: 20 * time.Millisecond,
			ErrorRate:        0.02, // 2% error rate
			TimeoutRate:      0.01, // 1% timeout rate
			MaxCollections:   100,
			MaxPointsPerCol:  10000,
			EnableMetrics:    true,
		},
		stats: &MockStats{},
	}

	// Seed with realistic test data
	mock.seedTestData()
	return mock
}

// Search simulates QDrant vector search with realistic behavior
func (m *MockQDrantClient) Search(ctx context.Context, collection string, req *QDrantSearchRequest) (*QDrantSearchResponse, error) {
	start := time.Now()

	// Update request stats
	m.stats.TotalRequests++
	m.stats.LastRequestTime = time.Now()

	// Simulate network latency with variation
	latency := m.simulateLatency()

	// Check for timeout simulation
	if m.shouldTimeout() {
		m.stats.TimeoutRequests++
		select {
		case <-time.After(latency * 3): // Extended timeout
			return nil, fmt.Errorf("request timeout")
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	// Simulate processing time
	select {
	case <-time.After(latency):
		// Continue processing
	case <-ctx.Done():
		return nil, ctx.Err()
	}

	// Simulate random errors
	if m.shouldError() {
		m.stats.FailedRequests++
		return nil, fmt.Errorf("simulated QDrant error: collection '%s' temporarily unavailable", collection)
	}

	// Perform mock search
	response, err := m.performMockSearch(collection, req)
	if err != nil {
		m.stats.FailedRequests++
		return nil, err
	}

	// Update success stats
	m.stats.SuccessfulReqs++
	duration := time.Since(start)
	m.updateLatencyStats(duration)

	return response, nil
}

// performMockSearch executes the actual mock search logic
func (m *MockQDrantClient) performMockSearch(collection string, req *QDrantSearchRequest) (*QDrantSearchResponse, error) {
	m.mutex.RLock()
	points, exists := m.collections[collection]
	m.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("collection '%s' not found", collection)
	}

	// Simulate vector similarity search
	var results []QDrantPoint
	for _, point := range points {
		// Calculate mock similarity score
		score := m.calculateMockSimilarity(req.Vector, point.Vector)

		// Apply threshold filter
		if req.Threshold > 0 && score < req.Threshold {
			continue
		}

		// Apply custom filters
		if !m.matchesFilters(point, req.Filter) {
			continue
		}

		// Create result point
		resultPoint := QDrantPoint{
			ID:     point.ID,
			Vector: point.Vector,
			Score:  score,
		}

		// Include payload if requested
		if req.WithPayload {
			resultPoint.Payload = point.Payload
		}

		results = append(results, resultPoint)
	}

	// Sort by score (descending)
	m.sortByScore(results)

	// Apply limit
	if req.Limit > 0 && len(results) > req.Limit {
		results = results[:req.Limit]
	}

	return &QDrantSearchResponse{
		Points: results,
		Status: "ok",
		Time:   m.config.BaseLatency.Seconds(),
	}, nil
}

// CreateCollection simulates QDrant collection creation
func (m *MockQDrantClient) CreateCollection(ctx context.Context, name string, config map[string]interface{}) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	if len(m.collections) >= m.config.MaxCollections {
		return fmt.Errorf("maximum collections limit reached: %d", m.config.MaxCollections)
	}

	m.collections[name] = make([]*QDrantPoint, 0)

	// Simulate creation latency
	time.Sleep(m.simulateLatency())

	return nil
}

// UpsertPoints simulates adding/updating vectors in QDrant
func (m *MockQDrantClient) UpsertPoints(ctx context.Context, collection string, points []*QDrantPoint) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	collectionPoints, exists := m.collections[collection]
	if !exists {
		return fmt.Errorf("collection '%s' not found", collection)
	}

	if len(collectionPoints)+len(points) > m.config.MaxPointsPerCol {
		return fmt.Errorf("collection size limit exceeded")
	}

	// Simulate batch processing
	batchSize := 100
	for i := 0; i < len(points); i += batchSize {
		end := i + batchSize
		if end > len(points) {
			end = len(points)
		}

		// Add points to collection
		m.collections[collection] = append(m.collections[collection], points[i:end]...)

		// Simulate processing latency per batch
		time.Sleep(m.simulateLatency() / 10)
	}

	return nil
} // Helper methods for MockQDrantClient (continued)

// simulateLatency returns realistic latency with variation
func (m *MockQDrantClient) simulateLatency() time.Duration {
	variation := time.Duration(rand.Float64() * float64(m.config.LatencyVariation))
	if rand.Float64() < 0.5 {
		variation = -variation
	}
	return m.config.BaseLatency + variation
}

// shouldError determines if this request should simulate an error
func (m *MockQDrantClient) shouldError() bool {
	return rand.Float64() < m.config.ErrorRate
}

// shouldTimeout determines if this request should simulate a timeout
func (m *MockQDrantClient) shouldTimeout() bool {
	return rand.Float64() < m.config.TimeoutRate
}

// calculateMockSimilarity computes a realistic similarity score
func (m *MockQDrantClient) calculateMockSimilarity(query, target []float64) float64 {
	if len(query) != len(target) {
		return 0.0
	}

	// Cosine similarity simulation
	dotProduct := 0.0
	queryMag := 0.0
	targetMag := 0.0

	for i := 0; i < len(query); i++ {
		dotProduct += query[i] * target[i]
		queryMag += query[i] * query[i]
		targetMag += target[i] * target[i]
	}

	if queryMag == 0 || targetMag == 0 {
		return 0.0
	}

	similarity := dotProduct / (math.Sqrt(queryMag) * math.Sqrt(targetMag))

	// Add slight randomness to make it more realistic
	noise := (rand.Float64() - 0.5) * 0.05 // ±2.5% noise
	similarity += noise

	// Clamp to [0, 1]
	if similarity < 0 {
		similarity = 0
	}
	if similarity > 1 {
		similarity = 1
	}

	return similarity
}

// matchesFilters checks if a point matches the provided filters
func (m *MockQDrantClient) matchesFilters(point *QDrantPoint, filters map[string]interface{}) bool {
	if len(filters) == 0 {
		return true
	}

	for key, value := range filters {
		payloadValue, exists := point.Payload[key]
		if !exists {
			return false
		}

		// Simple equality check (can be extended for complex filters)
		if payloadValue != value {
			return false
		}
	}

	return true
}

// sortByScore sorts results by similarity score in descending order
func (m *MockQDrantClient) sortByScore(points []QDrantPoint) {
	sort.Slice(points, func(i, j int) bool {
		return points[i].Score > points[j].Score
	})
}

// updateLatencyStats updates the average latency using exponential moving average
func (m *MockQDrantClient) updateLatencyStats(latency time.Duration) {
	if m.stats.TotalRequests == 1 {
		m.stats.AverageLatency = latency
	} else {
		alpha := 0.1 // Smoothing factor
		m.stats.AverageLatency = time.Duration(
			float64(m.stats.AverageLatency)*(1-alpha) + float64(latency)*alpha,
		)
	}
}

// seedTestData populates the mock with realistic test data
func (m *MockQDrantClient) seedTestData() {
	// Create default test collection
	m.collections["documents"] = []*QDrantPoint{
		{
			ID:     "doc1",
			Vector: generateRandomVector(768),
			Payload: map[string]interface{}{
				"title":    "Introduction to RAG Systems",
				"content":  "RAG combines retrieval and generation...",
				"category": "tech",
				"tags":     []string{"ai", "nlp", "rag"},
			},
		},
		{
			ID:     "doc2",
			Vector: generateRandomVector(768),
			Payload: map[string]interface{}{
				"title":    "Vector Databases Explained",
				"content":  "Vector databases store and search embeddings...",
				"category": "tech",
				"tags":     []string{"database", "vectors", "search"},
			},
		},
		// Add more test documents...
	}

	// Add more collections for testing
	m.collections["knowledge_base"] = []*QDrantPoint{}
	m.collections["embeddings"] = []*QDrantPoint{}
}

// generateRandomVector creates a normalized random vector
func generateRandomVector(dim int) []float64 {
	vector := make([]float64, dim)
	var magnitude float64

	for i := 0; i < dim; i++ {
		vector[i] = rand.NormFloat64()
		magnitude += vector[i] * vector[i]
	}

	magnitude = math.Sqrt(magnitude)
	for i := 0; i < dim; i++ {
		vector[i] /= magnitude
	}

	return vector
}

// GetStats returns current mock statistics
func (m *MockQDrantClient) GetStats() *MockStats {
	return m.stats
}

// GetConfig returns current mock configuration
func (m *MockQDrantClient) GetConfig() *MockConfig {
	return m.config
}

// UpdateConfig updates mock behavior configuration
func (m *MockQDrantClient) UpdateConfig(config *MockConfig) {
	m.config = config
}

// ResetStats resets all performance statistics
func (m *MockQDrantClient) ResetStats() {
	m.stats = &MockStats{}
}

// GetCollectionStats returns statistics for a specific collection
func (m *MockQDrantClient) GetCollectionStats(collection string) map[string]interface{} {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	points, exists := m.collections[collection]
	if !exists {
		return nil
	}

	return map[string]interface{}{
		"name":         collection,
		"point_count":  len(points),
		"vector_size":  len(points[0].Vector), // Assuming all vectors same size
		"last_updated": time.Now(),
	}
}
