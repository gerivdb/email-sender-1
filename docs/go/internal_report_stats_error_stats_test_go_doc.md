# Package stats

Package stats provides error statistics aggregation for reports


## Types

### ErrorEntry

ErrorEntry represents statistics for a single error type


### ErrorStats

ErrorStats tracks and aggregates error statistics


#### Methods

##### ErrorStats.GetErrorRate

GetErrorRate returns the error rate over a given duration


```go
func (es *ErrorStats) GetErrorRate(duration time.Duration) float64
```

##### ErrorStats.GetTopErrors

GetTopErrors returns the top N most frequent errors


```go
func (es *ErrorStats) GetTopErrors() []ErrorSummary
```

##### ErrorStats.GetTotalErrors

GetTotalErrors returns the total number of errors


```go
func (es *ErrorStats) GetTotalErrors() int
```

##### ErrorStats.RecordError

RecordError records an error occurrence


```go
func (es *ErrorStats) RecordError(errType string, sample string)
```

##### ErrorStats.Reset

Reset clears all error statistics


```go
func (es *ErrorStats) Reset()
```

### ErrorSummary

ErrorSummary summarizes error statistics


