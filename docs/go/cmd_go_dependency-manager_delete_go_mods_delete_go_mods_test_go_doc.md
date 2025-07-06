# Package delete_go_mods

## Types

### DeletionReport

DeletionReport summarizes the deletion process.


### DeletionResult

DeletionResult represents the result of a single file deletion attempt.


## Functions

### RunDelete

RunDelete performs the deletion of files listed in inputJSONPath and generates a report.


```go
func RunDelete(inputJSONPath, outputReportPath string) error
```

