# Package workflow

## Types

### DynamicPlan

### FileWatcher

### RoadmapConnector

### SyncConfig

### SyncEngine

Additional components for unified workflow


### SyncPoint

SyncPoint represents a synchronization point in the workflow


### Task

### TaskMasterAdapter

### WorkflowConfig

WorkflowConfig holds configuration for the unified workflow


### WorkflowMetrics

WorkflowMetrics tracks performance and health metrics


### WorkflowOrchestrator

WorkflowOrchestrator manages the unified workflow between Markdown, Dynamic system, and Roadmap Manager


#### Methods

##### WorkflowOrchestrator.ExecuteFullSync

ExecuteFullSync performs a complete synchronization across all sync points


```go
func (wo *WorkflowOrchestrator) ExecuteFullSync(ctx context.Context) error
```

##### WorkflowOrchestrator.GetMetrics

GetMetrics returns current workflow metrics


```go
func (wo *WorkflowOrchestrator) GetMetrics() *WorkflowMetrics
```

##### WorkflowOrchestrator.GetSyncPoints

GetSyncPoints returns current synchronization points


```go
func (wo *WorkflowOrchestrator) GetSyncPoints() []SyncPoint
```

##### WorkflowOrchestrator.Initialize

Initialize sets up all components and synchronization points


```go
func (wo *WorkflowOrchestrator) Initialize() error
```

##### WorkflowOrchestrator.IsRunning

IsRunning returns whether the workflow orchestrator is currently running


```go
func (wo *WorkflowOrchestrator) IsRunning() bool
```

##### WorkflowOrchestrator.Start

Start begins the unified workflow orchestration


```go
func (wo *WorkflowOrchestrator) Start(ctx context.Context) error
```

##### WorkflowOrchestrator.Stop

Stop gracefully stops the workflow orchestration


```go
func (wo *WorkflowOrchestrator) Stop() error
```

