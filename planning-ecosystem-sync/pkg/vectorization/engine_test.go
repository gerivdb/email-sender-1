package vectorization

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap/zaptest"
)

// TestVectorizationEngine_NewVectorizationEngine tests engine creation
func TestVectorizationEngine_NewVectorizationEngine(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	if engine == nil {
		t.Fatal("Engine should not be nil")
	}

	if engine.client != mockClient {
		t.Error("Client not properly set")
	}

	if engine.modelClient != mockEmbedding {
		t.Error("Model client not properly set")
	}

	if engine.cache != mockCache {
		t.Error("Cache not properly set")
	}

	if engine.logger != logger {
		t.Error("Logger not properly set")
	}
}

// TestVectorizationEngine_Initialize tests engine initialization
func TestVectorizationEngine_Initialize(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	ctx := context.Background()
	err := engine.Initialize(ctx)

	if err != nil {
		t.Errorf("Initialize should not fail: %v", err)
	}

	if !mockClient.connected {
		t.Error("Client should be connected after initialization")
	}

	if !mockCache.cleared {
		t.Error("Cache should be cleared during initialization")
	}
}

// TestVectorizationEngine_VectorizeText tests single text vectorization
func TestVectorizationEngine_VectorizeText(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	ctx := context.Background()
	text := "Test text for vectorization"

	vector, err := engine.VectorizeText(ctx, text)

	if err != nil {
		t.Errorf("VectorizeText should not fail: %v", err)
	}

	if len(vector) == 0 {
		t.Error("Vector should not be empty")
	}

	expectedDimension := 384 // Standard dimension
	if len(vector) != expectedDimension {
		t.Errorf("Vector dimension should be %d, got %d", expectedDimension, len(vector))
	}

	// Check if result was cached
	if !mockCache.setWasCalled {
		t.Error("Vector should be cached after generation")
	}
}

// TestVectorizationEngine_VectorizeText_Cache tests cache functionality
func TestVectorizationEngine_VectorizeText_Cache(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	ctx := context.Background()
	text := "Cached text"

	// Set up cache to return a value
	cachedVector := []float32{0.1, 0.2, 0.3}
	mockCache.cachedVectors[text] = cachedVector

	vector, err := engine.VectorizeText(ctx, text)

	if err != nil {
		t.Errorf("VectorizeText should not fail: %v", err)
	}

	// Should return cached vector
	if len(vector) != len(cachedVector) {
		t.Error("Should return cached vector")
	}

	// Should not call embedding client
	if mockEmbedding.generateWasCalled {
		t.Error("Should not generate new embedding when cached")
	}
}

// TestVectorizationEngine_VectorizeBatch tests batch vectorization
func TestVectorizationEngine_VectorizeBatch(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	ctx := context.Background()
	texts := []string{
		"First text",
		"Second text",
		"Third text",
	}

	vectors, err := engine.VectorizeBatch(ctx, texts)

	if err != nil {
		t.Errorf("VectorizeBatch should not fail: %v", err)
	}

	if len(vectors) != len(texts) {
		t.Errorf("Should return %d vectors, got %d", len(texts), len(vectors))
	}

	for i, vector := range vectors {
		if len(vector) == 0 {
			t.Errorf("Vector %d should not be empty", i)
		}
	}

	// Check if batch generation was called
	if !mockEmbedding.batchGenerateWasCalled {
		t.Error("Batch generation should be called")
	}
}

// TestVectorizationEngine_StoreVectors tests vector storage
func TestVectorizationEngine_StoreVectors(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	ctx := context.Background()
	collection := "test_collection"
	points := []Point{
		{
			ID:     "test_1",
			Vector: []float32{0.1, 0.2, 0.3},
			Payload: map[string]interface{}{
				"text": "Test text",
			},
		},
	}

	err := engine.StoreVectors(ctx, collection, points)

	if err != nil {
		t.Errorf("StoreVectors should not fail: %v", err)
	}

	if !mockClient.upsertWasCalled {
		t.Error("Upsert should be called on client")
	}

	if mockClient.lastCollection != collection {
		t.Errorf("Collection should be %s, got %s", collection, mockClient.lastCollection)
	}
}

// TestVectorizationEngine_StoreVectors_Retry tests retry logic
func TestVectorizationEngine_StoreVectors_Retry(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	// Set up client to fail first few attempts
	mockClient.shouldFailUpsert = true
	mockClient.failCount = 2

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)
	engine.maxRetries = 3
	engine.retryDelay = time.Millisecond * 10 // Speed up test

	ctx := context.Background()
	collection := "test_collection"
	points := []Point{
		{
			ID:     "test_1",
			Vector: []float32{0.1, 0.2, 0.3},
		},
	}

	err := engine.StoreVectors(ctx, collection, points)

	if err != nil {
		t.Errorf("StoreVectors should succeed after retries: %v", err)
	}

	if mockClient.upsertAttempts < 3 {
		t.Errorf("Should have attempted upsert at least 3 times, got %d", mockClient.upsertAttempts)
	}
}

// TestVectorizationEngine_GetStats tests statistics retrieval
func TestVectorizationEngine_GetStats(t *testing.T) {
	logger := zaptest.NewLogger(t)
	mockClient := &MockQdrantClient{}
	mockEmbedding := &MockEmbeddingClient{}
	mockCache := &MockCache{}

	engine := NewVectorizationEngine(mockClient, mockEmbedding, mockCache, logger)

	stats := engine.GetStats()

	if stats == nil {
		t.Fatal("Stats should not be nil")
	}

	// Check required fields
	requiredFields := []string{"cache_size", "worker_count", "batch_size", "max_retries", "model_info"}
	for _, field := range requiredFields {
		if _, exists := stats[field]; !exists {
			t.Errorf("Stats should contain field: %s", field)
		}
	}
}

// Mock implementations for testing

type MockQdrantClient struct {
	connected        bool
	upsertWasCalled  bool
	lastCollection   string
	shouldFailUpsert bool
	failCount        int
	upsertAttempts   int
}

func (m *MockQdrantClient) Connect(ctx context.Context) error {
	m.connected = true
	return nil
}

func (m *MockQdrantClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error {
	return nil
}

func (m *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	m.upsertWasCalled = true
	m.lastCollection = collection
	m.upsertAttempts++

	if m.shouldFailUpsert && m.upsertAttempts <= m.failCount {
		return fmt.Errorf("mock upsert failure")
	}

	return nil
}

func (m *MockQdrantClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error) {
	return &SearchResponse{Result: []ScoredPoint{}}, nil
}

func (m *MockQdrantClient) DeleteCollection(ctx context.Context, name string) error {
	return nil
}

func (m *MockQdrantClient) HealthCheck(ctx context.Context) error {
	return nil
}

type MockEmbeddingClient struct {
	generateWasCalled      bool
	batchGenerateWasCalled bool
}

func (m *MockEmbeddingClient) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	m.generateWasCalled = true
	// Return mock embedding
	embedding := make([]float32, 384)
	for i := range embedding {
		embedding[i] = float32(len(text)) / float32(1000+i)
	}
	return embedding, nil
}

func (m *MockEmbeddingClient) BatchGenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error) {
	m.batchGenerateWasCalled = true
	embeddings := make([][]float32, len(texts))
	for i, text := range texts {
		embedding, err := m.GenerateEmbedding(ctx, text)
		if err != nil {
			return nil, err
		}
		embeddings[i] = embedding
	}
	return embeddings, nil
}

func (m *MockEmbeddingClient) GetModelInfo() ModelInfo {
	return ModelInfo{
		Name:      "mock-model",
		Dimension: 384,
		MaxTokens: 512,
		Language:  "en",
	}
}

type MockCache struct {
	cachedVectors map[string][]float32
	setWasCalled  bool
	cleared       bool
}

func NewMockCache() *MockCache {
	return &MockCache{
		cachedVectors: make(map[string][]float32),
	}
}

func (m *MockCache) Get(key string) ([]float32, bool) {
	vector, exists := m.cachedVectors[key]
	return vector, exists
}

func (m *MockCache) Set(key string, value []float32, ttl time.Duration) {
	m.setWasCalled = true
	if m.cachedVectors == nil {
		m.cachedVectors = make(map[string][]float32)
	}
	m.cachedVectors[key] = value
}

func (m *MockCache) Clear() {
	m.cleared = true
	m.cachedVectors = make(map[string][]float32)
}

func (m *MockCache) Size() int {
	return len(m.cachedVectors)
}
