package storage

import (
	"context"
	"encoding/json"
	"fmt"
)

// Generic object storage operations

// StoreObject stocke un objet générique
func (sm *StorageManagerImpl) StoreObject(ctx context.Context, key string, obj interface{}) error {
	if !sm.isInitialized {
		return fmt.Errorf("storage manager not initialized")
	}

	// Sérialiser l'objet
	data, err := json.Marshal(obj)
	if err != nil {
		return fmt.Errorf("failed to marshal object: %w", err)
	}

	// Stocker en base de données
	query := `
		INSERT INTO object_storage (key, data, created_at, updated_at)
		VALUES ($1, $2, NOW(), NOW())
		ON CONFLICT (key) 
		DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()
	`

	_, err = sm.db.ExecContext(ctx, query, key, data)
	if err != nil {
		return fmt.Errorf("failed to store object: %w", err)
	}

	// Mettre en cache
	sm.setCache(key, obj)

	sm.logger.Printf("Stored object with key: %s", key)
	return nil
}

// GetObject récupère un objet générique
func (sm *StorageManagerImpl) GetObject(ctx context.Context, key string, obj interface{}) error {
	if !sm.isInitialized {
		return fmt.Errorf("storage manager not initialized")
	}

	// Vérifier le cache
	if cached := sm.getCache(key); cached != nil {
		// Copy cached object to obj
		data, err := json.Marshal(cached)
		if err == nil {
			if err := json.Unmarshal(data, obj); err == nil {
				return nil
			}
		}
	}

	// Récupérer depuis la base de données
	query := `SELECT data FROM object_storage WHERE key = $1`

	var data []byte
	err := sm.db.QueryRowContext(ctx, query, key).Scan(&data)
	if err != nil {
		return fmt.Errorf("failed to get object: %w", err)
	}

	// Désérialiser
	if err := json.Unmarshal(data, obj); err != nil {
		return fmt.Errorf("failed to unmarshal object: %w", err)
	}

	// Mettre en cache
	sm.setCache(key, obj)

	return nil
}

// DeleteObject supprime un objet
func (sm *StorageManagerImpl) DeleteObject(ctx context.Context, key string) error {
	if !sm.isInitialized {
		return fmt.Errorf("storage manager not initialized")
	}

	query := `DELETE FROM object_storage WHERE key = $1`
	_, err := sm.db.ExecContext(ctx, query, key)
	if err != nil {
		return fmt.Errorf("failed to delete object: %w", err)
	}

	// Supprimer du cache
	sm.deleteCache(key)

	sm.logger.Printf("Deleted object with key: %s", key)
	return nil
}

// ListObjects liste les objets avec un préfixe
func (sm *StorageManagerImpl) ListObjects(ctx context.Context, prefix string) ([]string, error) {
	if !sm.isInitialized {
		return nil, fmt.Errorf("storage manager not initialized")
	}

	query := `SELECT key FROM object_storage WHERE key LIKE $1 ORDER BY key`
	rows, err := sm.db.QueryContext(ctx, query, prefix+"%")
	if err != nil {
		return nil, fmt.Errorf("failed to list objects: %w", err)
	}
	defer rows.Close()

	var keys []string
	for rows.Next() {
		var key string
		if err := rows.Scan(&key); err != nil {
			return nil, fmt.Errorf("failed to scan key: %w", err)
		}
		keys = append(keys, key)
	}

	return keys, nil
}
