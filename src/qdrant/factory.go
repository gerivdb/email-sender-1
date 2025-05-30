package qdrant

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"
)

// ClientMode defines the mode of operation for Qdrant
type ClientMode string

const (
	// ModeExternal uses external Qdrant server
	ModeExternal ClientMode = "external"
	// ModeEmbedded uses embedded/internal Qdrant
	ModeEmbedded ClientMode = "embedded"
	// ModeAuto automatically chooses based on environment
	ModeAuto ClientMode = "auto"
)

// QdrantInterface defines the common interface for both client types
type QdrantInterface interface {
	HealthCheck() error
	CreateCollection(name string, vectorSize int) error
	UpsertPoints(collection string, points []Point) error
	Search(collection string, request SearchRequest) ([]SearchResult, error)
	DeleteCollection(collection string) error
	GetCollectionInfo(collection string) (*CollectionInfo, error)
	GetStats() map[string]interface{}
	Close() error
}

// ClientFactory creates the appropriate Qdrant client based on configuration
type ClientFactory struct {
	mode      ClientMode
	baseURL   string
	timeout   time.Duration
	enableSSL bool
}

// NewClientFactory creates a new client factory
func NewClientFactory() *ClientFactory {
	return &ClientFactory{
		mode:      ModeAuto,
		baseURL:   "http://localhost:6333",
		timeout:   30 * time.Second,
		enableSSL: false,
	}
}

// WithMode sets the client mode
func (cf *ClientFactory) WithMode(mode ClientMode) *ClientFactory {
	cf.mode = mode
	return cf
}

// WithBaseURL sets the base URL for external mode
func (cf *ClientFactory) WithBaseURL(url string) *ClientFactory {
	cf.baseURL = url
	return cf
}

// WithTimeout sets the timeout for requests
func (cf *ClientFactory) WithTimeout(timeout time.Duration) *ClientFactory {
	cf.timeout = timeout
	return cf
}

// WithSSL enables SSL for external connections
func (cf *ClientFactory) WithSSL(enable bool) *ClientFactory {
	cf.enableSSL = enable
	return cf
}

// CreateClient creates the appropriate client based on configuration
func (cf *ClientFactory) CreateClient() (QdrantInterface, error) {
	mode := cf.determineMode()

	switch mode {
	case ModeEmbedded:
		return cf.createEmbeddedClient()
	case ModeExternal:
		return cf.createExternalClient()
	default:
		return nil, fmt.Errorf("unsupported client mode: %s", mode)
	}
}

// determineMode automatically determines the best mode
func (cf *ClientFactory) determineMode() ClientMode {
	if cf.mode != ModeAuto {
		return cf.mode
	}

	// Check environment variable first
	if envMode := os.Getenv("QDRANT_MODE"); envMode != "" {
		switch envMode {
		case "embedded", "internal":
			return ModeEmbedded
		case "external", "server":
			return ModeExternal
		}
	}

	// Check if external Qdrant is available
	if cf.isExternalQdrantAvailable() {
		return ModeExternal
	}

	// Default to embedded mode
	return ModeEmbedded
}

// isExternalQdrantAvailable checks if external Qdrant server is reachable
func (cf *ClientFactory) isExternalQdrantAvailable() bool {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(cf.baseURL + "/")
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK
}

// createEmbeddedClient creates an embedded Qdrant client
func (cf *ClientFactory) createEmbeddedClient() (QdrantInterface, error) {
	config := DefaultEmbeddedConfig()

	// Override with environment variables if available
	if dataPath := os.Getenv("QDRANT_DATA_PATH"); dataPath != "" {
		config.DataPath = dataPath
	}

	if maxColStr := os.Getenv("QDRANT_MAX_COLLECTIONS"); maxColStr != "" {
		if maxCol, err := strconv.Atoi(maxColStr); err == nil {
			config.MaxCollections = maxCol
		}
	}

	if enablePersistStr := os.Getenv("QDRANT_ENABLE_PERSIST"); enablePersistStr != "" {
		config.EnablePersist = enablePersistStr == "true"
	}

	return NewEmbeddedClient(config), nil
}

// createExternalClient creates an external Qdrant client
func (cf *ClientFactory) createExternalClient() (QdrantInterface, error) {
	client := NewQdrantClient(cf.baseURL)
	client.HTTPClient.Timeout = cf.timeout

	// Test connection
	if err := client.HealthCheck(); err != nil {
		return nil, fmt.Errorf("failed to connect to external Qdrant at %s: %w", cf.baseURL, err)
	}

	return &ExternalClientWrapper{client: client}, nil
}

// ExternalClientWrapper wraps the existing QdrantClient to implement QdrantInterface
type ExternalClientWrapper struct {
	client *QdrantClient
}

// HealthCheck implements QdrantInterface
func (w *ExternalClientWrapper) HealthCheck() error {
	return w.client.HealthCheck()
}

// CreateCollection implements QdrantInterface
func (w *ExternalClientWrapper) CreateCollection(name string, vectorSize int) error {
	config := CollectionConfig{
		VectorSize: vectorSize,
		Distance:   "Cosine",
	}
	return w.client.CreateCollection(name, config)
}

// UpsertPoints implements QdrantInterface
func (w *ExternalClientWrapper) UpsertPoints(collection string, points []Point) error {
	return w.client.UpsertPoints(collection, points)
}

// Search implements QdrantInterface
func (w *ExternalClientWrapper) Search(collection string, request SearchRequest) ([]SearchResult, error) {
	return w.client.Search(collection, request)
}

// DeleteCollection implements QdrantInterface
func (w *ExternalClientWrapper) DeleteCollection(collection string) error {
	return w.client.DeleteCollection(collection)
}

// GetCollectionInfo implements QdrantInterface
func (w *ExternalClientWrapper) GetCollectionInfo(collection string) (*CollectionInfo, error) {
	return w.client.GetCollectionInfo(collection)
}

// GetStats implements QdrantInterface
func (w *ExternalClientWrapper) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"mode":     "external",
		"base_url": w.client.BaseURL,
		"timeout":  w.client.HTTPClient.Timeout,
	}
}

// Close implements QdrantInterface
func (w *ExternalClientWrapper) Close() error {
	// External client doesn't need explicit cleanup
	return nil
}

// NewAutoClient creates a client using automatic mode detection
// This is the recommended way to create a Qdrant client
func NewAutoClient() (QdrantInterface, error) {
	factory := NewClientFactory()
	return factory.CreateClient()
}

// NewEmbeddedClientSimple creates an embedded client with default config
func NewEmbeddedClientSimple() (QdrantInterface, error) {
	factory := NewClientFactory().WithMode(ModeEmbedded)
	return factory.CreateClient()
}

// NewExternalClientSimple creates an external client with default config
func NewExternalClientSimple(baseURL string) (QdrantInterface, error) {
	factory := NewClientFactory().WithMode(ModeExternal).WithBaseURL(baseURL)
	return factory.CreateClient()
}
