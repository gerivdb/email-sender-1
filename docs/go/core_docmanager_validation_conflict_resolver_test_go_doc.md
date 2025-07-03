# Package validation

## Types

### Conflict

### Document

### ValidationIssue

### ValidationReport

## Functions

### AutoFixIssues

```go
func AutoFixIssues(ctx context.Context, doc *Document) error
```

### ManualConflictResolution

```go
func ManualConflictResolution(conflict Conflict) error
```

### ResolveConflict

```go
func ResolveConflict(conflict Conflict) error
```

### ValidateDocument

```go
func ValidateDocument(ctx context.Context, doc *Document) error
```

