package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestSimpleCacheOperations tests basic cache operations
func TestSimpleCacheOperations(t *testing.T) {
	cache := NewSimpleCacheDebug()

	// Test Set operation
	cache.Set("test_key", "test_value")

	// Test Get operation
	value, exists := cache.Get("test_key")
	assert.True(t, exists, "Key should exist in cache")
	assert.Equal(t, "test_value", value, "Value should match what was set")

	// Test Get non-existent key
	_, exists = cache.Get("non_existent")
	assert.False(t, exists, "Non-existent key should not exist")
}

// TestCacheDebugOutput tests debug output functionality
func TestCacheDebugOutput(t *testing.T) {
	cache := NewSimpleCacheDebug()

	cache.Set("key1", "value1")
	cache.Set("key2", 42)

	// Test debug output (no assertion needed, just ensure it doesn't panic)
	cache.Debug()

	assert.True(t, true, "Debug output completed successfully")
}
