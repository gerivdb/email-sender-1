// SPDX-License-Identifier: MIT
// Package docmanager - Tests Plugin Registry Open/Closed Principle
package docmanager

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"
)

// TestPluginRegistry_ConcurrentRegistration teste l'enregistrement concurrent
func TestPluginRegistry_ConcurrentRegistration(t *testing.T) {
	// TASK ATOMIQUE 3.1.2.1.2 - Plugin registry implementation
	registry := NewPluginRegistry()

	// Test concurrent registration
	var wg sync.WaitGroup
	numPlugins := 10

	for i := 0; i < numPlugins; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			plugin := &MockPlugin{
				name:    fmt.Sprintf("test-plugin-%d", id),
				version: "1.0.0",
			}
			err := registry.Register(plugin)
			if err != nil {
				t.Errorf("Failed to register plugin %d: %v", id, err)
			}
		}(i)
	}

	wg.Wait()

	// Vérifier que tous les plugins sont enregistrés
	if registry.Count() != numPlugins {
		t.Errorf("Expected %d plugins, got %d", numPlugins, registry.Count())
	}
}

// TestPluginRegistry_VersionConflictDetection teste la détection de conflits
func TestPluginRegistry_VersionConflictDetection(t *testing.T) {
	registry := NewPluginRegistry()

	// Enregistrer un plugin
	plugin1 := &MockPlugin{name: "test", version: "1.0.0"}
	err := registry.Register(plugin1)
	if err != nil {
		t.Fatalf("Failed to register first plugin: %v", err)
	}

	// Tenter d'enregistrer la même version
	plugin2 := &MockPlugin{name: "test", version: "1.0.0"}
	err = registry.Register(plugin2)
	if err == nil {
		t.Error("Expected error for duplicate version")
	}

	// Enregistrer une nouvelle version (doit réussir)
	plugin3 := &MockPlugin{name: "test", version: "1.1.0"}
	err = registry.Register(plugin3)
	if err != nil {
		t.Errorf("Failed to register updated version: %v", err)
	}
}

// TestCacheStrategyFactory_MultipleBehavior teste la création de stratégies multiples
func TestCacheStrategyFactory_MultipleBehavior(t *testing.T) {
	// TASK ATOMIQUE 3.1.2.2.2 - Strategy factory pattern
	factory := NewCacheStrategyFactory()

	// Tester toutes les stratégies par défaut
	strategies := []string{"lru", "lfu", "ttl", "size_based"}

	for _, strategyName := range strategies {
		strategy, err := factory.CreateStrategy(strategyName)
		if err != nil {
			t.Errorf("Failed to create strategy %s: %v", strategyName, err)
		}

		// Tester le comportement de base
		doc := &Document{
			ID:          "test",
			Content:     "test content",
			LastUpdated: time.Now(),
		}

		shouldCache := strategy.ShouldCache(doc)
		ttl := strategy.CalculateTTL(doc)
		policy := strategy.EvictionPolicy()

		if !shouldCache {
			t.Errorf("Strategy %s should cache test document", strategyName)
		}
		if ttl <= 0 {
			t.Errorf("Strategy %s should return positive TTL", strategyName)
		}
		if policy < 0 {
			t.Errorf("Strategy %s should return valid eviction policy", strategyName)
		}
	}
}

// TestVectorizationStrategy_RuntimeSwitch teste le changement de stratégies à l'exécution
func TestVectorizationStrategy_RuntimeSwitch(t *testing.T) {
	// TASK ATOMIQUE 3.1.2.3.2 - Strategy configuration system
	factory := NewVectorizationStrategyFactory()

	configs := []VectorizationConfig{
		{Strategy: "local", ModelName: "test-model", Dimensions: 384},
		{Strategy: "openai", ModelName: "ada-002", Dimensions: 1536, APIKey: "test-key"},
		{Strategy: "cohere", ModelName: "embed-v3", Dimensions: 1024, APIKey: "test-key"},
	}

	text := "This is a test document for vectorization"

	for _, config := range configs {
		strategy, err := factory.LoadVectorizationStrategy(config)
		if err != nil {
			t.Errorf("Failed to load strategy %s: %v", config.Strategy, err)
			continue
		}

		// Tester la génération d'embedding
		embedding, err := strategy.GenerateEmbedding(text)
		if err != nil {
			t.Errorf("Failed to generate embedding with %s: %v", config.Strategy, err)
			continue
		}

		expectedDim := strategy.OptimalDimensions()
		if len(embedding) != expectedDim {
			t.Errorf("Strategy %s: expected %d dimensions, got %d", config.Strategy, expectedDim, len(embedding))
		}

		// Tester compatibilité output
		if len(embedding) == 0 {
			t.Errorf("Strategy %s generated empty embedding", config.Strategy)
		}
	}
}

// TestDocManager_ExtensionCapabilities teste les capacités d'extension
func TestDocManager_ExtensionCapabilities(t *testing.T) {
	// TASK ATOMIQUE 3.1.2.1.3 - Dynamic manager extension
	dm := NewDocManager(Config{})

	// Test plugin registration
	plugin := &MockPlugin{name: "test-extension", version: "1.0.0"}
	err := dm.RegisterPlugin(plugin)
	if err != nil {
		t.Errorf("Failed to register plugin: %v", err)
	}

	// Test plugin listing
	plugins := dm.ListPlugins()
	if len(plugins) != 1 {
		t.Errorf("Expected 1 plugin, got %d", len(plugins))
	}

	// Test cache strategy loading
	cacheStrategies := dm.ListCacheStrategies()
	if len(cacheStrategies) == 0 {
		t.Error("No cache strategies available")
	}

	strategy, err := dm.LoadCacheStrategy("lru")
	if err != nil {
		t.Errorf("Failed to load LRU strategy: %v", err)
	}
	if strategy == nil {
		t.Error("Strategy should not be nil")
	}

	// Test vectorization strategy loading
	vectorStrategies := dm.ListVectorizationStrategies()
	if len(vectorStrategies) == 0 {
		t.Error("No vectorization strategies available")
	}

	config := VectorizationConfig{Strategy: "local", Dimensions: 100}
	vectorStrategy, err := dm.LoadVectorizationStrategy(config)
	if err != nil {
		t.Errorf("Failed to load vectorization strategy: %v", err)
	}
	if vectorStrategy == nil {
		t.Error("Vectorization strategy should not be nil")
	}
}

// MockPlugin plugin de test
type MockPlugin struct {
	name           string
	version        string
	initialized    bool
	shutdownCalled bool
}

func (mp *MockPlugin) Name() string {
	return mp.name
}

func (mp *MockPlugin) Version() string {
	return mp.version
}

func (mp *MockPlugin) Initialize() error {
	mp.initialized = true
	return nil
}

func (mp *MockPlugin) Execute(ctx context.Context, input interface{}) (interface{}, error) {
	return "mock result", nil
}

func (mp *MockPlugin) Shutdown() error {
	mp.shutdownCalled = true
	return nil
}
