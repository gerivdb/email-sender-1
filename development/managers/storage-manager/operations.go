package storage

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/email-sender-manager/interfaces"
)

// QueryDependencies recherche des dépendances
func (sm *StorageManagerImpl) QueryDependencies(ctx context.Context, query string) ([]*interfaces.DependencyMetadata, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("storage manager not initialized")
	}

	sqlQuery := `
		SELECT name, version, description, dependencies, created_at, updated_at
		FROM dependency_metadata 
		WHERE name ILIKE $1 OR description ILIKE $1
		ORDER BY created_at DESC
	`

	rows, err := sm.db.QueryContext(ctx, sqlQuery, "%"+query+"%")
	if err != nil {
		return nil, fmt.Errorf("failed to query dependencies: %w", err)
	}
	defer rows.Close()

	var results []*interfaces.DependencyMetadata
	for rows.Next() {
		var metadata interfaces.DependencyMetadata
		var dependenciesJSON []byte
		var createdAt, updatedAt time.Time

		err := rows.Scan(
			&metadata.Name, &metadata.Version, &metadata.Description,
			&dependenciesJSON, &createdAt, &updatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan dependency: %w", err)
		}

		if err := json.Unmarshal(dependenciesJSON, &metadata.Dependencies); err != nil {
			sm.logger.Printf("Warning: Failed to unmarshal dependencies for %s: %v", metadata.Name, err)
			metadata.Dependencies = []string{}
		}

		results = append(results, &metadata)
	}

	return results, nil
}