# Package parallel

Package parallel provides batch storage optimization for massive data ingestion

Package parallel provides performance monitoring and resource management

Package parallel provides concurrent processing capabilities for massive plan ingestion


## Types

### BatchJob

BatchJob represents a batch of files to process


### BatchResult

BatchResult contains the result of processing a batch


### BatchStorage

BatchStorage provides optimized batch storage operations


#### Methods

##### BatchStorage.AddItem

AddItem adds an item to the batch buffer


```go
func (bs *BatchStorage) AddItem(item types.RoadmapItem) error
```

##### BatchStorage.AddItems

AddItems adds multiple items to the batch buffer


```go
func (bs *BatchStorage) AddItems(items []types.RoadmapItem) error
```

##### BatchStorage.Close

Close flushes all remaining items and closes the batch storage


```go
func (bs *BatchStorage) Close() error
```

##### BatchStorage.Flush

Flush manually flushes all buffered items to storage


```go
func (bs *BatchStorage) Flush() error
```

##### BatchStorage.GetMetrics

GetMetrics returns current storage metrics


```go
func (bs *BatchStorage) GetMetrics() BatchStorageMetrics
```

### BatchStorageConfig

BatchStorageConfig contains configuration for batch storage operations


### BatchStorageMetrics

BatchStorageMetrics tracks batch storage performance


### ConcurrentBatchStorage

ConcurrentBatchStorage provides thread-safe batch storage with multiple writers


#### Methods

##### ConcurrentBatchStorage.AddItem

AddItem safely adds an item from multiple goroutines


```go
func (cbs *ConcurrentBatchStorage) AddItem(item types.RoadmapItem) error
```

##### ConcurrentBatchStorage.AddItems

AddItems safely adds multiple items from multiple goroutines


```go
func (cbs *ConcurrentBatchStorage) AddItems(items []types.RoadmapItem) error
```

##### ConcurrentBatchStorage.Close

Close safely closes from multiple goroutines


```go
func (cbs *ConcurrentBatchStorage) Close() error
```

##### ConcurrentBatchStorage.Flush

Flush safely flushes from multiple goroutines


```go
func (cbs *ConcurrentBatchStorage) Flush() error
```

##### ConcurrentBatchStorage.GetMetrics

GetMetrics safely gets metrics from multiple goroutines


```go
func (cbs *ConcurrentBatchStorage) GetMetrics() BatchStorageMetrics
```

### PerformanceMonitor

PerformanceMonitor tracks system performance during parallel processing


#### Methods

##### PerformanceMonitor.GetCurrentSample

GetCurrentSample returns the most recent performance sample


```go
func (pm *PerformanceMonitor) GetCurrentSample() PerformanceSample
```

##### PerformanceMonitor.Start

Start begins performance monitoring in a background goroutine


```go
func (pm *PerformanceMonitor) Start(ctx context.Context)
```

##### PerformanceMonitor.Stop

Stop stops performance monitoring and returns a report


```go
func (pm *PerformanceMonitor) Stop() PerformanceReport
```

### PerformanceReport

PerformanceReport provides a comprehensive performance summary


### PerformanceSample

PerformanceSample represents a point-in-time performance measurement


### PlanProcessor

PlanProcessor handles parallel processing of plan files


#### Methods

##### PlanProcessor.GetMetrics

GetMetrics returns current processing metrics (thread-safe)


```go
func (p *PlanProcessor) GetMetrics() ProcessingMetrics
```

##### PlanProcessor.ProcessPlansParallel

ProcessPlansParallel processes plan files in parallel using worker pools


```go
func (p *PlanProcessor) ProcessPlansParallel(
	ctx context.Context,
	planFiles []string,
	ingester *ingestion.PlanIngester,
	roadmapStorage *storage.JSONStorage,
) ([]types.RoadmapItem, ProcessingMetrics, error)
```

### ProcessingMetrics

ProcessingMetrics tracks processing statistics


### ProcessorConfig

ProcessorConfig contains configuration for parallel processing


### ResourceManager

ResourceManager provides dynamic resource management during processing


#### Methods

##### ResourceManager.GetOptimalWorkerCount

GetOptimalWorkerCount returns the recommended number of workers


```go
func (rm *ResourceManager) GetOptimalWorkerCount() int
```

##### ResourceManager.SetWorkerCount

SetWorkerCount updates the current worker count


```go
func (rm *ResourceManager) SetWorkerCount(count int)
```

##### ResourceManager.ShouldReduceWorkers

ShouldReduceWorkers checks if worker count should be reduced due to resource pressure


```go
func (rm *ResourceManager) ShouldReduceWorkers() bool
```

