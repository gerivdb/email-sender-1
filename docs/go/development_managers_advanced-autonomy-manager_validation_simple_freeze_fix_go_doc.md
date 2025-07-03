# Package advanced_autonomy_manager

## Types

### SimpleAdvancedAutonomyManager

SimpleAdvancedAutonomyManager minimal implementation focusing on freeze fix


#### Methods

##### SimpleAdvancedAutonomyManager.Cleanup

Cleanup shuts down the manager - THIS IS WHERE THE FREEZE FIX IS CRITICAL


```go
func (sam *SimpleAdvancedAutonomyManager) Cleanup() error
```

##### SimpleAdvancedAutonomyManager.HealthCheck

HealthCheck checks if the manager is healthy


```go
func (sam *SimpleAdvancedAutonomyManager) HealthCheck(ctx context.Context) error
```

##### SimpleAdvancedAutonomyManager.Initialize

Initialize starts the manager with workers


```go
func (sam *SimpleAdvancedAutonomyManager) Initialize(ctx context.Context) error
```

### SimpleLogger

SimpleLogger basic logger implementation for testing


#### Methods

##### SimpleLogger.Debug

```go
func (s *SimpleLogger) Debug(msg string)
```

##### SimpleLogger.Error

```go
func (s *SimpleLogger) Error(msg string)
```

##### SimpleLogger.Info

```go
func (s *SimpleLogger) Info(msg string)
```

##### SimpleLogger.Warn

```go
func (s *SimpleLogger) Warn(msg string)
```

##### SimpleLogger.WithError

```go
func (s *SimpleLogger) WithError(err error) Logger
```

### Worker

Worker represents a worker goroutine that could cause freeze


# Package main

