# Package errormanager

## Types

### Point

Point represents a vector point in Qdrant


### QdrantClient

QdrantClient represents a Qdrant REST API client


## Functions

### InitializePostgres

InitializePostgres initializes the PostgreSQL connection


```go
func InitializePostgres(connStr string) error
```

### InitializeQdrant

InitializeQdrant initializes the Qdrant client


```go
func InitializeQdrant(endpoint string) error
```

### PersistErrorToSQL

PersistErrorToSQL inserts an ErrorEntry into the PostgreSQL database


```go
func PersistErrorToSQL(entry errormanager.ErrorEntry) error
```

### StoreErrorVector

StoreErrorVector stores an error vector in Qdrant


```go
func StoreErrorVector(collection string, vector []float32, payload map[string]interface{}) error
```

