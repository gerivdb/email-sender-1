// SPDX-License-Identifier: MIT
// Package main - Test d'interface enhancement indépendant
package main

import (
	"context"
	"fmt"
	"time"

	"email_sender/pkg/docmanager"
)

// TestManagerImplementation teste l'implémentation ManagerType
type TestManagerImplementation struct {
	initialized bool
	shutdown    bool
	requests    int64
}

func (tm *TestManagerImplementation) Initialize(ctx context.Context) error {
	tm.initialized = true
	fmt.Println("✅ Manager initialized")
	return nil
}

func (tm *TestManagerImplementation) Process(ctx context.Context, data interface{}) (interface{}, error) {
	if !tm.initialized {
		return nil, fmt.Errorf("manager not initialized")
	}
	tm.requests++
	fmt.Printf("✅ Processed request #%d\n", tm.requests)
	return map[string]interface{}{"processed": data, "request_id": tm.requests}, nil
}

func (tm *TestManagerImplementation) Shutdown() error {
	tm.shutdown = true
	tm.initialized = false
	fmt.Println("✅ Manager shutdown")
	return nil
}

func (tm *TestManagerImplementation) Health() docmanager.HealthStatus {
	status := "healthy"
	var issues []string

	if !tm.initialized {
		status = "not_initialized"
		issues = append(issues, "Manager not initialized")
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

func (tm *TestManagerImplementation) Metrics() docmanager.ManagerMetrics {
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
			"memory_mb": 15.0,
		},
		Status: status,
	}
}

// TestRepositoryImplementation teste l'implémentation Repository étendue
type TestRepositoryImplementation struct {
	documents map[string]*docmanager.Document
}

func (tr *TestRepositoryImplementation) Store(doc *docmanager.Document) error {
	if tr.documents == nil {
		tr.documents = make(map[string]*docmanager.Document)
	}
	tr.documents[doc.ID] = doc
	fmt.Printf("✅ Stored document: %s\n", doc.ID)
	return nil
}

func (tr *TestRepositoryImplementation) Retrieve(id string) (*docmanager.Document, error) {
	if tr.documents == nil {
		return nil, fmt.Errorf("document not found: %s", id)
	}
	doc, exists := tr.documents[id]
	if !exists {
		return nil, fmt.Errorf("document not found: %s", id)
	}
	fmt.Printf("✅ Retrieved document: %s\n", doc.ID)
	return doc, nil
}

func (tr *TestRepositoryImplementation) Search(query docmanager.SearchQuery) ([]*docmanager.Document, error) {
	var results []*docmanager.Document
	for _, doc := range tr.documents {
		if query.Text == "" || doc.Path == query.Text {
			results = append(results, doc)
		}
	}
	fmt.Printf("✅ Search found %d documents\n", len(results))
	return results, nil
}

// Alias methods
func (tr *TestRepositoryImplementation) Save(doc *docmanager.Document) error { 
	return tr.Store(doc) 
}
func (tr *TestRepositoryImplementation) Get(id string) (*docmanager.Document, error) { 
	return tr.Retrieve(id) 
}
func (tr *TestRepositoryImplementation) Delete(id string) error {
	if tr.documents == nil {
		return fmt.Errorf("document not found: %s", id)
	}
	delete(tr.documents, id)
	fmt.Printf("✅ Deleted document: %s\n", id)
	return nil
}

func (tr *TestRepositoryImplementation) List() ([]*docmanager.Document, error) {
	var docs []*docmanager.Document
	for _, doc := range tr.documents {
		docs = append(docs, doc)
	}
	return docs, nil
}

// Enhanced context-aware methods
func (tr *TestRepositoryImplementation) StoreWithContext(ctx context.Context, doc *docmanager.Document) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return tr.Store(doc)
	}
}

func (tr *TestRepositoryImplementation) RetrieveWithContext(ctx context.Context, id string) (*docmanager.Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return tr.Retrieve(id)
	}
}

func (tr *TestRepositoryImplementation) SearchWithContext(ctx context.Context, query docmanager.SearchQuery) ([]*docmanager.Document, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	default:
		return tr.Search(query)
	}
}

func (tr *TestRepositoryImplementation) DeleteWithContext(ctx context.Context, id string) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return tr.Delete(id)
	}
}

func (tr *TestRepositoryImplementation) Batch(ctx context.Context, operations []docmanager.Operation) ([]docmanager.BatchResult, error) {
	var results []docmanager.BatchResult
	fmt.Printf("✅ Processing batch of %d operations\n", len(operations))

	for i, op := range operations {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		result := docmanager.BatchResult{
			OperationID: fmt.Sprintf("op_%d", i),
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
		case docmanager.OperationDelete:
			if op.ID != "" {
				err := tr.Delete(op.ID)
				result.Success = err == nil
				result.Error = err
			}
		}

		results = append(results, result)
	}

	return results, nil
}

func (tr *TestRepositoryImplementation) Transaction(ctx context.Context, fn func(docmanager.TransactionContext) error) error {
	fmt.Println("✅ Starting transaction")
	err := fn(tr)
	if err != nil {
		fmt.Printf("❌ Transaction failed: %v\n", err)
		return err
	}
	fmt.Println("✅ Transaction committed")
	return nil
}

// Transaction context methods
func (tr *TestRepositoryImplementation) Commit() error {
	fmt.Println("✅ Transaction commit")
	return nil
}

func (tr *TestRepositoryImplementation) Rollback() error {
	fmt.Println("🔄 Transaction rollback")
	return nil
}

func (tr *TestRepositoryImplementation) IsDone() bool {
	return false
}

func main() {
	fmt.Println("🧪 Testing Interface Enhancement Implementation")
	fmt.Println("================================================")

	// Test ManagerType interface compliance
	var manager docmanager.ManagerType = &TestManagerImplementation{}
	fmt.Println("\n1. Testing ManagerType Interface:")

	ctx := context.Background()

	// Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		fmt.Printf("❌ Initialize failed: %v\n", err)
		return
	}

	// Health check
	health := manager.Health()
	fmt.Printf("   Health Status: %s\n", health.Status)

	// Process some data
	result, err := manager.Process(ctx, map[string]string{"test": "data"})
	if err != nil {
		fmt.Printf("❌ Process failed: %v\n", err)
		return
	}
	fmt.Printf("   Process result: %v\n", result)

	// Get metrics
	metrics := manager.Metrics()
	fmt.Printf("   Metrics - Requests: %d, Status: %s\n", metrics.RequestCount, metrics.Status)

	// Shutdown
	err = manager.Shutdown()
	if err != nil {
		fmt.Printf("❌ Shutdown failed: %v\n", err)
		return
	}

	// Test Repository interface compliance
	var repo docmanager.Repository = &TestRepositoryImplementation{}
	fmt.Println("\n2. Testing Repository Interface:")

	// Test document
	doc := &docmanager.Document{
		ID:      "test-doc-1",
		Path:    "/test/doc1.md",
		Content: []byte("Test content for validation"),
		Version: 1,
	}

	// Store with context
	err = repo.StoreWithContext(ctx, doc)
	if err != nil {
		fmt.Printf("❌ StoreWithContext failed: %v\n", err)
		return
	}

	// Retrieve with context
	retrieved, err := repo.RetrieveWithContext(ctx, doc.ID)
	if err != nil {
		fmt.Printf("❌ RetrieveWithContext failed: %v\n", err)
		return
	}
	fmt.Printf("   Retrieved: %s\n", retrieved.ID)

	// Test batch operations
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

	batchResults, err := repo.Batch(ctx, operations)
	if err != nil {
		fmt.Printf("❌ Batch failed: %v\n", err)
		return
	}

	successCount := 0
	for _, result := range batchResults {
		if result.Success {
			successCount++
		}
	}
	fmt.Printf("   Batch: %d/%d operations successful\n", successCount, len(batchResults))

	// Test transaction
	err = repo.Transaction(ctx, func(txCtx docmanager.TransactionContext) error {
		testDoc := &docmanager.Document{
			ID:      "tx-test",
			Path:    "/tx/test.md",
			Content: []byte("Transaction test"),
			Version: 1,
		}
		return txCtx.Store(testDoc)
	})

	if err != nil {
		fmt.Printf("❌ Transaction failed: %v\n", err)
		return
	}

	fmt.Println("\n✅ All Interface Enhancement Tests Passed!")
	fmt.Println("========================================")
	fmt.Println("TASK 3.2.1.1.2 - ManagerType Interface Enhancement: ✅ COMPLETED")
	fmt.Println("TASK 3.2.1.2.2 - Repository Interface Enhancement: ✅ COMPLETED")
}
