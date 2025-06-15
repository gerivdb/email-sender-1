// Package qdrant provides migration wrappers for existing Qdrant clients
// Phase 2.2.1: Refactoring du Client Principal
package qdrant

import (
	"context"
	"fmt"

	unified "email_sender/planning-ecosystem-sync/pkg/qdrant"

	"go.uber.org/zap"
)

// LegacyClientWrapper wraps the original client to maintain API compatibility
// Phase 2.2.1.1: Migrer src/qdrant/qdrant.go vers le client unifié
type LegacyClientWrapper struct {
	unifiedClient unified.QdrantInterface
	logger        *zap.Logger
}

// Original structures from src/qdrant/qdrant.go for compatibility
type QdrantClient struct {
	BaseURL    string
	HTTPClient interface{} // Simplified for compatibility
}

type Point struct {
	ID      interface{}            `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// NewLegacyClientWrapper creates a wrapper around the unified client
// Phase 2.2.1.1.1: Wrapper les méthodes existantes
func NewLegacyClientWrapper(baseURL string, logger *zap.Logger) (*LegacyClientWrapper, error) {
	unifiedClient, err := unified.NewUnifiedClient(baseURL, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create unified client: %w", err)
	}

	return &LegacyClientWrapper{
		unifiedClient: unifiedClient,
		logger:        logger,
	}, nil
}

// CreateCollection maintains the original API signature
// Phase 2.2.1.1.2: Maintenir la compatibilité API
func (w *LegacyClientWrapper) CreateCollection(ctx context.Context, name string, vectorSize int, distance string) error {
	config := unified.CollectionConfig{
		VectorSize:    vectorSize,
		Distance:      distance,
		OnDiskPayload: false,
		ReplicaCount:  1,
		ShardNumber:   1,
	}

	w.logger.Info("Creating collection via legacy wrapper",
		zap.String("name", name),
		zap.Int("vector_size", vectorSize))

	return w.unifiedClient.CreateCollection(ctx, name, config)
}

// UpsertPoints maintains the original API signature
func (w *LegacyClientWrapper) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	// Convert legacy points to unified points
	unifiedPoints := make([]unified.Point, len(points))
	for i, p := range points {
		unifiedPoints[i] = unified.Point{
			ID:      p.ID,
			Vector:  p.Vector,
			Payload: p.Payload,
		}
	}

	return w.unifiedClient.UpsertPoints(ctx, collection, unifiedPoints)
}

// SearchPoints maintains the original API signature but returns legacy format
func (w *LegacyClientWrapper) SearchPoints(ctx context.Context, collection string, vector []float32, limit int) ([]Point, error) {
	searchReq := unified.SearchRequest{
		Vector:      vector,
		Limit:       limit,
		WithPayload: true,
		WithVector:  true,
	}

	response, err := w.unifiedClient.SearchPoints(ctx, collection, searchReq)
	if err != nil {
		return nil, err
	}

	// Convert unified response to legacy format
	legacyPoints := make([]Point, len(response.Result))
	for i, result := range response.Result {
		legacyPoints[i] = Point{
			ID:      result.ID,
			Vector:  result.Vector,
			Payload: result.Payload,
		}
	}

	return legacyPoints, nil
}

// DeleteCollection maintains the original API signature
func (w *LegacyClientWrapper) DeleteCollection(ctx context.Context, name string) error {
	return w.unifiedClient.DeleteCollection(ctx, name)
}

// Connect maintains the original API signature
func (w *LegacyClientWrapper) Connect(ctx context.Context) error {
	return w.unifiedClient.Connect(ctx)
}
