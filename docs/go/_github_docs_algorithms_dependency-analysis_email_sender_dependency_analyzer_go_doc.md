# Package main

## Types

### CircularDependency

CircularDependency represents a circular dependency cycle


### DependencyEdge

DependencyEdge represents a dependency relationship


### DependencyGraph

DependencyGraph represents the complete dependency structure


#### Methods

##### DependencyGraph.AnalyzeDependencies

AnalyzeDependencies analyzes dependencies between components


```go
func (dg *DependencyGraph) AnalyzeDependencies()
```

##### DependencyGraph.CalculateStats

CalculateStats calculates dependency statistics


```go
func (dg *DependencyGraph) CalculateStats()
```

##### DependencyGraph.DetectCircularDependencies

DetectCircularDependencies detects circular dependency cycles


```go
func (dg *DependencyGraph) DetectCircularDependencies()
```

##### DependencyGraph.DisplaySummary

DisplaySummary displays a summary of the dependency analysis


```go
func (dg *DependencyGraph) DisplaySummary()
```

##### DependencyGraph.GenerateReport

GenerateReport generates a JSON report of the dependency analysis


```go
func (dg *DependencyGraph) GenerateReport(outputFile string) error
```

##### DependencyGraph.ScanProject

ScanProject scans the project directory for components


```go
func (dg *DependencyGraph) ScanProject() error
```

### DependencyNode

DependencyNode represents a component in the dependency graph


### DependencyStats

DependencyStats provides analysis statistics


