package core

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// SQLTestStorage represents a test SQL storage
type SQLTestStorage struct {
	DB     *sql.DB
	DBPath string
}

// createTestSQLStorage creates a new SQL test storage with temporary SQLite database
func createTestSQLStorage(t interface{}) *SQLTestStorage {
	tmpDir, err := os.MkdirTemp("", "test-sql-storage-*")
	if err != nil {
		fmt.Printf("Error creating temp dir: %v\n", err)
		return nil
	}

	dbPath := filepath.Join(tmpDir, "test.db")
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		fmt.Printf("Error opening database: %v\n", err)
		return nil
	}

	// Create necessary tables
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS plans (
			id TEXT PRIMARY KEY,
			name TEXT,
			version INTEGER,
			content TEXT,
			last_updated TIMESTAMP
		);
		
		CREATE TABLE IF NOT EXISTS conflicts (
			id TEXT PRIMARY KEY,
			plan_id TEXT,
			type TEXT,
			description TEXT,
			status TEXT,
			created_at TIMESTAMP,
			FOREIGN KEY (plan_id) REFERENCES plans(id)
		);
	`)

	if err != nil {
		fmt.Printf("Error creating tables: %v\n", err)
		db.Close()
		return nil
	}

	return &SQLTestStorage{
		DB:     db,
		DBPath: dbPath,
	}
}

// Close closes the test database and removes temporary files
func (s *SQLTestStorage) Close() {
	if s.DB != nil {
		s.DB.Close()
	}

	if s.DBPath != "" {
		os.RemoveAll(filepath.Dir(s.DBPath))
	}
}
func createTestSQLStorageWithErr() (*SQLTestStorage, error) {
	// Create a temporary directory for the test database
	tempDir, err := os.MkdirTemp("", "sync-test-*")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp directory: %w", err)
	}

	dbPath := filepath.Join(tempDir, "test.db")
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Create test tables
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS conflicts (
			id TEXT PRIMARY KEY,
			type TEXT NOT NULL,
			severity TEXT NOT NULL,
			status TEXT NOT NULL,
			detected_at TIMESTAMP NOT NULL,
			source_content TEXT,
			target_content TEXT,
			metadata TEXT
		);
		
		CREATE TABLE IF NOT EXISTS resolutions (
			id TEXT PRIMARY KEY,
			conflict_id TEXT NOT NULL,
			action TEXT NOT NULL,
			resolved_at TIMESTAMP NOT NULL,
			resolver TEXT NOT NULL,
			result TEXT,
			metadata TEXT,
			FOREIGN KEY (conflict_id) REFERENCES conflicts(id)
		);
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	return &SQLTestStorage{
		DB:     db,
		DBPath: dbPath,
	}, nil
}

// CloseWithError closes the database connection and removes the temporary file
func (s *SQLTestStorage) CloseWithError() error {
	if s.DB != nil {
		err := s.DB.Close()
		if err != nil {
			return err
		}
	}

	// Remove the database file
	if s.DBPath != "" {
		err := os.RemoveAll(filepath.Dir(s.DBPath))
		if err != nil {
			return err
		}
	}

	return nil
}

// SaveConflict saves a conflict to the database
func (s *SQLTestStorage) SaveConflict(ctx context.Context, conflict *Conflict) error {
	_, err := s.DB.ExecContext(ctx,
		"INSERT INTO conflicts (id, type, severity, status, detected_at, source_content, target_content, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
		conflict.ID,
		conflict.Type,
		conflict.Severity,
		conflict.Status,
		conflict.DetectedAt.Format(time.RFC3339),
		conflict.SourceContent,
		conflict.TargetContent,
		conflict.Metadata,
	)

	if err != nil {
		return fmt.Errorf("failed to save conflict: %w", err)
	}

	return nil
}

// GetConflict retrieves a conflict from the database
func (s *SQLTestStorage) GetConflict(ctx context.Context, id string) (*Conflict, error) {
	var conflict Conflict
	var detectedAtStr string

	err := s.DB.QueryRowContext(ctx,
		"SELECT id, type, severity, status, detected_at, source_content, target_content, metadata FROM conflicts WHERE id = ?",
		id,
	).Scan(
		&conflict.ID,
		&conflict.Type,
		&conflict.Severity,
		&conflict.Status,
		&detectedAtStr,
		&conflict.SourceContent,
		&conflict.TargetContent,
		&conflict.Metadata,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get conflict: %w", err)
	}

	detectedAt, err := time.Parse(time.RFC3339, detectedAtStr)
	if err != nil {
		return nil, fmt.Errorf("failed to parse detected_at: %w", err)
	}

	conflict.DetectedAt = detectedAt

	return &conflict, nil
}

// SaveResolution saves a conflict resolution to the database
func (s *SQLTestStorage) SaveResolution(ctx context.Context, resolution *ConflictResolution) error {
	_, err := s.DB.ExecContext(ctx,
		"INSERT INTO resolutions (id, conflict_id, action, resolved_at, resolver, result, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)",
		resolution.ID,
		resolution.ConflictID,
		resolution.Action,
		resolution.ResolvedAt.Format(time.RFC3339),
		resolution.Resolver,
		resolution.Result,
		resolution.Metadata,
	)

	if err != nil {
		return fmt.Errorf("failed to save resolution: %w", err)
	}

	return nil
}
