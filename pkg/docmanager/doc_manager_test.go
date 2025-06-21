// SPDX-License-Identifier: MIT
// Tests SRP pour DocManager - TASK ATOMIQUE 3.1.1.1
package docmanager

import (
	"testing"
	"time"
)

// TestDocManager_SRP vérifie le respect du principe SRP pour DocManager
// MICRO-TASK 3.1.1.1.1 - Validation responsabilité coordination exclusive
func TestDocManager_SRP(t *testing.T) {
	config := Config{
		DatabaseURL:   "postgres://test",
		RedisURL:      "redis://test",
		QDrantURL:     "http://qdrant:6333",
		SyncInterval:  time.Minute * 5,
		PathTracking:  true,
		AutoResolve:   true,
		CrossBranch:   true,
		DefaultBranch: "main",
	}

	manager := NewDocManager(config)

	// Vérifier que DocManager a été créé
	if manager == nil {
		t.Fatal("DocManager should be created successfully")
	}

	// Vérifier responsabilité coordination exclusive
	if manager.GetActiveOperations() != 0 {
		t.Error("DocManager should start with 0 active operations")
	}

	// Test injection de dépendances (respecte Dependency Inversion)
	testPersistence := &TestPersistenceImpl{}
	manager.SetPersistence(testPersistence)

	testCache := &TestCachingImpl{}
	manager.SetCache(testCache)

	testVectorizer := &TestVectorizationImpl{}
	manager.SetVectorizer(testVectorizer)
}

// TestDocManager_CoordinationOnly vérifie que DocManager ne fait que coordonner
// MICRO-TASK 3.1.1.1.2 - Validation aucune logique métier externe
func TestDocManager_CoordinationOnly(t *testing.T) {
	manager := NewDocManager(Config{})

	// Test document pour opérations
	doc := &Document{
		ID:       "test-doc",
		Path:     "/test/doc.md", // Added Path, as it's a field in Document
		Content:  []byte("Test content"),
		Version:  1, // Changed to int
		Metadata: map[string]interface{}{"test": "value"},
	}

	// Test coordination store (sans persistence configurée)
	err := manager.CoordinateDocumentOperation(doc, "store")
	if err != nil {
		t.Logf("Expected behavior - no persistence configured: %v", err)
	}

	// Vérifier que l'opération a été comptée
	if manager.GetActiveOperations() != 0 {
		t.Error("Operation should have completed")
	}

	// Configurer persistence et retester
	testPersistence := &TestPersistenceImpl{}
	manager.SetPersistence(testPersistence)

	err = manager.CoordinateDocumentOperation(doc, "store")
	if err != nil {
		t.Errorf("Store operation should succeed with persistence: %v", err)
	}
}

// TestDocManager_DependencyInjection vérifie l'injection de dépendances
func TestDocManager_DependencyInjection(t *testing.T) {
	manager := NewDocManager(Config{})

	// Test injection des composants spécialisés
	testComponents := map[string]interface{}{
		"persistence":  &TestPersistenceImpl{},
		"cache":        &TestCachingImpl{},
		"vectorizer":   &TestVectorizationImpl{},
		"searcher":     &TestSearchImpl{},
		"synchronizer": &TestSynchronizationImpl{},
		"pathTracker":  &TestPathTrackingImpl{},
	}

	// Injection via setters (respecte Dependency Inversion Principle)
	manager.SetPersistence(testComponents["persistence"].(DocumentPersistence))
	manager.SetCache(testComponents["cache"].(DocumentCaching))
	manager.SetVectorizer(testComponents["vectorizer"].(DocumentVectorization))
	manager.SetSearcher(testComponents["searcher"].(DocumentSearch))
	manager.SetSynchronizer(testComponents["synchronizer"].(DocumentSynchronization))
	manager.SetPathTracker(testComponents["pathTracker"].(DocumentPathTracking))

	// Vérifier que l'injection fonctionne sans erreur
	t.Log("All specialized components injected successfully")
}

// TestDocManager_ThreadSafety vérifie la sécurité thread
func TestDocManager_ThreadSafety(t *testing.T) {
	manager := NewDocManager(Config{})
	manager.SetPersistence(&TestPersistenceImpl{})

	doc := &Document{
		ID:      "concurrent-test",
		Path:    "/concurrent/test.md", // Added Path
		Content: []byte("test"),
		Version: 1,                     // Added Version
	}

	// Test opérations concurrentes
	done := make(chan bool, 3)

	for i := 0; i < 3; i++ {
		go func(id int) {
			err := manager.CoordinateDocumentOperation(doc, "store")
			if err != nil {
				t.Errorf("Concurrent operation %d failed: %v", id, err)
			}
			done <- true
		}(i)
	}

	// Attendre toutes les opérations
	for i := 0; i < 3; i++ {
		<-done
	}

	// Vérifier état final
	if manager.GetActiveOperations() != 0 {
		t.Error("All operations should have completed")
	}
}
