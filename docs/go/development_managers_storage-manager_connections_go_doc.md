# Package storage

## Types

### CacheConfig

CacheConfig configuration cache


### ColumnSchema

ColumnSchema représente un schéma de colonne


### ConfigMetadata

ConfigMetadata métadonnées d'un fichier de configuration indexé


### ConfigurationIndexer

ConfigurationIndexer gère l'auto-indexation des fichiers de configuration


### ConstraintSchema

ConstraintSchema représente une contrainte


### DatabaseSchema

DatabaseSchema représente un schéma de base de données


### ForeignKey

ForeignKey représente une clé étrangère


### IndexSchema

IndexSchema représente un index


### MigrationManager

MigrationManager gère les migrations de base de données


### MigrationsConfig

MigrationsConfig configuration migrations


### PostgreSQLConfig

PostgreSQLConfig configuration PostgreSQL


### QdrantClient

QdrantClient interface pour Qdrant


### QdrantConfig

QdrantConfig configuration Qdrant


### QdrantSearchResult

QdrantSearchResult résultat de recherche Qdrant


### RelationSchema

RelationSchema représente une relation entre tables


### SchemaVectorizer

SchemaVectorizer gère la vectorisation des schémas de base de données


### SearchResult

SearchResult représente un résultat de recherche sémantique


### SemanticSearcher

SemanticSearcher gère la recherche sémantique dans les configurations


### StorageConfig

StorageConfig configuration pour le gestionnaire de stockage


### StorageManagerImpl

StorageManagerImpl implémente StorageManager


#### Methods

##### StorageManagerImpl.DeleteObject

DeleteObject supprime un objet


```go
func (sm *StorageManagerImpl) DeleteObject(ctx context.Context, key string) error
```

##### StorageManagerImpl.DisableVectorization

DisableVectorization désactive la vectorisation


```go
func (sm *StorageManagerImpl) DisableVectorization() error
```

##### StorageManagerImpl.EnableVectorization

EnableVectorization active la vectorisation


```go
func (sm *StorageManagerImpl) EnableVectorization() error
```

##### StorageManagerImpl.FindSimilarSchemas

FindSimilarSchemas trouve des schémas similaires


```go
func (sm *StorageManagerImpl) FindSimilarSchemas(ctx context.Context, schemaName string, threshold float64) ([]SearchResult, error)
```

##### StorageManagerImpl.GetDependencyMetadata

GetDependencyMetadata récupère les métadonnées de dépendance


```go
func (sm *StorageManagerImpl) GetDependencyMetadata(ctx context.Context, name string) (*interfaces.DependencyMetadata, error)
```

##### StorageManagerImpl.GetID

GetID retourne l'ID du manager


```go
func (sm *StorageManagerImpl) GetID() string
```

##### StorageManagerImpl.GetName

GetName retourne le nom du manager


```go
func (sm *StorageManagerImpl) GetName() string
```

##### StorageManagerImpl.GetObject

GetObject récupère un objet générique


```go
func (sm *StorageManagerImpl) GetObject(ctx context.Context, key string, obj interface{}) error
```

##### StorageManagerImpl.GetPostgreSQLConnection

GetPostgreSQLConnection returns the PostgreSQL connection


```go
func (sm *StorageManagerImpl) GetPostgreSQLConnection() (interface{}, error)
```

##### StorageManagerImpl.GetQdrantConnection

GetQdrantConnection returns the Qdrant connection


```go
func (sm *StorageManagerImpl) GetQdrantConnection() (interface{}, error)
```

##### StorageManagerImpl.GetSchemaEmbedding

GetSchemaEmbedding récupère l'embedding d'un schéma


```go
func (sm *StorageManagerImpl) GetSchemaEmbedding(ctx context.Context, schemaName string) ([]float32, error)
```

##### StorageManagerImpl.GetStatus

GetStatus retourne le statut du manager


```go
func (sm *StorageManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### StorageManagerImpl.GetVectorizationMetrics

GetVectorizationMetrics retourne les métriques de vectorisation


```go
func (sm *StorageManagerImpl) GetVectorizationMetrics() VectorizationMetrics
```

##### StorageManagerImpl.GetVectorizationStatus

GetVectorizationStatus retourne le statut de la vectorisation


```go
func (sm *StorageManagerImpl) GetVectorizationStatus() bool
```

##### StorageManagerImpl.GetVersion

GetVersion retourne la version du manager


```go
func (sm *StorageManagerImpl) GetVersion() string
```

##### StorageManagerImpl.Health

Health vérifie la santé du gestionnaire


```go
func (sm *StorageManagerImpl) Health(ctx context.Context) error
```

##### StorageManagerImpl.IndexConfiguration

IndexConfiguration indexe un fichier de configuration


```go
func (sm *StorageManagerImpl) IndexConfiguration(ctx context.Context, filePath string) error
```

##### StorageManagerImpl.IndexDatabaseSchema

IndexDatabaseSchema indexe un schéma de base de données


```go
func (sm *StorageManagerImpl) IndexDatabaseSchema(ctx context.Context, schemaName string) error
```

##### StorageManagerImpl.Initialize

Initialize initialise le gestionnaire de stockage


```go
func (sm *StorageManagerImpl) Initialize(ctx context.Context) error
```

##### StorageManagerImpl.ListObjects

ListObjects liste les objets avec un préfixe


```go
func (sm *StorageManagerImpl) ListObjects(ctx context.Context, prefix string) ([]string, error)
```

##### StorageManagerImpl.QueryDependencies

QueryDependencies recherche des dépendances


```go
func (sm *StorageManagerImpl) QueryDependencies(ctx context.Context, query string) ([]*interfaces.DependencyMetadata, error)
```

##### StorageManagerImpl.RemoveConfigurationIndex

RemoveConfigurationIndex supprime un fichier de l'index


```go
func (sm *StorageManagerImpl) RemoveConfigurationIndex(ctx context.Context, filePath string) error
```

##### StorageManagerImpl.RunMigrations

RunMigrations exécute les migrations de base de données


```go
func (sm *StorageManagerImpl) RunMigrations(ctx context.Context) error
```

##### StorageManagerImpl.SaveDependencyMetadata

SaveDependencyMetadata sauvegarde les métadonnées de dépendance


```go
func (sm *StorageManagerImpl) SaveDependencyMetadata(ctx context.Context, metadata *interfaces.DependencyMetadata) error
```

##### StorageManagerImpl.SearchAll

SearchAll recherche dans tous les types


```go
func (sm *StorageManagerImpl) SearchAll(ctx context.Context, query string, limit int) ([]SearchResult, error)
```

##### StorageManagerImpl.SearchConfigurations

SearchConfigurations recherche dans les configurations


```go
func (sm *StorageManagerImpl) SearchConfigurations(ctx context.Context, query string, limit int) ([]SearchResult, error)
```

##### StorageManagerImpl.SearchSchemas

SearchSchemas recherche dans les schémas


```go
func (sm *StorageManagerImpl) SearchSchemas(ctx context.Context, query string, limit int) ([]SearchResult, error)
```

##### StorageManagerImpl.SearchTables

SearchTables recherche dans les tables


```go
func (sm *StorageManagerImpl) SearchTables(ctx context.Context, query string, limit int) ([]SearchResult, error)
```

##### StorageManagerImpl.Start

Start démarre le gestionnaire de stockage


```go
func (sm *StorageManagerImpl) Start(ctx context.Context) error
```

##### StorageManagerImpl.Stop

Stop arrête le gestionnaire de stockage


```go
func (sm *StorageManagerImpl) Stop(ctx context.Context) error
```

##### StorageManagerImpl.StoreObject

StoreObject stocke un objet générique


```go
func (sm *StorageManagerImpl) StoreObject(ctx context.Context, key string, obj interface{}) error
```

##### StorageManagerImpl.UpdateConfigurationIndex

UpdateConfigurationIndex met à jour l'index d'un fichier de configuration


```go
func (sm *StorageManagerImpl) UpdateConfigurationIndex(ctx context.Context, filePath string) error
```

##### StorageManagerImpl.UpdateSchemaIndex

UpdateSchemaIndex met à jour l'index d'un schéma


```go
func (sm *StorageManagerImpl) UpdateSchemaIndex(ctx context.Context, schemaName string) error
```

##### StorageManagerImpl.WatchConfigurationDirectory

WatchConfigurationDirectory surveille un répertoire pour les changements de configuration


```go
func (sm *StorageManagerImpl) WatchConfigurationDirectory(ctx context.Context, dirPath string) error
```

### StorageVectorization

StorageVectorization interface pour les capacités de vectorisation du Storage Manager


### TableSchema

TableSchema représente un schéma de table


### VectorizationEngine

VectorizationEngine interface pour le moteur de vectorisation


### VectorizationMetrics

VectorizationMetrics métriques de vectorisation


## Functions

### NewStorageManager

NewStorageManager crée une nouvelle instance du gestionnaire de stockage


```go
func NewStorageManager() interfaces.StorageManager
```

