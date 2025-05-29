// invalidationmanager.go - Implementation of InvalidationManager for cache invalidation
package ttl

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

// TTLCacheManager interface defines the methods needed by InvalidationManager
type TTLCacheManager interface {
	clearInMemory(key string)
}

// InvalidationManager handles cache invalidation operations
type InvalidationManager struct {
	redisClient *redis.Client
	ttlManager  TTLCacheManager // Reference to TTLManager for in-memory cache consistency
}

// NewInvalidationManager creates a new instance of InvalidationManager
// ttlManager can be nil if in-memory cache clearing is not needed.
func NewInvalidationManager(redisClient *redis.Client, ttlManager TTLCacheManager) *InvalidationManager {
	return &InvalidationManager{
		redisClient: redisClient,
		ttlManager:  ttlManager,
	}
}

// InvalidateByPattern invalidates cache entries matching a pattern in Redis
// and clears them from the associated TTLManager's in-memory cache.
func (im *InvalidationManager) InvalidateByPattern(pattern string) error {
	if pattern == "" {
		return fmt.Errorf("pattern cannot be empty")
	}
	ctx := context.Background()
	iter := im.redisClient.Scan(ctx, 0, pattern, 0).Iterator()
	var invalidatedRedisKeys []string
	var keysClearedFromMemory []string

	for iter.Next(ctx) {
		keyToInvalidate := iter.Val()
		// Delete from Redis
		if err := im.redisClient.Del(ctx, keyToInvalidate).Err(); err != nil {
			// Log error but continue trying to invalidate other keys for robustness
			fmt.Printf("Warning: failed to delete key %s from Redis: %v. Continuing...\n", keyToInvalidate, err)
			continue // Or return error, depending on desired atomicity
		}
		invalidatedRedisKeys = append(invalidatedRedisKeys, keyToInvalidate)

		// Also invalidate from TTLManager's in-memory cache if ttlManager is provided
		if im.ttlManager != nil {
			im.ttlManager.clearInMemory(keyToInvalidate)
			keysClearedFromMemory = append(keysClearedFromMemory, keyToInvalidate)
		}
	}
	if err := iter.Err(); err != nil {
		return fmt.Errorf("error scanning keys with pattern '%s': %w", pattern, err)
	}

	if len(invalidatedRedisKeys) > 0 {
		fmt.Printf("Invalidated %d keys matching pattern '%s' from Redis: %v\n", len(invalidatedRedisKeys), pattern, invalidatedRedisKeys)
		if im.ttlManager != nil && len(keysClearedFromMemory) > 0 {
			fmt.Printf("Cleared %d corresponding keys from in-memory cache.\n", len(keysClearedFromMemory))
		}
	} else {
		fmt.Printf("No keys found matching pattern '%s' in Redis.\n", pattern)
	}
	return nil
}

// InvalidateByEvent invalidates cache entries based on an event type and key
// from Redis and the associated TTLManager's in-memory cache.
func (im *InvalidationManager) InvalidateByEvent(event, key string) error {
	if event == "" || key == "" {
		return fmt.Errorf("event and key must not be empty")
	}
	fullKey := fmt.Sprintf("%s:%s", event, key)

	// Delete from Redis
	deletedCount, err := im.redisClient.Del(context.Background(), fullKey).Result()
	if err != nil {
		return fmt.Errorf("failed to delete key '%s' from Redis for event '%s': %w", fullKey, event, err)
	}

	if deletedCount > 0 {
		fmt.Printf("Invalidated key '%s' from Redis based on event '%s'.\n", fullKey, event)
		// Also invalidate from TTLManager's in-memory cache if ttlManager is provided
		if im.ttlManager != nil {
			im.ttlManager.clearInMemory(fullKey)
		}
	} else {
		fmt.Printf("Key '%s' for event '%s' not found in Redis or already deleted.\n", fullKey, event)
		// Still attempt to clear from memory in case it exists there due to some inconsistency
		if im.ttlManager != nil {
			im.ttlManager.clearInMemory(fullKey)
		}
	}
	return nil
}

// InvalidateByVersion invalidates cache entries by version suffix from Redis
// and the associated TTLManager's in-memory cache.
func (im *InvalidationManager) InvalidateByVersion(key string, version int) error {
	if key == "" {
		return fmt.Errorf("key must not be empty")
	}
	if version < 0 {
		return fmt.Errorf("version must be non-negative")
	}
	versionedKey := fmt.Sprintf("%s:v%d", key, version)

	// Delete from Redis
	deletedCount, err := im.redisClient.Del(context.Background(), versionedKey).Result()
	if err != nil {
		return fmt.Errorf("failed to delete versioned key '%s' from Redis: %w", versionedKey, err)
	}

	if deletedCount > 0 {
		fmt.Printf("Invalidated versioned key '%s' from Redis.\n", versionedKey)
		// Also invalidate from TTLManager's in-memory cache if ttlManager is provided
		if im.ttlManager != nil {
			im.ttlManager.clearInMemory(versionedKey)
		}
	} else {
		fmt.Printf("Versioned key '%s' not found in Redis or already deleted.\n", versionedKey)
		if im.ttlManager != nil {
			im.ttlManager.clearInMemory(versionedKey)
		}
	}
	return nil
}

// InvalidateByAge invalidates keys older than a specified age in seconds.
// The current implementation is a stub for Redis logic.
// If implemented, it should also clear corresponding keys from TTLManager's in-memory cache.
func (im *InvalidationManager) InvalidateByAge(ageSeconds int) error {
	if ageSeconds < 0 {
		return fmt.Errorf("age must be non-negative")
	}
	// This assumes keys are stored with a TTL or timestamp, which would be managed elsewhere.
	fmt.Printf("InvalidateByAge would require tracking key timestamps in Redis. (Current Redis logic is a stub)\n")
	// Stub logic here — a real implementation would require Redis sorted sets or metadata tracking.
	// If keys were identified from Redis, they would then be passed to:
	// if im.ttlManager != nil {
	//    im.ttlManager.clearInMemory(keyFoundByAgeLogic)
	// }
	return nil
}
