# Package cleanup

## Types

### CleanupManager

CleanupManager handles intelligent file organization and cleanup


#### Methods

##### CleanupManager.AnalyzeDirectoryHealth

AnalyzeDirectoryHealth performs health analysis of directory structure


```go
func (cm *CleanupManager) AnalyzeDirectoryHealth(ctx context.Context, directory string) (map[string]interface{}, error)
```

##### CleanupManager.AnalyzeDirectoryStructure

AnalyzeDirectoryStructure performs comprehensive directory structure analysis


```go
func (cm *CleanupManager) AnalyzeDirectoryStructure(ctx context.Context, directory string) (*DirectoryAnalysis, error)
```

##### CleanupManager.AnalyzePatterns

AnalyzePatterns analyzes file patterns in the specified directory


```go
func (cm *CleanupManager) AnalyzePatterns(ctx context.Context, directory string) ([]FilePattern, error)
```

##### CleanupManager.ApplyPatternBasedCleanup

ApplyPatternBasedCleanup applies cleanup based on detected patterns


```go
func (cm *CleanupManager) ApplyPatternBasedCleanup(ctx context.Context, directory string, patterns []FilePattern) ([]CleanupTask, error)
```

##### CleanupManager.DetectFilePatterns

DetectFilePatterns detects specific file patterns that indicate cleanup opportunities


```go
func (cm *CleanupManager) DetectFilePatterns(ctx context.Context, directory string) ([]CleanupTask, error)
```

##### CleanupManager.ExecuteTasks

ExecuteTasks executes the provided cleanup tasks


```go
func (cm *CleanupManager) ExecuteTasks(ctx context.Context, tasks []CleanupTask, dryRun bool) error
```

##### CleanupManager.GenerateOrganizationReport

GenerateOrganizationReport generates a comprehensive organization report


```go
func (cm *CleanupManager) GenerateOrganizationReport(ctx context.Context, directory string) (*OrganizationReport, error)
```

##### CleanupManager.GetHealthStatus

GetHealthStatus returns the health status of the cleanup manager


```go
func (cm *CleanupManager) GetHealthStatus(ctx context.Context) core.HealthStatus
```

##### CleanupManager.GetStats

GetStats returns the current cleanup statistics


```go
func (cm *CleanupManager) GetStats() CleanupStats
```

##### CleanupManager.OptimizeDirectoryStructure

OptimizeDirectoryStructure optimizes directory structure using AI insights


```go
func (cm *CleanupManager) OptimizeDirectoryStructure(ctx context.Context, directory string) (*OrganizationReport, error)
```

##### CleanupManager.Reset

Reset resets the cleanup statistics


```go
func (cm *CleanupManager) Reset()
```

##### CleanupManager.ScanForCleanup

ScanForCleanup scans the specified directories for cleanup opportunities


```go
func (cm *CleanupManager) ScanForCleanup(ctx context.Context, directories []string) ([]CleanupTask, error)
```

### CleanupStats

CleanupStats tracks cleanup operations statistics


### CleanupTask

CleanupTask represents a cleanup task to be executed


### DirectoryAnalysis

### DuplicateGroup

DuplicateGroup represents a group of duplicate files


### FilePattern

Additional structures for Level 2 and Level 3 functionality


### OrganizationReport

### OrganizationRule

OrganizationRule represents a file organization rule


### SafetyCheck

SafetyCheck represents safety validation for cleanup operations


