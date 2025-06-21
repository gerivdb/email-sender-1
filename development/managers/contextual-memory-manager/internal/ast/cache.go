// internal/ast/cache.go
package ast

import (
	"context"
	"sync"
	"time"

	"github.com/contextual-memory-manager/interfaces"
)

type ASTCache struct {
	entries       map[string]*cacheEntry
	maxSize       int
	ttl           time.Duration
	mu            sync.RWMutex
	stopCh        chan struct{}
	cleanupTicker *time.Ticker
	stats         *cacheStats
}

type cacheEntry struct {
	data        *interfaces.ASTAnalysisResult
	timestamp   time.Time
	accessed    time.Time
	accessCount int64
}

type cacheStats struct {
	hits         int64
	misses       int64
	evictions    int64
	totalEntries int64
	mu           sync.RWMutex
}

func NewASTCache(maxSize int, ttl time.Duration) *ASTCache {
	return &ASTCache{
		entries: make(map[string]*cacheEntry),
		maxSize: maxSize,
		ttl:     ttl,
		stopCh:  make(chan struct{}),
		stats:   &cacheStats{},
	}
}

func (c *ASTCache) Start(ctx context.Context) {
	c.cleanupTicker = time.NewTicker(c.ttl / 2)

	go func() {
		for {
			select {
			case <-c.cleanupTicker.C:
				c.cleanup()
			case <-c.stopCh:
				return
			case <-ctx.Done():
				return
			}
		}
	}()
}

func (c *ASTCache) Stop() {
	close(c.stopCh)
	if c.cleanupTicker != nil {
		c.cleanupTicker.Stop()
	}
}

func (c *ASTCache) Get(key string) (*interfaces.ASTAnalysisResult, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, exists := c.entries[key]
	if !exists {
		c.stats.mu.Lock()
		c.stats.misses++
		c.stats.mu.Unlock()
		return nil, false
	}

	// Vérifier si l'entrée est expirée
	if time.Since(entry.timestamp) > c.ttl {
		c.mu.RUnlock()
		c.mu.Lock()
		delete(c.entries, key)
		c.stats.evictions++
		c.mu.Unlock()
		c.mu.RLock()

		c.stats.mu.Lock()
		c.stats.misses++
		c.stats.mu.Unlock()
		return nil, false
	}

	// Mettre à jour les statistiques d'accès
	entry.accessed = time.Now()
	entry.accessCount++

	c.stats.mu.Lock()
	c.stats.hits++
	c.stats.mu.Unlock()

	return entry.data, true
}

func (c *ASTCache) Set(key string, data *interfaces.ASTAnalysisResult) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Vérifier si on dépasse la taille maximale
	if len(c.entries) >= c.maxSize {
		c.evictLeastRecentlyUsed()
	}

	c.entries[key] = &cacheEntry{
		data:        data,
		timestamp:   time.Now(),
		accessed:    time.Now(),
		accessCount: 1,
	}

	c.stats.mu.Lock()
	c.stats.totalEntries++
	c.stats.mu.Unlock()
}

func (c *ASTCache) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.entries = make(map[string]*cacheEntry)

	c.stats.mu.Lock()
	c.stats.evictions += c.stats.totalEntries
	c.stats.totalEntries = 0
	c.stats.mu.Unlock()
}

func (c *ASTCache) Size() int {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return len(c.entries)
}

func (c *ASTCache) GetStats() *interfaces.ASTCacheStats {
	c.stats.mu.RLock()
	defer c.stats.mu.RUnlock()

	c.mu.RLock()
	defer c.mu.RUnlock()

	totalRequests := c.stats.hits + c.stats.misses
	hitRate := 0.0
	missRate := 0.0

	if totalRequests > 0 {
		hitRate = float64(c.stats.hits) / float64(totalRequests)
		missRate = float64(c.stats.misses) / float64(totalRequests)
	}

	// Trouver les entrées les plus anciennes et les plus récentes
	var oldest, newest time.Time
	first := true

	for _, entry := range c.entries {
		if first {
			oldest = entry.timestamp
			newest = entry.timestamp
			first = false
		} else {
			if entry.timestamp.Before(oldest) {
				oldest = entry.timestamp
			}
			if entry.timestamp.After(newest) {
				newest = entry.timestamp
			}
		}
	}

	return &interfaces.ASTCacheStats{
		TotalEntries: len(c.entries),
		HitRate:      hitRate,
		MissRate:     missRate,
		MemoryUsage:  c.estimateMemoryUsage(),
		OldestEntry:  oldest,
		NewestEntry:  newest,
	}
}

func (c *ASTCache) cleanup() {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	keysToDelete := make([]string, 0)

	for key, entry := range c.entries {
		if now.Sub(entry.timestamp) > c.ttl {
			keysToDelete = append(keysToDelete, key)
		}
	}

	for _, key := range keysToDelete {
		delete(c.entries, key)
		c.stats.evictions++
	}
}

func (c *ASTCache) evictLeastRecentlyUsed() {
	var lruKey string
	var lruTime time.Time
	first := true

	for key, entry := range c.entries {
		if first {
			lruKey = key
			lruTime = entry.accessed
			first = false
		} else if entry.accessed.Before(lruTime) {
			lruKey = key
			lruTime = entry.accessed
		}
	}

	if lruKey != "" {
		delete(c.entries, lruKey)
		c.stats.evictions++
	}
}

func (c *ASTCache) estimateMemoryUsage() int64 {
	// Estimation approximative de l'usage mémoire
	baseSize := int64(len(c.entries)) * 1000 // ~1KB par entrée de base

	for _, entry := range c.entries {
		// Estimation basée sur le nombre d'éléments dans l'analyse
		entrySize := int64(len(entry.data.Functions)*100 +
			len(entry.data.Types)*100 +
			len(entry.data.Variables)*50 +
			len(entry.data.Constants)*50 +
			len(entry.data.Dependencies)*50 +
			len(entry.data.Imports)*30)
		baseSize += entrySize
	}

	return baseSize
}
