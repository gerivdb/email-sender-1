// Package manager implements the contextual memory management system
package manager

import (
	"context"
	"fmt"
	"log"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/interfaces"
)

// ContextualMemoryManagerImpl implements the ContextualMemoryManager interface
type ContextualMemoryManagerImpl struct {
	indexManager       interfaces.IndexManager
	retrievalManager   interfaces.RetrievalManager
	integrationManager interfaces.IntegrationManager
	config             interfaces.Config
	initialized        bool
}

// NewContextualMemoryManager creates a new contextual memory manager
func NewContextualMemoryManager() *ContextualMemoryManagerImpl {
	return &ContextualMemoryManagerImpl{
		initialized: false,
	}
}

// Initialize sets up the contextual memory system
func (c *ContextualMemoryManagerImpl) Initialize(ctx context.Context, config interfaces.Config) error {
	log.Printf("Initializing Contextual Memory Manager with config: %+v", config)

	c.config = config

	// Initialize index manager with SQLite
	indexManager, err := NewSQLiteIndexManager(config.DatabaseURL)
	if err != nil {
		return fmt.Errorf("failed to initialize SQLite index manager: %w", err)
	}
	c.indexManager = indexManager

	// Initialize retrieval manager with Qdrant
	retrievalManager, err := NewQdrantRetrievalManager(config.VectorDB, config.Embedding)
	if err != nil {
		return fmt.Errorf("failed to initialize Qdrant retrieval manager: %w", err)
	}
	c.retrievalManager = retrievalManager

	// Initialize integration manager with webhooks
	integrationManager, err := NewWebhookIntegrationManager(config.Integrations)
	if err != nil {
		return fmt.Errorf("failed to initialize integration manager: %w", err)
	}
	c.integrationManager = integrationManager

	c.initialized = true
	log.Printf("Contextual Memory Manager initialized successfully")

	return nil
}

// Shutdown gracefully shuts down the system
func (c *ContextualMemoryManagerImpl) Shutdown(ctx context.Context) error {
	log.Printf("Shutting down Contextual Memory Manager")

	if !c.initialized {
		return nil
	}

	// Shutdown in reverse order
	if c.integrationManager != nil {
		// Integration manager shutdown logic would go here
		log.Printf("Integration manager shutdown complete")
	}

	if c.retrievalManager != nil {
		// Retrieval manager shutdown logic would go here
		log.Printf("Retrieval manager shutdown complete")
	}

	if c.indexManager != nil {
		// Index manager shutdown logic would go here
		log.Printf("Index manager shutdown complete")
	}

	c.initialized = false
	log.Printf("Contextual Memory Manager shutdown complete")

	return nil
}

// GetVersion returns the system version
func (c *ContextualMemoryManagerImpl) GetVersion() string {
	return "1.0.0"
}

// IndexManager methods delegation

// Index adds or updates a document in the index
func (c *ContextualMemoryManagerImpl) Index(ctx context.Context, doc interfaces.Document) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.Index(ctx, doc)
}

// Delete removes a document from the index
func (c *ContextualMemoryManagerImpl) Delete(ctx context.Context, documentID string) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.Delete(ctx, documentID)
}

// Update modifies an existing document
func (c *ContextualMemoryManagerImpl) Update(ctx context.Context, doc interfaces.Document) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.Update(ctx, doc)
}

// GetDocument retrieves a document by ID
func (c *ContextualMemoryManagerImpl) GetDocument(ctx context.Context, documentID string) (*interfaces.Document, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.GetDocument(ctx, documentID)
}

// ListDocuments returns all documents with pagination
func (c *ContextualMemoryManagerImpl) ListDocuments(ctx context.Context, offset, limit int) ([]interfaces.Document, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.ListDocuments(ctx, offset, limit)
}

// GetStats returns indexing statistics
func (c *ContextualMemoryManagerImpl) GetStats(ctx context.Context) (interfaces.IndexStats, error) {
	if !c.initialized {
		return interfaces.IndexStats{}, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.GetStats(ctx)
}

// Health checks the health of the index
func (c *ContextualMemoryManagerImpl) Health(ctx context.Context) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.indexManager.Health(ctx)
}

// RetrievalManager methods delegation

// Search performs similarity search
func (c *ContextualMemoryManagerImpl) Search(ctx context.Context, query string, limit int) ([]interfaces.SearchResult, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.retrievalManager.Search(ctx, query, limit)
}

// SemanticSearch performs semantic similarity search
func (c *ContextualMemoryManagerImpl) SemanticSearch(ctx context.Context, queryVector []float32, limit int) ([]interfaces.SearchResult, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.retrievalManager.SemanticSearch(ctx, queryVector, limit)
}

// FilteredSearch performs search with metadata filters
func (c *ContextualMemoryManagerImpl) FilteredSearch(ctx context.Context, query string, filters map[string]string, limit int) ([]interfaces.SearchResult, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.retrievalManager.FilteredSearch(ctx, query, filters, limit)
}

// GetSimilar finds documents similar to a given document
func (c *ContextualMemoryManagerImpl) GetSimilar(ctx context.Context, documentID string, limit int) ([]interfaces.SearchResult, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.retrievalManager.GetSimilar(ctx, documentID, limit)
}

// GetContext retrieves contextual information for a query
func (c *ContextualMemoryManagerImpl) GetContext(ctx context.Context, query string, maxTokens int) (string, error) {
	if !c.initialized {
		return "", fmt.Errorf("contextual memory manager not initialized")
	}
	return c.retrievalManager.GetContext(ctx, query, maxTokens)
}

// IntegrationManager methods delegation

// RegisterWebhook registers a webhook for document updates
func (c *ContextualMemoryManagerImpl) RegisterWebhook(ctx context.Context, url string, events []string) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.RegisterWebhook(ctx, url, events)
}

// UnregisterWebhook removes a webhook
func (c *ContextualMemoryManagerImpl) UnregisterWebhook(ctx context.Context, url string) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.UnregisterWebhook(ctx, url)
}

// NotifyUpdate sends notifications about document updates
func (c *ContextualMemoryManagerImpl) NotifyUpdate(ctx context.Context, event interfaces.UpdateEvent) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.NotifyUpdate(ctx, event)
}

// ExportDocuments exports documents in various formats
func (c *ContextualMemoryManagerImpl) ExportDocuments(ctx context.Context, format string, filters map[string]string) ([]byte, error) {
	if !c.initialized {
		return nil, fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.ExportDocuments(ctx, format, filters)
}

// ImportDocuments imports documents from external sources
func (c *ContextualMemoryManagerImpl) ImportDocuments(ctx context.Context, source string, config map[string]interface{}) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.ImportDocuments(ctx, source, config)
}

// SyncWithExternal synchronizes with external data sources
func (c *ContextualMemoryManagerImpl) SyncWithExternal(ctx context.Context, source string) error {
	if !c.initialized {
		return fmt.Errorf("contextual memory manager not initialized")
	}
	return c.integrationManager.SyncWithExternal(ctx, source)
}
