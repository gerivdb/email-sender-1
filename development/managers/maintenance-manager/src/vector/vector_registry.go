package vector

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	// "github.com/qdrant/go-client/qdrant" // Temporarily disabled
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
	client         qdrant.PointsClient
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
	// Connect to QDrant
	conn, err := grpc.Dial(
		fmt.Sprintf("%s:%d", config.QdrantHost, config.QdrantPort),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to QDrant: %w", err)
	}

	client := qdrant.NewPointsClient(conn)

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
	collectionsClient := qdrant.NewCollectionsClient(vr.conn)

	// Check if collection exists
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(vr.config.Timeout)*time.Second)
	defer cancel()

	info, err := collectionsClient.Get(ctx, &qdrant.GetCollectionInfoRequest{
		CollectionName: vr.collectionName,
	})

	if err == nil && info != nil {
		log.Printf("Collection %s already exists", vr.collectionName)
		return nil
	}

	// Create collection
	_, err = collectionsClient.Create(ctx, &qdrant.CreateCollection{
		CollectionName: vr.collectionName,
		VectorsConfig: &qdrant.VectorsConfig{
			Config: &qdrant.VectorsConfig_Params{
				Params: &qdrant.VectorParams{
					Size:     vr.vectorSize,
					Distance: qdrant.Distance_Cosine,
				},
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

	// Prepare QDrant point
	payload, err := vr.preparePayload(point.Metadata)
	if err != nil {
		return fmt.Errorf("failed to prepare payload: %w", err)
	}

	qdrantPoint := &qdrant.PointStruct{
		Id: &qdrant.PointId{
			PointIdOptions: &qdrant.PointId_Uuid{
				Uuid: point.ID,
			},
		},
		Vectors: &qdrant.Vectors{
			VectorsOptions: &qdrant.Vectors_Vector{
				Vector: &qdrant.Vector{
					Data: point.Vector,
				},
			},
		},
		Payload: payload,
	}

	// Upsert point
	_, err = vr.client.Upsert(ctx, &qdrant.UpsertPoints{
		CollectionName: vr.collectionName,
		Points:         []*qdrant.PointStruct{qdrantPoint},
	})

	if err != nil {
		return fmt.Errorf("failed to upsert point: %w", err)
	}

	// Update cache
	vr.cache[point.ID] = point

	log.Printf("Registered file: %s (ID: %s)", point.Metadata.Path, point.ID)
	return nil
}

// preparePayload converts file metadata to QDrant payload
func (vr *VectorRegistry) preparePayload(metadata FileMetadata) (map[string]*qdrant.Value, error) {
	payload := make(map[string]*qdrant.Value)

	// Add basic metadata
	payload["path"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: metadata.Path}}
	payload["hash"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: metadata.Hash}}
	payload["size"] = &qdrant.Value{Kind: &qdrant.Value_IntegerValue{IntegerValue: metadata.Size}}
	payload["type"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: metadata.Type}}
	payload["language"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: metadata.Language}}
	payload["complexity"] = &qdrant.Value{Kind: &qdrant.Value_DoubleValue{DoubleValue: metadata.Complexity}}
	payload["mod_time"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: metadata.ModTime.Format(time.RFC3339)}}

	// Add arrays as JSON strings
	if len(metadata.Dependencies) > 0 {
		deps, _ := json.Marshal(metadata.Dependencies)
		payload["dependencies"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: string(deps)}}
	}

	if len(metadata.Tags) > 0 {
		tags, _ := json.Marshal(metadata.Tags)
		payload["tags"] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: string(tags)}}
	}

	// Add custom attributes
	for key, value := range metadata.Attributes {
		payload["attr_"+key] = &qdrant.Value{Kind: &qdrant.Value_StringValue{StringValue: value}}
	}

	return payload, nil
}

// SearchSimilar finds similar files based on vector similarity
func (vr *VectorRegistry) SearchSimilar(ctx context.Context, vector []float32, limit uint64, filter *SearchFilter) ([]*SearchResult, error) {
	vr.mutex.RLock()
	defer vr.mutex.RUnlock()

	// Build QDrant filter
	qdrantFilter := vr.buildQdrantFilter(filter)

	// Perform search
	response, err := vr.client.Search(ctx, &qdrant.SearchPoints{
		CollectionName: vr.collectionName,
		Vector:         vector,
		Limit:          limit,
		WithPayload: &qdrant.WithPayloadSelector{
			SelectorOptions: &qdrant.WithPayloadSelector_Enable{
				Enable: true,
			},
		},
		Filter: qdrantFilter,
	})

	if err != nil {
		return nil, fmt.Errorf("failed to search: %w", err)
	}

	// Convert results
	results := make([]*SearchResult, len(response.Result))
	for i, result := range response.Result {
		point, err := vr.convertFromQdrantPoint(result)
		if err != nil {
			log.Printf("Failed to convert point %v: %v", result.Id, err)
			continue
		}

		results[i] = &SearchResult{
			Point:    *point,
			Score:    result.Score,
			Distance: 1.0 - result.Score, // Convert score to distance
		}
	}

	return results, nil
}

// buildQdrantFilter converts SearchFilter to QDrant filter
func (vr *VectorRegistry) buildQdrantFilter(filter *SearchFilter) *qdrant.Filter {
	if filter == nil {
		return nil
	}

	var conditions []*qdrant.Condition

	// File types filter
	if len(filter.FileTypes) > 0 {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.Condition_Field{
				Field: &qdrant.FieldCondition{
					Key: "type",
					Match: &qdrant.Match{
						MatchValue: &qdrant.Match_Keywords{
							Keywords: &qdrant.RepeatedStrings{
								Strings: filter.FileTypes,
							},
						},
					},
				},
			},
		})
	}

	// Languages filter
	if len(filter.Languages) > 0 {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.Condition_Field{
				Field: &qdrant.FieldCondition{
					Key: "language",
					Match: &qdrant.Match{
						MatchValue: &qdrant.Match_Keywords{
							Keywords: &qdrant.RepeatedStrings{
								Strings: filter.Languages,
							},
						},
					},
				},
			},
		})
	}

	// Size range filter
	if filter.MinSize > 0 {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.Condition_Field{
				Field: &qdrant.FieldCondition{
					Key: "size",
					Range: &qdrant.Range{
						Gte: &filter.MinSize,
					},
				},
			},
		})
	}

	if filter.MaxSize > 0 {
		conditions = append(conditions, &qdrant.Condition{
			ConditionOneOf: &qdrant.Condition_Field{
				Field: &qdrant.FieldCondition{
					Key: "size",
					Range: &qdrant.Range{
						Lte: &filter.MaxSize,
					},
				},
			},
		})
	}

	if len(conditions) == 0 {
		return nil
	}

	return &qdrant.Filter{
		Must: conditions,
	}
}

// convertFromQdrantPoint converts QDrant point to VectorPoint
func (vr *VectorRegistry) convertFromQdrantPoint(result *qdrant.ScoredPoint) (*VectorPoint, error) {
	// Extract metadata from payload
	metadata := FileMetadata{}

	if path, ok := result.Payload["path"]; ok {
		if strVal := path.GetStringValue(); strVal != "" {
			metadata.Path = strVal
		}
	}

	if hash, ok := result.Payload["hash"]; ok {
		if strVal := hash.GetStringValue(); strVal != "" {
			metadata.Hash = strVal
		}
	}

	if size, ok := result.Payload["size"]; ok {
		metadata.Size = result.Payload["size"].GetIntegerValue()
	}

	if fileType, ok := result.Payload["type"]; ok {
		if strVal := fileType.GetStringValue(); strVal != "" {
			metadata.Type = strVal
		}
	}

	if language, ok := result.Payload["language"]; ok {
		if strVal := language.GetStringValue(); strVal != "" {
			metadata.Language = strVal
		}
	}

	if complexity, ok := result.Payload["complexity"]; ok {
		metadata.Complexity = result.Payload["complexity"].GetDoubleValue()
	}

	// Parse dependencies and tags from JSON strings
	if deps, ok := result.Payload["dependencies"]; ok {
		if strVal := deps.GetStringValue(); strVal != "" {
			json.Unmarshal([]byte(strVal), &metadata.Dependencies)
		}
	}

	if tags, ok := result.Payload["tags"]; ok {
		if strVal := tags.GetStringValue(); strVal != "" {
			json.Unmarshal([]byte(strVal), &metadata.Tags)
		}
	}

	// Extract custom attributes
	metadata.Attributes = make(map[string]string)
	for key, value := range result.Payload {
		if len(key) > 5 && key[:5] == "attr_" {
			attrKey := key[5:]
			if strVal := value.GetStringValue(); strVal != "" {
				metadata.Attributes[attrKey] = strVal
			}
		}
	}

	point := &VectorPoint{
		ID:       result.Id.GetUuid(),
		Vector:   result.Vectors.GetVector().GetData(),
		Metadata: metadata,
		Payload:  make(map[string]interface{}),
	}

	return point, nil
}

// GetFile retrieves a file by ID
func (vr *VectorRegistry) GetFile(ctx context.Context, id string) (*VectorPoint, error) {
	vr.mutex.RLock()

	// Check cache first
	if point, exists := vr.cache[id]; exists {
		vr.mutex.RUnlock()
		return point, nil
	}
	vr.mutex.RUnlock()

	// Retrieve from QDrant
	response, err := vr.client.Get(ctx, &qdrant.GetPoints{
		CollectionName: vr.collectionName,
		Ids: []*qdrant.PointId{
			{
				PointIdOptions: &qdrant.PointId_Uuid{
					Uuid: id,
				},
			},
		},
		WithPayload: &qdrant.WithPayloadSelector{
			SelectorOptions: &qdrant.WithPayloadSelector_Enable{
				Enable: true,
			},
		},
		WithVectors: &qdrant.WithVectorsSelector{
			SelectorOptions: &qdrant.WithVectorsSelector_Enable{
				Enable: true,
			},
		},
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get point: %w", err)
	}

	if len(response.Result) == 0 {
		return nil, fmt.Errorf("file not found: %s", id)
	}

	// Convert and cache
	point, err := vr.convertFromQdrantRetrievedPoint(response.Result[0])
	if err != nil {
		return nil, err
	}

	vr.mutex.Lock()
	vr.cache[id] = point
	vr.mutex.Unlock()

	return point, nil
}

// convertFromQdrantRetrievedPoint converts retrieved QDrant point to VectorPoint
func (vr *VectorRegistry) convertFromQdrantRetrievedPoint(result *qdrant.RetrievedPoint) (*VectorPoint, error) {
	// Similar to convertFromQdrantPoint but for retrieved points
	metadata := FileMetadata{}

	if path, ok := result.Payload["path"]; ok {
		if strVal := path.GetStringValue(); strVal != "" {
			metadata.Path = strVal
		}
	}

	// ... (similar extraction logic as above)

	point := &VectorPoint{
		ID:       result.Id.GetUuid(),
		Vector:   result.Vectors.GetVector().GetData(),
		Metadata: metadata,
		Payload:  make(map[string]interface{}),
	}

	return point, nil
}

// RemoveFile removes a file from the vector registry
func (vr *VectorRegistry) RemoveFile(ctx context.Context, id string) error {
	vr.mutex.Lock()
	defer vr.mutex.Unlock()

	// Remove from QDrant
	_, err := vr.client.Delete(ctx, &qdrant.DeletePoints{
		CollectionName: vr.collectionName,
		Points: &qdrant.PointsSelector{
			PointsSelectorOneOf: &qdrant.PointsSelector_Points{
				Points: &qdrant.PointsIdsList{
					Ids: []*qdrant.PointId{
						{
							PointIdOptions: &qdrant.PointId_Uuid{
								Uuid: id,
							},
						},
					},
				},
			},
		},
	})

	if err != nil {
		return fmt.Errorf("failed to delete point: %w", err)
	}

	// Remove from cache
	delete(vr.cache, id)

	log.Printf("Removed file with ID: %s", id)
	return nil
}

// GetStats returns statistics about the vector registry
func (vr *VectorRegistry) GetStats(ctx context.Context) (map[string]interface{}, error) {
	collectionsClient := qdrant.NewCollectionsClient(vr.conn)

	info, err := collectionsClient.Get(ctx, &qdrant.GetCollectionInfoRequest{
		CollectionName: vr.collectionName,
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get collection info: %w", err)
	}

	stats := map[string]interface{}{
		"collection_name": vr.collectionName,
		"vector_size":     vr.vectorSize,
		"cache_size":      len(vr.cache),
	}

	if info.Result != nil {
		stats["total_points"] = info.Result.PointsCount
		stats["indexed_points"] = info.Result.IndexedVectorsCount
		stats["status"] = info.Result.Status.String()
	}

	return stats, nil
}

// Close closes the vector registry connection
func (vr *VectorRegistry) Close() error {
	vr.mutex.Lock()
	defer vr.mutex.Unlock()

	if vr.conn != nil {
		err := vr.conn.Close()
		vr.conn = nil
		return err
	}

	return nil
}

// BatchRegister registers multiple files at once
func (vr *VectorRegistry) BatchRegister(ctx context.Context, points []*VectorPoint) error {
	vr.mutex.Lock()
	defer vr.mutex.Unlock()

	batchSize := vr.config.BatchSize
	if batchSize <= 0 {
		batchSize = 100
	}

	for i := 0; i < len(points); i += batchSize {
		end := i + batchSize
		if end > len(points) {
			end = len(points)
		}

		batch := points[i:end]
		qdrantPoints := make([]*qdrant.PointStruct, len(batch))

		for j, point := range batch {
			payload, err := vr.preparePayload(point.Metadata)
			if err != nil {
				return fmt.Errorf("failed to prepare payload for point %s: %w", point.ID, err)
			}

			qdrantPoints[j] = &qdrant.PointStruct{
				Id: &qdrant.PointId{
					PointIdOptions: &qdrant.PointId_Uuid{
						Uuid: point.ID,
					},
				},
				Vectors: &qdrant.Vectors{
					VectorsOptions: &qdrant.Vectors_Vector{
						Vector: &qdrant.Vector{
							Data: point.Vector,
						},
					},
				},
				Payload: payload,
			}

			// Update cache
			vr.cache[point.ID] = point
		}

		// Batch upsert
		_, err := vr.client.Upsert(ctx, &qdrant.UpsertPoints{
			CollectionName: vr.collectionName,
			Points:         qdrantPoints,
		})

		if err != nil {
			return fmt.Errorf("failed to batch upsert points %d-%d: %w", i, end-1, err)
		}

		log.Printf("Batch registered %d points (%d-%d)", len(batch), i, end-1)
	}

	return nil
}
