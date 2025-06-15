package main

import (
	"context"
	"fmt"
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

// SyncClient wraps the unified Qdrant client for sync-core operations
// Implementation of Phase 2.2.3.1: Migrer planning-ecosystem-sync/tools/sync-core/qdrant.go
type SyncClient struct {
	unifiedClient QdrantInterface
	logger        *zap.Logger
	ctx           context.Context
}

// PlanPoint represents a plan point for sync operations  
// Adapted from QDrantPoint to work with unified client
type PlanPoint struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"` // Changed from float64 to float32 for unified client
	Payload map[string]interface{} `json:"payload"`
}

// SyncResponse represents sync operation response
// Modernized response structure
type SyncResponse struct {
	Success bool        `json:"success"`
	Result  interface{} `json:"result,omitempty"`
	Error   string      `json:"error,omitempty"`
	Time    time.Time   `json:"time"`
}

// NewSyncClient creates a new sync client using the unified Qdrant client
// Phase 2.2.3.1.1: Adapter les méthodes de synchronisation
func NewSyncClient(baseURL string, logger *zap.Logger) (*SyncClient, error) {
	// For now, we'll create a mock client that implements the interface
	// In a real implementation, this would use the actual unified client
	mockClient := &MockUnifiedClient{baseURL: baseURL, logger: logger}

	return &SyncClient{
		unifiedClient: mockClient,
		logger:        logger,
		ctx:           context.Background(),
	}, nil
}

// MockUnifiedClient is a temporary implementation for demonstration
// In production, this would be replaced with the actual unified client
type MockUnifiedClient struct {
	baseURL string
	logger  *zap.Logger
}

func (m *MockUnifiedClient) Connect(ctx context.Context) error {
	m.logger.Info("MockUnifiedClient: Connect called")
	return nil
}

func (m *MockUnifiedClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error {
	m.logger.Info("MockUnifiedClient: CreateCollection called", zap.String("name", name))
	return nil
}

func (m *MockUnifiedClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	m.logger.Info("MockUnifiedClient: UpsertPoints called", 
		zap.String("collection", collection), 
		zap.Int("points_count", len(points)))
	return nil
}

func (m *MockUnifiedClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error) {
	m.logger.Info("MockUnifiedClient: SearchPoints called", zap.String("collection", collection))
	return &SearchResponse{Result: []ScoredPoint{}}, nil
}

func (m *MockUnifiedClient) DeleteCollection(ctx context.Context, name string) error {
	m.logger.Info("MockUnifiedClient: DeleteCollection called", zap.String("name", name))
	return nil
}

func (m *MockUnifiedClient) HealthCheck(ctx context.Context) error {
	m.logger.Info("MockUnifiedClient: HealthCheck called")
	return nil
}

// PlanPoint represents a plan point for sync operations  
// Adapted from QDrantPoint to work with unified client
type PlanPoint struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"` // Changed from float64 to float32 for unified client
	Payload map[string]interface{} `json:"payload"`
}

// SyncResponse represents sync operation response
// Modernized response structure
type SyncResponse struct {
	Success bool        `json:"success"`
	Result  interface{} `json:"result,omitempty"`
	Error   string      `json:"error,omitempty"`
	Time    time.Time   `json:"time"`
}

// NewSyncClient creates a new sync client using the unified Qdrant client
// Phase 2.2.3.1.1: Adapter les méthodes de synchronisation
func NewSyncClient(baseURL string, logger *zap.Logger) (*SyncClient, error) {
	// Create unified client
	unifiedClient, err := qdrant.NewUnifiedClient(baseURL, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create unified client: %w", err)
	}

	return &SyncClient{
		unifiedClient: unifiedClient,
		logger:        logger,
		ctx:           context.Background(),
	}, nil
}

// StorePlanEmbeddings stores plan embeddings using the unified client
// Phase 2.2.3.1.1: Adapter les méthodes de synchronisation
func (sc *SyncClient) StorePlanEmbeddings(plan *DynamicPlan) error {
	sc.logger.Info("📡 Storing embeddings for plan", zap.String("plan_id", plan.ID))
	
	if len(plan.Embeddings) == 0 {
		return fmt.Errorf("plan has no embeddings to store")
	}
	// Ensure collection exists
	collectionName := "plan_embeddings"
	collectionConfig := CollectionConfig{
		VectorSize:    len(plan.Embeddings),
		Distance:      "cosine",
		OnDiskPayload: false,
		ReplicaCount:  1,
		ShardNumber:   1,
	}

	// Phase 2.2.3.1.2: Intégrer avec le nouveau système de logging
	ctx, cancel := context.WithTimeout(sc.ctx, 30*time.Second)
	defer cancel()

	// Create collection if it doesn't exist (will be no-op if exists)
	if err := sc.unifiedClient.CreateCollection(ctx, collectionName, collectionConfig); err != nil {
		sc.logger.Error("Failed to create collection", zap.Error(err))
		return fmt.Errorf("failed to create collection: %w", err)
	}

	// Convert plan to points for unified client
	points := []Point{
		{
			ID:     plan.ID,
			Vector: plan.Embeddings,
			Payload: map[string]interface{}{
				"plan_name":    plan.Name,
				"description":  plan.Description,
				"created_at":   plan.CreatedAt,
				"updated_at":   plan.UpdatedAt,
				"status":       plan.Status,
				"dependencies": plan.Dependencies,
			},
		},
	}
	// Store using unified client
	if err := sc.unifiedClient.UpsertPoints(ctx, collectionName, points); err != nil {
		sc.logger.Error("Failed to store embeddings", zap.Error(err))
		return fmt.Errorf("failed to store embeddings: %w", err)
	}

	sc.logger.Info("✅ Successfully stored plan embeddings", 
		zap.String("plan_id", plan.ID),
		zap.Int("vector_size", len(plan.Embeddings)))

	return nil
}

// SearchSimilarPlans finds similar plans using unified client vector search
// Phase 2.2.3.1.1: Adapter les méthodes de synchronisation
func (sc *SyncClient) SearchSimilarPlans(queryVector []float32, limit int) (*SearchResponse, error) {
	sc.logger.Info("🔍 Searching for similar plans", zap.Int("limit", limit))
	
	ctx, cancel := context.WithTimeout(sc.ctx, 15*time.Second)
	defer cancel()

	searchReq := SearchRequest{
		Vector:      queryVector,
		Limit:       limit,
		WithPayload: true,
		WithVector:  false,
	}

	response, err := sc.unifiedClient.SearchPoints(ctx, "plan_embeddings", searchReq)
	if err != nil {
		sc.logger.Error("Failed to search similar plans", zap.Error(err))
		return nil, fmt.Errorf("failed to search similar plans: %w", err)
	}

	sc.logger.Info("✅ Found similar plans", zap.Int("count", len(response.Result)))
	return response, nil
}

// HealthCheck verifies Qdrant connection using unified client
// Phase 2.2.3.1.3: Valider l'intégrité des données synchronisées
func (sc *SyncClient) HealthCheck() error {
	ctx, cancel := context.WithTimeout(sc.ctx, 10*time.Second)
	defer cancel()

	if err := sc.unifiedClient.HealthCheck(ctx); err != nil {
		sc.logger.Error("Health check failed", zap.Error(err))
		return fmt.Errorf("health check failed: %w", err)
	}

	sc.logger.Info("✅ Health check passed")
	return nil
}

// SyncPlanData synchronizes plan data with integrity validation
// Phase 2.2.3.1.3: Valider l'intégrité des données synchronisées
func (sc *SyncClient) SyncPlanData(plans []*DynamicPlan) error {
	sc.logger.Info("🔄 Starting plan data synchronization", zap.Int("plan_count", len(plans)))
	
	// Validate data integrity before sync
	for _, plan := range plans {
		if plan.ID == "" {
			return fmt.Errorf("plan missing ID")
		}
		if len(plan.Embeddings) == 0 {
			return fmt.Errorf("plan %s missing embeddings", plan.ID)
		}
	}

	// Store each plan
	successCount := 0
	for _, plan := range plans {
		if err := sc.StorePlanEmbeddings(plan); err != nil {
			sc.logger.Error("Failed to sync plan", 
				zap.String("plan_id", plan.ID), 
				zap.Error(err))
			continue
		}
		successCount++
	}

	sc.logger.Info("📊 Synchronization completed", 
		zap.Int("total", len(plans)),
		zap.Int("success", successCount),
		zap.Int("failed", len(plans)-successCount))

	if successCount == 0 {
		return fmt.Errorf("no plans were successfully synchronized")
	}
	return nil
}
