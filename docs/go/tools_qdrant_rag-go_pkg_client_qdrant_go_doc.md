# Package client

Package client provides RAG-optimized Qdrant client using the unified client
Phase 2.2.2: Refactoring du Client RAG


## Types

### Collection

### DocumentChunk

DocumentChunk represents a document chunk for RAG processing


### Point

### QdrantClient

#### Methods

##### QdrantClient.CreateCollection

```go
func (q *QdrantClient) CreateCollection(name string, vectorSize int) error
```

##### QdrantClient.HealthCheck

```go
func (q *QdrantClient) HealthCheck() error
```

##### QdrantClient.Search

```go
func (q *QdrantClient) Search(collectionName string, req SearchRequest) ([]SearchResult, error)
```

##### QdrantClient.UpsertPoints

```go
func (q *QdrantClient) UpsertPoints(collectionName string, points []Point) error
```

### RAGClient

RAGClient provides RAG-specific optimizations while using the unified client
Phase 2.2.2.1: Migrer tools/qdrant/rag-go/pkg/client/qdrant.go


#### Methods

##### RAGClient.GetMetrics

GetMetrics returns current RAG performance metrics
Phase 2.2.2.1.3: Valider la performance (benchmarks)


```go
func (r *RAGClient) GetMetrics() RAGMetrics
```

##### RAGClient.ProcessDocument

ProcessDocument chunks a document and stores it for RAG
Phase 2.2.2.1.2: Préserver les fonctionnalités spécialisées


```go
func (r *RAGClient) ProcessDocument(ctx context.Context, collection string, docID string, content string, metadata map[string]interface{}) error
```

##### RAGClient.SearchRAG

SearchRAG performs RAG-optimized vector search
Phase 2.2.2.1.2: Préserver les fonctionnalités spécialisées


```go
func (r *RAGClient) SearchRAG(ctx context.Context, collection string, req RAGSearchRequest) (*RAGSearchResult, error)
```

### RAGMetrics

RAGMetrics tracks RAG-specific performance metrics


### RAGSearchRequest

RAGSearchRequest extends basic search with RAG-specific parameters


### RAGSearchResult

RAGSearchResult contains search results with RAG context


### SearchRequest

### SearchResult

