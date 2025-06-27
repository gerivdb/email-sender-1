package vector

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

// FileMetadata represents metadata for a file in the vector registry
type FileMetadata struct {
	Path         string            `json:"path"`
	Hash         string            `json:"hash"`
	Size         int64             `json:"size"`
	ModTime      time.Time         `json:"mod_time"`
	Type         string            `json:"type"`
	Language     string            `json:"language"`
	Complexity   float64           `json:"complexity"`
	Dependencies []string          `json:"dependencies"`
	Tags         []string          `json:"tags"`
	Attributes   map[string]string `json:"attributes"`
}

// VectorPoint represents a vector point with file metadata
type VectorPoint struct {
	ID       string                 `json:"id"`
	Vector   []float32              `json:"vector"`
	Metadata FileMetadata           `json:"metadata"`
	Payload  map[string]interface{} `json:"payload"`
}

// SearchFilter represents search filters for vector queries
type SearchFilter struct {
	FileTypes  []string          `json:"file_types,omitempty"`
	Languages  []string          `json:"languages,omitempty"`
	MinSize    int64             `json:"min_size,omitempty"`
	MaxSize    int64             `json:"max_size,omitempty"`
	Tags       []string          `json:"tags,omitempty"`
	Attributes map[string]string `json:"attributes,omitempty"`
	DateRange  *DateRange        `json:"date_range,omitempty"`
}

// DateRange represents a date range filter
type DateRange struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

// SearchResult represents a search result from the vector registry
type SearchResult struct {
	Point    VectorPoint `json:"point"`
	Score    float32     `json:"score"`
	Distance float32     `json:"distance"`
}

// VectorRegistry manages file embeddings and metadata in QDrant
type VectorRegistry struct {
	client         *PointsClient
	conn           *grpc.ClientConn
	collectionName string
	vectorSize     uint64
	mutex          sync.RWMutex
	cache          map[string]*VectorPoint
	config         *RegistryConfig
}

// RegistryConfig holds configuration for the vector registry
type RegistryConfig struct {
	QdrantHost     string `yaml:"qdrant_host"`
	QdrantPort     int    `yaml:"qdrant_port"`
	CollectionName string `yaml:"collection_name"`
	VectorSize     uint64 `yaml:"vector_size"`
	CacheSize      int    `yaml:"cache_size"`
	BatchSize      int    `yaml:"batch_size"`
	Timeout        int    `yaml:"timeout_seconds"`
}

// NewVectorRegistry creates a new vector registry instance
func NewVectorRegistry(config *RegistryConfig) (*VectorRegistry, error) {
	conn, err := grpc.Dial(
		fmt.Sprintf("%s:%d", config.QdrantHost, config.QdrantPort),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to QDrant: %w", err)
	}

	client := NewPointsClient(conn)

	registry := &VectorRegistry{
		client:         client,
		conn:           conn,
		collectionName: config.CollectionName,
		vectorSize:     config.VectorSize,
		cache:          make(map[string]*VectorPoint),
		config:         config,
	}

	// Initialize collection if it doesn't exist
	if err := registry.initializeCollection(); err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to initialize collection: %w", err)
	}

	return registry, nil
}

// initializeCollection creates the QDrant collection if it doesn't exist
func (vr *VectorRegistry) initializeCollection() error {
	collectionsClient := NewCollectionsClient(vr.conn)

	// Check if collection exists (stub always returns empty)
	// So always create
	_, err := collectionsClient.Create(context.Background(), &CreateCollection{
		CollectionName: vr.collectionName,
		VectorsConfig: &VectorsConfig{
			Params: &VectorParams{
				Size:     vr.vectorSize,
				Distance: Distance_Cosine,
			},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to create collection: %w", err)
	}

	log.Printf("Created collection %s with vector size %d", vr.collectionName, vr.vectorSize)
	return nil
}

// RegisterFile adds or updates a file in the vector registry
func (vr *VectorRegistry) RegisterFile(ctx context.Context, point *VectorPoint) error {
	vr.mutex.Lock()
	defer vr.mutex.Unlock()

	payload, err := vr.preparePayload(point.Metadata)
	if err != nil {
		return fmt.Errorf("failed to prepare payload: %w", err)
	}

	qdrantPoint := &PointStruct{
		Id: &PointId{
			PointIdOptions: point.ID,
		},
		Vectors: &Vectors{
			VectorsOptions: point.Vector,
		},
		Payload: payload,
	}

	_, err = vr.client.Upsert(ctx, &UpsertPoints{
		CollectionName: vr.collectionName,
		Points:         []*PointStruct{qdrantPoint},
	})
	if err != nil {
		return fmt.Errorf("failed to upsert point: %w", err)
	}

	vr.cache[point.ID] = point

	log.Printf("Registered file: %s (ID: %s)", point.Metadata.Path, point.ID)
	return nil
}

// preparePayload converts file metadata to QDrant payload
func (vr *VectorRegistry) preparePayload(metadata FileMetadata) (map[string]*Value, error) {
	payload := make(map[string]*Value)

	payload["path"] = &Value{Kind: &Value_StringValue{StringValue: metadata.Path}}
	payload["hash"] = &Value{Kind: &Value_StringValue{StringValue: metadata.Hash}}
	payload["size"] = &Value{Kind: &Value_IntegerValue{IntegerValue: metadata.Size}}
	payload["type"] = &Value{Kind: &Value_StringValue{StringValue: metadata.Type}}
	payload["language"] = &Value{Kind: &Value_StringValue{StringValue: metadata.Language}}
	payload["complexity"] = &Value{Kind: &Value_DoubleValue{DoubleValue: metadata.Complexity}}
	payload["mod_time"] = &Value{Kind: &Value_StringValue{StringValue: metadata.ModTime.Format(time.RFC3339)}}

	if len(metadata.Dependencies) > 0 {
		deps, _ := json.Marshal(metadata.Dependencies)
		payload["dependencies"] = &Value{Kind: &Value_StringValue{StringValue: string(deps)}}
	}

	if len(metadata.Tags) > 0 {
		tags, _ := json.Marshal(metadata.Tags)
		payload["tags"] = &Value{Kind: &Value_StringValue{StringValue: string(tags)}}
	}

	for key, value := range metadata.Attributes {
		payload["attr_"+key] = &Value{Kind: &Value_StringValue{StringValue: value}}
	}

	return payload, nil
}

// SearchSimilar finds similar files based on vector similarity
func (vr *VectorRegistry) SearchSimilar(ctx context.Context, vector []float32, limit uint64, filter *SearchFilter) ([]*SearchResult, error) {
	vr.mutex.RLock()
	defer vr.mutex.RUnlock()

	// Build filter (stub: not used)
	// Perform search (stub: always returns empty)
	return []*SearchResult{}, nil
}

// The rest of the methods (GetFile, RemoveFile, BatchRegister, etc.) can be stubbed similarly if needed.
