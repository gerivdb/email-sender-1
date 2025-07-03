# Package diff

Package diff provides unified diff generation for reports


## Types

### DiffLine

DiffLine represents a single line in a diff with its content and type


### LineType

LineType represents the type of a diff line


### UnifiedDiff

UnifiedDiff represents a unified diff format generator


#### Methods

##### UnifiedDiff.Generate

Generate generates a unified diff between two texts


```go
func (ud *UnifiedDiff) Generate(oldText, newText string) (string, error)
```

