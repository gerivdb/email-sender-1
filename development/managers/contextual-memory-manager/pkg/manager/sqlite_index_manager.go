// Package manager implements SQLite-based index management
package manager

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"time"

	_ "github.com/mattn/go-sqlite3"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/interfaces"
)

// SQLiteIndexManager implements IndexManager using SQLite database
type SQLiteIndexManager struct {
	db           *sql.DB
	cache        interfaces.Cache
	initialized  bool
	databasePath string
}

// EmbeddingCache implements simple in-memory cache with SQLite persistence
type SQLiteEmbeddingCache struct {
	db          *sql.DB
	memoryCache map[string][]byte
}

// NewSQLiteIndexManager creates a new SQLite-based index manager
func NewSQLiteIndexManager(databasePath string) (*SQLiteIndexManager, error) {
	log.Printf("Creating SQLite IndexManager with database: %s", databasePath)

	db, err := sql.Open("sqlite3", databasePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open SQLite database: %w", err)
	}
	// Test connection
	err = db.Ping()
	if err != nil {
		return nil, fmt.Errorf("failed to ping SQLite database: %w", err)
	}

	// Create cache
	cache, err := NewSQLiteEmbeddingCache(db)
	if err != nil {
		return nil, fmt.Errorf("failed to create embedding cache: %w", err)
	}

	manager := &SQLiteIndexManager{
		db:           db,
		cache:        cache,
		databasePath: databasePath,
		initialized:  false,
	}

	return manager, nil
}

// NewSQLiteEmbeddingCache creates a new SQLite-based embedding cache
func NewSQLiteEmbeddingCache(db *sql.DB) (*SQLiteEmbeddingCache, error) {
	cache := &SQLiteEmbeddingCache{
		db:          db,
		memoryCache: make(map[string][]byte),
	}

	// Initialize cache tables
	if err := cache.initializeTables(); err != nil {
		return nil, fmt.Errorf("failed to initialize cache tables: %w", err)
	}

	return cache, nil
}

// Initialize sets up the SQLite index manager
func (s *SQLiteIndexManager) Initialize(ctx context.Context) error {
	log.Println("Initializing SQLite IndexManager...")

	if err := s.createTables(); err != nil {
		return fmt.Errorf("failed to create tables: %w", err)
	}

	s.initialized = true
	log.Println("SQLite IndexManager initialized successfully")
	return nil
}

// createTables creates the necessary database tables
func (s *SQLiteIndexManager) createTables() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS documents (
			id TEXT PRIMARY KEY,
			content TEXT NOT NULL,
			metadata TEXT,
			embedding_vector BLOB,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			version INTEGER DEFAULT 1
		)`,
		`CREATE TABLE IF NOT EXISTS document_metadata (
			document_id TEXT,
			key TEXT,
			value TEXT,
			FOREIGN KEY(document_id) REFERENCES documents(id),
			PRIMARY KEY(document_id, key)
		)`,
		`CREATE TABLE IF NOT EXISTS index_statistics (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			total_documents INTEGER DEFAULT 0,
			total_size_bytes INTEGER DEFAULT 0,
			last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
		)`,
		`CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at)`,
		`CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents(updated_at)`,
		`CREATE INDEX IF NOT EXISTS idx_metadata_key_value ON document_metadata(key, value)`,
	}

	for _, query := range queries {
		if _, err := s.db.Exec(query); err != nil {
			return fmt.Errorf("failed to execute query %s: %w", query, err)
		}
	}

	return nil
}

// AddDocument adds a document to the index
func (s *SQLiteIndexManager) AddDocument(ctx context.Context, doc interfaces.Document) error {
	if !s.initialized {
		return fmt.Errorf("index manager not initialized")
	}

	log.Printf("Adding document to SQLite index: %s", doc.ID)

	// Start transaction
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Serialize metadata
	metadataJSON, err := json.Marshal(doc.Metadata)
	if err != nil {
		return fmt.Errorf("failed to serialize metadata: %w", err)
	}

	// Insert or update document
	query := `INSERT OR REPLACE INTO documents 
		(id, content, metadata, updated_at) 
		VALUES (?, ?, ?, CURRENT_TIMESTAMP)`

	if _, err := tx.ExecContext(ctx, query, doc.ID, doc.Content, string(metadataJSON)); err != nil {
		return fmt.Errorf("failed to insert document: %w", err)
	}

	// Insert metadata entries
	if err := s.insertMetadataEntries(ctx, tx, doc.ID, doc.Metadata); err != nil {
		return fmt.Errorf("failed to insert metadata entries: %w", err)
	}

	// Update statistics
	if err := s.updateStatistics(ctx, tx); err != nil {
		return fmt.Errorf("failed to update statistics: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	log.Printf("Document added successfully: %s", doc.ID)
	return nil
}

// GetDocument retrieves a document by ID
func (s *SQLiteIndexManager) GetDocument(ctx context.Context, id string) (*interfaces.Document, error) {
	if !s.initialized {
		return nil, fmt.Errorf("index manager not initialized")
	}

	log.Printf("Retrieving document from SQLite: %s", id)

	query := `SELECT id, content, metadata, created_at, updated_at 
		FROM documents WHERE id = ?`

	var doc interfaces.Document
	var metadataJSON string
	var createdAt, updatedAt time.Time

	err := s.db.QueryRowContext(ctx, query, id).Scan(
		&doc.ID, &doc.Content, &metadataJSON, &createdAt, &updatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("document not found: %s", id)
		}
		return nil, fmt.Errorf("failed to query document: %w", err)
	}

	// Deserialize metadata
	if err := json.Unmarshal([]byte(metadataJSON), &doc.Metadata); err != nil {
		return nil, fmt.Errorf("failed to deserialize metadata: %w", err)
	}

	log.Printf("Document retrieved successfully: %s", id)
	return &doc, nil
}

// UpdateDocument updates an existing document
func (s *SQLiteIndexManager) UpdateDocument(ctx context.Context, doc interfaces.Document) error {
	if !s.initialized {
		return fmt.Errorf("index manager not initialized")
	}

	// Check if document exists
	existing, err := s.GetDocument(ctx, doc.ID)
	if err != nil {
		return fmt.Errorf("document not found for update: %w", err)
	}

	log.Printf("Updating document in SQLite: %s", doc.ID)
	// Update with version increment
	currentVersion := existing.Metadata["version"]
	if currentVersion == "" {
		currentVersion = "1"
	}

	// Parse current version as integer, increment, and convert back to string
	var versionNum int
	if _, err := fmt.Sscanf(currentVersion, "%d", &versionNum); err != nil {
		versionNum = 1
	} else {
		versionNum++
	}
	doc.Metadata["version"] = fmt.Sprintf("%d", versionNum)

	return s.AddDocument(ctx, doc)
}

// DeleteDocument removes a document from the index
func (s *SQLiteIndexManager) DeleteDocument(ctx context.Context, id string) error {
	if !s.initialized {
		return fmt.Errorf("index manager not initialized")
	}

	log.Printf("Deleting document from SQLite: %s", id)

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()
	// Delete metadata entries
	_, metaErr := tx.ExecContext(ctx, "DELETE FROM document_metadata WHERE document_id = ?", id)
	if metaErr != nil {
		return fmt.Errorf("failed to delete metadata: %w", metaErr)
	}

	// Delete document
	result, err := tx.ExecContext(ctx, "DELETE FROM documents WHERE id = ?", id)
	if err != nil {
		return fmt.Errorf("failed to delete document: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("document not found: %s", id)
	}

	// Update statistics
	if err := s.updateStatistics(ctx, tx); err != nil {
		return fmt.Errorf("failed to update statistics: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	log.Printf("Document deleted successfully: %s", id)
	return nil
}

// GetStatistics returns index statistics
func (s *SQLiteIndexManager) GetStatistics(ctx context.Context) (map[string]interface{}, error) {
	if !s.initialized {
		return nil, fmt.Errorf("index manager not initialized")
	}

	stats := make(map[string]interface{})

	// Get document count
	var docCount int
	err := s.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM documents").Scan(&docCount)
	if err != nil {
		return nil, fmt.Errorf("failed to get document count: %w", err)
	}

	// Get database size (approximate)
	var dbSize int64
	err = s.db.QueryRowContext(ctx, "SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()").Scan(&dbSize)
	if err != nil {
		log.Printf("Warning: failed to get database size: %v", err)
		dbSize = 0
	}

	stats["total_documents"] = docCount
	stats["database_size_bytes"] = dbSize
	stats["database_path"] = s.databasePath
	stats["initialized"] = s.initialized
	stats["last_updated"] = time.Now()

	return stats, nil
}

// Close closes the database connection
func (s *SQLiteIndexManager) Close() error {
	log.Println("Closing SQLite IndexManager...")

	if s.db != nil {
		if err := s.db.Close(); err != nil {
			return fmt.Errorf("failed to close database: %w", err)
		}
	}

	s.initialized = false
	log.Println("SQLite IndexManager closed successfully")
	return nil
}

// Interface implementation methods to satisfy IndexManager interface

// Index adds or updates a document in the index (interface method)
func (s *SQLiteIndexManager) Index(ctx context.Context, doc interfaces.Document) error {
	return s.AddDocument(ctx, doc)
}

// Delete removes a document from the index (interface method)
func (s *SQLiteIndexManager) Delete(ctx context.Context, documentID string) error {
	return s.DeleteDocument(ctx, documentID)
}

// Update modifies an existing document (interface method)
func (s *SQLiteIndexManager) Update(ctx context.Context, doc interfaces.Document) error {
	return s.UpdateDocument(ctx, doc)
}

// GetDocument retrieves a document by ID (interface method - already implemented)

// ListDocuments returns all documents with pagination (interface method)
func (s *SQLiteIndexManager) ListDocuments(ctx context.Context, offset, limit int) ([]interfaces.Document, error) {
	if !s.initialized {
		return nil, fmt.Errorf("index manager not initialized")
	}

	log.Printf("Listing documents with pagination: offset=%d, limit=%d", offset, limit)

	query := `SELECT id, content, metadata, created_at, updated_at 
		FROM documents 
		ORDER BY created_at DESC 
		LIMIT ? OFFSET ?`

	rows, err := s.db.QueryContext(ctx, query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query documents: %w", err)
	}
	defer rows.Close()

	var documents []interfaces.Document
	for rows.Next() {
		var doc interfaces.Document
		var metadataJSON string
		var createdAt, updatedAt time.Time

		err := rows.Scan(&doc.ID, &doc.Content, &metadataJSON, &createdAt, &updatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan document: %w", err)
		}
		// Deserialize metadata directly to map[string]string
		if err := json.Unmarshal([]byte(metadataJSON), &doc.Metadata); err != nil {
			return nil, fmt.Errorf("failed to deserialize metadata: %w", err)
		}

		documents = append(documents, doc)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	log.Printf("Listed %d documents", len(documents))
	return documents, nil
}

// GetStats returns indexing statistics (interface method)
func (s *SQLiteIndexManager) GetStats(ctx context.Context) (interfaces.IndexStats, error) {
	if !s.initialized {
		return interfaces.IndexStats{}, fmt.Errorf("index manager not initialized")
	}

	stats, err := s.GetStatistics(ctx)
	if err != nil {
		return interfaces.IndexStats{}, err
	}

	return interfaces.IndexStats{
		TotalDocuments:  int64(stats["total_documents"].(int)),
		IndexSize:       stats["database_size_bytes"].(int64),
		LastUpdated:     stats["last_updated"].(time.Time),
		VectorDimension: 1536, // Default OpenAI embedding dimension
	}, nil
}

// Health checks the health of the index (interface method)
func (s *SQLiteIndexManager) Health(ctx context.Context) error {
	if !s.initialized {
		return fmt.Errorf("index manager not initialized")
	}

	// Test database connection
	if err := s.db.PingContext(ctx); err != nil {
		return fmt.Errorf("database connection unhealthy: %w", err)
	}

	// Test a simple query
	var count int
	err := s.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM documents").Scan(&count)
	if err != nil {
		return fmt.Errorf("database query failed: %w", err)
	}

	log.Printf("SQLite IndexManager health check passed: %d documents", count)
	return nil
}

// Helper methods

func (s *SQLiteIndexManager) insertMetadataEntries(ctx context.Context, tx *sql.Tx, docID string, metadata map[string]string) error {
	// Delete existing metadata
	if _, err := tx.ExecContext(ctx, "DELETE FROM document_metadata WHERE document_id = ?", docID); err != nil {
		return fmt.Errorf("failed to delete existing metadata: %w", err)
	}

	// Insert new metadata
	for key, value := range metadata {
		if _, err := tx.ExecContext(ctx,
			"INSERT INTO document_metadata (document_id, key, value) VALUES (?, ?, ?)",
			docID, key, value); err != nil {
			return fmt.Errorf("failed to insert metadata entry: %w", err)
		}
	}

	return nil
}

func (s *SQLiteIndexManager) updateStatistics(ctx context.Context, tx *sql.Tx) error {
	query := `INSERT OR REPLACE INTO index_statistics (id, total_documents, last_updated)
		SELECT 1, COUNT(*), CURRENT_TIMESTAMP FROM documents`

	if _, err := tx.ExecContext(ctx, query); err != nil {
		return fmt.Errorf("failed to update statistics: %w", err)
	}

	return nil
}

// Cache implementation methods

func (c *SQLiteEmbeddingCache) initializeTables() error {
	query := `CREATE TABLE IF NOT EXISTS embedding_cache (
		key TEXT PRIMARY KEY,
		value BLOB,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		last_accessed DATETIME DEFAULT CURRENT_TIMESTAMP
	)`

	if _, err := c.db.Exec(query); err != nil {
		return fmt.Errorf("failed to create cache table: %w", err)
	}

	return nil
}

// Get retrieves a value from the cache
func (c *SQLiteEmbeddingCache) Get(ctx context.Context, key string) ([]byte, error) {
	// Check memory cache first
	if value, exists := c.memoryCache[key]; exists {
		return value, nil
	}

	// Check database cache
	var value []byte
	err := c.db.QueryRowContext(ctx, "SELECT value FROM embedding_cache WHERE key = ?", key).Scan(&value)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("cache miss: key not found")
		}
		return nil, fmt.Errorf("failed to get cache value: %w", err)
	}

	// Update last accessed time
	_, err = c.db.ExecContext(ctx, "UPDATE embedding_cache SET last_accessed = CURRENT_TIMESTAMP WHERE key = ?", key)
	if err != nil {
		log.Printf("Warning: failed to update last accessed time: %v", err)
	}

	// Store in memory cache
	c.memoryCache[key] = value

	return value, nil
}

// Set stores a value in the cache
func (c *SQLiteEmbeddingCache) Set(ctx context.Context, key string, value []byte, ttl time.Duration) error {
	// Store in memory cache
	c.memoryCache[key] = value

	// Store in database cache (TTL is ignored for SQLite implementation)
	_, err := c.db.ExecContext(ctx, "INSERT OR REPLACE INTO embedding_cache (key, value, last_accessed) VALUES (?, ?, CURRENT_TIMESTAMP)", key, value)
	if err != nil {
		return fmt.Errorf("failed to set cache value: %w", err)
	}

	return nil
}

// Delete removes a value from the cache
func (c *SQLiteEmbeddingCache) Delete(ctx context.Context, key string) error {
	// Remove from memory cache
	delete(c.memoryCache, key)

	// Remove from database cache
	_, err := c.db.ExecContext(ctx, "DELETE FROM embedding_cache WHERE key = ?", key)
	if err != nil {
		return fmt.Errorf("failed to delete cache value: %w", err)
	}

	return nil
}

// Clear removes all values from the cache
func (c *SQLiteEmbeddingCache) Clear(ctx context.Context) error {
	// Clear memory cache
	c.memoryCache = make(map[string][]byte)

	// Clear database cache
	_, err := c.db.ExecContext(ctx, "DELETE FROM embedding_cache")
	if err != nil {
		return fmt.Errorf("failed to clear cache: %w", err)
	}

	return nil
}

// GetStats returns cache statistics
func (c *SQLiteEmbeddingCache) GetStats(ctx context.Context) (interfaces.CacheStats, error) {
	var stats interfaces.CacheStats

	// Get cache size from database
	err := c.db.QueryRowContext(ctx, "SELECT COUNT(*) FROM embedding_cache").Scan(&stats.Size)
	if err != nil {
		return stats, fmt.Errorf("failed to get cache size: %w", err)
	}

	// Memory cache stats
	stats.Size += int64(len(c.memoryCache))
	stats.MaxSize = 10000 // Default max size

	// Note: SQLite doesn't track hits/misses/evictions, so we leave them as 0
	return stats, nil
}
