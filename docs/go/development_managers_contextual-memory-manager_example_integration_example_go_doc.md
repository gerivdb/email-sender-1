# Package main

## Types

### MockConfigManager

#### Methods

##### MockConfigManager.GetBool

```go
func (m *MockConfigManager) GetBool(key string) bool
```

##### MockConfigManager.GetInt

```go
func (m *MockConfigManager) GetInt(key string) int
```

##### MockConfigManager.GetStatus

```go
func (m *MockConfigManager) GetStatus() string
```

##### MockConfigManager.GetString

```go
func (m *MockConfigManager) GetString(key string) string
```

##### MockConfigManager.Initialize

```go
func (m *MockConfigManager) Initialize(ctx context.Context) error
```

##### MockConfigManager.Shutdown

```go
func (m *MockConfigManager) Shutdown(ctx context.Context) error
```

### MockDB

#### Methods

##### MockDB.Close

```go
func (m *MockDB) Close() error
```

##### MockDB.Ping

```go
func (m *MockDB) Ping() error
```

### MockErrorManager

#### Methods

##### MockErrorManager.GetStatus

```go
func (m *MockErrorManager) GetStatus() string
```

##### MockErrorManager.Initialize

```go
func (m *MockErrorManager) Initialize(ctx context.Context) error
```

##### MockErrorManager.LogError

```go
func (m *MockErrorManager) LogError(ctx context.Context, message string, err error)
```

##### MockErrorManager.ProcessError

```go
func (m *MockErrorManager) ProcessError(ctx context.Context, err error) error
```

##### MockErrorManager.Shutdown

```go
func (m *MockErrorManager) Shutdown(ctx context.Context) error
```

### MockStorageManager

Mock implementations (same as in test files)


#### Methods

##### MockStorageManager.GetPostgreSQLConnection

```go
func (m *MockStorageManager) GetPostgreSQLConnection() (interface{}, error)
```

##### MockStorageManager.GetSQLiteConnection

```go
func (m *MockStorageManager) GetSQLiteConnection(dbPath string) (interface{}, error)
```

##### MockStorageManager.GetStatus

```go
func (m *MockStorageManager) GetStatus() string
```

##### MockStorageManager.Initialize

```go
func (m *MockStorageManager) Initialize(ctx context.Context) error
```

##### MockStorageManager.Shutdown

```go
func (m *MockStorageManager) Shutdown(ctx context.Context) error
```

