package main

import (
	"fmt"
	"sync"
)

// SimpleCacheDebug provides simple cache debugging utilities
type SimpleCacheDebug struct {
	cache map[string]interface{}
	mutex sync.RWMutex
}

// NewSimpleCacheDebug creates a new simple cache debugger
func NewSimpleCacheDebug() *SimpleCacheDebug {
	return &SimpleCacheDebug{
		cache: make(map[string]interface{}),
	}
}

// Set adds a key-value pair to the cache
func (s *SimpleCacheDebug) Set(key string, value interface{}) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	s.cache[key] = value
	fmt.Printf("DEBUG: Set key=%s, value=%v\n", key, value)
}

// Get retrieves a value from the cache
func (s *SimpleCacheDebug) Get(key string) (interface{}, bool) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	value, exists := s.cache[key]
	fmt.Printf("DEBUG: Get key=%s, exists=%t, value=%v\n", key, exists, value)
	return value, exists
}

// Debug prints the current cache state
func (s *SimpleCacheDebug) Debug() {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	fmt.Println("=== Simple Cache Debug State ===")
	for k, v := range s.cache {
		fmt.Printf("  %s: %v\n", k, v)
	}
	fmt.Printf("Total entries: %d\n", len(s.cache))
}
