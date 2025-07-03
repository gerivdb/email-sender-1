# Package toolsext

Package toolsext provides performance metrics extensions

Package toolsext provides sync logger functionality


## Types

### ExtPerformanceMetrics

ExtPerformanceMetrics represents extended performance metrics for the application


#### Methods

##### ExtPerformanceMetrics.CollectMetrics

CollectMetrics collects performance metrics


```go
func (p *ExtPerformanceMetrics) CollectMetrics()
```

##### ExtPerformanceMetrics.Reset

Reset resets all metrics


```go
func (p *ExtPerformanceMetrics) Reset()
```

### ExtSyncLogger

ExtSyncLogger represents a simple synchronization logger


#### Methods

##### ExtSyncLogger.LogDebug

LogDebug logs a debug message if debug is enabled


```go
func (sl *ExtSyncLogger) LogDebug(component, message string)
```

##### ExtSyncLogger.LogError

LogError logs an error message


```go
func (sl *ExtSyncLogger) LogError(component string, err error)
```

##### ExtSyncLogger.LogSync

LogSync logs a synchronization event


```go
func (sl *ExtSyncLogger) LogSync(component, message string)
```

##### ExtSyncLogger.StartOperation

StartOperation logs the start of an operation and returns a function to log its completion


```go
func (sl *ExtSyncLogger) StartOperation(name string) func(success bool)
```

