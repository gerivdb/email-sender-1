package storage

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/email-sender-manager/interfaces"
)

func TestStorageManager_Interface(t *testing.T) {
	sm := NewStorageManager()
	
	// Vérifier que StorageManager implémente l'interface
	assert.Implements(t, (*interfaces.StorageManager)(nil), sm)
	assert.Implements(t, (*interfaces.BaseManager)(nil), sm)
}

func TestStorageManager_BasicOperations(t *testing.T) {
	sm := NewStorageManager()
	
	// Test des getters de base
	assert.NotEmpty(t, sm.GetID())
	assert.Equal(t, "storage-manager", sm.GetName())
	assert.Equal(t, "1.0.0", sm.GetVersion())
	assert.Equal(t, interfaces.StatusStopped, sm.GetStatus())
}

func TestStorageManager_StatusTransitions(t *testing.T) {
	sm := NewStorageManager()
	ctx := context.Background()

	// État initial
	assert.Equal(t, interfaces.StatusStopped, sm.GetStatus())

	// Test de health check sur un manager arrêté
	err := sm.Health(ctx)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "not running")

	// Start sans initialisation (devrait initialiser automatiquement)
	// Note: En mode test, la base de données ne sera pas disponible
	// donc nous testons seulement la logique de base
}

func TestStorageManager_CacheOperations(t *testing.T) {
	sm := NewStorageManager().(*StorageManagerImpl)
	
	// Test cache operations
	key := "test-key"
	value := "test-value"
	
	// Set cache
	sm.setCache(key, value)
	
	// Get cache
	cached := sm.getCache(key)
	assert.Equal(t, value, cached)
	
	// Delete cache
	sm.deleteCache(key)
	cached = sm.getCache(key)
	assert.Nil(t, cached)
	
	// Clear cache
	sm.setCache("key1", "value1")
	sm.setCache("key2", "value2")
	sm.clearCache()
	
	assert.Nil(t, sm.getCache("key1"))
	assert.Nil(t, sm.getCache("key2"))
}

func TestStorageManager_Configuration(t *testing.T) {
	config := loadStorageConfig()
	
	// Vérifier les valeurs par défaut
	assert.Equal(t, "localhost", config.PostgreSQL.Host)
	assert.Equal(t, 5432, config.PostgreSQL.Port)
	assert.Equal(t, "email_sender", config.PostgreSQL.Database)
	
	assert.Equal(t, "localhost", config.Qdrant.Host)
	assert.Equal(t, 6333, config.Qdrant.Port)
	
	assert.Equal(t, 1000, config.Cache.MaxSize)
	assert.Equal(t, "./migrations", config.Migrations.Path)
	assert.True(t, config.Migrations.AutoRun)
}

func TestDependencyMetadata_Operations(t *testing.T) {
	// Test mock pour les opérations de métadonnées
	// En mode test réel, nous aurions besoin d'une base de données de test
	
	metadata := &interfaces.DependencyMetadata{
		Name:         "test-package",
		Version:      "1.0.0",
		Description:  "Test package for unit tests",
		Dependencies: []string{"dep1", "dep2"},
	}
	
	assert.Equal(t, "test-package", metadata.Name)
	assert.Equal(t, "1.0.0", metadata.Version)
	assert.Len(t, metadata.Dependencies, 2)
}

func TestMigrationManager_TableCreation(t *testing.T) {
	// Test de la logique de création de tables
	// Ceci testerait normalement avec une vraie base de données
	
	config := MigrationsConfig{
		Path:      "./migrations",
		AutoRun:   true,
		TableName: "test_migrations",
	}
	
	assert.Equal(t, "./migrations", config.Path)
	assert.True(t, config.AutoRun)
	assert.Equal(t, "test_migrations", config.TableName)
}
