# Package core

## Types

### CacheManagerInterface

CacheManagerInterface définit les opérations du CacheManager


### LWMInterface

LWMInterface définit les opérations du LWM


### MemoryBankAPIClient

MemoryBankAPIClient définit les opérations du client Memory Bank API
Pour l'instant, nous utiliserons une interface simplifiée pour la simulation


### MockCacheManager

MockCacheManager implémente CacheManagerInterface pour les tests


#### Methods

##### MockCacheManager.Invalidate

```go
func (m *MockCacheManager) Invalidate(ctx context.Context, key string) error
```

##### MockCacheManager.Update

```go
func (m *MockCacheManager) Update(ctx context.Context, key string, value interface{}) error
```

### MockLWM

MockLWM implémente LWMInterface pour les tests


#### Methods

##### MockLWM.GetWorkflowStatus

```go
func (m *MockLWM) GetWorkflowStatus(ctx context.Context, taskID string) (string, error)
```

##### MockLWM.TriggerWorkflow

```go
func (m *MockLWM) TriggerWorkflow(ctx context.Context, workflowID string, payload map[string]interface{}) (string, error)
```

### MockMemoryBank

MockMemoryBank implémente MemoryBankAPIClient pour les tests


#### Methods

##### MockMemoryBank.Retrieve

```go
func (m *MockMemoryBank) Retrieve(ctx context.Context, id string) (map[string]interface{}, error)
```

##### MockMemoryBank.Store

```go
func (m *MockMemoryBank) Store(ctx context.Context, key string, data map[string]interface{}, ttl string) (string, error)
```

### MockRAG

MockRAG implémente RAGInterface pour les tests


#### Methods

##### MockRAG.GenerateContent

```go
func (m *MockRAG) GenerateContent(ctx context.Context, query string, context []string) (string, error)
```

### RAGInterface

RAGInterface définit les opérations du RAG


