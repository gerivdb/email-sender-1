// Package vectorization provides Go native vector operations for EMAIL_SENDER_1
// This replaces the Python vectorization scripts with a high-performance Go implementation
package vectorization

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	"github.com/qdrant/go-client/qdrant"
	"go.uber.org/zap"
)

// VectorConfig holds configuration for vector operations
type VectorConfig struct {
	Host           string `json:"host" yaml:"host"`
	Port           int    `json:"port" yaml:"port"`
	CollectionName string `json:"collection_name" yaml:"collection_name"`
	VectorSize     int    `json:"vector_size" yaml:"vector_size"`
	Distance       string `json:"distance" yaml:"distance"`
	APIKey         string `json:"api_key,omitempty" yaml:"api_key,omitempty"`
	Timeout        int    `json:"timeout" yaml:"timeout"`
}

// DefaultConfig returns a default configuration for vector operations
func DefaultConfig() VectorConfig {
	return VectorConfig{
		Host:           "localhost",
		Port:           6333,
		CollectionName: "email_vectors",
		VectorSize:     384,
		Distance:       "cosine",
		Timeout:        30,
	}
}

// VectorData represents a vector with its metadata
type VectorData struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
	Created time.Time              `json:"created"`
	Source  string                 `json:"source"`
}

// VectorClient provides Go native operations for Qdrant
type VectorClient struct {
	client *qdrant.Client
	config VectorConfig
	logger *zap.Logger
}

// NewVectorClient creates a new vector client with the given configuration
func NewVectorClient(config VectorConfig, logger *zap.Logger) (*VectorClient, error) {
	if logger == nil {
		logger, _ = zap.NewDevelopment()
	}

	// Create Qdrant client configuration
	clientConfig := &qdrant.Config{
		Host: config.Host,
		Port: config.Port,
	}

	if config.APIKey != "" {
		clientConfig.APIKey = config.APIKey
	}

	client, err := qdrant.NewClient(clientConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create Qdrant client: %w", err)
	}

	return &VectorClient{
		client: client,
		config: config,
		logger: logger,
	}, nil
}

// CreateCollection creates a new collection in Qdrant
func (vc *VectorClient) CreateCollection(ctx context.Context) error {
	vc.logger.Info("Creating collection", zap.String("name", vc.config.CollectionName))

	distance := qdrant.Distance_Cosine
	if vc.config.Distance == "euclidean" {
		distance = qdrant.Distance_Euclid
	} else if vc.config.Distance == "dot" {
		distance = qdrant.Distance_Dot
	}

	err := vc.client.CreateCollection(ctx, &qdrant.CreateCollection{
		CollectionName: vc.config.CollectionName,
		VectorsConfig: qdrant.VectorsConfig{
			Size:     uint64(vc.config.VectorSize),
			Distance: distance,
		},
		OptimizersConfig: &qdrant.OptimizersConfigDiff{
			DefaultSegmentNumber: &[]uint64{2}[0],
		},
		ReplicationFactor: &[]uint32{1}[0],
	})

	if err != nil {
		return fmt.Errorf("failed to create collection: %w", err)
	}

	vc.logger.Info("Collection created successfully", zap.String("name", vc.config.CollectionName))
	return nil
}

// UpsertVectors inserts or updates vectors in the collection
func (vc *VectorClient) UpsertVectors(ctx context.Context, vectors []VectorData) error {
	if len(vectors) == 0 {
		return nil
	}

	vc.logger.Info("Upserting vectors", zap.Int("count", len(vectors)))

	points := make([]*qdrant.PointStruct, len(vectors))
	for i, vector := range vectors {
		points[i] = &qdrant.PointStruct{
			Id: &qdrant.PointId{
				PointIdOptions: &qdrant.PointId_Uuid{
					Uuid: vector.ID,
				},
			},
			Vectors: &qdrant.Vectors{
				VectorsOptions: &qdrant.Vectors_Vector{
					Vector: &qdrant.Vector{
						Data: vector.Vector,
					},
				},
			},
			Payload: convertPayload(vector.Payload),
		}
	}

	_, err := vc.client.Upsert(ctx, &qdrant.UpsertPoints{
		CollectionName: vc.config.CollectionName,
		Points:         points,
		Wait:           &[]bool{true}[0],
	})

	if err != nil {
		return fmt.Errorf("failed to upsert vectors: %w", err)
	}

	vc.logger.Info("Vectors upserted successfully", zap.Int("count", len(vectors)))
	return nil
}

// SearchSimilar searches for similar vectors
func (vc *VectorClient) SearchSimilar(ctx context.Context, query []float32, limit uint64) ([]VectorData, error) {
	vc.logger.Debug("Searching similar vectors", zap.Uint64("limit", limit))

	response, err := vc.client.Search(ctx, &qdrant.SearchPoints{
		CollectionName: vc.config.CollectionName,
		Vector:         query,
		Limit:          limit,
		WithPayload:    &qdrant.WithPayloadSelector{SelectorOptions: &qdrant.WithPayloadSelector_Enable{Enable: true}},
		WithVectors:    &qdrant.WithVectorsSelector{SelectorOptions: &qdrant.WithVectorsSelector_Enable{Enable: true}},
	})

	if err != nil {
		return nil, fmt.Errorf("failed to search vectors: %w", err)
	}

	results := make([]VectorData, len(response.Result))
	for i, result := range response.Result {
		vectorData := VectorData{
			ID:      result.Id.GetUuid(),
			Payload: convertPayloadBack(result.Payload),
		}

		if vectors := result.Vectors.GetVector(); vectors != nil {
			vectorData.Vector = vectors.Data
		}

		results[i] = vectorData
	}

	vc.logger.Debug("Search completed", zap.Int("results", len(results)))
	return results, nil
}

// GetCollectionInfo returns information about the collection
func (vc *VectorClient) GetCollectionInfo(ctx context.Context) (*qdrant.CollectionInfo, error) {
	response, err := vc.client.GetCollection(ctx, &qdrant.GetCollectionInfoRequest{
		CollectionName: vc.config.CollectionName,
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get collection info: %w", err)
	}

	return response.Result, nil
}

// DeleteCollection deletes the collection
func (vc *VectorClient) DeleteCollection(ctx context.Context) error {
	vc.logger.Info("Deleting collection", zap.String("name", vc.config.CollectionName))

	_, err := vc.client.DeleteCollection(ctx, &qdrant.DeleteCollection{
		CollectionName: vc.config.CollectionName,
	})

	if err != nil {
		return fmt.Errorf("failed to delete collection: %w", err)
	}

	vc.logger.Info("Collection deleted successfully")
	return nil
}

// Close closes the client connection
func (vc *VectorClient) Close() error {
	// The Qdrant Go client doesn't have an explicit close method
	// This is here for interface compatibility
	return nil
}

// Helper functions

func convertPayload(payload map[string]interface{}) map[string]*qdrant.Value {
	result := make(map[string]*qdrant.Value)
	for key, value := range payload {
		result[key] = convertValue(value)
	}
	return result
}

func convertValue(value interface{}) *qdrant.Value {
	switch v := value.(type) {
	case string:
		return &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: v}}
	case int:
		return &qdrant.Value{Kind: &qdrant.Value_IntegerValue{IntegerValue: int64(v)}}
	case int64:
		return &qdrant.Value{Kind: &qdrant.Value_IntegerValue{IntegerValue: v}}
	case float64:
		return &qdrant.Value{Kind: &qdrant.Value_DoubleValue{DoubleValue: v}}
	case bool:
		return &qdrant.Value{Kind: &qdrant.Value_BoolValue{BoolValue: v}}
	default:
		// Convert to string as fallback
		return &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: fmt.Sprintf("%v", v)}}
	}
}

func convertPayloadBack(payload map[string]*qdrant.Value) map[string]interface{} {
	result := make(map[string]interface{})
	for key, value := range payload {
		result[key] = convertValueBack(value)
	}
	return result
}

func convertValueBack(value *qdrant.Value) interface{} {
	switch v := value.Kind.(type) {
	case *qdrant.Value_StringValue:
		return v.StringValue
	case *qdrant.Value_IntegerValue:
		return v.IntegerValue
	case *qdrant.Value_DoubleValue:
		return v.DoubleValue
	case *qdrant.Value_BoolValue:
		return v.BoolValue
	default:
		return nil
	}
}

// LoadVectorsFromJSON loads vectors from a JSON file
func LoadVectorsFromJSON(filename string) ([]VectorData, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filename, err)
	}

	var vectors []VectorData
	err = json.Unmarshal(data, &vectors)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal vectors from %s: %w", filename, err)
	}

	return vectors, nil
}

// SaveVectorsToJSON saves vectors to a JSON file
func SaveVectorsToJSON(vectors []VectorData, filename string) error {
	// Ensure directory exists
	dir := filepath.Dir(filename)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(vectors, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal vectors: %w", err)
	}

	err = os.WriteFile(filename, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write file %s: %w", filename, err)
	}

	return nil
}

// GenerateTestVectors generates test vectors for development and testing
func GenerateTestVectors(count int, vectorSize int) []VectorData {
	vectors := make([]VectorData, count)

	for i := 0; i < count; i++ {
		vector := make([]float32, vectorSize)
		for j := 0; j < vectorSize; j++ {
			vector[j] = float32(i*vectorSize+j) / 1000.0 // Simple deterministic pattern
		}

		vectors[i] = VectorData{
			ID:     uuid.New().String(),
			Vector: vector,
			Payload: map[string]interface{}{
				"index":       i,
				"description": fmt.Sprintf("Test vector %d", i),
				"category":    fmt.Sprintf("test_%d", i%5),
				"timestamp":   time.Now().Unix(),
			},
			Created: time.Now(),
			Source:  "test_generation",
		}
	}

	log.Printf("Generated %d test vectors of size %d", count, vectorSize)
	return vectors
}
