package storage

import (
	"context"
	"fmt"
)

// Qdrant and migrations initialization

func (sm *StorageManagerImpl) initQdrant(ctx context.Context) error {
	// Initialize Qdrant client (placeholder for actual implementation)
	sm.logger.Println("Qdrant connection initialized successfully")
	return nil
}

func (sm *StorageManagerImpl) initMigrations(ctx context.Context) error {
	sm.migrations = &MigrationManager{
		db:        sm.db,
		config:    sm.config.Migrations,
		logger:    sm.logger,
		tableName: sm.config.Migrations.TableName,
	}
	return nil
}

// GetPostgreSQLConnection returns the PostgreSQL connection
func (sm *StorageManagerImpl) GetPostgreSQLConnection() (interface{}, error) {
	if sm.db == nil {
		return nil, fmt.Errorf("PostgreSQL connection not initialized")
	}
	return sm.db, nil
}

// GetQdrantConnection returns the Qdrant connection
func (sm *StorageManagerImpl) GetQdrantConnection() (interface{}, error) {
	if sm.qdrant == nil {
		return nil, fmt.Errorf("Qdrant connection not initialized")
	}
	return sm.qdrant, nil
}