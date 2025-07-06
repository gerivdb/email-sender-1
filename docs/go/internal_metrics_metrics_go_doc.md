# Package metrics

Package metrics provides comprehensive monitoring for RAG system
Time-Saving Method 6: Metrics-Driven Development
ROI: +20h/month (identifies performance bottlenecks instantly)


## Types

### RAGMetrics

RAGMetrics provides comprehensive metrics collection for RAG operations


#### Methods

##### RAGMetrics.CollectSystemMetrics

CollectSystemMetrics starts a goroutine to collect system metrics


```go
func (m *RAGMetrics) CollectSystemMetrics(ctx context.Context, interval time.Duration)
```

##### RAGMetrics.GetHandler

GetHandler returns the Prometheus metrics HTTP handler


```go
func (m *RAGMetrics) GetHandler() http.Handler
```

##### RAGMetrics.GetRegistry

GetRegistry returns the Prometheus registry for custom metrics


```go
func (m *RAGMetrics) GetRegistry() *prometheus.Registry
```

##### RAGMetrics.IncrementCacheHits

Cache metrics


```go
func (m *RAGMetrics) IncrementCacheHits(cacheType, keyType string)
```

##### RAGMetrics.IncrementCacheMisses

```go
func (m *RAGMetrics) IncrementCacheMisses(cacheType, keyType string)
```

##### RAGMetrics.IncrementDocumentsIndexed

Business metrics


```go
func (m *RAGMetrics) IncrementDocumentsIndexed(collection, status string)
```

##### RAGMetrics.IncrementEmbeddingCacheHits

```go
func (m *RAGMetrics) IncrementEmbeddingCacheHits(cacheType string)
```

##### RAGMetrics.IncrementEmbeddingErrors

```go
func (m *RAGMetrics) IncrementEmbeddingErrors(errorType, model string)
```

##### RAGMetrics.IncrementEmbeddingTotal

```go
func (m *RAGMetrics) IncrementEmbeddingTotal(model, status string)
```

##### RAGMetrics.IncrementHTTPErrors

```go
func (m *RAGMetrics) IncrementHTTPErrors(method, endpoint, errorType string)
```

##### RAGMetrics.IncrementSearchErrors

```go
func (m *RAGMetrics) IncrementSearchErrors(errorType, collection string)
```

##### RAGMetrics.IncrementSearchTotal

```go
func (m *RAGMetrics) IncrementSearchTotal(collection, status string)
```

##### RAGMetrics.IncrementVectorDBErrors

```go
func (m *RAGMetrics) IncrementVectorDBErrors(errorType, operation string)
```

##### RAGMetrics.MetricsMiddleware

MetricsMiddleware creates HTTP middleware for automatic metrics collection


```go
func (m *RAGMetrics) MetricsMiddleware() func(http.Handler) http.Handler
```

##### RAGMetrics.NewSearchTimer

NewSearchTimer creates a timer for search operations


```go
func (m *RAGMetrics) NewSearchTimer(collection, resultRange, cacheStatus string) *RAGTimer
```

##### RAGMetrics.RecordEmbeddingDuration

Embedding operation metrics


```go
func (m *RAGMetrics) RecordEmbeddingDuration(model string, textLength int, duration time.Duration)
```

##### RAGMetrics.RecordHTTPRequest

HTTP metrics


```go
func (m *RAGMetrics) RecordHTTPRequest(method, endpoint, statusCode string, duration time.Duration)
```

##### RAGMetrics.RecordSearchDuration

Search operation metrics


```go
func (m *RAGMetrics) RecordSearchDuration(collection string, resultCount int, cached bool, duration time.Duration)
```

##### RAGMetrics.RecordVectorDBOperation

Vector database metrics


```go
func (m *RAGMetrics) RecordVectorDBOperation(operation, collection, status string, duration time.Duration)
```

##### RAGMetrics.SetActiveSearches

```go
func (m *RAGMetrics) SetActiveSearches(count float64)
```

##### RAGMetrics.SetCPUUsage

```go
func (m *RAGMetrics) SetCPUUsage(percent float64)
```

##### RAGMetrics.SetCacheSize

```go
func (m *RAGMetrics) SetCacheSize(cacheType string, bytes float64)
```

##### RAGMetrics.SetGoroutineCount

```go
func (m *RAGMetrics) SetGoroutineCount(count float64)
```

##### RAGMetrics.SetIndexingQueueSize

```go
func (m *RAGMetrics) SetIndexingQueueSize(size float64)
```

##### RAGMetrics.SetMemoryUsage

System metrics


```go
func (m *RAGMetrics) SetMemoryUsage(bytes float64)
```

##### RAGMetrics.SetTotalDocuments

```go
func (m *RAGMetrics) SetTotalDocuments(count float64)
```

##### RAGMetrics.SetVectorDBConnections

```go
func (m *RAGMetrics) SetVectorDBConnections(count float64)
```

##### RAGMetrics.StartMetricsServer

StartMetricsServer starts a dedicated metrics server


```go
func (m *RAGMetrics) StartMetricsServer(ctx context.Context, addr string) error
```

### RAGTimer

RAGTimer provides convenient timing for operations


#### Methods

##### RAGTimer.Stop

Stop records the timing and stops the timer


```go
func (t *RAGTimer) Stop()
```

