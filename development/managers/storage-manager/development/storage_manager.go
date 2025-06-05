package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"go.uber.org/zap"
	_ "github.com/lib/pq" // PostgreSQL driver
)

// StorageManager interface defines the contract for storage management
type StorageManager interface {
	Initialize(ctx context.Context) error
	GetPostgreSQLConnection() (interface{}, error)
	GetQdrantConnection() (interface{}, error)
	RunMigrations(ctx context.Context) error
	SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error
	GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error)
	QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*DependencyMetadata, error)
	HealthCheck(ctx context.Context) error
	Cleanup() error
}

// DependencyMetadata represents metadata for a dependency
type DependencyMetadata struct {
	Name        string            `json:"name"`
	Version     string            `json:"version"`
	Description string            `json:"description,omitempty"`
	License     string            `json:"license,omitempty"`
	Repository  string            `json:"repository,omitempty"`
	Tags        []string          `json:"tags,omitempty"`
	Metadata    map[string]string `json:"metadata,omitempty"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
}

// DependencyQuery represents a query for dependencies
type DependencyQuery struct {
	Name       string            `json:"name,omitempty"`
	Version    string            `json:"version,omitempty"`
	Tags       []string          `json:"tags,omitempty"`
	Limit      int               `json:"limit,omitempty"`
	Offset     int               `json:"offset,omitempty"`
	Filters    map[string]string `json:"filters,omitempty"`
}

// QdrantPoint represents a point in Qdrant vector database
type QdrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// storageManagerImpl implements StorageManager with ErrorManager integration
type storageManagerImpl struct {
	logger       *zap.Logger
	errorManager ErrorManager
	pgConnString string
	qdrantURL    string
	pgDB         *sql.DB
	qdrantClient *http.Client
}

// ErrorManager interface for local implementation
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(ctx context.Context, entry *ErrorEntry) error
	ValidateErrorEntry(entry *ErrorEntry) error
}

// ErrorEntry represents an error entry
type ErrorEntry struct {
	ID        string `json:"id"`
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Component string `json:"component"`
	Operation string `json:"operation"`
	Message   string `json:"message"`
	Details   string `json:"details,omitempty"`
}

// ErrorHooks for error processing
type ErrorHooks struct {
	PreProcess  func(error) error
	PostProcess func(error) error
}

// NewStorageManager creates a new StorageManager instance
func NewStorageManager(logger *zap.Logger, pgConnString, qdrantURL string) StorageManager {
	return &storageManagerImpl{
		logger:       logger,
		pgConnString: pgConnString,
		qdrantURL:    qdrantURL,
		qdrantClient: &http.Client{Timeout: 30 * time.Second},
	}
}

// Initialize initializes the storage manager
func (sm *storageManagerImpl) Initialize(ctx context.Context) error {
	sm.logger.Info("Initializing StorageManager")
	
	// Initialize PostgreSQL connection
	if err := sm.initializePostgreSQL(); err != nil {
		return fmt.Errorf("failed to initialize PostgreSQL: %w", err)
	}
	
	// Initialize Qdrant connection
	if err := sm.initializeQdrant(ctx); err != nil {
		return fmt.Errorf("failed to initialize Qdrant: %w", err)
	}
	
	sm.logger.Info("StorageManager initialized successfully")
	return nil
}

// initializePostgreSQL sets up PostgreSQL connection
func (sm *storageManagerImpl) initializePostgreSQL() error {
	db, err := sql.Open("postgres", sm.pgConnString)
	if err != nil {
		return fmt.Errorf("failed to open PostgreSQL connection: %w", err)
	}
	
	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)
	
	// Test connection
	if err := db.Ping(); err != nil {
		return fmt.Errorf("failed to ping PostgreSQL: %w", err)
	}
	
	sm.pgDB = db
	sm.logger.Info("PostgreSQL connection established")
	return nil
}

// initializeQdrant sets up Qdrant connection
func (sm *storageManagerImpl) initializeQdrant(ctx context.Context) error {
	// Test Qdrant connection
	req, err := http.NewRequestWithContext(ctx, "GET", sm.qdrantURL+"/collections", nil)
	if err != nil {
		return fmt.Errorf("failed to create Qdrant request: %w", err)
	}
	
	resp, err := sm.qdrantClient.Do(req)
	if err != nil {
		sm.logger.Warn("Qdrant connection test failed, continuing without vector search", zap.Error(err))
		return nil // Non-fatal error
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		sm.logger.Warn("Qdrant not available, continuing without vector search", zap.Int("status", resp.StatusCode))
		return nil
	}
	
	sm.logger.Info("Qdrant connection established")
	return nil
}

// GetPostgreSQLConnection returns PostgreSQL connection
func (sm *storageManagerImpl) GetPostgreSQLConnection() (interface{}, error) {
	if sm.pgDB == nil {
		return nil, fmt.Errorf("PostgreSQL not initialized")
	}
	return sm.pgDB, nil
}

// GetQdrantConnection returns Qdrant connection info
func (sm *storageManagerImpl) GetQdrantConnection() (interface{}, error) {
	if sm.qdrantURL == "" {
		return nil, fmt.Errorf("Qdrant not configured")
	}
	return map[string]interface{}{
		"url":    sm.qdrantURL,
		"client": sm.qdrantClient,
	}, nil
}

// RunMigrations executes database migrations
func (sm *storageManagerImpl) RunMigrations(ctx context.Context) error {
	sm.logger.Info("Running database migrations")
	
	if sm.pgDB == nil {
		return fmt.Errorf("PostgreSQL not initialized")
	}
	
	// Create dependencies table
	createDepsTable := `
		CREATE TABLE IF NOT EXISTS dependencies (
			id SERIAL PRIMARY KEY,
			name VARCHAR(255) NOT NULL UNIQUE,
			version VARCHAR(100) NOT NULL,
			description TEXT,
			license VARCHAR(100),
			repository VARCHAR(500),
			tags TEXT[], -- PostgreSQL array
			metadata JSONB,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
		
		CREATE INDEX IF NOT EXISTS idx_dependencies_name ON dependencies(name);
		CREATE INDEX IF NOT EXISTS idx_dependencies_version ON dependencies(version);
		CREATE INDEX IF NOT EXISTS idx_dependencies_tags ON dependencies USING GIN(tags);
		CREATE INDEX IF NOT EXISTS idx_dependencies_metadata ON dependencies USING GIN(metadata);
	`
	
	if _, err := sm.pgDB.ExecContext(ctx, createDepsTable); err != nil {
		return fmt.Errorf("failed to create dependencies table: %w", err)
	}
	
	// Create dependency_history table for tracking changes
	createHistoryTable := `
		CREATE TABLE IF NOT EXISTS dependency_history (
			id SERIAL PRIMARY KEY,
			dependency_name VARCHAR(255) NOT NULL,
			old_version VARCHAR(100),
			new_version VARCHAR(100),
			change_type VARCHAR(50) NOT NULL, -- 'added', 'updated', 'removed'
			changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB
		);
		
		CREATE INDEX IF NOT EXISTS idx_dep_history_name ON dependency_history(dependency_name);
		CREATE INDEX IF NOT EXISTS idx_dep_history_changed_at ON dependency_history(changed_at);
	`
	
	if _, err := sm.pgDB.ExecContext(ctx, createHistoryTable); err != nil {
		return fmt.Errorf("failed to create dependency_history table: %w", err)
	}
	
	sm.logger.Info("Database migrations completed successfully")
	return nil
}

// SaveDependencyMetadata saves dependency metadata to storage
func (sm *storageManagerImpl) SaveDependencyMetadata(ctx context.Context, metadata *DependencyMetadata) error {
	if sm.pgDB == nil {
		return fmt.Errorf("PostgreSQL not initialized")
	}
	
	sm.logger.Info("Saving dependency metadata", zap.String("name", metadata.Name))
	
	metadataJSON, err := json.Marshal(metadata.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	
	tagsJSON, err := json.Marshal(metadata.Tags)
	if err != nil {
		return fmt.Errorf("failed to marshal tags: %w", err)
	}
	
	query := `
		INSERT INTO dependencies (name, version, description, license, repository, tags, metadata, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
		ON CONFLICT (name) DO UPDATE SET
			version = EXCLUDED.version,
			description = EXCLUDED.description,
			license = EXCLUDED.license,
			repository = EXCLUDED.repository,
			tags = EXCLUDED.tags,
			metadata = EXCLUDED.metadata,
			updated_at = NOW()
	`
	
	_, err = sm.pgDB.ExecContext(ctx, query,
		metadata.Name,
		metadata.Version,
		metadata.Description,
		metadata.License,
		metadata.Repository,
		tagsJSON,
		metadataJSON,
	)
	
	if err != nil {
		return fmt.Errorf("failed to save dependency metadata: %w", err)
	}
	
	// Record change in history
	historyQuery := `
		INSERT INTO dependency_history (dependency_name, new_version, change_type, metadata)
		VALUES ($1, $2, 'updated', $3)
	`
	
	_, err = sm.pgDB.ExecContext(ctx, historyQuery, metadata.Name, metadata.Version, metadataJSON)
	if err != nil {
		sm.logger.Warn("Failed to record dependency history", zap.Error(err))
	}
	
	sm.logger.Info("Dependency metadata saved successfully", zap.String("name", metadata.Name))
	return nil
}

// GetDependencyMetadata retrieves dependency metadata from storage
func (sm *storageManagerImpl) GetDependencyMetadata(ctx context.Context, name string) (*DependencyMetadata, error) {
	if sm.pgDB == nil {
		return nil, fmt.Errorf("PostgreSQL not initialized")
	}
	
	sm.logger.Info("Getting dependency metadata", zap.String("name", name))
	
	query := `
		SELECT name, version, description, license, repository, tags, metadata, created_at, updated_at
		FROM dependencies
		WHERE name = $1
	`
	
	row := sm.pgDB.QueryRowContext(ctx, query, name)
	
	var metadata DependencyMetadata
	var tagsJSON, metadataJSON []byte
	
	err := row.Scan(
		&metadata.Name,
		&metadata.Version,
		&metadata.Description,
		&metadata.License,
		&metadata.Repository,
		&tagsJSON,
		&metadataJSON,
		&metadata.CreatedAt,
		&metadata.UpdatedAt,
	)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("dependency not found: %s", name)
		}
		return nil, fmt.Errorf("failed to get dependency metadata: %w", err)
	}
	
	// Unmarshal JSON fields
	if len(tagsJSON) > 0 {
		if err := json.Unmarshal(tagsJSON, &metadata.Tags); err != nil {
			sm.logger.Warn("Failed to unmarshal tags", zap.Error(err))
		}
	}
	
	if len(metadataJSON) > 0 {
		if err := json.Unmarshal(metadataJSON, &metadata.Metadata); err != nil {
			sm.logger.Warn("Failed to unmarshal metadata", zap.Error(err))
		}
	}
	
	return &metadata, nil
}

// QueryDependencies queries dependencies based on criteria
func (sm *storageManagerImpl) QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*DependencyMetadata, error) {
	if sm.pgDB == nil {
		return nil, fmt.Errorf("PostgreSQL not initialized")
	}
	
	sm.logger.Info("Querying dependencies", zap.Any("query", query))
	
	sqlQuery := `
		SELECT name, version, description, license, repository, tags, metadata, created_at, updated_at
		FROM dependencies
		WHERE 1=1
	`
	
	args := []interface{}{}
	argIndex := 1
	
	if query.Name != "" {
		sqlQuery += fmt.Sprintf(" AND name ILIKE $%d", argIndex)
		args = append(args, "%"+query.Name+"%")
		argIndex++
	}
	
	if query.Version != "" {
		sqlQuery += fmt.Sprintf(" AND version = $%d", argIndex)
		args = append(args, query.Version)
		argIndex++
	}
	
	sqlQuery += " ORDER BY name"
	
	if query.Limit > 0 {
		sqlQuery += fmt.Sprintf(" LIMIT $%d", argIndex)
		args = append(args, query.Limit)
		argIndex++
	}
	
	if query.Offset > 0 {
		sqlQuery += fmt.Sprintf(" OFFSET $%d", argIndex)
		args = append(args, query.Offset)
	}
	
	rows, err := sm.pgDB.QueryContext(ctx, sqlQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query dependencies: %w", err)
	}
	defer rows.Close()
	
	var results []*DependencyMetadata
	
	for rows.Next() {
		var metadata DependencyMetadata
		var tagsJSON, metadataJSON []byte
		
		err := rows.Scan(
			&metadata.Name,
			&metadata.Version,
			&metadata.Description,
			&metadata.License,
			&metadata.Repository,
			&tagsJSON,
			&metadataJSON,
			&metadata.CreatedAt,
			&metadata.UpdatedAt,
		)
		
		if err != nil {
			return nil, fmt.Errorf("failed to scan dependency row: %w", err)
		}
		
		// Unmarshal JSON fields
		if len(tagsJSON) > 0 {
			json.Unmarshal(tagsJSON, &metadata.Tags)
		}
		
		if len(metadataJSON) > 0 {
			json.Unmarshal(metadataJSON, &metadata.Metadata)
		}
		
		results = append(results, &metadata)
	}
	
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error reading dependency rows: %w", err)
	}
	
	sm.logger.Info("Query completed", zap.Int("results", len(results)))
	return results, nil
}

// HealthCheck performs health check on storage connections
func (sm *storageManagerImpl) HealthCheck(ctx context.Context) error {
	sm.logger.Info("Performing storage health check")
	
	// Check PostgreSQL
	if sm.pgDB != nil {
		if err := sm.pgDB.PingContext(ctx); err != nil {
			return fmt.Errorf("PostgreSQL health check failed: %w", err)
		}
	} else {
		return fmt.Errorf("PostgreSQL not initialized")
	}
	
	// Check Qdrant (non-fatal)
	if sm.qdrantURL != "" {
		req, err := http.NewRequestWithContext(ctx, "GET", sm.qdrantURL+"/health", nil)
		if err == nil {
			resp, err := sm.qdrantClient.Do(req)
			if err != nil {
				sm.logger.Warn("Qdrant health check failed", zap.Error(err))
			} else {
				resp.Body.Close()
				if resp.StatusCode != http.StatusOK {
					sm.logger.Warn("Qdrant unhealthy", zap.Int("status", resp.StatusCode))
				}
			}
		}
	}
	
	sm.logger.Info("Storage health check completed")
	return nil
}

// Cleanup cleans up storage resources
func (sm *storageManagerImpl) Cleanup() error {
	sm.logger.Info("Cleaning up StorageManager resources")
	
	if sm.pgDB != nil {
		if err := sm.pgDB.Close(); err != nil {
			sm.logger.Error("Failed to close PostgreSQL connection", zap.Error(err))
		} else {
			sm.logger.Info("PostgreSQL connection closed")
		}
	}
	
	// Close HTTP client
	sm.qdrantClient.CloseIdleConnections()
	
	sm.logger.Info("StorageManager cleanup completed")
	return nil
}

func main() {
	logger, _ := zap.NewDevelopment()
	defer logger.Sync()

	sm := NewStorageManager(logger, "postgres://...", "http://localhost:6333")
	
	ctx := context.Background()
	if err := sm.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize StorageManager: %v", err)
	}

	logger.Info("StorageManager initialized successfully")
}
