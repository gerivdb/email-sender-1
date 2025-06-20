// SPDX-License-Identifier: MIT
// Package docmanager - Cache Interface Before Redis Implementation
package docmanager

import (
	"time"
)

// TASK ATOMIQUE 3.1.5.2.1 - Cache abstraction implementation

// CacheStats statistiques du cache
type CacheStats struct {
	Hits          int64
	Misses        int64
	Keys          int64
	Memory        int64
	HitRatio      float64
	EvictionCount int64
	LastEviction  time.Time
}

// DocumentCache interface pour le cache de documents
// Abstraction complete avant Redis implementation
type DocumentCache interface {
	Get(key string) (*Document, bool)
	Set(key string, doc *Document) error // Harmonisé avec interface Cache
	SetWithTTL(key string, doc *Document, ttl time.Duration) error
	Delete(key string) error
	Clear() error
	Stats() CacheStats
	IsConnected() bool
	Close() error
}

// TASK ATOMIQUE 3.1.5.2.1 - Validation: DocManager uses interface, not concrete Redis

// CacheConfig configuration pour le cache
type CacheConfig struct {
	Provider  string // "memory", "redis", "file"
	TTL       time.Duration
	MaxSize   int64
	KeyPrefix string
	Host      string
	Port      int
	Password  string
	Database  int
	PoolSize  int
}

// CacheProvider factory pour créer des instances de cache
type CacheProvider interface {
	CreateCache(config CacheConfig) (DocumentCache, error)
	SupportedProviders() []string
}

// DefaultCacheProvider implémentation par défaut du factory
type DefaultCacheProvider struct {
	providers map[string]func(CacheConfig) (DocumentCache, error)
}

// NewDefaultCacheProvider crée un nouveau provider par défaut
func NewDefaultCacheProvider() *DefaultCacheProvider {
	provider := &DefaultCacheProvider{
		providers: make(map[string]func(CacheConfig) (DocumentCache, error)),
	}

	// Enregistrement des providers disponibles
	provider.RegisterProvider("memory", func(config CacheConfig) (DocumentCache, error) {
		return NewMemoryCache(config), nil
	})

	provider.RegisterProvider("redis", func(config CacheConfig) (DocumentCache, error) {
		return NewRedisCache(config)
	})

	return provider
}

// RegisterProvider enregistre un nouveau provider de cache
func (dcp *DefaultCacheProvider) RegisterProvider(name string, factory func(CacheConfig) (DocumentCache, error)) {
	dcp.providers[name] = factory
}

// CreateCache crée une instance de cache selon la configuration
func (dcp *DefaultCacheProvider) CreateCache(config CacheConfig) (DocumentCache, error) {
	factory, exists := dcp.providers[config.Provider]
	if !exists {
		// Fallback to memory cache
		return NewMemoryCache(config), nil
	}
	return factory(config)
}

// SupportedProviders retourne la liste des providers supportés
func (dcp *DefaultCacheProvider) SupportedProviders() []string {
	providers := make([]string, 0, len(dcp.providers))
	for name := range dcp.providers {
		providers = append(providers, name)
	}
	return providers
}

// MemoryCache implémentation en mémoire du cache
type MemoryCache struct {
	data      map[string]*CacheEntry
	config    CacheConfig
	stats     CacheStats
	connected bool
}

// CacheEntry entrée dans le cache avec TTL
type CacheEntry struct {
	Document  *Document
	CreatedAt time.Time
	TTL       time.Duration
}

// NewMemoryCache crée un nouveau cache mémoire
func NewMemoryCache(config CacheConfig) *MemoryCache {
	return &MemoryCache{
		data:      make(map[string]*CacheEntry),
		config:    config,
		stats:     CacheStats{},
		connected: true,
	}
}

// Get récupère un document du cache mémoire
func (mc *MemoryCache) Get(key string) (*Document, bool) {
	entry, exists := mc.data[key]
	if !exists {
		mc.stats.Misses++
		return nil, false
	}

	// Vérification TTL
	if mc.isExpired(entry) {
		delete(mc.data, key)
		mc.stats.Misses++
		return nil, false
	}

	mc.stats.Hits++
	mc.updateHitRatio()
	return entry.Document, true
}

// Set stocke un document dans le cache mémoire
func (mc *MemoryCache) Set(key string, doc *Document) error {
	ttl := mc.config.TTL

	entry := &CacheEntry{
		Document:  doc,
		CreatedAt: time.Now(),
		TTL:       ttl,
	}

	mc.data[key] = entry
	mc.stats.Keys = int64(len(mc.data))
	return nil
}

// SetWithTTL stocke un document avec un TTL spécifique
func (mc *MemoryCache) SetWithTTL(key string, doc *Document, ttl time.Duration) error {
	mc.data[key] = &CacheEntry{
		Document:  doc,
		CreatedAt: time.Now(),
		TTL:       ttl,
	}
	mc.stats.Keys = int64(len(mc.data))
	return nil
}

// Delete supprime un document du cache mémoire
func (mc *MemoryCache) Delete(key string) error {
	delete(mc.data, key)
	mc.stats.Keys = int64(len(mc.data))
	return nil
}

// Clear vide complètement le cache mémoire
func (mc *MemoryCache) Clear() error {
	mc.data = make(map[string]*CacheEntry)
	mc.stats.Keys = 0
	return nil
}

// Stats retourne les statistiques du cache mémoire
func (mc *MemoryCache) Stats() CacheStats {
	mc.updateHitRatio()
	mc.stats.Keys = int64(len(mc.data))
	return mc.stats
}

// IsConnected retourne l'état de connexion du cache mémoire
func (mc *MemoryCache) IsConnected() bool {
	return mc.connected
}

// Close ferme le cache mémoire
func (mc *MemoryCache) Close() error {
	mc.connected = false
	mc.data = nil
	return nil
}

// Helper methods

// isExpired vérifie si une entrée est expirée
func (mc *MemoryCache) isExpired(entry *CacheEntry) bool {
	if entry.TTL <= 0 {
		return false // Pas d'expiration
	}
	return time.Since(entry.CreatedAt) > entry.TTL
}

// updateHitRatio met à jour le ratio de hit
func (mc *MemoryCache) updateHitRatio() {
	total := mc.stats.Hits + mc.stats.Misses
	if total > 0 {
		mc.stats.HitRatio = float64(mc.stats.Hits) / float64(total)
	}
}

// GetDocument récupère un document du cache (format bool compatible)
func (mc *MemoryCache) GetDocument(key string) (*Document, bool) {
	entry, exists := mc.data[key]
	if !exists {
		mc.stats.Misses++
		return nil, false
	}

	// Vérification TTL
	if mc.isExpired(entry) {
		delete(mc.data, key)
		mc.stats.Misses++
		return nil, false
	}

	mc.stats.Hits++
	return entry.Document, true
}
