package main

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/go-redis/redis/v8"
	"go.uber.org/zap"
)

// CacheManager manages Redis and in-memory caching
type CacheManager struct {
	redis    *redis.Client
	memory   *MemoryCache
	strategy CacheStrategy
	config   *CacheConfig
	logger   *zap.Logger
	mu       sync.RWMutex
}

// CacheConfig holds cache configuration
type CacheConfig struct {
	Redis  *RedisConfig  `yaml:"redis"`
	Memory *MemoryConfig `yaml:"memory"`
	Strategy *StrategyConfig `yaml:"strategy"`
}

// RedisConfig holds Redis connection settings
type RedisConfig struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Password string `yaml:"password"`
	DB       int    `yaml:"db"`
	PoolSize int    `yaml:"pool_size"`
	Timeout  int    `yaml:"timeout"`
}

// MemoryConfig holds in-memory cache settings
type MemoryConfig struct {
	MaxSize    int           `yaml:"max_size"`
	DefaultTTL time.Duration `yaml:"default_ttl"`
	CleanupInterval time.Duration `yaml:"cleanup_interval"`
}

// StrategyConfig holds caching strategy settings
type StrategyConfig struct {
	Type       string        `yaml:"type"` // "multi-level", "redis-only", "memory-only"
	MemoryTTL  time.Duration `yaml:"memory_ttl"`
	RedisTTL   time.Duration `yaml:"redis_ttl"`
	Fallback   bool          `yaml:"fallback"`
}

// CacheStrategy defines caching behavior
type CacheStrategy struct {
	Type      string
	MemoryTTL time.Duration
	RedisTTL  time.Duration
	Fallback  bool
}

// MemoryCache implements an in-memory cache with TTL
type MemoryCache struct {
	items   map[string]*CacheItem
	maxSize int
	mu      sync.RWMutex
	ticker  *time.Ticker
	done    chan struct{}
}

// CacheItem represents a cached item with metadata
type CacheItem struct {
	Value     interface{}
	ExpiresAt time.Time
	AccessCount int64
	LastAccess  time.Time
}

// CacheResult represents a cache operation result
type CacheResult struct {
	Value  interface{}
	Hit    bool
	Source string // "memory", "redis", "miss"
}

// NewCacheManager creates a new cache manager
func NewCacheManager(config *CacheConfig) *CacheManager {
	logger, _ := zap.NewProduction()
	
	cm := &CacheManager{
		config: config,
		logger: logger,
	}
	
	// Initialize strategy
	if config.Strategy != nil {
		cm.strategy = CacheStrategy{
			Type:      config.Strategy.Type,
			MemoryTTL: config.Strategy.MemoryTTL,
			RedisTTL:  config.Strategy.RedisTTL,
			Fallback:  config.Strategy.Fallback,
		}
	} else {
		// Default strategy
		cm.strategy = CacheStrategy{
			Type:      "multi-level",
			MemoryTTL: 5 * time.Minute,
			RedisTTL:  30 * time.Minute,
			Fallback:  true,
		}
	}
	
	return cm
}

// Start initializes the cache manager
func (cm *CacheManager) Start(ctx context.Context) error {
	cm.logger.Info("Starting Cache Manager")
	
	// Initialize Redis client
	if err := cm.initializeRedis(); err != nil {
		if !cm.strategy.Fallback {
			return fmt.Errorf("failed to initialize Redis: %w", err)
		}
		cm.logger.Warn("Redis initialization failed, continuing with memory-only caching", zap.Error(err))
	}
	
	// Initialize memory cache
	cm.initializeMemoryCache()
	
	cm.logger.Info("Cache Manager started successfully")
	return nil
}

// Stop shuts down the cache manager
func (cm *CacheManager) Stop(ctx context.Context) error {
	cm.logger.Info("Stopping Cache Manager")
	
	// Close Redis connection
	if cm.redis != nil {
		if err := cm.redis.Close(); err != nil {
			cm.logger.Error("Failed to close Redis connection", zap.Error(err))
		}
	}
	
	// Stop memory cache cleanup
	if cm.memory != nil {
		cm.memory.Stop()
	}
	
	cm.logger.Info("Cache Manager stopped")
	return nil
}

// Health returns the health status of the cache manager
func (cm *CacheManager) Health() HealthStatus {
	details := make(map[string]interface{})
	overallHealthy := true
	
	// Check Redis health
	if cm.redis != nil {
		if err := cm.redis.Ping(context.Background()).Err(); err != nil {
			details["redis"] = "unhealthy: " + err.Error()
			overallHealthy = false
		} else {
			details["redis"] = "healthy"
		}
	} else {
		details["redis"] = "not configured"
	}
	
	// Check memory cache health
	if cm.memory != nil {
		details["memory"] = "healthy"
		details["memory_size"] = len(cm.memory.items)
	} else {
		details["memory"] = "not configured"
		overallHealthy = false
	}
	
	status := "healthy"
	message := "Cache manager is healthy"
	
	if !overallHealthy {
		status = "degraded"
		message = "Cache manager is running in degraded mode"
	}
	
	return HealthStatus{
		Status:    status,
		Message:   message,
		Timestamp: time.Now(),
		Details:   details,
	}
}

// Metrics returns cache metrics
func (cm *CacheManager) Metrics() map[string]interface{} {
	metrics := make(map[string]interface{})
	
	// Redis metrics
	if cm.redis != nil {
		stats := cm.redis.PoolStats()
		metrics["redis"] = map[string]interface{}{
			"hits":         stats.Hits,
			"misses":       stats.Misses,
			"timeouts":     stats.Timeouts,
			"total_conns":  stats.TotalConns,
			"idle_conns":   stats.IdleConns,
			"stale_conns":  stats.StaleConns,
		}
	}
	
	// Memory cache metrics
	if cm.memory != nil {
		cm.memory.mu.RLock()
		itemCount := len(cm.memory.items)
		cm.memory.mu.RUnlock()
		
		metrics["memory"] = map[string]interface{}{
			"item_count": itemCount,
			"max_size":   cm.memory.maxSize,
		}
	}
	
	return metrics
}

// GetName returns the manager name
func (cm *CacheManager) GetName() string {
	return "cache"
}

// Get retrieves a value from cache using multi-level strategy
func (cm *CacheManager) Get(ctx context.Context, key string) (interface{}, error) {
	switch cm.strategy.Type {
	case "multi-level":
		return cm.getMultiLevel(ctx, key)
	case "redis-only":
		return cm.getFromRedis(ctx, key)
	case "memory-only":
		return cm.getFromMemory(key)
	default:
		return cm.getMultiLevel(ctx, key)
	}
}

// Set stores a value in cache using the configured strategy
func (cm *CacheManager) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	switch cm.strategy.Type {
	case "multi-level":
		return cm.setMultiLevel(ctx, key, value, ttl)
	case "redis-only":
		return cm.setInRedis(ctx, key, value, ttl)
	case "memory-only":
		return cm.setInMemory(key, value, ttl)
	default:
		return cm.setMultiLevel(ctx, key, value, ttl)
	}
}

// Delete removes a key from cache
func (cm *CacheManager) Delete(ctx context.Context, key string) error {
	var err error
	
	// Remove from memory cache
	if cm.memory != nil {
		cm.memory.Delete(key)
	}
	
	// Remove from Redis
	if cm.redis != nil {
		err = cm.redis.Del(ctx, key).Err()
	}
	
	return err
}

// getMultiLevel implements multi-level cache retrieval
func (cm *CacheManager) getMultiLevel(ctx context.Context, key string) (interface{}, error) {
	// Try memory cache first
	if value, found := cm.memory.Get(key); found {
		return value, nil
	}
	
	// Try Redis cache
	value, err := cm.getFromRedis(ctx, key)
	if err == nil && value != nil {
		// Store in memory cache for faster access
		cm.memory.Set(key, value, cm.strategy.MemoryTTL)
		return value, nil
	}
	
	if err != redis.Nil {
		cm.logger.Error("Redis cache error", zap.String("key", key), zap.Error(err))
	}
	
	return nil, fmt.Errorf("cache miss for key: %s", key)
}

// setMultiLevel implements multi-level cache storage
func (cm *CacheManager) setMultiLevel(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	// Set in memory cache
	memoryTTL := cm.strategy.MemoryTTL
	if ttl > 0 && ttl < memoryTTL {
		memoryTTL = ttl
	}
	cm.memory.Set(key, value, memoryTTL)
	
	// Set in Redis
	redisTTL := cm.strategy.RedisTTL
	if ttl > 0 {
		redisTTL = ttl
	}
	
	return cm.setInRedis(ctx, key, value, redisTTL)
}

// getFromRedis retrieves a value from Redis
func (cm *CacheManager) getFromRedis(ctx context.Context, key string) (interface{}, error) {
	if cm.redis == nil {
		return nil, fmt.Errorf("Redis not available")
	}
	
	val, err := cm.redis.Get(ctx, key).Result()
	if err != nil {
		return nil, err
	}
	
	var result interface{}
	if err := json.Unmarshal([]byte(val), &result); err != nil {
		return val, nil // Return raw string if not JSON
	}
	
	return result, nil
}

// setInRedis stores a value in Redis
func (cm *CacheManager) setInRedis(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	if cm.redis == nil {
		return fmt.Errorf("Redis not available")
	}
	
	// Serialize value
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	
	return cm.redis.Set(ctx, key, data, ttl).Err()
}

// getFromMemory retrieves a value from memory cache
func (cm *CacheManager) getFromMemory(key string) (interface{}, error) {
	if cm.memory == nil {
		return nil, fmt.Errorf("Memory cache not available")
	}
	
	if value, found := cm.memory.Get(key); found {
		return value, nil
	}
	
	return nil, fmt.Errorf("key not found in memory cache: %s", key)
}

// setInMemory stores a value in memory cache
func (cm *CacheManager) setInMemory(key string, value interface{}, ttl time.Duration) error {
	if cm.memory == nil {
		return fmt.Errorf("Memory cache not available")
	}
	
	cm.memory.Set(key, value, ttl)
	return nil
}

// initializeRedis sets up the Redis client
func (cm *CacheManager) initializeRedis() error {
	if cm.config.Redis == nil {
		return fmt.Errorf("Redis configuration not provided")
	}
	
	cm.redis = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cm.config.Redis.Host, cm.config.Redis.Port),
		Password: cm.config.Redis.Password,
		DB:       cm.config.Redis.DB,
		PoolSize: cm.config.Redis.PoolSize,
	})
	
	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	return cm.redis.Ping(ctx).Err()
}

// initializeMemoryCache sets up the in-memory cache
func (cm *CacheManager) initializeMemoryCache() {
	maxSize := 1000
	defaultTTL := 5 * time.Minute
	cleanupInterval := 1 * time.Minute
	
	if cm.config.Memory != nil {
		if cm.config.Memory.MaxSize > 0 {
			maxSize = cm.config.Memory.MaxSize
		}
		if cm.config.Memory.DefaultTTL > 0 {
			defaultTTL = cm.config.Memory.DefaultTTL
		}
		if cm.config.Memory.CleanupInterval > 0 {
			cleanupInterval = cm.config.Memory.CleanupInterval
		}
	}
	
	cm.memory = NewMemoryCache(maxSize, cleanupInterval)
}

// NewMemoryCache creates a new in-memory cache
func NewMemoryCache(maxSize int, cleanupInterval time.Duration) *MemoryCache {
	mc := &MemoryCache{
		items:   make(map[string]*CacheItem),
		maxSize: maxSize,
		ticker:  time.NewTicker(cleanupInterval),
		done:    make(chan struct{}),
	}
	
	// Start cleanup goroutine
	go mc.cleanup()
	
	return mc
}

// Get retrieves a value from memory cache
func (mc *MemoryCache) Get(key string) (interface{}, bool) {
	mc.mu.RLock()
	defer mc.mu.RUnlock()
	
	item, exists := mc.items[key]
	if !exists {
		return nil, false
	}
	
	// Check if expired
	if time.Now().After(item.ExpiresAt) {
		go mc.Delete(key) // Delete asynchronously
		return nil, false
	}
	
	// Update access statistics
	item.AccessCount++
	item.LastAccess = time.Now()
	
	return item.Value, true
}

// Set stores a value in memory cache
func (mc *MemoryCache) Set(key string, value interface{}, ttl time.Duration) {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	
	// Evict if at capacity
	if len(mc.items) >= mc.maxSize {
		mc.evictLRU()
	}
	
	mc.items[key] = &CacheItem{
		Value:       value,
		ExpiresAt:   time.Now().Add(ttl),
		AccessCount: 1,
		LastAccess:  time.Now(),
	}
}

// Delete removes a key from memory cache
func (mc *MemoryCache) Delete(key string) {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	
	delete(mc.items, key)
}

// Stop stops the memory cache cleanup
func (mc *MemoryCache) Stop() {
	close(mc.done)
	mc.ticker.Stop()
}

// cleanup removes expired items
func (mc *MemoryCache) cleanup() {
	for {
		select {
		case <-mc.ticker.C:
			mc.cleanupExpired()
		case <-mc.done:
			return
		}
	}
}

// cleanupExpired removes expired items
func (mc *MemoryCache) cleanupExpired() {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	
	now := time.Now()
	for key, item := range mc.items {
		if now.After(item.ExpiresAt) {
			delete(mc.items, key)
		}
	}
}

// evictLRU removes the least recently used item
func (mc *MemoryCache) evictLRU() {
	if len(mc.items) == 0 {
		return
	}
	
	var oldestKey string
	var oldestTime time.Time = time.Now()
	
	for key, item := range mc.items {
		if item.LastAccess.Before(oldestTime) {
			oldestTime = item.LastAccess
			oldestKey = key
		}
	}
	
	if oldestKey != "" {
		delete(mc.items, oldestKey)
	}
}
