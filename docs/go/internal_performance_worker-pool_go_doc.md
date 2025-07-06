# Package performance

## Types

### PoolConfig

PoolConfig contient la configuration du pool


### Task

Task représente une tâche à exécuter


### WorkerPool

WorkerPool représente un pool de workers optimisé pour la vectorisation


#### Methods

##### WorkerPool.GetStats

GetStats retourne les statistiques actuelles du pool


```go
func (wp *WorkerPool) GetStats() map[string]interface{}
```

##### WorkerPool.Shutdown

Shutdown arrête proprement le worker pool


```go
func (wp *WorkerPool) Shutdown(timeout time.Duration) error
```

##### WorkerPool.Submit

Submit soumet une tâche au pool


```go
func (wp *WorkerPool) Submit(task Task) error
```

### WorkerPoolMetrics

WorkerPoolMetrics contient les métriques pour les worker pools


