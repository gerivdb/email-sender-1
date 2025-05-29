package ttl

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockTTLManager provides a mock implementation for TTLManager
type MockTTLManager struct {
	mock.Mock
	clearedKeys []string
}

func (m *MockTTLManager) clearInMemory(key string) {
	m.Called(key)
	m.clearedKeys = append(m.clearedKeys, key)
}

func (m *MockTTLManager) GetTTL(dataType DataType) (time.Duration, error) {
	args := m.Called(dataType)
	return args.Get(0).(time.Duration), args.Error(1)
}

func (m *MockTTLManager) SetWithTTL(ctx context.Context, key, value string, dataType DataType) error {
	args := m.Called(ctx, key, value, dataType)
	return args.Error(0)
}

// Tests for NewInvalidationManager
func TestNewInvalidationManager(t *testing.T) {
	t.Run("Create with Redis client and TTL manager", func(t *testing.T) {
		// Create a real Redis client for this test (won't actually connect)
		redisClient := redis.NewClient(&redis.Options{
			Addr: "localhost:6379",
		})
		mockTTL := &MockTTLManager{}

		manager := NewInvalidationManager(redisClient, mockTTL)

		assert.NotNil(t, manager)
		assert.Equal(t, redisClient, manager.redisClient)
		assert.Equal(t, mockTTL, manager.ttlManager)
	})

	t.Run("Create with Redis client only (nil TTL manager)", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{
			Addr: "localhost:6379",
		})

		manager := NewInvalidationManager(redisClient, nil)

		assert.NotNil(t, manager)
		assert.Equal(t, redisClient, manager.redisClient)
		assert.Nil(t, manager.ttlManager)
	})
}

// Tests for InvalidateByEvent
func TestInvalidationManager_InvalidateByEvent(t *testing.T) {
	t.Run("Empty event should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByEvent("", "test-key")

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "event and key must not be empty")
	})

	t.Run("Empty key should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByEvent("user_logout", "")

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "event and key must not be empty")
	})

	t.Run("Both empty should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByEvent("", "")

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "event and key must not be empty")
	})

	t.Run("Works with nil TTL manager", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		manager := NewInvalidationManager(redisClient, nil)

		// This will fail because Redis isn't running, but it validates
		// that the method doesn't panic with nil TTL manager
		err := manager.InvalidateByEvent("user_logout", "789")

		// We expect an error because Redis isn't running, but the method
		// should handle nil TTL manager gracefully
		assert.Error(t, err) // Redis connection error expected
	})
}

// Tests for InvalidateByVersion
func TestInvalidationManager_InvalidateByVersion(t *testing.T) {
	t.Run("Empty key should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByVersion("", 1)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "key must not be empty")
	})

	t.Run("Negative version should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByVersion("test-key", -1)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "version must be non-negative")
	})

	t.Run("Zero version should be valid", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		// This will fail due to Redis connection, but validates the version check
		err := manager.InvalidateByVersion("test-key", 0)

		// We expect a Redis connection error, not a version validation error
		assert.Error(t, err)
		assert.NotContains(t, err.Error(), "version must be non-negative")
	})
}

// Tests for InvalidateByAge
func TestInvalidationManager_InvalidateByAge(t *testing.T) {
	t.Run("Negative age should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByAge(-1)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "age must be non-negative")
	})

	t.Run("Zero age should be valid", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByAge(0)

		assert.NoError(t, err)
	})

	t.Run("Positive age returns success (stub implementation)", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByAge(3600)

		assert.NoError(t, err)
	})

	t.Run("Method is currently a stub", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		// This test verifies the current stub implementation
		// In the future, when the method is fully implemented,
		// this test should be updated to check actual functionality
		err := manager.InvalidateByAge(1800)

		assert.NoError(t, err)
		// The method should log that it's a stub implementation
		// but not fail
	})
}

// Tests for InvalidateByPattern
func TestInvalidationManager_InvalidateByPattern(t *testing.T) {
	t.Run("Empty pattern should return error", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		err := manager.InvalidateByPattern("")

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "pattern cannot be empty")
	})

	t.Run("Valid pattern structure test", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		// This will fail due to Redis connection but validates pattern handling
		err := manager.InvalidateByPattern("user:*")

		// We expect a Redis connection error, not a pattern validation error
		assert.Error(t, err)
		assert.NotContains(t, err.Error(), "pattern cannot be empty")
	})
}

// Edge case tests
func TestInvalidationManager_EdgeCases(t *testing.T) {
	t.Run("Very long key names", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		longKey := string(make([]byte, 1000)) // Very long key
		for i := range longKey {
			longKey = longKey[:i] + "a" + longKey[i+1:]
		}

		err := manager.InvalidateByVersion(longKey, 1)

		// Should handle long keys without validation errors
		assert.Error(t, err) // Redis connection error expected
		assert.NotContains(t, err.Error(), "key must not be empty")
	})

	t.Run("Special characters in keys", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		specialKey := "key:with-special.chars_123!@#$%"

		err := manager.InvalidateByEvent("event", specialKey)

		// Should handle special characters without validation errors
		assert.Error(t, err) // Redis connection error expected
		assert.NotContains(t, err.Error(), "event and key must not be empty")
	})

	t.Run("Maximum integer version", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		maxVersion := int(^uint(0) >> 1) // Maximum int value

		err := manager.InvalidateByVersion("test", maxVersion)

		// Should handle large version numbers without validation errors
		assert.Error(t, err) // Redis connection error expected
		assert.NotContains(t, err.Error(), "version must be non-negative")
	})
}

// Benchmark tests
func BenchmarkInvalidationManager_InvalidateByEvent(b *testing.B) {
	redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	mockTTL := &MockTTLManager{}
	manager := NewInvalidationManager(redisClient, mockTTL)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		// These will fail due to Redis connection, but we're benchmarking
		// the validation and structure creation overhead
		_ = manager.InvalidateByEvent("benchmark", fmt.Sprintf("key%d", i))
	}
}

func BenchmarkInvalidationManager_InvalidateByVersion(b *testing.B) {
	redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	mockTTL := &MockTTLManager{}
	manager := NewInvalidationManager(redisClient, mockTTL)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		// These will fail due to Redis connection, but we're benchmarking
		// the validation and structure creation overhead
		_ = manager.InvalidateByVersion(fmt.Sprintf("benchmark%d", i), i)
	}
}

// Integration-style tests (without actual Redis)
func TestInvalidationManager_MethodSignatures(t *testing.T) {
	t.Run("All methods exist and have correct signatures", func(t *testing.T) {
		redisClient := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		mockTTL := &MockTTLManager{}
		manager := NewInvalidationManager(redisClient, mockTTL)

		// Verify all methods can be called with expected signatures
		assert.NotNil(t, manager)

		// Test method signatures exist (will fail due to Redis, but validates signatures)
		var err error

		err = manager.InvalidateByPattern("test:*")
		assert.Error(t, err) // Expected due to no Redis

		err = manager.InvalidateByEvent("event", "key")
		assert.Error(t, err) // Expected due to no Redis

		err = manager.InvalidateByVersion("key", 1)
		assert.Error(t, err) // Expected due to no Redis

		err = manager.InvalidateByAge(3600)
		assert.NoError(t, err) // Should work as it's a stub
	})
}
