# Package cachemanager

## Types

### CacheAdapter

Interfaces des adapters


### CacheManager

CacheManager principal


#### Methods

##### CacheManager.GetContext

GetContext — Récupération contextuelle


```go
func (cm *CacheManager) GetContext(key string) (interface{}, error)
```

##### CacheManager.GetLogs

GetLogs — Recherche unifiée (LMCache prioritaire)


```go
func (cm *CacheManager) GetLogs(query LogQuery) ([]LogEntry, error)
```

##### CacheManager.StoreContext

StoreContext — Stockage contextuel


```go
func (cm *CacheManager) StoreContext(key string, value interface{}) error
```

##### CacheManager.StoreLog

StoreLog — Orchestration selon la politique (LMCache prioritaire)


```go
func (cm *CacheManager) StoreLog(entry LogEntry) error
```

### LMCacheAdapter

LMCacheAdapter — implémente CacheAdapter pour LMCache


#### Methods

##### LMCacheAdapter.GetContext

```go
func (l *LMCacheAdapter) GetContext(key string) (interface{}, error)
```

##### LMCacheAdapter.GetLogs

```go
func (l *LMCacheAdapter) GetLogs(query LogQuery) ([]LogEntry, error)
```

##### LMCacheAdapter.StoreContext

```go
func (l *LMCacheAdapter) StoreContext(key string, value interface{}) error
```

##### LMCacheAdapter.StoreLog

```go
func (l *LMCacheAdapter) StoreLog(entry LogEntry) error
```

### LMCacheClient

Simule un client LMCache (à remplacer par l’intégration réelle)


### LogEntry

Structure du log (conforme à logging_format_spec.json)


### LogQuery

Structure de requête de logs


### RedisAdapter

RedisAdapter — implémente CacheAdapter pour Redis


#### Methods

##### RedisAdapter.GetContext

```go
func (r *RedisAdapter) GetContext(key string) (interface{}, error)
```

##### RedisAdapter.GetLogs

```go
func (r *RedisAdapter) GetLogs(query LogQuery) ([]LogEntry, error)
```

##### RedisAdapter.StoreContext

```go
func (r *RedisAdapter) StoreContext(key string, value interface{}) error
```

##### RedisAdapter.StoreLog

```go
func (r *RedisAdapter) StoreLog(entry LogEntry) error
```

### RedisClient

Simule un client Redis (à remplacer par l’intégration réelle)


### SQLiteAdapter

SQLiteAdapter — implémente CacheAdapter pour SQLite


#### Methods

##### SQLiteAdapter.GetContext

```go
func (s *SQLiteAdapter) GetContext(key string) (interface{}, error)
```

##### SQLiteAdapter.GetLogs

```go
func (s *SQLiteAdapter) GetLogs(query LogQuery) ([]LogEntry, error)
```

##### SQLiteAdapter.StoreContext

```go
func (s *SQLiteAdapter) StoreContext(key string, value interface{}) error
```

##### SQLiteAdapter.StoreLog

```go
func (s *SQLiteAdapter) StoreLog(entry LogEntry) error
```

### SQLiteClient

Simule un client SQLite (à remplacer par l’intégration réelle)


# Package main

