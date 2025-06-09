package vector

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/qdrant/go-client/qdrant"
	"go.uber.org/zap"

	"github.com/email-sender/maintenance-manager/src/core"
)

// QdrantManager manages Qdrant vector database operations
type QdrantManager struct {
	logger      *zap.Logger
	client      *qdrant.Client
	config      core.VectorDBConfig
	collections map[string]*Collection
	initialized bool
}

// Collection represents a Qdrant collection
type Collection struct {
	Name       string            `json:"name"`
	VectorSize int               `json:"vector_size"`
	Distance   string            `json:"distance"`
	Metadata   map[string]string `json:"metadata"`
	CreatedAt  time.Time         `json:"created_at"`
}

// VectorPoint represents a vector point with metadata
type VectorPoint struct {
	ID       string                 `json:"id"`
	Vector   []float32              `json:"vector"`
	Payload  map[string]interface{} `json:"payload"`
	Metadata map[string]string      `json:"metadata"`
}

// SearchResult represents a vector search result
type SearchResult struct {
	ID       string                 `json:"id"`
	Score    float64                `json:"score"`
	Payload  map[string]interface{} `json:"payload"`
	Metadata map[string]string      `json:"metadata"`
}

// VectorStats contains statistics about the vector database
type VectorStats struct {
	TotalVectors    int64            `json:"total_vectors"`
	Collections     int              `json:"collections"`
	IndexType       string           `json:"index_type"`
	MemoryUsage     int64            `json:"memory_usage"`
	DiskUsage       int64            `json:"disk_usage"`
	LastUpdated     time.Time        `json:"last_updated"`
	CollectionStats map[string]int64 `json:"collection_stats"`
}

// NewQdrantManager creates a new Qdrant manager instance
func NewQdrantManager(logger *zap.Logger, config core.VectorDBConfig) (*QdrantManager, error) {
	if !config.Enabled {
		return nil, fmt.Errorf("vector database is disabled")
	}

	// Create Qdrant client
	qdrantURL := fmt.Sprintf("http://%s:%d", config.Host, config.Port)
	client, err := qdrant.NewClient(&qdrant.Config{
		Host:   config.Host,
		Port:   config.Port,
		UseTLS: false,
		APIKey: "",
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create Qdrant client: %w", err)
	}

	manager := &QdrantManager{
		logger:      logger,
		client:      client,
		config:      config,
		collections: make(map[string]*Collection),
		initialized: false,
	}

	return manager, nil
}

// Initialize sets up the Qdrant manager and ensures required collections exist
func (qm *QdrantManager) Initialize(ctx context.Context) error {
	qm.logger.Info("Initializing Qdrant manager",
		zap.String("host", qm.config.Host),
		zap.Int("port", qm.config.Port))

	// Test connection
	if err := qm.testConnection(ctx); err != nil {
		return fmt.Errorf("failed to connect to Qdrant: %w", err)
	}

	// Ensure main collection exists
	if err := qm.ensureCollection(ctx, qm.config.CollectionName, qm.config.VectorSize); err != nil {
		return fmt.Errorf("failed to ensure collection: %w", err)
	}

	// Load existing collections
	if err := qm.loadCollections(ctx); err != nil {
		qm.logger.Warn("Failed to load existing collections", zap.Error(err))
	}

	qm.initialized = true
	qm.logger.Info("Qdrant manager initialized successfully")
	return nil
}

// testConnection tests the connection to Qdrant
func (qm *QdrantManager) testConnection(ctx context.Context) error {
	// Create a simple HTTP client for health check
	httpClient := &http.Client{Timeout: 5 * time.Second}
	healthURL := fmt.Sprintf("http://%s:%d/", qm.config.Host, qm.config.Port)

	req, err := http.NewRequestWithContext(ctx, "GET", healthURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unhealthy response: %d", resp.StatusCode)
	}

	return nil
}

// ensureCollection ensures a collection exists with the specified parameters
func (qm *QdrantManager) ensureCollection(ctx context.Context, name string, vectorSize int) error {
	// Check if collection exists
	collections, err := qm.client.ListCollections(ctx)
	if err != nil {
		return fmt.Errorf("failed to list collections: %w", err)
	}

	// Check if our collection exists
	exists := false
	for _, collection := range collections.Collections {
		if collection.Name == name {
			exists = true
			break
		}
	}

	if !exists {
		// Create collection
		qm.logger.Info("Creating collection",
			zap.String("name", name),
			zap.Int("vector_size", vectorSize))

		_, err := qm.client.CreateCollection(ctx, &qdrant.CreateCollection{
			CollectionName: name,
			VectorsConfig: qdrant.VectorsConfig{
				Params: &qdrant.VectorParams{
					Size:     uint64(vectorSize),
					Distance: qdrant.Distance_Cosine,
				},
			},
		})
		if err != nil {
			return fmt.Errorf("failed to create collection: %w", err)
		}

		qm.logger.Info("Collection created successfully", zap.String("name", name))
	}

	// Store collection info
	qm.collections[name] = &Collection{
		Name:       name,
		VectorSize: vectorSize,
		Distance:   "cosine",
		Metadata:   make(map[string]string),
		CreatedAt:  time.Now(),
	}

	return nil
}

// loadCollections loads information about existing collections
func (qm *QdrantManager) loadCollections(ctx context.Context) error {
	collections, err := qm.client.ListCollections(ctx)
	if err != nil {
		return fmt.Errorf("failed to list collections: %w", err)
	}

	for _, collection := range collections.Collections {
		info, err := qm.client.GetCollection(ctx, collection.Name)
		if err != nil {
			qm.logger.Warn("Failed to get collection info",
				zap.String("collection", collection.Name),
				zap.Error(err))
			continue
		}

		vectorSize := int(info.Config.Params.VectorSize)
		distance := info.Config.Params.Distance.String()

		qm.collections[collection.Name] = &Collection{
			Name:       collection.Name,
			VectorSize: vectorSize,
			Distance:   distance,
			Metadata:   make(map[string]string),
			CreatedAt:  time.Now(), // We don't have the actual creation time
		}
	}

	qm.logger.Info("Loaded collections", zap.Int("count", len(qm.collections)))
	return nil
}

// StoreVector stores a vector with metadata in the specified collection
func (qm *QdrantManager) StoreVector(ctx context.Context, collectionName string, point VectorPoint) error {
	if !qm.initialized {
		return fmt.Errorf("Qdrant manager not initialized")
	}

	qm.logger.Debug("Storing vector",
		zap.String("collection", collectionName),
		zap.String("id", point.ID))

	// Create Qdrant point
	qdrantPoint := &qdrant.PointStruct{
		Id:      qdrant.NewIDNum(0), // Let Qdrant assign ID if needed
		Vectors: qdrant.NewVectors(point.Vector...),
		Payload: qdrant.NewValueMap(point.Payload),
	}

	// Upsert point
	_, err := qm.client.Upsert(ctx, &qdrant.UpsertPoints{
		CollectionName: collectionName,
		Points:         []*qdrant.PointStruct{qdrantPoint},
	})
	if err != nil {
		return fmt.Errorf("failed to store vector: %w", err)
	}

	qm.logger.Debug("Vector stored successfully", zap.String("id", point.ID))
	return nil
}

// StoreBatch stores multiple vectors in a single batch operation
func (qm *QdrantManager) StoreBatch(ctx context.Context, collectionName string, points []VectorPoint) error {
	if !qm.initialized {
		return fmt.Errorf("Qdrant manager not initialized")
	}

	if len(points) == 0 {
		return nil
	}

	qm.logger.Debug("Storing vector batch",
		zap.String("collection", collectionName),
		zap.Int("count", len(points)))

	// Convert to Qdrant points
	qdrantPoints := make([]*qdrant.PointStruct, len(points))
	for i, point := range points {
		qdrantPoints[i] = &qdrant.PointStruct{
			Id:      qdrant.NewIDNum(uint64(i)), // Use index as ID for batch
			Vectors: qdrant.NewVectors(point.Vector...),
			Payload: qdrant.NewValueMap(point.Payload),
		}
	}

	// Upsert points
	_, err := qm.client.Upsert(ctx, &qdrant.UpsertPoints{
		CollectionName: collectionName,
		Points:         qdrantPoints,
	})
	if err != nil {
		return fmt.Errorf("failed to store vector batch: %w", err)
	}

	qm.logger.Debug("Vector batch stored successfully", zap.Int("count", len(points)))
	return nil
}

// Search performs vector similarity search
func (qm *QdrantManager) Search(ctx context.Context, collectionName string, queryVector []float32, limit int, filter map[string]interface{}) ([]SearchResult, error) {
	if !qm.initialized {
		return nil, fmt.Errorf("Qdrant manager not initialized")
	}

	qm.logger.Debug("Performing vector search",
		zap.String("collection", collectionName),
		zap.Int("limit", limit))

	// Create search request
	searchReq := &qdrant.SearchPoints{
		CollectionName: collectionName,
		Vector:         queryVector,
		Limit:          uint64(limit),
		WithPayload:    &qdrant.WithPayloadSelector{SelectorOptions: &qdrant.WithPayloadSelector_Enable{Enable: true}},
		WithVectors:    &qdrant.WithVectorsSelector{SelectorOptions: &qdrant.WithVectorsSelector_Enable{Enable: false}},
	}

	// Add filter if provided
	if filter != nil {
		// Convert filter to Qdrant filter format
		// This is a simplified implementation
		searchReq.Filter = &qdrant.Filter{
			// Add filter conditions based on the filter map
		}
	}

	// Perform search
	response, err := qm.client.Search(ctx, searchReq)
	if err != nil {
		return nil, fmt.Errorf("search failed: %w", err)
	}

	// Convert results
	results := make([]SearchResult, len(response.Result))
	for i, result := range response.Result {
		payload := make(map[string]interface{})
		if result.Payload != nil {
			for key, value := range result.Payload {
				payload[key] = value.AsInterface()
			}
		}

		results[i] = SearchResult{
			ID:       result.Id.String(),
			Score:    float64(result.Score),
			Payload:  payload,
			Metadata: make(map[string]string), // Extract from payload if needed
		}
	}

	qm.logger.Debug("Search completed",
		zap.Int("results", len(results)))

	return results, nil
}

// Delete removes vectors by IDs
func (qm *QdrantManager) Delete(ctx context.Context, collectionName string, ids []string) error {
	if !qm.initialized {
		return fmt.Errorf("Qdrant manager not initialized")
	}

	qm.logger.Debug("Deleting vectors",
		zap.String("collection", collectionName),
		zap.Int("count", len(ids)))

	// Convert string IDs to Qdrant IDs
	qdrantIDs := make([]*qdrant.PointId, len(ids))
	for i, id := range ids {
		qdrantIDs[i] = qdrant.NewIDString(id)
	}

	// Delete points
	_, err := qm.client.Delete(ctx, &qdrant.DeletePoints{
		CollectionName: collectionName,
		Points: &qdrant.PointsSelector{
			PointsSelectorOneOf: &qdrant.PointsSelector_Points{
				Points: &qdrant.PointsIdsList{
					Ids: qdrantIDs,
				},
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to delete vectors: %w", err)
	}

	qm.logger.Debug("Vectors deleted successfully", zap.Int("count", len(ids)))
	return nil
}

// GetStats returns statistics about the vector database
func (qm *QdrantManager) GetStats(ctx context.Context) (*VectorStats, error) {
	if !qm.initialized {
		return nil, fmt.Errorf("Qdrant manager not initialized")
	}

	stats := &VectorStats{
		Collections:     len(qm.collections),
		LastUpdated:     time.Now(),
		CollectionStats: make(map[string]int64),
	}

	// Get stats for each collection
	var totalVectors int64
	for name := range qm.collections {
		info, err := qm.client.GetCollection(ctx, name)
		if err != nil {
			qm.logger.Warn("Failed to get collection stats",
				zap.String("collection", name),
				zap.Error(err))
			continue
		}

		vectorCount := int64(info.VectorsCount)
		stats.CollectionStats[name] = vectorCount
		totalVectors += vectorCount
	}

	stats.TotalVectors = totalVectors
	stats.IndexType = "HNSW"

	return stats, nil
}

// GetCollections returns information about all collections
func (qm *QdrantManager) GetCollections() map[string]*Collection {
	collections := make(map[string]*Collection)
	for name, collection := range qm.collections {
		collections[name] = &Collection{
			Name:       collection.Name,
			VectorSize: collection.VectorSize,
			Distance:   collection.Distance,
			Metadata:   collection.Metadata,
			CreatedAt:  collection.CreatedAt,
		}
	}
	return collections
}

// CreateCollection creates a new collection
func (qm *QdrantManager) CreateCollection(ctx context.Context, name string, vectorSize int, distance string) error {
	if !qm.initialized {
		return fmt.Errorf("Qdrant manager not initialized")
	}

	// Convert distance string to Qdrant distance type
	var distanceType qdrant.Distance
	switch distance {
	case "cosine":
		distanceType = qdrant.Distance_Cosine
	case "euclidean":
		distanceType = qdrant.Distance_Euclid
	case "dot":
		distanceType = qdrant.Distance_Dot
	default:
		distanceType = qdrant.Distance_Cosine
	}

	qm.logger.Info("Creating collection",
		zap.String("name", name),
		zap.Int("vector_size", vectorSize),
		zap.String("distance", distance))

	_, err := qm.client.CreateCollection(ctx, &qdrant.CreateCollection{
		CollectionName: name,
		VectorsConfig: qdrant.VectorsConfig{
			Params: &qdrant.VectorParams{
				Size:     uint64(vectorSize),
				Distance: distanceType,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create collection: %w", err)
	}

	// Store collection info
	qm.collections[name] = &Collection{
		Name:       name,
		VectorSize: vectorSize,
		Distance:   distance,
		Metadata:   make(map[string]string),
		CreatedAt:  time.Now(),
	}

	qm.logger.Info("Collection created successfully", zap.String("name", name))
	return nil
}

// Stop gracefully shuts down the Qdrant manager
func (qm *QdrantManager) Stop() error {
	qm.logger.Info("Stopping Qdrant manager")

	if qm.client != nil {
		if err := qm.client.Close(); err != nil {
			qm.logger.Error("Failed to close Qdrant client", zap.Error(err))
			return err
		}
	}

	qm.initialized = false
	qm.logger.Info("Qdrant manager stopped successfully")
	return nil
}

// GetHealth returns the health status of the Qdrant manager
func (qm *QdrantManager) GetHealth() core.HealthStatus {
	status := core.HealthStatus{
		Details: make(map[string]string),
	}

	if !qm.initialized {
		status.Status = "unhealthy"
		status.Details["error"] = "not initialized"
		return status
	}

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := qm.testConnection(ctx)
	if err != nil {
		status.Status = "unhealthy"
		status.Details["error"] = err.Error()
		return status
	}

	status.Status = "healthy"
	status.Details["collections"] = fmt.Sprintf("%d", len(qm.collections))
	status.Details["host"] = qm.config.Host
	status.Details["port"] = fmt.Sprintf("%d", qm.config.Port)

	return status
}

// GetMetrics returns metrics about the Qdrant manager
func (qm *QdrantManager) GetMetrics() map[string]interface{} {
	metrics := map[string]interface{}{
		"initialized":       qm.initialized,
		"collections_count": len(qm.collections),
		"host":              qm.config.Host,
		"port":              qm.config.Port,
		"collection_name":   qm.config.CollectionName,
		"vector_size":       qm.config.VectorSize,
	}

	if qm.initialized {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if stats, err := qm.GetStats(ctx); err == nil {
			metrics["total_vectors"] = stats.TotalVectors
			metrics["memory_usage"] = stats.MemoryUsage
			metrics["disk_usage"] = stats.DiskUsage
			metrics["last_updated"] = stats.LastUpdated.Unix()
		}
	}

	return metrics
}
