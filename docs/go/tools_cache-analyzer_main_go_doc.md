# Package main

Cache analyzer tool for TTL optimization


## Types

### AnalysisReport

AnalysisReport contains the results of cache analysis


### CacheAnalyzer

CacheAnalyzer performs comprehensive cache analysis


#### Methods

##### CacheAnalyzer.Close

Close cleans up resources


```go
func (ca *CacheAnalyzer) Close()
```

##### CacheAnalyzer.RunAnalysis

RunAnalysis performs comprehensive cache analysis


```go
func (ca *CacheAnalyzer) RunAnalysis(ctx context.Context, duration time.Duration, verbose bool) *AnalysisReport
```

### Recommendation

Recommendation represents an optimization recommendation


