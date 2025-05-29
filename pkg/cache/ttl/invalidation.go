package ttl

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// InvalidationStrategy defines interface for cache invalidation strategies
type InvalidationStrategy interface {
	// Invalidate performs the invalidation based on strategy
	Invalidate(ctx context.Context, keys []string) error
	// ShouldInvalidate determines if invalidation should occur
	ShouldInvalidate(ctx context.Context, key string, metadata map[string]interface{}) bool
	// GetName returns the strategy name
	GetName() string
}

// InvalidationManager manages different invalidation strategies
type InvalidationManager struct {
	strategies map[string]InvalidationStrategy
	redis      *redis.Client
	metrics    *InvalidationMetrics
	mu         sync.RWMutex
}

// InvalidationMetrics tracks invalidation operations
type InvalidationMetrics struct {
	StrategyExecutions  map[string]int64 `json:"strategy_executions"`
	InvalidatedKeys     int64            `json:"invalidated_keys"`
	FailedInvalidations int64            `json:"failed_invalidations"`
	AverageLatency      time.Duration    `json:"average_latency"`
	mu                  sync.RWMutex
}

// NewInvalidationManager creates a new invalidation manager
func NewInvalidationManager(redisClient *redis.Client) *InvalidationManager {
	manager := &InvalidationManager{
		strategies: make(map[string]InvalidationStrategy),
		redis:      redisClient,
		metrics: &InvalidationMetrics{
			StrategyExecutions: make(map[string]int64),
		},
	}

	// Register default strategies
	manager.RegisterStrategy(NewTimeBasedInvalidation(redisClient))
	manager.RegisterStrategy(NewEventBasedInvalidation(redisClient))
	manager.RegisterStrategy(NewVersionBasedInvalidation(redisClient))

	return manager
}

// RegisterStrategy adds a new invalidation strategy
func (im *InvalidationManager) RegisterStrategy(strategy InvalidationStrategy) {
	im.mu.Lock()
	defer im.mu.Unlock()
	im.strategies[strategy.GetName()] = strategy
}

// ExecuteStrategy runs a specific invalidation strategy
func (im *InvalidationManager) ExecuteStrategy(ctx context.Context, strategyName string, keys []string) error {
	im.mu.RLock()
	strategy, exists := im.strategies[strategyName]
	im.mu.RUnlock()

	if !exists {
		return fmt.Errorf("strategy %s not found", strategyName)
	}

	start := time.Now()
	err := strategy.Invalidate(ctx, keys)
	latency := time.Since(start)

	// Update metrics
	im.metrics.mu.Lock()
	im.metrics.StrategyExecutions[strategyName]++
	if err != nil {
		im.metrics.FailedInvalidations++
	} else {
		im.metrics.InvalidatedKeys += int64(len(keys))
	}
	im.metrics.AverageLatency = (im.metrics.AverageLatency + latency) / 2
	im.metrics.mu.Unlock()

	return err
}

// TimeBasedInvalidation invalidates based on time patterns
type TimeBasedInvalidation struct {
	redis    *redis.Client
	patterns map[string]time.Duration // Key patterns and their max age
	mu       sync.RWMutex
}

// NewTimeBasedInvalidation creates a time-based invalidation strategy
func NewTimeBasedInvalidation(redisClient *redis.Client) *TimeBasedInvalidation {
	return &TimeBasedInvalidation{
		redis:    redisClient,
		patterns: make(map[string]time.Duration),
	}
}

func (tbi *TimeBasedInvalidation) GetName() string {
	return "time_based"
}

func (tbi *TimeBasedInvalidation) AddPattern(pattern string, maxAge time.Duration) {
	tbi.mu.Lock()
	defer tbi.mu.Unlock()
	tbi.patterns[pattern] = maxAge
}

func (tbi *TimeBasedInvalidation) Invalidate(ctx context.Context, keys []string) error {
	for _, key := range keys {
		// Check if key exists and get its age
		result := tbi.redis.ObjectIdleTime(ctx, key)
		if result.Err() != nil {
			continue // Skip if can't get idle time
		}

		idleTime := result.Val()

		// Check against patterns
		tbi.mu.RLock()
		shouldInvalidate := false
		for pattern, maxAge := range tbi.patterns {
			if matchPattern(key, pattern) && idleTime > maxAge {
				shouldInvalidate = true
				break
			}
		}
		tbi.mu.RUnlock()

		if shouldInvalidate {
			tbi.redis.Del(ctx, key)
		}
	}
	return nil
}

func (tbi *TimeBasedInvalidation) ShouldInvalidate(ctx context.Context, key string, metadata map[string]interface{}) bool {
	result := tbi.redis.ObjectIdleTime(ctx, key)
	if result.Err() != nil {
		return false
	}

	idleTime := result.Val()

	tbi.mu.RLock()
	defer tbi.mu.RUnlock()

	for pattern, maxAge := range tbi.patterns {
		if matchPattern(key, pattern) && idleTime > maxAge {
			return true
		}
	}
	return false
}

// EventBasedInvalidation invalidates based on external events
type EventBasedInvalidation struct {
	redis         *redis.Client
	eventTriggers map[string][]string // Event type -> Keys to invalidate
	mu            sync.RWMutex
}

// NewEventBasedInvalidation creates an event-based invalidation strategy
func NewEventBasedInvalidation(redisClient *redis.Client) *EventBasedInvalidation {
	return &EventBasedInvalidation{
		redis:         redisClient,
		eventTriggers: make(map[string][]string),
	}
}

func (ebi *EventBasedInvalidation) GetName() string {
	return "event_based"
}

func (ebi *EventBasedInvalidation) AddTrigger(eventType string, keys []string) {
	ebi.mu.Lock()
	defer ebi.mu.Unlock()
	ebi.eventTriggers[eventType] = append(ebi.eventTriggers[eventType], keys...)
}

func (ebi *EventBasedInvalidation) Invalidate(ctx context.Context, keys []string) error {
	if len(keys) == 0 {
		return nil
	}

	// Delete all specified keys
	return ebi.redis.Del(ctx, keys...).Err()
}

func (ebi *EventBasedInvalidation) ShouldInvalidate(ctx context.Context, key string, metadata map[string]interface{}) bool {
	eventType, exists := metadata["event_type"].(string)
	if !exists {
		return false
	}

	ebi.mu.RLock()
	defer ebi.mu.RUnlock()

	triggeredKeys, exists := ebi.eventTriggers[eventType]
	if !exists {
		return false
	}

	for _, triggeredKey := range triggeredKeys {
		if matchPattern(key, triggeredKey) {
			return true
		}
	}
	return false
}

// TriggerEvent triggers invalidation for a specific event
func (ebi *EventBasedInvalidation) TriggerEvent(ctx context.Context, eventType string) error {
	ebi.mu.RLock()
	keys, exists := ebi.eventTriggers[eventType]
	ebi.mu.RUnlock()

	if !exists {
		return fmt.Errorf("event type %s not registered", eventType)
	}

	return ebi.Invalidate(ctx, keys)
}

// VersionBasedInvalidation invalidates based on data version changes
type VersionBasedInvalidation struct {
	redis    *redis.Client
	versions map[string]string // Key -> Current version
	mu       sync.RWMutex
}

// NewVersionBasedInvalidation creates a version-based invalidation strategy
func NewVersionBasedInvalidation(redisClient *redis.Client) *VersionBasedInvalidation {
	return &VersionBasedInvalidation{
		redis:    redisClient,
		versions: make(map[string]string),
	}
}

func (vbi *VersionBasedInvalidation) GetName() string {
	return "version_based"
}

func (vbi *VersionBasedInvalidation) SetVersion(key, version string) {
	vbi.mu.Lock()
	defer vbi.mu.Unlock()
	vbi.versions[key] = version
}

func (vbi *VersionBasedInvalidation) Invalidate(ctx context.Context, keys []string) error {
	for _, key := range keys {
		// Get stored version from metadata
		versionKey := key + ":version"
		storedVersion := vbi.redis.Get(ctx, versionKey).Val()

		vbi.mu.RLock()
		currentVersion, exists := vbi.versions[key]
		vbi.mu.RUnlock()

		if exists && storedVersion != "" && storedVersion != currentVersion {
			// Version mismatch, invalidate
			vbi.redis.Del(ctx, key)
			vbi.redis.Set(ctx, versionKey, currentVersion, 0) // Update version
		}
	}
	return nil
}

func (vbi *VersionBasedInvalidation) ShouldInvalidate(ctx context.Context, key string, metadata map[string]interface{}) bool {
	version, exists := metadata["version"].(string)
	if !exists {
		return false
	}

	vbi.mu.RLock()
	currentVersion, exists := vbi.versions[key]
	vbi.mu.RUnlock()

	return exists && version != currentVersion
}

// Helper function to match key patterns (simple wildcard matching)
func matchPattern(key, pattern string) bool {
	if pattern == "*" {
		return true
	}
	if pattern == key {
		return true
	}
	// Add more sophisticated pattern matching as needed
	return false
}

// GetMetrics returns invalidation metrics
func (im *InvalidationManager) GetMetrics() *InvalidationMetrics {
	im.metrics.mu.RLock()
	defer im.metrics.mu.RUnlock()

	metrics := &InvalidationMetrics{
		StrategyExecutions:  make(map[string]int64),
		InvalidatedKeys:     im.metrics.InvalidatedKeys,
		FailedInvalidations: im.metrics.FailedInvalidations,
		AverageLatency:      im.metrics.AverageLatency,
	}

	for k, v := range im.metrics.StrategyExecutions {
		metrics.StrategyExecutions[k] = v
	}

	return metrics
}
