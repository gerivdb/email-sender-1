# Package main

Package main implements the vectorization CLI tool
Phase 3.1.2.1: Créer planning-ecosystem-sync/cmd/vectorize/main.go


## Types

### CollectionConfig

### EmbeddingClient

EmbeddingClient interface for generating embeddings


### MarkdownParser

MarkdownParser handles markdown parsing
Phase 3.1.2.1.1: Migrer la logique de parsing Markdown


#### Methods

##### MarkdownParser.ParseDirectory

ParseDirectory recursively parses markdown files in a directory


```go
func (mp *MarkdownParser) ParseDirectory(rootPath string, stats *ProcessingStats) ([]TaskEntry, error)
```

##### MarkdownParser.ParseFile

ParseFile parses a single markdown file for tasks
Phase 3.1.2.1.1: Migrer la logique de parsing Markdown


```go
func (mp *MarkdownParser) ParseFile(filePath string) ([]TaskEntry, error)
```

### MockCache

#### Methods

##### MockCache.Clear

```go
func (m *MockCache) Clear()
```

##### MockCache.Delete

```go
func (m *MockCache) Delete(key string)
```

##### MockCache.Get

```go
func (m *MockCache) Get(key string) ([]float32, bool)
```

##### MockCache.Set

```go
func (m *MockCache) Set(key string, value []float32)
```

##### MockCache.Size

```go
func (m *MockCache) Size() int
```

### MockEmbeddingClient

MockEmbeddingClient is a mock implementation for demonstration


#### Methods

##### MockEmbeddingClient.BatchGenerateEmbeddings

```go
func (m *MockEmbeddingClient) BatchGenerateEmbeddings(ctx context.Context, texts []string) ([][]float32, error)
```

##### MockEmbeddingClient.GenerateEmbedding

```go
func (m *MockEmbeddingClient) GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
```

##### MockEmbeddingClient.GetModelInfo

```go
func (m *MockEmbeddingClient) GetModelInfo() ModelInfo
```

### MockQdrantClient

#### Methods

##### MockQdrantClient.Connect

```go
func (m *MockQdrantClient) Connect(ctx context.Context) error
```

##### MockQdrantClient.CreateCollection

```go
func (m *MockQdrantClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error
```

##### MockQdrantClient.DeleteCollection

```go
func (m *MockQdrantClient) DeleteCollection(ctx context.Context, name string) error
```

##### MockQdrantClient.HealthCheck

```go
func (m *MockQdrantClient) HealthCheck(ctx context.Context) error
```

##### MockQdrantClient.SearchPoints

```go
func (m *MockQdrantClient) SearchPoints(ctx context.Context, collection string, req SearchRequest) (*SearchResponse, error)
```

##### MockQdrantClient.UpsertPoints

```go
func (m *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error
```

### ModelInfo

ModelInfo contains embedding model information


### Point

### ProcessingStats

ProcessingStats tracks processing statistics


### SearchRequest

### SearchResponse

### TaskEntry

TaskEntry represents a parsed task from markdown


### VectorizationConfig

VectorizationConfig holds configuration for vectorization


### VectorizationEngine

#### Methods

##### VectorizationEngine.GetStats

```go
func (ve *VectorizationEngine) GetStats() map[string]interface{}
```

##### VectorizationEngine.Initialize

```go
func (ve *VectorizationEngine) Initialize(ctx context.Context) error
```

##### VectorizationEngine.ProcessRequests

```go
func (ve *VectorizationEngine) ProcessRequests(requests []VectorizationRequest) []VectorizationResult
```

##### VectorizationEngine.Shutdown

```go
func (ve *VectorizationEngine) Shutdown()
```

### VectorizationRequest

Helper types from vectorization engine


### VectorizationResult

## Functions

### ProcessTasksWithEngine

ProcessTasksWithEngine processes tasks using the vectorization engine
Phase 3.1.2.2: Implémenter les optimisations de performance


```go
func ProcessTasksWithEngine(tasks []TaskEntry, config *VectorizationConfig, logger *zap.Logger, stats *ProcessingStats) error
```

