// Package interfaces defines the core interfaces for the contextual memory system
package interfaces

import (
	"context"
	"time"
)

// Document represents a document in the contextual memory system
type ContextualMemoryDocument struct {
	ID       string            `json:"id"`
	Content  string            `json:"content"`
	Metadata map[string]string `json:"metadata"`
	Vector   []float32         `json:"vector,omitempty"`
}

// SearchResult represents a search result with similarity score
type SearchResult struct {
	Document   ContextualMemoryDocument `json:"document"`
	Score      float64  `json:"score"`
	Highlights []string `json:"highlights,omitempty"`
}

// IndexManager manages document indexing and storage
type IndexManager interface {
	// Index adds or updates a document in the index
	Index(ctx context.Context, doc ContextualMemoryDocument) error
	
	// Delete removes a document from the index
	Delete(ctx context.Context, documentID string) error
	
	// Update modifies an existing document
	Update(ctx context.Context, doc ContextualMemoryDocument) error
	
	// GetDocument retrieves a document by ID
	GetDocument(ctx context.Context, documentID string) (*ContextualMemoryDocument, error)
	
	// ListDocuments returns all documents with pagination
	ListDocuments(ctx context.Context, offset, limit int) ([]ContextualMemoryDocument, error)
	
	// GetStats returns indexing statistics
	GetStats(ctx context.Context) (IndexStats, error)
	
	// Health checks the health of the index
	Health(ctx context.Context) error
}

// RetrievalManager handles document retrieval and search
type RetrievalManager interface {
	// Search performs similarity search
	Search(ctx context.Context, query string, limit int) ([]SearchResult, error)
	
	// SemanticSearch performs semantic similarity search
	SemanticSearch(ctx context.Context, queryVector []float32, limit int) ([]SearchResult, error)
	
	// FilteredSearch performs search with metadata filters
	FilteredSearch(ctx context.Context, query string, filters map[string]string, limit int) ([]SearchResult, error)
	
	// GetSimilar finds documents similar to a given document
	GetSimilar(ctx context.Context, documentID string, limit int) ([]SearchResult, error)
	
	// GetContext retrieves contextual information for a query
	GetContext(ctx context.Context, query string, maxTokens int) (string, error)
}

// IntegrationManager handles integration with external systems
type IntegrationManager interface {
	// RegisterWebhook registers a webhook for document updates
	RegisterWebhook(ctx context.Context, url string, events []string) error
	
	// UnregisterWebhook removes a webhook
	UnregisterWebhook(ctx context.Context, url string) error
	
	// NotifyUpdate sends notifications about document updates
	NotifyUpdate(ctx context.Context, event UpdateEvent) error
	
	// ExportDocuments exports documents in various formats
	ExportDocuments(ctx context.Context, format string, filters map[string]string) ([]byte, error)
	
	// ImportDocuments imports documents from external sources
	ImportDocuments(ctx context.Context, source string, config map[string]interface{}) error
	
	// SyncWithExternal synchronizes with external data sources
	SyncWithExternal(ctx context.Context, source string) error
}

// ContextualMemoryManager is the main interface combining all managers
type ContextualMemoryManager interface {
	IndexManager
	RetrievalManager
	IntegrationManager
	
	// Initialize sets up the contextual memory system
	Initialize(ctx context.Context, config Config) error
	
	// Shutdown gracefully shuts down the system
	Shutdown(ctx context.Context) error
	
	// GetVersion returns the system version
	GetVersion() string
}

// IndexStats contains statistics about the index
type IndexStats struct {
	TotalDocuments int64     `json:"total_documents"`
	IndexSize      int64     `json:"index_size_bytes"`
	LastUpdated    time.Time `json:"last_updated"`
	VectorDimension int      `json:"vector_dimension"`
}

// UpdateEvent represents a document update event
type UpdateEvent struct {
	Type       string    `json:"type"` // created, updated, deleted
	DocumentID string    `json:"document_id"`
	Timestamp  time.Time `json:"timestamp"`
	Metadata   map[string]string `json:"metadata,omitempty"`
}

// Config holds configuration for the contextual memory system
type Config struct {
	// Database configuration
	DatabaseURL string `json:"database_url"`
	
	// Vector database configuration
	VectorDB VectorDBConfig `json:"vector_db"`
	
	// Embedding configuration
	Embedding EmbeddingConfig `json:"embedding"`
	
	// Cache configuration
	Cache CacheConfig `json:"cache"`
	
	// Integration configuration
	Integrations map[string]interface{} `json:"integrations"`
}

// VectorDBConfig configures the vector database
type VectorDBConfig struct {
	Type     string `json:"type"`     // qdrant, pinecone, weaviate
	URL      string `json:"url"`
	APIKey   string `json:"api_key"`
	Collection string `json:"collection"`
	Dimension  int    `json:"dimension"`
}

// EmbeddingConfig configures the embedding provider
type EmbeddingConfig struct {
	Provider string `json:"provider"` // openai, huggingface, local
	Model    string `json:"model"`
	APIKey   string `json:"api_key"`
	Dimension int   `json:"dimension"`
}

// CacheConfig configures the caching layer
type CacheConfig struct {
	Type     string        `json:"type"`     // redis, memory, sqlite
	URL      string        `json:"url"`
	TTL      time.Duration `json:"ttl"`
	MaxSize  int64         `json:"max_size"`
}

// EmbeddingProvider generates embeddings for text
type EmbeddingProvider interface {
	// Embed generates embeddings for the given text
	Embed(ctx context.Context, text string) ([]float32, error)
	
	// EmbedBatch generates embeddings for multiple texts
	EmbedBatch(ctx context.Context, texts []string) ([][]float32, error)
	
	// GetDimension returns the dimension of the embeddings
	GetDimension() int
	
	// GetModel returns the model name
	GetModel() string
}

// VectorStore handles vector storage and similarity search
type VectorStore interface {
	// Insert stores vectors with metadata
	Insert(ctx context.Context, vectors []VectorWithMetadata) error
	
	// Search performs similarity search
	Search(ctx context.Context, vector []float32, limit int, filters map[string]string) ([]SearchResult, error)
	
	// Delete removes vectors by ID
	Delete(ctx context.Context, ids []string) error
	
	// Update modifies existing vectors
	Update(ctx context.Context, vectors []VectorWithMetadata) error
	
	// GetStats returns vector store statistics
	GetStats(ctx context.Context) (VectorStats, error)
}

// VectorWithMetadata combines a vector with its metadata
type VectorWithMetadata struct {
	ID       string            `json:"id"`
	Vector   []float32         `json:"vector"`
	Metadata map[string]string `json:"metadata"`
}

// VectorStats contains statistics about the vector store
type VectorStats struct {
	TotalVectors int64 `json:"total_vectors"`
	Dimension    int   `json:"dimension"`
	IndexType    string `json:"index_type"`
}

// Cache provides caching functionality
type Cache interface {
	// Get retrieves a value from cache
	Get(ctx context.Context, key string) ([]byte, error)
	
	// Set stores a value in cache
	Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
	
	// Delete removes a value from cache
	Delete(ctx context.Context, key string) error
	
	// Clear removes all values from cache
	Clear(ctx context.Context) error
	
	// GetStats returns cache statistics
	GetStats(ctx context.Context) (CacheStats, error)
}

// CacheStats contains cache statistics
type CacheStats struct {
	Hits        int64 `json:"hits"`
	Misses      int64 `json:"misses"`
	Size        int64 `json:"size"`
	MaxSize     int64 `json:"max_size"`
	Evictions   int64 `json:"evictions"`
}
