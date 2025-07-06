# Package vectorization

## Types

### CacheEntry

CacheEntry représente une entrée dans le cache


### CacheMetrics

CacheMetrics contient les métriques du cache


### CircuitBreaker

CircuitBreaker implémente un circuit breaker pour les opérations vectorielles


#### Methods

##### CircuitBreaker.Execute

Execute exécute une opération via le circuit breaker


```go
func (cb *CircuitBreaker) Execute(operation string, fn func() error) error
```

##### CircuitBreaker.GetState

GetState retourne l'état actuel du circuit breaker


```go
func (cb *CircuitBreaker) GetState() string
```

### CollectionInfo

CollectionInfo représente les informations d'une collection


### Connection

Connection représente une connexion au serveur Qdrant


### ConnectionPool

ConnectionPool gère un pool de connexions pour Qdrant


#### Methods

##### ConnectionPool.Close

Close ferme le pool et toutes ses connexions


```go
func (cp *ConnectionPool) Close() error
```

##### ConnectionPool.GetConnection

GetConnection récupère une connexion du pool


```go
func (cp *ConnectionPool) GetConnection(ctx context.Context) (Connection, error)
```

##### ConnectionPool.GetMetrics

GetMetrics retourne les métriques actuelles du pool


```go
func (cp *ConnectionPool) GetMetrics() PoolMetrics
```

##### ConnectionPool.HealthCheck

HealthCheck vérifie la santé du pool


```go
func (cp *ConnectionPool) HealthCheck(ctx context.Context) error
```

##### ConnectionPool.ReturnConnection

ReturnConnection remet une connexion dans le pool


```go
func (cp *ConnectionPool) ReturnConnection(conn Connection)
```

### ErrorHandler

ErrorHandler gère les erreurs et les retry


#### Methods

##### ErrorHandler.ExecuteWithRetry

ExecuteWithRetry exécute une opération avec retry automatique


```go
func (eh *ErrorHandler) ExecuteWithRetry(ctx context.Context, operation string, fn func() error) error
```

### ErrorType

ErrorType représente le type d'erreur vectorielle


### LRUNode

LRUNode représente un nœud dans la liste LRU


### MigrationConfig

MigrationConfig configure la migration


### MigrationStats

MigrationStats contient les statistiques de migration


### PoolMetrics

PoolMetrics contient les métriques du pool de connexions


### PythonVectorData

PythonVectorData représente la structure des données vectorielles Python


### RetryConfig

RetryConfig configure la stratégie de retry


### SearchResult

SearchResult représente un résultat de recherche vectorielle


### Vector

Vector représente un vecteur avec ses métadonnées


### VectorCache

VectorCache implémente un cache LRU pour les résultats de recherche vectorielle


#### Methods

##### VectorCache.Clear

Clear vide complètement le cache


```go
func (vc *VectorCache) Clear()
```

##### VectorCache.Get

Get récupère les résultats du cache


```go
func (vc *VectorCache) Get(ctx context.Context, query Vector, topK int) ([]SearchResult, bool)
```

##### VectorCache.GetMetrics

GetMetrics retourne les métriques du cache


```go
func (vc *VectorCache) GetMetrics() CacheMetrics
```

##### VectorCache.Put

Put stocke les résultats dans le cache


```go
func (vc *VectorCache) Put(ctx context.Context, query Vector, topK int, results []SearchResult)
```

### VectorClient

VectorClient représente le client de vectorisation unifié


#### Methods

##### VectorClient.CreateCollection

CreateCollection crée une nouvelle collection vectorielle


```go
func (vc *VectorClient) CreateCollection(ctx context.Context) error
```

##### VectorClient.DeleteCollection

DeleteCollection supprime une collection


```go
func (vc *VectorClient) DeleteCollection(ctx context.Context) error
```

##### VectorClient.GetCollectionInfo

GetCollectionInfo récupère les informations de la collection


```go
func (vc *VectorClient) GetCollectionInfo(ctx context.Context) (*CollectionInfo, error)
```

##### VectorClient.ListVectors

ListVectors liste tous les vecteurs d'une collection


```go
func (vc *VectorClient) ListVectors(ctx context.Context) ([]Vector, error)
```

##### VectorClient.SearchVectors

SearchVectors recherche des vecteurs similaires


```go
func (vc *VectorClient) SearchVectors(ctx context.Context, query Vector, topK int) ([]SearchResult, error)
```

##### VectorClient.SearchVectorsParallel

SearchVectorsParallel effectue des recherches vectorielles en parallèle


```go
func (vc *VectorClient) SearchVectorsParallel(ctx context.Context, queries []Vector, topK int) ([]SearchResult, error)
```

##### VectorClient.UpsertVectors

UpsertVectors insère ou met à jour des vecteurs


```go
func (vc *VectorClient) UpsertVectors(ctx context.Context, vectors []Vector) error
```

### VectorConfig

VectorConfig contient la configuration du client vectoriel


### VectorError

VectorError représente une erreur dans les opérations vectorielles


#### Methods

##### VectorError.Error

```go
func (ve *VectorError) Error() string
```

##### VectorError.Unwrap

```go
func (ve *VectorError) Unwrap() error
```

### VectorMigrator

VectorMigrator gère la migration des vecteurs depuis Python vers Go


#### Methods

##### VectorMigrator.ExportMigrationReport

ExportMigrationReport exporte un rapport de migration


```go
func (vm *VectorMigrator) ExportMigrationReport(outputPath string) error
```

##### VectorMigrator.GetMigrationStats

GetMigrationStats retourne les statistiques actuelles de migration


```go
func (vm *VectorMigrator) GetMigrationStats() MigrationStats
```

##### VectorMigrator.MigratePythonVectors

MigratePythonVectors migre tous les vecteurs Python vers Go


```go
func (vm *VectorMigrator) MigratePythonVectors(ctx context.Context) error
```

### VectorOperations

VectorOperations étend VectorClient avec les opérations CRUD avancées


#### Methods

##### VectorOperations.BatchUpsertVectors

BatchUpsertVectors insère des vecteurs par lots pour optimiser les performances


```go
func (vo *VectorOperations) BatchUpsertVectors(ctx context.Context, vectors []Vector) error
```

##### VectorOperations.BulkDelete

BulkDelete supprime plusieurs vecteurs par leurs IDs


```go
func (vo *VectorOperations) BulkDelete(ctx context.Context, vectorIDs []string) error
```

##### VectorOperations.DeleteVector

DeleteVector supprime un vecteur par son ID


```go
func (vo *VectorOperations) DeleteVector(ctx context.Context, vectorID string) error
```

##### VectorOperations.GetStats

GetStats récupère les statistiques de la collection


```go
func (vo *VectorOperations) GetStats(ctx context.Context) (map[string]interface{}, error)
```

##### VectorOperations.GetVector

GetVector récupère un vecteur par son ID


```go
func (vo *VectorOperations) GetVector(ctx context.Context, vectorID string) (*Vector, error)
```

##### VectorOperations.SearchVectorsParallel

SearchVectorsParallel recherche des vecteurs similaires en parallèle pour plusieurs requêtes


```go
func (vo *VectorOperations) SearchVectorsParallel(ctx context.Context, queries []Vector, topK int) ([][]SearchResult, error)
```

##### VectorOperations.UpdateVector

UpdateVector met à jour un vecteur existant


```go
func (vo *VectorOperations) UpdateVector(ctx context.Context, vector Vector) error
```

## Functions

### ValidateVector

ValidateVector valide un vecteur avant traitement


```go
func ValidateVector(vector Vector, expectedSize int) error
```

### ValidateVectors

ValidateVectors valide un lot de vecteurs


```go
func ValidateVectors(vectors []Vector, expectedSize int) error
```

