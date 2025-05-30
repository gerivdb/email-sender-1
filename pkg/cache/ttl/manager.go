// Package ttl provides Time-To-Live management for cache entries
package ttl

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// TTLConfig defines TTL settings for each data type
type TTLConfig struct {
	DefaultValues time.Duration `json:"default_values" yaml:"default_values"`
	Statistics    time.Duration `json:"statistics" yaml:"statistics"`
	MLModels      time.Duration `json:"ml_models" yaml:"ml_models"`
	Configuration time.Duration `json:"configuration" yaml:"configuration"`
	UserSessions  time.Duration `json:"user_sessions" yaml:"user_sessions"`
}

// DefaultTTLConfig returns the default TTL configuration
func DefaultTTLConfig() *TTLConfig {
	return &TTLConfig{
		DefaultValues: 3600 * time.Second,  // 1 hour
		Statistics:    86400 * time.Second, // 24 hours
		MLModels:      3600 * time.Second,  // 1 hour with intelligent refresh
		Configuration: 1800 * time.Second,  // 30 minutes
		UserSessions:  7200 * time.Second,  // 2 hours
	}
}

// TTLManager manages Time-To-Live for cache entries
type TTLManager struct {
	config     *TTLConfig
	redis      *redis.Client
	metrics    *TTLMetrics
	mu         sync.RWMutex
	analyzer   *TTLAnalyzer
	ctx        context.Context
	cancel     context.CancelFunc
	inMemCache map[string]cachedItem // In-memory cache for fast access
}

// cachedItem represents an item stored in the in-memory cache
type cachedItem struct {
	value      interface{}
	expiryTime time.Time
}

// TTLMetrics tracks TTL-related metrics
type TTLMetrics struct {
	ExpirationsByType map[DataType]int64   `json:"expirations_by_type"`
	TTLOptimizations  int64                `json:"ttl_optimizations"`
	InvalidationCount int64                `json:"invalidation_count"`
	AverageTTLUsage   map[DataType]float64 `json:"average_ttl_usage"`
	mu                sync.RWMutex
}

// NewTTLManager creates a new TTL manager
func NewTTLManager(redisClient *redis.Client, config *TTLConfig) *TTLManager {
	if config == nil {
		config = DefaultTTLConfig()
	}

	ctx, cancel := context.WithCancel(context.Background())
	manager := &TTLManager{
		config: config,
		redis:  redisClient,
		metrics: &TTLMetrics{
			ExpirationsByType: make(map[DataType]int64),
			AverageTTLUsage:   make(map[DataType]float64),
		},
		ctx:        ctx,
		cancel:     cancel,
		inMemCache: make(map[string]cachedItem),
	}

	manager.analyzer = NewTTLAnalyzer(manager)

	// Start background monitoring
	go manager.startMonitoring()

	return manager
}

// GetTTL returns the TTL for a specific data type
func (tm *TTLManager) GetTTL(dataType DataType) (time.Duration, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	switch dataType {
	case DefaultValues:
		return tm.config.DefaultValues, nil
	case Statistics:
		return tm.config.Statistics, nil
	case MLModels:
		return tm.config.MLModels, nil
	case Configuration:
		return tm.config.Configuration, nil
	case UserSessions:
		return tm.config.UserSessions, nil
	default:
		return tm.config.DefaultValues, nil // Fallback
	}
}

// SetTTL updates the TTL for a specific data type
func (tm *TTLManager) SetTTL(dataType DataType, ttl time.Duration) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	switch dataType {
	case DefaultValues:
		tm.config.DefaultValues = ttl
	case Statistics:
		tm.config.Statistics = ttl
	case MLModels:
		tm.config.MLModels = ttl
	case Configuration:
		tm.config.Configuration = ttl
	case UserSessions:
		tm.config.UserSessions = ttl
	default:
		return fmt.Errorf("unknown data type: %s", dataType)
	}

	tm.metrics.mu.Lock()
	tm.metrics.TTLOptimizations++
	tm.metrics.mu.Unlock()

	return nil
}

// SetWithTTL sets a cache entry with appropriate TTL
func (tm *TTLManager) SetWithTTL(ctx context.Context, key string, value interface{}, dataType DataType) error {
	ttl, err := tm.GetTTL(dataType)
	if err != nil {
		return fmt.Errorf("failed to get TTL for data type %s: %w", dataType, err)
	}

	err = tm.redis.Set(ctx, key, value, ttl).Err()
	if err != nil {
		return fmt.Errorf("failed to set cache entry with TTL: %w", err)
	}

	// Also store in in-memory cache for fast access
	tm.setInMemory(key, value, ttl)

	// Update metrics
	tm.metrics.mu.Lock()
	tm.metrics.ExpirationsByType[dataType]++
	tm.metrics.mu.Unlock()

	return nil
}

// ExpireKey sets TTL for an existing key
func (tm *TTLManager) ExpireKey(ctx context.Context, key string, dataType DataType) error {
	ttl, err := tm.GetTTL(dataType)
	if err != nil {
		return fmt.Errorf("failed to get TTL for data type %s: %w", dataType, err)
	}

	err = tm.redis.Expire(ctx, key, ttl).Err()
	if err != nil {
		return fmt.Errorf("failed to set TTL for key %s: %w", key, err)
	}

	return nil
}

// Get retrieves a value from cache (for email service compatibility)
func (tm *TTLManager) Get(key string, dest interface{}) (bool, error) {
	value, found := tm.getFromMemory(key)
	if !found {
		// Try Redis as fallback
		ctx := context.Background()
		result, err := tm.redis.Get(ctx, key).Result()
		if err != nil {
			if err == redis.Nil {
				return false, nil // Key not found
			}
			return false, fmt.Errorf("redis get error: %w", err)
		}

		// Try to unmarshal into dest
		if err := json.Unmarshal([]byte(result), dest); err != nil {
			return false, fmt.Errorf("unmarshal error: %w", err)
		}
		return true, nil
	}

	// Convert value to dest
	data, err := json.Marshal(value)
	if err != nil {
		return false, fmt.Errorf("marshal error: %w", err)
	}

	if err := json.Unmarshal(data, dest); err != nil {
		return false, fmt.Errorf("unmarshal error: %w", err)
	}

	return true, nil
}

// Set stores a value in cache with automatic TTL based on data type
func (tm *TTLManager) Set(key string, value interface{}, dataType DataType) error {
	ctx := context.Background()
	return tm.SetWithTTL(ctx, key, value, dataType)
}

// Delete removes a value from cache
func (tm *TTLManager) Delete(key string) error {
	tm.mu.Lock()
	delete(tm.inMemCache, key)
	tm.mu.Unlock()

	// Also delete from Redis
	ctx := context.Background()
	return tm.redis.Del(ctx, key).Err()
}

// GetMetrics returns current TTL metrics
func (tm *TTLManager) GetMetrics() *TTLMetrics {
	tm.metrics.mu.RLock()
	defer tm.metrics.mu.RUnlock()

	// Create a copy to avoid data races
	metrics := &TTLMetrics{
		ExpirationsByType: make(map[DataType]int64),
		AverageTTLUsage:   make(map[DataType]float64),
		TTLOptimizations:  tm.metrics.TTLOptimizations,
		InvalidationCount: tm.metrics.InvalidationCount,
	}

	for k, v := range tm.metrics.ExpirationsByType {
		metrics.ExpirationsByType[k] = v
	}
	for k, v := range tm.metrics.AverageTTLUsage {
		metrics.AverageTTLUsage[k] = v
	}

	return metrics
}

// startMonitoring runs background monitoring tasks
func (tm *TTLManager) startMonitoring() {
	ticker := time.NewTicker(60 * time.Second) // Monitor every minute
	defer ticker.Stop()

	for {
		select {
		case <-tm.ctx.Done():
			return
		case <-ticker.C:
			tm.analyzer.AnalyzeUsagePatterns()
		}
	}
}

// Close stops the TTL manager and cleanup resources
func (tm *TTLManager) Close() error {
	tm.cancel()
	return nil
}

// clearInMemory removes an item only from the in-memory cache.
// This is used by InvalidationManager to keep the local cache consistent.
func (tm *TTLManager) clearInMemory(key string) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	if _, exists := tm.inMemCache[key]; exists {
		delete(tm.inMemCache, key)
		fmt.Printf("Key '%s' cleared from in-memory cache due to external invalidation.\n", key)
	}
}

// setInMemory stores an item in the in-memory cache with expiry time
func (tm *TTLManager) setInMemory(key string, value interface{}, ttl time.Duration) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	tm.inMemCache[key] = cachedItem{
		value:      value,
		expiryTime: time.Now().Add(ttl),
	}
}

// getFromMemory retrieves an item from the in-memory cache if not expired
func (tm *TTLManager) getFromMemory(key string) (interface{}, bool) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	item, exists := tm.inMemCache[key]
	if !exists {
		return nil, false
	}

	if time.Now().After(item.expiryTime) {
		// Item expired, remove it
		delete(tm.inMemCache, key)
		return nil, false
	}

	return item.value, true
}
