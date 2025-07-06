# Package manager

## Types

### ManagerToolkit

ManagerToolkit provides the external interface for toolkit operations


#### Methods

##### ManagerToolkit.ExecuteOperation

ExecuteOperation executes a toolkit operation


```go
func (mt *ManagerToolkit) ExecuteOperation(ctx context.Context, op toolkit.Operation, opts *toolkit.OperationOptions) error
```

