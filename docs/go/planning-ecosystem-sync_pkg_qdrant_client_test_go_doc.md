# Package qdrant

Package qdrant provides a unified Qdrant client implementation
This is part of Phase 2 of plan-dev-v56: Unification des Clients Qdrant


## Types

### ClientMetrics

ClientMetrics tracks client performance metrics
Implementation of Phase 2.1.2.2.1: Intégrer avec le système de métriques existant


### CollectionConfig

CollectionConfig represents configuration for creating collections


### ConnectionPool

ConnectionPool manages HTTP connections with pooling
Implementation of Phase 2.1.2.1.1: Implémenter connection pooling


### Point

Point represents a vector point with metadata


### QdrantInterface

QdrantInterface defines the unified interface for all Qdrant operations
Implementation of Phase 2.1.1.1: Créer planning-ecosystem-sync/pkg/qdrant/client.go


### ScoredPoint

ScoredPoint represents a search result with score


### SearchRequest

SearchRequest represents a vector search request


### SearchResponse

SearchResponse represents the response from a vector search


### UnifiedClient

UnifiedClient implements the QdrantInterface with advanced features
Phase 2.1.1: Architecture du Client de Référence


#### Methods

##### UnifiedClient.Close

Close cleanly shuts down the client


```go
func (c *UnifiedClient) Close() error
```

##### UnifiedClient.Connect

Connect establishes connection to Qdrant server
Phase 2.1.1.1.2: Implémenter les méthodes de base (Connect, CreateCollection, Upsert, Search)


```go
func (c *UnifiedClient) Connect(ctx context.Context) error
```

##### UnifiedClient.CreateCollection

CreateCollection creates a new vector collection
Phase 2.1.1.1.2: Implémenter les méthodes de base


```go
func (c *UnifiedClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error
```

##### UnifiedClient.DeleteCollection

DeleteCollection deletes a vector collection
Phase 2.1.1.1.2: Implémenter les méthodes de base


```go
func (c *UnifiedClient) DeleteCollection(ctx context.Context, name string) error
```

##### UnifiedClient.GetMetrics

GetMetrics returns current client metrics
Phase 2.1.2.2.1: Monitoring integration


```go
func (c *UnifiedClient) GetMetrics() ClientMetrics
```

##### UnifiedClient.HealthCheck

HealthCheck verifies Qdrant server health
Phase 2.1.1.1.2: Implémenter les méthodes de base


```go
func (c *UnifiedClient) HealthCheck(ctx context.Context) error
```

##### UnifiedClient.LogPerformanceStats

LogPerformanceStats logs current performance statistics
Phase 2.1.2.2.2: Ajouter logging structuré (zap.Logger)


```go
func (c *UnifiedClient) LogPerformanceStats()
```

##### UnifiedClient.SearchPoints

SearchPoints performs vector similarity search
Phase 2.1.1.1.2: Implémenter les méthodes de base


```go
func (c *UnifiedClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error)
```

##### UnifiedClient.UpsertPoints

UpsertPoints inserts or updates vector points
Phase 2.1.1.1.2: Implémenter les méthodes de base


```go
func (c *UnifiedClient) UpsertPoints(ctx context.Context, collection string, points []Point) error
```

