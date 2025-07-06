# Package vector

## Types

### Client

#### Methods

##### Client.Close

```go
func (c *Client) Close() error
```

##### Client.CreateCollection

```go
func (c *Client) CreateCollection(ctx context.Context, req *CreateCollection) (*CreateCollectionResponse, error)
```

##### Client.Delete

```go
func (c *Client) Delete(ctx context.Context, req *DeletePoints) (interface{}, error)
```

##### Client.GetCollection

```go
func (c *Client) GetCollection(ctx context.Context, name string) (*CollectionInfo, error)
```

##### Client.ListCollections

```go
func (c *Client) ListCollections(ctx context.Context) (*ListCollectionsResponse, error)
```

##### Client.Search

```go
func (c *Client) Search(ctx context.Context, req *SearchPoints) (*SearchPointsResponse, error)
```

##### Client.Upsert

```go
func (c *Client) Upsert(ctx context.Context, req *UpsertPoints) (interface{}, error)
```

### Collection

Collection represents a Qdrant collection


### CollectionInfo

### CollectionStatus

#### Methods

##### CollectionStatus.String

```go
func (cs *CollectionStatus) String() string
```

### CollectionSummary

### CollectionsClient

#### Methods

##### CollectionsClient.Create

```go
func (c *CollectionsClient) Create(ctx context.Context, req *CreateCollection) (*CreateCollectionResponse, error)
```

### Condition

### Condition_Field

### CreateCollection

### CreateCollectionResponse

### DateRange

DateRange represents a date range filter


### DeletePoints

### Distance

### FieldCondition

### FileMetadata

FileMetadata represents metadata for a file in the vector registry


### Filter

### GetCollectionInfoRequest

### GetCollectionInfoResponse

### GetPoints

### ListCollectionsResponse

### Match

### Match_Keywords

### PointId

### PointStruct

### PointsClient

#### Methods

##### PointsClient.Upsert

```go
func (c *PointsClient) Upsert(ctx context.Context, req *UpsertPoints) (interface{}, error)
```

### PointsIdsList

### PointsSelector

### PointsSelector_Points

### QdrantManager

QdrantManager manages Qdrant vector database operations


#### Methods

##### QdrantManager.CreateCollection

CreateCollection creates a new collection


```go
func (qm *QdrantManager) CreateCollection(ctx context.Context, name string, vectorSize int, distance string) error
```

##### QdrantManager.Delete

Delete removes vectors by IDs


```go
func (qm *QdrantManager) Delete(ctx context.Context, collectionName string, ids []string) error
```

##### QdrantManager.GetCollections

GetCollections returns information about all collections


```go
func (qm *QdrantManager) GetCollections() map[string]*Collection
```

##### QdrantManager.GetHealth

GetHealth returns the health status of the Qdrant manager


```go
func (qm *QdrantManager) GetHealth() core.HealthStatus
```

##### QdrantManager.GetMetrics

GetMetrics returns metrics about the Qdrant manager


```go
func (qm *QdrantManager) GetMetrics() map[string]interface{}
```

##### QdrantManager.GetStats

GetStats returns statistics about the vector database


```go
func (qm *QdrantManager) GetStats(ctx context.Context) (*VectorStats, error)
```

##### QdrantManager.Initialize

Initialize sets up the Qdrant manager and ensures required collections exist


```go
func (qm *QdrantManager) Initialize(ctx context.Context) error
```

##### QdrantManager.Search

Search performs vector similarity search


```go
func (qm *QdrantManager) Search(ctx context.Context, collectionName string, queryVector []float32, limit int, filter map[string]interface{}) ([]SearchResult, error)
```

##### QdrantManager.Stop

Stop gracefully shuts down the Qdrant manager


```go
func (qm *QdrantManager) Stop() error
```

##### QdrantManager.StoreBatch

StoreBatch stores multiple vectors in a single batch operation


```go
func (qm *QdrantManager) StoreBatch(ctx context.Context, collectionName string, points []VectorPoint) error
```

##### QdrantManager.StoreVector

StoreVector stores a vector with metadata in the specified collection


```go
func (qm *QdrantManager) StoreVector(ctx context.Context, collectionName string, point VectorPoint) error
```

### Range

### RegistryConfig

RegistryConfig holds configuration for the vector registry


### RepeatedStrings

### RetrievedPoint

### ScoredPoint

### SearchFilter

SearchFilter represents search filters for vector queries


### SearchPoints

### SearchPointsResponse

### SearchResult

SearchResult represents a search result from the vector registry


### UpsertPoints

### Value

#### Methods

##### Value.GetDoubleValue

```go
func (v *Value) GetDoubleValue() float64
```

##### Value.GetIntegerValue

```go
func (v *Value) GetIntegerValue() int64
```

##### Value.GetStringValue

```go
func (v *Value) GetStringValue() string
```

### Value_DoubleValue

### Value_IntegerValue

### Value_StringValue

### Vector

### VectorParams

### VectorPoint

VectorPoint represents a vector point with file metadata


### VectorRegistry

VectorRegistry manages file embeddings and metadata in QDrant


#### Methods

##### VectorRegistry.RegisterFile

RegisterFile adds or updates a file in the vector registry


```go
func (vr *VectorRegistry) RegisterFile(ctx context.Context, point *VectorPoint) error
```

##### VectorRegistry.SearchSimilar

SearchSimilar finds similar files based on vector similarity


```go
func (vr *VectorRegistry) SearchSimilar(ctx context.Context, vector []float32, limit uint64, filter *SearchFilter) ([]*SearchResult, error)
```

### VectorStats

VectorStats contains statistics about the vector database


### Vectors

### VectorsConfig

### VectorsConfig_Params

### WithPayloadSelector

### WithPayloadSelector_Enable

### WithVectorsSelector

### WithVectorsSelector_Enable

