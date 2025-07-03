# Package main

Package main implements the vector validation CLI tool
Phase 3.2.1.1: Créer planning-ecosystem-sync/cmd/validate-vectors/main.go


## Types

### CheckResult

CheckResult represents the result of a specific check


### CheckSummary

CheckSummary provides a summary of all checks


### CollectionInfo

CollectionInfo contains collection metadata


### QdrantInfo

QdrantInfo contains Qdrant cluster information


### ValidationConfig

ValidationConfig holds configuration for validation


### ValidationResult

ValidationResult represents the result of a validation check


### Validator

Validator performs various validation checks


#### Methods

##### Validator.ValidateAll

ValidateAll performs all validation checks


```go
func (v *Validator) ValidateAll(ctx context.Context) ([]ValidationResult, error)
```

