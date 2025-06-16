package ai

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

func TestNewQDrantClient(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()

	client, err := NewQDrantClient(config, logger)
	if err != nil {
		t.Errorf("Unexpected error creating QDrant client: %v", err)
	}
	if client == nil {
		t.Error("QDrant client should not be nil")
	}
	if client.config != config {
		t.Error("Config should be set correctly")
	}
	if client.connected {
		t.Error("Client should not be connected initially")
	}
}

func TestQDrantClient_StartStop(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	client, _ := NewQDrantClient(config, logger)

	ctx := context.Background()

	// Test start
	startTime := time.Now()
	err := client.Start(ctx)
	startDuration := time.Since(startTime)

	if err != nil {
		t.Errorf("Unexpected error starting client: %v", err)
	}
	if !client.connected {
		t.Error("Client should be connected after start")
	}
	if startDuration > 100*time.Millisecond {
		t.Errorf("Start took %v, should be < 100ms for FMOUA compliance", startDuration)
	}

	// Test stop
	err = client.Stop()
	if err != nil {
		t.Errorf("Unexpected error stopping client: %v", err)
	}
	if client.connected {
		t.Error("Client should not be connected after stop")
	}
}

func TestQDrantClient_VectorizeText(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	client, _ := NewQDrantClient(config, logger)

	// Test vectorization without connection
	_, err := client.VectorizeText("test text")
	if err == nil {
		t.Error("Should return error when not connected")
	}

	// Connect and test vectorization
	ctx := context.Background()
	client.Start(ctx)
	defer client.Stop()

	vector, err := client.VectorizeText("test text content")
	if err != nil {
		t.Errorf("Unexpected error vectorizing text: %v", err)
	}
	if len(vector) != 768 {
		t.Errorf("Expected vector size 768, got %d", len(vector))
	}

	// Test performance
	startTime := time.Now()
	for i := 0; i < 10; i++ {
		client.VectorizeText("performance test")
	}
	duration := time.Since(startTime)
	averageLatency := duration / 10

	if averageLatency > 10*time.Millisecond {
		t.Errorf("Average vectorization latency %v too high", averageLatency)
	}
}

func TestNewAnalysisCache(t *testing.T) {
	logger := zap.NewNop()
	cache := NewAnalysisCache(100, logger)

	if cache == nil {
		t.Error("Cache should not be nil")
	}
	if cache.maxSize != 100 {
		t.Errorf("Expected max size 100, got %d", cache.maxSize)
	}
	if len(cache.cache) != 0 {
		t.Error("Cache should be empty initially")
	}
}

func TestAnalysisCache_GetSet(t *testing.T) {
	logger := zap.NewNop()
	cache := NewAnalysisCache(2, logger)

	decision := &interfaces.AIDecision{
		ID:             "test_decision",
		Type:           interfaces.DecisionOrganization,
		Confidence:     0.9,
		Recommendation: "Test recommendation",
		Timestamp:      time.Now(),
		Actions:        []interfaces.RecommendedAction{},
	}

	// Test miss
	result := cache.Get("missing_key")
	if result != nil {
		t.Error("Should return nil for missing key")
	}
	if cache.misses != 1 {
		t.Errorf("Expected 1 miss, got %d", cache.misses)
	}

	// Test set and hit
	cache.Set("test_key", decision)
	result = cache.Get("test_key")
	if result == nil {
		t.Error("Should return cached decision")
	}
	if result.ID != decision.ID {
		t.Error("Cached decision should match original")
	}
	if cache.hits != 1 {
		t.Errorf("Expected 1 hit, got %d", cache.hits)
	}

	// Test eviction (maxSize = 2)
	decision2 := &interfaces.AIDecision{ID: "decision2"}
	decision3 := &interfaces.AIDecision{ID: "decision3"}

	cache.Set("key2", decision2)
	cache.Set("key3", decision3) // Should evict first entry

	if len(cache.cache) > 2 {
		t.Errorf("Cache size should not exceed maxSize, got %d", len(cache.cache))
	}
}

func TestAnalysisCache_WarmUp(t *testing.T) {
	logger := zap.NewNop()
	cache := NewAnalysisCache(100, logger)

	err := cache.WarmUp()
	if err != nil {
		t.Errorf("Unexpected error warming up cache: %v", err)
	}
}

func TestNewDecisionEngine(t *testing.T) {
	config := &types.AIConfig{
		Enabled:             true,
		Provider:            "openai",
		Model:               "gpt-4",
		ConfidenceThreshold: 0.8,
	}
	logger := zap.NewNop()

	engine := NewDecisionEngine(config, logger)
	if engine == nil {
		t.Error("Decision engine should not be nil")
	}
	if engine.config != config {
		t.Error("Config should be set correctly")
	}
}

func TestDecisionEngine_StartStop(t *testing.T) {
	config := &types.AIConfig{
		Enabled:             true,
		Provider:            "openai",
		Model:               "gpt-4",
		ConfidenceThreshold: 0.8,
	}
	logger := zap.NewNop()
	engine := NewDecisionEngine(config, logger)

	ctx := context.Background()

	err := engine.Start(ctx)
	if err != nil {
		t.Errorf("Unexpected error starting decision engine: %v", err)
	}

	err = engine.Stop()
	if err != nil {
		t.Errorf("Unexpected error stopping decision engine: %v", err)
	}
}

func TestDecisionEngine_Analyze(t *testing.T) {
	config := &types.AIConfig{
		Enabled:             true,
		Provider:            "openai",
		Model:               "gpt-4",
		ConfidenceThreshold: 0.8,
	}
	logger := zap.NewNop()
	engine := NewDecisionEngine(config, logger)

	// Test with sufficient vectors
	vectors := make([][]float32, 15)
	for i := range vectors {
		vectors[i] = make([]float32, 768)
	}

	decision, err := engine.Analyze(vectors)
	if err != nil {
		t.Errorf("Unexpected error analyzing vectors: %v", err)
	}
	if decision == nil {
		t.Error("Decision should not be nil")
	}
	if decision.Confidence != 0.9 {
		t.Errorf("Expected confidence 0.9, got %f", decision.Confidence)
	}
	if decision.Type != interfaces.DecisionOrganization {
		t.Errorf("Expected DecisionOrganization, got %v", decision.Type)
	}

	// Test with insufficient vectors (lower confidence)
	smallVectors := make([][]float32, 5)
	for i := range smallVectors {
		smallVectors[i] = make([]float32, 768)
	}

	decision, err = engine.Analyze(smallVectors)
	if err != nil {
		t.Errorf("Unexpected error analyzing small vectors: %v", err)
	}
	if decision.Confidence != 0.7 {
		t.Errorf("Expected confidence 0.7 for small dataset, got %f", decision.Confidence)
	}
}

func TestNewVectorStore(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	qdrantClient, _ := NewQDrantClient(config, logger)

	vectorStore := NewVectorStore(qdrantClient, logger)
	if vectorStore == nil {
		t.Error("Vector store should not be nil")
	}
	if vectorStore.qdrantClient != qdrantClient {
		t.Error("QDrant client should be set correctly")
	}
}

func TestVectorStore_Initialize(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	qdrantClient, _ := NewQDrantClient(config, logger)
	vectorStore := NewVectorStore(qdrantClient, logger)

	err := vectorStore.Initialize()
	if err != nil {
		t.Errorf("Unexpected error initializing vector store: %v", err)
	}
}

func TestVectorStore_VectorizeRepository(t *testing.T) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	qdrantClient, _ := NewQDrantClient(config, logger)

	// Connect QDrant client
	ctx := context.Background()
	qdrantClient.Start(ctx)
	defer qdrantClient.Stop()

	vectorStore := NewVectorStore(qdrantClient, logger)

	vectors, err := vectorStore.VectorizeRepository("/test/repo")
	if err != nil {
		t.Errorf("Unexpected error vectorizing repository: %v", err)
	}
	if len(vectors) == 0 {
		t.Error("Should return at least one vector")
	}

	// Verify vector dimensions
	for i, vector := range vectors {
		if len(vector) != 768 {
			t.Errorf("Vector %d has wrong size: expected 768, got %d", i, len(vector))
		}
	}
}

func TestAnalysisCache_Performance(t *testing.T) {
	logger := zap.NewNop()
	cache := NewAnalysisCache(1000, logger)

	// Populate cache
	for i := 0; i < 100; i++ {
		decision := &interfaces.AIDecision{
			ID:         fmt.Sprintf("decision_%d", i),
			Confidence: 0.9,
		}
		cache.Set(fmt.Sprintf("key_%d", i), decision)
	}

	// Test retrieval performance
	startTime := time.Now()
	for i := 0; i < 1000; i++ {
		cache.Get(fmt.Sprintf("key_%d", i%100))
	}
	duration := time.Since(startTime)

	averageLatency := duration / 1000
	if averageLatency > time.Microsecond*100 {
		t.Errorf("Cache retrieval too slow: %v per operation", averageLatency)
	}
}

func BenchmarkQDrantClient_VectorizeText(b *testing.B) {
	config := &types.QDrantConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "test_collection",
		VectorSize:     768,
		DistanceMetric: "cosine",
		Timeout:        30 * time.Second,
	}
	logger := zap.NewNop()
	client, _ := NewQDrantClient(config, logger)

	ctx := context.Background()
	client.Start(ctx)
	defer client.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		client.VectorizeText("benchmark test text")
	}
}

func BenchmarkAnalysisCache_GetSet(b *testing.B) {
	logger := zap.NewNop()
	cache := NewAnalysisCache(1000, logger)

	decision := &interfaces.AIDecision{
		ID:         "bench_decision",
		Confidence: 0.9,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		key := fmt.Sprintf("key_%d", i%100)
		if i%2 == 0 {
			cache.Set(key, decision)
		} else {
			cache.Get(key)
		}
	}
}
