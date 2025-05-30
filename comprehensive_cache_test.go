package main

import (
	"email_sender/src/providers"
	"fmt"
)

func main() {
	fmt.Println("=== Comprehensive Cache Test Verification ===")

	// Test both scenarios from the failing tests
	testCacheSizeLimit()
	fmt.Println()
	testCacheEvictionOrder()
}

func testCacheSizeLimit() {
	fmt.Println("=== Test 1: Cache Size Limit ===")

	// Configuration: cache for exactly 2 embeddings
	maxSize := int64(1536 * 4 * 2) // 12,288 bytes for 2 embeddings

	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0), // 100% deterministic for testing
	)

	fmt.Printf("Cache max size: %d bytes\n", maxSize)

	// Test sequence: ["text1", "text2", "text3"]
	texts := []string{"text1", "text2", "text3"}

	fmt.Println("Inserting 3 texts (should evict first)...")
	for _, text := range texts {
		_, err := provider.Embed(text)
		if err != nil {
			fmt.Printf("Error embedding %s: %v\n", text, err)
			return
		}
		fmt.Printf("Added '%s', cache size: %d bytes\n", text, provider.GetCacheSize())
	}

	// Verify the state after initial insertions
	fmt.Println("\nAfter initial insertions:")
	fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())

	// Test 1: text1 should have been evicted
	if provider.IsInCache("text1") {
		fmt.Println("❌ FAIL: text1 should have been evicted")
	} else {
		fmt.Println("✅ PASS: text1 was evicted correctly")
	}

	// Test 2: text2 should still be in cache
	if !provider.IsInCache("text2") {
		fmt.Println("❌ FAIL: text2 should still be in cache")
	} else {
		fmt.Println("✅ PASS: text2 is still in cache")
	}

	// Test 3: text3 should still be in cache
	if !provider.IsInCache("text3") {
		fmt.Println("❌ FAIL: text3 should still be in cache")
	} else {
		fmt.Println("✅ PASS: text3 is still in cache")
	}

	// Test 4: Cache size should not exceed limit
	if provider.GetCacheSize() > maxSize {
		fmt.Printf("❌ FAIL: Cache size exceeds limit: %d > %d\n", provider.GetCacheSize(), maxSize)
	} else {
		fmt.Printf("✅ PASS: Cache size within limit: %d <= %d\n", provider.GetCacheSize(), maxSize)
	}

	// Test 5: FIFO behavior - reinserting text1 should evict text2
	fmt.Println("\nReinserting text1 (should evict text2)...")
	_, err := provider.Embed("text1")
	if err != nil {
		fmt.Printf("Error reinserting text1: %v\n", err)
		return
	}

	fmt.Printf("Cache contents after reinserting text1: %v\n", provider.GetCacheContents())

	if provider.IsInCache("text2") {
		fmt.Println("❌ FAIL: text2 should have been evicted after reinserting text1")
	} else {
		fmt.Println("✅ PASS: text2 was evicted after reinserting text1")
	}
}

func testCacheEvictionOrder() {
	fmt.Println("=== Test 2: Cache Eviction Order ===")

	// Configuration: cache for exactly 2 embeddings
	maxSize := int64(1536 * 4 * 2) // 12,288 bytes for 2 embeddings

	provider := providers.NewMockEmbeddingProvider(
		providers.WithMaxCacheSize(maxSize),
		providers.WithCacheHitRate(1.0), // 100% deterministic for testing
	)

	fmt.Printf("Cache max size: %d bytes\n", maxSize)

	// Test sequence: ["first", "second", "third"]
	sequence := []string{"first", "second", "third"}

	fmt.Println("Inserting sequence in order...")
	for i, text := range sequence {
		_, err := provider.Embed(text)
		if err != nil {
			fmt.Printf("Error embedding %s: %v\n", text, err)
			return
		}
		fmt.Printf("Step %d: Added '%s', cache size: %d bytes\n", i+1, text, provider.GetCacheSize())
		fmt.Printf("  Cache contents: %v\n", provider.GetCacheContents())
	}

	fmt.Println("\nFinal verification:")

	// Expected results according to FIFO with cache size for 2 embeddings:
	expectedResults := map[string]bool{
		"first":  false, // should be evicted
		"second": true,  // should remain
		"third":  true,  // should remain
	}

	allPassed := true
	for text, expected := range expectedResults {
		actual := provider.IsInCache(text)
		status := "✅ PASS"
		if actual != expected {
			status = "❌ FAIL"
			allPassed = false
		}
		fmt.Printf("%s - '%s': in cache = %t (expected: %t)\n",
			status, text, actual, expected)
	}

	fmt.Printf("\nOverall Cache Eviction Order test: ")
	if allPassed {
		fmt.Printf("✅ ALL TESTS PASSED\n")
	} else {
		fmt.Printf("❌ SOME TESTS FAILED\n")
	}

	fmt.Printf("Final cache state:\n")
	fmt.Printf("Cache size: %d / %d bytes\n", provider.GetCacheSize(), maxSize)
	fmt.Printf("Cache contents: %v\n", provider.GetCacheContents())
}
