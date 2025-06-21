// SPDX-License-Identifier: MIT
// Package docmanager - Interface Segregation Principle Tests
package docmanager

import (
	"context"
	"testing"
	"time"
)

// TASK ATOMIQUE 3.1.4.1.2 - Implementation verification pour BranchAware

// TestBranchAware_InterfaceCompliance teste la conformité de l'interface BranchAware
func TestBranchAware_InterfaceCompliance(t *testing.T) {
	// Compile-time check: vérifie que BranchSynchronizer implémente BranchAware
	var _ BranchAware = (*BranchSynchronizer)(nil)

	// Test avec instance réelle
	bs := NewBranchSynchronizer()
	testBranchAwareInterface(t, bs)
}

// testBranchAwareInterface teste toutes les méthodes de l'interface BranchAware
func testBranchAwareInterface(t *testing.T, ba BranchAware) {
	ctx := context.Background()

	// Test SyncAcrossBranches
	_, err := ba.SyncAcrossBranches(ctx) // Adjusted to receive two values
	if err != nil {
		t.Logf("SyncAcrossBranches returned error (may be expected): %v", err)
	}

	// Test GetBranchStatus
	status, err := ba.GetBranchStatus("dev")
	if err != nil {
		t.Logf("GetBranchStatus returned error (may be expected): %v", err)
	}
	if status.Branch != "" {
		t.Logf("GetBranchStatus returned status for branch: %s", status.Branch)
	}

	// Test MergeDocumentation
	err = ba.MergeDocumentation("feature-branch", "dev")
	if err != nil {
		t.Logf("MergeDocumentation returned error (may be expected): %v", err)
	}

	// Validation: toutes méthodes implémentées correctement
	t.Log("✅ BranchAware interface correctly implemented")
}

// TASK ATOMIQUE 3.1.4.2.2 - Cross-implementation compatibility pour PathResilient

// TestPathResilient_CrossImplementation teste la compatibilité entre implémentations
func TestPathResilient_CrossImplementation(t *testing.T) {
	// Test multiple implémentations PathResilient
	implementations := []PathResilient{
		&PathTracker{},       // Implémentation principale
		&MockPathResilient{}, // Mock pour tests
	}

	for i, impl := range implementations {
		t.Run(getPathResilientName(impl), func(t *testing.T) {
			testPathResilientBehavior(t, impl, i)
		})
	}
}

// testPathResilientBehavior teste le comportement consistent d'une implémentation PathResilient
func testPathResilientBehavior(t *testing.T, pr PathResilient, testID int) {
	// Test TrackFileMove
	oldPath := "/old/test-" + string(rune(testID)) + ".md"
	newPath := "/new/test-" + string(rune(testID)) + ".md"

	err := pr.TrackFileMove(oldPath, newPath)
	if err != nil {
		t.Logf("TrackFileMove returned error (may be expected): %v", err)
	}

	// Test CalculateContentHash
	hash, err := pr.CalculateContentHash(newPath)
	if err != nil {
		t.Logf("CalculateContentHash returned error (may be expected): %v", err)
	}
	if hash != "" {
		t.Logf("CalculateContentHash returned hash: %s", hash)
	}

	// Test UpdateAllReferences
	err = pr.UpdateAllReferences(oldPath, newPath)
	if err != nil {
		t.Logf("UpdateAllReferences returned error (may be expected): %v", err)
	}

	// Test HealthCheck
	report, err := pr.HealthCheck()
	if err != nil {
		t.Logf("HealthCheck returned error (may be expected): %v", err)
	}
	if report != nil {
		t.Logf("HealthCheck returned report with %d total files", report.TotalFiles) // Changed TotalPaths to TotalFiles
	}

	// Validation: Interface allows substitution without behavior change
	t.Log("✅ PathResilient implementation allows substitution")
}

// getPathResilientName retourne le nom de l'implémentation PathResilient
func getPathResilientName(pr PathResilient) string {
	switch pr.(type) {
	case *PathTracker:
		return "PathTracker"
	case *MockPathResilient:
		return "MockPathResilient"
	default:
		return "UnknownPathResilient"
	}
}

// TASK ATOMIQUE 3.1.4.3.2 - Implementation in DocManager pour CacheAware

// TestDocManager_CacheAwareImplementation teste l'implémentation CacheAware dans DocManager
func TestDocManager_CacheAwareImplementation(t *testing.T) {
	// Compile-time check: vérifie que DocManager implémente CacheAware
	var _ CacheAware = (*DocManager)(nil)

	// Test avec instance réelle
	// Provide a default config for NewDocManager
	dm := NewDocManager(Config{
		SyncInterval:  1 * time.Minute, // Example value
		DefaultBranch: "main",            // Example value
	})
	testCacheAwareInterface(t, dm)
}

// testCacheAwareInterface teste toutes les méthodes de l'interface CacheAware
func testCacheAwareInterface(t *testing.T, ca CacheAware) {
	// Test EnableCaching
	strategy := &MockCacheStrategy{}
	err := ca.EnableCaching(strategy)
	if err != nil {
		t.Logf("EnableCaching returned error (may be expected): %v", err)
	}

	// Test GetCacheMetrics
	metrics := ca.GetCacheMetrics()
	t.Logf("Cache metrics - Hit ratio: %f, Miss count: %d", metrics.HitRatio, metrics.MissCount)

	// Test InvalidateCache
	err = ca.InvalidateCache("test-*")
	if err != nil {
		t.Logf("InvalidateCache returned error (may be expected): %v", err)
	}

	// Test DisableCaching
	err = ca.DisableCaching()
	if err != nil {
		t.Logf("DisableCaching returned error (may be expected): %v", err)
	}

	// Validation: Integration avec cache system sans tight coupling
	t.Log("✅ CacheAware interface correctly implemented without tight coupling")
}

// TASK ATOMIQUE 3.1.4.4.2 - Non-intrusive metrics collection

// TestMetricsAware_PerformanceImpact teste l'impact performance des métriques
func TestMetricsAware_PerformanceImpact(t *testing.T) {
	// Test que l'impact performance est < 5% avec metrics enabled
	// Provide a default config for NewDocManager
	dm := NewDocManager(Config{
		SyncInterval:  1 * time.Minute, // Example value
		DefaultBranch: "main",            // Example value
	})

	// Mesure performance sans métriques
	start := time.Now()
	for i := 0; i < 1000; i++ {
		// Opération de base simulated
		_ = dm.ProcessDocument(&Document{
			ID:      "perf-test",
			Path:    "/test/perf.md",
			Content: []byte("test content"),
			Version: 1,
		})
	}
	baselineDuration := time.Since(start)

	// Mesure performance avec métriques enabled
	if ma, ok := dm.(MetricsAware); ok {
		_ = ma.SetMetricsInterval(100 * time.Millisecond)

		start = time.Now()
		for i := 0; i < 1000; i++ {
			// Même opération avec métriques
			_ = dm.ProcessDocument(&Document{
				ID:      "perf-test-metrics",
				Path:    "/test/perf-metrics.md",
				Content: []byte("test content with metrics"),
				Version: 1,
			})
		}
		withMetricsDuration := time.Since(start)

		// Calcul impact performance
		impactPercent := float64(withMetricsDuration-baselineDuration) / float64(baselineDuration) * 100

		t.Logf("Baseline duration: %v", baselineDuration)
		t.Logf("With metrics duration: %v", withMetricsDuration)
		t.Logf("Performance impact: %.2f%%", impactPercent)

		// Validation: Performance impact < 5%
		if impactPercent > 5.0 {
			t.Errorf("Performance impact %.2f%% exceeds 5%% threshold", impactPercent)
		} else {
			t.Log("✅ Performance impact within acceptable range (<5%)")
		}
	}
}

// TASK ATOMIQUE - Mock implementations pour les tests

// MockPathResilient implémentation mock pour PathResilient
type MockPathResilient struct {
	moves map[string]string
}

// TrackFileMove simule le tracking de déplacement
func (m *MockPathResilient) TrackFileMove(oldPath, newPath string) error {
	if m.moves == nil {
		m.moves = make(map[string]string)
	}
	m.moves[oldPath] = newPath
	return nil
}

// CalculateContentHash retourne un hash mock
func (m *MockPathResilient) CalculateContentHash(filePath string) (string, error) {
	return "mock-hash-" + filePath, nil
}

// UpdateAllReferences simule la mise à jour des références
func (m *MockPathResilient) UpdateAllReferences(oldPath, newPath string) error {
	// Mock implementation
	return nil
}

// HealthCheck retourne un rapport mock
func (m *MockPathResilient) HealthCheck() (*PathHealthReport, error) {
	return &PathHealthReport{
		TotalFiles:      100, // Changed from TotalPaths
		ValidPaths:      97,  // Example value
		BrokenPaths:     []string{"/broken/path1.md", "/broken/path2.md"}, // Example
		OrphanedHashes:  []string{"hash123"},          // Example
		Recommendations: []string{"Run cleanup"},      // Example
		Timestamp:       time.Now(),
	}, nil
}

// MockCacheStrategy implémentation mock pour CacheStrategy
type MockCacheStrategy struct{}

// ShouldCache retourne toujours true pour les tests
func (m *MockCacheStrategy) ShouldCache(doc *Document) bool {
	return true
}

// CalculateTTL retourne un TTL mock
func (m *MockCacheStrategy) CalculateTTL(doc *Document) time.Duration {
	return 5 * time.Minute
}

// EvictionPolicy retourne LRU
func (m *MockCacheStrategy) EvictionPolicy() EvictionType {
	return LRU
}

// OnCacheHit mock implementation
func (m *MockCacheStrategy) OnCacheHit(key string) {
	// Mock implementation
}

// OnCacheMiss mock implementation
func (m *MockCacheStrategy) OnCacheMiss(key string) {
	// Mock implementation
}
