# Package validation

Package validation provides fail-fast validation for RAG search operations
Time-Saving Method 1: Fail-Fast Validation
ROI: +48-72h immediate + 24h/month (eliminates 70% debug cycles)


## Types

### SearchRequest

SearchRequest represents a RAG search request


### ValidationConfig

ValidationConfig holds validator configuration


### ValidationError

ValidationError represents a validation error with context


#### Methods

##### ValidationError.Error

```go
func (e ValidationError) Error() string
```

### ValidationResult

ValidationResult encapsulates validation results with metrics


### ValidationStats

ValidationStats tracks validation performance metrics


### Validator

Validator provides fail-fast validation with built-in performance monitoring


#### Methods

##### Validator.GetConfig

GetConfig returns current validation configuration


```go
func (v *Validator) GetConfig() *ValidationConfig
```

##### Validator.GetStats

GetStats returns current validation statistics


```go
func (v *Validator) GetStats() *ValidationStats
```

##### Validator.UpdateConfig

UpdateConfig updates validator configuration


```go
func (v *Validator) UpdateConfig(config *ValidationConfig)
```

##### Validator.ValidateSearchRequest

ValidateSearchRequest performs comprehensive fail-fast validation


```go
func (v *Validator) ValidateSearchRequest(req *SearchRequest) (*ValidationResult, error)
```

