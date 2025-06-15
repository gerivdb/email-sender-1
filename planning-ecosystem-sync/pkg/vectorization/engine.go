// Package vectorization provides a unified vectorization engine
// Implementation of Phase 3.1.1: Création du Package Vectorization
package vectorization

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// VectorizationEngine provides unified vectorization capabilities
// Phase 3.1.1.1.1: Implémenter VectorizationEngine avec interface standardisée
type VectorizationEngine struct {
	client      QdrantInterface
	modelClient EmbeddingClient
	cache       Cache
	logger      *zap.Logger

	// Performance optimization
	workerPool *WorkerPool
	batchSize  int
	maxRetries int
	retryDelay time.Duration
}

// EmbeddingClient interface for generating embeddings
// Phase 3.1.1.1.2: Intégrer avec sentence-transformers via HTTP API ou CLI bridge
type EmbeddingClient interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	BatchGenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error)
	GetModelInfo() ModelInfo
}

// QdrantInterface provides unified Qdrant operations
type QdrantInterface interface {
	Connect(ctx context.Context) error
	CreateCollection(ctx context.Context, name string, config CollectionConfig) error
	UpsertPoints(ctx context.Context, collection string, points []Point) error
	SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error)
	DeleteCollection(ctx context.Context, name string) error
	HealthCheck(ctx context.Context) error
}

// Cache interface for local caching
// Phase 3.1.1.1.3: Ajouter cache local pour optimiser les performances
type Cache interface {
	Get(key string) ([]float32, bool)
	Set(key string, value []float32, ttl time.Duration)
	Clear()
	Size() int
}

// ModelInfo contains embedding model information
type ModelInfo struct {
	Name      string `json:"name"`
	Dimension int    `json:"dimension"`
	MaxTokens int    `json:"max_tokens"`
	Language  string `json:"language"`
}

// CollectionConfig represents Qdrant collection configuration
type CollectionConfig struct {
	VectorSize    int    `json:"vector_size"`
	Distance      string `json:"distance"`
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

// SearchResponse represents search results
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

// VectorizationRequest represents a request for vectorization
type VectorizationRequest struct {
	Text       string                 `json:"text"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
	Collection string                 `json:"collection"`
	ID         interface{}            `json:"id,omitempty"`
}

// VectorizationResult represents the result of vectorization
type VectorizationResult struct {
	ID       interface{}            `json:"id"`
	Vector   []float32              `json:"vector"`
	Metadata map[string]interface{} `json:"metadata"`
	Success  bool                   `json:"success"`
	Error    string                 `json:"error,omitempty"`
}

// WorkerPool manages concurrent vectorization workers
// Phase 3.1.2.2.1: Parallélisation avec goroutines (worker pool pattern)
type WorkerPool struct {
	workers int
	jobs    chan VectorizationRequest
	results chan VectorizationResult
	wg      sync.WaitGroup
	ctx     context.Context
	cancel  context.CancelFunc
}

// NewVectorizationEngine creates a new vectorization engine
func NewVectorizationEngine(client QdrantInterface, modelClient EmbeddingClient, cache Cache, logger *zap.Logger) *VectorizationEngine {
	ctx, cancel := context.WithCancel(context.Background())

	engine := &VectorizationEngine{
		client:      client,
		modelClient: modelClient,
		cache:       cache,
		logger:      logger,
		batchSize:   50, // Default batch size
		maxRetries:  3,  // Default retry count
		retryDelay:  time.Second * 2,
		workerPool: &WorkerPool{
			workers: 4, // Default worker count
			jobs:    make(chan VectorizationRequest, 100),
			results: make(chan VectorizationResult, 100),
			ctx:     ctx,
			cancel:  cancel,
		},
	}

	// Start worker pool
	engine.startWorkerPool()

	return engine
}

// Initialize initializes the vectorization engine
func (ve *VectorizationEngine) Initialize(ctx context.Context) error {
	ve.logger.Info("🚀 Initializing vectorization engine")

	// Connect to Qdrant
	if err := ve.client.Connect(ctx); err != nil {
		ve.logger.Error("Failed to connect to Qdrant", zap.Error(err))
		return fmt.Errorf("failed to connect to Qdrant: %w", err)
	}

	// Verify model client
	modelInfo := ve.modelClient.GetModelInfo()
	ve.logger.Info("🤖 Model client initialized",
		zap.String("model", modelInfo.Name),
		zap.Int("dimension", modelInfo.Dimension))

	// Initialize cache
	ve.cache.Clear()
	ve.logger.Info("💾 Cache initialized")

	ve.logger.Info("✅ Vectorization engine initialized successfully")
	return nil
}

// VectorizeText vectorizes a single text with caching
func (ve *VectorizationEngine) VectorizeText(ctx context.Context, text string) ([]float32, error) {
	// Check cache first
	if cached, found := ve.cache.Get(text); found {
		ve.logger.Debug("🎯 Cache hit for text", zap.String("text_preview", text[:min(50, len(text))]))
		return cached, nil
	}

	// Generate embedding
	embedding, err := ve.modelClient.GenerateEmbedding(ctx, text)
	if err != nil {
		return nil, fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Cache the result
	ve.cache.Set(text, embedding, time.Hour*24) // Cache for 24 hours

	ve.logger.Debug("✨ Generated new embedding",
		zap.String("text_preview", text[:min(50, len(text))]),
		zap.Int("dimension", len(embedding)))

	return embedding, nil
}

// VectorizeBatch vectorizes multiple texts efficiently
// Phase 3.1.2.2.2: Batching intelligent des opérations Qdrant
func (ve *VectorizationEngine) VectorizeBatch(ctx context.Context, texts []string) ([][]float32, error) {
	ve.logger.Info("📊 Starting batch vectorization", zap.Int("text_count", len(texts)))

	var uncachedTexts []string
	var uncachedIndices []int
	results := make([][]float32, len(texts))

	// Check cache for all texts
	for i, text := range texts {
		if cached, found := ve.cache.Get(text); found {
			results[i] = cached
		} else {
			uncachedTexts = append(uncachedTexts, text)
			uncachedIndices = append(uncachedIndices, i)
		}
	}

	ve.logger.Info("💾 Cache analysis",
		zap.Int("total", len(texts)),
		zap.Int("cached", len(texts)-len(uncachedTexts)),
		zap.Int("uncached", len(uncachedTexts)))

	if len(uncachedTexts) == 0 {
		return results, nil
	}

	// Generate embeddings for uncached texts
	embeddings, err := ve.modelClient.BatchGenerateEmbeddings(ctx, uncachedTexts)
	if err != nil {
		return nil, fmt.Errorf("failed to generate batch embeddings: %w", err)
	}

	// Fill results and cache new embeddings
	for i, embedding := range embeddings {
		resultIndex := uncachedIndices[i]
		results[resultIndex] = embedding
		ve.cache.Set(uncachedTexts[i], embedding, time.Hour*24)
	}

	ve.logger.Info("✅ Batch vectorization completed",
		zap.Int("generated", len(uncachedTexts)),
		zap.Int("total", len(texts)))

	return results, nil
}

// StoreVectors stores vectors in Qdrant with retry logic
// Phase 3.1.2.1.3: Ajouter l'upload vers Qdrant avec retry logic
func (ve *VectorizationEngine) StoreVectors(ctx context.Context, collection string, points []Point) error {
	ve.logger.Info("💾 Storing vectors in Qdrant",
		zap.String("collection", collection),
		zap.Int("point_count", len(points)))

	var lastErr error
	for attempt := 1; attempt <= ve.maxRetries; attempt++ {
		err := ve.client.UpsertPoints(ctx, collection, points)
		if err == nil {
			ve.logger.Info("✅ Successfully stored vectors",
				zap.String("collection", collection),
				zap.Int("points", len(points)),
				zap.Int("attempt", attempt))
			return nil
		}

		lastErr = err
		ve.logger.Warn("⚠️ Failed to store vectors, retrying",
			zap.Error(err),
			zap.Int("attempt", attempt),
			zap.Int("max_retries", ve.maxRetries))

		if attempt < ve.maxRetries {
			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(ve.retryDelay * time.Duration(attempt)):
				// Exponential backoff
			}
		}
	}

	return fmt.Errorf("failed to store vectors after %d attempts: %w", ve.maxRetries, lastErr)
}

// ProcessRequests processes vectorization requests using worker pool
func (ve *VectorizationEngine) ProcessRequests(requests []VectorizationRequest) []VectorizationResult {
	ve.logger.Info("🔄 Processing vectorization requests", zap.Int("count", len(requests)))

	results := make([]VectorizationResult, 0, len(requests))

	// Send jobs to worker pool
	go func() {
		defer close(ve.workerPool.jobs)
		for _, req := range requests {
			select {
			case ve.workerPool.jobs <- req:
			case <-ve.workerPool.ctx.Done():
				return
			}
		}
	}()

	// Collect results
	for i := 0; i < len(requests); i++ {
		select {
		case result := <-ve.workerPool.results:
			results = append(results, result)
		case <-ve.workerPool.ctx.Done():
			break
		}
	}

	ve.logger.Info("✅ Completed processing requests",
		zap.Int("processed", len(results)),
		zap.Int("total", len(requests)))

	return results
}

// startWorkerPool starts the worker pool for concurrent processing
func (ve *VectorizationEngine) startWorkerPool() {
	for i := 0; i < ve.workerPool.workers; i++ {
		ve.workerPool.wg.Add(1)
		go ve.worker(i)
	}
}

// worker processes vectorization jobs
func (ve *VectorizationEngine) worker(id int) {
	defer ve.workerPool.wg.Done()

	ve.logger.Debug("🔧 Starting worker", zap.Int("worker_id", id))

	for {
		select {
		case req, ok := <-ve.workerPool.jobs:
			if !ok {
				ve.logger.Debug("🔧 Worker stopping", zap.Int("worker_id", id))
				return
			}

			result := ve.processRequest(req)

			select {
			case ve.workerPool.results <- result:
			case <-ve.workerPool.ctx.Done():
				return
			}

		case <-ve.workerPool.ctx.Done():
			ve.logger.Debug("🔧 Worker cancelled", zap.Int("worker_id", id))
			return
		}
	}
}

// processRequest processes a single vectorization request
func (ve *VectorizationEngine) processRequest(req VectorizationRequest) VectorizationResult {
	ctx, cancel := context.WithTimeout(ve.workerPool.ctx, time.Minute*5)
	defer cancel()

	// Generate embedding
	vector, err := ve.VectorizeText(ctx, req.Text)
	if err != nil {
		return VectorizationResult{
			ID:      req.ID,
			Success: false,
			Error:   err.Error(),
		}
	}

	// Create point
	point := Point{
		ID:      req.ID,
		Vector:  vector,
		Payload: req.Metadata,
	}

	// Store in Qdrant
	if err := ve.StoreVectors(ctx, req.Collection, []Point{point}); err != nil {
		return VectorizationResult{
			ID:      req.ID,
			Vector:  vector,
			Success: false,
			Error:   err.Error(),
		}
	}

	return VectorizationResult{
		ID:       req.ID,
		Vector:   vector,
		Metadata: req.Metadata,
		Success:  true,
	}
}

// Shutdown gracefully shuts down the vectorization engine
func (ve *VectorizationEngine) Shutdown() {
	ve.logger.Info("🛑 Shutting down vectorization engine")

	// Stop worker pool
	ve.workerPool.cancel()
	ve.workerPool.wg.Wait()

	// Clear cache
	ve.cache.Clear()

	ve.logger.Info("✅ Vectorization engine shutdown complete")
}

// GetStats returns engine statistics
func (ve *VectorizationEngine) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"cache_size":     ve.cache.Size(),
		"worker_count":   ve.workerPool.workers,
		"batch_size":     ve.batchSize,
		"max_retries":    ve.maxRetries,
		"retry_delay_ms": ve.retryDelay.Milliseconds(),
		"model_info":     ve.modelClient.GetModelInfo(),
	}
}

// Helper function for min
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
