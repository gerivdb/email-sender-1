// Package client provides RAG-optimized Qdrant client using the unified client
// Phase 2.2.2: Refactoring du Client RAG
package client

import (
	"context"
	"fmt"
	"time"

	unified "github.com/gerivdb/email-sender-1/planning-ecosystem-sync/pkg/qdrant"

	"go.uber.org/zap"
)

// RAGClient provides RAG-specific optimizations while using the unified client
// Phase 2.2.2.1: Migrer tools/qdrant/rag-go/pkg/client/qdrant.go
type RAGClient struct {
	unifiedClient unified.QdrantInterface
	logger        *zap.Logger

	// RAG-specific configurations
	chunkSize          int
	overlapSize        int
	embeddingCache     map[string][]float32
	performanceMetrics *RAGMetrics
}

// RAGMetrics tracks RAG-specific performance metrics
type RAGMetrics struct {
	DocumentsProcessed  int           `json:"documents_processed"`
	ChunksCreated       int           `json:"chunks_created"`
	CacheHits           int           `json:"cache_hits"`
	CacheMisses         int           `json:"cache_misses"`
	AverageChunkTime    time.Duration `json:"average_chunk_time"`
	TotalProcessingTime time.Duration `json:"total_processing_time"`
}

// DocumentChunk represents a document chunk for RAG processing
type DocumentChunk struct {
	ID       string                 `json:"id"`
	Content  string                 `json:"content"`
	Metadata map[string]interface{} `json:"metadata"`
	Vector   []float32              `json:"vector,omitempty"`
}

// RAGSearchRequest extends basic search with RAG-specific parameters
type RAGSearchRequest struct {
	Query          string                 `json:"query"`
	Vector         []float32              `json:"vector"`
	Limit          int                    `json:"limit"`
	MinScore       float32                `json:"min_score"`
	ContextWindow  int                    `json:"context_window"`
	Metadata       map[string]interface{} `json:"metadata,omitempty"`
	IncludeContext bool                   `json:"include_context"`
}

// RAGSearchResult contains search results with RAG context
type RAGSearchResult struct {
	Chunks      []DocumentChunk `json:"chunks"`
	Context     string          `json:"context"`
	TotalChunks int             `json:"total_chunks"`
	MaxScore    float32         `json:"max_score"`
	QueryTime   time.Duration   `json:"query_time"`
}

// NewRAGClient creates a new RAG-optimized client
// Phase 2.2.2.1.1: Adapter les optimisations RAG au client unifié
func NewRAGClient(baseURL string, logger *zap.Logger) (*RAGClient, error) {
	unifiedClient, err := unified.NewUnifiedClient(baseURL, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create unified client for RAG: %w", err)
	}

	return &RAGClient{
		unifiedClient:      unifiedClient,
		logger:             logger,
		chunkSize:          1000, // Default chunk size for RAG
		overlapSize:        200,  // Default overlap between chunks
		embeddingCache:     make(map[string][]float32),
		performanceMetrics: &RAGMetrics{},
	}, nil
}

// ProcessDocument chunks a document and stores it for RAG
// Phase 2.2.2.1.2: Préserver les fonctionnalités spécialisées
func (r *RAGClient) ProcessDocument(ctx context.Context, collection string, docID string, content string, metadata map[string]interface{}) error {
	start := time.Now()

	r.logger.Info("Processing document for RAG",
		zap.String("doc_id", docID),
		zap.Int("content_length", len(content)))

	// Chunk the document
	chunks := r.chunkDocument(content, docID)

	// Convert chunks to unified points
	points := make([]unified.Point, len(chunks))
	for i, chunk := range chunks {
		// Generate or retrieve embedding vector (simulation for now)
		vector := r.getOrGenerateEmbedding(chunk.Content)

		// Merge chunk metadata with document metadata
		payload := make(map[string]interface{})
		for k, v := range metadata {
			payload[k] = v
		}
		for k, v := range chunk.Metadata {
			payload[k] = v
		}
		payload["content"] = chunk.Content
		payload["document_id"] = docID
		payload["chunk_id"] = chunk.ID

		points[i] = unified.Point{
			ID:      chunk.ID,
			Vector:  vector,
			Payload: payload,
		}
	}

	// Upsert chunks using unified client
	err := r.unifiedClient.UpsertPoints(ctx, collection, points)
	if err != nil {
		return fmt.Errorf("failed to upsert document chunks: %w", err)
	}

	// Update metrics
	processingTime := time.Since(start)
	r.updateMetrics(len(chunks), processingTime)

	r.logger.Info("Document processed successfully",
		zap.String("doc_id", docID),
		zap.Int("chunks_created", len(chunks)),
		zap.Duration("processing_time", processingTime))

	return nil
}

// SearchRAG performs RAG-optimized vector search
// Phase 2.2.2.1.2: Préserver les fonctionnalités spécialisées
func (r *RAGClient) SearchRAG(ctx context.Context, collection string, req RAGSearchRequest) (*RAGSearchResult, error) {
	start := time.Now()

	r.logger.Debug("Performing RAG search",
		zap.String("query", req.Query),
		zap.Int("limit", req.Limit))

	// Use the unified client for vector search
	searchReq := unified.SearchRequest{
		Vector:      req.Vector,
		Limit:       req.Limit,
		WithPayload: true,
		WithVector:  false, // Don't need vectors in response for RAG
		Filter:      req.Metadata,
	}

	response, err := r.unifiedClient.SearchPoints(ctx, collection, searchReq)
	if err != nil {
		return nil, fmt.Errorf("RAG search failed: %w", err)
	}

	// Convert results to RAG format
	chunks := make([]DocumentChunk, 0, len(response.Result))
	var maxScore float32
	var context string

	for _, result := range response.Result {
		if req.MinScore > 0 && result.Score < req.MinScore {
			continue
		}

		if result.Score > maxScore {
			maxScore = result.Score
		}

		chunk := DocumentChunk{
			ID:       fmt.Sprintf("%v", result.ID),
			Metadata: result.Payload,
		}

		// Extract content from payload
		if content, ok := result.Payload["content"].(string); ok {
			chunk.Content = content
			if req.IncludeContext {
				context += content + "\n\n"
			}
		}

		chunks = append(chunks, chunk)
	}

	queryTime := time.Since(start)

	result := &RAGSearchResult{
		Chunks:      chunks,
		Context:     context,
		TotalChunks: len(chunks),
		MaxScore:    maxScore,
		QueryTime:   queryTime,
	}

	r.logger.Debug("RAG search completed",
		zap.Int("results", len(chunks)),
		zap.Float32("max_score", maxScore),
		zap.Duration("query_time", queryTime))

	return result, nil
}

// GetMetrics returns current RAG performance metrics
// Phase 2.2.2.1.3: Valider la performance (benchmarks)
func (r *RAGClient) GetMetrics() RAGMetrics {
	return *r.performanceMetrics
}

// chunkDocument splits a document into overlapping chunks
func (r *RAGClient) chunkDocument(content string, docID string) []DocumentChunk {
	var chunks []DocumentChunk

	if len(content) <= r.chunkSize {
		// Document is small enough to be a single chunk
		chunks = append(chunks, DocumentChunk{
			ID:      fmt.Sprintf("%s_chunk_0", docID),
			Content: content,
			Metadata: map[string]interface{}{
				"chunk_index":  0,
				"total_chunks": 1,
				"chunk_size":   len(content),
			},
		})
		return chunks
	}

	chunkIndex := 0
	for i := 0; i < len(content); i += (r.chunkSize - r.overlapSize) {
		end := i + r.chunkSize
		if end > len(content) {
			end = len(content)
		}

		chunkContent := content[i:end]
		chunks = append(chunks, DocumentChunk{
			ID:      fmt.Sprintf("%s_chunk_%d", docID, chunkIndex),
			Content: chunkContent,
			Metadata: map[string]interface{}{
				"chunk_index": chunkIndex,
				"start_pos":   i,
				"end_pos":     end,
				"chunk_size":  len(chunkContent),
				"has_overlap": i > 0,
			},
		})

		chunkIndex++

		if end >= len(content) {
			break
		}
	}

	// Update total chunks in metadata
	for i := range chunks {
		chunks[i].Metadata["total_chunks"] = len(chunks)
	}

	return chunks
}

// getOrGenerateEmbedding retrieves cached embedding or generates new one
func (r *RAGClient) getOrGenerateEmbedding(content string) []float32 {
	// Check cache first
	if vector, exists := r.embeddingCache[content]; exists {
		r.performanceMetrics.CacheHits++
		return vector
	}

	r.performanceMetrics.CacheMisses++

	// Generate embedding (simulation - in real implementation, use actual embedding model)
	vector := make([]float32, 384) // Using 384-dim vectors for efficiency
	hash := 0
	for _, char := range content {
		hash = hash*31 + int(char)
	}

	for i := range vector {
		vector[i] = float32((hash+i)%1000) / 1000.0
	}

	// Cache the embedding
	r.embeddingCache[content] = vector

	return vector
}

// updateMetrics updates RAG performance metrics
func (r *RAGClient) updateMetrics(chunksCreated int, processingTime time.Duration) {
	r.performanceMetrics.DocumentsProcessed++
	r.performanceMetrics.ChunksCreated += chunksCreated
	r.performanceMetrics.TotalProcessingTime += processingTime

	// Update average chunk time
	if r.performanceMetrics.ChunksCreated > 0 {
		r.performanceMetrics.AverageChunkTime = r.performanceMetrics.TotalProcessingTime / time.Duration(r.performanceMetrics.ChunksCreated)
	}
}
