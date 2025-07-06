# Package vectorization

Package vectorization provides a unified vectorization engine
Implementation of Phase 3.1.1: Création du Package Vectorization


## Types

### Cache

Cache interface for local caching
Phase 3.1.1.1.3: Ajouter cache local pour optimiser les performances


### CollectionConfig

CollectionConfig represents Qdrant collection configuration


### EmbeddingClient

EmbeddingClient interface for generating embeddings
Phase 3.1.1.1.2: Intégrer avec sentence-transformers via HTTP API ou CLI bridge


### ModelInfo

ModelInfo contains embedding model information


### Point

Point represents a vector point with metadata


### QdrantInterface

QdrantInterface provides unified Qdrant operations


### ScoredPoint

ScoredPoint represents a search result with score


### SearchRequest

SearchRequest represents a vector search request


### SearchResponse

SearchResponse represents search results


### VectorizationEngine

VectorizationEngine provides unified vectorization capabilities
Phase 3.1.1.1.1: Implémenter VectorizationEngine avec interface standardisée


#### Methods

##### VectorizationEngine.GetStats

GetStats returns engine statistics


```go
func (ve *VectorizationEngine) GetStats() map[string]interface{}
```

##### VectorizationEngine.Initialize

Initialize initializes the vectorization engine


```go
func (ve *VectorizationEngine) Initialize(ctx context.Context) error
```

##### VectorizationEngine.ProcessRequests

ProcessRequests processes vectorization requests using worker pool


```go
func (ve *VectorizationEngine) ProcessRequests(requests []VectorizationRequest) []VectorizationResult
```

##### VectorizationEngine.Shutdown

Shutdown gracefully shuts down the vectorization engine


```go
func (ve *VectorizationEngine) Shutdown()
```

##### VectorizationEngine.StoreVectors

StoreVectors stores vectors in Qdrant with retry logic
Phase 3.1.2.1.3: Ajouter l'upload vers Qdrant avec retry logic


```go
func (ve *VectorizationEngine) StoreVectors(ctx context.Context, collection string, points []Point) error
```

##### VectorizationEngine.VectorizeBatch

VectorizeBatch vectorizes multiple texts efficiently
Phase 3.1.2.2.2: Batching intelligent des opérations Qdrant


```go
func (ve *VectorizationEngine) VectorizeBatch(ctx context.Context, texts []string) ([][]float32, error)
```

##### VectorizationEngine.VectorizeText

VectorizeText vectorizes a single text with caching


```go
func (ve *VectorizationEngine) VectorizeText(ctx context.Context, text string) ([]float32, error)
```

### VectorizationRequest

VectorizationRequest represents a request for vectorization


### VectorizationResult

VectorizationResult represents the result of vectorization


### WorkerPool

WorkerPool manages concurrent vectorization workers
Phase 3.1.2.2.1: Parallélisation avec goroutines (worker pool pattern)


