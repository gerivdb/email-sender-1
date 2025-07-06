# Package qdrant

## Types

### Client

Client is an alias for QdrantClient for compatibility


### ClientFactory

ClientFactory creates the appropriate Qdrant client based on configuration


#### Methods

##### ClientFactory.CreateClient

CreateClient creates the appropriate client based on configuration


```go
func (cf *ClientFactory) CreateClient() (QdrantInterface, error)
```

##### ClientFactory.WithBaseURL

WithBaseURL sets the base URL for external mode


```go
func (cf *ClientFactory) WithBaseURL(url string) *ClientFactory
```

##### ClientFactory.WithMode

WithMode sets the client mode


```go
func (cf *ClientFactory) WithMode(mode ClientMode) *ClientFactory
```

##### ClientFactory.WithSSL

WithSSL enables SSL for external connections


```go
func (cf *ClientFactory) WithSSL(enable bool) *ClientFactory
```

##### ClientFactory.WithTimeout

WithTimeout sets the timeout for requests


```go
func (cf *ClientFactory) WithTimeout(timeout time.Duration) *ClientFactory
```

### ClientMode

ClientMode defines the mode of operation for Qdrant


### Collection

### CollectionConfig

### CollectionInfo

### EmbeddedClient

EmbeddedClient wraps the mock client to provide an embedded Qdrant experience
This allows for internal vector storage without external Qdrant dependency


#### Methods

##### EmbeddedClient.Close

Close cleans up resources (for interface compatibility)


```go
func (e *EmbeddedClient) Close() error
```

##### EmbeddedClient.CreateCollection

CreateCollection creates a new vector collection


```go
func (e *EmbeddedClient) CreateCollection(name string, vectorSize int) error
```

##### EmbeddedClient.DeleteCollection

DeleteCollection removes a collection


```go
func (e *EmbeddedClient) DeleteCollection(collection string) error
```

##### EmbeddedClient.GetCollectionInfo

GetCollectionInfo returns information about a collection


```go
func (e *EmbeddedClient) GetCollectionInfo(collection string) (*CollectionInfo, error)
```

##### EmbeddedClient.GetStats

GetStats returns client statistics


```go
func (e *EmbeddedClient) GetStats() map[string]interface{}
```

##### EmbeddedClient.HealthCheck

HealthCheck always returns nil for embedded client (always available)


```go
func (e *EmbeddedClient) HealthCheck() error
```

##### EmbeddedClient.IsEmbedded

IsEmbedded returns true to indicate this is an embedded client


```go
func (e *EmbeddedClient) IsEmbedded() bool
```

##### EmbeddedClient.Search

Search performs vector similarity search


```go
func (e *EmbeddedClient) Search(collection string, request SearchRequest) ([]SearchResult, error)
```

##### EmbeddedClient.UpsertPoints

UpsertPoints adds or updates points in a collection


```go
func (e *EmbeddedClient) UpsertPoints(collection string, points []Point) error
```

### EmbeddedConfig

EmbeddedConfig controls the embedded client behavior


### ExternalClientWrapper

ExternalClientWrapper wraps the existing QdrantClient to implement QdrantInterface


#### Methods

##### ExternalClientWrapper.Close

Close implements QdrantInterface


```go
func (w *ExternalClientWrapper) Close() error
```

##### ExternalClientWrapper.CreateCollection

CreateCollection implements QdrantInterface


```go
func (w *ExternalClientWrapper) CreateCollection(name string, vectorSize int) error
```

##### ExternalClientWrapper.DeleteCollection

DeleteCollection implements QdrantInterface


```go
func (w *ExternalClientWrapper) DeleteCollection(collection string) error
```

##### ExternalClientWrapper.GetCollectionInfo

GetCollectionInfo implements QdrantInterface


```go
func (w *ExternalClientWrapper) GetCollectionInfo(collection string) (*CollectionInfo, error)
```

##### ExternalClientWrapper.GetStats

GetStats implements QdrantInterface


```go
func (w *ExternalClientWrapper) GetStats() map[string]interface{}
```

##### ExternalClientWrapper.HealthCheck

HealthCheck implements QdrantInterface


```go
func (w *ExternalClientWrapper) HealthCheck() error
```

##### ExternalClientWrapper.Search

Search implements QdrantInterface


```go
func (w *ExternalClientWrapper) Search(collection string, request SearchRequest) ([]SearchResult, error)
```

##### ExternalClientWrapper.UpsertPoints

UpsertPoints implements QdrantInterface


```go
func (w *ExternalClientWrapper) UpsertPoints(collection string, points []Point) error
```

### Point

### QdrantClient

#### Methods

##### QdrantClient.Close

Close closes the HTTP client and cleans up resources
This method implements the QdrantInterface for compatibility with the factory pattern


```go
func (q *QdrantClient) Close() error
```

##### QdrantClient.CreateCollection

```go
func (q *QdrantClient) CreateCollection(name string, config CollectionConfig) error
```

##### QdrantClient.DeleteCollection

```go
func (q *QdrantClient) DeleteCollection(name string) error
```

##### QdrantClient.GetCollectionInfo

```go
func (q *QdrantClient) GetCollectionInfo(name string) (*CollectionInfo, error)
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

### QdrantInterface

QdrantInterface defines the common interface for both client types


### SearchRequest

### SearchResult

