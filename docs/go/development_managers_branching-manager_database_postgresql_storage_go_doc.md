# Package database

## Types

### PostgreSQLConfig

PostgreSQLConfig holds PostgreSQL connection configuration


### PostgreSQLStorageManager

PostgreSQLStorageManager implements StorageManager interface with PostgreSQL backend


#### Methods

##### PostgreSQLStorageManager.Close

Close closes the database connection


```go
func (s *PostgreSQLStorageManager) Close() error
```

##### PostgreSQLStorageManager.GetBranch

GetBranch implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) GetBranch(ctx context.Context, branchID string) (*interfaces.Branch, error)
```

##### PostgreSQLStorageManager.GetPendingEvents

GetPendingEvents implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) GetPendingEvents(ctx context.Context) ([]*interfaces.BranchingEvent, error)
```

##### PostgreSQLStorageManager.GetQuantumBranch

GetQuantumBranch implements StorageManager interface for Level 8


```go
func (s *PostgreSQLStorageManager) GetQuantumBranch(ctx context.Context, quantumBranchID string) (*interfaces.QuantumBranch, error)
```

##### PostgreSQLStorageManager.GetSession

GetSession implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) GetSession(ctx context.Context, sessionID string) (*interfaces.Session, error)
```

##### PostgreSQLStorageManager.GetTemporalSnapshots

GetTemporalSnapshots implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) GetTemporalSnapshots(ctx context.Context, branchID string, timeRange interfaces.TimeRange) ([]*interfaces.TemporalSnapshot, error)
```

##### PostgreSQLStorageManager.Health

Health checks the database connection health


```go
func (s *PostgreSQLStorageManager) Health(ctx context.Context) error
```

##### PostgreSQLStorageManager.ListSessions

ListSessions implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) ListSessions(ctx context.Context, filters interfaces.SessionFilters) ([]*interfaces.Session, error)
```

##### PostgreSQLStorageManager.MarkEventProcessed

MarkEventProcessed implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) MarkEventProcessed(ctx context.Context, eventID string) error
```

##### PostgreSQLStorageManager.SaveBranch

SaveBranch implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) SaveBranch(ctx context.Context, branch *interfaces.Branch) error
```

##### PostgreSQLStorageManager.SaveEvent

SaveEvent implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) SaveEvent(ctx context.Context, event *interfaces.BranchingEvent) error
```

##### PostgreSQLStorageManager.SaveQuantumBranch

SaveQuantumBranch implements StorageManager interface for Level 8


```go
func (s *PostgreSQLStorageManager) SaveQuantumBranch(ctx context.Context, qb *interfaces.QuantumBranch) error
```

##### PostgreSQLStorageManager.SaveSession

SaveSession implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) SaveSession(ctx context.Context, session *interfaces.Session) error
```

##### PostgreSQLStorageManager.SaveTemporalSnapshot

SaveTemporalSnapshot implements StorageManager interface


```go
func (s *PostgreSQLStorageManager) SaveTemporalSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error
```

### QdrantConfig

QdrantConfig holds Qdrant connection configuration


### QdrantVectorManager

QdrantVectorManager implements vector operations for AI-powered branching features


#### Methods

##### QdrantVectorManager.DeletePoint

DeletePoint removes a point from the vector database


```go
func (q *QdrantVectorManager) DeletePoint(ctx context.Context, pointID string) error
```

##### QdrantVectorManager.GenerateEmbedding

GenerateEmbedding creates embeddings for text content (mock implementation)
In production, this would call a real embedding service like OpenAI, Cohere, or local models


```go
func (q *QdrantVectorManager) GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
```

##### QdrantVectorManager.GetCollectionInfo

GetCollectionInfo returns information about the collection


```go
func (q *QdrantVectorManager) GetCollectionInfo(ctx context.Context) (map[string]interface{}, error)
```

##### QdrantVectorManager.Health

Health checks the Qdrant connection health


```go
func (q *QdrantVectorManager) Health(ctx context.Context) error
```

##### QdrantVectorManager.IndexBranch

IndexBranch stores branch embeddings for similarity search


```go
func (q *QdrantVectorManager) IndexBranch(ctx context.Context, branch *interfaces.Branch, embedding []float32) error
```

##### QdrantVectorManager.IndexBranchingPattern

IndexBranchingPattern stores branching pattern embeddings for AI analysis


```go
func (q *QdrantVectorManager) IndexBranchingPattern(ctx context.Context, pattern *interfaces.BranchingPattern, embedding []float32) error
```

##### QdrantVectorManager.IndexQuantumApproach

IndexQuantumApproach stores quantum approach embeddings for optimization


```go
func (q *QdrantVectorManager) IndexQuantumApproach(ctx context.Context, approach *interfaces.BranchApproach, embedding []float32) error
```

##### QdrantVectorManager.IndexSession

IndexSession stores session embeddings for similarity search


```go
func (q *QdrantVectorManager) IndexSession(ctx context.Context, session *interfaces.Session, embedding []float32) error
```

##### QdrantVectorManager.SearchOptimalApproaches

SearchOptimalApproaches finds optimal quantum approaches based on similarity


```go
func (q *QdrantVectorManager) SearchOptimalApproaches(ctx context.Context, embedding []float32, limit int) ([]*interfaces.ApproachSimilarity, error)
```

##### QdrantVectorManager.SearchSimilarBranches

SearchSimilarBranches finds branches similar to the given embedding


```go
func (q *QdrantVectorManager) SearchSimilarBranches(ctx context.Context, embedding []float32, limit int) ([]*interfaces.BranchSimilarity, error)
```

##### QdrantVectorManager.SearchSimilarPatterns

SearchSimilarPatterns finds branching patterns similar to the given embedding


```go
func (q *QdrantVectorManager) SearchSimilarPatterns(ctx context.Context, embedding []float32, limit int) ([]*interfaces.PatternSimilarity, error)
```

##### QdrantVectorManager.SearchSimilarSessions

SearchSimilarSessions finds sessions similar to the given embedding


```go
func (q *QdrantVectorManager) SearchSimilarSessions(ctx context.Context, embedding []float32, limit int) ([]*interfaces.SessionSimilarity, error)
```

### SearchRequest

SearchRequest represents a Qdrant search request


### SearchResponse

SearchResponse represents a Qdrant search response


### SearchResult

SearchResult represents a Qdrant search result


### VectorPoint

VectorPoint represents a point in Qdrant vector space


