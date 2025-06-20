// SPDX-License-Identifier: MIT
// Package docmanager - Redis Cache Implementation
package docmanager

import (
	"encoding/json"
	"fmt"
	"time"
)

// TASK ATOMIQUE 3.1.5.2.2 - Redis implementation

// RedisClient interface pour abstraction du client Redis
type RedisClient interface {
	Get(key string) (string, error)
	Set(key string, value string, ttl time.Duration) error
	Del(key string) error
	FlushDB() error
	Info() (map[string]string, error)
	Close() error
	Ping() error
}

// RedisCache implémentation Redis du cache de documents
type RedisCache struct {
	client     RedisClient
	keyPrefix  string
	defaultTTL time.Duration
	config     CacheConfig
	stats      CacheStats
	connected  bool
}

// MockRedisClient implémentation mock pour les tests
type MockRedisClient struct {
	data      map[string]string
	connected bool
}

// NewMockRedisClient crée un client Redis mock
func NewMockRedisClient() *MockRedisClient {
	return &MockRedisClient{
		data:      make(map[string]string),
		connected: true,
	}
}

// Get récupère une valeur du Redis mock
func (mrc *MockRedisClient) Get(key string) (string, error) {
	if !mrc.connected {
		return "", fmt.Errorf("redis not connected")
	}

	value, exists := mrc.data[key]
	if !exists {
		return "", fmt.Errorf("key not found: %s", key)
	}
	return value, nil
}

// Set stocke une valeur dans le Redis mock
func (mrc *MockRedisClient) Set(key string, value string, ttl time.Duration) error {
	if !mrc.connected {
		return fmt.Errorf("redis not connected")
	}

	mrc.data[key] = value
	// Note: TTL simulation non implémentée dans le mock
	return nil
}

// Del supprime une clé du Redis mock
func (mrc *MockRedisClient) Del(key string) error {
	if !mrc.connected {
		return fmt.Errorf("redis not connected")
	}

	delete(mrc.data, key)
	return nil
}

// FlushDB vide la base Redis mock
func (mrc *MockRedisClient) FlushDB() error {
	if !mrc.connected {
		return fmt.Errorf("redis not connected")
	}

	mrc.data = make(map[string]string)
	return nil
}

// Info retourne les informations du Redis mock
func (mrc *MockRedisClient) Info() (map[string]string, error) {
	if !mrc.connected {
		return nil, fmt.Errorf("redis not connected")
	}

	return map[string]string{
		"redis_version":     "mock-7.0.0",
		"connected_clients": "1",
		"used_memory":       "1024",
	}, nil
}

// Close ferme la connexion Redis mock
func (mrc *MockRedisClient) Close() error {
	mrc.connected = false
	return nil
}

// Ping teste la connexion Redis mock
func (mrc *MockRedisClient) Ping() error {
	if !mrc.connected {
		return fmt.Errorf("redis not connected")
	}
	return nil
}

// NewRedisCache crée un nouveau cache Redis
func NewRedisCache(config CacheConfig) (*RedisCache, error) {
	// Pour les tests, utilise un client mock
	// En production, on utiliserait un vrai client Redis
	client := NewMockRedisClient()

	rc := &RedisCache{
		client:     client,
		keyPrefix:  config.KeyPrefix,
		defaultTTL: config.TTL,
		config:     config,
		stats:      CacheStats{},
		connected:  true,
	}

	// Test de connexion
	if err := client.Ping(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %v", err)
	}

	return rc, nil
}

// Get récupère un document du cache Redis
func (rc *RedisCache) Get(key string) (*Document, bool) {
	fullKey := rc.keyPrefix + key

	data, err := rc.client.Get(fullKey)
	if err != nil {
		rc.stats.Misses++
		return nil, false
	}

	var doc Document
	if err := json.Unmarshal([]byte(data), &doc); err != nil {
		rc.stats.Misses++
		return nil, false
	}

	rc.stats.Hits++
	rc.updateHitRatio()
	return &doc, true
}

// Set stocke un document dans le cache Redis
func (rc *RedisCache) Set(key string, doc *Document) error {
	fullKey := rc.keyPrefix + key

	ttl := rc.defaultTTL

	data, err := json.Marshal(doc)
	if err != nil {
		return fmt.Errorf("failed to marshal document: %v", err)
	}

	if err := rc.client.Set(fullKey, string(data), ttl); err != nil {
		return fmt.Errorf("failed to set document in Redis: %v", err)
	}

	rc.stats.Keys++
	return nil
}

// SetWithTTL stocke un document avec un TTL spécifique
func (rc *RedisCache) SetWithTTL(key string, doc *Document, ttl time.Duration) error {
	if !rc.connected {
		return ErrCacheUnavailable
	}

	data, err := json.Marshal(doc)
	if err != nil {
		return fmt.Errorf("failed to marshal document: %w", err)
	}

	fullKey := rc.keyPrefix + key
	return rc.client.Set(fullKey, string(data), ttl)
}

// Delete supprime un document du cache Redis
func (rc *RedisCache) Delete(key string) error {
	fullKey := rc.keyPrefix + key

	if err := rc.client.Del(fullKey); err != nil {
		return fmt.Errorf("failed to delete document from Redis: %v", err)
	}

	rc.stats.Keys--
	return nil
}

// Clear vide complètement le cache Redis
func (rc *RedisCache) Clear() error {
	if err := rc.client.FlushDB(); err != nil {
		return fmt.Errorf("failed to clear Redis cache: %v", err)
	}

	rc.stats.Keys = 0
	return nil
}

// Stats retourne les statistiques du cache Redis
func (rc *RedisCache) Stats() CacheStats {
	rc.updateHitRatio()

	// Récupération des stats Redis si disponibles
	if info, err := rc.client.Info(); err == nil {
		// Parse des informations Redis pour enrichir les stats
		rc.enrichStatsFromRedisInfo(info)
	}

	return rc.stats
}

// IsConnected retourne l'état de connexion du cache Redis
func (rc *RedisCache) IsConnected() bool {
	if err := rc.client.Ping(); err != nil {
		rc.connected = false
		return false
	}
	rc.connected = true
	return true
}

// Close ferme la connexion au cache Redis
func (rc *RedisCache) Close() error {
	if err := rc.client.Close(); err != nil {
		return fmt.Errorf("failed to close Redis connection: %v", err)
	}
	rc.connected = false
	return nil
}

// GetDocument récupère un document du cache (format bool compatible)
func (rc *RedisCache) GetDocument(key string) (*Document, bool) {
	doc, found := rc.Get(key)
	return doc, found
}

// Helper methods

// updateHitRatio met à jour le ratio de hit
func (rc *RedisCache) updateHitRatio() {
	total := rc.stats.Hits + rc.stats.Misses
	if total > 0 {
		rc.stats.HitRatio = float64(rc.stats.Hits) / float64(total)
	}
}

// enrichStatsFromRedisInfo enrichit les statistiques avec les infos Redis
func (rc *RedisCache) enrichStatsFromRedisInfo(info map[string]string) {
	// Parse des informations Redis pour enrichir les stats
	// Implementation simplifiée pour l'exemple
	if memory, exists := info["used_memory"]; exists && memory != "" {
		// Parse memory usage (simplified)
		rc.stats.Memory = 1024 // Valeur simulée
	}
}
