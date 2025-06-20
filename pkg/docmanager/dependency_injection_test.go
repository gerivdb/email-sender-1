// SPDX-License-Identifier: MIT
// Package docmanager - Dependency Injection Tests
package docmanager

import (
	"context"
	"sync"
	"testing"
	"time"
)

// TASK ATOMIQUE 3.1.5.1.2 - Dependency injection enhancement
// TestDocManager_DependencyInjection avec mocks

// MockRepository implémentation mock du Repository
type MockRepository struct {
	documents map[string]*Document
	mu        sync.RWMutex
	connected bool
}

// NewMockRepository crée un nouveau mock repository
func NewMockRepository() *MockRepository {
	return &MockRepository{
		documents: make(map[string]*Document),
		connected: true,
	}
}

// Save sauvegarde un document
func (mr *MockRepository) Save(doc *Document) error {
	if !mr.connected {
		return ErrRepositoryUnavailable
	}
	mr.mu.Lock()
	defer mr.mu.Unlock()
	mr.documents[doc.ID] = doc
	return nil
}

// Get récupère un document
func (mr *MockRepository) Get(id string) (*Document, error) {
	if !mr.connected {
		return nil, ErrRepositoryUnavailable
	}
	mr.mu.RLock()
	defer mr.mu.RUnlock()
	doc, exists := mr.documents[id]
	if !exists {
		return nil, ErrDocumentNotFound
	}
	return doc, nil
}

// Delete supprime un document
func (mr *MockRepository) Delete(id string) error {
	if !mr.connected {
		return ErrRepositoryUnavailable
	}
	mr.mu.Lock()
	defer mr.mu.Unlock()
	delete(mr.documents, id)
	return nil
}

// List liste tous les documents
func (mr *MockRepository) List() ([]*Document, error) {
	if !mr.connected {
		return nil, ErrRepositoryUnavailable
	}
	mr.mu.RLock()
	defer mr.mu.RUnlock()
	docs := make([]*Document, 0, len(mr.documents))
	for _, doc := range mr.documents {
		docs = append(docs, doc)
	}
	return docs, nil
}

// Store alias pour Save
func (mr *MockRepository) Store(doc *Document) error {
	return mr.Save(doc)
}

// Retrieve alias pour Get
func (mr *MockRepository) Retrieve(id string) (*Document, error) {
	return mr.Get(id)
}

// Search recherche des documents (simulation simple)
func (mr *MockRepository) Search(query SearchQuery) ([]*Document, error) {
	if !mr.connected {
		return nil, ErrRepositoryUnavailable
	}
	mr.mu.RLock()
	defer mr.mu.RUnlock()

	// Simulation simple: retourne tous les documents qui contiennent le texte
	var results []*Document
	for _, doc := range mr.documents {
		if query.Text == "" ||
			(doc.Path != "" && doc.Path == query.Text) ||
			(string(doc.Content) != "" && string(doc.Content) == query.Text) {
			results = append(results, doc)
		}
	}
	return results, nil
}

// Enhanced Repository methods (TASK 3.2.1.2.2)

// StoreWithContext stocke un document avec contexte
func (mr *MockRepository) StoreWithContext(ctx context.Context, doc *Document) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return mr.Store(doc)
	}
}

// RetrieveWithContext récupère un document avec contexte
func (mr *MockRepository) RetrieveWithContext(ctx context.Context, id string) (*Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return mr.Retrieve(id)
	}
}

// SearchWithContext recherche des documents avec contexte
func (mr *MockRepository) SearchWithContext(ctx context.Context, query SearchQuery) ([]*Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return mr.Search(query)
	}
}

// DeleteWithContext supprime un document avec contexte
func (mr *MockRepository) DeleteWithContext(ctx context.Context, id string) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return mr.Delete(id)
	}
}

// Batch traite plusieurs opérations en une seule fois
func (mr *MockRepository) Batch(ctx context.Context, operations []Operation) ([]BatchResult, error) {
	var results []BatchResult

	for i, op := range operations {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		result := BatchResult{
			OperationID: string(rune('A' + i)),
			ProcessedAt: time.Now(),
		}

		switch op.Type {
		case OperationStore:
			if op.Document != nil {
				err := mr.Store(op.Document)
				result.Success = err == nil
				result.Error = err
				result.Document = op.Document
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}
		case OperationRetrieve:
			if op.ID != "" {
				doc, err := mr.Retrieve(op.ID)
				result.Success = err == nil
				result.Error = err
				result.Document = doc
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}
		case OperationDelete:
			if op.ID != "" {
				err := mr.Delete(op.ID)
				result.Success = err == nil
				result.Error = err
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}
		}

		results = append(results, result)
	}

	return results, nil
}

// Transaction exécute une fonction dans un contexte transactionnel
func (mr *MockRepository) Transaction(ctx context.Context, fn func(TransactionContext) error) error {
	// Simple transaction mock - pour les tests
	return fn(mr)
}

// Transaction context methods (MockRepository implémente aussi TransactionContext)
func (mr *MockRepository) Commit() error {
	// Mock implementation
	return nil
}

func (mr *MockRepository) Rollback() error {
	// Mock implementation
	return nil
}

func (mr *MockRepository) IsDone() bool {
	// Mock implementation
	return false
}

// MockCache implémentation mock du Cache
type MockCache struct {
	data      map[string]*Document
	mu        sync.RWMutex
	connected bool
	stats     CacheStats
}

// NewMockCache crée un nouveau mock cache
func NewMockCache() *MockCache {
	return &MockCache{
		data:      make(map[string]*Document),
		connected: true,
		stats:     CacheStats{},
	}
}

// Get récupère un document du cache (compatible avec Cache interface)
func (mc *MockCache) Get(key string) (*Document, bool) {
	if !mc.connected {
		return nil, false
	}
	mc.mu.RLock()
	defer mc.mu.RUnlock()
	doc, exists := mc.data[key]
	if exists {
		mc.stats.Hits++
		return doc, true
	} else {
		mc.stats.Misses++
		return nil, false
	}
}

// GetDocument récupère un document du cache (compatible avec DocumentCache interface)
func (mc *MockCache) GetDocument(key string) (*Document, bool) {
	if !mc.connected {
		return nil, false
	}
	mc.mu.RLock()
	defer mc.mu.RUnlock()
	doc, exists := mc.data[key]
	if exists {
		mc.stats.Hits++
	} else {
		mc.stats.Misses++
	}
	return doc, exists
}

// Set stocke un document dans le cache
func (mc *MockCache) Set(key string, doc *Document) error {
	if !mc.connected {
		return ErrCacheUnavailable
	}
	mc.mu.Lock()
	defer mc.mu.Unlock()
	mc.data[key] = doc
	mc.stats.Keys++
	return nil
}

// Delete supprime un document du cache
func (mc *MockCache) Delete(key string) error {
	if !mc.connected {
		return ErrCacheUnavailable
	}
	mc.mu.Lock()
	defer mc.mu.Unlock()
	delete(mc.data, key)
	mc.stats.Keys--
	return nil
}

// Clear vide le cache
func (mc *MockCache) Clear() error {
	if !mc.connected {
		return ErrCacheUnavailable
	}
	mc.mu.Lock()
	defer mc.mu.Unlock()
	mc.data = make(map[string]*Document)
	mc.stats.Keys = 0
	return nil
}

// Stats retourne les statistiques du cache
func (mc *MockCache) Stats() CacheStats {
	mc.mu.RLock()
	defer mc.mu.RUnlock()
	return mc.stats
}

// SetWithTTL stocke un document avec un TTL spécifique
func (mc *MockCache) SetWithTTL(key string, doc *Document, ttl time.Duration) error {
	if !mc.connected {
		return ErrCacheUnavailable
	}
	// Pour un mock simple, on ignore le TTL et on utilise Set normal
	return mc.Set(key, doc)
}

// MockVectorizer implémentation mock du Vectorizer
type MockVectorizer struct {
	vectors   map[string][]float64
	documents map[string]*Document
	mu        sync.RWMutex
	connected bool
}

// NewMockVectorizer crée un nouveau mock vectorizer
func NewMockVectorizer() *MockVectorizer {
	return &MockVectorizer{
		vectors:   make(map[string][]float64),
		documents: make(map[string]*Document),
		connected: true,
	}
}

// GenerateEmbedding génère un embedding pour un texte
func (mv *MockVectorizer) GenerateEmbedding(text string) ([]float64, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}
	// Simulation d'un embedding simple (longueur fixe)
	embedding := make([]float64, 384)
	for i := range embedding {
		embedding[i] = float64(len(text)%256) / 256.0
	}
	return embedding, nil
}

// Index indexe un document (alias pour IndexDocument)
func (mv *MockVectorizer) Index(doc *Document) error {
	return mv.IndexDocument(doc)
}

// IndexDocument indexe un document
func (mv *MockVectorizer) IndexDocument(doc *Document) error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}
	mv.mu.Lock()
	defer mv.mu.Unlock()
	embedding, err := mv.GenerateEmbedding(string(doc.Content))
	if err != nil {
		return err
	}
	mv.vectors[doc.ID] = embedding
	mv.documents[doc.ID] = doc
	return nil
}

// SearchVector recherche par vecteur (alias pour SearchSimilar)
func (mv *MockVectorizer) SearchVector(query string, topK int) ([]*Document, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}
	// Génération du vecteur de requête
	vector, err := mv.GenerateEmbedding(query)
	if err != nil {
		return nil, err
	}
	return mv.SearchSimilar(vector, topK)
}

// SearchSimilar recherche des documents similaires
func (mv *MockVectorizer) SearchSimilar(vector []float64, limit int) ([]*Document, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}
	mv.mu.RLock()
	defer mv.mu.RUnlock()

	// Simulation simple: retourne tous les documents (limité)
	docs := make([]*Document, 0, limit)
	count := 0
	for _, doc := range mv.documents {
		if count >= limit {
			break
		}
		docs = append(docs, doc)
		count++
	}
	return docs, nil
}

// RemoveDocument supprime un document de l'index
func (mv *MockVectorizer) RemoveDocument(id string) error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}
	mv.mu.Lock()
	defer mv.mu.Unlock()
	delete(mv.vectors, id)
	delete(mv.documents, id)
	return nil
}

// TestDocManager_DependencyInjection_Basic teste l'injection de dépendances de base
func TestDocManager_DependencyInjection_Basic(t *testing.T) {
	// Arrange
	mockRepo := NewMockRepository()
	mockCache := NewMockCache()
	mockVectorizer := NewMockVectorizer()

	// Act
	dm := NewDocManagerWithDependencies(mockRepo, mockCache, mockVectorizer)

	// Assert
	if dm == nil {
		t.Fatal("NewDocManagerWithDependencies returned nil")
	}

	if dm.Repo == nil {
		t.Error("Repository not injected correctly")
	}

	if dm.Cache == nil {
		t.Error("Cache not injected correctly")
	}

	if dm.Vectorizer == nil {
		t.Error("Vectorizer not injected correctly")
	}

	// Vérifier la configuration par défaut
	if dm.Config.SyncInterval != 30*time.Second {
		t.Errorf("Expected SyncInterval 30s, got %v", dm.Config.SyncInterval)
	}

	if !dm.Config.PathTracking {
		t.Error("Expected PathTracking to be true")
	}

	if !dm.Config.AutoResolve {
		t.Error("Expected AutoResolve to be true")
	}

	if !dm.Config.CrossBranch {
		t.Error("Expected CrossBranch to be true")
	}

	if dm.Config.DefaultBranch != "main" {
		t.Errorf("Expected DefaultBranch 'main', got %s", dm.Config.DefaultBranch)
	}
}

// TestDocManager_DependencyInjection_Integration teste l'intégration complète
func TestDocManager_DependencyInjection_Integration(t *testing.T) {
	// Arrange
	mockRepo := NewMockRepository()
	mockCache := NewMockCache()
	mockVectorizer := NewMockVectorizer()

	dm := NewDocManagerWithDependencies(mockRepo, mockCache, mockVectorizer)

	// Test document
	doc := &Document{
		ID:      "test-doc-1",
		Path:    "/test/document.md",
		Content: []byte("This is a test document for dependency injection"),
		Metadata: map[string]interface{}{
			"tags": []string{"test", "integration"},
		},
		Version: 1,
	}

	// Act & Assert - Repository integration
	err := dm.Repo.Save(doc)
	if err != nil {
		t.Fatalf("Failed to save document: %v", err)
	}

	retrievedDoc, err := dm.Repo.Get(doc.ID)
	if err != nil {
		t.Fatalf("Failed to get document: %v", err)
	}

	if retrievedDoc.ID != doc.ID {
		t.Errorf("Expected ID %s, got %s", doc.ID, retrievedDoc.ID)
	}
	// Act & Assert - Cache integration
	cachedDoc, found := dm.Cache.Get(doc.ID)
	if found {
		t.Error("Document should not be in cache initially")
	}

	err = dm.Cache.Set(doc.ID, doc)
	if err != nil {
		t.Fatalf("Failed to set cache: %v", err)
	}

	cachedDoc, found = dm.Cache.Get(doc.ID)
	if !found {
		t.Fatal("Document should be in cache after Set")
	}

	if cachedDoc.ID != doc.ID {
		t.Errorf("Expected cached ID %s, got %s", doc.ID, cachedDoc.ID)
	}

	// Act & Assert - Vectorizer integration
	err = dm.Vectorizer.IndexDocument(doc)
	if err != nil {
		t.Fatalf("Failed to index document: %v", err)
	}

	embedding, err := dm.Vectorizer.GenerateEmbedding(string(doc.Content))
	if err != nil {
		t.Fatalf("Failed to generate embedding: %v", err)
	}

	if len(embedding) == 0 {
		t.Error("Embedding should not be empty")
	}

	similar, err := dm.Vectorizer.SearchSimilar(embedding, 5)
	if err != nil {
		t.Fatalf("Failed to search similar: %v", err)
	}

	if len(similar) == 0 {
		t.Error("Should find at least one similar document")
	}
}

// TestDocManager_DependencyInjection_NilDependencies teste la gestion des dépendances nil
func TestDocManager_DependencyInjection_NilDependencies(t *testing.T) {
	// Test avec dépendances nil (ne devrait pas panic)
	dm := NewDocManagerWithDependencies(nil, nil, nil)

	if dm == nil {
		t.Fatal("NewDocManagerWithDependencies should not return nil even with nil dependencies")
	}

	// Les dépendances nil sont acceptées (lazy initialization)
	if dm.Repo != nil {
		t.Error("Expected nil repository")
	}

	if dm.Cache != nil {
		t.Error("Expected nil cache")
	}

	if dm.Vectorizer != nil {
		t.Error("Expected nil vectorizer")
	}
}

// BenchmarkDocManager_DependencyInjection benchmark de l'injection de dépendances
func BenchmarkDocManager_DependencyInjection(b *testing.B) {
	mockRepo := NewMockRepository()
	mockCache := NewMockCache()
	mockVectorizer := NewMockVectorizer()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		dm := NewDocManagerWithDependencies(mockRepo, mockCache, mockVectorizer)
		_ = dm
	}
}

// BenchmarkDocManager_DependencyInjection_Operations benchmark des opérations
func BenchmarkDocManager_DependencyInjection_Operations(b *testing.B) {
	mockRepo := NewMockRepository()
	mockCache := NewMockCache()
	mockVectorizer := NewMockVectorizer()

	dm := NewDocManagerWithDependencies(mockRepo, mockCache, mockVectorizer)

	doc := &Document{
		ID:      "bench-doc",
		Path:    "/benchmark/document.md",
		Content: []byte("This is a benchmark document"),
		Metadata: map[string]interface{}{
			"tags": []string{"benchmark"},
		},
		Version: 1,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// Repository operation
		err := dm.Repo.Save(doc)
		if err != nil {
			b.Fatalf("Save failed: %v", err)
		}

		// Cache operation
		err = dm.Cache.Set(doc.ID, doc)
		if err != nil {
			b.Fatalf("Cache set failed: %v", err)
		}

		// Vectorizer operation
		err = dm.Vectorizer.IndexDocument(doc)
		if err != nil {
			b.Fatalf("Index failed: %v", err)
		}
	}
}
