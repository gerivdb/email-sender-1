package types

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

// Supported distance metrics
const (
	DistanceCosine    = "cosine"
	DistanceEuclidean = "euclidean"
	DistanceDot       = "dot"
)

// CollectionConfig represents configuration for creating a collection
type CollectionConfig struct {
	// Name is the collection name
	Name string `json:"name"`

	// VectorSize is the dimension of vectors in this collection
	VectorSize int `json:"vector_size"`

	// Distance is the distance metric used for similarity search (cosine, euclidean, dot)
	Distance string `json:"distance"`

	// IndexingConfig contains optional indexing parameters
	IndexingConfig *IndexingConfig `json:"indexing_config,omitempty"`

	// OptimizationConfig contains optional optimization parameters
	OptimizationConfig *OptimizationConfig `json:"optimization_config,omitempty"`
}

// Collection represents a QDrant collection
type Collection struct {
	// Name is the collection name
	Name string `json:"name"`

	// VectorSize is the dimension of vectors in this collection
	VectorSize int `json:"vector_size"`

	// Distance is the distance metric used for similarity search
	Distance string `json:"distance"`

	// DocumentCount is the number of documents in the collection
	DocumentCount int `json:"document_count"`

	// IndexingConfig contains indexing parameters
	IndexingConfig *IndexingConfig `json:"indexing_config,omitempty"`

	// OptimizationConfig contains optimization parameters
	OptimizationConfig *OptimizationConfig `json:"optimization_config,omitempty"`

	// CreatedAt is the collection creation timestamp
	CreatedAt time.Time `json:"created_at"`

	// UpdatedAt is the last update timestamp
	UpdatedAt time.Time `json:"updated_at"`
}

// IndexingConfig contains parameters for indexing
type IndexingConfig struct {
	// IndexingThreshold is the threshold for creating index
	IndexingThreshold int `json:"indexing_threshold"`

	// MaxSegmentNumber is the maximum number of segments
	MaxSegmentNumber int `json:"max_segment_number"`

	// MemmapThreshold is the threshold for memory mapping
	MemmapThreshold int `json:"memmap_threshold"`
}

// OptimizationConfig contains optimization parameters
type OptimizationConfig struct {
	// VacuumMinVectorNumber is the minimum number of vectors to start vacuuming
	VacuumMinVectorNumber int `json:"vacuum_min_vector_number"`

	// DefaultSegmentNumber is the default number of segments to create
	DefaultSegmentNumber int `json:"default_segment_number"`

	// MaxOptimizersThreads is the maximum number of threads for optimization
	MaxOptimizersThreads int `json:"max_optimizers_threads"`
}

// NewCollection creates a new collection with the given name and parameters
func NewCollection(name string, vectorSize int, distance string) *Collection {
	return &Collection{
		Name:          name,
		VectorSize:    vectorSize,
		Distance:      distance,
		DocumentCount: 0,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}
}

// NewCollectionFromConfig creates a new collection from configuration
func NewCollectionFromConfig(config CollectionConfig) (*Collection, error) {
	// Validate the configuration
	if err := ValidateCollectionConfig(config); err != nil {
		return nil, err
	}

	collection := &Collection{
		Name:               config.Name,
		VectorSize:         config.VectorSize,
		Distance:           config.Distance,
		DocumentCount:      0,
		IndexingConfig:     config.IndexingConfig,
		OptimizationConfig: config.OptimizationConfig,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	return collection, nil
}

// ValidateCollectionConfig validates the collection configuration
func ValidateCollectionConfig(config CollectionConfig) error {
	// Validate name
	if strings.TrimSpace(config.Name) == "" {
		return errors.New("collection name cannot be empty")
	}

	// Validate vector size
	if config.VectorSize <= 0 {
		return fmt.Errorf("vector size must be positive, got %d", config.VectorSize)
	}

	// Validate distance metric
	validDistances := map[string]bool{
		DistanceCosine:    true,
		DistanceEuclidean: true,
		DistanceDot:       true,
	}

	if !validDistances[strings.ToLower(config.Distance)] {
		return fmt.Errorf("unsupported distance metric: %s", config.Distance)
	}

	return nil
}

// Validate checks if the collection is valid
func (c *Collection) Validate() error {
	// Check if name is not empty
	if strings.TrimSpace(c.Name) == "" {
		return errors.New("collection name cannot be empty")
	}

	// Validate vector size
	if c.VectorSize <= 0 {
		return fmt.Errorf("vector size must be positive, got %d", c.VectorSize)
	}

	// Validate distance metric
	validDistances := map[string]bool{
		DistanceCosine:    true,
		DistanceEuclidean: true,
		DistanceDot:       true,
	}

	if !validDistances[strings.ToLower(c.Distance)] {
		return fmt.Errorf("unsupported distance metric: %s", c.Distance)
	}

	// Validate document count
	if c.DocumentCount < 0 {
		return fmt.Errorf("document count cannot be negative, got %d", c.DocumentCount)
	}

	return nil
}

// ToJSON serializes the collection to JSON
func (c *Collection) ToJSON() ([]byte, error) {
	// Validate before serialization
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("collection validation failed: %w", err)
	}

	data, err := json.Marshal(c)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal collection to JSON: %w", err)
	}

	return data, nil
}

// FromJSON deserializes the collection from JSON
func (c *Collection) FromJSON(data []byte) error {
	if err := json.Unmarshal(data, c); err != nil {
		return fmt.Errorf("failed to unmarshal collection from JSON: %w", err)
	}

	// Validate after deserialization
	if err := c.Validate(); err != nil {
		return fmt.Errorf("collection validation failed after deserialization: %w", err)
	}

	return nil
}

// UpdateDocumentCount updates the document count
func (c *Collection) UpdateDocumentCount(count int) {
	c.DocumentCount = count
	c.UpdatedAt = time.Now()
}

// IncrementDocumentCount increments the document count by the given amount
func (c *Collection) IncrementDocumentCount(increment int) {
	c.DocumentCount += increment
	c.UpdatedAt = time.Now()
}

// SetIndexingConfig sets the indexing configuration
func (c *Collection) SetIndexingConfig(config *IndexingConfig) {
	c.IndexingConfig = config
	c.UpdatedAt = time.Now()
}

// SetOptimizationConfig sets the optimization configuration
func (c *Collection) SetOptimizationConfig(config *OptimizationConfig) {
	c.OptimizationConfig = config
	c.UpdatedAt = time.Now()
}

// Update updates the collection with new data
func (c *Collection) Update(other *Collection) {
	if other == nil {
		return
	}

	if other.VectorSize > 0 {
		c.VectorSize = other.VectorSize
	}

	if other.Distance != "" {
		c.Distance = other.Distance
	}

	if other.DocumentCount >= 0 {
		c.DocumentCount = other.DocumentCount
	}

	if other.IndexingConfig != nil {
		c.IndexingConfig = other.IndexingConfig
	}

	if other.OptimizationConfig != nil {
		c.OptimizationConfig = other.OptimizationConfig
	}

	c.UpdatedAt = time.Now()
}

// IsEmpty checks if the collection is empty
func (c *Collection) IsEmpty() bool {
	return c.DocumentCount == 0
}

// GetAge returns the age of the collection
func (c *Collection) GetAge() time.Duration {
	return time.Since(c.CreatedAt)
}

// GetLastUpdateAge returns the time since last update
func (c *Collection) GetLastUpdateAge() time.Duration {
	return time.Since(c.UpdatedAt)
}

// ToConfig creates a collection config from this collection
func (c *Collection) ToConfig() CollectionConfig {
	return CollectionConfig{
		Name:               c.Name,
		VectorSize:         c.VectorSize,
		Distance:           c.Distance,
		IndexingConfig:     c.IndexingConfig,
		OptimizationConfig: c.OptimizationConfig,
	}
}
