# Package registry

## Types

### ToolRegistry

ToolRegistry manages automatic tool registration and conflict prevention


#### Methods

##### ToolRegistry.GetConflicts

GetConflicts returns all detected naming conflicts


```go
func (tr *ToolRegistry) GetConflicts() map[string][]string
```

##### ToolRegistry.GetTool

GetTool retrieves a tool by operation


```go
func (tr *ToolRegistry) GetTool(op toolkit.Operation) (toolkit.ToolkitOperation, error)
```

##### ToolRegistry.ListOperations

ListOperations returns all registered operations


```go
func (tr *ToolRegistry) ListOperations() []toolkit.Operation
```

##### ToolRegistry.Register

Register registers a new tool with conflict detection


```go
func (tr *ToolRegistry) Register(op toolkit.Operation, tool toolkit.ToolkitOperation) error
```

##### ToolRegistry.Validate

Validate performs comprehensive validation of all registered tools


```go
func (tr *ToolRegistry) Validate(ctx context.Context) error
```

## Functions

### RegisterGlobalTool

RegisterGlobalTool registers a tool with the global registry


```go
func RegisterGlobalTool(op toolkit.Operation, tool toolkit.ToolkitOperation) error
```

