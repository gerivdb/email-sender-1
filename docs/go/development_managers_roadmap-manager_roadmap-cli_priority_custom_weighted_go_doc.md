# Package priority

## Types

### CustomWeightedCalculator

CustomWeightedCalculator implements a fully customizable weighted priority algorithm


#### Methods

##### CustomWeightedCalculator.Calculate

Calculate computes priority using fully customizable weights


```go
func (c *CustomWeightedCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
```

##### CustomWeightedCalculator.GetDescription

GetDescription returns the calculator description


```go
func (c *CustomWeightedCalculator) GetDescription() string
```

##### CustomWeightedCalculator.GetName

GetName returns the calculator name


```go
func (c *CustomWeightedCalculator) GetName() string
```

### EisenhowerCalculator

EisenhowerCalculator implements the Eisenhower Matrix (Urgent/Important) priority algorithm


#### Methods

##### EisenhowerCalculator.Calculate

Calculate computes priority using the Eisenhower Matrix


```go
func (c *EisenhowerCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
```

##### EisenhowerCalculator.GetDescription

GetDescription returns the calculator description


```go
func (c *EisenhowerCalculator) GetDescription() string
```

##### EisenhowerCalculator.GetName

GetName returns the calculator name


```go
func (c *EisenhowerCalculator) GetName() string
```

### Engine

Engine implements the PriorityEngine interface


#### Methods

##### Engine.Calculate

Calculate computes priority for a single item


```go
func (e *Engine) Calculate(item types.RoadmapItem) (TaskPriority, error)
```

##### Engine.ClearCache

ClearCache clears the priority calculation cache


```go
func (e *Engine) ClearCache()
```

##### Engine.GetCachedPriority

GetCachedPriority returns cached priority if available


```go
func (e *Engine) GetCachedPriority(taskID string) (TaskPriority, bool)
```

##### Engine.GetWeightingConfig

GetWeightingConfig returns the current weighting configuration


```go
func (e *Engine) GetWeightingConfig() WeightingConfig
```

##### Engine.Rank

Rank sorts items by priority score in descending order


```go
func (e *Engine) Rank(items []types.RoadmapItem) ([]types.RoadmapItem, error)
```

##### Engine.SetCalculator

SetCalculator sets the priority calculation algorithm


```go
func (e *Engine) SetCalculator(calculator PriorityCalculator)
```

##### Engine.SetWeightingConfig

SetWeightingConfig sets the weighting configuration


```go
func (e *Engine) SetWeightingConfig(config WeightingConfig)
```

##### Engine.Update

Update recalculates priority for a specific task


```go
func (e *Engine) Update(taskID string) error
```

### HybridCalculator

HybridCalculator combines multiple priority calculation approaches


#### Methods

##### HybridCalculator.Calculate

Calculate computes priority using a hybrid approach


```go
func (c *HybridCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
```

##### HybridCalculator.GetAlgorithmScores

GetAlgorithmScores returns individual algorithm scores for analysis


```go
func (c *HybridCalculator) GetAlgorithmScores(item types.RoadmapItem, config WeightingConfig) (map[string]float64, error)
```

##### HybridCalculator.GetDescription

GetDescription returns the calculator description


```go
func (c *HybridCalculator) GetDescription() string
```

##### HybridCalculator.GetName

GetName returns the calculator name


```go
func (c *HybridCalculator) GetName() string
```

##### HybridCalculator.SetHybridConfig

SetHybridConfig allows customization of algorithm weights


```go
func (c *HybridCalculator) SetHybridConfig(config HybridConfig)
```

### HybridConfig

HybridConfig defines weights for combining different algorithms


### MoSCoWCalculator

MoSCoWCalculator implements the MoSCoW (Must/Should/Could/Won't) priority algorithm


#### Methods

##### MoSCoWCalculator.Calculate

Calculate computes priority using MoSCoW methodology


```go
func (c *MoSCoWCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
```

##### MoSCoWCalculator.GetDescription

GetDescription returns the calculator description


```go
func (c *MoSCoWCalculator) GetDescription() string
```

##### MoSCoWCalculator.GetName

GetName returns the calculator name


```go
func (c *MoSCoWCalculator) GetName() string
```

### MoSCoWCategory

MoSCoWCategory represents MoSCoW priority categories


### PriorityCalculator

PriorityCalculator interface defines methods for priority calculation algorithms


### PriorityEngine

PriorityEngine interface defines the main priority engine operations


### PriorityFactor

PriorityFactor represents different factors that influence task priority


### TaskPriority

TaskPriority represents the calculated priority for a task


### WSJFCalculator

WSJFCalculator implements the Weighted Shortest Job First algorithm


#### Methods

##### WSJFCalculator.Calculate

Calculate computes priority using WSJF formula
WSJF = Cost of Delay / Job Size
Cost of Delay = User-Business Value + Time Criticality + Risk Reduction


```go
func (c *WSJFCalculator) Calculate(item types.RoadmapItem, config WeightingConfig) (TaskPriority, error)
```

##### WSJFCalculator.GetDescription

GetDescription returns the calculator description


```go
func (c *WSJFCalculator) GetDescription() string
```

##### WSJFCalculator.GetName

GetName returns the calculator name


```go
func (c *WSJFCalculator) GetName() string
```

### WeightingConfig

WeightingConfig represents user-customizable weights for priority factors


