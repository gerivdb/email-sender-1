package middleware

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"sync"
	"time"
)

// APIKeyStore interface pour le stockage des clés API
type APIKeyStore interface {
	GetAPIKey(key string) (*APIKey, error)
	CreateAPIKey(userID, name string, permissions []string, expiresAt *time.Time) (*APIKey, error)
	UpdateAPIKey(apiKey *APIKey) error
	DeleteAPIKey(keyID string) error
	ListAPIKeys(userID string) ([]*APIKey, error)
	RevokeAPIKey(keyID string) error
}

// MemoryAPIKeyStore implémentation en mémoire (pour développement)
type MemoryAPIKeyStore struct {
	keys map[string]*APIKey
	mu   sync.RWMutex
}

// NewMemoryAPIKeyStore crée un store en mémoire
func NewMemoryAPIKeyStore() APIKeyStore {
	store := &MemoryAPIKeyStore{
		keys: make(map[string]*APIKey),
	}

	// Créer une clé API par défaut pour les tests
	defaultKey, _ := store.CreateAPIKey(
		"default-user",
		"Default Development Key",
		[]string{"*"}, // Toutes permissions
		nil,           // Pas d'expiration
	)

	fmt.Printf("🔑 Default API Key created: %s\n", defaultKey.Key)

	return store
}

func (m *MemoryAPIKeyStore) GetAPIKey(key string) (*APIKey, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	apiKey, exists := m.keys[key]
	if !exists {
		return nil, fmt.Errorf("API key not found")
	}

	return apiKey, nil
}

func (m *MemoryAPIKeyStore) CreateAPIKey(userID, name string, permissions []string, expiresAt *time.Time) (*APIKey, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	// Générer une clé API sécurisée
	keyBytes := make([]byte, 32)
	if _, err := rand.Read(keyBytes); err != nil {
		return nil, fmt.Errorf("failed to generate API key: %w", err)
	}

	key := hex.EncodeToString(keyBytes)
	id := fmt.Sprintf("ak_%s", hex.EncodeToString(keyBytes[:8]))

	apiKey := &APIKey{
		ID:          id,
		Key:         key,
		Name:        name,
		UserID:      userID,
		Permissions: permissions,
		CreatedAt:   time.Now(),
		ExpiresAt:   expiresAt,
		IsActive:    true,
		RateLimit: &RateLimit{
			RequestsPerMinute: 60,
			RequestsPerHour:   1000,
			BurstLimit:        10,
			WindowDuration:    time.Minute,
		},
	}

	m.keys[key] = apiKey
	return apiKey, nil
}

func (m *MemoryAPIKeyStore) UpdateAPIKey(apiKey *APIKey) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.keys[apiKey.Key]; !exists {
		return fmt.Errorf("API key not found")
	}

	m.keys[apiKey.Key] = apiKey
	return nil
}

func (m *MemoryAPIKeyStore) DeleteAPIKey(keyID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for key, apiKey := range m.keys {
		if apiKey.ID == keyID {
			delete(m.keys, key)
			return nil
		}
	}

	return fmt.Errorf("API key not found")
}

func (m *MemoryAPIKeyStore) ListAPIKeys(userID string) ([]*APIKey, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var result []*APIKey
	for _, apiKey := range m.keys {
		if apiKey.UserID == userID {
			// Créer une copie sans exposer la clé réelle
			keyCopy := *apiKey
			keyCopy.Key = "ak_" + keyCopy.Key[:8] + "..." // Masquer la clé
			result = append(result, &keyCopy)
		}
	}

	return result, nil
}

func (m *MemoryAPIKeyStore) RevokeAPIKey(keyID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, apiKey := range m.keys {
		if apiKey.ID == keyID {
			apiKey.IsActive = false
			return nil
		}
	}

	return fmt.Errorf("API key not found")
}

// RedisAPIKeyStore implémentation Redis (pour production)
type RedisAPIKeyStore struct {
	// TODO: Implémenter avec Redis client
	// redisClient redis.Client
	// keyPrefix   string
}

// NewRedisAPIKeyStore crée un store Redis
func NewRedisAPIKeyStore(redisAddr, keyPrefix string) APIKeyStore {
	// TODO: Implémenter Redis store
	panic("Redis API Key Store not implemented yet")
}
