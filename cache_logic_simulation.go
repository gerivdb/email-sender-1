// Simulation of cache behavior to debug the issue
// This script manually traces through what should happen

package main

import "fmt"

func main() {
	fmt.Println("=== Cache Eviction Logic Simulation ===")

	maxSize := int64(1536 * 4 * 2)   // 12,288 bytes for 2 embeddings
	embeddingSize := int64(1536 * 4) // 6,144 bytes per embedding

	fmt.Printf("Max cache size: %d bytes\n", maxSize)
	fmt.Printf("Size per embedding: %d bytes\n", embeddingSize)
	fmt.Printf("Max embeddings: %d\n", maxSize/embeddingSize)

	// Simulate cache state
	cache := make(map[string]bool)
	evictQueue := []string{}
	cacheSize := int64(0)

	// Step 1: Insert "first"
	fmt.Println("\n--- Step 1: Insert 'first' ---")
	text := "first"
	newSize := embeddingSize

	fmt.Printf("Adding '%s' (size: %d)\n", text, newSize)
	fmt.Printf("Current cache size: %d, after add would be: %d\n", cacheSize, cacheSize+newSize)

	if cacheSize+newSize <= maxSize {
		cache[text] = true
		evictQueue = append(evictQueue, text)
		cacheSize += newSize
		fmt.Printf("Added '%s'. Cache size: %d, Queue: %v\n", text, cacheSize, evictQueue)
	}

	// Step 2: Insert "second"
	fmt.Println("\n--- Step 2: Insert 'second' ---")
	text = "second"
	newSize = embeddingSize

	fmt.Printf("Adding '%s' (size: %d)\n", text, newSize)
	fmt.Printf("Current cache size: %d, after add would be: %d\n", cacheSize, cacheSize+newSize)

	if cacheSize+newSize <= maxSize {
		cache[text] = true
		evictQueue = append(evictQueue, text)
		cacheSize += newSize
		fmt.Printf("Added '%s'. Cache size: %d, Queue: %v\n", text, cacheSize, evictQueue)
	}

	// Step 3: Insert "third" - should trigger eviction
	fmt.Println("\n--- Step 3: Insert 'third' ---")
	text = "third"
	newSize = embeddingSize

	fmt.Printf("Adding '%s' (size: %d)\n", text, newSize)
	fmt.Printf("Current cache size: %d, after add would be: %d\n", cacheSize, cacheSize+newSize)

	// Check if eviction is needed
	if cacheSize+newSize > maxSize {
		fmt.Printf("Eviction needed: %d + %d = %d > %d\n", cacheSize, newSize, cacheSize+newSize, maxSize)

		// Evict oldest (FIFO)
		if len(evictQueue) > 0 {
			oldest := evictQueue[0]
			evictQueue = evictQueue[1:]
			delete(cache, oldest)
			cacheSize -= embeddingSize
			fmt.Printf("Evicted '%s'. Cache size: %d, Queue: %v\n", oldest, cacheSize, evictQueue)
		}
	}

	// Now add "third"
	cache[text] = true
	evictQueue = append(evictQueue, text)
	cacheSize += newSize
	fmt.Printf("Added '%s'. Cache size: %d, Queue: %v\n", text, cacheSize, evictQueue)

	// Final state
	fmt.Println("\n=== Final Cache State ===")
	fmt.Printf("Cache size: %d / %d bytes\n", cacheSize, maxSize)
	fmt.Printf("Evict queue: %v\n", evictQueue)
	fmt.Println("Items in cache:")
	for item := range cache {
		fmt.Printf("  - %s\n", item)
	}

	// Test expected results
	fmt.Println("\n=== Test Results ===")
	tests := []struct {
		item     string
		expected bool
	}{
		{"first", false},
		{"second", true},
		{"third", true},
	}

	allPassed := true
	for _, test := range tests {
		actual := cache[test.item]
		status := "PASS"
		if actual != test.expected {
			status = "FAIL"
			allPassed = false
		}
		fmt.Printf("%s - '%s': in cache = %t (expected: %t)\n", status, test.item, actual, test.expected)
	}

	if allPassed {
		fmt.Println("\n✓ All tests should PASS with correct implementation")
	} else {
		fmt.Println("\n✗ Some tests FAILED - there's a bug in the implementation")
	}
}
