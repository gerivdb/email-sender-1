// SPDX-License-Identifier: MIT
// Package docmanager - Cache Simple Tests
package docmanager

import (
	"testing"
	"time"
)

// TestMemoryCacheBasic teste MemoryCache de base
func TestMemoryCacheBasic(t *testing.T) {
	cache := NewMemoryCache(CacheConfig{MaxSize: 100, TTL: time.Hour})

	// Document de test
	doc := &Document{
		ID:      "test-cache-1",
		Path:    "/test/cache1.md",
		Content: []byte("Test cache content"),
		Version: 1,
	}

	// Test Set
	err := cache.Set("test-key", doc)
	if err != nil {
		t.Fatalf("MemoryCache Set failed: %v", err)
	}

	// Test Get
	retrievedDoc, found := cache.Get("test-key")
	if !found {
		t.Fatal("MemoryCache Get failed: document not found")
	}

	if retrievedDoc.ID != doc.ID {
		t.Errorf("MemoryCache Get returned wrong document ID: expected %s, got %s",
			doc.ID, retrievedDoc.ID)
	}

	// Test GetDocument
	retrievedDoc2, found2 := cache.GetDocument("test-key")
	if !found2 {
		t.Fatal("MemoryCache GetDocument failed: document not found")
	}

	if retrievedDoc2.ID != doc.ID {
		t.Errorf("MemoryCache GetDocument returned wrong document ID: expected %s, got %s",
			doc.ID, retrievedDoc2.ID)
	}

	// Test SetWithTTL
	err = cache.SetWithTTL("ttl-key", doc, time.Millisecond*50)
	if err != nil {
		t.Fatalf("MemoryCache SetWithTTL failed: %v", err)
	}

	// Should be found immediately
	_, found = cache.Get("ttl-key")
	if !found {
		t.Error("Document should be found immediately after SetWithTTL")
	}

	// Test Stats
	stats := cache.Stats()
	t.Logf("Cache stats: %+v", stats)

	// Test Delete
	err = cache.Delete("test-key")
	if err != nil {
		t.Fatalf("MemoryCache Delete failed: %v", err)
	}

	// Verify deletion
	_, found = cache.Get("test-key")
	if found {
		t.Error("MemoryCache Get after delete should not find document")
	}
}
