// SPDX-License-Identifier: MIT
// Package docmanager - Cache Strategy Plugin System
package docmanager

import (
	"fmt"
	"sync"
	"time"
)

// TASK ATOMIQUE 3.1.2.2 - Cache Strategy Plugin System
// MICRO-TASK 3.1.2.2.2 - Strategy factory pattern

// CacheStrategyFactory fabrique pour les stratégies de cache
type CacheStrategyFactory struct {
	strategies      map[string]func() CacheStrategy
	defaultStrategy CacheStrategy
	mu              sync.RWMutex
}

// NewCacheStrategyFactory crée une nouvelle fabrique de stratégies
func NewCacheStrategyFactory() *CacheStrategyFactory {
	factory := &CacheStrategyFactory{
		strategies: make(map[string]func() CacheStrategy),
		mu:         sync.RWMutex{},
	}

	// Enregistrer les stratégies par défaut
	factory.RegisterStrategy("lru", func() CacheStrategy { return &LRUCacheStrategy{} })
	factory.RegisterStrategy("lfu", func() CacheStrategy { return &LFUCacheStrategy{} })
	factory.RegisterStrategy("ttl", func() CacheStrategy { return &TTLCacheStrategy{} })
	factory.RegisterStrategy("size_based", func() CacheStrategy { return &SizeBasedCacheStrategy{} })

	return factory
}

// RegisterStrategy enregistre une nouvelle stratégie
func (csf *CacheStrategyFactory) RegisterStrategy(name string, creator func() CacheStrategy) {
	csf.mu.Lock()
	defer csf.mu.Unlock()
	csf.strategies[name] = creator
}

// CreateStrategy crée une stratégie par son nom
func (csf *CacheStrategyFactory) CreateStrategy(name string) (CacheStrategy, error) {
	csf.mu.RLock()
	defer csf.mu.RUnlock()

	creator, exists := csf.strategies[name]
	if !exists {
		return nil, fmt.Errorf("strategy %s not found", name)
	}

	return creator(), nil
}

// ListStrategies retourne les noms des stratégies disponibles
func (csf *CacheStrategyFactory) ListStrategies() []string {
	csf.mu.RLock()
	defer csf.mu.RUnlock()

	names := make([]string, 0, len(csf.strategies))
	for name := range csf.strategies {
		names = append(names, name)
	}
	return names
}

// SetDefaultStrategy définit la stratégie par défaut
func (csf *CacheStrategyFactory) SetDefaultStrategy(strategy CacheStrategy) {
	csf.mu.Lock()
	defer csf.mu.Unlock()
	csf.defaultStrategy = strategy
}

// GetDefaultStrategy retourne la stratégie par défaut
func (csf *CacheStrategyFactory) GetDefaultStrategy() CacheStrategy {
	csf.mu.RLock()
	defer csf.mu.RUnlock()
	if csf.defaultStrategy == nil {
		return &LRUCacheStrategy{} // Stratégie par défaut
	}
	return csf.defaultStrategy
}

// IMPLEMENTATIONS CONCRÈTES DES STRATÉGIES

// LRUCacheStrategy stratégie Least Recently Used
type LRUCacheStrategy struct{}

func (lru *LRUCacheStrategy) ShouldCache(doc *Document) bool {
	return doc != nil && len(doc.Content) > 0
}

func (lru *LRUCacheStrategy) CalculateTTL(doc *Document) time.Duration {
	// TTL basé sur la taille du document
	baseTime := 1 * time.Hour
	if len(doc.Content) > 10000 {
		return baseTime * 2 // Documents plus gros restent plus longtemps
	}
	return baseTime
}

func (lru *LRUCacheStrategy) EvictionPolicy() EvictionType {
	return LRU
}

func (lru *LRUCacheStrategy) OnCacheHit(key string) {
	// Mettre à jour timestamp pour LRU
}

func (lru *LRUCacheStrategy) OnCacheMiss(key string) {
	// Log miss pour statistiques
}

// LFUCacheStrategy stratégie Least Frequently Used
type LFUCacheStrategy struct{}

func (lfu *LFUCacheStrategy) ShouldCache(doc *Document) bool {
	return doc != nil && doc.Path != ""
}

func (lfu *LFUCacheStrategy) CalculateTTL(doc *Document) time.Duration {
	return 2 * time.Hour // TTL fixe pour LFU
}

func (lfu *LFUCacheStrategy) EvictionPolicy() EvictionType {
	return LFU
}

func (lfu *LFUCacheStrategy) OnCacheHit(key string) {
	// Incrémenter compteur fréquence
}

func (lfu *LFUCacheStrategy) OnCacheMiss(key string) {
	// Initialiser compteur à 1
}

// TTLCacheStrategy stratégie basée sur Time To Live
type TTLCacheStrategy struct{}

func (ttl *TTLCacheStrategy) ShouldCache(doc *Document) bool {
	return doc != nil
}

func (ttl *TTLCacheStrategy) CalculateTTL(doc *Document) time.Duration {
	// TTL basé sur la version du document (simulé)
	if doc.Version > 5 {
		return 4 * time.Hour // Document avec beaucoup de versions = cache plus longtemps
	}
	return 1 * time.Hour
}

func (ttl *TTLCacheStrategy) EvictionPolicy() EvictionType {
	return TTL_BASED
}

func (ttl *TTLCacheStrategy) OnCacheHit(key string) {}

func (ttl *TTLCacheStrategy) OnCacheMiss(key string) {}

// SizeBasedCacheStrategy stratégie basée sur la taille
type SizeBasedCacheStrategy struct{}

func (sbs *SizeBasedCacheStrategy) ShouldCache(doc *Document) bool {
	// Ne cache que les documents de taille raisonnable
	return doc != nil && len(doc.Content) > 100 && len(doc.Content) < 50000
}

func (sbs *SizeBasedCacheStrategy) CalculateTTL(doc *Document) time.Duration {
	size := len(doc.Content)
	if size < 1000 {
		return 30 * time.Minute // Petits docs = TTL court
	} else if size < 10000 {
		return 1 * time.Hour
	}
	return 3 * time.Hour // Gros docs = TTL long
}

func (sbs *SizeBasedCacheStrategy) EvictionPolicy() EvictionType {
	return CUSTOM
}

func (sbs *SizeBasedCacheStrategy) OnCacheHit(key string) {}

func (sbs *SizeBasedCacheStrategy) OnCacheMiss(key string) {}
