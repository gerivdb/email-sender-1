package storage

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

// PostgreSQL initialization

func (sm *StorageManagerImpl) initPostgreSQL(ctx context.Context) error {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		sm.config.PostgreSQL.Host,
		sm.config.PostgreSQL.Port,
		sm.config.PostgreSQL.Username,
		sm.config.PostgreSQL.Password,
		sm.config.PostgreSQL.Database,
		sm.config.PostgreSQL.SSLMode,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(sm.config.PostgreSQL.MaxOpenConns)
	db.SetMaxIdleConns(sm.config.PostgreSQL.MaxIdleConns)
	
	if lifetime, err := time.ParseDuration(sm.config.PostgreSQL.MaxLifetime); err == nil {
		db.SetConnMaxLifetime(lifetime)
	}

	// Test connection
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return fmt.Errorf("failed to ping database: %w", err)
	}

	sm.db = db
	sm.logger.Println("PostgreSQL connection initialized successfully")
	return nil
}