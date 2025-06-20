// SPDX-License-Identifier: MIT
// Package docmanager_test - Test d'interface enhancement externes
package docmanager_test

import (
	"context"
	"testing"
	"time"

	"email_sender/pkg/docmanager"
)

// TestManagerTypeInterface teste l'interface ManagerType 
func TestManagerTypeInterface(t *testing.T) {
	manager := &TestManager{}

	// Vérification de conformité d'interface
	var _ docmanager.ManagerType = manager

	// Test cycle de vie complet
	ctx := context.Background()

	// Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}

	// Health après initialization
	health := manager.Health()
	if health.Status != "healthy" {
		t.Errorf("Expected healthy status, got %s", health.Status)
	}

	// Process data
	result, err := manager.Process(ctx, map[string]string{"test": "data"})
	if err != nil {
		t.Fatalf("Process failed: %v", err)
	}

	if result == nil {
		t.Error("Process should return non-nil result")
	}

	// Metrics
	metrics := manager.Metrics()
	if metrics.Status != "active" {
		t.Errorf("Expected active status, got %s", metrics.Status)
	}

	if metrics.RequestCount != 1 {
		t.Errorf("Expected 1 request, got %d", metrics.RequestCount)
	}

	// Shutdown
	err = manager.Shutdown()
	if err != nil {
		t.Fatalf("Shutdown failed: %v", err)
	}

	// Health après shutdown
	health = manager.Health()
	if health.Status != "shutdown" {
		t.Errorf("Expected shutdown status, got %s", health.Status)
	}
}

// TestRepositoryEnhancedInterface teste l'interface Repository étendue
func TestRepositoryEnhancedInterface(t *testing.T) {
	repo := &TestRepository{}

	// Vérification de conformité d'interface
	var _ docmanager.Repository = repo

	ctx := context.Background()

	// Test document
	doc := &docmanager.Document{
		ID:      "test-repo-1",
		Path:    "/test/repo1.md",
		Content: []byte("Test repository content"),
		Version: 1,
	}

	// Test StoreWithContext
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

	// Test Batch operations
	operations := []docmanager.Operation{
		{
			Type: docmanager.OperationStore,
			Document: &docmanager.Document{
				ID:      "batch-1",
				Path:    "/batch/1.md",
				Content: []byte("Batch content 1"),
				Version: 1,
			},
		},
		{
			Type: docmanager.OperationStore,
			Document: &docmanager.Document{
				ID:      "batch-2",
				Path:    "/batch/2.md",
				Content: []byte("Batch content 2"),
				Version: 1,
			},
		},
	}

	results, err := repo.Batch(ctx, operations)
	if err != nil {
		t.Fatalf("Batch failed: %v", err)
	}

	if len(results) != 2 {
		t.Errorf("Expected 2 batch results, got %d", len(results))
	}

	for _, result := range results {
		if !result.Success {
			t.Errorf("Batch operation failed: %v", result.Error)
		}
	}

	// Test Transaction
	err = repo.Transaction(ctx, func(txCtx docmanager.TransactionContext) error {
		// Simple transaction test
		doc := &docmanager.Document{
			ID:      "tx-test",
			Path:    "/tx/test.md",
			Content: []byte("Transaction test"),
			Version: 1,
		}
		return txCtx.Store(doc)
	})

	if err != nil {
		t.Fatalf("Transaction failed: %v", err)
	}
}

// TestManager implémentation simple pour tests
type TestManager struct {
	initialized bool
	shutdown    bool
	requests    int64
}

func (tm *TestManager) Initialize(ctx context.Context) error {
	tm.initialized = true
	return nil
}

func (tm *TestManager) Process(ctx context.Context, data interface{}) (interface{}, error) {
	if !tm.initialized {
		return nil, docmanager.ErrRepositoryUnavailable
	}
	tm.requests++
	return map[string]interface{}{"processed": data}, nil
}

func (tm *TestManager) Shutdown() error {
	tm.shutdown = true
	tm.initialized = false
	return nil
}

func (tm *TestManager) Health() docmanager.HealthStatus {
	status := "healthy"
	var issues []string

	if !tm.initialized {
		status = "not_initialized"
		issues = append(issues, "Not initialized")
	}
	if tm.shutdown {
		status = "shutdown"
		issues = append(issues, "Manager is shutdown")
	}

	return docmanager.HealthStatus{
		Status:    status,
		LastCheck: time.Now(),
		Issues:    issues,
		Details: map[string]interface{}{
			"initialized": tm.initialized,
			"shutdown":    tm.shutdown,
		},
	}
}

func (tm *TestManager) Metrics() docmanager.ManagerMetrics {
	status := "active"
	if !tm.initialized {
		status = "inactive"
	}
	if tm.shutdown {
		status = "shutdown"
	}

	return docmanager.ManagerMetrics{
		RequestCount:        tm.requests,
		AverageResponseTime: time.Millisecond * 10,
		ErrorCount:          0,
		LastProcessedAt:     time.Now(),
		ResourceUsage: map[string]interface{}{
			"memory": "15MB",
		},
		Status: status,
	}
}

// TestRepository implémentation simple pour tests
type TestRepository struct {
	documents map[string]*docmanager.Document
}

func (tr *TestRepository) Store(doc *docmanager.Document) error {
	if tr.documents == nil {
		tr.documents = make(map[string]*docmanager.Document)
	}
	tr.documents[doc.ID] = doc
	return nil
}

func (tr *TestRepository) Retrieve(id string) (*docmanager.Document, error) {
	if tr.documents == nil {
		return nil, docmanager.ErrDocumentNotFound
	}
	doc, exists := tr.documents[id]
	if !exists {
		return nil, docmanager.ErrDocumentNotFound
	}
	return doc, nil
}

func (tr *TestRepository) Search(query docmanager.SearchQuery) ([]*docmanager.Document, error) {
	var results []*docmanager.Document
	for _, doc := range tr.documents {
		if query.Text == "" || doc.Path == query.Text {
			results = append(results, doc)
		}
	}
	return results, nil
}

func (tr *TestRepository) Save(doc *docmanager.Document) error { return tr.Store(doc) }
func (tr *TestRepository) Get(id string) (*docmanager.Document, error) { return tr.Retrieve(id) }
func (tr *TestRepository) Delete(id string) error {
	if tr.documents == nil {
		return docmanager.ErrDocumentNotFound
	}
	delete(tr.documents, id)
	return nil
}

func (tr *TestRepository) List() ([]*docmanager.Document, error) {
	var docs []*docmanager.Document
	for _, doc := range tr.documents {
		docs = append(docs, doc)
	}
	return docs, nil
}

// Enhanced methods
func (tr *TestRepository) StoreWithContext(ctx context.Context, doc *docmanager.Document) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return tr.Store(doc)
	}
}

func (tr *TestRepository) RetrieveWithContext(ctx context.Context, id string) (*docmanager.Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return tr.Retrieve(id)
	}
}

func (tr *TestRepository) SearchWithContext(ctx context.Context, query docmanager.SearchQuery) ([]*docmanager.Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return tr.Search(query)
	}
}

func (tr *TestRepository) DeleteWithContext(ctx context.Context, id string) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return tr.Delete(id)
	}
}

func (tr *TestRepository) Batch(ctx context.Context, operations []docmanager.Operation) ([]docmanager.BatchResult, error) {
	var results []docmanager.BatchResult

	for i, op := range operations {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		result := docmanager.BatchResult{
			OperationID: string(rune('A' + i)),
			ProcessedAt: time.Now(),
		}

		switch op.Type {
		case docmanager.OperationStore:
			if op.Document != nil {
				err := tr.Store(op.Document)
				result.Success = err == nil
				result.Error = err
				result.Document = op.Document
			}
		}

		results = append(results, result)
	}

	return results, nil
}

func (tr *TestRepository) Transaction(ctx context.Context, fn func(docmanager.TransactionContext) error) error {
	return fn(tr)
}

func (tr *TestRepository) Commit() error   { return nil }
func (tr *TestRepository) Rollback() error { return nil }
func (tr *TestRepository) IsDone() bool    { return false }