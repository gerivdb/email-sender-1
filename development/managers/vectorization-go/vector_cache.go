package vectorization

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// VectorCache implémente un cache LRU pour les résultats de recherche vectorielle
type VectorCache struct {
	mu       sync.RWMutex
	cache    map[string]*CacheEntry
	lruList  *LRUNode
	capacity int
	ttl      time.Duration
	logger   *zap.Logger
	metrics  CacheMetrics
}

// CacheEntry représente une entrée dans le cache
type CacheEntry struct {
	Key         string         `json:"key"`
	Results     []SearchResult `json:"results"`
	CreatedAt   time.Time      `json:"created_at"`
	LastAccess  time.Time      `json:"last_access"`
	AccessCount int64          `json:"access_count"`
	node        *LRUNode
}

// LRUNode représente un nœud dans la liste LRU
type LRUNode struct {
	Key  string
	Prev *LRUNode
	Next *LRUNode
}

// CacheMetrics contient les métriques du cache
type CacheMetrics struct {
	Hits        int64         `json:"hits"`
	Misses      int64         `json:"misses"`
	Evictions   int64         `json:"evictions"`
	TotalItems  int           `json:"total_items"`
	HitRatio    float64       `json:"hit_ratio"`
	AvgLoadTime time.Duration `json:"avg_load_time"`
}

// NewVectorCache crée un nouveau cache vectoriel
func NewVectorCache(capacity int, ttl time.Duration, logger *zap.Logger) *VectorCache {
	// Créer les nœuds de tête et queue pour la liste LRU
	head := &LRUNode{Key: "head"}
	tail := &LRUNode{Key: "tail"}
	head.Next = tail
	tail.Prev = head

	cache := &VectorCache{
		cache:    make(map[string]*CacheEntry, capacity),
		lruList:  head,
		capacity: capacity,
		ttl:      ttl,
		logger:   logger,
		metrics: CacheMetrics{
			Hits:       0,
			Misses:     0,
			Evictions:  0,
			TotalItems: 0,
			HitRatio:   0.0,
		},
	}

	// Démarrer la routine de nettoyage périodique
	go cache.cleanupRoutine()

	logger.Info("Vector cache initialized",
		zap.Int("capacity", capacity),
		zap.Duration("ttl", ttl))

	return cache
}

// generateCacheKey génère une clé de cache pour une requête vectorielle
func (vc *VectorCache) generateCacheKey(query Vector, topK int) string {
	// Créer un hash de la requête vectorielle
	hash := md5.New()

	// Ajouter l'ID de la requête
	hash.Write([]byte(query.ID))

	// Ajouter les valeurs du vecteur (simplifié pour la démo)
	for _, val := range query.Values {
		hash.Write([]byte(fmt.Sprintf("%.6f", val)))
	}

	// Ajouter topK
	hash.Write([]byte(fmt.Sprintf("%d", topK)))

	return hex.EncodeToString(hash.Sum(nil))
}

// Get récupère les résultats du cache
func (vc *VectorCache) Get(ctx context.Context, query Vector, topK int) ([]SearchResult, bool) {
	key := vc.generateCacheKey(query, topK)

	vc.mu.RLock()
	entry, exists := vc.cache[key]
	vc.mu.RUnlock()

	if !exists {
		vc.mu.Lock()
		vc.metrics.Misses++
		vc.mu.Unlock()

		vc.logger.Debug("Cache miss", zap.String("key", key))
		return nil, false
	}

	// Vérifier si l'entrée n'a pas expiré
	if time.Since(entry.CreatedAt) > vc.ttl {
		vc.mu.Lock()
		delete(vc.cache, key)
		vc.removeLRUNode(entry.node)
		vc.metrics.Misses++
		vc.metrics.TotalItems = len(vc.cache)
		vc.mu.Unlock()

		vc.logger.Debug("Cache entry expired", zap.String("key", key))
		return nil, false
	}

	// Mettre à jour les statistiques d'accès
	vc.mu.Lock()
	entry.LastAccess = time.Now()
	entry.AccessCount++
	vc.metrics.Hits++

	// Déplacer en tête de la liste LRU
	vc.moveToHead(entry.node)

	// Mettre à jour le ratio de hit
	total := vc.metrics.Hits + vc.metrics.Misses
	if total > 0 {
		vc.metrics.HitRatio = float64(vc.metrics.Hits) / float64(total)
	}
	vc.mu.Unlock()

	vc.logger.Debug("Cache hit",
		zap.String("key", key),
		zap.Int64("access_count", entry.AccessCount))

	return entry.Results, true
}

// Put stocke les résultats dans le cache
func (vc *VectorCache) Put(ctx context.Context, query Vector, topK int, results []SearchResult) {
	key := vc.generateCacheKey(query, topK)

	vc.mu.Lock()
	defer vc.mu.Unlock()

	// Vérifier si l'entrée existe déjà
	if entry, exists := vc.cache[key]; exists {
		// Mettre à jour l'entrée existante
		entry.Results = results
		entry.LastAccess = time.Now()
		entry.AccessCount++
		vc.moveToHead(entry.node)
		return
	}

	// Vérifier si le cache est plein
	if len(vc.cache) >= vc.capacity {
		vc.evictLRU()
	}

	// Créer nouvelle entrée
	node := &LRUNode{Key: key}
	entry := &CacheEntry{
		Key:         key,
		Results:     results,
		CreatedAt:   time.Now(),
		LastAccess:  time.Now(),
		AccessCount: 1,
		node:        node,
	}

	vc.cache[key] = entry
	vc.addToHead(node)
	vc.metrics.TotalItems = len(vc.cache)

	vc.logger.Debug("Cache entry added",
		zap.String("key", key),
		zap.Int("results_count", len(results)))
}

// evictLRU supprime l'entrée la moins récemment utilisée
func (vc *VectorCache) evictLRU() {
	tail := vc.lruList.Next
	for tail.Key != "tail" {
		tail = tail.Next
	}

	lastNode := tail.Prev
	if lastNode.Key != "head" {
		delete(vc.cache, lastNode.Key)
		vc.removeLRUNode(lastNode)
		vc.metrics.Evictions++

		vc.logger.Debug("Cache entry evicted", zap.String("key", lastNode.Key))
	}
}

// addToHead ajoute un nœud en tête de la liste LRU
func (vc *VectorCache) addToHead(node *LRUNode) {
	node.Prev = vc.lruList
	node.Next = vc.lruList.Next
	vc.lruList.Next.Prev = node
	vc.lruList.Next = node
}

// removeLRUNode supprime un nœud de la liste LRU
func (vc *VectorCache) removeLRUNode(node *LRUNode) {
	node.Prev.Next = node.Next
	node.Next.Prev = node.Prev
}

// moveToHead déplace un nœud en tête de la liste LRU
func (vc *VectorCache) moveToHead(node *LRUNode) {
	vc.removeLRUNode(node)
	vc.addToHead(node)
}

// cleanupRoutine nettoie périodiquement les entrées expirées
func (vc *VectorCache) cleanupRoutine() {
	ticker := time.NewTicker(time.Minute * 5) // Nettoyage toutes les 5 minutes
	defer ticker.Stop()

	for range ticker.C {
		vc.cleanupExpired()
	}
}

// cleanupExpired supprime les entrées expirées
func (vc *VectorCache) cleanupExpired() {
	vc.mu.Lock()
	defer vc.mu.Unlock()

	now := time.Now()
	expiredKeys := make([]string, 0)

	for key, entry := range vc.cache {
		if now.Sub(entry.CreatedAt) > vc.ttl {
			expiredKeys = append(expiredKeys, key)
		}
	}

	for _, key := range expiredKeys {
		entry := vc.cache[key]
		delete(vc.cache, key)
		vc.removeLRUNode(entry.node)
	}

	if len(expiredKeys) > 0 {
		vc.metrics.TotalItems = len(vc.cache)
		vc.logger.Info("Expired cache entries cleaned up",
			zap.Int("count", len(expiredKeys)))
	}
}

// GetMetrics retourne les métriques du cache
func (vc *VectorCache) GetMetrics() CacheMetrics {
	vc.mu.RLock()
	defer vc.mu.RUnlock()

	metrics := vc.metrics
	metrics.TotalItems = len(vc.cache)

	total := metrics.Hits + metrics.Misses
	if total > 0 {
		metrics.HitRatio = float64(metrics.Hits) / float64(total)
	}

	return metrics
}

// Clear vide complètement le cache
func (vc *VectorCache) Clear() {
	vc.mu.Lock()
	defer vc.mu.Unlock()

	vc.cache = make(map[string]*CacheEntry, vc.capacity)

	// Réinitialiser la liste LRU
	head := &LRUNode{Key: "head"}
	tail := &LRUNode{Key: "tail"}
	head.Next = tail
	tail.Prev = head
	vc.lruList = head

	vc.metrics.TotalItems = 0

	vc.logger.Info("Cache cleared")
}
