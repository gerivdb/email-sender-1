# Package dashboard

## Types

### ConflictInfo

ConflictInfo represents conflict information from the sync engine


### ConflictResolutionRequest

ConflictResolutionRequest represents a conflict resolution request


### DivergenceInfo

DivergenceInfo represents a detected divergence


### PerformanceMetrics

PerformanceMetrics represents sync performance data


### SyncDashboard

SyncDashboard represents the web dashboard for synchronization monitoring


#### Methods

##### SyncDashboard.Start

Start starts the dashboard web server


```go
func (sd *SyncDashboard) Start(port string) error
```

##### SyncDashboard.Stop

Stop gracefully stops the dashboard


```go
func (sd *SyncDashboard) Stop(ctx context.Context) error
```

### SyncEngine

SyncEngine defines the interface for the synchronization engine


### SyncHistoryEntry

SyncHistoryEntry represents a sync history entry


### SyncStatus

SyncStatus represents the current synchronization status


