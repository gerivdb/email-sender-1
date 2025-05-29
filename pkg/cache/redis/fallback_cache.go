package redis

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// LocalCache provides a fallback cache when Redis is unavailable
type LocalCache struct {
	data    map[string]localCacheItem
	mutex   sync.RWMutex
	maxSize int
	ttl     time.Duration
}

type localCacheItem struct {
	value     interface{}
	expiresAt time.Time
}

// NewLocalCache creates a new local cache with specified max size and default TTL
func NewLocalCache(maxSize int, defaultTTL time.Duration) *LocalCache {
	lc := &LocalCache{
		data:    make(map[string]localCacheItem),
		maxSize: maxSize,
		ttl:     defaultTTL,
	}

	// Start cleanup routine
	go lc.cleanupExpired()

	return lc
}

// Set stores a value in the local cache
func (lc *LocalCache) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	if ttl <= 0 {
		ttl = lc.ttl
	}

	lc.mutex.Lock()
	defer lc.mutex.Unlock()

	// If cache is full, remove oldest items
	if len(lc.data) >= lc.maxSize {
		lc.evictOldest()
	}

	lc.data[key] = localCacheItem{
		value:     value,
		expiresAt: time.Now().Add(ttl),
	}

	return nil
}

// Get retrieves a value from the local cache
func (lc *LocalCache) Get(ctx context.Context, key string) (interface{}, error) {
	lc.mutex.RLock()
	defer lc.mutex.RUnlock()

	item, exists := lc.data[key]
	if !exists {
		return nil, fmt.Errorf("key not found")
	}

	if time.Now().After(item.expiresAt) {
		// Item expired, remove it
		lc.mutex.RUnlock()
		lc.mutex.Lock()
		delete(lc.data, key)
		lc.mutex.Unlock()
		lc.mutex.RLock()
		return nil, fmt.Errorf("key expired")
	}

	return item.value, nil
}

// Delete removes a key from the local cache
func (lc *LocalCache) Delete(ctx context.Context, key string) error {
	lc.mutex.Lock()
	defer lc.mutex.Unlock()

	delete(lc.data, key)
	return nil
}

// evictOldest removes the oldest items when cache is full
func (lc *LocalCache) evictOldest() {
	// Simple eviction: remove expired items first
	now := time.Now()
	for key, item := range lc.data {
		if now.After(item.expiresAt) {
			delete(lc.data, key)
		}
	}

	// If still full, remove oldest by creation time (simplified)
	if len(lc.data) >= lc.maxSize {
		// Remove one arbitrary item
		for key := range lc.data {
			delete(lc.data, key)
			break
		}
	}
}

// cleanupExpired periodically removes expired items
func (lc *LocalCache) cleanupExpired() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		lc.mutex.Lock()
		now := time.Now()
		for key, item := range lc.data {
			if now.After(item.expiresAt) {
				delete(lc.data, key)
			}
		}
		lc.mutex.Unlock()
	}
}

// Stats returns cache statistics
func (lc *LocalCache) Stats() map[string]interface{} {
	lc.mutex.RLock()
	defer lc.mutex.RUnlock()

	return map[string]interface{}{
		"size":     len(lc.data),
		"max_size": lc.maxSize,
		"ttl":      lc.ttl,
	}
}

// HybridRedisClient combines Redis with local cache fallback
type HybridRedisClient struct {
	client          *redis.Client
	config          *RedisConfig
	errorHandler    *ErrorHandler
	circuitBreaker  *CircuitBreaker
	healthChecker   *HealthChecker
	localCache      *LocalCache
	fallbackEnabled bool
}

// NewHybridRedisClient creates a new hybrid client with Redis and local cache fallback
func NewHybridRedisClient(config *RedisConfig) (*HybridRedisClient, error) {
	var client *redis.Client
	var errorHandler *ErrorHandler
	var circuitBreaker *CircuitBreaker
	var healthChecker *HealthChecker

	// Try to create Redis client
	if config != nil {
		if err := config.Validate(); err == nil {
			opts := config.ToRedisOptions()
			client = redis.NewClient(opts)

			// Test connection
			ctx, cancel := context.WithTimeout(context.Background(), config.DialTimeout)
			defer cancel()

			if err := client.Ping(ctx).Err(); err != nil {
				client.Close()
				client = nil
			} else {
				// Create supporting components
				errorHandler = NewErrorHandler(nil)
				circuitBreaker = NewCircuitBreaker(DefaultCircuitBreakerConfig(), nil)
				healthChecker = NewHealthChecker(client, config.HealthCheckInterval, 5*time.Second, nil)
				healthChecker.Start()
			}
		}
	}

	localCache := NewLocalCache(1000, 5*time.Minute) // 1000 items, 5 min TTL

	return &HybridRedisClient{
		client:          client,
		config:          config,
		errorHandler:    errorHandler,
		circuitBreaker:  circuitBreaker,
		healthChecker:   healthChecker,
		localCache:      localCache,
		fallbackEnabled: true,
	}, nil
}

// Set stores a value, trying Redis first, then local cache
func (hrc *HybridRedisClient) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	// Try Redis first
	if hrc.client != nil && hrc.IsRedisHealthy() {
		err := hrc.client.Set(ctx, key, value, ttl).Err()
		if err == nil {
			return nil
		}
		// Handle error through error handler
		if hrc.errorHandler != nil {
			hrc.errorHandler.Handle(err)
		}
	}

	// Fallback to local cache if enabled
	if hrc.fallbackEnabled {
		return hrc.localCache.Set(ctx, key, value, ttl)
	}

	return fmt.Errorf("both Redis and local cache unavailable")
}

// Get retrieves a value, trying Redis first, then local cache
func (hrc *HybridRedisClient) Get(ctx context.Context, key string) (interface{}, error) {
	// Try Redis first
	if hrc.client != nil && hrc.IsRedisHealthy() {
		result, err := hrc.client.Get(ctx, key).Result()
		if err == nil {
			return result, nil
		}
		// Handle error through error handler
		if hrc.errorHandler != nil {
			hrc.errorHandler.Handle(err)
		}
	}

	// Fallback to local cache if enabled
	if hrc.fallbackEnabled {
		return hrc.localCache.Get(ctx, key)
	}

	return nil, fmt.Errorf("both Redis and local cache unavailable")
}

// Delete removes a key from both Redis and local cache
func (hrc *HybridRedisClient) Delete(ctx context.Context, key string) error {
	var errs []error

	// Try Redis
	if hrc.client != nil {
		if err := hrc.client.Del(ctx, key).Err(); err != nil {
			errs = append(errs, err)
			if hrc.errorHandler != nil {
				hrc.errorHandler.Handle(err)
			}
		}
	}

	// Try local cache
	if hrc.fallbackEnabled {
		if err := hrc.localCache.Delete(ctx, key); err != nil {
			errs = append(errs, err)
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("delete errors: %v", errs)
	}

	return nil
}

// IsRedisHealthy returns true if Redis is available and healthy
func (hrc *HybridRedisClient) IsRedisHealthy() bool {
	if hrc.healthChecker != nil {
		return hrc.healthChecker.IsHealthy()
	}
	if hrc.client != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		return hrc.client.Ping(ctx).Err() == nil
	}
	return false
}

// GetStats returns statistics for both Redis and local cache
func (hrc *HybridRedisClient) GetStats() map[string]interface{} {
	stats := make(map[string]interface{})

	if hrc.client != nil {
		poolStats := hrc.client.PoolStats()
		stats["redis"] = map[string]interface{}{
			"pool": map[string]interface{}{
				"hits":        poolStats.Hits,
				"misses":      poolStats.Misses,
				"timeouts":    poolStats.Timeouts,
				"total_conns": poolStats.TotalConns,
				"idle_conns":  poolStats.IdleConns,
				"stale_conns": poolStats.StaleConns,
			},
		}
		stats["redis_healthy"] = hrc.IsRedisHealthy()

		if hrc.circuitBreaker != nil {
			stats["circuit_breaker"] = hrc.circuitBreaker.Stats()
		}

		if hrc.healthChecker != nil {
			stats["health"] = map[string]interface{}{
				"is_healthy":    hrc.healthChecker.IsHealthy(),
				"last_check":    hrc.healthChecker.LastCheck(),
				"check_count":   hrc.healthChecker.GetCheckCount(),
				"failure_count": hrc.healthChecker.GetFailureCount(),
			}
		}
	} else {
		stats["redis"] = "unavailable"
		stats["redis_healthy"] = false
	}

	stats["local_cache"] = hrc.localCache.Stats()
	stats["fallback_enabled"] = hrc.fallbackEnabled

	return stats
}

// Close closes both Redis and local cache
func (hrc *HybridRedisClient) Close() error {
	if hrc.healthChecker != nil {
		hrc.healthChecker.Stop()
	}
	if hrc.client != nil {
		return hrc.client.Close()
	}
	return nil
}
