package core

import (
	"context"
	"fmt"
)

// MockCacheManager implémente CacheManagerInterface pour les tests
type MockCacheManager struct{}

func (m *MockCacheManager) Invalidate(ctx context.Context, key string) error {
	fmt.Printf("MockCacheManager: Invalidate(%s) appelé.\n", key)
	return nil
}

func (m *MockCacheManager) Update(ctx context.Context, key string, value interface{}) error {
	fmt.Printf("MockCacheManager: Update(%s, %v) appelé.\n", key, value)
	return nil
}

// MockLWM implémente LWMInterface pour les tests
type MockLWM struct{}

func (m *MockLWM) TriggerWorkflow(ctx context.Context, workflowID string, payload map[string]interface{}) (string, error) {
	fmt.Printf("MockLWM: TriggerWorkflow(%s, %v) appelé.\n", workflowID, payload)
	return "mock-task-id-123", nil
}

func (m *MockLWM) GetWorkflowStatus(ctx context.Context, taskID string) (string, error) {
	fmt.Printf("MockLWM: GetWorkflowStatus(%s) appelé.\n", taskID)
	return "completed", nil
}

// MockRAG implémente RAGInterface pour les tests
type MockRAG struct{}

func (m *MockRAG) GenerateContent(ctx context.Context, query string, context []string) (string, error) {
	fmt.Printf("MockRAG: GenerateContent(query: %s, context: %v) appelé.\n", query, context)
	return "Contenu généré par mock.", nil
}

// MockMemoryBank implémente MemoryBankAPIClient pour les tests
type MockMemoryBank struct{}

func (m *MockMemoryBank) Store(ctx context.Context, key string, data map[string]interface{}, ttl string) (string, error) {
	fmt.Printf("MockMemoryBank: Store(key: %s, data: %v, ttl: %s) appelé.\n", key, data, ttl)
	return "mock-id-456", nil
}

func (m *MockMemoryBank) Retrieve(ctx context.Context, id string) (map[string]interface{}, error) {
	fmt.Printf("MockMemoryBank: Retrieve(%s) appelé.\n", id)
	return map[string]interface{}{"retrieved": "data"}, nil
}
