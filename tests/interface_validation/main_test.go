// SPDX-License-Identifier: MIT
// Package interface_validation - Test unitaires d'interface enhancement
package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"email_sender/pkg/docmanager"
)

// TestManagerTypeCompliance teste la conformité de l'interface ManagerType
func TestManagerTypeCompliance(t *testing.T) {
	// Vérification de conformité d'interface
	var _ docmanager.ManagerType = &TestManagerImplementation{}
	t.Log("✅ TestManagerImplementation implements ManagerType interface")
}

// TestManagerTypeLifecycle teste le cycle de vie complet d'un manager
func TestManagerTypeLifecycle(t *testing.T) {
	manager := &TestManagerImplementation{}
	ctx := context.Background()

	// Test Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}

	// Test Health après initialisation
	health := manager.Health()
	if health.Status != "healthy" {
		t.Errorf("Expected status 'healthy', got '%s'", health.Status)
	}

	if len(health.Issues) > 0 {
		t.Errorf("Expected no health issues after initialization, got: %v", health.Issues)
	}

	// Test Process
	testData := map[string]interface{}{
		"type":    "test",
		"content": "test data",
	}

	result, err := manager.Process(ctx, testData)
	if err != nil {
		t.Fatalf("Process failed: %v", err)
	}

	if result == nil {
		t.Error("Process should return non-nil result")
	}

	// Test Metrics
	metrics := manager.Metrics()
	if metrics.RequestCount != 1 {
		t.Errorf("Expected 1 request processed, got %d", metrics.RequestCount)
	}

	if metrics.Status != "active" {
		t.Errorf("Expected status 'active', got '%s'", metrics.Status)
	}

	// Test Shutdown
	err = manager.Shutdown()
	if err != nil {
		t.Fatalf("Shutdown failed: %v", err)
	}

	// Test Health après shutdown
	health = manager.Health()
	if health.Status != "shutdown" {
		t.Errorf("Expected status 'shutdown' after shutdown, got '%s'", health.Status)
	}

	// Test Process après shutdown (devrait échouer)
	_, err = manager.Process(ctx, testData)
	if err == nil {
		t.Error("Process should fail after shutdown")
	}
}

// TestRepositoryCompliance teste la conformité de l'interface Repository
func TestRepositoryCompliance(t *testing.T) {
	// Vérification de conformité d'interface Repository
	var _ docmanager.Repository = &TestRepositoryImplementation{}
	t.Log("✅ TestRepositoryImplementation implements Repository interface")

	// Vérification de conformité d'interface TransactionContext
	var _ docmanager.TransactionContext = &TestRepositoryImplementation{}
	t.Log("✅ TestRepositoryImplementation implements TransactionContext interface")
}

// TestRepositoryContextOperations teste les opérations avec contexte
func TestRepositoryContextOperations(t *testing.T) {
	repo := &TestRepositoryImplementation{}
	ctx := context.Background()

	// Document de test
	doc := &docmanager.Document{
		ID:      "test-context-1",
		Path:    "/test/context1.md",
		Content: []byte("Test context operations"),
		Version: 1,
	}

	// Test StoreWithContext
	err := repo.StoreWithContext(ctx, doc)
	if err != nil {
		t.Fatalf("StoreWithContext failed: %v", err)
	}

	// Test RetrieveWithContext
	retrieved, err := repo.RetrieveWithContext(ctx, doc.ID)
	if err != nil {
		t.Fatalf("RetrieveWithContext failed: %v", err)
	}

	if retrieved.ID != doc.ID {
		t.Errorf("Expected document ID '%s', got '%s'", doc.ID, retrieved.ID)
	}

	// Test SearchWithContext
	query := docmanager.SearchQuery{
		Text: doc.Path,
	}

	results, err := repo.SearchWithContext(ctx, query)
	if err != nil {
		t.Fatalf("SearchWithContext failed: %v", err)
	}

	if len(results) != 1 {
		t.Errorf("Expected 1 search result, got %d", len(results))
	}

	// Test avec contexte annulé
	cancelCtx, cancel := context.WithCancel(ctx)
	cancel() // Annuler immédiatement

	_, err = repo.RetrieveWithContext(cancelCtx, doc.ID)
	if err == nil {
		t.Error("RetrieveWithContext should fail with cancelled context")
	}

	// Test DeleteWithContext
	err = repo.DeleteWithContext(ctx, doc.ID)
	if err != nil {
		t.Fatalf("DeleteWithContext failed: %v", err)
	}

	// Vérifier que le document a été supprimé
	_, err = repo.RetrieveWithContext(ctx, doc.ID)
	if err == nil {
		t.Error("Document should not exist after deletion")
	}
}

// TestRepositoryBatchOperations teste les opérations batch
func TestRepositoryBatchOperations(t *testing.T) {
	repo := &TestRepositoryImplementation{}
	ctx := context.Background()

	// Préparer des opérations batch
	operations := []docmanager.Operation{
		{
			Type: docmanager.OperationStore,
			Document: &docmanager.Document{
				ID:      "batch-test-1",
				Path:    "/batch/test1.md",
				Content: []byte("Batch test content 1"),
				Version: 1,
			},
		},
		{
			Type: docmanager.OperationStore,
			Document: &docmanager.Document{
				ID:      "batch-test-2",
				Path:    "/batch/test2.md",
				Content: []byte("Batch test content 2"),
				Version: 1,
			},
		},
		{
			Type: docmanager.OperationDelete,
			ID:   "batch-test-1", // Supprimer le premier document
		},
	}

	// Exécuter les opérations batch
	results, err := repo.Batch(ctx, operations)
	if err != nil {
		t.Fatalf("Batch operations failed: %v", err)
	}

	if len(results) != len(operations) {
		t.Errorf("Expected %d batch results, got %d", len(operations), len(results))
	}

	// Vérifier les résultats
	for i, result := range results {
		if !result.Success {
			t.Errorf("Batch operation %d failed: %v", i, result.Error)
		}

		if result.OperationID == "" {
			t.Errorf("Batch operation %d should have an operation ID", i)
		}

		if result.ProcessedAt.IsZero() {
			t.Errorf("Batch operation %d should have a processed timestamp", i)
		}
	}

	// Vérifier que batch-test-2 existe toujours et batch-test-1 a été supprimé
	_, err = repo.Retrieve("batch-test-2")
	if err != nil {
		t.Error("batch-test-2 should still exist after batch operations")
	}

	_, err = repo.Retrieve("batch-test-1")
	if err == nil {
		t.Error("batch-test-1 should not exist after batch deletion")
	}
}

// TestRepositoryTransactions teste les transactions
func TestRepositoryTransactions(t *testing.T) {
	repo := &TestRepositoryImplementation{}
	ctx := context.Background()

	// Test transaction successful
	err := repo.Transaction(ctx, func(txCtx docmanager.TransactionContext) error {
		doc := &docmanager.Document{
			ID:      "tx-success",
			Path:    "/tx/success.md",
			Content: []byte("Transaction success test"),
			Version: 1,
		}
		return txCtx.Store(doc)
	})

	if err != nil {
		t.Fatalf("Successful transaction failed: %v", err)
	}

	// Vérifier que le document a été stocké
	_, err = repo.Retrieve("tx-success")
	if err != nil {
		t.Error("Document from successful transaction should exist")
	}

	// Test transaction with error
	expectedError := "test transaction error"
	err = repo.Transaction(ctx, func(txCtx docmanager.TransactionContext) error {
		return &TestError{Message: expectedError}
	})

	if err == nil {
		t.Error("Transaction with error should fail")
	}

	if err.Error() != expectedError {
		t.Errorf("Expected error '%s', got '%s'", expectedError, err.Error())
	}
}

// TestError simple error for testing
type TestError struct {
	Message string
}

func (te *TestError) Error() string {
	return te.Message
}

// BenchmarkManagerTypeOperations benchmark pour les opérations de manager
func BenchmarkManagerTypeOperations(b *testing.B) {
	manager := &TestManagerImplementation{}
	ctx := context.Background()

	// Initialize une seule fois
	_ = manager.Initialize(ctx)

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		// Process
		_, _ = manager.Process(ctx, map[string]int{"iteration": i})

		// Health check occasionnel
		if i%100 == 0 {
			_ = manager.Health()
		}

		// Metrics occasionnel
		if i%50 == 0 {
			_ = manager.Metrics()
		}
	}
}

// BenchmarkRepositoryOperations benchmark pour les opérations de repository
func BenchmarkRepositoryOperations(b *testing.B) {
	repo := &TestRepositoryImplementation{}
	ctx := context.Background()

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		doc := &docmanager.Document{
			ID:      fmt.Sprintf("bench-doc-%d", i),
			Path:    fmt.Sprintf("/bench/doc%d.md", i),
			Content: []byte(fmt.Sprintf("Benchmark content %d", i)),
			Version: 1,
		}

		// Store
		_ = repo.StoreWithContext(ctx, doc)

		// Retrieve occasionnel
		if i%10 == 0 {
			_, _ = repo.RetrieveWithContext(ctx, doc.ID)
		}
	}
}
