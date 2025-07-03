# Package ast

internal/ast/analyzer.go

internal/ast/cache.go

internal/ast/worker_pool.go


## Types

### ASTCache

#### Methods

##### ASTCache.Clear

```go
func (c *ASTCache) Clear()
```

##### ASTCache.Get

```go
func (c *ASTCache) Get(key string) (*interfaces.ASTAnalysisResult, bool)
```

##### ASTCache.GetStats

```go
func (c *ASTCache) GetStats() *interfaces.ASTCacheStats
```

##### ASTCache.Set

```go
func (c *ASTCache) Set(key string, data *interfaces.ASTAnalysisResult)
```

##### ASTCache.Size

```go
func (c *ASTCache) Size() int
```

##### ASTCache.Start

```go
func (c *ASTCache) Start(ctx context.Context)
```

##### ASTCache.Stop

```go
func (c *ASTCache) Stop()
```

### Task

### TaskResult

### Worker

### WorkerPool

#### Methods

##### WorkerPool.GetResult

```go
func (wp *WorkerPool) GetResult() <-chan TaskResult
```

##### WorkerPool.IsStarted

```go
func (wp *WorkerPool) IsStarted() bool
```

##### WorkerPool.Size

```go
func (wp *WorkerPool) Size() int
```

##### WorkerPool.Start

```go
func (wp *WorkerPool) Start(ctx context.Context) error
```

##### WorkerPool.Stop

```go
func (wp *WorkerPool) Stop(ctx context.Context) error
```

##### WorkerPool.SubmitTask

```go
func (wp *WorkerPool) SubmitTask(task Task) error
```

## Functions

### NewASTAnalysisManager

NewASTAnalysisManager crée une nouvelle instance


```go
func NewASTAnalysisManager(
	storageManager interfaces.StorageManager,
	errorManager interfaces.ErrorManager,
	configManager interfaces.ConfigManager,
	monitoringManager interfaces.MonitoringManager,
) (interfaces.ASTAnalysisManager, error)
```

