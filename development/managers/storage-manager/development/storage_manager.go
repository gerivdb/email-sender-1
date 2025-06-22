package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"./interfaces" // Added import
	"go.uber.org/zap"
	_ "github.com/lib/pq" // PostgreSQL driver
)

// StorageManager centralise la gestion de la persistance documentaire, du stockage objet, des connexions PostgreSQL/Qdrant et des métadonnées de dépendances.
//
// Rôle :
//   - Fournit une interface unifiée pour la gestion du stockage (PostgreSQL, Qdrant, objets, métadonnées).
//   - Intègre ErrorManager pour la gestion des erreurs lors des opérations de stockage et de migration.
//
// Interfaces principales :
//   - Initialize(ctx context.Context) error
//       → Initialise les connexions et ressources nécessaires.
//   - GetPostgreSQLConnection() (interface{}, error)
//       → Retourne la connexion PostgreSQL active.
//   - GetQdrantConnection() (interface{}, error)
//       → Retourne la connexion Qdrant active.
//   - RunMigrations(ctx context.Context) error
//       → Exécute les migrations de schéma nécessaires.
//   - SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error
//   - GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)
//   - QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error)
//   - HealthCheck(ctx context.Context) error
//   - Cleanup() error
//
// Utilisation :
//   - Centralise toutes les opérations de stockage, migration et récupération documentaire.
//   - Utilisé par d’autres managers pour la persistance, la migration et la recherche vectorielle.
//
// Entrées/Sorties :
//   - Entrées : contextes d’exécution, métadonnées, requêtes de dépendances, objets à stocker.
//   - Sorties : statuts, objets/document récupérés, erreurs, logs.
//
// Voir aussi : ErrorManager, DependencyQuery, QdrantPoint

// StorageManager interface defines the contract for storage management
type StorageManager interface {
	Initialize(ctx context.Context) error
	GetPostgreSQLConnection() (interface{}, error)
	GetQdrantConnection() (interface{}, error)
	RunMigrations(ctx context.Context) error
	SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error // Changed to interfaces type
	GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)   // Changed to interfaces type
	QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error) // Changed to interfaces type
	HealthCheck(ctx context.Context) error
	Cleanup() error
}

// DependencyQuery represents a query for dependencies (local type)
type DependencyQuery struct {
	Name       string            `json:"name,omitempty"`
	Version    string            `json:"version,omitempty"`
	Tags       []string          `json:"tags,omitempty"` // This will be used to query the map[string]string Tags
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
	errorManager ErrorManager // Assuming ErrorManager is a local interface or type for now
	pgConnString string
	qdrantURL    string
	pgDB         *sql.DB
	qdrantClient *http.Client
}

// ErrorManager interface for local implementation (if not sourced from a shared package)
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(ctx context.Context, entry *ErrorEntry) error
	ValidateErrorEntry(entry *ErrorEntry) error
}

// ErrorEntry represents an error entry (local type)
type ErrorEntry struct {
	ID        string `json:"id"`
	Timestamp string `json:"timestamp"`
	Level     string `json:"level"`
	Component string `json:"component"`
	Operation string `json:"operation"`
	Message   string `json:"message"`
	Details   string `json:"details,omitempty"`
}

// ErrorHooks for error processing (local type)
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
	if err := sm.initializePostgreSQL(); err != nil {
		return fmt.Errorf("failed to initialize PostgreSQL: %w", err)
	}
	if err := sm.initializeQdrant(ctx); err != nil {
		return fmt.Errorf("failed to initialize Qdrant: %w", err)
	}
	sm.logger.Info("StorageManager initialized successfully")
	return nil
}

func (sm *storageManagerImpl) initializePostgreSQL() error {
	db, err := sql.Open("postgres", sm.pgConnString)
	if err != nil { return fmt.Errorf("failed to open PostgreSQL connection: %w", err) }
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(5 * time.Minute)
	if err := db.Ping(); err != nil { return fmt.Errorf("failed to ping PostgreSQL: %w", err) }
	sm.pgDB = db
	sm.logger.Info("PostgreSQL connection established")
	return nil
}

func (sm *storageManagerImpl) initializeQdrant(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, "GET", sm.qdrantURL+"/collections", nil)
	if err != nil { return fmt.Errorf("failed to create Qdrant request: %w", err) }
	resp, err := sm.qdrantClient.Do(req)
	if err != nil { sm.logger.Warn("Qdrant connection test failed", zap.Error(err)); return nil }
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK { sm.logger.Warn("Qdrant not available", zap.Int("status", resp.StatusCode)); return nil }
	sm.logger.Info("Qdrant connection established")
	return nil
}

func (sm *storageManagerImpl) GetPostgreSQLConnection() (interface{}, error) {
	if sm.pgDB == nil { return nil, fmt.Errorf("PostgreSQL not initialized") }
	return sm.pgDB, nil
}

func (sm *storageManagerImpl) GetQdrantConnection() (interface{}, error) {
	if sm.qdrantURL == "" { return nil, fmt.Errorf("Qdrant not configured") }
	return map[string]interface{}{"url": sm.qdrantURL, "client": sm.qdrantClient}, nil
}

func (sm *storageManagerImpl) RunMigrations(ctx context.Context) error {
	sm.logger.Info("Running database migrations")
	if sm.pgDB == nil { return fmt.Errorf("PostgreSQL not initialized") }
	
	createDepsTable := `
		CREATE TABLE IF NOT EXISTS dependencies (
			id SERIAL PRIMARY KEY,
			name VARCHAR(255) NOT NULL UNIQUE,
			version VARCHAR(100) NOT NULL,
			description TEXT,
			license VARCHAR(100),
			repository VARCHAR(500),
			tags JSONB, -- Changed from TEXT[] to JSONB to store map[string]string
			attributes JSONB, -- Changed from metadata to attributes
			package_manager VARCHAR(100),
			source VARCHAR(255),
			type VARCHAR(100),
			direct BOOLEAN,
			required BOOLEAN,
			vulnerabilities JSONB, -- Storing []Vulnerability as JSONB
			last_updated TIMESTAMP WITH TIME ZONE,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
		CREATE INDEX IF NOT EXISTS idx_dependencies_name ON dependencies(name);
		CREATE INDEX IF NOT EXISTS idx_dependencies_tags ON dependencies USING GIN(tags);
		CREATE INDEX IF NOT EXISTS idx_dependencies_attributes ON dependencies USING GIN(attributes);
	`
	if _, err := sm.pgDB.ExecContext(ctx, createDepsTable); err != nil {
		return fmt.Errorf("failed to create dependencies table: %w", err)
	}
	
	createHistoryTable := `
		CREATE TABLE IF NOT EXISTS dependency_history (
			id SERIAL PRIMARY KEY,
			dependency_name VARCHAR(255) NOT NULL,
			old_version VARCHAR(100),
			new_version VARCHAR(100),
			change_type VARCHAR(50) NOT NULL,
			changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB
		);
		CREATE INDEX IF NOT EXISTS idx_dep_history_name ON dependency_history(dependency_name);
	`
	if _, err := sm.pgDB.ExecContext(ctx, createHistoryTable); err != nil {
		return fmt.Errorf("failed to create dependency_history table: %w", err)
	}
	sm.logger.Info("Database migrations completed successfully")
	return nil
}

func (sm *storageManagerImpl) SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error {
	if sm.pgDB == nil { return fmt.Errorf("PostgreSQL not initialized") }
	sm.logger.Info("Saving dependency metadata", zap.String("name", metadata.Name))

	tagsJSON, err := json.Marshal(metadata.Tags)
	if err != nil { return fmt.Errorf("failed to marshal tags: %w", err) }
	
	attributesJSON, err := json.Marshal(metadata.Attributes)
	if err != nil { return fmt.Errorf("failed to marshal attributes: %w", err) }

	vulnerabilitiesJSON, err := json.Marshal(metadata.Vulnerabilities)
	if err != nil { return fmt.Errorf("failed to marshal vulnerabilities: %w", err) }

	query := `
		INSERT INTO dependencies (name, version, description, license, repository, tags, attributes, package_manager, source, type, direct, required, vulnerabilities, last_updated, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW())
		ON CONFLICT (name) DO UPDATE SET
			version = EXCLUDED.version,
			description = EXCLUDED.description,
			license = EXCLUDED.license,
			repository = EXCLUDED.repository,
			tags = EXCLUDED.tags,
			attributes = EXCLUDED.attributes,
			package_manager = EXCLUDED.package_manager,
			source = EXCLUDED.source,
			type = EXCLUDED.type,
			direct = EXCLUDED.direct,
			required = EXCLUDED.required,
			vulnerabilities = EXCLUDED.vulnerabilities,
			last_updated = EXCLUDED.last_updated,
			updated_at = NOW()
	`
	_, err = sm.pgDB.ExecContext(ctx, query,
		metadata.Name, metadata.Version, metadata.Description, metadata.License, metadata.Repository,
		tagsJSON, attributesJSON, metadata.PackageManager, metadata.Source, metadata.Type,
		metadata.Direct, metadata.Required, vulnerabilitiesJSON, metadata.LastUpdated,
	)
	if err != nil { return fmt.Errorf("failed to save dependency metadata: %w", err) }
	
	// Record change in history (simplified, consider what metadata to store in history)
	historyQuery := `INSERT INTO dependency_history (dependency_name, new_version, change_type) VALUES ($1, $2, 'updated')`
	_, err = sm.pgDB.ExecContext(ctx, historyQuery, metadata.Name, metadata.Version)
	if err != nil { sm.logger.Warn("Failed to record dependency history", zap.Error(err)) }
	
	sm.logger.Info("Dependency metadata saved successfully", zap.String("name", metadata.Name))
	return nil
}

func (sm *storageManagerImpl) GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error) {
	if sm.pgDB == nil { return nil, fmt.Errorf("PostgreSQL not initialized") }
	sm.logger.Info("Getting dependency metadata", zap.String("name", name))
	query := `
		SELECT name, version, description, license, repository, tags, attributes, package_manager, source, type, direct, required, vulnerabilities, last_updated, created_at, updated_at
		FROM dependencies WHERE name = $1
	`
	row := sm.pgDB.QueryRowContext(ctx, query, name)
	var metadata interfaces.DependencyMetadata
	var tagsJSON, attributesJSON, vulnerabilitiesJSON []byte
	
	err := row.Scan(
		&metadata.Name, &metadata.Version, &metadata.Description, &metadata.License, &metadata.Repository,
		&tagsJSON, &attributesJSON, &metadata.PackageManager, &metadata.Source, &metadata.Type,
		&metadata.Direct, &metadata.Required, &vulnerabilitiesJSON, &metadata.LastUpdated,
		&metadata.CreatedAt, &metadata.UpdatedAt, // Assuming CreatedAt is part of interfaces.DependencyMetadata or we add it
	)
	if err != nil {
		if err == sql.ErrNoRows { return nil, fmt.Errorf("dependency not found: %s", name) }
		return nil, fmt.Errorf("failed to get dependency metadata: %w", err)
	}
	
	if err := json.Unmarshal(tagsJSON, &metadata.Tags); err != nil { sm.logger.Warn("Failed to unmarshal tags", zap.Error(err)) }
	if err := json.Unmarshal(attributesJSON, &metadata.Attributes); err != nil { sm.logger.Warn("Failed to unmarshal attributes", zap.Error(err)) }
	if err := json.Unmarshal(vulnerabilitiesJSON, &metadata.Vulnerabilities); err != nil { sm.logger.Warn("Failed to unmarshal vulnerabilities", zap.Error(err)) }
	
	return &metadata, nil
}

func (sm *storageManagerImpl) QueryDependencies(ctx context.Context, query *DependencyQuery) ([]*interfaces.DependencyMetadata, error) {
	if sm.pgDB == nil { return nil, fmt.Errorf("PostgreSQL not initialized") }
	sm.logger.Info("Querying dependencies", zap.Any("query", query))
	
	sqlQuery := "SELECT name, version, description, license, repository, tags, attributes, package_manager, source, type, direct, required, vulnerabilities, last_updated, created_at, updated_at FROM dependencies WHERE 1=1"
	args := []interface{}{}
	argIndex := 1
	
	if query.Name != "" { sqlQuery += fmt.Sprintf(" AND name ILIKE $%d", argIndex); args = append(args, "%"+query.Name+"%"); argIndex++ }
	if query.Version != "" { sqlQuery += fmt.Sprintf(" AND version = $%d", argIndex); args = append(args, query.Version); argIndex++ }
	// Querying tags (map[string]string stored as JSONB) requires specific JSONB operators, e.g., tags @> '{"key":"value"}'::jsonb
	// This simplified query won't directly filter by tags effectively without such operators.
	
	sqlQuery += " ORDER BY name"
	if query.Limit > 0 { sqlQuery += fmt.Sprintf(" LIMIT $%d", argIndex); args = append(args, query.Limit); argIndex++ }
	if query.Offset > 0 { sqlQuery += fmt.Sprintf(" OFFSET $%d", argIndex); args = append(args, query.Offset) }
	
	rows, err := sm.pgDB.QueryContext(ctx, sqlQuery, args...)
	if err != nil { return nil, fmt.Errorf("failed to query dependencies: %w", err) }
	defer rows.Close()
	
	var results []*interfaces.DependencyMetadata
	for rows.Next() {
		var metadata interfaces.DependencyMetadata
		var tagsJSON, attributesJSON, vulnerabilitiesJSON []byte
		err := rows.Scan(
			&metadata.Name, &metadata.Version, &metadata.Description, &metadata.License, &metadata.Repository,
			&tagsJSON, &attributesJSON, &metadata.PackageManager, &metadata.Source, &metadata.Type,
			&metadata.Direct, &metadata.Required, &vulnerabilitiesJSON, &metadata.LastUpdated,
			&metadata.CreatedAt, &metadata.UpdatedAt,
		)
		if err != nil { return nil, fmt.Errorf("failed to scan dependency row: %w", err) }
		if err := json.Unmarshal(tagsJSON, &metadata.Tags); err != nil { sm.logger.Warn("Failed to unmarshal tags for "+metadata.Name, zap.Error(err)) }
		if err := json.Unmarshal(attributesJSON, &metadata.Attributes); err != nil { sm.logger.Warn("Failed to unmarshal attributes for "+metadata.Name, zap.Error(err)) }
		if err := json.Unmarshal(vulnerabilitiesJSON, &metadata.Vulnerabilities); err != nil { sm.logger.Warn("Failed to unmarshal vulnerabilities for "+metadata.Name, zap.Error(err)) }
		results = append(results, &metadata)
	}
	if err := rows.Err(); err != nil { return nil, fmt.Errorf("error reading dependency rows: %w", err) }
	sm.logger.Info("Query completed", zap.Int("results", len(results)))
	return results, nil
}

func (sm *storageManagerImpl) HealthCheck(ctx context.Context) error {
	sm.logger.Info("Performing storage health check")
	if sm.pgDB != nil {
		if err := sm.pgDB.PingContext(ctx); err != nil { return fmt.Errorf("PostgreSQL health check failed: %w", err) }
	} else { return fmt.Errorf("PostgreSQL not initialized") }
	if sm.qdrantURL != "" {
		req, err := http.NewRequestWithContext(ctx, "GET", sm.qdrantURL+"/health", nil)
		if err == nil {
			resp, errHealth := sm.qdrantClient.Do(req)
			if errHealth != nil { sm.logger.Warn("Qdrant health check failed", zap.Error(errHealth))
			} else { resp.Body.Close(); if resp.StatusCode != http.StatusOK { sm.logger.Warn("Qdrant unhealthy", zap.Int("status", resp.StatusCode)) } }
		}
	}
	sm.logger.Info("Storage health check completed")
	return nil
}

func (sm *storageManagerImpl) Cleanup() error {
	sm.logger.Info("Cleaning up StorageManager resources")
	if sm.pgDB != nil {
		if err := sm.pgDB.Close(); err != nil { sm.logger.Error("Failed to close PostgreSQL connection", zap.Error(err))
		} else { sm.logger.Info("PostgreSQL connection closed") }
	}
	sm.qdrantClient.CloseIdleConnections()
	sm.logger.Info("StorageManager cleanup completed")
	return nil
}

func main() {
	logger, _ := zap.NewDevelopment()
	defer logger.Sync() // nolint:errcheck

	// Example usage (replace with actual configuration)
	pgConn := "user=postgres password=secret dbname=dependencies sslmode=disable host=localhost port=5432"
	qdrantURL := "http://localhost:6333"

	storageMgr := NewStorageManager(logger, pgConn, qdrantURL)
	
	ctx := context.Background()
	if err := storageMgr.Initialize(ctx); err != nil {
		log.Fatalf("Failed to initialize StorageManager: %v", err)
	}
	logger.Info("StorageManager initialized successfully.")

	// Example: Save metadata
	sampleMeta := &interfaces.DependencyMetadata{
		Name: "example-lib", Version: "1.0.2", Description: "An example library", License: "MIT",
		Repository: "github.com/example/example-lib", Tags: map[string]string{"language": "go", "status": "beta"},
		Attributes: map[string]string{"size": "10MB", "complexity": "medium"}, PackageManager: "go_modules",
		Source: "github", Type: "library", Direct: true, Required: true,
		Vulnerabilities: []interfaces.Vulnerability{{Severity: "HIGH", Description: "XSS vulnerability", CVEIDs: []string{"CVE-2023-1234"}}},
		LastUpdated: time.Now(), UpdatedAt: time.Now(), // CreatedAt will be set by DB
	}
	if err := storageMgr.SaveDependencyMetadata(ctx, sampleMeta); err != nil {
		logger.Error("Failed to save sample metadata", zap.Error(err))
	} else {
		logger.Info("Sample metadata saved.")
	}

	// Example: Get metadata
	retrievedMeta, err := storageMgr.GetDependencyMetadata(ctx, "example-lib")
	if err != nil {
		logger.Error("Failed to retrieve sample metadata", zap.Error(err))
	} else {
		logger.Info("Retrieved metadata", zap.Any("metadata", retrievedMeta))
	}
}
