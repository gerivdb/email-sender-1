# Package conflict

## Types

### AlertingSystem

AlertingSystem with configurable thresholds.


#### Methods

##### AlertingSystem.Check

```go
func (a *AlertingSystem) Check(value int)
```

### AutoMergeStrategy

AutoMergeStrategy implements automatic safe merging.


#### Methods

##### AutoMergeStrategy.Execute

```go
func (a *AutoMergeStrategy) Execute(conflict Conflict) (Resolution, error)
```

##### AutoMergeStrategy.Rollback

```go
func (a *AutoMergeStrategy) Rollback(res Resolution) error
```

##### AutoMergeStrategy.Validate

```go
func (a *AutoMergeStrategy) Validate(res Resolution) error
```

### BackupAndReplaceStrategy

BackupAndReplaceStrategy implements backup then replace resolution.


#### Methods

##### BackupAndReplaceStrategy.Execute

```go
func (b *BackupAndReplaceStrategy) Execute(conflict Conflict) (Resolution, error)
```

##### BackupAndReplaceStrategy.Rollback

```go
func (b *BackupAndReplaceStrategy) Rollback(res Resolution) error
```

##### BackupAndReplaceStrategy.Validate

```go
func (b *BackupAndReplaceStrategy) Validate(res Resolution) error
```

### Conflict

Conflict represents a detected conflict in the system.


#### Methods

##### Conflict.String

```go
func (c Conflict) String() string
```

### ConflictHistory

ConflictHistory structure with timestamps and metadata.


#### Methods

##### ConflictHistory.Add

```go
func (h *ConflictHistory) Add(record ConflictRecord)
```

##### ConflictHistory.CommitResolution

Versioning resolutions with Git integration.


```go
func (h *ConflictHistory) CommitResolution(message string) error
```

##### ConflictHistory.ExportHistory

ExportHistory exports history to JSON.


```go
func (h *ConflictHistory) ExportHistory(path string) error
```

##### ConflictHistory.Filter

```go
func (h *ConflictHistory) Filter(resolved bool) []ConflictRecord
```

##### ConflictHistory.ImportHistory

ImportHistory imports history from JSON.


```go
func (h *ConflictHistory) ImportHistory(path string) error
```

##### ConflictHistory.LoadHistory

LoadHistory loads ConflictHistory from a JSON file.


```go
func (h *ConflictHistory) LoadHistory(path string) error
```

##### ConflictHistory.SaveHistory

SaveHistory saves ConflictHistory to a JSON file.


```go
func (h *ConflictHistory) SaveHistory(path string) error
```

##### ConflictHistory.SearchByType

Search and filter in history.


```go
func (h *ConflictHistory) SearchByType(t ConflictType) []ConflictRecord
```

### ConflictManager

ConflictManager orchestrates the detection and resolution of multiple conflicts.


#### Methods

##### ConflictManager.AddConflict

```go
func (cm *ConflictManager) AddConflict(c Conflict)
```

##### ConflictManager.ListConflicts

```go
func (cm *ConflictManager) ListConflicts() []Conflict
```

### ConflictMonitor

ConflictMonitor monitors conflicts in real time using channels and goroutines.


#### Methods

##### ConflictMonitor.Start

```go
func (m *ConflictMonitor) Start()
```

##### ConflictMonitor.Stop

```go
func (m *ConflictMonitor) Stop()
```

### ConflictRecord

### ConflictScorer

ConflictScorer interface for scoring and comparing conflicts.


### ConflictType

ConflictType represents the type of conflict encountered.


#### Methods

##### ConflictType.String

```go
func (ct ConflictType) String() string
```

### ConflictWithScore

### ContentConflictDetector

ContentConflictDetector detects content-based conflicts (concurrent modifications).


#### Methods

##### ContentConflictDetector.Detect

Detect scans the given files for content conflicts (dummy implementation for demo).


```go
func (c *ContentConflictDetector) Detect(files []string) ([]Conflict, error)
```

### MultiCriteriaScorer

MultiCriteriaScorer implements ConflictScorer with impact, urgency, complexity.


#### Methods

##### MultiCriteriaScorer.Calculate

```go
func (m *MultiCriteriaScorer) Calculate(conflict Conflict) float64
```

##### MultiCriteriaScorer.Compare

```go
func (m *MultiCriteriaScorer) Compare(a, b Conflict) int
```

### PathConflictDetector

PathConflictDetector detects path-related conflicts (broken links, duplicates).


#### Methods

##### PathConflictDetector.Detect

Detect scans the given root directory for path conflicts.


```go
func (p *PathConflictDetector) Detect(root string) ([]Conflict, error)
```

### PermissionConflictDetector

PermissionConflictDetector detects permission-related conflicts.


#### Methods

##### PermissionConflictDetector.Detect

Detect checks for permission conflicts in the provided files (dummy: files not readable).


```go
func (p *PermissionConflictDetector) Detect(files []string) ([]Conflict, error)
```

### PriorityBasedStrategy

PriorityBasedStrategy implements resolution based on priority/weight.


#### Methods

##### PriorityBasedStrategy.Execute

```go
func (p *PriorityBasedStrategy) Execute(conflict Conflict) (Resolution, error)
```

##### PriorityBasedStrategy.Rollback

```go
func (p *PriorityBasedStrategy) Rollback(res Resolution) error
```

##### PriorityBasedStrategy.Validate

```go
func (p *PriorityBasedStrategy) Validate(res Resolution) error
```

### PriorityQueue

PriorityQueue implements a priority queue for conflicts.


#### Methods

##### PriorityQueue.Len

```go
func (pq PriorityQueue) Len() int
```

##### PriorityQueue.Less

```go
func (pq PriorityQueue) Less(i, j int) bool
```

##### PriorityQueue.Peek

```go
func (pq *PriorityQueue) Peek() *ConflictWithScore
```

##### PriorityQueue.Pop

```go
func (pq *PriorityQueue) Pop() interface{}
```

##### PriorityQueue.Push

```go
func (pq *PriorityQueue) Push(x interface{})
```

##### PriorityQueue.Swap

```go
func (pq PriorityQueue) Swap(i, j int)
```

### RealTimeDetector

RealTimeDetector uses fsnotify and channels for real-time conflict detection.


#### Methods

##### RealTimeDetector.Close

```go
func (r *RealTimeDetector) Close() error
```

##### RealTimeDetector.Watch

```go
func (r *RealTimeDetector) Watch(path string) error
```

### Resolution

Resolution represents the result of a conflict resolution attempt.


### ResolutionStrategy

ResolutionStrategy defines the interface for all resolution strategies.


### RollbackManager

RollbackManager handles rollback of resolutions.


#### Methods

##### RollbackManager.RollbackLast

RollbackLast undoes the last conflict resolution recorded in the history.


```go
func (r *RollbackManager) RollbackLast() error
```

### ScoreHistory

ScoreHistory keeps a record of scores for learning.


#### Methods

##### ScoreHistory.Add

```go
func (h *ScoreHistory) Add(score float64)
```

##### ScoreHistory.Last

```go
func (h *ScoreHistory) Last() float64
```

### ScoringConfig

ScoringConfig holds dynamic weights for scoring.


#### Methods

##### ScoringConfig.Update

```go
func (c *ScoringConfig) Update(impact, urgency, complexity float64)
```

### ScoringMetrics

ScoringMetrics exposes scoring precision metrics.


#### Methods

##### ScoringMetrics.Precision

```go
func (m *ScoringMetrics) Precision() float64
```

### StrategyChain

StrategyChain allows chaining multiple strategies.


#### Methods

##### StrategyChain.Execute

```go
func (s *StrategyChain) Execute(conflict Conflict) (Resolution, error)
```

##### StrategyChain.Rollback

```go
func (s *StrategyChain) Rollback(res Resolution) error
```

##### StrategyChain.Validate

```go
func (s *StrategyChain) Validate(res Resolution) error
```

### UserPromptStrategy

UserPromptStrategy implements interactive resolution.


#### Methods

##### UserPromptStrategy.Execute

```go
func (u *UserPromptStrategy) Execute(conflict Conflict) (Resolution, error)
```

##### UserPromptStrategy.Rollback

```go
func (u *UserPromptStrategy) Rollback(res Resolution) error
```

##### UserPromptStrategy.Validate

```go
func (u *UserPromptStrategy) Validate(res Resolution) error
```

### VersionConflictDetector

VersionConflictDetector detects version incompatibility conflicts.


#### Methods

##### VersionConflictDetector.Detect

Detect checks for version conflicts in the provided version map.


```go
func (v *VersionConflictDetector) Detect(versions map[string]string) ([]Conflict, error)
```

## Functions

### DashboardMetricsHandler

DashboardMetrics exposes metrics via HTTP endpoints.


```go
func DashboardMetricsHandler(w http.ResponseWriter, r *http.Request)
```

### HealthCheck

HealthCheck and self-monitoring.


```go
func HealthCheck() bool
```

### IncConflictsDetected

```go
func IncConflictsDetected()
```

### IncDetectionDuration

```go
func IncDetectionDuration(ms int64)
```

### LogStructured

LogStructured logs a structured message.


```go
func LogStructured(msg string, fields ...zap.Field)
```

### SendToExternalMonitoring

ExternalMonitoring integration stub.


```go
func SendToExternalMonitoring(data interface{}) error
```

## Variables

### PerfMetrics

PerfMetrics exposes performance metrics for conflict detection.


```go
var PerfMetrics = expvar.NewMap("conflict_detection_metrics")
```

