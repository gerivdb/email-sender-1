package storage

import (
	"context"
	"database/sql"
	"fmt"
	"log"
)

// Migrations implementation

// RunMigrations exécute les migrations de base de données
func (sm *StorageManagerImpl) RunMigrations(ctx context.Context) error {
	if sm.migrations == nil {
		return fmt.Errorf("migrations manager not initialized")
	}

	sm.logger.Println("Running database migrations...")

	// Créer la table des migrations si elle n'existe pas
	if err := sm.migrations.createMigrationsTable(ctx); err != nil {
		return fmt.Errorf("failed to create migrations table: %w", err)
	}

	// Créer les tables principales
	if err := sm.migrations.createMainTables(ctx); err != nil {
		return fmt.Errorf("failed to create main tables: %w", err)
	}

	sm.logger.Println("Database migrations completed successfully")
	return nil
}

// createMigrationsTable crée la table de suivi des migrations
func (mm *MigrationManager) createMigrationsTable(ctx context.Context) error {
	query := fmt.Sprintf(`
		CREATE TABLE IF NOT EXISTS %s (
			id SERIAL PRIMARY KEY,
			version VARCHAR(255) NOT NULL UNIQUE,
			applied_at TIMESTAMP DEFAULT NOW()
		)
	`, mm.tableName)

	_, err := mm.db.ExecContext(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to create migrations table: %w", err)
	}

	mm.logger.Printf("Migrations table %s ready", mm.tableName)
	return nil
}

// createMainTables crée les tables principales
func (mm *MigrationManager) createMainTables(ctx context.Context) error {
	tables := []struct {
		name  string
		query string
	}{
		{
			name: "dependency_metadata",
			query: `
				CREATE TABLE IF NOT EXISTS dependency_metadata (
					id SERIAL PRIMARY KEY,
					name VARCHAR(255) NOT NULL,
					version VARCHAR(100) NOT NULL,
					description TEXT,
					dependencies JSONB,
					created_at TIMESTAMP DEFAULT NOW(),
					updated_at TIMESTAMP DEFAULT NOW(),
					UNIQUE(name, version)
				)
			`,
		},
		{
			name: "object_storage",
			query: `
				CREATE TABLE IF NOT EXISTS object_storage (
					id SERIAL PRIMARY KEY,
					key VARCHAR(500) NOT NULL UNIQUE,
					data JSONB NOT NULL,
					created_at TIMESTAMP DEFAULT NOW(),
					updated_at TIMESTAMP DEFAULT NOW()
				)
			`,
		},
	}

	for _, table := range tables {
		if err := mm.createTable(ctx, table.name, table.query); err != nil {
			return err
		}
	}

	return nil
}

// createTable crée une table spécifique
func (mm *MigrationManager) createTable(ctx context.Context, tableName, query string) error {
	_, err := mm.db.ExecContext(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to create table %s: %w", tableName, err)
	}

	mm.logger.Printf("Table %s created successfully", tableName)
	return nil
}
