package core

import (
	"context"
)

// CacheManagerInterface définit les opérations du CacheManager
type CacheManagerInterface interface {
	Invalidate(ctx context.Context, key string) error
	Update(ctx context.Context, key string, value interface{}) error
}

// LWMInterface définit les opérations du LWM
type LWMInterface interface {
	TriggerWorkflow(ctx context.Context, workflowID string, payload map[string]interface{}) (string, error)
	GetWorkflowStatus(ctx context.Context, taskID string) (string, error)
}

// RAGInterface définit les opérations du RAG
type RAGInterface interface {
	GenerateContent(ctx context.Context, query string, context []string) (string, error)
}

// MemoryBankAPIClient définit les opérations du client Memory Bank API
// Pour l'instant, nous utiliserons une interface simplifiée pour la simulation
type MemoryBankAPIClient interface {
	Store(ctx context.Context, key string, data map[string]interface{}, ttl string) (string, error)
	Retrieve(ctx context.Context, id string) (map[string]interface{}, error)
}
