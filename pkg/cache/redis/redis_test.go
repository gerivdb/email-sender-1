package redis

import (
	"context"
	"testing"
	"time"
)

func TestDefaultRedisConfig(t *testing.T) {
	config := DefaultRedisConfig()
	
	// Test Plan v39 specifications
	if config.Host != "localhost" {
		t.Errorf("Expected Host to be localhost, got %s", config.Host)
	}
	
	if config.Port != 6379 {
		t.Errorf("Expected Port to be 6379, got %d", config.Port)
	}
	
	// Test timeout specifications from Plan v39
	if config.DialTimeout != 5*time.Second {
		t.Errorf("Expected DialTimeout to be 5s, got %v", config.DialTimeout)
	}
	
	if config.ReadTimeout != 3*time.Second {
		t.Errorf("Expected ReadTimeout to be 3s, got %v", config.ReadTimeout)
	}
	
	if config.WriteTimeout != 3*time.Second {
		t.Errorf("Expected WriteTimeout to be 3s, got %v", config.WriteTimeout)
	}
	
	// Test retry configuration from Plan v39
	if config.MaxRetries != 3 {
		t.Errorf("Expected MaxRetries to be 3, got %d", config.MaxRetries)
	}
	
	if config.MinRetryBackoff != 1*time.Second {
		t.Errorf("Expected MinRetryBackoff to be 1s, got %v", config.MinRetryBackoff)
	}
	
	if config.MaxRetryBackoff != 3*time.Second {
		t.Errorf("Expected MaxRetryBackoff to be 3s, got %v", config.MaxRetryBackoff)
	}
	
	// Test pool configuration from Plan v39
	if config.PoolSize != 10 {
		t.Errorf("Expected PoolSize to be 10, got %d", config.PoolSize)
	}
	
	if config.MinIdleConns != 5 {
		t.Errorf("Expected MinIdleConns to be 5, got %d", config.MinIdleConns)
	}
	
	if config.PoolTimeout != 4*time.Second {
		t.Errorf("Expected PoolTimeout to be 4s, got %v", config.PoolTimeout)
	}
	
	// Test health check interval from Plan v39
	if config.HealthCheckInterval != 30*time.Second {
		t.Errorf("Expected HealthCheckInterval to be 30s, got %v", config.HealthCheckInterval)
	}
}

func TestConfigValidation(t *testing.T) {
	validator := NewConfigValidator()
	
	// Test valid configuration
	validConfig := DefaultRedisConfig()
	if err := validator.Validate(validConfig); err != nil {
		t.Errorf("Valid configuration should pass validation, got error: %v", err)
	}
	
	// Test invalid host
	invalidHostConfig := DefaultRedisConfig()
	invalidHostConfig.Host = ""
	if err := validator.Validate(invalidHostConfig); err == nil {
		t.Error("Empty host should fail validation")
	}
	
	// Test invalid port
	invalidPortConfig := DefaultRedisConfig()
	invalidPortConfig.Port = 0
	if err := validator.Validate(invalidPortConfig); err == nil {
		t.Error("Invalid port should fail validation")
	}
	
	// Test invalid database number
	invalidDBConfig := DefaultRedisConfig()
	invalidDBConfig.DB = -1
	if err := validator.Validate(invalidDBConfig); err == nil {
		t.Error("Invalid database number should fail validation")
	}
}

func TestCircuitBreaker(t *testing.T) {
	cb := NewCircuitBreaker(DefaultCircuitBreakerConfig(), nil)
	
	// Test initial state
	if cb.State() != StateClosed {
		t.Errorf("Expected initial state to be Closed, got %v", cb.State())
	}
	
	// Test failures trigger circuit breaker
	for i := 0; i < 5; i++ {
		cb.Execute(func() error {
			return &RedisError{Type: ErrorTypeConnection, Message: "test error", Time: time.Now()}
		})
	}
	
	if cb.State() != StateOpen {
		t.Errorf("Expected state to be Open after 5 failures, got %v", cb.State())
	}
	
	// Test that execution is blocked when open
	err := cb.Execute(func() error {
		return nil
	})
	
	if err == nil {
		t.Error("Expected execution to be blocked when circuit breaker is open")
	}
}

func TestLocalCache(t *testing.T) {
	cache := NewLocalCache(10, 1*time.Second)
	ctx := context.Background()
	
	// Test Set and Get
	key := "test-key"
	value := "test-value"
	
	if err := cache.Set(ctx, key, value, 1*time.Second); err != nil {
		t.Errorf("Failed to set value: %v", err)
	}
	
	retrievedValue, err := cache.Get(ctx, key)
	if err != nil {
		t.Errorf("Failed to get value: %v", err)
	}
	
	if retrievedValue != value {
		t.Errorf("Retrieved value doesn't match. Expected %v, got %v", value, retrievedValue)
	}
	
	// Test expiration
	time.Sleep(1100 * time.Millisecond) // Wait for expiration
	
	_, err = cache.Get(ctx, key)
	if err == nil {
		t.Error("Expected error when getting expired value")
	}
	
	// Test deletion
	cache.Set(ctx, key, value, 10*time.Second)
	if err := cache.Delete(ctx, key); err != nil {
		t.Errorf("Failed to delete value: %v", err)
	}
	
	_, err = cache.Get(ctx, key)
	if err == nil {
		t.Error("Expected error when getting deleted value")
	}
}

func TestErrorHandler(t *testing.T) {
	handler := NewErrorHandler(nil)
	
	// Test error classification
	testCases := []struct {
		error    error
		expected ErrorType
	}{
		{&RedisError{Type: ErrorTypeConnection, Message: "connection refused"}, ErrorTypeConnection},
		{&RedisError{Type: ErrorTypeTimeout, Message: "timeout"}, ErrorTypeTimeout},
		{&RedisError{Type: ErrorTypeAuthentication, Message: "auth failed"}, ErrorTypeAuthentication},
		{&RedisError{Type: ErrorTypeNetwork, Message: "network error"}, ErrorTypeNetwork},
	}
	
	for _, tc := range testCases {
		handledErr := handler.Handle(tc.error)
		if handledErr == nil {
			t.Error("Expected error to be handled")
		}
		
		if handledErr.Type != tc.expected {
			t.Errorf("Expected error type %v, got %v", tc.expected, handledErr.Type)
		}
	}
}

func TestHybridRedisClient(t *testing.T) {
	// Test with invalid config to force fallback
	config := DefaultRedisConfig()
	config.Host = "invalid-host"
	config.Port = 9999
	
	hybridClient, err := NewHybridRedisClient(config)
	if err != nil {
		t.Errorf("Failed to create hybrid client: %v", err)
	}
	defer hybridClient.Close()
	
	// Test that Redis is not healthy (should use fallback)
	if hybridClient.IsRedisHealthy() {
		t.Error("Redis should not be healthy with invalid config")
	}
	
	// Test fallback functionality
	ctx := context.Background()
	key := "test-key"
	value := "test-value"
	
	if err := hybridClient.Set(ctx, key, value, 1*time.Second); err != nil {
		t.Errorf("Failed to set value through hybrid client: %v", err)
	}
	
	retrievedValue, err := hybridClient.Get(ctx, key)
	if err != nil {
		t.Errorf("Failed to get value through hybrid client: %v", err)
	}
	
	if retrievedValue != value {
		t.Errorf("Retrieved value doesn't match. Expected %v, got %v", value, retrievedValue)
	}
	
	// Test stats
	stats := hybridClient.GetStats()
	if stats == nil {
		t.Error("Expected stats to be returned")
	}
	
	if stats["redis_healthy"].(bool) {
		t.Error("Redis should not be healthy in stats")
	}
	
	if !stats["fallback_enabled"].(bool) {
		t.Error("Fallback should be enabled in stats")
	}
}
