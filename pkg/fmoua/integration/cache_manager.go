// Package integration provides CacheManager implementation for FMOUA Phase 2
package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// CacheBackend interface for cache backend implementations
type CacheBackend interface {
	Get(key string) (interface{}, bool)
	Set(key string, value interface{}, ttl time.Duration) error
	Delete(key string) error
	Clear() error
	Keys() []string
	Stats() CacheBackendStats
	Close() error
}

// CacheBackendStats represents cache backend statistics
type CacheBackendStats struct {
	Hits         int64     `json:"hits"`
	Misses       int64     `json:"misses"`
	Keys         int64     `json:"keys"`
	Memory       int64     `json:"memory_bytes"`
	HitRate      float64   `json:"hit_rate"`
	Evictions    int64     `json:"evictions"`
	LastEviction time.Time `json:"last_eviction"`
}

// CacheManager manages cache operations with multiple backends
type CacheManager struct {
	*BaseManager
	config   types.CacheManagerConfig
	backends map[string]CacheBackend
	mu       sync.RWMutex
}

// NewCacheManager creates a new CacheManager instance
func NewCacheManager(id string, config types.ManagerConfig, logger *zap.Logger, metrics MetricsCollector) (*CacheManager, error) {
	baseManager := NewBaseManager(id, config, logger, metrics)

	// Parse cache-specific config
	cacheConfig, err := parseCacheManagerConfig(config.Config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse cache config: %w", err)
	}

	cm := &CacheManager{
		BaseManager: baseManager,
		config:      cacheConfig,
		backends:    make(map[string]CacheBackend),
	}

	return cm, nil
}

// Initialize initializes the cache manager with backends
func (cm *CacheManager) Initialize(config types.ManagerConfig) error {
	if err := cm.BaseManager.Initialize(config); err != nil {
		return err
	}

	// Initialize cache backends
	for name, backendConfig := range cm.config.Backends {
		backend, err := cm.createBackend(name, backendConfig)
		if err != nil {
			cm.LogError("Failed to create cache backend", err,
				zap.String("backend", name))
			continue
		}

		cm.mu.Lock()
		cm.backends[name] = backend
		cm.mu.Unlock()

		cm.LogInfo("Cache backend initialized",
			zap.String("backend", name),
			zap.String("type", backendConfig.Type))
	}

	if len(cm.backends) == 0 {
		// Add default memory backend
		backend := NewMemoryCacheBackend()
		cm.backends["default"] = backend
		cm.LogInfo("Added default memory cache backend")
	}

	return nil
}

// Execute processes a cache task
func (cm *CacheManager) Execute(ctx context.Context, task types.Task) (types.Result, error) {
	startTime := time.Now()

	result := types.Result{
		TaskID:    task.ID,
		Timestamp: startTime,
	}

	cm.LogInfo("Executing cache task",
		zap.String("task_id", task.ID),
		zap.String("task_type", task.Type))

	switch task.Type {
	case "get":
		data, err := cm.handleGet(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		} else {
			result.Data = map[string]interface{}{"value": data}
		}

	case "set":
		err := cm.handleSet(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "delete":
		err := cm.handleDelete(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "clear":
		err := cm.handleClear(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "stats":
		stats := cm.handleStats(ctx, task)
		result.Success = true
		result.Data = map[string]interface{}{"cache_stats": stats}

	default:
		err := fmt.Errorf("unsupported task type: %s", task.Type)
		result.Success = false
		result.Error = err.Error()
	}

	result.Duration = time.Since(startTime)

	// Update metrics
	cm.metrics.Histogram("cache_task_duration",
		float64(result.Duration.Milliseconds()),
		map[string]string{
			"task_type": task.Type,
			"success":   fmt.Sprintf("%t", result.Success),
		})

	return result, nil
}

// Start starts the cache manager
func (cm *CacheManager) Start() error {
	if err := cm.BaseManager.Start(); err != nil {
		return err
	}

	cm.LogInfo("Cache manager started",
		zap.Int("backends", len(cm.backends)))

	return nil
}

// Stop stops the cache manager
func (cm *CacheManager) Stop() error {
	cm.LogInfo("Stopping cache manager")

	// Close all cache backends
	cm.mu.Lock()
	for name, backend := range cm.backends {
		if err := backend.Close(); err != nil {
			cm.LogError("Failed to close cache backend", err,
				zap.String("backend", name))
		}
	}
	cm.mu.Unlock()

	return cm.BaseManager.Stop()
}

// GetType returns the manager type
func (cm *CacheManager) GetType() string {
	return "cache"
}

// createBackend creates a cache backend based on configuration
func (cm *CacheManager) createBackend(name string, config types.CacheBackendConfig) (CacheBackend, error) {
	switch config.Type {
	case "memory":
		return NewMemoryCacheBackend(), nil
	case "redis":
		return NewRedisCacheBackend(config), nil
	case "memcached":
		return NewMemcachedBackend(config), nil
	default:
		return nil, fmt.Errorf("unsupported cache backend type: %s", config.Type)
	}
}

// handleGet handles cache get operations
func (cm *CacheManager) handleGet(ctx context.Context, task types.Task) (interface{}, error) {
	backendName, ok := task.Payload["backend"].(string)
	if !ok {
		backendName = "default"
	}

	key, ok := task.Payload["key"].(string)
	if !ok {
		return nil, fmt.Errorf("cache key not specified")
	}

	cm.mu.RLock()
	backend, exists := cm.backends[backendName]
	cm.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("cache backend not found: %s", backendName)
	}

	value, found := backend.Get(key)
	if !found {
		cm.metrics.Increment("cache_miss", map[string]string{
			"backend": backendName,
		})
		return nil, fmt.Errorf("cache miss for key: %s", key)
	}

	cm.metrics.Increment("cache_hit", map[string]string{
		"backend": backendName,
	})

	return value, nil
}

// handleSet handles cache set operations
func (cm *CacheManager) handleSet(ctx context.Context, task types.Task) error {
	backendName, ok := task.Payload["backend"].(string)
	if !ok {
		backendName = "default"
	}

	key, ok := task.Payload["key"].(string)
	if !ok {
		return fmt.Errorf("cache key not specified")
	}

	value := task.Payload["value"]
	if value == nil {
		return fmt.Errorf("cache value not specified")
	}

	ttl := cm.config.Strategies.DefaultTTL
	if ttlData, ok := task.Payload["ttl"]; ok {
		if ttlSeconds, ok := ttlData.(float64); ok {
			ttl = time.Duration(ttlSeconds) * time.Second
		}
	}

	cm.mu.RLock()
	backend, exists := cm.backends[backendName]
	cm.mu.RUnlock()

	if !exists {
		return fmt.Errorf("cache backend not found: %s", backendName)
	}

	return backend.Set(key, value, ttl)
}

// handleDelete handles cache delete operations
func (cm *CacheManager) handleDelete(ctx context.Context, task types.Task) error {
	backendName, ok := task.Payload["backend"].(string)
	if !ok {
		backendName = "default"
	}

	key, ok := task.Payload["key"].(string)
	if !ok {
		return fmt.Errorf("cache key not specified")
	}

	cm.mu.RLock()
	backend, exists := cm.backends[backendName]
	cm.mu.RUnlock()

	if !exists {
		return fmt.Errorf("cache backend not found: %s", backendName)
	}

	return backend.Delete(key)
}

// handleClear handles cache clear operations
func (cm *CacheManager) handleClear(ctx context.Context, task types.Task) error {
	backendName, ok := task.Payload["backend"].(string)
	if !ok {
		backendName = "default"
	}

	cm.mu.RLock()
	backend, exists := cm.backends[backendName]
	cm.mu.RUnlock()

	if !exists {
		return fmt.Errorf("cache backend not found: %s", backendName)
	}

	return backend.Clear()
}

// handleStats handles cache statistics retrieval
func (cm *CacheManager) handleStats(ctx context.Context, task types.Task) map[string]interface{} {
	stats := make(map[string]interface{})

	cm.mu.RLock()
	for name, backend := range cm.backends {
		stats[name] = backend.Stats()
	}
	cm.mu.RUnlock()

	return stats
}

// parseCacheManagerConfig parses cache manager configuration
func parseCacheManagerConfig(config map[string]interface{}) (types.CacheManagerConfig, error) {
	// Simplified parser
	cacheConfig := types.CacheManagerConfig{
		Backends: make(map[string]types.CacheBackendConfig),
		Strategies: types.CacheStrategiesConfig{
			DefaultTTL:     time.Hour,
			EvictionPolicy: "lru",
			MaxMemory:      "100MB",
			Serialization:  "json",
		},
		Monitoring: types.CacheMonitoringConfig{
			Enabled:        true,
			MetricsPrefix:  "cache",
			StatsInterval:  time.Minute,
			AlertThreshold: 0.9,
		},
	}

	// Parse backends configuration
	if backendsData, ok := config["backends"].(map[string]interface{}); ok {
		for name, backendData := range backendsData {
			if backendMap, ok := backendData.(map[string]interface{}); ok {
				backendConfig := types.CacheBackendConfig{}

				if typ, ok := backendMap["type"].(string); ok {
					backendConfig.Type = typ
				}
				if addresses, ok := backendMap["addresses"].([]interface{}); ok {
					for _, addr := range addresses {
						if addrStr, ok := addr.(string); ok {
							backendConfig.Addresses = append(backendConfig.Addresses, addrStr)
						}
					}
				}
				if timeout, ok := backendMap["timeout"].(float64); ok {
					backendConfig.Timeout = time.Duration(timeout) * time.Second
				}

				cacheConfig.Backends[name] = backendConfig
			}
		}
	}

	return cacheConfig, nil
}
