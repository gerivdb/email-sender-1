// SPDX-License-Identifier: MIT
// Package docmanager - Interface Enhancement Tests
package docmanager

import (
	"context"
	"testing"
	"time"
)

// TASK ATOMIQUE 3.2.1.1.2 - Test compliance check toutes implémentations

// TestManagerType_InterfaceCompliance teste la conformité de l'interface ManagerType
func TestManagerType_InterfaceCompliance(t *testing.T) {
	// Test que MockDocManager implémente ManagerType
	var _ ManagerType = &MockDocManager{}
	t.Log("MockDocManager satisfies ManagerType interface")
}

// MockDocManager implémentation mock pour les tests
type MockDocManager struct {
	initialized   bool
	shutdown      bool
	processCount  int64
	errorCount    int64
	lastProcessed time.Time
}

// Initialize initialise le manager
func (mdm *MockDocManager) Initialize(ctx context.Context) error {
	mdm.initialized = true
	return nil
}

// Process traite des données
func (mdm *MockDocManager) Process(ctx context.Context, data interface{}) (interface{}, error) {
	if !mdm.initialized {
		mdm.errorCount++
		return nil, ErrRepositoryUnavailable
	}

	mdm.processCount++
	mdm.lastProcessed = time.Now()

	// Simulation de traitement
	if data == nil {
		mdm.errorCount++
		return nil, ErrInvalidDocument
	}

	return map[string]interface{}{
		"processed": true,
		"timestamp": mdm.lastProcessed,
		"data":      data,
	}, nil
}

// Shutdown arrête le manager
func (mdm *MockDocManager) Shutdown() error {
	mdm.shutdown = true
	mdm.initialized = false
	return nil
}

// Health retourne le statut de santé
func (mdm *MockDocManager) Health() HealthStatus {
	status := "healthy"
	var issues []string

	if !mdm.initialized {
		status = "not_initialized"
		issues = append(issues, "Manager not initialized")
	}

	if mdm.shutdown {
		status = "shutdown"
		issues = append(issues, "Manager is shutdown")
	}

	if mdm.errorCount > 10 {
		status = "degraded"
		issues = append(issues, "High error count detected")
	}

	return HealthStatus{
		Status:    status,
		LastCheck: time.Now(),
		Issues:    issues,
		Details: map[string]interface{}{
			"initialized":   mdm.initialized,
			"shutdown":      mdm.shutdown,
			"process_count": mdm.processCount,
			"error_count":   mdm.errorCount,
		},
	}
}

// Metrics retourne les métriques du manager
func (mdm *MockDocManager) Metrics() ManagerMetrics {
	avgResponseTime := time.Duration(0)
	if mdm.processCount > 0 {
		avgResponseTime = time.Millisecond * 50 // simulation
	}

	status := "active"
	if !mdm.initialized {
		status = "inactive"
	}
	if mdm.shutdown {
		status = "shutdown"
	}

	return ManagerMetrics{
		RequestCount:        mdm.processCount,
		AverageResponseTime: avgResponseTime,
		ErrorCount:          mdm.errorCount,
		LastProcessedAt:     mdm.lastProcessed,
		ResourceUsage: map[string]interface{}{
			"memory_mb":   25.5,
			"cpu_percent": 5.2,
			"goroutines":  3,
		},
		Status: status,
	}
}

// TestManagerType_Implementation teste l'implémentation complète
func TestManagerType_Implementation(t *testing.T) {
	manager := &MockDocManager{}
	ctx := context.Background()

	// Test Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}

	if !manager.initialized {
		t.Error("Manager should be initialized")
	}

	// Test Health après initialisation
	health := manager.Health()
	if health.Status != "healthy" {
		t.Errorf("Expected status 'healthy', got %s", health.Status)
	}

	if len(health.Issues) > 0 {
		t.Errorf("Expected no issues after initialization, got %v", health.Issues)
	}

	// Test Process avec données valides
	testData := map[string]interface{}{
		"type":    "document",
		"content": "test content",
	}

	result, err := manager.Process(ctx, testData)
	if err != nil {
		t.Fatalf("Process failed: %v", err)
	}

	if result == nil {
		t.Error("Process should return result")
	}

	resultMap, ok := result.(map[string]interface{})
	if !ok {
		t.Error("Result should be a map")
	} else {
		if processed, exists := resultMap["processed"]; !exists || processed != true {
			t.Error("Result should indicate successful processing")
		}
	}

	// Test Process avec données invalides
	_, err = manager.Process(ctx, nil)
	if err == nil {
		t.Error("Process should fail with nil data")
	}

	// Test Metrics après traitement
	metrics := manager.Metrics()
	if metrics.RequestCount != 2 { // 1 succès + 1 échec
		t.Errorf("Expected 2 requests, got %d", metrics.RequestCount)
	}

	if metrics.ErrorCount != 1 {
		t.Errorf("Expected 1 error, got %d", metrics.ErrorCount)
	}

	if metrics.Status != "active" {
		t.Errorf("Expected status 'active', got %s", metrics.Status)
	}

	// Test Shutdown
	err = manager.Shutdown()
	if err != nil {
		t.Fatalf("Shutdown failed: %v", err)
	}

	if !manager.shutdown {
		t.Error("Manager should be shutdown")
	}

	// Test Health après shutdown
	health = manager.Health()
	if health.Status != "shutdown" {
		t.Errorf("Expected status 'shutdown', got %s", health.Status)
	}

	// Test Metrics après shutdown
	metrics = manager.Metrics()
	if metrics.Status != "shutdown" {
		t.Errorf("Expected metrics status 'shutdown', got %s", metrics.Status)
	}
}

// TASK ATOMIQUE 3.2.1.2.2 - Test transactional behavior, batch efficiency

// MockRepositoryEnhanced repository mock avec nouvelles fonctionnalités
type MockRepositoryEnhanced struct {
	documents    map[string]*Document
	operations   []Operation
	transactions []func(TransactionContext) error
	batchCount   int64
}

// NewMockRepositoryEnhanced crée un nouveau repository enhanced mock
func NewMockRepositoryEnhanced() *MockRepositoryEnhanced {
	return &MockRepositoryEnhanced{
		documents: make(map[string]*Document),
	}
}

// Méthodes existantes (implémentation basique)
func (mre *MockRepositoryEnhanced) Store(doc *Document) error {
	mre.documents[doc.ID] = doc
	return nil
}

func (mre *MockRepositoryEnhanced) Retrieve(id string) (*Document, error) {
	doc, exists := mre.documents[id]
	if !exists {
		return nil, ErrDocumentNotFound
	}
	return doc, nil
}

func (mre *MockRepositoryEnhanced) Search(query SearchQuery) ([]*Document, error) {
	var results []*Document
	for _, doc := range mre.documents {
		results = append(results, doc)
	}
	return results, nil
}

func (mre *MockRepositoryEnhanced) Save(doc *Document) error {
	return mre.Store(doc)
}

func (mre *MockRepositoryEnhanced) Get(id string) (*Document, error) {
	return mre.Retrieve(id)
}

func (mre *MockRepositoryEnhanced) Delete(id string) error {
	delete(mre.documents, id)
	return nil
}

func (mre *MockRepositoryEnhanced) List() ([]*Document, error) {
	var docs []*Document
	for _, doc := range mre.documents {
		docs = append(docs, doc)
	}
	return docs, nil
}

// Nouvelles méthodes avec context
func (mre *MockRepositoryEnhanced) StoreWithContext(ctx context.Context, doc *Document) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return mre.Store(doc)
	}
}

func (mre *MockRepositoryEnhanced) RetrieveWithContext(ctx context.Context, id string) (*Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return mre.Retrieve(id)
	}
}

func (mre *MockRepositoryEnhanced) SearchWithContext(ctx context.Context, query SearchQuery) ([]*Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return mre.Search(query)
	}
}

func (mre *MockRepositoryEnhanced) DeleteWithContext(ctx context.Context, id string) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return mre.Delete(id)
	}
}

// Batch traite plusieurs opérations en une seule fois
func (mre *MockRepositoryEnhanced) Batch(ctx context.Context, operations []Operation) ([]BatchResult, error) {
	mre.batchCount++
	var results []BatchResult

	for i, op := range operations {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		result := BatchResult{
			OperationID: string(rune('A' + i)), // Simple ID generation
			ProcessedAt: time.Now(),
		}

		switch op.Type {
		case OperationStore:
			if op.Document != nil {
				err := mre.Store(op.Document)
				result.Success = err == nil
				result.Error = err
				result.Document = op.Document
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}

		case OperationRetrieve:
			if op.ID != "" {
				doc, err := mre.Retrieve(op.ID)
				result.Success = err == nil
				result.Error = err
				result.Document = doc
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}

		case OperationDelete:
			if op.ID != "" {
				err := mre.Delete(op.ID)
				result.Success = err == nil
				result.Error = err
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}

		case OperationUpdate:
			if op.Document != nil && op.Document.ID != "" {
				err := mre.Store(op.Document) // Simulation d'update
				result.Success = err == nil
				result.Error = err
				result.Document = op.Document
			} else {
				result.Success = false
				result.Error = ErrInvalidDocument
			}
		}

		results = append(results, result)
	}

	return results, nil
}

// MockTransactionContext context de transaction mock
type MockTransactionContext struct {
	*MockRepositoryEnhanced
	committed  bool
	rolledBack bool
}

// Commit valide la transaction
func (mtc *MockTransactionContext) Commit() error {
	mtc.committed = true
	return nil
}

// Rollback annule la transaction
func (mtc *MockTransactionContext) Rollback() error {
	mtc.rolledBack = true
	return nil
}

// IsDone vérifie si la transaction est terminée
func (mtc *MockTransactionContext) IsDone() bool {
	return mtc.committed || mtc.rolledBack
}

// Transaction exécute une fonction dans un contexte transactionnel
func (mre *MockRepositoryEnhanced) Transaction(ctx context.Context, fn func(TransactionContext) error) error {
	// Créer un contexte de transaction
	txCtx := &MockTransactionContext{
		MockRepositoryEnhanced: &MockRepositoryEnhanced{
			documents: make(map[string]*Document),
		},
	}

	// Copier l'état actuel
	for k, v := range mre.documents {
		txCtx.documents[k] = v
	}

	// Exécuter la fonction
	err := fn(txCtx)
	if err != nil {
		// En cas d'erreur, rollback automatique
		return txCtx.Rollback()
	}

	// Si pas d'erreur et pas encore committé, commit automatique
	if !txCtx.IsDone() {
		err = txCtx.Commit()
		if err != nil {
			return err
		}

		// Appliquer les changements au repository principal
		mre.documents = txCtx.documents
	}

	return nil
}

// TestRepository_EnhancedOperations teste les nouvelles opérations repository
func TestRepository_EnhancedOperations(t *testing.T) {
	repo := NewMockRepositoryEnhanced()
	ctx := context.Background()

	// Test que le mock implémente l'interface Repository étendue
	var _ Repository = repo

	// Test StoreWithContext
	doc := &Document{
		ID:      "test-doc-1",
		Path:    "/test/doc1.md",
		Content: []byte("Test document content"),
		Version: 1,
	}

	err := repo.StoreWithContext(ctx, doc)
	if err != nil {
		t.Fatalf("StoreWithContext failed: %v", err)
	}

	// Test RetrieveWithContext
	retrievedDoc, err := repo.RetrieveWithContext(ctx, doc.ID)
	if err != nil {
		t.Fatalf("RetrieveWithContext failed: %v", err)
	}

	if retrievedDoc.ID != doc.ID {
		t.Errorf("Expected document ID %s, got %s", doc.ID, retrievedDoc.ID)
	}

	// Test avec contexte annulé
	cancelCtx, cancel := context.WithCancel(ctx)
	cancel() // Annuler immédiatement

	_, err = repo.RetrieveWithContext(cancelCtx, doc.ID)
	if err == nil {
		t.Error("RetrieveWithContext should fail with cancelled context")
	}
}

// TestRepository_BatchOperations teste les opérations batch
func TestRepository_BatchOperations(t *testing.T) {
	repo := NewMockRepositoryEnhanced()
	ctx := context.Background()

	// Préparer des opérations batch
	operations := []Operation{
		{
			Type: OperationStore,
			Document: &Document{
				ID:      "batch-doc-1",
				Path:    "/batch/doc1.md",
				Content: []byte("Batch document 1"),
				Version: 1,
			},
		},
		{
			Type: OperationStore,
			Document: &Document{
				ID:      "batch-doc-2",
				Path:    "/batch/doc2.md",
				Content: []byte("Batch document 2"),
				Version: 1,
			},
		},
		{
			Type: OperationRetrieve,
			ID:   "batch-doc-1",
		},
		{
			Type: OperationDelete,
			ID:   "batch-doc-2",
		},
	}

	// Exécuter les opérations batch
	results, err := repo.Batch(ctx, operations)
	if err != nil {
		t.Fatalf("Batch failed: %v", err)
	}

	if len(results) != len(operations) {
		t.Errorf("Expected %d results, got %d", len(operations), len(results))
	}

	// Vérifier les résultats
	for i, result := range results {
		if !result.Success {
			t.Errorf("Operation %d failed: %v", i, result.Error)
		}

		if result.OperationID == "" {
			t.Errorf("Operation %d should have an ID", i)
		}

		if result.ProcessedAt.IsZero() {
			t.Errorf("Operation %d should have a processed timestamp", i)
		}
	}

	// Vérifier que batch-doc-1 existe et batch-doc-2 a été supprimé
	_, err = repo.Retrieve("batch-doc-1")
	if err != nil {
		t.Error("batch-doc-1 should exist after batch operations")
	}

	_, err = repo.Retrieve("batch-doc-2")
	if err == nil {
		t.Error("batch-doc-2 should not exist after deletion")
	}

	// Vérifier que le compteur batch a été incrémenté
	if repo.batchCount != 1 {
		t.Errorf("Expected batch count 1, got %d", repo.batchCount)
	}
}

// TestRepository_TransactionalBehavior teste le comportement transactionnel
func TestRepository_TransactionalBehavior(t *testing.T) {
	repo := NewMockRepositoryEnhanced()
	ctx := context.Background()

	// Ajouter un document initial
	initialDoc := &Document{
		ID:      "initial-doc",
		Path:    "/initial/doc.md",
		Content: []byte("Initial document"),
		Version: 1,
	}

	err := repo.Store(initialDoc)
	if err != nil {
		t.Fatalf("Failed to store initial document: %v", err)
	}

	// Test transaction réussie
	err = repo.Transaction(ctx, func(txRepo TransactionContext) error {
		// Ajouter un document dans la transaction
		newDoc := &Document{
			ID:      "tx-doc-1",
			Path:    "/tx/doc1.md",
			Content: []byte("Transaction document 1"),
			Version: 1,
		}

		err := txRepo.Store(newDoc)
		if err != nil {
			return err
		}

		// Modifier le document initial
		initialDoc.Content = []byte("Modified in transaction")
		initialDoc.Version = 2
		return txRepo.Store(initialDoc)
	})
	if err != nil {
		t.Fatalf("Transaction failed: %v", err)
	}

	// Vérifier que les changements ont été appliqués
	modifiedDoc, err := repo.Retrieve("initial-doc")
	if err != nil {
		t.Error("Modified document should exist")
	} else if string(modifiedDoc.Content) != "Modified in transaction" {
		t.Error("Document should be modified by transaction")
	}

	txDoc, err := repo.Retrieve("tx-doc-1")
	if err != nil {
		t.Error("Transaction document should exist")
	} else if txDoc.ID != "tx-doc-1" {
		t.Error("Transaction document should have correct ID")
	}

	// Test transaction échouée (rollback)
	err = repo.Transaction(ctx, func(txRepo TransactionContext) error {
		// Ajouter un document
		failDoc := &Document{
			ID:      "fail-doc",
			Path:    "/fail/doc.md",
			Content: []byte("This should be rolled back"),
			Version: 1,
		}

		err := txRepo.Store(failDoc)
		if err != nil {
			return err
		}

		// Simuler une erreur
		return ErrInvalidDocument
	})

	if err == nil {
		t.Error("Transaction should have failed")
	}

	// Vérifier que le document n'a pas été ajouté (rollback)
	_, err = repo.Retrieve("fail-doc")
	if err == nil {
		t.Error("fail-doc should not exist after rollback")
	}
}

// BenchmarkRepository_BatchOperations benchmark des opérations batch
func BenchmarkRepository_BatchOperations(b *testing.B) {
	repo := NewMockRepositoryEnhanced()
	ctx := context.Background()

	// Préparer des opérations batch
	operations := make([]Operation, 100)
	for i := 0; i < 100; i++ {
		operations[i] = Operation{
			Type: OperationStore,
			Document: &Document{
				ID:      string(rune('A'+(i%26))) + string(rune('0'+(i/26))),
				Path:    "/bench/doc.md",
				Content: []byte("Benchmark document"),
				Version: 1,
			},
		}
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_, err := repo.Batch(ctx, operations)
		if err != nil {
			b.Fatalf("Batch failed: %v", err)
		}
	}
}

// TestManagerType_LifecycleCompliance teste la conformité du cycle de vie
func TestManagerType_LifecycleCompliance(t *testing.T) {
	manager := &MockDocManager{}
	ctx := context.Background()

	// Test cycle de vie complet
	// 1. Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}

	// 2. Process multiple times
	for i := 0; i < 5; i++ {
		_, err := manager.Process(ctx, map[string]interface{}{"iter": i})
		if err != nil {
			t.Errorf("Process iteration %d failed: %v", i, err)
		}
	}

	// 3. Check metrics
	metrics := manager.Metrics()
	if metrics.RequestCount != 5 {
		t.Errorf("Expected 5 requests, got %d", metrics.RequestCount)
	}

	// 4. Shutdown
	err = manager.Shutdown()
	if err != nil {
		t.Fatalf("Shutdown failed: %v", err)
	}

	// 5. Verify post-shutdown state
	health := manager.Health()
	if health.Status != "shutdown" {
		t.Errorf("Expected shutdown status, got %s", health.Status)
	}

	// 6. Process should fail after shutdown
	_, err = manager.Process(ctx, map[string]interface{}{"post_shutdown": true})
	if err == nil {
		t.Error("Process should fail after shutdown")
	}
}
