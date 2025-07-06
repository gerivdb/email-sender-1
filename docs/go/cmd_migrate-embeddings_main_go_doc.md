# Package main

## Types

### BatchResult

BatchResult contient les résultats d'un batch


### Collection

Collection représente une collection Qdrant


### CollectionConfig

CollectionConfig contient la configuration d'une collection


### EmbeddingMigrator

EmbeddingMigrator gère la migration des embeddings vers de nouveaux modèles


#### Methods

##### EmbeddingMigrator.MigrateCollection

MigrateCollection migre une collection vers le nouveau modèle


```go
func (em *EmbeddingMigrator) MigrateCollection(ctx context.Context, collectionName string) (*MigrationResult, error)
```

### EmbeddingModel

EmbeddingModel interface pour les modèles d'embedding


### MigrationMetrics

MigrationMetrics contient les métriques de migration


### MigrationResult

MigrationResult contient les résultats de migration


### MockEmbeddingModel

#### Methods

##### MockEmbeddingModel.GenerateEmbedding

```go
func (m *MockEmbeddingModel) GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
```

##### MockEmbeddingModel.GetDimensions

```go
func (m *MockEmbeddingModel) GetDimensions() int
```

##### MockEmbeddingModel.GetModelName

```go
func (m *MockEmbeddingModel) GetModelName() string
```

### MockQdrantClient

#### Methods

##### MockQdrantClient.CreateCollection

```go
func (c *MockQdrantClient) CreateCollection(ctx context.Context, name string, config CollectionConfig) error
```

##### MockQdrantClient.GetCollection

```go
func (c *MockQdrantClient) GetCollection(ctx context.Context, name string) (*Collection, error)
```

##### MockQdrantClient.GetPoints

```go
func (c *MockQdrantClient) GetPoints(ctx context.Context, collection string, limit int, offset int) ([]Point, error)
```

##### MockQdrantClient.UpsertPoints

```go
func (c *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error
```

### Point

Point représente un point dans Qdrant


### QdrantClient

QdrantClient interface pour le client Qdrant


