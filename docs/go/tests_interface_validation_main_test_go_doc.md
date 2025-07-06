# Package main

SPDX-License-Identifier: MIT
Package main - Test d'interface enhancement indépendant


## Types

### TestManagerImplementation

TestManagerImplementation teste l'implémentation ManagerType


#### Methods

##### TestManagerImplementation.Health

```go
func (tm *TestManagerImplementation) Health() docmanager.HealthStatus
```

##### TestManagerImplementation.Initialize

```go
func (tm *TestManagerImplementation) Initialize(ctx context.Context) error
```

##### TestManagerImplementation.Metrics

```go
func (tm *TestManagerImplementation) Metrics() docmanager.ManagerMetrics
```

##### TestManagerImplementation.Process

```go
func (tm *TestManagerImplementation) Process(ctx context.Context, data interface{}) (interface{}, error)
```

##### TestManagerImplementation.Shutdown

```go
func (tm *TestManagerImplementation) Shutdown() error
```

### TestRepositoryImplementation

TestRepositoryImplementation teste l'implémentation Repository étendue


#### Methods

##### TestRepositoryImplementation.Batch

```go
func (tr *TestRepositoryImplementation) Batch(ctx context.Context, operations []docmanager.Operation) ([]docmanager.BatchResult, error)
```

##### TestRepositoryImplementation.Commit

Transaction context methods


```go
func (tr *TestRepositoryImplementation) Commit() error
```

##### TestRepositoryImplementation.Delete

```go
func (tr *TestRepositoryImplementation) Delete(id string) error
```

##### TestRepositoryImplementation.DeleteWithContext

```go
func (tr *TestRepositoryImplementation) DeleteWithContext(ctx context.Context, id string) error
```

##### TestRepositoryImplementation.Get

```go
func (tr *TestRepositoryImplementation) Get(id string) (*docmanager.Document, error)
```

##### TestRepositoryImplementation.IsDone

```go
func (tr *TestRepositoryImplementation) IsDone() bool
```

##### TestRepositoryImplementation.List

```go
func (tr *TestRepositoryImplementation) List() ([]*docmanager.Document, error)
```

##### TestRepositoryImplementation.Retrieve

```go
func (tr *TestRepositoryImplementation) Retrieve(id string) (*docmanager.Document, error)
```

##### TestRepositoryImplementation.RetrieveWithContext

```go
func (tr *TestRepositoryImplementation) RetrieveWithContext(ctx context.Context, id string) (*docmanager.Document, error)
```

##### TestRepositoryImplementation.Rollback

```go
func (tr *TestRepositoryImplementation) Rollback() error
```

##### TestRepositoryImplementation.Save

Alias methods


```go
func (tr *TestRepositoryImplementation) Save(doc *docmanager.Document) error
```

##### TestRepositoryImplementation.Search

```go
func (tr *TestRepositoryImplementation) Search(query docmanager.SearchQuery) ([]*docmanager.Document, error)
```

##### TestRepositoryImplementation.SearchWithContext

```go
func (tr *TestRepositoryImplementation) SearchWithContext(ctx context.Context, query docmanager.SearchQuery) ([]*docmanager.Document, error)
```

##### TestRepositoryImplementation.Store

```go
func (tr *TestRepositoryImplementation) Store(doc *docmanager.Document) error
```

##### TestRepositoryImplementation.StoreWithContext

Enhanced context-aware methods


```go
func (tr *TestRepositoryImplementation) StoreWithContext(ctx context.Context, doc *docmanager.Document) error
```

##### TestRepositoryImplementation.Transaction

```go
func (tr *TestRepositoryImplementation) Transaction(ctx context.Context, fn func(docmanager.TransactionContext) error) error
```

